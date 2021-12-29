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

async function changeAlarmSound(alarmId: string, audioFilename?: string) {
  if (audioFilename) {
    //Check if sound exists
    let sound = await AudioNameMappingModel.findOne({
      where: { filename: audioFilename },
    });
    if (!sound) {
      logger.warn(
        `User tried to change alarm ${alarmId} sound to something that doesn't exist (${audioFilename})`
      );
      return false;
    }
  } else {
    //If user didn't specify the audioFilename, clear the audio - set the default one
    audioFilename = "default.mp3";
  }

  //If alarm doesn't exist in the audio database yet, create it
  let alarm: any = await AlarmsAudioModel.findOne({
    where: { alarmId: alarmId },
  });
  if (alarm) {
    alarm.filename = audioFilename;
    await alarm.save();
  } else {
    alarm = await AlarmsAudioModel.create({
      alarmId: alarmId,
      filename: audioFilename,
    });
  }
  logger.info(
    `Successfully changed alarm ${alarmId} audio to ${audioFilename}`
  );
  return alarm;
}

async function deleteSound(
  filename: string
): Promise<{ error: boolean; errorCode?: string }> {
  if (filename === "default.mp3") {
    return { error: true, errorCode: "CANNOT_DELETE_DEFAULT_SOUND" };
  }

  //Check if sound exists
  let soundObj = await AudioNameMappingModel.findOne({
    where: { filename: filename },
  });
  if (!soundObj) {
    return { error: true, errorCode: "SOUND_DOES_NOT_EXIST" };
  }

  //Delete all the relations - if alarm has this sound set as its sound
  let alarmsWithTheSound: any = await AlarmsAudioModel.findAll({
    where: { filename: filename },
  });
  for await (const alarm of alarmsWithTheSound) {
    await changeAlarmSound(alarm.alarmId);
  }

  await soundObj.destroy();
  logger.info(`Successfully deleted sound ${filename}`);

  return { error: false };
}

export default PlayAudio;
export { getAlarmAudio, changeAlarmSound, deleteSound };
