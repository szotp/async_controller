import 'package:async_controller/async_controller.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';

class AsyncButtonPage extends StatefulWidget with ExamplePage {
  @override
  String get title => 'Async button';

  @override
  _AsyncButtonPageState createState() => _AsyncButtonPageState();
}

class _AsyncButtonPageState extends State<AsyncButtonPage> {
  int _counter = 0;

  Future<void> success() async {
    await Future<void>.delayed(Duration(seconds: 1));
    setState(() {
      _counter++;
    });
  }

  Future<void> failure() async {
    await Future<void>.delayed(Duration(seconds: 1));
    throw 'Failed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Clicks: $_counter'),
            const SizedBox(height: 16),
            AsyncButton(
              child: const Text('This will work'),
              onPressed: success,
              builder: buttonStyleOne,
            ),
            AsyncButton(
              child: const Text('This will fail'),
              onPressed: failure,
              builder: buttonStyleTwo,
              loadingColor: Colors.white,
            ),
            AsyncButton(
              child: const Text('This will not lock interface'),
              onPressed: success,
              builder: buttonStyleOne,
              lockInterface: false,
            ),
            AsyncButton(
              // AsyncButtons takes a child like typical button
              child: const Text('Press me!'),
              // AsyncButton accepts async onPressed method and handles it
              onPressed: () => Future.delayed(Duration(seconds: 1)),
              // Through builder method we can support any kind of button
              builder: (x) => FlatButton(
                onPressed: x.onPressed,
                child: x.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buttonStyleOne(AsyncButtonSettings settings) {
    return SizedBox(
      width: 200,
      child: OutlineButton(
        child: settings.child,
        onPressed: settings.onPressed,
        color: Colors.red,
      ),
    );
  }

  Widget buttonStyleTwo(AsyncButtonSettings settings) {
    return SizedBox(
      width: 200,
      child: FlatButton(
        child: settings.child,
        onPressed: settings.onPressed,
        color: Colors.orange,
        textColor: Colors.white,
      ),
    );
  }
}
