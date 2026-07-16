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
- Desktop app: 168 tests across 24 files cover the current reproducible-snapshot checkpoint; full lint, TypeScript, production build, Windows packaging, packaged-app smoke, and native Electron replay verification passed.
- Completed optimization foundation: whole-loadout cap handling, enchant resolution, deterministic set thresholds, curated deterministic effects, initial Mage Arcane/Fire/Frost encounter models, Pareto DPS/survival recommendation lenses, and versioned reproducible analysis snapshots.
- Current model boundary: this is not a combat simulator; nondeterministic procs, richer encounter mechanics, and most class/spec rotations remain unmodeled or explicit fallbacks.

## Next milestone

Add **confidence/sensitivity analysis** over the reproducible snapshot contract so users can see which uncertain assumptions or supported model boundaries change a recommendation.

Completed implementation plans retained for history:

- [`.hermes/plans/2026-07-15_100520-pareto-front-recommendations.md`](.hermes/plans/2026-07-15_100520-pareto-front-recommendations.md)
- [`.hermes/plans/2026-07-16_063009-reproducible-analysis-snapshots.md`](.hermes/plans/2026-07-16_063009-reproducible-analysis-snapshots.md)

After confidence/sensitivity analysis:

1. Extend deterministic class/spec and encounter modules.
2. Harden Electron and modernize dependencies in staged branches.
3. Execute and record the live-WoW manual release matrix.

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