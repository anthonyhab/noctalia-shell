import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.Compositor
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
    if (section && sectionWidgetIndex >= 0) {
      var widgets = Settings.data.bar.widgets[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property string barPosition: Settings.data.bar.position
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real baseDimensionRatio: 0.65 * (widgetSettings.labelMode === "none" ? 0.75 : 1)

  readonly property string labelMode: (widgetSettings.labelMode !== undefined) ? widgetSettings.labelMode : widgetMetadata.labelMode

  readonly property bool hideUnoccupied: (widgetSettings.hideUnoccupied !== undefined) ? widgetSettings.hideUnoccupied : widgetMetadata.hideUnoccupied
  readonly property bool followFocusedScreen: (widgetSettings.followFocusedScreen !== undefined) ? widgetSettings.followFocusedScreen : widgetMetadata.followFocusedScreen
  readonly property int characterCount: {
    const count = (widgetSettings.characterCount !== undefined) ? widgetSettings.characterCount : widgetMetadata.characterCount;
    return isVertical ? Math.min(count, 2) : count;
  }

  // Grouped mode (show applications) settings
  readonly property bool showApplications: (widgetSettings.showApplications !== undefined) ? widgetSettings.showApplications : widgetMetadata.showApplications
  readonly property bool showApplicationsHover: (widgetSettings.showApplicationsHover !== undefined) ? widgetSettings.showApplicationsHover : widgetMetadata.showApplicationsHover
  readonly property bool showLabelsOnlyWhenOccupied: (widgetSettings.showLabelsOnlyWhenOccupied !== undefined) ? widgetSettings.showLabelsOnlyWhenOccupied : widgetMetadata.showLabelsOnlyWhenOccupied
  readonly property bool colorizeIcons: (widgetSettings.colorizeIcons !== undefined) ? widgetSettings.colorizeIcons : widgetMetadata.colorizeIcons
  readonly property real unfocusedIconsOpacity: (widgetSettings.unfocusedIconsOpacity !== undefined) ? widgetSettings.unfocusedIconsOpacity : widgetMetadata.unfocusedIconsOpacity
  readonly property real groupedBorderOpacity: (widgetSettings.groupedBorderOpacity !== undefined) ? widgetSettings.groupedBorderOpacity : widgetMetadata.groupedBorderOpacity
  readonly property bool enableScrollWheel: (widgetSettings.enableScrollWheel !== undefined) ? widgetSettings.enableScrollWheel : widgetMetadata.enableScrollWheel
  readonly property real iconScale: (widgetSettings.iconScale !== undefined) ? widgetSettings.iconScale : widgetMetadata.iconScale
  readonly property string activeIndicatorStyle: (widgetSettings.activeIndicatorStyle !== undefined) ? widgetSettings.activeIndicatorStyle : widgetMetadata.activeIndicatorStyle

  readonly property string focusedWindowId: {
    var idx = CompositorService.focusedWindowIndex;
    if (idx >= 0 && idx < CompositorService.windows.count) {
      var win = CompositorService.windows.get(idx);
      return win ? win.id : "";
    }
    return "";
  }

  // Only for grouped mode / show apps
  readonly property int baseItemSize: Style.toOdd(Style.capsuleHeight * 0.8)
  readonly property int iconSize: Style.toOdd(baseItemSize * iconScale)
  readonly property real textRatio: 0.50

  // Context menu state for grouped mode - store IDs instead of object references to avoid stale references
  property string selectedWindowId: ""
  property string selectedAppId: ""

  // Helper to get the current window object from ID
  function getSelectedWindow() {
    if (!selectedWindowId)
      return null;
    for (var i = 0; i < localWorkspaces.count; i++) {
      var ws = localWorkspaces.get(i);
      if (ws && ws.windows) {
        for (var j = 0; j < ws.windows.count; j++) {
          var win = ws.windows.get(j);
          // Using loose equality on purpose (==)
          if (win && (win.id == selectedWindowId || win.address == selectedWindowId)) {
            return win;
          }
        }
      }
    }
    return null;
  }

  property bool isDestroying: false

  property ListModel localWorkspaces: ListModel {}
  property real masterProgress: 0.0
  property bool effectsActive: false
  property color effectColor: Color.mPrimary

  readonly property int barInset: Style.pixelAlignCenter(Style.barHeight, Style.capsuleHeight)
  readonly property int groupedContentPadding: Math.max(Style.marginXXS, Math.round(root.iconSize * 0.15))
  readonly property real groupedMaxIconScale: 0.88 + 0.16 + 0.07
  readonly property int groupedIndicatorInset: root.activeIndicatorStyle !== "none" ? Style.marginXXS : 0
  readonly property int groupedEdgeInset: Math.max(Style.marginXXS, Math.ceil(root.iconSize * (groupedMaxIconScale - 1) * 0.5) + groupedIndicatorInset)
  readonly property int labelPillWidth: Math.max(Style.toOdd(Style.capsuleHeight * 0.34), Math.ceil(Style.fontSizeXS * 1.5))
  readonly property int labelPillWidthActive: Style.toOdd(labelPillWidth * 1.45)
  readonly property int labelPillGap: groupedContentPadding
  readonly property int pillPadding: Style.pixelAlignCenter(Style.capsuleHeight, Style.toOdd(Style.capsuleHeight * root.baseDimensionRatio))
  property int horizontalPadding: showApplications ? 0 : pillPadding
  property int spacingBetweenPills: Style.marginXS
  // Wheel scroll handling
  property int wheelAccumulatedDelta: 0
  property bool wheelCooldown: false
  property int focusTick: 0
  property string windowsSignature: ""

  signal workspaceChanged(int workspaceId, color accentColor)

  implicitWidth: showApplications ? (isVertical ? groupedGrid.implicitWidth + barInset * 2 : groupedGrid.implicitWidth + horizontalPadding * 2) : (isVertical ? Style.barHeight : computeWidth())
  implicitHeight: showApplications ? (isVertical ? Math.round(groupedGrid.implicitHeight + barInset * 2) : Style.barHeight) : (isVertical ? computeHeight() : Style.barHeight)

  function getWorkspaceWidth(ws) {
    const d = Math.round(Style.capsuleHeight * root.baseDimensionRatio);
    const factor = ws.isActive ? 2.2 : 1;

    // Don't calculate text width if labels are off
    if (labelMode === "none") {
      return Math.round(d * factor);
    }

    var displayText = ws.idx.toString();

    if (ws.name && ws.name.length > 0) {
      if (root.labelMode === "name") {
        displayText = ws.name.substring(0, characterCount);
      } else if (root.labelMode === "index+name") {
        displayText = ws.idx.toString() + " " + ws.name.substring(0, characterCount);
      }
    }

    const textWidth = displayText.length * (d * 0.4); // Approximate width per character
    const padding = d * 0.6;
    return Style.toOdd(Math.max(d * factor, textWidth + padding));
  }

  function getWorkspaceHeight(ws) {
    const d = Math.round(Style.capsuleHeight * root.baseDimensionRatio);
    const factor = ws.isActive ? 2.2 : 1;
    return Style.toOdd(d * factor);
  }

  function computeWidth() {
    let total = 0;
    for (var i = 0; i < localWorkspaces.count; i++) {
      const ws = localWorkspaces.get(i);
      total += getWorkspaceWidth(ws);
    }
    total += Math.max(localWorkspaces.count - 1, 0) * spacingBetweenPills;
    total += horizontalPadding * 2;
    return Style.toOdd(total);
  }

  function computeHeight() {
    let total = 0;
    for (var i = 0; i < localWorkspaces.count; i++) {
      const ws = localWorkspaces.get(i);
      total += getWorkspaceHeight(ws);
    }
    total += Math.max(localWorkspaces.count - 1, 0) * spacingBetweenPills;
    total += horizontalPadding * 2;
    return Style.toOdd(total);
  }

  function clampRadius(radius, width, height) {
    return Math.min(radius, Math.min(width, height) / 2);
  }

  function mixColor(colorA, colorB, t) {
    var f = Math.max(0, Math.min(1, t));
    return Qt.rgba(colorA.r * (1 - f) + colorB.r * f, colorA.g * (1 - f) + colorB.g * f, colorA.b * (1 - f) + colorB.b * f, colorA.a * (1 - f) + colorB.a * f);
  }

  function trOrDefault(key, fallbackText) {
    var translated = I18n.tr(key);
    if (translated === undefined || translated === null)
      return fallbackText;
    if (typeof translated === "string" && translated.length >= 4 && translated.slice(0, 2) === "!!" && translated.slice(-2) === "!!") {
      return fallbackText;
    }
    return translated;
  }

  function getFocusedLocalIndex() {
    for (var i = 0; i < localWorkspaces.count; i++) {
      if (localWorkspaces.get(i).isFocused === true)
        return i;
    }
    return -1;
  }

  function switchByOffset(offset) {
    if (localWorkspaces.count <= 1)
      return;
    var current = getFocusedLocalIndex();
    if (current < 0)
      current = 0;
    var next = (current + offset) % localWorkspaces.count;
    if (next < 0)
      next = localWorkspaces.count - 1;
    if (next === current)
      return;
    const ws = localWorkspaces.get(next);
    if (ws && ws.idx !== undefined)
      CompositorService.switchToWorkspace(ws);
  }

  // Helper function to normalize app IDs for case-insensitive matching
  function normalizeAppId(appId) {
    if (!appId || typeof appId !== 'string')
      return "";
    return appId.toLowerCase().trim();
  }

  // Helper function to check if an app is pinned
  function isAppPinned(appId) {
    if (!appId)
      return false;
    const pinnedApps = Settings.data.dock.pinnedApps || [];
    const normalizedId = normalizeAppId(appId);
    return pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedId);
  }

  // Helper function to toggle app pin/unpin
  function toggleAppPin(appId) {
    if (!appId)
      return;

    const normalizedId = normalizeAppId(appId);
    let pinnedApps = (Settings.data.dock.pinnedApps || []).slice();

    const existingIndex = pinnedApps.findIndex(pinnedId => normalizeAppId(pinnedId) === normalizedId);
    const isPinned = existingIndex >= 0;

    if (isPinned) {
      pinnedApps.splice(existingIndex, 1);
    } else {
      pinnedApps.push(appId);
    }

    Settings.data.dock.pinnedApps = pinnedApps;
  }

  // Deferred via Qt.callLater to avoid synchronous ListModel mutations during
  // signal cascades. Qt.callLater deduplicates by function identity, so rapid
  // calls from multiple signal handlers coalesce into a single refresh.
  function scheduleRefresh() {
    if (!root.isDestroying)
      Qt.callLater(root.refreshWorkspaces);
  }

  Component.onCompleted: scheduleRefresh()

  Component.onDestruction: {
    root.isDestroying = true;
  }

  onScreenChanged: scheduleRefresh()
  onScreenNameChanged: scheduleRefresh()
  onHideUnoccupiedChanged: scheduleRefresh()
  onShowApplicationsChanged: {
    if (showApplications) {
      scheduleRefresh();
    }
  }

  Connections {
    target: CompositorService
    function onWorkspacesChanged() {
  Connections {
    target: CompositorService
    function onWorkspacesChanged() {
      scheduleRefresh();
      root.triggerUnifiedWave();
    }
    function onWindowListChanged() {
      if (showApplications || showLabelsOnlyWhenOccupied) {
        var sig = computeWindowsSignature();
        if (sig !== windowsSignature) {
          windowsSignature = sig;
          scheduleRefresh();
        } else {
          focusTick++;
        }
      }
    }
    function onActiveWindowChanged() {
      if (showApplications) {
        focusTick++;
      }
    }
      }
    }
  }

  function refreshWorkspaces() {
    localWorkspaces.clear();

    var focusedOutput = null;
    if (followFocusedScreen) {
      for (var i = 0; i < CompositorService.workspaces.count; i++) {
        const ws = CompositorService.workspaces.get(i);
        if (ws.isFocused)
          focusedOutput = ws.output.toLowerCase();
      }
    }

    if (screen !== null) {
      const screenName = screen.name.toLowerCase();
      for (var i = 0; i < CompositorService.workspaces.count; i++) {
        const ws = CompositorService.workspaces.get(i);
        const matchesScreen = (followFocusedScreen && ws.output.toLowerCase() == focusedOutput) || (!followFocusedScreen && ws.output.toLowerCase() == screenName);

        if (!matchesScreen)
          continue;
        if (hideUnoccupied && !ws.isOccupied && !ws.isFocused)
          continue;

        if (showApplications) {
          // For grouped mode, attach windows to each workspace
          var workspaceData = Object.assign({}, ws);
          workspaceData.windows = CompositorService.getWindowsForWorkspace(ws.id);
          localWorkspaces.append(workspaceData);
        } else {
          localWorkspaces.append(ws);
        }
      }
    }
    workspaceRepeaterHorizontal.model = localWorkspaces;
    workspaceRepeaterVertical.model = localWorkspaces;
    updateWorkspaceFocus();
    windowsSignature = computeWindowsSignature();
  }

  function computeWindowsSignature() {
    var entries = [];
    for (var i = 0; i < CompositorService.windows.count; i++) {
      var win = CompositorService.windows.get(i);
      if (!win)
        continue;
      entries.push((win.id || "") + "|" + (win.workspaceId || -1) + "|" + (win.appId || ""));
    }
    entries.sort();
    return entries.join(",");
  }

  function triggerUnifiedWave() {
    effectColor = Color.mPrimary;
    masterAnimation.restart();
  }

  function updateWorkspaceFocus() {
    for (var i = 0; i < localWorkspaces.count; i++) {
      const ws = localWorkspaces.get(i);
      if (ws.isFocused === true) {
        root.workspaceChanged(ws.id, Color.mPrimary);
        break;
      }
    }
  }

  SequentialAnimation {
    id: masterAnimation
    PropertyAction {
      target: root
      property: "effectsActive"
      value: true
    }
    NumberAnimation {
      target: root
      property: "masterProgress"
      from: 0.0
      to: 1.0
      duration: Style.animationSlow * 2
      easing.type: Easing.OutQuint
    }
    PropertyAction {
      target: root
      property: "effectsActive"
      value: false
    }
    PropertyAction {
      target: root
      property: "masterProgress"
      value: 0.0
    }
  }

  NPopupContextMenu {
    id: contextMenu

    onVisibleChanged: {
      if (visible) {
        hoverEval.stop();
        root.isHovered = true;
      } else {
        hoverEval.restart();
      }
    }

    model: {
      var items = [];
      if (root.selectedWindowId) {
        // Focus item
        items.push({
                     "label": root.trOrDefault("common.focus", "Focus"),
                     "action": "focus",
                     "icon": "eye"
                   });

        // Pin/Unpin item
        const isPinned = root.isAppPinned(root.selectedAppId);
        items.push({
                     "label": !isPinned ? root.trOrDefault("common.pin", "Pin") : root.trOrDefault("common.unpin", "Unpin"),
                     "action": "pin",
                     "icon": !isPinned ? "pin" : "pinned-off"
                   });

        // Close item
        items.push({
                     "label": root.trOrDefault("common.close", "Close"),
                     "action": "close",
                     "icon": "x"
                   });

        // Add desktop entry actions
        if (typeof DesktopEntries !== 'undefined' && DesktopEntries.byId && root.selectedAppId) {
          const entry = (DesktopEntries.heuristicLookup) ? DesktopEntries.heuristicLookup(root.selectedAppId) : DesktopEntries.byId(root.selectedAppId);
          if (entry != null && entry.actions) {
            entry.actions.forEach(function (action) {
              items.push({
                           "label": action.name,
                           "action": "desktop-action-" + action.name,
                           "icon": "chevron-right",
                           "desktopAction": action
                         });
            });
          }
        }
      }
      items.push({
                   "label": root.trOrDefault("actions.widget-settings", "Widget settings"),
                   "action": "widget-settings",
                   "icon": "settings"
                 });
      return items;
    }

    onTriggered: (action, item) => {
                   var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
                   if (popupMenuWindow) {
                     popupMenuWindow.close();
                   }

                   const selectedWindow = root.getSelectedWindow();

                   if (action === "focus" && selectedWindow) {
                     CompositorService.focusWindow(selectedWindow);
                   } else if (action === "pin" && selectedAppId) {
                     root.toggleAppPin(selectedAppId);
                   } else if (action === "close" && selectedWindow) {
                     CompositorService.closeWindow(selectedWindow);
                   } else if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, section, sectionWidgetIndex, widgetId, widgetSettings);
                   } else if (action.startsWith("desktop-action-") && item && item.desktopAction) {
                     if (item.desktopAction.command && item.desktopAction.command.length > 0) {
                       Quickshell.execDetached(item.desktopAction.command);
                     } else if (item.desktopAction.execute) {
                       item.desktopAction.execute();
                     }
                   }
                   selectedWindowId = "";
                   selectedAppId = "";
                 }
  }

  Rectangle {
    id: workspaceBackground
    visible: !showApplications
    width: isVertical ? Style.capsuleHeight : parent.width
    height: isVertical ? parent.height : Style.capsuleHeight
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    x: isVertical ? Style.pixelAlignCenter(parent.width, width) : 0
    y: isVertical ? 0 : Style.pixelAlignCenter(parent.height, height)

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.RightButton
      onClicked: mouse => {
                   if (mouse.button === Qt.RightButton) {
                     mouse.accepted = true;
                     root.selectedWindowId = "";
                     root.selectedAppId = "";
                     var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
                     if (popupMenuWindow) {
                       popupMenuWindow.showContextMenu(contextMenu);
                       contextMenu.openAtItem(workspaceBackground, screen);
                     }
                   }
                 }
    }
  }

  // Debounce timer for wheel interactions
  Timer {
    id: wheelDebounce
    interval: 150
    repeat: false
    onTriggered: {
      root.wheelCooldown = false;
      root.wheelAccumulatedDelta = 0;
    }
  }

  // Scroll to switch workspaces
  WheelHandler {
    id: wheelHandler
    target: root
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    enabled: root.enableScrollWheel
    onWheel: function (event) {
      if (root.wheelCooldown)
        return;
      // Prefer vertical delta, fall back to horizontal if needed
      var dy = event.angleDelta.y;
      var dx = event.angleDelta.x;
      var useDy = Math.abs(dy) >= Math.abs(dx);
      var delta = useDy ? dy : dx;
      // One notch is typically 120
      root.wheelAccumulatedDelta += delta;
      var step = 120;
      if (Math.abs(root.wheelAccumulatedDelta) >= step) {
        var direction = root.wheelAccumulatedDelta > 0 ? -1 : 1;
        // For vertical layout, natural mapping: wheel up -> previous, down -> next (already handled by sign)
        // For horizontal layout, same mapping using vertical wheel
        root.switchByOffset(direction);
        root.wheelCooldown = true;
        wheelDebounce.restart();
        root.wheelAccumulatedDelta = 0;
        event.accepted = true;
      }
    }
  }

  // Horizontal layout for top/bottom bars
  Row {
    id: pillRow
    spacing: spacingBetweenPills
    x: horizontalPadding
    y: workspaceBackground.y + Style.pixelAlignCenter(workspaceBackground.height, height)
    visible: !isVertical && !showApplications

    Repeater {
      id: workspaceRepeaterHorizontal
      model: localWorkspaces
      Item {
        id: workspacePillContainer
        width: root.getWorkspaceWidth(model)
        height: Style.toOdd(Style.capsuleHeight * root.baseDimensionRatio)

        Rectangle {
          id: pill
          anchors.fill: parent

          Loader {
            active: (labelMode !== "none") && (!root.showLabelsOnlyWhenOccupied || model.isOccupied || model.isFocused)
            sourceComponent: Component {
              NText {
                x: Style.pixelAlignCenter(pill.width, width)
                y: Style.pixelAlignCenter(pill.height, height)
                text: {
                  if (model.name && model.name.length > 0) {
                    if (root.labelMode === "name") {
                      return model.name.substring(0, characterCount);
                    }
                    if (root.labelMode === "index+name") {
                      return (model.idx.toString() + " " + model.name.substring(0, characterCount));
                    }
                  }
                  return model.idx.toString();
                }
                family: Settings.data.ui.fontFixed
                pointSize: workspacePillContainer.height * root.textRatio
                applyUiScale: false
                font.capitalization: Font.AllUppercase
                font.weight: Style.fontWeightBold
                wrapMode: Text.Wrap
                color: {
                  if (model.isFocused)
                    return Color.mOnPrimary;
                  if (model.isUrgent)
                    return Color.mOnError;
                  if (model.isOccupied)
                    return Color.mOnSecondary;

                  return Color.mOnSecondary;
                }
              }
            }
          }

          radius: root.clampRadius(Style.nestedRadius(Style.radiusM, root.pillPadding), width, height)
          color: {
            if (model.isFocused)
              return Color.mPrimary;
            if (model.isUrgent)
              return Color.mError;
            if (model.isOccupied)
              return Color.mSecondary;

            return Qt.alpha(Color.mSecondary, 0.3);
          }
          z: 0

          MouseArea {
            id: pillMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                         if (mouse.button === Qt.LeftButton) {
                           CompositorService.switchToWorkspace(model);
                         }
                       }
            onPressed: mouse => {
                         if (mouse.button === Qt.RightButton) {
                           mouse.accepted = true;
                           root.selectedWindowId = "";
                           root.selectedAppId = "";
                           var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
                           if (popupMenuWindow) {
                             popupMenuWindow.showContextMenu(contextMenu);
                             contextMenu.openAtItem(pill, screen);
                           }
                         }
                       }
            hoverEnabled: true
          }
          // Material 3-inspired smooth animation for width, height, scale, color, opacity, and radius
          Behavior on width {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
          Behavior on height {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
          Behavior on scale {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutCubic
            }
          }
          Behavior on opacity {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutCubic
            }
          }
          Behavior on radius {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
        }

        Behavior on width {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutBack
          }
        }
        Behavior on height {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutBack
          }
        }
        // Burst effect overlay for focused pill (smaller outline)
        Rectangle {
          id: pillBurst
          anchors.centerIn: workspacePillContainer
          width: workspacePillContainer.width + 18 * root.masterProgress * scale
          height: workspacePillContainer.height + 18 * root.masterProgress * scale
          radius: root.clampRadius(pill.radius + 9 * root.masterProgress * scale, width, height)
          color: Color.transparent
          border.color: root.effectColor
          border.width: Math.max(1, Math.round((2 + 6 * (1.0 - root.masterProgress))))
          opacity: root.effectsActive && model.isFocused ? (1.0 - root.masterProgress) * 0.7 : 0
          visible: root.effectsActive && model.isFocused
          z: 1
        }
      }
    }
  }

  // Vertical layout for left/right bars
  Column {
    id: pillColumn
    spacing: spacingBetweenPills
    x: workspaceBackground.x + Style.pixelAlignCenter(workspaceBackground.width, width)
    y: horizontalPadding
    visible: isVertical && !showApplications
    scale: visible ? 1.0 : 0.8
    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
      }
    }

    Repeater {
      id: workspaceRepeaterVertical
      model: localWorkspaces
      Item {
        id: workspacePillContainerVertical
        width: Style.toOdd(Style.capsuleHeight * root.baseDimensionRatio)
        height: root.getWorkspaceHeight(model)

        Rectangle {
          id: pillVertical
          anchors.fill: parent

          Loader {
            active: (labelMode !== "none") && (!root.showLabelsOnlyWhenOccupied || model.isOccupied || model.isFocused)
            sourceComponent: Component {
              NText {
                x: Style.pixelAlignCenter(pillVertical.width, width)
                y: Style.pixelAlignCenter(pillVertical.height, height)
                text: {
                  if (model.name && model.name.length > 0) {
                    if (root.labelMode === "name") {
                      return model.name.substring(0, characterCount);
                    }
                    if (root.labelMode === "index+name") {
                      return (model.idx.toString() + model.name.substring(0, 1));
                    }
                  }
                  return model.idx.toString();
                }
                family: Settings.data.ui.fontFixed
                pointSize: workspacePillContainerVertical.width * root.textRatio
                applyUiScale: false
                font.capitalization: Font.AllUppercase
                font.weight: Style.fontWeightBold
                wrapMode: Text.Wrap
                color: {
                  if (model.isFocused)
                    return Color.mOnPrimary;
                  if (model.isUrgent)
                    return Color.mOnError;
                  if (model.isOccupied)
                    return Color.mOnSecondary;

                  return Color.mOnSecondary;
                }
              }
            }
          }

          radius: root.clampRadius(Style.nestedRadius(Style.radiusM, root.pillPadding), width, height)
          color: {
            if (model.isFocused)
              return Color.mPrimary;
            if (model.isUrgent)
              return Color.mError;
            if (model.isOccupied)
              return Color.mSecondary;

            return Qt.alpha(Color.mSecondary, 0.3);
          }
          z: 0

          MouseArea {
            id: pillMouseAreaVertical
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                         if (mouse.button === Qt.LeftButton) {
                           CompositorService.switchToWorkspace(model);
                         }
                       }
            onPressed: mouse => {
                         if (mouse.button === Qt.RightButton) {
                           mouse.accepted = true;
                           root.selectedWindowId = "";
                           root.selectedAppId = "";
                           var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
                           if (popupMenuWindow) {
                             popupMenuWindow.showContextMenu(contextMenu);
                             contextMenu.openAtItem(pillVertical, screen);
                           }
                         }
                       }
            hoverEnabled: true
          }
          // Material 3-inspired smooth animation for width, height, scale, color, opacity, and radius
          Behavior on width {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
          Behavior on height {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
          Behavior on scale {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutCubic
            }
          }
          Behavior on opacity {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutCubic
            }
          }
          Behavior on radius {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.OutBack
            }
          }
        }

        Behavior on width {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutBack
          }
        }
        Behavior on height {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutBack
          }
        }
        // Burst effect overlay for focused pill (smaller outline)
        Rectangle {
          id: pillBurstVertical
          anchors.centerIn: workspacePillContainerVertical
          width: workspacePillContainerVertical.width + 18 * root.masterProgress * scale
          height: workspacePillContainerVertical.height + 18 * root.masterProgress * scale
          radius: root.clampRadius(pillVertical.radius + 9 * root.masterProgress * scale, width, height)
          color: Color.transparent
          border.color: root.effectColor
          border.width: Math.max(1, Math.round((2 + 6 * (1.0 - root.masterProgress))))
          opacity: root.effectsActive && model.isFocused ? (1.0 - root.masterProgress) * 0.7 : 0
          visible: root.effectsActive && model.isFocused
          z: 1
        }
      }
    }
  }

  // ========================================
  // Grouped mode (showApplications = true)
  // ========================================

  Component {
    id: groupedWorkspaceDelegate

    Rectangle {
      id: groupedContainer

      required property var model
      property var workspaceModel: model
      property bool hasWindows: (workspaceModel?.windows?.count ?? 0) > 0
      property bool hoverPreviewActive: false
      readonly property bool revealRequested: hasWindows && (workspaceModel.isFocused || hoverPreviewActive)
      property real revealProgress: revealRequested ? 1.0 : 0.0
      readonly property bool showWindows: revealProgress > 0.001

      HoverHandler {
        id: groupedContainerHoverHandler
      }

      Timer {
        id: hoverRevealDelay
        interval: 36
        repeat: false
        onTriggered: {
          if (groupedContainer.hasWindows && groupedContainerHoverHandler.hovered) {
            groupedContainer.hoverPreviewActive = true;
          }
        }
      }

      Timer {
        id: hoverHideDelay
        interval: 150
        repeat: false
        onTriggered: groupedContainer.hoverPreviewActive = false
      }

      onHasWindowsChanged: {
        if (!hasWindows) {
          hoverRevealDelay.stop();
          hoverHideDelay.stop();
          hoverPreviewActive = false;
        }
      }

      Connections {
        target: groupedContainerHoverHandler
        function onHoveredChanged() {
          if (!groupedContainer.hasWindows) {
            groupedContainer.hoverPreviewActive = false;
            hoverRevealDelay.stop();
            hoverHideDelay.stop();
            return;
          }
          if (groupedContainerHoverHandler.hovered) {
            hoverHideDelay.stop();
            hoverRevealDelay.restart();
          } else {
            hoverRevealDelay.stop();
            if (groupedContainer.workspaceModel.isFocused) {
              groupedContainer.hoverPreviewActive = false;
            } else {
              hoverHideDelay.restart();
            }
          }
        }
      }

      Connections {
        target: CompositorService
        function onWorkspacesChanged() {
          if (!groupedContainerHoverHandler.hovered && !groupedContainer.workspaceModel.isFocused) {
            hoverRevealDelay.stop();
            hoverHideDelay.stop();
            groupedContainer.hoverPreviewActive = false;
          }
        }
      }
      readonly property string labelText: {
        if (workspaceModel.name && workspaceModel.name.length > 0) {
          if (root.labelMode === "name") {
            return workspaceModel.name.substring(0, root.characterCount);
          }
          if (root.labelMode === "index+name") {
            return (workspaceModel.idx.toString() + " " + workspaceModel.name.substring(0, 1));
          }
        }
        return workspaceModel.idx.toString();
      }
      readonly property int labelPillWidthCurrent: workspaceModel.isFocused ? root.labelPillWidthActive : root.labelPillWidth
      readonly property int contentInset: 0
      readonly property int borderInset: Math.ceil(borderStrokeWidth)
      readonly property int interiorInset: Math.max(contentInset, borderInset)
      readonly property int numberChipCrossLimit: Math.max(1, Style.capsuleHeight - interiorInset * 2)
      readonly property int numberChipTextPadding: Style.marginXS * 2
      readonly property int numberChipTextWidth: Math.ceil(groupedWorkspaceNumber.contentWidth)
      readonly property int numberChipTextHeight: Math.ceil(groupedWorkspaceNumber.contentHeight)
      readonly property bool compactIndexBadge: root.labelMode === "index" || (root.labelMode === "index+name" && (!workspaceModel.name || workspaceModel.name.length === 0))
      readonly property int numberChipMainRaw: {
        if (root.labelMode === "none")
          return 0;
        if (compactIndexBadge)
          return numberChipCrossLimit;
        if (root.isVertical) {
          return Math.max(labelPillWidthCurrent, numberChipTextHeight + numberChipTextPadding);
        }
        return Math.max(labelPillWidthCurrent, numberChipTextWidth + numberChipTextPadding);
      }
      readonly property int numberChipMainMax: Style.toOdd(Style.capsuleHeight * 1.9)
      readonly property int numberChipMainMin: numberChipCrossLimit
      readonly property int numberChipMain: Math.min(numberChipMainMax, Math.max(numberChipMainRaw, numberChipMainMin))
      readonly property int numberChipWidth: root.isVertical ? numberChipCrossLimit : numberChipMain
      readonly property int numberChipHeight: root.isVertical ? numberChipMain : numberChipCrossLimit
      readonly property real containerRadius: root.clampRadius(Style.radiusM, width, height)
      readonly property real numberChipRadius: Math.min(numberChipWidth, numberChipHeight) / 2
      readonly property int numberTextOffsetY: 0
      readonly property int revealGap: Math.max(Style.marginS, Math.round(root.iconSize * 0.22))
      readonly property int numberSlotWidthCollapsed: (!root.isVertical && root.labelMode !== "none") ? numberChipWidth : 0
      readonly property int numberSlotHeightCollapsed: (root.isVertical && root.labelMode !== "none") ? numberChipHeight : 0
      readonly property int numberSlotWidthExpanded: (!root.isVertical && root.labelMode !== "none") ? numberSlotWidthCollapsed : 0
      readonly property int numberSlotHeightExpanded: (root.isVertical && root.labelMode !== "none") ? numberSlotHeightCollapsed : 0
      readonly property int numberSlotVisualWidthCollapsed: numberSlotWidthCollapsed + ((!root.isVertical && compactIndexBadge) ? borderInset * 2 : 0)
      readonly property int numberSlotVisualHeightCollapsed: numberSlotHeightCollapsed + ((root.isVertical && compactIndexBadge) ? borderInset * 2 : 0)
      readonly property int numberSlotVisualWidthExpanded: numberSlotWidthExpanded + ((!root.isVertical && compactIndexBadge) ? borderInset * 2 : 0)
      readonly property int numberSlotVisualHeightExpanded: numberSlotHeightExpanded + ((root.isVertical && compactIndexBadge) ? borderInset * 2 : 0)
      readonly property int baseInnerCross: Math.max(1, Style.capsuleHeight - borderInset * 2)
      readonly property color labelBaseColor: {
        if (workspaceModel.isUrgent)
          return Qt.alpha(Color.mError, 0.72);
        if (workspaceModel.isFocused)
          return Qt.alpha(Color.mPrimary, showWindows ? 0.62 : 0.46);
        if (workspaceModel.isOccupied)
          return Qt.alpha(Color.mSecondary, 0.22);
        return Qt.alpha(Color.mSurfaceVariant, 0.42);
      }
      readonly property color iconAccentColor: Color.mSecondary
      readonly property var groupedWindows: {
        var groups = [];
        var map = {};
        if (!workspaceModel || !workspaceModel.windows)
          return groups;
        for (var i = 0; i < workspaceModel.windows.count; i++) {
          var win = workspaceModel.windows.get(i);
          if (!win)
            continue;
          var key = (win.appId || "").toString();
          if (!map[key]) {
            map[key] = {
              "appId": key,
              "entries": []
            };
            groups.push(map[key]);
          }
          map[key].entries.push({
                                  "window": win,
                                  "baseIndex": map[key].entries.length
                                });
        }
        return groups;
      }

      function appGroupExtent(group, vertical) {
        if (!group || !group.entries || group.entries.length <= 0)
          return root.iconSize;
        var count = group.entries.length;
        if (count > 2) {
          var stackOffset = Math.max(4, Math.round(root.iconSize * 0.3));
          var carouselRadius = Math.round(stackOffset * 1.6);
          return vertical ? Math.round(root.iconSize + carouselRadius * 2) : Math.round(root.iconSize + carouselRadius * 2);
        }
        return root.iconSize;
      }

      readonly property int iconFlowWidth: {
        if (!hasWindows)
          return root.iconSize;
        if (!groupedWindows || groupedWindows.length === 0)
          return root.iconSize;
        var totalWidth = 0;
        for (var i = 0; i < groupedWindows.length; i++) {
          totalWidth += root.isVertical ? root.iconSize : appGroupExtent(groupedWindows[i], false);
        }
        totalWidth += Math.max(0, groupedWindows.length - 1) * root.groupedContentPadding;
        return totalWidth;
      }

      readonly property int iconFlowHeight: {
        if (!hasWindows)
          return root.iconSize;
        if (!groupedWindows || groupedWindows.length === 0)
          return root.iconSize;
        if (!root.isVertical)
          return root.iconSize;
        var totalHeight = 0;
        for (var i = 0; i < groupedWindows.length; i++) {
          totalHeight += appGroupExtent(groupedWindows[i], true);
        }
        totalHeight += Math.max(0, groupedWindows.length - 1) * root.groupedContentPadding;
        return totalHeight;
      }

      // Focused-only morph: compact number chip capsule -> expanded icon capsule.
      readonly property int slotGap: root.labelMode !== "none" ? revealGap : 0
      readonly property int collapsedWidth: root.isVertical ? Style.capsuleHeight : (((root.labelMode !== "none") ? numberSlotWidthCollapsed : baseInnerCross) + borderInset * 2)
      readonly property int expandedWidth: root.isVertical ? Style.capsuleHeight : (iconFlowWidth + numberSlotWidthExpanded + slotGap + root.groupedContentPadding + root.groupedEdgeInset * 2 + borderInset * 2)
      readonly property int collapsedHeight: root.isVertical ? (((root.labelMode !== "none") ? numberSlotHeightCollapsed : baseInnerCross) + borderInset * 2) : Style.capsuleHeight
      readonly property int expandedHeight: root.isVertical ? (iconFlowHeight + numberSlotHeightExpanded + slotGap + root.groupedContentPadding + root.groupedEdgeInset * 2 + borderInset * 2) : Style.capsuleHeight
      readonly property real iconRevealProgress: Math.max(0, Math.min(1, (revealProgress - 0.08) / 0.92))

      width: root.isVertical ? Style.capsuleHeight : Style.toOdd(collapsedWidth + (expandedWidth - collapsedWidth) * revealProgress)
      height: root.isVertical ? Style.toOdd(collapsedHeight + (expandedHeight - collapsedHeight) * revealProgress) : Style.capsuleHeight

      Behavior on revealProgress {
        NumberAnimation {
          duration: Math.round(Style.animationNormal * 0.9)
          easing.type: Easing.OutBack
          easing.overshoot: 0.6
        }
      }

      readonly property color collapsedFillColor: workspaceModel.isFocused ? Qt.alpha(Color.mPrimary, 0.18) : Style.capsuleColor
      readonly property color expandedBaseColor: Qt.alpha(Color.mPrimary, workspaceModel.isFocused ? 0.14 : 0.1)
      readonly property color expandedFillColor: root.mixColor(expandedBaseColor, Qt.alpha(Color.mSecondary, workspaceModel.isFocused ? 0.18 : 0.14), workspaceModel.isFocused ? 0.48 : 0.32)
      color: root.mixColor(collapsedFillColor, expandedFillColor, revealProgress)
      radius: containerRadius
      antialiasing: true
      readonly property real activeBorderOpacity: Math.min(0.72, 0.45 + root.groupedBorderOpacity * 0.25)
      readonly property color outlineColor: {
        if (workspaceModel.isFocused)
          return Qt.alpha(Color.mPrimary, activeBorderOpacity);
        if (Settings.data.bar.showOutline)
          return Style.capsuleBorderColor;
        if (root.groupedBorderOpacity <= 0)
          return Color.transparent;
        return Qt.alpha(Color.mOutline, Math.min(0.45, root.groupedBorderOpacity * 0.35));
      }
      readonly property real borderStrokeWidth: outlineColor.a > 0 ? Style.borderS : 0
      border.width: 0

      Item {
        id: groupedContent
        anchors.fill: parent
        clip: true

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          enabled: !groupedContainer.hasWindows
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          preventStealing: true
          onPressed: mouse => {
                       if (mouse.button === Qt.LeftButton) {
                         CompositorService.switchToWorkspace(groupedContainer.workspaceModel);
                       }
                     }
          onReleased: mouse => {
                        if (mouse.button === Qt.RightButton) {
                          mouse.accepted = true;
                          TooltipService.hide();
                          root.selectedWindowId = "";
                          root.selectedAppId = "";
                          openGroupedContextMenu(groupedContainer);
                        }
                      }
        }

        Flow {
          id: groupedIconsFlow

          x: root.isVertical ? Style.pixelAlignCenter(parent.width, width) : (groupedContainer.numberSlotVisualWidthExpanded + groupedContainer.slotGap)
          y: root.isVertical ? (groupedContainer.numberSlotVisualHeightExpanded + groupedContainer.slotGap) : Style.pixelAlignCenter(parent.height, height)
          opacity: groupedContainer.iconRevealProgress
          scale: 0.965 + groupedContainer.iconRevealProgress * 0.035

          spacing: root.groupedContentPadding
          flow: root.isVertical ? Flow.TopToBottom : Flow.LeftToRight

          Behavior on opacity {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutCubic
            }
          }
          Behavior on x {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.InOutCubic
            }
          }
          Behavior on y {
            NumberAnimation {
              duration: Style.animationNormal
              easing.type: Easing.InOutCubic
            }
          }
          Behavior on scale {
            NumberAnimation {
              duration: Style.animationFast
              easing.type: Easing.OutCubic
            }
          }

          Repeater {
            model: groupedContainer.groupedWindows

            delegate: Item {
              id: appGroup

              required property var modelData

              readonly property var entries: modelData.entries ? modelData.entries : []
              readonly property int windowCount: entries.length
              readonly property int stackOffset: Math.max(4, Math.round(root.iconSize * 0.3))
              readonly property int carouselRadius: Math.round(stackOffset * 1.6)
              readonly property real angleStep: windowCount > 0 ? (Math.PI * 2 / windowCount) : 0
              readonly property bool useCarousel: windowCount > 2 && !collapseStack
              readonly property int activeIndex: {
                var tick = root.focusTick;
                var focusedId = root.focusedWindowId;
                for (var i = 0; i < entries.length; i++) {
                  if (entries[i].window && entries[i].window.id === focusedId)
                    return entries[i].baseIndex;
                }
                return -1;
              }
              property int lastActiveIndex: 0
              readonly property int effectiveActiveIndex: (activeIndex >= 0) ? activeIndex : lastActiveIndex
              readonly property bool collapseStack: !groupedContainer.revealRequested

              onActiveIndexChanged: {
                if (activeIndex >= 0) {
                  lastActiveIndex = activeIndex;
                }
              }

              width: useCarousel ? (root.isVertical ? root.iconSize : Math.round(root.iconSize + carouselRadius * 2)) : root.iconSize
              height: useCarousel ? (root.isVertical ? Math.round(root.iconSize + carouselRadius * 2) : root.iconSize) : root.iconSize

              Behavior on width {
                NumberAnimation {
                  duration: Style.animationNormal
                  easing.type: Easing.OutCubic
                }
              }
              Behavior on height {
                NumberAnimation {
                  duration: Style.animationNormal
                  easing.type: Easing.OutCubic
                }
              }

              Repeater {
                model: appGroup.entries

                delegate: Item {
                  id: groupedTaskbarItem

                  required property var modelData

                  property var windowModel: modelData.window
                  property bool isFocusedWindow: {
                    var tick = root.focusTick;
                    return windowModel && windowModel.id === root.focusedWindowId && groupedContainer.workspaceModel.isFocused;
                  }
                  property int baseIndex: modelData.baseIndex
                  property int stackIndex: {
                    if (appGroup.windowCount === 0)
                      return 0;
                    if (appGroup.collapseStack)
                      return 0;
                    var active = appGroup.effectiveActiveIndex < 0 ? 0 : appGroup.effectiveActiveIndex;
                    var diff = baseIndex - active;
                    var half = appGroup.windowCount / 2;
                    if (diff > half)
                      diff -= appGroup.windowCount;
                    else if (diff < -half)
                      diff += appGroup.windowCount;
                    return diff;
                  }
                  property bool itemHovered: false
                  readonly property bool isStackLeader: baseIndex === appGroup.effectiveActiveIndex
                  readonly property real depthValue: appGroup.useCarousel ? Math.cos(angle) : 1
                  readonly property real depthNormalized: appGroup.useCarousel ? ((depthValue + 1) / 2) : 1
                  property real angle: stackIndex * appGroup.angleStep
                  readonly property int indicatorInset: Math.max(1, Math.round(root.iconSize * 0.06))
                  readonly property string appIdText: (windowModel && windowModel.appId !== undefined && windowModel.appId !== null) ? windowModel.appId.toString() : ""
                  readonly property string titleText: (windowModel && windowModel.title !== undefined && windowModel.title !== null && windowModel.title.toString().length > 0) ? windowModel.title.toString() : (appIdText.length > 0 ? appIdText : "Unknown app.")
                  readonly property string iconSource: {
                    var icon = "";
                    if (appIdText.length > 0) {
                      icon = ThemeIcons.iconForAppId(appIdText);
                      if ((!icon || icon.length === 0) && appIdText.toLowerCase) {
                        icon = ThemeIcons.iconForAppId(appIdText.toLowerCase());
                      }
                    }
                    if (!icon || icon.length === 0) {
                      icon = ThemeIcons.iconFromName("application-x-executable");
                    }
                    return icon;
                  }

                  width: root.iconSize
                  height: root.iconSize
                  x: root.isVertical ? (appGroup.width / 2 - width / 2) : (appGroup.width / 2 + Math.sin(angle) * (appGroup.useCarousel ? appGroup.carouselRadius : 0) - width / 2)
                  y: root.isVertical ? (appGroup.height / 2 + Math.sin(angle) * (appGroup.useCarousel ? appGroup.carouselRadius : 0) - height / 2) : (appGroup.height / 2 - height / 2)
                  z: appGroup.collapseStack ? (isStackLeader ? 10 : 0) : (isFocusedWindow ? 20 : Math.round(depthNormalized * 10))
                  readonly property real baseScale: appGroup.collapseStack ? 1.0 : (0.88 + depthNormalized * 0.16)
                  readonly property real focusBoost: isFocusedWindow ? 0.03 : (itemHovered ? 0.03 : 0.0)
                  scale: baseScale + focusBoost
                  opacity: appGroup.collapseStack ? (isStackLeader ? Style.opacityFull : Style.opacityNone) : (isFocusedWindow ? Style.opacityFull : Math.min(Style.opacityFull, Style.opacityHeavy + depthNormalized * 0.25))

                  Behavior on angle {
                    NumberAnimation {
                      duration: Style.animationNormal
                      easing.type: Easing.OutCubic
                    }
                  }
                  Behavior on x {
                    NumberAnimation {
                      duration: Style.animationNormal
                      easing.type: Easing.InOutCubic
                    }
                  }
                  Behavior on y {
                    NumberAnimation {
                      duration: Style.animationNormal
                      easing.type: Easing.InOutCubic
                    }
                  }
                  Behavior on scale {
                    NumberAnimation {
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

                  IconImage {
                    id: groupedAppIcon

                    width: parent.width
                    height: parent.height
                    source: groupedTaskbarItem.iconSource
                    smooth: true
                    asynchronous: true
                    opacity: isFocusedWindow ? Style.opacityFull : unfocusedIconsOpacity
                    layer.enabled: root.colorizeIcons && !isFocusedWindow

                    layer.effect: ShaderEffect {
                      property color targetColor: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mSurfaceVariant
                      property real colorizeMode: 0
                      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                    }
                  }

                  // Active window indicator - supports multiple styles
                  Rectangle {
                    id: activeHalo
                    visible: isFocusedWindow && root.activeIndicatorStyle !== "none"
                    z: (root.activeIndicatorStyle === "line" || root.activeIndicatorStyle === "dot") ? 1 : -1

                    // Position based on indicator style
                    x: {
                      switch (root.activeIndicatorStyle) {
                      case "pill":
                      case "circle":
                      case "ring":
                      case "glow":
                        return (parent.width - width) / 2;
                      case "line":
                      case "dot":
                        return (parent.width - width) / 2;
                      default:
                        return (parent.width - width) / 2;
                      }
                    }
                    y: {
                      switch (root.activeIndicatorStyle) {
                      case "pill":
                      case "circle":
                      case "ring":
                      case "glow":
                        return (parent.height - height) / 2;
                      case "line":
                      case "dot":
                        return parent.height - height + Style.marginXXS;
                      default:
                        return (parent.height - height) / 2;
                      }
                    }

                    width: {
                      switch (root.activeIndicatorStyle) {
                      case "pill":
                        return parent.width + groupedTaskbarItem.indicatorInset * 2;
                      case "circle":
                      case "ring":
                        return parent.width + groupedTaskbarItem.indicatorInset * 2;
                      case "line":
                        return parent.width * 0.85;
                      case "dot":
                        return Style.marginS;
                      case "glow":
                        return parent.width * 1.25;
                      default:
                        return parent.width + Style.marginXXS * 2;
                      }
                    }

                    height: {
                      switch (root.activeIndicatorStyle) {
                      case "pill":
                        return parent.height + groupedTaskbarItem.indicatorInset * 2;
                      case "circle":
                      case "ring":
                        return parent.height + groupedTaskbarItem.indicatorInset * 2;
                      case "line":
                        return Style.borderM;
                      case "dot":
                        return Style.marginS;
                      case "glow":
                        return parent.height * 1.25;
                      default:
                        return parent.height + Style.marginXXS * 2;
                      }
                    }

                    radius: {
                      switch (root.activeIndicatorStyle) {
                      case "pill":
                        return height / 2;
                      case "circle":
                      case "ring":
                      case "glow":
                        return Math.min(width, height) / 2;
                      case "line":
                        return Style.borderM / 2;
                      case "dot":
                        return Style.marginS / 2;
                      default:
                        return Math.min(width, height) / 2;
                      }
                    }

                    color: {
                      switch (root.activeIndicatorStyle) {
                      case "pill":
                        return Color.transparent;
                      case "circle":
                        return Qt.alpha(groupedContainer.iconAccentColor, 0.2);
                      case "ring":
                        return Color.transparent;
                      case "line":
                      case "dot":
                        return groupedContainer.iconAccentColor;
                      case "glow":
                        return Qt.alpha(groupedContainer.iconAccentColor, 0.3);
                      default:
                        return Qt.alpha(groupedContainer.iconAccentColor, 0.2);
                      }
                    }

                    border.color: (root.activeIndicatorStyle === "pill" || root.activeIndicatorStyle === "circle" || root.activeIndicatorStyle === "ring") ? Qt.alpha(groupedContainer.iconAccentColor, 0.62) : Color.transparent
                    border.width: (root.activeIndicatorStyle === "pill" || root.activeIndicatorStyle === "circle" || root.activeIndicatorStyle === "ring") ? Style.borderS : 0
                  }

                  NDropShadow {
                    anchors.fill: groupedAppIcon
                    source: groupedAppIcon
                    shadowOpacity: isFocusedWindow ? 0.45 : 0.3
                    shadowBlur: isFocusedWindow ? 1.2 : 0.8
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 1
                    z: -2
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true
                    enabled: groupedTaskbarItem.opacity > 0.05

                    onPressed: mouse => {
                                 if (!windowModel)
                                 return;
                                 if (mouse.button === Qt.LeftButton) {
                                   CompositorService.focusWindow(windowModel);
                                 }
                               }

                    onReleased: mouse => {
                                  if (!windowModel)
                                  return;
                                  if (mouse.button === Qt.RightButton) {
                                    mouse.accepted = true;
                                    TooltipService.hide();
                                    root.selectedWindowId = windowModel.id || windowModel.address || "";
                                    root.selectedAppId = groupedTaskbarItem.appIdText;
                                    openGroupedContextMenu(groupedTaskbarItem);
                                  }
                                }
                    onEntered: {
                      groupedTaskbarItem.itemHovered = true;
                      TooltipService.show(groupedTaskbarItem, groupedTaskbarItem.titleText, BarService.getTooltipDirection());
                    }
                    onExited: {
                      groupedTaskbarItem.itemHovered = false;
                      TooltipService.hide();
                    }
                  }
                }
              }

              Rectangle {
                id: stackCountBadge
                visible: appGroup.collapseStack && appGroup.windowCount > 1
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: Style.marginXXS
                anchors.topMargin: Style.marginXXS
                width: Math.max(Style.toOdd(root.iconSize * 0.52), countText.implicitWidth + Style.marginS)
                height: Math.max(Style.toOdd(root.iconSize * 0.52), countText.implicitHeight + Style.marginXS)
                radius: Math.min(width, height) / 2
                color: Color.mTertiary
                border.color: Qt.alpha(Color.mOnTertiary, 0.35)
                border.width: Style.borderS
                z: 20

                NText {
                  id: countText
                  anchors.centerIn: parent
                  text: appGroup.windowCount.toString()
                  family: Settings.data.ui.fontFixed
                  pointSize: Style.barFontSize * 0.75
                  applyUiScale: false
                  color: Color.mOnTertiary
                }
              }
            }
          }
        }

        Item {
          id: groupedWorkspaceNumberContainer
          clip: true
          visible: root.labelMode !== "none" && (!root.showLabelsOnlyWhenOccupied || groupedContainer.hasWindows || groupedContainer.workspaceModel.isFocused)
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.leftMargin: groupedContainer.compactIndexBadge ? 0 : groupedContainer.borderInset
          anchors.topMargin: groupedContainer.compactIndexBadge ? 0 : groupedContainer.borderInset
          width: root.isVertical ? Math.max(1, parent.width - (((root.isVertical && groupedContainer.compactIndexBadge) ? 0 : groupedContainer.borderInset) * 2)) : (groupedContainer.showWindows ? groupedContainer.numberSlotVisualWidthExpanded : groupedContainer.numberSlotVisualWidthCollapsed)
          height: root.isVertical ? (groupedContainer.showWindows ? groupedContainer.numberSlotVisualHeightExpanded : groupedContainer.numberSlotVisualHeightCollapsed) : Math.max(1, parent.height - (((!root.isVertical && groupedContainer.compactIndexBadge) ? 0 : groupedContainer.borderInset) * 2))
          z: 2

          Rectangle {
            id: groupedWorkspaceBadge
            width: groupedContainer.compactIndexBadge ? Math.max(1, parent.width) : Math.max(1, Math.min(parent.width, groupedContainer.numberChipWidth))
            height: groupedContainer.compactIndexBadge ? Math.max(1, parent.height) : Math.max(1, Math.min(parent.height, groupedContainer.numberChipHeight))
            anchors.centerIn: parent
            radius: groupedContainer.compactIndexBadge ? Style.nestedRadius(groupedContainer.containerRadius, groupedContainer.borderInset) : groupedContainer.numberChipRadius
            color: groupedContainer.labelBaseColor
            scale: groupedContainer.compactIndexBadge ? 1.0 : (groupedContainer.workspaceModel.isFocused ? 1.02 : 1.0)

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: CompositorService.switchToWorkspace(groupedContainer.workspaceModel)
            }

            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
                easing.type: Easing.InOutCubic
              }
            }
            Behavior on width {
              NumberAnimation {
                duration: Style.animationFast
                easing.type: Easing.InOutCubic
              }
            }
            Behavior on height {
              NumberAnimation {
                duration: Style.animationFast
                easing.type: Easing.InOutCubic
              }
            }
            Behavior on scale {
              NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutBack
                easing.overshoot: 0.5
              }
            }
            NText {
              id: groupedWorkspaceNumber
              x: Style.pixelAlignCenter(parent.width, width)
              y: Style.pixelAlignCenter(parent.height, height) + groupedContainer.numberTextOffsetY
              text: groupedContainer.labelText
              family: Settings.data.ui.fontFixed
              font {
                pointSize: Style.barFontSize * 0.8
                weight: groupedContainer.workspaceModel.isFocused ? Style.fontWeightBold : Style.fontWeightMedium
                capitalization: Font.AllUppercase
              }
              applyUiScale: false
              color: {
                if (groupedContainer.workspaceModel.isFocused)
                  return Color.mOnPrimary;
                if (groupedContainer.workspaceModel.isUrgent)
                  return Color.mOnError;
                if (groupedContainer.workspaceModel.isOccupied)
                  return Color.mOnSurface;
                return Qt.alpha(Color.mOnSurface, 0.72);
              }
            }
          }

          Rectangle {
            id: groupedWorkspaceBadgeBurst
            anchors.centerIn: groupedWorkspaceBadge
            width: groupedWorkspaceBadge.width
            height: groupedWorkspaceBadge.height
            radius: groupedWorkspaceBadge.radius
            color: Color.transparent
            border.color: root.effectColor
            border.width: Math.max(1, Math.round((2 + 4 * (1.0 - root.masterProgress))))
            opacity: root.effectsActive && groupedContainer.workspaceModel.isFocused ? (1.0 - root.masterProgress) * 0.55 : 0
            visible: root.effectsActive && groupedContainer.workspaceModel.isFocused
            z: 1
          }
        }

        Rectangle {
          id: groupedContainerBorder
          anchors.fill: parent
          color: Color.transparent
          radius: groupedContainer.radius
          border.color: groupedContainer.outlineColor
          border.width: groupedContainer.borderStrokeWidth
          antialiasing: true
          z: 20

          Behavior on border.color {
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutCubic
            }
          }
        }
      }
    }
  }

  Flow {
    id: groupedGrid
    visible: showApplications
    scale: visible ? 1.0 : 0.8
    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
      }
    }

    x: root.isVertical ? Style.pixelAlignCenter(parent.width, width) : root.horizontalPadding
    y: root.isVertical ? Style.marginM : Style.pixelAlignCenter(parent.height, height)

    spacing: root.spacingBetweenPills
    flow: root.isVertical ? Flow.TopToBottom : Flow.LeftToRight

    Repeater {
      model: showApplications ? localWorkspaces : null
      delegate: groupedWorkspaceDelegate
    }
  }

  function openGroupedContextMenu(item) {
    var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
    if (popupMenuWindow) {
      popupMenuWindow.showContextMenu(contextMenu);
      contextMenu.openAtItem(item, screen);
    }
  }
}
