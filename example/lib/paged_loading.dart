import 'dart:math';

import 'package:async_controller/async_controller.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';

/// Utility to mock paged data loading with various situations.
class FakePageDataProvider extends PagedAsyncController<String> {
  FakePageDataProvider(
    this.totalCount, {
    this.errorChance = 0,
    this.errorChanceOnFirstPage,
  });

  @override
  final int totalCount;
  final int errorChance;
  final int? errorChanceOnFirstPage;

  @override
  Future<PagedData<String>> fetchPage(int pageIndex) async {
    final index = pageSize * pageIndex;
    await Future<void>.delayed(Duration(milliseconds: 500));

    int? chance = errorChance;
    if (pageIndex == 0 && errorChanceOnFirstPage != null) {
      chance = errorChanceOnFirstPage;
    }

    if (chance! > Random().nextInt(100)) {
      throw 'Random failure';
    }

    final count = min(totalCount, index + pageSize) - index;
    final list =
        Iterable.generate(count, (i) => 'Item ${index + i + 1}').toList();

    return PagedData(pageIndex, totalCount, list);
  }

  @override
  void deactivate() {
    super.deactivate();
    reset();
  }

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
  );

  CasePickerItem buildCase(String title, FakePageDataProvider provider,
      [Widget Function(FakePageDataProvider)? builder]) {
    return CasePickerItem(title, (context) => (builder ?? buildList)(provider));
  }

  List<CasePickerItem>? cases;

  @override
  Widget build(BuildContext context) {
    cases ??= [
      buildCase('Always works', FakePageDataProvider(25)),
      buildCase('No content', FakePageDataProvider(0)),
      buildCase('Always error', FakePageDataProvider(0, errorChance: 100)),
      buildCase('Sometimes error', FakePageDataProvider(1000, errorChance: 50)),
      buildCase(
        'Always error on next page',
        FakePageDataProvider(1000, errorChance: 100, errorChanceOnFirstPage: 0),
      ),
      buildCase('Grid', FakePageDataProvider(1000), buildGridExample),
    ];

    return CasePicker(appBar: widget.buildAppBar(), cases: cases);
  }

  Widget buildGridExample(FakePageDataProvider provider) {
    return PagedListView(
      controller: provider,
      itemBuilder: (context, i, dynamic item) {
        return Container(
          color: Colors.grey[300],
          child: Center(child: Text('$item')),
        );
      },
      listBuilder: (context, itemCount, itemBuilder) {
        return GridView.builder(
          itemBuilder: itemBuilder,
          itemCount: itemCount,
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
        );
      },
    );
  }

  Widget buildList(FakePageDataProvider _controller) {
    return PagedListView<String>(
      controller: _controller,
      itemBuilder: (_, i, data) {
        return Text(data);
      },
      decoration: _decorator,
    );
  }
}
