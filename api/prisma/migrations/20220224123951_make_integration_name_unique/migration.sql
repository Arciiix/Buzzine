/*
  Warnings:

  - The primary key for the `IntegrationStatuses` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `id` on the `IntegrationStatuses` table. All the data in the column will be lost.

*/
-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_IntegrationStatuses" (
    "name" TEXT NOT NULL PRIMARY KEY,
    "isActive" BOOLEAN NOT NULL DEFAULT false,
    "config" TEXT NOT NULL
);
INSERT INTO "new_IntegrationStatuses" ("config", "isActive", "name") SELECT "config", "isActive", "name" FROM "IntegrationStatuses";
DROP TABLE "IntegrationStatuses";
ALTER TABLE "new_IntegrationStatuses" RENAME TO "IntegrationStatuses";
CREATE UNIQUE INDEX "IntegrationStatuses_name_key" ON "IntegrationStatuses"("name");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
