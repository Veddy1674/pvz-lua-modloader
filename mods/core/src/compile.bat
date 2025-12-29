@echo off
setlocal

REM open x86 Native Tools Command Prompt VS 2022
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"

REM compile both cpp files
cl /nologo /O2 /LD /MD /W3 /EHsc /c mem.cpp asm.cpp eventhandler.cpp /I "C:\Lua54\include"

link /nologo /DLL /out:mem.dll /implib:mem.lib mem.obj asm.obj eventhandler.obj "C:\Lua54\lua54.lib" user32.lib

REM cleanup
if exist mem.obj del mem.obj
if exist asm.obj del asm.obj
if exist eventhandler.obj del eventhandler.obj
if exist mem.exp del mem.exp
if exist mem.lib del mem.lib

echo - Compiled into mem.dll successfully.
echo.
echo Done.
pause