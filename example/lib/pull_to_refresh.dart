import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<List<String>> fetch() async {
  await Future.delayed(Duration(seconds: 1));
  final date = DateTime.now();
  final format = DateFormat.Hms();
  return [format.format(date), 'Hello', 'World'];
}

class PullToRefreshPage extends StatefulWidget with ExamplePage {
  @override
  _PullToRefreshPageState createState() => _PullToRefreshPageState();

  @override
  String get title => 'Pull to refresh';
}

class _PullToRefreshPageState extends State<PullToRefreshPage> {
  final controller = AsyncController.method(fetch)
    ..addRefresher(OnReconnectedRefresher())
    ..addRefresher(PeriodicRefresher(Duration(seconds: 10)));

  final formatter = DateFormat.Hms();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: Column(
        children: <Widget>[
          FlatButton(child: Text('Reset'), onPressed: controller.reset),
          Expanded(
            child: RefreshIndicator(
              /// Calling controller.refresh in RefreshIndicator is all you need to implement pull to refresh
              onRefresh: controller.refresh,
              child: AsyncBuilder<List<String>>(
                controller: controller,
                builder: (context, data) {
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        title: Text(data[i]),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
