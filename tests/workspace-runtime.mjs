import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const repoRoot = path.resolve(".");
const harnessPath = path.join(repoRoot, "tests/qml/WorkspaceRuntimeHarness.qml");
const widgetsDir = path.join(repoRoot, "Modules/Bar/Widgets");

if (!fs.existsSync(harnessPath)) {
  console.error(`Expected runtime harness at ${harnessPath}.`);
  process.exit(1);
}

const configDir = fs.mkdtempSync(path.join(os.tmpdir(), "workspace-runtime-config-"));
const runtimeDir = fs.mkdtempSync(path.join(os.tmpdir(), "workspace-runtime-"));
fs.chmodSync(runtimeDir, 0o700);

function ensureDir(relativePath) {
  fs.mkdirSync(path.join(configDir, relativePath), { recursive: true });
}

function linkDir(relativePath, targetPath) {
  const linkPath = path.join(configDir, relativePath);
  fs.mkdirSync(path.dirname(linkPath), { recursive: true });
  fs.symlinkSync(targetPath, linkPath, "dir");
}

function writeFile(relativePath, content) {
  const filePath = path.join(configDir, relativePath);
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content);
}

linkDir("Modules/Bar/Widgets", widgetsDir);
ensureDir("tests/qml");
fs.copyFileSync(harnessPath, path.join(configDir, "tests/qml/WorkspaceRuntimeHarness.qml"));

writeFile("shell.qml", `
import QtQuick
import Quickshell
import "./tests/qml" as RuntimeHarness

ShellRoot {
  RuntimeHarness.WorkspaceRuntimeHarness {}
}
`);

writeFile("Commons/Style.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  readonly property int capsuleHeight: 25
  readonly property int barFontSize: 11
  readonly property int radiusS: 6
  readonly property int radiusM: 12
  readonly property int borderS: 1
  readonly property int capsuleBorderWidth: 1
  readonly property color capsuleColor: "#242424"
  readonly property color capsuleBorderColor: "#7f7f7f"
  readonly property int marginXXS: 2
  readonly property int marginXS: 4
  readonly property int marginS: 6
  readonly property int marginL: 12
  readonly property int margin2M: 16
  readonly property real fontSizeXXS: 8
  readonly property int fontWeightMedium: 500
  readonly property int fontWeightBold: 700
  readonly property int animationFaster: 25
  readonly property int animationFast: 0
  readonly property int animationNormal: 0
  readonly property real iconScaleRatio: 1.0
  function getCapsuleHeightForScreen(screenName) {
    return capsuleHeight;
  }
  function getBarFontSizeForScreen(screenName) {
    return barFontSize;
  }
  function pixelAlignCenter(containerSize, contentSize) {
    return Math.round((containerSize - contentSize) / 2);
  }
  function toOdd(n) {
    return Math.floor(n / 2) * 2 + 1;
  }
}
`);

writeFile("Commons/Color.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  readonly property color mPrimary: "#fff59b"
  readonly property color mSecondary: "#ffb34d"
  readonly property color mHover: "#9BFECE"
  readonly property color mOnHover: "#0e0e43"
  readonly property color mSurface: "#090911"
  readonly property color mSurfaceVariant: "#383838"
  readonly property color mOnSurface: "#f5f5f5"
  readonly property color mOnSurfaceVariant: "#d2d2d2"
  readonly property color mOnPrimary: "#0e0e43"
  readonly property color mOutline: "#808080"
  function smartAlpha(baseColor, minAlpha) {
    const target = Math.max(0, Math.min(1, minAlpha === undefined ? 0.4 : minAlpha));
    return Qt.alpha(baseColor, Math.max(baseColor.a || 1, target));
  }
}
`);

writeFile("Commons/Settings.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  property var data: ({
    "ui": {
      "fontFixed": "Sans Serif",
      "fontDefault": "Sans Serif",
      "fontFixedScale": 1,
      "fontDefaultScale": 1,
      "translucentWidgets": true,
      "panelBackgroundOpacity": 0.9
    },
    "bar": {
      "showCapsule": true,
      "capsuleOpacity": 1,
      "capsuleColorKey": "none",
      "showOutline": true,
      "widgetOutlineColorKey": "none"
    },
    "colorSchemes": {
      "darkMode": true
    }
  })

  function getBarWidgetsForScreen(screenName) {
    return {
      "left": [],
      "center": [],
      "right": [],
    };
  }
}
`);

writeFile("Commons/ThemeIcons.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  function iconForAppId(appId) {
    return "";
  }
  function iconFromName(name) {
    return "";
  }
}
`);

writeFile("Commons/I18n.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  function tr(key) {
    return key;
  }
}
`);

writeFile("Widgets/NText.qml", `import QtQuick
import qs.Commons

Text {
  id: root
  property string family: Settings.data.ui.fontDefault
  property real pointSize: Style.fontSizeXXS
  property bool applyUiScale: false
  property var features: ({})
  font.family: root.family
  font.pointSize: root.pointSize
  font.weight: Style.fontWeightMedium
  font.features: root.features
  color: Color.mOnSurface
}
`);

writeFile("Widgets/NPopupContextMenu.qml", `import QtQuick

QtObject {
  id: root
  property var model: []
  signal triggered(string action)
  function openAtItem(item) {
  }
  function close() {
  }
}
`);

writeFile("Services/Compositor/CompositorService.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  property ListModel workspaces: ListModel {}
  property ListModel specialWorkspaces: ListModel {}
  property ListModel windows: ListModel {}
  property string activeSpecialWorkspaceName: ""
  property string focusedWindowId: ""
  property string focusedScreen: ""

  signal windowListChanged()

  function getWindowsForWorkspace(workspaceId) {
    const matches = [];
    for (let i = 0; i < windows.count; i++) {
      const window = windows.get(i);
      if (window && window.workspaceId == workspaceId)
        matches.push(window);
    }
    return matches;
  }

  function switchToWorkspace(workspace) {
  }

  function focusWindow(window) {
  }

  function closeWindow(window) {
  }
}
`);

writeFile("Services/UI/BarService.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  function getTooltipDirection(screenName) {
    return true;
  }

  function openWidgetSettings(screen, section, index, widgetId, widgetSettings) {
  }
}
`);

writeFile("Services/UI/BarWidgetRegistry.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  property var widgetMetadata: ({
    "Workspace": {
      "labelMode": "index",
      "characterCount": 2,
      "hideUnoccupied": false,
      "followFocusedScreen": false,
      "showScratchpad": true,
      "colorizeIcons": false,
      "unfocusedIconsOpacity": 0.75,
      "enableScrollWheel": true,
      "scrollThroughScratchpads": false,
      "iconScale": 1.0
    }
  })
}
`);

writeFile("Services/UI/TooltipService.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  function show(anchorItem, text, direction) {
  }

  function hide() {
  }
}
`);

writeFile("Services/UI/PanelService.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  function closeContextMenu(screen) {
  }
}
`);

writeFile("Modules/MainScreen/Backgrounds/ShellGeometryPolicy.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  function barConfig(screenName) {
    return {
      "position": "top",
      "isVertical": false,
      "barHeight": 25,
      "marginHorizontal": 0,
    };
  }
}
`);

const result = spawnSync("qs", ["-p", configDir], {
  cwd: repoRoot,
  encoding: "utf8",
  env: {
    ...process.env,
    XDG_RUNTIME_DIR: runtimeDir,
    QT_QPA_PLATFORM: "offscreen",
  },
});

const output = `${result.stdout || ""}${result.stderr || ""}`;
process.stdout.write(output);

const requiredMarkers = [
  "WORKSPACE_RUNTIME_PASS workspace_bar_height_resolves",
  "WORKSPACE_RUNTIME_PASS workspace_geometry_orientation_resolves",
  "WORKSPACE_RUNTIME_PASS workspace_initial_visible_count",
  "WORKSPACE_RUNTIME_PASS workspace_reset_visible_count",
  "WORKSPACE_RUNTIME_PASS workspace_reset_updates_first_id",
  "WORKSPACE_RUNTIME_RESULT PASS",
];

if (output.includes("WORKSPACE_RUNTIME_FAIL")) {
  console.error("Runtime harness reported a FAIL marker.");
  process.exit(1);
}

for (const marker of requiredMarkers) {
  if (!output.includes(marker)) {
    console.error(`Missing runtime marker: ${marker}`);
    process.exit(1);
  }
}

if (result.error && !(result.error.code === "EPERM" && output.includes("WORKSPACE_RUNTIME_RESULT PASS"))) {
  console.error(result.error);
  process.exit(1);
}

if (result.status !== 0 && result.status !== null) {
  console.error(`Runtime harness exited with status ${result.status}.`);
  process.exit(1);
}
