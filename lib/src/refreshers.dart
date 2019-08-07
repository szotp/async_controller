import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';

class InForegroundRefresher extends LoadingRefresher with WidgetsBindingObserver {
  @override
  void activate() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.setNeedsRefresh();
    }
  }

  @override
  void deactivate() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

class StreamRefresher<T> extends LoadingRefresher {
  StreamRefresher(this.stream);

  final Stream<T> stream;
  StreamSubscription<T> _sub;

  @override
  void activate() {
    _sub = stream.listen(_onData);
  }

  bool shouldRefresh(T data) => true;

  void _onData(T data) {
    if (shouldRefresh(data)) {
      controller.setNeedsRefresh();
    }
  }

  @override
  void deactivate() {
    _sub.cancel();
  }
}

class OnReconnectedRefresher extends StreamRefresher<ConnectivityResult> {
  OnReconnectedRefresher([this.alwaysRefresh = false]) : super(Connectivity().onConnectivityChanged);

  // If false, it will refresh only if controller is in error state.
  final bool alwaysRefresh;
  bool _wasConnected = false;

  @override
  bool shouldRefresh(ConnectivityResult data) {
    final isConnected = data != ConnectivityResult.none;
    if (isConnected != _wasConnected) {
      _wasConnected = isConnected;
      return alwaysRefresh || controller.error != null;
    } else {
      return false;
    }
  }
}

/// Updates loading controller every given period.
class PeriodicRefresher extends LoadingRefresher {
  PeriodicRefresher(this.period) : assert(period != null);

  final Duration period;

  Timer _timer;

  void onTick(Timer timer) {
    controller.setNeedsRefresh();
  }

  @override
  void activate() {
    _timer = Timer.periodic(period, onTick);
  }

  @override
  void deactivate() {
    _timer?.cancel();
  }
}

class ListenerRefresher extends LoadingRefresher {
  ListenerRefresher(this.listenable);

  final Listenable listenable;

  @override
  void activate() {
    listenable.addListener(onChange);
  }

  @override
  void deactivate() {
    listenable.removeListener(onChange);
  }

  void onChange() {
    controller.setNeedsRefresh();
  }
}
