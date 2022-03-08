<p align="center">
    <img src="https://github.com/Arciiix/Buzzine/blob/main/icon/icon-1024-regular.png?raw=true" width="120px" height="120px" alt="Buzzine icon">
    <h2 align="center">Buzzine</h2>
</p>

> An improved version of my personal Arduino-based **alarm clock**, made to work on Raspberry Pi (especially with Docker environment). Easy to use **REST API** based on **Socket.io** done with a compound **Node.js core** and many other services, including **physical device support** (using **Tasmota on ESP8266** based devices).
> **Multiple alarms, custom sounds, sleep and indoor temperature data, and effective waking up with protection** are only a few of many features.

## Made with ❤️ by Arciiix 2021/2022

This is my biggest project at the time, I'm 15 years old now and so excited about it :DD <br>
Mainly done during two school winter breaks. <br>
I think I'll miss those great moments I came through while making the Buzzine, I put so much heart into it ❤️

#### Under development

Everything is under development, the app will evolve slowly, step by step. Even the README file is under construction and will be better :)

## So many modules...

Buzzine is built on the modular application design - every unit of it is split into a functional microservice. The microservices communicate with each other.

| Service name | Description                                                                                                                                                                                                                                                                                           | Default port |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| core         | The core of the app - a basic module. Other microservices cannot run without it. Handles all the alarm logic.                                                                                                                                                                                         | 3333         |
| API          | The way Buzzine communicates with the outside world (e.g. used by the mobile app). It's also used to exchange information through notifications or fetch weather from an external [`OpenWeatherMap`](https://openweathermap.org/api) API.                                                             | 1111         |
| audio        | That's the one you can judge for waking you up - it uses [`ffplay`](https://ffmpeg.org/ffplay.html) to play sound. It also allows to add new audio, e.g. from YouTube, or cut it (using [`ffmpeg`](https://ffmpeg.org/)).                                                                             | 7777         |
| adapter      | It's called an adapter, because it's used to communicate with different interfaces, not built into the app, for example [`Tasmota`](https://tasmota.github.io/docs/). It's used for emergency and getting the temperature, so you may also call it ou may also call it "emergency" or "temperatures". | 2222         |
| tracking     | It's a service that's built to analyze your sleep and make it better. It gathers the sleep data, for example when you go to bed and when you actually go to sleep, or when you wake up vs when you get out of the bed.                                                                                | 4444         |
| mobile       | A mobile app built with Flutter that makes "talking" to the whole Buzzine app easy.                                                                                                                                                                                                                   | -            |

## Important things

1. Make a _default.mp3_ file in _audio/audio_ directory - it will be your default alarm tone. Ensure you have ffmpeg and ffplay installed.
2. Provide the OpenWeatherMap API key as an API microservice environment variable OPEN_WEATHER_MAP_API_KEY (see below).
3. Remember - if you compile the code using `tsc` command, you will find the output files in the /dist folder of each microservice.

   **Important: copy all the necessary assets into that folder**, e.g., audio/default.mp3 when it comes to the audio service or the database. Use the `copyFilesToDist.cmd` script.

4. Adapter is a microservice used for emergency. If you wish to use it, flash ESP8266 with Tasmota and pass its IP adress as an environment variable to the adapter.
5. Remember to initialize a Firebase project and update the necessary config, such as `google-services.json` on mobile or `firebaseServiceAccountKey.json` on API

## Database

The database used in this project is [`SQLite`](https://www.sqlite.org/index.html) together with [`Sequelize`](https://sequelize.org/) ORM. I migrated to [`Prisma`](https://www.prisma.io/) once (commits [28b742db26efd8fe980b25aeed4d188160f20a69](https://github.com/Arciiix/Buzzine/commit/28b742db26efd8fe980b25aeed4d188160f20a69), [c6c3af4a963db09db625f1aba38d672d6c730547](https://github.com/Arciiix/Buzzine/commit/c6c3af4a963db09db625f1aba38d672d6c730547), [ee03827ad40600000b88309ac15f435a345897ad](https://github.com/Arciiix/Buzzine/commit/ee03827ad40600000b88309ac15f435a345897ad)), but when deploying the app, it seemed that **Prisma** is much slower than **Sequelize** on my production machine.

### Environment variables

#### Core

| Name                      | Default value | Description                                                                                                                      | Unit    |
| ------------------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------- |
| PORT                      | 3333          | A port the core will run on                                                                                                      |         |
| MUTE_AFTER                | 10            | The alarm will mute itself after that time if no user action is performed                                                        | minutes |
| EMERGENCY_MUTE_AFTER      | 15            | The emergency alarm will mute itself after that time if no user action is performed                                              | minutes |
| RESEND_INTERVAL           | 10            | The core will resend the socket ALARM_RINGING event every specified seconds                                                      | seconds |
| DEFAULT_SNOOZE_LENGTH     | 300           | Default snooze length if nothing is provided as `Alarm.snoozeAlarm()` method param                                               | seconds |
| MAX_TOTAL_SNOOZE_DURATION | 900           | App won't allow to snooze longer than the provided time - the `Alarm` class param, and if it's null - this environment variable. | seconds |
| DISABLE_EMERGENCY         | false         | Disable the emergency alerts (not recommended)                                                                                   | boolean |

#### API

| Name                        | Default value                                     | Description                                                                                | Unit    |
| --------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------- |
| PORT                        | 1111                                              | A port the API will run on                                                                 |         |
| CORE_URL                    | http://localhost:3333 (to be changed with Docker) | Used for socket.io connection                                                              |         |
| AUDIO_URL                   | http://localhost:7777 (to be changed with Docker) | Used for communication                                                                     |         |
| OPEN_WEATHER_MAP_API_KEY    |                                                   | OpenWeatherMap API key used for the weather information                                    |         |
| ADAPTER_URL                 | http://localhost:2222 (to be changed with Docker) | Used for emergency requests                                                                |         |
| SLEEP_AS_ANDROID_MUTE_AFTER | 10                                                | The Sleep as Android alarm will mute itself after that time if no user action is performed | minutes |
| TRACKING_URL                | http://localhost:4444 (to be changed with Docker) | Used for saving sleep data                                                                 |         |

#### Audio

| Name     | Default value                                     | Description                   | Unit |
| -------- | ------------------------------------------------- | ----------------------------- | ---- |
| PORT     | 7777                                              | A port the API will run on    |      |
| CORE_URL | http://localhost:3333 (to be changed with Docker) | Used for socket.io connection |      |

#### Adapter

| Name                | Default value                                     | Description                                                                                       | Unit    |
| ------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------- |
| PORT                | 2222                                              | A port the app will run on.                                                                       |         |
| TAMOSTA_URL         | http://192.168.0.130                              | Tasmota's IP adress used to communicate with the module.                                          |         |
| RELAY_INDEX         | 1                                                 | Which Tasmota relay to use as emergency. It will inject this into "Power" command, e.g. "Power1". |         |
| CORE_URL            | http://localhost:3333 (to be changed with Docker) | Used for socket.io connection.                                                                    |         |
| HEARTBEAT_CRONJOB   | _/3 _ \* \* \*                                    | Cronjob used to send the heartbeat to Tasmota. Default is every 3rd minute.                       | cron    |
| TEMPERATURE_CRONJOB | _/15 _ \* \* \*                                   | Cronjob used to fetch the temperature. Default is every 15th minute.                              | cron    |
| PROTECTION_DELAY    | 600                                               | Injected into Tasmota command RuleTimer1 x (where x is the value)                                 | seconds |

#### Tracking

| Name                     | Default value                                     | Description                                                                                                                                 | Unit  |
| ------------------------ | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| PORT                     | 4444                                              | A port the app will run on.                                                                                                                 |       |
| API_URL                  | http://localhost:1111 (to be changed with Docker) | Used for communication with the API.                                                                                                        |       |
| VERSION_HISTORY_MAX_DAYS | 7                                                 | The version history of given tracking entity will delete itself after that amount of days.                                                  | days  |
| TRACKER_DAY_START        | 20:00                                             | The tracker next day will start at that time. Generally it's the latest you would ever wake up and the earliest you would ever go to sleep. | HH:mm |
| STATS_REFRESH_TIME       | 15:00                                             | The tracking stats will be regenerated at that time. It requires some time if there's a lot of data.                                        | HH:mm |
