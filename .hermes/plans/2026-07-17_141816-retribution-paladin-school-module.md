# Retribution Paladin Holy-School Module Implementation Plan

> **For Hermes:** Implement this plan task-by-task with strict RED-GREEN TDD.

**Goal:** Add a conservative Retribution Paladin Holy-school damage module using exported dominant talent-tab evidence without pretending to model a complete rotation.

**Architecture:** Reuse the existing `paladin-ret` physical/hybrid preset. Register only Retribution-dominant talent tab 2 in the declarative school-module registry, preserving all physical weights, neutralizing unrelated spell schools, and valuing Holy-only damage at the preset's existing generic spell-power weight. Tied, Holy-dominant, Protection-dominant, and survival-mode inputs retain existing fallback behavior.

**Tech Stack:** TypeScript, Vitest, React/Vite/Electron repository gates.

---

### Task 1: Specify conservative Retribution Holy-school inference

**Objective:** Apply a Holy-only spell-school mapping for unambiguous Retribution-dominant DPS exports.

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.test.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.ts`

**Step 1: Write failing test**

Assert that `getSpecModel('paladin-ret', 'dps', 60, [0, 0, 31])` retains the hybrid preset's physical weights, maps generic spell power to Holy-only damage, neutralizes unrelated schools, and names the Retribution/Holy evidence boundary. Assert that Holy-dominant, Protection-dominant, and tied inputs retain fallback behavior.

**Step 2: Verify RED**

Run: `npx vitest run src/lib/specModel.test.ts`

Expected: FAIL because the registry has no Paladin module.

**Step 3: Implement minimally**

Register tab `2` for base preset `paladin-ret` as a Holy-school module. Do not add spell sequences, Holy/physical damage ratios, seal choice, proc assumptions, or encounter mechanics.

**Step 4: Verify GREEN and integration**

Run: `npx vitest run src/lib/specModel.test.ts src/lib/upgradeEngine.test.ts src/lib/upgradeFinder.test.ts && npx tsc --noEmit`

Expected: PASS.

### Task 2: Reconcile documentation and close the checkpoint

**Objective:** Preserve accurate cross-repository continuation state.

**Files:**
- Modify: `C:/Projects/StatForge-App/README.md`
- Modify: `C:/Projects/StatForge-App/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/AUDIT.md`
- Modify: `C:/Projects/StatForge/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/CHANGELOGS.md`

**Step 1: Document supported evidence and limits**

Record Retribution-dominant → Holy-school support while preserving physical weights. State that unrelated spell schools are neutral, unsupported/tied Paladin tabs remain fallback, no complete rotation is inferred, and the addon schema did not change.

**Step 2: Run final gates**

App: `npm run test && npm run lint && npm run build && git diff --check`

Addon/tracking: `npm test && git diff --check`

**Step 3: Inspect and publish**

Review complete diffs. Commit only with user authorization; if authorized, use `Gohan <gohan@local>`, push both branches, require exact-SHA CI success, fetch, and verify clean `0 ahead / 0 behind` state.
