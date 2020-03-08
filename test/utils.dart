import 'package:async_controller/async_controller.dart';
import 'package:flutter/foundation.dart';

class Controller extends AsyncController<int> {
  int counter = 1;

  bool shouldFail = false;

  Recorder _recorder;
  Recorder get r {
    return _recorder ??= Recorder(this);
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

  Future<void> waitUntilFinished() async {
    while (isLoading) {
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  /// Ensures that futures were handled
  Future<void> pump() => Future.microtask(() {});
}

class Recorder {
  factory Recorder(AsyncController input) {
    String takeSnapshot() {
      final s = input.state;

      var name = describeEnum(s);
      name = name.padRight(10);

      final snapshot = '$name: ${input.value ?? input.error}';

      return snapshot;
    }

    return Recorder.custom(input, takeSnapshot);
  }

  Recorder.custom(this.input, this.snapshotter) {
    input.addListener(onChanged);
    onChanged();
  }

  final Listenable input;
  final String Function() snapshotter;
  final List<String> snapshots = <String>[];

  void dispose() {
    input.removeListener(onChanged);
  }

  void erase() {
    snapshots.clear();
  }

  void onChanged() {
    final snapshot = snapshotter();

    if (snapshots.isNotEmpty && snapshots.last == snapshot) {
      return;
    }

    snapshots.add(snapshot);
  }
}
