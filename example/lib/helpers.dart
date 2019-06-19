import 'package:flutter/material.dart';

class TitledValue<T> {
  final String title;
  final T value;

  TitledValue(this.title, this.value);
}

abstract class ExamplePage implements Widget {
  String get title;

  AppBar buildAppBar() {
    return AppBar(title: Text(title));
  }
}

class CasePicker<T> extends StatefulWidget {
  final AppBar appBar;
  final List<TitledValue<T>> cases;
  final Widget Function(BuildContext context, T item) builder;

  CasePicker({Key key, this.builder, this.cases, this.appBar}) : super(key: key);

  @override
  _CasePickerState createState() => _CasePickerState<T>();
}

class _CasePickerState<T> extends State<CasePicker<T>> {
  int index = 0;

  void setIndex(int newIndex) {
    final last = widget.cases.length - 1;

    if (newIndex < 0) {
      newIndex = last;
    }

    if (newIndex > last) {
      newIndex = 0;
    }

    setState(() {
      index = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.cases[index];

    var i = 0;
    final items = widget.cases.map((x) {
      return DropdownMenuItem<int>(
        child: Text(x.title),
        value: i++,
      );
    });

    return Scaffold(
      appBar: widget.appBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  setIndex(index - 1);
                },
              ),
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: index,
                  items: items.toList(),
                  onChanged: (i) {
                    setState(() {
                      index = i;
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  setIndex(index + 1);
                },
              ),
            ],
          ),
          Expanded(
            child: widget.builder(context, item.value),
          ),
        ],
      ),
    );
  }
}
