import express from "express";
import path from "path";
import logger from "./logger";

const cdn = express.Router();
cdn.get("/iconTransparent", (req, res) => {
  logger.http("[CDN] /iconTransparent");
  res.sendFile(
    path.join(__dirname, "..", "assets", "icon-1024-transparent.png")
  );
});
cdn.get("/iconSolid", (req, res) => {
  logger.http("[CDN] /iconSolid");
  res.sendFile(path.join(__dirname, "..", "assets", "icon-1024-solid.png"));
});
cdn.get("/iconRegular", (req, res) => {
  logger.http("[CDN] /iconRegular");
  res.sendFile(path.join(__dirname, "..", "assets", "icon-1024-regular.png"));
});

export default cdn;
