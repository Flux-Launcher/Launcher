import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_acrylic/widgets/visual_effect_subview_container/visual_effect_subview_container_resize_event_relay.dart';

import 'visual_effect_subview_container_property_storage.dart';

class VisualEffectSubviewContainerWithGlobalKey extends StatefulWidget {
  final Widget child;
  final double alphaValue;
  final double? cornerRadius;
  final int cornerMask;
  final WindowEffect effect;
  final MacOSBlurViewState state;
  final EdgeInsets padding;
  final VisualEffectSubviewContainerResizeEventRelay? resizeEventRelay;

  static const topLeftCorner = VisualEffectSubviewProperties.topLeftCorner;
  static const topRightCorner = VisualEffectSubviewProperties.topRightCorner;
  static const bottomRightCorner =
      VisualEffectSubviewProperties.bottomRightCorner;
  static const bottomLeftCorner =
      VisualEffectSubviewProperties.bottomLeftCorner;

  const VisualEffectSubviewContainerWithGlobalKey({
    required GlobalKey key,
    required this.child,
    this.alphaValue = 1.0,
    this.cornerRadius,
    this.cornerMask = 0xf,
    required this.effect,
    required this.state,
    required this.padding,
    this.resizeEventRelay,
  }) : super(key: key);

  @override
  State<VisualEffectSubviewContainerWithGlobalKey> createState() =>
      _VisualEffectSubviewContainerWithGlobalKeyState();
}

class _VisualEffectSubviewContainerWithGlobalKeyState
    extends State<VisualEffectSubviewContainerWithGlobalKey> {
  int? _visualEffectSubviewId;
  final _propertyStorage = VisualEffectSubviewContainerPropertyStorage();

  VisualEffectSubviewProperties _getInitialVisualEffectSubviewProperties() {
    return VisualEffectSubviewProperties(
      alphaValue: widget.alphaValue,
      cornerRadius: widget.cornerRadius,
      cornerMask: widget.cornerMask,
      effect: widget.effect,
    );
  }

  void _addVisualEffectSubviewToApplicationWindow() async {
    final properties = _getInitialVisualEffectSubviewProperties();
    _visualEffectSubviewId = await Window.addVisualEffectSubview(properties);
    _propertyStorage.updateProperties(properties);

    Timer(const Duration(), () {
      _updateVisualEffectSubview();
    });
  }

  void _initializeResizeEventRelay() {
    if (widget.resizeEventRelay == null) {
      return;
    }

    widget.resizeEventRelay!.registerForceUpdateFunction(() {
      _updateVisualEffectSubview();
    });
  }

  @override
  void initState() {
    _addVisualEffectSubviewToApplicationWindow();
    _initializeResizeEventRelay();

    super.initState();
  }

  void _removeVisualEffectSubviewFromApplicationWindow() {
    if (_visualEffectSubviewId == null) {
      return;
    }

    Window.removeVisualEffectSubview(_visualEffectSubviewId!);
  }

  @override
  void dispose() {
    _removeVisualEffectSubviewFromApplicationWindow();

    super.dispose();
  }

  void _modifyVisualEffectSubview({
    required double xPosition,
    required double yPosition,
    required double width,
    required double height,
  }) {
    if (_visualEffectSubviewId == null) {
      return;
    }

    final newProperties = VisualEffectSubviewProperties(
      frameX: xPosition,
      frameY: yPosition,
      frameWidth: width,
      frameHeight: height,
      alphaValue: widget.alphaValue,
      cornerMask: widget.cornerMask,
      cornerRadius: widget.cornerRadius,
      effect: widget.effect,
      state: widget.state,
    );

    final delta = _propertyStorage.getDeltaProperties(newProperties);
    if (!delta.isEmpty) {
      Window.updateVisualEffectSubviewProperties(
        _visualEffectSubviewId!,
        delta,
      );
      _propertyStorage.updateProperties(newProperties);
    }
  }

  void _updateVisualEffectSubview() {
    final renderObject = (widget.key as GlobalKey)
        .currentContext!
        .findRenderObject() as RenderBox;
    final position = renderObject.localToGlobal(Offset.zero);

    final windowHeight = MediaQuery.of(context).size.height;

    final xPosition = position.dx + widget.padding.left;
    final yPosition = windowHeight -
        renderObject.size.height -
        position.dy +
        widget.padding.bottom;
    final width =
        renderObject.size.width - widget.padding.left - widget.padding.right;
    final height =
        renderObject.size.height - widget.padding.bottom - widget.padding.top;

    _modifyVisualEffectSubview(
      xPosition: xPosition,
      yPosition: yPosition,
      width: width,
      height: height,
    );
  }

  void _updateVisualEffectSubviewFromBuildMethodIfPermitted() {
    if (widget.resizeEventRelay != null) {
      if (widget.resizeEventRelay!.disableUpdateOnBuild) {
        return;
      }
    }

    Timer(const Duration(), () {
      _updateVisualEffectSubview();
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateVisualEffectSubviewFromBuildMethodIfPermitted();

    return widget.child;
  }
}
