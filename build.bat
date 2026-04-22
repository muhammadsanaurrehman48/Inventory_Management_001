@echo off
cls

SET MASM=C:\Masm615
SET PATH=%MASM%\BIN;%PATH%
SET INCLUDE=%MASM%\INCLUDE;D:\Subjects Semster 4\COAL\Project\include
SET LIB=%MASM%\LIB

cd /d "D:\Subjects Semster 4\COAL\Project"

REM ✅ Create obj folder if missing
if not exist obj mkdir obj

echo ============================
echo Cleaning old files...
echo ============================
del obj\*.obj >nul 2>&1

echo ============================
echo Assembling...
echo ============================

pushd obj
ml /c /coff ..\src\main.asm || popd && goto error
ml /c /coff ..\src\inventory.asm || popd && goto error
ml /c /coff ..\src\menu.asm || popd && goto error
ml /c /coff ..\src\sales.asm || popd && goto error
ml /c /coff ..\src\utils.asm || popd && goto error
ml /c /coff ..\src\data.asm || popd && goto error
ml /c /coff ..\src\file.asm || popd && goto error
popd

echo ============================
echo Linking...
echo ============================

link /subsystem:console ^
obj\main.obj ^
obj\inventory.obj ^
obj\menu.obj ^
obj\sales.obj ^
obj\utils.obj ^
obj\data.obj ^
obj\file.obj ^
Irvine32.lib kernel32.lib || goto error

echo ============================
echo Running...
echo ============================

main.exe

goto end

:error
echo.
echo ❌ Build failed
pause

:end
pause