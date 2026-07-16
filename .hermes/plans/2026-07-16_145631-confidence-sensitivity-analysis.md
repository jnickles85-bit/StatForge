# Confidence and Sensitivity Analysis Implementation Plan

> **For Hermes:** Use test-driven development to implement this plan task-by-task.

**Goal:** Add deterministic, local sensitivity analysis over reproducible Finder snapshots so users can see whether the top recommendation changes across disclosed DPS/survival trade-off scenarios and where model boundaries limit confidence.

**Architecture:** Create a pure `sensitivityAnalysis.ts` domain module that consumes the existing versioned snapshot contract. It will normalize each slot's DPS/survival objective scores, evaluate a small disclosed scenario set, classify the saved rank-one recommendation as Stable, Sensitive, or Model-limited, and expose winner frequency, score range, switching scenarios, and explicit limitation evidence. React will render the report inside the existing snapshot panel; it will not recompute or invent combat outcomes.

**Tech Stack:** TypeScript, Zod-backed snapshot contract, React, Vitest, Tailwind, Electron/Vite.

---

### Task 1: Define sensitivity scenarios and stability contract

**Files:**
- Create: `C:/Projects/StatForge-App/src/lib/sensitivityAnalysis.ts`
- Create: `C:/Projects/StatForge-App/src/lib/sensitivityAnalysis.test.ts`

1. Write a failing test with competing DPS/survival candidates.
2. Run `npx vitest run src/lib/sensitivityAnalysis.test.ts` and confirm the missing module failure.
3. Implement per-slot min-max normalization, deterministic scenario evaluation, stable item-ID tie-breaking, and winner-frequency reporting.
4. Verify the focused test passes.

Scenarios are explicit planning lenses, not probabilities: DPS emphasis (75/25), Balanced (50/50), and Survival emphasis (25/75). Maximum-DPS and Maximum-Survival endpoint outcomes are retained as evidence. Degenerate equal-objective ranges normalize to 1 so an objective shared equally by all candidates does not falsely punish every candidate.

### Task 2: Classify uncertainty and model boundaries

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/sensitivityAnalysis.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/sensitivityAnalysis.test.ts`

1. Add a failing test for recommendation switching across scenarios.
2. Implement `Sensitive` classification and list the exact scenario/winner changes.
3. Add a failing test for unsupported proc/effect evidence.
4. Implement `Model-limited` precedence when unmodeled effects or explicit unsupported/unknown assumptions affect compared candidates.
5. Add empty/single-candidate tests and verify deterministic output.

### Task 3: Render the report in the snapshot panel

**Files:**
- Modify: `C:/Projects/StatForge-App/src/components/AnalysisSnapshotsPanel.tsx`
- Modify: `C:/Projects/StatForge-App/src/components/AnalysisSnapshotsPanel.test.tsx`

1. Add failing static-render tests for the sensitivity summary, classifications, winners, and limitation language.
2. Render a collapsible Confidence & sensitivity section for the current snapshot.
3. Show aggregate counts, per-slot classification, rank-one recommendation, scenario winners, objective-score range, and explicit non-probabilistic trust language.
4. Verify focused domain and component tests.

### Task 4: Update continuity documentation

**Files:**
- Modify: `C:/Projects/StatForge-App/README.md`
- Modify: `C:/Projects/StatForge-App/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/AUDIT.md`
- Modify: `C:/Projects/StatForge/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/CHANGELOGS.md`

Document the implemented scenario set, classification meanings, limitations, unchanged addon schema, and next roadmap item. Refresh stale test totals only after final verification.

### Task 5: Verify the complete tranche

1. Run focused tests during RED/GREEN.
2. Run `npm run lint`, `npm test`, `npm run build`, and `git diff --check` in StatForge-App.
3. Run `npm test` and `git diff --check` in StatForge.
4. Launch the standalone Electron app with a clean project-owned Vite process.
5. Exercise Find Upgrades → Reproducible analysis snapshots → Confidence & sensitivity and verify readable state in the renderer.
6. Stop the tracked development process and verify no orphaned Vite/Electron process remains.
7. Inspect complete diffs and repository statuses. Leave changes uncommitted until the user authorizes commit/push.
