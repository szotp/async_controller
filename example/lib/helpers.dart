import 'package:flutter/material.dart';

class TitledValue<T> {
  const TitledValue(this.title, this.value);

  final String title;
  final T value;
}

// ignore: avoid_implementing_value_types
abstract class ExamplePage implements Widget {
  String get title;

  AppBar buildAppBar() {
    return AppBar(title: Text(title));
  }
}

class CasePicker<T> extends StatefulWidget {
  const CasePicker({Key key, this.builder, this.cases, this.appBar})
      : super(key: key);

  final AppBar appBar;
  final List<TitledValue<T>> cases;
  final Widget Function(BuildContext context, T item) builder;

  @override
  _CasePickerState createState() => _CasePickerState<T>();
}

class _CasePickerState<T> extends State<CasePicker<T>> {
  int index = 0;

  void setIndex(int newIndex) {
    var index = newIndex;
    final last = widget.cases.length - 1;

    if (newIndex < 0) {
      index = last;
    }

    if (newIndex > last) {
      index = 0;
    }

    setState(() {
      this.index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.cases[index];

    var i = 0;
    final items = widget.cases.map((x) {
      return DropdownMenuItem<int>(
        value: i++,
        child: Text(x.title),
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
