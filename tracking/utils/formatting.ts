function toDateString(date: Date): string {
  return `${addZero(date.getDate())}.${addZero(
    date.getMonth() + 1
  )}.${date.getFullYear()}`;
}

function toDateTimeString(date: Date, includeSeconds?: boolean): string {
  return `${addZero(date.getHours())}:${addZero(date.getMinutes())}${
    includeSeconds ? ":" + addZero(date.getSeconds()) : ""
  } ${toDateString(date)}`;
}

function dateTimeToDateOnly(date: Date): Date {
  //Clear the time part of a date
  return new Date(
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
  );
}

function addZero(num: number): string {
  return num.toString().padStart(2, "0");
}

function parseHHmm(
  inputText: string,
  defaultValue: { hour: number; minute: number }
): { hour: number; minute: number } {
  let parsed = inputText.split(":");
  if (
    isNaN(parseInt(parsed[0])) ||
    isNaN(parseInt(parsed[1])) ||
    parseInt(parsed[0]) < 0 ||
    parseInt(parsed[0]) > 23 ||
    parseInt(parsed[1]) < 0 ||
    parseInt(parsed[1]) > 59
  ) {
    return defaultValue;
  }
  return { hour: parseInt(parsed[0]), minute: parseInt(parsed[1]) };
}

export {
  toDateString,
  toDateTimeString,
  dateTimeToDateOnly,
  addZero,
  parseHHmm,
};
