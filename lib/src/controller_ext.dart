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

    final value = this.value;

    if (version > 0 && value != null) {
      return AsyncSnapshot.withData(connection, value);
    } else if (error != null) {
      return AsyncSnapshot.withError(connection, error!);
    } else {
      return AsyncSnapshot.waiting();
    }
  }

  AsyncData<T> buildAsyncData({
    required AsyncDataFunction<T> builder,
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
    required P Function() selector,
    required Widget Function(BuildContext, P) builder,
  }) {
    return AsyncPropertyBuilder<P>(
      selector: selector,
      listenable: this,
      builder: builder,
    );
  }

  Widget buildAsyncVisibility(
      {required bool Function() selector, required Widget child}) {
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
    required bool Function() selector,
    required Widget child,
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
