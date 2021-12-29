import socketioClient from "socket.io-client";
import dotenv from "dotenv";
import logger from "./utils/logger";
import { initDatabase } from "./utils/db";
import PlaySound from "./utils/playAudio";

//Load environment variables from file
dotenv.config();

const io = socketioClient(process.env.CORE_URL || "http://localhost:5555"); //DEV TODO: Change the default CORE_URL
let audioInstance: PlaySound;

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
    //TODO: Select the proper audio
    audioInstance = new PlaySound("test.mp3");
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
  await initDatabase();
}

init();
