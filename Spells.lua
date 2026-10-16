-- Spell / talent names AND descriptions in tooltips (UNOFFICIAL text written for this project: no French spell data
-- exists in the server or the client). Descriptions are matched against templates in which every number/$token is a
-- hole: SFR_D.sdesc[key] = { { p = { literal0, literal1, ... }, f = "French text with {1} {2} ..." }, ... }.
-- "deepspells" also translates spellbook / talent frame / action bar names.

local function MatchEntry(entry, text)
	local p = entry.p
	local n = table.getn(p)
	local first = p[1]
	local fl = strlen(first)
	if strsub(text, 1, fl) ~= first then return nil end
	if n == 1 then
		if text ~= first then return nil end
		return entry.f
	end
	local pos = fl + 1
	local caps = {}
	for i = 2, n do
		local lit = p[i]
		local s = nil
		if i == n then
			local ll = strlen(lit)
			s = strlen(text) - ll + 1
			if s < pos then return nil end
			if ll > 0 and strsub(text, s) ~= lit then return nil end
		else
			s = strfind(text, lit, pos, true)
			if not s then return nil end
		end
		local cap = strsub(text, pos, s - 1)
		if cap == "" then return nil end
		caps[i - 1] = cap
		pos = s + strlen(lit)
	end
	return (gsub(entry.f, "{(%d+)}", function(k) return caps[tonumber(k)] or "" end))
end

local function DescLookup(text)
	local d = SFR_D.sdesc
	if not d or not text or strlen(text) < 8 then return nil end
	local lists = { d[strsub(text, 1, 10)], d[""] }
	for li = 1, 2 do
		local list = lists[li]
		if list then
			for i = 1, table.getn(list) do
				local r = MatchEntry(list[i], text)
				if r then return r end
			end
		end
	end
	return nil
end
SFR.SpellDesc = DescLookup

local function Translate(tt)
	if not SFR.On("spells") then return end
	local tname = tt:GetName()
	if not tname then return end
	local left1 = getglobal(tname .. "TextLeft1")
	local t = left1 and left1:GetText()
	if not t or not SFR_D.spell then return end
	local changed = nil
	local fr = SFR_D.spell[t]
	if fr then
		left1:SetText(fr)
		changed = 1
	elseif strlen(t) < 60 then
		SFR.Miss("spell", t)
	end
	local n = tt:NumLines()
	for i = 1, n do
		local right = getglobal(tname .. "TextRight" .. i)
		local rt = right and right:GetText()
		if rt then
			local nt = SFR.SpellLine(rt)
			if nt ~= rt then right:SetText(nt) changed = 1 end
		end
		if i > 1 then
			local left = getglobal(tname .. "TextLeft" .. i)
			local lt = left and left:GetText()
			if lt then
				local nt = SFR.SpellLine(lt)
				if nt == lt then
					local d = DescLookup(lt)
					if d then nt = d elseif strlen(lt) > 40 then SFR.Miss("desc", lt) end
				end
				if nt ~= lt then left:SetText(nt) changed = 1 end
			end
		end
	end
	if changed then
		SFR.Count("spells")
		tt:Show()
	end
end

local METHODS = {
	"SetSpell", "SetAction", "SetPlayerBuff", "SetUnitBuff", "SetUnitDebuff", "SetTalent",
	"SetTrainerService", "SetPetAction", "SetShapeshift",
}
local function HookMethod(method)
	SFR.Hook(GameTooltip, method, function(orig, self, a1, a2, a3, a4, a5)
		local r1, r2, r3 = orig(self, a1, a2, a3, a4, a5)
		SFR.Try(function() Translate(self) end)
		return r1, r2, r3
	end)
end
for i = 1, table.getn(METHODS) do HookMethod(METHODS[i]) end

local function Name(en)
	if en and SFR.On("deepspells") and SFR_D.spell then
		-- look the translation up first: the caller check (debugstack) only runs when there is something to return
		local fr = SFR_D.spell[en]
		if fr and not SFR.CallerIsAddon() then return fr end
	end
	return en
end

-- spellbook: (name, rank)
SFR.HookGlobal("GetSpellName", function(orig, a1, a2)
	local name, rank = orig(a1, a2)
	return Name(name), rank
end)
-- talent frame: (name, iconTexture, tier, column, rank, maxRank, ...) and tab names (name, icon, points, background)
SFR.HookGlobal("GetTalentInfo", function(orig, a1, a2)
	local name, b, c, d, e, f, g = orig(a1, a2)
	return Name(name), b, c, d, e, f, g
end)
SFR.HookGlobal("GetTalentTabInfo", function(orig, a1)
	local name, b, c, d = orig(a1)
	if name and SFR_UI.tree[name] and SFR.On("deepspells") and not SFR.CallerIsAddon() then name = SFR_UI.tree[name] end
	return name, b, c, d
end)

-- macros and addons that pass back a name obtained from GetSpellName: French -> English before the game sees it
SFR.HookGlobal("CastSpellByName", function(orig, name, onSelf)
	if name and SFR.On("deepspells") and SFR_D.spell then
		local _, _, base, rest = strfind(name, "^%s*([^(]-)%s*(%(.*)$")
		if not base then base = name rest = "" end
		local en = SFR.Reverse("spell")[base]
		if en then
			rest = gsub(rest, "Rang", "Rank")
			name = en .. rest
		end
	end
	return orig(name, onSelf)
end)
