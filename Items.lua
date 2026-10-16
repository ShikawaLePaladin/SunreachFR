-- Item names/descriptions in tooltips (by item id, from the hyperlink) + item names in chat links.

local function IdFromLink(link)
	if not link then return nil end
	local _, _, id = strfind(link, "item:(%d+)")
	if id then return tonumber(id) end
	return nil
end
SFR.ItemIdFromLink = IdFromLink

-- true when the item link carries a random suffix/property ("item:id:enchant:suffix:unique", suffix <> 0)
local function HasSuffix(link)
	if not link then return nil end
	local _, _, s = strfind(link, "item:%d+:%-?%d+:(%-?%d+)")
	if s and tonumber(s) ~= 0 then return 1 end
	return nil
end
SFR.LinkHasSuffix = HasSuffix

-- French name for an item id, or nil
function SFR.ItemName(id)
	if not id or not SFR.On("items") or not SFR.Need("Items", "items") then return nil end
	local d = SFR_D.items[id]
	if type(d) == "table" then return d[1] end
	return d
end

local function SetIf(fs, old, new)
	if new and new ~= old then fs:SetText(new) return 1 end
	return nil
end

local function TranslateTooltip(tt, link)
	local tname = tt:GetName()
	if not tname then return end
	local id = IdFromLink(link)
	local fr, en_d, fr_d
	if id and SFR.On("items") and SFR.Need("Items", "items") then
		local d = SFR_D.items[id]
		if type(d) == "table" then fr = d[1] en_d = d[2] fr_d = d[3] else fr = d end
	end
	if id and not fr then
		local l1 = getglobal(tname .. "TextLeft1")
		SFR.Miss("item", l1 and l1:GetText())
	end
	local ui = SFR.On("tooltipui")
	local sp = SFR.On("spells")
	if not fr and not ui and not sp then return end
	-- random-suffix items ("... of the Owl"): the data holds the base name only, so keep the English name
	-- rather than silently dropping the suffix
	local suffixed = HasSuffix(link)
	local changed = nil
	local n = tt:NumLines()
	for i = 1, n do
		local left = getglobal(tname .. "TextLeft" .. i)
		local t = left and left:GetText()
		if t then
			local nt = nil
			if i == 1 then
				if not suffixed then nt = fr end
			elseif en_d and fr_d and t == en_d then
				nt = fr_d
			elseif en_d and fr_d and t == '"' .. en_d .. '"' then
				nt = '"' .. fr_d .. '"'
			else
				-- "Equip:" / "Use:" effect texts: exact models of the spell descriptions (Spells.lua / data/Descriptions.lua)
				if sp and SFR.SpellDesc and (strfind(t, "^Equip: ") or strfind(t, "^Use: ") or strfind(t, "^Chance on hit: ")) then
					nt = SFR.SpellDesc(t)
				end
				if not nt and ui then nt = SFR.UILine(t) end
			end
			if SetIf(left, t, nt) then changed = 1 end
		end
		if ui then
			local right = getglobal(tname .. "TextRight" .. i)
			local rt = right and right:GetText()
			if rt and SetIf(right, rt, SFR.UILine(rt)) then changed = 1 end
		end
	end
	if changed then
		SFR.Count("tooltips")
		tt:Show() -- recompute the tooltip size after the text changed
	end
end
SFR.TranslateItemTooltip = TranslateTooltip

local function Get(name, a1, a2)
	local f = getglobal(name)
	if f then return f(a1, a2) end
	return nil
end

local LINKS = {
	SetBagItem = function(a1, a2) return Get("GetContainerItemLink", a1, a2) end,
	SetInventoryItem = function(a1, a2) return Get("GetInventoryItemLink", a1, a2) end,
	SetLootItem = function(a1) return Get("GetLootSlotLink", a1) end,
	SetMerchantItem = function(a1) return Get("GetMerchantItemLink", a1) end,
	SetQuestItem = function(a1, a2) return Get("GetQuestItemLink", a1, a2) end,
	SetQuestLogItem = function(a1, a2) return Get("GetQuestLogItemLink", a1, a2) end,
	SetAuctionItem = function(a1, a2) return Get("GetAuctionItemLink", a1, a2) end,
	SetTradePlayerItem = function(a1) return Get("GetTradePlayerItemLink", a1) end,
	SetTradeTargetItem = function(a1) return Get("GetTradeTargetItemLink", a1) end,
	SetLootRollItem = function(a1) return Get("GetLootRollItemLink", a1) end,
	SetTradeSkillItem = function(a1, a2)
		if a2 then return Get("GetTradeSkillReagentItemLink", a1, a2) end
		return Get("GetTradeSkillItemLink", a1)
	end,
	SetCraftItem = function(a1, a2) return Get("GetCraftReagentItemLink", a1, a2) end,
	SetHyperlink = function(a1) return a1 end,
}

-- Lua 5.0: a closure created inside a 'for' body sees the loop variable reset to nil after the loop ends,
-- so the closure is built in its own function where 'linkfn' is an ordinary parameter.
local function HookLink(tt, method, linkfn)
	SFR.Hook(tt, method, function(orig, self, a1, a2, a3, a4, a5)
		local r1, r2, r3 = orig(self, a1, a2, a3, a4, a5)
		SFR.Try(function() TranslateTooltip(self, linkfn(a1, a2)) end)
		return r1, r2, r3
	end)
end

local function InstallOn(tt)
	if not tt then return end
	for method, linkfn in pairs(LINKS) do
		HookLink(tt, method, linkfn)
	end
end
InstallOn(GameTooltip)
InstallOn(ItemRefTooltip)
InstallOn(ShoppingTooltip1)
InstallOn(ShoppingTooltip2)

-- chat: [English name] -> [nom français] inside item hyperlinks
local function FixLinks(text)
	if not text or not strfind(text, "|Hitem:", 1, true) then return text end
	return (gsub(text, "(|Hitem:(%d+)[^|]*|h)%[(.-)%](|h)", function(head, id, name, tail)
		local fr = SFR.ItemName(tonumber(id))
		if fr and not HasSuffix(head) then return head .. "[" .. fr .. "]" .. tail end
		return head .. "[" .. name .. "]" .. tail
	end))
end
SFR.FixLinks = FixLinks
