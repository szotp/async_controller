import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';

typedef Widget AsyncBuilderFunction<T>(BuildContext context, T data);

class AsyncBuilder<T> extends StatefulWidget {
  /// Source of data and changes.
  final LoadingValueListenable<T> controller;

  /// This builder runs only when data is not null.
  final AsyncBuilderFunction<T> builder;

  /// Provides widgets for AsyncBuilder when there is no data to show.
  final AsyncBuilderDecoration decorator;

  AsyncBuilder({
    Key key,
    @required this.controller,
    @required this.builder,
    this.decorator = const AsyncBuilderDecoration(),
  }) : super(key: key);

  @override
  _AsyncBuilderState createState() => _AsyncBuilderState<T>();

  static AsyncBuilder of(BuildContext context) {
    final state = context.ancestorStateOfType(TypeMatcher<_AsyncBuilderState>());
    return state.widget;
  }
}

class _AsyncBuilderState<T> extends State<AsyncBuilder<T>> {
  int _version;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(AsyncBuilder<T> oldWidget) {
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

/// Provides widgets for AsyncBuilder when there is no data to show.
class AsyncBuilderDecoration {
  const AsyncBuilderDecoration();

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
  Widget decorate(Widget child, AsyncBuilder builder) {
    return child;
  }
}
