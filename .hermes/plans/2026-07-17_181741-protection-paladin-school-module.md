# Protection Paladin Holy-School Module Implementation Plan

> **For Hermes:** Implement this plan task-by-task with strict RED-GREEN TDD.

**Goal:** Add a conservative Protection Paladin Holy-school damage boundary using exported dominant talent-tab evidence without claiming a complete tank rotation or threat simulation.

**Architecture:** Reuse the existing `paladin-prot` hybrid preset. Register only Protection-dominant talent tab 1. Preserve physical, defensive, and other non-school weights; neutralize unrelated spell schools; map the preset's existing generic spell-power weight to Holy damage. Holy-, Retribution-, tied-, malformed-, and absent talent evidence remain explicit base-preset fallback. Survival mode remains unchanged.

**Evidence boundary:** Classic spell records identify Protection's Holy Shield and the shared Consecration spell as Holy damage. This supports a Holy school boundary for existing generic spell-power value, not ability sequencing, uptime, threat, mitigation, seal choice, or physical-versus-Holy damage ratios.

**Tech stack:** TypeScript, Vitest, React/Vite/Electron repository gates.

---

## Task 1: Add Protection Paladin school inference through RED-GREEN TDD

**Files:**
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.test.ts`
- Modify: `C:/Projects/StatForge-App/src/lib/specModel.ts`

1. Add a focused test for `getSpecModel('paladin-prot', 'dps', 60, [0, 31, 0])` proving:
   - module identity and human-readable name;
   - physical/defensive DPS weights are preserved;
   - generic spell-power value becomes Holy-only damage;
   - unrelated schools are neutral;
   - the visible assumption names Protection-dominant and Holy-school evidence;
   - Holy-, Retribution-, and tied evidence remain fallback.
2. Run `npx vitest run src/lib/specModel.test.ts` and require an expected RED failure caused by the missing registry entry.
3. Add only the `paladin-prot` tab-1 declarative registry entry.
4. Run `npx vitest run src/lib/specModel.test.ts src/lib/upgradeEngine.test.ts src/lib/upgradeFinder.test.ts && npx tsc --noEmit` and require GREEN.

## Task 2: Reconcile documentation and tracking

**Files:**
- Modify: `C:/Projects/StatForge-App/README.md`
- Modify: `C:/Projects/StatForge-App/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/AUDIT.md`
- Modify: `C:/Projects/StatForge/CHANGELOG.md`
- Modify: `C:/Projects/StatForge/CHANGELOGS.md`
- Modify: local `statforge-app-ui` reference only if its support list becomes stale.

Document the supported Protection-dominant → Holy boundary, preserved hybrid weights, explicit fallbacks, lack of complete rotation/threat simulation, and unchanged addon schema.

## Task 3: Verify and close the milestone

1. App: `npm run test && npm run lint && npm run build && git diff --check`.
2. Addon/tracking: `npm test && git diff --check`.
3. Inspect complete diffs and scan intended staged files for secrets.
4. Commit/push both repositories as `Gohan <gohan@local>` because the user explicitly asked to proceed with the audit milestone.
5. Require exact-SHA GitHub Actions success, fetch, and verify clean `HEAD == origin/<branch>` with zero ahead/behind in both repositories.
