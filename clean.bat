@echo off
setlocal

pushd "%~dp0" || exit /b 1
set "directories=.\obj .\x64.Debug .\x64.Release .\x64.Debug-MT .\x64.Release-MT .\Win32.Debug .\Win32.Release .\Win32.Debug-MT .\Win32.Release-MT .\.vs"

for %%D in (%directories%) do (
	if exist "%%~D" rd /s /q "%%~D"
)

for /f "tokens=2" %%P in ('git config -f .gitmodules --get-regexp "^submodule\..*\.path$"') do (
	if exist "%%P\.vs" rd /s /q "%%P\.vs"
)

popd
exit /b 0
