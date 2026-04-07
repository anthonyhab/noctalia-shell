import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property var windowModel: null
  property int slotExtent: 24
  property int renderExtent: slotExtent
  property bool isFocusedWindow: false
  property real iconOpacity: 0.75
  property real unfocusedIconsOpacity: 0.75
  property bool colorizeIcons: false
  property string iconSource: ""
  property color iconColor: "#ffffff"
  property color hoveredIconColor: "#ffffff"
  property bool itemHovered: false
  property bool itemPressed: false
  property string tooltipDirection: "bottom"

  signal clicked(var window)
  signal rightClicked(var window, string appId)

  implicitWidth: slotExtent
  implicitHeight: slotExtent

  Item {
    id: iconStage
    anchors.centerIn: parent
    width: root.slotExtent
    height: root.slotExtent
    scale: root.itemPressed ? 0.94 : (root.itemHovered ? 1.05 : 1.0)

    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    Image {
      width: Math.max(1, root.renderExtent)
      height: width
      x: Style.pixelAlignCenter(parent.width, width)
      y: Style.pixelAlignCenter(parent.height, height)
      source: root.iconSource.startsWith("/") ? "file://" + root.iconSource : root.iconSource
      fillMode: Image.PreserveAspectFit
      smooth: true
      asynchronous: true
      opacity: root.itemHovered ? Math.min(1.0, root.iconOpacity + 0.20) : root.iconOpacity

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      layer.enabled: root.colorizeIcons
      layer.effect: ShaderEffect {
        property color targetColor: root.itemHovered ? root.hoveredIconColor : root.iconColor
        property vector4d params: Qt.vector4d(0.0, 0.0, 0.0, 0.0)
        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: {
      root.itemHovered = true;
      const title = root.windowModel?.title || root.windowModel?.appId || "";
      if (title.length > 0)
        TooltipService.show(root, title, root.tooltipDirection, 120);
    }
    onExited: {
      root.itemHovered = false;
      root.itemPressed = false;
      TooltipService.hide(root);
    }
    onPressed: mouse => {
      if (mouse.button === Qt.LeftButton)
        root.itemPressed = true;
    }
    onReleased: mouse => {
      root.itemPressed = false;
      if (mouse.button === Qt.RightButton && root.windowModel) {
        const appId = root.windowModel.appId ? root.windowModel.appId.toString() : "";
        root.rightClicked(root.windowModel, appId);
      }
    }
    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton && root.windowModel)
        root.clicked(root.windowModel);
    }
  }
}
