import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_form.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:flutter/material.dart';

class AlarmList extends StatefulWidget {
  final Alarm? selectedAlarm;

  const AlarmList({Key? key, this.selectedAlarm}) : super(key: key);

  @override
  _AlarmListState createState() => _AlarmListState();
}

class _AlarmListState extends State<AlarmList> {
  late List<Alarm> alarms;

  void addAlarm(Alarm? selectedAlarm) async {
    Alarm? alarm = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AlarmForm(baseAlarm: selectedAlarm),
    ));

    if (alarm != null) {
      await GlobalData.addAlarm(alarm.toMap(), selectedAlarm != null);
      await GlobalData.getData();
      setState(() {
        alarms = GlobalData.alarms;
      });
    }
  }

  void deleteAlarm(Alarm alarmToDelete) async {
    await GlobalData.deleteAlarm(alarmToDelete.id ?? "");
    showSnackbar(context, "Usunięto alarm!");
    await GlobalData.getData();
    setState(() {
      alarms = GlobalData.alarms;
    });
  }

  @override
  void initState() {
    super.initState();
    alarms = GlobalData.alarms;
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
            onRefresh: () async {
              await GlobalData.getData();
              setState(() {
                alarms = GlobalData.alarms;
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
                                          height: 320,
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
                                            repeat: e.repeat,
                                          )))));
                        }),
                  )
                : const Center(
                    child: Text("Brak alarmów!",
                        style: TextStyle(fontSize: 32, color: Colors.white)))));
  }
}
