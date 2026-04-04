const ICON_RENDER_RATIO = 0.8;
const HOVER_WINDOW_CAP = 5;
const ACTIVE_WINDOW_CAP = 6;

function toOdd(n) {
  const value = Math.max(1, Number(n) || 0);
  return Math.floor(value / 2) * 2 + 1;
}

function buildMetrics(options) {
  options = options || {};
  const capsuleHeight = Math.max(1, Number(options.capsuleHeight) || 1);
  const iconScale = Math.max(0.1, Number(options.iconScale) || 1);
  const marginXXS = Math.max(1, Number(options.marginXXS) || 1);
  const marginXS = Math.max(1, Number(options.marginXS) || marginXXS);
  const iconSlotExtent = toOdd(capsuleHeight);
  const iconRenderExtent = toOdd(capsuleHeight * iconScale * ICON_RENDER_RATIO);
  const spacingUnit = marginXXS;
  const visualGap = marginXS;
  const restingWidth = iconSlotExtent;
  const anchorWidth = restingWidth;
  const pillGap = visualGap;
  const drawerInset = spacingUnit;
  const drawerJoinOverlap = spacingUnit;
  const activePanelInset = drawerJoinOverlap;
  const hoverPanelInset = drawerJoinOverlap;
  const activePanelLeadingInset = 2 * visualGap;
  const activePanelTrailingInset = 2 * visualGap;
  const hoverPanelLeadingInset = 2 * visualGap;
  const hoverPanelTrailingInset = 2 * visualGap;
  const panelIconGap = visualGap;
  const activePanelMinLength = toOdd(iconSlotExtent + activePanelLeadingInset + activePanelTrailingInset);
  const hoverPanelMinLength = toOdd(iconSlotExtent + hoverPanelLeadingInset + hoverPanelTrailingInset);
  const indicatorThickness = 2;
  const indicatorWidth = Math.max(indicatorThickness, toOdd(iconRenderExtent * 0.3));

  return {
    capsuleHeight,
    iconScale,
    spacingUnit,
    restingWidth,
    anchorWidth,
    pillGap,
    drawerInset,
    drawerJoinOverlap,
    activePanelInset,
    hoverPanelInset,
    activePanelLeadingInset,
    activePanelTrailingInset,
    hoverPanelLeadingInset,
    hoverPanelTrailingInset,
    panelIconGap,
    activePanelMinLength,
    hoverPanelMinLength,
    iconSlotExtent,
    iconRenderExtent,
    indicatorThickness,
    indicatorWidth,
    hoverWindowCap: HOVER_WINDOW_CAP,
    activeWindowCap: ACTIVE_WINDOW_CAP,
  };
}

function slotCount(visibleCount, overflowCount) {
  return Math.max(0, visibleCount) + (overflowCount > 0 ? 1 : 0);
}

function panelLength(visibleCount, overflowCount, slotExtent, gap, leadingInset, trailingInset) {
  const slots = slotCount(visibleCount, overflowCount);
  const contentLength = slots > 0 ? slots * slotExtent + Math.max(0, slots - 1) * gap : 0;
  const startInset = Math.max(0, Number(leadingInset) || 0);
  const endInset = trailingInset === undefined ? startInset : Math.max(0, Number(trailingInset) || 0);
  return toOdd(startInset + endInset + contentLength);
}

function pillMainLength(anchorWidth, visibleCount, overflowCount, slotExtent, gap, leadingInset, trailingInset, overlapInset) {
  const panel = panelLength(visibleCount, overflowCount, slotExtent, gap, leadingInset, trailingInset);
  return toOdd(anchorWidth + panel - Math.max(0, Number(overlapInset) || 0));
}

function capsuleMainLength(labelExtent, visibleCount, overflowCount, slotExtent, gap, innerPadding) {
  return toOdd(labelExtent + gap + panelLength(visibleCount, overflowCount, slotExtent, gap, innerPadding, innerPadding));
}

function visibleItems(items, cap) {
  if (!Array.isArray(items))
    return [];
  return items.slice(0, Math.max(0, cap));
}

function overflowCount(items, cap) {
  if (!Array.isArray(items))
    return 0;
  return Math.max(0, items.length - Math.max(0, cap));
}

if (typeof module !== "undefined") {
  module.exports = {
    buildMetrics,
    capsuleMainLength,
    overflowCount,
    panelLength,
    pillMainLength,
    slotCount,
    toOdd,
    visibleItems,
  };
}
