class HistoricalAlarm {
  String id;
  DateTime invocationDate;
  String? name;
  String? notes;

  HistoricalAlarm(
      {required this.id, required this.invocationDate, this.name, this.notes});
}
