-- Compatibilité addons (WoW 1.12 / Lua 5.0). v0.6.0
-- OBJECTIF : TOUT le jeu en français ET les addons anglais continuent de marcher.
--
-- Deux mécanismes :
--  1. NOS addons patchés (liste PATCHED ci-dessous) reçoivent des noms FR des
--     API globales mais les normalisent EN->FR via SFR.EN() avant de comparer :
--     rien à couper, ils marquent/marquent/tournent normalement.
--  2. Les addons TIERS non patchables qui comparent des noms anglais se voient
--     couper SEULEMENT les options qui les cassent - sauf choix explicite /sfr
--     (mémorisé dans SunreachFRDB.userset, prioritaire pour toujours).
--     v0.6.0 : la coupure est faite EN MÉMOIRE (SFR.compatForced, lue par SFR.On) et n'est plus
--     écrite dans SunreachFRDB : désinstaller l'addon rétablit l'option au login suivant.

-- Addons protégés par la DÉTECTION D'APPELANT (v0.4.0) : ils reçoivent
-- l'anglais des API (UnitName, GetSpellName, GetItemInfo, zones) pendant
-- que l'interface du jeu affiche le français. Rien à couper, rien à
-- modifier chez eux. (Fallback sans debugstack : SFR.COMPAT ci-dessous.)
SFR.COMPAT_PATCHED = {
	{ addon = "AutoMarkerOW", why = "reçoit les noms/zone EN, l'écran reste FR" },
	{ addon = "ShikatoRotation", why = "reçoit les noms de sorts EN" },
	{ addon = "rt", why = "reçoit les zones EN (RaidTools)" },
	{ addon = "pfUI", why = "affichage FR, comparaisons EN" },
	{ addon = "AtlasLoot", why = "listes FR, comparaisons EN" },
}

-- Addons tiers -> options à couper quand ils sont chargés (et pourquoi).
SFR.COMPAT = {
	{
		addon = "ItemRack",
		off = { "deepitems" },
		why = "identifie les équipements par nom d'objet",
	},
	{
		addon = "SuperMacro",
		off = { "deepspells", "deepnames" },
		why = "les macros comparent des noms EN de sorts et de cibles",
	},
}

-- addons charge's : remplis au PLAYER_LOGIN (tous les .toc sont alors lus)
SFR.loaded = {}
SFR.compatForced = {}   -- [option] = nom de l'addon qui l'a fait couper
SFR.compatReport = nil  -- pret quand RunCompat a tourné

local function AddonLoaded(name)
	local ok, v = pcall(IsAddOnLoaded, name)
	if ok and v then return 1 end
	return nil
end

-- L'API publique pour les AUTRES addons qui veulent volontairement du
-- français (ou de l'anglais) : zéro risque, ce sont de simples lectures.
--   SFR.FR("npc", "Lucifron")  -> nom FR ou nil
--   SFR.EN("npc", "Lucifron ") -> nom EN ou nil (dictionnaire inverse)
--   SFR.FR("spell", "Slam") / SFR.FR("itemn", "Linens") ... clés de SFR_D
function SFR.FR(cat, en)
	if cat and en and SFR_D and SFR_D[cat] then
		return SFR_D[cat][en]
	end
	return nil
end

function SFR.EN(cat, fr)
	if cat and fr and SFR_D and SFR_D[cat] then
		return SFR.Reverse(cat)[fr]
	end
	return nil
end

-- Nom FR d'affichage pour une unité (sans toucher UnitName) : pour les
-- addons qui veulent afficher du français tout en comparant de l'anglais.
function SFR.UnitNameFR(unit)
	if unit and UnitExists(unit) and not UnitIsPlayer(unit) then
		return SFR.FR("npc", SFR.RealUnitName and SFR.RealUnitName(unit) or UnitName(unit))
	end
	return nil
end

function SFR.RunCompat()
	if SFR.compatReport then return end
	SFR.compatReport = {}
	local db = SunreachFRDB or {}
	local userset = db.userset
	local n = 0
	-- v0.3.0-v0.5.0 wrote the cut (db[key] = 0) into SunreachFRDB for good, without 'userset': restore those values once
	-- (a value set with /sfr always has userset[key] and is never touched)
	if SunreachFRDB and not db.compatMigrated then
		local restored = ""
		local keys = { "deepnames", "deepitems", "deepspells", "zones" }
		for k = 1, table.getn(keys) do
			local key = keys[k]
			if db[key] == 0 and not (userset and userset[key]) then
				db[key] = nil
				restored = restored .. key .. " "
			end
		end
		db.compatMigrated = 1
		if restored ~= "" then
			SFR.Print("anciennes coupures de compatibilite retirees de la sauvegarde : " .. restored .. "(reappliquees a chaque connexion si un addon sensible est present)")
		end
	end
	-- nos addons protégés : information seulement
	for i = 1, table.getn(SFR.COMPAT_PATCHED) do
		local c = SFR.COMPAT_PATCHED[i]
		if AddonLoaded(c.addon) then
			SFR.loaded[c.addon] = 1
			table.insert(SFR.compatReport, c.addon .. " : protege par detection d'appelant (" .. c.why .. ")")
		end
	end
	-- addons tiers : coupure ciblée
	for i = 1, table.getn(SFR.COMPAT) do
		local c = SFR.COMPAT[i]
		if AddonLoaded(c.addon) then
			SFR.loaded[c.addon] = 1
			local forcedHere = {}
			for j = 1, table.getn(c.off) do
				local key = c.off[j]
				-- jamais toucher un réglage explicite de l'utilisateur
				if not (userset and userset[key]) then
					SFR.compatForced[key] = c.addon
					forcedHere[key] = 1
					n = n + 1
				end
			end
			local line = c.addon .. " present"
			local first = 1
			for key, _ in pairs(forcedHere) do
				if first then line = line .. " -> coupe " first = nil else line = line .. ", " end
				line = line .. key
			end
			if first == nil then line = line .. " (" .. c.why .. ")" end
			table.insert(SFR.compatReport, line)
		end
	end
	if n > 0 then
		SFR.Print("compatibilite : " .. n .. " option(s) limite(s) pour des addons tiers (voir /sfr compat).")
	end
end

function SFR.CompatPrint()
	if not SFR.compatReport then
		SFR.Print("compatibilite pas encore evaluee (relog ou /reload).")
		return
	end
	if table.getn(SFR.compatReport) == 0 then
		SFR.Print("aucun addon sensible detecte : toutes les options restent librement traduites.")
		return
	end
	for i = 1, table.getn(SFR.compatReport) do
		SFR.Print("  " .. SFR.compatReport[i])
	end
	local forcedAny = nil
	for key, addon in pairs(SFR.compatForced) do
		SFR.Print("  " .. key .. " coupe a cause de " .. addon .. " - /sfr " .. key .. " on pour forcer malgre tout.")
		forcedAny = 1
	end
	if not forcedAny then
		SFR.Print("  (rien de coupe : tes reglages personnels ont priorite)")
	end
end

-- au PLAYER_LOGIN tous les addons sont charges : c'est le bon moment
local cf = CreateFrame("Frame", "SunreachFRCompatFrame")
cf:RegisterEvent("PLAYER_LOGIN")
cf:SetScript("OnEvent", function()
	SFR.Try(SFR.RunCompat)
end)
