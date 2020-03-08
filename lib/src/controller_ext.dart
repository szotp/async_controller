import 'package:flutter/widgets.dart';

import 'async_data.dart';
import 'controller.dart';
import 'utils.dart';

extension AsyncControllerExt<T> on AsyncController<T> {
  /// Provides AsyncSnapshot for compability with other widgets.
  /// It is usually better to use state property.
  AsyncSnapshot<T> get snapshot {
    ConnectionState connection;

    if (isLoading) {
      connection = ConnectionState.waiting;
    } else {
      connection = ConnectionState.done;
    }

    if (version > 0) {
      return AsyncSnapshot.withData(connection, value);
    } else if (error != null) {
      return AsyncSnapshot.withError(connection, error);
    } else {
      return AsyncSnapshot.withData(connection, null);
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
}

extension ListenableExt on Listenable {
  /// Returns reactive widget that builds when value returned from selector is different than before.
  /// The selector runs only when this controller changes.
  Widget buildAsyncProperty<P>({
    @required P Function() selector,
    @required Widget Function(BuildContext, P) builder,
  }) {
    return AsyncPropertyBuilder<P>(
      selector: selector,
      listenable: this,
      builder: (context, value, child) => builder(context, value),
    );
  }

  Widget buildAsyncVisibility({bool Function() selector, Widget child}) {
    return AsyncPropertyBuilder<bool>(
      selector: selector,
      listenable: this,
      builder: (_, visible, __) {
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
      builder: (_, value, __) {
        return Opacity(
          opacity: value ? opacityForTrue : opacityForFalse,
          child: child,
        );
      },
    );
  }
}
