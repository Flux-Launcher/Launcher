import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:flutter_acrylic/flutter_acrylic.dart';

class _MacOSTitlebarSafeArea extends StatefulWidget {
  final Widget child;

  const _MacOSTitlebarSafeArea({Key? key, required this.child})
      : super(key: key);

  @override
  State<_MacOSTitlebarSafeArea> createState() => _MacOSTitlebarSafeAreaState();
}

class _MacOSTitlebarSafeAreaState extends State<_MacOSTitlebarSafeArea> {
  double _titlebarHeight = 0.0;

  Future<void> _updateTitlebarHeight() async {
    final newTitlebarHeight = await Window.getTitlebarHeight();
    if (_titlebarHeight != newTitlebarHeight) {
      setState(() {
        _titlebarHeight = newTitlebarHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateTitlebarHeight();

    return Padding(
      padding: EdgeInsets.only(top: _titlebarHeight),
      child: widget.child,
    );
  }
}

class TitlebarSafeArea extends StatelessWidget {
  final Widget child;

  const TitlebarSafeArea({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) return child;

    return _MacOSTitlebarSafeArea(child: child);
  }
}
