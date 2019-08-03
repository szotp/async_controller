import 'package:flutter_test/flutter_test.dart';
import 'package:async_controller/async_controller.dart';

class Controller extends PagedAsyncController<int> {
  Controller() : super(10);

  static const largeCount = 10000000;

  @override
  Future<PagedData<int>> fetchPage(int pageIndex) async {
    final data = List.generate(pageSize, (i) => i + pageIndex * pageSize);
    return PagedData<int>(pageIndex, largeCount, data);
  }

  int notifyCount = 0;

  @override
  void notifyListeners() {
    notifyCount++;
    super.notifyListeners();
  }
}

void main() {
  test('fetch distant item', () async {
    final c = Controller();
    await c.loadIfNeeded();

    expect(c.totalCount, Controller.largeCount);

    final t1 = c.getItem(Controller.largeCount - 1);

    expect(t1, null);
    expect(c.isLoading, true);

    await c.loadIfNeeded();
    final t2 = c.getItem(Controller.largeCount - 1);
    expect(t2, isNotNull);
  });

  test('getItem must not notify', () async {
    final c = Controller();
    await c.loadIfNeeded();

    final counter1 = c.notifyCount;
    c.getItem(Controller.largeCount - 1);
    final counter2 = c.notifyCount;
    expect(counter2, counter1);
  });
}
