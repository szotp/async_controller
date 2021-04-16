import 'package:flutter/widgets.dart';

import '../async_controller.dart';
import 'async_data.dart';

class DefaultAsyncDataDecoration extends StatelessWidget {
  final AsyncDataDecoration data;
  final Widget child;

  const DefaultAsyncDataDecoration({
    Key key,
    @required this.data,
    @required this.child,
  }) : super(key: key);

  static AsyncDataDecoration of(BuildContext context) =>
      context
          .findAncestorWidgetOfExactType<DefaultAsyncDataDecoration>()
          ?.data ??
      const AsyncDataDecoration();

  @override
  Widget build(BuildContext context) => child;
}
