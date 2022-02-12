import { DataTypes } from "sequelize";
import shortUUID from "short-uuid";
import db from "../utils/db";
import AlarmsAudioModel from "./AlarmsAudio";

const AudioNameMappingModel = db.define("AudioNameMapping", {
  audioId: {
    allowNull: false,
    type: DataTypes.STRING,
    unique: true,
    primaryKey: true,
    defaultValue: () => shortUUID.generate(),
  },
  filename: {
    allowNull: false,
    type: DataTypes.STRING,
  },
  friendlyName: {
    allowNull: true,
    type: DataTypes.STRING,
  },
  youtubeID: {
    allowNull: true,
    type: DataTypes.STRING,
  },
  duration: {
    allowNull: true,
    type: DataTypes.INTEGER,
  },
});

AlarmsAudioModel.belongsTo(AudioNameMappingModel, { foreignKey: "audioId" });

export default AudioNameMappingModel;
