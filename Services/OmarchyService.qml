pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Services.Theming
import qs.Services.UI
import "../Helpers/ColorsConvert.js" as ColorsConvert

Singleton {
  id: root

  readonly property string omarchyConfigDir: {
    const noctaliaPath = Settings.configDir
    if (noctaliaPath.includes("/noctalia"))
    return noctaliaPath.replace("/noctalia", "/omarchy")

    const parts = noctaliaPath.split('/')
    const lastPart = parts[parts.length - 1] || parts[parts.length - 2]
    if (lastPart === "noctalia") {
      parts[parts.length - 1 || parts.length - 2] = "omarchy"
      return parts.join('/') + (noctaliaPath.endsWith('/') ? '' : '/')
    }
    return (process.env.HOME || process.env.XDG_CONFIG_HOME || "~") + "/.config/omarchy/"
  }
  readonly property string omarchyConfigPath: omarchyConfigDir + "current/theme/alacritty.toml"
  readonly property string omarchyThemePath: omarchyConfigDir + "current/theme"
  readonly property string omarchyThemesDir: omarchyConfigDir + "themes"
  readonly property string omarchyThemeSetPath: {
    // Derive home directory from Settings.configDir (e.g., /home/user/.config/noctalia -> /home/user)
    const configDir = Settings.configDir
    const parts = configDir.split('/')
    // Remove trailing empty string if path ends with /
    if (parts[parts.length - 1] === '')
    parts.pop()
    // Remove .config/noctalia or similar
    const homeIndex = parts.indexOf('.config')
    if (homeIndex > 0) {
      const home = parts.slice(0, homeIndex).join('/')
      return home + "/.local/share/omarchy/bin/omarchy-theme-set"
    }
    // Fallback: try to construct from config dir
    const home = configDir.replace(/\/.config\/.*$/, '')
    return home + "/.local/share/omarchy/bin/omarchy-theme-set"
  }
  readonly property string outputJsonPath: Settings.configDir + "omarchy-colors.json"
  property bool available: false
  property string themeName: ""
  property var availableThemes: []

  signal schemeReady

  function init() {
    Logger.i("Omarchy", "Service started")
    Logger.d("Omarchy", "Looking for config at:", omarchyConfigPath)
    Logger.d("Omarchy", "Theme set path:", omarchyThemeSetPath)
    checkAvailability()
    scanThemes()
  }

  function checkAvailability() {
    availabilityChecker.running = true
  }

  function isAvailable() {
    return available
  }

  function activate() {
    Logger.i("Omarchy", "Activating Omarchy theme sync")
    if (!available) {
      Logger.w("Omarchy", "Omarchy config not found at", omarchyConfigPath)
      ToastService.showError("Omarchy", "Omarchy config not found")
      return false
    }
    Settings.data.omarchy.active = true
    reload()
    return true
  }

  function deactivate() {
    Logger.i("Omarchy", "Deactivating Omarchy theme sync")
    Settings.data.omarchy.active = false
    if (Settings.data.colorSchemes.useWallpaperColors) {
      Logger.i("Omarchy", "Restoring wallpaper-based colors")
      AppThemeService.generate()
    } else if (Settings.data.colorSchemes.predefinedScheme) {
      Logger.i("Omarchy", "Restoring predefined scheme:", Settings.data.colorSchemes.predefinedScheme)
      ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme)
    } else {
      Logger.w("Omarchy", "No predefined scheme configured; triggering AppThemeService fallback")
      AppThemeService.generate()
    }
  }

  function reload() {
    Logger.i("Omarchy", "Reloading Omarchy theme")
    if (!available) {
      Logger.w("Omarchy", "Omarchy config not found at", omarchyConfigPath)
      return
    }
    getThemeName()
    alacrittyReader.path = ""
    alacrittyReader.path = omarchyConfigPath
  }

  function getThemeName() {
    themeNameReader.running = true
  }

  function scanThemes() {
    Logger.d("Omarchy", "Scanning themes directory:", omarchyThemesDir)
    themeScanner.running = true
  }

  function extractPreviewColors(content) {
    function extractColorFromLine(line) {
      const colorMatch = line.match(/=\s*['"](?:#|0x)?([a-fA-F0-9]{6})['"]/)
      if (colorMatch)
        return "#" + colorMatch[1].toLowerCase()
      return null
    }

    const colors = {}
    const lines = content.split('\n')
    let currentSection = null

    for (var i = 0; i < lines.length; i++) {
      const line = lines[i].trim()
      if (!line)
        continue

      if (line.startsWith('[colors.primary]')) {
        currentSection = 'primary'
        continue
      } else if (line.startsWith('[colors.normal]')) {
        currentSection = 'normal'
        continue
      } else if (line.startsWith('[')) {
        currentSection = null
        continue
      }

      if (currentSection === 'primary' && line.includes('background')) {
        const color = extractColorFromLine(line)
        if (color)
          colors.background = color
      } else if (currentSection === 'normal') {
        if (line.match(/^\s*green\s*=/)) {
          const color = extractColorFromLine(line)
          if (color)
            colors.green = color
        } else if (line.match(/^\s*yellow\s*=/)) {
          const color = extractColorFromLine(line)
          if (color)
            colors.yellow = color
        } else if (line.match(/^\s*red\s*=/)) {
          const color = extractColorFromLine(line)
          if (color)
            colors.red = color
        } else if (line.match(/^\s*blue\s*=/)) {
          const color = extractColorFromLine(line)
          if (color)
            colors.blue = color
        }
      }
    }

    // Return top 4 colors for preview
    const previewColors = []
    if (colors.background)
      previewColors.push(colors.background)
    if (colors.green)
      previewColors.push(colors.green)
    if (colors.yellow)
      previewColors.push(colors.yellow)
    if (colors.red)
      previewColors.push(colors.red)

    // Fill in blue if we don't have 4 colors
    if (previewColors.length < 4 && colors.blue)
      previewColors.push(colors.blue)

    return previewColors.slice(0, 4)
  }

  function setTheme(themeName) {
    if (!available) {
      Logger.w("Omarchy", "Cannot set theme - Omarchy not available")
      ToastService.showError("Omarchy", "Omarchy is not available")
      return false
    }

    // Check if theme exists in the new structure
    const themeExists = availableThemes.some(t => typeof t === 'string' ? t === themeName : t.name === themeName)
    if (!themeExists) {
      Logger.w("Omarchy", "Theme not found:", themeName)
      ToastService.showError("Omarchy", `Theme '${themeName}' not found`)
      return false
    }

    Logger.i("Omarchy", "Setting theme to:", themeName)
    themeSwitcher.command = [omarchyThemeSetPath, themeName]
    themeSwitcher.running = true
    return true
  }

  function selectBestAccentColors(colors) {
    const primary = colors.green || colors.blue || colors.cyan || "#4CAF50"
    const secondary = colors.yellow || colors.red || colors.magenta || "#FFC107"
    const tertiary = colors.blue || colors.cyan || colors.magenta || "#2196F3"

    Logger.d("Omarchy", "Selected accents:", "primary=" + primary, "secondary=" + secondary, "tertiary=" + tertiary)

    return {
      "primary": primary,
      "secondary": secondary,
      "tertiary": tertiary
    }
  }

  function parseAlacrittyToml(content) {
    function extractColorFromLine(line) {
      const colorMatch = line.match(/=\s*['"](?:#|0x)?([a-fA-F0-9]{6})['"]/)
      if (colorMatch)
        return "#" + colorMatch[1].toLowerCase()

      return null
    }

    const colors = {}
    const lines = content.split('\n')
    let currentSection = null
    for (var i = 0; i < lines.length; i++) {
      const line = lines[i].trim()
      if (!line)
        continue

      if (line.startsWith('[colors.primary]')) {
        currentSection = 'primary'
        continue
      } else if (line.startsWith('[colors.normal]')) {
        currentSection = 'normal'
        continue
      } else if (line.startsWith('[')) {
        currentSection = null
        continue
      }
      if (currentSection === 'primary') {
        if (line.includes('background')) {
          const color = extractColorFromLine(line)
          if (color) {
            colors.background = color
            Logger.d("Omarchy", "Parsed background:", color)
          }
        } else if (line.includes('foreground')) {
          const color = extractColorFromLine(line)
          if (color) {
            colors.foreground = color
            Logger.d("Omarchy", "Parsed foreground:", color)
          }
        }
      } else if (currentSection === 'normal') {
        const normalColors = ['black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white']
        for (const colorName of normalColors) {
          const nameMatch = line.match(new RegExp(`^\\s*(${colorName})\\s*=`))
          if (nameMatch) {
            const color = extractColorFromLine(line)
            if (color) {
              colors[colorName] = color
              Logger.d("Omarchy", "Parsed " + colorName + ":", color)
            }
            break
          }
        }
      }
    }
    Logger.d("Omarchy", "Parsed colors:", JSON.stringify(colors))
    if (!colors.background || !colors.foreground) {
      Logger.e("Omarchy", "Missing essential colors (background/foreground)")
      return null
    }
    return colors
  }

  function generateScheme(colors) {
    const isDarkMode = ColorsConvert.getLuminance(colors.background) < 0.5
    Logger.d("Omarchy", "Detected mode:", isDarkMode ? "dark" : "light")

    if (Settings.data.colorSchemes.darkMode !== isDarkMode) {
      Logger.i("Omarchy", "Syncing dark mode setting to match theme:", isDarkMode)
      ColorSchemeService.suppressDarkModeNotification = true
      Settings.data.colorSchemes.darkMode = isDarkMode
      ColorSchemeService.suppressDarkModeNotification = false
    }

    const mSurface = colors.background || "#000000"
    const mOnSurface = colors.foreground || "#ffffff"

    const contrastRatio = ColorsConvert.getContrastRatio(mSurface, mOnSurface)
    if (contrastRatio < 3.0) {
      Logger.w("Omarchy", "Poor contrast detected:", contrastRatio.toFixed(2) + ":1", "(Surface:", mSurface + ", OnSurface:", mOnSurface + ")")
    } else {
      Logger.d("Omarchy", "Contrast ratio:", contrastRatio.toFixed(2) + ":1")
    }

    const accents = selectBestAccentColors(colors)

    const mPrimary = accents.primary
    const mSecondary = accents.secondary
    const mTertiary = accents.tertiary
    const mError = colors.red || "#ff0000"

    const mOnPrimary = mSurface
    const mOnSecondary = mSurface
    const mOnTertiary = mSurface
    const mOnError = mSurface

    const mSurfaceVariant = ColorsConvert.generateSurfaceVariant(mSurface, 1, isDarkMode)

    const mOnSurfaceVariant = ColorsConvert.adjustLightness(mOnSurface, isDarkMode ? -20 : 20)

    const mOutline = ColorsConvert.adjustLightnessAndSaturation(mOnSurface, isDarkMode ? -30 : 30, isDarkMode ? -30 : 30)

    const mShadow = colors.black || "#000000"

    const scheme = {
      "mPrimary": mPrimary,
      "mOnPrimary": mOnPrimary,
      "mSecondary": mSecondary,
      "mOnSecondary": mOnSecondary,
      "mTertiary": mTertiary,
      "mOnTertiary": mOnTertiary,
      "mError": mError,
      "mOnError": mOnError,
      "mSurface": mSurface,
      "mOnSurface": mOnSurface,
      "mSurfaceVariant": mSurfaceVariant,
      "mOnSurfaceVariant": mOnSurfaceVariant,
      "mOutline": mOutline,
      "mShadow": mShadow
    }
    Logger.i("Omarchy", "Generated base scheme with improved color selection")
    return scheme
  }

  function generateOmarchyPalette(baseScheme, isDarkMode) {
    const c = hex => ({
                        "default": {
                          "hex": hex,
                          "hex_stripped": hex.replace(/^#/, "")
                        }
                      })

    const primaryContainer = ColorsConvert.generateContainerColor(baseScheme.mPrimary, isDarkMode)
    const secondaryContainer = ColorsConvert.generateContainerColor(baseScheme.mSecondary, isDarkMode)
    const tertiaryContainer = ColorsConvert.generateContainerColor(baseScheme.mTertiary, isDarkMode)

    const onPrimaryContainer = ColorsConvert.generateOnColor(primaryContainer, isDarkMode)
    const onSecondaryContainer = ColorsConvert.generateOnColor(secondaryContainer, isDarkMode)
    const onTertiaryContainer = ColorsConvert.generateOnColor(tertiaryContainer, isDarkMode)

    const errorContainer = ColorsConvert.generateContainerColor(baseScheme.mError, isDarkMode)
    const onError = baseScheme.mOnError
    const onErrorContainer = ColorsConvert.generateOnColor(errorContainer, isDarkMode)

    const surface = baseScheme.mSurface
    const onSurface = baseScheme.mOnSurface
    const surfaceVariant = baseScheme.mSurfaceVariant
    const onSurfaceVariant = baseScheme.mOnSurfaceVariant

    const surfaceContainerLowest = ColorsConvert.generateSurfaceVariant(surface, 0, isDarkMode)
    const surfaceContainerLow = ColorsConvert.generateSurfaceVariant(surface, 1, isDarkMode)
    const surfaceContainer = ColorsConvert.generateSurfaceVariant(surface, 2, isDarkMode)
    const surfaceContainerHigh = ColorsConvert.generateSurfaceVariant(surface, 3, isDarkMode)
    const surfaceContainerHighest = ColorsConvert.generateSurfaceVariant(surface, 4, isDarkMode)

    const surfaceBright = (() => {
                             const hsl = ColorsConvert.hexToHSL(surface)
                             if (!hsl)
                             return surface
                             hsl.l = Math.min(100, hsl.l + (isDarkMode ? 15 : 5))
                             return ColorsConvert.hslToHex(hsl.h, hsl.s, hsl.l)
                           })()

    const surfaceDim = (() => {
                          const hsl = ColorsConvert.hexToHSL(surface)
                          if (!hsl)
                          return surface
                          hsl.l = Math.max(0, hsl.l - (isDarkMode ? 5 : 10))
                          return ColorsConvert.hslToHex(hsl.h, hsl.s, hsl.l)
                        })()

    const outline = baseScheme.mOutline
    const outlineVariant = ColorsConvert.adjustLightness(outline, isDarkMode ? -20 : 20)

    const shadow = "#000000"

    const palette = {
      "primary": c(baseScheme.mPrimary),
      "on_primary": c(baseScheme.mOnPrimary),
      "primary_container": c(primaryContainer),
      "on_primary_container": c(onPrimaryContainer),
      "secondary": c(baseScheme.mSecondary),
      "on_secondary": c(baseScheme.mOnSecondary),
      "secondary_container": c(secondaryContainer),
      "on_secondary_container": c(onSecondaryContainer),
      "tertiary": c(baseScheme.mTertiary),
      "on_tertiary": c(baseScheme.mOnTertiary),
      "tertiary_container": c(tertiaryContainer),
      "on_tertiary_container": c(onTertiaryContainer),
      "error": c(baseScheme.mError),
      "on_error": c(onError),
      "error_container": c(errorContainer),
      "on_error_container": c(onErrorContainer),
      "background": c(surface),
      "on_background": c(onSurface),
      "surface": c(surface),
      "on_surface": c(onSurface),
      "surface_variant": c(surfaceVariant),
      "on_surface_variant": c(onSurfaceVariant),
      "surface_container_lowest": c(surfaceContainerLowest),
      "surface_container_low": c(surfaceContainerLow),
      "surface_container": c(surfaceContainer),
      "surface_container_high": c(surfaceContainerHigh),
      "surface_container_highest": c(surfaceContainerHighest),
      "surface_bright": c(surfaceBright),
      "surface_dim": c(surfaceDim),
      "outline": c(outline),
      "outline_variant": c(outlineVariant),
      "shadow": c(shadow)
    }

    Logger.i("Omarchy", "Generated extended palette:", Object.keys(palette).length, "properties")
    return palette
  }

  function writeScheme(scheme, isDarkMode) {
    const extendedPalette = generateOmarchyPalette(scheme, isDarkMode)

    const output = {}
    Object.keys(extendedPalette).forEach(key => {
                                           const camelKey = 'm' + key.split('_').map(part => part.charAt(0).toUpperCase() + part.slice(1)).join('')
                                           output[camelKey] = extendedPalette[key].default.hex
                                         })

    Logger.d("Omarchy", "Writing extended palette with", Object.keys(output).length, "properties")

    const jsonContent = JSON.stringify(output, null, 2)
    writerProcess.command = ["sh", "-c", `cat > '${outputJsonPath}' << 'OMARCHY_EOF'\n${jsonContent}\nOMARCHY_EOF`]
    writerProcess.running = true
  }

  Process {
    id: availabilityChecker

    command: ["test", "-f", omarchyConfigPath]
    onExited: function (code) {
      root.available = (code === 0)
      if (root.available) {
        Logger.i("Omarchy", "Omarchy config detected")
        if (Settings.data.omarchy.active) {
          Logger.i("Omarchy", "Active flag detected on startup, reloading theme")
          root.reload()
        }
      } else {
        Logger.d("Omarchy", "Omarchy config not found")
      }
    }
  }

  Process {
    id: themeNameReader

    command: ["readlink", "-f", root.omarchyThemePath]
    running: false
    onExited: function (code) {
      if (code === 0) {
        const path = stdout.text.trim()
        const parts = path.split("/")
        root.themeName = parts[parts.length - 1] || "Omarchy"
        Logger.d("Omarchy", "Theme name detected:", root.themeName)
      } else {
        root.themeName = "Omarchy"
        Logger.d("Omarchy", "Could not determine theme name, using default")
      }
    }

    stdout: StdioCollector {}
  }

  FileView {
    id: alacrittyReader

    path: ""
    onLoaded: {
      try {
        const content = text()
        const colors = parseAlacrittyToml(content)
        if (colors) {
          const isDarkMode = ColorsConvert.getLuminance(colors.background) < 0.5
          const scheme = generateScheme(colors)
          writeScheme(scheme, isDarkMode)
        } else {
          Logger.e("Omarchy", "Failed to parse colors from alacritty.toml")
        }
      } catch (e) {
        Logger.e("Omarchy", "Error parsing alacritty.toml:", e)
      }
    }
  }

  Process {
    id: writerProcess

    running: false
    onExited: function (code) {
      if (code === 0) {
        Logger.i("Omarchy", "Scheme written to", outputJsonPath)
        const displayName = root.themeName ? `${root.themeName} (Omarchy)` : "Omarchy theme"
        ToastService.showNotice("Color Scheme", `Set to ${displayName}`, "settings-color-scheme")
        if (!Settings.data.omarchy.active) {
          Settings.data.omarchy.active = true
        }
        root.schemeReady()
      } else {
        Logger.e("Omarchy", "Failed to write scheme file")
        if (stderr.text)
          Logger.e("Omarchy", "Error details:", stderr.text.trim())

        ToastService.showNotice("Color Scheme", "Failed to load Omarchy theme", "settings-color-scheme")
      }
    }

    stdout: StdioCollector {}

    stderr: StdioCollector {}
  }

  Process {
    id: themeScanner

    command: ["bash", "-c", `cd "${root.omarchyThemesDir}" && for theme in */; do theme=\${theme%/}; file="$theme/alacritty.toml"; if [ -f "$file" ]; then echo -n "$theme:"; grep -E '(background|green|yellow|red|blue)\\s*=' "$file" | sed "s/.*['\\"]\\(#\\|0x\\)\\([0-9a-fA-F]\\{6\\}\\).*/\\2/" | sed 's/^/#/' | head -4 | tr '\\n' ',' | sed 's/,$//'; echo; fi; done`]
    running: false
    onExited: function (code) {
      if (code === 0) {
        const output = stdout.text.trim()
        if (output) {
          const themes = []
          const lines = output.split('\n')
          for (var i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line)
              continue
            const parts = line.split(':')
            if (parts.length === 2) {
              const themeName = parts[0]
              const colorStr = parts[1]
              const colors = colorStr ? colorStr.split(',').filter(c => c.length === 7 && c.startsWith('#')).map(c => c.toLowerCase()).slice(0, 4) : []
              themes.push({
                            "name": themeName,
                            "colors": colors
                          })
            }
          }
          root.availableThemes = themes
          Logger.i("Omarchy", "Found", root.availableThemes.length, "themes with colors")
        } else {
          root.availableThemes = []
          Logger.w("Omarchy", "No themes found in themes directory")
        }
      } else {
        Logger.w("Omarchy", "Failed to scan themes directory")
        root.availableThemes = []
      }
    }

    stdout: StdioCollector {}

    stderr: StdioCollector {}
  }

  Process {
    id: themeSwitcher

    running: false
    onExited: function (code) {
      if (code === 0) {
        Logger.i("Omarchy", "Theme switched successfully")
        // Reload will be triggered by symlink watcher
      } else {
        Logger.e("Omarchy", "Failed to switch theme")
        if (stderr.text) {
          Logger.e("Omarchy", "Error details:", stderr.text.trim())
        }
        ToastService.showError("Omarchy", "Failed to switch theme")
      }
    }

    stdout: StdioCollector {}

    stderr: StdioCollector {}
  }
}
