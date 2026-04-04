import fs from "node:fs";
import path from "node:path";

function readContract(relativePath) {
  const filePath = path.resolve(relativePath);
  if (!fs.existsSync(filePath)) {
    console.error(`Expected ${relativePath} to exist.`);
    process.exit(1);
  }
  return fs.readFileSync(filePath, "utf8");
}

function expectIncludes(fileName, fileText, needle, message) {
  if (!fileText.includes(needle)) {
    console.error(`Expected ${fileName} to ${message}.`);
    process.exit(1);
  }
}

const pill = readContract("Modules/Bar/Widgets/Workspace/WorkspacePill.qml");
const panel = readContract("Modules/Bar/Widgets/Workspace/WorkspaceRevealPanel.qml");
const strip = readContract("Modules/Bar/Widgets/Workspace/WorkspaceStrip.qml");

expectIncludes("WorkspacePill.qml", pill, "property bool labelHovered: false", "track label hover separately");
expectIncludes("WorkspacePill.qml", pill, "property bool panelHovered: false", "track reveal hover separately");
expectIncludes("WorkspacePill.qml", pill, "readonly property bool itemHovered: labelHovered || panelHovered", "treat the full pill surface as hovered");
expectIncludes("WorkspacePill.qml", pill, "readonly property int panelLeadingInset", "keep the reveal join geometry split across leading and trailing insets");
expectIncludes("WorkspacePill.qml", pill, "readonly property int panelTrailingInset", "keep the reveal join geometry split across leading and trailing insets");
expectIncludes("WorkspacePill.qml", pill, "readonly property int pillMainExtent", "derive pill width from the drawer geometry");
expectIncludes("WorkspacePill.qml", pill, "WorkspaceMetrics.pillMainLength", "grow the drawer using the shared metrics helper");
expectIncludes("WorkspacePill.qml", pill, "hoverExpanded", "allow inactive hover previews to participate in drawer expansion");
expectIncludes("WorkspacePill.qml", pill, "onHoveredWorkspaceIdChanged: {", "clear hover ownership when another workspace takes the hover");
expectIncludes("WorkspacePill.qml", pill, "panelHovered = false;", "reset reveal hover ownership when another workspace takes the hover");
expectIncludes("WorkspaceRevealPanel.qml", panel, "signal panelHoverChanged(bool hovered)", "emit reveal-surface hover ownership changes");
expectIncludes("WorkspaceRevealPanel.qml", panel, "acceptedButtons: Qt.NoButton", "use a hover-only surface for reveal ownership");
expectIncludes("WorkspaceStrip.qml", strip, "property string hoveredWorkspaceId", "own the strip-level hover lock");
expectIncludes("WorkspaceStrip.qml", strip, "onHoverActivated: workspaceId => root.hoveredWorkspaceId = workspaceId || \"\"", "route hover ownership back into the strip");
