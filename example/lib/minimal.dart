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

class Minimal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AsyncData<String>.method(
      fetch: () async {
        await Future<void>.delayed(Duration(seconds: 1));
        return 'Hello world';
      },
      builder: (_, data) {
        return Text(data);
      },
    );
  }
}
