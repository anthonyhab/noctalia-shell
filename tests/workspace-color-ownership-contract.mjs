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

const files = {
  pill: readContract("Modules/Bar/Widgets/Workspace/WorkspacePill.qml"),
  panel: readContract("Modules/Bar/Widgets/Workspace/WorkspaceRevealPanel.qml"),
  icon: readContract("Modules/Bar/Widgets/Workspace/WorkspaceMiniAppIcon.qml"),
  anchor: readContract("Modules/Bar/Widgets/Workspace/WorkspaceLabelAnchor.qml"),
};

function expectIncludes(fileName, fileText, needle, message) {
  if (!fileText.includes(needle)) {
    console.error(`Expected ${fileName} to ${message}.`);
    process.exit(1);
  }
}

expectIncludes("WorkspacePill.qml", files.pill, "\"WorkspaceColors.js\" as WorkspaceColors", "import the shared workspace color helper");
expectIncludes("WorkspacePill.qml", files.pill, "readonly property var colorPalette", "own the resolved workspace color palette");
expectIncludes("WorkspacePill.qml", files.pill, "WorkspaceColors.buildPalette", "resolve colors through the shared helper");
expectIncludes("WorkspacePill.qml", files.pill, "\"surface\": Color.mSurface", "pass the shell surface into the workspace color helper");

expectIncludes("WorkspaceLabelAnchor.qml", files.anchor, "property color textColor", "accept explicit text color from the pill");
if (files.anchor.includes("Color.mOnPrimary")) {
  console.error("Expected WorkspaceLabelAnchor.qml to stop hardcoding active label colors.");
  process.exit(1);
}

expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property color panelSurfaceColor", "accept explicit panel surface color");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property color overflowSurfaceColor", "accept explicit overflow surface color");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property color overflowTextColor", "accept explicit overflow text color");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property color iconColor", "accept explicit icon foreground color");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property color hoveredIconColor", "accept explicit hover icon foreground color");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property color focusIndicatorColor", "accept explicit focused-indicator color");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "unfocusedIconsOpacity: root.unfocusedIconsOpacity", "respect the caller-owned unfocused icon opacity");

expectIncludes("WorkspaceMiniAppIcon.qml", files.icon, "property color iconColor", "accept explicit icon foreground color");
expectIncludes("WorkspaceMiniAppIcon.qml", files.icon, "property color hoveredIconColor", "accept explicit hover icon foreground color");

if (/Color\.mHover|Color\.mOnHover|Color\.mOnSurface|Color\.mOnPrimary/.test(files.icon)) {
  console.error("Expected WorkspaceMiniAppIcon.qml to stop hardcoding shell color tokens locally.");
  process.exit(1);
}

if (files.panel.includes("accentChipColor") || files.panel.includes("accentTextColor")) {
  console.error("Expected WorkspaceRevealPanel.qml to stop owning focused-chip colors.");
  process.exit(1);
}
