import assert from "node:assert/strict";
import { createRequire } from "node:module";
import path from "node:path";

const require = createRequire(import.meta.url);
const metrics = require(path.resolve("Modules/Bar/Widgets/Workspace/WorkspaceMetrics.js"));

assert.equal(typeof metrics.buildMetrics, "function", "Expected WorkspaceMetrics.buildMetrics to exist.");

const cases = [
  {
    name: "mini",
    input: { capsuleHeight: 19, iconScale: 1.0, marginXXS: 2, marginXS: 4, borderM: 2 },
    expected: {
      anchorWidth: 19,
      restingWidth: 19,
      pillGap: 4,
      activePanelInset: 2,
      hoverPanelInset: 2,
      drawerInset: 2,
      drawerJoinOverlap: 2,
      activePanelLeadingInset: 8,
      activePanelTrailingInset: 8,
      hoverPanelLeadingInset: 8,
      hoverPanelTrailingInset: 8,
      panelIconGap: 4,
      iconSlotExtent: 19,
      iconRenderExtent: 15,
      indicatorThickness: 2,
      indicatorWidth: 5,
      activePanelMinLength: 35,
      hoverPanelMinLength: 35,
      activeWindowCap: 6,
      hoverWindowCap: 5,
    },
  },
  {
    name: "default",
    input: { capsuleHeight: 25, iconScale: 1.0, marginXXS: 2, marginXS: 4, borderM: 2 },
    expected: {
      anchorWidth: 25,
      restingWidth: 25,
      pillGap: 4,
      activePanelInset: 2,
      hoverPanelInset: 2,
      drawerInset: 2,
      drawerJoinOverlap: 2,
      activePanelLeadingInset: 8,
      activePanelTrailingInset: 8,
      hoverPanelLeadingInset: 8,
      hoverPanelTrailingInset: 8,
      panelIconGap: 4,
      iconSlotExtent: 25,
      iconRenderExtent: 21,
      indicatorThickness: 2,
      indicatorWidth: 7,
      activePanelMinLength: 41,
      hoverPanelMinLength: 41,
      activeWindowCap: 6,
      hoverWindowCap: 5,
    },
  },
  {
    name: "comfortable",
    input: { capsuleHeight: 29, iconScale: 1.0, marginXXS: 2, marginXS: 4, borderM: 2 },
    expected: {
      anchorWidth: 29,
      restingWidth: 29,
      pillGap: 4,
      activePanelInset: 2,
      hoverPanelInset: 2,
      drawerInset: 2,
      drawerJoinOverlap: 2,
      activePanelLeadingInset: 8,
      activePanelTrailingInset: 8,
      hoverPanelLeadingInset: 8,
      hoverPanelTrailingInset: 8,
      panelIconGap: 4,
      iconSlotExtent: 29,
      iconRenderExtent: 23,
      indicatorThickness: 2,
      indicatorWidth: 7,
      activePanelMinLength: 45,
      hoverPanelMinLength: 45,
      activeWindowCap: 6,
      hoverWindowCap: 5,
    },
  },
  {
    name: "spacious",
    input: { capsuleHeight: 31, iconScale: 1.0, marginXXS: 2, marginXS: 4, borderM: 2 },
    expected: {
      anchorWidth: 31,
      restingWidth: 31,
      pillGap: 4,
      activePanelInset: 2,
      hoverPanelInset: 2,
      drawerInset: 2,
      drawerJoinOverlap: 2,
      activePanelLeadingInset: 8,
      activePanelTrailingInset: 8,
      hoverPanelLeadingInset: 8,
      hoverPanelTrailingInset: 8,
      panelIconGap: 4,
      iconSlotExtent: 31,
      iconRenderExtent: 25,
      indicatorThickness: 2,
      indicatorWidth: 7,
      activePanelMinLength: 47,
      hoverPanelMinLength: 47,
      activeWindowCap: 6,
      hoverWindowCap: 5,
    },
  },
  {
    name: "default @ 0.85x icons",
    input: { capsuleHeight: 25, iconScale: 0.85, marginXXS: 2, marginXS: 4, borderM: 2 },
    expected: {
      anchorWidth: 25,
      restingWidth: 25,
      pillGap: 4,
      activePanelInset: 2,
      hoverPanelInset: 2,
      drawerInset: 2,
      drawerJoinOverlap: 2,
      activePanelLeadingInset: 8,
      activePanelTrailingInset: 8,
      hoverPanelLeadingInset: 8,
      hoverPanelTrailingInset: 8,
      panelIconGap: 4,
      iconSlotExtent: 25,
      iconRenderExtent: 17,
      indicatorThickness: 2,
      indicatorWidth: 5,
      activePanelMinLength: 41,
      hoverPanelMinLength: 41,
      activeWindowCap: 6,
      hoverWindowCap: 5,
    },
  },
  {
    name: "tiny edge",
    input: { capsuleHeight: 1, iconScale: 1.0, marginXXS: 1, marginXS: 1, borderM: 2 },
    expected: {
      anchorWidth: 1,
      restingWidth: 1,
      pillGap: 1,
      activePanelInset: 1,
      hoverPanelInset: 1,
      drawerInset: 1,
      drawerJoinOverlap: 1,
      activePanelLeadingInset: 2,
      activePanelTrailingInset: 2,
      hoverPanelLeadingInset: 2,
      hoverPanelTrailingInset: 2,
      panelIconGap: 1,
      iconSlotExtent: 1,
      iconRenderExtent: 1,
      indicatorThickness: 2,
      indicatorWidth: 2,
      activePanelMinLength: 5,
      hoverPanelMinLength: 5,
      activeWindowCap: 6,
      hoverWindowCap: 5,
    },
  },
];

for (const testCase of cases) {
  const actual = metrics.buildMetrics(testCase.input);
  const expected = testCase.expected;

  assert.equal(actual.anchorWidth, expected.anchorWidth, `${testCase.name}: expected anchorWidth to match the approved pill geometry.`);
  assert.equal(actual.restingWidth, expected.restingWidth, `${testCase.name}: expected restingWidth to match the approved pill geometry.`);
  assert.equal(actual.pillGap, expected.pillGap, `${testCase.name}: expected pillGap to stay token-snapped.`);
  assert.equal(actual.activePanelInset, expected.activePanelInset, `${testCase.name}: expected activePanelInset to match the shared drawer join overlap.`);
  assert.equal(actual.hoverPanelInset, expected.hoverPanelInset, `${testCase.name}: expected hoverPanelInset to stay on the same drawer lattice as active.`);
  assert.equal(actual.drawerInset, expected.drawerInset, `${testCase.name}: expected drawerInset to preserve the shared drawer join geometry.`);
  assert.equal(actual.drawerJoinOverlap, expected.drawerJoinOverlap, `${testCase.name}: expected drawerJoinOverlap to preserve the trailing overlap geometry.`);
  assert.equal(actual.activePanelLeadingInset, expected.activePanelLeadingInset, `${testCase.name}: expected activePanelLeadingInset to add breathing room near the label anchor.`);
  assert.equal(actual.activePanelTrailingInset, expected.activePanelTrailingInset, `${testCase.name}: expected activePanelTrailingInset to keep the final icon from feeling clipped.`);
  assert.equal(actual.hoverPanelLeadingInset, expected.hoverPanelLeadingInset, `${testCase.name}: expected hoverPanelLeadingInset to stay compact.`);
  assert.equal(actual.hoverPanelTrailingInset, expected.hoverPanelTrailingInset, `${testCase.name}: expected hoverPanelTrailingInset to stay on the same spacing lattice.`);
  assert.equal(actual.panelIconGap, expected.panelIconGap, `${testCase.name}: expected panelIconGap to stay on the shared spacing lattice.`);
  assert.equal(actual.iconSlotExtent, expected.iconSlotExtent, `${testCase.name}: expected iconSlotExtent to match the approved values.`);
  assert.equal(actual.iconRenderExtent, expected.iconRenderExtent, `${testCase.name}: expected iconRenderExtent to match Noctalia's square-button icon rhythm.`);
  assert.equal(actual.indicatorThickness, expected.indicatorThickness, `${testCase.name}: expected indicatorThickness to stay at the approved 2px bottom rule.`);
  assert.equal(actual.indicatorWidth, expected.indicatorWidth, `${testCase.name}: expected indicatorWidth to stay smaller than the icon span.`);
  assert.equal(actual.activePanelMinLength, expected.activePanelMinLength, `${testCase.name}: expected activePanelMinLength to match the approved values.`);
  assert.equal(actual.hoverPanelMinLength, expected.hoverPanelMinLength, `${testCase.name}: expected hoverPanelMinLength to match the approved values.`);
  assert.equal(actual.activeWindowCap, expected.activeWindowCap, `${testCase.name}: expected activeWindowCap to stay at the approved limit.`);
  assert.equal(actual.hoverWindowCap, expected.hoverWindowCap, `${testCase.name}: expected hoverWindowCap to stay at the approved limit.`);
  assert.equal(actual.anchorWidth % 2, 1, `${testCase.name}: expected anchorWidth to stay odd.`);
  assert.equal(actual.iconSlotExtent % 2, 1, `${testCase.name}: expected iconSlotExtent to stay odd.`);
  assert.equal(actual.iconRenderExtent % 2, 1, `${testCase.name}: expected iconRenderExtent to stay odd.`);
  assert.equal(actual.activePanelMinLength % 2, 1, `${testCase.name}: expected activePanelMinLength to stay odd.`);
  assert.equal(actual.hoverPanelMinLength % 2, 1, `${testCase.name}: expected hoverPanelMinLength to stay odd.`);
  assert.equal(actual.pillGap, actual.panelIconGap, `${testCase.name}: expected outer rail gap and inner icon gap to share the same spacing unit.`);
  assert.equal(actual.activePanelLeadingInset, actual.activePanelTrailingInset, `${testCase.name}: expected active reveal edge padding to be uniform.`);
  assert.equal(actual.hoverPanelLeadingInset, actual.hoverPanelTrailingInset, `${testCase.name}: expected hover reveal edge padding to be uniform.`);
  assert.equal(actual.anchorWidth, actual.iconSlotExtent, `${testCase.name}: expected the label cell to use the same square cell geometry as the drawer slots.`);
  assert.ok(actual.iconRenderExtent <= actual.iconSlotExtent, `${testCase.name}: expected the icon render size to fit cleanly inside the square slot.`);
  assert.ok(actual.indicatorWidth <= Math.max(actual.iconSlotExtent, actual.indicatorThickness), `${testCase.name}: expected the shared focus indicator to stay within the visible icon cell footprint.`);
}
