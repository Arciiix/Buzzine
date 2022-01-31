<p align="center">
    <img src="https://github.com/Arciiix/Buzzine/blob/main/icon/icon-1024-regular.png?raw=true" width="120px" height="120px" alt="Buzzine icon">
    <h2 align="center">Buzzine</h2>
</p>

> An improved version of my personal Arduino-based alarm clock, made to work on **Raspberry Pi** (especially with Docker environment). Easy to use **REST API** based on **Socket.io** done with a compound **Node.js** core with some doses of **Python**.
> **Multiple alarms, custom sounds, physical LCD support** and **effective waking up with protection** are only a few of many features.

#### Under development

Everything is under development, the app will evolve slowly, step by step. Even the read me file is under construction and will be better :)

## Important things

1. Make a _default.mp3_ file in _audio/audio_ directory - it will be your default alarm tone

### Environment variables

#### Core

| Name                      | Default value | Description                                                                                                                      | Unit    |
| ------------------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------- |
| PORT                      | 3333          | A port the core will run on                                                                                                      |         |
| MUTE_AFTER                | 15            | The alarm will mute itself after that time if no user action is performed                                                        | minutes |
| RESEND_INTERVAL           | 10            | The core will resend the socket ALARM_RINGING event every specified seconds                                                      | seconds |
| DEFAULT_SNOOZE_LENGTH     | 300           | Default snooze length if nothing is provided as `Alarm.snoozeAlarm()` method param                                               | seconds |
| MAX_TOTAL_SNOOZE_DURATION | 900           | App won't allow to snooze longer than the provided time - the `Alarm` class param, and if it's null - this environment variable. | seconds |
| DISABLE_EMERGENCY         | false         | Disable the emergency alerts (not recommended)                                                                                   | boolean |

#### API

| Name                     | Default value                                     | Description                                             | Unit |
| ------------------------ | ------------------------------------------------- | ------------------------------------------------------- | ---- |
| PORT                     | 1111                                              | A port the API will run on                              |      |
| CORE_URL                 | http://localhost:3333 (to be changed with Docker) | Used for socket.io connection                           |      |
| AUDIO_URL                | http://localhost:7777 (to be changed with Docker) | Used for communication                                  |      |
| OPEN_WEATHER_MAP_API_KEY |                                                   | OpenWeatherMap API key used for the weather information |      |

#### Audio

| Name     | Default value                                     | Description                   | Unit |
| -------- | ------------------------------------------------- | ----------------------------- | ---- |
| PORT     | 7777                                              | A port the API will run on    |      |
| CORE_URL | http://localhost:3333 (to be changed with Docker) | Used for socket.io connection |      |
