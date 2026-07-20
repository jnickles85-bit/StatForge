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

## Current checkpoint — July 20, 2026

- Addon behavior harness: 11 deterministic tests.
- Desktop app: 235 tests across 28 files pass after completing Phase 4.4 accessibility, Phase 4.2 crash/error diagnostics, and Phase 5 What-if planning mode. The July 19 dependency-modernization checkpoint exposed an out-of-sync npm lockfile in GitHub Actions; the omitted Electron Builder Windows Squirrel/signing peer packages were restored July 20. Clean Node 22/npm 10 installation, zero-warning lint, TypeScript/production build, NSIS plus unpacked packaging, and packaged smoke pass locally. Accessibility now covers skip links, ARIA landmarks, tab labels, focus-visible rings, reduced motion, live regions, icon-only button labels, and hidden decorative icons. The opt-in bounded error log and non-destructive What-if sandbox remain local-first.
- Completed optimization foundation: whole-loadout cap handling, enchant resolution, deterministic set thresholds, curated deterministic effects, declarative spec modules, explicit encounter windows, Pareto recommendations, versioned reproducible analysis snapshots, five-lens sensitivity classification, What-if planning, crash/error diagnostics, and full accessibility.
- Current model boundary: this is not a combat simulator; nondeterministic procs, encounter mechanics beyond duration, unsupported talent tabs, and most class/spec rotations remain unmodeled or explicit fallbacks.

## Next milestone

Offline-first icon/data cache status is the last Phase 4 item with no external dependency (Phase 4.3). Phase 4.5 performance budget measurement remains. Phase 5 advanced items (Web Workers, shareable analysis bundles, plugin-like spec model registry) are larger.

Completed implementation plans retained for history:

- [`.hermes/plans/2026-07-15_100520-pareto-front-recommendations.md`](.hermes/plans/2026-07-15_100520-pareto-front-recommendations.md)
- [`.hermes/plans/2026-07-16_063009-reproducible-analysis-snapshots.md`](.hermes/plans/2026-07-16_063009-reproducible-analysis-snapshots.md)
- [`.hermes/plans/2026-07-16_145631-confidence-sensitivity-analysis.md`](.hermes/plans/2026-07-16_145631-confidence-sensitivity-analysis.md)
- [`.hermes/plans/2026-07-16_152821-caster-spec-encounter-modules.md`](.hermes/plans/2026-07-16_152821-caster-spec-encounter-modules.md)
- [`.hermes/plans/2026-07-16_161311-elemental-shaman-school-module.md`](.hermes/plans/2026-07-16_161311-elemental-shaman-school-module.md)
- [`.hermes/plans/2026-07-16_170041-explicit-encounter-profiles.md`](.hermes/plans/2026-07-16_170041-explicit-encounter-profiles.md)

Latest completed implementation plans:

- [`.hermes/plans/2026-07-17_141816-retribution-paladin-school-module.md`](.hermes/plans/2026-07-17_141816-retribution-paladin-school-module.md)
- [`.hermes/plans/2026-07-17_181741-protection-paladin-school-module.md`](.hermes/plans/2026-07-17_181741-protection-paladin-school-module.md)
- [`.hermes/plans/2026-07-17_184001-custom-encounter-duration.md`](.hermes/plans/2026-07-17_184001-custom-encounter-duration.md)

Next sequencing:

1. Add offline-first icon/data cache status (Phase 4.3).
2. Measure app startup/load/render performance against an explicit budget before considering more splitting or virtualization (Phase 4.5).
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