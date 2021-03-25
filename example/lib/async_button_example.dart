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
    await Future<void>.delayed(const Duration(seconds: 1));
    setState(() {
      _counter++;
    });
  }

  Future<void> failure() async {
    await Future<void>.delayed(const Duration(seconds: 1));
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
              onPressed: success,
              builder: buttonStyleOne,
              child: const Text('This will work'),
            ),
            AsyncButton(
              onPressed: failure,
              builder: buttonStyleTwo,
              loadingColor: Colors.white,
              child: const Text('This will fail'),
            ),
            AsyncButton(
              onPressed: success,
              builder: buttonStyleOne,
              lockInterface: false,
              child: const Text('This will not lock interface'),
            ),
            AsyncButton(
              // AsyncButton accepts async onPressed method and handles it
              onPressed: () => Future.delayed(const Duration(seconds: 1)),
              // Through builder method we can support any kind of button
              builder: (x) => TextButton(
                onPressed: x.onPressed,
                child: x.child,
              ),
              // AsyncButtons takes a child like typical button
              child: const Text('Press me!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buttonStyleOne(AsyncButtonSettings settings) {
    return SizedBox(
      width: 200,
      child: OutlinedButton(
        onPressed: settings.onPressed,
        style:
            ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.red)),
        child: settings.child,
      ),
    );
  }

  Widget buttonStyleTwo(AsyncButtonSettings settings) {
    return SizedBox(
      width: 200,
      child: TextButton(
        onPressed: settings.onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.orange),
          foregroundColor: MaterialStateProperty.all(Colors.white),
        ),
        child: settings.child,
      ),
    );
  }
}
