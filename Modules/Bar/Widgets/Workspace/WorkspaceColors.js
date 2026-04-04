function clamp01(value) {
  return Math.max(0, Math.min(1, Number(value) || 0));
}

function normalizeHex(color) {
  if (color === undefined || color === null)
    return "#000000";

  const value = color.toString().trim().toLowerCase();
  if (value === "transparent")
    return "#00000000";
  if (/^#[0-9a-f]{6}$/.test(value) || /^#[0-9a-f]{8}$/.test(value))
    return value;
  return "#000000";
}

function parseColor(color) {
  const normalized = normalizeHex(color);
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

function toHexChannel(value) {
  const rounded = Math.max(0, Math.min(255, Math.round(Number(value) || 0)));
  return rounded.toString(16).padStart(2, "0");
}

function toHex(color, forceAlpha) {
  const alpha = clamp01(color.a);
  if (forceAlpha || alpha < 0.999) {
    return "#" + toHexChannel(alpha * 255) + toHexChannel(color.r) + toHexChannel(color.g) + toHexChannel(color.b);
  }
  return "#" + toHexChannel(color.r) + toHexChannel(color.g) + toHexChannel(color.b);
}

function withAlpha(color, alpha) {
  const parsed = parseColor(color);
  parsed.a = clamp01(alpha);
  return toHex(parsed, true);
}

function mixColors(leftColor, rightColor, ratio) {
  const t = clamp01(ratio);
  const left = parseColor(leftColor);
  const right = parseColor(rightColor);

  return toHex({
    r: left.r + (right.r - left.r) * t,
    g: left.g + (right.g - left.g) * t,
    b: left.b + (right.b - left.b) * t,
    a: left.a + (right.a - left.a) * t,
  }, left.a < 0.999 || right.a < 0.999);
}

function compositeOver(overColor, underColor) {
  const top = parseColor(overColor);
  const bottom = parseColor(underColor);
  const alpha = top.a + bottom.a * (1 - top.a);

  if (alpha <= 0)
    return "#00000000";

  return toHex({
    r: (top.r * top.a + bottom.r * bottom.a * (1 - top.a)) / alpha,
    g: (top.g * top.a + bottom.g * bottom.a * (1 - top.a)) / alpha,
    b: (top.b * top.a + bottom.b * bottom.a * (1 - top.a)) / alpha,
    a: alpha,
  }, alpha < 0.999);
}

function resolveVisibleColor(color, backdrop) {
  const normalized = normalizeHex(color);
  if (!backdrop)
    return normalized;

  const parsed = parseColor(normalized);
  if (parsed.a >= 0.999)
    return normalized;
  return compositeOver(normalized, backdrop);
}

function relativeLuminance(color, backdrop) {
  const parsed = parseColor(resolveVisibleColor(color, backdrop));

  function channel(value) {
    const srgb = value / 255;
    if (srgb <= 0.03928)
      return srgb / 12.92;
    return Math.pow((srgb + 0.055) / 1.055, 2.4);
  }

  return 0.2126 * channel(parsed.r) + 0.7152 * channel(parsed.g) + 0.0722 * channel(parsed.b);
}

function contrastRatio(background, foreground, backdrop) {
  const resolvedBackground = resolveVisibleColor(background, backdrop);
  const resolvedForeground = resolveVisibleColor(foreground, resolvedBackground);
  const bg = relativeLuminance(resolvedBackground);
  const fg = relativeLuminance(resolvedForeground);
  const lighter = Math.max(bg, fg);
  const darker = Math.min(bg, fg);
  return (lighter + 0.05) / (darker + 0.05);
}

function pickReadableForeground(background, candidates, backdrop) {
  let best = normalizeHex(candidates && candidates.length > 0 ? candidates[0] : "#ffffff");
  let bestRatio = -1;

  for (let i = 0; i < (candidates || []).length; i++) {
    const candidate = normalizeHex(candidates[i]);
    const ratio = contrastRatio(background, candidate, backdrop);
    if (ratio > bestRatio) {
      best = candidate;
      bestRatio = ratio;
    }
  }

  return best;
}

function preferReadableForeground(background, preferred, fallbacks, backdrop, minRatio) {
  const preferredColor = normalizeHex(preferred);
  const minimum = minRatio === undefined ? 4.5 : minRatio;
  if (contrastRatio(background, preferredColor, backdrop) >= minimum)
    return preferredColor;
  return pickReadableForeground(background, fallbacks, backdrop);
}

function effectivePanelBackgroundOpacity(darkMode, panelBackgroundOpacity) {
  const base = clamp01(panelBackgroundOpacity === undefined ? 1 : panelBackgroundOpacity);
  return darkMode ? base : Math.pow(base, 2);
}

function smartAlphaEquivalent(color, options, minAlpha) {
  const parsed = parseColor(color);
  if (!options.translucentWidgets)
    return toHex(parsed, parsed.a < 0.999);

  const alpha = Math.max(effectivePanelBackgroundOpacity(options.darkMode, options.panelBackgroundOpacity), clamp01(minAlpha));
  const resultAlpha = Math.max(0, parsed.a - (1 - alpha));
  return toHex({
    r: parsed.r,
    g: parsed.g,
    b: parsed.b,
    a: resultAlpha,
  }, true);
}

function applyCapsuleOpacity(color, capsuleOpacity) {
  const parsed = parseColor(color);
  parsed.a = Math.min(parsed.a, clamp01(capsuleOpacity === undefined ? 1 : capsuleOpacity));
  return toHex(parsed, parsed.a < 0.999);
}

function neutralCapsuleBase(options) {
  const rawCapsule = options.showCapsule
    ? applyCapsuleOpacity(options.capsuleColor, options.capsuleOpacity)
    : options.surfaceVariant;

  const resolvedCapsule = resolveVisibleColor(rawCapsule, options.surface);
  if (options.capsuleColorKey && options.capsuleColorKey !== "none") {
    return mixColors(options.surfaceVariant, resolvedCapsule, options.darkMode ? 0.18 : 0.12);
  }
  return resolvedCapsule;
}

function tonedSurface(baseColor, tintColor, tintAmount, options, minAlpha) {
  return smartAlphaEquivalent(mixColors(baseColor, tintColor, tintAmount), options, minAlpha);
}

function buildPalette(rawOptions) {
  const options = {
    darkMode: !!rawOptions.darkMode,
    translucentWidgets: rawOptions.translucentWidgets !== false,
    panelBackgroundOpacity: rawOptions.panelBackgroundOpacity === undefined ? 1 : rawOptions.panelBackgroundOpacity,
    showCapsule: rawOptions.showCapsule !== false,
    capsuleOpacity: rawOptions.capsuleOpacity === undefined ? 1 : rawOptions.capsuleOpacity,
    capsuleColorKey: rawOptions.capsuleColorKey || "none",
    capsuleColor: normalizeHex(rawOptions.capsuleColor || rawOptions.surfaceVariant || "#000000"),
    capsuleBorderColor: normalizeHex(rawOptions.capsuleBorderColor || rawOptions.outline || "#000000"),
    primary: normalizeHex(rawOptions.primary || "#ffffff"),
    onPrimary: normalizeHex(rawOptions.onPrimary || "#000000"),
    hover: normalizeHex(rawOptions.hover || "#ffffff"),
    onHover: normalizeHex(rawOptions.onHover || "#000000"),
    surface: normalizeHex(rawOptions.surface || rawOptions.surfaceVariant || "#000000"),
    surfaceVariant: normalizeHex(rawOptions.surfaceVariant || "#000000"),
    onSurface: normalizeHex(rawOptions.onSurface || "#ffffff"),
    onSurfaceVariant: normalizeHex(rawOptions.onSurfaceVariant || rawOptions.onSurface || "#ffffff"),
    outline: normalizeHex(rawOptions.outline || rawOptions.capsuleBorderColor || "#000000"),
  };

  const neutralBase = neutralCapsuleBase(options);
  const panelBackdrop = options.surface;
  const emptyShellFill = tonedSurface(neutralBase, options.onSurface, options.darkMode ? 0.02 : 0.03, options, options.darkMode ? 0.16 : 0.10);
  const occupiedShellFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.04 : 0.03, options, options.darkMode ? 0.18 : 0.10);
  const activeShellFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.08 : 0.06, options, options.darkMode ? 0.26 : 0.15);
  const hoverShellFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.06 : 0.04, options, options.darkMode ? 0.22 : 0.12);
  const emptyAnchorFill = tonedSurface(neutralBase, options.onSurface, options.darkMode ? 0.03 : 0.05, options, options.darkMode ? 0.18 : 0.11);
  const occupiedAnchorFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.08 : 0.06, options, options.darkMode ? 0.24 : 0.14);
  const hoverAnchorFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.12 : 0.09, options, options.darkMode ? 0.30 : 0.18);
  const panelFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.12 : 0.10, options, options.darkMode ? 0.36 : 0.22);
  const hoverPanelFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.08 : 0.06, options, options.darkMode ? 0.26 : 0.16);

  const anchorFill = options.primary;
  const anchorText = preferReadableForeground(anchorFill, options.onPrimary, [options.onPrimary, options.onSurface, options.onSurfaceVariant, "#ffffff", "#000000"], panelBackdrop, 4.5);
  const emptyAnchorText = preferReadableForeground(emptyAnchorFill, options.onSurface, [options.onSurface, options.onSurfaceVariant, "#ffffff", "#000000"], panelBackdrop, 4.5);
  const occupiedAnchorText = preferReadableForeground(occupiedAnchorFill, options.onPrimary, [options.onPrimary, options.onSurface, options.onSurfaceVariant, "#ffffff", "#000000"], panelBackdrop, 4.5);
  const hoverAnchorText = preferReadableForeground(hoverAnchorFill, options.onPrimary, [options.onPrimary, options.onSurface, options.onSurfaceVariant, "#ffffff", "#000000"], panelBackdrop, 4.5);
  const panelIconColor = preferReadableForeground(panelFill, options.onPrimary, [options.onPrimary, options.onSurface, options.onSurfaceVariant, "#ffffff", "#000000"], panelBackdrop, 4.5);
  const hoveredIconColor = preferReadableForeground(hoverPanelFill, options.onPrimary, [options.onPrimary, options.onSurface, options.onSurfaceVariant, "#ffffff", "#000000"], panelBackdrop, 4.5);
  const focusedChipFill = options.primary;
  const focusedChipText = preferReadableForeground(focusedChipFill, options.onPrimary, [options.onPrimary, options.onSurface, "#000000", "#ffffff"], panelBackdrop, 4.5);
  const activeOverflowFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.20 : 0.14, options, options.darkMode ? 0.56 : 0.30);
  const hoverOverflowFill = tonedSurface(neutralBase, options.primary, options.darkMode ? 0.12 : 0.08, options, options.darkMode ? 0.34 : 0.20);
  const focusIndicatorColor = options.primary;

  return {
    anchorFill,
    anchorText,
    activeShellFill,
    hoverShellFill,
    focusedChipFill,
    focusedChipText,
    panelFill,
    hoverPanelFill,
    panelIconColor,
    hoveredIconColor,
    focusIndicatorColor,
    emptyShellFill,
    occupiedShellFill,
    emptyShellBorder: withAlpha(options.capsuleBorderColor, options.darkMode ? 0.48 : 0.28),
    occupiedShellBorder: withAlpha(options.capsuleBorderColor, options.darkMode ? 0.62 : 0.34),
    activeShellBorder: withAlpha(options.primary, options.darkMode ? 0.32 : 0.24),
    hoverShellBorder: withAlpha(options.primary, options.darkMode ? 0.22 : 0.16),
    emptyAnchorFill,
    occupiedAnchorFill,
    hoverAnchorFill,
    emptyAnchorText,
    occupiedAnchorText,
    hoverAnchorText,
    emptyAnchorBorder: withAlpha(options.capsuleBorderColor, options.darkMode ? 0.08 : 0.10),
    occupiedAnchorBorder: withAlpha(options.primary, options.darkMode ? 0.16 : 0.12),
    hoverAnchorBorder: withAlpha(options.primary, options.darkMode ? 0.24 : 0.18),
    activeAnchorBorder: withAlpha(options.primary, options.darkMode ? 0.18 : 0.24),
    focusedChipBorder: withAlpha(options.primary, options.darkMode ? 0.30 : 0.22),
    activeOverflowFill,
    hoverOverflowFill,
    activeOverflowText: focusedChipText,
    hoverOverflowText: hoveredIconColor,
  };
}

if (typeof module !== "undefined") {
  module.exports = {
    buildPalette,
    contrastRatio,
    pickReadableForeground,
  };
}
