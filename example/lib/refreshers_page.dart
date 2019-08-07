import 'package:async_controller/async_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'helpers.dart';

class RefreshersPage extends StatefulWidget with ExamplePage {
  @override
  String get title => 'Refreshers';

  @override
  _RefreshersPageState createState() => _RefreshersPageState();
}

class _RefreshersPageState extends State<RefreshersPage> {
  final controllerA = AsyncController<DateTime>.method(() => Future.value(DateTime.now()))
    ..addRefresher(
      PeriodicRefresher(Duration(seconds: 1)),
    );

  final controllerB = AsyncController<DateTime>.method(() => Future.value(DateTime.now()))
    ..addRefresher(
      InForegroundRefresher(),
    );

  final controllerC = AsyncController<DateTime>.method(() async {
    await Future<void>.delayed(Duration(seconds: 3));
    throw 'Failed';
  })
    ..addRefresher(
      OnReconnectedRefresher(),
    );

  final formatter = DateFormat.Hms();

  Widget buildClock(AsyncController<DateTime> controller, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(description),
          SizedBox(height: 4),
          Container(
            alignment: Alignment.center,
            child: controller.buildAsyncData(
              builder: (context, date) {
                return Text(
                  formatter.format(date),
                  style: TextStyle(fontSize: 30),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: ListView(
        children: <Widget>[
          buildClock(controllerA, 'This timer updates every second'),
          buildClock(controllerB, 'This timer updates when app goes to foreground'),
          buildClock(controllerC, 'This timer always fails but tries to refresh when connection goes back. Try toggling airplane mode.')
        ],
      ),
    );
  }
}
