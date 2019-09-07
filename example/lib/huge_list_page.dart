import 'package:async_controller/async_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'helpers.dart';

/// Utility to mock paged data loading with various situations.
class _HugeListController extends PagedAsyncController<String> {
  _HugeListController() : super(10);

  @override
  Future<PagedData<String>> fetchPage(int pageIndex) async {
    await Future<void>.delayed(Duration(milliseconds: 500));
    final data =
        List.generate(pageSize, (i) => 'Item ${i + pageIndex * pageSize}');
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
  final _scrollController =
      ScrollController(initialScrollOffset: tileHeight * 10000000);

  static const tileHeight = 50.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: _controller.buildAsyncData(builder: (context, totalCount) {
        // With GridView we can calculate position for given tile without loading every previous tile
        // This lets us instantly jump right into tile X
        // If you don't need jumping functionality, consider using PagedListView
        return GridView.builder(
          controller: _scrollController,
          gridDelegate: const ConstTileHeightGridDelegate(tileHeight),
          itemBuilder: (context, i) {
            final item = _controller.getItem(i);

            if (item != null) {
              return Text(item.toString());
            } else {
              return const Text('Loading...');
            }
          },
        );
      }),
    );
  }
}

class ConstTileHeightGridDelegate extends SliverGridDelegate {
  const ConstTileHeightGridDelegate(this.tileHeight);

  final double tileHeight;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    return ConstTileHeightGridLayout(constraints.crossAxisExtent, tileHeight);
  }

  @override
  bool shouldRelayout(SliverGridDelegate oldDelegate) {
    return false;
  }
}

class ConstTileHeightGridLayout extends SliverGridLayout {
  const ConstTileHeightGridLayout(this.width, this.tileHeight);

  final double width;
  final double tileHeight;

  @override
  double computeMaxScrollOffset(int childCount) {
    return childCount * tileHeight;
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    return SliverGridGeometry(
      crossAxisExtent: width,
      mainAxisExtent: tileHeight,
      crossAxisOffset: 0,
      scrollOffset: index * tileHeight,
    );
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    return scrollOffset ~/ tileHeight + 1;
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    return scrollOffset ~/ tileHeight;
  }
}
