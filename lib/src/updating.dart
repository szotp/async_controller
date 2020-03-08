import 'package:async_controller/async_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class UpdatingController<P> extends ChangeNotifier {
  UpdatingController(this._data);

  P _data;

  UpdatingProperty<P> _dataProperty;
  UpdatingProperty<P> get data {
    return _dataProperty ??= bind('data', (x) => x, (x, v) => _data = v);
  }

  final Set<String> _toUpdate = {};
  final _core = AsyncFetchCore();

  int _isUpdatingCounter = 0;
  bool get isUpdating => _isUpdatingCounter > 0;

  Object _error;
  Object get error => _error;

  /// Delay between update and actually sending the requests
  Duration get delay => Duration(seconds: 1);

  bool needsUpdate(String key) => _toUpdate.contains(key);

  Future<void> ensureUpdatedOrThrow() async {
    await _core.waitIfNeeded();
    if (hasUpdates) {
      await performUpdate();
    }

    if (error != null) {
      throw error;
    }
    assert(!hasUpdates);
  }

  @protected
  Future<void> setNeedsUpdate(String key) {
    _toUpdate.add(key);
    notifyListeners();
    return performUpdate();
  }

  Future<void> performUpdate() => _core.perform(_updateAndNotify);

  Future<void> _updateAndNotify(AsyncFetchItem item) async {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }

    await item.ifNotCancelled(Future.delayed(delay));

    _isUpdatingCounter++;
    notifyListeners();

    try {
      await update(item, _toUpdate);

      if (!item.isCancelled) {
        _toUpdate.clear();
        _error = null;
      }
    } catch (e) {
      if (!item.isCancelled) {
        _error = e;
      }
    }

    _isUpdatingCounter--;
    notifyListeners();
  }

  bool get hasUpdates => _toUpdate.isNotEmpty;

  @protected
  Future<void> update(AsyncFetchItem item, Set<String> keys);

  UpdatingPropertyStatus statusOf(String key) {
    if (!needsUpdate(key)) return UpdatingPropertyStatus.ok;
    if (isUpdating) return UpdatingPropertyStatus.isUpdating;
    if (error != null) return UpdatingPropertyStatus.error;
    return UpdatingPropertyStatus.needsUpdate;
  }

  @protected
  UpdatingProperty<T> bind<T>(
      String key, T Function(P) getter, void Function(P, T) setter) {
    return UpdatingProperty(
      () => getter(_data),
      (newValue) {
        setter(_data, newValue);
        setNeedsUpdate(key);
      },
      this,
      key,
    );
  }

  @override
  void dispose() {
    assert(!hasUpdates);
    super.dispose();
  }
}

enum UpdatingPropertyStatus {
  /// Property is synced
  ok,

  /// Sync failed
  error,

  /// Property is not synced but parent is waiting
  needsUpdate,

  /// Property is being synced right now
  isUpdating,
}

/// Represents a value that can be updated in UpdatingController.
/// Setting value or calling update will register the change an schedule it for update in the controller
/// If something goes wrong, update can be retried using recoverFromError method
class UpdatingProperty<T> implements Property<T> {
  final UpdatingController _parent;
  final ValueGetter<T> _getter;
  final ValueSetter<T> _setter;

  final String key;

  UpdatingProperty(this._getter, this._setter, this._parent, this.key);

  UpdatingPropertyStatus get status => _parent.statusOf(key);

  Object get error => _parent.error;

  /// Tells parent to retry updates
  Future<void> recoverFromError() {
    assert(status == UpdatingPropertyStatus.error);
    return _parent.performUpdate();
  }

  @override
  String toString() {
    return '$key: $value';
  }

  @override
  void update(T newValue) {
    _setter(newValue);
  }

  @override
  T get value => _getter();

  @override
  void addListener(listener) {
    _parent.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _parent.removeListener(listener);
  }
}

/// Displays decoration around the child to indicate that update is happening
class UpdatingPropertyListener extends StatelessWidget {
  final UpdatingProperty property;
  final Widget child;

  final Widget Function(
    BuildContext context,
    UpdatingPropertyStatus status,
    UpdatingPropertyListener listener,
  ) decorator;

  const UpdatingPropertyListener({
    @required this.property,
    @required this.decorator,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncPropertyBuilder<UpdatingPropertyStatus>(
      listenable: property,
      selector: () => property.status,
      builder: (context, status, _) => decorator(context, status, this),
    );
  }
}
