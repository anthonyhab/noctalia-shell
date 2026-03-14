import QtQuick
import Quickshell
import qs.Commons

Item {
  id: root
  
  // The raw size the UI wants the icon to be rendered at
  property real renderSize: 24
  
  // The DBus URL or local image path to analyze and render
  property string source: ""
  
  // Custom manual multiplier applied on top of the auto-calculated crop (default 1.0)
  property real manualScale: 1.0

  // Maximum pixel size for the final rendered icon (0 = unconstrained)
  property real maxSize: 0

  // Visual image element that actually renders to the Tray
  property alias imageNode: visualIcon

  // True autoScale retrieved natively from the centralized IconScaling cache
  // Defaults to 1.0 until the Canvas completes its asynchronous analysis
  readonly property real _autoScale: IconScaling.getTrayIconScale("", "", root.source)

  // The final size calculated instantly from the synchronous global cache
  readonly property real iconSize: {
    var raw = Math.round(root.renderSize * _autoScale * root.manualScale);
    return root.maxSize > 0 ? Math.min(raw, root.maxSize) : raw;
  }

  width: root.renderSize
  height: root.renderSize

  // The invisible analyzer that calculates and caches true bounding boxes
  Image {
    id: hiddenRenderer
    width: 64
    height: 64
    visible: false
    sourceSize.width: 64
    sourceSize.height: 64
    fillMode: Image.PreserveAspectFit
    
    // Only load if it's not already cached
    property string activeUrl: ""

    Connections {
      target: root
      function onSourceChanged() {
        if (!root.source) return;
        
        var cacheKey = root.source.toString();
        if (cacheKey.includes("?path=")) {
          const chunks = cacheKey.split("?path=");
          const name = chunks[0];
          const path = chunks[1];
          const fileName = name.substring(name.lastIndexOf("/") + 1);
          cacheKey = `file://${path}/${fileName}`;
        }
        
        if (IconScaling.cropCache[cacheKey] !== undefined) {
          return;
        }

        hiddenRenderer.activeUrl = cacheKey;
        hiddenRenderer.source = cacheKey;
      }
    }

    onStatusChanged: {
      if (status === Image.Ready && source.toString() === activeUrl) {
         // The image is visually loaded in the scenegraph. Grab its texture back to CPU.
         hiddenRenderer.grabToImage(function(result) {
            // Qt QImage to JS Canvas Context bridge
            var ctx = analyzer.getContext("2d");
            ctx.clearRect(0, 0, 64, 64);
            // We use the grabbed snapshot URL instead of the DBus URL directly
            analyzer.activeUrl = result.url;
            analyzer.loadImage(result.url);
         }, Qt.size(64, 64));
      }
    }
  }

  // Pure logic canvas solely for pixel extraction, not network IO
  Canvas {
    id: analyzer
    width: 64
    height: 64
    visible: false
    property string activeUrl: ""

    onImageLoaded: {
       analyzer.requestPaint();
    }

    onPaint: {
      var ctx = analyzer.getContext("2d");
      try {
        ctx.drawImage(analyzer.activeUrl, 0, 0, width, height);
        var imageData = ctx.getImageData(0, 0, width, height);
        var data = imageData.data;

        var minX = width, minY = height, maxX = 0, maxY = 0;
        var hasContent = false;

        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            var alpha = data[(y * width + x) * 4 + 3];
            if (alpha > 5) {
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
              hasContent = true;
            }
          }
        }

        if (hasContent) {
          var boundingWidth = maxX - minX + 1;
          var boundingHeight = maxY - minY + 1;
          var maxDim = Math.max(boundingWidth, boundingHeight);

          var calculatedScale = width / Math.max(1, maxDim);
          if (calculatedScale > 0.5 && calculatedScale < 4.0) {
              // Extract the original target URL that started this chain
              IconScaling.setCropScale(hiddenRenderer.activeUrl, calculatedScale);
          }
        }
      } catch (err) {}
    }
  }

  // The actual UI element. Thanks to the global dictionary, this sizing binding
  // evaluates synchronously during grid paints, completely eliminating unpinned scaling glitches!
  Image {
    id: visualIcon
    source: root.source
    
    width: root.iconSize
    height: root.iconSize
    
    anchors.centerIn: parent

    // Render at 4x display resolution for perfectly sharp supersampled anti-aliasing (SSAA)
    sourceSize.width: width * Screen.devicePixelRatio * 4
    sourceSize.height: height * Screen.devicePixelRatio * 4
    
    fillMode: Image.PreserveAspectFit
    mipmap: true
    smooth: true
    asynchronous: true
    opacity: status === Image.Ready ? 1 : 0
  }
}
