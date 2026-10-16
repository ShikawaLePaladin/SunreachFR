-- SunreachFR core (WoW 1.12 / Lua 5.0). No '#', no string.match, no select(), no '...' as an expression,
-- and no closure over a 'for' loop variable (Lua 5.0 resets it after the loop). test/run.js lints the first rules.
-- Translation data: server tables (locales_*) for names/quests/books/chat; UNOFFICIAL text written for this project
-- for spells, talents and interface lines. Every hook runs under pcall: a translation problem never breaks the UI.

SFR = SFR or {}
SFR.version = "0.7.0"
SFR.stats = {}
SFR_D = SFR_D or {}

-- 1 = on by default
SFR.DEFAULTS = {
	items = 1, units = 1, quests = 1, gossip = 1, books = 1, chatlinks = 1, chatnpc = 1, tooltipui = 1, spells = 1,
	professions = 1, collect = 1,
	deepnames = 1, deepitems = 1, deepspells = 1, -- names everywhere (unit frames, AtlasLoot lists, spellbook); /sfr safe turns them off
	factions = 1, -- noms des factions de reputation (liste NON OFFICIELLE)
	zones = 1, -- FR par defaut : la normalisation est geree dans AutoMarkerOW/Shikato/RaidTools (v0.3.1)
}
SFR.DESC = {
	items = "noms/descriptions d'objets dans les infobulles",
	units = "noms et titres des PNJ et objets du monde (infobulles)",
	quests = "textes de quetes, journal, suivi",
	gossip = "options de dialogue et titres de quetes chez les PNJ",
	books = "livres et lettres",
	chatlinks = "noms d'objets dans les liens du chat",
	chatnpc = "repliques des PNJ dans le chat",
	tooltipui = "lignes d'infobulle (Niveau requis, Durabilite, ...) - NON OFFICIEL",
	spells = "noms et descriptions de sorts/talents dans les infobulles - NON OFFICIEL",
	professions = "noms des recettes et composants dans les fenetres de metier",
	collect = "note dans SunreachFRDB les textes sans traduction (pour les traduire ensuite)",
	deepnames = "noms de PNJ partout (cadres d'unite...) - peut gener des addons",
	deepitems = "GetItemInfo en francais (AtlasLoot, listes...) - peut gener des addons d'inventaire",
	deepspells = "noms de sorts dans grimoire/talents/barres - peut gener des addons de rotation",
	zones = "noms de zones (peut gener les addons qui comparent les noms de zones)",
	factions = "noms des factions dans le panneau de reputation - NON OFFICIEL",
}

function SFR.Print(msg)
	if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffSunreach FR|r: " .. msg) end
end

function SFR.On(key)
	-- cut applied at runtime for a third-party addon (Compat.lua); never written to SunreachFRDB, never set over a /sfr choice
	local cf = SFR.compatForced
	if cf and cf[key] then return false end
	local db = SunreachFRDB
	if db then
		local v = db[key]
		if v ~= nil then return v == 1 end
	end
	return SFR.DEFAULTS[key] == 1
end

function SFR.Count(key)
	SFR.stats[key] = (SFR.stats[key] or 0) + 1
end

-- All data files are listed in the TOC and loaded at startup (a 1.12 addon cannot load its own files later).
function SFR.Need(mod, key)
	return SFR_D[key] ~= nil
end

-- Fill gaps in SFR_D[key] with the entries of t: an entry that already exists is NEVER replaced. Used by data/Extra_*.lua.
function SFR.AddData(key, t)
	local d = SFR_D[key]
	if not d then SFR_D[key] = t return end
	for k, v in pairs(t) do
		if d[k] == nil then d[k] = v end
	end
end

-- Quest titles without any text (no record in quest/questx yet): { t = French title, k = "" }
function SFR.AddTitles(t)
	local q = SFR_D.quest
	if not q then q = {} SFR_D.quest = q end
	local qx = SFR_D.questx
	for en, fr in pairs(t) do
		if q[en] == nil and not (qx and qx[en] ~= nil) then q[en] = { t = fr, k = "" } end
	end
end

-- Lua 5.0: extra arguments arrive in the implicit 'arg' table (with arg.n); '...' itself is NOT an expression in 5.0.
-- (The test harness replaces this function, because it runs on a newer Lua.)
function SFR.Pack(...)
	return arg
end

function SFR.Try(f, a1, a2, a3, a4, a5)
	local ok, err = pcall(f, a1, a2, a3, a4, a5)
	if not ok then
		SFR.Count("errors")
		SFR.lastError = err
	end
	return ok
end

-- untranslated strings seen in play, saved in SunreachFRDB.miss so they can be translated later
local MISS_LIMIT = 4000
function SFR.Miss(cat, en)
	if not en or en == "" or not SunreachFRDB or not SFR.On("collect") then return end
	local m = SunreachFRDB.miss
	if not m then m = {} SunreachFRDB.miss = m end
	local c = m[cat]
	if not c then c = { n = 0 } m[cat] = c end
	if c[en] == nil and c.n < MISS_LIMIT then
		c[en] = 1
		c.n = c.n + 1
	end
end

SFR.hooks = { ok = 0, fail = 0, failed = {} }
local function HookResult(ok, what)
	if ok then SFR.hooks.ok = SFR.hooks.ok + 1
	else SFR.hooks.fail = SFR.hooks.fail + 1 tinsert(SFR.hooks.failed, what) end
end

-- Replace obj[method] by fn(orig, self, a1..a5) -> returns; missing methods are ignored.
function SFR.Hook(obj, method, fn)
	if not obj or not obj[method] then HookResult(nil, "methode " .. tostring(method)) return false end
	local orig = obj[method]
	obj[method] = function(self, a1, a2, a3, a4, a5)
		return fn(orig, self, a1, a2, a3, a4, a5)
	end
	HookResult(1)
	return true
end

-- Replace a global function; returns the original so the wrapper can call it.
function SFR.HookGlobal(name, fn)
	local orig = getglobal(name)
	if not orig then HookResult(nil, "global " .. tostring(name)) return nil end
	HookResult(1)
	setglobal(name, function(a1, a2, a3, a4, a5, a6, a7, a8, a9)
		return fn(orig, a1, a2, a3, a4, a5, a6, a7, a8, a9)
	end)
	return orig
end

-- Détection d'appelant (v0.4.0) : l'interface du jeu reçoit le français,
-- les AUTRES addons reçoivent l'anglais - sans rien modifier chez eux.
-- debugstack existe dans le client 1.12 (utilisé par BugSack/Swatter).
-- On remonte la pile en ignorant nos propres frames (SunreachFR) : la
-- première ligne restante dit si l'appelant vit sous Interface\AddOns\
-- (1 = addon -> rendre l'anglais) ou dans l'UI Blizzard (nil -> français).
-- Sans debugstack : nil -> français (comportement historique).
-- v0.6.0 : valeurs de retour = 1 (addon) ou nil. Jusqu'à la v0.5.0 l'UI Blizzard renvoyait 0, or 0 est VRAI en Lua
-- ('not 0' vaut false) : toutes les gardes 'not SFR.CallerIsAddon()' refusaient donc le français à tout le monde.
local HAS_DEBUGSTACK = (debugstack ~= nil)
local ADDON_DIR = "AddOns\\"
function SFR.CallerIsAddon()
	if not HAS_DEBUGSTACK then return nil end
	local ok, st = pcall(debugstack, 2, 5, 0)
	if not ok or not st then return nil end
	-- NB : gfind n'est PAS un global en 1.12 (strfind/gsub le sont) ->
	-- string.gfind obligatoire (bug "attempt to call global 'gfind'").
	for line in string.gfind(st, "[^\n]+") do
		if not strfind(line, "SunreachFR", 1, true) then
			if strfind(line, ADDON_DIR, 1, true) then
				-- les addons Blizzard_* (TalentUI, TradeSkillUI...) vivent
				-- sous AddOns\ mais sont l'UI DU JEU -> français
				if strfind(line, "AddOns\\Blizzard_", 1, true) then return nil end
				return 1
			end
			return nil
		end
	end
	return nil
end

-- Code that must wrap what OTHER addons installed (pfUI replaces tooltip scripts after us: addons load in ASCII
-- order, so 'SunreachFR' loads before 'pfUI'). Runs a few seconds after PLAYER_ENTERING_WORLD.
local readyList = {}
SFR.readyDone = nil
function SFR.OnReady(fn)
	if SFR.readyDone then SFR.Try(fn) else tinsert(readyList, fn) end
end
function SFR.RunReady()
	SFR.readyDone = 1
	for i = 1, table.getn(readyList) do SFR.Try(readyList[i]) end
	readyList = {}
end

-- FR -> EN reverse dictionaries, so macros and addons that hand a French name back to the game still work
local rev = {}
function SFR.Reverse(key)
	local r = rev[key]
	if r then return r end
	r = {}
	local d = SFR_D[key]
	if d then
		for en, fr in pairs(d) do
			if type(fr) == "string" and r[fr] == nil then r[fr] = en end
		end
	end
	rev[key] = r
	return r
end

-- /sfr test
local MODULES = { { "items", "items" }, { "npc", "npc" }, { "go", "go" }, { "quests", "quest" }, { "books", "page" }, { "chat", "chat" }, { "spells", "spell" }, { "descriptions", "sdesc" }, { "zones", "area" }, { "taxi", "taxi" } }
local function CountTable(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end
function SFR.SelfTest()
	SFR.Print("test v" .. SFR.version .. " - hooks installes: " .. SFR.hooks.ok .. ", echecs: " .. SFR.hooks.fail)
	for i = 1, table.getn(SFR.hooks.failed) do SFR.Print("  hook manquant: " .. SFR.hooks.failed[i]) end
	local opts = ""
	for k, _ in pairs(SFR.DEFAULTS) do opts = opts .. k .. "=" .. (SFR.On(k) and "1" or "0") .. " " end
	SFR.Print("options: " .. opts)
	for i = 1, table.getn(MODULES) do
		local name, key = MODULES[i][1], MODULES[i][2]
		if SFR_D[key] then SFR.Print("  " .. name .. ": OK (" .. CountTable(SFR_D[key]) .. " entrees)")
		else SFR.Print("  " .. name .. ": DONNEES ABSENTES") end
	end
	if SFR_D.items then SFR.Print("  exemple objet 2589 -> " .. tostring(SFR.ItemName(2589))) end
	SFR.Print("  compteurs: " .. (SFR.stats.tooltips or 0) .. " infobulles, " .. (SFR.stats.units or 0) .. " PNJ, " .. (SFR.stats.quests or 0) .. " quetes, " .. (SFR.stats.spells or 0) .. " sorts, erreurs " .. (SFR.stats.errors or 0))
	local m = SunreachFRDB and SunreachFRDB.miss
	if m then
		local s = ""
		for cat, c in pairs(m) do s = s .. cat .. "=" .. c.n .. " " end
		SFR.Print("  textes sans traduction notes: " .. s)
	end
	if SFR.lastError then SFR.Print("  derniere erreur: " .. tostring(SFR.lastError)) end
end

-- /sfr
SLASH_SUNREACHFR1 = "/sfr"
SLASH_SUNREACHFR2 = "/sunreachfr"
SlashCmdList["SUNREACHFR"] = function(msg)
	msg = msg or ""
	local _, _, cmd, arg2 = strfind(msg, "^(%S*)%s*(%S*)$")
	cmd = strlower(cmd or "")
	arg2 = strlower(arg2 or "")
	if cmd == "test" then
		SFR.SelfTest()
		return
	end
	if cmd == "stats" then
		local any = nil
		for k, v in pairs(SFR.stats) do SFR.Print(k .. " = " .. v) any = 1 end
		if not any then SFR.Print("rien de traduit pour l'instant") end
		if SFR.lastError then SFR.Print("derniere erreur: " .. tostring(SFR.lastError)) end
		return
	end
	if cmd == "safe" then
		SunreachFRDB = SunreachFRDB or {}
		SunreachFRDB.deepnames = 0 SunreachFRDB.deepitems = 0 SunreachFRDB.deepspells = 0 SunreachFRDB.zones = 0
		SunreachFRDB.userset = SunreachFRDB.userset or {}
		SunreachFRDB.userset.deepnames = 1 SunreachFRDB.userset.deepitems = 1
		SunreachFRDB.userset.deepspells = 1 SunreachFRDB.userset.zones = 1
		SFR.Print("mode sur : plus aucun nom global n'est modifie (infobulles seulement). /reload pour appliquer.")
		return
	end
	if cmd == "clearmiss" then
		if SunreachFRDB then SunreachFRDB.miss = nil end
		SFR.Print("liste des textes sans traduction videe")
		return
	end
	if cmd == "compat" then
		if SFR.CompatPrint then SFR.CompatPrint() end
		return
	end
	if SFR.DEFAULTS[cmd] ~= nil and (arg2 == "on" or arg2 == "off") then
		SunreachFRDB = SunreachFRDB or {}
		SunreachFRDB[cmd] = (arg2 == "on") and 1 or 0
		-- choix explicite : mémorisé, la compatibilité ne le touchera plus
		SunreachFRDB.userset = SunreachFRDB.userset or {}
		SunreachFRDB.userset[cmd] = 1
		local extra = ""
		if SFR.compatForced and SFR.compatForced[cmd] then
			extra = " (choix perso prioritaire sur la compatibilite)"
			SFR.compatForced[cmd] = nil
		end
		SFR.Print(cmd .. " = " .. arg2 .. extra .. " (/reload recommande)")
		return
	end
	SFR.Print("v" .. SFR.version .. " - /sfr <option> on|off, /sfr safe, /sfr compat, /sfr test, /sfr stats, /sfr clearmiss")
	for k, _ in pairs(SFR.DEFAULTS) do
		SFR.Print("  " .. k .. " : " .. (SFR.On(k) and "on" or "off") .. " - " .. (SFR.DESC[k] or ""))
	end
end

local f = CreateFrame("Frame", "SunreachFRFrame")
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
local waited = nil
f:SetScript("OnEvent", function()
	if event == "VARIABLES_LOADED" then
		SunreachFRDB = SunreachFRDB or {}
	elseif event == "PLAYER_LOGIN" then
		SFR.Print("v" .. SFR.version .. " charge - /sfr pour les options")
	elseif event == "PLAYER_ENTERING_WORLD" then
		waited = 0
	end
end)
f:SetScript("OnUpdate", function()
	if waited and not SFR.readyDone then
		waited = waited + arg1
		if waited >= 3 then SFR.RunReady() f:SetScript("OnUpdate", nil) end
	end
end)
