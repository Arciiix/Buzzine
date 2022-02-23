-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_TrackingVersionHistory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "day" DATETIME NOT NULL,
    "fieldName" TEXT NOT NULL,
    "value" DATETIME NOT NULL,
    CONSTRAINT "TrackingVersionHistory_day_fkey" FOREIGN KEY ("day") REFERENCES "TrackingEntry" ("day") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_TrackingVersionHistory" ("day", "fieldName", "id", "value") SELECT "day", "fieldName", "id", "value" FROM "TrackingVersionHistory";
DROP TABLE "TrackingVersionHistory";
ALTER TABLE "new_TrackingVersionHistory" RENAME TO "TrackingVersionHistory";
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
