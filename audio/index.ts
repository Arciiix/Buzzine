import socketioClient from "socket.io-client";
import express from "express";
import dotenv from "dotenv";
import logger, { logHTTPEndpoints } from "./utils/logger";
import { initDatabase } from "./utils/db";
import AudioNameMappingModel from "./models/AudioNameMapping";
import AlarmsAudioModel from "./models/AlarmsAudio";
import PlaySound, {
  changeAlarmSound,
  deleteSound,
  getAlarmAudio,
  getAudioDurationFromFile,
} from "./utils/playAudio";
import fs from "fs";
import path from "path";
import {
  downloadFromYouTube,
  getYouTubeVideoInfo,
} from "./utils/YouTubeDownloader";
import { cutAudio, previewCut } from "./utils/cutAudio";
import { addFadeEffect, previewFadeEffect } from "./utils/fadeEffects";

//Load environment variables from file
dotenv.config();

const io = socketioClient(process.env.CORE_URL || "http://localhost:3333"); //DEV TODO: Change the default CORE_URL
const app = express();
const PORT = process.env.PORT || 7777;

app.use(express.json());

let audioInstance: PlaySound;
let emergencyInstance: PlaySound;
let audioPreviewInstance: PlaySound;
let audioPreviewTimeout: ReturnType<typeof setTimeout>;
let isRinging: boolean = false;

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
  if (!audioInstance && !isRinging) {
    isRinging = true;
    let audioObj = await getAlarmAudio(data?.id);
    audioInstance = new PlaySound(audioObj.filename);
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

io.on("EMERGENCY_ALARM_CANCELLED", async (data) => {
  if (emergencyInstance) {
    emergencyInstance.destroy();
    emergencyInstance = null;
    logger.info("Emergency cancelled");
  } else {
    logger.warn(
      `User tried to cancel the emergency but no emergency audio is playing`
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
  isRinging = false;
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
api.use(logHTTPEndpoints);

api.get("/ping", (req, res) => {
  res.send({ error: false, timestamp: new Date() });
});

api.put("/alarmRinging", async (req, res) => {
  if (!req.body.alarmId) {
    res.status(400).send({ error: true, errorCode: "MISSING_ALARM_ID" });
    return;
  }
  if (!audioInstance && !isRinging) {
    isRinging = true;
    let audioObj = await getAlarmAudio(req.body.alarmId);
    audioInstance = new PlaySound(audioObj.filename);
  } else {
    logger.info(`Skipping playing audio since the audio is playing already...`);
  }

  res.send({ error: false });
});
api.put("/muteAudio", async (req, res) => {
  if (!req.body.alarmId) {
    res.status(400).send({ error: true, errorCode: "MISSING_ALARM_ID" });
    return;
  }
  if (!audioInstance) {
    logger.warn(
      `Trying to mute audio, but it doesn't exist. Alarm id: ${req.body.alarmId}`
    );
    res.status(404).send({ error: true, errorCode: "AUDIO_DOES_NOT_EXIST" });
    return;
  }
  audioInstance.destroy();
  audioInstance = null;
  isRinging = false;
  res.send({ error: false });
});

api.get("/getSoundList", async (req, res) => {
  let soundList = await AudioNameMappingModel.findAll();
  res.send({ error: false, data: soundList });
});

api.get("/getAlarmSound", async (req, res) => {
  if (!req.query.alarmId) {
    res.status(400).send({ error: true, errorCode: "MISSING_ALARM_ID" });
    return;
  }
  let alarmSound = await getAlarmAudio(req.query.alarmId as string);
  res.send({ error: false, response: alarmSound });
});

api.get("/getAlarmSoundList", async (req, res) => {
  let soundList: any[] = await AlarmsAudioModel.findAll({
    include: AudioNameMappingModel,
  });
  res.send({
    error: false,
    data: soundList.map((e: any) => {
      let newElem = { ...JSON.parse(JSON.stringify(e)) };
      newElem.filename = e.AudioNameMapping.filename;
      newElem.duration = e.AudioNameMapping.duration;
      newElem.friendlyName = e.AudioNameMapping.friendlyName;
      return newElem;
    }),
  });
});

api.post("/addYouTubeSound", async (req, res) => {
  if (!req.body.url) {
    return res.status(400).send({ error: true, errorCode: "MISSING_URL" });
  }

  //Hang the request
  let { error, errorCode, statusCode } = await downloadFromYouTube(
    req.body.url
  );
  res.status(statusCode).send({ error: error, errorCode: errorCode });
});
api.put("/updateAudio", async (req, res) => {
  if (!req.body.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIO_ID" });
    return;
  }

  let audioInstance: any = await AudioNameMappingModel.findOne({
    where: { audioId: req.body.audioId },
  });

  if (!audioInstance) {
    res.status(404).send({ error: true, errorCode: "WRONG_AUDIO_ID" });
    return;
  } else {
    if (req.body.friendlyName) {
      audioInstance.friendlyName = req.body.friendlyName;
    }
    if (req.body.filename) {
      let audioPath = path.join(__dirname, "audio", req.body.filename);
      if (fs.existsSync(audioPath)) {
        audioInstance.filename = req.body.filename;
        audioInstance.duration = await getAudioDurationFromFile(
          req.body.filename
        );
      } else {
        res
          .status(404)
          .send({ error: true, errorCode: "NON_EXISTING_FILENAME" });
        return;
      }
    }

    await audioInstance.save();

    res.send({ error: false });
  }
});

api.put("/changeAlarmSound", async (req, res) => {
  if (!req.body.alarmId) {
    res.status(400).send({ error: true, errorCode: "MISSING_ALARMID" });
    return;
  }
  if (!req.body.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIOID" });
    return;
  }

  let changeSoundResult = await changeAlarmSound(
    req.body.alarmId,
    req.body.audioId
  );
  if (!changeSoundResult) {
    res.status(400).send({ error: true });
  } else {
    res.send({ error: false, alarm: changeSoundResult });
  }
});

api.delete("/clearAlarmCustomSound", async (req, res) => {
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
  if (!req.body.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIO_ID" });
    return;
  }

  //Check if sound exists
  let soundObj: any = await AudioNameMappingModel.findOne({
    where: { audioId: req.body.audioId },
  });
  if (!soundObj) {
    res.status(400).send({ error: true, errorCode: "SOUND_DOES_NOT_EXIST" });
    return;
  }

  //If the sound is being played right now, stop it
  if (audioInstance?.filename === soundObj.filename) {
    res.status(409).send({ error: true, errorCode: "AUDIO_IS_RINGING_NOW" });
    return;
  }
  if (audioPreviewInstance?.filename === soundObj.filename) {
    audioPreviewInstance.destroy();
    audioPreviewInstance = null;
  }

  let deleteSoundResult = await deleteSound(req.body.audioId);
  if (!deleteSoundResult.error) {
    res.send({ error: false });
  } else {
    res.status(500).send(deleteSoundResult);
  }
});

api.put("/tempMuteAudio", async (req, res) => {
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
  if (!req.query.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIO_ID" });
    logger.warn("Tried to preview an audio but didn't specify the audio id");
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

  let audioInstance: any = await AudioNameMappingModel.findOne({
    where: { audioId: req.query.audioId },
  });

  if (!audioInstance) {
    res.status(400).send({ error: true, errorCode: "WRONG_AUDIO_ID" });
    logger.warn(`Tried to preview an unexisting audio ${req.query.audioId}`);
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

  audioPreviewInstance = new PlaySound(audioInstance.filename);
  audioPreviewTimeout = setTimeout(() => {
    audioPreviewInstance.destroy();
    audioPreviewInstance = null;
    logger.info("Stopped the preview audio playback because of timeout");
  }, parseInt(req.query.duration as string) * 1000);

  logger.info(
    `Playing a preview of file ${req.query.audioId} for duration: ${parseInt(
      req.query.duration as string
    )}s`
  );
  res.send({ error: false, duration: parseInt(req.query.duration as string) });
});

api.put("/stopAudioPreview", (req, res) => {
  if (audioPreviewTimeout) {
    clearTimeout(audioPreviewTimeout);
    audioPreviewTimeout = null;
  }

  if (audioPreviewInstance) {
    audioPreviewInstance.destroy();
    audioPreviewInstance = null;
  }

  setTimeout(() => {
    //After a timeout because of the speaker delay
    fs.rmSync("./audio/previews/", { force: true, recursive: true });
  }, 500);

  logger.info("User has stopped the preview audio playback");

  res.send({ error: false });
});

api.get("/getYouTubeVideoInfo", async (req, res) => {
  if (!req.query.videoURL) {
    res.status(400).send({ error: true, errorCode: "MISSING_VIDEO_URL" });
    return;
  }

  let videoInfo = await getYouTubeVideoInfo(req.query.videoURL as string);
  if (videoInfo.error) {
    res.status(400);
    logger.info(
      `User tried to get YouTube video info but there's an error: ${videoInfo.errorCode}`
    );
  } else {
    res.status(200);
    logger.info(`Got the info for YouTube video ${req.query.videoURL}`);
  }

  res.send(videoInfo);
});

api.put("/cutAudio", async (req, res) => {
  if (!req.body.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIO_ID" });
    logger.warn(`Tried to cut audio but audioId is missing`);
    return;
  }

  let start, end;

  if (req.body.start) {
    start = parseFloat(req.body.start);
    if (isNaN(start)) {
      return res
        .status(400)
        .send({ error: true, errorCode: "WRONG_START_TIME" });
    }
  }
  if (req.body.end) {
    end = parseFloat(req.body.end);
    if (isNaN(end)) {
      return res.status(400).send({ error: true, errorCode: "WRONG_END_TIME" });
    }
  }

  let cutAudioResult = await cutAudio(
    req.body.audioId,
    req.body.start,
    req.body.end
  );

  if (cutAudioResult.error) {
    res.status(400);
  } else {
    res.status(200);
  }

  res.send(cutAudioResult);
});

api.get("/previewCut", async (req, res) => {
  if (!req.query.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIO_ID" });
    logger.warn(`Tried to preview-cut audio but audioId is missing`);
    return;
  }

  let start, end;

  if (req.query.start) {
    start = parseFloat(req.query.start as string);
    if (isNaN(start)) {
      return res
        .status(400)
        .send({ error: true, errorCode: "WRONG_START_TIME" });
    }
  }
  if (req.query.end) {
    end = parseFloat(req.query.end as string);
    if (isNaN(end)) {
      return res.status(400).send({ error: true, errorCode: "WRONG_END_TIME" });
    }
  }

  if (audioPreviewTimeout) {
    clearTimeout(audioPreviewTimeout);
    audioPreviewTimeout = null;
  }
  if (audioPreviewInstance) {
    audioPreviewInstance.destroy();
    audioPreviewInstance = null;
  }

  let cutAudioResult = await previewCut(
    req.query.audioId as string,
    parseFloat(req.query.start as string),
    parseFloat(req.query.end as string)
  );

  if (cutAudioResult.error) {
    res.status(400);
  } else {
    res.status(200);

    let audioInstance: any = await AudioNameMappingModel.findOne({
      where: { audioId: req.query.audioId },
    });

    if (!audioInstance) {
      res.status(400).send({ error: true, errorCode: "WRONG_AUDIO_ID" });
      logger.warn(`Tried to preview an unexisting audio ${req.query.audioId}`);
      return;
    }

    audioPreviewInstance = new PlaySound(`previews/${audioInstance.filename}`);
    audioPreviewTimeout = setTimeout(() => {
      audioPreviewInstance.destroy();
      audioPreviewInstance = null;
      logger.info("Stopped the cut-preview audio playback because of timeout");

      fs.rmSync("./audio/previews/", { force: true, recursive: true });
    }, cutAudioResult.response.duration * 1000);

    logger.info(
      `Playing a cut-preview of file ${req.query.audioId} from ${req.query.start}s to ${req.query.end}s for duration: ${cutAudioResult.response.duration}s`
    );
  }

  res.send(cutAudioResult);
});

api.put("/addAudioFadeEffect", async (req, res) => {
  if (!req.body.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIO_ID" });
    logger.warn(`Tried to add audio fade effect but audioId is missing`);
    return;
  }

  let fadeInDuration, fadeOutDuration;

  if (req.body.fadeInDuration) {
    fadeInDuration = parseFloat(req.body.fadeInDuration);
    if (isNaN(fadeInDuration)) {
      return res
        .status(400)
        .send({ error: true, errorCode: "WRONG_FADE_IN_DURATION" });
    }
  }
  if (req.body.fadeOutDuration) {
    fadeOutDuration = parseFloat(req.body.fadeOutDuration);
    if (isNaN(fadeOutDuration)) {
      return res
        .status(400)
        .send({ error: true, errorCode: "WRONG_FADE_OUT_DURATION" });
    }
  }

  let fadeResult = await addFadeEffect(
    req.body.audioId,
    parseInt(req.body.fadeInDuration),
    parseInt(req.body.fadeOutDuration)
  );

  if (fadeResult.error) {
    res.status(400);
  } else {
    res.status(200);
  }

  res.send(fadeResult);
});

api.get("/previewAudioFadeEffect", async (req, res) => {
  if (!req.query.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIO_ID" });
    logger.warn(`Tried to preview audio fade effects but audioId is missing`);
    return;
  }

  let fadeInDuration, fadeOutDuration;

  if (req.query.fadeInDuration) {
    fadeInDuration = parseFloat(req.query.fadeInDuration as string);
    if (isNaN(fadeInDuration)) {
      return res
        .status(400)
        .send({ error: true, errorCode: "WRONG_FADE_IN_DURATION" });
    }
  }
  if (req.query.fadeOutDuration) {
    fadeOutDuration = parseFloat(req.query.fadeOutDuration as string);
    if (isNaN(fadeOutDuration)) {
      return res
        .status(400)
        .send({ error: true, errorCode: "WRONG_FADE_OUT_DURATION" });
    }
  }

  if (audioPreviewTimeout) {
    clearTimeout(audioPreviewTimeout);
    audioPreviewTimeout = null;
  }
  if (audioPreviewInstance) {
    audioPreviewInstance.destroy();
    audioPreviewInstance = null;
  }

  let fadeResult = await previewFadeEffect(
    req.query.audioId as string,
    parseInt(req.query.fadeInDuration as string),
    parseInt(req.query.fadeOutDuration as string)
  );

  if (fadeResult.error) {
    res.status(400);
  } else {
    res.status(200);

    let audioInstance: any = await AudioNameMappingModel.findOne({
      where: { audioId: req.query.audioId },
    });

    if (!audioInstance) {
      res.status(400).send({ error: true, errorCode: "WRONG_AUDIO_ID" });
      logger.warn(`Tried to preview an unexisting audio ${req.query.audioId}`);
      return;
    }

    audioPreviewInstance = new PlaySound(`previews/${audioInstance.filename}`);
    audioPreviewTimeout = setTimeout(() => {
      audioPreviewInstance.destroy();
      audioPreviewInstance = null;
      logger.info(
        "Stopped the preview of fade audio effects because of timeout"
      );

      fs.rmSync("./audio/previews/", { force: true, recursive: true });
    }, audioInstance.duration * 1000);

    logger.info(
      `Playing a preview of fade audio effects ${
        req.query.audioId
      } - fade in: ${fadeInDuration || 0}s, fade out: ${fadeOutDuration || 0}s`
    );
  }

  res.send(fadeResult);
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
    where: { audioId: "default" },
  });
  if (!defaultAudioObj) {
    let defaultAudioDuration = await getAudioDurationFromFile("default.mp3");
    await AudioNameMappingModel.create({
      audioId: "default",
      filename: "default.mp3",
      friendlyName: "Default audio",
      duration: defaultAudioDuration,
    });
  }
}

app.listen(PORT, () => {
  logger.info(`Audio API has started on port ${PORT}`);
});

init();
