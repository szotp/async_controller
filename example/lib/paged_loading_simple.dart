import 'package:async_controller/async_controller.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';

class _SimpleController extends PagedAsyncController<int> {
  _SimpleController();

  @override
  Future<PagedData<int>> fetchPage(int pageIndex) async {
    await Future<dynamic>.delayed(Duration(milliseconds: 150)); //<----- delay

    return PagedData(
      pageIndex,
      1000,
      List.generate(10, (i) => i + pageIndex * 10),
    );
  }
}

class PagedLoadingSimplePage extends StatefulWidget with ExamplePage {
  @override
  String get title => 'Paged data - simplest';

  @override
  _PagedLoadingSimplePageState createState() => _PagedLoadingSimplePageState();
}

class _PagedLoadingSimplePageState extends State<PagedLoadingSimplePage> {
  final _controller = _SimpleController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: PagedListView<int>(
        controller: _controller,
        itemBuilder: (_, __, item) {
          return ListTile(title: Text(item.toString()));
        },
      ),
    );
  }
}
