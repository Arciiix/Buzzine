import socketioClient from "socket.io-client";
import dotenv from "dotenv";
import logger from "./utils/logger";
import { initDatabase } from "./utils/db";
import PlaySound, { getAlarmAudio } from "./utils/playAudio";
import fs from "fs";

//Load environment variables from file
dotenv.config();

const io = socketioClient(process.env.CORE_URL || "http://localhost:5555"); //DEV TODO: Change the default CORE_URL
let audioInstance: PlaySound;
let emergencyInstance: PlaySound;

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

async function init() {
  if (!fs.existsSync("audio")) {
    fs.mkdirSync("audio");
  }
  await initDatabase();
}

init();
