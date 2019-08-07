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
    Key key,
    @required this.controller,
    @required this.builder,
    this.decorator = const AsyncDataDecoration(),
  })  : setup = null,
        super(key: key);

  /// Creates AsyncData with setup method that will create the controller and dispose it when needed.
  const AsyncData.setup({
    Key key,
    @required this.setup,
    @required this.builder,
    this.decorator = const AsyncDataDecoration(),
  })  : controller = null,
        super(key: key);

  /// Creates simple AsyncData, constructing LoadingController with provided fetch and refreshers.
  AsyncData.method({
    Key key,
    @required AsyncControllerFetch<T> fetch,
    List<LoadingRefresher> refreshers,
    @required this.builder,
    this.decorator = const AsyncDataDecoration(),
  })  : controller = null,
        setup = _fromFetch(fetch, refreshers),
        super(key: key);

  /// Source of data and changes.
  final LoadingValueListenable<T> Function() setup;

  final LoadingValueListenable<T> controller;

  /// This builder runs only when data is available.
  final AsyncDataFunction<T> builder;

  /// Provides widgets for AsyncData when there is no data to show.
  final AsyncDataDecoration decorator;

  @override
  _AsyncDataState createState() => _AsyncDataState<T>();

  static _AsyncDataState of(BuildContext context) {
    final state = context.ancestorStateOfType(const TypeMatcher<_AsyncDataState>());
    return state;
  }
}

class _AsyncDataState<T> extends State<AsyncData<T>> {
  int _version;
  LoadingValueListenable<T> _controller;
  LoadingValueListenable<T> get controller => _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newController = widget.controller ?? widget.setup();

    if (newController != _controller) {
      _controller?.removeListener(_handleChange);
      _controller = newController;
      _controller.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    if (widget.controller == null) {
      controller.dispose();
    }
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

LoadingValueListenable<T> Function() _fromFetch<T>(AsyncControllerFetch<T> fetch, List<LoadingRefresher> refreshers) {
  return () {
    final result = AsyncController.method(fetch);
    refreshers.forEach(result.addRefresher);
    return result;
  };
}
