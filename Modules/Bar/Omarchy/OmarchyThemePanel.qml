import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.MainScreen

SmartPanel {
  id: root

  preferredWidth: 350 * Style.uiScaleRatio
  preferredHeight: 450 * Style.uiScaleRatio
  readonly property real maxListHeight: 320 * Style.uiScaleRatio

  panelContent: Rectangle {
    color: Color.transparent
    readonly property real contentPreferredHeight: Math.min(contentColumn.implicitHeight + Style.marginL * 2, root.preferredHeight)

    ColumnLayout {
      id: contentColumn
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Header
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.marginM * 2

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NIcon {
            icon: "palette"
            pointSize: Style.fontSizeXXL
            color: Color.mPrimary
          }

          NText {
            text: I18n.tr("settings.color-scheme.omarchy.panel.title")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.fillWidth: true
          }

          NIconButton {
            icon: "close"
            tooltipText: I18n.tr("tooltips.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: root.close()
          }
        }
      }

      // Theme list
      NScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(themeListLayout.implicitHeight, root.maxListHeight)
        Layout.maximumHeight: root.maxListHeight
        Layout.minimumHeight: Math.min(themeListLayout.implicitHeight, root.maxListHeight)
        horizontalPolicy: ScrollBar.AlwaysOff
        verticalPolicy: ScrollBar.AsNeeded
        clip: true

        ColumnLayout {
          id: themeListLayout
          width: parent.width
          spacing: 0

          Repeater {
            model: OmarchyService.availableThemes

            delegate: Rectangle {
              id: entry
              required property var modelData
              required property int index

              readonly property var theme: modelData
              readonly property string themeName: typeof theme === 'string' ? theme : theme.name
              readonly property var themeColors: typeof theme === 'object' ? theme.colors : []
              readonly property bool isCurrentTheme: themeName === OmarchyService.themeName

              Layout.preferredWidth: parent.width
              Layout.preferredHeight: Style.baseWidgetSize * 0.9
              color: Color.transparent

              Rectangle {
                anchors.fill: parent
                color: isCurrentTheme ? Color.mSecondary : (mouseArea.containsMouse ? Color.mHover : Color.transparent)
                radius: Style.radiusS

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Style.marginM
                  anchors.rightMargin: Style.marginM
                  spacing: Style.marginS

                  NText {
                    Layout.fillWidth: true
                    color: isCurrentTheme ? Color.mOnSecondary : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)
                    text: entry.themeName
                    pointSize: Style.fontSizeM
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                  }

                  // Color preview circles
                  Row {
                    spacing: Style.marginXS / 2
                    visible: entry.themeColors.length > 0

                    Repeater {
                      model: entry.themeColors

                      Rectangle {
                        width: Style.fontSizeM * 0.9
                        height: Style.fontSizeM * 0.9
                        radius: width / 2
                        color: modelData
                        border.color: Qt.darker(modelData, 1.2)
                        border.width: 1
                      }
                    }
                  }
                }

                MouseArea {
                  id: mouseArea
                  anchors.fill: parent
                  hoverEnabled: true

                  onClicked: {
                    Logger.d("OmarchyThemePanel", "Selected theme:", entry.themeName)
                    OmarchyService.setTheme(entry.themeName)
                    root.close()
                  }
                }
              }
            }
          }

          // Show message if no themes available
          NText {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.baseWidgetSize * 2
            visible: OmarchyService.availableThemes.length === 0
            text: I18n.tr("omarchy.no-themes")
            pointSize: Style.fontSizeM
            color: Color.mOnSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
