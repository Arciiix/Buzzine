import fs from "fs";
import childProcess from "child_process";
import logger from "./logger";
import AudioNameMappingModel from "../models/AudioNameMapping";

async function addFadeEffect(
  audioId: string,
  fadeInDuration?: number,
  fadeOutDuration?: number
): Promise<{ error: boolean; errorCode?: string }> {
  let audioObj: any = await AudioNameMappingModel.findOne({
    where: { audioId },
  });
  if (!audioObj) return { error: true, errorCode: "WRONG_AUDIO_ID" };
  let filename = audioObj.filename;
  let cutResponse = await applyFadeEffect(
    filename,
    fadeInDuration,
    fadeOutDuration,
    audioObj.duration
  );
  if (!cutResponse.error) {
    //If it was a YouTube audio, it's not the exact same video anymore, so clear the id
    audioObj.youtubeID = null;
    await audioObj.save();
  }
  return cutResponse;
}

async function applyFadeEffect(
  filename: string,
  fadeInDuration: number,
  fadeOutDuration: number,
  duration: number
): Promise<{
  error: boolean;
  errorCode?: string;
}> {
  if (fadeInDuration >= duration) {
    return { error: true, errorCode: "WRONG_FADE_IN_DURATION" };
  }
  if (fadeOutDuration >= duration) {
    return { error: true, errorCode: "WRONG_FADE_OUT_DURATION" };
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

  //Fade filters
  let filters = '"';

  if (fadeInDuration) {
    filters += `afade=t=in:st=0:d=${parseInt(fadeInDuration.toString()) || 0}`;
  }
  if (fadeOutDuration) {
    if (fadeInDuration) {
      filters += ",";
    }

    filters += `afade=t=out:st=${
      duration - (parseInt(fadeOutDuration.toString()) || 0)
    }:d=${parseInt(fadeOutDuration.toString()) || 0}`;
  }

  filters += '"';

  if (fadeInDuration || fadeOutDuration) {
    params.push("-af");
    params.push(filters);
  }

  //The output file
  params.push(filePath);

  return await new Promise((resolve, reject) => {
    childProcess.exec(
      `ffmpeg ${params.join(" ")}`,
      async (err, stdout, stderr) => {
        if (err) {
          logger.error(
            `Error while trying to add fade effects to audio ${filename} - fade in: ${
              fadeInDuration || 0
            }s, fade out: ${fadeOutDuration || 0}s: ${stderr.toString()}`
          );
          reject({ error: true, errorCode: stderr.toString() });
        } else {
          fs.unlinkSync(tempFilePath);
          logger.info(
            `Added audio effects to audio ${filename} - fade in: ${
              fadeInDuration || 0
            }s, fade out: ${fadeOutDuration || 0}s`
          );
          resolve({
            error: false,
          });
        }
      }
    );
  });
}

async function previewFadeEffect(
  audioId: string,
  fadeInDuration?: number,
  fadeOutDuration?: number
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

  if (!fs.existsSync("./audio/previews")) {
    fs.mkdirSync("./audio/previews");
  }

  fs.copyFileSync(`./audio/${filename}`, `./audio/previews/${filename}`);
  let fadeResponse = await applyFadeEffect(
    `previews/${filename}`,
    fadeInDuration,
    fadeOutDuration,
    audioObj.duration
  );
  return fadeResponse;
}

export { addFadeEffect, applyFadeEffect, previewFadeEffect };
