-- CreateTable
CREATE TABLE "AlarmsAudios" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "alarmId" TEXT NOT NULL,
    "audioId" TEXT NOT NULL,
    CONSTRAINT "AlarmsAudios_audioId_fkey" FOREIGN KEY ("audioId") REFERENCES "AudioNameMappings" ("audioId") ON DELETE NO ACTION ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "AudioNameMappings" (
    "audioId" TEXT NOT NULL PRIMARY KEY,
    "filename" TEXT NOT NULL,
    "friendlyName" TEXT,
    "youtubeID" TEXT,
    "duration" REAL,
    "playFrom" REAL,
    "playTo" REAL
);
