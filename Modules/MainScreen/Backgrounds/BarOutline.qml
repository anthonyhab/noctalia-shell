import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Modules.MainScreen.Backgrounds
import qs.Services.UI

/**
 * BarOutline — ShapePath stroke companion to BarBackground.
 *
 * Simple bar: Mirrors BarBackground corner geometry. Screen-flush edges use
 * screenEdgeOvershoot so the stroke path is pushed off-screen and naturally
 * clipped by the compositor, leaving only the visible (non-flush) edges.
 *
 * Framed bar: Only strokes the inner content-area rectangle with frameRadius.
 */
ShapePath {
  id: root

  required property var bar
  required property var shapeContainer
  required property var windowRoot
  property bool disabled: false

  readonly property bool shouldShow: {
    if (disabled) return false;
    if (!BarService.effectivelyVisible) return false;
    var monitors = Settings.data.bar.monitors || [];
    var screenName = windowRoot?.screen?.name || "";
    return monitors.length === 0 || monitors.includes(screenName);
  }

  readonly property var barGeometryConfig: ShellGeometryPolicy.barConfig(windowRoot?.screen?.name)
  readonly property bool isFramed: barGeometryConfig.isFramed
  readonly property real frameThickness: barGeometryConfig.frameThickness
  readonly property real frameRadius: Settings.data.bar.frameRadius ?? 20

  readonly property point barMappedPos: bar ? Qt.point(bar.x, bar.y) : Qt.point(0, 0)
  readonly property real barWidth:  (bar && shouldShow) ? bar.width : 0
  readonly property real barHeight: (bar && shouldShow) ? bar.height : 0
  readonly property real screenWidth:  windowRoot?.screen?.width || 0
  readonly property real screenHeight: windowRoot?.screen?.height || 0

  readonly property bool shouldFlatten: bar ? ShapeCornerHelper.shouldFlatten(barWidth, barHeight, Style.radiusL) : false
  readonly property real effectiveRadius: shouldFlatten ? (bar ? ShapeCornerHelper.getFlattenedRadius(Math.min(barWidth, barHeight), Style.radiusL) : 0) : Style.radiusL

  function getCornerRadius(s) { return s === -1 ? 0 : effectiveRadius; }

  readonly property real mxTL: bar ? ShapeCornerHelper.getMultX(bar.topLeftCornerState) : 1
  readonly property real myTL: bar ? ShapeCornerHelper.getMultY(bar.topLeftCornerState) : 1
  readonly property real rTL:  bar ? getCornerRadius(bar.topLeftCornerState)  : 0

  readonly property real mxTR: bar ? ShapeCornerHelper.getMultX(bar.topRightCornerState) : 1
  readonly property real myTR: bar ? ShapeCornerHelper.getMultY(bar.topRightCornerState) : 1
  readonly property real rTR:  bar ? getCornerRadius(bar.topRightCornerState) : 0

  readonly property real mxBR: bar ? ShapeCornerHelper.getMultX(bar.bottomRightCornerState) : 1
  readonly property real myBR: bar ? ShapeCornerHelper.getMultY(bar.bottomRightCornerState) : 1
  readonly property real rBR:  bar ? getCornerRadius(bar.bottomRightCornerState) : 0

  readonly property real mxBL: bar ? ShapeCornerHelper.getMultX(bar.bottomLeftCornerState) : 1
  readonly property real myBL: bar ? ShapeCornerHelper.getMultY(bar.bottomLeftCornerState) : 1
  readonly property real rBL:  bar ? getCornerRadius(bar.bottomLeftCornerState) : 0

  // Screen-edge overshoot: push flush edges off-screen so stroke is fully clipped
  readonly property real screenEdgeOvershoot: 2
  readonly property real topOvs:    (!isFramed && shouldShow && rTL === 0 && rTR === 0 && barMappedPos.y <= 0) ? -screenEdgeOvershoot : 0
  readonly property real bottomOvs: (!isFramed && shouldShow && rBL === 0 && rBR === 0 && (barMappedPos.y + barHeight) >= screenHeight) ? screenEdgeOvershoot : 0
  readonly property real leftOvs:   (!isFramed && shouldShow && rTL === 0 && rBL === 0 && barMappedPos.x <= 0) ? -screenEdgeOvershoot : 0
  readonly property real rightOvs:  (!isFramed && shouldShow && rTR === 0 && rBR === 0 && (barMappedPos.x + barWidth) >= screenWidth) ? screenEdgeOvershoot : 0

  // Auto-hide opacity fade
  property real opacityFactor: (bar && bar.isHidden) ? 0 : 1
  Behavior on opacityFactor {
    enabled: bar && bar.autoHide
    NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutQuad }
  }

  // Framed inner hole
  readonly property real holeX: (barGeometryConfig.position === "left") ? barWidth : frameThickness
  readonly property real holeY: (barGeometryConfig.position === "top") ? barHeight : frameThickness
  readonly property real holeW: screenWidth - ((barGeometryConfig.position === "left" || barGeometryConfig.position === "right") ? (barWidth + frameThickness) : (frameThickness * 2))
  readonly property real holeH: screenHeight - ((barGeometryConfig.position === "top" || barGeometryConfig.position === "bottom") ? (barHeight + frameThickness) : (frameThickness * 2))

  fillColor: "transparent"
  strokeColor: disabled ? "transparent" : Qt.rgba(Style.barOutlineColor.r, Style.barOutlineColor.g, Style.barOutlineColor.b, Style.barOutlineColor.a * opacityFactor)
  strokeWidth: disabled ? 0 : Style.barOutlineWidth
  strokeStyle: ShapePath.SolidLine
  capStyle: ShapePath.FlatCap
  joinStyle: ShapePath.MiterJoin
  fillRule: ShapePath.WindingFill

  startX: {
    if (!shouldShow) return 0;
    if (isFramed) return holeX + frameRadius;
    return barMappedPos.x + rTL * mxTL + leftOvs;
  }
  startY: {
    if (!shouldShow) return 0;
    if (isFramed) return holeY;
    return barMappedPos.y + topOvs;
  }

  // Top edge → TR arc
  PathLine {
    x: root.isFramed ? root.holeX + root.holeW - root.frameRadius : (root.barMappedPos.x + root.barWidth + root.rightOvs - root.rTR * root.mxTR)
    y: root.isFramed ? root.holeY : (root.barMappedPos.y + root.topOvs)
  }
  PathArc {
    x: root.isFramed ? root.holeX + root.holeW : (root.barMappedPos.x + root.barWidth + root.rightOvs)
    y: root.isFramed ? root.holeY + root.frameRadius : (root.barMappedPos.y + root.topOvs + root.rTR * root.myTR)
    radiusX: root.isFramed ? root.frameRadius : root.rTR
    radiusY: root.isFramed ? root.frameRadius : root.rTR
    direction: root.isFramed ? PathArc.Clockwise : ShapeCornerHelper.getArcDirection(root.mxTR, root.myTR)
  }

  // Right edge → BR arc
  PathLine {
    x: root.isFramed ? root.holeX + root.holeW : (root.barMappedPos.x + root.barWidth + root.rightOvs)
    y: root.isFramed ? root.holeY + root.holeH - root.frameRadius : (root.barMappedPos.y + root.barHeight + root.bottomOvs - root.rBR * root.myBR)
  }
  PathArc {
    x: root.isFramed ? root.holeX + root.holeW - root.frameRadius : (root.barMappedPos.x + root.barWidth + root.rightOvs - root.rBR * root.mxBR)
    y: root.isFramed ? root.holeY + root.holeH : (root.barMappedPos.y + root.barHeight + root.bottomOvs)
    radiusX: root.isFramed ? root.frameRadius : root.rBR
    radiusY: root.isFramed ? root.frameRadius : root.rBR
    direction: root.isFramed ? PathArc.Clockwise : ShapeCornerHelper.getArcDirection(root.mxBR, root.myBR)
  }

  // Bottom edge → BL arc
  PathLine {
    x: root.isFramed ? root.holeX + root.frameRadius : (root.barMappedPos.x + root.leftOvs + root.rBL * root.mxBL)
    y: root.isFramed ? root.holeY + root.holeH : (root.barMappedPos.y + root.barHeight + root.bottomOvs)
  }
  PathArc {
    x: root.isFramed ? root.holeX : (root.barMappedPos.x + root.leftOvs)
    y: root.isFramed ? root.holeY + root.holeH - root.frameRadius : (root.barMappedPos.y + root.barHeight + root.bottomOvs - root.rBL * root.myBL)
    radiusX: root.isFramed ? root.frameRadius : root.rBL
    radiusY: root.isFramed ? root.frameRadius : root.rBL
    direction: root.isFramed ? PathArc.Clockwise : ShapeCornerHelper.getArcDirection(root.mxBL, root.myBL)
  }

  // Left edge → TL arc
  PathLine {
    x: root.isFramed ? root.holeX : (root.barMappedPos.x + root.leftOvs)
    y: root.isFramed ? root.holeY + root.frameRadius : (root.barMappedPos.y + root.topOvs + root.rTL * root.myTL)
  }
  PathArc {
    x: root.isFramed ? root.holeX + root.frameRadius : (root.barMappedPos.x + root.leftOvs + root.rTL * root.mxTL)
    y: root.isFramed ? root.holeY : (root.barMappedPos.y + root.topOvs)
    radiusX: root.isFramed ? root.frameRadius : root.rTL
    radiusY: root.isFramed ? root.frameRadius : root.rTL
    direction: root.isFramed ? PathArc.Clockwise : ShapeCornerHelper.getArcDirection(root.mxTL, root.myTL)
  }
}
