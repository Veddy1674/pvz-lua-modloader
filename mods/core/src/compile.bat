@echo off
setlocal

REM open x86 Native Tools Command Prompt VS 2022
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"

set FILES=mem.cpp asm.cpp eventhandler.cpp breakpoint.cpp
set OBJS=mem.obj asm.obj eventhandler.obj breakpoint.obj

REM compile cpp files
cl /nologo /O2 /LD /MD /W3 /EHsc /c %FILES% /I "C:\Lua54\include"

link /nologo /DLL /out:mem.dll /implib:mem.lib %OBJS% "C:\Lua54\lua54.lib" user32.lib

REM cleanup (if exists X del X)
del %OBJS% 2>nul

del mem.exp mem.lib 2>nul

echo - Compiled into mem.dll successfully.
pause