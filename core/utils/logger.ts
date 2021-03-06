import * as winston from "winston";
import DailyRotateFile = require("winston-daily-rotate-file");

const fileTransport = new DailyRotateFile({
  filename: "./logs/buzzine-core-%DATE%.log",
  datePattern: "DD.MM.YYYY",
  zippedArchive: true,
  maxFiles: "14d",
  level: "info",
});
const errorFileTransport = new DailyRotateFile({
  filename: "./logs/errors-buzzine-core-%DATE%.log",
  datePattern: "DD.MM.YYYY",
  zippedArchive: true,
  maxFiles: "14d",
  level: "warn",
});

const format = winston.format.printf((info) => {
  return `[${info.level}] [${info.timestamp}]${
    info.label ? " " + info.label : ""
  }: ${info.message}`;
});

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp({ format: "DD.MM.YYYY HH:mm:ss" }),
    format
  ),
  transports: [
    fileTransport,
    errorFileTransport,
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.timestamp({ format: "DD.MM.YYYY HH:mm:ss" }),
        format
      ),
      level: "debug",
    }),
  ],
});

export default logger;
