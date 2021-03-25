import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';

typedef AsyncDataFunction<T> = Widget Function(BuildContext context, T data);

/// A widget that let's the user specify builder for asynchronously loaded data.
/// Error handling, empty state and loading are handled by the widget.
/// The automatic handling is customizable with AsyncDataDecoration.
class AsyncData<T> extends StatefulWidget {
  /// Creates AsyncData with already existing controller.
  const AsyncData({
    Key? key,
    required this.controller,
    required this.builder,
    this.decorator = const AsyncDataDecoration(),
  }) : super(key: key);

  final AsyncController<T> controller;

  /// This builder runs only when data is available.
  final AsyncDataFunction<T> builder;

  /// Provides widgets for AsyncData when there is no data to show.
  final AsyncDataDecoration decorator;

  @override
  _AsyncDataState createState() => _AsyncDataState<T>();

  static _AsyncDataState? of(BuildContext context) {
    final result = context.findAncestorStateOfType<_AsyncDataState>();
    if (result == null && context is StatefulElement) {
      final state = context.state;
      if (state is _AsyncDataState) {
        return state;
      }
    }

    return result;
  }
}

class _AsyncDataState<T> extends State<AsyncData<T>> {
  int _version = 0;

  AsyncController<T> get controller => widget.controller;

  @override
  void initState() {
    widget.controller.addListener(_handleChange);
    super.initState();
  }

  @override
  void didUpdateWidget(AsyncData<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      widget.controller.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (_version > 0 && _version == widget.controller.version) {
      // skip unnecessary rebuilds after data is available
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _version = widget.controller.version;

    Widget buildContent() {
      switch (widget.controller.state) {
        case AsyncControllerState.hasData:
          final data = widget.controller.value;
          assert(data != null);
          if (data == null) {
            return SizedBox();
          }
          return widget.builder(context, data);
        case AsyncControllerState.failed:
          return widget.decorator.buildError(context, widget.controller.error,
              widget.controller.performUserInitiatedRefresh);
        case AsyncControllerState.noDataYet:
          return widget.decorator.buildNoDataYet(context);
        case AsyncControllerState.noData:
          return widget.decorator.buildNoData(context);
      }
    }

    final child = buildContent();
    return widget.decorator.decorate(child, widget);
  }
}

/// Provides widgets for AsyncData when there is no data to show.
class AsyncDataDecoration {
  const AsyncDataDecoration();

  factory AsyncDataDecoration.customized({Widget? noData}) {
    return _CustomizedAsyncDataDecoration(noData);
  }

  /// Constructs widget (usually Text) to describe given error
  Widget buildErrorDescription(BuildContext context, dynamic error) {
    return Text(error.toString());
  }

  /// There was error during fetch, we don't data to show so we may show error with try again button.
  Widget buildError(
      BuildContext context, dynamic error, VoidCallback tryAgain) {
    final errorWidget = buildErrorDescription(context, error);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            errorWidget,
            IconButton(icon: Icon(Icons.refresh), onPressed: tryAgain),
          ],
        ),
      ),
    );
  }

  /// Shows error after AsyncButton failed.
  /// By default, a snackbar.
  void showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: buildErrorDescription(context, error),
    ));
  }

  /// There is no data because it was not loaded yet.
  Widget buildNoDataYet(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// There is not data because fetch returned null.
  Widget buildNoData(BuildContext context) {
    return buildNoDataYet(context);
  }

  /// Always runs, gives possiblity to add the same widget for each state.
  Widget decorate(Widget child, AsyncData builder) {
    return child;
  }
}

class _CustomizedAsyncDataDecoration extends AsyncDataDecoration {
  _CustomizedAsyncDataDecoration(this.customNoData);
  final Widget? customNoData;

  @override
  Widget buildNoData(BuildContext context) {
    return customNoData ?? SizedBox();
  }
}
