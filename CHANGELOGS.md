# StatForge Project Tracking

This file is the cross-repository continuation index. It does not replace either repository's conventional `CHANGELOG.md`.

## Canonical records

| Record | Purpose |
|---|---|
| [`AUDIT.md`](AUDIT.md) | Canonical findings, remaining improvements, phases, and priority order across both repositories |
| [`CHANGELOG.md`](CHANGELOG.md) | Addon history plus concise companion-app milestones that affect the shared product |
| [`../StatForge-App/CHANGELOG.md`](../StatForge-App/CHANGELOG.md) | Detailed Electron/React optimizer history |
| [`.hermes/plans/`](.hermes/plans/) | Actionable plans for upcoming milestones |
| [`docs/MANUAL_TEST_MATRIX.md`](docs/MANUAL_TEST_MATRIX.md) | Live Classic-client checks that offline automation cannot certify |

## Current checkpoint — July 16, 2026

- Addon behavior harness: 11 deterministic tests.
- Desktop app: 184 tests across 26 files cover the confidence/sensitivity checkpoint, expanded caster school-module registry, explicit encounter-profile flow, and strict Electron/Vite development-port lifecycle; full lint, TypeScript, and production build pass locally. Standalone Electron verification confirms all four encounter options render, the Dungeon profile updates through React, persists locally, and restores after reload. A controlled port-5173 collision now fails closed instead of moving Vite to 5174 while Electron polls a dead renderer URL.
- Completed optimization foundation: whole-loadout cap handling, enchant resolution, deterministic set thresholds, curated deterministic effects, declarative Mage Arcane/Fire/Frost, Shadow Priest, Affliction Warlock, and Elemental Shaman school modules, explicit Automatic/Solo/Dungeon-boss/Raid-boss effect windows, Pareto DPS/survival recommendation lenses, versioned reproducible analysis snapshots, and five-lens deterministic sensitivity classification.
- Current model boundary: this is not a combat simulator; nondeterministic procs, encounter mechanics beyond duration, unsupported talent tabs, and most class/spec rotations remain unmodeled or explicit fallbacks.

## Next milestone

Continue the deterministic class/spec tranche with the next evidence-supported module while retaining explicit fallback and model-boundary evidence.

Completed implementation plans retained for history:

- [`.hermes/plans/2026-07-15_100520-pareto-front-recommendations.md`](.hermes/plans/2026-07-15_100520-pareto-front-recommendations.md)
- [`.hermes/plans/2026-07-16_063009-reproducible-analysis-snapshots.md`](.hermes/plans/2026-07-16_063009-reproducible-analysis-snapshots.md)
- [`.hermes/plans/2026-07-16_145631-confidence-sensitivity-analysis.md`](.hermes/plans/2026-07-16_145631-confidence-sensitivity-analysis.md)
- [`.hermes/plans/2026-07-16_152821-caster-spec-encounter-modules.md`](.hermes/plans/2026-07-16_152821-caster-spec-encounter-modules.md)
- [`.hermes/plans/2026-07-16_161311-elemental-shaman-school-module.md`](.hermes/plans/2026-07-16_161311-elemental-shaman-school-module.md)
- [`.hermes/plans/2026-07-16_170041-explicit-encounter-profiles.md`](.hermes/plans/2026-07-16_170041-explicit-encounter-profiles.md)

After extending deterministic class/spec and encounter modules:

1. Harden Electron and modernize dependencies in staged branches.
2. Execute and record the live-WoW manual release matrix.

## Closure checklist for every milestone

1. Use RED-GREEN TDD for domain behavior.
2. Keep owned-upgrade and Finder scoring assumptions consistent.
3. Update `AUDIT.md` and each affected repository's `CHANGELOG.md`.
4. Run focused tests, then full tests, lint, TypeScript, production build, and `git diff --check` as applicable.
5. Verify UI changes in the standalone Electron window.
6. Execute live-WoW checks separately when addon behavior changes.
7. Inspect the complete diff and avoid overstating deterministic models.
8. Commit/push clean checkpoints as `Gohan <gohan@local>`.
9. Fetch and verify clean repositories with `0 ahead / 0 behind`.