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

class OnReconnectedRefresher extends LoadingRefresher {
  OnReconnectedRefresher([this.alwaysRefresh = false]);

  final bool alwaysRefresh;

  StreamSubscription _sub;
  bool _wasConnected = false;

  @override
  void activate() {
    _sub = Connectivity().onConnectivityChanged.listen(_onData);
  }

  void _onData(ConnectivityResult state) {
    final isConnected = state != ConnectivityResult.none;
    if (isConnected != _wasConnected) {
      _wasConnected = isConnected;

      if (alwaysRefresh || controller.error != null) {
        controller.setNeedsRefresh();
      }
    }
  }

  @override
  void deactivate() {
    _sub.cancel();
    _sub = null;
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
