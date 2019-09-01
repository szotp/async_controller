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

  Future<void> refresh();

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

  /// _version == 0 means that there is no data
  int _version = 0;
  T _value;
  Object _error;
  bool _isLoading = false;

  AsyncFetchItem _lastFetch;

  /// Behaviors dictate when loading controller needs to reload.
  final List<LoadingRefresher> _behaviors = [];

  /// AsyncController can contain value, error and be loading at the same time.
  /// This property simplifies things by using value if it exists, ignoring the error or loading
  /// This is good default behavior - if pull to refresh fails we don't want to loose older data
  AsyncSnapshot<T> get snapshot {
    if (_version > 0) {
      return AsyncSnapshot.withData(ConnectionState.done, _value);
    } else if (_error != null) {
      return AsyncSnapshot.withError(ConnectionState.done, _error);
    } else {
      return const AsyncSnapshot.withData(ConnectionState.waiting, null);
    }
  }

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
    _lastFetch = null;
    if (hasListeners) {
      refresh();
    }
  }

  Future<void> reset() {
    _version = 0;
    _lastFetch?._isCancelled = true;
    _lastFetch = null;
    _value = null;
    _error = null;
    _isLoading = false;

    if (hasListeners) {
      return loadIfNeeded();
    } else {
      return Future<void>.value();
    }
  }

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
      _lastFetch?._isCancelled = true;
      _lastFetch = status;

      if (!_isLoading) {
        _isLoading = true;

        if (hasListeners) {
          final _ = Future.microtask(() {
            // this avoids crash when calling load from the build method
            notifyListeners();
          });
        }
      }

      final method = fetch ?? this.fetch;

      try {
        final future = method(status);
        _lastFetch = status;

        final value = await status.ifNotCancelled(future);

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
  Future<void> refresh() {
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

  void addRefresher(LoadingRefresher behavior) {
    assert(behavior.controller == null);
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
  void setNeedsRefresh(SetNeedsRefreshFlag flags) {
    _cachedBase = null;
    super.setNeedsRefresh(flags);
  }

  @protected
  void setNeedsLocalTransform() {
    super.setNeedsRefresh(SetNeedsRefreshFlag.always);
  }
}

/// A controller that loads a list and then removes some items from it.
abstract class FilteringAsyncController<Value> extends MappedAsyncController<List<Value>, List<Value>> {
  @override
  bool get hasData => super.hasData && value.isNotEmpty;
}
