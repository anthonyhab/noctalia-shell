import fs from "node:fs";
import path from "node:path";

const settingsPath = path.resolve("Modules/Panels/Settings/Bar/WidgetSettings/WorkspaceSettings.qml");
const settingsFile = fs.readFileSync(settingsPath, "utf8");

const legacyNeedles = [
  "show-applications-label",
  "show-applications-hover-label",
  "active-indicator-style-label",
  "grouped-border-opacity-label",
  "show-labels-only-when-occupied-label",
];

for (const needle of legacyNeedles) {
  if (settingsFile.includes(needle)) {
    console.error(`Expected workspace settings UI to hide legacy grouped-mode control: ${needle}`);
    process.exit(1);
  }
}

if (!settingsFile.includes("show-scratchpad-label")) {
  console.error("Expected workspace settings UI to keep scratchpad visibility control.");
  process.exit(1);
}
