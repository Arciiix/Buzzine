import express from "express";
import crypto from "crypto";
import QRCode from "qrcode";
import path from "path";
import logger from "./utils/logger";
import QRCodeModel from "./models/QRCode.model";

const guardRouter = express.Router();

let currentQRCodeHash = null;

guardRouter.post("/generateQRCode", async (req, res) => {
  let generatedHash = await generateQRCode();
  res.send({ error: false, generatedHash });
});
guardRouter.get("/getCurrentQRCodeHash", async (req, res) => {
  res.send({ error: false, currentHash: await getCurrentQRCodeHash() });
});
guardRouter.get("/qrCode", async (req, res) => {
  if (!req.query.size)
    return res.status(400).send({ error: true, errorCode: "MISSING_SIZE" });
  if (!parseInt(req.query.size as string)) {
    return res.status(400).send({ error: true, errorCode: "WRONG_SIZE" });
  }

  let hash = await getCurrentQRCodeHash();

  res.setHeader("Content-Type", "image/png");

  QRCode.toFileStream(res, `Buzzine/${hash}`, {
    width: parseInt(req.query.size as string),
  });
});
guardRouter.get("/checkQRCode", async (req, res) => {
  if (!req.query.data) {
    return res.status(400).send({ error: true, errorCode: "MISSING_DATA" });
  }

  return res.send({
    error: false,
    isVaild: await checkQRCode(req.query.data.toString()),
  });
});
guardRouter.get("/printQRCode", (req, res) => {
  res.sendFile(path.join(__dirname, "sites", "print.html"));
});

async function checkQRCode(qrCodeData: string): Promise<boolean> {
  //The format of the QR code is Buzzine/hash where hash is 8 characters length
  let regExp = /^Buzzine\/[A-Za-z0-9]{32}$/;
  if (!regExp.test(qrCodeData)) {
    return false;
  }

  let hash = qrCodeData.slice(8, 40);
  return hash === (await getCurrentQRCodeHash());
}

async function generateQRCode(): Promise<string> {
  let generatedHash = crypto.randomBytes(16).toString("hex");

  //Remove the old QR codes
  await QRCodeModel.destroy({ where: {} });

  await QRCodeModel.create({
    hash: generatedHash,
  });
  currentQRCodeHash = generatedHash;
  logger.info(`[GUARD] Generated new QR code with hash ${generatedHash}`);
  return generatedHash;
}
async function getCurrentQRCodeHash(): Promise<string> {
  let hash: any = await QRCodeModel.findOne({ order: [["createdAt", "DESC"]] });
  if (!hash) {
    await generateQRCode();
  } else {
    currentQRCodeHash = hash.hash;
    return currentQRCodeHash;
  }
}

export default guardRouter;
export { checkQRCode, generateQRCode, getCurrentQRCodeHash };
