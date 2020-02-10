import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/widgets.dart';

class SetNeedsRefreshFlag {
  final bool flagOnlyIfError;
  final bool flagReset;
  final bool flagOnlyIfNotLoading;

  static const always = SetNeedsRefreshFlag();
  static const ifError = SetNeedsRefreshFlag(flagOnlyIfError: true);
  static const reset = SetNeedsRefreshFlag(flagReset: true);
  static const ifNotLoading = SetNeedsRefreshFlag(flagOnlyIfNotLoading: true);

  const SetNeedsRefreshFlag({
    this.flagOnlyIfError = false,
    this.flagReset = false,
    this.flagOnlyIfNotLoading = false,
  });
}

abstract class Refreshable {
  void setNeedsRefresh(SetNeedsRefreshFlag flag);
}

abstract class LoadingRefresher {
  /// Flag that will be used to refresh the controller.
  SetNeedsRefreshFlag flag = SetNeedsRefreshFlag.always;
  Refreshable _controller;

  /// Performs setNeedsRefresh on controller with stored flag
  @protected
  void setNeedsRefresh() {
    _controller?.setNeedsRefresh(flag);
  }

  //ignore: use_setters_to_change_properties
  void mount(Refreshable controller) {
    _controller = controller;
  }

  void activate();
  void deactivate();
}

class InForegroundRefresher extends LoadingRefresher
    with WidgetsBindingObserver {
  @override
  void activate() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setNeedsRefresh();
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
    _sub = stream.listen(onData);
  }

  @protected
  void onData(T data) {
    setNeedsRefresh();
  }

  @override
  void deactivate() {
    _sub.cancel();
  }
}

class OnReconnectedRefresher extends StreamRefresher<ConnectivityResult> {
  OnReconnectedRefresher() : super(Connectivity().onConnectivityChanged) {
    flag = SetNeedsRefreshFlag.ifError;
  }

  bool _wasConnected = false;

  @override
  void onData(ConnectivityResult data) {
    final isConnected = data != ConnectivityResult.none;
    if (isConnected != _wasConnected) {
      _wasConnected = isConnected;
      setNeedsRefresh();
    }
  }
}

/// Updates loading controller every given period.
class PeriodicRefresher extends LoadingRefresher {
  PeriodicRefresher(this.period) : assert(period != null);

  final Duration period;

  Timer _timer;

  void onTick(Timer timer) {
    setNeedsRefresh();
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
    setNeedsRefresh();
  }
}
