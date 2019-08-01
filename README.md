# async_controller

A library for managing asynchronously loaded data in Flutter.

```dart
final _controller = AsyncController<String>.method(() async {
  await Future.delayed(Duration(seconds: 1));
  return 'Hello world';
});

class Minimal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _controller.buildAsync(builder: (_, data) {
      // This builder runs only if data is available.
      // buildAsync takes care of other situations
      return Text(data);
    });
  }
}
```

### How is this better than a FutureBuilder?

AsyncController automatically handles boring edge cases, letting you focus on the happy path. It provides:
1. A refresh method that can be combined with RefreshIndicator widget for pull to refresh. No `setState` needed!
2. A loading spinner when data is loading.
3. Error widget when something goes wrong, with a 'Try again' button.
4. Optional and extensible refreshing behaviors:
  * Refresh data every X seconds.
  ```dart
  controller.addRefresher(PeriodicRefresher(Duration(seconds: 3)));
  ```

  * Refresh after network connection comes back.
  ```dart
  controller.addRefresher(OnReconnectedRefresher());
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

### Extras

This repository also contains `PagedAsyncController` built on top of `AsyncController`, designed for incrementally loading lists.

Finally, there is `AsyncButton` - a button that can handle async operation, by showing loading indicator when operation is pending, and show snackbar when it fails.

### Examples

Please check out the example project to see each feature in action.
