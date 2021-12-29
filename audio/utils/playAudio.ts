import childProcess from "child_process";
import AlarmsAudioModel from "../models/AlarmsAudio";
import AudioNameMappingModel from "../models/AudioNameMapping";
import logger from "./logger";

class PlayAudio {
  filename: string;
  isPlaying: boolean;
  private process: any;

  constructor(filename: string) {
    this.filename = filename;
    if (!this.filename) {
      logger.error("Missing filename!");
      //TODO: Send socket.io error event
    } else {
      this.isPlaying = true;
      this.process = childProcess.spawn("ffplay", [
        `./audio/${filename}`,
        "-nodisp",
        "-autoexit",
        // 'loop 0' doesn't work, it has to be separately
        "-loop",
        "0",
      ]);

      logger.info(`Audio ${this.filename} has started playing!`);
    }
  }

  destroy() {
    this.isPlaying = false;
    this.process.kill("SIGKILL");
    logger.info(`Audio ${this.filename} has stopped playing!`);
  }
}

async function getAlarmAudio(alarmId: string) {
  if (!alarmId) return "default.mp3";
  let audio: any = await AlarmsAudioModel.findOne({
    where: { alarmId: alarmId },
    include: AudioNameMappingModel,
  });

  return audio ? audio.filename : "default.mp3";
}

export default PlayAudio;
export { getAlarmAudio };
