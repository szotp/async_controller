# async_controller

A library for managing asynchronously loaded data in Flutter. It handles loading indicator, error handling, and refreshing, in few lines of code.

```dart
final _controller = AsyncController<String>.method(() async {
  await Future<void>.delayed(Duration(seconds: 1));
  return 'Hello world';
});

class Minimal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _controller.buildAsyncData(builder: (_, data) {
      // This builder runs only if data is available.
      // buildAsync takes care of other situations
      return Text(data);
    });
  }
}
```

### Pull to refresh

AsynController plays nicely with pull to refresh.
```dart
final _controller = createAsyncController();
RefreshIndicator(
  onRefresh: _controller.performUserInitiatedRefresh,
  child: buildContent()
)
```
[pull_to_refresh.dart](example/lib/pull_to_refresh.dart)

### Loading and error handling

AsyncController used with `buildAsyncData`, automatically handles loading and error states. There is no need to manually change isLoading flag, or catch. AsyncController will do the right thing by default, while allowing for customizations.

### Automatic refresh

Every AsyncController can be customized to automatically refresh itself in certain situations.

* Refresh after network connection comes back.
```dart
controller.addRefresher(OnReconnectedRefresher());
```

* Refresh data every X seconds.
```dart
controller.addRefresher(PeriodicRefresher(Duration(seconds: 3)));
```

* Refresh after user resumes the app from background.
```dart
controller.addRefresher(InForegroundRefresher());
```

* Refresh when another ChangeNotifier updates.
```dart
controller.addRefresher(ListenerRefresher(listenable));
```

5. Easy to use customization through AsyncDataDecoration.
```dart
class MyDecoration extends AsyncDataDecoration {
  @override
  Widget buildNoDataYet(BuildContext context) => MyProgressIndicator();
}
```
[refreshers_page.dart](example/lib/refreshers_page.dart)

#### Paginated data

`PagedAsyncController` class, which extends AsyncController, is capable of loading data in pages.
[paged_loading.dart](example/lib/paged_loading.dart)

#### Filtering & searching

AsyncController can be extended to implement filtering & searching. You do this by extending FilteringAsyncController.
[sort_and_search.dart](example/lib/sort_and_search.dart)

#### Async button

This repository provides AsyncButton class - a button which shows loading indicator when pressed, and a snackbar when async operation fails.
```dart
AsyncButton(
  // AsyncButtons takes a child like typical button
  child: const Text('Press me!'),
  // AsyncButton accepts async onPressed method and handles it
  onPressed: () => Future.delayed(Duration(seconds: 1)),
  // Through builder method we can support any kind of button
  builder: (x) => FlatButton(
    onPressed: x.onPressed,
    child: x.child,
  ),
),
```
Example: [async_button.dart](example/lib/async_button.dart)