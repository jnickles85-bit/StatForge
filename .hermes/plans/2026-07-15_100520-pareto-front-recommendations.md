# Pareto-Front Recommendations Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Replace the Finder's single-objective ranking with an honest two-objective DPS/survival Pareto front and three deterministic views: Maximum DPS, Balanced, and Maximum Survival.

**Architecture:** Keep the existing DPS and survival scoring models as the two source objectives; do not invent a third EP table. Add a small pure `paretoModel` module that identifies non-dominated candidates and ranks the resulting front for each user view. Integrate it into the Finder first, where many obtainable alternatives exist, while leaving owned-gear/equip decisions on the existing explicit DPS or Survival mode until a later audited slice.

**Tech Stack:** TypeScript, React, Vitest, existing StatForge scoring/upgrade engines.

---

## Current context and decisions

- The current app exposes `WeightMode = 'dps' | 'survival'` in `src/types/index.ts` and evaluates Finder candidates under only the selected mode.
- `src/lib/upgradeFinder.ts` currently drops candidates whose selected-mode score is non-positive, then sorts by one scalar score.
- The Pareto implementation must retain a candidate when it improves at least one objective, even if it sacrifices the other.
- A candidate dominates another when it is no worse in both objective scores and strictly better in at least one.
- “Balanced” must be transparent and deterministic. Rank Pareto candidates by distance to the per-slot normalized ideal point `(1, 1)`; use DPS score, survival score, then item ID as stable tie-breakers.
- Do not label the result “best overall.” The UI should identify the active lens and expose both objective deltas.
- Keep KISS/YAGNI: no user-authored objective weights, simulations, probabilistic effects, or persistence migrations in this slice.

## Task 1: Add the pure Pareto model through RED-GREEN TDD

**Objective:** Implement mathematically correct non-dominance and deterministic profile ranking independent of UI and item data.

**Files:**
- Create: `C:/Projects/StatForge-App/src/lib/paretoModel.ts`
- Create: `C:/Projects/StatForge-App/src/lib/paretoModel.test.ts`
- Modify: `C:/Projects/StatForge-App/src/types/index.ts`

**Step 1: Add the public profile type**

Add:

```ts
export type RecommendationProfile = 'max-dps' | 'balanced' | 'max-survival'
```

Do not expand `WeightMode`; existing scoring functions should continue accepting only real scoring objectives.

**Step 2: Write failing unit tests**

Cover:

1. A candidate dominated in both objectives is removed.
2. DPS-heavy, balanced, and survival-heavy tradeoffs all remain on the front.
3. Equal candidates resolve deterministically by item ID.
4. Negative tradeoff scores remain eligible when the other objective improves.
5. `max-dps` and `max-survival` select the corresponding extreme.
6. `balanced` selects the front member closest to the normalized ideal.
7. Zero-range normalization does not produce `NaN` or unstable ordering.

Use a minimal fixture shape:

```ts
interface ObjectiveCandidate {
  itemId: number
  objectiveScores: { dps: number; survival: number }
}
```

**Step 3: Run RED**

```bash
npm test -- --run src/lib/paretoModel.test.ts
```

Expected: failure because `paretoModel` does not exist.

**Step 4: Implement the minimum pure API**

Export:

```ts
export interface ObjectiveScores {
  dps: number
  survival: number
}

export function paretoFront<T extends { itemId: number; objectiveScores: ObjectiveScores }>(items: T[]): T[]

export function rankParetoFront<T extends { itemId: number; objectiveScores: ObjectiveScores }>(
  items: T[],
  profile: RecommendationProfile,
): T[]
```

Keep comparison, normalization, and tie-breaking private and side-effect free.

**Step 5: Run GREEN and refactor**

```bash
npm test -- --run src/lib/paretoModel.test.ts
npm run lint
```

Expected: all new tests pass and lint reports zero warnings.

## Task 2: Make Finder candidates carry both objective scores

**Objective:** Evaluate every obtainable candidate against the same loadout under both existing scoring objectives before filtering or ranking.

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/upgradeFinder.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/upgradeFinder.test.ts`
- Reuse: `C:/Projects/StatForge-App/src/lib/specModel.ts`
- Reuse: `C:/Projects/StatForge-App/src/lib/scoringModel.ts`

**Step 1: Write failing integration tests**

Add fixtures representing:

- A high-DPS/negative-survival item.
- A moderate item that improves both objectives.
- A high-survival/negative-DPS item.
- One item dominated by the moderate item.

Assert that:

- Each retained `FinderCandidate` exposes `objectiveScores.dps` and `.survival`.
- The three tradeoff items survive candidate generation.
- The dominated item is excluded from the front.
- Cap, enchant, set, and effect deltas are independently scored under each objective rather than copied from the active mode.

**Step 2: Run RED**

```bash
npm test -- --run src/lib/upgradeFinder.test.ts
```

Expected: assertions fail because Finder candidates expose only one `score`.

**Step 3: Refactor candidate evaluation once, score twice**

In `upgradeFinder.ts`:

- Keep shared loadout construction, stat diff, set comparison, effect comparison, and obtainability filters single-pass.
- Resolve a DPS spec model and a Survival spec model.
- Score the same combined stat diff against both weight/cap models.
- Add `objectiveScores` to `FinderCandidate`.
- Preserve the existing `score`, `rawScore`, `effectiveStatDiff`, and `capImpacts` fields as the active display lens to minimize UI churn.
- Retain a candidate if either objective score is positive.
- Compute the per-slot Pareto front before applying `topN`.
- Do not silently discard a negative tradeoff on one objective.

**Step 4: Run GREEN**

```bash
npm test -- --run src/lib/upgradeFinder.test.ts src/lib/paretoModel.test.ts
./node_modules/.bin/tsc --noEmit
```

Expected: all targeted tests pass and TypeScript reports no errors.

## Task 3: Add explicit Finder recommendation lenses

**Objective:** Let users switch among Maximum DPS, Balanced, and Maximum Survival while seeing both objective deltas.

**Files:**
- Modify: `C:/Projects/StatForge-App/src/components/UpgradesPanel.tsx`
- Modify: `C:/Projects/StatForge-App/src/lib/recommendationExplanation.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/recommendationExplanation.test.ts`
- Test in existing component/lib tests where feasible; do not add a new UI framework.

**Step 1: Write failing explanation tests**

Assert that an explanation includes:

- Active recommendation lens.
- DPS objective delta.
- Survival objective delta.
- A statement that the item is non-dominated, not universally best.
- Existing cap/effect/set/enchant assumptions unchanged.

**Step 2: Run RED**

```bash
npm test -- --run src/lib/recommendationExplanation.test.ts
```

**Step 3: Implement the Finder-only selector**

In the Finder section of `UpgradesPanel.tsx`:

- Add a compact three-option segmented control.
- Default to `balanced` for the Finder only.
- Persist to a new key such as `statforge:finder-profile`.
- Do not repurpose the existing global DPS/Survival mode control used by owned upgrades.
- Rank each slot's front with `rankParetoFront` for the selected profile.
- Display compact `DPS +x` and `Survival +y` chips on each candidate.
- Label the list “Pareto recommendations” and explain that changing the lens reorders the same non-dominated set.

**Step 4: Keep accessibility in scope**

- Use actual buttons.
- Provide `aria-pressed` or tab semantics.
- Preserve visible focus styles.
- Do not encode DPS/survival meaning by color alone.

**Step 5: Run GREEN**

```bash
npm test -- --run src/lib/recommendationExplanation.test.ts src/lib/upgradeFinder.test.ts src/lib/paretoModel.test.ts
npm run lint
./node_modules/.bin/tsc --noEmit
```

## Task 4: Protect acquisition planning from unstable lens changes

**Objective:** Ensure route planning consumes intentional Pareto candidates and remains deterministic.

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/acquisitionPlanner.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/acquisitionPlanner.test.ts`

**Step 1: Write failing tests**

Cover:

- Planner receives only the selected/ranked Pareto candidates.
- Changing recommendation lens changes priority order but not source grouping semantics.
- Item-ID tie-breaking keeps plans reproducible.

**Step 2: Run RED**

```bash
npm test -- --run src/lib/acquisitionPlanner.test.ts
```

**Step 3: Implement the smallest adapter**

Prefer passing already-ranked Finder results into the existing planner. Do not duplicate Pareto math inside `acquisitionPlanner.ts`.

**Step 4: Run GREEN**

```bash
npm test -- --run src/lib/acquisitionPlanner.test.ts src/lib/upgradeFinder.test.ts src/lib/paretoModel.test.ts
```

## Task 5: Update product documentation and the audit honestly

**Objective:** Record what the Pareto slice does and what it does not prove.

**Files:**
- Modify: `C:/Projects/StatForge-App/README.md`
- Modify: `C:/Projects/StatForge-App/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/AUDIT.md`

**Steps:**

1. Mark Phase 3 item 6 complete only after all gates pass.
2. Explain the dominance rule and the three ranking lenses.
3. State that “Balanced” is normalized distance to the per-slot ideal, not a simulation or universal truth.
4. Keep uncertainty/sensitivity analysis and reproducible snapshots open.
5. Refresh stale audit facts while editing:
   - Update the test count from 141 to the actual post-change count.
   - Remove the obsolete broken-lint claim.
   - Rewrite the executive-summary claim that caps/effects/enchants/set bonuses are entirely unmodeled.
   - Update H1 next steps to show Mage spec modules are partial rather than absent.
6. Do not rewrite the historical July 11 verification snapshot as if it were current; label it historical or add a clearly dated current checkpoint.

## Task 6: Full verification, native-window review, and clean checkpoints

**Objective:** Prove behavior, inspect the resulting UI, and leave both repositories synchronized.

**Step 1: Run complete app gates**

```bash
npm run test
npm run lint
./node_modules/.bin/tsc --noEmit
npm run build
git diff --check
```

Expected: all tests pass, lint has zero warnings, TypeScript and production build pass, and no whitespace errors appear.

**Step 2: Inspect the complete diff**

Check for:

- Duplicate DPS/survival evaluation logic.
- Mutation of input arrays.
- Unstable sorting.
- Incorrect treatment of negative tradeoffs.
- UI claims such as “best” that overstate Pareto results.
- Unrelated formatting churn.

**Step 3: Verify the standalone Electron app**

```bash
npm run electron:dev
```

Verify in the native window:

- Three recommendation lenses are visible and keyboard reachable.
- Switching lenses reorders candidates without changing the underlying front.
- Both objective deltas remain readable at the normal window size.
- Empty/single-candidate slots render cleanly.
- No new console errors occur.

Stop the development process after verification.

**Step 4: Verify addon documentation repository**

```bash
cd C:/Projects/StatForge
npm run test
git diff --check
```

Expected: 11 addon behavior tests pass and the audit diff is clean.

**Step 5: Commit only after all checks pass**

App checkpoint:

```bash
git add README.md CHANGELOG.md src
git commit -m "feat: add pareto recommendation lenses"
git push origin master
```

Audit checkpoint:

```bash
git add AUDIT.md
git commit -m "docs: record pareto recommendations"
git push origin main
```

Author must remain `Gohan <gohan@local>`.

**Step 6: Final synchronization check**

For each repository, fetch and verify a clean tree with `0 ahead / 0 behind`.

---

## Risks and tradeoffs

- DPS and survival score magnitudes are not naturally comparable; normalize per slot before computing the balanced ideal distance and disclose that rule.
- The Pareto front can be large when many items have tiny tradeoffs. Use deterministic equality/tolerance handling and retain the existing `topN` only after front construction/ranking.
- Survival scores may be sparse for some specs. Zero-range handling must be explicit so Balanced does not collapse unpredictably.
- Do not let the Finder profile mutate owned-upgrade mode, saved-loadout mode, or current gear recommendations.
- Effect assumptions can differ by encounter profile. Both objective evaluations must use the same character/encounter window so the comparison changes only objective weights.

## Deferred after this milestone

1. Phase 3.7 reproducible analysis snapshots.
2. Confidence/sensitivity ranges.
3. Remaining class/spec rotation modules.
4. Electron hardening.
5. Staged dependency modernization.
6. Live-WoW manual release matrix.
