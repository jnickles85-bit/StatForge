# Caster Spec and Encounter Module Expansion Plan

> **For Hermes:** Execute task-by-task with RED-GREEN tests and keep talent inference conservative.

**Goal:** Extend the deterministic school model beyond Mage for class/spec combinations that can be resolved from exported talent-tab dominance without inventing named talent ranks or rotation precision.

**Architecture:** Refactor `specModel.ts` from a Mage-only branch to a declarative talent-module registry. Retain the existing stat presets as the source of generic spell-power weights, derive a supported module's school-specific damage weight from that generic weight, neutralize only the off-school damage fields represented by the preset, and preserve explicit level-based encounter profiles. Add conservative modules for Shadow-dominant Priest and Affliction-dominant Warlock; unsupported or tied tabs keep their existing mixed/base preset and disclose the fallback.

**Tech Stack:** TypeScript, Vitest, existing owned-upgrade/Finder evaluators, React/Electron presentation already consuming `modelAssumption`.

---

### Task 1: Generalize deterministic talent-module resolution

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.test.ts`

1. Add failing tests for a Shadow-dominant Priest and Affliction-dominant Warlock.
2. Add failing fallback tests for unsupported Priest/Warlock tabs and tied exports.
3. Replace the Mage-only conditional with a declarative registry keyed by base preset and dominant tab.
4. Derive school damage weight from the preset's generic `spellPower` weight; do not add independent tuning constants.
5. Preserve survival-mode neutrality and the 30-second leveling / 180-second raid encounter profiles.
6. Run focused tests and `npx tsc --noEmit`.

### Task 2: Verify evaluator integration invariants

**Files:**
- Modify only if a failing regression demonstrates a gap:
  - `C:/Projects/StatForge-App/src/lib/upgradeEngine.test.ts`
  - `C:/Projects/StatForge-App/src/lib/upgradeFinder.test.ts`

1. Confirm owned upgrades and Finder both continue to call `getSpecModel` with exported talent points.
2. Run focused owned-upgrade/Finder tests that cover model assumptions and shared weights.
3. Do not duplicate school resolution in either evaluator or in React.

### Task 3: Update continuity documentation

**Files:**
- Modify: `C:/Projects/StatForge-App/README.md`
- Modify: `C:/Projects/StatForge-App/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/AUDIT.md`
- Modify: `C:/Projects/StatForge/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/CHANGELOGS.md`

Document supported modules, conservative fallbacks, unchanged addon schema, test evidence, and the next unsupported class/spec tranche.

### Task 4: Verify the complete tranche

1. Run `npx vitest run src/lib/specModel.test.ts` during RED/GREEN.
2. Run `npx tsc --noEmit` after the shared model change.
3. Run `npm run lint`, `npm test`, `npm run build`, and `git diff --check` in StatForge-App.
4. Run `npm test` and `git diff --check` in StatForge.
5. Inspect complete diffs for invented constants, duplicated resolution, secrets, and unrelated changes.
6. Exercise the standalone Electron recommendation path if the rendered assumption surface changed unexpectedly; otherwise rely on the already-covered shared presentation path plus component tests.
7. Leave repositories cleanly documented and ready for an authorized commit/push checkpoint.
