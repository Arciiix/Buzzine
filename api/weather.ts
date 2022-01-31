import express from "express";
import logger from "./utils/logger";
import dotenv from "dotenv";
import axios from "axios";

//Load environment variables from file
dotenv.config();
const OPEN_WEATHER_MAP_API_KEY = process.env.OPEN_WEATHER_MAP_API_KEY;
if (!OPEN_WEATHER_MAP_API_KEY) {
  logger.error("OpenWeatherMap API key not provided!");
}
let isAPIKeyValid;

const weatherRouter = express.Router();

//Check the API key
weatherRouter.use((req, res, next) => {
  if (!isAPIKeyValid) {
    res
      .status(502)
      .send({ error: true, errorCode: "WRONG_OPEN_WEATHER_MAP_API_KEY" });
    return;
  } else {
    next();
  }
});

weatherRouter.get("/", async (req, res) => {
  logger.http("[WEATHER] GET /");

  res.send({
    error: false,
    provider: "https://openweathermap.org/",
  });
});

weatherRouter.get("/getFullWeather", async (req, res) => {
  logger.http(
    `[WEATHER] GET /getFullWeather with data ${JSON.stringify(req.query)}`
  );

  if (!req.query.latitude || isNaN(parseInt(req.query.latitude as string))) {
    res.status(400).send({ error: true, errorCode: "MISSING_LATITUDE" });
    return;
  }
  if (!req.query.longitude || isNaN(parseInt(req.query.longitude as string))) {
    res.status(400).send({ error: true, errorCode: "MISSING_LONGITUDE" });
    return;
  }
  //Hours count is the amount of hourly weather data to get
  if (req.query.hoursCount && isNaN(parseInt(req.query.hoursCount as string))) {
    res.status(400).send({ error: true, errorCode: "WRONG_HOURS_COUNT" });
    return;
  }

  //TODO
  try {
    let response = await axios.get(
      "https://api.openweathermap.org/data/2.5/onecall",
      {
        params: {
          lat: req.query.latitude as string,
          lon: req.query.longitude as string,
          exclude: "alerts,minutely,daily",
          units: "metric",
          lang: "pl",
          appId: OPEN_WEATHER_MAP_API_KEY,
        },
      }
    );
    //TODO
    let returnObj: IWeatherDataObject = {
      latitude: response.data.lat,
      longitude: response.data.lon,
      timezone: response.data.timezone,
      current: serializeWeatherObject(response.data.current),
      hourly: response.data.hourly
        .slice(0, parseInt(req.query.hoursCount as string))
        .map((e) => serializeWeatherObject(e)),
    };
    res.send({ error: false, response: returnObj });
  } catch (err) {
    logger.error(
      `Error while getting weather for latitude ${
        req.query.latitude as string
      } and longitude ${
        req.query.longitude as string
      }: ${err.toString()} - ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
  }
});

async function checkOpenWeatherMapAPIKey() {
  //Validate the API key by making a sample request
  isAPIKeyValid = false;
  if (OPEN_WEATHER_MAP_API_KEY) {
    try {
      let response = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather?q=London&appid=${OPEN_WEATHER_MAP_API_KEY}`
      );
      if (response.status === 200) {
        isAPIKeyValid = true;
      }
    } catch (err) {
      logger.warn(
        `Error while checking the OpenWeatherMap API key: ${err.toString()} - ${JSON.stringify(
          err?.response?.data
        )} with status ${err?.response?.status}`
      );
      isAPIKeyValid = false;
    }
  }

  logger.info("Checked the OpenWeatherMap API key");
}

function serializeWeatherObject(weatherObject: any): IWeather {
  return {
    timestamp: new Date(weatherObject.dt * 1000), //Timestamp returned in the OpenWeatherMap API is given in seconds, convert it to milliseconds and Date object
    temperature: weatherObject.temp,
    feelsLike: weatherObject.feels_like,
    pressure: weatherObject.pressure,
    humidity: weatherObject.humidity,
    windSpeed: weatherObject.wind_speed,
    weatherId: weatherObject.weather[0].id,
    weatherTitle: weatherObject.weather[0].main,
    weatherDescription: weatherObject.weather[0].description,
    weatherIcon: `https://openweathermap.org/img/wn/${weatherObject.weather[0].icon}@2x.png`,
  };
}

interface IWeatherDataObject {
  latitude: number;
  longitude: number;
  timezone: string;
  current: IWeather;
  hourly: IWeather[];
}

interface IWeather {
  timestamp: Date;
  temperature: number;
  feelsLike: number;
  pressure: number;
  humidity: number;
  windSpeed: number;
  weatherId: number;
  weatherTitle: string;
  weatherDescription: string;
  weatherIcon: string;
}

checkOpenWeatherMapAPIKey();
export default weatherRouter;
