import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.MainScreen.Backgrounds

/**
* BarExclusionZone - Invisible PanelWindow that reserves exclusive space for the bar
*
* This is a minimal window that works with the compositor to reserve space,
* while the actual bar UI is rendered in NFullScreenWindow.
*
* DEPRECATED:
* Main screen integration should use Modules/MainScreen/BarExclusionZone.qml.
*/
PanelWindow {
  id: root

  readonly property var barGeometryConfig: ShellGeometryPolicy.barConfig(screen?.name)
  readonly property string barPosition: barGeometryConfig.position
  readonly property bool barIsVertical: barGeometryConfig.isVertical
  readonly property bool barFloating: barGeometryConfig.floating
  readonly property real barMarginH: barGeometryConfig.marginHorizontal
  readonly property real barMarginV: barGeometryConfig.marginVertical
  readonly property real barHeight: barGeometryConfig.barHeight

  // Invisible - just reserves space
  color: "transparent"

  mask: Region {}

  // Wayland layer shell configuration
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "noctalia-bar-exclusion-" + (screen?.name || "unknown")
  WlrLayershell.exclusionMode: ExclusionMode.Auto

  // Anchor based on bar position
  anchors {
    top: barPosition === "top"
    bottom: barPosition === "bottom"
    left: barPosition === "left" || barPosition === "top" || barPosition === "bottom"
    right: barPosition === "right" || barPosition === "top" || barPosition === "bottom"
  }

  // Size based on bar orientation
  // When floating, only reserve space for the bar + margin on the anchored edge
  implicitWidth: {
    if (barIsVertical) {
      // Vertical bar: reserve bar height + margin on the anchored edge only
      if (barFloating) {
        // For left bar, reserve left margin; for right bar, reserve right margin
        return barHeight + barMarginH;
      }
      return barHeight;
    }
    return 0; // Auto-width when left/right anchors are true
  }

  implicitHeight: {
    if (!barIsVertical) {
      // Horizontal bar: reserve bar height + margin on the anchored edge only
      if (barFloating) {
        // For top bar, reserve top margin; for bottom bar, reserve bottom margin
        return barHeight + barMarginV;
      }
      return barHeight;
    }
    return 0; // Auto-height when top/bottom anchors are true
  }

  Component.onCompleted: {
    Logger.w("BarExclusionZone", "Deprecated component instantiated. Use Modules/MainScreen/BarExclusionZone.qml instead.");
    Logger.d("BarExclusionZone", "Created for screen:", screen?.name);
    Logger.d("BarExclusionZone", "  Position:", barPosition, "Floating:", barFloating);
    Logger.d("BarExclusionZone", "  Anchors - top:", anchors.top, "bottom:", anchors.bottom, "left:", anchors.left, "right:", anchors.right);
    Logger.d("BarExclusionZone", "  Size:", width, "x", height, "implicitWidth:", implicitWidth, "implicitHeight:", implicitHeight);
  }
}
