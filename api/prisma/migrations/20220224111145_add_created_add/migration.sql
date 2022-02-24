-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_QRCodes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "hash" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_QRCodes" ("hash", "id") SELECT "hash", "id" FROM "QRCodes";
DROP TABLE "QRCodes";
ALTER TABLE "new_QRCodes" RENAME TO "QRCodes";
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
