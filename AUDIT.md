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

### H3. No character roster; newest export silently wins — resolved

**Resolved July 12, 2026:** imports are retained by normalized realm + character key, the title bar exposes explicit selection and pinning, pinned characters are not silently replaced by newer watcher exports, and export/bank-cache freshness is visible. Existing single-character local storage migrates into the roster.

### H4. The release pipeline does not prove the packaged desktop app works — resolved

**Resolved July 12, 2026:** Windows CI now builds the production renderer, packages NSIS and unpacked artifacts, verifies the installer, smoke-launches the packaged executable, and uploads release artifacts. Code signing and controlled auto-update remain later ship-quality work.

### H5. Live addon behavior is not covered by a repeatable test harness

**Verified evidence:** addon CI only runs luacheck. Core behavior depends on WoW globals and event order. This audit could not run luacheck locally because the command is missing, and it cannot exercise WoW APIs offline without mocks.

**Impact:** bank caching, logout export, tooltip scanning, UI lifecycle, combat lockdown, and sequential equip behavior can regress despite green CI.

**Recommendation:** introduce a Lua mock harness (WoW API stubs + fixtures) for link parsing, JSON escaping, bank-cache guards, setup parsing/matching, and equip decisions. Maintain a short manual in-game matrix for APIs that cannot be realistically mocked.

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

1. ~~Fix ESLint and add it to CI.~~ — completed July 12, 2026.
2. ~~Introduce one runtime schema + golden addon fixtures.~~ — completed July 11, 2026.
3. ~~Add SavedVariables, validation, and farming-risk tests.~~ — completed July 12, 2026.
4. ~~Fix enchant-aware setup matching.~~ — completed July 11, 2026.
5. ~~Update both READMEs and versions.~~ — completed July 12, 2026.
6. ~~Add Windows production build/package smoke CI.~~ — completed July 12, 2026.

### Phase 2 — Hardcore companion advantage (2–4 weeks)

1. ~~Character roster with pinning, export age, and bank-cache freshness.~~ — completed July 12, 2026.
2. ~~Saved loadouts and comparison views.~~ — completed July 12, 2026.
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
| 1 | Recommendation explanations | Makes gains, losses, assumptions, sources, and risk understandable |
| 2 | Upgrade acquisition planner | Converts isolated upgrades into practical Hardcore routes |
| 3 | Hardcore risk model v2 + data provenance diagnostics | Deepens the product's local-first Hardcore advantage and trust |
| 4 | Cap-aware scoring + enchants + set bonuses | Highest recommendation-quality gain before full simulation |
| 5 | Effect/rotation modules + confidence analysis | Path toward genuinely state-of-the-art optimization fidelity |

## Bottom line

StatForge has already crossed the line from JSON viewer to a credible two-way optimizer companion. Its strongest assets are the local-first workflow, tested joint-slot logic, and Hardcore-specific direction. To become state of the art, prioritize **model fidelity, explainability, reproducible contracts, and release engineering** ahead of more decorative UI work.
