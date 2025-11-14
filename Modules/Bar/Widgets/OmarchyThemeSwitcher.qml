import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Services.UI
import qs.Modules.Bar.Extras

Item {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section]
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  readonly property bool isBarVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"
  readonly property string displayMode: widgetSettings.displayMode !== undefined ? widgetSettings.displayMode : widgetMetadata.displayMode

  implicitWidth: pill.width
  implicitHeight: pill.height

  BarPill {
    id: pill

    density: Settings.data.bar.density
    oppositeDirection: BarService.getPillDirection(root)
    icon: "palette"
    text: OmarchyService.available ? OmarchyService.themeName : ""
    autoHide: false
    forceOpen: !isBarVertical && root.displayMode === "alwaysShow"
    forceClose: isBarVertical || root.displayMode === "alwaysHide" || !pill.text
    tooltipText: {
      if (!OmarchyService.available) {
        return I18n.tr("tooltips.omarchy-not-available")
      }
      return I18n.tr("tooltips.omarchy-theme", {
                       "theme": OmarchyService.themeName
                     })
    }

    onClicked: {
      if (OmarchyService.available && OmarchyService.availableThemes.length > 0) {
        PanelService.getPanel("omarchyThemePanel", root.screen)?.toggle(pill)
      }
    }

    onRightClicked: {
      if (OmarchyService.available) {
        cycleTheme()
      }
    }

    onMiddleClicked: {
      if (OmarchyService.available) {
        selectRandomTheme()
      }
    }
  }

  function cycleTheme() {
    var themes = OmarchyService.availableThemes
    if (themes.length === 0) {
      Logger.w("OmarchyThemeSwitcher", "No themes available")
      return
    }

    var currentIndex = -1
    for (var i = 0; i < themes.length; i++) {
      var themeName = typeof themes[i] === 'string' ? themes[i] : themes[i].name
      if (themeName === OmarchyService.themeName) {
        currentIndex = i
        break
      }
    }

    var nextIndex = (currentIndex + 1) % themes.length
    var nextTheme = themes[nextIndex]
    var nextThemeName = typeof nextTheme === 'string' ? nextTheme : nextTheme.name

    Logger.d("OmarchyThemeSwitcher", "Cycling from", OmarchyService.themeName, "to", nextThemeName)
    OmarchyService.setTheme(nextThemeName)
  }

  function selectRandomTheme() {
    var themes = OmarchyService.availableThemes
    if (themes.length === 0) {
      Logger.w("OmarchyThemeSwitcher", "No themes available")
      return
    }

    var randomIndex = Math.floor(Math.random() * themes.length)
    var randomTheme = themes[randomIndex]
    var randomThemeName = typeof randomTheme === 'string' ? randomTheme : randomTheme.name

    Logger.d("OmarchyThemeSwitcher", "Selecting random theme:", randomThemeName)
    OmarchyService.setTheme(randomThemeName)
  }
}
