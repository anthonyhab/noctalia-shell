import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property string icon: ""
  property bool checked: false
  property bool hovering: false
  property bool pressed: false
  property int baseSize: Math.round(Style.baseWidgetSize * 0.8 * Style.uiScaleRatio)
  property var defaultValue: undefined
  property string settingsPath: ""

  signal toggled(bool checked)
  signal entered
  signal exited

  Layout.fillWidth: true

  opacity: enabled ? 1.0 : 0.6
  spacing: Style.marginM

  readonly property bool isValueChanged: (defaultValue !== undefined) && (checked !== defaultValue)
  readonly property string indicatorTooltip: defaultValue !== undefined ? I18n.tr("panels.indicator.default-value", {
                                                                                    "value": typeof defaultValue === "boolean" ? (defaultValue ? "true" : "false") : String(defaultValue)
                                                                                  }) : ""

  NLabel {
    Layout.fillWidth: true
    label: root.label
    description: root.description
    icon: root.icon
    iconColor: root.checked ? Color.mPrimary : Color.mOnSurface
    visible: root.label !== "" || root.description !== ""
    showIndicator: root.isValueChanged
    indicatorTooltip: root.indicatorTooltip
  }

  Rectangle {
    id: switcher

    Layout.alignment: Qt.AlignVCenter
    Layout.margins: Style.borderS

    implicitWidth: Math.round(root.baseSize * .85) * 2
    implicitHeight: Math.round(root.baseSize * .5) * 2
    radius: Math.min(Style.iRadiusL, height / 2)
    color: root.checked ? Color.mPrimary : Color.mSurface
    border.color: Color.mOutline
    border.width: Style.borderS

    Behavior on color {
      enabled: !Color.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    Behavior on border.color {
      enabled: !Color.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    Item {
      id: knobItem
      implicitWidth: Math.round(root.baseSize * 0.4) * 2
      implicitHeight: Math.round(root.baseSize * 0.4) * 2
      anchors.verticalCenter: parent.verticalCenter
      x: root.checked ? switcher.width - width - 3 : 3

      scale: root.pressed ? 0.95 : (root.hovering ? 1.05 : 1.0)
      Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
      }

      Behavior on x {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Rectangle {
        id: knobBorder
        anchors.fill: parent
        radius: Style.nestedRadius(switcher.radius, (switcher.height - height) / 2)
        color: Color.mSurface

        Rectangle {
          anchors.fill: parent
          anchors.margins: Style.borderM
          radius: Style.nestedRadius(parent.radius, Style.borderM)
          color: root.checked ? Color.mOnPrimary : Color.mPrimary

          Behavior on color {
            enabled: !Color.isTransitioning
            ColorAnimation {
              duration: Style.animationFast
            }
          }
        }
      }

      NDropShadow {
        source: knobBorder
        anchors.fill: knobBorder
        shadowBlur: 0.5
        shadowOpacity: 0.3
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 0
      }
    }

    MouseArea {
      enabled: root.enabled
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onEntered: {
        if (!enabled)
          return;
        hovering = true;
        root.entered();
      }
      onExited: {
        if (!enabled)
          return;
        hovering = false;
        root.exited();
      }
      onPressed: {
        if (!enabled)
          return;
        root.pressed = true;
      }
      onReleased: {
        if (!enabled)
          return;
        root.pressed = false;
      }
      onCanceled: {
        root.pressed = false;
      }
      onClicked: {
        if (!enabled)
          return;
        root.toggled(!root.checked);
      }
    }
  }
}
