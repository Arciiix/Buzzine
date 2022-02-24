import ytdl, { validateID } from "ytdl-core";
import fs from "fs";
import shortUUID from "short-uuid";
import path from "path";
import logger from "./logger";
import { getAudioDurationFromFile } from "./playAudio";
import db from "./db";

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
    let dbEntity = await db.audioNameMappings.findFirst({
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
          errorCode: "YOUTUBE_ERROR",
        });
      });

      ytdlObj.on("info", async (data) => {
        let name =
          data?.videoDetails?.title + " by " + data?.videoDetails?.author?.name;
        await db.audioNameMappings.create({
          data: {
            filename: newFileId + ".mp3",
            friendlyName: name,
            youtubeID: await ytdl.getURLVideoID(url),
          },
        });

        logger.info(
          `New mapping for video ${await ytdl.getURLVideoID(
            url
          )} has been added (${name})`
        );
      });

      ytdlObj.on("finish", async (data) => {
        //If the YouTube audio was allowed to be downloaded, there wasn't any audio with the same youtubeId before, so find the latest object with that filename from the database
        let databaseObj: any = await db.audioNameMappings.findFirst({
          where: {
            filename: newFileId + ".mp3",
            youtubeID: await ytdl.getURLVideoID(url),
          },
          orderBy: [
            {
              createdAt: "desc",
            },
          ],
        });

        let resultObj = await db.audioNameMappings.update({
          where: {
            audioId: databaseObj.audioId,
          },
          data: {
            duration: await getAudioDurationFromFile(newFileId + ".mp3"),
          },
        });

        logger.info(
          `Updated the duration for YouTube video ${await ytdl.getURLVideoID(
            url
          )} to ${resultObj.duration}`
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

async function getYouTubeVideoInfo(videoURL: string): Promise<{
  error: boolean;
  errorCode?: string;
  response?: IYouTubeVideoInfo;
}> {
  try {
    if (!ytdl.validateURL(videoURL)) {
      return { error: true, errorCode: "WRONG_VIDEO_URL" };
    }

    let videoInfo = await ytdl.getBasicInfo(videoURL);
    return {
      error: false,
      response: {
        channel: {
          name: videoInfo.videoDetails.ownerChannelName,
          id: videoInfo.videoDetails.author.id,
          isVerified: videoInfo.videoDetails.author.verified,
          username: videoInfo.videoDetails.author.user,
          url: videoInfo.videoDetails.author.channel_url,
        },
        description: videoInfo.videoDetails.description,
        lengthSeconds: videoInfo.videoDetails.lengthSeconds,
        thumbnail: {
          url: videoInfo.videoDetails.thumbnails[
            videoInfo.videoDetails.thumbnails.length - 1
          ].url,
          width:
            videoInfo.videoDetails.thumbnails[
              videoInfo.videoDetails.thumbnails.length - 1
            ].width,
          height:
            videoInfo.videoDetails.thumbnails[
              videoInfo.videoDetails.thumbnails.length - 1
            ].height,
        },
        title: videoInfo.videoDetails.title,
        uploadDate: new Date(videoInfo.videoDetails.uploadDate),
        url: videoInfo.videoDetails.video_url,
      },
    };
  } catch (err) {
    return { error: true, errorCode: err.toString() };
  }
}

interface IYouTubeVideoInfo {
  channel: {
    name: string;
    id: string;
    isVerified: boolean;
    username: string;
    url: string;
  };
  description: string;
  lengthSeconds: string;
  thumbnail: {
    url: string;
    width: number;
    height: number;
  };
  title: string;
  uploadDate: Date;
  url: string;
}

export { downloadFromYouTube, getYouTubeVideoInfo };
