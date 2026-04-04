import fs from "node:fs";
import path from "node:path";

const workspacePath = path.resolve("Modules/Bar/Widgets/Workspace.qml");
const compositorPath = path.resolve("Services/Compositor/CompositorService.qml");
const hyprlandPath = path.resolve("Services/Compositor/HyprlandService.qml");

const workspace = fs.readFileSync(workspacePath, "utf8");
const compositor = fs.readFileSync(compositorPath, "utf8");
const hyprland = fs.readFileSync(hyprlandPath, "utf8");

if (!compositor.includes("property string focusedScreen:")) {
  console.error("Expected CompositorService to expose a reactive focusedScreen property.");
  process.exit(1);
}

if (!compositor.includes("function updateFocusedScreen()")) {
  console.error("Expected CompositorService to centralize focused-screen refreshes.");
  process.exit(1);
}

if (!compositor.includes("const nextFocusedScreen = getFocusedScreen();")) {
  console.error("Expected CompositorService to normalize the backend focused-screen result before storing it.");
  process.exit(1);
}

const focusedScreenNormalizationNeedles = [
  "if (typeof nextFocusedScreen === \"string\")",
  "focusedScreen = nextFocusedScreen;",
  "if (nextFocusedScreen && typeof nextFocusedScreen === \"object\" && nextFocusedScreen.name)",
  "focusedScreen = nextFocusedScreen.name;",
  "focusedScreen = \"\";",
];

for (const needle of focusedScreenNormalizationNeedles) {
  if (!compositor.includes(needle)) {
    console.error(`Expected CompositorService.updateFocusedScreen() to normalize focused-screen values: ${needle}`);
    process.exit(1);
  }
}

if (!compositor.includes("if (backend.focusedScreenChanged)")) {
  console.error("Expected CompositorService to subscribe to a dedicated backend focusedScreenChanged signal when available.");
  process.exit(1);
}

if (!compositor.includes("backend.focusedScreenChanged.connect(() => {\n        updateFocusedScreen();\n      });")) {
  console.error("Expected CompositorService to refresh focusedScreen directly from the backend focusedScreenChanged signal.");
  process.exit(1);
}

const focusedScreenRefreshSites = [
  "syncWorkspaces();\n      updateFocusedScreen();",
  "syncFocusedWindow();\n                                          updateFocusedScreen();",
  "syncWindows();\n                                        updateFocusedScreen();",
  "syncWorkspaces();\n    syncWindows();\n    updateFocusedScreen();",
];

for (const needle of focusedScreenRefreshSites) {
  if (!compositor.includes(needle)) {
    console.error(`Expected CompositorService to refresh focusedScreen after backend state changes: ${needle}`);
    process.exit(1);
  }
}

if (!workspace.includes("readonly property string focusedScreen: CompositorService.focusedScreen")) {
  console.error("Expected Workspace.qml to bind a reactive focusedScreen property from CompositorService.");
  process.exit(1);
}

if (!workspace.includes("return focusedScreen || screenName;")) {
  console.error("Expected Workspace.qml to derive filterScreenName from the reactive focusedScreen binding.");
  process.exit(1);
}

if (workspace.includes("CompositorService.getFocusedScreen()")) {
  console.error("Expected Workspace.qml to stop using the non-reactive CompositorService.getFocusedScreen() binding path.");
  process.exit(1);
}

if (!workspace.includes("onFocusedScreenChanged: rebuildVisibleWorkspaces()")) {
  console.error("Expected Workspace.qml to rebuild visible workspaces when focusedScreen changes.");
  process.exit(1);
}

if (!hyprland.includes("signal focusedScreenChanged")) {
  console.error("Expected HyprlandService to expose a dedicated focusedScreenChanged signal.");
  process.exit(1);
}

if (!hyprland.includes("ignoreUnknownSignals: true")) {
  console.error("Expected HyprlandService focused-monitor connection to ignore unknown signals safely.");
  process.exit(1);
}

if (!hyprland.includes("function onFocusedMonitorChanged()")) {
  console.error("Expected HyprlandService to react to Hyprland focused-monitor changes.");
  process.exit(1);
}

if (!hyprland.includes("focusedScreenChanged();")) {
  console.error("Expected HyprlandService to emit focusedScreenChanged when the focused monitor changes.");
  process.exit(1);
}
