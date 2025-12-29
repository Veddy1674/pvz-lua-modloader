#pragma once
#include <windows.h>
#include <tlhelp32.h>
#include <lua.hpp>
#include <cstdint>
#include <vector>
#include <string>
#include <cctype>
#include "mem.h"

static bool loopRunning = false;
static lua_State* loopState = nullptr;

static int pendingErrorRef = LUA_NOREF;

int lStopUpdate(lua_State* L) {
    loopRunning = false;
    return 0;
}

int lOnUpdate(lua_State* L) {
    luaL_checktype(L, 1, LUA_TFUNCTION);
    int interval = (int)luaL_optinteger(L, 2, 16);

    lua_pushvalue(L, 1);
    int cbRef = luaL_ref(L, LUA_REGISTRYINDEX);

    loopRunning = true;
    loopState = L;

    while (loopRunning) {
        lua_pushcfunction(L, msghandler);
        lua_rawgeti(L, LUA_REGISTRYINDEX, cbRef);

        int status = lua_pcall(L, 0, 0, -2);
        if (status != LUA_OK) {
            pendingErrorRef = luaL_ref(L, LUA_REGISTRYINDEX); // pop errorString

            lua_pop(L, 1); // pop msghandler
            loopRunning = false;
            break;
        }

        lua_pop(L, 1); // pop msghandler
        Sleep(interval);
    }

    luaL_unref(L, LUA_REGISTRYINDEX, cbRef);

    if (pendingErrorRef != LUA_NOREF) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, pendingErrorRef);
        luaL_unref(L, LUA_REGISTRYINDEX, pendingErrorRef);
        pendingErrorRef = LUA_NOREF;

        return lua_error(L); // print error once (before i had double error printing)
    }

    return 0;
}

static int msghandler(lua_State* L) {
    if (lua_isstring(L, 1)) {
        lua_pushvalue(L, 1); // return original message string
        return 1;
    }
    if (luaL_callmeta(L, 1, "__tostring") && lua_isstring(L, -1)) {
        return 1; // __tostring pushed it
    }
    lua_pushliteral(L, "(error object is not a string)"); // no idea
    return 1;
}

// in mem.cpp it might make more sense?
int vkFromName(const char* name) {
    if (!name) return -1;
    
    std::string s(name);
    for (auto &c : s) c = (char)std::tolower((unsigned char)c);

    // single letter or digit -> use ASCII VK code ('A'..'Z','0'..'9')
    if (s.size() == 1) {
        char c = s[0];
        if (c >= 'a' && c <= 'z') return (int)std::toupper(c);
        if (c >= '0' && c <= '9') return (int)c;
    }

    // i hate you cpp for not having switch for strings
    if (s == "esc" || s == "escape") return VK_ESCAPE;
    if (s == "enter") return VK_RETURN;
    if (s == "space" || s == "spacebar") return VK_SPACE;
    if (s == "left") return VK_LEFT;
    if (s == "right") return VK_RIGHT;
    if (s == "up") return VK_UP;
    if (s == "down") return VK_DOWN;
    if (s == "shift") return VK_SHIFT;
    if (s == "ctrl") return VK_CONTROL;
    if (s == "alt") return VK_MENU;
    if (s == "tab") return VK_TAB;
    if (s == "backspace") return VK_BACK;
    if (s == "caps" || s == "capslock") return VK_CAPITAL;

    // function keys f1..f24
    if (s.size() > 1 && s[0] == 'f') {
        int n = atoi(s.c_str() + 1);

        if (n >= 1 && n <= 24)
            return VK_F1 + (n - 1);
    }

    return -1; // unknown
}

// lua wrapper for vkFromName
int lIsPressed(lua_State* L) {
    // arg1: string or number (vk)
    // arg2: optional boolean requireForeground (default true)

    int vk = -1;
    if (lua_type(L, 1) == LUA_TSTRING) {
        const char* name = luaL_checkstring(L, 1);
        vk = vkFromName(name);
    } else if (lua_type(L, 1) == LUA_TNUMBER) {
        vk = (int)luaL_checkinteger(L, 1);
    } else {
        lua_pushboolean(L, 0);
        return 1;
    }

    if (vk < 0) {
        lua_pushboolean(L, 0);
        return 1;
    }

    int requireForeground = 1;
    if (lua_gettop(L) >= 2 && lua_isboolean(L, 2))
        requireForeground = lua_toboolean(L, 2) ? 1 : 0;

    if (requireForeground) {
        if (gPid == 0) { // not started yet -> treat as not foreground
            lua_pushboolean(L, 0);
            return 1;
        }
        HWND fg = GetForegroundWindow();
        if (!fg) {
            lua_pushboolean(L, 0);
            return 1;
        }

        DWORD fgPid = 0;
        GetWindowThreadProcessId(fg, &fgPid);

        if (fgPid != gPid) {
            lua_pushboolean(L, 0);
            return 1;
        }
    }

    SHORT state = GetAsyncKeyState(vk);
    lua_pushboolean(L, (state & 0x8000) != 0);
    return 1;
}