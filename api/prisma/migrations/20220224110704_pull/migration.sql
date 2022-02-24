-- CreateTable
CREATE TABLE "FirebaseNotificationTokens" (
    "token" TEXT NOT NULL PRIMARY KEY
);

-- CreateTable
CREATE TABLE "IntegrationStatuses" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT false,
    "config" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "QRCodes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "hash" TEXT NOT NULL
);
