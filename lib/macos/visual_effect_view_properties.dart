import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_acrylic/macos/converters/blur_view_state_to_visual_effect_view_state_converter.dart';
import 'package:flutter_acrylic/macos/converters/window_effect_to_material_converter.dart';

import 'package:macos_window_utils/macos_window_utils.dart'
    as macos_window_utils;

class VisualEffectSubviewProperties {

  final double? frameWidth;

  final double? frameHeight;

  final double? frameX;

  final double? frameY;

  final double? alphaValue;

  final double? cornerRadius;

  final int? cornerMask;

  final WindowEffect? effect;

  final MacOSBlurViewState? state;

  VisualEffectSubviewProperties({
    this.frameWidth,
    this.frameHeight,
    this.frameX,
    this.frameY,
    this.alphaValue,
    this.cornerRadius,
    this.cornerMask,
    this.effect,
    this.state,
  });

  static const topLeftCorner = 1 << 0;
  static const topRightCorner = 1 << 1;
  static const bottomRightCorner = 1 << 2;
  static const bottomLeftCorner = 1 << 3;

  bool get isEmpty =>
      frameHeight == null &&
      frameHeight == null &&
      frameX == null &&
      frameY == null &&
      alphaValue == null &&
      cornerRadius == null &&
      cornerMask == null &&
      effect == null &&
      state == null;

  macos_window_utils.VisualEffectSubviewProperties
      toMacOSWindowUtilsVisualEffectSubviewProperties() {
    final material = effect == null
        ? null
        : WindowEffectToMaterialConverter.convertWindowEffectToMaterial(
            effect!,
          );
    final visualEffectViewState = state == null
        ? null
        : BlurViewStateToVisualEffectViewStateConverter
            .convertBlurViewStateToVisualEffectViewState(state!);

    return macos_window_utils.VisualEffectSubviewProperties(
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      frameX: frameX,
      frameY: frameY,
      alphaValue: alphaValue,
      cornerRadius: cornerRadius,
      cornerMask: cornerMask,
      material: material,
      state: visualEffectViewState,
    );
  }

  @override
  operator ==(Object other) {
    return other is VisualEffectSubviewProperties &&
        frameWidth == other.frameWidth &&
        frameHeight == other.frameHeight &&
        frameX == other.frameX &&
        frameY == other.frameY &&
        alphaValue == other.alphaValue &&
        cornerRadius == other.cornerRadius &&
        cornerMask == other.cornerMask &&
        effect == other.effect &&
        state == other.state;
  }

  @override
  int get hashCode {
    return frameWidth.hashCode ^
        frameHeight.hashCode ^
        frameX.hashCode ^
        frameY.hashCode ^
        alphaValue.hashCode ^
        cornerRadius.hashCode ^
        cornerMask.hashCode ^
        effect.hashCode ^
        state.hashCode;
  }

  @override
  String toString() {
    return '$frameWidth $frameHeight $frameX $frameY $alphaValue $cornerRadius'
        '$cornerMask $effect $state';
  }
}
