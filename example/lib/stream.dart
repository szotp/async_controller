import 'dart:math';

import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';

class _Loader extends StreamAsyncControlelr<String> {
  final int failureChance;

  _Loader(this.failureChance);

  final _random = Random();

  @override
  Stream<String> getStream(AsyncFetchItem item) {
    return Stream.periodic(Duration(seconds: 1), (i) => i.toString()).map((x) {
      final random = _random.nextInt(100);

      if (random < failureChance) {
        throw 'error';
      } else {
        return x;
      }
    });
  }
}

class _ClosingLoader extends StreamAsyncControlelr<String> {
  @override
  final Duration renewAfter;

  _ClosingLoader(this.renewAfter);

  @override
  Stream<String> getStream(AsyncFetchItem status) async* {
    await Future.delayed(Duration(seconds: 1));
    yield '0';
    await Future.delayed(Duration(seconds: 1));
    yield '1';
    await Future.delayed(Duration(seconds: 1));
    yield '2';
  }
}

class StreamExamplePage extends StatefulWidget with ExamplePage {
  @override
  _StreamExamplePageState createState() => _StreamExamplePageState();

  @override
  String get title => 'stream example';
}

class _StreamExamplePageState extends State<StreamExamplePage> {
  final _loader1 = _Loader(0);
  final _loader2 = _Loader(50);
  final _loader3 = _ClosingLoader(Duration(seconds: 2));

  bool _isActive = true;

  Iterable<AsyncController> get loaders => [_loader1, _loader2, _loader3];

  void refreshAll() {
    for (final loader in loaders) {
      loader.performUserInitiatedRefresh();
    }
  }

  void resetAll() {
    for (final loader in loaders) {
      loader.reset();
    }
  }

  void toggle() {
    setState(() {
      _isActive = !_isActive;
    });
  }

  Widget buildContent(BuildContext context, String string) {
    final ctrl = AsyncData.of(context).controller;
    return ctrl.buildAsyncOpacity(
      selector: () => ctrl.error == null,
      child: Text(string, style: TextStyle(fontSize: 30)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: Center(
        child: Column(
          children: <Widget>[
            FlatButton(
              onPressed: refreshAll,
              child:
                  Text('Refresh (restarts streams without losing last value)'),
            ),
            FlatButton(
              onPressed: resetAll,
              child: Text('Reset (clears everything)'),
            ),
            FlatButton(
              onPressed: toggle,
              child: Text(
                  'Toggle activation (restarts stream after becoming visible)'),
            ),
            SizedBox(height: 30),
            Expanded(child: SizedBox()),
            if (_isActive)
              Column(
                children: <Widget>[
                  Text('Always works:'),
                  _loader1.buildAsyncData(builder: buildContent),
                  Text('Sometimes fails (becomes gray):'),
                  _loader2.buildAsyncData(builder: buildContent),
                  Text('Closes after 3, renews itself:'),
                  _loader3.buildAsyncData(builder: buildContent),
                ],
              ),
            Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
