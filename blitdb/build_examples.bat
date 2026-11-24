@echo off
setlocal
set "BLITTER_KEY=MjAwOS0yMDE5IChjKSBUaGUgRHJhZ29u"
pushd "%~dp0" || exit /b 1

reason.exe website.json 0
if errorlevel 1 goto :failed

for %%F in (user publisher company ads ad_category ad_subcategory barrios) do (
	season.exe "%%F.json" 128 1 "%BLITTER_KEY%"
	if errorlevel 1 goto :failed
)

popd
exit /b 0

:failed
set "BLITTER_RESULT=%ERRORLEVEL%"
popd
exit /b %BLITTER_RESULT%
