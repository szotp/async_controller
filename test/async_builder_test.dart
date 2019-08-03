import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:async_controller/async_controller.dart';

class Controller extends AsyncController<int> {
  int counter = 1;

  bool shouldFail = false;

  @override
  Future<int> fetch(AsyncStatus status) {
    bool willFail = shouldFail;
    shouldFail = false;

    return Future.microtask(() {
      if (willFail) {
        throw 'failed';
      }
      return counter++;
    });
  }
}

class Recorder<T> {
  final AsyncController<T> input;
  final data = <T>[];
  final snapshots = <String>[];

  Recorder(this.input) {
    input.addListener(onChanged);
    onChanged();
  }

  void dispose() {
    input.removeListener(onChanged);
  }

  void onChanged() {
    data.add(input.value);
    final s = input.snapshot;

    var name = s.connectionState.toString();
    name = name.replaceFirst('ConnectionState.', '');
    name = name.padRight(8);
    snapshots.add('$name: ${s.data ?? s.error}');
  }
}

void main() {
  test('test initial conditions', () {
    final loader = Controller();
    expect(loader.value, null);
    expect(loader.snapshot, AsyncSnapshot.nothing());
  });

  test('test loads on listener', () {
    final loader = Controller();
    loader.addListener(() {});
    expect(loader.snapshot, AsyncSnapshot.nothing().inState(ConnectionState.waiting));
  });

  test('test loads on listener and finishes', () async {
    final loader = Controller();
    loader.addListener(() {});
    await Future.value();
    expect(loader.snapshot, AsyncSnapshot.withData(ConnectionState.done, 1));
  });

  test('test loadIfNeeded once', () async {
    final loader = Controller();
    final f1 = loader.loadIfNeeded();
    final f2 = loader.loadIfNeeded();
    final f3 = loader.loadIfNeeded();
    await Future.wait([f1, f2, f3]);
    expect(loader.value, 1);
  });

  test('test refresh works multiple times', () async {
    final loader = Controller();
    final recorder = Recorder(loader);
    final f1 = loader.refresh();
    final f2 = loader.refresh();
    final f3 = loader.refresh();
    await Future.wait([f1, f2, f3]);
    expect(loader.value, 4);
    expect(recorder.snapshots, [
      'waiting : null',
      'done    : 4',
    ]);
  });

  test('test refresh keeps data', () async {
    final loader = Controller();
    final recorder = Recorder(loader);
    await loader.loadIfNeeded();
    await loader.refresh();
    expect(recorder.snapshots, [
      'waiting : null',
      'done    : 1',
      'waiting : 1',
      'done    : 2',
    ]);
  });

  test('test refresh erases error', () async {
    final loader = Controller();
    loader.shouldFail = true;
    final recorder = Recorder(loader);
    await loader.loadIfNeeded();
    await loader.refresh();
    expect(recorder.snapshots, [
      'waiting : null',
      'done    : failed',
      'waiting : null',
      'done    : 1',
    ]);
  });
}
