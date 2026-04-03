pragma Singleton

import QtQuick
import Quickshell
import qs.Services.Compositor

/**
* SurfaceRenderPolicy - Shared geometry + pixel snapping rules for shell surfaces
*
* Rectangle fast path is used when the surface only needs normal/square corners.
* Complex geometries (inverted corners, framed cutouts) must use ShapePath.
*/
Singleton {
  id: root

  function deviceScale(screenName) {
    var scale = Number(CompositorService.getDisplayScale(screenName));
    if (!isFinite(scale) || scale <= 0) {
      return 1.0;
    }
    return scale;
  }

  function epsilonForScreen(screenName) {
    // Logical units for one physical pixel on this output.
    return 1.0 / deviceScale(screenName);
  }

  function nearlyEqual(a, b, screenName) {
    return Math.abs((Number(a) || 0) - (Number(b) || 0)) <= epsilonForScreen(screenName);
  }

  function isInvertedCorner(cornerState) {
    return cornerState === 1 || cornerState === 2;
  }

  function canUseRectPath(topLeftState, topRightState, bottomLeftState, bottomRightState, isFramed) {
    if (isFramed) {
      return false;
    }
    return !isInvertedCorner(topLeftState)
        && !isInvertedCorner(topRightState)
        && !isInvertedCorner(bottomLeftState)
        && !isInvertedCorner(bottomRightState);
  }

  function effectiveRadiusForSize(baseRadius, width, height) {
    var w = Math.max(0, Number(width) || 0);
    var h = Math.max(0, Number(height) || 0);
    var maxRadius = Math.min(w, h) / 2;
    return Math.max(0, Math.min(Number(baseRadius) || 0, maxRadius));
  }

  function cornerRadiusForState(cornerState, baseRadius) {
    if (cornerState === -1) {
      return 0;
    }
    return Math.max(0, Number(baseRadius) || 0);
  }

  function snapToDevicePixel(value, screenName) {
    var scale = deviceScale(screenName);
    return Math.round((Number(value) || 0) * scale) / scale;
  }

  function snapRect(x, y, width, height, screenName) {
    var w = Math.max(0, Number(width) || 0);
    var h = Math.max(0, Number(height) || 0);
    var left = snapToDevicePixel(x, screenName);
    var top = snapToDevicePixel(y, screenName);
    var right = snapToDevicePixel((Number(x) || 0) + w, screenName);
    var bottom = snapToDevicePixel((Number(y) || 0) + h, screenName);
    return {
      "x": left,
      "y": top,
      "width": Math.max(0, right - left),
      "height": Math.max(0, bottom - top)
    };
  }
}
