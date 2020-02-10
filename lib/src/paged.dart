import 'package:async_controller/src/debugging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../async_controller.dart';
import 'async_data.dart';
import 'controller.dart';
import 'controller_ext.dart';

/// A slice of bigger array, returned from backend. All values must not be null.
class PagedData<T> {
  PagedData(this.pageIndex, this.totalCount, this.data);

  final int pageIndex;
  final int totalCount;
  final List<T> data;
}

/// Loads data into array, in pages.
/// The value of loader is totalCount of items available. The actual items can be fetched using getItem method.
abstract class PagedAsyncController<T> extends AsyncController<int> {
  final List<T> _items = [];

  PagedAsyncController({this.loadingMargin = 10});

  /// Amount of extra items to load that are not yet visible.
  final int loadingMargin;

  int _nextPage = 0;

  /// Widget uses this property to determine curently visible amount of items.
  int get loadedItemsCount => _items.length;

  int get totalCount => value;

  /// If data for given item is not loaded, getItem will return null and schedule a page load.
  /// After page is loaded, notifyListeners will be called, which will trigger listener widget to reload.
  T getItem(int itemIndex) {
    if (itemIndex < _items.length) {
      if (itemIndex > (_items.length - loadingMargin)) {
        loadMoreIfPossible();
      }

      return _items[itemIndex];
    }

    loadMoreIfPossible();
    return null;
  }

  Future<PagedData<T>> fetchPage(int pageIndex);

  bool get hasMoreToLoad => totalCount == null || loadedItemsCount < totalCount;

  /// Fetches more data, if there is anything to fetch and controller is not already loading it.
  void loadMoreIfPossible() {
    if (hasMoreToLoad && !isLoading) {
      performFetch(_fetchNext);
    }
  }

  @override
  Future<int> fetch(AsyncFetchItem status) async {
    debugLog('Fetching page 0');
    final run = await status.ifNotCancelled(fetchPage(0));
    _items.clear();
    _items.addAll(run.data);

    _nextPage = 1;
    return run.totalCount;
  }

  Future<int> _fetchNext(AsyncFetchItem status) async {
    final nextPage = _nextPage;
    debugLog('Fetching page $nextPage');

    final run = await status.ifNotCancelled(fetchPage(nextPage));
    _items.addAll(run.data);

    _nextPage = nextPage + 1;
    return run.totalCount;
  }

  @override
  Future<void> reset() {
    _nextPage = 0;
    _items.clear();
    return super.reset();
  }

  @override
  bool get hasData => value != 0 && version > 0;
}

typedef PagedItemBuilder<T> = Widget Function(
    BuildContext context, int i, T item);

typedef CollectionViewBuilder = Widget Function(
    BuildContext, int itemCount, IndexedWidgetBuilder);

class PagedListView<T> extends StatelessWidget {
  final PagedListDecoration decoration;
  final PagedAsyncController<T> controller;
  final PagedItemBuilder<T> itemBuilder;

  /// Builder that will create ListView or something else for given parameters.
  /// Use cases:
  /// - custom scroll physics
  /// - custom scroll controller
  /// - using grid view instead of list view
  final CollectionViewBuilder listBuilder;

  /// Default listBuilder. Returns ListView with default parameters
  static Widget buildSimpleList(
      BuildContext context, int itemCount, IndexedWidgetBuilder itemBuilder) {
    return ListView.builder(itemBuilder: itemBuilder, itemCount: itemCount);
  }

  const PagedListView({
    Key key,
    @required this.controller,
    @required this.itemBuilder,
    this.listBuilder = buildSimpleList,
    this.decoration = PagedListDecoration.empty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return controller.buildAsyncData(
      decorator: decoration,
      builder: (context, __) {
        return listBuilder(context, getItemCount(), (context, i) {
          final item = controller.getItem(i);
          if (item != null) {
            return itemBuilder(context, i, item);
          } else {
            return buildMissingTile(context, i);
          }
        });
      },
    );
  }

  @protected
  int getItemCount() {
    if (controller.totalCount != null &&
        controller.loadedItemsCount < controller.totalCount) {
      return controller.loadedItemsCount + 1;
    } else {
      return controller.totalCount;
    }
  }

  @protected
  Widget buildMissingTile(BuildContext context, int i) {
    return controller.buildAsyncProperty(
      selector: () => controller.error,
      builder: (_, error) {
        if (error != null) {
          return decoration.buildErrorTile(
            context,
            error,
            () => controller.loadMoreIfPossible(),
            i,
          );
        } else {
          return decoration.buildNoDataYetTile(context, i);
        }
      },
    );
  }
}

/// Adds custom handling for empty content. Can be reused across the app.
/// Automatically adds RefreshIndicator. Set addRefreshIndicator to false to disable it.
class PagedListDecoration extends AsyncDataDecoration {
  const PagedListDecoration({
    this.noDataContent = const SizedBox(),
    this.addRefreshIndicator = true,
  });

  // Widget to display when there is zero items.
  final Widget noDataContent;

  /// Whether refresh indicator should be inserted. It will call controller.performUserInitiatedRefresh method.
  final bool addRefreshIndicator;

  static const empty = PagedListDecoration();

  @override
  Widget buildNoData(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            width: constraints.maxWidth,

            /// Ensures that pull to refresh is possible
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
        onRefresh: builder.controller.performUserInitiatedRefresh,
        child: child,
      );
    } else {
      return child;
    }
  }

  /// Called to build tile when incremental loading failed.
  /// By default returns the same content as buildError
  Widget buildErrorTile(
      BuildContext context, Object error, Function() tryAgain, int index) {
    return buildError(context, error, tryAgain);
  }

  /// Called to build  tile when data is still loading.
  /// By default returns the same content as buildNoDataYet.
  Widget buildNoDataYetTile(BuildContext context, int index) {
    return buildNoDataYet(context);
  }
}
