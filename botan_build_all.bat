@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: 编码设置
:: ============================================================
chcp 65001 >nul
set PYTHONUTF8=1

:: ============================================================
:: 配置区
:: ============================================================
set "VCVARSALL=D:\VS2022BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
if not exist "%VCVARSALL%" (
    set "VCVARSALL=D:\VisualStudio2022BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
)

:: 检查 vcvarsall.bat 是否存在
if not exist "%VCVARSALL%" (
    echo [ERROR] 找不到 vcvarsall.bat
    echo 路径: %VCVARSALL%
    pause
    exit /b 1
)

:: ============================================================
:: 第一轮：x86 编译
:: ============================================================
echo.
echo ================================================================
echo   [1/2] 编译 x86（x64_x86 Cross Tools）
echo ================================================================
echo.

:: 用 cmd /k 的方式不行，需要直接 call
:: 每次调用 vcvarsall 前最好重置环境，用 setlocal/endlocal 隔离
call :BUILD_X86
if errorlevel 1 (
    echo [FAILED] x86 编译失败！
    pause
    exit /b 1
)

:: ============================================================
:: 第二轮：x64 编译
:: ============================================================
echo.
echo ================================================================
echo   [2/2] 编译 x64（x64 Native Tools）
echo ================================================================
echo.

call :BUILD_X64
if errorlevel 1 (
    echo [FAILED] x64 编译失败！
    pause
    exit /b 1
)

:: ============================================================
echo.
echo ================================================================
echo   全部编译完成！
echo   x86 输出: %~dp0install_x86
echo   x64 输出: %~dp0install_x64
echo ================================================================
pause
exit /b 0


:: ============================================================
:: 子过程：编译 x86
:: ============================================================
:BUILD_X86
setlocal

:: 设置 x64_x86 交叉编译环境
call "%VCVARSALL%" x64_x86
if errorlevel 1 exit /b 1

:: 进入脚本所在目录
cd /d "%~dp0"

:: 删除 build 文件夹
rmdir /s /q "%~dp0build"

echo [x86] 运行 configure...
py configure.py --cpu x86_32 --build-tool ninja --enable-static-library --disable-shared-library --msvc-runtime=MT ^
 --prefix "%~dp0install_x86" --extra-cxxflags "/GL"
if errorlevel 1 exit /b 1

echo [x86] 运行 ninja...
ninja
if errorlevel 1 exit /b 1

echo [x86] 运行 ninja install...
ninja install
if errorlevel 1 exit /b 1

if exist "%~dp0build\include\internal" (
    xcopy /E /I /Y "%~dp0build\include\internal" "%~dp0install_x86\include\botan-3" >nul
)

echo [x86] 完成！
endlocal
exit /b 0


:: ============================================================
:: 子过程：编译 x64
:: ============================================================
:BUILD_X64
setlocal

:: 设置 x64 原生编译环境
call "%VCVARSALL%" x64
if errorlevel 1 exit /b 1

cd /d "%~dp0"

:: 删除 build 文件夹
rmdir /s /q "%~dp0build"

echo [x64] 运行 configure...
py configure.py --cpu x86_64 --build-tool ninja --enable-static-library --disable-shared-library --msvc-runtime=MT ^
 --prefix "%~dp0install_x64" --extra-cxxflags "/GL"
if errorlevel 1 exit /b 1

echo [x64] 运行 ninja...
ninja
if errorlevel 1 exit /b 1

echo [x64] 运行 ninja install...
ninja install
if errorlevel 1 exit /b 1

if exist "%~dp0build\include\internal" (
    xcopy /E /I /Y "%~dp0build\include\internal" "%~dp0install_x64\include\botan-3" >nul
)

echo [x64] 完成！
endlocal
exit /b 0
