class PlatformViewRegistry {
  void registerViewFactory(String viewTypeId, dynamic Function(int viewId) viewFactory) {}
}
final platformViewRegistry = PlatformViewRegistry();
