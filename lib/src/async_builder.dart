import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';

typedef Widget AsyncDataFunction<T>(BuildContext context, T data);

/// A widget that let's the user specify builder for asynchronously loaded data.
/// Error handling, empty state and loading are handled by the widget.
/// The automatic handling is customizable with AsyncDataDecoration.
class AsyncData<T> extends StatefulWidget {
  /// Source of data and changes.
  final LoadingValueListenable<T> controller;

  /// This builder runs only when data is not null.
  final AsyncDataFunction<T> builder;

  /// Provides widgets for AsyncData when there is no data to show.
  final AsyncDataDecoration decorator;

  AsyncData({
    Key key,
    @required this.controller,
    @required this.builder,
    this.decorator = const AsyncDataDecoration(),
  }) : super(key: key);

  @override
  _AsyncDataState createState() => _AsyncDataState<T>();

  static AsyncData of(BuildContext context) {
    final state = context.ancestorStateOfType(TypeMatcher<_AsyncDataState>());
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
        assert(widget.controller.value != null);
        return widget.builder(context, widget.controller.value);
      } else if (widget.controller.error != null && !widget.controller.isLoading) {
        return widget.decorator.buildError(context, widget.controller.error, widget.controller.refresh);
      } else if (widget.controller.version == 0) {
        return widget.decorator.buildNoDataYet(context);
      } else {
        return widget.decorator.buildNoData(context);
      }
    }

    Widget child = buildContent();
    return widget.decorator.decorate(child, widget);
  }
}

/// Provides widgets for AsyncData when there is no data to show.
class AsyncDataDecoration {
  factory AsyncDataDecoration.customized({Widget noData}) {
    return _CustomizedAsyncDataDecoration(noData);
  }

  const AsyncDataDecoration();

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
  final Widget customNoData;
  _CustomizedAsyncDataDecoration(this.customNoData);

  @override
  Widget buildNoData(BuildContext context) {
    return customNoData;
  }
}
