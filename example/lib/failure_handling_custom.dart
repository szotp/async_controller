import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';

class FailureHandlingCustomPage extends StatefulWidget with ExamplePage {
  @override
  _FailureHandlingCustomPageState createState() => _FailureHandlingCustomPageState();

  @override
  String get title => 'Failure handling custom';
}

class _FailureHandlingCustomPageState extends State<FailureHandlingCustomPage> {
  final _controller = AsyncController<int>.method(() async {
    await Future<void>.delayed(Duration(seconds: 1));
    throw 'Sorry, loading failed.';
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: _controller.buildAsyncData(
        builder: (_, data) {
          return const Text('OK');
        },
        decorator: CustomAsyncDataDecoration(),
      ),
    );
  }
}

class CustomAsyncDataDecoration extends AsyncDataDecoration {
  @override
  Widget buildError(BuildContext context, dynamic error, VoidCallback tryAgain) {
    return Text('Sorry :(');
  }
}
