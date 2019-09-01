import 'package:async_controller/async_controller.dart';
import 'package:flutter/foundation.dart';

class Controller extends AsyncController<int> {
  int counter = 1;

  bool shouldFail = false;

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

  void onChanged() {
    data.add(input.value);
    final s = input.state;

    var name = describeEnum(s);
    name = name.padRight(10);
    snapshots.add('$name: ${input.value ?? input.error}');
  }
}
