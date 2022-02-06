import { DataTypes } from "sequelize";
import db from "../utils/db";

const AlarmsAudioModel = db.define("AlarmsAudio", {
  alarmId: {
    allowNull: false,
    type: DataTypes.STRING,
  },
  audioId: {
    allowNull: false,
    type: DataTypes.STRING,
  },
});

export default AlarmsAudioModel;
