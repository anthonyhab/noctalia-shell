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
};

function expectIncludes(fileName, fileText, needle, message) {
  if (!fileText.includes(needle)) {
    console.error(`Expected ${fileName} to ${message}.`);
    process.exit(1);
  }
}

expectIncludes("WorkspacePill.qml", files.pill, "WorkspaceLabelAnchor", "use WorkspaceLabelAnchor");
expectIncludes("WorkspacePill.qml", files.pill, "WorkspaceRevealPanel", "use WorkspaceRevealPanel");
expectIncludes("WorkspacePill.qml", files.pill, "property alias labelAnchor", "expose the labelAnchor alias");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property Item labelAnchor", "accept labelAnchor as an input property");
expectIncludes("WorkspacePill.qml", files.pill, "labelAnchor: labelAnchor", "forward the labelAnchor reference into the reveal panel");

expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property bool isHoverPreview", "expose isHoverPreview");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property bool revealBehindAnchor", "expose revealBehindAnchor");
expectIncludes("WorkspacePill.qml", files.pill, "revealBehindAnchor: true", "forward revealBehindAnchor explicitly");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property int panelInset", "expose panelInset");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property int panelMinLength", "expose panelMinLength");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property real activePanelOpacity", "expose activePanelOpacity");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property real hoverPreviewOpacity", "expose hoverPreviewOpacity");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property real panelOpacity", "expose panelOpacity");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property bool hoverPreviewIsShorter", "expose hoverPreviewIsShorter");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property bool hoverPreviewIsLighter", "expose hoverPreviewIsLighter");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "hoverPreviewIsShorter: panelMinLength === metrics.hoverPanelMinLength && metrics.hoverPanelMinLength < metrics.activePanelMinLength", "encode hover preview as shorter than active");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "hoverPreviewIsLighter: panelOpacity === hoverPreviewOpacity && hoverPreviewOpacity < activePanelOpacity", "encode hover preview as lighter than active");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "panelOpacity: isHoverPreview ? hoverPreviewOpacity : activePanelOpacity", "select a lighter hover opacity than active");

if (files.pill.includes("WorkspaceCapsule") || files.panel.includes("WorkspaceCapsule")) {
  console.error("Expected the new live path to stop depending on the old WorkspaceCapsule surface ownership.");
  process.exit(1);
}
