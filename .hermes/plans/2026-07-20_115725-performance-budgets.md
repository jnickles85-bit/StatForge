# StatForge Desktop Phase 4.5 — performance budgets

**Status:** Completed locally; exact-SHA CI pending  
**Date:** 2026-07-20  
**Repositories:** `StatForge-App/master`, `StatForge/main`

## Goal

Replace subjective performance claims with repeatable packaged-Electron measurements and explicit budgets. Measure before optimizing; do not add workers, virtualization, or chunk surgery without a demonstrated budget miss.

## Measurement contract

The packaged application records these bounded milestones:

- Electron app ready from main-process start.
- Renderer DOM ready from main-process start.
- Renderer shell commit from renderer navigation start.
- Local item database ready from renderer navigation start.
- Representative Finder analysis duration using the checked-in demo character and normal full item database.
- Aggregate Electron working-set memory when the benchmark completes.

The benchmark runs the unpacked Windows application six times in isolated application-data directories, discards the first launch as warm-up, and reports median and p95 from five measured launches. This is a repeatable local launch baseline, not an operating-system cold-cache guarantee or end-user hardware universal.

## Budgets

| Metric | Budget | Rationale |
|---|---:|---|
| Electron app ready | 1,500 ms | Main-process initialization should remain lightweight. |
| Renderer DOM ready | 3,000 ms | Includes executable launch and renderer document load. |
| Renderer shell commit | 1,500 ms | Keeps navigation-to-visible-shell responsive. |
| Item database ready | 2,500 ms | Covers local compact JSON fetch, decode, and 15k-record map construction. |
| Representative Finder analysis | 500 ms | Keeps a user-triggered analysis below the obvious blocking threshold. |
| Aggregate Electron working set | 500 MiB | Conservative ceiling across main, renderer, GPU, and utility processes. |

All budgets are ceilings evaluated against p95. Passing on one machine is evidence for that machine/build, not a universal hardware guarantee.

## Implementation

1. Add a tested CommonJS performance tracker shared by Electron runtime and the measurement script.
2. Register fixed IPC for renderer marks and read-only snapshots; validate metric names and finite non-negative values.
3. Add narrow preload methods and typed renderer declarations.
4. Record renderer shell and item-database milestones. In benchmark mode only, run the normal Finder against the checked-in demo fixture and full loaded database.
5. Add a Windows measurement script that launches the packaged executable sequentially with isolated user data, aggregates median/p95, evaluates budgets, and writes a JSON report.
6. Surface the current session snapshot and budget status in Data Diagnostics without presenting it as a universal benchmark.
7. Build/package, execute the benchmark, inspect any misses, and optimize only if evidence requires it.

## Verification

- RED-GREEN tests for validation, assessment, aggregation, and IPC behavior.
- Focused tests, full Vitest suite, zero-warning lint, TypeScript/Vite production build.
- Windows Electron package, packaged smoke test, and packaged performance measurement.
- Standalone visual verification of the Diagnostics performance section.
- Clean worktrees, commits in both repositories, pushes, exact-SHA GitHub Actions success, and local/remote synchronization.

## Recorded result

The final packaged baseline used one discarded warm-up plus five measured launches on Windows 10.0.26200, Ryzen 9 7945HX, 31.2 GiB RAM, Node 22.22.3, and the unpacked Electron 43 app. Every nearest-rank p95 budget passed:

| Metric | Median | p95 | Budget |
|---|---:|---:|---:|
| Electron app ready | 35.13 ms | 36.89 ms | 1,500 ms |
| DOM ready | 285.34 ms | 296.07 ms | 3,000 ms |
| Renderer shell | 212.5 ms | 221.9 ms | 1,500 ms |
| Item database | 366 ms | 370.7 ms | 2,500 ms |
| Finder analysis | 21.9 ms | 22.2 ms | 500 ms |
| Aggregate working set | 378.03 MiB | 378.82 MiB | 500 MiB |

The harness exposed a packaged-only defect before the baseline: root-absolute item-data URLs failed under `file://`. Public data and provenance requests now resolve beside the built index, with RED-GREEN URL tests. The final harness then completed all six launches and loaded the real packaged compact database.

No list virtualization, extra chunk surgery, or Web Worker was added because no measured trace justifies that complexity. The JSON report records every sample and explicitly does not claim OS-cold-cache behavior or universal hardware performance.

Local gates: zero-warning lint; 255/255 tests across 33 files; TypeScript/Vite build; NSIS and unpacked Windows package; packaged 8-second smoke; packaged six-launch performance harness; addon 11/11 behavior tests; `git diff --check`. Standalone visual capture was attempted, but `computer_use` could not revive its ended cua-driver session; no visual claim is made from that failed tool.
