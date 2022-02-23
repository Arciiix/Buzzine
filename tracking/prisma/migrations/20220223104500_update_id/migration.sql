/*
  Warnings:

  - You are about to drop the column `id` on the `TrackingEntry` table. All the data in the column will be lost.

*/
-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_TrackingEntry" (
    "day" DATETIME NOT NULL PRIMARY KEY,
    "bedTime" DATETIME,
    "sleepTime" DATETIME,
    "firstAlarmTime" DATETIME,
    "wakeupTime" DATETIME,
    "getUpTime" DATETIME
);
INSERT INTO "new_TrackingEntry" ("bedTime", "day", "firstAlarmTime", "getUpTime", "sleepTime", "wakeupTime") SELECT "bedTime", "day", "firstAlarmTime", "getUpTime", "sleepTime", "wakeupTime" FROM "TrackingEntry";
DROP TABLE "TrackingEntry";
ALTER TABLE "new_TrackingEntry" RENAME TO "TrackingEntry";
CREATE UNIQUE INDEX "TrackingEntry_day_key" ON "TrackingEntry"("day");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
