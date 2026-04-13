import QtQuick
import "WorkspaceColors.js" as WorkspaceColors
import "WorkspaceMetrics.js" as WorkspaceMetrics
import "WorkspaceWindowMatcher.js" as WorkspaceWindowMatcher
import "WorkspaceWindowSource.js" as WorkspaceWindowSource
import qs.Commons
import qs.Services.Compositor
import qs.Widgets

Item {
    id: root

    property var workspaceModel
    property string workspaceId: ""
    property string labelMode: "index"
    property int characterCount: 3
    property bool isVertical: false
    property bool isScratchpad: false
    property string activeSpecialWorkspaceName: ""
    property var metrics: ({
    })
    property real capsuleHeight: Style.capsuleHeight
    property real barFontSize: Style.barFontSize
    property string focusedWindowId: ""
    property bool colorizeIcons: false
    property real unfocusedIconsOpacity: 0.75
    property string hoveredWorkspaceId: ""
    property string tooltipDirection: "bottom"
    property alias labelAnchor: labelAnchor
    property bool labelHovered: false
    property bool panelHovered: false
    property bool hoverExpanded: false
    property var workspaceWindows: []
    property bool hasWorkspaceWindows: false
    readonly property bool isFocused: {
        if (!workspaceModel)
            return false;

        if (isScratchpad)
            return workspaceModel.scratchpadName === activeSpecialWorkspaceName;

        if (activeSpecialWorkspaceName !== "")
            return false;

        return !!workspaceModel.isFocused;
    }
    readonly property string workspaceName: WorkspaceWindowSource.deriveWorkspaceName(workspaceModel, isScratchpad)
    readonly property var liveWorkspaceId: WorkspaceWindowSource.resolveLiveWorkspaceId(workspaceModel, workspaceId, isScratchpad)
    readonly property bool isExpanded: hasWorkspaceWindows && (isFocused || hoverExpanded)
    readonly property bool isHoverPreview: hoverExpanded && !isFocused
    readonly property bool itemHovered: labelHovered || panelHovered
    readonly property int windowCap: isFocused ? (metrics.activeWindowCap || 6) : (metrics.hoverWindowCap || 5)
    readonly property int anchorMainExtent: Math.max(capsuleHeight, metrics.anchorWidth || capsuleHeight)
    readonly property var visibleWindows: isExpanded ? WorkspaceMetrics.visibleItems(workspaceWindows, windowCap) : []
    readonly property int overflowCount: isExpanded ? WorkspaceMetrics.overflowCount(workspaceWindows, windowCap) : 0
    property var displayedWindows: []
    property int displayedOverflowCount: 0
    readonly property int revealInset: isHoverPreview ? (metrics.hoverPanelInset || Style.marginXXS) : (metrics.activePanelInset || Style.marginXXS)
    readonly property int panelLeadingInset: isHoverPreview ? (metrics.hoverPanelLeadingInset || Style.marginXS) : (metrics.activePanelLeadingInset || Style.marginXS)
    readonly property int panelTrailingInset: isHoverPreview ? (metrics.hoverPanelTrailingInset || Style.marginXS) : (metrics.activePanelTrailingInset || Style.marginXS)
    readonly property int panelMinLength: isHoverPreview ? (metrics.hoverPanelMinLength || Style.toOdd(capsuleHeight + Style.marginXS * 2)) : (metrics.activePanelMinLength || Style.toOdd(capsuleHeight + Style.marginXS * 2))
    readonly property int panelSlotExtent: Math.max(1, metrics.iconSlotExtent || Style.toOdd(capsuleHeight))
    readonly property int panelGap: Math.max(0, metrics.panelIconGap || 0)
    readonly property int panelLength: isExpanded ? Math.max(panelMinLength, WorkspaceMetrics.panelLength(visibleWindows.length, overflowCount, panelSlotExtent, panelGap, panelLeadingInset, panelTrailingInset)) : 0
    readonly property int labelMainExtent: anchorMainExtent
    readonly property int pillMainExtent: isExpanded ? WorkspaceMetrics.pillMainLength(labelMainExtent, visibleWindows.length, overflowCount, panelSlotExtent, panelGap, panelLeadingInset, panelTrailingInset, revealInset) : Math.max(capsuleHeight, labelMainExtent)
    readonly property var colorPalette: WorkspaceColors.buildPalette({
        "darkMode": Settings.data.colorSchemes.darkMode,
        "translucentWidgets": Settings.data.ui.translucentWidgets,
        "panelBackgroundOpacity": Settings.data.ui.panelBackgroundOpacity,
        "showCapsule": Settings.data.bar.showCapsule,
        "capsuleOpacity": Settings.data.bar.capsuleOpacity,
        "capsuleColorKey": Settings.data.bar.capsuleColorKey,
        "capsuleColor": Style.capsuleColor,
        "capsuleBorderColor": Style.capsuleBorderColor,
        "primary": Color.mPrimary,
        "onPrimary": Color.mOnPrimary,
        "hover": Color.mHover,
        "onHover": Color.mOnHover,
        "surface": Color.mSurface,
        "surfaceVariant": Color.mSurfaceVariant,
        "onSurface": Color.mOnSurface,
        "onSurfaceVariant": Color.mOnSurfaceVariant,
        "outline": Color.mOutline
    })
    readonly property color shellColor: {
        if (isFocused)
            return colorPalette.activeShellFill;

        if (isHoverPreview)
            return colorPalette.hoverShellFill;

        if (hasWorkspaceWindows)
            return colorPalette.occupiedShellFill;

        return colorPalette.emptyShellFill;
    }
    readonly property color shellBorderColor: {
        if (isFocused)
            return colorPalette.activeShellBorder;

        if (isHoverPreview)
            return colorPalette.hoverShellBorder;

        if (hasWorkspaceWindows)
            return colorPalette.occupiedShellBorder;

        return colorPalette.emptyShellBorder;
    }
    readonly property color labelSurfaceColor: {
        if (isFocused)
            return colorPalette.anchorFill;

        if (labelHovered || isHoverPreview)
            return colorPalette.hoverAnchorFill;

        if (hasWorkspaceWindows)
            return colorPalette.occupiedAnchorFill;

        return colorPalette.emptyAnchorFill;
    }
    readonly property color labelTextColor: {
        if (isFocused)
            return colorPalette.anchorText;

        if (labelHovered || isHoverPreview)
            return colorPalette.hoverAnchorText;

        if (hasWorkspaceWindows)
            return colorPalette.occupiedAnchorText;

        return colorPalette.emptyAnchorText;
    }
    readonly property color revealPanelSurfaceColor: isFocused ? colorPalette.panelFill : colorPalette.hoverPanelFill
    readonly property color revealPanelOverflowFill: isFocused ? colorPalette.activeOverflowFill : colorPalette.hoverOverflowFill
    readonly property color revealPanelHoveredOverflowFill: isFocused ? colorPalette.panelFill : colorPalette.activeOverflowFill
    readonly property color revealPanelOverflowText: isFocused ? colorPalette.activeOverflowText : colorPalette.hoverOverflowText
    readonly property real revealPanelInactiveIconOpacity: isFocused ? Math.min(unfocusedIconsOpacity, 0.78) : Math.min(unfocusedIconsOpacity, 0.68)

    signal switchToWorkspace(var workspace)
    signal windowActivated(var window, var workspace, bool workspaceIsFocused)
    signal windowRightClicked(var anchorItem, var window, string appId)
    signal contextMenuRequested(var anchorItem, string windowId, string appId)
    signal hoverActivated(var workspaceId)

    function snapshotWindows(windows) {
        var result = [];
        for (var i = 0; i < windows.length; i++) {
            var w = windows[i];
            if (!w)
                continue;

            result.push({
                "id": w.id !== undefined && w.id !== null ? w.id : "",
                "address": w.address || "",
                "appId": w.appId || "",
                "title": w.title || ""
            });
        }
        return result;
    }

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

    function rebuildVisibleWindows() {
        const source = workspaceModel && workspaceModel.windows ? workspaceModel.windows : null;
        const sourceCount = modelCount(source);
        if (sourceCount > 0) {
            const sourceWindows = [];
            for (var i = 0; i < sourceCount; i++) {
                const win = modelItem(source, i);
                if (win)
                    sourceWindows.push(win);

            }
            workspaceWindows = sourceWindows;
            hasWorkspaceWindows = sourceWindows.length > 0;
            return ;
        }
        const nextWindows = [];
        const rawWindows = CompositorService.getWindowsForWorkspace(liveWorkspaceId) || [];
        for (var j = 0; j < rawWindows.length; j++) {
            const win = rawWindows[j];
            if (win)
                nextWindows.push(win);

        }
        if (nextWindows.length === 0 && (liveWorkspaceId !== "" || workspaceName !== "")) {
            for (var k = 0; k < CompositorService.windows.count; k++) {
                const candidate = CompositorService.windows.get(k);
                if (!candidate)
                    continue;

                if (WorkspaceWindowMatcher.workspaceMatchesWindow(candidate, liveWorkspaceId, workspaceName))
                    nextWindows.push(candidate);

            }
        }
        workspaceWindows = nextWindows;
        hasWorkspaceWindows = nextWindows.length > 0;
    }

    function requestHoverExpansion(active) {
        if (!hasWorkspaceWindows || isFocused) {
            expandTimer.stop();
            collapseTimer.stop();
            hoverExpanded = false;
            hoverActivated("");
            return ;
        }
        if (active) {
            if (hoveredWorkspaceId !== "" && hoveredWorkspaceId !== workspaceId) {
                expandTimer.stop();
                return ;
            }
            collapseTimer.stop();
            expandTimer.restart();
        } else {
            expandTimer.stop();
            collapseTimer.restart();
        }
    }

    function activateWindow(window) {
        if (window)
            root.windowActivated(window, root.workspaceModel, root.isFocused);

    }

    function isFocusedWindow(window) {
        if (!window || !root.focusedWindowId)
            return false;

        const windowId = window.id !== undefined && window.id !== null ? window.id : window.address;
        return windowId !== undefined && windowId !== null && windowId.toString() === root.focusedWindowId;
    }

    implicitWidth: isVertical ? capsuleHeight : pillMainExtent
    implicitHeight: isVertical ? pillMainExtent : capsuleHeight
    width: implicitWidth
    height: implicitHeight
    z: isFocused ? 4 : (hoverExpanded ? 3 : (hasWorkspaceWindows ? 2 : 1))
    onHoveredWorkspaceIdChanged: {
        if (hoveredWorkspaceId !== "" && hoveredWorkspaceId !== workspaceId) {
            expandTimer.stop();
            collapseTimer.stop();
            labelHovered = false;
            panelHovered = false;
            hoverExpanded = false;
        } else if (hoveredWorkspaceId === "" && itemHovered) {
            requestHoverExpansion(true);
        }
    }
    onWorkspaceModelChanged: rebuildVisibleWindows()
    onWorkspaceIdChanged: rebuildVisibleWindows()
    onLiveWorkspaceIdChanged: rebuildVisibleWindows()
    onWorkspaceNameChanged: rebuildVisibleWindows()
    onIsFocusedChanged: {
        if (isFocused) {
            hoverExpanded = false;
            expandTimer.stop();
            collapseTimer.stop();
            panelHovered = false;
            if (hoveredWorkspaceId === workspaceId)
                hoverActivated("");

        }
    }
    onItemHoveredChanged: requestHoverExpansion(itemHovered)
    onIsExpandedChanged: {
        if (isExpanded) {
            displayClearTimer.stop();
            displayedWindows = snapshotWindows(visibleWindows);
            displayedOverflowCount = overflowCount;
        } else {
            displayClearTimer.restart();
        }
    }
    onVisibleWindowsChanged: {
        if (isExpanded && visibleWindows.length > 0) {
            displayedWindows = snapshotWindows(visibleWindows);
            displayedOverflowCount = overflowCount;
        }
    }
    Component.onCompleted: rebuildVisibleWindows()
    Component.onDestruction: {
        if (hoveredWorkspaceId === workspaceId)
            hoverActivated("");

    }

    Connections {
        function onWindowListChanged() {
            root.rebuildVisibleWindows();
        }

        target: CompositorService
    }

    Connections {
        function onCountChanged() {
            root.rebuildVisibleWindows();
        }

        function onDataChanged() {
            root.rebuildVisibleWindows();
        }

        function onModelReset() {
            root.rebuildVisibleWindows();
        }

        target: root.workspaceModel && root.workspaceModel.windows && root.workspaceModel.windows.count !== undefined ? root.workspaceModel.windows : null
        ignoreUnknownSignals: true
    }

    Timer {
        id: expandTimer

        interval: Style.animationFaster
        repeat: false
        onTriggered: {
            const ownsHover = root.hoveredWorkspaceId === "" || root.hoveredWorkspaceId === root.workspaceId;
            if (!root.isFocused && root.hasWorkspaceWindows && root.itemHovered && ownsHover) {
                root.hoverExpanded = true;
                root.hoverActivated(root.workspaceId);
            }
        }
    }

    Timer {
        id: collapseTimer

        interval: Math.max(1, Style.animationFaster)
        repeat: false
        onTriggered: {
            root.panelHovered = false;
            root.hoverExpanded = false;
            if (root.hoveredWorkspaceId === root.workspaceId)
                root.hoverActivated("");

        }
    }

    Timer {
        id: displayClearTimer

        interval: Style.animationNormal + 50
        repeat: false
        onTriggered: {
            if (!root.isExpanded) {
                root.displayedWindows = [];
                root.displayedOverflowCount = 0;
            }
        }
    }

    Rectangle {
        id: shell

        anchors.fill: parent
        radius: Math.min(Style.radiusM, capsuleHeight / 2)
        color: root.shellColor
        border.width: 0

        Behavior on color {
            enabled: !Color.isTransitioning

            ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }

        }

    }

    Item {
        id: labelAnchor

        z: 2
        implicitWidth: root.isVertical ? root.capsuleHeight : root.anchorMainExtent
        implicitHeight: root.isVertical ? root.anchorMainExtent : root.capsuleHeight
        width: implicitWidth
        height: implicitHeight

        Rectangle {
            id: labelSurface

            readonly property int bw: Style.capsuleBorderWidth

            x: bw
            y: bw
            width: parent.width - bw * 2
            height: parent.height - bw * 2
            radius: Style.nestedRadius(Math.min(Style.radiusM, root.capsuleHeight / 2), bw)
            color: root.labelSurfaceColor
            border.width: 0

            Behavior on color {
                enabled: !Color.isTransitioning

                ColorAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

        WorkspaceLabelAnchor {
            id: labelAnchorText

            anchors.centerIn: parent
            workspaceModel: root.workspaceModel
            isFocused: root.isFocused
            labelMode: root.labelMode
            characterCount: root.characterCount
            workspaceId: root.workspaceId
            isScratchpad: root.isScratchpad
            textColor: root.labelTextColor
            capsuleHeight: root.capsuleHeight
            barFontSize: root.barFontSize
            spacingUnit: root.metrics.spacingUnit || Style.marginXXS
        }

        MouseArea {
            id: labelMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onEntered: root.labelHovered = true
            onExited: root.labelHovered = false
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton)
                    root.switchToWorkspace(root.workspaceModel);

                if (mouse.button === Qt.RightButton)
                    root.contextMenuRequested(labelAnchor, "", "");

            }
        }

    }

    WorkspaceRevealPanel {
        id: revealPanel

        z: 1
        isVertical: root.isVertical
        isExpanded: root.isExpanded
        isFocused: root.isFocused
        isHoverPreview: root.isHoverPreview
        labelAnchor: labelAnchor
        revealBehindAnchor: true
        metrics: root.metrics
        capsuleHeight: root.capsuleHeight
        barFontSize: root.barFontSize
        visibleWindows: root.displayedWindows
        overflowCount: root.displayedOverflowCount
        focusedWindowId: root.focusedWindowId
        colorizeIcons: root.colorizeIcons
        unfocusedIconsOpacity: root.unfocusedIconsOpacity
        panelSurfaceColor: root.revealPanelSurfaceColor
        overflowSurfaceColor: root.revealPanelOverflowFill
        hoveredOverflowSurfaceColor: root.revealPanelHoveredOverflowFill
        overflowTextColor: root.revealPanelOverflowText
        iconColor: root.colorPalette.panelIconColor
        hoveredIconColor: root.colorPalette.hoveredIconColor
        focusIndicatorColor: root.colorPalette.focusIndicatorColor
        inactiveIconOpacity: root.revealPanelInactiveIconOpacity
        tooltipDirection: root.tooltipDirection
        onPanelHoverChanged: (hovered) => {
            return root.panelHovered = hovered;
        }
        onWindowActivated: (window) => {
            return root.activateWindow(window);
        }
        onWindowRightClicked: (window, appId) => {
            return root.windowRightClicked(labelAnchor, window, appId);
        }
    }

    Rectangle {
        id: borderOverlay

        z: 5
        anchors.fill: parent
        color: "transparent"
        radius: Math.min(Style.radiusM, capsuleHeight / 2)
        border.color: root.shellBorderColor
        border.width: Style.capsuleBorderWidth

        Behavior on border.color {
            enabled: !Color.isTransitioning

            ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }

        }

    }

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

}
