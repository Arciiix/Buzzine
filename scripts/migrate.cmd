@echo off
title Buzzine - migrate to new version (update)
set /p old="Enter old directory: "
set /p new="Enter new directory: "

pause

echo Current service: core
echo Database (file)
xcopy %old%\core\dist\buzzine.db %new%\core\dist\buzzine.db /w /f /s /e /i
echo ENV (file)
xcopy %old%\core\dist\.env* %new%\core\dist\.env* /w /f /s /e /i

echo Current service: API
echo Database (file)
xcopy %old%\API\dist\buzzineAPI.db %new%\API\dist\buzzineAPI.db /w /f /s /e /i
echo Assets (folder)
xcopy %old%\API\dist\assets %new%\API\dist\assets /w /f /s /e /i
echo Sites (folder)
xcopy %old%\API\dist\sites %new%\API\dist\sites /w /f /s /e /i
echo ENV (file)
xcopy %old%\API\dist\.env* %new%\API\dist\.env* /w /f /s /e /i
echo Firebase service account key (file)
xcopy %old%\API\dist\firebaseServiceAccountKey.json %new%\API\dist\firebaseServiceAccountKey.json /w /f /s /e /i

echo Current service: audio
echo Database (file)
xcopy %old%\audio\dist\buzzineAudio.db %new%\audio\dist\buzzineAudio.db /w /f /s /e /i
echo Audio (folder)
xcopy %old%\audio\dist\audio %new%\audio\dist\audio /w /f /s /e /i
echo Emergency.wav (file)
xcopy %old%\audio\dist\emergency.wav %new%\audio\dist\emergency.wav /w /f /s /e /i
echo ENV (file)
xcopy %old%\audio\dist\.env* %new%\audio\dist\.env* /w /f /s /e /i

echo Current service: adapter
echo ENV (file)
xcopy %old%\adapter\dist\.env* %new%\adapter\dist\.env* /w /f /s /e /i
echo Database (file)
xcopy %old%\adapter\dist\buzzineAdapter.db %new%\adapter\dist\buzzineAdapter.db /w /f /s /e /i

echo Current service: tracking
echo ENV (file)
xcopy %old%\tracking\dist\.env* %new%\tracking\dist\.env* /w /f /s /e /i
echo Database (file)
xcopy %old%\tracking\dist\buzzineTracking.db %new%\tracking\dist\buzzineTracking.db /w /f /s /e /i

pause
