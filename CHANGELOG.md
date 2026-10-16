# Changelog

## 0.7.0 - 2026-10-17

### Added

* **Unofficial French layer** (`data\Unofficial_*.lua`, loaded after the official data, never replaces an official entry): about
  8 800 item names, 3 700 NPC names, 2 300 quest titles, 880 class spell / talent names, 1 200 world object names,
  650 gossip options and 340 zone names that had no French source. Written by hand from the English text with the vocabulary of
  the official data (see README). Remove the `Unofficial_*` lines of the `.toc` to switch it off.
* **Reputation faction names** (`factions` option, `GetFactionInfo` / `GetWatchedFactionInfo`), French for the game's interface,
  English for other addons like every other hook. 52 names, also unofficial.

### Changed

* Version 0.7.0; the `.toc` lists the new data files.

## 0.6.0 - 2026-10-16

Audit release. Most of it fixes things that silently did not work.

### Fixed

* **Caller detection never worked.** `SFR.CallerIsAddon()` returned `0` for the game's own interface and every guard was written
  `not SFR.CallerIsAddon()`; in Lua `0` is true, so on a client that has `debugstack` the guard always said "addon" and the deep
  translations (`UnitName`, `GetSpellName`, talents, zones, `GetItemInfo`, professions) were never French, for anybody. It now
  returns `1` for an addon and `nil` otherwise. `Blizzard_*` load-on-demand frames still count as the game's interface.
* **Zone names were German.** The `locales_area` table of the server holds German text in its French column; the old `area`
  table (1 105 entries) was a copy of it, so with `zones` on (default) the game could have displayed "Ödland" for the Badlands.
  The table is rebuilt from French sources only (Babble-Zone and pfQuest, 862 names).
* **Quest dialogs raised a Lua error for 15 quests**: `questx` holds a plain string for title-only quests but `Quest()` called
  `table.getn` on it. Those titles are now translated (title only) and the English text is kept.
* **Spell descriptions: 131 of 348 models were dropped.** `data\Descriptions.lua` repeated 20 bucket keys, and a Lua table
  constructor keeps only the last duplicate, so the earlier models (including 77 of the generic bucket) never loaded. Buckets are
  merged; two models stored under an unreachable key were moved to the right one.
* **Books**: pages whose first 60 characters are identical lost all but the last variant (37 variants recovered, stored as a
  list of `{ length, text }`). The `Missing Text` key, which held six different French pages, was removed.
* **Item effect lines** ("Equip:", "Use:", "Chance on hit:") in bag/inventory/vendor tooltips now use the description models
  (they were only applied to action-bar and buff tooltips).
* **Random-suffix items** ("... of the Owl"): the data holds base names only, so the French name used to drop the suffix in
  tooltips, chat links and `GetItemInfo`. Such items keep their English name.
* **pfQuest / _LazyPig compatibility**: `GetQuestLogLeaderBoard`, `GetQuestLogTitle`, `GetQuestLogQuestText`, the quest dialog
  getters, `GetAvailableTitle`/`GetActiveTitle` and the gossip lists now return English to other addons (pfQuest parses
  "X slain: 1/5" with English patterns; _LazyPig compares gossip texts with English strings) and French to the game windows.
* **Compat cuts are no longer written to `SunreachFRDB`.** Versions 0.3-0.5 stored `deepitems = 0` (etc.) for good when ItemRack
  or SuperMacro was loaded, so uninstalling the addon never brought the option back. The cut is now applied in memory
  (`SFR.compatForced`, read by `SFR.On`). Old stale values (without a `/sfr` choice) are removed once.
* **`ChatFrame_OnEvent` hook** puts `arg1` back after the call, so other handlers of the same event do not receive the
  translated line (BigWigs-style yell triggers match English text).
* Swapped gossip entries: "Officers' Lounge" was "Maître d'armes" and "Battlemaster" was "Quartier des officiers" (swapped in the
  server data). The first now reads "Quartier des officiers", the second was removed.
* UTF-8 text mis-decoded as cp1252 ("Ã©") repaired in one NPC name and 135 places of the books.

### Performance

* The caller check (`debugstack` allocates a string) now runs only when a translation exists: players, untranslated NPCs,
  empty zone names and untranslated spells no longer pay for it.
* The `OnUpdate` script that waits for `PLAYER_ENTERING_WORLD` removes itself once the delayed hooks are installed.

### Added

* `SFR.AddData` and `SFR.AddTitles` (fill gaps, never replace) and three source-stamped data files:
  `Extra_DB.lua` (370 NPC chat lines), `Extra_pfQuest.lua` (1 577 item names, 239 NPC names, 4 objects, 25 quest titles,
  798 zone names), `Extra_Babble.lua` (241 spell names, 64 zone names).
* `/sfr test` also reports world objects, zones and taxi tables.
* This README and CHANGELOG.

### Not changed on purpose

* Existing translations are never overwritten. 210 spell names differ between the addon and the Babble libraries
  (listed by the maintainer in `DIVERGENCES_sorts.csv`); they were left as they are.
* 29 entries of the `taxi` table are really NPC / quest / item names (collected by an earlier version); they never apply and
  were left alone.

## 0.5.0 and earlier

See the project journal: compatibility layer (0.3), caller detection (0.4.0), descriptions from the server `Spell.dbc`
(0.4.2 - 0.5.0).
