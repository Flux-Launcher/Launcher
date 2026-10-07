import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:macos_window_utils/macos/ns_visual_effect_view_material.dart';

class WindowEffectToMaterialConverter {
  WindowEffectToMaterialConverter._();

  static NSVisualEffectViewMaterial convertWindowEffectToMaterial(
    WindowEffect windowEffect,
  ) {
    switch (windowEffect.index) {
      case 0:
        return NSVisualEffectViewMaterial.windowBackground;

      case 1:
        return NSVisualEffectViewMaterial.windowBackground;

      case 2:
        return NSVisualEffectViewMaterial.underWindowBackground;

      case 3:
        return NSVisualEffectViewMaterial.hudWindow;

      case 4:
        return NSVisualEffectViewMaterial.fullScreenUI;

      case 5:
        return NSVisualEffectViewMaterial.headerView;

      case 6:
        return NSVisualEffectViewMaterial.headerView;

      case 7:
        return NSVisualEffectViewMaterial.titlebar;

      case 8:
        return NSVisualEffectViewMaterial.selection;

      case 9:
        return NSVisualEffectViewMaterial.menu;

      case 10:
        return NSVisualEffectViewMaterial.popover;

      case 11:
        return NSVisualEffectViewMaterial.sidebar;

      case 12:
        return NSVisualEffectViewMaterial.headerView;

      case 13:
        return NSVisualEffectViewMaterial.sheet;

      case 14:
        return NSVisualEffectViewMaterial.windowBackground;

      case 15:
        return NSVisualEffectViewMaterial.hudWindow;

      case 16:
        return NSVisualEffectViewMaterial.fullScreenUI;

      case 17:
        return NSVisualEffectViewMaterial.toolTip;

      case 18:
        return NSVisualEffectViewMaterial.contentBackground;

      case 19:
        return NSVisualEffectViewMaterial.underWindowBackground;

      case 20:
        return NSVisualEffectViewMaterial.underPageBackground;

      default:
        return NSVisualEffectViewMaterial.windowBackground;
    }
  }
}
