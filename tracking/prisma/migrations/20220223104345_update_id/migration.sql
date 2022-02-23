/*
  Warnings:

  - The primary key for the `TrackingEntry` table will be changed. If it partially fails, the table could be left without primary key constraint.

*/
-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_TrackingEntry" (
    "id" TEXT NOT NULL,
    "day" DATETIME NOT NULL PRIMARY KEY,
    "bedTime" DATETIME,
    "sleepTime" DATETIME,
    "firstAlarmTime" DATETIME,
    "wakeupTime" DATETIME,
    "getUpTime" DATETIME
);
INSERT INTO "new_TrackingEntry" ("bedTime", "day", "firstAlarmTime", "getUpTime", "id", "sleepTime", "wakeupTime") SELECT "bedTime", "day", "firstAlarmTime", "getUpTime", "id", "sleepTime", "wakeupTime" FROM "TrackingEntry";
DROP TABLE "TrackingEntry";
ALTER TABLE "new_TrackingEntry" RENAME TO "TrackingEntry";
CREATE UNIQUE INDEX "TrackingEntry_day_key" ON "TrackingEntry"("day");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
