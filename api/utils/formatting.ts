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
export { parseHHmm };
