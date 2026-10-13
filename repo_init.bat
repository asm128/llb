@echo off
setlocal

pushd "%~dp0" || exit /b 1
git submodule sync --recursive || goto :failed
git submodule update --init --recursive || goto :failed

for /f "tokens=2" %%P in ('git config -f .gitmodules --get-regexp "^submodule\..*\.path$"') do (
	call :configure "%%P"
	if errorlevel 1 goto :failed
)

if /I "%~1"=="--configure-only" goto :done
start "" "llc\llc.sln"

:done
popd
exit /b 0

:configure
if not exist "%~1\repo_init.bat" exit /b 0
call "%~1\repo_init.bat" --configure-only
exit /b %errorlevel%

:failed
popd
exit /b 1
