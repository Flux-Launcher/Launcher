import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_acrylic/widgets/visual_effect_subview_container/visual_effect_subview_container.dart';
import 'package:flutter_acrylic/widgets/visual_effect_subview_container/visual_effect_subview_container_resize_event_relay.dart';

class TransparentMacOSBottomBar extends StatelessWidget {
  final Widget child;
  final double alphaValue;
  final WindowEffect effect;
  final MacOSBlurViewState state;
  final VisualEffectSubviewContainerResizeEventRelay? resizeEventRelay;

  const TransparentMacOSBottomBar({
    Key? key,
    this.alphaValue = 1.0,
    this.effect = WindowEffect.sidebar,
    this.state = MacOSBlurViewState.followsWindowActiveState,
    this.resizeEventRelay,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VisualEffectSubviewContainer(
      alphaValue: alphaValue,
      effect: effect,
      resizeEventRelay: resizeEventRelay,
      state: state,

      padding: const EdgeInsets.only(right: -7680.0),
      child: child,
    );
  }
}
