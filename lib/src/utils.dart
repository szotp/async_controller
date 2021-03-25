import 'package:flutter/widgets.dart';

class AsyncPropertyBuilder<P> extends StatefulWidget {
  const AsyncPropertyBuilder(
      {Key? key,
      required this.selector,
      required this.builder,
      required this.listenable})
      : super(key: key);

  final Listenable listenable;
  final P Function() selector;
  final Widget Function(BuildContext, P) builder;

  @override
  _AsyncPropertyBuilderState createState() => _AsyncPropertyBuilderState<P>();
}

class _AsyncPropertyBuilderState<P> extends State<AsyncPropertyBuilder<P?>> {
  P? _current;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_handleChange);
    _current = widget.selector();
  }

  @override
  void didUpdateWidget(AsyncPropertyBuilder<P?> oldWidget) {
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
    final P? now = widget.selector();
    if (now != _current) {
      setState(() {
        _current = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _current);
  }
}
