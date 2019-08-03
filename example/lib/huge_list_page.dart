import 'package:async_controller/async_controller.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';

/// Utility to mock paged data loading with various situations.
class _HugeListController extends PagedAsyncController<String> {
  _HugeListController() : super(10);

  Future<PagedData<String>> fetchPage(int pageIndex) async {
    await Future.delayed(Duration(milliseconds: 500));
    final data = List.generate(pageSize, (i) => 'Item ${i + pageIndex * pageSize}');
    return PagedData(pageIndex, null, data);
  }
}

class HugeListPage extends StatefulWidget with ExamplePage {
  @override
  String get title => 'Huge list';

  @override
  _HugeListPageState createState() => _HugeListPageState();
}

class _HugeListPageState extends State<HugeListPage> {
  final _controller = _HugeListController();
  final _scrollController = ScrollController(initialScrollOffset: tileHeight * 10000);

  @override
  void initState() {
    super.initState();
  }

  static const tileHeight = 50.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = constraints.maxWidth / tileHeight;

          return _controller.buildAsyncData(builder: (context, totalCount) {
            // GridView is needed here because it can't calculate position for tile x without calculating height of previous tiles
            return GridView.builder(
              controller: _scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, childAspectRatio: aspectRatio),
              itemBuilder: (context, i) {
                final item = _controller.getItem(i);

                if (item != null) {
                  return Text(item.toString());
                } else {
                  return Text('Loading...');
                }
              },
            );
          });
        },
      ),
    );
  }
}
