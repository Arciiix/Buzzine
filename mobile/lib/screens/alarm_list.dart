import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_form.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:flutter/material.dart';

class AlarmList extends StatefulWidget {
  final Alarm? selectedAlarm;
  final bool Function(Alarm)? filter;

  const AlarmList({Key? key, this.selectedAlarm, this.filter})
      : super(key: key);

  @override
  _AlarmListState createState() => _AlarmListState();
}

class _AlarmListState extends State<AlarmList> {
  late List<Alarm> alarms;
  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  void addAlarm(Alarm? selectedAlarm) async {
    Alarm? alarm = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AlarmForm(baseAlarm: selectedAlarm),
    ));

    if (alarm != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleLoadingDialog("Trwa tworzenie alarmu...");
        },
      );
      await GlobalData.addAlarm(alarm.toMap(), selectedAlarm != null);
      Navigator.of(context).pop();
      await _refreshState.currentState!.show();
    }
  }

  void deleteAlarm(Alarm alarmToDelete) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa usuwanie alarmu...");
      },
    );
    await GlobalData.deleteAlarm(alarmToDelete.id ?? "");
    Navigator.of(context).pop();
    showSnackbar(context, "Usunięto alarm!");
    await _refreshState.currentState!.show();
  }

  @override
  void initState() {
    super.initState();
    if (widget.filter != null) {
      alarms = GlobalData.alarms.where(widget.filter!).toList();
    } else {
      alarms = GlobalData.alarms;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Alarmy")),
        floatingActionButton: FloatingActionButton(
          onPressed: () => addAlarm(null),
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
            key: _refreshState,
            onRefresh: () async {
              await GlobalData.getData();
              setState(() {
                if (widget.filter != null) {
                  alarms = GlobalData.alarms.where(widget.filter!).toList();
                } else {
                  alarms = GlobalData.alarms;
                }
              });
            },
            child: alarms.isNotEmpty
                ? Scrollbar(
                    child: ListView.builder(
                        itemCount: alarms.length,
                        itemBuilder: (BuildContext context, int index) {
                          Alarm e = alarms[index];
                          return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              child: Dismissible(
                                  key: ObjectKey(e),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.only(right: 20),
                                      color: Colors.red,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: const [
                                          Icon(Icons.delete,
                                              color: Colors.white),
                                          Text("Usuń",
                                              style: TextStyle(
                                                  color: Colors.white))
                                        ],
                                      )),
                                  confirmDismiss:
                                      (DismissDirection direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Usuń alarm"),
                                          content: Text(
                                              'Czy na pewno chcesz usunąć ${e.name != null ? "${e.name}" : "ten alarm"}?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text("Anuluj"),
                                            ),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text("Usuń")),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (DismissDirection direction) {
                                    deleteAlarm(e);
                                  },
                                  child: InkWell(
                                      onTap: () => addAlarm(e),
                                      child: SizedBox(
                                          height: 360,
                                          child: AlarmCard(
                                            id: e.id!,
                                            name: e.name,
                                            hour: e.hour,
                                            minute: e.minute,
                                            nextInvocation: e.nextInvocation,
                                            isActive: e.isActive,
                                            isSnoozeEnabled: e.isSnoozeEnabled,
                                            deleteAfterRinging:
                                                e.deleteAfterRinging,
                                            maxTotalSnoozeDuration:
                                                e.maxTotalSnoozeDuration,
                                            sound: e.sound,
                                            isGuardEnabled: e.isGuardEnabled,
                                            notes: e.notes,
                                            isRepeating: e.isRepeating,
                                            emergencyAlarmTimeoutSeconds:
                                                e.emergencyAlarmTimeoutSeconds,
                                            repeat: e.repeat,
                                            // refresh: () async =>       await _refreshState.currentState!.show()
                                          )))));
                        }),
                  )
                : const Center(
                    child: Text("Brak alarmów!",
                        style: TextStyle(fontSize: 32, color: Colors.white)))));
  }
}
