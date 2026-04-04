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
    id: workspaceStripComponent
    WorkspaceComponents.WorkspaceStrip {
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

  function createStrip() {
    return workspaceStripComponent.createObject(root, {
      "workspaces": [
        {
          "id": 1,
          "idx": 1,
          "name": "one",
          "isFocused": false,
          "windows": [],
        },
        {
          "id": 3,
          "idx": 3,
          "name": "three",
          "isFocused": true,
          "windows": sampleWindows(2),
        },
        {
          "id": 4,
          "idx": 4,
          "name": "occupied",
          "isFocused": false,
          "windows": sampleWindows(5),
        },
      ],
      "scratchpadWorkspaces": [
        {
          "id": -1,
          "name": "S",
          "scratchpadName": "S",
          "scratchpadLabel": "S",
          "windows": sampleWindows(1),
        },
      ],
      "effectiveLabelMode": "index",
      "characterCount": 3,
      "isVertical": false,
      "focusedWindowId": "window-0",
      "metrics": root.metrics,
      "capsuleHeight": root.metrics.capsuleHeight,
      "barFontSize": 11,
      "colorizeIcons": false,
      "unfocusedIconsOpacity": 0.75,
      "activeSpecialWorkspaceName": "",
      "hoveredWorkspaceId": "",
    });
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

  function collectPills(item) {
    const pills = [];

    function visit(node) {
      if (!node)
        return;

      if (node.workspaceId !== undefined && node.pillMainExtent !== undefined && node.labelMainExtent !== undefined && node.hoverExpanded !== undefined)
        pills.push(node);

      const children = node.children || [];
      for (let i = 0; i < children.length; i++)
        visit(children[i]);
    }

    visit(item);
    return pills;
  }

  function pillId(pill) {
    return pill && pill.workspaceId !== undefined && pill.workspaceId !== null ? pill.workspaceId.toString() : "";
  }

  function pillFor(pills, workspaceId) {
    const targetId = workspaceId.toString();
    for (let i = 0; i < pills.length; i++) {
      if (pillId(pills[i]) === targetId)
        return pills[i];
    }
    return null;
  }

  function itemLeft(item) {
    if (!item)
      return -1;
    return item.mapToItem(root, 0, 0).x;
  }

  function fail(name, details) {
    failed = true;
    console.log("WORKSPACE_STRIP_RUNTIME_FAIL", name, details || "");
  }

  function pass(name) {
    console.log("WORKSPACE_STRIP_RUNTIME_PASS", name);
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

  function testStripTrailingMotion(done) {
    const strip = createStrip();

    wait(40, () => {
      const pills = collectPills(strip).sort((left, right) => left.x - right.x);
      const resting = pillFor(pills, 1);
      const active = pillFor(pills, 3);
      const occupied = pillFor(pills, 4);
      const scratchpad = pillFor(pills, "S");

      expectTrue("strip_has_four_pills", pills.length >= 4, "strip runtime should exercise four visible pills");
      expectTrue("resting_pills_found", resting !== null && occupied !== null && scratchpad !== null, "strip runtime should locate the resting pills");
      expectTrue("active_pill_found", active !== null, "strip runtime should locate the active pill");

      expectEqual("resting_pills_share_same_width", resting ? resting.width : -1, occupied ? occupied.width : -2);
      expectEqual("resting_pills_share_same_width_with_scratchpad", resting ? resting.width : -1, scratchpad ? scratchpad.width : -3);
      expectTrue("active_drawer_stays_open", active ? active.isExpanded : false, "the active drawer should stay open before hover previewing another pill");

      const before = {
        "resting": itemLeft(resting),
        "active": itemLeft(active),
        "occupied": itemLeft(occupied),
        "scratchpad": itemLeft(scratchpad),
        "activeWidth": active ? active.pillMainExtent : -1,
      };

      if (occupied)
        occupied.labelHovered = true;

      wait(60, () => {
        expectTrue("hovered_occupied_inactive_expands", occupied ? occupied.hoverExpanded : false, "hovering the occupied inactive pill should expand it");
        expectTrue("hover_preview_coexists_with_active_drawer", active ? active.isExpanded : false, "hovering an inactive pill should not collapse the active drawer");

        const afterHover = {
          "resting": itemLeft(resting),
          "active": itemLeft(active),
          "occupied": itemLeft(occupied),
          "scratchpad": itemLeft(scratchpad),
        };

        expectEqual("trailing_only_keeps_leading_positions", afterHover.resting, before.resting);
        expectEqual("trailing_only_keeps_active_position", afterHover.active, before.active);
        expectEqual("trailing_only_keeps_hovered_pill_position", afterHover.occupied, before.occupied);
        expectTrue("trailing_only_shifts_following_pills", afterHover.scratchpad > before.scratchpad, "pills after the expanded pill should shift trailing-only");

        const occupiedPanel = occupied ? revealPanelFor(occupied) : null;
        const occupiedWidthBeforeTransfer = occupied ? occupied.pillMainExtent : -1;

        if (occupied)
          occupied.labelHovered = false;
        if (occupiedPanel)
          occupiedPanel.panelHoverChanged(true);

        wait(20, () => {
          expectTrue("hover_ownership_transfers_without_collapse_jitter", occupied ? occupied.itemHovered : false, "hover ownership should move from label to drawer without collapsing the pill");
          expectEqual("hover_transfer_keeps_expanded_width", occupied ? occupied.pillMainExtent : -1, occupiedWidthBeforeTransfer);

          if (occupiedPanel)
            occupiedPanel.panelHoverChanged(false);

          wait(40, () => {
            expectEqual("hover_release_collapses_preview", occupied ? occupied.hoverExpanded : true, false);
            expectEqual("hover_release_restores_resting_width", occupied ? occupied.pillMainExtent : -1, occupied ? occupied.labelMainExtent : -2);
            expectEqual("active_width_stays_stable", active ? active.pillMainExtent : -1, before.activeWidth);
            done();
          });
        });
      });
    });
  }

  function finalize() {
    testStripTrailingMotion(() => {
      if (failed)
        console.log("WORKSPACE_STRIP_RUNTIME_RESULT FAIL");
      else
        console.log("WORKSPACE_STRIP_RUNTIME_RESULT PASS");

      Qt.quit();
    });
  }

  function run() {
    finalize();
  }

  Component.onCompleted: Qt.callLater(run)
}
