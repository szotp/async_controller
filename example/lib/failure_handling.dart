import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';

class FailureHandlingPage extends StatefulWidget with ExamplePage {
  @override
  _FailureHandlingPageState createState() => _FailureHandlingPageState();

  @override
  String get title => 'Failure handling';
}

class _FailureHandlingPageState extends State<FailureHandlingPage> {
  final _controller = AsyncController<int>.method(() async {
    await Future.delayed(Duration(seconds: 1));
    throw 'Sorry, loading failed.';
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: _controller.buildAsync(builder: (_, data) {
        return Text('OK');
      }),
    );
  }
}
