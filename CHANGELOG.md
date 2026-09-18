## 0.0.2

* Fixes `setState() or markNeedsBuild() called during build` when a destination
  is selected, or the destinations change, while `NavigationRail` is open as a
  modal overlay. The overlay is now built with an `OverlayPortal`, so it also
  inherits what the rail inherits (such as a local `Theme`), and dialogs or
  routes opened while it is showing now appear above it instead of beneath it.
* Fixes `NavigationBar` throwing an `ArgumentError` and rendering no
  destinations when a destination is narrower than 80dp, for example five
  destinations on a screen under 400dp wide. Destinations now squash to fit.

## 0.0.1

* Initial release.
