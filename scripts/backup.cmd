@echo off
title Buzzine - backup

cd ..

set backupDir=%CD%\backups\%date%

echo %backupDir%

mkdir %backupDir%

echo Current service: core
echo Database (file)
xcopy %CD%\core\dist\buzzine.db %backupDir%\core\ /s /q /y /f 
echo ENV (file)
xcopy %CD%\core\dist\.env %backupDir%\core\ /s /q /y /f 

echo Current service: API
echo Database (file)
xcopy %CD%\API\dist\buzzineAPI.db %backupDir%\API\ /s /q /y /f 
echo ENV (file)
xcopy %CD%\API\dist\.env %backupDir%\API\ /s /q /y /f 
echo Firebase service account key (file)
xcopy %CD%\API\dist\firebaseServiceAccountKey.json %backupDir%\API\ /s /q /y /f 

echo Current service: audio
echo Database (file)
xcopy %CD%\audio\dist\buzzineAudio.db %backupDir%\audio\ /s /q /y /f 
echo ENV (file)
xcopy %CD%\audio\dist\.env %backupDir%\audio\ /s /q /y /f 

echo Current service: adapter
echo ENV (file)
xcopy %CD%\adapter\dist\.env %backupDir%\adapter\ /s /q /y /f 
echo Database (file)
xcopy %CD%\adapter\dist\buzzineAdapter.db %backupDir%\adapter\ /s /q /y /f 

echo Current service: tracking
echo ENV (file)
xcopy %CD%\tracking\dist\.env %backupDir%\tracking\ /s /q /y /f 
echo Database (file)
xcopy %CD%\tracking\dist\buzzineTracking.db %backupDir%\tracking\ /s /q /y /f 

pause
