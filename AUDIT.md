# StatForge Full Project Audit — July 11, 2026

## Executive summary

StatForge is a two-repository, local-first WoW Classic Hardcore companion:

- **`StatForge`** (`main`) — a pure-Lua Classic Era addon that exports `StatForge-v1` character/gear JSON and imports `SFSETUP1` optimized loadouts.
- **`StatForge-App`** (`master`) — an Electron + React + TypeScript desktop optimizer with a compact local item database, SavedVariables watcher, upgrade engine, Hardcore farming-risk UI, and addon setup export.

**Overall assessment: strong prototype / early product, not yet state of the art.** The core bidirectional loop exists and the app's tested gear-combination logic is substantially better than a typical hobby optimizer. The biggest remaining gap is not visual polish: it is **recommendation fidelity**. Linear EP cannot yet model caps, effects, enchants, set bonuses, rotations, or encounter context well enough to compete with Raidbots/Ask Mr. Robot on optimization correctness.

There are **no verified release-blocking build or unit-test failures** in the app. There are, however, several high-priority product and correctness gaps and a broken lint gate.

## Verification snapshot

| Check | Result |
|---|---|
| App branch/status | `master...origin/master`, clean |
| Addon branch/status | `main...origin/main`, clean before this report |
| App tests | **68/68 passed**, 7/7 files |
| App production build | **passed**, 1,881 modules; JS 413.07 kB / 125.19 kB gzip |
| TypeScript | **passed** as part of `npm run build` |
| App lint | **failed**: ESLint has no configuration file |
| Addon luacheck | **not locally verifiable**: `luacheck` is not installed; GitHub workflow is configured |
| Production asset paths | **verified** relative (`base: './'`; generated `./assets/...`) |
| GitHub CI | App runs data build + tsc + tests; addon runs luacheck |

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
- **Verified:** the most correctness-sensitive engine code has meaningful unit coverage; all 68 current tests pass.

### ✅ Distinct product direction

StatForge has a credible niche rather than being a clone: **offline/local character data + Hardcore survivability + farming guidance + in-game equip return path**. That combination is differentiated from Raidbots and AMR.

---

## Findings

## 🔴 Critical

**No verified critical defect was found in this offline audit.** Do not interpret this as live-addon certification; the in-game workflow remains unverified here.

## 🟠 High priority

### H1. Recommendation quality has a hard linear-EP ceiling

**Verified evidence:** `upgradeEngine.ts:getItemScore()` multiplies each parsed stat by a fixed weight and sums it. The score has no stateful cap logic, proc/use modeling, set interactions, enchant contribution, rotation model, encounter duration, or uncertainty range.

**Impact:** recommendations can be directionally useful but cannot reliably match a simulator or mature optimizer. Hit beyond cap can be overvalued; on-use trinkets and set bonuses can be badly ranked; two items with identical static stats but very different effects collapse toward the same model.

**Recommendation:** build a layered evaluator:

1. Cap-aware marginal stat values (hit/defense and any class-specific breakpoints).
2. Enchant contribution and “missing enchant” comparison.
3. Proc/on-use effect registry with uptime and encounter-duration assumptions.
4. Set-bonus graph evaluated across whole loadouts.
5. A lightweight deterministic combat model for supported specs, with EP retained as fast fallback.
6. Show confidence and assumptions, not a single unexplained score.

### H2. ~~`SFSETUP1` carries enchant IDs but addon matching ignores them~~ — resolved

**Resolved July 11, 2026:** addon matching now requires the requested non-zero enchant ID across equipped items, bags, open-bank scans, and the closed-bank cache. Two regression tests exercise duplicate bag copies and cached-bank mismatch behavior; CI runs them through Fengari.

**Former impact:** duplicate copies with different enchants could cause the addon to equip the wrong physical copy.

**Remaining enhancement:** distinguish “same item, wrong enchant” from fully missing in the UI and add an instance discriminator where Classic item links permit one.

### H3. No character roster; newest export silently wins

**Verified evidence:** `App.tsx` sorts all discovered exports by timestamp and imports `withTime[0]`. There is no roster selector or pinned active character.

**Impact:** multi-alt Hardcore players can be moved to another character merely because that character exported most recently. It also prevents comparison, planning, and per-character history.

**Recommendation:** make the watcher ingest into a roster keyed by realm + character, then let the user select/pin the active character. Show export age and bank-cache age. Never silently replace the active character after the user pins it.

### H4. The release pipeline does not prove the packaged desktop app works

**Verified evidence:** app CI runs compact-data build, `tsc --noEmit`, and Vitest, but does not run `npm run build`, package with electron-builder, inspect artifacts, or smoke-launch the packaged application.

**Impact:** renderer tests can be green while production-only Electron/file/protocol/packaging defects ship.

**Recommendation:** add Windows CI that runs production build + NSIS packaging, verifies expected files, and launches an unpacked build with a smoke-test flag. Add signed releases and update metadata only after that gate passes.

### H5. Live addon behavior is not covered by a repeatable test harness

**Verified evidence:** addon CI only runs luacheck. Core behavior depends on WoW globals and event order. This audit could not run luacheck locally because the command is missing, and it cannot exercise WoW APIs offline without mocks.

**Impact:** bank caching, logout export, tooltip scanning, UI lifecycle, combat lockdown, and sequential equip behavior can regress despite green CI.

**Recommendation:** introduce a Lua mock harness (WoW API stubs + fixtures) for link parsing, JSON escaping, bank-cache guards, setup parsing/matching, and equip decisions. Maintain a short manual in-game matrix for APIs that cannot be realistically mocked.

## 🟡 Medium priority

### M1. The advertised lint command is broken

**Verified evidence:** `npm run lint` exits 2 because no ESLint configuration exists. The script remains in `package.json`, and CI does not invoke it.

**Recommendation:** add a flat ESLint config compatible with the installed TypeScript/React plugins, run it in CI, and treat zero warnings as a gate. Do not leave a knowingly nonfunctional script as project documentation.

### M2. Contract types drift from the actual addon payload — partially resolved

**Resolved July 11, 2026:** the addon serializer now actually emits its captured `suffixId`; app interfaces include `suffixId` and `meta.bankCachedAt`; runtime validation checks `suffixId`, `enchantId`, and `bankCachedAt`. Addon and app regression tests cover the repaired boundary.

**Remaining:** consolidate the handwritten validator and interfaces into one versioned schema, validate `meta.exportedAt`/`addonVersion`, and add addon-produced golden fixtures. `enchantId` remains optional for backward compatibility with pre-0.4.0 exports.

**Recommendation:** define one versioned schema (Zod, Valibot, or JSON Schema), infer TypeScript types from it, validate watcher and paste input with the same schema, and add addon-produced golden fixtures as contract tests.

### M3. Important boundary code has no direct tests

**Verified evidence:** focused `validation.ts` tests were added July 11, 2026. Direct tests are still missing for `electron/savedVariables.js` and `farmingRisk.tsx`.

**Impact:** Lua string unescaping/table extraction, malformed import handling, and Hardcore risk classification are user-critical but unprotected.

**Recommendation:** add fixture-driven tests for multiple accounts/characters, escaped strings, truncated Lua, malformed JSON, old schema versions, risk boundary levels, hazards, and class-kiting adjustments.

### M4. README and version metadata are stale/incomplete

**Verified evidence:** addon TOC says `0.5.0`, while README says `0.4.0`, calls setup storage “soon,” and says import/equip is “soon” although it is implemented. `StatForge-App` has no README. The app package remains `0.1.0` despite substantial functionality.

**Impact:** private GitHub documentation does not accurately explain installation, current features, constraints, or release maturity.

**Recommendation:** update addon README from code, add an app README with screenshots/workflow/build instructions/data privacy, and establish synchronized release notes and semantic versions.

### M5. Dependency and tooling modernization is deferred too far

**Verified evidence:** `npm outdated` reports Electron 31 vs current 43, Vite 5 vs 8, Vitest 1 vs 4, ESLint 8 vs 10, plus other majors. Test/build output warns about deprecated Vite CJS usage and typeless PostCSS module parsing.

**Impact:** security/support debt and future high-risk upgrade jumps. Blindly upgrading everything at once would also be risky.

**Recommendation:** upgrade in staged branches: Electron/builder first, then lint stack, then Vite/Vitest, then React. Add Dependabot or Renovate with grouped updates and CI gates. Resolve module-format warnings explicitly.

### M6. Electron hardening is baseline, not release-grade

**Verified evidence:** isolation is enabled, but no permission-request handler, navigation/window-open guard, sandbox setting, or strict production CSP split is present. CSP currently allows `'unsafe-eval'` globally.

**Recommendation:** disable unexpected navigation/window creation, deny permissions by default, enable renderer sandbox if preload compatibility permits, remove `'unsafe-eval'` in production, and verify remote content cannot acquire privileged bridge behavior.

### M7. Long-term optimizer architecture will strain the current component/state model

**Verified evidence:** app state is concentrated in `App.tsx`, imported data is a single localStorage blob, and several domain-heavy panels/engine files are already large.

**Recommendation:** before adding roster, loadouts, history, and simulation, separate domains: character repository, schema/import service, optimizer service, loadout service, and UI state. Use a small store only when the boundaries justify it; do not refactor solely for fashion.

### M8. Item data provenance and reproducibility need stronger product treatment

**Verified evidence:** a package-sourced item database is transformed locally, with project-specific Era heuristics documented in the previous audit. There is no visible data manifest/version in the UI.

**Recommendation:** ship a data manifest containing source package version, build timestamp, supported game build/phases, record count, parser version, and checksum. Surface it in About/Diagnostics. Prefer explicit phase/provenance data over ID heuristics as the dataset matures.

---

## State-of-the-art roadmap

The highest-leverage strategy is **not** “copy Raidbots.” Build the best Hardcore planning companion, then deepen simulation selectively.

### Phase 1 — Trustworthy product foundation (1–2 weeks)

1. Fix ESLint and add it to CI.
2. Introduce one runtime schema + golden addon fixtures.
3. Add SavedVariables, validation, and farming-risk tests.
4. Fix enchant-aware setup matching.
5. Update both READMEs and versions.
6. Add Windows production build/package smoke CI.

### Phase 2 — Hardcore companion advantage (2–4 weeks)

1. Character roster with pinning, export age, and bank-cache freshness.
2. Saved loadouts and comparison views.
3. “Why this upgrade?” explanations: gains, losses, cap impact, source, risk, travel burden.
4. Upgrade acquisition planner: route several upgrades together by zone/vendor/dungeon.
5. Hardcore risk model v2: escape toolkit, crowd-control immunity, caves, hyperspawns, patrol density, leash constraints, consumable readiness.
6. Data freshness/provenance diagnostics.

### Phase 3 — Optimization fidelity (4–8+ weeks, incremental)

1. Cap-aware weights and constraints.
2. Enchant library and scoring.
3. Set-bonus/loadout graph.
4. Proc/on-use effect registry.
5. Spec modules with deterministic rotation/encounter models.
6. Pareto-front recommendations: maximum DPS, balanced, and maximum survival rather than one scalar winner.
7. Reproducible analysis snapshots containing inputs, model version, assumptions, and score breakdown.

### Phase 4 — Ship-quality desktop application

1. Signed NSIS installer and controlled auto-update.
2. Crash/error diagnostics that remain local-first and opt-in.
3. Offline-first icon/data cache status.
4. Accessibility: keyboard navigation, focus states, reduced motion, contrast, screen-reader labels.
5. Performance budgets and list virtualization based on measured traces.

### Phase 5 — Optional advanced differentiators

- **Simulation worker threads/Web Workers** so deeper models never block the UI.
- **Sensitivity analysis:** show which uncertain assumptions change the recommendation.
- **What-if planning:** level, talent, enchant, and future-item scenarios without mutating current gear.
- **Shareable local analysis bundles** (no account upload required).
- **Plugin-like spec model registry** so new specs/effects can be added and tested independently.

---

## Recommended next order

| Priority | Work | Why |
|---|---|---|
| 1 | Schema + contract fixtures + missing boundary tests | Prevent silent corruption between the two repos |
| 2 | Enchant-aware matching | Closes a real loadout correctness gap |
| 3 | Roster + freshness UI | Largest immediate usability gain for real Hardcore play |
| 4 | Windows package smoke CI + installer/update path | Converts a dev app into a shippable product |
| 5 | Cap-aware scoring + enchants + set bonuses | Highest recommendation-quality gain before full simulation |
| 6 | Effect/rotation modules + confidence/explanations | Path toward genuine state-of-the-art trustworthiness |

## Bottom line

StatForge has already crossed the line from JSON viewer to a credible two-way optimizer companion. Its strongest assets are the local-first workflow, tested joint-slot logic, and Hardcore-specific direction. To become state of the art, prioritize **model fidelity, explainability, reproducible contracts, and release engineering** ahead of more decorative UI work.
