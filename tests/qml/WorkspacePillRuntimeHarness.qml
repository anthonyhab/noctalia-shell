import QtQuick
import "../../Modules/Bar/Widgets/Workspace" as WorkspaceComponents
import "../../Modules/Bar/Widgets/Workspace/WorkspaceMetrics.js" as WorkspaceMetrics

Item {
  id: root

  property var metrics: WorkspaceMetrics.buildMetrics({
    "capsuleHeight": 25,
    "iconScale": 1.0,
    "marginXXS": 2,
    "marginXS": 4,
  })
  property bool failed: false

  Component {
    id: workspacePillComponent
    WorkspaceComponents.WorkspacePill {
    }
  }

  Component {
    id: oneshotTimerComponent
    Timer {
      property var callback
      repeat: false
      onTriggered: {
        if (callback)
          callback();
        destroy();
      }
    }
  }

  function sampleWindows(count) {
    const windows = [];
    for (let i = 0; i < count; i++) {
      windows.push({
        "id": `window-${i}`,
        "address": `0x${i + 1}`,
        "appId": `app-${i}`,
        "title": `Window ${i}`,
      });
    }
    return windows;
  }

  function createPill(overrides) {
    const properties = {
      "workspaceId": "1",
      "workspaceModel": {
        "id": 1,
        "idx": 1,
        "name": "one",
        "isFocused": false,
        "windows": sampleWindows(3),
      },
      "metrics": root.metrics,
      "capsuleHeight": root.metrics.capsuleHeight,
      "barFontSize": 11,
      "hoveredWorkspaceId": "",
      "colorizeIcons": false,
    };

    for (const key in overrides)
      properties[key] = overrides[key];

    return workspacePillComponent.createObject(root, properties);
  }

  function findDescendant(item, predicate) {
    if (!item)
      return null;

    if (predicate(item))
      return item;

    const children = item.children || [];
    for (let i = 0; i < children.length; i++) {
      const match = findDescendant(children[i], predicate);
      if (match)
        return match;
    }

    return null;
  }

  function revealPanelFor(pill) {
    return findDescendant(pill, candidate => candidate !== pill && candidate.contentSlots !== undefined && candidate.panelLength !== undefined);
  }

  function sharedBottomIndicatorFor(panel) {
    return findDescendant(panel, candidate => candidate !== panel && candidate.indicatorThickness !== undefined && candidate.indicatorWidth !== undefined);
  }

  function labelAnchorComponentFor(pill) {
    return findDescendant(pill, candidate => candidate !== pill && candidate.labelText !== undefined && candidate.horizontalPadding !== undefined);
  }

  function labelTextFor(anchorComponent) {
    return findDescendant(anchorComponent, candidate => candidate !== anchorComponent && candidate.text !== undefined && candidate.font !== undefined);
  }

  function miniAppIconFor(panel) {
    return findDescendant(panel, candidate => candidate !== panel && candidate.renderExtent !== undefined && candidate.slotExtent !== undefined && candidate.iconSource !== undefined);
  }

  function fail(name, details) {
    failed = true;
    console.log("WORKSPACE_RUNTIME_FAIL", name, details || "");
  }

  function pass(name) {
    console.log("WORKSPACE_RUNTIME_PASS", name);
  }

  function expectTrue(name, value, details) {
    if (!value)
      fail(name, details || `expected truthy value but got ${value}`);
    else
      pass(name);
  }

  function expectEqual(name, actual, expected) {
    if (actual !== expected)
      fail(name, `expected ${expected} but got ${actual}`);
    else
      pass(name);
  }

  function wait(delay, callback) {
    oneshotTimerComponent.createObject(root, {
      "interval": delay,
      "callback": callback,
    }).start();
  }

  function testOccupiedInactiveRestAndHoverExpansion() {
    const pill = createPill({
      "workspaceModel": {
        "id": 1,
        "idx": 1,
        "name": "alpha",
        "isFocused": false,
        "windows": sampleWindows(6),
      },
    });
    const panel = revealPanelFor(pill);

    expectTrue("panel_found", panel !== null, "reveal panel should exist");
    expectEqual("inactive_rest_visible_windows", pill.visibleWindows.length, 0);
    expectEqual("inactive_rest_overflow_count", pill.overflowCount, 0);
    expectEqual("inactive_rest_pill_compact", pill.pillMainExtent, pill.labelMainExtent);
    expectEqual("inactive_rest_panel_hidden", panel ? panel.visible : false, false);

    pill.hoverExpanded = true;

    expectTrue("hover_preview_has_windows", pill.visibleWindows.length > 0, "hover preview should expose visible windows");
    expectTrue("hover_preview_expands_extent", pill.pillMainExtent > pill.labelMainExtent, "hover preview should widen the pill from the trailing edge");
    expectTrue("hover_preview_panel_length_positive", panel ? panel.animatedPanelLength > 0 : false, "hover preview should animate panel length open");
    expectEqual("hover_preview_reveals_panel", panel ? panel.visible : false, true);
    expectEqual("hover_preview_uniform_edge_padding", panel ? panel.trailingInset : -1, panel ? panel.leadingInset : -2);

    pill.hoverExpanded = false;
    expectEqual("collapsed_panel_hides", panel ? panel.visible : true, false);
    expectEqual("collapsed_panel_length_resets", panel ? panel.animatedPanelLength : -1, 0);

    const activePill = createPill({
      "workspaceId": "2",
      "focusedWindowId": "window-0",
      "workspaceModel": {
        "id": 2,
        "idx": 2,
        "name": "beta",
        "isFocused": true,
        "windows": sampleWindows(2),
      },
    });
    const activePanel = revealPanelFor(activePill);
    const sharedIndicator = sharedBottomIndicatorFor(activePanel);
    const activeMiniAppIcon = miniAppIconFor(activePanel);

    expectTrue("active_expansion_increases_extent", activePill.pillMainExtent > activePill.labelMainExtent, "active pill should allocate reveal extent");
    expectTrue("active_expansion_panel_length_positive", activePanel ? activePanel.animatedPanelLength > 0 : false, "active pill should animate panel length open");
    expectEqual("active_expansion_reveals_panel", activePanel ? activePanel.visible : false, true);
    expectTrue("shared_bottom_indicator_present", sharedIndicator !== null, "active reveal should own a shared bottom indicator");
    expectEqual("shared_bottom_indicator_thickness", sharedIndicator ? sharedIndicator.indicatorThickness : -1, 2);
    expectEqual("shared_bottom_indicator_width", sharedIndicator ? sharedIndicator.indicatorWidth : -1, root.metrics.indicatorWidth);
    expectEqual("shared_bottom_indicator_primary_role", sharedIndicator ? sharedIndicator.indicatorRole : "", "primary");
    expectEqual("shared_bottom_indicator_visible", sharedIndicator ? sharedIndicator.visible : false, true);
    expectEqual("active_panel_uniform_edge_padding", activePanel ? activePanel.trailingInset : -1, activePanel ? activePanel.leadingInset : -2);
    expectEqual("anchor_matches_square_slot_rhythm", activePanel ? activePill.labelMainExtent : -1, activePanel ? activePanel.slotExtent : -2);
    expectEqual("active_drawer_uses_visual_gap_insets", activePanel ? activePanel.leadingInset : -1, root.metrics.activePanelLeadingInset);
    expectEqual("drawer_icon_uses_button_rhythm", activeMiniAppIcon ? activeMiniAppIcon.renderExtent : -1, root.metrics.iconRenderExtent);
    expectEqual("active_anchor_uses_primary_role", activePill.labelSurfaceColor ? activePill.labelSurfaceColor.toString() : "", "#fff59b");

    const activeAnchor = labelAnchorComponentFor(activePill);
    const activeLabel = labelTextFor(activeAnchor);

    expectEqual("anchor_padding_matches_spacing_unit", activeAnchor ? activeAnchor.horizontalPadding : -1, root.metrics.spacingUnit);
    expectEqual("active_label_uses_on_primary_role", activeLabel ? activeLabel.color.toString() : "", "#0e0e43");
  }

  function testAnchorWidthStable() {
    const shortLabelPill = createPill({
      "labelMode": "index+name",
      "characterCount": 8,
      "workspaceId": "short",
      "workspaceModel": {
        "id": 3,
        "idx": 3,
        "name": "A",
        "isFocused": false,
        "windows": [],
      },
    });
    const longLabelPill = createPill({
      "labelMode": "index+name",
      "characterCount": 8,
      "workspaceId": "long",
      "workspaceModel": {
        "id": 4,
        "idx": 4,
        "name": "LongName",
        "isFocused": false,
        "windows": [],
      },
    });

    expectEqual("anchor_width_short_label", shortLabelPill.labelAnchor.width, root.metrics.anchorWidth);
    expectEqual("anchor_width_long_label", longLabelPill.labelAnchor.width, root.metrics.anchorWidth);
    expectEqual("anchor_width_stable", shortLabelPill.labelAnchor.width, longLabelPill.labelAnchor.width);
    expectEqual("anchor_width_matches_square_cell", shortLabelPill.labelAnchor.width, root.metrics.iconSlotExtent);

    const overflowingAnchor = labelAnchorComponentFor(longLabelPill);
    const overflowingLabel = labelTextFor(overflowingAnchor);
    const availableWidth = longLabelPill.labelAnchor.width - overflowingAnchor.horizontalPadding * 2;

    expectTrue("label_text_constrained_to_anchor", overflowingLabel && overflowingLabel.width <= availableWidth, "label width should stay inside the anchor block");
    expectEqual("label_text_elides_cleanly", overflowingLabel ? overflowingLabel.elide : Text.ElideNone, Text.ElideRight);
  }

  function testScratchpadFocusStyling() {
    const activePill = createPill({
      "workspaceId": "special:scratch",
      "isScratchpad": true,
      "activeSpecialWorkspaceName": "scratch",
      "workspaceModel": {
        "id": -1,
        "name": "special:scratch",
        "scratchpadName": "scratch",
        "scratchpadLabel": "Scratch",
        "isFocused": false,
        "windows": sampleWindows(1),
      },
    });
    const inactivePill = createPill({
      "workspaceId": "special:other",
      "isScratchpad": true,
      "activeSpecialWorkspaceName": "different",
      "workspaceModel": {
        "id": -2,
        "name": "special:other",
        "scratchpadName": "other",
        "scratchpadLabel": "Scratch",
        "isFocused": false,
        "windows": sampleWindows(1),
      },
    });
    const activeAnchor = labelAnchorComponentFor(activePill);
    const inactiveAnchor = labelAnchorComponentFor(inactivePill);
    const activeLabel = labelTextFor(activeAnchor);
    const inactiveLabel = labelTextFor(inactiveAnchor);

    expectEqual("scratchpad_effective_focus", activePill.isFocused, true);
    expectEqual("scratchpad_anchor_focus", activeAnchor ? activeAnchor.isFocused : false, true);
    expectTrue("scratchpad_font_weight", activeLabel && inactiveLabel && activeLabel.font.weight > inactiveLabel.font.weight, "active scratchpad label should be bolder");
    expectTrue("scratchpad_label_color", activeLabel && inactiveLabel && activeLabel.color.toString() !== inactiveLabel.color.toString(), "active scratchpad label color should differ");
  }

  function testHoverOwnershipRace(done) {
    const pill = createPill({
      "workspaceId": "race",
      "workspaceModel": {
        "id": 9,
        "idx": 9,
        "name": "race",
        "isFocused": false,
        "windows": sampleWindows(2),
      },
    });
    const activations = [];

    pill.hoverActivated.connect(workspaceId => activations.push(workspaceId));
    pill.labelHovered = true;

    wait(5, () => {
      pill.hoveredWorkspaceId = "other-workspace";
    });

    wait(60, () => {
      expectEqual("hover_ownership_change_keeps_compact_state", pill.hoverExpanded, false);
      expectEqual("hover_ownership_change_blocks_activation", activations.length, 0);
      done();
    });
  }

  function testRevealPanelHoverOwnership(done) {
    const pill = createPill({
      "workspaceId": "hover-transfer",
      "workspaceModel": {
        "id": 10,
        "idx": 10,
        "name": "hover-transfer",
        "isFocused": false,
        "windows": sampleWindows(3),
      },
    });
    const panel = revealPanelFor(pill);

    expectTrue("reveal_hover_panel_found", panel !== null, "reveal panel should exist for hover ownership test");
    pill.labelHovered = true;

    wait(40, () => {
      expectEqual("label_hover_expands_preview", pill.hoverExpanded, true);
      pill.labelHovered = false;
      if (panel)
        panel.panelHoverChanged(true);

      wait(20, () => {
        expectEqual("reveal_hover_claims_item_hover", pill.itemHovered, true);
        expectEqual("reveal_hover_keeps_preview_open", pill.hoverExpanded, true);
        if (panel)
          panel.panelHoverChanged(false);

        wait(40, () => {
          expectEqual("reveal_hover_release_collapses_preview", pill.hoverExpanded, false);
          done();
        });
      });
    });
  }

  function finalize() {
    testOccupiedInactiveRestAndHoverExpansion();
    testAnchorWidthStable();
    testScratchpadFocusStyling();

    if (failed)
      console.log("WORKSPACE_RUNTIME_RESULT FAIL");
    else
      console.log("WORKSPACE_RUNTIME_RESULT PASS");

    Qt.quit();
  }

  function run() {
    testHoverOwnershipRace(() => testRevealPanelHoverOwnership(finalize));
  }

  Component.onCompleted: Qt.callLater(run)
}
