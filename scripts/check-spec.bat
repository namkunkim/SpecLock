@echo off
setlocal

REM ============================================================
REM  BR <-> @Spec 정합성 검사 (Windows)
REM
REM  사용법:
REM    check-spec.bat
REM    check-spec.bat spec\uc app\src\test
REM
REM  종료 코드: 0 정합 / 1 불일치 / 2 경로 오류
REM
REM  실제 로직은 check-spec.ps1 에 있다.
REM  순수 배치로 구현하지 않은 이유는 findstr에 grep -o 에 해당하는
REM  기능이 없어 정규식으로 매치된 부분만 추출할 수 없기 때문이다.
REM  ID 추출이 핵심인 작업이라 PowerShell 이 적합하다.
REM ============================================================

set "SPEC_DIR=%~1"
set "TEST_DIR=%~2"

if "%SPEC_DIR%"=="" set "SPEC_DIR=docs/spec/uc"
if "%TEST_DIR%"=="" set "TEST_DIR=src/test"

where powershell >nul 2>&1
if errorlevel 1 (
    echo PowerShell 을 찾을 수 없습니다.
    echo Windows 7 이상이면 기본 포함되어 있습니다. PATH 를 확인하세요.
    exit /b 2
)

powershell -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0check-spec.ps1" ^
    -SpecDir "%SPEC_DIR%" -TestDir "%TEST_DIR%"

set "RESULT=%ERRORLEVEL%"

REM 더블클릭으로 실행한 경우 결과를 볼 수 있게 창을 유지한다.
REM (%CMDCMDLINE% 에 /c 가 있으면 탐색기에서 실행된 것)
echo %CMDCMDLINE% | findstr /I /C:"/c" >nul
if not errorlevel 1 (
    echo.
    pause
)

exit /b %RESULT%
