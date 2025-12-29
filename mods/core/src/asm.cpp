#include <windows.h>
#include <tlhelp32.h>
#include <lua.hpp>
#include <cstdint>
#include <vector>
#include "mem.h"

// asm buffers
std::vector<uint8_t> codeBuf; // buffer of bytes
std::vector<uint32_t> callsPos;

// reset
void asmInit() {
    codeBuf.clear();
    callsPos.clear();
}

void asmAddByte(uint8_t v) { codeBuf.push_back(v); } // adds a byte to buffer

void asmAddWord(uint16_t v) { // 2 bytes
    size_t p = codeBuf.size();
    codeBuf.resize(p + 2);
    memcpy(codeBuf.data() + p, &v, 2);
}

void asmAddDword(uint32_t v) { // 4 bytes
    size_t p = codeBuf.size();
    codeBuf.resize(p + 4);
    memcpy(codeBuf.data() + p, &v, 4);
}

// push imm8
void asmPushByte(uint8_t v) {
    asmAddByte(0x6A);
    asmAddByte(v);
}

// push imm32
void asmPushDword(uint32_t v) {
    asmAddByte(0x68);
    asmAddDword(v);
}

// mov reg, imm32 (0 = EAX, 1 = ECX, 2 = EDX, 3 = EBX, 4 = ESP, 5 = EBP, 6 = ESI, 7 = EDI)
void asmMovRegImm(int reg, uint32_t imm) {
    asmAddByte(0xB8 + (uint8_t)reg);
    asmAddDword(imm);
}

// mov reg, [imm32] (load absolute address)
void asmMovRegDwordPtr(int reg, uint32_t imm) {
    asmAddByte(0x8B);
    asmAddByte((uint8_t)(5 + (reg << 3))); // modrm: mod=00, r=reg, rm=101
    asmAddDword(imm);
}

// mov destReg, [destReg + disp32]  (destReg used both as dest and base)
void asmMovRegDwordPtrRegAdd(int reg, uint32_t disp)
{
    asmAddByte(0x8B);
    uint8_t r = (uint8_t)(reg & 7);
    uint8_t modrm = (uint8_t)(0x80 | (r << 3) | r); // 0x80 = mod=10, reg<<3, rm=reg
    asmAddByte(modrm);

    if (r == 4) // ESP needs SIB 0x24
        asmAddByte(0x24);

    asmAddDword(disp);
}

// push reg
void asmPushReg(int reg) { asmAddByte((uint8_t)(0x50 + reg)); }
// pop reg
void asmPopReg(int reg) { asmAddByte((uint8_t)(0x58 + reg)); }
// mov reg_to, reg_from
void asmMovRegReg(int toReg, int fromReg) {
    asmAddByte(0x8B);
    asmAddByte((uint8_t)(0xC0 + (toReg << 3) + fromReg));
}

// adds a list of bytes to buffer
void asmAddList(const std::vector<uint8_t>& v) {
    codeBuf.insert(codeBuf.end(), v.begin(), v.end());
}

// call absolute address?
void asmCall(uint32_t absAddr) {
    asmAddByte(0xE8);
    callsPos.push_back((uint32_t)codeBuf.size());
    asmAddDword(absAddr);
}

void asmRet() {
    asmAddByte(0xC3);
}

// execute: patch calls -> inject -> run -> end (free)
int asmExecute() // returns EAX (address)
{
    if (!hProc)
        return -1;

    std::vector<uint8_t> local = codeBuf; // local copy

    uintptr_t remoteAddr = (uintptr_t)VirtualAllocEx(
        hProc, 
        NULL, 
        local.size(), 
        MEM_COMMIT | MEM_RESERVE, 
        PAGE_EXECUTE_READWRITE
    );

    if (!remoteAddr)
        return -1;

    // patch call absolute to relative
    for (size_t i = 0; i < callsPos.size(); ++i) 
    {
        uint32_t pos = callsPos[i];
        if (pos + 4 > local.size()) 
        {
            VirtualFreeEx(hProc, (LPVOID)remoteAddr, 0, MEM_RELEASE);
            return -1;
        }

        int32_t orig = 0;
        memcpy(&orig, local.data() + pos, 4);

        int32_t rel = orig - ((int32_t)remoteAddr + (int32_t)pos + 4);
        memcpy(local.data() + pos, &rel, 4);
    }

    SIZE_T written = 0;

    // uh?
    if (!WriteProcessMemory(hProc, (LPVOID)remoteAddr, local.data(), local.size(), &written) || written != local.size()) 
    {
        VirtualFreeEx(hProc, (LPVOID)remoteAddr, 0, MEM_RELEASE);
        return -1;
    }

    FlushInstructionCache(hProc, (LPVOID)remoteAddr, local.size());

    HANDLE t = CreateRemoteThread(
        hProc, 
        NULL, 0, 
        (LPTHREAD_START_ROUTINE)remoteAddr, 
        NULL, 0, NULL
    );

    if (!t) 
    {
        VirtualFreeEx(hProc, (LPVOID)remoteAddr, 0, MEM_RELEASE);
        return -1;
    }

    WaitForSingleObject(t, 1000);

    DWORD eax = 0;
    GetExitCodeThread(t, &eax);

    CloseHandle(t);
    VirtualFreeEx(hProc, (LPVOID)remoteAddr, 0, MEM_RELEASE);

    return (int)eax;
}

// lua wrappers for asm
int lAsmInit(lua_State* L) 
{
    asmInit();
    return 0;
}

int lAsmAddByte(lua_State* L) 
{
    auto value = (uint8_t)luaL_checkinteger(L, 1);
    asmAddByte(value);
    return 0;
}

int lAsmAddWord(lua_State* L) 
{
    auto value = (uint16_t)luaL_checkinteger(L, 1);
    asmAddWord(value);
    return 0;
}

int lAsmAddDword(lua_State* L) 
{
    auto value = (uint32_t)luaL_checkinteger(L, 1);
    asmAddDword(value);
    return 0;
}

int lAsmPushByte(lua_State* L) 
{
    auto value = (uint8_t)luaL_checkinteger(L, 1);
    asmPushByte(value);
    return 0;
}

int lAsmPushDword(lua_State* L) 
{
    auto value = (uint32_t)luaL_checkinteger(L, 1);
    asmPushDword(value);
    return 0;
}

int lAsmMovRegImm(lua_State* L) 
{
    auto reg = (int)luaL_checkinteger(L, 1);
    auto imm = (uint32_t)luaL_checkinteger(L, 2);
    asmMovRegImm(reg, imm);
    return 0;
}

int lAsmMovRegDwordPtr(lua_State* L) 
{
    auto reg = (int)luaL_checkinteger(L, 1);
    auto addr = (uint32_t)luaL_checkinteger(L, 2);
    asmMovRegDwordPtr(reg, addr);
    return 0;
}

int lAsmMovRegDwordPtrRegAdd(lua_State* L) 
{
    auto reg = (int)luaL_checkinteger(L, 1);
    auto offset = (uint32_t)luaL_checkinteger(L, 2);
    asmMovRegDwordPtrRegAdd(reg, offset);
    return 0;
}

int lAsmPushReg(lua_State* L) 
{
    auto reg = (int)luaL_checkinteger(L, 1);
    asmPushReg(reg);
    return 0;
}

int lAsmPopReg(lua_State* L) 
{
    auto reg = (int)luaL_checkinteger(L, 1);
    asmPopReg(reg);
    return 0;
}

int lAsmMovRegReg(lua_State* L) 
{
    auto toReg = (int)luaL_checkinteger(L, 1);
    auto fromReg = (int)luaL_checkinteger(L, 2);
    asmMovRegReg(toReg, fromReg);
    return 0;
}

int lAsmAddList(lua_State* L) // list of bytes
{
    luaL_checktype(L, 1, LUA_TTABLE);
    int len = (int)luaL_len(L, 1);

    std::vector<uint8_t> bytes;
    bytes.reserve(len);

    for (int i = 1; i <= len; ++i) 
    {
        lua_rawgeti(L, 1, i);
        bytes.push_back((uint8_t)lua_tointeger(L, -1));
        lua_pop(L, 1);
    }

    asmAddList(bytes);
    return 0;
}

int lAsmCall(lua_State* L) 
{
    auto addr = (uint32_t)luaL_checkinteger(L, 1);
    asmCall(addr);
    return 0;
}

int lAsmRet(lua_State* L) 
{
    asmRet();
    return 0;
}

int lAsmExecute(lua_State* L) 
{
    int eax = asmExecute();

    if (eax < 0) 
    {
        lua_pushnil(L);
        return 1;
    }

    lua_pushinteger(L, eax);
    return 1;
}

int lSleep(lua_State* L) 
{
    int ms = (int)luaL_checkinteger(L, 1);
    Sleep(ms);
    return 0;
}