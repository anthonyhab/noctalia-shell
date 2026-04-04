import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const repoRoot = path.resolve(".");
const harnessPath = path.join(repoRoot, "tests/qml/WorkspacePillRuntimeHarness.qml");
const workspaceDir = path.join(repoRoot, "Modules/Bar/Widgets/Workspace");

if (!fs.existsSync(harnessPath)) {
  console.error(`Expected runtime harness at ${harnessPath}.`);
  process.exit(1);
}

const configDir = fs.mkdtempSync(path.join(os.tmpdir(), "workspace-pill-runtime-config-"));
const runtimeDir = fs.mkdtempSync(path.join(os.tmpdir(), "workspace-pill-runtime-"));
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

linkDir("Modules/Bar/Widgets/Workspace", workspaceDir);
ensureDir("tests/qml");
fs.copyFileSync(harnessPath, path.join(configDir, "tests/qml/WorkspacePillRuntimeHarness.qml"));

writeFile("shell.qml", `
import QtQuick
import Quickshell
import "./tests/qml" as RuntimeHarness

ShellRoot {
  RuntimeHarness.WorkspacePillRuntimeHarness {}
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
  readonly property real fontSizeXXS: 8
  readonly property int fontWeightMedium: 500
  readonly property int fontWeightBold: 700
  readonly property int animationFaster: 25
  readonly property int animationFast: 0
  readonly property int animationNormal: 0
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

writeFile("Services/Compositor/CompositorService.qml", `pragma Singleton
import QtQuick
import Quickshell

Singleton {
  property ListModel windows: ListModel {}
  signal windowListChanged()
  function getWindowsForWorkspace(workspaceId) {
    return [];
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
  "WORKSPACE_RUNTIME_PASS inactive_rest_visible_windows",
  "WORKSPACE_RUNTIME_PASS inactive_rest_overflow_count",
  "WORKSPACE_RUNTIME_PASS inactive_rest_pill_compact",
  "WORKSPACE_RUNTIME_PASS inactive_rest_panel_hidden",
  "WORKSPACE_RUNTIME_PASS hover_preview_has_windows",
  "WORKSPACE_RUNTIME_PASS hover_preview_expands_extent",
  "WORKSPACE_RUNTIME_PASS hover_preview_panel_length_positive",
  "WORKSPACE_RUNTIME_PASS hover_preview_reveals_panel",
  "WORKSPACE_RUNTIME_PASS hover_preview_uniform_edge_padding",
  "WORKSPACE_RUNTIME_PASS active_expansion_increases_extent",
  "WORKSPACE_RUNTIME_PASS active_expansion_panel_length_positive",
  "WORKSPACE_RUNTIME_PASS active_expansion_reveals_panel",
  "WORKSPACE_RUNTIME_PASS active_panel_uniform_edge_padding",
  "WORKSPACE_RUNTIME_PASS anchor_matches_square_slot_rhythm",
  "WORKSPACE_RUNTIME_PASS active_drawer_uses_visual_gap_insets",
  "WORKSPACE_RUNTIME_PASS drawer_icon_uses_button_rhythm",
  "WORKSPACE_RUNTIME_PASS active_anchor_uses_primary_role",
  "WORKSPACE_RUNTIME_PASS anchor_padding_matches_spacing_unit",
  "WORKSPACE_RUNTIME_PASS active_label_uses_on_primary_role",
  "WORKSPACE_RUNTIME_PASS shared_bottom_indicator_present",
  "WORKSPACE_RUNTIME_PASS shared_bottom_indicator_thickness",
  "WORKSPACE_RUNTIME_PASS shared_bottom_indicator_width",
  "WORKSPACE_RUNTIME_PASS shared_bottom_indicator_primary_role",
  "WORKSPACE_RUNTIME_PASS shared_bottom_indicator_visible",
  "WORKSPACE_RUNTIME_PASS collapsed_panel_length_resets",
  "WORKSPACE_RUNTIME_PASS collapsed_panel_hides",
  "WORKSPACE_RUNTIME_PASS anchor_width_short_label",
  "WORKSPACE_RUNTIME_PASS anchor_width_long_label",
  "WORKSPACE_RUNTIME_PASS anchor_width_stable",
  "WORKSPACE_RUNTIME_PASS anchor_width_matches_square_cell",
  "WORKSPACE_RUNTIME_PASS label_text_constrained_to_anchor",
  "WORKSPACE_RUNTIME_PASS label_text_elides_cleanly",
  "WORKSPACE_RUNTIME_PASS scratchpad_effective_focus",
  "WORKSPACE_RUNTIME_PASS scratchpad_anchor_focus",
  "WORKSPACE_RUNTIME_PASS scratchpad_font_weight",
  "WORKSPACE_RUNTIME_PASS scratchpad_label_color",
  "WORKSPACE_RUNTIME_PASS hover_ownership_change_keeps_compact_state",
  "WORKSPACE_RUNTIME_PASS hover_ownership_change_blocks_activation",
  "WORKSPACE_RUNTIME_PASS reveal_hover_panel_found",
  "WORKSPACE_RUNTIME_PASS label_hover_expands_preview",
  "WORKSPACE_RUNTIME_PASS reveal_hover_claims_item_hover",
  "WORKSPACE_RUNTIME_PASS reveal_hover_keeps_preview_open",
  "WORKSPACE_RUNTIME_PASS reveal_hover_release_collapses_preview",
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
