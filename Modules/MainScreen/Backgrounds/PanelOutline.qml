import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Modules.MainScreen.Backgrounds

/**
 * PanelOutline — stroke outline companion to PanelBackground.
 *
 * Mirrors PanelBackground's closed-path geometry exactly, using the same
 * raw corner states and arc multipliers. The only difference: edges that
 * are hidden (on the bar surface or screen edge) are replaced with PathMove
 * to skip drawing visible strokes over those areas.
 *
 * Junction points (8 positions around the path):
 *   A(after TL) → top edge → B(before TR) → TR arc → C(after TR) →
 *   right edge → D(before BR) → BR arc → E(after BR) → bottom edge →
 *   F(before BL) → BL arc → G(after BL) → left edge → H(before TL) →
 *   TL arc → back to A
 *
 * Edge suppression (direction-aware):
 *   - Horizontal edges (top/bottom): suppress if either corner is state 1
 *     (bar/screen on that horizontal side) or both flat (-1).
 *   - Vertical edges (left/right): suppress if either corner is state 2
 *     (bar/screen on that vertical side) or both flat (-1).
 *
 * Arc suppression:
 *   - Inverted arcs (state 1 or 2): always draw (concave junction ears).
 *   - Flat arcs (state -1): always suppress (zero radius).
 *   - Normal arcs (state 0): suppress only when both adjacent edges suppressed.
 */
ShapePath {
  id: root

  property var assignedPanel: null
  property bool disabled: false
  required property var shapeContainer

  readonly property var panelRegion: assignedPanel?.panelRegion ?? null
  readonly property var panelBg: (!disabled && panelRegion && panelRegion.visible) ? panelRegion.panelItem : null

  readonly property real px: panelBg ? panelBg.x : 0
  readonly property real py: panelBg ? panelBg.y : 0
  readonly property real pw: panelBg ? panelBg.width : 0
  readonly property real ph: panelBg ? panelBg.height : 0

  readonly property bool shouldFlatten: panelBg ? ShapeCornerHelper.shouldFlatten(pw, ph, Style.radiusL) : false
  readonly property real baseR: shouldFlatten ? ShapeCornerHelper.getFlattenedRadius(Math.min(pw, ph), Style.radiusL) : Style.radiusL

  // Raw corner states — used directly, no conversion
  readonly property int sTL: panelBg ? panelBg.topLeftCornerState : 0
  readonly property int sTR: panelBg ? panelBg.topRightCornerState : 0
  readonly property int sBR: panelBg ? panelBg.bottomRightCornerState : 0
  readonly property int sBL: panelBg ? panelBg.bottomLeftCornerState : 0

  // Per-corner helpers (identical to PanelBackground)
  function cr(s)  { return s === -1 ? 0 : baseR; }
  function mX(s)  { return s === 1 ? -1 : 1; }
  function mY(s)  { return s === 2 ? -1 : 1; }
  function inv(s) { return s === 1 || s === 2; }
  function arcDir(s) {
    var x = mX(s), y = mY(s);
    return ((x < 0) !== (y < 0)) ? PathArc.Counterclockwise : PathArc.Clockwise;
  }

  // ── Edge suppression ────────────────────────────────────────────────────
  function suppressHorizEdge(s1, s2) {
    return (s1 === 1 || s2 === 1) || (s1 === -1 && s2 === -1);
  }
  function suppressVertEdge(s1, s2) {
    return (s1 === 2 || s2 === 2) || (s1 === -1 && s2 === -1);
  }

  readonly property bool skipTopEdge:    disabled || suppressHorizEdge(sTL, sTR)
  readonly property bool skipRightEdge:  disabled || suppressVertEdge(sTR, sBR)
  readonly property bool skipBottomEdge: disabled || suppressHorizEdge(sBR, sBL)
  readonly property bool skipLeftEdge:   disabled || suppressVertEdge(sBL, sTL)

  // ── Arc suppression ─────────────────────────────────────────────────────
  function skipArcFn(s, adj1Skip, adj2Skip) {
    if (inv(s)) return false;
    if (s === -1) return true;
    return adj1Skip && adj2Skip;
  }

  readonly property bool skipTRarc: disabled || skipArcFn(sTR, skipTopEdge,    skipRightEdge)
  readonly property bool skipBRarc: disabled || skipArcFn(sBR, skipRightEdge,  skipBottomEdge)
  readonly property bool skipBLarc: disabled || skipArcFn(sBL, skipBottomEdge, skipLeftEdge)
  readonly property bool skipTLarc: disabled || skipArcFn(sTL, skipLeftEdge,   skipTopEdge)

  // ── Per-corner radius and multipliers ───────────────────────────────────
  readonly property real rTL: cr(sTL);  readonly property real xTL: mX(sTL);  readonly property real yTL: mY(sTL)
  readonly property real rTR: cr(sTR);  readonly property real xTR: mX(sTR);  readonly property real yTR: mY(sTR)
  readonly property real rBR: cr(sBR);  readonly property real xBR: mX(sBR);  readonly property real yBR: mY(sBR)
  readonly property real rBL: cr(sBL);  readonly property real xBL: mX(sBL);  readonly property real yBL: mY(sBL)

  // ── 8 junction points around the path ───────────────────────────────────
  // Exactly matching PanelBackground's absolute coordinates.
  readonly property real ax: px + rTL * xTL;           readonly property real ay: py                       // after TL / top edge start
  readonly property real bx: px + pw - rTR * xTR;      readonly property real by: py                       // top edge end / before TR
  readonly property real cx: px + pw;                   readonly property real cy: py + rTR * yTR           // after TR / right edge start
  readonly property real dx: px + pw;                   readonly property real dy: py + ph - rBR * yBR      // right edge end / before BR
  readonly property real ex: px + pw - rBR * xBR;       readonly property real ey: py + ph                  // after BR / bottom edge start
  readonly property real fx: px + rBL * xBL;            readonly property real fy: py + ph                  // bottom edge end / before BL
  readonly property real gx: px;                        readonly property real gy: py + ph - rBL * yBL      // after BL / left edge start
  readonly property real hx: px;                        readonly property real hy: py + rTL * yTL           // left edge end / before TL

  // Stroke config
  fillColor: "transparent"
  strokeColor: disabled ? "transparent" : Style.outerOutlineColor
  strokeWidth: disabled ? 0 : Style.outerOutlineWidth
  strokeStyle: ShapePath.SolidLine
  capStyle: ShapePath.FlatCap
  joinStyle: ShapePath.MiterJoin
  fillRule: ShapePath.WindingFill

  startX: disabled ? 0 : ax
  startY: disabled ? 0 : ay

  // ── TOP edge (A→B) + TR arc (B→C) ────────────────────────────────────
  PathMove {
    x: root.skipTopEdge ? root.bx : root.ax
    y: root.skipTopEdge ? root.by : root.ay
  }
  PathLine { x: root.bx; y: root.by }
  PathArc {
    x: root.skipTRarc ? root.bx : root.cx
    y: root.skipTRarc ? root.by : root.cy
    radiusX: root.skipTRarc ? 0 : root.rTR
    radiusY: root.skipTRarc ? 0 : root.rTR
    direction: root.arcDir(root.sTR)
  }

  // ── RIGHT edge (C→D) + BR arc (D→E) ──────────────────────────────────
  PathMove {
    x: root.skipRightEdge ? root.dx : root.cx
    y: root.skipRightEdge ? root.dy : root.cy
  }
  PathLine { x: root.dx; y: root.dy }
  PathArc {
    x: root.skipBRarc ? root.dx : root.ex
    y: root.skipBRarc ? root.dy : root.ey
    radiusX: root.skipBRarc ? 0 : root.rBR
    radiusY: root.skipBRarc ? 0 : root.rBR
    direction: root.arcDir(root.sBR)
  }

  // ── BOTTOM edge (E→F) + BL arc (F→G) ─────────────────────────────────
  PathMove {
    x: root.skipBottomEdge ? root.fx : root.ex
    y: root.skipBottomEdge ? root.fy : root.ey
  }
  PathLine { x: root.fx; y: root.fy }
  PathArc {
    x: root.skipBLarc ? root.fx : root.gx
    y: root.skipBLarc ? root.fy : root.gy
    radiusX: root.skipBLarc ? 0 : root.rBL
    radiusY: root.skipBLarc ? 0 : root.rBL
    direction: root.arcDir(root.sBL)
  }

  // ── LEFT edge (G→H) + TL arc (H→A) ───────────────────────────────────
  PathMove {
    x: root.skipLeftEdge ? root.hx : root.gx
    y: root.skipLeftEdge ? root.hy : root.gy
  }
  PathLine { x: root.hx; y: root.hy }
  PathArc {
    x: root.skipTLarc ? root.hx : root.ax
    y: root.skipTLarc ? root.hy : root.ay
    radiusX: root.skipTLarc ? 0 : root.rTL
    radiusY: root.skipTLarc ? 0 : root.rTL
    direction: root.arcDir(root.sTL)
  }
}
