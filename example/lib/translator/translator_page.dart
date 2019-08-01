import 'dart:async';

import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class TranslatorPage extends StatefulWidget with ExamplePage {
  @override
  String get title => 'translator';

  @override
  _TranslatorPageState createState() => _TranslatorPageState();
}

class TranslatorController extends AsyncController<String> {
  final _service = GoogleTranslator();

  @override
  Duration get delayToRefresh => Duration(seconds: 1);

  String _input;

  void setInput(String newValue) {
    _input = newValue;
    setNeedsRefresh();
  }

  @override
  Future<String> fetch() {
    if (_input == null || _input.length < 3) {
      return null;
    }
    return _service.translate(_input);
  }
}

class _TranslatorPageState extends State<TranslatorPage> {
  final _controller = TranslatorController();

  /// child will be slightly transparent when data is not fresh
  Widget buildDynamicOpacity(Widget child) {
    return _controller.buildAsyncProperty(
      selector: () => _controller.hasFreshData,
      builder: (context, hasFreshData) {
        return Opacity(opacity: hasFreshData ? 1.0 : 0.5, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: _controller.setInput,
            ),
            SizedBox(height: 16),
            buildDynamicOpacity(
              _controller.buildAsyncData(
                builder: (_, output) {
                  return Text(
                    output,
                    style: TextStyle(fontSize: 30),
                  );
                },
                decorator: AsyncDataDecoration.customized(
                  noData: Text('Please type more than 3 characters...'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
