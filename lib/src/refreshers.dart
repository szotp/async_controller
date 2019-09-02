import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/widgets.dart';

enum SetNeedsRefreshFlag {
  always,
  ifError,
  reset,
}

abstract class Refreshable {
  void setNeedsRefresh(SetNeedsRefreshFlag flag);
}

abstract class LoadingRefresher {
  Refreshable _controller;

  void setNeedsRefresh(SetNeedsRefreshFlag flag) {
    _controller?.setNeedsRefresh(flag);
  }

  void mount(Refreshable controller) {
    _controller = controller;
  }

  void activate();
  void deactivate();
}

class InForegroundRefresher extends LoadingRefresher with WidgetsBindingObserver {
  @override
  void activate() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setNeedsRefresh(SetNeedsRefreshFlag.always);
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

  SetNeedsRefreshFlag shouldRefresh(T data) => SetNeedsRefreshFlag.always;

  void _onData(T data) {
    final flag = shouldRefresh(data);
    if (flag != null) {
      setNeedsRefresh(flag);
    }
  }

  @override
  void deactivate() {
    _sub.cancel();
  }
}

class OnReconnectedRefresher extends StreamRefresher<ConnectivityResult> {
  OnReconnectedRefresher([this.flag = SetNeedsRefreshFlag.ifError]) : super(Connectivity().onConnectivityChanged);

  final SetNeedsRefreshFlag flag;
  bool _wasConnected = false;

  @override
  SetNeedsRefreshFlag shouldRefresh(ConnectivityResult data) {
    final isConnected = data != ConnectivityResult.none;
    if (isConnected != _wasConnected) {
      _wasConnected = isConnected;
      return flag;
    } else {
      return null;
    }
  }
}

/// Updates loading controller every given period.
class PeriodicRefresher extends LoadingRefresher {
  PeriodicRefresher(this.period) : assert(period != null);

  final Duration period;

  Timer _timer;

  void onTick(Timer timer) {
    setNeedsRefresh(SetNeedsRefreshFlag.always);
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

class ListeningRefresher extends LoadingRefresher {
  ListeningRefresher(this.listenable);

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
    setNeedsRefresh(SetNeedsRefreshFlag.always);
  }
}
