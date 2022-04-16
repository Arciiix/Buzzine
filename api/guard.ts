import express from "express";
import crypto from "crypto";
import QRCode from "qrcode";
import path from "path";
import logger from "./utils/logger";
import QRCodeModel from "./models/QRCode.model";
import QRCodeAlarmsMappingModel from "./models/QRCodesAlarmsMapping.model";
import shortUUID from "short-uuid";

const guardRouter = express.Router();

// let currentQRCodeHash = null;

// guardRouter.post("/generateQRCode", async (req, res) => {
//   let generatedHash = await generateQRCode();
//   res.send({ error: false, generatedHash });
// });
// guardRouter.get("/getCurrentQRCodeHash", async (req, res) => {
//   res.send({ error: false, currentHash: await getCurrentQRCodeHash() });
// });
// guardRouter.get("/qrCode", async (req, res) => {
//   if (!req.query.size)
//     return res.status(400).send({ error: true, errorCode: "MISSING_SIZE" });
//   if (!parseInt(req.query.size as string)) {
//     return res.status(400).send({ error: true, errorCode: "WRONG_SIZE" });
//   }

//   let hash = await getCurrentQRCodeHash();

//   res.setHeader("Content-Type", "image/png");

//   QRCode.toFileStream(res, `Buzzine/${hash}`, {
//     width: parseInt(req.query.size as string),
//   });
// });
// guardRouter.get("/checkQRCode", async (req, res) => {
//   if (!req.query.data) {
//     return res.status(400).send({ error: true, errorCode: "MISSING_DATA" });
//   }

//   return res.send({
//     error: false,
//     isVaild: await checkQRCode(req.query.data.toString()),
//   });
// });
// guardRouter.get("/printQRCode", (req, res) => {
//   res.sendFile(path.join(__dirname, "sites", "print.html"));
// });

// async function checkQRCode(qrCodeData: string): Promise<boolean> {
//   //The format of the QR code is Buzzine/hash where hash is 8 characters length
//   let regExp = /^Buzzine\/[A-Za-z0-9]{32}$/;
//   if (!regExp.test(qrCodeData)) {
//     return false;
//   }

//   let hash = qrCodeData.slice(8, 40);
//   return hash === (await getCurrentQRCodeHash());
// }

// async function generateQRCode(): Promise<string> {
//   let generatedHash = crypto.randomBytes(16).toString("hex");

//   //Remove the old QR codes
//   await QRCodeModel.destroy({ where: {} });

//   await QRCodeModel.create({
//     hash: generatedHash,
//   });
//   currentQRCodeHash = generatedHash;
//   logger.info(`[GUARD] Generated new QR code with hash ${generatedHash}`);
//   return generatedHash;
// }
// async function getCurrentQRCodeHash(): Promise<string> {
//   let hash: any = await QRCodeModel.findOne({ order: [["createdAt", "DESC"]] });
//   if (!hash) {
//     await generateQRCode();
//   } else {
//     currentQRCodeHash = hash.hash;
//     return currentQRCodeHash;
//   }
// }

guardRouter.get("/getAllQRCodes", async (req, res) => {
  res.send({
    error: false,
    qrCodes: await getAllQRCodes(req.query.includeAlarms ? true : false),
  });
});

guardRouter.get("/getAlarmsForQRCode/:name", async (req, res) => {
  if (!req.params.name) {
    return res.status(400).send({ error: true, errorCode: "MISSING_NAME" });
  }
  let alarms = await getAlarmsForQRCode(req.params.name);

  if (alarms.error) {
    res.status(404).send({ error: true, errorCode: "QRCODE_NOT_FOUND" });
  } else {
    res.status(200).send(alarms);
  }
});

guardRouter.get("/getQRCodeForAlarm/:alarmId", async (req, res) => {
  if (!req.params.alarmId) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ALARM_ID" });
  }

  let qrCode = await getQRCodeForAlarm(req.params.alarmId);

  res.send({ error: false, response: qrCode });
});

guardRouter.get("/getQRCodeByName", async (req, res) => {
  if (!req.query.name) {
    return res.status(400).send({ error: true, errorCode: "MISSING_NAME" });
  }

  let qrCode = await getQRCodeByName(req.query.name as string);

  if (qrCode.error) {
    res.status(404).send({ error: true, errorCode: "QRCODE_NOT_FOUND" });
  } else {
    res.status(200).send(qrCode);
  }
});

guardRouter.post("/generateQRCode", async (req, res) => {
  let generatedCode: IQRCode = await generateQRCode();
  res.send({ error: false, generatedCode });
});

guardRouter.get("/checkQRCode", async (req, res) => {
  if (!req.query.data) {
    return res.status(400).send({ error: true, errorCode: "MISSING_DATA" });
  }

  return res.send({
    error: false,
    isVaild: await checkQRCode(
      (req.query.name as string) ?? "default",
      req.query.data.toString()
    ),
  });
});

guardRouter.delete("/deleteQRCode", async (req, res) => {
  if (!req.body.name) {
    return res.status(400).send({ error: true, errorCode: "MISSING_NAME" });
  }
  if (req.body.name === "default") {
    return res
      .status(400)
      .send({ error: true, errorCode: "DEFAULT_QRCODE_CANNOT_BE_DELETED" });
  }

  let deleted = await deleteQRCode(req.body.name);

  res.status(deleted.statusCode).send(deleted);
});

guardRouter.get("/:name/print", async (req, res) => {
  if (!(await QRCodeModel.findOne({ where: { name: req.params.name } }))) {
    // res.status(404).send({ error: true, errorCode: "QRCODE_NOT_FOUND" });
    res.sendFile(path.join(__dirname, "sites", "404.html"));
    return;
  }
  res.sendFile(path.join(__dirname, "sites", "print.html"));
});

guardRouter.get("/:name/info", (req, res) => {
  res.redirect(`../getQRCodeByName?name=${req.params.name}`);
});

guardRouter.get("/:name/img", async (req, res) => {
  if (!req.params.name) {
    return res.status(400).send({ error: true, errorCode: "MISSING_NAME" });
  }
  if (!req.query.size)
    return res.status(400).send({ error: true, errorCode: "MISSING_SIZE" });
  if (!parseInt(req.query.size as string)) {
    return res.status(400).send({ error: true, errorCode: "WRONG_SIZE" });
  }

  let qrCode = await getQRCodeByName(req.params.name);
  //The only error is not found
  if (qrCode.error) {
    res.status(404).send({ error: true, errorCode: "QRCODE_NOT_FOUND" });
  }

  res.setHeader("Content-Type", "image/png");

  QRCode.toFileStream(res, `Buzzine/${qrCode.response.hash}`, {
    width: parseInt(req.query.size as string),
  });
});

guardRouter.put("/changeQRCodeName", async (req, res) => {
  if (!req.body.oldName) {
    return res.status(400).send({ error: true, errorCode: "MISSING_OLD_NAME" });
  }
  if (!req.body.newName) {
    return res.status(400).send({ error: true, errorCode: "MISSING_NEW_NAME" });
  }
  if (req.body.oldName === "default") {
    return res
      .status(400)
      .send({ error: true, errorCode: "DEFAULT_QRCODE_CANNOT_BE_CHANGED" });
  }
  if (req.body.newName === "default") {
    return res
      .status(400)
      .send({ error: true, errorCode: "NAME_CANNOT_BE_DEFAULT" });
  }

  let changed = await changeQRCodeName(req.body.oldName, req.body.newName);

  res.status(changed.statusCode).send(changed);
});

async function getAllQRCodes(includeAlarms: boolean): Promise<IQRCode[]> {
  let qrCodes: any = await QRCodeModel.findAll({
    order: [["createdAt", "DESC"]],
  });
  if (includeAlarms) {
    for await (const qrCode of qrCodes) {
      qrCode.alarms = await getAlarmsForQRCode(qrCode.name);
    }
  }
  return qrCodes.map((elem: any): IQRCode => {
    return {
      name: elem.name,
      hash: elem.hash,
      alarmsIds: elem.alarms,
    };
  });
}

async function getAlarmsForQRCode(
  qrCodeName: string = "default"
): Promise<{ error: boolean; response?: string[] }> {
  let alarms: any = await QRCodeAlarmsMappingModel.findAll({
    where: { name: qrCodeName },
  });
  if (!alarms) {
    return { error: true };
  }
  return { error: false, response: alarms.map((e) => e.alarmId) };
}

async function getQRCodeForAlarm(alarmId: string): Promise<IQRCode> {
  let qrCode: any = await QRCodeAlarmsMappingModel.findOne({
    where: {
      alarmId: alarmId,
    },
    include: {
      model: QRCodeModel,
    },
  });

  let qrCodeForAlarm = qrCode?.QRCode;

  if (!qrCodeForAlarm) {
    qrCodeForAlarm = await QRCodeModel.findOne({ where: { name: "default" } });
  }

  logger.info(`Got QR code for alarm ${alarmId}`);

  return {
    name: qrCodeForAlarm.name,
    hash: qrCodeForAlarm.hash,
  };
}

async function getQRCodeByName(
  name: string
): Promise<{ error: boolean; response?: IQRCode }> {
  let qrCode: any = await QRCodeModel.findOne({
    where: {
      name: name,
    },
  });
  if (!qrCode) {
    return { error: true };
  }
  return { error: false, response: { name: qrCode.name, hash: qrCode.hash } };
}

async function generateQRCode(name?: string): Promise<IQRCode> {
  let generatedHash = crypto.randomBytes(16).toString("hex");

  //If user has provided a name, check if it already exists
  if (name) {
    let qrCode: any = await QRCodeModel.findOne({ where: { name: name } });
    if (qrCode) {
      return {
        name: qrCode.name,
        hash: qrCode.hash,
      };
    }
  }

  let qrCode: any = await QRCodeModel.create({
    hash: generatedHash,
    name: name ?? shortUUID.generate(),
  });
  logger.info(
    `Generated new QR code ${qrCode.name} with hash ${generatedHash}`
  );
  return {
    name: qrCode.name,
    hash: qrCode.hash,
  };
}

async function checkQRCode(
  qrCodeName: string = "default",
  qrCodeData: string
): Promise<boolean> {
  //The format of the QR code is Buzzine/hash where hash is 8 characters length
  let regExp = /^Buzzine\/[A-Za-z0-9]{32}$/;
  if (!regExp.test(qrCodeData)) {
    return false;
  }

  let hash = qrCodeData.slice(8, 40);

  let qrCode: any = await QRCodeModel.findOne({
    where: {
      name: qrCodeName,
    },
  });

  if (!qrCode) {
    return false;
  }

  logger.info(
    `Check the QR code ${qrCodeName} with data ${qrCodeData} (valid: ${
      hash === qrCode.hash
    })`
  );

  return hash === qrCode.hash;
}

async function deleteQRCode(
  qrCodeName: string
): Promise<{ error: boolean; statusCode: number; errorCode?: string }> {
  let qrCode: any = await QRCodeModel.findOne({
    where: {
      name: qrCodeName,
    },
  });

  if (!qrCode) {
    return { error: true, errorCode: "NOT_FOUND", statusCode: 404 };
  }

  await QRCodeModel.destroy({
    where: {
      name: qrCodeName,
    },
  });

  await QRCodeAlarmsMappingModel.destroy({
    where: {
      name: qrCodeName,
    },
  });

  logger.info(`Deleted QR code ${qrCodeName}`);

  return { error: false, statusCode: 200 };
}

async function changeQRCodeName(
  oldName: string,
  newName: string
): Promise<{
  error: boolean;
  response?: IQRCode;
  errorCode?: string;
  statusCode: number;
}> {
  //Names have to be unique
  let nameCheck = await QRCodeModel.findOne({
    where: {
      name: newName,
    },
  });

  if (nameCheck) {
    return {
      error: true,
      errorCode: "NAME_ALREADY_EXISTS",
      statusCode: 409,
    };
  }

  let qrCode: any = await QRCodeModel.findOne({
    where: {
      name: oldName,
    },
  });

  if (!qrCode) {
    return { error: true, errorCode: "NOT_FOUND", statusCode: 404 };
  }

  // For some reason, this doesn't work
  // qrCode.name = newName;
  // await qrCode.save();

  await QRCodeModel.update(
    {
      name: newName,
    },
    {
      where: {
        name: oldName,
      },
    }
  );

  logger.info(`Changed QR code name ${oldName} to ${newName}`);

  return {
    error: false,
    response: { name: qrCode.name, hash: qrCode.hash },
    statusCode: 200,
  };
}

async function generateDefaultQRCodeIfDoesntExist(): Promise<void> {
  logger.info("Checking for default QR Code...");
  let qrCode: any = await QRCodeModel.findOne({
    where: {
      name: "default",
    },
  });

  if (!qrCode) {
    await generateQRCode("default");
    logger.info("Generated default QR Code");
  } else {
    logger.info("Default QR code exists");
  }
}

interface IQRCode {
  name: string;
  hash: string;
  alarmsIds?: string[];
}

export default guardRouter;
export { generateDefaultQRCodeIfDoesntExist };
