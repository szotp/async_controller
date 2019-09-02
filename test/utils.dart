import 'package:async_controller/async_controller.dart';
import 'package:flutter/foundation.dart';

class Controller extends AsyncController<int> {
  int counter = 1;

  bool shouldFail = false;

  Recorder<int> _recorder;
  Recorder<int> get r {
    _recorder ??= Recorder<int>(this);
    return _recorder;
  }

  static Future<Controller> failed() async {
    final p = Controller();
    p.shouldFail = true;
    await p.loadIfNeeded();
    p.r.erase();
    return p;
  }

  static Future<Controller> withData() async {
    final p = Controller();
    await p.loadIfNeeded();
    p.r.erase();
    return p;
  }

  @override
  Future<int> fetch(AsyncFetchItem status) async {
    final willFail = shouldFail;
    shouldFail = false;

    await Future<void>.delayed(Duration.zero);
    if (willFail) {
      throw 'failed';
    } else {
      return counter++;
    }
  }

  /// Ensures that futures were handled
  Future<void> pump() => Future.microtask(() {});
}

class Recorder<T> {
  Recorder(this.input) {
    input.addListener(onChanged);
    onChanged();
  }

  final AsyncController<T> input;
  final data = <T>[];
  final snapshots = <String>[];

  void dispose() {
    input.removeListener(onChanged);
  }

  void erase() {
    snapshots.clear();
  }

  void onChanged() {
    data.add(input.value);
    final s = input.state;

    var name = describeEnum(s);
    name = name.padRight(10);

    final snapshot = '$name: ${input.value ?? input.error}';

    if (snapshots.isNotEmpty && snapshots.last == snapshot) {
      return;
    }

    snapshots.add(snapshot);
  }
}
