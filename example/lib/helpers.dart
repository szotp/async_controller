import 'package:flutter/material.dart';

class CasePickerItem {
  const CasePickerItem(this.title, this.builder);

  final String title;
  final WidgetBuilder builder;
}

// ignore: avoid_implementing_value_types
abstract class ExamplePage implements Widget {
  String get title;

  AppBar buildAppBar() {
    return AppBar(title: Text(title));
  }
}

class CasePicker extends StatefulWidget {
  const CasePicker({Key key, this.cases, this.appBar}) : super(key: key);

  final AppBar appBar;
  final List<CasePickerItem> cases;

  @override
  _CasePickerState createState() => _CasePickerState();
}

class _CasePickerState extends State<CasePicker> {
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
            child: Builder(builder: item.builder),
          ),
        ],
      ),
    );
  }
}
