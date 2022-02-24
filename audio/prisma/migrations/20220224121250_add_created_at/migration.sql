-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_AudioNameMappings" (
    "audioId" TEXT NOT NULL PRIMARY KEY,
    "filename" TEXT NOT NULL,
    "friendlyName" TEXT,
    "youtubeID" TEXT,
    "duration" REAL,
    "playFrom" REAL,
    "playTo" REAL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_AudioNameMappings" ("audioId", "duration", "filename", "friendlyName", "playFrom", "playTo", "youtubeID") SELECT "audioId", "duration", "filename", "friendlyName", "playFrom", "playTo", "youtubeID" FROM "AudioNameMappings";
DROP TABLE "AudioNameMappings";
ALTER TABLE "new_AudioNameMappings" RENAME TO "AudioNameMappings";
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
