import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.MainScreen.Backgrounds
import qs.Services.UI

/**
* BarExclusionZone - Invisible PanelWindow that reserves exclusive space for the bar
*
* This is a minimal window that works with the compositor to reserve space,
* while the actual bar UI is rendered in MainScreen.
*/
PanelWindow {
  id: root

  // Edge to anchor to and thickness to reserve
  readonly property var barGeometryConfig: ShellGeometryPolicy.barConfig(screen?.name)
  property string edge: barGeometryConfig.position
  property real thickness: ShellGeometryPolicy.barExclusionThickness(screen?.name, edge)

  readonly property bool autoHide: Settings.getBarDisplayModeForScreen(screen?.name) === "auto_hide"
  readonly property bool nonExclusive: Settings.getBarDisplayModeForScreen(screen?.name) === "non_exclusive"
  // Reduce exclusion zone by 1 physical pixel so app windows blend flush against the bar edge
  readonly property real bleedInset: SurfaceRenderPolicy.epsilonForScreen(screen?.name)

  // Invisible - just reserves space
  color: "transparent"

  mask: Region {}

  // Wayland layer shell configuration
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "noctalia-bar-exclusion-" + edge + "-" + (screen?.name || "unknown")
  // When auto-hide, non-exclusive mode is enabled, OR bar is explicitly hidden via IPC, don't reserve space
  // Note: We check BarService.isVisible directly, NOT effectivelyVisible, because we want
  // the exclusion zone to stay during overview (effectivelyVisible is false during overview
  // when hideOnOverview is enabled, but isVisible remains true)
  WlrLayershell.exclusionMode: (autoHide || nonExclusive || !BarService.isVisible) ? ExclusionMode.Ignore : ExclusionMode.Auto

  // Anchor based on specified edge
  anchors {
    top: edge === "top"
    bottom: edge === "bottom"
    left: edge === "left" || edge === "top" || edge === "bottom"
    right: edge === "right" || edge === "top" || edge === "bottom"
  }

  // Size based on orientation
  implicitWidth: {
    if (edge === "left" || edge === "right") {
      return thickness - bleedInset;
    }
    return 0; // Auto-width when left/right anchors are true
  }

  implicitHeight: {
    if (edge === "top" || edge === "bottom") {
      return thickness - bleedInset;
    }
    return 0; // Auto-height when top/bottom anchors are true
  }

  Component.onCompleted: {
    Logger.d("BarExclusionZone", "Created for screen:", screen?.name);
  }
}
