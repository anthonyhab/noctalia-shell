import QtQuick

Item {
  id: root
  anchors.fill: parent

  property bool enabled: true
  property Item target: null

  signal scrolled(int direction)

  property int wheelAccumulatedDelta: 0
  property bool wheelCooldown: false

  Timer {
    id: wheelDebounce
    interval: 120
    repeat: false
    onTriggered: {
      root.wheelCooldown = false;
      root.wheelAccumulatedDelta = 0;
    }
  }

  WheelHandler {
    id: wheelHandler
    target: root.target
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    enabled: root.enabled
    onWheel: function (event) {
      if (root.wheelCooldown)
        return;
      // Prefer vertical delta, fall back to horizontal if needed
      var dy = event.angleDelta.y;
      var dx = event.angleDelta.x;
      var useDy = Math.abs(dy) >= Math.abs(dx);
      var delta = useDy ? dy : dx;
      // One notch is typically 120
      root.wheelAccumulatedDelta += delta;
      var step = 120;
      if (Math.abs(root.wheelAccumulatedDelta) >= step) {
        var direction = root.wheelAccumulatedDelta > 0 ? -1 : 1;
        root.scrolled(direction);
        root.wheelCooldown = true;
        wheelDebounce.restart();
        root.wheelAccumulatedDelta = 0;
        event.accepted = true;
      }
    }
  }
}
