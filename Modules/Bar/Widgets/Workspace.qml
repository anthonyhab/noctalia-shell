import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.MainScreen.Backgrounds
import qs.Services.Compositor
import qs.Services.UI
import qs.Widgets
import "Workspace" as WorkspaceComponents
import "Workspace/WorkspaceMetrics.js" as WorkspaceMetrics
import "Workspace/WorkspaceWindowMatcher.js" as WorkspaceWindowMatcher

Item {
  id: root

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] || {}
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0 && screenName) {
      var widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length && widgets[sectionWidgetIndex])
        return widgets[sectionWidgetIndex];
    }
    return {};
  }

  readonly property string effectiveLabelMode: {
    const savedMode = (widgetSettings.labelMode !== undefined) ? widgetSettings.labelMode : (widgetMetadata.labelMode || "index");
    return savedMode === "none" ? "index" : savedMode;
  }
  readonly property int characterCount: (widgetSettings.characterCount !== undefined) ? widgetSettings.characterCount : (widgetMetadata.characterCount || 2)
  readonly property bool hideUnoccupied: (widgetSettings.hideUnoccupied !== undefined) ? widgetSettings.hideUnoccupied : (widgetMetadata.hideUnoccupied !== undefined ? widgetMetadata.hideUnoccupied : false)
  readonly property bool followFocusedScreen: (widgetSettings.followFocusedScreen !== undefined) ? widgetSettings.followFocusedScreen : (widgetMetadata.followFocusedScreen !== undefined ? widgetMetadata.followFocusedScreen : false)
  readonly property bool showScratchpad: (widgetSettings.showScratchpad !== undefined) ? widgetSettings.showScratchpad : (widgetMetadata.showScratchpad || true)
  readonly property bool colorizeIcons: (widgetSettings.colorizeIcons !== undefined) ? widgetSettings.colorizeIcons : (widgetMetadata.colorizeIcons || false)
  readonly property real unfocusedIconsOpacity: (widgetSettings.unfocusedIconsOpacity !== undefined) ? widgetSettings.unfocusedIconsOpacity : (widgetMetadata.unfocusedIconsOpacity !== undefined ? widgetMetadata.unfocusedIconsOpacity : 1.0)
  readonly property bool enableScrollWheel: (widgetSettings.enableScrollWheel !== undefined) ? widgetSettings.enableScrollWheel : (widgetMetadata.enableScrollWheel !== undefined ? widgetMetadata.enableScrollWheel : true)
  readonly property bool scrollThroughScratchpads: (widgetSettings.scrollThroughScratchpads !== undefined) ? widgetSettings.scrollThroughScratchpads : (widgetMetadata.scrollThroughScratchpads !== undefined ? widgetMetadata.scrollThroughScratchpads : false)
  readonly property real iconScale: (widgetSettings.iconScale !== undefined) ? widgetSettings.iconScale : (widgetMetadata.iconScale || 1.0)

  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
  readonly property var barGeometryConfig: ShellGeometryPolicy.barConfig(screenName)
  readonly property bool isVertical: !!barGeometryConfig.isVertical
  readonly property real barHeight: barGeometryConfig.barHeight
  readonly property var metrics: WorkspaceMetrics.buildMetrics({
    capsuleHeight: capsuleHeight,
    iconScale: iconScale * Style.iconScaleRatio,
    marginXXS: Style.marginXXS,
    marginXS: Style.marginXS,
  })

  readonly property string tooltipDirection: BarService.getTooltipDirection(root.screenName)
  readonly property string focusedWindowId: CompositorService.focusedWindowId
  readonly property string focusedScreen: CompositorService.focusedScreen
  readonly property var localWorkspaces: CompositorService.workspaces
  readonly property var localSpecialWorkspaces: CompositorService.specialWorkspaces
  readonly property string filterScreenName: {
    if (!followFocusedScreen)
      return screenName;
    return focusedScreen || screenName;
  }

  property var visibleWorkspaces: []
  property var visibleSpecialWorkspaces: []

  property var selectedWindow: null
  property string selectedWindowId: ""
  property string selectedAppId: ""

  function getSelectedWindow() {
    if (!root.selectedWindowId)
      return null;
    for (var i = 0; i < CompositorService.windows.count; i++) {
      var win = CompositorService.windows.get(i);
      if (win && (win.id == root.selectedWindowId || win.address == root.selectedWindowId))
        return win;
    }
    return null;
  }

  function workspaceHasWindows(workspace, isScratchpad) {
    if (!workspace)
      return false;
    const workspaceId = isScratchpad ? (workspace.name || workspace.scratchpadName || "") : workspace.id;
    const workspaceName = isScratchpad ? (workspace.scratchpadName || workspace.name || "") : (workspace.name || workspace.id);
    if (workspaceId === "" && workspaceName === "")
      return false;
    const direct = CompositorService.getWindowsForWorkspace(workspaceId) || [];
    if (direct.length > 0)
      return true;
    for (var i = 0; i < CompositorService.windows.count; i++) {
      const win = CompositorService.windows.get(i);
      if (!win)
        continue;
      if (WorkspaceWindowMatcher.workspaceMatchesWindow(win, workspaceId, workspaceName))
        return true;
    }
    return false;
  }

  function workspaceMatchesScreen(workspace) {
    if (!workspace || !followFocusedScreen)
      return true;
    if (!workspace.output)
      return true;
    return workspace.output === filterScreenName;
  }

  function workspaceIsFocused(workspace, isScratchpad) {
    if (!workspace)
      return false;
    if (isScratchpad)
      return workspace.scratchpadName === CompositorService.activeSpecialWorkspaceName;
    return !!workspace.isFocused;
  }

  function collectVisibleWorkspaces(sourceModel, isScratchpad) {
    const collected = [];
    if (!sourceModel)
      return collected;

    for (var i = 0; i < sourceModel.count; i++) {
      const workspace = sourceModel.get(i);
      if (!workspace)
        continue;
      if (!workspaceMatchesScreen(workspace))
        continue;

      const focused = workspaceIsFocused(workspace, isScratchpad);
      const occupied = workspaceHasWindows(workspace, isScratchpad);
      if (hideUnoccupied && !focused && !occupied)
        continue;

      collected.push(workspace);
    }

    return collected;
  }

  function rebuildVisibleWorkspaces() {
    visibleWorkspaces = collectVisibleWorkspaces(localWorkspaces, false);
    visibleSpecialWorkspaces = showScratchpad ? collectVisibleWorkspaces(localSpecialWorkspaces, true) : [];
  }

  function switchByOffset(direction) {
    const normal = visibleWorkspaces;
    const special = (showScratchpad && scrollThroughScratchpads) ? visibleSpecialWorkspaces : [];
    const total = normal.length + special.length;

    if (total <= 1)
      return;

    var current = -1;
    for (var i = 0; i < normal.length; i++) {
      if (workspaceIsFocused(normal[i], false)) {
        current = i;
        break;
      }
    }

    if (current < 0 && special.length > 0) {
      for (var s = 0; s < special.length; s++) {
        if (workspaceIsFocused(special[s], true)) {
          current = normal.length + s;
          break;
        }
      }
    }

    if (current < 0)
      current = 0;

    var next = (current + direction) % total;
    if (next < 0)
      next = total - 1;

    if (next < normal.length) {
      CompositorService.switchToWorkspace(normal[next]);
    } else {
      CompositorService.switchToWorkspace(special[next - normal.length]);
    }
  }

  function handleWindowActivated(window, workspace, workspaceIsFocused) {
    if (!window)
      return;

    if (!workspaceIsFocused && workspace)
      CompositorService.switchToWorkspace(workspace);

    CompositorService.focusWindow(window);
  }

  Connections {
    target: CompositorService
    function onWorkspacesChanged() { root.rebuildVisibleWorkspaces(); }
    function onWindowListChanged() { root.rebuildVisibleWorkspaces(); }
    function onActiveSpecialWorkspaceNameChanged() { root.rebuildVisibleWorkspaces(); }
    function onSpecialWorkspacesChanged() { root.rebuildVisibleWorkspaces(); }
  }

  onScreenNameChanged: rebuildVisibleWorkspaces()
  onHideUnoccupiedChanged: rebuildVisibleWorkspaces()
  onShowScratchpadChanged: rebuildVisibleWorkspaces()
  onFollowFocusedScreenChanged: rebuildVisibleWorkspaces()
  onFocusedScreenChanged: rebuildVisibleWorkspaces()
  Component.onCompleted: rebuildVisibleWorkspaces()

  implicitWidth: isVertical ? barHeight : strip.implicitWidth
  implicitHeight: isVertical ? strip.implicitHeight : barHeight

  WorkspaceComponents.WorkspaceStrip {
    id: strip
    anchors.fill: parent
    workspaces: root.visibleWorkspaces
    scratchpadWorkspaces: root.visibleSpecialWorkspaces
    effectiveLabelMode: root.effectiveLabelMode
    characterCount: root.characterCount
    isVertical: root.isVertical
    focusedWindowId: root.focusedWindowId
    metrics: root.metrics
    capsuleHeight: root.capsuleHeight
    barFontSize: root.barFontSize
    colorizeIcons: root.colorizeIcons
    unfocusedIconsOpacity: root.unfocusedIconsOpacity
    activeSpecialWorkspaceName: CompositorService.activeSpecialWorkspaceName
    tooltipDirection: root.tooltipDirection

    onSwitchToWorkspace: ws => CompositorService.switchToWorkspace(ws)
    onWindowActivated: (window, workspace, workspaceIsFocused) => root.handleWindowActivated(window, workspace, workspaceIsFocused)
    onWindowRightClicked: (anchorItem, window, appId) => {
      root.selectedWindow = window;
      root.selectedWindowId = window && (window.id || window.address) ? (window.id || window.address).toString() : "";
      root.selectedAppId = appId;
      contextMenu.openAtItem(anchorItem);
    }
    onContextMenuRequested: (anchorItem, windowId, appId) => {
      root.selectedWindow = null;
      root.selectedWindowId = windowId;
      root.selectedAppId = appId;
      contextMenu.openAtItem(anchorItem);
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      { label: "Close Window", action: "close", icon: "x" },
      { label: I18n.tr("actions.widget-settings"), action: "widget-settings", icon: "settings" }
    ]
    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(root.screen);
      if (action === "close") {
        var win = root.selectedWindow || root.getSelectedWindow();
        if (win)
          CompositorService.closeWindow(win);
      } else if (action === "widget-settings") {
        BarService.openWidgetSettings(root.screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
      }
      root.selectedWindow = null;
      root.selectedWindowId = "";
      root.selectedAppId = "";
    }
  }

  WorkspaceComponents.WorkspaceScrollHandler {
    z: 1
    enabled: root.enableScrollWheel
    target: root
    onScrolled: direction => root.switchByOffset(direction)
  }
}
