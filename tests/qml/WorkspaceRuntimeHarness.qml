import QtQuick
import qs.Services.Compositor
import "../../Modules/Bar/Widgets" as BarWidgets

Item {
  id: root

  property bool failed: false

  Component {
    id: workspaceComponent
    BarWidgets.Workspace {
      widgetId: "Workspace"
      section: "left"
      sectionWidgetIndex: 0
      sectionWidgetsCount: 1
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

  function wait(delay, callback) {
    oneshotTimerComponent.createObject(root, {
      "interval": delay,
      "callback": callback,
    }).start();
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

  function collectPills(item) {
    const pills = [];

    function visit(node) {
      if (!node)
        return;

      if (node.workspaceId !== undefined && node.pillMainExtent !== undefined)
        pills.push(node);

      const children = node.children || [];
      for (let i = 0; i < children.length; i++)
        visit(children[i]);
    }

    visit(item);
    return pills;
  }

  function pillIds(widget) {
    return collectPills(widget).map(pill => String(pill.workspaceId));
  }

  function seedInitialState() {
    CompositorService.workspaces.clear();
    CompositorService.specialWorkspaces.clear();
    CompositorService.windows.clear();

    CompositorService.workspaces.append({
      "id": 1,
      "idx": 1,
      "name": "one",
      "output": "",
      "isFocused": true,
    });
    CompositorService.workspaces.append({
      "id": 2,
      "idx": 2,
      "name": "two",
      "output": "",
      "isFocused": false,
    });
    CompositorService.windows.append({
      "id": "window-1",
      "address": "0x1",
      "appId": "app-1",
      "title": "Window 1",
      "workspaceId": 1,
      "workspaceName": "one",
    });
    CompositorService.focusedWindowId = "window-1";
    CompositorService.focusedScreen = "";
    CompositorService.workspacesChanged();
    CompositorService.windowListChanged();
  }

  function resetWorkspaces() {
    CompositorService.workspaces.clear();
    CompositorService.windows.clear();

    CompositorService.workspaces.append({
      "id": 7,
      "idx": 7,
      "name": "seven",
      "output": "",
      "isFocused": false,
    });
    CompositorService.windows.append({
      "id": "window-7",
      "address": "0x7",
      "appId": "app-7",
      "title": "Window 7",
      "workspaceId": 7,
      "workspaceName": "seven",
    });
    CompositorService.focusedWindowId = "window-7";
    CompositorService.workspacesChanged();
    CompositorService.windowListChanged();
  }

  function finalize() {
    if (failed)
      console.log("WORKSPACE_RUNTIME_RESULT FAIL");
    else
      console.log("WORKSPACE_RUNTIME_RESULT PASS");

    Qt.quit();
  }

  function run() {
    seedInitialState();
    const widget = workspaceComponent.createObject(root);

    wait(40, () => {
      expectEqual("workspace_bar_height_resolves", widget.barHeight, 25);
      expectEqual("workspace_geometry_orientation_resolves", widget.isVertical, false);
      expectEqual("workspace_initial_visible_count", pillIds(widget).length, 2);

      resetWorkspaces();

      wait(40, () => {
        const ids = pillIds(widget);
        expectEqual("workspace_reset_visible_count", ids.length, 1);
        expectEqual("workspace_reset_updates_first_id", ids[0], "7");
        finalize();
      });
    });
  }

  Component.onCompleted: Qt.callLater(run)
}
