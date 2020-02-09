import 'package:flutter_test/flutter_test.dart';
import 'package:async_controller/async_controller.dart';

class Controller extends PagedAsyncController<int> {
  Controller() : super();

  static const largeCount = 10000000;

  int get pageSize => 10;

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
    c.addListener(() {});
    await c.loadIfNeeded();

    expect(c.totalCount, Controller.largeCount);

    for (int i = 0; i < 1000; i++) {
      final item = c.getItem(100);

      if (c.isLoading) {
        await c.loadIfNeeded();
      }

      if (item != null) {
        break;
      }
    }

    expect(c.loadedItemsCount, 110);
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
