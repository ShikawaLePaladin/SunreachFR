-- Books, NPC chat lines, chat item links, zone names, optional GetItemInfo.

-- books / letters: key = first 60 chars of the English page, value = { english length, french text }
-- or, when several pages share their first 60 chars, a LIST of such pairs: { {length, text}, {length, text}, ... }
if ItemTextGetText then
	SFR.HookGlobal("ItemTextGetText", function(orig)
		local t = orig()
		if t and SFR.On("books") and SFR.Need("Books", "page") then
			local e = SFR_D.page[strsub(t, 1, 60)]
			if e then
				local len = strlen(t)
				if type(e[1]) == "table" then
					for i = 1, table.getn(e) do
						if e[i][1] == len then SFR.Count("books") return e[i][2] end
					end
				elseif e[1] == len then
					SFR.Count("books")
					return e[2]
				end
			end
		end
		return t
	end)
end

-- chat: item links in every channel, NPC lines in the monster channels (exact English text only)
local orig_ChatFrame_OnEvent = ChatFrame_OnEvent
if orig_ChatFrame_OnEvent then
	ChatFrame_OnEvent = function(ev)
		local original = arg1
		if arg1 and type(arg1) == "string" then
			SFR.Try(function()
				if strfind(ev, "^CHAT_MSG_MONSTER") and SFR.On("chatnpc") and SFR.Need("Chat", "chat") then
					local fr = SFR_D.chat[arg1]
					if fr then arg1 = fr SFR.Count("chat") end
				end
				if SFR.On("chatlinks") then arg1 = SFR.FixLinks(arg1) end
			end)
		end
		local r1, r2 = orig_ChatFrame_OnEvent(ev)
		-- arg1 is a global shared with the other frames/addons handling this event: give them the original text back
		arg1 = original
		return r1, r2
	end
end

-- zone names (on by default; other addons still get the English name, see SFR.CallerIsAddon)
local function Zone(en)
	if en and en ~= "" and SFR.On("zones") and SFR_D.area then
		local fr = SFR_D.area[en]
		if fr and not SFR.CallerIsAddon() then return fr end
	end
	return en
end
SFR.HookGlobal("GetZoneText", function(orig) return Zone(orig()) end)
SFR.HookGlobal("GetRealZoneText", function(orig, a1) return Zone(orig(a1)) end)
SFR.HookGlobal("GetSubZoneText", function(orig) return Zone(orig()) end)
SFR.HookGlobal("GetMinimapZoneText", function(orig) return Zone(orig()) end)

-- flight master destinations
SFR.HookGlobal("TaxiNodeName", function(orig, i)
	local n = orig(i)
	if n and SFR.On("zones") and SFR_D.taxi then
		local fr = SFR_D.taxi[n]
		if fr and not SFR.CallerIsAddon() then return fr end
	end
	return n
end)

-- "deepitems": GetItemInfo returns the French name first
SFR.HookGlobal("GetItemInfo", function(orig, a1)
	local a, b, c, d, e, f, g, h, i = orig(a1)
	if a and SFR.On("deepitems") then
		local id = nil
		if type(a1) == "number" then id = a1
		elseif type(a1) == "string" and not SFR.LinkHasSuffix(a1) then id = SFR.ItemIdFromLink(a1) or tonumber(a1) end
		local fr = SFR.ItemName(id)
		-- translation first, caller check (debugstack) only when there is something to return
		if fr and not SFR.CallerIsAddon() then a = fr end
	end
	return a, b, c, d, e, f, g, h, i
end)

-- professions: recipe and reagent names come from the item names (a recipe is named after what it makes)
local function ItemFr(en)
	if en and SFR.On("professions") and SFR_D.itemn then
		local fr = SFR_D.itemn[en]
		if fr and not SFR.CallerIsAddon() then return fr end
	end
	return nil
end
SFR.HookGlobal("GetTradeSkillInfo", function(orig, i)
	local name, kind, c, d, e = orig(i)
	if name and kind ~= "header" then
		local fr = ItemFr(name)
		if fr then name = fr else SFR.Miss("recipe", name) end
	end
	return name, kind, c, d, e
end)
SFR.HookGlobal("GetTradeSkillReagentInfo", function(orig, i, j)
	local name, tex, count, player = orig(i, j)
	return ItemFr(name) or name, tex, count, player
end)
SFR.HookGlobal("GetCraftInfo", function(orig, i)
	local name, sub, kind, c, d, e, f = orig(i)
	if name and kind ~= "header" then name = ItemFr(name) or name end
	return name, sub, kind, c, d, e, f
end)
SFR.HookGlobal("GetCraftReagentInfo", function(orig, i, j)
	local name, tex, count, player = orig(i, j)
	return ItemFr(name) or name, tex, count, player
end)
