pragma Singleton

import Quickshell
import qs.Commons

Singleton {
  id: root

  // A ref. to the lockScreen, so it's accessible from anywhere
  // This is not a panel...
  property var lockScreen: null

  // Panels
  property var registeredPanels: ({})
  property var openedPanel: null
  property var panelPopupStacks: []
  signal willOpen
  signal didClose

  // Tray menu windows (one per screen)
  property var trayMenuWindows: ({})
  signal trayMenuWindowRegistered(var screen)

  // Register this panel (called after panel is loaded)
  function registerPanel(panel) {
    registeredPanels[panel.objectName] = panel
    Logger.d("PanelService", "Registered panel:", panel.objectName)
  }

  // Register tray menu window for a screen
  function registerTrayMenuWindow(screen, window) {
    if (!screen || !window)
      return
    var key = screen.name
    trayMenuWindows[key] = window
    Logger.d("PanelService", "Registered tray menu window for screen:", key)
    trayMenuWindowRegistered(screen)
  }

  // Get tray menu window for a screen
  function getTrayMenuWindow(screen) {
    if (!screen)
      return null
    return trayMenuWindows[screen.name] || null
  }

  // Returns a panel (loads it on-demand if not yet loaded)
  function getPanel(name, screen) {
    if (!screen) {
      Logger.d("PanelService", "missing screen for getPanel:", name)
      // If no screen specified, return the first matching panel
      for (var key in registeredPanels) {
        if (key.startsWith(name + "-")) {
          return registeredPanels[key]
        }
      }
      return null
    }

    var panelKey = `${name}-${screen.name}`

    // Check if panel is already loaded
    if (registeredPanels[panelKey]) {
      return registeredPanels[panelKey]
    }

    Logger.w("PanelService", "Panel not found:", panelKey)
    return null
  }

  // Check if a panel exists
  function hasPanel(name) {
    return name in registeredPanels
  }

  // Helper to keep only one panel open at any time
  function willOpenPanel(panel) {
    if (openedPanel && openedPanel !== panel) {
      openedPanel.close()
    }
    openedPanel = panel

    // emit signal
    willOpen()
  }

  function closedPanel(panel) {
    if (openedPanel && openedPanel === panel) {
      openedPanel = null
    }
    clearPanelPopups(panel)

    // emit signal
    didClose()
  }

  function popupStackIndex(panel) {
    if (!panelPopupStacks || !panel)
      return -1
    for (var i = 0; i < panelPopupStacks.length; ++i) {
      if (panelPopupStacks[i].panel === panel)
        return i
    }
    return -1
  }

  function registerPanelPopup(popup, panel) {
    if (!popup)
      return
    panel = panel || openedPanel
    if (!panel)
      return
    var idx = popupStackIndex(panel)
    if (idx === -1) {
      panelPopupStacks.push({
                              "panel": panel,
                              "popups": []
                            })
      idx = panelPopupStacks.length - 1
    }
    var stack = panelPopupStacks[idx].popups
    if (stack.indexOf(popup) === -1)
      stack.push(popup)
  }

  function unregisterPanelPopup(popup, panel) {
    if (!popup)
      return
    panel = panel || openedPanel
    if (!panel)
      return
    var idx = popupStackIndex(panel)
    if (idx === -1)
      return
    var stack = panelPopupStacks[idx].popups
    var popupIdx = stack.indexOf(popup)
    if (popupIdx !== -1)
      stack.splice(popupIdx, 1)
    if (stack.length === 0)
      panelPopupStacks.splice(idx, 1)
  }

  function closeTopPopup(panel) {
    panel = panel || openedPanel
    if (!panel)
      return false
    var idx = popupStackIndex(panel)
    if (idx === -1)
      return false
    var stack = panelPopupStacks[idx].popups
    while (stack.length > 0) {
      var popup = stack.pop()
      if (popup && popup.visible && typeof popup.close === "function") {
        popup.close()
        if (stack.length === 0)
          panelPopupStacks.splice(idx, 1)
        return true
      }
    }
    panelPopupStacks.splice(idx, 1)
    return false
  }

  function clearPanelPopups(panel) {
    panel = panel || openedPanel
    var idx = popupStackIndex(panel)
    if (idx !== -1)
      panelPopupStacks.splice(idx, 1)
  }
}
