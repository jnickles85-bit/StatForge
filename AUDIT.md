# StatForge Full Project Audit — July 11, 2026

## Executive summary

StatForge is a two-repository, local-first WoW Classic Hardcore companion:

- **`StatForge`** (`main`) — a pure-Lua Classic Era addon that exports `StatForge-v1` character/gear JSON and imports `SFSETUP1` optimized loadouts.
- **`StatForge-App`** (`master`) — an Electron + React + TypeScript desktop optimizer with a compact local item database, SavedVariables watcher, upgrade engine, Hardcore farming-risk UI, and addon setup export.

**Overall assessment: strong prototype / early product, not yet state of the art.** The core bidirectional loop exists and the app's tested gear-combination logic is substantially better than a typical hobby optimizer. Recommendation fidelity now includes whole-loadout cap, enchant, deterministic set/effect, and initial Mage encounter modeling, but it remains a deterministic optimizer rather than a combat simulator. The largest remaining fidelity gaps are broader class/spec models, Pareto tradeoff recommendations, reproducible analysis snapshots, and uncertainty/sensitivity analysis.

There are **no verified release-blocking build, lint, type-check, or unit-test failures** in the app. Live WoW behavior and packaged release behavior still require their documented release checks.

## Verification snapshot — refreshed July 15, 2026

| Check | Result |
|---|---|
| App branch/status | `master...origin/master`, clean |
| Addon branch/status | `main...origin/main`; project-tracking documents may be pending until checkpointed |
| App tests | **148/148 passed**, 21/21 files |
| App production build | **passed**, 1,973 modules; JS 536.83 kB / 159.85 kB gzip |
| TypeScript | **passed** both directly and as part of `npm run build` |
| App lint | **passed** with zero warnings |
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
- **Verified:** the most correctness-sensitive engine code has meaningful unit coverage; the desktop app has 141 passing tests and the addon mock harness has 11 passing behavior tests.

### ✅ Distinct product direction

StatForge has a credible niche rather than being a clone: **offline/local character data + Hardcore survivability + farming guidance + in-game equip return path**. That combination is differentiated from Raidbots and AMR.

---

## Findings

## 🔴 Critical

**No verified critical defect was found in this offline audit.** Do not interpret this as live-addon certification; the in-game workflow remains unverified here.

## 🟠 High priority

### H1. Recommendation quality has a hard linear-EP ceiling — partially resolved

**Resolved July 14, 2026:** owned and obtainable upgrade paths now score marginal changes against the complete equipped loadout. Conservative spec/mode cap profiles reduce only hit or defense gained beyond a modeled cap; equipped enchants resolve from exported tooltip evidence or a verified Classic ID library; deterministic static set thresholds are evaluated across loadout changes; and a curated effect registry converts fixed-duration/fixed-cooldown stat-use effects to encounter averages under a visible 180-second activation-on-pull profile. Finder explanations expose the active cap and encounter assumptions, effective capped delta, enchant treatment, gained/lost set thresholds, effect uptime, active time, and averaged stats. Unknown enchants, unregistered effects, nondeterministic procs, and opaque set effects remain visible or neutral without invented value.

**Remaining impact:** this is a stronger deterministic optimizer, not a combat simulator. The registry intentionally models only supportable deterministic stat-use effects. Registered items are modeled independently; shared cooldown/timing conflicts, nondeterministic procs, conditional set effects, rotation-specific timing, encounter mechanics beyond the current 30/180-second windows, broader class-specific breakpoints, and uncertainty/sensitivity analysis remain unmodeled and are disclosed in the recommendation assumption.

**Next steps:**

1. Expand the effect registry only where tooltip evidence and deterministic timing support a non-guessed value.
2. Extend the completed initial Mage modules to other classes/specs and richer encounter mechanics; retain EP as the explicit fallback.
3. Expand cap/breakpoint profiles only where Classic Era evidence is supportable.
4. Add confidence/sensitivity ranges and reproducible analysis snapshots.

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
5. Spec modules with deterministic rotation/encounter models. — Mage Arcane/Fire/Frost school-damage modules and level-sensitive 30-second leveling / 180-second raid encounter windows completed July 15, 2026; other classes and encounter mechanics remain incremental.
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

## Project continuity and tracking

Future work must use these repository records rather than relying on chat history:

1. **`AUDIT.md`** — canonical improvement list and completion state across both repositories.
2. **`CHANGELOGS.md`** — cross-repository index, current checkpoint, and next-action summary.
3. **`CHANGELOG.md` in each repository** — completed work for that repository. App-only milestones must also receive a concise `Companion desktop app` entry here stating whether the addon schema changed.
4. **`.hermes/plans/`** — actionable implementation plans for the next milestone. The current plan is `2026-07-15_100520-pareto-front-recommendations.md`.
5. **`docs/MANUAL_TEST_MATRIX.md`** — live-WoW release evidence that offline tests cannot provide.

When completing an audit item: update this file, update the affected changelog(s), run the repository gates, inspect the diff, commit a clean checkpoint, push it, and verify `HEAD == origin/<branch>` in both repositories. Do not mark a partially implemented model as fully simulated or live-client certified.

---

## Recommended next order

| Priority | Work | Why |
|---|---|---|
| 1 | Pareto-front recommendations | Exposes maximum-DPS, balanced, and maximum-survival tradeoffs instead of one scalar winner |
| 2 | Reproducible snapshots + confidence/sensitivity analysis | Makes assumptions, model versions, and recommendation stability auditable |
| 3 | Extend deterministic class/spec and encounter modules | Improves fidelity incrementally without pretending to be a full simulator |
| 4 | Electron hardening and staged dependency modernization | Reduces security/support debt without a risky all-at-once upgrade |

## Bottom line

StatForge has already crossed the line from JSON viewer to a credible two-way optimizer companion. Its strongest assets are the local-first workflow, tested joint-slot logic, and Hardcore-specific direction. To become state of the art, prioritize **model fidelity, explainability, reproducible contracts, and release engineering** ahead of more decorative UI work.
