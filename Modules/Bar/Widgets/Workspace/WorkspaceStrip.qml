import QtQuick
import qs.Commons
import qs.Widgets
import "WorkspaceStripNormalization.js" as WorkspaceStripNormalization

Item {
  id: root

  property var workspaces
  property var scratchpadWorkspaces
  property string effectiveLabelMode
  property int characterCount
  property bool isVertical
  property string focusedWindowId
  property var metrics
  property real capsuleHeight
  property real barFontSize
  property bool colorizeIcons
  property real unfocusedIconsOpacity
  property string activeSpecialWorkspaceName
  property string hoveredWorkspaceId: ""
  property string tooltipDirection: "bottom"

  property var normalizedWorkspaces: []

  function modelCount(model) {
    if (!model)
      return 0;
    if (Array.isArray(model))
      return model.length;
    if (model.count !== undefined)
      return model.count;
    if (model.length !== undefined)
      return model.length;
    return 0;
  }

  function modelItem(model, index) {
    if (!model)
      return null;
    if (Array.isArray(model))
      return model[index];
    if (model.get)
      return model.get(index);
    return model[index];
  }

  function rebuildNormalizedWorkspaces() {
    const regular = [];
    const scratchpads = [];
    const regularCount = modelCount(workspaces);
    const scratchpadCount = modelCount(scratchpadWorkspaces);

    for (var i = 0; i < regularCount; i++) {
      const workspace = modelItem(workspaces, i);
      if (!workspace)
        continue;
      regular.push({
                   "workspaceModel": workspace,
                   "workspaceId": WorkspaceStripNormalization.resolveWorkspaceId(workspace, false),
                   "isScratchpad": false,
                   "orderIndex": i,
                   "activeSpecialWorkspaceName": root.activeSpecialWorkspaceName,
                 });
    }

    for (var j = 0; j < scratchpadCount; j++) {
      const scratchpad = modelItem(scratchpadWorkspaces, j);
      if (!scratchpad)
        continue;
      scratchpads.push({
                         "workspaceModel": scratchpad,
                         "workspaceId": WorkspaceStripNormalization.resolveWorkspaceId(scratchpad, true),
                         "isScratchpad": true,
                         "orderIndex": j,
                         "activeSpecialWorkspaceName": root.activeSpecialWorkspaceName,
                       });
    }

    normalizedWorkspaces = regular.concat(scratchpads);
  }

  onWorkspacesChanged: rebuildNormalizedWorkspaces()
  onScratchpadWorkspacesChanged: rebuildNormalizedWorkspaces()
  onActiveSpecialWorkspaceNameChanged: rebuildNormalizedWorkspaces()
  Component.onCompleted: rebuildNormalizedWorkspaces()

  implicitWidth: root.isVertical ? verticalStrip.implicitWidth : horizontalStrip.implicitWidth
  implicitHeight: root.isVertical ? verticalStrip.implicitHeight : horizontalStrip.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Component {
    id: workspacePillDelegate

    WorkspacePill {
      required property var modelData
      workspaceModel: modelData.workspaceModel
      workspaceId: modelData.workspaceId
      labelMode: root.effectiveLabelMode
      characterCount: root.characterCount
      isScratchpad: modelData.isScratchpad
      activeSpecialWorkspaceName: modelData.activeSpecialWorkspaceName
      isVertical: root.isVertical
      focusedWindowId: root.focusedWindowId
      metrics: root.metrics
      capsuleHeight: root.capsuleHeight
      barFontSize: root.barFontSize
      colorizeIcons: root.colorizeIcons
      unfocusedIconsOpacity: root.unfocusedIconsOpacity
      hoveredWorkspaceId: root.hoveredWorkspaceId
      tooltipDirection: root.tooltipDirection
      onWidthChanged: {
        if (!root.isVertical)
          horizontalStrip.forceLayout();
      }
      onHeightChanged: {
        if (root.isVertical)
          verticalStrip.forceLayout();
      }
      onSwitchToWorkspace: workspace => root.switchToWorkspace(workspace)
      onWindowActivated: (window, workspace, workspaceIsFocused) => root.windowActivated(window, workspace, workspaceIsFocused)
      onWindowRightClicked: (anchorItem, window, appId) => root.windowRightClicked(anchorItem, window, appId)
      onContextMenuRequested: (anchorItem, windowId, appId) => root.contextMenuRequested(anchorItem, windowId, appId)
      onHoverActivated: workspaceId => root.hoveredWorkspaceId = workspaceId || ""
    }
  }

  Row {
    id: horizontalStrip
    visible: !root.isVertical
    spacing: root.metrics.pillGap
    y: Style.pixelAlignCenter(parent.height, height)

    Repeater {
      model: root.isVertical ? [] : root.normalizedWorkspaces
      delegate: workspacePillDelegate
    }
  }

  Column {
    id: verticalStrip
    visible: root.isVertical
    spacing: root.metrics.pillGap
    x: Style.pixelAlignCenter(parent.width, width)

    Repeater {
      model: root.isVertical ? root.normalizedWorkspaces : []
      delegate: workspacePillDelegate
    }
  }

  signal switchToWorkspace(var workspace)
  signal windowActivated(var window, var workspace, bool workspaceIsFocused)
  signal windowRightClicked(var anchorItem, var window, string appId)
  signal contextMenuRequested(var anchorItem, string windowId, string appId)
}
