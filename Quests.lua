-- Quest texts, quest log, tracker, gossip. Data keyed by the ENGLISH quest title (what the client shows).

local Real = {}
Real.GetTitleText = GetTitleText
Real.GetQuestText = GetQuestText
Real.GetObjectiveText = GetObjectiveText
Real.GetProgressText = GetProgressText
Real.GetRewardText = GetRewardText
Real.GetQuestLogTitle = GetQuestLogTitle
Real.GetQuestLogQuestText = GetQuestLogQuestText
Real.GetQuestLogSelection = GetQuestLogSelection

-- Several quests can share one title: SFR_D.questx[title] lists them, each with k = start of its English
-- details text. 'hint' is the English details text the client shows; without it the richest record is used.
-- A questx entry that is a plain STRING is a title-only translation (no text) for a title the quest table does not hold.
local titleOnly = {}
local function Quest(en, hint)
	if not en or not SFR.On("quests") or not SFR.Need("Quests", "quest") then return nil end
	local many = SFR_D.questx and SFR_D.questx[en]
	if type(many) == "table" and hint and hint ~= "" then
		for i = 1, table.getn(many) do
			local r = many[i]
			if r.k ~= "" and strsub(hint, 1, strlen(r.k)) == r.k then return r end
		end
	end
	local rec = SFR_D.quest[en]
	if not rec and type(many) == "string" then
		rec = titleOnly[en]
		if not rec then rec = { t = many, k = "" } titleOnly[en] = rec end
	end
	return rec
end

-- the client substitutes $N/$C/$R/$B/$g in the text it gives to the UI; do the same on the French text
local function Subst(s)
	if not s then return s end
	local name = SFR.RealUnitName and SFR.RealUnitName("player") or UnitName("player")
	s = gsub(s, "%$[Nn]", name or "")
	local class = UnitClass("player")
	s = gsub(s, "%$[Cc]", (SFR_UI.class[class or ""] or class or ""))
	local race = UnitRace("player")
	s = gsub(s, "%$[Rr]", (SFR_UI.race[race or ""] or race or ""))
	s = gsub(s, "%$[Bb]", "\n")
	s = gsub(s, "%$[Gg]([^:;]*):([^;]*);", function(m, f)
		if UnitSex("player") == 3 then return f end
		return m
	end)
	return s
end

-- the English details text of the open dialog identifies which same-titled quest it is
local function DialogQuest()
	return Quest(Real.GetTitleText(), Real.GetQuestText())
end
-- v0.6.0: like the names (UnitName, GetSpellName...), the quest texts are French for the game UI and ENGLISH for
-- other addons (SFR.CallerIsAddon): pfQuest parses the objective lines with the English patterns, _LazyPig compares
-- gossip/quest texts with English strings. The caller check only runs once a translation exists.
local function Field(key, en)
	local q = DialogQuest()
	if q and q[key] and not SFR.CallerIsAddon() then SFR.Count("quests") return Subst(q[key]) end
	return en
end

function GetTitleText()
	local en = Real.GetTitleText()
	local q = DialogQuest()
	if q and q.t then
		if not SFR.CallerIsAddon() then return q.t end
	elseif not q then
		SFR.Miss("quest", en)
	end
	return en
end
function GetQuestText() return Field("d", Real.GetQuestText()) end
function GetObjectiveText() return Field("o", Real.GetObjectiveText()) end
function GetProgressText() return Field("q", Real.GetProgressText()) end
function GetRewardText() return Field("r", Real.GetRewardText()) end

-- quest log list + tracker: (title, level, tag, isHeader, isCollapsed, isComplete, ...)
function GetQuestLogTitle(i)
	local a, b, c, d, e, f, g = Real.GetQuestLogTitle(i)
	if a and not d then
		local q = Quest(a)
		if q and q.t then
			if not SFR.CallerIsAddon() then a = q.t end
		elseif not q then
			SFR.Miss("quest", a)
		end
	end
	return a, b, c, d, e, f, g
end

function GetQuestLogQuestText()
	local desc, obj = Real.GetQuestLogQuestText()
	local sel = Real.GetQuestLogSelection and Real.GetQuestLogSelection()
	if sel and sel > 0 then
		local en = Real.GetQuestLogTitle(sel)
		local q = Quest(en, desc)
		if q and (q.d or q.o) and not SFR.CallerIsAddon() then
			if q.d then desc = Subst(q.d) end
			if q.o then obj = Subst(q.o) end
		end
	end
	return desc, obj
end

-- "Kobold Vermin slain: 3/10" / "Linen Cloth: 4/8" -> French names when known
local function Name(en)
	if SFR.Need("NPC", "npc") and SFR_D.npc[en] then return SFR_D.npc[en] end
	if SFR.Need("Items", "itemn") and SFR_D.itemn[en] then return SFR_D.itemn[en] end
	if SFR_D.go and SFR_D.go[en] then return SFR_D.go[en] end
	return en
end
local function Leader(text)
	if not text or not SFR.On("quests") then return text end
	local _, _, n, a, b = strfind(text, "^(.-) slain: (%d+)/(%d+)$")
	if n then return Name(n) .. " tué : " .. a .. "/" .. b end
	_, _, n, a, b = strfind(text, "^(.-): (%d+)/(%d+)$")
	if n then return Name(n) .. " : " .. a .. "/" .. b end
	return text
end
if GetQuestLogLeaderBoard then
	SFR.HookGlobal("GetQuestLogLeaderBoard", function(orig, i, q)
		local desc, kind, done = orig(i, q)
		local fr = Leader(desc)
		if fr ~= desc and SFR.CallerIsAddon() then fr = desc end -- pfQuest & co. parse the English line
		return fr, kind, done
	end)
end

-- NPC quest dialog lists
local function TitleOf(en)
	local q = Quest(en)
	if q and q.t then return q.t end
	return en
end
-- (addons get the English title, the game's own quest windows the French one)
local function TitleForUI(en)
	local fr = TitleOf(en)
	if fr ~= en and SFR.CallerIsAddon() then return en end
	return fr
end
SFR.HookGlobal("GetAvailableTitle", function(orig, i) return TitleForUI(orig(i)) end)
SFR.HookGlobal("GetActiveTitle", function(orig, i) return TitleForUI(orig(i)) end)

-- gossip: options (text, type)*, available quests (title, level, ...)*, active quests
local function TranslateAll(list, gossipOnly)
	local n = list.n or 0
	for i = 1, n do
		local v = list[i]
		if type(v) == "string" then
			local fr = nil
			if gossipOnly and SFR.Need("NPC", "gossip") then fr = SFR_D.gossip[v] end
			if not fr and not gossipOnly then fr = TitleOf(v) end
			if fr and fr ~= v then list[i] = fr SFR.Count("gossip") end
		end
	end
	return list
end
local function HookList(name, gossipOnly)
	local orig = getglobal(name)
	if not orig then return end
	setglobal(name, function(a1, a2, a3)
		local t = SFR.Pack(orig(a1, a2, a3))
		-- addons (_LazyPig...) get the English texts: only the game's own gossip/quest windows are translated
		if SFR.On("gossip") and not SFR.CallerIsAddon() then SFR.Try(function() TranslateAll(t, gossipOnly) end) end
		return unpack(t)
	end)
end
HookList("GetGossipOptions", true)
HookList("GetGossipAvailableQuests", false)
HookList("GetGossipActiveQuests", false)
