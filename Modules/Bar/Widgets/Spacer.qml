import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.MainScreen.Backgrounds
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  // Explicit screenName property ensures reactive binding when screen changes
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0 && screenName) {
      var widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property var barGeometryConfig: ShellGeometryPolicy.barConfig(screenName)
  readonly property string barPosition: barGeometryConfig.position
  readonly property bool isBarVertical: barGeometryConfig.isVertical
  readonly property real barHeight: barGeometryConfig.barHeight
  readonly property int spacerSize: widgetSettings.width !== undefined ? widgetSettings.width : widgetMetadata.width

  implicitWidth: isBarVertical ? barHeight : spacerSize
  implicitHeight: isBarVertical ? spacerSize : barHeight
  width: implicitWidth
  height: implicitHeight
}
