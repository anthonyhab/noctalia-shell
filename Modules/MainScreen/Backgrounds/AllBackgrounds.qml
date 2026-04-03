import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Modules.MainScreen.Backgrounds
import qs.Services.UI
import qs.Widgets

/**
* AllBackgrounds - Unified Shape container for all bar and panel backgrounds
*
* Uses a dual-path rendering policy:
* - Rectangle fast path for regular rounded/square corners (crisper translucent edges)
* - ShapePath fallback for complex geometries (inverted corners, framed cutouts)
*/
Item {
  id: root

  required property var bar
  required property var windowRoot

  readonly property color panelBackgroundColor: Color.mSurface
  readonly property string screenName: root.windowRoot?.screen?.name || ""

  function getAssignedPanel(slotIndex) {
    var assignments = PanelService.backgroundSlotAssignments || [];
    var panel = assignments[slotIndex];
    return (panel && panel.screen === root.windowRoot.screen) ? panel : null;
  }

  function getPanelItem(panel) {
    if (!panel) {
      return null;
    }
    var panelRegion = panel.panelRegion;
    return (panelRegion && panelRegion.visible) ? panelRegion.panelItem : null;
  }

  function getPanelColor(panel) {
    if (!panel) {
      return "transparent";
    }
    return panel.panelBackgroundColor !== undefined ? panel.panelBackgroundColor : panelBackgroundColor;
  }

  function getRectForItem(item) {
    if (!item) {
      return {
        "x": 0,
        "y": 0,
        "width": 0,
        "height": 0
      };
    }
    return SurfaceRenderPolicy.snapRect(item.x, item.y, item.width, item.height, screenName);
  }

  function useRectPathForItem(item, isFramed) {
    if (!item) {
      return false;
    }
    return SurfaceRenderPolicy.canUseRectPath(
          item.topLeftCornerState,
          item.topRightCornerState,
          item.bottomLeftCornerState,
          item.bottomRightCornerState,
          isFramed);
  }

  function shouldAntialiasRect(tl, tr, bl, br) {
    return (Number(tl) || 0) > 0
        || (Number(tr) || 0) > 0
        || (Number(bl) || 0) > 0
        || (Number(br) || 0) > 0;
  }

  readonly property var slot0Panel: getAssignedPanel(0)
  readonly property var slot1Panel: getAssignedPanel(1)

  readonly property var slot0PanelItem: getPanelItem(slot0Panel)
  readonly property var slot1PanelItem: getPanelItem(slot1Panel)
  readonly property bool hasPanelBackgroundOnScreen: !!slot0PanelItem || !!slot1PanelItem

  readonly property color slot0PanelColor: getPanelColor(slot0Panel)
  readonly property color slot1PanelColor: getPanelColor(slot1Panel)

  readonly property bool slot0UseRectPath: useRectPathForItem(slot0PanelItem, false)
  readonly property bool slot1UseRectPath: useRectPathForItem(slot1PanelItem, false)
  readonly property bool slot0UseShapePath: !!slot0PanelItem && !slot0UseRectPath
  readonly property bool slot1UseShapePath: !!slot1PanelItem && !slot1UseRectPath

  readonly property var slot0Rect: getRectForItem(slot0PanelItem)
  readonly property var slot1Rect: getRectForItem(slot1PanelItem)

  readonly property real slot0BaseRadius: SurfaceRenderPolicy.effectiveRadiusForSize(Style.radiusL, slot0Rect.width, slot0Rect.height)
  readonly property real slot1BaseRadius: SurfaceRenderPolicy.effectiveRadiusForSize(Style.radiusL, slot1Rect.width, slot1Rect.height)

  readonly property real slot0TLRadius: slot0PanelItem ? SurfaceRenderPolicy.cornerRadiusForState(slot0PanelItem.topLeftCornerState, slot0BaseRadius) : 0
  readonly property real slot0TRRadius: slot0PanelItem ? SurfaceRenderPolicy.cornerRadiusForState(slot0PanelItem.topRightCornerState, slot0BaseRadius) : 0
  readonly property real slot0BLRadius: slot0PanelItem ? SurfaceRenderPolicy.cornerRadiusForState(slot0PanelItem.bottomLeftCornerState, slot0BaseRadius) : 0
  readonly property real slot0BRRadius: slot0PanelItem ? SurfaceRenderPolicy.cornerRadiusForState(slot0PanelItem.bottomRightCornerState, slot0BaseRadius) : 0
  readonly property bool slot0RectAA: shouldAntialiasRect(slot0TLRadius, slot0TRRadius, slot0BLRadius, slot0BRRadius)

  readonly property real slot1TLRadius: slot1PanelItem ? SurfaceRenderPolicy.cornerRadiusForState(slot1PanelItem.topLeftCornerState, slot1BaseRadius) : 0
  readonly property real slot1TRRadius: slot1PanelItem ? SurfaceRenderPolicy.cornerRadiusForState(slot1PanelItem.topRightCornerState, slot1BaseRadius) : 0
  readonly property real slot1BLRadius: slot1PanelItem ? SurfaceRenderPolicy.cornerRadiusForState(slot1PanelItem.bottomLeftCornerState, slot1BaseRadius) : 0
  readonly property real slot1BRRadius: slot1PanelItem ? SurfaceRenderPolicy.cornerRadiusForState(slot1PanelItem.bottomRightCornerState, slot1BaseRadius) : 0
  readonly property bool slot1RectAA: shouldAntialiasRect(slot1TLRadius, slot1TRRadius, slot1BLRadius, slot1BRRadius)

  readonly property bool useRectBar: {
    if (!root.bar) {
      return false;
    }
    return SurfaceRenderPolicy.canUseRectPath(
          root.bar.topLeftCornerState,
          root.bar.topRightCornerState,
          root.bar.bottomLeftCornerState,
          root.bar.bottomRightCornerState,
          Settings.data.bar.barType === "framed");
  }

  readonly property var barRect: root.bar
    ? SurfaceRenderPolicy.snapRect(root.bar.x, root.bar.y, root.bar.width, root.bar.height, screenName)
    : ({
        "x": 0,
        "y": 0,
        "width": 0,
        "height": 0
      })

  readonly property real barBaseRadius: SurfaceRenderPolicy.effectiveRadiusForSize(Style.radiusL, barRect.width, barRect.height)
  readonly property real barTLRadius: root.bar ? SurfaceRenderPolicy.cornerRadiusForState(root.bar.topLeftCornerState, barBaseRadius) : 0
  readonly property real barTRRadius: root.bar ? SurfaceRenderPolicy.cornerRadiusForState(root.bar.topRightCornerState, barBaseRadius) : 0
  readonly property real barBLRadius: root.bar ? SurfaceRenderPolicy.cornerRadiusForState(root.bar.bottomLeftCornerState, barBaseRadius) : 0
  readonly property real barBRRadius: root.bar ? SurfaceRenderPolicy.cornerRadiusForState(root.bar.bottomRightCornerState, barBaseRadius) : 0
  readonly property bool barRectAA: shouldAntialiasRect(barTLRadius, barTRRadius, barBLRadius, barBRRadius)

  // Outline visibility helpers
  readonly property bool barOutlineVisible: Style.barOutlineEnabled && Style.barOutlineWidth > 0
  readonly property bool panelOutlineVisible: Style.outerOutlineEnabled && Style.outerOutlineWidth > 0

  anchors.fill: parent

  Item {
    anchors.fill: parent

    // Unified opacity mode (bar + panel backgrounds share one opacity factor)
    Item {
      anchors.fill: parent
      visible: !Settings.data.bar.useSeparateOpacity

      layer.enabled: Settings.data.general.enableShadows && root.hasPanelBackgroundOnScreen
      layer.smooth: false
      opacity: Settings.data.ui.panelBackgroundOpacity

      Item {
        id: unifiedBackgroundsSource
        anchors.fill: parent

        Rectangle {
          visible: root.useRectBar && root.bar
          x: root.barRect.x
          y: root.barRect.y
          width: root.barRect.width
          height: root.barRect.height
          color: panelBackgroundColor
          antialiasing: root.barRectAA
          topLeftRadius: root.barTLRadius
          topRightRadius: root.barTRRadius
          bottomLeftRadius: root.barBLRadius
          bottomRightRadius: root.barBRRadius
        }

        Rectangle {
          visible: root.slot0UseRectPath
          x: root.slot0Rect.x
          y: root.slot0Rect.y
          width: root.slot0Rect.width
          height: root.slot0Rect.height
          color: root.slot0PanelColor
          antialiasing: root.slot0RectAA
          topLeftRadius: root.slot0TLRadius
          topRightRadius: root.slot0TRRadius
          bottomLeftRadius: root.slot0BLRadius
          bottomRightRadius: root.slot0BRRadius
        }

        Rectangle {
          visible: root.slot1UseRectPath
          x: root.slot1Rect.x
          y: root.slot1Rect.y
          width: root.slot1Rect.width
          height: root.slot1Rect.height
          color: root.slot1PanelColor
          antialiasing: root.slot1RectAA
          topLeftRadius: root.slot1TLRadius
          topRightRadius: root.slot1TRRadius
          bottomLeftRadius: root.slot1BLRadius
          bottomRightRadius: root.slot1BRRadius
        }

        Shape {
          id: unifiedBackgroundsShape
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer
          asynchronous: true
          enabled: false

          BarBackground {
            bar: root.bar
            shapeContainer: unifiedBackgroundsShape
            windowRoot: root.windowRoot
            backgroundColor: panelBackgroundColor
            disabled: root.useRectBar
          }

          PanelBackground {
            assignedPanel: root.slot0UseShapePath ? root.slot0Panel : null
            shapeContainer: unifiedBackgroundsShape
            defaultBackgroundColor: panelBackgroundColor
            disabled: !root.slot0UseShapePath
          }

          PanelBackground {
            assignedPanel: root.slot1UseShapePath ? root.slot1Panel : null
            shapeContainer: unifiedBackgroundsShape
            defaultBackgroundColor: panelBackgroundColor
            disabled: !root.slot1UseShapePath
          }
        }
      }

      NDropShadow {
        anchors.fill: parent
        source: unifiedBackgroundsSource
        shadowEnabled: root.hasPanelBackgroundOnScreen
      }
    }

    // Separate opacity mode (panels and bar have independent opacity controls)
    Item {
      anchors.fill: parent
      visible: Settings.data.bar.useSeparateOpacity

      Item {
        anchors.fill: parent
        layer.enabled: Settings.data.general.enableShadows && root.hasPanelBackgroundOnScreen
        layer.smooth: false
        opacity: Settings.data.ui.panelBackgroundOpacity

        Item {
          id: panelBackgroundsSource
          anchors.fill: parent

          Rectangle {
            visible: root.slot0UseRectPath
            x: root.slot0Rect.x
            y: root.slot0Rect.y
            width: root.slot0Rect.width
            height: root.slot0Rect.height
            color: root.slot0PanelColor
            antialiasing: root.slot0RectAA
            topLeftRadius: root.slot0TLRadius
            topRightRadius: root.slot0TRRadius
            bottomLeftRadius: root.slot0BLRadius
            bottomRightRadius: root.slot0BRRadius
          }

          Rectangle {
            visible: root.slot1UseRectPath
            x: root.slot1Rect.x
            y: root.slot1Rect.y
            width: root.slot1Rect.width
            height: root.slot1Rect.height
            color: root.slot1PanelColor
            antialiasing: root.slot1RectAA
            topLeftRadius: root.slot1TLRadius
            topRightRadius: root.slot1TRRadius
            bottomLeftRadius: root.slot1BLRadius
            bottomRightRadius: root.slot1BRRadius
          }

          Shape {
            id: panelBackgroundsShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            enabled: false

            PanelBackground {
              assignedPanel: root.slot0UseShapePath ? root.slot0Panel : null
              shapeContainer: panelBackgroundsShape
              defaultBackgroundColor: panelBackgroundColor
              disabled: !root.slot0UseShapePath
            }

            PanelBackground {
              assignedPanel: root.slot1UseShapePath ? root.slot1Panel : null
              shapeContainer: panelBackgroundsShape
              defaultBackgroundColor: panelBackgroundColor
              disabled: !root.slot1UseShapePath
            }
          }
        }

        NDropShadow {
          anchors.fill: parent
          source: panelBackgroundsSource
          shadowEnabled: root.hasPanelBackgroundOnScreen
        }
      }

      Item {
        anchors.fill: parent
        layer.enabled: false
        layer.smooth: false
        opacity: Settings.data.bar.backgroundOpacity

        Rectangle {
          visible: root.useRectBar && root.bar
          x: root.barRect.x
          y: root.barRect.y
          width: root.barRect.width
          height: root.barRect.height
          color: panelBackgroundColor
          antialiasing: root.barRectAA
          topLeftRadius: root.barTLRadius
          topRightRadius: root.barTRRadius
          bottomLeftRadius: root.barBLRadius
          bottomRightRadius: root.barBRRadius
        }

        Shape {
          id: barBackgroundShape
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer
          enabled: false
          visible: !root.useRectBar

          BarBackground {
            bar: root.bar
            shapeContainer: barBackgroundShape
            windowRoot: root.windowRoot
            backgroundColor: panelBackgroundColor
            disabled: root.useRectBar
          }
        }
      }
    }
  }

  // ── Shared outline layer ─────────────────────────────────────────────────
  // Placed at root level OUTSIDE both opacity mode Items.
  // outline opacity is already encoded into barOutlineColor/outerOutlineColor via Qt.alpha,
  // so this Shape must never inherit any parent opacity.
  Shape {
    id: sharedOutlineShape
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    enabled: false
    visible: root.barOutlineVisible || root.panelOutlineVisible

    BarOutline {
      bar: root.bar
      shapeContainer: sharedOutlineShape
      windowRoot: root.windowRoot
      disabled: !root.barOutlineVisible
    }

    PanelOutline {
      assignedPanel: root.panelOutlineVisible ? root.slot0Panel : null
      shapeContainer: sharedOutlineShape
      disabled: !root.panelOutlineVisible || !root.slot0PanelItem
    }

    PanelOutline {
      assignedPanel: root.panelOutlineVisible ? root.slot1Panel : null
      shapeContainer: sharedOutlineShape
      disabled: !root.panelOutlineVisible || !root.slot1PanelItem
    }
  }
}
