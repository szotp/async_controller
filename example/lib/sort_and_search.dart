import 'package:async_controller/async_controller.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

import 'helpers.dart';

enum Sorting { ascending, descending }

class SearchingController extends FilteringAsyncController<String> {
  @override
  Future<List<String>> fetchBase() async {
    await Future<void>.delayed(Duration(seconds: 1));
    const faker = Faker();
    return List.generate(100, (_) => faker.person.name());
  }

  @override
  Future<List<String>> transform(List<String> data) async {
    final result = data.toList();

    // apply searching
    if (_searchText?.isNotEmpty == true) {
      final searchingFor = _searchText.toLowerCase();
      bool shouldRemove(String x) {
        return !x.toLowerCase().contains(searchingFor);
      }

      result.removeWhere(shouldRemove);
    }

    // apply sorting
    result.sort((lhs, rhs) {
      if (sorting == Sorting.ascending) {
        return lhs.compareTo(rhs);
      } else {
        return rhs.compareTo(lhs);
      }
    });
    return result;
  }

  String _searchText;
  Sorting sorting = Sorting.ascending;

  void setText(String value) {
    _searchText = value;
    setNeedsLocalTransform();
  }

  void toggleSorting() {
    if (sorting == Sorting.ascending) {
      sorting = Sorting.descending;
    } else {
      sorting = Sorting.ascending;
    }
    setNeedsLocalTransform();
  }
}

class SortAndSearchPage extends StatefulWidget with ExamplePage {
  @override
  String get title => 'Sort & search';

  @override
  _SortAndSearchPageState createState() => _SortAndSearchPageState();
}

class _SortAndSearchPageState extends State<SortAndSearchPage> {
  final _controller = SearchingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              TextField(
                onChanged: _controller.setText,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FlatButton(
                  onPressed: _controller.toggleSorting,
                  child: _controller.buildAsyncProperty<Sorting>(
                    selector: () => _controller.sorting,
                    builder: (context, sorting) {
                      final asc = sorting == Sorting.ascending;
                      if (asc) {
                        return Text('A -> Z');
                      } else {
                        return Text('Z -> A');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _controller.buildAsyncData(
                builder: (context, data) {
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        title: Text(data[i]),
                      );
                    },
                  );
                },
                decorator: const PagedListDecoration(
                    noDataContent: Text('I found nothing...'))),
          ),
        ],
      ),
    );
  }
}
