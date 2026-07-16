# Reproducible Analysis Snapshots Implementation Plan

> **For Hermes:** Execute this plan through RED-GREEN TDD and verify the standalone Electron UI before closing Phase 3.7.

**Goal:** Let StatForge save, export, import, and replay a Finder analysis with enough immutable context to audit and reproduce the imported character/loadout, deterministic model identity, visible assumptions, and objective-score breakdowns.

**Architecture:** Add a pure, versioned `analysisSnapshot` domain module. A snapshot embeds the validated `StatForge-v1` character export, Finder controls, an explicit optimizer/model-component version, exact item-data SHA-256, normalized assumptions, and deterministic per-slot candidate breakdowns. Keep lifecycle UI in a focused `AnalysisSnapshotsPanel`; replays restore the embedded character and Finder controls, recompute locally, and report exact match or drift. Persist snapshots only in localStorage and support local JSON files—no account service or upload.

**Tech Stack:** TypeScript, Zod, React, Vitest, existing Finder/spec/cap/effect/set/Pareto models, Electron/Vite.

---

## Contract decisions

- Contract discriminator: `StatForge-AnalysisSnapshot-v1`; schema version `1`.
- Optimizer model ID/version is independent of the app package version and must be bumped whenever scoring, eligibility, Pareto, cap, set, effect, spec, or result-normalization behavior changes.
- Model identity includes the generated item-data manifest parser version and compact-data SHA-256. A snapshot from different item bytes is not an exact reproduction.
- Inputs include the entire validated `StatForge-v1` export plus Finder settings: spec, recommendation lens, phase cap, objective mode, and per-slot result limit.
- Results preserve slot order and candidate order plus item/baseline identity, DPS and survival deltas, selected-lens utility, stat deltas, cap impacts, set impacts, effect impacts, model/cap/effect assumptions, and source identity.
- Volatile fields (`id`, `name`, `createdAt`) are metadata and are excluded from deterministic replay comparison.
- Replay is honest: restore embedded inputs/settings, recompute against the current engine/data, then show exact match or a precise compatibility/drift reason. Never silently bless stale scores.
- Imported JSON is runtime validated; malformed, unsupported, non-finite, or wrong-contract files are rejected without mutating active state.
- Character data remains local. Export uses a user-initiated local JSON download; no network upload is added.

## Task 1: Define the versioned snapshot domain through RED-GREEN TDD

**Files:**
- Create `C:/Projects/StatForge-App/src/lib/analysisSnapshot.test.ts`
- Create `C:/Projects/StatForge-App/src/lib/analysisSnapshot.ts`

1. Write failing tests for deterministic normalization, full input retention, model/data identity, visible assumption de-duplication, objective breakdown retention, stable result ordering, metadata-insensitive replay equality, malformed import rejection, unsupported schema/model/data detection, and score drift reporting.
2. Run the focused suite and confirm RED because the module does not exist.
3. Implement the smallest typed builder/parser/serializer/replay-comparison API.
4. Use the existing `statForgeV1Schema` inside the snapshot schema instead of duplicating the addon contract.
5. Run focused tests until GREEN, then lint/type-check.

## Task 2: Add local snapshot lifecycle UI

**Files:**
- Create `C:/Projects/StatForge-App/src/components/AnalysisSnapshotsPanel.tsx`
- Modify `C:/Projects/StatForge-App/src/components/UpgradesPanel.tsx`
- Modify `C:/Projects/StatForge-App/src/App.tsx`

1. Add a compact Finder-only Analysis snapshots section.
2. Save the current completed Finder analysis under an optional name; persist validated snapshots in `statforge:analysisSnapshots`.
3. List local snapshots with character, spec/lens, creation time, model version, data checksum prefix, and candidate count.
4. Support Replay, Export JSON, Import JSON, and Delete using accessible controls and a hidden file input.
5. Replay must restore the embedded character and Finder controls, wait for the item DB, recompute, and display exact match, compatible drift, or incompatibility.
6. Expose model identity, item-data identity, assumptions, and objective totals in the panel so the artifact is auditable before export.
7. Do not add cloud sharing, OS file privileges, arbitrary paths, or a second scoring implementation.

## Task 3: Protect integration behavior

**Files:**
- Extend `C:/Projects/StatForge-App/src/lib/analysisSnapshot.test.ts`
- Modify existing Finder tests only if a domain seam must be exported.

Cover:
- DPS-heavy, balanced, and survival-heavy candidates retain both objective scores.
- Candidate and assumption order is deterministic even if source arrays arrive in a different order.
- Replay ignores timestamp/name/ID but catches input, setting, model, data, assumption, and score changes.
- Import accepts only schema-valid `StatForge-AnalysisSnapshot-v1` data.
- Empty Finder slots and unsupported effects remain representable without invented scores.

## Task 4: Product documentation and audit closure

**Files:**
- Modify `C:/Projects/StatForge-App/README.md`
- Modify `C:/Projects/StatForge-App/CHANGELOG.md`
- Modify `C:/Projects/StatForge/AUDIT.md`
- Modify `C:/Projects/StatForge/CHANGELOG.md`
- Modify `C:/Projects/StatForge/CHANGELOGS.md`

1. Document save/export/import/replay behavior and local-only privacy.
2. State exactly what reproduction proves: identical normalized outputs under the embedded character/settings/model/data contract.
3. State what it does not prove: combat simulation validity, future compatibility, upstream data completeness, or live-client certification.
4. Mark Phase 3.7 complete only after all app/addon gates and native UI verification pass.
5. Set confidence/sensitivity analysis as the next milestone and retain this plan as implementation history.

## Task 5: Full verification and clean checkpoint

1. Run focused snapshot tests.
2. Run `npm test`, `npm run lint`, `npm run build`, and `git diff --check` in StatForge-App.
3. Inspect the complete app diff for unstable ordering, duplicated scoring, unsafe HTML/eval/process execution, secrets, misleading claims, and unrelated churn.
4. Run `npm run electron:dev`; in the standalone window load demo data, open Finder, save a snapshot, export/import it, replay it, and verify exact-match and visible contract metadata. Inspect for UI overflow and console/runtime errors. Stop the dev processes.
5. Run `npm test` and `git diff --check` in StatForge.
6. Review all audit/changelog changes against verified behavior.
7. Commit and push separate clean checkpoints as `Gohan <gohan@local>` only after successful gates, then verify CI and `HEAD == origin/<branch>` with clean trees.

## Deferred

- Confidence intervals and sensitivity analysis.
- Migration of old snapshot schema/model versions.
- Cloud/account sharing.
- Roster-wide batch comparisons.
- Additional class/spec rotations and probabilistic combat simulation.
