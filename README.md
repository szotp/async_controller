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
      // buildAsyncData takes care of other situations
      return Text(data);
    });
  }
}
```

Example: [minimal.dart](example/lib/minimal.dart)

### Pull to refresh

AsynController plays nicely with pull to refresh.
```dart
final _controller = AsyncController.method(fetchSomething);
RefreshIndicator(
  onRefresh: _controller.performUserInitiatedRefresh,
  child: _controller.buildAsyncData(builder: buildContent),
)
```
Example: [pull_to_refresh.dart](example/lib/pull_to_refresh.dart)

### Loading and error handling

AsyncController used with `buildAsyncData`, automatically handles loading and error states. There is no need to manually change isLoading flag, or catch. AsyncController will do the right thing by default, while allowing for customizations.

```dart
final _controller = AsyncController.method(() => throw 'error');
_controller.buildAsyncData(builder: builder: (_, data) {
  // this function runs only on success
  return Text(data);
})
```
Example: [failure_handling.dart](example/lib/failure_handling.dart)

### Custom loading and error handling
Loading are error handling widgets are created by AsyncDataDecoration. You may override their behavior by creating custom AsyncDataDecoration. The same decorator can then be used in every AsyncData in your app.
```dart
class CustomAsyncDataDecoration extends AsyncDataDecoration {
  @override
  Widget buildError(BuildContext context, dynamic error, VoidCallback tryAgain) {
    return Text('Sorry :(');
  }
}

final _controller = AsyncController.method(() => throw 'error');
_controller.buildAsyncData(
  builder: buildContent,
  decorator: CustomAsyncDataDecoration(),
)
```

Example: [failure_handling_custom.dart](example/lib/failure_handling_custom.dart)

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
Example: [refreshers_page.dart](example/lib/refreshers_page.dart)

#### Paginated data

`PagedAsyncController` class, which extends AsyncController, is capable of loading data in pages.

Example: [paged_loading.dart](example/lib/paged_loading.dart)

#### Filtering & searching

AsyncController can be extended to implement filtering & searching. You do this by extending FilteringAsyncController.
Example: [sort_and_search.dart](example/lib/sort_and_search.dart)

#### Async button

Not really related to AsyncController, but still useful. AsyncButton is a button that handles async onPressed methods. When user presses the button:
* starts the async operation provided in onPressed method
* shows loading indicator
* blocks the user interface to avoid typing on keyboard or leaving the page
* in case error, shows snackbar
* finally, cleans up loading indicator & interface lock

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
Example: [async_button_example.dart](example/lib/async_button_example.dart)