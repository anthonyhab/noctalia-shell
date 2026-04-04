import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const helperPath = path.resolve("Modules/Bar/Widgets/Workspace/WorkspaceColors.js");

if (!fs.existsSync(helperPath)) {
  console.error("Expected Modules/Bar/Widgets/Workspace/WorkspaceColors.js to exist.");
  process.exit(1);
}

const workspaceColors = require(helperPath);

assert.equal(typeof workspaceColors.buildPalette, "function", "Expected WorkspaceColors.buildPalette to exist.");
assert.equal(typeof workspaceColors.pickReadableForeground, "function", "Expected WorkspaceColors.pickReadableForeground to exist.");
assert.equal(typeof workspaceColors.contrastRatio, "function", "Expected WorkspaceColors.contrastRatio to exist.");

function hexToRgba(color) {
  const normalized = color.toLowerCase().trim();
  if (!/^#([0-9a-f]{6}|[0-9a-f]{8})$/.test(normalized)) {
    throw new Error(`Unsupported color format in contract: ${color}`);
  }
  if (normalized.length === 7) {
    return {
      r: parseInt(normalized.slice(1, 3), 16),
      g: parseInt(normalized.slice(3, 5), 16),
      b: parseInt(normalized.slice(5, 7), 16),
      a: 1,
    };
  }
  return {
    a: parseInt(normalized.slice(1, 3), 16) / 255,
    r: parseInt(normalized.slice(3, 5), 16),
    g: parseInt(normalized.slice(5, 7), 16),
    b: parseInt(normalized.slice(7, 9), 16),
  };
}

function alphaOf(color) {
  return hexToRgba(color).a;
}

function normalizeHex(color) {
  return color.toLowerCase();
}

const darkHover = "#9bfece";
const lightHover = "#67d5a5";

const darkPalette = workspaceColors.buildPalette({
  darkMode: true,
  translucentWidgets: true,
  panelBackgroundOpacity: 0.9,
  showCapsule: true,
  capsuleOpacity: 1,
  capsuleColorKey: "none",
  capsuleColor: "#11112d",
  capsuleBorderColor: "#21215f",
  primary: "#fff59b",
  onPrimary: "#0e0e43",
  hover: darkHover,
  onHover: "#0e0e43",
  surface: "#090911",
  surfaceVariant: "#11112d",
  onSurface: "#f3edf7",
  onSurfaceVariant: "#7c80b4",
  outline: "#21215f",
});

assert.equal(normalizeHex(darkPalette.anchorFill), "#fff59b", "Expected the active anchor to use the shell primary role.");
assert.equal(normalizeHex(darkPalette.anchorText), "#0e0e43", "Expected the active anchor text to prefer the readable on-primary role.");
assert.equal(normalizeHex(darkPalette.focusIndicatorColor), "#fff59b", "Expected the focus indicator to stay in the primary role.");
assert.notEqual(normalizeHex(darkPalette.panelFill), normalizeHex(darkPalette.anchorFill), "Expected the reveal panel to stay in the same family as the active anchor without becoming the same solid accent block.");
assert.ok(workspaceColors.contrastRatio("#090911", darkPalette.panelFill, "#090911") > workspaceColors.contrastRatio("#090911", darkPalette.hoverPanelFill, "#090911"), "Expected the hover drawer to stay weaker than the active drawer.");
assert.ok(workspaceColors.contrastRatio(darkPalette.anchorFill, darkPalette.anchorText, "#090911") >= 4.5, "Expected active anchor contrast to stay readable.");
assert.ok(workspaceColors.contrastRatio(darkPalette.panelFill, darkPalette.panelIconColor, "#090911") >= 4.5, "Expected reveal-panel icon contrast to stay readable.");
assert.notEqual(normalizeHex(darkPalette.panelFill), normalizeHex(darkPalette.hoverPanelFill), "Expected active and hover panel fills to differ by strength even when they share the same accent family.");
assert.notEqual(normalizeHex(darkPalette.hoverAnchorFill), normalizeHex(darkHover), "Expected mHover to stay outside the active accent family.");
assert.notEqual(normalizeHex(darkPalette.hoverPanelFill), normalizeHex(darkHover), "Expected mHover to stay outside the active drawer family.");

const lightPalette = workspaceColors.buildPalette({
  darkMode: false,
  translucentWidgets: true,
  panelBackgroundOpacity: 0.9,
  showCapsule: true,
  capsuleOpacity: 1,
  capsuleColorKey: "none",
  capsuleColor: "#f2effc",
  capsuleBorderColor: "#d0caef",
  primary: "#5b4ee7",
  onPrimary: "#ffffff",
  hover: lightHover,
  onHover: "#0f1a22",
  surface: "#fcf8ff",
  surfaceVariant: "#e8e3f7",
  onSurface: "#151327",
  onSurfaceVariant: "#4c4868",
  outline: "#c1b9e7",
});

assert.equal(normalizeHex(lightPalette.anchorFill), "#5b4ee7", "Expected the active anchor to stay primary-led in light mode.");
assert.equal(normalizeHex(lightPalette.focusIndicatorColor), "#5b4ee7", "Expected the focus indicator to stay primary-led in light mode.");
assert.ok(alphaOf(lightPalette.panelFill) < alphaOf(darkPalette.panelFill), "Expected light-mode neutral surfaces to become more transparent than dark mode.");
assert.ok(workspaceColors.contrastRatio(lightPalette.anchorFill, lightPalette.anchorText, "#fcf8ff") >= 4.5, "Expected light-mode active anchor contrast to stay readable.");
assert.ok(workspaceColors.contrastRatio(lightPalette.panelFill, lightPalette.panelIconColor, "#fcf8ff") >= 4.5, "Expected light-mode reveal-panel icon contrast to stay readable.");
assert.notEqual(normalizeHex(lightPalette.hoverAnchorFill), normalizeHex(lightHover), "Expected light-mode mHover to stay separate from the active accent family.");
assert.notEqual(normalizeHex(lightPalette.hoverPanelFill), normalizeHex(lightHover), "Expected light-mode mHover to stay separate from the active drawer family.");

const accentCapsulePalette = workspaceColors.buildPalette({
  darkMode: true,
  translucentWidgets: true,
  panelBackgroundOpacity: 0.9,
  showCapsule: true,
  capsuleOpacity: 1,
  capsuleColorKey: "primary",
  capsuleColor: "#fff59b",
  capsuleBorderColor: "#21215f",
  primary: "#fff59b",
  onPrimary: "#0e0e43",
  hover: "#9bfece",
  onHover: "#0e0e43",
  surface: "#090911",
  surfaceVariant: "#11112d",
  onSurface: "#f3edf7",
  onSurfaceVariant: "#7c80b4",
  outline: "#21215f",
});

assert.notEqual(normalizeHex(accentCapsulePalette.panelFill), normalizeHex(accentCapsulePalette.anchorFill), "Expected the reveal panel to stay visually distinct even when the bar capsule uses an accent color.");
assert.ok(workspaceColors.contrastRatio(accentCapsulePalette.panelFill, accentCapsulePalette.panelIconColor, "#090911") >= 4.5, "Expected accent-colored bar capsules to keep readable reveal-panel icons.");

const lowOpacityPalette = workspaceColors.buildPalette({
  darkMode: true,
  translucentWidgets: true,
  panelBackgroundOpacity: 0.9,
  showCapsule: true,
  capsuleOpacity: 0.35,
  capsuleColorKey: "none",
  capsuleColor: "#11112d",
  capsuleBorderColor: "#21215f",
  primary: "#fff59b",
  onPrimary: "#0e0e43",
  hover: "#9bfece",
  onHover: "#0e0e43",
  surface: "#090911",
  surfaceVariant: "#11112d",
  onSurface: "#f3edf7",
  onSurfaceVariant: "#7c80b4",
  outline: "#21215f",
});

assert.notEqual(normalizeHex(lowOpacityPalette.occupiedShellFill), normalizeHex(darkPalette.occupiedShellFill), "Expected capsule opacity to influence the neutral workspace surfaces.");
