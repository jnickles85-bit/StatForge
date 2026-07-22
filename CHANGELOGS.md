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

## Current checkpoint — July 22, 2026

- Addon behavior harness: 11 deterministic tests.
- Live Classic Era 1.15.9 matrix: intentionally paused after A12 with **9/12 core checks passed**. A1–A5, A7, A9, A10, and A12 have recorded evidence. A6, A8, and A11 remain core release blockers; A13–A14 remain pending. The exact selected setup, visible status rows, equip summary, and resume instructions are preserved in `docs/MANUAL_TEST_MATRIX.md`.
- Desktop app: Phase 4.5 now has fixed performance budgets, a repeatable packaged-Windows harness, and an honest current-session Diagnostics card through narrow typed IPC. One discarded warm-up plus five isolated-profile launches passed every nearest-rank p95 budget; the full machine/method/sample record is in `StatForge-App/docs/performance-baseline.json`. The harness exposed and fixed packaged `file://` item-data URLs before recording the baseline. List virtualization and Web Workers were not added because bounded lists and a 22.2 ms Finder p95 provide no measured justification.
- Completed optimization foundation: whole-loadout cap handling, enchant resolution, deterministic set thresholds, curated deterministic effects, declarative spec modules, explicit encounter windows, Pareto recommendations, versioned reproducible analysis snapshots, five-lens sensitivity classification, What-if planning, crash/error diagnostics, and full accessibility.
- Current model boundary: this is not a combat simulator; nondeterministic procs, encounter mechanics beyond duration, unsupported talent tabs, and most class/spec rotations remain unmodeled or explicit fallbacks.

## Next milestone

Phase 4.5 performance-budget measurement is complete. Resume the paused live-WoW matrix at A11 combat lockdown when a safe combat situation is available, then complete A6 and A8's inventory-dependent evidence plus A13–A14. The release gate remains open until A6, A8, and A11 pass; later class/spec expansion remains evidence-gated.

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
- [`.hermes/plans/2026-07-20_111311-offline-cache-diagnostics.md`](.hermes/plans/2026-07-20_111311-offline-cache-diagnostics.md)
- [`.hermes/plans/2026-07-20_115725-performance-budgets.md`](.hermes/plans/2026-07-20_115725-performance-budgets.md)

Next sequencing:

1. Resume and complete the live-WoW manual release matrix from the checkpoint in `docs/MANUAL_TEST_MATRIX.md`.
2. Continue deterministic class/spec modules only where exported evidence supports a conservative model.

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