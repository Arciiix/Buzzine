/*
  Warnings:

  - You are about to drop the column `day` on the `TrackingVersionHistory` table. All the data in the column will be lost.
  - The primary key for the `TrackingEntry` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `day` on the `TrackingEntry` table. All the data in the column will be lost.
  - Added the required column `date` to the `TrackingVersionHistory` table without a default value. This is not possible if the table is not empty.
  - Added the required column `date` to the `TrackingEntry` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_TrackingVersionHistory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date" DATETIME NOT NULL,
    "fieldName" TEXT NOT NULL,
    "value" DATETIME NOT NULL,
    CONSTRAINT "TrackingVersionHistory_date_fkey" FOREIGN KEY ("date") REFERENCES "TrackingEntry" ("date") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_TrackingVersionHistory" ("fieldName", "id", "timestamp", "value") SELECT "fieldName", "id", "timestamp", "value" FROM "TrackingVersionHistory";
DROP TABLE "TrackingVersionHistory";
ALTER TABLE "new_TrackingVersionHistory" RENAME TO "TrackingVersionHistory";
CREATE TABLE "new_TrackingEntry" (
    "date" DATETIME NOT NULL PRIMARY KEY,
    "bedTime" DATETIME,
    "sleepTime" DATETIME,
    "firstAlarmTime" DATETIME,
    "wakeUpTime" DATETIME,
    "getUpTime" DATETIME,
    "rate" INTEGER
);
INSERT INTO "new_TrackingEntry" ("bedTime", "firstAlarmTime", "getUpTime", "rate", "sleepTime", "wakeUpTime") SELECT "bedTime", "firstAlarmTime", "getUpTime", "rate", "sleepTime", "wakeUpTime" FROM "TrackingEntry";
DROP TABLE "TrackingEntry";
ALTER TABLE "new_TrackingEntry" RENAME TO "TrackingEntry";
CREATE UNIQUE INDEX "TrackingEntry_date_key" ON "TrackingEntry"("date");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
