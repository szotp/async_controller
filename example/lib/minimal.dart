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

/// Because this controller has been created as static global property, it will keep the data for entire life of the app.
/// Typically it is better to create it inside StatefulWidget's state to ensure that data is delete after user logged out.
final _controller = AsyncController<String>.method(() async {
  await Future.delayed(Duration(seconds: 1));
  return 'Hello world';
});

class Minimal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _controller.buildAsync(builder: (_, data) {
      return Text(data);
    });
  }
}
