@echo off
echo.
echo ============================================
echo   Building Inventory Management System
echo ============================================
echo.

SET ML=
SET LINK=
SET PATH=C:\Masm615;C:\WINDOWS;C:\WINDOWS\SYSTEM32
SET INCLUDE=C:\Masm615\INCLUDE
SET LIB=C:\Masm615\LIB

IF NOT EXIST obj mkdir obj

echo [1/7] data.asm
ML -c -coff /Fo obj\data.obj src\data.asm
IF ERRORLEVEL 1 GOTO ERR

echo [2/7] inventory.asm
ML -c -coff /Fo obj\inventory.obj src\inventory.asm
IF ERRORLEVEL 1 GOTO ERR

echo [3/7] sales.asm
ML -c -coff /Fo obj\sales.obj src\sales.asm
IF ERRORLEVEL 1 GOTO ERR

echo [4/7] menu.asm
ML -c -coff /Fo obj\menu.obj src\menu.asm
IF ERRORLEVEL 1 GOTO ERR

echo [5/7] file.asm
ML -c -coff /Fo obj\file.obj src\file.asm
IF ERRORLEVEL 1 GOTO ERR

echo [6/7] utils.asm
ML -c -coff /Fo obj\utils.obj src\utils.asm
IF ERRORLEVEL 1 GOTO ERR

echo [7/7] main.asm
ML -c -coff /Fo obj\main.obj src\main.asm
IF ERRORLEVEL 1 GOTO ERR

echo.
echo [LINK] Linking...
LINK32 obj\main.obj obj\menu.obj obj\inventory.obj obj\sales.obj obj\data.obj obj\file.obj obj\utils.obj Irvine32.lib kernel32.lib /SUBSYSTEM:CONSOLE /OUT:main.exe
IF ERRORLEVEL 1 GOTO ERR

echo.
echo ============================================
echo   BUILD SUCCESSFUL  ^>  main.exe
echo ============================================
GOTO END

:ERR
echo.
echo [FAILED] See errors above.
EXIT /B 1

:END