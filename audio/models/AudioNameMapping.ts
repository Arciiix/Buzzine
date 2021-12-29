import { DataTypes } from "sequelize";
import db from "../utils/db";
import AlarmsAudioModel from "./AlarmsAudio";

const AudioNameMappingModel = db.define("AudioNameMapping", {
  filename: {
    allowNull: false,
    type: DataTypes.STRING,
    primaryKey: true,
  },
  friendlyName: {
    allowNull: true,
    type: DataTypes.STRING,
  },
  youtubeID: {
    allowNull: true,
    type: DataTypes.STRING,
  },
});

AlarmsAudioModel.belongsTo(AudioNameMappingModel, { foreignKey: "filename" });

export default AudioNameMappingModel;
