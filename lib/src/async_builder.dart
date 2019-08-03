import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';

typedef AsyncDataFunction<T> = Widget Function(BuildContext context, T data);

/// A widget that let's the user specify builder for asynchronously loaded data.
/// Error handling, empty state and loading are handled by the widget.
/// The automatic handling is customizable with AsyncDataDecoration.
class AsyncData<T> extends StatefulWidget {
  const AsyncData({
    Key key,
    @required this.controller,
    @required this.builder,
    this.decorator = const AsyncDataDecoration(),
  }) : super(key: key);

  /// Source of data and changes.
  final LoadingValueListenable<T> controller;

  /// This builder runs only when data is not null.
  final AsyncDataFunction<T> builder;

  /// Provides widgets for AsyncData when there is no data to show.
  final AsyncDataDecoration decorator;

  @override
  _AsyncDataState createState() => _AsyncDataState<T>();

  static AsyncData of(BuildContext context) {
    final state = context.ancestorStateOfType(const TypeMatcher<_AsyncDataState>());
    return state.widget;
  }
}

class _AsyncDataState<T> extends State<AsyncData<T>> {
  int _version;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(AsyncData<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      widget.controller.addListener(_handleChange);
      _version = null;
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
      if (widget.controller.hasData) {
        return widget.builder(context, widget.controller.value);
      } else if (widget.controller.error != null && !widget.controller.isLoading) {
        return widget.decorator.buildError(context, widget.controller.error, widget.controller.refresh);
      } else if (widget.controller.version == 0) {
        return widget.decorator.buildNoDataYet(context);
      } else {
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

  factory AsyncDataDecoration.customized({Widget noData}) {
    return _CustomizedAsyncDataDecoration(noData);
  }

  /// There was error during fetch, we don't data to show so we may show error with try again button.
  Widget buildError(BuildContext context, dynamic error, VoidCallback tryAgain) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(error.toString()),
          IconButton(icon: Icon(Icons.refresh), onPressed: tryAgain),
        ],
      ),
    );
  }

  /// There is no data because it was not loaded yet.
  Widget buildNoDataYet(BuildContext context) {
    return Center(
      child: const CircularProgressIndicator(),
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
  final Widget customNoData;

  @override
  Widget buildNoData(BuildContext context) {
    return customNoData;
  }
}
