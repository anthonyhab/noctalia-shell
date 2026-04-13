import QtQuick
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var workspaceModel
    property bool isFocused: false
    property string labelMode: "index"
    property int characterCount: 3
    property string workspaceId: ""
    property bool isScratchpad: false
    property color textColor: "#ffffff"
    property real capsuleHeight: Style.capsuleHeight
    property real barFontSize: Style.barFontSize
    property int spacingUnit: Style.marginXXS
    readonly property string labelText: {
        if (!workspaceModel)
            return "";

        if (isScratchpad && workspaceModel.scratchpadLabel)
            return workspaceModel.scratchpadLabel.toString();

        const idx = workspaceModel.idx !== undefined ? workspaceModel.idx.toString() : "";
        const name = workspaceModel.name ? workspaceModel.name.toString().substring(0, characterCount) : "";
        if (labelMode === "name")
            return name;

        if (labelMode === "index+name" && name.length > 0)
            return idx.length > 0 ? idx + " " + name : name;

        return idx;
    }
    readonly property int horizontalPadding: Math.max(0, spacingUnit)

    clip: true
    implicitWidth: Math.max(1, Style.toOdd(capsuleHeight))
    implicitHeight: capsuleHeight
    width: parent ? parent.width : implicitWidth
    height: capsuleHeight

    NText {
        id: label

        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        text: root.labelText
        family: Settings.data.ui.fontFixed
        pointSize: root.barFontSize
        applyUiScale: false
        font.weight: root.isFocused ? Style.fontWeightBold : Style.fontWeightMedium
        color: root.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        clip: true
        features: ({
            "tnum": 1
        })

        Behavior on color {
            enabled: !Color.isTransitioning

            ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }

        }

    }

}
