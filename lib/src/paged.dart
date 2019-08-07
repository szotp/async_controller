import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import 'async_builder.dart';
import 'controller.dart';

/// A slice of bigger array, returned from backend. All values must not be null.
class PagedData<T> {
  PagedData(this.index, this.totalCount, this.data);

  final int index;
  final int totalCount;
  final List<T> data;
}

/// Loads data into array, in pages.
/// The value of loader is totalCount of items available. The actual items can be fetched using getItem method.
abstract class PagedAsyncController<T> extends AsyncController<int> {
  PagedAsyncController(this.pageSize, {CacheMap<int, PagedData<T>> cache}) : _cache = cache ?? CacheMap(10);

  final CacheMap<int, PagedData<T>> _cache;
  final int pageSize;

  int _loadedItemsCount = 0;

  /// Widget uses this property to determine curently visible amount of items.
  int get loadedItemsCount => _loadedItemsCount;

  int get totalCount => value;

  Future<PagedData<T>> fetchPage(int pageIndex);

  Future<int> _fetchPage(int pageIndex, AsyncStatus status) async {
    try {
      final page = await fetchPage(pageIndex);
      if (!status.isCancelled) {
        _cache[pageIndex] = page;
        _loadedItemsCount = max(_loadedItemsCount, pageIndex * pageSize + page.data.length);
      }
      return page.totalCount;
    } catch (e) {
      _cache[pageIndex] = PagedData(pageIndex, totalCount, null);
      rethrow;
    }
  }

  @override
  Future<int> fetch(AsyncStatus status) async {
    return _fetchPage(0, status);
  }

  @override
  void reset() {
    _loadedItemsCount = 0;
    _cache.clear();
    super.reset();
  }

  @override
  bool get hasData => value != 0 && version > 0;

  void refreshFailedPage() {
    final lastPageIndex = _cache._queue.last;
    schedulePageLoad(lastPageIndex);
  }

  void schedulePageLoad(int pageIndex) {
    if (isLoading) {
      return;
    }
    internallyLoadAndNotify((status) => _fetchPage(pageIndex, status));
  }

  /// If data for given item is not loaded, getItem will return null and schedule a page load.
  /// After page is loaded, notifyListeners will be called, which will trigger listener widget to reload.
  T getItem(int itemIndex) {
    final pageIndex = itemIndex ~/ pageSize;
    final itemIndexInPage = itemIndex - pageIndex * pageSize;
    final page = _cache[pageIndex];

    if (page != null) {
      if (page.data != null) {
        return page.data[itemIndexInPage];
      } else {
        return null;
      }
    } else {
      schedulePageLoad(pageIndex);
      return null;
    }
  }
}

class PagedListView<T> extends StatelessWidget {
  const PagedListView({
    Key key,
    @required this.dataController,
    this.scrollController,
    @required this.itemBuilder,
    this.decoration = PagedListDecoration.empty,
  }) : super(key: key);

  final PagedAsyncController<T> dataController;
  final PagedListDecoration decoration;
  final ScrollController scrollController;
  final Widget Function(BuildContext context, int i, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return dataController.buildAsyncData(
      decorator: decoration,
      builder: (_, totalCount) {
        final itemCount = decoration.getTileCount(dataController.loadedItemsCount, totalCount);

        return ListView.builder(
          controller: scrollController,
          itemCount: itemCount,
          itemBuilder: (context, i) {
            final item = dataController.getItem(i);
            if (item != null) {
              return itemBuilder(context, i, item);
            } else {
              return decoration.loadMoreTile;
            }
          },
        );
      },
    );
  }
}

class PagedListLoadMoreTile extends StatelessWidget {
  const PagedListLoadMoreTile();

  @override
  Widget build(BuildContext context) {
    final builder = AsyncData.of(context);
    final PagedAsyncController controller = builder.controller;
    final decorator = builder.widget.decorator;

    return controller.buildAsyncProperty<bool>(
      selector: () => controller.error != null && !controller.isLoading,
      builder: (context, showError) {
        if (showError) {
          return decorator.buildError(context, controller.error, controller.refreshFailedPage);
        } else {
          return decorator.buildNoDataYet(context);
        }
      },
    );
  }
}

/// Adds custom handling for empty content.
class PagedListDecoration extends AsyncDataDecoration {
  const PagedListDecoration({
    this.noDataContent = const SizedBox(),
    this.addRefreshIndicator = false,
    this.loadMoreTile = const PagedListLoadMoreTile(),
    this.trimToLastLoaded = true,
  });

  // Widget to display when there is zero items.
  final Widget noDataContent;

  /// Whether refresh indicator should be inserted. It will call controller.refresh method.
  final bool addRefreshIndicator;

  // Widget to display as last tile when data is loading.
  // By default it's PagedListLoadMoreTile, which will decorators loading and error states.
  final Widget loadMoreTile;

  static const empty = PagedListDecoration();

  final bool trimToLastLoaded;

  @override
  Widget buildNoData(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            width: constraints.maxWidth,
            height: constraints.maxHeight + 0.1,
            child: noDataContent,
          ),
        );
      },
    );
  }

  @override
  Widget decorate(Widget child, AsyncData builder) {
    if (addRefreshIndicator) {
      return RefreshIndicator(
        onRefresh: builder.controller.refresh,
        child: child,
      );
    } else {
      return child;
    }
  }

  int getTileCount(int loadedItemsCount, int totalCount) {
    int count;

    if (trimToLastLoaded) {
      count = loadedItemsCount;
      final total = totalCount;

      if (total == null || count < totalCount) {
        count += 1;
      }
    } else {
      count = totalCount;
    }

    return count;
  }
}

/// Map with limited number of entries.
class CacheMap<Key, T> {
  CacheMap(this.maxCount) : assert(maxCount > 0);

  final int maxCount;

  final Map<Key, T> _map = {};
  final Queue<Key> _queue = Queue();

  T operator [](Key key) {
    return _map[key];
  }

  void operator []=(Key key, T value) {
    if (_map[key] != null) {
      _map.remove(key);
      _queue.removeWhere((other) => other == key);
    }

    _queue.add(key);
    _map[key] = value;
    if (_queue.length > maxCount) {
      final toRemove = _queue.removeFirst();
      _map[toRemove] = null;
    }
  }

  void clear() {
    _queue.clear();
    _map.clear();
  }
}
