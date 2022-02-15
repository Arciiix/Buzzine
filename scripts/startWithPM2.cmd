@echo off
title Buzzine - start with PM2

cd ..

echo Starting core...
cd core
cd dist
call pm2 start index.js --name buzzine-core

cd ..
cd ..
echo Starting API...
cd api
cd dist
call pm2 start index.js --name buzzine-api

cd ..
cd ..
echo Starting audio...
cd audio
cd dist
call pm2 start index.js --name buzzine-audio

cd ..
cd ..
echo Starting adapter...
cd adapter
cd dist
call pm2 start index.js --name buzzine-adapter

echo Saving...
call pm2 save

pause
