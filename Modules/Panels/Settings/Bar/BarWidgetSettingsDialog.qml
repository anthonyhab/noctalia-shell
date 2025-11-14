import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI

// Widget Settings Dialog Component
Popup {
  id: root

  property int widgetIndex: -1
  property var widgetData: null
  property string widgetId: ""
  property string sectionId: ""

  signal updateWidgetSettings(string section, int index, var settings)

  readonly property real minDialogWidth: Math.round(700 * Style.uiScaleRatio)
  readonly property real overlayAvailableWidth: parent ? parent.width - Style.marginXL * 2 : minDialogWidth

  width: Math.min(Math.max(content.implicitWidth + padding * 2, minDialogWidth), Math.max(overlayAvailableWidth, 0))
  height: content.implicitHeight + padding * 2
  padding: Style.marginXL
  modal: true
  closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnPressOutsideParent
  dim: false
  anchors.centerIn: parent

  onOpened: {
    PanelService.registerPanelPopup(root)
    // Load settings when popup opens with data
    if (widgetData && widgetId) {
      loadWidgetSettings()
    }
  }

  onClosed: PanelService.unregisterPanelPopup(root)

  background: Rectangle {
    id: bgRect

    color: Color.mSurface
    radius: Style.radiusL
    border.color: Color.mPrimary
    border.width: Style.borderM
  }

  contentItem: ColumnLayout {
    id: content

    width: parent.width
    spacing: Style.marginM

    // Title
    RowLayout {
      Layout.fillWidth: true

      NText {
        text: I18n.tr("system.widget-settings-title", {
                        "widget": root.widgetId
                      })
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
        Layout.fillWidth: true
      }

      NIconButton {
        icon: "close"
        tooltipText: I18n.tr("tooltips.close")
        onClicked: root.close()
      }
    }

    // Separator
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Color.mOutline
    }

    // Settings based on widget type
    // Will be triggered via settingsLoader.setSource()
    Loader {
      id: settingsLoader
      Layout.fillWidth: true
    }

    // Action buttons
    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginM
      spacing: Style.marginM

      Item {
        Layout.fillWidth: true
      }

      NButton {
        text: I18n.tr("bar.widget-settings.dialog.cancel")
        outlined: true
        onClicked: root.close()
      }

      NButton {
        text: I18n.tr("bar.widget-settings.dialog.apply")
        icon: "check"
        onClicked: {
          if (settingsLoader.item && settingsLoader.item.saveSettings) {
            var newSettings = settingsLoader.item.saveSettings()
            root.updateWidgetSettings(root.sectionId, root.widgetIndex, newSettings)
            root.close()
          }
        }
      }
    }
  }

  function loadWidgetSettings() {
    const source = BarWidgetRegistry.widgetSettingsMap[widgetId]
    if (source) {
      // Use setSource to pass properties at creation time
      settingsLoader.setSource(source, {
                                 "widgetData": widgetData,
                                 "widgetMetadata": BarWidgetRegistry.widgetMetadata[widgetId]
                               })
    }
  }
}
