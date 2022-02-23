-- CreateTable
CREATE TABLE "TrackingVersionHistory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "day" DATETIME NOT NULL,
    "fieldName" TEXT NOT NULL,
    "value" DATETIME NOT NULL,
    CONSTRAINT "TrackingVersionHistory_day_fkey" FOREIGN KEY ("day") REFERENCES "TrackingEntry" ("day") ON DELETE RESTRICT ON UPDATE CASCADE
);
