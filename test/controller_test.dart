import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:async_controller/async_controller.dart';

import 'utils.dart';

void main() {
  test('test initial conditions', () {
    final loader = Controller();
    expect(loader.value, null);
    expect(loader.snapshot,
        const AsyncSnapshot<int>.nothing().inState(ConnectionState.waiting));
  });

  test('test loads on listener', () {
    final loader = Controller();
    loader.addListener(() {});
    expect(loader.snapshot,
        const AsyncSnapshot<int>.nothing().inState(ConnectionState.waiting));
  });

  test('test loads on listeners', () async {
    final loader = Controller();

    expect(loader.isLoading, isFalse);
    loader.addListener(() {});
    expect(loader.isLoading, isTrue);
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
    final f1 = loader.performUserInitiatedRefresh();
    final f2 = loader.performUserInitiatedRefresh();
    final f3 = loader.performUserInitiatedRefresh();
    await Future.wait([f1, f2, f3]);
    expect(loader.value, 4);
    expect(recorder.snapshots, [
      'noDataYet : null',
      'hasData   : 4',
    ]);
  });

  test('test refresh keeps data', () async {
    final loader = Controller();
    final recorder = Recorder(loader);
    await loader.loadIfNeeded();
    await loader.performUserInitiatedRefresh();

    expect(recorder.snapshots, [
      'noDataYet : null',
      'hasData   : 1',
      'hasData   : 2',
    ]);
  });

  test('test refresh erases error', () async {
    final loader = Controller();
    loader.shouldFail = true;
    final recorder = Recorder(loader);
    await loader.loadIfNeeded();
    await loader.performUserInitiatedRefresh();
    expect(recorder.snapshots, [
      'noDataYet : null',
      'failed    : failed',
      'noDataYet : failed',
      'hasData   : 1',
    ]);
  });

  test('test reset', () async {
    final loader = Controller();
    final recorder = Recorder(loader);
    await loader.loadIfNeeded();
    await loader.reset();

    expect(recorder.snapshots, [
      'noDataYet : null',
      'hasData   : 1',
      'noDataYet : null',
      'hasData   : 2',
    ]);
  });

  test('test multiple loadIfNeeded', () async {
    final loader = Controller();
    final recorder = Recorder(loader);
    loader.loadIfNeeded();
    loader.loadIfNeeded();
    loader.loadIfNeeded();
    await loader.loadIfNeeded();

    expect(recorder.snapshots, [
      'noDataYet : null',
      'hasData   : 1',
    ]);
  });

  test('test instant success', () async {
    final loader = AsyncController<int>.method(() async => 1);
    loader.addListener(() {});
    await Future.microtask(() {});
    expect(loader.value, 1);
    expect(loader.state, AsyncControllerState.hasData);
  });

  test('test instant failure', () async {
    final loader = AsyncController<int>.method(() async => throw 'failed');
    loader.addListener(() {});
    await Future.microtask(() {});
    expect(loader.error, 'failed');
    expect(loader.state, AsyncControllerState.failed);
  });
}
