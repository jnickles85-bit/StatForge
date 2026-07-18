# Custom encounter duration milestone

**Date:** 2026-07-17

**Status:** Completed and verified July 18, 2026.

## Goal

Add a user-supplied deterministic encounter window without claiming to model rotations or encounter mechanics. The chosen duration changes only verified fixed-duration/fixed-cooldown effect uptime and must be shared by owned-item analysis, Upgrade Finder objectives, local persistence, and reproducible snapshots.

## Contract

- Add `custom` to the encounter-profile IDs and UI options.
- Accept a custom duration in whole seconds from **5 through 3600**.
- Use **60 seconds** as the explicit default when Custom is first selected or a persisted duration is invalid.
- Do not silently infer mechanics from duration; assumptions must say `custom encounter window`.
- Preserve `auto`, `solo`, `dungeon`, and `raid` behavior exactly.
- Old snapshots without encounter settings continue to normalize to `auto`; snapshots using `custom` must contain a valid custom duration.
- Bump the deterministic analysis model/component version because duration is a reproducible scoring input.
- No addon schema change is required.

## RED-GREEN sequence

1. **Spec model RED:** add focused tests proving a valid custom duration reaches `EncounterModel` and assumptions, while invalid values normalize to 60 seconds. Run and observe the expected failure.
2. **Spec model GREEN:** add the custom profile, bounds/default constants, normalization, and custom encounter description. Re-run focused tests.
3. **Owned-upgrade RED/GREEN:** prove a custom duration changes deterministic on-use uptime through `findUpgrades`; thread the duration through the engine.
4. **Finder RED/GREEN:** prove the same duration reaches both Finder objective models; thread the option consistently.
5. **Snapshot RED/GREEN:** round-trip `customEncounterDurationSec`, reject a custom snapshot without a valid duration, preserve legacy `auto`, and bump model identity.
6. **UI:** persist the custom duration, show a labeled numeric seconds control only for `custom`, pass it to both analysis paths and snapshots, and restore it during replay.
7. **Standalone Electron verification:** launch the real Electron app on verified StatForge port 5173; choose Custom, edit duration, confirm persistence after reload, and verify the visible control and assumption/result behavior.
8. **Documentation/continuity:** update app README/changelog plus addon/tracking CHANGELOG, AUDIT, CHANGELOGS, and this completed plan reference. Explicitly state no addon schema change.
9. **Closure:** run focused tests and `tsc`, then full app tests/lint/build/`git diff --check`, addon tests/`git diff --check`, inspect exact diffs and secret scan, commit/push both repositories as Gohan, verify exact-SHA CI, fetch, and confirm clean 0-ahead/0-behind synchronization.
