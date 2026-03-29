import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  // Properties to receive data from parent
  property var widgetData: null
  property var widgetMetadata: null

  property string valueLabelMode: widgetData.labelMode !== undefined ? widgetData.labelMode : widgetMetadata.labelMode
  property bool valueHideUnoccupied: widgetData.hideUnoccupied !== undefined ? widgetData.hideUnoccupied : widgetMetadata.hideUnoccupied
  property bool valueFollowFocusedScreen: widgetData.followFocusedScreen !== undefined ? widgetData.followFocusedScreen : widgetMetadata.followFocusedScreen
  property int valueCharacterCount: widgetData.characterCount !== undefined ? widgetData.characterCount : widgetMetadata.characterCount

  // Grouped mode settings
  property bool valueShowApplications: widgetData.showApplications !== undefined ? widgetData.showApplications : widgetMetadata.showApplications
  property bool valueShowApplicationsHover: widgetData.showApplicationsHover !== undefined ? widgetData.showApplicationsHover : widgetMetadata.showApplicationsHover
  property bool valueShowLabelsOnlyWhenOccupied: widgetData.showLabelsOnlyWhenOccupied !== undefined ? widgetData.showLabelsOnlyWhenOccupied : widgetMetadata.showLabelsOnlyWhenOccupied
  property bool valueColorizeIcons: widgetData.colorizeIcons !== undefined ? widgetData.colorizeIcons : widgetMetadata.colorizeIcons
  property real valueUnfocusedIconsOpacity: widgetData.unfocusedIconsOpacity !== undefined ? widgetData.unfocusedIconsOpacity : widgetMetadata.unfocusedIconsOpacity
  property real valueGroupedBorderOpacity: widgetData.groupedBorderOpacity !== undefined ? widgetData.groupedBorderOpacity : widgetMetadata.groupedBorderOpacity
  property bool valueEnableScrollWheel: widgetData.enableScrollWheel !== undefined ? widgetData.enableScrollWheel : widgetMetadata.enableScrollWheel
  property real valueIconScale: widgetData.iconScale !== undefined ? widgetData.iconScale : widgetMetadata.iconScale
  property string valueFocusedColor: widgetData.focusedColor !== undefined ? widgetData.focusedColor : widgetMetadata.focusedColor
  property string valueOccupiedColor: widgetData.occupiedColor !== undefined ? widgetData.occupiedColor : widgetMetadata.occupiedColor
  property string valueEmptyColor: widgetData.emptyColor !== undefined ? widgetData.emptyColor : widgetMetadata.emptyColor
  property bool valueShowBadge: widgetData.showBadge !== undefined ? widgetData.showBadge : widgetMetadata.showBadge
  property real valuePillSize: widgetData.pillSize !== undefined ? widgetData.pillSize : widgetMetadata.pillSize
  property string valueFontWeight: widgetData.fontWeight !== undefined ? widgetData.fontWeight : widgetMetadata.fontWeight
  property string valueActiveIndicatorStyle: widgetData.activeIndicatorStyle !== undefined ? widgetData.activeIndicatorStyle : widgetMetadata.activeIndicatorStyle

  function trOrDefault(key, fallbackText) {
    var translated = I18n.tr(key);
    if (translated === undefined || translated === null)
      return fallbackText;
    if (typeof translated === "string" && translated.length >= 4 && translated.slice(0, 2) === "!!" && translated.slice(-2) === "!!") {
      return fallbackText;
    }
    return translated;
  }

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.labelMode = valueLabelMode;
    settings.hideUnoccupied = valueHideUnoccupied;
    settings.characterCount = valueCharacterCount;
    settings.followFocusedScreen = valueFollowFocusedScreen;
    settings.showApplications = valueShowApplications;
    settings.showApplicationsHover = valueShowApplicationsHover;
    settings.showLabelsOnlyWhenOccupied = valueShowLabelsOnlyWhenOccupied;
    settings.colorizeIcons = valueColorizeIcons;
    settings.unfocusedIconsOpacity = valueUnfocusedIconsOpacity;
    settings.groupedBorderOpacity = valueGroupedBorderOpacity;
    settings.enableScrollWheel = valueEnableScrollWheel;
    settings.iconScale = valueIconScale;
    settings.focusedColor = valueFocusedColor;
    settings.occupiedColor = valueOccupiedColor;
    settings.emptyColor = valueEmptyColor;
    settings.showBadge = valueShowBadge;
    settings.pillSize = valuePillSize;
    settings.fontWeight = valueFontWeight;
    settings.activeIndicatorStyle = valueActiveIndicatorStyle;
    return settings;
  }

  NComboBox {
    id: labelModeCombo
    label: root.trOrDefault("bar.workspace.label-mode-label", "Label mode")
    description: root.trOrDefault("bar.workspace.label-mode-description", "Choose how workspace labels are displayed.")
    model: [
      {
        "key": "none",
        "name": root.trOrDefault("common.none", "None")
      },
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
    currentKey: widgetData.labelMode || widgetMetadata.labelMode
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
    visible: valueLabelMode === "name"
  }

  NToggle {
    label: root.trOrDefault("bar.workspace.hide-unoccupied-label", "Hide unoccupied")
    description: root.trOrDefault("bar.workspace.hide-unoccupied-description", "Don't display workspaces without windows.")
    checked: valueHideUnoccupied
    onToggled: checked => valueHideUnoccupied = checked
  }

  NToggle {
    label: root.trOrDefault("bar.workspace.show-labels-only-when-occupied-label", "Show labels only when occupied")
    description: root.trOrDefault("bar.workspace.show-labels-only-when-occupied-description", "Only show workspace labels when they contain windows.")
    checked: valueShowLabelsOnlyWhenOccupied
    onToggled: checked => valueShowLabelsOnlyWhenOccupied = checked
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
    label: root.trOrDefault("bar.workspace.show-applications-label", "Show applications")
    description: root.trOrDefault("bar.workspace.show-applications-description", "Display application icons inside each workspace.")
    checked: valueShowApplications
    onToggled: checked => valueShowApplications = checked
  }

  NToggle {
    label: root.trOrDefault("bar.tray.colorize-icons-label", "Colorize icons")
    description: root.trOrDefault("bar.active-window.colorize-icons-description", "Apply theme colors to active window icon.")
    checked: valueColorizeIcons
    onToggled: checked => valueColorizeIcons = checked
    visible: valueShowApplications
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
    onMoved: value => {
               valueUnfocusedIconsOpacity = value;
               saveSettings();
             }
    text: Math.floor(valueUnfocusedIconsOpacity * 100) + "%"
    visible: valueShowApplications
  }

  NValueSlider {
    label: root.trOrDefault("bar.workspace.grouped-border-opacity-label", "Border opacity")
    description: root.trOrDefault("bar.workspace.grouped-border-opacity-description", "Set the opacity level for workspace container borders.")
    from: 0
    to: 1
    stepSize: 0.01
    showReset: true
    value: valueGroupedBorderOpacity
    defaultValue: widgetMetadata.groupedBorderOpacity
    onMoved: value => {
               valueGroupedBorderOpacity = value;
               saveSettings();
             }
    text: Math.floor(valueGroupedBorderOpacity * 100) + "%"
    visible: valueShowApplications
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
    onMoved: value => {
               valueIconScale = value;
               saveSettings();
             }
    text: Math.round(valueIconScale * 100) + "%"
    visible: valueShowApplications
  }

  NComboBox {
    label: root.trOrDefault("bar.workspace.active-indicator-style-label", "Active indicator style")
    description: root.trOrDefault("bar.workspace.active-indicator-style-description", "Choose how the focused application is highlighted.")
    model: [
      {
        "key": "pill",
        "name": root.trOrDefault("bar.workspace.active-indicator-pill", "Pill")
      },
      {
        "key": "circle",
        "name": root.trOrDefault("bar.workspace.active-indicator-circle", "Circle")
      },
      {
        "key": "ring",
        "name": root.trOrDefault("bar.workspace.active-indicator-ring", "Ring")
      },
      {
        "key": "glow",
        "name": root.trOrDefault("bar.workspace.active-indicator-glow", "Glow")
      },
      {
        "key": "line",
        "name": root.trOrDefault("bar.workspace.active-indicator-line", "Line")
      },
      {
        "key": "dot",
        "name": root.trOrDefault("bar.workspace.active-indicator-dot", "Dot")
      },
      {
        "key": "none",
        "name": root.trOrDefault("common.none", "None")
      }
    ]
    currentKey: valueActiveIndicatorStyle
    onSelected: key => valueActiveIndicatorStyle = key
    minimumWidth: 200
    visible: valueShowApplications
  }
}
