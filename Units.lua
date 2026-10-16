-- NPC / world-object tooltips (mouseover in the world goes through OnShow; unit frames through SetUnit),
-- French names everywhere with "deepnames", and /target by French name.

local RealUnitName = UnitName
SFR.RealUnitName = RealUnitName

local function TranslateLines(tt, isUnit)
	local tname = tt:GetName()
	if not tname then return end
	local changed = nil
	local n = tt:NumLines()
	local ui = SFR.On("tooltipui")
	for i = 1, n do
		local left = getglobal(tname .. "TextLeft" .. i)
		local t = left and left:GetText()
		if t then
			local nt = nil
			if i == 1 then
				if isUnit then
					nt = SFR_D.npc[t]
					if not nt then SFR.Miss("npc", t) end
				else
					nt = SFR_D.go[t]
				end
			elseif isUnit and i == 2 then
				local _, _, inner = strfind(t, "^<(.*)>$")
				local sub = SFR_D.npcsub[inner or t]
				if sub then
					if inner then nt = "<" .. sub .. ">" else nt = sub end
				end
			end
			if not nt and ui and i > 1 then nt = SFR.UILine(t) end
			if nt and nt ~= t then left:SetText(nt) changed = 1 end
		end
	end
	if changed then
		SFR.Count("units")
		tt:Show()
	end
end

-- unit = "mouseover", "target", ...; only non-player units whose tooltip title is that unit's name
local function TranslateUnit(tt, unit)
	if not SFR.On("units") or not unit or not UnitExists(unit) or UnitIsPlayer(unit) then return end
	if not SFR.Need("NPC", "npc") then return end
	local first = getglobal(tt:GetName() .. "TextLeft1")
	if not first or first:GetText() ~= RealUnitName(unit) then return end
	TranslateLines(tt, true)
end

local busy = nil
local function OnShow(tt)
	if busy or not SFR.On("units") then return end
	busy = 1
	SFR.Try(function()
		if UnitExists("mouseover") then
			TranslateUnit(tt, "mouseover")
		elseif tt:NumLines() <= 3 and SFR.Need("NPC", "go") then
			local first = getglobal(tt:GetName() .. "TextLeft1")
			local t = first and first:GetText()
			if t and SFR_D.go[t] then TranslateLines(tt, false) end
		end
	end)
	busy = nil
end

SFR.Hook(GameTooltip, "SetUnit", function(orig, self, unit, a2, a3, a4, a5)
	local r1, r2 = orig(self, unit, a2, a3, a4, a5)
	SFR.Try(function() TranslateUnit(self, unit) end)
	return r1, r2
end)

-- installed late, so it wraps whatever tooltip script pfUI & co. installed after this addon loaded
SFR.OnReady(function()
	local old = GameTooltip:GetScript("OnShow")
	GameTooltip:SetScript("OnShow", function()
		if old then old() end
		OnShow(this)
	end)
end)

-- "deepnames": UnitName itself returns the French name of NPCs (target frame, party frames, addons...)
SFR.HookGlobal("UnitName", function(orig, unit)
	local name, realm = orig(unit)
	if name and SFR.On("deepnames") and SFR_D.npc and not UnitIsPlayer(unit) then
		-- look the translation up first: the caller check (debugstack) only runs when there is something to return
		local fr = SFR_D.npc[name]
		if fr and not SFR.CallerIsAddon() then return fr, realm end
	end
	return name, realm
end)

-- /target Nom-en-francais and addons that pass back a name obtained from UnitName
SFR.HookGlobal("TargetByName", function(orig, name, exact)
	if name and SFR.On("deepnames") and SFR_D.npc then
		local en = SFR.Reverse("npc")[name]
		if en then name = en end
	end
	return orig(name, exact)
end)
