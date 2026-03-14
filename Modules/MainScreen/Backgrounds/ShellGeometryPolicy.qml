pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

/**
* ShellGeometryPolicy - Shared geometry policy for bar-aligned surfaces
*
* Provides one source of truth for:
* - per-screen bar config
* - bar visual rect
* - bar corner states
* - content window margins/sizing
* - exclusion thickness per edge
*/
Singleton {
  id: root

  function zeroRect() {
    return {
      "x": 0,
      "y": 0,
      "width": 0,
      "height": 0
    };
  }

  function barConfig(screenName) {
    var position = Settings.getBarPositionForScreen(screenName);
    var isVertical = position === "left" || position === "right";
    var isFramed = Settings.data.bar.barType === "framed";
    var frameThickness = Number(Settings.data.bar.frameThickness);
    if (!isFinite(frameThickness)) {
      frameThickness = 8;
    }
    frameThickness = Math.max(0, frameThickness);

    var floating = Settings.data.bar.floating || false;
    var marginHorizontal = floating ? Math.ceil(Number(Settings.data.bar.marginHorizontal) || 0) : 0;
    var marginVertical = floating ? Math.ceil(Number(Settings.data.bar.marginVertical) || 0) : 0;
    var barHeight = Math.max(0, Number(Style.getBarHeightForScreen(screenName)) || 0);

    return {
      "position": position,
      "isVertical": isVertical,
      "isFramed": isFramed,
      "frameThickness": frameThickness,
      "floating": floating,
      "marginHorizontal": marginHorizontal,
      "marginVertical": marginVertical,
      "barHeight": barHeight
    };
  }

  function barVisualRect(screen) {
    if (!screen) {
      return zeroRect();
    }

    var screenName = screen.name;
    var cfg = barConfig(screenName);
    var screenWidth = Math.max(0, Number(screen.width) || 0);
    var screenHeight = Math.max(0, Number(screen.height) || 0);

    var x = cfg.marginHorizontal;
    if (cfg.position === "right") {
      x = screenWidth - cfg.barHeight - cfg.marginHorizontal;
    } else if (cfg.isFramed && !cfg.isVertical) {
      x = cfg.frameThickness;
    }

    var y = cfg.marginVertical;
    if (cfg.position === "bottom") {
      y = screenHeight - cfg.barHeight - cfg.marginVertical;
    } else if (cfg.isFramed && cfg.isVertical) {
      y = cfg.frameThickness;
    }

    var width = cfg.isVertical ? cfg.barHeight : (cfg.isFramed ? (screenWidth - cfg.frameThickness * 2) : (screenWidth - cfg.marginHorizontal * 2));
    var height = !cfg.isVertical ? cfg.barHeight : (cfg.isFramed ? (screenHeight - cfg.frameThickness * 2) : (screenHeight - cfg.marginVertical * 2));

    return SurfaceRenderPolicy.snapRect(x, y, width, height, screenName);
  }

  function barCornerStates(screenName) {
    var cfg = barConfig(screenName);

    if (cfg.floating) {
      return {
        "topLeft": 0,
        "topRight": 0,
        "bottomLeft": 0,
        "bottomRight": 0
      };
    }

    var outerCorners = Settings.data.bar.outerCorners;

    var topLeft = -1;
    if (cfg.position !== "top" && cfg.position !== "left" && outerCorners && (cfg.position === "bottom" || cfg.position === "right")) {
      topLeft = cfg.isVertical ? 1 : 2;
    }

    var topRight = -1;
    if (cfg.position !== "top" && cfg.position !== "right" && outerCorners && (cfg.position === "bottom" || cfg.position === "left")) {
      topRight = cfg.isVertical ? 1 : 2;
    }

    var bottomLeft = -1;
    if (cfg.position !== "bottom" && cfg.position !== "left" && outerCorners && (cfg.position === "top" || cfg.position === "right")) {
      bottomLeft = cfg.isVertical ? 1 : 2;
    }

    var bottomRight = -1;
    if (cfg.position !== "bottom" && cfg.position !== "right" && outerCorners && (cfg.position === "top" || cfg.position === "left")) {
      bottomRight = cfg.isVertical ? 1 : 2;
    }

    return {
      "topLeft": topLeft,
      "topRight": topRight,
      "bottomLeft": bottomLeft,
      "bottomRight": bottomRight
    };
  }

  function barWindowMargins(screenName) {
    var cfg = barConfig(screenName);
    return {
      "top": cfg.position === "top" ? cfg.marginVertical : (cfg.isFramed ? cfg.frameThickness : cfg.marginVertical),
      "bottom": cfg.position === "bottom" ? cfg.marginVertical : (cfg.isFramed ? cfg.frameThickness : cfg.marginVertical),
      "left": cfg.position === "left" ? cfg.marginHorizontal : (cfg.isFramed ? cfg.frameThickness : cfg.marginHorizontal),
      "right": cfg.position === "right" ? cfg.marginHorizontal : (cfg.isFramed ? cfg.frameThickness : cfg.marginHorizontal)
    };
  }

  function barWindowImplicitSize(screen) {
    if (!screen) {
      return {
        "width": 0,
        "height": 0
      };
    }

    var cfg = barConfig(screen.name);
    var screenWidth = Math.max(0, Number(screen.width) || 0);
    var screenHeight = Math.max(0, Number(screen.height) || 0);

    return {
      "width": cfg.isVertical ? cfg.barHeight : screenWidth,
      "height": cfg.isVertical ? screenHeight : cfg.barHeight
    };
  }

  function barExclusionThickness(screenName, edge) {
    var cfg = barConfig(screenName);
    var targetEdge = edge || cfg.position;
    var baseThickness = (cfg.isFramed && targetEdge !== cfg.position) ? cfg.frameThickness : cfg.barHeight;
    var floatingMargin = 0;

    if (cfg.floating && targetEdge === cfg.position) {
      floatingMargin = (targetEdge === "left" || targetEdge === "right") ? cfg.marginHorizontal : cfg.marginVertical;
    }

    return Math.max(0, baseThickness + floatingMargin);
  }

  function barAvoidanceInset(screenName, edge) {
    return barExclusionThickness(screenName, edge);
  }

  function barAvoidanceInsets(screenName) {
    return {
      "top": barAvoidanceInset(screenName, "top"),
      "bottom": barAvoidanceInset(screenName, "bottom"),
      "left": barAvoidanceInset(screenName, "left"),
      "right": barAvoidanceInset(screenName, "right")
    };
  }

  function barTooltipDirection(screenName) {
    var position = barConfig(screenName).position;
    switch (position) {
    case "right":
      return "left";
    case "left":
      return "right";
    case "bottom":
      return "top";
    default:
      return "bottom";
    }
  }

  function centeredOffsetForAxis(screenName, axis, totalLength, segmentLength) {
    var total = Math.max(0, Number(totalLength) || 0);
    var segment = Math.max(0, Number(segmentLength) || 0);
    var cfg = barConfig(screenName);
    var insets = barAvoidanceInsets(screenName);
    var startInset = 0;
    var endInset = 0;

    if (axis === "horizontal" && cfg.isVertical) {
      startInset = insets.left;
      endInset = insets.right;
    } else if (axis === "vertical" && !cfg.isVertical) {
      startInset = insets.top;
      endInset = insets.bottom;
    }

    var availableLength = Math.max(0, total - startInset - endInset);
    return Math.max(0, Math.round(startInset + (availableLength - segment) / 2));
  }
}
