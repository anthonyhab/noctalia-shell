import QtQuick
import qs.Commons
import qs.Widgets

Item {
  id: root

  property string appId: ""
  property var entries: []
  property int chipExtent: 24
  property real unfocusedIconsOpacity: 0.75
  property bool colorizeIcons: false
  property bool isVertical: false

  signal clicked(var window)
  signal rightClicked(var window, string appId)
  signal hovered(bool isHovered, string title)

  readonly property var leaderWindow: entries.length > 0 ? entries[0].window : null
  readonly property string iconSource: {
    var icon = "";
    if (appId.length > 0) {
      icon = ThemeIcons.iconForAppId(appId);
      if (!icon || icon.length === 0)
        icon = ThemeIcons.iconForAppId(appId.toLowerCase());
    }
    if (!icon || icon.length === 0)
      icon = ThemeIcons.iconFromName("application-x-executable");
    return icon;
  }

  implicitWidth: chipExtent
  implicitHeight: chipExtent

  WorkspaceWindowIcon {
    anchors.fill: parent
    windowModel: root.leaderWindow
    isFocusedWindow: false
    chipExtent: root.chipExtent
    unfocusedIconsOpacity: root.unfocusedIconsOpacity
    colorizeIcons: root.colorizeIcons
    iconSource: root.iconSource
    onClicked: window => root.clicked(window)
    onRightClicked: (window, passedAppId) => root.rightClicked(window, passedAppId)
    onHovered: (isHovered, title) => root.hovered(isHovered, title)
  }

  Rectangle {
    visible: root.entries.length > 1
    width: Math.max(Style.toOdd(root.chipExtent * 0.42), Style.marginL)
    height: width
    radius: width / 2
    color: Color.mTertiary
    border.color: Qt.alpha(Color.mOnTertiary, 0.32)
    border.width: Style.borderS
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    NText {
      anchors.centerIn: parent
      text: root.entries.length.toString()
      color: Color.mOnTertiary
      pointSize: Math.max(Style.fontSizeXXS, root.chipExtent * 0.34)
      applyUiScale: false
      font.weight: Style.fontWeightBold
    }
  }
}
