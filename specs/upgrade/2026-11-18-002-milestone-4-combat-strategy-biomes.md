# Reentombed Defense — Milestone 4: Combat, Strategy & Biome Art Foundation

**Spec ID:** `2026-11-18-002-milestone-4-combat-strategy-biomes`  
**Target version:** `v0.4`  
**Status:** Ready for Codex, conditioned on repository and license audit  
**Project:** https://github.com/azgrand/reentombed-defense  
**Authored:** 2026-11-18  
**Spec language:** Spanish  
**Code, resources, configuration keys and filenames:** English, `snake_case`

> **IMPORTANT — Execution contract.** Read the *actual current repository* before changing anything. The foundation below is informed by the Milestone 3 specification, not a guaranteed snapshot of all local Codex commits. If M3 is incomplete, do not invent completed features: report gaps and address dependencies first. Keep existing gameplay and tests working. Implement incrementally; produce commits and a structured agent report. Never silently change balances or introduce assets whose usage rights are unverified.

## 1. Context

Reentombed Defense is a 2D Godot 4.x/GDScript tower-defense game with seed-based procedural maps. The prior specification (M3/v0.3) establishes seven tower roles (`bolt`, `blast`, `frost`, `venom`, `storm`, `pierce`, `banner`), up to four levels, a grid shop, main menu, EN/ES localization, preference persistence, and a deterministic map-quality pass. **Codex must verify all are truly implemented on the current branch before relying on them.**

The product goal of v0.4 is to transform basic tower placement into meaningful tactical choice, give enemies distinct counters, add a boss encounter, and introduce a coherent pipeline for **visual themes/biomes from genuinely free CC0 asset packs**, without changing the procedural route algorithm or creating incompatible art dependencies.

This is **not** the campaign, endless mode, Android port, advertising or monetization milestone. Those remain later phases. Art/theme support is included now because the user wants diverse locations and a commercial-use-safe asset foundation.

## 2. Files to read first (mandatory)

- `README.md`, `project.godot`, `.gitignore`
- `scenes/` — entry scene, game scene, shop and menus (find actual paths)
- `scripts/core/entombed_mapper.gd` and all current map rendering/theme code
- All current `scripts/game/` tower/enemy/projectile/combat/wave/upgrade/UI scripts (do not assume they have M3 filenames)
- `data/balance.json` and any enemy/tower data files
- `specs/game-design.md`, `specs/architecture.md`, `specs/map-generator.md`, `specs/acceptance.md`, `specs/balance.schema.json`
- `specs/2026-11-18-001-milestone-3-visual-gameplay-expansion.md` if present; otherwise inspect M3 commit history and updated design docs
- `tests/`, `tools/check_project.py`, `assets/README.md` and actual asset tree
- Latest Git commit, `git status`, Godot editor version, whether Godot headless tests pass

**Preflight output required:** record `git rev-parse HEAD`; list implemented M3 features, real class/node/API names; identify current assets and third-party licenses; list discrepancies. Preserve untouched files when unnecessary.

## 3. Goals and non-goals

### Goals

1. Differentiated enemy roster: armored, swift, healer and final boss, integrated in the existing ten-wave game.
2. Two real **branch specializations** for each of the three original towers (`bolt`, `blast`, `frost`) at level 3; meaningful level 4 scaling. Other four tower types retain their M3 upgrade path.
3. Two player **active abilities** with resource/time rules, feedback and deterministic combat behavior.
4. Tactical UI: inspect armor, resistances, next wave composition, abilities, branch choice, boss health and threat indicators.
5. Procedural map **visual biomes** `forest`, `crypt`, `desert`, `volcanic` reusing one validated route/build grid, with well documented CC0 art.
6. Reusable asset import/manifest/license pipeline; update architecture, tests, translations and screenshots.
7. Performance compatible with eventual HTML5/WebGL2 and Android: no mandatory native plugins or platform SDKs.

### Explicit non-goals

- No monetization, ads, payments, online services, network leaderboard, multiplayer, gacha, microtransactions.
- No complete campaign, season progression, user account, cloud save, level editor or mandatory downloadable packs.
- No change to map routing/cell IDs/entry-exit invariants unless required by a diagnosed bug and separately tested.
- No new tower IDs solely to increase the catalogue in this milestone.
- No forced replacement of existing art until asset rights and visual compatibility have been checked.
- No mixing different 16px and 32px tile resources directly in the same TileSet without explicitly adapting sizes/scales and auditing visual consistency.

## 4. Implementation phases and commits

**A — Audit and data contracts.** Snapshot current branch, fix confirmed critical M3 integration gaps only; add versioned enemy/branch/ability/theme data schemas and documentation. Re-run tests.  
**B — Combat enemies and statuses.** Armor/resistance handling, swift/healer enemies, wave profiles, final boss; deterministic targeting, cleanup and tests.  
**C — Tower branches.** Three original towers get two specializations at level 3 and branch-consistent level 4; UI and tests.  
**D — Active abilities and tactical HUD.** Ability selection/casting, cooldowns, next-wave detail, boss feedback; EN/ES translations; tests.  
**E — Asset audit/import and four visual biomes.** License registry, theme resources, visual-only terrain/props and deterministic decoration; snapshots and tests.  
**F — Integration and balance.** Automated and manual playtests, screenshots, project docs, changelog, agent report. Submit one coherent commit per phase or smaller incremental commits.

Do **not** claim a phase complete if mandatory art is not downloaded or validated. Report `BLOCKED_ASSET_INPUT` and keep a working CC0/fallback theme until the files are made available.

## 5. COMBAT-01 — Enemy traits, armor and wave composition

### 5.1. Data-driven enemy contract

Extend the existing enemy definitions, maintaining backward compatibility with legacy entries:

```json
{
  "id": "armored",
  "hp_multiplier": 1.60,
  "speed_multiplier": 0.78,
  "reward_multiplier": 1.30,
  "armor_physical": 0.30,
  "resistances": {"poison": 0.0, "slow": 0.0},
  "abilities": [],
  "art_id": "armored"
}
```

Numbers are starting **tuning values**, not a requirement to overwrite the repository's current enemy balance. A resistance in `[0,1]` indicates damage or slow-effect strength reduction; reserve complete immunity for an explicit `1.0`. Legacy entries default to zero armor and zero resistance. Clamp invalid values at parsing/validation and reject malformed definitions in dev/test runs.

Damage pipeline: resolve attack/type -> raw damage & tower upgrade -> specific branch modifiers -> relevant vulnerability/modifier -> physical armor (physical only) OR elemental resistance (when defined) -> integer damage floor/rounding consistently -> HP decrement -> at most one death/reward. Define attack kinds such as `physical`, `arcane`, `poison`, `frost`; map all seven existing tower attacks explicitly. For physical damage after armor, apply `max(1, ceil(raw * (1 - armor_physical)))` to a positive hit; zero-damage support effects remain zero. Poison DoT must not accidentally double apply armor and must retain M3 refresh/nonstack rules. If current damage model differs, publish a migration note and tests.

### 5.2. Minimum enemy variants

| ID | First appearance | Behavior | Counterplay |
|---|---|---|---|
| `swift` | Wave 3+ | Fast, lower HP (starting HP ×0.75, speed ×1.55) | Frost, range, rapid attacks |
| `armored` | Wave 4+ | Armor 30%, higher HP ×1.60, speed ×0.78 | Arcane/poison, mixed composition |
| `healer` | Wave 6+ | Heals up to 2 allies within 2 grid cells every 4.0 game seconds for 6% of *each recipient's max HP* (max 2 targets per tick); heal never resurrects; prioritizes lowest HP ratio then stable spawn ID | Focus fire, chain, area damage |
| `boss_crypt_warden` | Wave 10 | One boss, starting HP = 8x current wave baseline normal-foe HP; speed ×0.65; armor 20%; slow duration halved; visible phase transitions at 66%/33% remaining HP | Mixed towers, stored cooldowns, active abilities |

Preserve current enemy set and map legacy visuals to a fallback where no audited sprite exists. Avoid spawning multiple overlapping bosses. Give the boss two **mechanically modest** phases: on first threshold, next 5 seconds speed ×1.15; on second, one limited summon of two standard enemies on a valid route tile behind the boss, with globally unique IDs and standard scoring/rewards only if existing economy expects rewards. **Never** create new map paths or teleport summons across occupied segments. Events must trigger exactly once per boss lifecycle.

### 5.3. Wave composition

Preserve the normal ten-wave game, existing pacing, rewards and game-over rules. Configure new enemy mix with additive wave data rather than scattered `if wave >=` code. Guaranteed onboarding: swift at 3, armored at 4, healer at 6, one boss at 10. Wave previews must show actual next-wave types/counts. If wave generation is seeded, preserve determinism and serialize any combat RNG seed as needed.

### 5.4. Combat correctness

- Stable enemy identity and deterministic tie breakers for target selection, poison ticks, heals and boss summons.
- No double rewards, double deaths, negative HP healing bugs, status effects persisting across reset, healing after death, or callbacks on freed nodes.
- Pause stops all game-time timers, status ticks, healing, boss phases and ability cooldowns; menu/other UI may still animate separately.
- Enemy route progress remains orthogonally valid; no pathfinding changes in this milestone.
- Existing `venom`, `storm`, `pierce`, `banner` special logic continues to work against every enemy type.

## 6. TOWERS-01 — Level 3 branches for the original three towers

### 6.1. Common rules

Only `bolt`, `blast`, `frost` gain specializations in v0.4. At **level 2 -> level 3**, present a localized modal offering two branch choices and a cost preview; the purchase is **atomic**: no gold charged until branch selection is confirmed, placement still exists, and player has sufficient gold. Cancel leaves level 2 unchanged. A chosen branch is immutable until that specific tower is sold; selling retains the existing invested-gold formula (if currently implemented differently, preserve the tested policy and document). Level 4 enhances the same branch. New tower instances are independent. Default branch `null` at levels 1–2.

Data-driven branch IDs; do not hard-code localized strings in combat logic. Existing M3 upgrade stats remain baseline; branch effects apply **after** generic level multipliers. Show exact changes (damage, cooldown, range, effect) and an icon/color + text label; no color-only messaging.

### 6.2. Starter branch proposals

| Tower | Branch ID | Player-facing name EN / ES | Level 3 branch effect (relative to current upgraded stats) | Level 4 enhancement |
|---|---|---|---|---|
| `bolt` | `sniper` | Sniper / Francotirador | Damage ×1.25, range +0.8 cell, cooldown ×1.15 | Damage further ×1.10 |
| `bolt` | `rapid_fire` | Rapid Fire / Fuego rápido | Damage ×0.80, cooldown ×0.65 | Cooldown further ×0.90 |
| `blast` | `siege` | Siege / Asedio | Area radius +0.5 cell, cooldown ×1.15 | Area radius further +0.2 cell |
| `blast` | `breaker` | Armor Breaker / Rompearmaduras | Direct/splash attack ignores 50% of target's **physical armor fraction**, area radius −0.2 cell (min 0.5) | Ignore 75% of armor instead |
| `frost` | `deep_freeze` | Deep Freeze / Congelación profunda | Slow factor becomes min(existing factor, 0.38), duration +0.4 s | Slow factor becomes min(existing, 0.33) |
| `frost` | `brittle` | Brittle / Quebradizo | Slow factor becomes 0.60, and targets take +10% physical direct damage while chilled; no amplification of poison ticks | Physical vulnerability +15% instead |

**Interpretation safeguards:** lower slow factor = stronger slowing if the current system uses multiplicative speed factors; if the implementation uses another convention, adapt mathematically without reversing the effect. Do not make bosses permanently immobile: cap boss minimum speed multiplier at 0.65 regardless of stacked slow. Vulnerability does not stack between multiple `brittle` sources; strongest applies. `breaker` armor ignoring must be calculated once, not additionally applied as damage bonus. Decide explicitly whether blast's `breaker` applies to entire splash; proposed **yes**.

Branch multipliers affect simulated DPS and tooltip values; represent complex effects without deceptive DPS estimates. Upgrade costs are inherited from M3, unless playtesting demonstrates a documented balance problem.

## 7. ABILITY-01 — Active player abilities

Add two universal active abilities, available in the ten-wave mode without monetization or consumable inventory. Cooldowns begin only on a **successful cast**. Cooldowns tick in game time (pause-aware). No casting from a modal, while paused, between runs, or on invalid ground outside the board.

| ID | EN / ES | Trigger | Effect | Cooldown |
|---|---|---|---|---:|
| `arcane_burst` | Arcane Burst / Estallido arcano | Select ability, click on valid board cell | 25 arcane damage to each enemy within 1.5 cells, one hit per target; scales only if its own data value changes | 35 s |
| `battle_rally` | Battle Rally / Arenga | Select ability, click on valid board cell | Allied attacking towers within 2.5 cells fire 20% faster for 5 s; does not affect banner itself; for overlapping attack-speed buffs apply strongest single bonus, not sum | 45 s |

Inputs: `Q` and `E` on desktop; **visible** clickable/tappable HUD actions; Escape or right click cancels aim mode without spending cooldown. During targeting, show translucent radius and targetability warning. HUD shows key/icon, ready/cooldown state, a textual tooltip, and **no hover-only information** (future touch compatibility). Small impact particles and restrained SFX are optional only when assets verified and frame budget allows.

## 8. BIOME-01 — Themed procedural map art (visual-only)

### 8.1. Four required map themes

| Theme ID | EN / ES | Atmosphere | Proposed assets | Current gameplay rules |
|---|---|---|---|---|
| `forest` | Forest / Bosque | Grass, dirt trails, shrubs, woodland | Existing verified pack **or** Foozle Lucifer Exterior | No change |
| `crypt` | Crypt / Cripta | Stone slabs, walls, ruined floors | Foozle Lucifer Dungeon | No change |
| `desert` | Desert Ruins / Ruinas del desierto | Sandstone, sand, broken pillars | Foozle Lucifer Desert | No change |
| `volcanic` | Volcanic Depths / Profundidades volcánicas | Basalt, lava, scorched structures | Foozle Lucifer Lava Dungeon | No change |

A fifth optional **preview** `frozen` (Tierras heladas / Frozen Lands) can use the CC0 MurphysDad RPG Asset Pack / OpenGameArt Eman Quest ice-forest tiles; **do not declare it production-ready** unless palette, 16→32 scaling and tile transitions pass the visual audit. Do not automatically add gameplay penalties from lava/ice here.

### 8.2. Theme choice and preview

- Keep the original seeded generator's `cells`, `route`, pads, path movement, seed and geometry authoritative. A theme is a **visual skin**, not a different path algorithm.
- At map creation, allow `Auto`, `Forest`, `Crypt`, `Desert`, `Volcanic` via menu/settings/seed entry screen. `Auto` must resolve deterministically from `(seed, generator_version)` using a local stable algorithm, not global RNG. For explicit theme selection, the **same seed generates the exact same logical map** independent of theme.
- Include theme identifier in map preview, restart/seed UI, screenshots, QA reports. If theme is changed during an ongoing run, require explicit confirmation because visuals reload; no mid-wave hot-swap.
- Use a `MapTheme` data resource or equivalent configuration that maps symbolic tile roles (`ground`, `road_straight`, `road_turn`, `pad`, `wall`, `edge`, `prop_small`, `prop_tall`) to **verified existing paths/atlas regions**. Never guess resource filenames from pack marketing descriptions.
- Do not make decorations block route, valid build pads, mouse interaction, enemy visibility, tower levels or projectiles; decorative lava is not actual collision. Tall props must be excluded from critical silhouettes or correctly layered.
- Keep static terrain generated once and batched where feasible. Godot 4 `TileMapLayer`/`TileSet` is suitable when audited atlases support it; otherwise maintain existing draw/cache pipeline and document choice. Use nearest-neighbor filtering and pixel-aligned sampling. No texture allocation/reloading in `_process`.
- Different input resolutions and 1280×800 default must not clip walkable paths or shop. Avoid changing logical TILE/ORIGIN values casually: design an art adapter so 32×32 native tile art can fit the board's existing logical cell extent while retaining crisp edges where possible; test any visual scaling carefully.
- Prefer **one art family** for all four primary biomes (Foozle Lucifer) and treat other artist packs as optional supplements until palette, perspective and outline weight have been reviewed.

### 8.3. Quality targets

Each theme must make the road, legal build pads and enemies more legible than decoration. On 20 representative fixed seeds per theme, verify: every road edge/corner joins; entry/exit are unmistakable; build locations distinguishable; no misleading blocked/empty tiles; props not under the HUD. Choose one visual fallback for unavailable resources and surface a dev warning instead of crashing.

## 9. ASSET-01 — Audited source list (free and commercial-use-ready)

**Meaning of 'free':** Cost and legal permission are separate. For the assets below the original individual page was checked on 2026-11-18. `Name your own price` on itch.io allows a zero-price download, but manual browser interaction may be required. The listed creators declare **CC0 1.0** and, for Foozle, expressly state commercial modification/use is allowed. Re-open the page and the downloaded archive's license before importing, since listings can change. A generic 'free' tag is not enough. CC0 normally requires no attribution, but credits and a source registry are recommended. Licenses of existing `simple_tower_defense` assets must still be independently documented.

### 9.1. Primary coherent art family — Foozle, 'Lucifer'

| Pack | Role | URL | Page-declared terms | Size / notes |
|---|---|---|---|---|
| Lucifer - Exterior Tileset | Forest/exterior | https://foozlecc.itch.io/lucifer-exterior-tileset | CC0 1.0; commercial yes | 32×32; Aseprite source; browser download |
| Lucifer - Dungeon Tileset | Crypt | https://foozlecc.itch.io/lucifer-dungeon-tileset | CC0 1.0; commercial yes | Top-down dungeon; Aseprite source |
| Lucifer - Desert Tileset | Desert | https://foozlecc.itch.io/lucifer-desert-tileset | CC0 1.0; commercial yes | 32×32; Aseprite source |
| Lucifer - Lava Dungeon Tileset | Volcanic | https://foozlecc.itch.io/lucifer-lava-dungeon-tileset | CC0 1.0; commercial yes | 32×32; Aseprite source |
| Lucifer - RPG UI | Optional consistent menus/abilities | https://foozlecc.itch.io/lucifer-rpg-ui | CC0 1.0; commercial yes | HUD, icons, panels; review size before import |
| Lucifer - Possessed Enemy | Candidate for swift/elite visual | https://foozlecc.itch.io/lucifer-possessed-enemy | CC0 1.0; commercial yes | 4-direction animation; source spritesheet |
| Lucifer - Skeleton Hunter Enemy | Candidate for armored/crypt enemy | https://foozlecc.itch.io/lucifer-skeleton-hunter-enemy | CC0 1.0; commercial yes | 4-direction animation |
| Lucifer - Cultist Enemy | Candidate for healer/caster | https://foozlecc.itch.io/lucifer-cultist-enemy | CC0 1.0; commercial yes | 4-direction animation |

Mapping sprite roles is **art-direction guidance**, not a claim the pack contains a built-in armored/healer mechanic. Reuse the same animation with a role overlay when needed. Avoid inventing unreleased pack names, sprite paths or animation frame layouts.

### 9.2. Additional CC0 alternatives, forest/winter/towers/audio

| Pack | Intended use | URL | Verified page notes |
|---|---|---|---|
| Top Down season/environment Tileset | Spring/desert/winter terrain prototype | https://opengameart.org/content/top-down-seasonenvironment-tileset | CC0; 20×20 tiles; adapt before use |
| Forest and Dungeon Tilesets from Eman Quest | Ice forest, death forest, lava, desert dungeon | https://opengameart.org/content/forest-and-dungeon-tilesets-from-eman-quest | CC0; 16×16 source, palette variations; visually review provenance/mixing |
| Fantasy Forest Tileset — Deluxt | Alternative forest tiles and foliage | https://deluxtdev.itch.io/fantasy-forest-tileset | Free download, CC0; base 16×16 and optional 8×8 detail overlay; style review needed |
| RPG Asset Pack — MurphysDad | Snow/grass/autumn optional preview | https://murphysdad.itch.io/rpg-asset-pack | Free/pay-what-you-want, CC0; 16×16 |
| Tiny Dungeon — Kenney | Fallback props/icons/enemies | https://kenney.nl/assets/tiny-dungeon | CC0; 16×16 |
| Tiny Battle — Kenney | Alternate tower/enemy silhouettes | https://kenney.nl/assets/tiny-battle | CC0; 16×16 |
| Tower Defense (Top-Down) — Kenney | Tower/projectile/UI alternatives | https://kenney.nl/assets/tower-defense-top-down | CC0; 300 files, 2D |
| UI Pack - Pixel Adventure — Kenney | Optional UI polish | https://kenney.nl/assets/ui-pack-pixel-adventure | CC0 |
| Impact Sounds — Kenney | Combat sound polish | https://kenney.nl/assets/impact-sounds | CC0 |

**Do not auto-import every pack.** Choose the minimum set for consistent visual style and weight. Download only from the author/official pack page, and preserve origin, terms and file hashes in the manifest.

### 9.3. Assets NOT automatically approved

- Current `assets/simple_tower_defense` or any other itch.io pack whose exact original page/license is not in the repository: **UNKNOWN until verified**. The user's recollection that the download was free is not sufficient proof of commercial redistribution rights. Do not delete existing playable assets; use them in development while the owner verifies terms, but mark the commercial release audit as blocked.
- `[FREE] Forest Tilesets` by Ulerinn (https://ulerinn.itch.io/free-forest-tilesets): the page simultaneously states CC0 and **'You cannot redistribute or sell this asset pack'**. Do not package raw assets in a public repository without resolving that extra restriction; for this milestone favor the unambiguous packs above.
- Any paid pack or sampler that only advertises a free preview: do not assume full contents are freely downloadable; inspect the actual purchase/download section.

### 9.4. Asset storage and attribution contract

Proposed (adapt to existing layout):

```text
assets/
  third_party/
    foozle_lucifer_exterior/
    foozle_lucifer_dungeon/
    foozle_lucifer_desert/
    foozle_lucifer_lava/
    foozle_lucifer_enemies/
  generated/                 # only derived, checked-in assets actually needed by Godot
  _incoming/                 # local download staging, ignored by Git
  ASSET_MANIFEST.json
  CREDITS.md
  LICENSES.md
```

`ASSET_MANIFEST.json` per pack: `pack_id`, `title`, `author`, `source_url`, `license_name`, `license_url`, `checked_at_utc`, `archive_filename`, `archive_sha256`, `imported_files`, `commercial_use_allowed`, `attribution_required`, `notes`. Use SHA-256 only if actual downloaded bytes are present; **never invent hashes**. Store the license text/source reference for each pack; link to exact source pages. Exclude `.ase` originals, original ZIP archives, preview PSDs and unused files from distribution unless needed and authorized. If committing extracted images, ensure the license permits redistribution and attribution requirements are met. Add `assets/_incoming/` to `.gitignore`.

Codex acquisition rule: if internet download is blocked or itch.io requires a manual confirmation, do **not** scrape/bypass the website or falsely declare imported images. Provide a manual download checklist, then import assets supplied at `assets/_incoming/`. When an image is not present, use a compatible existing/CC0 fallback and issue a clear `BLOCKED_ASSET_INPUT` list.

## 10. UI/UX-01 — Readable tactics and accessibility

- Selected enemy info: name, current/max HP, physical armor, resistances, movement speed, special ability and an icon with text for status. Hide implementation details, keep numeric consistency.
- Tower inspector at L2: show 'Choose specialization' before upgrade. At L3/L4: chosen branch, effects, damage/range/cooldown deltas, no false DPS for `banner` or aura-only effects.
- Next wave panel: accurate **type counts** and boss indicator from actual queued spawn definition, not guesses. On first introduction, concise optional hint explaining counterplay (translated).
- Boss bar and phase notice: clear, non-obscuring. No full-screen flashing; respect reduced effects setting if present.
- Ability UI must be usable with visible buttons (no hover-only text), keyboard and future touch interaction. Keyboard help in settings; no reliance on inaccessible red/green-only communication.
- Internationalization: all player-visible additions use the project's M3 localization mechanism, at minimum EN + ES. Define keys, update translations and test both languages for layout clipping.

## 11. Architecture and portability

Suggested responsibilities, **not mandatory literal file paths**; align with repository's existing structure:

- `EnemyDefinition`/enemy configuration schema and `EnemyRuntime` for mutable HP, statuses, phase state, heal accumulator.
- `CombatResolver` for damage/armor/resistance modifiers shared by bullets, splash, poison and abilities; keep death/reward idempotent.
- `TowerBranchCatalog` for data/ID translation and `UpgradeController` for transactional upgrades.
- `AbilityController` for cast validation, game-time cooldowns and target previews.
- `MapThemeCatalog`/theme resource with explicit sprite mappings, separated from immutable `cells`/`route` generation.
- `AssetCatalog` with safe missing-resource fallbacks + manifest metadata.

Keep simple GDScript and stock Godot resources, compatible with the existing renderer and future Web export. Do not introduce GDExtension/C# or proprietary runtime SDK dependencies. Use instance/time budgets, cached textures and event-driven UI; avoid per-frame file I/O and expensive scene-wide queries. If TileMapLayer is adopted, test terrain joins and visual ordering on the actual atlas.

## 12. Data and migration requirements

- Extend existing balance schemas, rather than replacing `data/balance.json` and losing user balance edits. New enemy/branch/ability/theme configs may live in separate JSON or `.tres` resources; make them human-editable.
- Set a documented content/data schema version. Defaults for legacy enemies and towers preserve an upgradeable game. Gameplay state reset may be acceptable if full save/load has not yet shipped, but preferences and language must persist.
- Unique IDs across enemies, branches and abilities; validate referenced IDs and sprite keys; reject `NaN`, negatives, missing required values and invalid intervals.
- Provide plain-language balance release notes for any changes to tower prices, upgrades, enemy rewards or wave counts.

## 13. Verification and tests (mandatory)

**Static/config tests**

- [ ] No unknown/missing required IDs, art mappings, translation keys, source records, broken `res://` references, or incompatible Godot APIs.
- [ ] JSON/schema validation passes on actual current data, including legacy fallbacks.
- [ ] Asset manifest contains real source URLs, licenses, file inventory; no invented file hashes; license unknowns flagged.

**Combat tests**

- [ ] Physical armor applies once; magical/poison damage type rules consistently bypass physical armor unless explicitly documented.
- [ ] Swift vs normal speed ratio and armor changes produce expected outcomes from a shared baseline.
- [ ] Healer respects range, target priority, cooldown, max HP; by design **does not heal itself**, dead enemies or removed targets.
- [ ] Boss phase thresholds trigger once; final summon IDs unique; kill reward once; win/lose flow unchanged.
- [ ] Slow/brittle poison stacking rules respected; damage and buffs consistent with level 4 and seven tower types.
- [ ] Pause/resume/reset cleanly handle all combat timers and statuses.

**Upgrade and ability tests**

- [ ] Confirm/cancel/reject branch upgrade is atomic, cost correct, no silent branch reset or exploit from sell.
- [ ] All 6 branches produce discernibly different values/behavior at L3 and L4; other 4 towers retain existing upgrades.
- [ ] Ability target/cooldown/cancel validations; no ability cast during pause or outside board; overlapping banners/rallies do not compound illegitimately.

**Maps and visual QA**

- [ ] At least 1,000 deterministic seeds still satisfy route connectivity, pads, board bounds and no unbounded generation; theme doesn't mutate logical `cells` or `route`.
- [ ] `Auto` theme deterministic; manually choosing theme keeps seed geometry identical.
- [ ] For 20 fixed seeds × 4 themes, save screenshot/contact sheet samples (80 images or representative contact sheets), document unreadable corners, walls, pads and texture mismatches.
- [ ] Full playthrough of ten waves in each theme; enemy visibility + tower ghost, selection and UI not obscured by props.

**Performance/portability**

- [ ] Godot editor import and headless script/tests run with the actual project-pinned Godot 4.x editor.
- [ ] No runaway memory/resource reload; report rough FPS in busy wave on at least one actual test system and test screen resolutions including 1280×800 and a lower window setting.
- [ ] Avoid Android/Web-only platform dependencies. A separate export smoke test is welcome but not a condition of this milestone.

## 14. Suggested balance playtest protocol

Across at least 3 known seeds and 3 difficulty-neutral theme choices, test: (1) no abilities; (2) mixed tower types; (3) L3/L4 specializations; (4) use of abilities. Track lives left, gold earned/spent, waves failed, enemy leaks, DPS/kill breakdown where instrumentation exists, number of upgrades chosen, boss survival time. Prefer changing values in data files rather than patching constants. Do not promise that the initial numeric values are balanced without human playtesting.

## 15. Deliverables / required files

Minimum project results, adapted to actual architecture:

- Combat data configs and validation schema(s) for enemy archetypes, tower branch definitions, abilities, map themes.
- Gameplay scripts/scenes implementing COMBAT-01, TOWERS-01, ABILITY-01, UI/UX-01 and theme selection with resilient art fallback.
- New imported CC0 art **only when actual downloads, licenses and source paths have been verified**.
- `assets/ASSET_MANIFEST.json`, `assets/LICENSES.md`, `assets/CREDITS.md`, `assets/README.md` updated.
- `specs/architecture.md`, `specs/game-design.md`, `specs/map-generator.md`, `specs/acceptance.md` updated to v0.4 state.
- New/updated EN and ES translations, tests, screenshots/contact sheets and `CHANGELOG.md` entry.
- `specs/reports/milestone-4-implementation-report.md` with commits, verified tests, observed screenshots and asset provenance.

## 16. Agent response format (Codex mandatory)

Return a Markdown report with:

1. `Repository snapshot`: current commit, Godot version, M3 gaps found, any blocking issue.
2. `Implemented per phase`: exact scripts/scenes/data modified, brief behavior descriptions, any scope deviations.
3. `Asset acquisition`: exact pack URLs, licenses, checked archive hashes (only when computed), exact imported file paths; list outstanding `BLOCKED_ASSET_INPUT` items and asset provenance of the current legacy pack.
4. `Testing`: commands run, counts/results, selected manual gameplay seed(s), screenshots and performance notes; explicitly distinguish executed from unexecuted tests.
5. `Balance changes`: table of changed numerical values and rationale.
6. `Remaining work`: bugs, deferred frozen theme, Android/Web readiness issues, commercial asset restrictions and next suggested milestone.
7. `Git commits`: one or more clearly named commits and clean/dirty final `git status`.

Do not state a phase 'done' until both behavioral and visual acceptance criteria that depend on available resources have actually been verified. If download or Godot runtime is unavailable, state that transparently and stop at a working incremental checkpoint.

## 17. Reference links and license evidence

These links are source pages, **not** preauthorized local file paths. Last reviewed 2026-11-18:

- Foozle main pack family: https://itch.io/c/1557879/lucifer
- Exterior: https://foozlecc.itch.io/lucifer-exterior-tileset
- Dungeon: https://foozlecc.itch.io/lucifer-dungeon-tileset
- Desert: https://foozlecc.itch.io/lucifer-desert-tileset
- Lava dungeon: https://foozlecc.itch.io/lucifer-lava-dungeon-tileset
- UI: https://foozlecc.itch.io/lucifer-rpg-ui
- Enemy sprites: https://foozlecc.itch.io/lucifer-possessed-enemy ; https://foozlecc.itch.io/lucifer-skeleton-hunter-enemy ; https://foozlecc.itch.io/lucifer-cultist-enemy
- OpenGameArt CC0 winter/season: https://opengameart.org/content/top-down-seasonenvironment-tileset
- OpenGameArt CC0 forest/dungeon: https://opengameart.org/content/forest-and-dungeon-tilesets-from-eman-quest
- Deluxt CC0 forest alternative: https://deluxtdev.itch.io/fantasy-forest-tileset
- MurphysDad winter/grass: https://murphysdad.itch.io/rpg-asset-pack
- Kenney asset license guidance: https://kenney.nl/support
- Kenney tower-defense: https://kenney.nl/assets/tower-defense-top-down
- Kenney tiny dungeon: https://kenney.nl/assets/tiny-dungeon
- Kenney tiny battle: https://kenney.nl/assets/tiny-battle
- Kenney pixel UI: https://kenney.nl/assets/ui-pack-pixel-adventure
- Kenney impact SFX: https://kenney.nl/assets/impact-sounds
- Godot 4.6 TileMapLayer: https://docs.godotengine.org/en/4.6/classes/class_tilemaplayer.html
- Godot 4.6 TileSet guide: https://docs.godotengine.org/en/4.6/tutorials/2d/using_tilesets.html
- CC0 legal text: https://creativecommons.org/publicdomain/zero/1.0/

---

**Success definition for M4:** The game retains its familiar procedural tower-defense loop but adds enemy counterplay, meaningful upgrade specializations, two active tactical decisions and four distinctly readable, optional CC0 visual environments. The project remains maintainable, localized and viable for later desktop/web/Android publication, with no invented asset rights or untested implementation claims.
