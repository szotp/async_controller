import 'dart:math';

import 'package:async_controller/async_controller.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';

/// Utility to mock paged data loading with various situations.
class FakePageDataProvider extends PagedAsyncController<String> {
  final int totalCount;
  final int errorChance;

  FakePageDataProvider(this.totalCount, {this.errorChance = 0}) : super(5);

  Future<PagedData<String>> fetchPage(int pageIndex) async {
    final index = pageSize * pageIndex;
    await Future.delayed(Duration(milliseconds: 500));

    if (errorChance > Random().nextInt(100)) {
      throw 'Random failure';
    }

    final count = min(totalCount, index + pageSize) - index;
    final list = Iterable.generate(count, (i) => 'Item ${index + i + 1}').toList();

    print('fetchPage, ${list.length} items');
    return PagedData(index, totalCount, list);
  }

  @override
  void deactivate() {
    super.deactivate();
    reset();
  }

  @override
  int get pageSize => 5;
}

class PagedLoadingPage extends StatefulWidget with ExamplePage {
  @override
  String get title => 'Paged data';

  @override
  _PagedLoadingPageState createState() => _PagedLoadingPageState();
}

class _PagedLoadingPageState extends State<PagedLoadingPage> {
  final _decorator = PagedListDecoration(
    noDataContent: Text('Sorry, no data'),
    addRefreshIndicator: true,
  );

  final cases = [
    TitledValue('Always works', FakePageDataProvider(25)),
    TitledValue('No content', FakePageDataProvider(0)),
    TitledValue('Always error', FakePageDataProvider(0, errorChance: 100)),
    TitledValue('Sometimes error', FakePageDataProvider(1000, errorChance: 50)),
  ];

  @override
  Widget build(BuildContext context) {
    return CasePicker<FakePageDataProvider>(
      appBar: widget.buildAppBar(),
      cases: cases,
      builder: buildCase,
    );
  }

  Widget buildCase(BuildContext context, FakePageDataProvider _controller) {
    return PagedListView<String>(
      dataController: _controller,
      itemBuilder: (_, i, data) {
        return Text(data);
      },
      decoration: _decorator,
    );
  }
}
