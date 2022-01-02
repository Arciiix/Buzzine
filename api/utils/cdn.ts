import express from "express";
import path from "path";

const cdn = express.Router();
cdn.get("/iconTransparent", (req, res) => {
  res.sendFile(
    path.join(__dirname, "..", "assets", "icon-1024-transparent.png")
  );
});
cdn.get("/iconSolid", (req, res) => {
  res.sendFile(path.join(__dirname, "..", "assets", "icon-1024-solid.png"));
});
cdn.get("/iconRegular", (req, res) => {
  res.sendFile(path.join(__dirname, "..", "assets", "icon-1024-regular.png"));
});

export default cdn;
