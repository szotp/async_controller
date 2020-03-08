import 'dart:async';

import 'package:async_controller/async_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'refreshers.dart';

/// Runs one fetch at a time.
/// If performFetch is called when old fetch is running, the old fetch will be canceled
class AsyncFetchCore {
  AsyncFetchItem _current;

  bool get isRunning => _current != null;

  Future<void> perform(AsyncControllerFetchExpanded<void> fetch) async {
    _current?._isCancelled = true;

    final status = AsyncFetchItem();
    _current = status;

    try {
      status._runningFuture = fetch(status);
      await status._runningFuture;
    } on AsyncFetchItemCanceled {
      // ignore canceled error
    } finally {
      if (_current == status) {
        _current = null;
      }
    }
  }

  /// Cancels current fetch and stops running
  void cancel() {
    _current?._isCancelled = true;
    _current = null;
  }

  /// Waits until core stops running
  Future<void> waitIfNeeded() async {
    while (_current?._runningFuture != null) {
      await _current._runningFuture;
    }
    assert(!isRunning);
  }
}

class AsyncFetchItemCanceled implements Exception {
  const AsyncFetchItemCanceled();
}

/// Object created for every fetch to control cancellation.
class AsyncFetchItem {
  static const cancelledError = AsyncFetchItemCanceled();
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
typedef AsyncControllerFetchExpanded<T> = Future<T> Function(
    AsyncFetchItem status);

/// A controller for managing asynchronously loading data.
abstract class AsyncController<T> extends ChangeNotifier
    implements ValueListenable<T>, Refreshable {
  AsyncController([T initialValue]) {
    if (initialValue != null) {
      _value = initialValue;
      _version = 1;
      _needsRefresh = false;
    }
  }

  factory AsyncController.method(AsyncControllerFetch<T> method) {
    return _SimpleAsyncController(method);
  }

  // prints errors in debug mode, ensures that they are not programmer's mistake
  static bool debugCheckErrors = true;

  /// _version == 0 means that there was no fetch yet
  int _version = 0;
  T _value;
  Object _error;
  bool _isLoading = false;
  bool _needsRefresh = true;

  /// Behaviors dictate when loading controller needs to reload.
  final List<LoadingRefresher> _behaviors = [];

  @override
  T get value => _value;

  Object get error => _error;
  bool get isLoading => _isLoading;

  /// Number of finished fetches since last reset.
  int get version => _version;

  Duration _lastFetchDuration;
  Duration get lastFetchDuration => _lastFetchDuration;

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

  @override
  void setNeedsRefresh(SetNeedsRefreshFlag flags) {
    if (flags == null ||
        flags.flagOnlyIfNotLoading && isLoading ||
        flags.flagOnlyIfError && error == null) {
      return;
    }

    if (flags == SetNeedsRefreshFlag.reset) {
      reset();
      return;
    }

    _core.cancel();
    _needsRefresh = true;
    if (hasListeners) {
      performFetch();
    }
  }

  /// Clears all stored data. Will fetch again if controller has listeners.
  Future<void> reset() {
    _version = 0;
    _core.cancel();
    _value = null;
    _error = null;
    _isLoading = false;
    _needsRefresh = true;

    if (hasListeners) {
      return performFetch();
    } else {
      return Future<void>.value();
    }
  }

  /// Indicates if controller has data that could be displayed.
  bool get hasData => _value != null;

  @protected
  Future<T> fetch(AsyncFetchItem status);

  final _core = AsyncFetchCore();

  /// Immediately runs default fetch or provided func. Previous fetch will be cancelled.
  @protected
  Future<void> performFetch([AsyncControllerFetchExpanded<T> fetch]) {
    final start = DateTime.now();

    return _core.perform((status) async {
      if (!_isLoading || error != null) {
        _isLoading = true;
        _error = null;

        // microtask avoids crash that would happen when executing loadIfNeeded from build method
        Future.microtask(notifyListeners);
      }

      try {
        final value =
            await status.ifNotCancelled((fetch ?? this.fetch)(status));
        _value = value;
        _version += 1;
        _error = null;
        _needsRefresh = false;
      } catch (e) {
        if (e == AsyncFetchItem.cancelledError) {
          return;
        }

        if (kDebugMode && AsyncController.debugCheckErrors) {
          // this is disabled in production code and behind a flag
          // ignore: avoid_print
          print('${this} got error:\n$e');

          assert(e is! NoSuchMethodError, '$e');
        }

        _error = e;
      }

      _lastFetchDuration = DateTime.now().difference(start);
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Notify that currently held value changed without doing new fetch.
  @protected
  void internallyUpdateVersion() {
    assert(_version > 0,
        'Attempted to raise version on empty controller. Something needs to be loaded.');
    _version++;
    notifyListeners();
  }

  /// Intended to use for pull to refresh.
  Future<void> performUserInitiatedRefresh() {
    return performFetch();
  }

  /// Perform fetch if there is no data yet.
  /// This future never fails - there is no need to catch.
  /// If there is error during loading it will handled by the controller.
  /// If multiple widgets call this method, they will get the same future.
  Future<void> loadIfNeeded() {
    if (_core.isRunning) {
      return _core._current._runningFuture;
    }

    if (_needsRefresh) {
      return performFetch();
    } else {
      return Future.value();
    }
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
    for (final b in _behaviors) {
      b.activate();
    }
    loadIfNeeded();
  }

  @protected
  void deactivate() {
    _core.cancel();
    for (final b in _behaviors) {
      b.deactivate();
    }
  }

  @override
  void addListener(void Function() listener) {
    if (!hasListeners) {
      activate();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(void Function() listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      deactivate();
    }
  }

  @override
  void dispose() {
    if (hasListeners) {
      deactivate();
    }
    super.dispose();
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
abstract class MappedAsyncController<BaseValue, MappedValue>
    extends AsyncController<MappedValue> {
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
    performFetch();
  }
}

/// A controller that loads a list and then removes some items from it.
abstract class FilteringAsyncController<Value>
    extends MappedAsyncController<List<Value>, List<Value>> {
  @override
  bool get hasData => super.hasData && value.isNotEmpty;
}

/// Provides the latest value from a stream.
/// Automatically closes / recreates the stream when activated / deactivated.
abstract class StreamAsyncControlelr<T> extends AsyncController<T> {
  Stream<T> getStream(AsyncFetchItem status);

  StreamSubscription<T> _sub;

  Duration get renewAfter => null;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onData(T data) {
    performFetch((_) => Future.value(data));
  }

  void _onError(dynamic error, stack) {
    performFetch((_) => throw error);
  }

  void _onDone() {
    final duration = renewAfter;
    if (renewAfter != null) {
      performFetch((item) async {
        await item.ifNotCancelled(Future.delayed(duration));
        return fetch(item);
      });
    }
  }

  @override
  void deactivate() {
    _sub?.cancel();
    _sub = null;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (_sub == null) {
      performFetch();
    }
  }

  @override
  Future<T> fetch(AsyncFetchItem status) {
    final stream = getStream(status);
    _sub?.cancel();
    _sub = stream.listen(_onData, onError: _onError, onDone: _onDone);

    return Future.value(value);
  }
}
