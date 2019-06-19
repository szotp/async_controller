import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'async_builder.dart';

typedef AsyncControllerFetch<T> = Future<T> Function();

/// Interface used by AsyncBuilder
abstract class LoadingValueListenable<T> implements ValueListenable<T> {
  int get version;
  bool get hasData;
  bool get isLoading;
  Object get error;

  Future<void> refresh();

  AsyncBuilder<T> buildAsync({
    AsyncBuilderFunction<T> builder,
    AsyncBuilderDecoration decorator = const AsyncBuilderDecoration(),
  }) {
    return AsyncBuilder(
      controller: this,
      decorator: decorator,
      builder: builder,
    );
  }
}

/// A controller for managing asynchronously loading data.
abstract class AsyncController<T> extends ChangeNotifier with LoadingValueListenable<T> {
  /// _version == 0 means that there is no data
  int _version = 0;
  T _value;
  Object _error;
  bool _isLoading;
  Future<void> _lastFetch;

  /// Behaviors dictate when loading controller needs to reload.
  List<LoadingRefresher> _behaviors = [];

  /// AsyncController can contain value, error and be loading at the same time.
  /// This property simplifies things by using value if it exists, ignoring the error or loading
  /// This is good default behavior - if pull to refresh fails we don't want to loose older data
  AsyncSnapshot<T> get snapshot {
    if (_version > 0) {
      return AsyncSnapshot.withData(ConnectionState.done, _value);
    } else if (_error != null) {
      return AsyncSnapshot.withError(ConnectionState.done, _error);
    } else {
      return AsyncSnapshot.withData(ConnectionState.waiting, null);
    }
  }

  AsyncController();

  factory AsyncController.method(AsyncControllerFetch<T> method) {
    return _SimpleAsyncController(method);
  }

  @override
  T get value => _value;
  Object get error => _error;
  bool get isLoading => _isLoading;
  int get version => _version;

  /// Current data should be
  void setNeedsRefresh() {
    _lastFetch = null;
    if (hasListeners) {
      refresh();
    }
  }

  void reset() {
    _version = 0;
    _lastFetch = null;
    _value = null;
    _error = null;
    _isLoading = false;

    if (hasListeners) {
      loadIfNeeded();
    }
  }

  bool get hasData => _value != null;

  @protected
  Future<T> fetch();

  @protected
  Future<void> internallyLoadAndNotify([AsyncControllerFetch<T> fetch]) async {
    _isLoading = true;
    notifyListeners();

    final method = fetch ?? this.fetch;

    /// This was written because failure from Result.capture was being catched by debugger
    Future<Result<T>> captureResult(Future<T> future) async {
      try {
        return ValueResult(await future);
      } catch (e, trace) {
        return ErrorResult(e, trace);
      }
    }

    final newLoading = captureResult(method());
    _lastFetch = newLoading;
    final newValue = await newLoading;

    if (newLoading != _lastFetch) {
      // If loading was restarted when future was running, we will just ignore the old result.
      return;
    }

    if (newValue.isValue) {
      _version += 1;
      _value = newValue.asValue.value;
      _error = null;
      _isLoading = false;
    } else {
      // _value - keep previous value
      _error = newValue.asError.error;
      _isLoading = false;
    }

    notifyListeners();
  }

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
    return _lastFetch;
  }

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
    super.dispose();
    if (hasListeners) {
      _deactivate();
    }
  }
}

class _SimpleAsyncController<T> extends AsyncController<T> {
  final AsyncControllerFetch<T> method;

  _SimpleAsyncController(this.method);

  @override
  Future<T> fetch() => method();
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
  Future<MappedValue> fetch() async {
    if (_cachedBase == null) {
      _cachedBase = fetchBase();
    }

    try {
      return transform(await _cachedBase);
    } catch (e) {
      _cachedBase = null;
      throw e;
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
