import 'package:async_controller/async_controller.dart';
import 'package:example/helpers.dart';
import 'package:flutter/material.dart';

class Settings {
  late String login;
  late String password;
  double limit = 0;
}

class UpdatingExampleController extends UpdatingController<Settings> {
  UpdatingExampleController() : super(Settings()..login = 'x');

  @override
  Future<void> update(AsyncFetchItem item, Set<String> keys) async {
    await Future.delayed(Duration(seconds: 1));
    return Future.value();
  }

  UpdatingProperty<String> get login =>
      bind('login', (x) => x.login, (x, v) => x.login = v);
  UpdatingProperty<String> get password =>
      bind('password', (x) => x.password, (x, v) => x.password = v);
  UpdatingProperty<double> get limit =>
      bind('limit', (x) => x.limit, (x, v) => x.limit = v);
}

class UpdatingExample extends StatefulWidget with ExamplePage {
  @override
  String get title => 'Updating';

  @override
  _UpdatingExampleState createState() => _UpdatingExampleState();
}

class _UpdatingExampleState extends State<UpdatingExample> {
  final _c = UpdatingExampleController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.buildAppBar(),
      body: ListView(
        children: <Widget>[
          buildTextField(property: _c.login),
          buildTextField(property: _c.password),
          Row(
            children: <Widget>[
              Expanded(
                child: AsyncPropertyBuilder(
                  listenable: _c.limit,
                  selector: _c.limit.read,
                  builder: (context, _, __) {
                    return Slider(
                      value: _c.limit.value,
                      onChanged: _c.limit.update,
                    );
                  },
                ),
              ),
              SyncSuffix(property: _c.limit),
              SizedBox(width: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTextField({required UpdatingProperty<String> property}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: TextFormField(
        autovalidateMode: AutovalidateMode.always,
        initialValue: property.value,
        onChanged: property.update,
        decoration: InputDecoration(
          suffixIcon: SyncSuffix(property: property),
        ),
      ),
    );
  }
}

/// Displays icon when property is syncing
class SyncSuffix extends StatelessWidget {
  final UpdatingProperty property;

  const SyncSuffix({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: UpdatingPropertyListener(
        property: property,
        decorator: (context, status, info) {
          switch (status) {
            case UpdatingPropertyStatus.ok:
              return Icon(null);
            case UpdatingPropertyStatus.error:
              return IconButton(
                icon: Icon(Icons.sync_problem),
                onPressed: property.recoverFromError,
              );
            case UpdatingPropertyStatus.needsUpdate:
              return Opacity(
                opacity: 0.5,
                child: Icon(Icons.sync),
              );

            case UpdatingPropertyStatus.isUpdating:
              return Icon(Icons.sync);
          }
        },
      ),
    );
  }
}
