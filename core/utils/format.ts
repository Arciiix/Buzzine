function addZero(num: number): string {
  return num < 10 ? `0${num.toString()}` : num.toString();
}

function formatTime(hour: number, minute: number, second?: number) {
  return `${addZero(hour)}:${addZero(minute)}${
    second ? ":" + addZero(second) : ""
  }`;
}

function formatDate(date: Date, includeTime = true) {
  return `${addZero(date.getDate())}.${addZero(
    date.getMonth() + 1
  )}.${date.getFullYear()}${
    includeTime ? " " + formatTime(date.getHours(), date.getMinutes()) : ""
  }`;
}

export { addZero, formatTime, formatDate };
