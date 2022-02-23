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
export { toDateString, toDateTimeString, dateTimeToDateOnly, addZero };
