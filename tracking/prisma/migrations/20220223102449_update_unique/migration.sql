/*
  Warnings:

  - A unique constraint covering the columns `[day]` on the table `TrackingEntry` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "TrackingEntry_day_key" ON "TrackingEntry"("day");
