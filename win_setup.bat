@echo off
setlocal

set "TARGET=%APPDATA%\mpv"
set "BACKUP=%APPDATA%\mpv.bak"

echo Target directory: %TARGET%

REM Backup existing configuration if present
if exist "%TARGET%" (
    echo Existing mpv configuration found.

    REM Remove previous backup if it exists
    if exist "%BACKUP%" (
        echo Removing previous backup...
        rmdir /S /Q "%BACKUP%"
    )

    echo Creating backup...
    move "%TARGET%" "%BACKUP%"
)

REM Create a fresh mpv directory
mkdir "%TARGET%"

echo Copying shaders...
xcopy "shaders" "%TARGET%\shaders" /E /I /Y >nul

echo Copying scripts...
xcopy "scripts" "%TARGET%\scripts" /E /I /Y >nul

echo Copying mpv.conf...
copy /Y "conf\windows\mpv.conf" "%TARGET%\mpv.conf" >nul

echo Copying input.conf...
copy /Y "conf\windows\input.conf" "%TARGET%\input.conf" >nul

echo.
echo Installation completed successfully.
echo Installed to: %TARGET%

if exist "%BACKUP%" (
    echo Backup saved to: %BACKUP%
)

pause