import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_form.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/AlarmType.dart';
import 'package:buzzine/types/Nap.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:flutter/material.dart';

class NapList extends StatefulWidget {
  final Nap? selectedNap;
  final bool Function(Nap)? filter;

  const NapList({Key? key, this.selectedNap, this.filter}) : super(key: key);

  @override
  _NapListState createState() => _NapListState();
}

class _NapListState extends State<NapList> {
  late List<Nap> naps;
  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  void addNap(Nap? selectedNap) async {
    Alarm? nap = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>
          AlarmForm(baseAlarm: selectedNap, alarmType: AlarmType.nap),
    ));

    if (nap != null) {
      Nap castedNap = Nap(
        id: nap.id,
        name: nap.name,
        hour: nap.hour,
        minute: nap.minute,
        second: nap.second,
        isSnoozeEnabled: nap.isSnoozeEnabled,
        maxTotalSnoozeDuration: nap.maxTotalSnoozeDuration,
        sound: nap.sound,
        isGuardEnabled: nap.isGuardEnabled,
        deleteAfterRinging: nap.deleteAfterRinging,
        notes: nap.notes,
        emergencyAlarmTimeoutSeconds: nap.emergencyAlarmTimeoutSeconds,
        isActive: false,
      );

      await GlobalData.addNap(castedNap.toMap(), selectedNap != null);

      await _refreshState.currentState!.show();
    }
  }

  void deleteNap(Nap napToDelete) async {
    await GlobalData.deleteAlarm(napToDelete.id ?? "");
    showSnackbar(context, "Usunięto drzemkę!");
    await _refreshState.currentState!.show();
  }

  @override
  void initState() {
    super.initState();
    if (widget.filter != null) {
      naps = GlobalData.naps.where(widget.filter!).toList();
    } else {
      naps = GlobalData.naps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Drzemki")),
        floatingActionButton: FloatingActionButton(
          onPressed: () => addNap(null),
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
            key: _refreshState,
            onRefresh: () async {
              await GlobalData.getData();
              setState(() {
                if (widget.filter != null) {
                  naps = GlobalData.naps.where(widget.filter!).toList();
                } else {
                  naps = GlobalData.naps;
                }
              });
            },
            child: naps.isNotEmpty
                ? Scrollbar(
                    child: ListView.builder(
                        itemCount: naps.length,
                        itemBuilder: (BuildContext context, int index) {
                          Nap e = naps[index];
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
                                          title: const Text("Usuń drzemkę"),
                                          content: Text(
                                              'Czy na pewno chcesz usunąć ${e.name != null ? "${e.name}" : "tę drzemkę"}?'),
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
                                    deleteNap(e);
                                  },
                                  child: InkWell(
                                      onTap: () => addNap(e),
                                      child: SizedBox(
                                        height: 360,
                                        child: AlarmCard(
                                            alarmType: AlarmType.nap,
                                            key: Key(e.id!),
                                            id: e.id!,
                                            name: e.name,
                                            hour: e.hour,
                                            minute: e.minute,
                                            second: e.second,
                                            nextInvocation: e.invocationDate,
                                            isActive: e.isActive,
                                            isSnoozeEnabled: e.isSnoozeEnabled,
                                            maxTotalSnoozeDuration:
                                                e.maxTotalSnoozeDuration,
                                            sound: e.sound,
                                            isGuardEnabled: e.isGuardEnabled,
                                            deleteAfterRinging:
                                                e.deleteAfterRinging,
                                            notes: e.notes,
                                            isRepeating: false,
                                            emergencyAlarmTimeoutSeconds:
                                                e.emergencyAlarmTimeoutSeconds,
                                            refresh: () async {
                                              await _refreshState.currentState!
                                                  .show();
                                            }),
                                      ))));
                        }),
                  )
                : const Center(
                    child: Text("Brak alarmów!",
                        style: TextStyle(fontSize: 32, color: Colors.white)))));
  }
}
