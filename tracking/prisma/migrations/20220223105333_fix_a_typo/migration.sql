/*
  Warnings:

  - You are about to drop the column `wakeupTime` on the `TrackingEntry` table. All the data in the column will be lost.

*/
-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_TrackingEntry" (
    "day" DATETIME NOT NULL PRIMARY KEY,
    "bedTime" DATETIME,
    "sleepTime" DATETIME,
    "firstAlarmTime" DATETIME,
    "wakeUpTime" DATETIME,
    "getUpTime" DATETIME
);
INSERT INTO "new_TrackingEntry" ("bedTime", "day", "firstAlarmTime", "getUpTime", "sleepTime") SELECT "bedTime", "day", "firstAlarmTime", "getUpTime", "sleepTime" FROM "TrackingEntry";
DROP TABLE "TrackingEntry";
ALTER TABLE "new_TrackingEntry" RENAME TO "TrackingEntry";
CREATE UNIQUE INDEX "TrackingEntry_day_key" ON "TrackingEntry"("day");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
