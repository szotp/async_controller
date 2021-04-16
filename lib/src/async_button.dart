import 'package:flutter/material.dart';

typedef AsyncButtonFunction = Future<void> Function();
typedef AsyncButtonBuilder = Widget Function(AsyncButtonSettings settings);

class AsyncButtonSettings {
  AsyncButtonSettings(this.context, this.child, this.onPressed);

  final BuildContext context;
  final Opacity child;
  final VoidCallback onPressed;

  Color loadingColor;
}

class AsyncButton extends StatefulWidget {
  const AsyncButton({
    Key key,
    @required this.onPressed,
    @required this.child,
    this.builder,
    this.loadingColor,
    this.lockInterface = true,
  }) : super(key: key);

  final AsyncButtonFunction onPressed;
  final Widget child;
  final AsyncButtonBuilder builder;
  final Color loadingColor;

  /// Should the UI be completely locked when operation is pending? Default: true.
  /// Note: if false, this button will still support only one execution at a time
  /// This flag is more useful to prevent user from pressing on multiple different commands.
  final bool lockInterface;

  @override
  AsyncButtonState createState() => AsyncButtonState();

  void showError(Object error, BuildContext context) {
    final scaffold = Scaffold.of(context);
    scaffold.showSnackBar(SnackBar(
      content: Text(error.toString()),
    ));
  }

  Widget buildLoadingIndicator(Color loadingColor) {
    Animation<Color> valueColor;

    final loadingColorMerged = loadingColor ?? this.loadingColor;

    if (loadingColorMerged != null) {
      valueColor = AlwaysStoppedAnimation(loadingColorMerged);
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: CircularProgressIndicator(valueColor: valueColor),
      ),
    );
  }

  Widget overlayContent(BuildContext context) {
    return Container(
      color: Colors.transparent,
    );
  }

  Widget build(AsyncButtonState state) {
    final settings = AsyncButtonSettings(
      state.context,
      Opacity(
        opacity: state.isLoading ? 0.5 : 1.0,
        child: child,
      ),
      state.onPressed,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        builder(settings),
        Visibility(
          visible: state.isLoading,
          child: Positioned.fill(
            child: Center(child: buildLoadingIndicator(settings.loadingColor)),
          ),
        )
      ],
    );
  }

  double get childOpacityWhenLoading => 0.5;
}

class AsyncButtonState extends State<AsyncButton> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _update(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  VoidCallback get onPressed {
    if (widget.onPressed != null) {
      return execute;
    } else {
      return null;
    }
  }

  Future<void> execute() async {
    if (isLoading) {
      return;
    }

    OverlayEntry _entry;

    if (widget.lockInterface) {
      final overlay = Overlay.of(context);
      _entry = OverlayEntry(builder: widget.overlayContent);
      overlay.insert(_entry);
    }

    try {
      _update(true);

      await widget.onPressed();
    } catch (e) {
      if (mounted) {
        widget.showError(e, context);
      }
    } finally {
      _entry?.remove();
      if (mounted) {
        _update(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(this);
  }
}
