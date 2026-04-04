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
  strip: readContract("Modules/Bar/Widgets/Workspace/WorkspaceStrip.qml"),
  pill: readContract("Modules/Bar/Widgets/Workspace/WorkspacePill.qml"),
  panel: readContract("Modules/Bar/Widgets/Workspace/WorkspaceRevealPanel.qml"),
  anchor: readContract("Modules/Bar/Widgets/Workspace/WorkspaceLabelAnchor.qml"),
};

function expectIncludes(fileName, fileText, needle, message) {
  if (!fileText.includes(needle)) {
    console.error(`Expected ${fileName} to ${message}.`);
    process.exit(1);
  }
}

expectIncludes("WorkspaceStrip.qml", files.strip, "WorkspacePill", "render WorkspacePill delegates");
expectIncludes("WorkspacePill.qml", files.pill, "WorkspaceLabelAnchor", "use WorkspaceLabelAnchor");
expectIncludes("WorkspacePill.qml", files.pill, "WorkspaceRevealPanel", "use WorkspaceRevealPanel");
expectIncludes("WorkspacePill.qml", files.pill, "property alias labelAnchor", "expose the labelAnchor alias");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property Item labelAnchor", "accept labelAnchor as an input property");
expectIncludes("WorkspacePill.qml", files.pill, "labelAnchor: labelAnchor", "forward the labelAnchor reference into the reveal panel");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "property bool revealBehindAnchor", "expose revealBehindAnchor");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property bool hoverPreviewIsShorter", "expose hoverPreviewIsShorter");
expectIncludes("WorkspaceRevealPanel.qml", files.panel, "readonly property bool hoverPreviewIsLighter", "expose hoverPreviewIsLighter");

if (files.strip.includes("WorkspaceCapsule") || files.pill.includes("WorkspaceCapsule") || files.panel.includes("WorkspaceCapsule") || files.anchor.includes("WorkspaceCapsule")) {
  console.error("Expected the hierarchy contract to stop depending on old WorkspaceCapsule internals.");
  process.exit(1);
}
