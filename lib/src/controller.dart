import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'async_builder.dart';
import 'utils.dart';

class AsyncStatus {
  static const cancelledError = 'cancelled';
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  Future<T> ifNotCancelled<T>(Future<T> future) {
    return future.then((x) {
      if (isCancelled) {
        throw cancelledError;
      } else {
        return x;
      }
    });
  }

  Future<void> _runningFuture;

  static Future<void> runFetch(AsyncControllerFetchExpanded<void> fetch) {
    final status = AsyncStatus();
    return fetch(status).catchError((dynamic error) {
      assert(error == cancelledError);
    });
  }
}

typedef AsyncControllerFetch<T> = Future<T> Function();
typedef AsyncControllerFetchExpanded<T> = Future<T> Function(AsyncStatus status);

abstract class Refreshable {
  Future<void> refresh();
  void setNeedsRefresh();
}

/// Interface used by AsyncData
abstract class LoadingValueListenable<T> implements ValueListenable<T>, Refreshable {
  int get version;
  bool get hasData;
  bool get isLoading;
  Object get error;

  bool get hasFreshData;

  @override
  Future<void> refresh();

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
    Object Function() selector,
    @required Widget Function(BuildContext, P) builder,
  }) {
    return AsyncPropertyBuilder<P>(
      selector: selector,
      listenable: this,
      builder: builder,
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

  AsyncStatus _lastFetch;

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
  bool get hasFreshData => _timer == null && !isLoading;

  @override
  void setNeedsRefresh() {
    _lastFetch = null;
    if (hasListeners) {
      final delay = delayToRefresh;
      if (delay != null) {
        _cancelRefreshTimer();
        _timer = Timer(delay, () {
          if (hasListeners) {
            refresh();
          }
        });
        notifyListeners();
      } else {
        refresh();
      }
    }
  }

  void _cancelRefreshTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    _cancelRefreshTimer();
    _version = 0;
    _lastFetch = null;
    _value = null;
    _error = null;
    _isLoading = false;

    if (hasListeners) {
      loadIfNeeded();
    }
  }

  @override
  bool get hasData => _version > 0;

  @protected
  Future<T> fetch(AsyncStatus status);

  /// Runs the fetch method, and updates this controller.
  /// Custom method can be provided for running, otherwise default fetch will be called.
  /// If AsyncStatus gets cancelled, for example when users performs pull to refresh,
  /// this method will ignore the result of fetch completely.
  @protected
  Future<void> internallyLoadAndNotify([AsyncControllerFetchExpanded<T> fetch]) {
    return AsyncStatus.runFetch((status) async {
      _lastFetch?._isCancelled = true;
      _lastFetch = status;

      _cancelRefreshTimer();
      _isLoading = true;

      if (hasListeners) {
        final _ = Future.microtask(() {
          // this avoids crash when calling load from the build method
          notifyListeners();
        });
      }

      final method = fetch ?? this.fetch;

      try {
        final future = method(status);
        status._runningFuture = future;
        _lastFetch = status;
        final value = await status.ifNotCancelled(future);

        _value = value;
        _version += 1;
        _error = null;
      } catch (e) {
        if (e == AsyncStatus.cancelledError) {
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

  Timer _timer;
  Duration get delayToRefresh => null;

  void addRefresher(LoadingRefresher behavior) {
    assert(behavior._controller == null);
    behavior._controller = this;
    _behaviors.add(behavior);

    if (hasListeners) {
      behavior.activate();
    }
  }

  void _activate() {
    for (var b in _behaviors) {
      b.activate();
    }
    loadIfNeeded();
  }

  void _deactivate() {
    for (var b in _behaviors) {
      b.deactivate();
    }
  }

  @override
  void addListener(listener) {
    if (!hasListeners) {
      _activate();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _deactivate();
    }
  }

  @override
  void dispose() {
    _cancelRefreshTimer();
    super.dispose();
    if (hasListeners) {
      _deactivate();
    }
  }
}

class _SimpleAsyncController<T> extends AsyncController<T> {
  _SimpleAsyncController(this.method);

  final AsyncControllerFetch<T> method;

  @override
  Future<T> fetch(AsyncStatus status) => method();
}

abstract class LoadingRefresher {
  AsyncController _controller;

  AsyncController get controller => _controller;

  void activate();
  void deactivate();
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
  Future<MappedValue> fetch(AsyncStatus status) async {
    _cachedBase ??= fetchBase();

    try {
      return transform(await _cachedBase);
    } catch (e) {
      _cachedBase = null;
      rethrow;
    }
  }

  @override
  void setNeedsRefresh() {
    _cachedBase = null;
    super.setNeedsRefresh();
  }

  @protected
  void setNeedsLocalTransform() {
    super.setNeedsRefresh();
  }
}

/// A controller that loads a list and then removes some items from it.
abstract class FilteringAsyncController<Value> extends MappedAsyncController<List<Value>, List<Value>> {}
