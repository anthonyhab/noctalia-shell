import QtQuick
import Quickshell
import qs.Commons

Item {
  id: root

  property var windowModel: null
  property bool showAccentChip: false
  property int chipExtent: 24
  property int accentChipExtent: 24
  property real unfocusedIconsOpacity: 0.75
  property bool colorizeIcons: false
  property string iconSource: ""
  property bool itemHovered: false
  property bool itemPressed: false

  signal clicked(var window)
  signal rightClicked(var window, string appId)
  signal hovered(bool isHovered, string title)

  implicitWidth: chipExtent
  implicitHeight: chipExtent

  Item {
    id: iconStage
    anchors.centerIn: parent
    width: root.chipExtent
    height: root.chipExtent
    scale: root.itemPressed ? 0.94 : (root.itemHovered ? 1.05 : 1.0)

    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
      }
    }

    Rectangle {
      id: accentChip
      visible: root.showAccentChip
      anchors.centerIn: parent
      width: root.accentChipExtent
      height: root.accentChipExtent
      radius: Math.min(Style.radiusS, height / 2)
      color: Qt.alpha(Color.mPrimary, 0.16)
      border.color: "transparent"
      border.width: 0
      opacity: root.showAccentChip ? 1.0 : 0.0

      Behavior on color {
        enabled: !Color.isTransitioning
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Behavior on border.color {
        enabled: !Color.isTransitioning
        ColorAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
    }

    Image {
      width: Style.toOdd(parent.width * 0.86)
      height: width
      x: Style.pixelAlignCenter(parent.width, width)
      y: Style.pixelAlignCenter(parent.height, height)
      source: root.iconSource.startsWith("/") ? "file://" + root.iconSource : root.iconSource
      smooth: true
      asynchronous: true
      opacity: root.showAccentChip ? 1.0 : (root.itemHovered ? Math.min(1.0, root.unfocusedIconsOpacity + 0.20) : root.unfocusedIconsOpacity)

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      layer.enabled: root.colorizeIcons
      layer.effect: ShaderEffect {
        property color targetColor: root.showAccentChip ? Color.mOnPrimary : Color.mOnSurface
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
      root.hovered(true, title.toString());
    }
    onExited: {
      root.itemHovered = false;
      root.itemPressed = false;
      root.hovered(false, "");
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
