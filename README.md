# SunreachFR

French translation layer for the **Sunreach** private server (WoW 1.12 / Turtle-like 1.18.1 client, `Interface: 11200`).
It does not touch the client files: it rewrites the texts the game shows (tooltips, names, quests, books, NPC chat...) while the
original English strings stay available to every other addon.

Version 0.6.0 - author "Sunreach". Saved variable: `SunreachFRDB`.

## What is translated, and where the French comes from

| Area | Entries | Source |
|---|---|---|
| Item names, descriptions (tooltips, chat links, `GetItemInfo`) | 15 906 items | 14 329 Sunreach database (`locales_item`) + 1 577 pfQuest |
| NPC names / titles, world objects | 7 152 NPC, 639 titles, 2 364 objects | Sunreach database (`locales_creature`, `locales_gameobject`: 6 913 + 639 + 2 360) + 243 pfQuest |
| Quests (title, text, objectives, progress, reward, log, tracker) | 3 176 titles | 3 151 Sunreach database (`locales_quest`; 376 titles are shared by several quests, 1 095 records) + 25 titles from pfQuest |
| Books and letters | 1 099 pages | Sunreach database (`locales_page_text`) |
| NPC chat lines | 8 736 | 8 366 + 370 Sunreach database (`locales_broadcast_text`, `script_texts`) |
| Gossip options, flight masters | 111 + 88 | Sunreach database |
| Zone and sub-zone names | 862 | 64 Babble-Zone (BigWigs) + 798 pfQuest |
| Spell / talent names | 1 253 | 1 012 **unofficial** (written for this project) + 241 from Babble-Spell (BigWigs) |
| Spell / item-effect descriptions | 348 patterns (warrior, mage, priest, druid, part of paladin) | **Unofficial** (written for this project from the server's `Spell.dbc` wordings) |
| Tooltip lines ("Binds when picked up", "Requires Level"...), classes, races | about 150 lines | **Unofficial** (`UI.lua`) |

Be aware of the limits: the server database has **no French spell data at all**, and the Turtle-specific content (custom items,
quests, NPCs, zones, ids 40000+) has no French source anywhere. Those texts stay in English.
"Unofficial" means the French was written by hand and has not been checked against a French client.
Everything else comes from the files listed above, nothing is machine-translated at run time.

Generated lists of what is still untranslated are kept outside the repository by the maintainer (items, NPCs, quests, spells...).

## Installation

Copy the `SunreachFR` folder into `Interface\AddOns\`. The addon is about 7.6 MB of Lua (loaded once at login, all data
files are listed in the `.toc`). The files are UTF-8, which is what the 1.12 client expects (the same encoding as every other
localised addon). Nothing to configure.

## Commands

`/sfr` (or `/sunreachfr`)

| Command | Effect |
|---|---|
| `/sfr` | list options and their state |
| `/sfr <option> on\|off` | switch an option (your choice is remembered and always wins over the automatic compatibility rules) |
| `/sfr safe` | turn off everything that changes names globally (`deepnames`, `deepitems`, `deepspells`, `zones`); tooltips stay French |
| `/sfr compat` | which installed addons triggered an automatic restriction, and why |
| `/sfr test` | self test: hooks, data tables, counters |
| `/sfr stats` | what was translated this session |
| `/sfr clearmiss` | empty the list of untranslated texts noted in `SunreachFRDB.miss` |

Options: `items units quests gossip books chatlinks chatnpc tooltipui spells professions collect deepnames deepitems deepspells zones`.
`collect` (on by default) writes the English texts it could not translate into `SunreachFRDB.miss`; switch it off if you do not need that.

## Compatibility with other addons

The game's own interface shows French, **other addons receive the original English**. This is done by looking at who calls
the API (`debugstack`): a call coming from a file under `Interface\AddOns\` (except `Blizzard_*`) gets English from
`UnitName`, `GetSpellName`, `GetTalentInfo`, `GetItemInfo`, the zone functions, `GetTradeSkill*`/`GetCraft*`, `TaxiNodeName`,
and from the quest and gossip functions (`GetQuestLogTitle`, `GetQuestLogLeaderBoard`, `GetGossipOptions`...). So pfUI, pfQuest,
AtlasLoot, BigWigs, DPSMate, TankSuite, ShikatoRotation, `_LazyPig`... keep comparing English strings.

Known limits of that approach:

* code run from a macro (`/script ...`, SuperMacro) looks like game code and receives French; for SuperMacro and ItemRack the
  addon therefore still turns off `deepnames`/`deepspells` (SuperMacro) and `deepitems` (ItemRack) while they are loaded
  (in memory only; `/sfr compat`);
* a function that returns another function's result with `return f(...)` (a tail call) hides its own stack frame, so the
  detection may look one level further up;
* tooltips are translated for everyone (they are only text), so an addon that scans `GameTooltip` lines for English patterns
  will see French; addons that use their own scanning tooltip are unaffected;
* French macros work (`CastSpellByName`, `TargetByName` convert French names back to English).

A small public API exists for addons that *want* French: `SFR.FR(category, english)`, `SFR.EN(category, french)`,
`SFR.UnitNameFR(unit)` (categories are the keys of `SFR_D`: `npc`, `spell`, `itemn`, `area`...).

## Data layout

`data\*.lua` are plain tables (`SFR_D.items[id]`, `SFR_D.npc[englishName]`, ...). The `Extra_*.lua` files add entries from
secondary sources through `SFR.AddData`, which never replaces an existing entry; each file starts with its source and entry count:

* `Extra_DB.lua` - NPC chat lines from the Sunreach database;
* `Extra_pfQuest.lua` - names from `pfQuest\db\frFR` (accepted only when pfQuest's English name equals the server's name for the same id);
* `Extra_Babble.lua` - spell and zone names from the Babble libraries shipped with BigWigs.

The code is Lua 5.0 (no `#`, `string.match`, `select`, varargs expressions); every hook runs under `pcall`, so a translation
problem never breaks the interface.

## License / credits

Texts of the game belong to their owners. French strings come from the sources above. No license has been chosen yet.
