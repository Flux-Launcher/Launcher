import 'package:flutter/widgets.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

import 'visual_effect_subview_container_resize_event_relay.dart';
import 'visual_effect_subview_container_with_global_key.dart';

class VisualEffectSubviewContainer extends StatefulWidget {
  final Widget child;
  final double alphaValue;
  final double? cornerRadius;
  final int cornerMask;
  final WindowEffect effect;
  final MacOSBlurViewState state;
  final EdgeInsets padding;
  final VisualEffectSubviewContainerResizeEventRelay? resizeEventRelay;

  static const topLeftCorner =
      VisualEffectSubviewContainerWithGlobalKey.topLeftCorner;
  static const topRightCorner =
      VisualEffectSubviewContainerWithGlobalKey.topRightCorner;
  static const bottomRightCorner =
      VisualEffectSubviewContainerWithGlobalKey.bottomRightCorner;
  static const bottomLeftCorner =
      VisualEffectSubviewContainerWithGlobalKey.bottomLeftCorner;

  const VisualEffectSubviewContainer({
    Key? key,
    required this.child,
    this.alphaValue = 1.0,
    this.cornerRadius,
    this.cornerMask = 0xf,
    required this.effect,
    this.state = MacOSBlurViewState.followsWindowActiveState,
    this.padding = EdgeInsets.zero,
    this.resizeEventRelay,
  }) : super(key: key);

  @override
  State<VisualEffectSubviewContainer> createState() =>
      _VisualEffectSubviewContainerState();
}

class _VisualEffectSubviewContainerState
    extends State<VisualEffectSubviewContainer> {
  final _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return VisualEffectSubviewContainerWithGlobalKey(
      key: _globalKey,
      alphaValue: widget.alphaValue,
      cornerRadius: widget.cornerRadius,
      cornerMask: widget.cornerMask,
      effect: widget.effect,
      state: widget.state,
      padding: widget.padding,
      resizeEventRelay: widget.resizeEventRelay,
      child: widget.child,
    );
  }
}
