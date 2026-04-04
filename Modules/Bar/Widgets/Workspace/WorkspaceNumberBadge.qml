import QtQuick
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var workspaceModel
  property string labelMode: "index"
  property int characterCount: 3
  property bool hasWindows: false
  property bool isFocused: false
  property bool isScratchpad: false
  property real capsuleHeight: Style.capsuleHeight
  property real barFontSize: Style.barFontSize
  property bool itemHovered: false
  property int inset: 0

  signal clicked()

  readonly property bool isUrgent: workspaceModel ? workspaceModel.isUrgent : false
  readonly property string labelText: {
    if (!workspaceModel)
      return "";
    if (isScratchpad && workspaceModel.scratchpadLabel)
      return workspaceModel.scratchpadLabel.toString();

    const idx = workspaceModel.idx !== undefined ? workspaceModel.idx.toString() : "";
    const name = workspaceModel.name ? workspaceModel.name.toString().substring(0, characterCount) : "";

    if (labelMode === "name")
      return name;
    if (labelMode === "index+name" && name.length > 0)
      return idx.length > 0 ? idx + " " + name : name;
    return idx;
  }

  readonly property int horizontalPadding: Math.max(Style.marginXS, Math.round(capsuleHeight * 0.24))

  implicitWidth: Math.max(capsuleHeight - (inset * 2), label.contentWidth + horizontalPadding * 2)
  implicitHeight: capsuleHeight

  NText {
    id: label
    anchors.centerIn: parent
    text: root.labelText
    family: Settings.data.ui.fontFixed
    pointSize: root.barFontSize
    applyUiScale: false
    font.weight: root.isFocused ? Style.fontWeightBold : Style.fontWeightMedium
    color: root.isFocused ? Color.mOnPrimary : (root.itemHovered ? Color.mOnHover : Qt.alpha(Color.mOnSurface, 0.96))
    Behavior on color {
      ColorAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutCubic
      }
    }
    features: ({
                 "tnum": 1
               })
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: root.itemHovered = true
    onExited: root.itemHovered = false
    onClicked: root.clicked()
  }
}
