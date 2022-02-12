import ytdl, { validateID } from "ytdl-core";
import fs from "fs";
import shortUUID from "short-uuid";
import path from "path";
import logger from "./logger";
import AudioNameMappingModel from "../models/AudioNameMapping";
import { getAudioDurationFromFile } from "./playAudio";

async function downloadFromYouTube(url): Promise<{
  error: boolean;
  errorCode?: string;
  statusCode: number;
}> {
  let isURLValid = await ytdl.validateURL(url);
  if (!isURLValid) {
    logger.warn(`Wrong video URL when downloading from YouTube: ${url}`);
    return { error: true, statusCode: 400, errorCode: "WRONG_URL" };
  }

  try {
    let id = await ytdl.getURLVideoID(url);
    let dbEntity = await AudioNameMappingModel.findOne({
      where: { youtubeID: id },
    });
    if (dbEntity) {
      logger.warn(
        `Tried to download a video which has been already downloaded. ID: ${id}`
      );
      return { error: true, statusCode: 409, errorCode: "ALREADY_EXISTS" };
    }
  } catch (err) {
    logger.warn(`Error when trying to get the YouTube video id of URL ${url}`);
    return { error: true, statusCode: 502, errorCode: "" };
  }

  let result: {
    error: boolean;
    errorCode?: string;
    statusCode: number;
  } = await new Promise(async (resolve, reject) => {
    try {
      let newFileId = shortUUID.generate();
      let fileDirectory = path.join(
        __dirname,
        "../",
        "audio",
        newFileId + ".mp3"
      );
      let fileStream = fs.createWriteStream(fileDirectory);
      let ytdlObj: any = ytdl(url, { filter: "audioonly" });
      ytdlObj.pipe(fileStream);

      ytdlObj.on("error", (err) => {
        //Do the cleanup
        fileStream.end();
        fs.unlinkSync(fileDirectory);
        logger.warn(
          `Error while downloading audio from YouTube: ${err.toString()}`
        );
        resolve({
          error: true,
          statusCode: 502,
          errorCode: "YOUTUBE_ERROR:" + err.toString(),
        });
      });

      ytdlObj.on("info", async (data) => {
        let name =
          data?.videoDetails?.title + " by " + data?.videoDetails?.author?.name;
        await AudioNameMappingModel.create({
          filename: newFileId + ".mp3",
          friendlyName: name,
          youtubeID: await ytdl.getURLVideoID(url),
        });

        logger.info(
          `New mapping for video ${await ytdl.getURLVideoID(
            url
          )} has been added (${name})`
        );
      });

      ytdlObj.on("finish", async (data) => {
        //If the YouTube audio was allowed to be downloaded, there wasn't any audio with the same youtubeId before, so find the latest object with that filename from the database
        let databaseObj: any = await AudioNameMappingModel.findOne({
          where: {
            filename: newFileId + ".mp3",
            youtubeID: await ytdl.getURLVideoID(url),
          },
          order: [["createdAt", "DESC"]],
        });

        databaseObj.duration = await getAudioDurationFromFile(
          newFileId + ".mp3"
        );
        await databaseObj.save();
        logger.info(
          `Updated the duration for YouTube video ${await ytdl.getURLVideoID(
            url
          )} to ${databaseObj.duration}`
        );

        resolve({ error: false, statusCode: 201 });
      });
    } catch (err) {
      logger.error(`Error while downloading from YouTube: ${err.toString()}`);
      resolve({ error: true, statusCode: 502, errorCode: err.toString() });
    }
  });

  return result;
}

export { downloadFromYouTube };
