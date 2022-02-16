import axios from "axios";
import { TASMOTA_URL } from "./constants";
import logger from "./logger";
import TemperatureModel from "./models/Temperature";
import db from "./db";
import { Op } from "sequelize";

async function fetchTemperature(): Promise<number> {
  try {
    let response = await axios.get(`${TASMOTA_URL}/cm?cmnd=Status%2010`);
    let temperature: number = parseFloat(
      response.data.StatusSNS.DS18B20.Temperature
    );
    logger.info(`Got the temperature: ${temperature}`);
    return temperature;
  } catch (err) {
    logger.error(
      `Error while trying to send the heartbeat to Tasmota: ${
        err?.response?.status
      } with data: ${JSON.stringify(err?.response?.data)}}`
    );
  }
}

async function saveTemperature(): Promise<void> {
  let insideTemperature = await fetchTemperature();
  if (insideTemperature) {
    await TemperatureModel.create({
      timestamp: new Date(),
      value: insideTemperature,
    });
    logger.info(`Added the temperature to the database`);
  } else {
    logger.warn(`Fetched temperature is null`);
  }
}

async function calculateCurrentTemperatureData(): Promise<ICurrentTemperatureData> {
  let currentTemperature = await fetchTemperature();
  let temperatureStats: ITemperatureData = await calculateTemperatureDataForDay(
    new Date()
  );
  let offsetPercent = await calculateTemperatureOffset(
    currentTemperature,
    new Date()
  );
  let temperatureData: ICurrentTemperatureData = {
    currentTemperature,
    ...temperatureStats,
    offsetPercent,
  };
  return temperatureData;
}

async function calculateTemperatureDataForDay(
  day: Date
): Promise<ITemperatureData> {
  day.setHours(0);
  day.setMinutes(0);
  day.setSeconds(0);

  let endDate = new Date(day);
  endDate.setHours(23);
  endDate.setMinutes(59);
  endDate.setSeconds(59);

  let data: any = await TemperatureModel.findOne({
    attributes: [
      [db.fn("MIN", db.col("value")), "minTemp"],
      [db.fn("MAX", db.col("value")), "maxTemp"],
      [db.fn("AVG", db.col("value")), "averageTemp"],
    ],
    where: {
      timestamp: {
        [Op.between]: [day, endDate],
      },
    },
  });

  let temperatureData: ITemperatureData = {
    min: data.dataValues.minTemp,
    max: data.dataValues.maxTemp,
    average: data.dataValues.averageTemp,
  };
  return temperatureData;
}

async function calculateTemperatureOffset(temperature: number, month: Date) {
  //The offset is calculated from the average monthly temperature
  month.setDate(1);
  month.setHours(0);
  month.setMinutes(0);

  let endDate = new Date(
    month.getFullYear(),
    month.getMonth() + 1,
    0,
    23,
    59,
    59
  );
  let data: any = await TemperatureModel.findOne({
    attributes: [[db.fn("AVG", db.col("value")), "averageTemp"]],
    where: {
      timestamp: {
        [Op.between]: [month, endDate],
      },
    },
  });

  return (
    (temperature - data.dataValues.averageTemp) / data.dataValues.averageTemp
  );
}

interface ITemperatureData {
  average: number;
  min: number;
  max: number;
}

type ICurrentTemperatureData = ITemperatureData & {
  currentTemperature: number;
  offsetPercent: number;
};

export {
  fetchTemperature,
  saveTemperature,
  calculateCurrentTemperatureData,
  calculateTemperatureDataForDay,
};
export type { ITemperatureData, ICurrentTemperatureData };
