import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HooksExamplePage extends HookWidget with ExamplePage {
  Future<String> fetch() async {
    await Future<void>.delayed(Duration(seconds: 1));
    return 'Hello world';
  }

  @override
  Widget build(BuildContext context) {
    final loader = useNewChangeNotifier(() => AsyncController.method(fetch))!;
    return Scaffold(
      appBar: buildAppBar(),
      body: loader.buildAsyncData(builder: (_, data) {
        return Center(child: Text(data));
      }),
    );
  }

  @override
  String get title => 'flutter_hooks';
}

/// Creates the provided notifier once, and then disposes it when appropriate.
T? useNewChangeNotifier<T extends ChangeNotifier>(T Function() builder) {
  return use(_NewChangeNotifierHook(builder: builder));
}

class _NewChangeNotifierHook<T extends ChangeNotifier> extends Hook<T?> {
  const _NewChangeNotifierHook({this.builder});

  final T Function()? builder;

  @override
  _NewChangeNotifierHookState<T> createState() =>
      _NewChangeNotifierHookState<T>();
}

class _NewChangeNotifierHookState<T extends ChangeNotifier>
    extends HookState<T?, _NewChangeNotifierHook<T>> {
  T? notifier;

  @override
  void initHook() {
    super.initHook();
    notifier = hook.builder!();
  }

  @override
  T? build(BuildContext context) {
    return notifier;
  }

  @override
  void dispose() {
    notifier!.dispose();
  }
}
