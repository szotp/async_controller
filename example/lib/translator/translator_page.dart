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
  Future<String> fetch(AsyncStatus status) {
    if (_input == null || _input.length < 3) {
      return Future.value();
    }
    return _service.translate(_input);
  }
}

class _TranslatorPageState extends State<TranslatorPage> {
  final _data = TranslatorController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: _data.setInput,
              decoration: InputDecoration(
                suffixIcon: _data.buildAsyncVisibility(
                  selector: () => _data.isLoading,
                  child: Icon(Icons.timer),
                ),
              ),
            ),
            SizedBox(height: 16),
            _data.buildAsyncOpacity(
              selector: () => _data.hasFreshData,
              child: _data.buildAsyncData(
                builder: (_, output) {
                  return Text(
                    output ?? '',
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
