-- CreateTable
CREATE TABLE "TrackingEntry" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "fromDay" DATETIME NOT NULL,
    "toDay" DATETIME NOT NULL,
    "bedTime" DATETIME NOT NULL,
    "sleepTime" DATETIME NOT NULL,
    "firstAlarmTime" DATETIME NOT NULL,
    "wakeupTime" DATETIME NOT NULL,
    "getUpTime" DATETIME NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "TrackingEntry_id_key" ON "TrackingEntry"("id");
