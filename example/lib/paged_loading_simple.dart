import 'package:async_controller/async_controller.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';

class _SimpleController extends PagedAsyncController<int> {
  _SimpleController() : super(10);

  @override
  Future<PagedData<int>> fetchPage(int pageIndex) async {
    return PagedData(
      pageIndex,
      100000,
      List.generate(pageSize, (i) => i + pageIndex * pageSize),
    );
  }
}

final _controller = _SimpleController();

class PagedLoadingSimplePage extends StatelessWidget with ExamplePage {
  @override
  String get title => 'Paged data - simplest';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: PagedListView<int>(
        dataController: _controller,
        itemBuilder: (_, __, item) {
          return ListTile(title: Text(item.toString()));
        },
      ),
    );
  }
}
