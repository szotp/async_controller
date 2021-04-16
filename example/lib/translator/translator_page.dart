import 'dart:async';

import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:example/updating_example.dart';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class TranslatorController extends UpdatingController<String> {
  final _service = GoogleTranslator();

  TranslatorController() : super('');

  @override
  Future<void> update(AsyncFetchItem item, Set<String> keys) async {
    if (data.value.length > 3) {
      _translated = (await _service.translate(data.value)).text;
    } else {
      _translated = '';
    }
  }

  String? _translated;

  String? get translated => _translated;
}

class TranslatorPage extends StatefulWidget with ExamplePage {
  @override
  String get title => 'translator';

  @override
  _TranslatorPageState createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final _translator = TranslatorController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: _translator.data.update,
              decoration: InputDecoration(
                suffixIcon: SyncSuffix(property: _translator.data),
              ),
            ),
            SizedBox(height: 16),
            _translator.buildAsyncProperty<String?>(
              selector: () => _translator.translated,
              builder: (context, translated) {
                if (translated?.isNotEmpty == true) {
                  return Text(translated ?? '', style: TextStyle(fontSize: 30));
                } else {
                  return Text('Please type more than 3 characters...');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
