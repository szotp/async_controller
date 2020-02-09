import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Loader extends AsyncController<String> {
  @override
  Future<String> fetch(AsyncFetchItem status) async {
    await Future<void>.delayed(Duration(seconds: 1));
    return 'Hello world';
  }

  static _Loader create(BuildContext context) => _Loader();
}

class ProviderExamplePage extends StatelessWidget with ExamplePage {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: _Loader.create,
      child: Scaffold(
        appBar: buildAppBar(),
        body: Builder(
          builder: buildBody,
        ),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    final loader = Provider.of<_Loader>(context, listen: false);
    return loader.buildAsyncData(builder: (context, data) {
      return Center(child: Text(data));
    });
  }

  @override
  String get title => 'provider example';
}
