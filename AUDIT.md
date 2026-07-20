# StatForge Full Project Audit — July 11, 2026

## Executive summary

StatForge is a two-repository, local-first WoW Classic Hardcore companion:

- **`StatForge`** (`main`) — a pure-Lua Classic Era addon that exports `StatForge-v1` character/gear JSON and imports `SFSETUP1` optimized loadouts.
- **`StatForge-App`** (`master`) — an Electron + React + TypeScript desktop optimizer with a compact local item database, SavedVariables watcher, upgrade engine, Hardcore farming-risk UI, and addon setup export.

**Overall assessment: strong prototype / early product, not yet state of the art.** The core bidirectional loop exists and the app's tested gear-combination logic is substantially better than a typical hobby optimizer. Recommendation fidelity now includes whole-loadout cap, enchant, deterministic set/effect, conservative talent-inferred school modules, explicit and custom encounter durations, Pareto DPS/survival tradeoff lenses, reproducible snapshots, and deterministic sensitivity classification, but it remains an optimizer rather than a combat simulator. The largest remaining gaps are broader evidence-backed class/spec models, offline cache visibility, measured performance budgets, and the live-WoW release matrix.

There are **no verified release-blocking build, lint, type-check, unit-test, Windows-package, packaged-smoke, or native-Electron failures** in the app. Live WoW behavior still requires its documented in-game release checks.

## Verification snapshot — refreshed July 20, 2026

| Check | Result |
|---|---|
| App branch/status | `master`; npm lockfile reproducibility repair verified locally July 20, 2026 |
| Addon branch/status | `main`; companion tracking records reconciled for the July 20 dependency-lock repair |
| App tests | **235/235 passed**, 28/28 files |
| App production build | **passed**, 2,301 modules; main JS 441.92 kB / 134.79 kB gzip |
| TypeScript | **passed** both directly and as part of `npm run build` |
| App lint | **passed** with zero warnings |
| Windows package | **passed** for NSIS installer and unpacked directory |
| Packaged smoke | **passed**; packaged StatForge remained running for the scripted 8-second gate |
| Native Electron custom-duration UI | **passed July 18** via the standalone renderer: Custom selection, 75-second entry, 5/3,600-second bounds, local persistence, and renderer reload restoration verified |
| Addon luacheck | **not locally verifiable**: `luacheck` is not installed; GitHub workflow is configured |
| Production asset paths | **verified** relative (`base: './'`; generated `./assets/...`) |
| GitHub CI | App runs clean `npm ci`, data build, lint, tsc, tests, Windows packaging, and packaged smoke; the July 19 omitted Electron Builder peer-package lock entries were repaired July 20. Addon runs behavior tests + luacheck; local `.luacheckrc` discovery repaired July 15 |

> Offline verification cannot replace live WoW validation. The addon shell, bank events, import dialog, and equip flow still need an in-game test matrix.

---

## What is already good

### ✅ Architecture and product shape

- **Verified:** the producer/consumer boundary is explicit: addon `Snapshot.lua` emits `StatForge-v1`; app `validation.ts` accepts it; app `setupExport.ts` emits `SFSETUP1`; addon `GearTab.lua` parses it.
- **Verified:** Electron uses `nodeIntegration: false`, `contextIsolation: true`, and a preload bridge. This is the correct security baseline.
- **Verified:** heavy analysis stays in the desktop app while the addon remains small and Classic-safe.
- **Verified:** SavedVariables discovery supports multiple WoW accounts and watches each account directory.
- **Verified:** the compact item DB build and runtime share the parser rather than maintaining two divergent implementations.

### ✅ Upgrade-engine foundations

- **Verified:** weapons are solved jointly, avoiding impossible “2H + off-hand” recommendations.
- **Verified:** rings and trinkets are solved as pairs, with physical-instance and Unique constraints.
- **Verified:** candidates are filtered by required level, class restrictions, weapon proficiency, and armor type.
- **Verified:** bag and bank items are included in owned-upgrade analysis.
- **Verified:** random-suffix item tooltips are captured by the addon and resolved by the app.
- **Verified:** the most correctness-sensitive engine code has meaningful unit coverage; the desktop app has 190 passing tests and the addon mock harness has 11 passing behavior tests.

### ✅ Distinct product direction

StatForge has a credible niche rather than being a clone: **offline/local character data + Hardcore survivability + farming guidance + in-game equip return path**. That combination is differentiated from Raidbots and AMR.

---

## Findings

## 🔴 Critical

**No verified critical defect was found in this offline audit.** Do not interpret this as live-addon certification; the in-game workflow remains unverified here.

## 🟠 High priority

### H1. Recommendation quality has a hard linear-EP ceiling — partially resolved

**Resolved July 14–18, 2026:** owned and obtainable upgrade paths now score marginal changes against the complete equipped loadout. Conservative spec/mode cap profiles reduce only hit or defense gained beyond a modeled cap; equipped enchants resolve from exported tooltip evidence or a verified Classic ID library; deterministic static set thresholds are evaluated across loadout changes; and a curated effect registry converts fixed-duration/fixed-cooldown stat-use effects to encounter averages under visible Automatic, Solo, Dungeon-boss, Raid-boss, and bounded Custom activation-on-pull windows. Finder explanations expose the active cap and encounter assumptions, effective capped delta, enchant treatment, gained/lost set thresholds, effect uptime, active time, and averaged stats. Unknown enchants, unregistered effects, nondeterministic procs, and opaque set effects remain visible or neutral without invented value.

**Remaining impact:** this is a stronger deterministic optimizer, not a combat simulator. The registry intentionally models only supportable deterministic stat-use effects. Registered items are modeled independently; shared cooldown/timing conflicts, nondeterministic procs, conditional set effects, rotation-specific timing, encounter mechanics beyond the selected deterministic duration, and broader class-specific breakpoints remain unmodeled and are disclosed in the recommendation assumption.

**Resolved July 15, 2026 (Pareto slice):** Finder replacements are independently evaluated under whole-loadout DPS and survival objectives. Strictly dominated alternatives are removed; Maximum DPS and Maximum Survival rank their named objectives, while Balanced uses equal-weight per-slot min-max normalization and distance to the ideal point with deterministic tie-breaking. The UI exposes both deltas and explicitly avoids calling Balanced universally optimal. The acquisition planner consumes the selected lens utility without changing source-grouping semantics.

**Next steps:**

1. Expand the effect registry only where tooltip evidence and deterministic timing support a non-guessed value.
2. Extend the completed initial Mage modules to other classes/specs and richer encounter mechanics; retain EP as the explicit fallback.
3. Expand cap/breakpoint profiles only where Classic Era evidence is supportable.
4. ~~Add confidence/sensitivity ranges and reproducible analysis snapshots.~~ — snapshots and five-lens deterministic objective sensitivity completed July 16, 2026; non-parameterized encounter/effect assumptions remain visible boundaries rather than guessed ranges.

### H2. ~~`SFSETUP1` carries enchant IDs but addon matching ignores them~~ — resolved

**Resolved July 11, 2026:** addon matching now requires the requested non-zero enchant ID across equipped items, bags, open-bank scans, and the closed-bank cache. Regression tests exercise duplicate bag copies and cached-bank mismatch behavior; CI runs them through Fengari.

**Resolved July 15, 2026 (continued):** same-item/suffix copies with the wrong requested enchant now receive a distinct `ench` Gear status and wrong-enchant equip-summary count instead of appearing fully missing. The mismatched copy remains ineligible for equipping.

**Former impact:** duplicate copies with different enchants could cause the addon to equip the wrong physical copy.

**Remaining enhancement:** add an instance discriminator where Classic item links expose a stable, useful value.

### H3. No character roster; newest export silently wins — resolved

**Resolved July 12, 2026:** imports are retained by normalized realm + character key, the title bar exposes explicit selection and pinning, pinned characters are not silently replaced by newer watcher exports, and export/bank-cache freshness is visible. Existing single-character local storage migrates into the roster.

### H4. The release pipeline does not prove the packaged desktop app works — resolved

**Resolved July 12, 2026:** Windows CI now builds the production renderer, packages NSIS and unpacked artifacts, verifies the installer, smoke-launches the packaged executable, and uploads release artifacts. Code signing and controlled auto-update remain later ship-quality work.

### H5. Live addon behavior is not covered by a repeatable test harness — resolved for offline-testable behavior

**Resolved July 15, 2026:** addon CI runs a Fengari harness with WoW API stubs and 11 deterministic behavior tests. Coverage now includes real item-link enchant/suffix fields, strict setup parsing, exact and wrong-enchant matching across equipped items, bags, and the closed-bank cache, combat-lockdown blocking, equip-summary decisions, empty-scan bank-cache preservation, JSON escaping, suffix serialization, and bank freshness. `docs/MANUAL_TEST_MATRIX.md` supplies a repeatable release gate for bank-event order, logout persistence, tooltip scanning, UI lifecycle, enchant-specific setup matching, and sequential equips.

**Remaining boundary:** offline mocks do not certify Blizzard API behavior in the live Classic client. The manual matrix must be executed and evidence recorded for release candidates; this audit has not marked those in-game checks as passed.

## 🟡 Medium priority

### M1. The advertised lint command is broken — resolved

**Resolved July 12, 2026:** the app now has a flat ESLint configuration covering TypeScript, React hooks, and component Fast Refresh boundaries. `npm run lint` enforces zero warnings and runs in CI before type checking and tests.

### M2. Contract types drift from the actual addon payload — resolved

**Resolved July 11, 2026:** the addon serializer now actually emits its captured `suffixId`; app interfaces include `suffixId` and `meta.bankCachedAt`; runtime validation checks `suffixId`, `enchantId`, and `bankCachedAt`. Addon and app regression tests cover the repaired boundary.

**Resolved July 11, 2026 (continued):** `meta.exportedAt` and `addonVersion` are required strings, app contract tests consume a golden fixture matching addon serializer output, and one versioned Zod schema now drives both runtime validation and inferred TypeScript contract types. Nested character, item, tooltip, bonus-ID, and character-sheet fields are validated by that schema.

**Backward compatibility:** `enchantId`, `suffixId`, `bankCachedAt`, talent points, tooltips, and character-sheet stats remain optional for older exports, but are validated when present.

### M3. Important boundary code has no direct tests — resolved

**Resolved July 12, 2026:** focused tests now cover validation, SavedVariables parsing, multiple characters, Lua escaping, truncation, malformed entries, farming-risk score boundaries, authored fallbacks, PvP exclusion, combat hazards, above-level danger, and complete location assessment.

### M4. README and version metadata are stale/incomplete — resolved

**Resolved July 12, 2026:** addon and desktop documentation now describe installation, the complete local data round trip, privacy boundaries, development, packaging, testing, and current limitations. Both projects and their changelogs are aligned at `0.5.0`; the app package includes explicit private/unlicensed, author, repository, homepage, and issue metadata.

### M5. Dependency and tooling modernization is deferred too far — resolved

**Resolved July 18, 2026:** all major dependencies upgraded in 4 staged commits, each with CI green (lint + tsc + tests + build):
- Stage 1 (`8e3c358`): Electron 31→43, electron-builder 24→26
- Stage 2 (`15afaf4`): ESLint 8→10, @typescript-eslint 7→8, react-hooks 4→7, react-refresh 0.4→0.5
- Stage 3 (`4615d26`): Vite 5→8, Vitest 1→4, @vitejs/plugin-react 4→6, added esbuild as explicit dep
- Stage 4 (`5c23b9c`): React 18→19, framer-motion 11→12, lucide-react 0.390→1, tailwind-merge 2→3, concurrently 8→10, wait-on 7→9

TypeScript kept at 5.9 (TS 7 incompatible with @typescript-eslint v8 internals). 190/190 tests pass throughout, lint clean, build clean. 3 new react-hooks v7 rules disabled (performance guidance, not correctness).

**Resolved July 20, 2026 (CI reproducibility follow-up):** GitHub Actions exposed that the regenerated npm lockfile referenced electron-builder 26's Windows Squirrel/signing peer packages without recording their package entries. Both Linux and Windows jobs stopped at `npm ci` before project gates. Regenerating the lockfile with Node 22/npm 10 and optional peers restored clean-install reproducibility; 235/235 tests, lint, TypeScript/build, NSIS plus unpacked packaging, and packaged smoke pass locally.

### M6. Electron hardening is baseline, not release-grade — resolved

**Resolved July 18, 2026:** renderer sandbox enabled (preload is contextBridge-only, compatible), all production navigation blocked via `will-navigate`/`will-redirect` preventDefault, `setWindowOpenHandler` denies all popups unconditionally, `setPermissionRequestHandler` denies by default and allows notifications only, and the production CSP meta tag contains no `'unsafe-eval'`. The dead `window.location.origin` reference in the redirect handler (would crash in main process) was removed. Verified: 190/190 tests pass, lint clean, build clean (575 kB JS / 32 kB CSS), commit `dc2d4e6` on `master`.

### M7. Long-term optimizer architecture will strain the current component/state model

**Verified evidence:** app state is concentrated in `App.tsx`, imported data is a single localStorage blob, and several domain-heavy panels/engine files are already large.

**Recommendation:** before adding roster, loadouts, history, and simulation, separate domains: character repository, schema/import service, optimizer service, loadout service, and UI state. Use a small store only when the boundaries justify it; do not refactor solely for fashion.

### M8. Item data provenance and reproducibility need stronger product treatment — resolved

**Resolved July 13, 2026:** compact generation emits a sidecar manifest with the installed source package/version, parser version, Classic Era/phase scope, record count, Era cutoff, build timestamp, and SHA-256. Data Diagnostics compares the loaded record count and independently hashes the exact compact bytes at runtime. The UI distinguishes verified, warning, and error states and does not present compact-build age as upstream record freshness.

**Remaining enhancement:** replace the project-specific Era item-ID cutoff when the source dataset provides complete explicit era provenance.

---

## State-of-the-art roadmap

The highest-leverage strategy is **not** “copy Raidbots.” Build the best Hardcore planning companion, then deepen simulation selectively.

### Phase 1 — Trustworthy product foundation (1–2 weeks)

1. ~~Fix ESLint and add it to CI.~~ — completed July 12, 2026.
2. ~~Introduce one runtime schema + golden addon fixtures.~~ — completed July 11, 2026.
3. ~~Add SavedVariables, validation, and farming-risk tests.~~ — completed July 12, 2026.
4. ~~Fix enchant-aware setup matching.~~ — completed July 11, 2026.
5. ~~Update both READMEs and versions.~~ — completed July 12, 2026.
6. ~~Add Windows production build/package smoke CI.~~ — completed July 12, 2026.
7. ~~Add an addon mock harness and repeatable in-game test matrix.~~ — completed July 15, 2026.

### Phase 2 — Hardcore companion advantage (2–4 weeks)

1. ~~Character roster with pinning, export age, and bank-cache freshness.~~ — completed July 12, 2026.
2. ~~Saved loadouts and comparison views.~~ — completed July 12, 2026.
3. ~~“Why this upgrade?” explanations: gains, losses, cap impact, source, risk, travel burden.~~ — completed July 13, 2026.
4. ~~Upgrade acquisition planner: route several upgrades together by zone/vendor/dungeon.~~ — completed July 13, 2026.
5. ~~Hardcore risk model v2: escape toolkit, crowd-control immunity, caves, hyperspawns, patrol density, leash constraints, consumable readiness.~~ — completed July 13, 2026.
6. ~~Data freshness/provenance diagnostics.~~ — completed July 13, 2026.

### Phase 3 — Optimization fidelity (4–8+ weeks, incremental)

1. ~~Cap-aware weights and constraints.~~ — deterministic hit/defense cap profiles completed July 14, 2026; broader class-specific breakpoints remain incremental.
2. ~~Enchant library and scoring.~~ — tooltip-first plus conservative verified-ID fallback completed July 14, 2026; unknown IDs remain neutral.
3. ~~Set-bonus/loadout graph.~~ — deterministic static thresholds completed July 14, 2026; opaque/conditional effects remain for the effect registry.
4. ~~Proc/on-use effect registry.~~ — curated deterministic stat-use effects completed July 14, 2026 with a visible 180-second profile; nondeterministic and unsupported effects remain neutral.
5. Spec modules with deterministic rotation/encounter models. — Mage Arcane/Fire/Frost school-damage modules and level-sensitive 30-second leveling / 180-second raid encounter windows completed July 15, 2026. A declarative registry plus conservative Shadow Priest, Affliction Warlock, and Elemental Shaman school modules followed July 16; Retribution and Protection Paladin Holy-school inference followed July 17 while preserving each hybrid preset's non-school weights. Explicit Automatic, Solo (30s), Dungeon boss (90s), Raid boss (180s), and bounded Custom (5–3,600s) profiles now drive duration-sensitive effect uptime in both analysis paths and reproducible snapshots. Custom duration was completed July 18 with local persistence and standalone Electron verification. These are school and deterministic-duration boundaries rather than complete rotations or threat simulations; unsupported tabs, other classes, and encounter mechanics beyond duration remain incremental.
6. ~~Pareto-front recommendations: maximum DPS, balanced, and maximum survival rather than one scalar winner.~~ — completed July 15, 2026 with separate whole-loadout objectives, strict dominance filtering, disclosed normalized Balanced ranking, and deterministic planner integration.
7. ~~Reproducible analysis snapshots containing inputs, model version, assumptions, and score breakdown.~~ — completed July 16, 2026 with a versioned `StatForgeAnalysisSnapshot` JSON contract, exact imported character/loadout inputs, deterministic component and item-data identities, visible assumptions, normalized objective breakdowns, local save/export/import, and exact replay comparison.
8. ~~Confidence/sensitivity analysis over reproducible snapshots.~~ — completed July 16, 2026 with five disclosed DPS/survival lenses, deterministic tie-breaking, Stable/Sensitive/Model-limited classifications, original objective deltas, normalized lens-fit ranges, and explicit unmodeled candidate evidence. This is a trade-off stability report, not probabilistic simulation.

### Phase 4 — Ship-quality desktop application

1. ~~Signed NSIS installer and controlled auto-update.~~ — **deferred indefinitely July 19, 2026.** After researching code-signing requirements, the cert purchase (~$100–300/yr OV, more for EV) and recurring renewal/KYC overhead are not justified for the current sharing-with-friends distribution model. StatForge will ship as a plain zip for manual download/redownload, matching the CurseForge manual-update pattern every WoW player already accepts. Revisit only if (a) SmartScreen warnings drive users away from public distribution, or (b) seamless auto-update becomes a priority. The WoW addon itself (Lua/XML) never needed signing — this decision concerns only the Electron desktop companion .exe.
2. ~~Crash/error diagnostics that remain local-first and opt-in.~~ — **completed July 19, 2026.** Opt-in error log captures React component errors, unhandled promise rejections, and app errors to a bounded localStorage ring buffer (last 50). `ErrorBoundary` wraps the app and shows a friendly reload fallback. Global `window.onerror` / `unhandledrejection` handlers wired at startup. The Diagnostics panel exposes the log with per-error expand/collapse, stack traces, clear-all, and per-error delete. 15 tests cover the ring buffer, opt-in toggle, error kinds, and graceful storage-failure handling. Local-first by design — no network calls, no PII.
3. Offline-first icon/data cache status.
4. ~~Accessibility: keyboard navigation, focus states, reduced motion, contrast, screen-reader labels~~ — **completed July 19, 2026**
   - **Resolved July 18, 2026:** skip-to-content link, ARIA landmarks (header, nav, main), sidebar tab labels with `aria-current`, decorative icons marked `aria-hidden`, `focus-visible:ring` on all interactive elements, `prefers-reduced-motion` support (both framer-motion and CSS), screen-reader-only utility class, focus management on tab change. Commit `f3f1e68`.
   - **Resolved July 19, 2026:** aria-live regions for dynamic content (ImportPanel error/success, AnalysisSnapshotsPanel save/restore messages), `aria-label` on all icon-only buttons (What-if slot/enchant remove, level +/-, scenario delete; Diagnostics per-error delete), `aria-expanded` on FarmingLocationsPanel toggle buttons, decorative chevrons marked `aria-hidden`. Screen readers now announce import outcomes and snapshot operations.
5. Performance budgets and list virtualization based on measured traces — partially resolved
   - **Resolved July 18, 2026:** code-split heavy panels (UpgradesPanel, FarmingLocationsPanel, DiagnosticsPanel) via `React.lazy` + `Suspense`. Main bundle reduced 29% (620→437 kB). Lazy chunks load on-demand. Commit `39cd055`.
   - **Remaining:** list virtualization not needed (farming locations ~42 items, upgrade candidates bounded per slot); measure actual load/render traces against a budget; consider further splitting shared itemDatabase chunk if it grows.
6. ~~Harden the Electron development lifecycle against renderer-port drift and orphaned processes.~~ — completed July 16, 2026. Vite now refuses to move off port 5173, and the coupled launcher closes Electron when renderer startup fails; a regression test preserves the strict-port contract.

### Phase 5 — Optional advanced differentiators

- **Simulation worker threads/Web Workers** so deeper models never block the UI.
- ~~**Sensitivity analysis:** show which objective trade-offs and supported model boundaries change the recommendation.~~ — completed July 16, 2026 over reproducible snapshots; richer parameterized encounter/effect sensitivity depends on future model modules.
- **What-if planning:** level, talent, enchant, and future-item scenarios without mutating current gear. — **partially resolved July 19, 2026**
  - **Resolved July 19, 2026:** What-if planning mode added as a new sidebar tab. Users can clone the current character into a sandbox, swap gear from the full item database, edit talent tab points, change character level, apply/remove enchants from the verified Classic enchant-ID library, and see side-by-side DPS/survival score deltas with stat changes, set bonus gains/losses, and gear slot change lists. Scenarios can be saved/restored per character in localStorage. Non-destructive by design — the real `CharacterData` is never mutated. 30 new tests cover clone isolation, modification, comparison, and persistence. 220/220 tests pass, lint clean, build clean.
  - **Remaining:** future-item scenarios (items not yet in the database); shareable local analysis bundles.
- **Shareable local analysis bundles** (no account upload required).
- **Plugin-like spec model registry** so new specs/effects can be added and tested independently.

## Project continuity and tracking

Future work must use these repository records rather than relying on chat history:

1. **`AUDIT.md`** — canonical improvement list and completion state across both repositories.
2. **`CHANGELOGS.md`** — cross-repository index, current checkpoint, and next-action summary.
3. **`CHANGELOG.md` in each repository** — completed work for that repository. App-only milestones must also receive a concise `Companion desktop app` entry here stating whether the addon schema changed.
4. **`.hermes/plans/`** — actionable implementation plans for milestones. The current completed plan is `2026-07-17_184001-custom-encounter-duration.md`.
5. **`docs/MANUAL_TEST_MATRIX.md`** — live-WoW release evidence that offline tests cannot provide.

When completing an audit item: update this file, update the affected changelog(s), run the repository gates, inspect the diff, commit a clean checkpoint, push it, and verify `HEAD == origin/<branch>` in both repositories. Do not mark a partially implemented model as fully simulated or live-client certified.

---

## Recommended next order

| Priority | Work | Why |
|---|---|---|
| 1 | Offline-first icon/data cache status | The icon cache exists, but users cannot see cache coverage, size, location, failures, or offline readiness; this is the last dependency-free Phase 4 product gap |
| 2 | Measure startup/load/render performance against an explicit budget | Code splitting reduced the main bundle, but measured traces should determine whether further splitting or virtualization is justified |
| 3 | Continue deterministic class/spec modules only with evidence, then execute the live-WoW release matrix | Extend fidelity only where exported evidence supports a conservative model, and keep live-client certification separate from offline automation |

## Bottom line

StatForge has already crossed the line from JSON viewer to a credible two-way optimizer companion. Its strongest assets are the local-first workflow, tested joint-slot logic, and Hardcore-specific direction. To become state of the art, prioritize **model fidelity, explainability, reproducible contracts, and release engineering** ahead of more decorative UI work.
