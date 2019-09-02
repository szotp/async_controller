import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'async_data.dart';
import 'refreshers.dart';
import 'utils.dart';

/// Object created for every fetch to control cancellation.
class AsyncFetchItem {
  static const cancelledError = 'cancelled';
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  /// Waits until feature is finished, and then ensures that fetch was not cancelled
  Future<T> ifNotCancelled<T>(Future<T> future) async {
    final result = await future;
    if (isCancelled) {
      throw cancelledError;
    }

    return result;
  }

  Future<void> _runningFuture;

  static Future<void> runFetch(AsyncControllerFetchExpanded<void> fetch) {
    final status = AsyncFetchItem();
    status._runningFuture = fetch(status);

    return status._runningFuture.catchError((dynamic error) {
      assert(error == cancelledError);
    });
  }
}

enum AsyncControllerState {
  /// Controller was just created and there is nothing to show.
  /// Usually loading indicator will be shown in this case. data == nil, error == nil
  noDataYet,

  /// The fetch was successful, and we have something to show. data.isNotEmpty
  hasData,

  /// The fetch was successful, but there is nothing to show. data == nil || data.isEmpty
  noData,

  /// Fetch failed. error != nil
  failed,
}

/// Simplified fetch function that does not care about cancellation.
typedef AsyncControllerFetch<T> = Future<T> Function();
typedef AsyncControllerFetchExpanded<T> = Future<T> Function(AsyncFetchItem status);

/// Interface used by AsyncData
abstract class LoadingValueListenable<T> implements ValueListenable<T>, Refreshable {
  int get version;
  bool get hasData;
  bool get isLoading;
  Object get error;

  /// Method usually used to execute pull to refresh.
  Future<void> performUserInitiatedRefresh();

  void dispose();

  AsyncControllerState get state {
    if (hasData) {
      return AsyncControllerState.hasData;
    } else if (error != null && !isLoading) {
      return AsyncControllerState.failed;
    } else if (version == 0) {
      return AsyncControllerState.noDataYet;
    } else {
      return AsyncControllerState.noData;
    }
  }

  /// Provides AsyncSnapshot for compability with other widgets.
  /// It is usually better to use state property.
  AsyncSnapshot<T> get snapshot {
    if (version > 0) {
      return AsyncSnapshot.withData(ConnectionState.done, value);
    } else if (error != null) {
      return AsyncSnapshot.withError(ConnectionState.done, error);
    } else {
      return const AsyncSnapshot.withData(ConnectionState.waiting, null);
    }
  }

  AsyncData<T> buildAsyncData({
    @required AsyncDataFunction<T> builder,
    AsyncDataDecoration decorator = const AsyncDataDecoration(),
  }) {
    return AsyncData(
      controller: this,
      decorator: decorator,
      builder: builder,
    );
  }

  /// Returns reactive widget that builds when value returned from selector is different than before.
  /// The selector runs only when this controller changes.
  Widget buildAsyncProperty<P>({
    P Function() selector,
    @required Widget Function(BuildContext, P) builder,
  }) {
    return AsyncPropertyBuilder<P>(
      selector: selector,
      listenable: this,
      builder: builder,
    );
  }

  Widget buildAsyncVisibility({bool Function() selector, Widget child}) {
    return AsyncPropertyBuilder<bool>(
      selector: selector,
      listenable: this,
      builder: (_, visible) {
        print('Visibility $visible');
        return Visibility(
          visible: visible,
          child: child,
        );
      },
    );
  }

  Widget buildAsyncOpacity({
    bool Function() selector,
    Widget child,
    double opacityForTrue = 1.0,
    double opacityForFalse = 0.5,
  }) {
    return AsyncPropertyBuilder<bool>(
      selector: selector,
      listenable: this,
      builder: (_, value) {
        return Opacity(
          opacity: value ? opacityForTrue : opacityForFalse,
          child: child,
        );
      },
    );
  }
}

/// A controller for managing asynchronously loading data.
abstract class AsyncController<T> extends ChangeNotifier with LoadingValueListenable<T> {
  AsyncController();

  factory AsyncController.method(AsyncControllerFetch<T> method) {
    return _SimpleAsyncController(method);
  }

  /// _version == 0 means that there was no fetch yet
  int _version = 0;
  T _value;
  Object _error;
  bool _isLoading = false;

  AsyncFetchItem _lastFetch;

  /// Behaviors dictate when loading controller needs to reload.
  final List<LoadingRefresher> _behaviors = [];

  @override
  T get value => _value;

  @override
  Object get error => _error;

  @override
  bool get isLoading => _isLoading;

  @override
  int get version => _version;

  @override
  void setNeedsRefresh(SetNeedsRefreshFlag flags) {
    if (flags == SetNeedsRefreshFlag.ifError && error == null) {
      return;
    }

    if (flags == SetNeedsRefreshFlag.reset) {
      reset();
      return;
    }

    _cancelCurrentFetch();
    if (hasListeners) {
      internallyLoadAndNotify();
    }
  }

  void _cancelCurrentFetch([AsyncFetchItem nextFetch]) {
    _lastFetch?._isCancelled = true;
    _lastFetch = nextFetch;
  }

  /// Clears all stored data. Will fetch again if controller has listeners.
  Future<void> reset() {
    _version = 0;
    _cancelCurrentFetch();
    _value = null;
    _error = null;
    _isLoading = false;

    if (hasListeners) {
      return internallyLoadAndNotify();
    } else {
      return Future<void>.value();
    }
  }

  /// Indicates if controller has data that could be displayed.
  @override
  bool get hasData => _value != null;

  @protected
  Future<T> fetch(AsyncFetchItem status);

  /// Runs the fetch method, and updates this controller.
  /// Custom method can be provided for running, otherwise default fetch will be called.
  /// If AsyncStatus gets cancelled, for example when users performs pull to refresh,
  /// this method will ignore the result of fetch completely.
  @protected
  Future<void> internallyLoadAndNotify([AsyncControllerFetchExpanded<T> fetch]) {
    return AsyncFetchItem.runFetch((status) async {
      _cancelCurrentFetch(status);

      if (!_isLoading) {
        _isLoading = true;

        // microtask avoids crash that would happen when executing loadIfNeeded from build method
        Future.microtask(notifyListeners);
      }

      final method = fetch ?? this.fetch;

      try {
        final value = await status.ifNotCancelled(method(status));

        _value = value;
        _version += 1;
        _error = null;
      } catch (e) {
        if (e == AsyncFetchItem.cancelledError) {
          return;
        }

        _error = e;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  Future<void> performUserInitiatedRefresh() {
    return internallyLoadAndNotify();
  }

  /// This future never fails - there is no need to catch.
  /// If there is error during loading it will handled by the controller.
  /// If multiple widgets call this method, they will get the same future.
  Future<void> loadIfNeeded() {
    if (_lastFetch == null) {
      internallyLoadAndNotify();
    }
    return _lastFetch._runningFuture;
  }

  /// Adds loading refresher that will have capability to trigger a reload of controller.
  void addRefresher(LoadingRefresher behavior) {
    behavior.mount(this);
    _behaviors.add(behavior);

    if (hasListeners) {
      behavior.activate();
    }
  }

  @protected
  void activate() {
    for (var b in _behaviors) {
      b.activate();
    }
    loadIfNeeded();
  }

  @protected
  void deactivate() {
    for (var b in _behaviors) {
      b.deactivate();
    }
  }

  @override
  void addListener(listener) {
    if (!hasListeners) {
      activate();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      deactivate();
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (hasListeners) {
      deactivate();
    }
  }
}

class _SimpleAsyncController<T> extends AsyncController<T> {
  _SimpleAsyncController(this.method);

  final AsyncControllerFetch<T> method;

  @override
  Future<T> fetch(AsyncFetchItem status) => method();
}

/// A controller that does additonal processing after fetching base data.
/// Useful for local filtering, sorting, etc.
abstract class MappedAsyncController<BaseValue, MappedValue> extends AsyncController<MappedValue> {
  Future<BaseValue> fetchBase();

  /// A method that runs after expensive base fetch. Call setNeedsLocalTransform if conditions affecting the transform has changed.
  /// For example if searchText for locally implemented search has changed.
  Future<MappedValue> transform(BaseValue data);

  Future<BaseValue> _cachedBase;

  @override
  Future<MappedValue> fetch(AsyncFetchItem status) async {
    _cachedBase ??= fetchBase();

    try {
      return transform(await _cachedBase);
    } catch (e) {
      _cachedBase = null;
      rethrow;
    }
  }

  @override
  Future<void> performUserInitiatedRefresh() {
    _cachedBase = null;
    return super.performUserInitiatedRefresh();
  }

  /// Re-run fetch on existing cached base
  @protected
  void setNeedsLocalTransform() {
    internallyLoadAndNotify();
  }
}

/// A controller that loads a list and then removes some items from it.
abstract class FilteringAsyncController<Value> extends MappedAsyncController<List<Value>, List<Value>> {
  @override
  bool get hasData => super.hasData && value.isNotEmpty;
}
