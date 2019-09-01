import 'dart:async';

import 'package:async_controller/async_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  test('test change notifier refresher', () async {
    final notifier = ChangeNotifier();

    final loader = Controller();
    final recorder = Recorder(loader);
    loader.addRefresher(ListeningRefresher(notifier));

    await loader.loadIfNeeded();
    notifier.notifyListeners();
    await loader.loadIfNeeded();

    expect(recorder.snapshots, [
      'noDataYet : null',
      'hasData   : 1',
      'hasData   : 1',
      'hasData   : 2',
    ]);
  });

  test('test periodic refresher', () async {
    final fake = FakeTimer();
    fake.run(() async {
      final notifier = PeriodicRefresher(Duration(seconds: 1));
      expect(fake.tick, 0);

      final loader = Controller();
      loader.addRefresher(notifier);
      final recorder = Recorder(loader);
      await loader.loadIfNeeded();

      expect(recorder.snapshots, [
        'noDataYet : null',
        'hasData   : 1',
      ]);

      fake.fakeTick();

      expect(recorder.snapshots, [
        'noDataYet : null',
        'hasData   : 1',
        'hasData   : 1',
        'hasData   : 2',
      ]);

      expect(fake.isActive, true);
      recorder.dispose();
      expect(fake.isActive, false);
    });
  });
}

class FakeTimer implements Timer {
  Function(Timer timer) f;

  @override
  void cancel() {
    f = null;
  }

  void run(AsyncCallback callback) {
    runZoned(
      callback,
      zoneSpecification: ZoneSpecification(createPeriodicTimer: createPeriodicTimer),
    );
  }

  @override
  bool get isActive => f != null;

  @override
  int tick = 0;

  void fakeTick() {
    tick++;
    f(this);
  }

  Timer createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone, Duration period, void Function(Timer timer) f) {
    return this;
  }
}
