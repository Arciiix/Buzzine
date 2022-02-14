@echo off
title Buzzine - copy files to dist folders
set /p directory="Enter directory: "
pause

echo Current service: core

echo Current service: API
echo Assets (folder)
xcopy %directory%\API\assets %directory%\API\dist\assets /w /f /s /e /i
echo Sites (folder)
xcopy %directory%\API\sites %directory%\API\dist\sites /w /f /s /e /i

echo Current service: audio
mkdir %directory%\audio\dist\audio
echo Emergency.wav (file)
xcopy %directory%\audio\emergency.wav %directory%\audio\dist\emergency.wav /w /f /s /e /i

echo Current service: adapter

pause
