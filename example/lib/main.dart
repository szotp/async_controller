import 'package:example/helpers.dart';
import 'package:example/hooks_example.dart';
import 'package:example/paged_loading.dart';
import 'package:example/refreshers_page.dart';
import 'package:example/sort_and_search.dart';
import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:async_controller/src/debugging.dart';

import 'async_button_example.dart';
import 'failure_handling.dart';
import 'failure_handling_custom.dart';
import 'minimal.dart';
import 'paged_loading_simple.dart';
import 'provider_example.dart';
import 'pull_to_refresh.dart';
import 'translator/translator_page.dart';

void main() {
  internalDebugLogEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExampleSwitcher(),
    );
  }
}

class ExampleSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final examples = <ExamplePage>[
      MinimalExample(),
      PullToRefreshPage(),
      FailureHandlingPage(),
      FailureHandlingCustomPage(),
      PagedLoadingSimplePage(),
      PagedLoadingPage(),
      SortAndSearchPage(),
      AsyncButtonPage(),
      RefreshersPage(),
      TranslatorPage(),
      ProviderExamplePage(),
      HooksExamplePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('async_controller'),
      ),
      body: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, i) {
          final example = examples[i];
          return ListTile(
            title: Text(example.title),
            onTap: () {
              final route =
                  MaterialPageRoute<void>(builder: (context) => examples[i]);
              Navigator.of(context).push(route);
            },
          );
        },
      ),
    );
  }
}
