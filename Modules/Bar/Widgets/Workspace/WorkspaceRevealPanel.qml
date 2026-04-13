import QtQuick
import "WorkspaceMetrics.js" as WorkspaceMetrics
import qs.Commons
import qs.Widgets

Item {
    id: root

    property bool isVertical: false
    property bool isExpanded: false
    property bool isFocused: false
    property bool isHoverPreview: false
    property Item labelAnchor
    property bool revealBehindAnchor: false
    property var metrics: ({
    })
    property real capsuleHeight: Style.capsuleHeight
    property real barFontSize: Style.barFontSize
    property var visibleWindows: []
    property int overflowCount: 0
    property string focusedWindowId: ""
    property bool colorizeIcons: false
    property real unfocusedIconsOpacity: 0.75
    property color panelSurfaceColor: "#000000"
    property color overflowSurfaceColor: "#000000"
    property color hoveredOverflowSurfaceColor: "#000000"
    property color overflowTextColor: "#ffffff"
    property color iconColor: "#ffffff"
    property color hoveredIconColor: "#ffffff"
    property color focusIndicatorColor: "#ffffff"
    property real inactiveIconOpacity: 0.78
    property string tooltipDirection: "bottom"
    readonly property int panelInset: isHoverPreview ? metrics.hoverPanelInset : metrics.activePanelInset
    readonly property int leadingInset: isHoverPreview ? metrics.hoverPanelLeadingInset : metrics.activePanelLeadingInset
    readonly property int trailingInset: isHoverPreview ? metrics.hoverPanelTrailingInset : metrics.activePanelTrailingInset
    readonly property int panelMinLength: isHoverPreview ? metrics.hoverPanelMinLength : metrics.activePanelMinLength
    readonly property int slotExtent: Math.max(1, metrics.iconSlotExtent || Style.toOdd(capsuleHeight))
    readonly property int iconRenderExtent: Math.max(1, metrics.iconRenderExtent || Style.toOdd(capsuleHeight * 0.8))
    readonly property int slotGap: Math.max(0, metrics.panelIconGap || 0)
    readonly property int contentSlots: Math.max(0, (visibleWindows ? visibleWindows.length : 0)) + (overflowCount > 0 ? 1 : 0)
    readonly property int measuredPanelLength: WorkspaceMetrics.panelLength(visibleWindows ? visibleWindows.length : 0, overflowCount, slotExtent, slotGap, leadingInset, trailingInset)
    readonly property int panelLength: Math.max(panelMinLength, measuredPanelLength)
    readonly property int targetPanelLength: isExpanded ? panelLength : 0
    readonly property int crossExtent: Math.max(1, capsuleHeight)
    readonly property int indicatorThickness: Math.max(1, metrics.indicatorThickness || 2)
    readonly property int indicatorWidth: Math.max(indicatorThickness, metrics.indicatorWidth || slotExtent)
    readonly property int focusedVisibleIndex: {
        if (!root.isFocused || !root.focusedWindowId || !root.visibleWindows)
            return -1;

        for (let i = 0; i < root.visibleWindows.length; i++) {
            const windowModel = root.visibleWindows[i];
            const windowId = windowModel && (windowModel.id !== undefined && windowModel.id !== null ? windowModel.id : windowModel.address);
            if (windowId !== undefined && windowId !== null && windowId.toString() === root.focusedWindowId)
                return i;

        }
        return -1;
    }
    readonly property real focusedIndicatorX: focusedVisibleIndex >= 0 ? leadingInset + focusedVisibleIndex * (slotExtent + slotGap) + Style.pixelAlignCenter(slotExtent, indicatorWidth) : leadingInset
    property real animatedPanelLength: 0

    signal windowActivated(var window)
    signal windowRightClicked(var window, string appId)
    signal panelHoverChanged(bool hovered)

    implicitWidth: isVertical ? crossExtent : animatedPanelLength
    implicitHeight: isVertical ? animatedPanelLength : crossExtent
    width: implicitWidth
    height: implicitHeight
    visible: isExpanded || animatedPanelLength > 0
    opacity: (isExpanded || animatedPanelLength > 0) ? 1 : 0
    onTargetPanelLengthChanged: animatedPanelLength = targetPanelLength
    Component.onCompleted: animatedPanelLength = targetPanelLength
    onVisibleChanged: {
        if (!visible)
            panelHoverChanged(false);

    }
    x: labelAnchor ? (isVertical ? (revealBehindAnchor ? labelAnchor.x : labelAnchor.x) : (revealBehindAnchor ? labelAnchor.x + labelAnchor.width - panelInset : labelAnchor.x + labelAnchor.width)) : 0
    y: labelAnchor ? (isVertical ? (revealBehindAnchor ? labelAnchor.y + labelAnchor.height - panelInset : labelAnchor.y + labelAnchor.height) : (revealBehindAnchor ? labelAnchor.y : labelAnchor.y)) : 0

    Rectangle {
        id: surface

        readonly property int bw: Style.capsuleBorderWidth

        x: root.isVertical ? bw : 0
        y: root.isVertical ? 0 : bw
        width: root.isVertical ? (parent.width - bw * 2) : (parent.width - bw)
        height: root.isVertical ? (parent.height - bw) : (parent.height - bw * 2)
        radius: Style.nestedRadius(Math.min(Style.radiusM, Math.max(1, root.crossExtent / 2)), bw)
        color: root.panelSurfaceColor
        border.color: "transparent"
        border.width: 0
        clip: true

        Component {
            id: windowSlotDelegate

            Item {
                required property var modelData

                width: root.slotExtent
                height: root.slotExtent

                WorkspaceMiniAppIcon {
                    anchors.centerIn: parent
                    slotExtent: root.slotExtent
                    renderExtent: root.iconRenderExtent
                    windowModel: modelData
                    unfocusedIconsOpacity: root.unfocusedIconsOpacity
                    iconOpacity: isFocusedWindow ? 1 : root.inactiveIconOpacity
                    colorizeIcons: root.colorizeIcons
                    iconColor: root.iconColor
                    hoveredIconColor: root.hoveredIconColor
                    tooltipDirection: root.tooltipDirection
                    iconSource: {
                        const appId = modelData && modelData.appId ? modelData.appId.toString() : "";
                        let icon = ThemeIcons.iconForAppId(appId);
                        if ((!icon || icon.length === 0) && appId.length > 0)
                            icon = ThemeIcons.iconForAppId(appId.toLowerCase());

                        if (!icon || icon.length === 0)
                            icon = ThemeIcons.iconFromName("application-x-executable");

                        return icon;
                    }
                    onClicked: (window) => {
                        return root.windowActivated(window);
                    }
                    onRightClicked: (window, appId) => {
                        return root.windowRightClicked(window, appId);
                    }
                }

            }

        }

        Component {
            id: overflowChipDelegate

            Item {
                width: root.slotExtent
                height: root.slotExtent

                Rectangle {
                    id: overflowChip

                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: Math.min(Style.radiusS, height / 2)
                    color: mouseArea.containsMouse ? root.hoveredOverflowSurfaceColor : root.overflowSurfaceColor
                    border.color: "transparent"
                    border.width: 0
                    scale: mouseArea.pressed ? 0.94 : (mouseArea.containsMouse ? 1.05 : 1)

                    Text {
                        anchors.centerIn: parent
                        text: "+" + root.overflowCount
                        color: root.overflowTextColor
                        font.pointSize: Math.max(Style.fontSizeXXS, root.barFontSize * 0.86)
                        font.weight: Style.fontWeightBold

                        Behavior on color {
                            enabled: !Color.isTransitioning

                            ColorAnimation {
                                duration: Style.animationFast
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                    Behavior on color {
                        enabled: !Color.isTransitioning

                        ColorAnimation {
                            duration: Style.animationFast
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Style.animationFast
                            easing.type: Easing.OutCubic
                        }

                    }

                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                }

            }

        }

        Row {
            id: horizontalContent

            visible: !root.isVertical
            x: root.leadingInset
            y: Style.pixelAlignCenter(parent.height, height)
            spacing: root.slotGap

            Repeater {
                model: root.visibleWindows
                delegate: windowSlotDelegate
            }

            Loader {
                visible: root.overflowCount > 0
                active: visible
                sourceComponent: overflowChipDelegate
            }

        }

        Column {
            id: verticalContent

            visible: root.isVertical
            x: Style.pixelAlignCenter(parent.width, width)
            y: root.leadingInset
            spacing: root.slotGap

            Repeater {
                model: root.visibleWindows
                delegate: windowSlotDelegate
            }

            Loader {
                visible: root.overflowCount > 0
                active: visible
                sourceComponent: overflowChipDelegate
            }

        }

        Rectangle {
            id: focusedIndicator

            property int indicatorThickness: root.indicatorThickness
            property int indicatorWidth: root.indicatorWidth
            property string indicatorRole: "primary"

            visible: root.isFocused && root.focusedVisibleIndex >= 0
            x: root.isVertical ? parent.width - root.indicatorThickness : root.focusedIndicatorX
            y: root.isVertical ? root.focusedIndicatorX : parent.height - root.indicatorThickness
            width: root.isVertical ? root.indicatorThickness : root.indicatorWidth
            height: root.isVertical ? root.indicatorWidth : root.indicatorThickness
            radius: root.indicatorThickness / 2
            color: root.focusIndicatorColor
            opacity: visible ? 1 : 0

            Behavior on x {
                NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.OutCubic
                }

            }

            Behavior on y {
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

        }

        Behavior on color {
            enabled: !Color.isTransitioning

            ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }

        }

    }

    HoverHandler {
        enabled: root.isExpanded
        onHoveredChanged: root.panelHoverChanged(hovered)
    }

    Behavior on animatedPanelLength {
        NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }

    }

}
