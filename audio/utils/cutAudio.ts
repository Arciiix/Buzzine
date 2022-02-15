import fs from "fs";
import childProcess from "child_process";
import AudioNameMappingModel from "../models/AudioNameMapping";
import logger from "./logger";
import { getAudioDurationFromFile } from "./playAudio";

async function cutAudio(
  audioId: string,
  start?: number,
  end?: number
): Promise<{ error: boolean; errorCode?: string }> {
  let audioObj: any = await AudioNameMappingModel.findOne({
    where: { audioId },
  });
  if (!audioObj) return { error: true, errorCode: "WRONG_AUDIO_ID" };
  let filename = audioObj.filename;
  let cutResponse = await cutAudioFile(filename, start, end, audioObj.duration);
  if (!cutResponse.error) {
    audioObj.duration = cutResponse.response.duration;
    //If it was a YouTube audio, it's not the whole video anymore, so clear the id
    audioObj.youtubeID = null;
    await audioObj.save();
  }
  return cutResponse;
}

async function cutAudioFile(
  filename: string,
  start: number,
  end: number,
  duration: number
): Promise<{
  error: boolean;
  errorCode?: string;
  response?: { duration: number };
}> {
  if (end > duration) {
    return { error: true, errorCode: "WRONG_END_TIME" };
  }
  if (start < 0) {
    return { error: true, errorCode: "WRONG_START_TIME" };
  }

  let filePath = `./audio/${filename}`;

  if (!fs.existsSync(filePath)) {
    return { error: true, errorCode: "FILE_DOES_NOT_EXIST" };
  }

  //The last dot location is the dot that defines the extension
  let dotLocation = filePath.lastIndexOf(".");
  let tempFilePath =
    filePath.slice(0, dotLocation) + ".old" + filePath.slice(dotLocation);

  fs.renameSync(filePath, tempFilePath);

  let params: string[] = [
    "-i",
    tempFilePath,
    "-y", //Overwrite
  ];
  if (start) {
    params.push(...["-ss", start.toString()]);
  }
  if (end) {
    params.push(...["-to", end.toString()]);
  }

  //The output file
  params.push(filePath);

  return await new Promise((resolve, reject) => {
    childProcess.exec(
      `ffmpeg ${params.join(" ")}`,
      async (err, stdout, stderr) => {
        if (err) {
          logger.error(
            `Error while cutting audio ${filename} from ${start}s to ${end}s: ${stderr.toString()}`
          );
          reject({ error: true, errorCode: stderr.toString() });
        } else {
          fs.unlinkSync(tempFilePath);
          logger.info(`Cut audio ${filename} from ${start}s to ${end}s`);
          resolve({
            error: false,
            response: { duration: await getAudioDurationFromFile(filename) },
          });
        }
      }
    );
  });
}

async function previewCut(
  audioId: string,
  start?: number,
  end?: number
): Promise<{
  error: boolean;
  errorCode?: string;
  response?: { duration: number };
}> {
  let audioObj: any = await AudioNameMappingModel.findOne({
    where: { audioId },
  });
  if (!audioObj) return { error: true, errorCode: "WRONG_AUDIO_ID" };

  let filename = audioObj.filename;

  if (!fs.existsSync("./audio/cutPreviews")) {
    fs.mkdirSync("./audio/cutPreviews");
  }

  fs.copyFileSync(`./audio/${filename}`, `./audio/cutPreviews/${filename}`);
  let cutResponse = await cutAudioFile(
    `cutPreviews/${filename}`,
    start,
    end,
    audioObj.duration
  );
  return cutResponse;
}

export { cutAudio, cutAudioFile, previewCut };
