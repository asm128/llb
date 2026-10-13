@echo off
setlocal

pushd "%~dp0" || exit /b 1
call repo_init.bat --configure-only || goto :failed

for /f "tokens=2" %%P in ('git config -f .gitmodules --get-regexp "^submodule\..*\.path$"') do (
	git -C "%%P" checkout master
	if errorlevel 1 goto :failed
	git -C "%%P" pull --ff-only
	if errorlevel 1 goto :failed
	if exist "%%P\repo_init.bat" (
		call "%%P\repo_init.bat" --configure-only
		if errorlevel 1 goto :failed
	)
)

:done
popd
exit /b 0

:failed
popd
exit /b 1
