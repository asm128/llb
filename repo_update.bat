@echo off
setlocal

pushd "%~dp0" || exit /b 1
git pull --ff-only || goto :failed
call repo_init.bat --configure-only || goto :failed

popd
exit /b 0

:failed
popd
exit /b 1
