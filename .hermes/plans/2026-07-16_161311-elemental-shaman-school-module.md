# Elemental Shaman School Module Implementation Plan

> **For Hermes:** Implement this plan task-by-task with strict RED-GREEN TDD.

**Goal:** Add a conservative Elemental Shaman Nature-school model using the exported dominant talent tab, without inferring a rotation or changing survival behavior.

**Architecture:** Add a dedicated `shaman-elemental` baseline preset and map the Shaman Elemental talent tab to it. Register only the Elemental-dominant tab in the existing declarative talent-module registry, neutralizing off-school damage and restoring Nature damage at the preset's generic spell-power weight. Unsupported/tied talent evidence retains the baseline fallback.

**Tech Stack:** TypeScript, Vitest, React/Vite/Electron repository gates.

---

### Task 1: Specify Elemental preset selection

**Objective:** Make the existing class/talent selector expose a dedicated Elemental Shaman preset.

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/statWeights.test.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/statWeights.ts`

**Step 1: Write failing test**

Assert that `pickSpecForCharacter('SHAMAN', [31, 0, 0])` returns `shaman-elemental`, that the preset is listed for Shaman, and that its generic spell-power and Nature suffix weights are defined.

**Step 2: Verify RED**

Run: `npx vitest run src/lib/statWeights.test.ts`

Expected: FAIL because the Elemental tab still maps to `shaman-resto`.

**Step 3: Implement minimally**

Add the dedicated preset, class-spec entry, and Elemental tab mapping. Keep Restoration unchanged.

**Step 4: Verify GREEN**

Run: `npx vitest run src/lib/statWeights.test.ts`

Expected: PASS.

### Task 2: Specify conservative Nature-school inference

**Objective:** Apply the existing school-module contract to unambiguous Elemental talent evidence only.

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.test.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.ts`

**Step 1: Write failing test**

Assert that an Elemental-dominant DPS export selects `shaman-elemental`, retains the preset's generic spell-power weight as Nature damage, neutralizes all off-school damage, and names the evidence/model boundary. Assert that tied or unsupported tabs retain fallback behavior.

**Step 2: Verify RED**

Run: `npx vitest run src/lib/specModel.test.ts`

Expected: FAIL because the registry has no Shaman module.

**Step 3: Implement minimally**

Register tab `0` for base preset `shaman-elemental` as a Nature-school module. Do not add Enhancement, Restoration, spell sequences, damage ratios, proc assumptions, or encounter mechanics.

**Step 4: Verify GREEN and integration**

Run: `npx vitest run src/lib/specModel.test.ts src/lib/statWeights.test.ts src/lib/upgradeEngine.test.ts src/lib/upgradeFinder.test.ts && npx tsc --noEmit`

Expected: PASS.

### Task 3: Reconcile documentation and close the checkpoint

**Objective:** Preserve accurate cross-repository continuation state.

**Files:**
- Modify: `C:/Projects/StatForge-App/README.md`
- Modify: `C:/Projects/StatForge-App/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/AUDIT.md`
- Modify: `C:/Projects/StatForge/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/CHANGELOGS.md`

**Step 1: Document the supported evidence and limits**

Record Elemental-dominant → Nature-school support. State that off-school damage is neutral and that unsupported/tied Shaman tabs remain fallback. State that no addon schema changed.

**Step 2: Run final gates**

App: `npm run test && npm run lint && npm run build && git diff --check`

Tracking: `npm test && git diff --check`

**Step 3: Inspect and publish**

Review complete diffs, ensure clean authorship as `Gohan <gohan@local>`, commit each repository separately, push both branches, require exact-SHA CI success, fetch, and verify clean `0 ahead / 0 behind` state.
