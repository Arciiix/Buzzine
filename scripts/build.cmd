@echo off
title Buzzine - build

cd ..
cd core
echo Core - installing packages...
call npm install
echo Core - building...
call npm run build

cd ..
cd api
echo API - installing packages...
call npm install
echo API - building...
call npm run build

cd ..
cd audio
echo Audio - installing packages...
call npm install
echo Audio - building...
call npm run build

cd ..
cd adapter
echo Adapter - installing packages...
call npm install
echo Adapter - building...
call npm run build

cd ..
cd tracking
echo Tracking - installing packages...
call npm install
echo Tracking - building...
call npm run build

pause
