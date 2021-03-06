class Repeat {
  //Indexes of elements in daysOfWeek enum
  List<int>? daysOfWeek;
  List<int>? days;
  List<int>? months;

  Repeat({this.daysOfWeek, this.days, this.months});

  Map toMap() {
    return {
      'dayOfWeek': daysOfWeek,
      'date': days,
      'month': months,
      'tz': "Europe/Warsaw"
    };
  }
}

const List<String> daysOfWeek = [
  "niedziela",
  "poniedziałek",
  "wtorek",
  "środa",
  "czwartek",
  "piątek",
  "sobota",
];
const List<String> months = [
  "Styczeń",
  "Luty",
  "Marzec",
  "Kwiecień",
  "Maj",
  "Czerwiec",
  "Lipiec",
  "Sierpień",
  "Wrzesień",
  "Październik",
  "Listopad",
  "Grudzień",
];
