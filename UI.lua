-- Interface strings. NON OFFICIEL : traductions faites sans fichiers du client français, à relire.
-- Only display lines are rewritten (tooltips, quest placeholders); combat-log / parsing globals are never touched.

SFR_UI = {}

SFR_UI.class = {
	["Warrior"] = "Guerrier", ["Paladin"] = "Paladin", ["Hunter"] = "Chasseur", ["Rogue"] = "Voleur",
	["Priest"] = "Prêtre", ["Shaman"] = "Chaman", ["Mage"] = "Mage", ["Warlock"] = "Démoniste", ["Druid"] = "Druide",
}
SFR_UI.race = {
	["Human"] = "Humain", ["Dwarf"] = "Nain", ["Night Elf"] = "Elfe de la nuit", ["Gnome"] = "Gnome",
	["Orc"] = "Orc", ["Undead"] = "Mort-vivant", ["Tauren"] = "Tauren", ["Troll"] = "Troll",
	["High Elf"] = "Haut-elfe", ["Goblin"] = "Gobelin",
}

-- whole-line translations (left or right column of a tooltip)
SFR_UI.exact = {
	["Binds when picked up"] = "Lié quand ramassé",
	["Binds when equipped"] = "Lié quand équipé",
	["Binds when used"] = "Lié quand utilisé",
	["Soulbound"] = "Lié",
	["Quest Item"] = "Objet de quête",
	["Unique"] = "Unique",
	["Unique-Equipped"] = "Unique - équipé",
	["Conjured Item"] = "Objet invoqué",
	["Two-Hand"] = "Deux mains", ["One-Hand"] = "Une main", ["Main Hand"] = "Main droite", ["Off Hand"] = "Main gauche",
	["Held In Off-hand"] = "Tenu en main gauche", ["Ranged"] = "À distance", ["Thrown"] = "Arme de jet",
	["Projectile"] = "Projectile", ["Ammo"] = "Munitions",
	["Head"] = "Tête", ["Neck"] = "Cou", ["Shoulder"] = "Épaules", ["Back"] = "Dos", ["Chest"] = "Torse",
	["Shirt"] = "Chemise", ["Tabard"] = "Tabard", ["Wrist"] = "Poignets", ["Hands"] = "Mains", ["Waist"] = "Taille",
	["Legs"] = "Jambes", ["Feet"] = "Pieds", ["Finger"] = "Doigt", ["Trinket"] = "Bijou", ["Relic"] = "Relique",
	["Cloth"] = "Tissu", ["Leather"] = "Cuir", ["Mail"] = "Mailles", ["Plate"] = "Plaques", ["Shield"] = "Bouclier",
	["Axe"] = "Hache", ["Bow"] = "Arc", ["Crossbow"] = "Arbalète", ["Dagger"] = "Dague", ["Gun"] = "Arme à feu",
	["Mace"] = "Masse", ["Polearm"] = "Arme d'hast", ["Staff"] = "Bâton", ["Sword"] = "Épée", ["Wand"] = "Baguette",
	["Fist Weapon"] = "Arme de pugilat", ["Fishing Pole"] = "Canne à pêche", ["Miscellaneous"] = "Divers",
	["Idol"] = "Idole", ["Libram"] = "Libram", ["Totem"] = "Totem", ["Bag"] = "Sac", ["Quiver"] = "Carquois",
	["Ammo Pouch"] = "Giberne", ["Soul Bag"] = "Sac d'âmes",
	-- lignes de tooltips de sorts (temps d'incantation, exigences d'arme)
	["Next melee"] = "Attaque suivante", ["Instant cast"] = "Incantation immédiate",
	["Requires Melee Weapon"] = "Nécessite une arme de mêlée",
	["Requires a Melee Weapon"] = "Nécessite une arme de mêlée",
	["Requires Ranged Weapon"] = "Nécessite une arme à distance",
	["Requires a Ranged Weapon"] = "Nécessite une arme à distance",
	["Requires a Thrown Weapon"] = "Nécessite une arme de jet",
	["Melee Weapon"] = "Arme de mêlée", ["Ranged Weapon"] = "Arme à distance",
	["Melee Range"] = "Portée de mêlée", ["5 yd range"] = "Portée 5 m",
	["8 yd range"] = "Portée 8 m", ["30 yd range"] = "Portée 30 m",
	-- creature ranks / types (unit tooltips)
	["(Elite)"] = "(Élite)", ["(Rare)"] = "(Rare)", ["(Rare Elite)"] = "(Élite rare)", ["(Boss)"] = "(Boss)",
	["Beast"] = "Bête", ["Humanoid"] = "Humanoïde", ["Demon"] = "Démon", ["Elemental"] = "Élémentaire",
	["Dragonkin"] = "Draconien", ["Giant"] = "Géant", ["Mechanical"] = "Mécanique", ["Critter"] = "Bestiole",
	["Not specified"] = "Non spécifié", ["Aberration"] = "Aberration", ["Undead"] = "Mort-vivant",
}

local function ClassList(s)
	-- "Warrior, Rogue" -> "Guerrier, Voleur"
	return (gsub(s, "([^,]+)", function(w)
		local _, _, lead, name, trail = strfind(w, "^(%s*)(.-)(%s*)$")
		return lead .. (SFR_UI.class[name] or SFR_UI.race[name] or name) .. trail
	end))
end

-- patterns: { lua pattern, replacement string OR function(captures...) }
SFR_UI.patterns = {
	{ "^Requires Level (%d+)$", "Niveau %1 requis" },
	{ "^Requires level (%d+)$", "Niveau %1 requis" },
	{ "^Item Level (%d+)$", "Niveau d'objet %1" },
	{ "^Durability (%d+) / (%d+)$", "Durabilité %1 / %2" },
	{ "^(%d+) Armor$", "%1 Armure" },
	{ "^(%d+) Block$", "%1 Blocage" },
	{ "^(%d+) %- (%d+) Damage$", "%1 - %2 Dégâts" },
	{ "^(%d+) %- (%d+) (%a+) Damage$", "%1 - %2 Dégâts (%3)" },
	{ "^%(([%d%.]+) damage per second%)$", "(%1 dégâts par seconde)" },
	{ "^Speed ([%d%.]+)$", "Vitesse %1" },
	{ "^%+(%d+) Strength$", "+%1 Force" },
	{ "^%+(%d+) Agility$", "+%1 Agilité" },
	{ "^%+(%d+) Stamina$", "+%1 Endurance" },
	{ "^%+(%d+) Intellect$", "+%1 Intelligence" },
	{ "^%+(%d+) Spirit$", "+%1 Esprit" },
	{ "^%+(%d+) Fire Resistance$", "+%1 Résistance au Feu" },
	{ "^%+(%d+) Nature Resistance$", "+%1 Résistance à la Nature" },
	{ "^%+(%d+) Frost Resistance$", "+%1 Résistance au Givre" },
	{ "^%+(%d+) Shadow Resistance$", "+%1 Résistance à l'Ombre" },
	{ "^%+(%d+) Arcane Resistance$", "+%1 Résistance aux Arcanes" },
	{ "^%+(%d+) Holy Resistance$", "+%1 Résistance au Sacré" },
	{ "^Equip: (.+)$", "Équipé : %1" },
	{ "^Use: (.+)$", "Utilisation : %1" },
	{ "^Chance on hit: (.+)$", "Chances quand vous touchez : %1" },
	{ "^Classes: (.+)$", function(l) return "Classes : " .. ClassList(l) end },
	{ "^Races: (.+)$", function(l) return "Races : " .. ClassList(l) end },
	{ "^Requires (.+) %((%d+)%)$", "Nécessite %1 (%2)" },
	{ "^Requires (.+)$", "Nécessite %1" },
	{ "^Sell Price: (.+)$", "Prix de vente : %1" },
	{ "^(%d+) Slot Bag$", "Sac de %1 emplacements" },
	{ "^Level (%d+) (.+)$", function(lv, ty) return "Niveau " .. lv .. " " .. (SFR_UI.exact[ty] or ty) end },
	{ "^Level (%d+)$", "Niveau %1" },
	{ "^Level %?%?$", "Niveau ??" },
	{ "^Level %?%? (.+)$", function(ty) return "Niveau ?? " .. (SFR_UI.exact[ty] or ty) end },
}

-- returns the translated text, or the same text when nothing applies
function SFR.UILine(text)
	if not text or text == "" then return text end
	local ex = SFR_UI.exact[text]
	if ex then return ex end
	local pats = SFR_UI.patterns
	for i = 1, table.getn(pats) do
		local p = pats[i]
		local s, n = gsub(text, p[1], p[2])
		if n and n > 0 then return s end
	end
	return text
end

-- spell / talent tooltip lines (UNOFFICIAL)
SFR_UI.tree = {
	["Holy"] = "Sacré", ["Protection"] = "Protection", ["Retribution"] = "Vindicte", ["Arcane"] = "Arcanes", ["Fire"] = "Feu",
	["Frost"] = "Givre", ["Arms"] = "Armes", ["Fury"] = "Fureur", ["Discipline"] = "Discipline", ["Shadow"] = "Ombre",
	["Assassination"] = "Assassinat", ["Combat"] = "Combat", ["Subtlety"] = "Finesse", ["Elemental"] = "Élémentaire",
	["Enhancement"] = "Amélioration", ["Restoration"] = "Restauration", ["Balance"] = "Équilibre",
	["Feral Combat"] = "Combat farouche", ["Affliction"] = "Affliction", ["Demonology"] = "Démonologie",
	["Destruction"] = "Destruction", ["Beast Mastery"] = "Maîtrise des bêtes", ["Marksmanship"] = "Précision", ["Survival"] = "Survie",
}
SFR_UI.spellPatterns = {
	{ "^Rank (%d+)/(%d+)$", "Rang %1/%2" },
	{ "^Rank (%d+)$", "Rang %1" },
	{ "^Requires (%d+) points in (.+) Talents$", function(n, tr) return "Nécessite " .. n .. " points dans les talents " .. (SFR_UI.tree[tr] or tr) end },
	{ "^Requires Level (%d+)$", "Niveau %1 requis" },
	{ "^Instant cast$", "Incantation immédiate" },
	{ "^Instant$", "Instantané" },
	{ "^([%d%.]+) sec cast$", "%1 sec d'incantation" },
	{ "^(%d+) Mana$", "%1 mana" },
	{ "^(%d+) Rage$", "%1 rage" },
	{ "^(%d+) Energy$", "%1 énergie" },
	{ "^([%d%.]+) yd range$", "Portée : %1 m" },
	{ "^Melee Range$", "Mêlée" },
	{ "^Passive$", "Passif" },
	{ "^Requires (.+)$", "Nécessite %1" },
	{ "^Cooldown remaining: (.+)$", "Temps de recharge restant : %1" },
	{ "^([%d%.]+) sec cooldown$", "%1 sec de recharge" },
	{ "^([%d%.]+) min cooldown$", "%1 min de recharge" },
}
function SFR.SpellLine(text)
	if not text or text == "" then return text end
	local pats = SFR_UI.spellPatterns
	for i = 1, table.getn(pats) do
		local p = pats[i]
		local s, n = gsub(text, p[1], p[2])
		if n and n > 0 then return s end
	end
	return text
end