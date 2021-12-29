import ytdl, { validateID } from "ytdl-core";
import fs from "fs";
import shortUUID from "short-uuid";
import path from "path";
import logger from "./logger";
import AudioNameMappingModel from "../models/AudioNameMapping";

async function downloadFromYouTube(url) {
  let isURLValid = await ytdl.validateURL(url);
  if (!isURLValid) {
    logger.warn(`Wrong video URL when downloading from YouTube: ${url}`);
    return false;
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
      return false;
    }
  } catch (err) {
    logger.warn(`Error when trying to get the YouTube video id of URL ${url}`);
    return false;
  }

  if (!fs.existsSync("audio")) {
    fs.mkdirSync("audio");
  }

  let newFileId = shortUUID.generate();
  let fileDirectory = path.join(__dirname, "../", "audio", newFileId + ".mp3");
  let fileStream = fs.createWriteStream(fileDirectory);
  let ytdlObj: any = ytdl(url);

  ytdlObj.pipe(fileStream);

  ytdlObj.on("error", (err) => {
    //Do the cleanup
    fileStream.end();
    fs.unlinkSync(fileDirectory);
    logger.warn(
      `Error while downloading audio from YouTube: ${err.toString()}`
    );
    return false;
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

  return true;
}

export { downloadFromYouTube };
