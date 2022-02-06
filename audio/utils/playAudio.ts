import childProcess from "child_process";
import AlarmsAudioModel from "../models/AlarmsAudio";
import AudioNameMappingModel from "../models/AudioNameMapping";
import logger from "./logger";
import fs from "fs";
import path from "path";

class PlayAudio {
  filename: string;
  isPlaying: boolean;
  private process: any;
  private tempMuteTimeout: ReturnType<typeof setTimeout>;

  constructor(filename: string) {
    this.filename = filename;
    if (!this.filename) {
      logger.error("Missing filename!");
      //TODO: Send socket.io error event
    } else {
      this.play();
    }
  }

  play() {
    this.isPlaying = true;
    this.process = childProcess.spawn("ffplay", [
      `./audio/${this.filename}`,
      "-nodisp",
      "-autoexit",
      // 'loop 0' doesn't work, it has to be separate
      "-loop",
      "0",
    ]);

    logger.info(`Audio ${this.filename} has started playing!`);
  }

  tempMute(duration: number): { error: boolean; errorCode?: string } {
    if (!this.isPlaying) {
      logger.warn(
        `Tried to temp-mute audio but audio ${this.filename} is not playing`
      );
      return { error: true, errorCode: "AUDIO_IS_NOT_PLAYING" };
    }
    if (duration < 5 || duration > 300) {
      logger.warn(
        `Tried to temp-mute audio ${this.filename} with out-of-range duration (${duration})`
      );
      return { error: true, errorCode: "DURATION_OUT_OF_RANGE_5_TO_300" };
    }
    if (this.tempMuteTimeout) {
      logger.warn(
        `Tried to mute audio ${this.filename}, but it has already been muted`
      );
      return { error: true, errorCode: "ALREADY_USED" };
    }
    this.destroy();
    this.tempMuteTimeout = setTimeout(this.play.bind(this), duration * 1000);

    logger.info(
      `Temp-muted the current audio ${this.filename} for ${duration} second(s)`
    );

    return { error: false };
  }

  destroy() {
    if (this.tempMuteTimeout) {
      clearTimeout(this.tempMuteTimeout);
    }
    this.isPlaying = false;
    this.process.kill("SIGKILL");
    logger.info(`Audio ${this.filename} has stopped playing!`);
  }
}

async function getAlarmAudio(
  alarmId: string
): Promise<{ audioFilename: string; audioId: string }> {
  if (!alarmId) return { audioFilename: "default.mp3", audioId: "default" };
  let audio: any = await AlarmsAudioModel.findOne({
    where: { alarmId: alarmId },
    include: AudioNameMappingModel,
  });

  return audio
    ? { audioFilename: audio.AudioNameMapping.filename, audioId: audio.audioId }
    : { audioFilename: "default.mp3", audioId: "default" };
}

async function changeAlarmSound(alarmId: string, audioId?: string) {
  if (audioId) {
    //Check if sound exists
    let sound = await AudioNameMappingModel.findOne({
      where: { audioId: audioId },
    });
    if (!sound) {
      logger.warn(
        `User tried to change alarm ${alarmId} sound to something that doesn't exist (${audioId})`
      );
      return false;
    }
  } else {
    //If user didn't specify the audioFilename, clear the audio - set the default one
    audioId = "default";
  }

  //If alarm doesn't exist in the audio database yet, create it
  let alarm: any = await AlarmsAudioModel.findOne({
    where: { alarmId: alarmId },
  });
  if (alarm) {
    alarm.audioId = audioId;
    await alarm.save();
  } else {
    alarm = await AlarmsAudioModel.create({
      alarmId: alarmId,
      audioId: audioId,
    });
  }
  logger.info(`Successfully changed alarm ${alarmId} audio to ${audioId}`);
  return alarm;
}

async function deleteSound(
  audioId: string
): Promise<{ error: boolean; errorCode?: string }> {
  if (audioId === "default") {
    return { error: true, errorCode: "CANNOT_DELETE_DEFAULT_SOUND" };
  }

  //Check if sound exists
  let soundObj: any = await AudioNameMappingModel.findOne({
    where: { audioId: audioId },
  });
  if (!soundObj) {
    return { error: true, errorCode: "SOUND_DOES_NOT_EXIST" };
  }

  //Delete all the relations - if alarm has this sound set as its sound
  let alarmsWithTheSound: any = await AlarmsAudioModel.findAll({
    where: { audioId: audioId },
  });
  for await (const alarm of alarmsWithTheSound) {
    await changeAlarmSound(alarm.alarmId);
  }

  await soundObj.destroy();

  //Delete the actual file
  fs.unlinkSync(path.join(__dirname, "..", "audio", soundObj.filename));

  logger.info(`Successfully deleted sound ${audioId}`);

  return { error: false };
}

export default PlayAudio;
export { getAlarmAudio, changeAlarmSound, deleteSound };
