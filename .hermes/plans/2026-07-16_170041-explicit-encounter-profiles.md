# Explicit Encounter Profiles Implementation Plan

> **For Hermes:** Use strict RED-GREEN TDD and complete each task in order.

**Goal:** Let users explicitly model solo, dungeon-boss, or raid-boss encounter windows while retaining the current level-sensitive automatic default, and preserve that choice in reproducible analysis snapshots.

**Architecture:** Extend the pure `specModel` encounter resolver with a small declarative profile registry. Thread the selected profile through owned-upgrade and Finder scoring so deterministic on-use uptime uses one shared encounter window. Persist and replay the profile through the existing version-1 snapshot settings with an `auto` default for older snapshot files, then expose it as one accessible Upgrades control.

**Tech Stack:** TypeScript, React, Vitest, Zod, Electron, Vite.

---

### Task 1: Add explicit encounter resolution

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.test.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.ts`

1. Add tests showing `auto` retains 30-second leveling / 180-second raid behavior and explicit `solo`, `dungeon`, and `raid` profiles resolve to 30, 90, and 180 seconds with human-readable assumptions.
2. Run `npx vitest run src/lib/specModel.test.ts`; expect failures because profile arguments/registry do not exist.
3. Add `EncounterProfileId`, exported profile options, resolver logic, and an optional profile argument to `getSpecModel`.
4. Re-run the focused test; expect PASS.

### Task 2: Thread the profile through both scoring paths

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/upgradeEngine.test.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/upgradeEngine.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/upgradeFinder.test.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/upgradeFinder.ts`

1. Add an owned-upgrade test proving a dungeon profile gives the registered 30-second on-use effect `30/90` uptime.
2. Run that test and verify RED because `findUpgrades` cannot accept the profile.
3. Add an optional encounter-profile argument and pass it to `getSpecModel`; verify GREEN.
4. Add the equivalent FinderOptions test and verify RED.
5. Add `encounterProfile` to `FinderOptions`, route it to both DPS and survival spec models, and verify GREEN.
6. Run both focused test files plus `npx tsc --noEmit`.

### Task 3: Preserve the setting in reproducible snapshots

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/analysisSnapshot.test.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/analysisSnapshot.ts`
- Modify typed fixtures only where TypeScript requires the new setting.

1. Add tests that newly created snapshots embed `encounterProfile`, replay comparison detects profile drift, and a legacy version-1 snapshot without the field parses as `auto`.
2. Run `npx vitest run src/lib/analysisSnapshot.test.ts`; expect RED.
3. Extend snapshot settings with a Zod default of `auto`, add the typed input field, and bump the deterministic model version/component identity because score semantics now include an explicit encounter choice.
4. Verify the focused test and `npx tsc --noEmit` pass.

### Task 4: Add and replay the UI control

**Files:**
- Modify: `C:/Projects/StatForge-App/src/components/UpgradesPanel.tsx`
- Modify snapshot/component fixtures if required by type checking.

1. Add persisted `statforge:encounterProfile` state with validation and default `auto`.
2. Pass the profile to owned-upgrade scoring, Finder scoring, and snapshot creation.
3. Restore it during snapshot replay.
4. Render a labeled/selectable encounter control with Auto, Solo (30s), Dungeon boss (90s), and Raid boss (180s).
5. Run `npx tsc --noEmit` and the affected component/snapshot tests.

### Task 5: Documentation, runtime exercise, and closure

**Files:**
- Modify: `C:/Projects/StatForge-App/README.md`
- Modify: `C:/Projects/StatForge-App/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/AUDIT.md`
- Modify: `C:/Projects/StatForge/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/CHANGELOGS.md`

1. Document that profiles change deterministic on-use uptime only; they do not claim a combat simulation, movement model, phase timing, shared cooldowns, or proc probabilities.
2. Launch standalone Electron after verifying port ownership/title; exercise at least Auto and Dungeon boss and verify visible assumption/score updates.
3. Stop Electron and verify no project Vite/Electron descendants remain.
4. Run app gates: `npm run test && npm run lint && npm run build && git diff --check`.
5. Run addon/tracking gates: `npm test && git diff --check`.
6. Inspect complete diffs, commit as `Gohan <gohan@local>`, push both repositories, require exact-SHA CI success, fetch, and verify clean `0 ahead / 0 behind` repositories.
