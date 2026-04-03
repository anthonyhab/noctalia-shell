pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Centralized icon scaling utility for consistent icon sizing throughout the shell
QtObject {
  id: root
  
  // Global cache of auto-calculated canvas crops (URL -> multiplier)
  property var cropCache: ({})

  // Get scale factor. Returns the cached auto-cropped scale, or 1.0 if not yet analyzed.
  function getTrayIconScale(appId, appTitle, iconPath) {
    if (!iconPath) return 1.0;
    
    // Resolve full path for the cache key
    var cacheKey = iconPath.toString();
    if (cacheKey.includes("?path=")) {
      const chunks = cacheKey.split("?path=");
      const name = chunks[0];
      const path = chunks[1];
      const fileName = name.substring(name.lastIndexOf("/") + 1);
      cacheKey = `file://${path}/${fileName}`;
    }
    
    // Explicit manual overrides can still go here if absolutely necessary, but
    // the goal is for cropCache to handle 99% of bounding box math automatically.
    
    if (cropCache[cacheKey] !== undefined) {
      return cropCache[cacheKey];
    }
    
    // Default: no scaling while Canvas analyzes in the background
    return 1.0
  }
  
  // Register a newly calculated crop scale from an NAutoCropIcon canvas analyzer
  function setCropScale(iconUrl, scale) {
    if (!iconUrl) return;
    
    // Force reactivity by creating a new object
    var newCache = Object.assign({}, cropCache);
    newCache[iconUrl.toString()] = scale;
    cropCache = newCache;
  }
  
  // Calculate constrained scale that doesn't exceed container bounds
  function getConstrainedScale(requestedScale, containerHeight) {
    // Compact density padding (4px)
    var padding = Style.marginXS
    var maxIconSize = containerHeight - (padding * 2)
    
    // Base icon is ~65% of container height
    var baseIconSize = containerHeight * 0.65
    var maxScale = maxIconSize / baseIconSize
    
    // Clamp between 0.5x and container-bound maximum
    return Math.max(0.5, Math.min(requestedScale, maxScale))
  }
  
  // Get final effective scale for an icon
  function getEffectiveScale(iconPath, containerHeight) {
    var densityScale = getScale(iconPath)
    var globalScale = Settings.data.ui.iconScale
    var rawScale = densityScale * globalScale
    
    return getConstrainedScale(rawScale, containerHeight)
  }
}
