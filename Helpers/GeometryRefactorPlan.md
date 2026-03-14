# Geometry Refactor Plan

This document is the working reference for geometry cleanup across shell surfaces.
It is intended for humans and subagents.

## Goal

Make bar/panel/overlay geometry deterministic and shared, so visual surfaces, input masks,
and exclusion zones use the same math with scale-aware tolerances.

## Source of Truth

- `Modules/MainScreen/Backgrounds/ShellGeometryPolicy.qml`
  - bar config (position, floating, framed, margins, thickness)
  - bar visual rect
  - corner states
  - bar window margins/sizing
  - exclusion and avoidance insets
- `Modules/MainScreen/Backgrounds/SurfaceRenderPolicy.qml`
  - pixel snapping
  - scale-aware epsilon/tolerance helpers

## Completed

1. Centralized bar geometry and corner states in `ShellGeometryPolicy`.
2. Migrated bar placeholder/corners in `MainScreen` to policy outputs.
3. Migrated `Bar.qml` corner-state logic to policy outputs.
4. Migrated `BarContentWindow`, `BarExclusionZone`, and `BarTriggerZone` to policy outputs.
5. Replaced hardcoded `<= 1` geometry tolerances in `SmartPanel` with scale-aware epsilon checks.
6. Migrated Notification/Toast bar offset math to shared bar-avoidance insets.
7. Migrated Dock phase A by routing bar config, same-edge offsets, and center-span calculations to shared policy in `Modules/Dock/Dock.qml`.
8. Migrated OSD and desktop widget edit-panel bar offset logic to shared policy insets.
9. Migrated settings panel bar attachment geometry bindings to shared bar config.
10. Migrated static dock panel, launcher panel, and wallpaper panel bar-position binding to shared bar config.
11. Migrated tray menu bar-position/height lookups to shared bar config.
12. Migrated bar widget loader, tray drawer panel, and media panel follow-bar lookups to shared bar config.
13. Migrated core bar widgets (`Taskbar`, `ActiveWindow`, `MediaMini`) to shared bar config for orientation/height calculations.
14. Migrated remaining common bar widgets (`Battery`, `Clock`, `Volume`, `SystemMonitor`, `LockKeys`, `CustomButton`, `AudioVisualizer`, `Brightness`, `Network`, `Bluetooth`, `VPN`, `Microphone`, `KeyboardLayout`, `KeepAwake`, `Spacer`) to shared bar config for orientation/height calculations.
15. Migrated `BarPill`, legacy `BarExclusionZone`, and `AllScreens` bar-position wiring to shared bar config.

## In Progress / Next

1. Dock parity sweep: validate `wrapperBleed` sizing and alignment behavior across scale/position matrix.
2. Taskbar/Tray local pixel nudges: audit and convert to explicit indicator lane/hit-slop patterns.
3. Consolidate remaining panel/menu bar-position lookups that are still metadata-only and not yet on policy.

## Rules

1. Do not add new bar geometry formulas directly in feature modules.
2. Add geometry helpers to `ShellGeometryPolicy` instead, then consume them.
3. Use `SurfaceRenderPolicy.epsilonForScreen` / `nearlyEqual` for edge-touch checks.
4. Preserve behavior first, then simplify.

## Verification Matrix

Run checks across:

- bar position: `top`, `bottom`, `left`, `right`
- bar mode: `simple`, `floating`, `framed`
- display scale: `1.0`, `1.25`, `1.5`
- display mode: `always_visible`, `auto_hide`, `non_exclusive`

Verify:

- no seams/gaps at bar-panel joins
- no overlap with reserved/exclusion space
- no attach flicker around edge thresholds
- notification/toast offsets remain visually correct
- dock alignment parity (during dock migration)

## Subagent Prompt Template

Use this template for focused geometry tasks:

```
Read-only geometry audit.

Scope:
- <list exact files>

Goal:
- identify duplicated geometry formulas, fixed-pixel nudges, and tolerance hacks
- propose replacement using ShellGeometryPolicy + SurfaceRenderPolicy

Output:
1) ranked issues with path:line
2) exact patch plan (behavior-preserving first)
3) helper API additions needed in ShellGeometryPolicy
4) focused validation checklist
```
