import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';

class MinimalExample extends StatelessWidget with ExamplePage {
  @override
  String get title => 'Minimal example';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Center(
        child: Minimal(),
      ),
    );
  }
}

/// In real world app, I would recommend using provider or flutter_hooks to create the controller
/// Storing data globally is generally a bad practice.
final _controller = AsyncController<String>.method(() async {
  await Future<void>.delayed(Duration(seconds: 1));
  return 'Hello world';
});

class Minimal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _controller.buildAsyncData(builder: (_, data) {
      // This builder runs only if data is available.
      // buildAsyncData takes care of other situations
      return Text(data);
    });
  }
}
