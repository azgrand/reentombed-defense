# Reentombed Defense — Milestone 3: Visual & Gameplay Expansion

**Spec ID:** `2026-11-18-001-milestone-3-visual-gameplay-expansion`  
**Target version:** `v0.3`  
**Status:** Ready for Codex implementation, subject to repository verification  
**Project:** [azgrand/reentombed-defense](https://github.com/azgrand/reentombed-defense)  
**Authored:** 2026-11-18  
**Language of this spec:** Spanish. **Language of code, identifiers and paths:** English (`snake_case`).

> **Execution contract:** This is one *master milestone* divided into small, independently verifiable phases. Implement them in order, with separate commits and test runs. Do **not** replace the existing project with a new prototype or silently remove behavior to simplify implementation. If an implementation detail conflicts with the real repository, inspect the code, document the conflict and preserve the functional intent of this spec.

## 1. Context

### 1.1. Verified starting point (repository `main`, 2026-11-18)

- Godot 4.x, GDScript, Compatibility renderer. `README.md` indicates Godot 4.3+; `project.godot` currently declares `config/features=PackedStringArray("4.6", "GL Compatibility")`: **verify the actual target editor/runtime version before implementation and correct documentation only after confirming**.
- Resolution target: **1280 × 800** with `canvas_items` stretch; initial scene `res://scenes/main.tscn`.
- Grid **29 × 21**, currently displayed at `TILE = 30.0` px and `ORIGIN = (28, 112)`.
- `EntombedMapper.generate(seed)` returns `{seed, cells, route}`. Cell values: `WALL=0`, `FLOOR=1`, `PATH=2`, `PAD=3`; a seeded contextual terrain pass + randomized DFS generates a single enemy route. Entrance is on the left; exit along the bottom. At least 30 pads and unique contiguous route currently expected.
- `scripts/game/main.gd` currently manages state, input, simulation, drawing and HUD; `scripts/game/art.gd` contains a texture catalogue.
- Three towers in `data/balance.json`: **Aguja** (`bolt`), **Mortero** (`blast`) and **Escarcha** (`frost`). Existing cost/damage/range/cooldown values are authoritative. Mortero hits in area; Escarcha slows by factor 0.45 for 1.6 seconds.
- Current input: 1–3 choose towers, left click build on pad, right click sells with `floor(base_cost * 0.65)`, Space starts wave, P pauses; seed repeat/new map exist.
- Economy: 180 starting gold, 20 lives, 10 waves, +25 gold per completed wave. Existing enemy spawn, reward and progression rules must continue unless expressly changed below.
- Existing asset pack is `assets/simple_tower_defense/` (46 original PNG according to `assets/README.md`); sprites and projectiles are currently selected by list index. **Inventory the actual files before selecting additional sprites; do not invent asset filenames.**
- Current tests include **1,000 seeded maps** plus combat and economy assertions. Existing `tools/check_project.py` and `specs/balance.schema.json` require exactly three towers. Adapt them.

### 1.2. Product problem

The map is technically valid but often visually noisy: heavily meandering route, stone pads generated around nearly every path tile, decoration without deliberate grouping, limited tile transitions. The tower menu is a vertical information-heavy list. There is no main menu, no tower upgrades, no extensible tower behavior system, and game strings are hardcoded in Spanish.

### 1.3. Goal

Deliver a more polished, readable tower-defense game while preserving its **seed-based identity**, existing assets, deterministic map generation, functional combat loop and current baseline test coverage.

## 2. Files to read (mandatory, before code changes)

- `README.md`
- `project.godot`
- `scenes/main.tscn`
- `scripts/core/entombed_mapper.gd`
- `scripts/game/main.gd`
- `scripts/game/art.gd`
- `data/balance.json`
- `specs/map-generator.md`
- `specs/game-design.md`
- `specs/architecture.md`
- `specs/acceptance.md`
- `specs/balance.schema.json`
- `tests/run_tests.gd`
- `tools/check_project.py`
- `assets/README.md` and the actual PNG inventory beneath `assets/simple_tower_defense/`

**Read before editing:** inspect `git status`, local Godot version, resource paths and all existing tests. Do not assume this milestone document mirrors uncommitted Codex changes.

## 3. Task / scope

Implement seven workstreams:

1. Better procedural **map layout and environmental visuals**.
2. Replace vertical tower list with a **grid-based tower shop** and **hover/focus information**.
3. Add **four genuinely differentiated towers**.
4. Add **per-tower levels and paid upgrades**.
5. Add **main menu** with Play / Settings / Quit, and an in-game return flow.
6. Introduce **full internationalization** (English and Spanish).
7. Additional polish: **valid placement preview**, **next-wave preview** and **persistent settings**.

### Non-goals for v0.3

No online services, multiplayer, dynamic rerouting after placement, full save/load of a run, user accounts, monetization, new game modes or mandatory external addons. Keep the original 10-wave mode as the default.

## 4. Implementation order / deliverables

**Phase A — Foundation:** make code/data extensible and secure existing tests. Split the oversized `main.gd` by responsibilities without gratuitously rewriting the game loop. Preserve an adapter for existing tests or migrate tests in the same commit.  
**Phase B — Visual map v0.3:** quality-based generation, tile transitions, restrained and clustered decoration.  
**Phase C — Localization and menus:** `.po` catalogues, main menu, settings, resume/return flow.  
**Phase D — Shop and new tower behaviors:** two-column grid, information tooltip, four extra towers, data-driven input.  
**Phase E — Tower upgrades and context panel:** level progression, level-dependent stats, sale accounting.  
**Phase F — UX polish, automated validation, screenshots, documentation and balance review.**

Each phase should compile, be manually usable, and pass the relevant automated tests before proceeding. If a phase is too large for one Codex pass, split it into subcommits, not an unreviewable monolithic change.

---

## 5. Feature MAP-01 — Map generation with an aesthetic quality pass

### 5.1. Layout strategy

**Preserve the spirit of the existing Entombed-adapted generator**, including the independent seed-controlled RNG and cell/route contract. Add a *bounded selection-and-polish stage*, not an arbitrary handcrafted fixed level.

1. Generate up to **16 deterministic candidates** using RNG streams derived locally from the requested seed and candidate index. The same original seed must choose the same final map on the same target engine/generator version. No global random state.
2. Compute a reproducible, documented **quality score** per candidate, based on:
   - Visually understandable route: meaningful straight sections and intentional turns; penalize frequent alternating one-cell zigzags.
   - Reasonable route length: **prefer** approximately 45–120 tiles on the current 29×21 grid; treat as a tuning target, not an unsupported guarantee.
   - Room to build: at least 30 legal pads after styling, distributed across early/middle/late route sections.
   - Avoid excessive parallel route segments directly adjacent without useful spacing, where practical.
   - Variation between seeds: no hardcoded single route or fixed entrances.
3. Prefer the highest-scoring valid candidate; ties resolved by deterministic candidate order. When none meets preferred thresholds, select the best *valid* candidate. **Always terminate**; no unbounded `while` rerolls.
4. Preserve one ordered, orthogonally connected enemy route, a left-edge entry, a bottom-edge exit, no duplicate route tiles, no tower placement on paths or walls, and 30+ legal pads.
5. Preserve or version the existing `{seed, cells, route}` shape. It is permitted to add optional `visuals`, `decorations`, `theme`, `generator_version` keys. Do not repurpose the numeric cell IDs silently.
6. Seeds from v0.2 may produce different maps under v0.3. Record this in `specs/map-generator.md` and expose `generator_version` in diagnostics if necessary; **do not promise backward-identical maps**.

### 5.2. Build-pad distribution

- Stop promoting **every** orthogonal neighbor of the route to a visibly dominant stone platform.
- Pick legal pads via a deterministic distribution algorithm: spread them across the route, favor clear placement areas, limit large uninterrupted blobs of stone, guarantee at least 30 buildable pads.
- Other adjacent non-path cells remain non-buildable terrain/decoration (no gameplay collision changes).
- Keep the `+` build marker only when helpful (e.g. empty pad and/or placement mode). Existing players must still be able to identify legal pads immediately.
- Do not change a pad's build legality merely because decoration visually overlaps it.

### 5.3. Visual treatment

- Use the **existing art pack** first. Inspect the ground/stone atlases before defining sprite-region coordinates. Replace the current simplistic four-neighbor atlas selection only with a tile mapping that matches the actual atlas layout.
- Add visually coherent road edges, turns, end caps and transitions to grass. Avoid obvious disconnected dirt squares.
- Create seed-stable decoration groups (e.g. forest clusters, isolated rocks/mushrooms, small clearings). **No decoration may obscure the enemy path, entrance, exit, occupied tower, hover targeting or build-pad indicator.**
- If several looks are feasible with the supplied art, choose 2–3 lightweight visual themes/palettes (e.g. forest, ruins, overgrown) using only existing resources, palette variations and decoration density. Theme is selected deterministically from the map seed and does not change tower mechanics.
- Render order: background → decorative ground → path/pads → non-blocking decorations → combat entities/effects → highlights and UI. Any taller decorative sprite overlapping a lane should be clipped, culled or relocated rather than hiding an enemy.
- Keep `TEXTURE_FILTER_NEAREST` and pixel-art-friendly integer-aligned placement. Avoid expensive texture loads or costly procedural layout recomputation in `_process`/`_draw`.
- Precompute static cells/autotile and decoration decisions **once on map creation**, draw/cache them efficiently; only animate dynamic objects per frame.

### 5.4. Acceptance

- [ ] Same seed and generator version produce identical `cells`, `route`, chosen theme and decoration metadata.
- [ ] 1,000 seeds: all routes connected and unique, all pads valid, minimum 30 build pads, no infinite loops; existing variety tests pass or are meaningfully adapted.
- [ ] No route covered by tall decoration; paths, turns and endpoints visibly connect at 1280×800 and scaled windows.
- [ ] At least 20 seed screenshots are inspected for overcrowding, unreadable routes, empty regions and excessive stone pads; document examples.
- [ ] Changing a map resets the current run as before; build/combat/seed-repeat still work.

## 6. Feature UI-01 — Grid tower shop with hover/focus details

### 6.1. Shop layout

- Replace the three large vertical shop buttons with a **2-column `GridContainer`** inside the existing right-hand panel; support at least **8 slots** without overlapping stats, wave controls, seed inputs or messages.
- Each card shows **tower sprite + localized short name**, selected state and a clear affordable/unaffordable visual. Full damage, cost, range and behavior text are **not permanently printed in each card**.
- Hover with mouse or focus with keyboard/gamepad opens a **localized tooltip/info panel** showing: name, role, cost, damage, cooldown, range, approximate DPS for direct-damage towers, and special effect/description. For the non-damaging support tower show "Support" rather than misleading `0 DPS`.
- Tooltip must stay within viewport and not prevent clicking the grid card. The tooltip should remain readable for disabled/unaffordable towers.
- Selection by clicking cards. Numeric shortcuts **1–7** map to the current seven towers in the data order; generate this mapping from available towers and guard invalid indices. Show shortcut on each card/tooltip. Optional scroll support if future roster expands.
- Use Control containers/anchors instead of fragile fixed screen offsets for new UI. Accommodate localized text and 1280×800 target.

### 6.2. Interactions

- The selected shop card gets a persistent, readable highlight. Insufficient gold blocks buying, **not** inspecting or selecting.
- On map hover with selected tower: range preview + semi-transparent sprite ghost; **green/positive** for valid empty pad with enough gold, **red/negative** otherwise. No click should spend gold on invalid tiles.
- When a built tower is left-clicked, open **existing-tower details**, not a purchase. Distinguish shop selection from selected existing tower. Right-click selling may be preserved as a shortcut, but the upgrade panel must also contain a visible Sell action and refund preview.
- Focus navigation and ESC/back behavior must not accidentally build/sell towers.

### 6.3. Acceptance

- [ ] 7 cards fit in 2 columns × 4 rows (one empty cell) at 1280×800.
- [ ] Tooltip renders all values correctly on hover and keyboard focus, including new statuses and upgrade values.
- [ ] Selection/shortcuts 1–7 work; no out-of-bounds access, including when data order changes.
- [ ] Shop is usable without pointer hover via keyboard focus/click; translated text does not overflow.
- [ ] Valid/invalid placement indicators are correct and spending is atomic.

## 7. Feature TWR-01 — Expand arsenal from three to seven towers

### 7.1. Current towers (preserve identity and baseline values)

| ID | Display name ES / EN | Role | Baseline cost | Baseline mechanics |
|---|---|---|---:|---|
| `bolt` | Aguja / Needle | fast single-target | 50 | damage 16, range 3.2, cooldown 0.55 |
| `blast` | Mortero / Mortar | area damage | 85 | damage 28, range 3.8, cooldown 1.5, splash 1.5 |
| `frost` | Escarcha / Frost | slow/debuff | 65 | damage 5, range 2.8, cooldown 0.75, slow factor 0.45 for 1.6 s |

### 7.2. Proposed new tower types — starting balance, tune after test play

| ID | ES / EN | Cost | Damage | Range | Cooldown | Unique behavior |
|---|---|---:|---:|---:|---:|---|
| `venom` | Veneno / Venom | 90 | 6 | 3.1 | 1.0 s | Applies **poison 9 damage/s for 3.0 s**. Reapply refreshes duration; overlapping poisons from the same effect do not stack DPS. Dead enemies cannot pay reward twice. |
| `storm` | Tormenta / Storm | 120 | 18 | 3.3 | 1.25 s | **Chain lightning**: initial target plus at most 3 additional enemies, each jump within 1.8 cells of the previous one; each next hit deals 70% of the previous damage; no repeated target. |
| `pierce` | Balista / Ballista | 110 | 30 | 4.5 | 1.6 s | **Piercing bolt**: hits up to 3 enemies aligned near the shot segment (tolerance 0.45 cells); one hit per enemy per shot. Deterministic targeting and hit order. |
| `banner` | Estandarte / Banner | 100 | 0 | 2.5 | — | **Support aura**: friendly towers within 2.5 cells fire **15% faster**; excludes itself; overlapping auras use the strongest bonus, do not stack. Does not target enemies or fire projectiles. |

**Do not silently add another armor reduction system:** in v0.2 "armored" enemies only have extra HP and reduced speed. If proper armor/resistance is proposed later, document and balance it as a separate milestone.

### 7.3. Implementation rules

- Replace `Art.TOWERS[i]` and `Art.PROJECTILES[kind]` position-based assumptions with data-driven **IDs / explicit art mappings**, with an intentional fallback if a compatible sprite does not exist. Retain the original PNGs unmodified and respect their license status.
- Inventory the provided art pack and choose visually distinguishable sprites for each new tower. If a role lacks a matching image, use a documented tint/overlay of an existing asset rather than a broken preload or invented filename; list such substitutions in the agent report.
- Separate the tower **definition** (cost/stats/behavior/art/localization key), **instance runtime state** (cell, level, cooldown, invested gold, target etc.) and **behavior execution**. A small behavior dispatch/strategy pattern is acceptable; a complex framework is not required.
- `data/balance.json` remains authoritative. Extend `specs/balance.schema.json` and `tools/check_project.py`: unique IDs, >=7 supported towers, behavior-specific constraints. For passive support `damage=0` and `cooldown=0` are valid **only** for non-attacking behavior.
- Explicitly define effect stacking and cleanup. Poison ticks must not move while paused; slow and poison must stop after expiry, defeat, victory or reset as appropriate.
- Maintain targeting baseline (furthest-progressed enemy in range) for offensive towers unless the special behavior demands a deterministic tie break. For chain and pierce, deterministic ordering is required.
- Non-damaging support towers must not collect on-kill gold; kill rewards remain credited once per defeated enemy, even with poison/area/chain effects.
- Existing prices and starting economy remain initially unchanged; check whether the four new towers can reasonably be purchased during normal play; tune values in `data/balance.json`, not hardcoded in scripts.

### 7.4. Acceptance

- [ ] Seven towers can be purchased, rendered, attacked/used as appropriate, and sold.
- [ ] Each new tower has a distinct, verifiable gameplay effect, including non-attacking support behavior.
- [ ] Poison refresh/no stack, chain target uniqueness, ballista one-hit-per-enemy, and no aura stacking are covered by tests.
- [ ] Projectile/impact effects visually correspond to role without requiring new external assets.
- [ ] No duplicate rewards, negative gold or attacks on already-dead enemies.
- [ ] Legacy three-tower tests are generalized rather than deleted.

## 8. Feature TWR-02 — Tower levels, upgrades and sale accounting

### 8.1. Player flow

- **Every placed tower starts at level 1; max level 4** in this milestone.
- Left-click an occupied pad/tower to select it. Open a panel showing tower name, **Level 1/4** etc., current damage/range/cooldown/DPS or aura effect, next-level stat delta, upgrade price, and Sell/refund.
- Upgrade button is disabled when at max level or gold is insufficient. Give readable feedback for failure/success. Do not upgrade a selected tower that was sold/reset during the same frame.
- Show compact level pips/badges above the placed tower (or on its base) without covering enemy health bars. At level 4 use a subtle visual distinction; no sprite scaling that makes footprint ambiguous.

### 8.2. Baseline formulas (data-driven and testable)

For offensive towers, let `d0`, `r0` be base damage and range:

| Level | Damage multiplier | Range addition |
|---:|---:|---:|
| 1 | ×1.00 | +0.00 cells |
| 2 | ×1.35 | +0.10 cells |
| 3 | ×1.75 | +0.20 cells |
| 4 | ×2.25 | +0.30 cells |

- Damage shown and damage applied use the **same calculation**. Keep full precision internally and format display consistently (e.g. one decimal if needed); do not introduce inconsistent rounding.
- Default cooldown unchanged by tower level, unless a tower's explicitly configured behavior says otherwise.
- **Estandarte**: level-dependent aura speed bonus `[0.15, 0.20, 0.25, 0.30]`, with same level-dependent range growth. For non-damage towers the panel shows the aura percentage, not fake damage increases.
- Poison DOT, chain and pierce effects use **the upgraded tower's computed damage for direct hits**; poison DOT remains fixed initially unless explicitly configured as upgradable (do not accidentally double-scale damage). Prefer a documented data-field to control this.
- Upgrade price for level 1→2: `ceil(base_cost × 0.75)`; 2→3: `ceil(base_cost × 1.15)`; 3→4: `ceil(base_cost × 1.60)`. Use one shared calculation for UI, transaction and tests.
- Track `total_invested` for each instance = purchase cost + successful upgrade costs.
- Sale refund = `floor(total_invested × 0.65)`. Level-1 behavior remains identical to existing sale value; higher-level towers return a fair proportion of investment. **No upgrade/sell cycle may generate gold.**
- Applying buffs: aggregate aura **dynamically or with correct invalidation** when adding/removing/upgrading support towers; exclude self; take strongest active bonus; do not permanently modify base tower definitions. An affected tower's new cooldown must be based on its computed attack speed at firing time.

### 8.3. Acceptance

- [ ] All seven tower types upgrade to level 4 (support tower improves aura).
- [ ] Money and computed stats match declared formulas exactly; max level cannot upgrade again.
- [ ] Tower upgrades do not occupy an extra pad or reroute enemies.
- [ ] Upgrading/selling while waves are active is safe; paused/ended handling is consistent and documented.
- [ ] Selling returns 65% of total investment rounded down; resetting clears all levels and investment.
- [ ] Tests cover upgrade success/failure, max level, upgrades during active waves, sell refund, and aura updates.

## 9. Feature MENU-01 — Main menu, Settings, Quit and navigation

### 9.1. Scenes and entry

- Add `scenes/main_menu.tscn` as the **actual startup scene** in `project.godot`; reuse `scenes/main.tscn` as the game scene or rename only with a clear migration.
- Main menu must have title/logo **Reentombed Defense** and three primary actions: **Play**, **Settings**, **Quit**. Background uses existing visual assets or a lightweight original drawing; do not fetch new paid assets.
- **Play** starts a new run with a fresh random seed, maintaining current starting economy and 10 waves.
- **Settings** opens a reusable settings panel, accessible from main menu and in-game pause menu.
- **Quit** closes the application on desktop; do not bind to `get_tree().quit()` as a side effect on menu creation/import/tests.

### 9.2. In-game navigation

- `P` continues to pause/unpause; `Esc` opens/closes pause menu unless a tooltip/modal needs dismissal first.
- Pause menu: **Resume**, **Settings**, **Main Menu**. The game state must remain frozen while settings or pause overlay is open.
- **Main Menu** requires confirmation that unsaved run progress will be lost. Cancel returns to paused game; confirm returns to main menu. v0.3 does not implement saved runs.
- Victory/defeat should show a legible overlay with **Retry same seed**, **New map**, **Main Menu** (recommended additional polish). Reuse existing result logic, do not create duplicate end-state transitions.
- Scene switches must free the old gameplay scene safely and avoid dangling audio/UI callbacks.

### 9.3. Settings

- **Language**: English / Español (immediate application).
- **Sound**: on/off (initially reuses existing `audio_enabled` semantics, applied across scenes); optional simple master-volume slider if safe to implement in current audio setup.
- **Window mode**: windowed/fullscreen, with a safe default, if supported by the target desktop export. Avoid platform-specific crashes when headless.
- Save only preferences in `user://settings.cfg` (ConfigFile or equally simple native Godot persistence); corrupted/missing settings must be handled gracefully with defaults. **Do not save game state here.**

### 9.4. Acceptance

- [ ] F5 opens menu, not immediate gameplay. Play starts functioning game.
- [ ] Quit works on desktop, and automated headless tests can run without invoking it.
- [ ] Settings work from both menu and pause; returning from settings preserves the previous context.
- [ ] Pausing fully freezes simulation, poison, animations, spawn timers and effects.
- [ ] Main Menu confirmation protects an active run, and victory/defeat navigation works.
- [ ] Settings persist after restart; corrupt file loads documented defaults without crash.

## 10. Feature I18N-01 — English and Spanish translation infrastructure

### 10.1. Required directory structure

```text
localization/
├── en.po
├── es.po
└── README.md
```

Use **Godot's native gettext `.po` support**, registered in Project Settings → Localization → Translations (`project.godot`), not a custom JSON translation engine. Source `.po` files stay in Git; do not commit generated `.godot/` import cache. `TranslationServer.set_locale()` selects a language; code and dynamic UI use `tr()`/`tr_n()` where appropriate.

### 10.2. Key design

- Use stable semantic keys such as `menu.play`, `menu.settings`, `menu.quit`, `shop.cost`, `shop.damage`, `tower.bolt.name`, `tower.venom.description`, `game.wave_started`, `game.not_enough_gold`, `game.victory`, `game.defeat`, `settings.language`, `settings.sound`, etc.
- The Spanish and English catalogues must contain the **same keys**, with natural language translations, not an empty placeholder file.
- Replace every player-visible hardcoded string: menus, instructions, seed errors, wave messages, tower names/descriptions, tooltips, stats, upgrades, victory/defeat, settings, buttons and confirmations. Keep internal IDs (`bolt`, `storm`, etc.) stable and untranslated.
- Dynamic messages should use **named placeholders** (e.g. `{amount}` or a Godot-supported named formatting form) with identical placeholder names in both catalogues. Prefer safe `tr()` + Dictionary `%` formatting as supported by Godot; validate in running project.
- `data/balance.json` must refer to a `name_key`/`description_key` rather than treating the existing Spanish `name` as the authoritative UI string. Handle any required migration predictably; don't silently alter combat IDs.
- Brand/title **Reentombed Defense** may remain untranslated. Keyboards shortcuts, numbers, seed digits and asset filenames are not localizable text.
- On locale change, update **already-visible dynamic UI**, tooltips, menu buttons and status labels immediately. Do not require restarting a run.
- Starting language: saved preference if present; otherwise use Spanish for system locales beginning `es`, English otherwise; fallback to English for unsupported locales.
- `localization/README.md` explains how to add a third language and run the missing-key check.

### 10.3. Acceptance

- [ ] Both `en.po` and `es.po` are complete for all in-scope player-facing text.
- [ ] Switching language in Settings updates active menus, game HUD, hover tooltip, tower details and messages without restart.
- [ ] No hardcoded Spanish UI strings remain in GDScript/scene text outside translation resources, except comments, debug/dev output and explicitly documented proper nouns.
- [ ] Missing-key validator detects untranslated or missing keys and placeholder mismatches.
- [ ] English and Spanish fit visually at the 1280×800 viewport; keyboard navigation is still usable.

## 11. Extra quality-of-life features

### QOL-01 — Placement validation preview

- Green/valid and red/invalid ghost plus range circle, visible when mouse is over board and a tower type is selected.
- Distinguish: legal pad, already occupied, blocked cell, insufficient gold, paused/ended state; feedback in localized tooltip/hint.
- Grid coordinates and visual placement must match exactly; never show a green ghost on an illegal cell.

### QOL-02 — Next-wave forecast

- While in preparation, show **upcoming wave number**, **expected total enemies** (`6 + 2*n` under current rules), and estimated number of heavy/large enemies based on global enemy ID modulo 5; do not hardcode a false forecast.
- Provide a localized brief warning/special-enemy legend. Update immediately at wave completion and after reset.
- Do not reveal future random data that the game has not generated unless deterministically derivable from current wave rules.

### QOL-03 — Lightweight gameplay feedback

- Add clear feedback for upgrade success, insufficient gold, enemy poisoning, chain jump, aura buff and final-wave victory (minor non-blocking effects, no flashing strobe).
- Preserve nearest-neighbor pixel art and consistent layering; minimize excessive per-frame node/resource allocations.
- Keep mouse/keyboard usability and maintain legibility of gold/lives/wave throughout combat.

## 12. Proposed modular architecture (adjust to actual repository)

Suggested file ownership (examples, not a forced full rewrite):

```text
scenes/
  main_menu.tscn                  # NEW: startup
  main.tscn                       # EXISTING: gameplay
  ui/settings_panel.tscn         # NEW: reusable settings
  ui/tower_shop.tscn             # NEW: two-column cards
  ui/tower_details.tscn          # NEW: placed tower actions
scripts/
  core/entombed_mapper.gd        # EXISTING: pure deterministic generation
  core/map_quality.gd            # NEW: candidate score / guardrails
  game/main.gd                   # EXISTING: coordinator and compatibility
  game/art.gd                    # EXISTING: data-driven art mapping
  game/tower_system.gd           # NEW: stats, behaviors, upgrades
  game/map_renderer.gd           # NEW: visual-only seeded map layers
  ui/main_menu.gd                # NEW
  ui/settings_panel.gd           # NEW
  ui/tower_shop.gd               # NEW
  ui/tower_details.gd            # NEW
  services/settings_store.gd     # NEW: preferences only
  services/localization.gd       # NEW: optional, if useful; no custom translator
localization/
  en.po
  es.po
  README.md
data/
  balance.json                   # MODIFIED: 7 towers, effect params
specs/
  map-generator.md               # UPDATED v0.3
  game-design.md                 # UPDATED v0.3
  architecture.md                # UPDATED
  acceptance.md                  # UPDATED
  balance.schema.json            # UPDATED
tests/
  run_tests.gd                   # UPDATED, not stripped
  ...                            # NEW focused tests if helpful
tools/
  check_project.py               # UPDATED validators
  ...                            # NEW localization / map analysis tooling
```

**Important:** These are proposed paths. Codex must verify the current tree and may choose fewer files to keep complexity reasonable. Do not duplicate state owners. Avoid adding a third-party architecture framework or new runtime dependencies. Prefer signals where UI observes state changes; gameplay logic should not depend on a specific tooltip layout.

## 13. Invariants and compatibility requirements

1. The map generator remains deterministic for a given seed and v0.3 generator version. It must never block the main thread indefinitely.
2. Enemies follow the reserved path; placing/upgrading/selling towers never edits route geometry.
3. Existing wave progression and initial economy remain compatible, except explicit new tower/upgrade expenditures.
4. No negative gold, duplicate gold rewards, invalid purchases, duplicate tower occupation, attacks on already-dead enemies or invalid indices.
5. No asset renames, deletion or modification to the supplied original PNG files unless necessary and documented; verify license before redistributing third-party assets beyond current usage.
6. No hardcoded count of three towers anywhere in input, art lookup, validator, tests or shop.
7. Correct pause behavior applies to **all** effects and animations, including new poison/aura states.
8. A tower's displayed stats equal the stats used in simulation; the same shared calculator feeds both.
9. Runtime logic remains reasonably testable headless without requiring screenshots, mouse movement or audio hardware.
10. Avoid per-frame translation parsing, reloading assets, map generation or rebuilding all shop nodes. Update UI on state changes when practical.
11. Keep code identifiers and function names in English and `snake_case`. UI text is localizable.
12. Respect the actual Godot engine version used by the project; report and resolve any `README` vs `project.godot` version discrepancy rather than assuming compatibility.

## 14. Acceptance criteria — complete milestone

### 14.1. Automated verification

Run (or clearly report why unavailable):

```bash
python3 tools/check_project.py
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --quit-after 120
```

If the binary is named `godot4`, replace `godot`; use the installed engine version or container documented by project. Also add dedicated automated checks for:

- 1,000 seeds: deterministic result, unique/contiguous route, entry/exit, pads>=30, stable decoration/theme, quality scorer termination and reasonable variety.
- All 7 tower definitions parse and possess valid referenced assets/localization keys.
- All special tower behaviors: DOT timing/refresh, chain max jumps/no repeated hit, piercing max 3, support strongest-only buff and exclusion of self.
- Upgrade formulas, insufficient gold, max level, expected refund, sell/reset safety.
- Pause correctness for new effects and game transitions.
- Locale catalogue key parity and placeholder parity; settings serialization and defaults.
- Shop indexing/shortcut mapping, no viewport overflow logic as feasible (manual inspection still required).

Do not simply delete/relax existing `tests/run_tests.gd` assertions to make the suite green. When behavior legitimately changes, replace assertions with equally meaningful new invariants.

### 14.2. Manual acceptance scenarios

1. Launch: see menu; Play begins new seed. Settings toggles ES/EN, persists on app relaunch.
2. Generate/repeat ~20 seeds; assess route readability, non-repetitive scenery and platform distribution.
3. Hover/focus each of seven shop cards: correct localized stats; select and place legally; invalid placements clearly rejected.
4. Inspect each tower type during wave: role-specific attack/effect; combat remains playable.
5. Click placed tower: inspect level/stats; upgrade 1→2→3→4 and sell for correct amount. Try insufficient gold and max level.
6. Place adjacent Estandartes, move/sell/upgrade one: verify no stacked permanent bonus.
7. Pause mid-poison/chain with P/Esc: no simulated time advances. Resume, end wave, show next-wave forecast.
8. Return to main menu mid-run with confirmation; cancel preserves it, confirm discards it.
9. Victory/defeat overlays: Retry seed, New map, Main Menu correctly reset and navigate.
10. Resize window / test text in English and Spanish; confirm HUD never blocks buildable map, tooltip never goes offscreen.
11. Validate no errors in Godot Debugger or broken resources after clean import; verify `gl_compatibility` output.

### 14.3. Screenshots for manual QA

Capture/attach (if display available) **menu**, **settings in Spanish**, **English shop hover**, **seed 42 map**, **another seed map**, **tower level 4 details**, and **combat with effect**. Record inspected seed values. Headless tests are not a substitute for visually judging whether the map is "bonito".

## 15. Completion definition

All feature acceptance items above must be satisfied; docs, balance schema and tests must reflect the actual shipping project. New towers must be visually distinct and mechanistically verifiable. Language switching must work immediately. Keep a stable executable game at the end of every phase.

### Agent response / Codex reporting contract

For **every phase**, report in Spanish:

1. What was implemented, with the related feature IDs and commit hash (if committed).
2. Exact files created/modified and why.
3. Tests run and actual results (or explicit limitations; never invent a pass).
4. Asset mappings used for each new tower and any missing/fallback art.
5. Manual smoke-test steps and concrete seeds to review.
6. Risks, departures from the spec, follow-up technical debt.
7. Whether the phase is ready for the next one. **Stop if a blocking acceptance criterion fails.**

### Suggested commit groups

- `refactor: prepare extensible tower and ui architecture`
- `feat: improve seeded map layouts and environment rendering`
- `feat: add localization and main menu settings`
- `feat: add grid-based tower shop and four behaviors`
- `feat: add tower upgrade progression and refunds`
- `test: cover v0.3 systems and document visual acceptance`

## 16. Relevant source references

Project references at drafting time:

- `README.md`: https://github.com/azgrand/reentombed-defense
- Map generator: https://github.com/azgrand/reentombed-defense/blob/main/scripts/core/entombed_mapper.gd
- Game: https://github.com/azgrand/reentombed-defense/blob/main/scripts/game/main.gd
- Art: https://github.com/azgrand/reentombed-defense/blob/main/scripts/game/art.gd
- Balance: https://github.com/azgrand/reentombed-defense/blob/main/data/balance.json
- Existing map contract: https://github.com/azgrand/reentombed-defense/blob/main/specs/map-generator.md
- Existing acceptance: https://github.com/azgrand/reentombed-defense/blob/main/specs/acceptance.md
- Existing test runner: https://github.com/azgrand/reentombed-defense/blob/main/tests/run_tests.gd
- Godot gettext: https://docs.godotengine.org/en/stable/tutorials/i18n/localization_using_gettext.html
- Godot internationalization: https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html
