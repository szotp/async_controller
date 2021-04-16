import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:async_controller/async_controller.dart';

import 'utils.dart';

class Storage {
  late String string;
  late int number;
}

class TestUpdating extends UpdatingController<Storage> {
  final Future<void> Function(Set<String> keys) updater;

  TestUpdating(this.updater) : super(Storage());

  @override
  Future<void> update(AsyncFetchItem item, Set<String> keys) => updater(keys);

  UpdatingProperty<String> get string =>
      bind('string', (x) => x.string, (x, v) => x.string = v);
  UpdatingProperty<int> get number =>
      bind('login', (x) => x.number, (x, v) => x.number = v);
}

void main() {
  test('test simple', () async {
    final loader = TestUpdating((keys) => Future.value());
    final p = loader.string;
    final r = Recorder.custom(p, () => describeEnum(p.status));

    p.update('x');
    expect(p.status, UpdatingPropertyStatus.needsUpdate);

    await loader.ensureUpdatedOrThrow();

    expect(p.status, UpdatingPropertyStatus.ok);

    expect(r.snapshots, ['ok', 'needsUpdate', 'isUpdating', 'ok']);
  });
}
