#include <windows.h>
#include <tlhelp32.h>
#include <lua.hpp>
#include <cstdint>
#include <vector>
#include "mem.h"

HANDLE hProc = nullptr; // pvz process
int memRef = LUA_NOREF; // ref lua
lua_State* gLua = nullptr; // L variable
DWORD gPid = 0; // pid of PlantsVsZombies.exe (set in lStart)

// helpers
DWORD getPid(const wchar_t* exeName) {
    PROCESSENTRY32W pe;
    pe.dwSize = sizeof(pe);

    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE)
        return 0;

    if (Process32FirstW(snap, &pe)) 
        do 
            if (!_wcsicmp(pe.szExeFile, exeName)) 
            {
                CloseHandle(snap);
                return pe.th32ProcessID;
            }
        while (Process32NextW(snap, &pe));

    CloseHandle(snap);
    return 0;
}

uintptr_t readPtr(uintptr_t addr) {
    if (!hProc || addr == 0)
        return 0;

    uintptr_t out = 0;
    SIZE_T bytesRead = 0;

    BOOL ok = ReadProcessMemory(hProc, (LPCVOID)addr, &out, sizeof(out), &bytesRead);
    if (!ok || bytesRead != sizeof(out)) // if wrong size
        return 0;

    return out;
}

// reads 32 bit address
bool readIntAt(uintptr_t addr, int &out) 
{
    if (!hProc || addr == 0)
        return false;

    SIZE_T bytesRead = 0;
    BOOL ok = ReadProcessMemory(hProc, (LPCVOID)addr, &out, sizeof(out), &bytesRead);

    return ok && bytesRead == sizeof(out);
}

// writes a buffer of bytes
//! NOTE: This does not give ReadWriteExecute permissions, which could be a issue when ASM injecting in code caves
bool writeBytesAt(uintptr_t addr, const std::vector<uint8_t>& buf) 
{
    if (!hProc || addr == 0)
        return false;

    SIZE_T bytesWritten = 0;
    BOOL ok = WriteProcessMemory(hProc, (LPVOID)addr, buf.data(), buf.size(), &bytesWritten);

    return ok && bytesWritten == buf.size();
}

// other lua wrappers about memory read/write i guess
bool readByteAt(uintptr_t addr, uint8_t &out) // was missing
{
    if (!hProc || addr == 0)
        return false;

    SIZE_T bytesRead = 0;
    BOOL ok = ReadProcessMemory(hProc, (LPCVOID)addr, &out, sizeof(out), &bytesRead);

    return ok && bytesRead == sizeof(out);
}
// reads an integer (4 bytes) from memory
int lReadInt(lua_State* L) {
    uintptr_t addr = 0;
    
    // Support for pointer chains (like readMemory)
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1) {
            lua_pushnil(L);
            return 1;
        }
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        // If chain has more than 1 element, first is a pointer to dereference
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            if (tmp) 
                addr = tmp;
            else {
                lua_pushnil(L);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushnil(L);
            return 1;
        }
        
        // Follow the chain
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                if (!next) {
                    lua_pushnil(L);
                    return 1;
                }
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        // Direct address
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    int value = 0;
    if (readIntAt(addr, value))
        lua_pushinteger(L, value);
    else
        lua_pushnil(L);
    
    return 1;
}

// reads a short (2 bytes) from memory
int lReadShort(lua_State* L) {
    uintptr_t addr = 0;
    
    // Same pointer chain logic
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1) {
            lua_pushnil(L);
            return 1;
        }
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            if (tmp) 
                addr = tmp;
            else {
                lua_pushnil(L);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushnil(L);
            return 1;
        }
        
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                if (!next) {
                    lua_pushnil(L);
                    return 1;
                }
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    // Read 2 bytes
    if (!hProc || addr == 0) {
        lua_pushnil(L);
        return 1;
    }
    
    short value = 0;
    SIZE_T bytesRead = 0;
    BOOL ok = ReadProcessMemory(hProc, (LPCVOID)addr, &value, sizeof(value), &bytesRead);
    
    if (ok && bytesRead == sizeof(value))
        lua_pushinteger(L, value);
    else
        lua_pushnil(L);
    
    return 1;
}

// reads a float (4 bytes) from memory
int lReadFloat(lua_State* L) {
    uintptr_t addr = 0;
    
    // Pointer chain logic
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1) {
            lua_pushnil(L);
            return 1;
        }
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            if (tmp) 
                addr = tmp;
            else {
                lua_pushnil(L);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushnil(L);
            return 1;
        }
        
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                if (!next) {
                    lua_pushnil(L);
                    return 1;
                }
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    // Read 4 bytes as float
    if (!hProc || addr == 0) {
        lua_pushnil(L);
        return 1;
    }
    
    float value = 0.0f;
    SIZE_T bytesRead = 0;
    BOOL ok = ReadProcessMemory(hProc, (LPCVOID)addr, &value, sizeof(value), &bytesRead);
    
    if (ok && bytesRead == sizeof(value))
        lua_pushnumber(L, value);
    else
        lua_pushnil(L);
    
    return 1;
}

// lua wrapper!!
int lReadByte(lua_State* L) {
    uintptr_t addr = 0;
    
    // pointer chain as usual (simplify?)
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1) {
            lua_pushnil(L);
            return 1;
        }
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            if (tmp) addr = tmp;
            else {
                lua_pushnil(L);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushnil(L);
            return 1;
        }
        
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                if (!next) {
                    lua_pushnil(L);
                    return 1;
                }
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        // direct
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    uint8_t val = 0;
    if (readByteAt(addr, val))
        lua_pushinteger(L, val);
    else
        lua_pushnil(L);
    
    return 1;
}

// write complementary
// writes an integer (4 bytes) to memory
int lWriteInt(lua_State* L) {
    uintptr_t addr = 0;
    
    // Get address (chain or direct)
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        // dereference first element if chainLen > 1
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            if (tmp)
                addr = tmp;
            else {
                lua_pushboolean(L, 0);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        // Follow pointer chain
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                if (!next) {
                    lua_pushboolean(L, 0);
                    return 1;
                }
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        // Direct address
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    // Get value to write
    int value = (int)luaL_checkinteger(L, 2);
    
    // Write 4 bytes
    if (!hProc || addr == 0) {
        lua_pushboolean(L, 0);
        return 1;
    }
    
    SIZE_T bytesWritten = 0;
    BOOL ok = WriteProcessMemory(hProc, (LPVOID)addr, &value, sizeof(value), &bytesWritten);
    
    lua_pushboolean(L, ok && bytesWritten == sizeof(value));
    return 1;
}

// writes a short (2 bytes) to memory
int lWriteShort(lua_State* L) {
    uintptr_t addr = 0;
    
    // Get address (chain or direct)
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            if (tmp)
                addr = tmp;
            else {
                lua_pushboolean(L, 0);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                if (!next) {
                    lua_pushboolean(L, 0);
                    return 1;
                }
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    // Get value to write (cast to short)
    short value = (short)luaL_checkinteger(L, 2);
    
    // Write 2 bytes
    if (!hProc || addr == 0) {
        lua_pushboolean(L, 0);
        return 1;
    }
    
    SIZE_T bytesWritten = 0;
    BOOL ok = WriteProcessMemory(hProc, (LPVOID)addr, &value, sizeof(value), &bytesWritten);
    
    lua_pushboolean(L, ok && bytesWritten == sizeof(value));
    return 1;
}

// writes a float (4 bytes) to memory
int lWriteFloat(lua_State* L) {
    uintptr_t addr = 0;
    
    // Get address (chain or direct)
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            if (tmp)
                addr = tmp;
            else {
                lua_pushboolean(L, 0);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                if (!next) {
                    lua_pushboolean(L, 0);
                    return 1;
                }
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    // Get value to write
    float value = (float)luaL_checknumber(L, 2);
    
    // Write 4 bytes as float
    if (!hProc || addr == 0) {
        lua_pushboolean(L, 0);
        return 1;
    }
    
    SIZE_T bytesWritten = 0;
    BOOL ok = WriteProcessMemory(hProc, (LPVOID)addr, &value, sizeof(value), &bytesWritten);
    
    lua_pushboolean(L, ok && bytesWritten == sizeof(value));
    return 1;
}

// writes a single byte to memory (simpler version)
int lWriteByte(lua_State* L) {
    uintptr_t addr = 0;
    
    // Get address (chain or direct)
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            if (tmp)
                addr = tmp;
            else {
                lua_pushboolean(L, 0);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                if (!next) {
                    lua_pushboolean(L, 0);
                    return 1;
                }
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    // Get value to write
    uint8_t value = (uint8_t)luaL_checkinteger(L, 2);
    
    // Write 1 byte
    if (!hProc || addr == 0) {
        lua_pushboolean(L, 0);
        return 1;
    }
    
    SIZE_T bytesWritten = 0;
    BOOL ok = WriteProcessMemory(hProc, (LPVOID)addr, &value, sizeof(value), &bytesWritten);
    
    lua_pushboolean(L, ok && bytesWritten == sizeof(value));
    return 1;
}

// other lua wrappers (asm-related defined in asm.cpp)
// module start/stop (todo rewise)
int lStart(lua_State* L) {
    // if (hProc) { // ignores memory.start if already started
    //     lua_pushboolean(L, 0);
    //     return 1;
    // }

    auto pid = getPid(L"PlantsVsZombies.exe");
    if (!pid) return luaL_error(L,"'PlantsVsZombies.exe' not found in the process list!");

    gPid = pid; // save pid

    hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
    if (!hProc) return luaL_error(L,"OpenProcess failed");

    lua_pushboolean(L, 1);
    return 1;
}

int lStop(lua_State* L) {
    // stop process
    if (hProc) {
        CloseHandle(hProc);
        hProc = nullptr;
    }
    return 0;
}

// readMemory wrapper
int lReadMemory(lua_State* L) {
    luaL_checktype(L, 1, LUA_TTABLE); // check type

    int chainLen = (int)luaL_len(L, 1);

    if (chainLen < 1) {
        lua_pushnil(L);
        return 1;
    }

    uintptr_t addr = 0;
    lua_rawgeti(L, 1, 1); // first element?

    addr = (uintptr_t)lua_tointeger(L, -1);
    lua_pop(L, 1);
    
    // if chainLen > 1, first element is a pointer to dereference

    if (chainLen > 1) {
        uintptr_t tmp = readPtr(addr);

        if (tmp) addr = tmp;
        else {
            lua_pushnil(L);
            return 1;
        }
    }
    
    if (!addr) {
        lua_pushnil(L);
        return 1;
    }

    for (int i = 2; i <= chainLen; ++i) { // confusing
        lua_rawgeti(L, 1, i);

        uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);

        if (i < chainLen) {
            uintptr_t next = readPtr(addr + off);
            
            if (!next) {
                lua_pushnil(L);
                return 1;
            }
            
            addr = next;
        } else
            addr = addr + off; // can += be used?
    }

    int val = 0; // when table has 1 element, the int value is read directly
    
    if (readIntAt(addr, val))
        lua_pushinteger(L, val);
    else
        lua_pushnil(L);
    
    return 1;
}

// writeMemory wrapper
int lWriteMemory(lua_State* L) {
    uintptr_t addr = 0;
    
    // Get address (chain or direct)
    if (lua_type(L, 1) == LUA_TTABLE) {
        int chainLen = (int)luaL_len(L, 1);
        
        if (chainLen < 1)
            return luaL_error(L, "empty chain");
        
        lua_rawgeti(L, 1, 1);
        addr = (uintptr_t)lua_tointeger(L, -1);
        lua_pop(L, 1);
        
        // dereference first element if chainLen > 1 - like in readmemory
        if (chainLen > 1) {
            uintptr_t tmp = readPtr(addr);
            
            if (tmp)
                addr = tmp;
            else {
                lua_pushboolean(L, 0);
                return 1;
            }
        }
        
        if (!addr) {
            lua_pushboolean(L, 0);
            return 1;
        }
        
        // chain of pointers
        for (int i = 2; i <= chainLen; ++i) {
            lua_rawgeti(L, 1, i);
            uintptr_t off = (uintptr_t)lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            if (i < chainLen) {
                uintptr_t next = readPtr(addr + off);
                
                if (!next) {
                    lua_pushboolean(L, 0);
                    return 1;
                }
                
                addr = next;
            } else {
                addr = addr + off;
            }
        }
    } else {
        // direct
        addr = (uintptr_t)luaL_checkinteger(L, 1);
    }
    
    if (lua_type(L, 2) == LUA_TTABLE) {
        // bytes from table
        int len = (int)luaL_len(L, 2);
        std::vector<uint8_t> buf;
        buf.reserve(len);
        
        for (int i = 1; i <= len; ++i) {
            lua_rawgeti(L, 2, i);
            buf.push_back((uint8_t)lua_tointeger(L, -1));
            lua_pop(L, 1);
        }
        
        lua_pushboolean(L, writeBytesAt(addr, buf));
    } else {
        // int 4 bytes...
        int v = (int)luaL_checkinteger(L, 2);
        std::vector<uint8_t> b(sizeof(int));
        memcpy(b.data(), &v, sizeof(int));
        
        lua_pushboolean(L, writeBytesAt(addr, b));
    }
    
    return 1;
}

// allocates executable memory
int lAllocateExecutable(lua_State* L) {
    SIZE_T size = (SIZE_T)luaL_checkinteger(L, 1); // size, usually 32, 64, 128...
    
    if (!hProc) {
        lua_pushnil(L);
        lua_pushstring(L, "Process not attached");
        return 2;
    }
    
    LPVOID addr = VirtualAllocEx(hProc, NULL, size, 
        MEM_COMMIT | MEM_RESERVE, 
        PAGE_EXECUTE_READWRITE
    );
    
    if (!addr) {
        lua_pushnil(L);
        lua_pushstring(L, "VirtualAllocEx failed");
        return 2;
    }
    
    lua_pushinteger(L, (DWORD)addr);
    return 1;
}

int lFreeMemory(lua_State* L) {
    DWORD addr = (DWORD)luaL_checkinteger(L, 1); // address, not size
    
    if (!hProc) {
        lua_pushboolean(L, 0);
        return 1;
    }
    
    BOOL ok = VirtualFreeEx(hProc, (LPVOID)addr, 0, MEM_RELEASE);
    lua_pushboolean(L, ok);
    return 1;
}

// module open: register functions and constants
extern "C" __declspec(dllexport)

int __cdecl luaopen_mem(lua_State* L) {
    gLua = L;

    luaL_Reg funcs[] = {
        {"start", lStart}, {"stop", lStop},
        {"readMemory", lReadMemory}, {"writeMemory", lWriteMemory},

        {"allocateEx", lAllocateExecutable}, {"freeEx", lFreeMemory},

        {"readByte", lReadByte}, {"writeByte", lWriteByte},
        {"readInt", lReadInt}, {"writeInt", lWriteInt},
        {"readShort", lReadShort}, {"writeShort", lWriteShort},
        {"readFloat", lReadFloat}, {"writeFloat", lWriteFloat},

        {"onUpdate", lOnUpdate},
        {"stopUpdate", lStopUpdate},

        {"isKeyPressed", lIsPressed},

        // breakpoints
        // {"setBreakpoint", lSetBreakpoint},
        // {"removeBreakpoint", lRemoveBreakpoint},

        // asm functions
        {"asm_init", lAsmInit},
        {"asm_add_byte", lAsmAddByte},
        {"asm_add_word", lAsmAddWord},
        {"asm_add_dword", lAsmAddDword},
        {"asm_push_byte", lAsmPushByte},
        {"asm_push_dword", lAsmPushDword},
        {"asm_mov_reg_imm", lAsmMovRegImm},
        {"asm_mov_dword_ptr_reg", lAsmMovRegDwordPtr},
        {"asm_mov_dword_ptr_reg_add", lAsmMovRegDwordPtrRegAdd},
        {"asm_push_reg", lAsmPushReg},
        {"asm_pop_reg", lAsmPopReg},
        {"asm_mov_reg_reg", lAsmMovRegReg},
        {"asm_add_list", lAsmAddList},
        {"asm_call", lAsmCall},
        {"asm_ret", lAsmRet},
        {"asm_code_inject", lAsmExecute},
        {"sleep", lSleep},

        {nullptr,nullptr}
    };
    luaL_newlib(L, funcs);

    // define regs constants
    lua_pushinteger(L, 0); lua_setfield(L, -2, "EAX");
    lua_pushinteger(L, 1); lua_setfield(L, -2, "ECX");
    lua_pushinteger(L, 2); lua_setfield(L, -2, "EDX");
    lua_pushinteger(L, 3); lua_setfield(L, -2, "EBX");
    lua_pushinteger(L, 4); lua_setfield(L, -2, "ESP");
    lua_pushinteger(L, 5); lua_setfield(L, -2, "EBP");
    lua_pushinteger(L, 6); lua_setfield(L, -2, "ESI");
    lua_pushinteger(L, 7); lua_setfield(L, -2, "EDI");

    lua_pushvalue(L, -1);
    memRef = luaL_ref(L, LUA_REGISTRYINDEX);
    return 1;
}