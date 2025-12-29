#pragma once
#include <windows.h>
#include <lua.hpp>
#include <cstdint>
#include <vector>

// defined in mem.cpp:
extern HANDLE hProc;
extern int memRef;
extern lua_State* gLua; // global lua state
extern DWORD gPid;

// helpers
DWORD getPid(const wchar_t* exeName);
uintptr_t readPtr(uintptr_t addr);
bool readIntAt(uintptr_t addr, int &out);
bool writeBytesAt(uintptr_t addr, const std::vector<uint8_t>& buf);

// asm buffer
void asmInit();
void asmAddByte(uint8_t v);
void asmAddWord(uint16_t v);
void asmAddDword(uint32_t v);
void asmPushByte(uint8_t v);
void asmPushDword(uint32_t v);
void asmMovRegImm(int reg, uint32_t imm);
void asmMovRegDwordPtr(int reg, uint32_t imm);
void asmMovRegDwordPtrRegAdd(int reg, uint32_t imm);
void asmPushReg(int reg);
void asmPopReg(int reg);
void asmMovRegReg(int toReg, int fromReg);
void asmAddList(const std::vector<uint8_t>& v);
void asmCall(uint32_t absAddr);
void asmRet();
int asmExecute();

// lua wrappers
int lStart(lua_State* L);
int lStop(lua_State* L);

// asm
int lAsmInit(lua_State* L);
int lAsmAddByte(lua_State* L);
int lAsmAddWord(lua_State* L);
int lAsmAddDword(lua_State* L);
int lAsmPushByte(lua_State* L);
int lAsmPushDword(lua_State* L);
int lAsmMovRegImm(lua_State* L);
int lAsmMovRegDwordPtr(lua_State* L);
int lAsmMovRegDwordPtrRegAdd(lua_State* L);
int lAsmPushReg(lua_State* L);
int lAsmPopReg(lua_State* L);
int lAsmMovRegReg(lua_State* L);
int lAsmAddList(lua_State* L);
int lAsmCall(lua_State* L);
int lAsmRet(lua_State* L);
int lAsmExecute(lua_State* L);
int lSleep(lua_State* L);

// memory
int lReadMemory(lua_State* L);
int lWriteMemory(lua_State* L);

// event handler
int msghandler(lua_State* L);
int lOnUpdate(lua_State* L);
int lStopUpdate(lua_State* L);
int lIsPressed(lua_State* L);

// key detect
int vkFromName(const char* name);

// bool readChain(const std::vector<uintptr_t>& chain, int& out);
// int lAddEventListener(lua_State* L);
// int lRemoveEventListener(lua_State* L);
// int lRemoveAllEventListeners(lua_State* L);

// lua export
extern "C" __declspec(dllexport) int luaopen_mem(lua_State* L);