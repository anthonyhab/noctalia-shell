import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var screen: null
  property var widgetData: null
  property var widgetMetadata: null

  property string valueLabelMode: widgetData.labelMode !== undefined ? widgetData.labelMode : widgetMetadata.labelMode
  property bool valueHideUnoccupied: widgetData.hideUnoccupied !== undefined ? widgetData.hideUnoccupied : widgetMetadata.hideUnoccupied
  property bool valueFollowFocusedScreen: widgetData.followFocusedScreen !== undefined ? widgetData.followFocusedScreen : widgetMetadata.followFocusedScreen
  property int valueCharacterCount: widgetData.characterCount !== undefined ? widgetData.characterCount : widgetMetadata.characterCount
  property bool valueShowScratchpad: widgetData.showScratchpad !== undefined ? widgetData.showScratchpad : widgetMetadata.showScratchpad
  property bool valueScrollThroughScratchpads: widgetData.scrollThroughScratchpads !== undefined ? widgetData.scrollThroughScratchpads : widgetMetadata.scrollThroughScratchpads
  property bool valueColorizeIcons: widgetData.colorizeIcons !== undefined ? widgetData.colorizeIcons : widgetMetadata.colorizeIcons
  property real valueUnfocusedIconsOpacity: widgetData.unfocusedIconsOpacity !== undefined ? widgetData.unfocusedIconsOpacity : widgetMetadata.unfocusedIconsOpacity
  property bool valueEnableScrollWheel: widgetData.enableScrollWheel !== undefined ? widgetData.enableScrollWheel : widgetMetadata.enableScrollWheel
  property real valueIconScale: widgetData.iconScale !== undefined ? widgetData.iconScale : widgetMetadata.iconScale

  function trOrDefault(key, fallbackText) {
    var translated = I18n.tr(key);
    if (translated === undefined || translated === null)
      return fallbackText;
    if (typeof translated === "string" && translated.length >= 4 && translated.slice(0, 2) === "!!" && translated.slice(-2) === "!!")
      return fallbackText;
    return translated;
  }

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.labelMode = valueLabelMode;
    settings.hideUnoccupied = valueHideUnoccupied;
    settings.characterCount = valueCharacterCount;
    settings.followFocusedScreen = valueFollowFocusedScreen;
    settings.showScratchpad = valueShowScratchpad;
    settings.scrollThroughScratchpads = valueScrollThroughScratchpads;
    settings.colorizeIcons = valueColorizeIcons;
    settings.unfocusedIconsOpacity = valueUnfocusedIconsOpacity;
    settings.enableScrollWheel = valueEnableScrollWheel;
    settings.iconScale = valueIconScale;
    return settings;
  }

  NComboBox {
    label: root.trOrDefault("bar.workspace.label-mode-label", "Label mode")
    description: root.trOrDefault("bar.workspace.label-mode-description", "Choose how workspace labels are displayed.")
    model: [
      {
        "key": "index",
        "name": root.trOrDefault("options.workspace-labels.index", "Index")
      },
      {
        "key": "name",
        "name": root.trOrDefault("options.workspace-labels.name", "Name")
      },
      {
        "key": "index+name",
        "name": root.trOrDefault("options.workspace-labels.index-and-name", "Index + name")
      }
    ]
    currentKey: valueLabelMode === "none" ? "index" : valueLabelMode
    onSelected: key => valueLabelMode = key
    minimumWidth: 200
  }

  NSpinBox {
    label: root.trOrDefault("bar.workspace.character-count-label", "Character count")
    description: root.trOrDefault("bar.workspace.character-count-description", "Number of characters to display from workspace names (1-10).")
    from: 1
    to: 10
    value: valueCharacterCount
    onValueChanged: valueCharacterCount = value
    visible: valueLabelMode === "name" || valueLabelMode === "index+name"
  }

  NToggle {
    label: root.trOrDefault("bar.workspace.hide-unoccupied-label", "Hide unoccupied")
    description: root.trOrDefault("bar.workspace.hide-unoccupied-description", "Don't display workspaces without windows.")
    checked: valueHideUnoccupied
    onToggled: checked => valueHideUnoccupied = checked
  }

  NToggle {
    label: root.trOrDefault("bar.workspace.show-scratchpad-label", "Show scratchpad")
    description: root.trOrDefault("bar.workspace.show-scratchpad-description", "Display scratchpad/special workspaces in the workspace switcher.")
    checked: valueShowScratchpad
    onToggled: checked => valueShowScratchpad = checked
  }

  NToggle {
    label: root.trOrDefault("bar.workspace.scroll-through-scratchpads-label", "Scroll through scratchpad")
    description: root.trOrDefault("bar.workspace.scroll-through-scratchpads-description", "Include scratchpad workspaces in scroll wheel navigation.")
    checked: valueScrollThroughScratchpads
    onToggled: checked => valueScrollThroughScratchpads = checked
    visible: valueShowScratchpad
  }

  NToggle {
    label: root.trOrDefault("bar.workspace.follow-focused-screen-label", "Follow focused screen")
    description: root.trOrDefault("bar.workspace.follow-focused-screen-description", "Display workspaces from the currently focused screen, rather than the screen where the bar is located.")
    checked: valueFollowFocusedScreen
    onToggled: checked => valueFollowFocusedScreen = checked
  }

  NToggle {
    label: root.trOrDefault("bar.workspace.enable-scrollwheel-label", "Scroll to switch workspaces")
    description: root.trOrDefault("bar.workspace.enable-scrollwheel-description", "Switch between workspaces using the mouse scroll wheel.")
    checked: valueEnableScrollWheel
    onToggled: checked => valueEnableScrollWheel = checked
  }

  NDivider {
    Layout.fillWidth: true
  }

  NToggle {
    label: root.trOrDefault("bar.tray.colorize-icons-label", "Colorize icons")
    description: root.trOrDefault("bar.active-window.colorize-icons-description", "Apply theme colors to active window icon.")
    checked: valueColorizeIcons
    onToggled: checked => valueColorizeIcons = checked
  }

  NValueSlider {
    label: root.trOrDefault("bar.workspace.unfocused-icons-opacity-label", "Unfocused icons opacity")
    description: root.trOrDefault("bar.workspace.unfocused-icons-opacity-description", "Set the opacity level for unfocused app icons.")
    from: 0
    to: 1
    stepSize: 0.01
    showReset: true
    value: valueUnfocusedIconsOpacity
    defaultValue: widgetMetadata.unfocusedIconsOpacity
    onMoved: value => valueUnfocusedIconsOpacity = value
    text: Math.floor(valueUnfocusedIconsOpacity * 100) + "%"
  }

  NValueSlider {
    label: root.trOrDefault("bar.taskbar.icon-scale-label", "Icon scaling")
    description: root.trOrDefault("bar.taskbar.icon-scale-description", "Sets the scaling factor for taskbar icons.")
    from: 0.5
    to: 1
    stepSize: 0.01
    showReset: true
    value: valueIconScale
    defaultValue: widgetMetadata.iconScale
    onMoved: value => valueIconScale = value
    text: Math.round(valueIconScale * 100) + "%"
  }
}
