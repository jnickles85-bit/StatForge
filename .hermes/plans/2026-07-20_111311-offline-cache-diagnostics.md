# Offline cache diagnostics — completed

**Date:** 2026-07-20
**Audit item:** Phase 4.3
**Repositories:** `StatForge-App` implementation; `StatForge` continuity records

## Goal

Give users concrete, local-first visibility into packaged item-data availability and the Electron-owned icon cache without guessing network readiness or exposing renderer filesystem access.

## Completed implementation

- Extracted a tested main-process icon-cache manager.
- Reported exact cached JPEG count, byte size, cache path, and current-session cache hits, downloads, and failures.
- Registered validated, narrow `getIconCacheStats` and `clearIconCache` IPC handlers through the preload bridge.
- Restricted clearing to regular `.jpg` files inside the application-owned `userData/icons` directory.
- Added a Diagnostics panel section showing packaged dataset availability and icon-cache coverage.
- Added refresh plus explicit two-step clear confirmation and error feedback.
- Clarified that cache coverage is concrete local coverage, not a prediction of network or full offline readiness.

## RED-GREEN coverage

- Cache inventory counts and byte totals.
- Runtime activity counters.
- Safe clear behavior that preserves unrelated files and directories.
- Missing cache-directory creation.
- IPC registration and delegation.
- Byte formatting and empty/available/failure user-facing summaries.

## Verification target

- Focused cache tests.
- Full Vitest suite.
- Zero-warning lint.
- TypeScript/production build.
- Windows NSIS and unpacked packaging.
- Packaged Electron smoke gate.
- Standalone Electron visual inspection.
- Exact-SHA GitHub Actions success and 0 ahead / 0 behind repository synchronization.

## Scope boundary

This milestone does not claim that every application asset or network-dependent behavior is available offline. It reports the packaged item dataset and the icon files demonstrably present on the local machine. It does not change the addon export schema.
