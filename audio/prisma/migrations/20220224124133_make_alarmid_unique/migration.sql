/*
  Warnings:

  - A unique constraint covering the columns `[alarmId]` on the table `AlarmsAudios` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "AlarmsAudios_alarmId_key" ON "AlarmsAudios"("alarmId");
