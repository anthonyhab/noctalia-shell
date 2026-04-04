import fs from "node:fs";
import path from "node:path";

const iconPath = path.resolve("Modules/Bar/Widgets/Workspace/WorkspaceMiniAppIcon.qml");
const panelPath = path.resolve("Modules/Bar/Widgets/Workspace/WorkspaceRevealPanel.qml");
if (!fs.existsSync(iconPath)) {
  console.error("Expected Modules/Bar/Widgets/Workspace/WorkspaceMiniAppIcon.qml to exist.");
  process.exit(1);
}
if (!fs.existsSync(panelPath)) {
  console.error("Expected Modules/Bar/Widgets/Workspace/WorkspaceRevealPanel.qml to exist.");
  process.exit(1);
}

const iconFile = fs.readFileSync(iconPath, "utf8");
const panelFile = fs.readFileSync(panelPath, "utf8");

if (iconFile.includes("showAccentChip") || iconFile.includes("accentChipColor") || iconFile.includes("accentTextColor")) {
  console.error("Expected WorkspaceMiniAppIcon to stay a plain icon renderer without focused-chip chrome.");
  process.exit(1);
}

if (!iconFile.includes("layer.enabled: root.colorizeIcons")) {
  console.error("Expected WorkspaceMiniAppIcon to preserve colorize icon support.");
  process.exit(1);
}

if (!iconFile.includes("property int renderExtent")) {
  console.error("Expected WorkspaceMiniAppIcon to expose a renderExtent sized to the shell's button rhythm.");
  process.exit(1);
}

if (/Rectangle\s*\{[\s\S]{0,400}(?:Qt\.alpha\(Color\.mSurfaceVariant|Color\.mSurfaceVariant)/.test(iconFile)) {
  console.error("Expected WorkspaceMiniAppIcon to avoid boxed chrome surface treatment.");
  process.exit(1);
}

if (!panelFile.includes("id: focusedIndicator")) {
  console.error("Expected WorkspaceRevealPanel to own the shared focused-window indicator.");
  process.exit(1);
}

if (!panelFile.includes("indicatorThickness") || !panelFile.includes("indicatorWidth")) {
  console.error("Expected WorkspaceRevealPanel's focused indicator to expose its shared geometry.");
  process.exit(1);
}
