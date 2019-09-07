# async_controller

A library for managing asynchronously loaded data in Flutter.

### Do I need this?
If your project contains `isLoading` flags or error handling duplicated across many pages, you may benefit from this package. It will let you write async loading with minimal amount of boilerplate. Unlike FutureBuilder, AsyncController ensures that fetch is performed only when necessary. You may configure when controller should refresh using provided Refreshers. More on that later.

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
AsynController provides a method that you can plug right into a RefreshIndicator. Also, if user tries to refresh while loading is already pending the previous loading will be cancelled. 

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

### Interaction with other packages

AsyncController plays nicely with other. It implements ChangeNotifier and ValueListenable - classes commonly used inside Flutter. You can use it with any state management / dependency injection that you want. The example project includes samples for flutter_hooks and provider.

Example 1: [hooks_example.dart](example/lib/hooks_example.dart)

Example 2: [provider_example.dart](example/lib/provider_example.dart)