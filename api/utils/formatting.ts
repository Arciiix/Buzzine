function addZero(num: number): string {
  return num.toString().padStart(2, "0");
}
function dateTimeToDateOnly(date: Date): Date {
  //Clear the time part of a date
  return new Date(
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())
  );
}

export { addZero, dateTimeToDateOnly };
