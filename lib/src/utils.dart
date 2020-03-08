import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AsyncPropertyBuilder<P> extends StatefulWidget {
  const AsyncPropertyBuilder(
      {Key key,
      @required this.selector,
      @required this.builder,
      @required this.listenable,
      this.child})
      : super(key: key);

  final Listenable listenable;
  final P Function() selector;
  final ValueWidgetBuilder<P> builder;
  final Widget child;

  @override
  _AsyncPropertyBuilderState createState() => _AsyncPropertyBuilderState<P>();
}

class _AsyncPropertyBuilderState<P> extends State<AsyncPropertyBuilder<P>> {
  P _current;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_handleChange);
    _current = widget.selector();
  }

  @override
  void didUpdateWidget(AsyncPropertyBuilder<P> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_handleChange);
      widget.listenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    final now = widget.selector();
    if (now != _current) {
      setState(() {
        _current = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _current, widget.child);
  }
}

/// A getter and setter associated with given listenable.
abstract class Property<T> extends ValueListenable<T> {
  void update(T newValue);
}

extension ValueListenableRead<T> on ValueListenable<T> {
  T read() => value;
}
