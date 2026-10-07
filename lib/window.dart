import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/macos/converters/blur_view_state_to_visual_effect_view_state_converter.dart';
import 'package:flutter_acrylic/macos/converters/mac_toolbar_style_to_window_toolbar_style_converter.dart';
import 'package:flutter_acrylic/macos/converters/window_effect_to_material_converter.dart';
import 'package:flutter_acrylic/macos/macos_blur_view_state.dart';
import 'package:flutter_acrylic/macos/macos_toolbar_style.dart';
import 'package:flutter_acrylic/macos/visual_effect_view_properties.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:macos_window_utils/window_manipulator.dart';

const _kChannelName = "com.alexmercerind/flutter_acrylic";

const _kInitialize = "Initialize";

const _kSetEffect = "SetEffect";

const _kHideWindowControls = "HideWindowControls";

const _kShowWindowControls = "ShowWindowControls";

const _kEnterFullscreen = "EnterFullscreen";

const _kExitFullscreen = "ExitFullscreen";

const MethodChannel _kChannel = MethodChannel(_kChannelName);
final Completer<void> _kCompleter = Completer<void>();

class Window {

  static Future<void> initialize() async {
    if (Platform.isMacOS) {
      await WindowManipulator.initialize();
      setEffect(effect: WindowEffect.values[0]);

      return;
    }

    await _kChannel.invokeMethod(_kInitialize);
    _kCompleter.complete();
  }

  static Future<void> setEffect({
    required WindowEffect effect,
    Color color = Colors.transparent,
    bool dark = true,
  }) async {
    if (Platform.isMacOS) {
      final material = WindowEffectToMaterialConverter.convertWindowEffectToMaterial(effect);
      WindowManipulator.setMaterial(material);

      return;
    }

    await _kCompleter.future;
    await _kChannel.invokeMethod(
      _kSetEffect,
      {
        'effect': effect.index,
        'color': {
          'R': color.red,
          'G': color.green,
          'B': color.blue,
          'A': color.alpha,
        },
        'dark': dark,
      },
    );
  }

  static Future<void> hideWindowControls() async {
    if (Platform.isMacOS) {
      WindowManipulator.hideCloseButton();
      WindowManipulator.hideMiniaturizeButton();
      WindowManipulator.hideZoomButton();

      return;
    }

    await _kChannel.invokeMethod(_kHideWindowControls);
  }

  static Future<void> showWindowControls() async {
    if (Platform.isMacOS) {
      WindowManipulator.showCloseButton();
      WindowManipulator.showMiniaturizeButton();
      WindowManipulator.showZoomButton();

      return;
    }

    await _kChannel.invokeMethod(_kShowWindowControls);
  }

  static Future<void> enterFullscreen() async {
    if (Platform.isMacOS) {
      WindowManipulator.enterFullscreen();

      return;
    }

    await _kChannel.invokeMethod(_kEnterFullscreen);
  }

  static Future<void> exitFullscreen() async {
    if (Platform.isMacOS) {
      WindowManipulator.exitFullscreen();

      return;
    }

    await _kChannel.invokeMethod(_kExitFullscreen);
  }

  static Future<double> getTitlebarHeight() async {
    if (Platform.isMacOS) {
      return WindowManipulator.getTitlebarHeight();
    }

    throw UnsupportedError('getTitlebarHeight() is only available on macOS.');
  }

  static Future<void> setDocumentEdited() async {
    WindowManipulator.setDocumentEdited();
  }

  static Future<void> setDocumentUnedited() async {
    WindowManipulator.setDocumentUnedited();
  }

  static Future<void> setRepresentedFilename(String filename) async {
    WindowManipulator.setRepresentedFilename(filename);
  }

  static Future<void> setRepresentedUrl(String url) async {
    WindowManipulator.setRepresentedUrl(url);
  }

  static Future<void> hideTitle() async {
    WindowManipulator.hideTitle();
  }

  static Future<void> showTitle() async {
    WindowManipulator.showTitle();
  }

  static Future<void> makeTitlebarTransparent() async {
    WindowManipulator.makeTitlebarTransparent();
  }

  static Future<void> makeTitlebarOpaque() async {
    WindowManipulator.makeTitlebarOpaque();
  }

  static Future<void> enableFullSizeContentView() async {
    WindowManipulator.enableFullSizeContentView();
  }

  static Future<void> disableFullSizeContentView() async {
    WindowManipulator.disableFullSizeContentView();
  }

  static Future<void> zoomWindow() async {
    WindowManipulator.zoomWindow();
  }

  static Future<void> unzoomWindow() async {
    WindowManipulator.unzoomWindow();
  }

  static Future<bool> isWindowZoomed() async {
    if (Platform.isMacOS) {
      return WindowManipulator.isWindowZoomed();
    }

    if (!Platform.isMacOS) {
      throw UnsupportedError('isWindowZoomed() is only available on macOS.');
    }

    return false;
  }

  static Future<bool> isWindowFullscreened() async {
    if (Platform.isMacOS) {
      return WindowManipulator.isWindowFullscreened();
    }

    if (!Platform.isMacOS) {
      throw UnsupportedError(
        'isWindowFullscreened() is only available on macOS.',
      );
    }

    return false;
  }

  static Future<void> hideZoomButton() async {
    WindowManipulator.hideZoomButton();
  }

  static Future<void> showZoomButton() async {
    WindowManipulator.showZoomButton();
  }

  static Future<void> hideMiniaturizeButton() async {
    WindowManipulator.hideMiniaturizeButton();
  }

  static Future<void> showMiniaturizeButton() async {
    WindowManipulator.showMiniaturizeButton();
  }

  static Future<void> hideCloseButton() async {
    WindowManipulator.hideCloseButton();
  }

  static Future<void> showCloseButton() async {
    WindowManipulator.showCloseButton();
  }

  static Future<void> enableZoomButton() async {
    WindowManipulator.enableZoomButton();
  }

  static Future<void> disableZoomButton() async {
    WindowManipulator.disableZoomButton();
  }

  static Future<void> enableMiniaturizeButton() async {
    WindowManipulator.enableMiniaturizeButton();
  }

  static Future<void> disableMiniaturizeButton() async {
    WindowManipulator.disableMiniaturizeButton();
  }

  static Future<void> enableCloseButton() async {
    WindowManipulator.enableCloseButton();
  }

  static Future<void> disableCloseButton() async {
    WindowManipulator.disableCloseButton();
  }

  static Future<bool> isWindowInLiveResize() async {
    if (Platform.isMacOS) {
      return WindowManipulator.isWindowInLiveResize();
    }

    throw UnsupportedError(
      'isWindowInLiveResize() is only available on macOS.',
    );
  }

  static Future<void> setWindowAlphaValue(double value) async {
    WindowManipulator.setWindowAlphaValue(value);

    return;
  }

  static Future<bool> isWindowVisible() async {
    return WindowManipulator.isWindowVisible();
  }

  static Future<void> setWindowBackgroundColorToDefaultColor() async {
    WindowManipulator.setWindowBackgroundColorToDefaultColor();
  }

  static Future<void> setWindowBackgroundColorToClear() async {
    WindowManipulator.setWindowBackgroundColorToClear();
  }

  static Future<void> setBlurViewState(MacOSBlurViewState state) async {
    final visualEffectViewState = BlurViewStateToVisualEffectViewStateConverter.convertBlurViewStateToVisualEffectViewState(state);
    WindowManipulator.setNSVisualEffectViewState(visualEffectViewState);
  }

  static Future<int> addVisualEffectSubview(
    VisualEffectSubviewProperties properties,
  ) async {
    if (Platform.isMacOS) {
      final newProperties = properties.toMacOSWindowUtilsVisualEffectSubviewProperties();

      return WindowManipulator.addVisualEffectSubview(newProperties);
    }

    return -1;
  }

  static Future<void> updateVisualEffectSubviewProperties(
    int visualEffectSubviewId,
    VisualEffectSubviewProperties properties,
  ) async {
    final newProperties = properties.toMacOSWindowUtilsVisualEffectSubviewProperties();
    WindowManipulator.updateVisualEffectSubviewProperties(
      visualEffectSubviewId,
      newProperties,
    );
  }

  static Future<void> removeVisualEffectSubview(
    int visualEffectSubviewId,
  ) async {
    WindowManipulator.removeVisualEffectSubview(visualEffectSubviewId);
  }

  static Future<void> overrideMacOSBrightness({
    required bool dark,
  }) async {
    WindowManipulator.overrideMacOSBrightness(dark: dark);
  }

  static Future<void> addToolbar() async {
    WindowManipulator.addToolbar();
  }

  static Future<void> removeToolbar() async {
    WindowManipulator.removeToolbar();
  }

  static Future<void> setToolbarStyle({
    required MacOSToolbarStyle toolbarStyle,
  }) async {
    final newToolbarStyle = MacOSToolbarStyleToWindowToolbarStyleConverter.convertMacOSToolbarStyleToWindowToolbarStyle(toolbarStyle);
    WindowManipulator.setToolbarStyle(toolbarStyle: newToolbarStyle);
  }

  static Future<void> enableShadow() async {
    WindowManipulator.enableShadow();
  }

  static Future<void> disableShadow() async {
    WindowManipulator.disableShadow();
  }

  static Future<void> invalidateShadows() async {
    WindowManipulator.invalidateShadows();
  }

  static Future<void> addEmptyMaskImage() async {
    WindowManipulator.addEmptyMaskImage();
  }

  static Future<void> removeMaskImage() async {
    WindowManipulator.removeMaskImage();
  }

  static void makeWindowFullyTransparent() {
    setWindowBackgroundColorToClear();
    makeTitlebarTransparent();
    addEmptyMaskImage();
    disableShadow();
  }

  static Future<void> ignoreMouseEvents() async {
    WindowManipulator.ignoreMouseEvents();
  }

  static Future<void> acknowledgeMouseEvents() async {
    WindowManipulator.acknowledgeMouseEvents();
  }

  static Future<void> setSubtitle(String subtitle) async {
    WindowManipulator.setSubtitle(subtitle);
  }
}
