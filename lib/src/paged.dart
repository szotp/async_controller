import 'package:flutter/material.dart';

import 'async_builder.dart';
import 'controller.dart';

/// A slice of bigger array, returned from backend. All values must not be null.
class PagedData<T> {
  final int index;
  final int totalCount;
  final List<T> data;

  PagedData(this.index, this.totalCount, this.data)
      : assert(index != null),
        assert(data != null);
}

/// Loads data into array, in pages.
/// Widget using this controller must call markAccess when accessing the items to continue loading.
abstract class PagedAsyncController<T> extends AsyncController<List<T>> {
  bool get hasAll => _totalCount != null && _totalCount == value.length;

  int _totalCount;

  int get pageSize;

  PagedAsyncController();

  Future<PagedData<T>> fetchPage(int index);

  @override
  Future<List<T>> fetch() async {
    final page = await fetchPage(0);
    _totalCount = page.totalCount;
    return page.data;
  }

  @override
  bool get hasData => value?.isNotEmpty ?? false;

  void loadNextPage() {
    // markAccess runs from build method so we need to wait with updates to avoid
    // setting state
    Future.microtask(() {
      if (isLoading) return; // in case markAccess was called multiple times in one frame
      final result = (value ?? []).toList();

      internallyLoadAndNotify(() async {
        final page = await fetchPage(result.length);
        _totalCount = page.totalCount;
        result.addAll(page.data);
        return result;
      });
    });
  }

  void markAccess(int index) {
    if (value == null || index < (value.length - 1) || isLoading || hasAll) return;
    loadNextPage();
  }
}

class PagedListView<T> extends StatelessWidget {
  final PagedAsyncController<T> controller;
  final PagedListDecoration decoration;
  final Widget Function(BuildContext context, int i, T item) itemBuilder;

  const PagedListView({Key key, @required this.controller, @required this.itemBuilder, @required this.decoration}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return controller.buildAsyncData(
      decorator: decoration,
      builder: (_, data) {
        var count = data.length;
        if (!controller.hasAll) {
          count += 1;
        }

        return ListView.builder(
          itemCount: count,
          itemBuilder: (context, i) {
            if (i >= data.length) {
              return decoration.loadMoreTile;
            }

            controller.markAccess(i);
            return itemBuilder(context, i, data[i]);
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
    final decorator = builder.decorator;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.error != null && !controller.isLoading) {
          return decorator.buildError(context, controller.error, controller.loadNextPage);
        } else {
          return decorator.buildNoDataYet(context);
        }
      },
    );
  }
}

/// Adds custom handling for empty content.
class PagedListDecoration extends AsyncDataDecoration {
  // Widget to display when there is zero items.
  final Widget noDataContent;

  /// Whether refresh indicator should be inserted. It will call controller.refresh method.
  final bool addRefreshIndicator;

  // Widget to display as last tile when data is loading.
  // By default it's PagedListLoadMoreTile, which will decorators loading and error states.
  final Widget loadMoreTile;

  PagedListDecoration({
    @required this.noDataContent,
    this.addRefreshIndicator = false,
    this.loadMoreTile = const PagedListLoadMoreTile(),
  });

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
}
