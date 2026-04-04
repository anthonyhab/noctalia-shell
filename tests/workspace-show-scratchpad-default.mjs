import fs from "node:fs";

const workspaceWidgetPath = new URL("../Modules/Bar/Widgets/Workspace.qml", import.meta.url);
const registryPath = new URL("../Services/UI/BarWidgetRegistry.qml", import.meta.url);

const workspaceWidget = fs.readFileSync(workspaceWidgetPath, "utf8");
const registry = fs.readFileSync(registryPath, "utf8");

if (!workspaceWidget.includes('readonly property bool showScratchpad:') || !workspaceWidget.includes('(widgetMetadata.showScratchpad || true)')) {
  console.error("Expected Workspace widget fallback default for showScratchpad to be true.");
  process.exit(1);
}

if (workspaceWidget.includes('return widgets[sectionWidgetIndex].settings || {};')) {
  console.error("Expected Workspace widget to read saved widget settings from the widget entry, not a nested .settings object.");
  process.exit(1);
}

if (!registry.includes('"showScratchpad": true')) {
  console.error("Expected Workspace widget metadata default showScratchpad to be true.");
  process.exit(1);
}
