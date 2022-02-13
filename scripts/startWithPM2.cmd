@echo off
title Buzzine - start with PM2

cd ..

echo Starting core...
cd core
cd dist
pm2 start index.js --name buzzine-core

echo Starting API...
cd API
cd dist
pm2 start index.js --name buzzine-api

echo Starting audio...
cd audio
cd dist
pm2 start index.js --name buzzine-audio

echo Saving...
pm2 save

pause
