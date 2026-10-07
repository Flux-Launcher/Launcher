class VisualEffectSubviewContainerResizeEventRelay {

  final bool disableUpdateOnBuild;

  VisualEffectSubviewContainerResizeEventRelay({
    required this.disableUpdateOnBuild,
  });

  void Function()? _forceUpdate;

  void registerForceUpdateFunction(void Function() forceUpdate) {
    _forceUpdate = forceUpdate;
  }

  void onResize() {
    if (_forceUpdate == null) {
      return;
    }

    _forceUpdate!();
  }
}
