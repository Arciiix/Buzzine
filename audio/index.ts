import socketioClient from "socket.io-client";
import express from "express";
import bodyParser from "body-parser";
import dotenv from "dotenv";
import logger from "./utils/logger";
import { initDatabase } from "./utils/db";
import PlaySound, {
  changeAlarmSound,
  deleteSound,
  getAlarmAudio,
} from "./utils/playAudio";
import fs from "fs";
import AudioNameMappingModel from "./models/AudioNameMapping";
import AlarmsAudioModel from "./models/AlarmsAudio";
import { downloadFromYouTube } from "./utils/YouTubeDownloader";

//Load environment variables from file
dotenv.config();

const io = socketioClient(process.env.CORE_URL || "http://localhost:3333"); //DEV TODO: Change the default CORE_URL
const app = express();
const PORT = process.env.PORT || 7777;

app.use(bodyParser.json());

let audioInstance: PlaySound;
let emergencyInstance: PlaySound;
let audioPreviewInstance: PlaySound;
let audioPreviewTimeout: ReturnType<typeof setTimeout>;

//Socket events

io.on("connect", () => {
  logger.info(
    `Connection with core has been established. Waiting for the initial message...`
  );
});

io.on("hello", () => {
  logger.info(`Connected to the core successfully`);
});

io.on("ALARM_RINGING", async (data) => {
  if (!audioInstance) {
    let audioFilename = await getAlarmAudio(data?.id);
    audioInstance = new PlaySound(audioFilename);
  } else {
    logger.info(`Skipping playing audio since the audio is playing already...`);
  }
});

io.on("EMERGENCY_ALARM", async (data) => {
  if (!emergencyInstance) {
    logger.info("EMERGENCY");
    emergencyInstance = new PlaySound("../emergency.wav");
  } else {
    logger.info(
      `Skipping playing the emergency audio since the audio is playing already...`
    );
  }
});

io.on("ALARM_MUTE", (data) => {
  if (!audioInstance) {
    logger.warn(
      `Trying to mute audio, but it doesn't exist. Alarm id: ${data.id}`
    );
    return;
  }
  audioInstance.destroy();
  audioInstance = null;
});

app.get("/", async (req, res) => {
  res.send({
    error: false,
    currentAPIVersion: "v1",
    totalSounds: await AudioNameMappingModel.count(),
  });
});

//API endpoints
const api = express.Router();
app.use("/v1", api);

api.get("/getSoundList", async (req, res) => {
  logger.http("GET /getSoundList");

  let soundList = await AudioNameMappingModel.findAll();
  res.send({ error: false, data: soundList });
});

api.get("/getAlarmSoundList", async (req, res) => {
  logger.http("GET /getAlarmSoundList");

  let soundList = await AlarmsAudioModel.findAll({
    include: AudioNameMappingModel,
  });
  res.send({ error: false, data: soundList });
});

api.post("/addYouTubeSound", (req, res) => {
  logger.http(`POST /addYouTubeSound with data ${JSON.stringify(req.body)}`);

  if (!req.body.url) {
    return res.status(400).send({ error: true, errorCode: "MISSING_URL" });
  }

  downloadFromYouTube(req.body.url);
  res.send({ error: false, message: "STARTED_DOWNLOADING" });
});

api.put("/changeAlarmSound", async (req, res) => {
  logger.http(`PUT /changeAlarmSound with data ${JSON.stringify(req.body)}`);

  if (!req.body.alarmId) {
    res.send({ error: true, errorCode: "MISSING_ALARMID" });
    return;
  }
  if (!req.body.audioFilename) {
    res.send({ error: true, errorCode: "MISSING_AUDIOFILENAME" });
    return;
  }

  let changeSoundResult = await changeAlarmSound(
    req.body.alarmId,
    req.body.audioFilename
  );
  if (!changeSoundResult) {
    res.status(400).send({ error: true });
  } else {
    res.send({ error: false, alarm: changeSoundResult });
  }
});

api.delete("/clearAlarmCustomSound", async (req, res) => {
  logger.http(
    `DELETE /clearAlarmCustomSound with data ${JSON.stringify(req.body)}`
  );

  if (!req.body.alarmId) {
    res.send({ error: true, errorCode: "MISSING_ALARMID" });
    return;
  }

  let changeSoundResult = await changeAlarmSound(req.body.alarmId);
  if (!changeSoundResult) {
    res.status(400).send({ error: true });
  } else {
    res.send({ error: false, alarm: changeSoundResult });
  }
});

api.delete("/deleteSound", async (req, res) => {
  logger.http(`DELETE /deleteSound with data ${JSON.stringify(req.body)}`);

  if (!req.body.filename) {
    res.status(400).send({ error: true, errorCode: "MISSING_FILENAME" });
    return;
  }

  let deleteSoundResult = await deleteSound(req.body.filename);
  if (!deleteSoundResult.error) {
    res.send({ error: false });
  } else {
    res.status(500).send(deleteSoundResult);
  }
});

api.put("/tempMuteAudio", async (req, res) => {
  logger.http(`PUT /tempMuteAudio with data ${JSON.stringify(req.body)}`);

  if (!req.body.duration) {
    res.status(400).send({ error: true, errorCode: "MISSING_DURATION" });
    logger.warn(`Tried to temp-mute audio but duration is missing`);
    return;
  }
  let duration = parseInt(req.body.duration);

  if (isNaN(duration)) {
    res.status(400).send({ error: true, errorCode: "WRONG_DURATION" });
    logger.warn(`Tried to temp-mute audio but duration is wrong`);
    return;
  }
  if (!audioInstance) {
    res.status(400).send({ error: true, errorCode: "NO_AUDIO_IS_PLAYING" });
    logger.warn(`Tried to temp-mute audio but no audio is playing`);
    return;
  }

  let tempMuteResult = audioInstance.tempMute(duration);

  if (tempMuteResult.error) {
    res.status(400);
  } else {
    res.status(200);
  }

  res.send(tempMuteResult);
});

api.get("/previewAudio", async (req, res) => {
  logger.http(`GET /previewAudio with data ${JSON.stringify(req.query)}`);

  if (!req.query.filename) {
    res.status(400).send({ error: true, errorCode: "MISSING_FILENAME" });
    logger.warn("Tried to preview an audio but didn't specify the filename");
    return;
  }

  if (
    !req.query.duration ||
    isNaN(parseInt(req.query.duration as string)) ||
    parseInt(req.query.duration as string) < 1
  ) {
    res.status(400).send({ error: true, errorCode: "MISSING_DURATION" });
    logger.warn(
      `Tried to preview an audio but didn't specify/specified wrong duration: ${req.query.duration}`
    );
    return;
  }

  let audioInstance = await AudioNameMappingModel.findOne({
    where: { filename: req.query.filename },
  });

  if (!audioInstance) {
    res.status(400).send({ error: true, errorCode: "WRONG_FILENAME" });
    logger.warn(`Tried to preview an unexisting audio ${req.query.filename}`);
    return;
  }

  if (audioPreviewTimeout) {
    clearTimeout(audioPreviewTimeout);
    audioPreviewTimeout = null;
  }
  if (audioPreviewInstance) {
    audioPreviewInstance.destroy();
    audioPreviewInstance = null;
  }

  audioPreviewInstance = new PlaySound(req.query.filename as string);
  audioPreviewTimeout = setTimeout(() => {
    audioPreviewInstance.destroy();
    audioPreviewInstance = null;
    logger.info("Stopped the preview audio playback because of timeout");
  }, parseInt(req.query.duration as string) * 1000);

  logger.info(
    `Playing a preview of file ${req.query.filename} for duration: ${parseInt(
      req.query.duration as string
    )}s`
  );
  res.send({ error: false, duration: parseInt(req.query.duration as string) });
});

api.put("/stopAudioPreview", (req, res) => {
  logger.http(`PUT /stopAudioPreview with data ${JSON.stringify(req.body)}`);

  if (audioPreviewTimeout) {
    clearTimeout(audioPreviewTimeout);
    audioPreviewTimeout = null;
  }

  if (audioPreviewInstance) {
    audioPreviewInstance.destroy();
    audioPreviewInstance = null;
  }

  logger.info("User has stopped the preview audio playback");

  res.send({ error: false });
});

async function init() {
  if (!fs.existsSync("audio")) {
    fs.mkdirSync("audio");
  }

  if (!fs.existsSync("./audio/default.mp3")) {
    logger.error("Cannot find audio/default.mp3!");
    throw new Error("Cannot find audio/default.mp3!");
  }

  await initDatabase();

  //Add the default audio to the table if it doesn't exist yet
  let defaultAudioObj = await AudioNameMappingModel.findOne({
    where: { filename: "default.mp3" },
  });
  if (!defaultAudioObj) {
    await AudioNameMappingModel.create({
      filename: "default.mp3",
      friendlyName: "Default audio",
    });
  }
}

app.listen(PORT, () => {
  logger.info(`Audio API has started on port ${PORT}`);
});

init();
