import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Services.Keyboard
import "HyprlandWorkspaceSignature.js" as HyprlandWorkspaceSignature

Item {
  id: root

  // Properties that match the facade interface
  property ListModel workspaces: ListModel {}
  property ListModel specialWorkspaces: ListModel {}
  property string activeSpecialWorkspaceName: ""
  property var windows: []
  property int focusedWindowIndex: -1

  // Signals that match the facade interface
  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged
  signal focusedScreenChanged

  // Hyprland-specific properties
  property bool initialized: false
  property var workspaceCache: ({})
  property var windowCache: ({})
  property string lastWorkspaceSignature: ""

  // Debounce timer for updates
  Timer {
    id: updateTimer
    interval: 50
    repeat: false
    onTriggered: safeUpdate()
  }

  // Initialization
  function initialize() {
    if (initialized)
      return;
    try {
      Hyprland.refreshWorkspaces();
      Hyprland.refreshToplevels();
      Qt.callLater(() => {
                     safeUpdateWorkspaces();
                     safeUpdateWindows();
                     queryDisplayScales();
                     queryKeyboardLayout();
                   });
      initialized = true;
      Logger.i("HyprlandService", "Service started");
    } catch (e) {
      Logger.e("HyprlandService", "Failed to initialize:", e);
    }
  }

  // Query display scales
  function queryDisplayScales() {
    hyprlandMonitorsProcess.running = true;
  }

  // Hyprland monitors process for display scale detection
  Process {
    id: hyprlandMonitorsProcess
    running: false
    command: ["hyprctl", "monitors", "-j"]

    property string accumulatedOutput: ""

    stdout: SplitParser {
      onRead: function (line) {
        // Accumulate lines instead of parsing each one
        hyprlandMonitorsProcess.accumulatedOutput += line;
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0 || !accumulatedOutput) {
        Logger.e("HyprlandService", "Failed to query monitors, exit code:", exitCode);
        accumulatedOutput = "";
        return;
      }

      try {
        const monitorsData = JSON.parse(accumulatedOutput);
        const scales = {};

        for (const monitor of monitorsData) {
          if (monitor.name) {
            scales[monitor.name] = {
              "name": monitor.name,
              "scale": monitor.scale || 1.0,
              "width": monitor.width || 0,
              "height": monitor.height || 0,
              "refresh_rate": monitor.refreshRate || 0,
              "x": monitor.x || 0,
              "y": monitor.y || 0,
              "active_workspace": monitor.activeWorkspace ? monitor.activeWorkspace.id : -1,
              "vrr": monitor.vrr || false,
              "focused": monitor.focused || false
            };
          }
        }

        // Notify CompositorService (it will emit displayScalesChanged)
        if (CompositorService && CompositorService.onDisplayScalesUpdated) {
          CompositorService.onDisplayScalesUpdated(scales);
        }
      } catch (e) {
        Logger.e("HyprlandService", "Failed to parse monitors:", e);
      } finally {
        // Clear accumulated output for next query
        accumulatedOutput = "";
      }
    }
  }

  function queryKeyboardLayout() {
    hyprlandDevicesProcess.running = true;
  }
  // Hyprland devices process for keyboard layout detection
  Process {
    id: hyprlandDevicesProcess
    running: false
    command: ["hyprctl", "devices", "-j"]

    property string accumulatedOutput: ""

    stdout: SplitParser {
      onRead: function (line) {
        // Accumulate lines instead of parsing each one
        hyprlandDevicesProcess.accumulatedOutput += line;
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0 || !accumulatedOutput) {
        Logger.e("HyprlandService", "Failed to query devices, exit code:", exitCode);
        accumulatedOutput = "";
        return;
      }

      try {
        const devicesData = JSON.parse(accumulatedOutput);
        for (const keyboard of devicesData.keyboards) {
          if (keyboard.main) {
            const layoutName = keyboard.active_keymap;
            KeyboardLayoutService.setCurrentLayout(layoutName);
            Logger.d("HyprlandService", "Keyboard layout switched:", layoutName);
          }
        }
      } catch (e) {
        Logger.e("HyprlandService", "Failed to parse devices:", e);
      } finally {
        // Clear accumulated output for next query
        accumulatedOutput = "";
      }
    }
  }

  // Safe update wrapper
  function safeUpdate() {
    safeUpdateWindows();
    const workspacesChanged = safeUpdateWorkspaces();
    if (workspacesChanged) {
      workspaceChanged();
    }
    windowListChanged();
  }

  // Safe workspace update
  function safeUpdateWorkspaces() {
    try {
      if (!Hyprland.workspaces || !Hyprland.workspaces.values) {
        return false;
      }

      const hlWorkspaces = Hyprland.workspaces.values;
      const occupiedIds = getOccupiedWorkspaceIds();

      const hlToplevels = Hyprland.toplevels?.values || [];
      const signature = HyprlandWorkspaceSignature.buildSignature(hlWorkspaces, occupiedIds, hlToplevels);
      if (signature === lastWorkspaceSignature) {
        return false; // No change
      }
      lastWorkspaceSignature = signature;

      // Clear both models
      workspaces.clear();
      specialWorkspaces.clear();
      workspaceCache = {};

      const normalWorkspaces = [];
      const scratchpadWorkspaces = [];

      for (var i = 0; i < hlWorkspaces.length; i++) {
        const ws = hlWorkspaces[i];
        const isScratchpad = (ws.id < 0) || (ws.name && ws.name.startsWith("special:"));
        
        if (isScratchpad) {
          // Normalize scratchpad name
          let scratchpadName = ws.name || "";
          if (scratchpadName.startsWith("special:")) {
            scratchpadName = scratchpadName.substring(8);
          }
          
          // Generate label and key
          const scratchpadLabel = scratchpadName.length > 0 ? scratchpadName.charAt(0).toUpperCase() : "S";
          const scratchpadKey = scratchpadName.length > 0 ? scratchpadName : "special";
          
          const spData = {
            "id": ws.id,
            "idx": ws.id,
            "name": ws.name || "",
            "scratchpadName": scratchpadName,
            "scratchpadLabel": scratchpadLabel,
            "scratchpadKey": scratchpadKey,
            "output": (ws.monitor && ws.monitor.name) ? ws.monitor.name : "",
            "isActive": ws.active === true,
            "isFocused": ws.focused === true,
            "isUrgent": ws.urgent === true,
            "isOccupied": occupiedIds[ws.id] === true,
            "isScratchpad": true
          };
          
          scratchpadWorkspaces.push(spData);
          workspaceCache[ws.id] = spData;
        } else {
          const wsData = {
            "id": ws.id,
            "idx": ws.id,
            "name": ws.name || "",
            "output": (ws.monitor && ws.monitor.name) ? ws.monitor.name : "",
            "isActive": ws.active === true,
            "isFocused": ws.focused === true,
            "isUrgent": ws.urgent === true,
            "isOccupied": occupiedIds[ws.id] === true,
            "isScratchpad": false
          };
          
          normalWorkspaces.push(wsData);
          workspaceCache[ws.id] = wsData;
        }
      }

      // Secondary pass: detect scratchpads from windows (handles empty scratchpads not in workspaces list)
      const scratchpadIdsFromWorkspaces = new Set();
      for (let i = 0; i < scratchpadWorkspaces.length; i++) {
        scratchpadIdsFromWorkspaces.add(scratchpadWorkspaces[i].id);
      }

      for (let i = 0; i < hlToplevels.length; i++) {
        const toplevel = hlToplevels[i];
        if (!toplevel || !toplevel.workspace) continue;

        const wsId = toplevel.workspace.id;
        if (wsId >= 0 || scratchpadIdsFromWorkspaces.has(wsId)) continue;

        let scratchpadName = toplevel.workspace.name || "";
        if (scratchpadName.startsWith("special:")) {
          scratchpadName = scratchpadName.substring(8);
        }

        const scratchpadLabel = scratchpadName.length > 0 ? scratchpadName.charAt(0).toUpperCase() : "S";
        const scratchpadKey = scratchpadName.length > 0 ? scratchpadName : "special";

        const spData = {
          "id": wsId,
          "idx": wsId,
          "name": toplevel.workspace.name || "",
          "scratchpadName": scratchpadName,
          "scratchpadLabel": scratchpadLabel,
          "scratchpadKey": scratchpadKey,
          "output": toplevel.monitor?.name || "",
          "isActive": false,
          "isFocused": false,
          "isUrgent": false,
          "isOccupied": true,
          "isScratchpad": true
        };

        scratchpadWorkspaces.push(spData);
        workspaceCache[wsId] = spData;
      }

      // Sort normal workspaces by idx
      normalWorkspaces.sort((a, b) => a.idx - b.idx);

      // Sort scratchpad workspaces by key (alphabetical)
      scratchpadWorkspaces.sort((a, b) => a.scratchpadKey.localeCompare(b.scratchpadKey));

      // Populate normal workspaces model
      for (var j = 0; j < normalWorkspaces.length; j++) {
        workspaces.append(normalWorkspaces[j]);
      }

      // Populate special workspaces model
      for (var k = 0; k < scratchpadWorkspaces.length; k++) {
        specialWorkspaces.append(scratchpadWorkspaces[k]);
      }

      return true; // Workspaces changed

    } catch (e) {
      Logger.e("HyprlandService", "Error updating workspaces:", e);
      return false;
    }
  }

  // Get occupied workspace IDs safely
  function getOccupiedWorkspaceIds() {
    const occupiedIds = {};

    try {
      if (!Hyprland.toplevels || !Hyprland.toplevels.values) {
        return occupiedIds;
      }

      const hlToplevels = Hyprland.toplevels.values;
      for (var i = 0; i < hlToplevels.length; i++) {
        const toplevel = hlToplevels[i];
        if (!toplevel)
          continue;
        try {
          const wsId = toplevel.workspace ? toplevel.workspace.id : null;
          if (wsId !== null && wsId !== undefined) {
            occupiedIds[wsId] = true;
          }
        } catch (e)

          // Ignore individual toplevel errors
        {}
      }
    } catch (e)

      // Return empty if we can't determine occupancy
    {}

    return occupiedIds;
  }

  // Safe window update
  function safeUpdateWindows() {
    try {
      const windowsList = [];
      windowCache = {};

      if (!Hyprland.toplevels || !Hyprland.toplevels.values) {
        windows = [];
        focusedWindowIndex = -1;
        return;
      }

      const hlToplevels = Hyprland.toplevels.values;
      let newFocusedIndex = -1;

      // Get active workspaces to filter focus
      const activeWorkspaceIds = {};
      if (Hyprland.workspaces && Hyprland.workspaces.values) {
        const hlWorkspaces = Hyprland.workspaces.values;
        for (var j = 0; j < hlWorkspaces.length; j++) {
          if (hlWorkspaces[j].active) {
            activeWorkspaceIds[hlWorkspaces[j].id] = true;
          }
        }
      }

      for (var i = 0; i < hlToplevels.length; i++) {
        const toplevel = hlToplevels[i];
        if (!toplevel)
          continue;
        const windowData = extractWindowData(toplevel);
        if (windowData) {
          // If the window claims to be focused, verify it's on an active workspace
          if (windowData.isFocused) {
            if (!activeWorkspaceIds[windowData.workspaceId]) {
              windowData.isFocused = false;
            }
          }

          windowsList.push(windowData);
          windowCache[windowData.id] = windowData;

          if (windowData.isFocused) {
            newFocusedIndex = windowsList.length - 1;
          }
        }
      }

      windows = toSortedWindowList(windowsList);

      // Recalculate focused index from the sorted list to ensure it's accurate
      newFocusedIndex = -1;
      for (var k = 0; k < windows.length; k++) {
        if (windows[k].isFocused) {
          newFocusedIndex = k;
          break;
        }
      }

      if (newFocusedIndex !== focusedWindowIndex) {
        focusedWindowIndex = newFocusedIndex;
        activeWindowChanged();
      }
    } catch (e) {
      Logger.e("HyprlandService", "Error updating windows:", e);
    }
  }

  // Extract window data safely from a toplevel
  function extractWindowData(toplevel) {
    if (!toplevel)
      return null;

    try {
      // Safely extract properties
      const windowId = safeGetProperty(toplevel, "address", "");
      if (!windowId)
        return null;

      const appId = getAppId(toplevel);
      const title = getAppTitle(toplevel);
      const wsId = toplevel.workspace ? toplevel.workspace.id : null;
      const focused = toplevel.activated === true;
      const output = toplevel.monitor?.name || "";

      // Extract position
      let x = 0;
      let y = 0;
      try {
        const ipcData = toplevel.lastIpcObject;
        if (ipcData && ipcData.at) {
          x = ipcData.at[0];
          y = ipcData.at[1];
        } else if (typeof toplevel.x !== 'undefined') {
          x = toplevel.x;
          y = toplevel.y;
        }
      } catch (e) {}

      return {
        "id": windowId,
        "title": title,
        "appId": appId,
        "workspaceId": wsId || -1,
        "isFocused": focused,
        "output": output,
        "x": x,
        "y": y
      };
    } catch (e) {
      return null;
    }
  }

  function toSortedWindowList(windowList) {
    return windowList.sort((a, b) => {
                             // Sort by workspace first (just in case they are mixed)
                             if (a.workspaceId !== b.workspaceId) {
                               return a.workspaceId - b.workspaceId;
                             }
                             // Then sort by X position (left to right)
                             if (a.x !== b.x) {
                               return a.x - b.x;
                             }
                             // Then sort by Y position (top to bottom)
                             if (a.y !== b.y) {
                               return a.y - b.y;
                             }
                             // Fallback to Window ID mapping
                             return a.id.localeCompare(b.id);
                           });
  }

  function getAppTitle(toplevel) {
    try {
      var title = toplevel.wayland.title;
      if (title)
        return title;
    } catch (e) {}

    return safeGetProperty(toplevel, "title", "");
  }

  function getAppId(toplevel) {
    if (!toplevel)
      return "";

    var appId = "";

    // Try the wayland object first!
    // From my (Lemmy) testing it works fine so we could probably get rid of all the other attempts below.
    // Leaving them in for now, just in case...
    try {
      appId = toplevel.wayland.appId;
      if (appId)
        return appId;
    } catch (e) {}

    // Try direct properties
    appId = safeGetProperty(toplevel, "class", "");
    if (appId)
      return appId;

    appId = safeGetProperty(toplevel, "initialClass", "");
    if (appId)
      return appId;

    appId = safeGetProperty(toplevel, "appId", "");
    if (appId)
      return appId;

    // Try lastIpcObject
    try {
      const ipcData = toplevel.lastIpcObject;
      if (ipcData) {
        return String(ipcData.class || ipcData.initialClass || ipcData.appId || ipcData.wm_class || "");
      }
    } catch (e) {}

    return "";
  }

  // Safe property getter
  function safeGetProperty(obj, prop, defaultValue) {
    try {
      const value = obj[prop];
      if (value !== undefined && value !== null) {
        return String(value);
      }
    } catch (e)

      // Property access failed
    {}
    return defaultValue;
  }

  function handleActiveLayoutEvent(ev) {
    try {
      let beforeParenthesis;
      const parenthesisPos = ev.lastIndexOf('(');

      if (parenthesisPos === -1) {
        beforeParenthesis = ev;
      } else {
        beforeParenthesis = ev.substring(0, parenthesisPos);
      }

      const layoutNameStart = beforeParenthesis.lastIndexOf(',') + 1;
      const layoutName = ev.substring(layoutNameStart);

      // Ignore bogus "error" layout reported by virtual keyboards (e.g. wtype)
      if (layoutName.toLowerCase() === "error") {
        Logger.d("HyprlandService", "Ignoring bogus 'error' layout from activelayout event");
        return;
      }

      KeyboardLayoutService.setCurrentLayout(layoutName);
      Logger.d("HyprlandService", "Keyboard layout switched:", layoutName);
    } catch (e) {
      Logger.e("HyprlandService", "Error handling activelayout:", e);
    }
  }

  // Connections to Hyprland
  Connections {
    target: Hyprland.workspaces
    enabled: initialized
    function onValuesChanged() {
      const changed = safeUpdateWorkspaces();
      if (changed) {
        workspaceChanged();
        // Reconcile scratchpad state after workspace changes
        reconcileActiveScratchpad();
      }
    }
  }

  Connections {
    target: Hyprland.toplevels
    enabled: initialized
    function onValuesChanged() {
      Qt.callLater(safeUpdate);
    }
  }

  Connections {
    target: Hyprland
    enabled: initialized
    function onRawEvent(event) {
      Hyprland.refreshWorkspaces();
      Hyprland.refreshToplevels();
      const changed = safeUpdateWorkspaces();
      if (changed) {
        workspaceChanged();
      }
      Qt.callLater(safeUpdate);

      const monitorsEvents = ["configreloaded", "monitoradded", "monitorremoved", "monitoraddedv2", "monitorremovedv2"];

      if (monitorsEvents.includes(event.name)) {
        Qt.callLater(queryDisplayScales);
      }

      if (event.name == "activelayout") {
        handleActiveLayoutEvent(event.data);
      }
    }
  }

  Connections {
    target: Hyprland
    enabled: initialized
    ignoreUnknownSignals: true
    function onFocusedMonitorChanged() {
      focusedScreenChanged();
    }
  }

  // Public functions
  function switchToWorkspace(workspace) {
    try {
      if (workspace.isScratchpad) {
        // Scratchpad workspaces use togglespecialworkspace
        const scratchName = workspace.scratchpadName || "";
        if (scratchName.length > 0) {
          Hyprland.dispatch("togglespecialworkspace " + scratchName);
          // Optimistic update: mark this scratchpad as active
          activeSpecialWorkspaceName = scratchName;
        }
      } else {
        // Normal workspaces
        if (workspace.name) {
          Hyprland.dispatch(`workspace ${workspace.name}`);
        } else {
          Hyprland.dispatch(`workspace ${workspace.idx}`);
        }
        // Clear active special workspace when switching to normal
        activeSpecialWorkspaceName = "";
      }
    } catch (e) {
      Logger.e("HyprlandService", "Failed to switch workspace:", e);
    }
  }

  // Event-based reconciliation: update active special workspace name
  // This handles external toggles (e.g., via keybind)
  function reconcileActiveScratchpad() {
    try {
      // Check if any scratchpad workspace reports as focused/active
      for (let i = 0; i < specialWorkspaces.count; i++) {
        const sp = specialWorkspaces.get(i);
        if (sp && sp.isFocused) {
          activeSpecialWorkspaceName = sp.scratchpadName;
          return;
        }
      }
      // If we get here, no scratchpad is focused
      // Keep current value (don't clear) - user might have toggled off
      // Only clear if we explicitly switched to a normal workspace
    } catch (e) {
      Logger.d("HyprlandService", "Failed to reconcile scratchpad state:", e);
    }
  }

  function focusWindow(window) {
    try {
      if (!window || !window.id) {
        Logger.w("HyprlandService", "Invalid window object for focus");
        return;
      }

      const windowId = window.id.toString();
      Hyprland.dispatch(`focuswindow address:0x${windowId}`);
      Hyprland.dispatch(`alterzorder top,address:0x${windowId}`); // Bring the focused window to the top (essential for Float Mode)
    } catch (e) {
      Logger.e("HyprlandService", "Failed to switch window:", e);
    }
  }

  function closeWindow(window) {
    try {
      Hyprland.dispatch(`killwindow address:0x${window.id}`);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to close window:", e);
    }
  }

  function turnOffMonitors() {
    try {
      Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "off"]);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to turn off monitors:", e);
    }
  }

  function turnOnMonitors() {
    try {
      Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "on"]);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to turn on monitors:", e);
    }
  }

  function logout() {
    try {
      Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to logout:", e);
    }
  }

  function cycleKeyboardLayout() {
    try {
      Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to cycle keyboard layout:", e);
    }
  }

  function getFocusedScreen() {
    const hyprMon = Hyprland.focusedMonitor;
    if (hyprMon) {
      const monitorName = hyprMon.name;
      for (let i = 0; i < Quickshell.screens.length; i++) {
        if (Quickshell.screens[i].name === monitorName) {
          return Quickshell.screens[i];
        }
      }
    }
    return null;
  }

  function spawn(command) {
    try {
      Quickshell.execDetached(["hyprctl", "dispatch", "--", "exec"].concat(command));
    } catch (e) {
      Logger.e("HyprlandService", "Failed to spawn command:", e);
    }
  }
}
