local addonName, MTI = ...;
MoreTooltipInfo = MTI
MoreTooltipInfo.Enum = {}

local _G = _G
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

local dataVersion = "9.0.1.35755"
local dataDate = "2020-09-03_14:04"

local cfg
local dbDefaults = {
	char = {},
}
local charDefaults = { 
  enableSpellID = true,
  enableSpellRPPM = true,
  enableSpellGCD = true,
  enableItemID = true,
  enableItemSpellID = true,
  enableItemRPPM = true,
  enableItemBonusID = true,
  enableItemGemID = true,
  enableItemEnchantID = true,
  enableItemEnchantSpellID = true,
  enableItemEnchantSpellRPPM = true,
  enableItemDPS = true,
  enableSoulbindID = true,
  enableConduitID = true,
  enableConduitSpellID = true,
  enableConduitRank = true
}

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)
f:RegisterEvent("ADDON_LOADED")

function MoreTooltipInfo.TooltipLine(tooltip, info, infoType)
  local found = false

  -- Check if we already added to this tooltip. Happens on the talent frame
  for i = 1,15 do
    local frame = _G[tooltip:GetName() .. "TextLeft" .. i]
    local text
    if frame then text = frame:GetText() end
    if text and text == infoType then 
      found = true 
      break 
    end
  end

  if not found then
    tooltip:AddDoubleLine(infoType, "|cffffffff" .. info)
    tooltip:Show()
  end
end

function MoreTooltipInfo.FormatSpace(number)
  local formatted = number

  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
    if (k == 0) then
      return formatted
    end
  end
end

function MoreTooltipInfo.GetSpecID()
  -- Spec Info
	local globalSpecID
	local specId = GetSpecialization()
	if specId then
		globalSpecID = GetSpecializationInfo(specId)
	end
	return tonumber(globalSpecID)
end

function MoreTooltipInfo.GetRace()
	-- Race info
	local _, playerRace = UnitRace('player')
  
  return tonumber(playerRace)
end

function MoreTooltipInfo.GetClassID()
	-- Class info
	local _, _, playerRace = UnitClass('player')
  
  return tonumber(playerRace)
end

function MoreTooltipInfo.GetHastePct()
  return GetHaste()
end

function MoreTooltipInfo.GetCritPct()
  return GetCritChance()
end

function MoreTooltipInfo.GetItemSplit(itemLink)
  local itemString = string.match(itemLink, "item:([%-?%d:]+)")
  local itemSplit = {}

  -- Split data into a table
  for _, v in ipairs({strsplit(":", itemString)}) do
    if v == "" then
      itemSplit[#itemSplit + 1] = 0
    else
      itemSplit[#itemSplit + 1] = tonumber(v)
    end
  end

  return itemSplit
end

function MoreTooltipInfo.GetIDFromLink(linktype,Link)
	local xString = string.match(Link, linktype .. ":([%-?%d:]+)")
	local xSplit = {}
  
  if not xString then
    return nil
  end

	-- Split data into a table
	for v in string.gmatch(xString, "(%d*:?)") do
		if v == ":" then
		  xSplit[#xSplit + 1] = 0
		else
		  xSplit[#xSplit + 1] = string.gsub(v, ':', '')
		end
	end

	return tonumber(xSplit[1])
end

function MoreTooltipInfo.GetItemBonusID(itemSplit)
  local bonuses = {}

  for index=1, itemSplit[13] do
    bonuses[#bonuses + 1] = itemSplit[13 + index]
  end

  if #bonuses > 0 then
    return table.concat(bonuses, '/')
  end
end

function MoreTooltipInfo.GetGemItemID(itemLink, index)
  local _, gemLink = GetItemGem(itemLink, index)
  if gemLink ~= nil then
    local itemIdStr = string.match(gemLink, "item:(%d+)")
    if itemIdStr ~= nil then
      return tonumber(itemIdStr)
    end
  end

  return 0
end

function MoreTooltipInfo.GetGemBonuses(itemLink, index)
  local bonuses = {}
  local _, gemLink = GetItemGem(itemLink, index)
  if gemLink ~= nil then
    local gemSplit = MoreTooltipInfo.GetItemSplit(gemLink)
    for index=1, gemSplit[13] do
      bonuses[#bonuses + 1] = gemSplit[13 + index]
    end
  end

  if #bonuses > 0 then
    return table.concat(bonuses, ':')
  end

  return 0
end

function MoreTooltipInfo.getGemString(self,itemLink)
  local gems = {}
  local gemBonuses = {}

  local itemSplit = MoreTooltipInfo.GetItemSplit(itemLink)

  for gemOffset = 3, 6 do
    local gemIndex = (gemOffset - 3) + 1
    if itemSplit[gemOffset] > 0 then
      local gemId = MoreTooltipInfo.GetGemItemID(itemLink, gemIndex)
      if gemId > 0 then
        gems[gemIndex] = gemId
        gemBonuses[gemIndex] = MoreTooltipInfo.GetGemBonuses(itemLink, gemIndex)
      end
    else
      gems[gemIndex] = 0
      gemBonuses[gemIndex] = 0
    end
  end

  -- Remove any trailing zeros from the gems array
  while #gems > 0 and gems[#gems] == 0 do
    table.remove(gems, #gems)
  end
  -- Remove any trailing zeros from the gem bonuses
  while #gemBonuses > 0 and gemBonuses[#gemBonuses] == 0 do
    table.remove(gemBonuses, #gemBonuses)
  end

  if #gems > 0 then
    MoreTooltipInfo.TooltipLine(self, table.concat(gems, '/'), "GemID")
    if #gemBonuses > 0 then
      MoreTooltipInfo.TooltipLine(self, table.concat(gemBonuses, '/'), "GemBonusID")
    end
  end
end

function MoreTooltipInfo.GetItemLevelFromTooltip(tooltip)
  local itemLink = tooltip:GetItem()
  if not itemLink then return end

  for i = 2, tooltip:NumLines() do
    local text = _G[tooltip:GetName() .. "TextLeft"..i]:GetText()

    if(text and text ~= "") then
      local value = tonumber(text:match(ITEM_LEVEL:gsub("%%d", "(%%d+)")))
      if value then
        return value
      end
    end
  end
end

function MoreTooltipInfo.GetItemSpellID(itemID)
  local spellID = MoreTooltipInfo.Enum.ItemSpell[itemID]
  if spellID then
    return spellID
  end
end

function MoreTooltipInfo.GetConduitSpellID(conduitID)
  local spellID = MoreTooltipInfo.Enum.Conduits[conduitID]
  if spellID then
    return spellID
  end
end

function MoreTooltipInfo.GetRPPM(spellID)
  local rppmtable = MoreTooltipInfo.Enum.RPPM[spellID]
  if not rppmtable then
    return nil
  end
  
  local specID = MoreTooltipInfo.GetSpecID()
  local classID = MoreTooltipInfo.GetClassID()
  local race = MoreTooltipInfo.GetRace()
  
  local baseRPPM = rppmtable[0]
  
  local modHaste = false
  if rppmtable[1] then
    modHaste = true
  end
  local modCrit = false
  if rppmtable[2] then
    modCrit = true
  end
  
  local modRace = nil
  if rppmtable[5] then
    if rppmtable[5][race] then
      modRace = rppmtable[5][race]
    end
  end
  
  local modClass = nil
  if rppmtable[3] then
    if rppmtable[3][classID] then
      modClass = rppmtable[3][classID]
    end
  end
  
  local modSpec = nil
  if rppmtable[4] then
    if rppmtable[4][specID] then
      modSpec = rppmtable[4][bspecID]
    end
  end
    
  local rppmString = ""
  
  if modRace then
    rppmString = modRace
  elseif modClass then
    rppmString = modClass
  elseif modSpec then
    rppmString = modSpec
  else
    rppmString = baseRPPM
  end
  if modHaste then
    local currentHasteRating = MoreTooltipInfo.GetHastePct()
    local hastedRPPM = rppmString * (1 + (currentHasteRating / 100))
    rppmString = rppmString .. " (Hasted : " .. string.format("%.4f", hastedRPPM) ..")"
  elseif modCrit then
    local currentCritRating = MoreTooltipInfo.GetCritPct()
    local critRPPM = rppmString * (1 + (currentCritRating / 100))
    rppmString = rppmString .. " (Crit : " .. string.format("%.4f", critRPPM) ..")"
  end
  
  return rppmString
end

function MoreTooltipInfo.GetGCD(spellID)
  local gcd = 0
  if MoreTooltipInfo.Enum.TriggerGCD[spellID] ~= nil then
    gcd = MoreTooltipInfo.Enum.TriggerGCD[spellID]
  else
    return nil
  end
  return gcd
end

function MoreTooltipInfo.GetDPS(itemID,tooltip)
  local dps
  local specID = MoreTooltipInfo.GetSpecID()
  local classID = MoreTooltipInfo.GetClassID()

  if MoreTooltipInfo.Enum.ItemDPS[itemID] then
    local itemData = MoreTooltipInfo.Enum.ItemDPS[itemID]
    local itemlevel = MoreTooltipInfo.GetItemLevelFromTooltip(tooltip)
    if itemlevel and specID and classID and #itemData > 0 then
      if itemData[classID][specID][itemlevel] then
        dps = MoreTooltipInfo.FormatSpace(itemData[classID][specID][itemlevel])
      end
    end
  end

  return dps
end

function MoreTooltipInfo.RPPMTooltip(destination, spellID, forceTitle)
  if spellID then
    local rppm = MoreTooltipInfo.GetRPPM(spellID)
    if rppm then
      local title = "RPPM"
      if forceTitle then
        title = forceTitle
      end
      MoreTooltipInfo.TooltipLine(destination, rppm, title)
    end
  end
end

function MoreTooltipInfo.GCDTooltip(destination, spellID)
  if spellID then
    local gcd = MoreTooltipInfo.GetGCD(spellID)
    if gcd then
      gcd = gcd / 1000
      MoreTooltipInfo.TooltipLine(destination, gcd, "GCD")
    end
  end
end

function MoreTooltipInfo.DPSTooltip(destination, itemID)
  if itemID then
    local dps = MoreTooltipInfo.GetDPS(itemID,destination)
    if dps then
      MoreTooltipInfo.TooltipLine(destination, dps, "simDPS")
    end
  end
end

function MoreTooltipInfo.AzeritePowerTooltip(destination, azeritePowerID)
  if azeritePowerID then
    MoreTooltipInfo.TooltipLine(destination, azeritePowerID, "Azerite Power ID")
  end
end

function MoreTooltipInfo.ItemTooltipOverride(self)
  local itemLink = select(2, self:GetItem())
  if itemLink then
    local itemID = tonumber(MoreTooltipInfo.GetIDFromLink("item",itemLink))
    if itemID then
      if cfg.enableItemID then MoreTooltipInfo.TooltipLine(self, itemID, "ItemID") end

      local itemSplit = MoreTooltipInfo.GetItemSplit(itemLink)

      local bonusID = MoreTooltipInfo.GetItemBonusID(itemSplit)
      if bonusID then
        if cfg.enableItemBonusID then MoreTooltipInfo.TooltipLine(self, bonusID, "BonusID") end
      end

      local enchantID = itemSplit[2]
      if enchantID > 0 then
        if cfg.enableItemEnchantID then MoreTooltipInfo.TooltipLine(self, enchantID, "EnchantID") end
        local enchantSpellID = MoreTooltipInfo.Enum.SpellEnchants[enchantID]
        if enchantSpellID then --enchant, we put enchant spellid and rppm
          if cfg.enableItemEnchantSpellID then MoreTooltipInfo.TooltipLine(self, enchantSpellID, "Enchant SpellID") end
          if cfg.enableItemEnchantSpellRPPM then MoreTooltipInfo.RPPMTooltip(self, enchantSpellID, "Enchant RPPM") end
        end
      end

      if cfg.enableItemGemID then MoreTooltipInfo.getGemString(self,itemLink) end
      
      local spellID = MoreTooltipInfo.GetItemSpellID(itemID)
      if spellID then
        if cfg.enableItemSpellID then MoreTooltipInfo.TooltipLine(self, spellID, "SpellID") end
        if cfg.enableItemRPPM then MoreTooltipInfo.RPPMTooltip(self, spellID) end
      end    

      if cfg.enableItemDPS then MoreTooltipInfo.DPSTooltip(self, itemID) end
    end
  end
end

function MoreTooltipInfo.SpellTooltipOverride(option, self, ...)
  local spellID
  
  if option == "default" then
    spellID = select(2, self:GetSpell())
  elseif option == "aura" then
    spellID = select(10, UnitAura(...))
  elseif option == "buff" then
    spellID = select(10, UnitBuff(...)) 
  elseif option == "debuff" then
    spellID = select(10, UnitDebuff(...))   
  elseif option == "conduit" then
    local conduitID = select(1, ...)
    --get spell id from game file
    spellID = MoreTooltipInfo.GetConduitSpellID(select(1, ...))   
  elseif option == "ref" then
    spellID = MoreTooltipInfo.GetIDFromLink("spell", self)
    self = ItemRefTooltip
  end
  
  if spellID then
    if option ~= "conduit" then
      if cfg.enableSpellID then MoreTooltipInfo.TooltipLine(self, spellID, "SpellID") end
    end
    if cfg.enableSpellRPPM then MoreTooltipInfo.RPPMTooltip(self, spellID) end
    if cfg.enableSpellGCD then MoreTooltipInfo.GCDTooltip(self, spellID) end
    if option == "conduit" then
      if cfg.enableConduitID then MoreTooltipInfo.TooltipLine(self, select(1, ...), "ConduitID") end
      if cfg.enableConduitRank then MoreTooltipInfo.TooltipLine(self, select(2, ...), "ConduitRank") end
      if cfg.enableConduitSpellID then MoreTooltipInfo.TooltipLine(self, spellID, "ConduitSpellID") end
    end
  end
end

function MoreTooltipInfo.ManageTooltips(tooltipType, option, ...)
  --print(tooltipType, option)
  if tooltipType =="spell" then
    MoreTooltipInfo.SpellTooltipOverride(option, ...)
  elseif tooltipType =="item" then
    MoreTooltipInfo.ItemTooltipOverride(...)
  end
end

function MoreTooltipInfo:initDB(db, defaults)
	if type(db) ~= "table" then db = {} end
	if type(defaults) ~= "table" then return db end
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			db[k] = MoreTooltipInfo:initDB(db[k], v)
		elseif type(v) ~= type(db[k]) then
			db[k] = v
		end
	end
	return db
end

-------------------
-- Interface UI  --
-------------------

function f:CreateOptions()
	if self.optionsFrame then return end

  -- Config showing in the Blizzard Options
  local mainPanel = {
		type = "group",
		name = addonName .." options",
		order = 103,
		get = function(info) return cfg[ info[#info] ] end,
		set = function(info, value) cfg[ info[#info] ] = value; end,
		args = {
      version = {
        type = "description",
        name = NORMAL_FONT_COLOR_CODE .. "Data version: " .. HIGHLIGHT_FONT_COLOR_CODE .. dataVersion .. " (" .. dataDate .. ")" .. FONT_COLOR_CODE_CLOSE,
        fontSize = "medium",
        width = "full",
        order = 1,
      },
		},
  }
	local tooltipPanel = {
		type = "group",
		name = "Tooltip options",
		order = 103,
		get = function(info) return cfg[ info[#info] ] end,
		set = function(info, value) cfg[ info[#info] ] = value; end,
		args = {
      gSpell = {
				type = "group",
				name = "Spells",
				inline = true,
				order = 0,
				args = {
					enableSpellID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable SpellID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 0,
          },
          enableSpellRPPM = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Spell RPPM" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 1,
          },
          enableSpellGCD = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Spell GCD" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 2,
          },
        },
      },
      gItem = {
        type = "group",
        name = "Items",
        inline = true,
        order = 1,
        args = {
          enableItemID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable ItemID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 0,
          },
          enableItemSpellID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item Spell ID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 1,
          },
          enableItemRPPM = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item Spell RPPM" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 2,
          },
          enableItemBonusID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item BonusID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 3,
          },
          enableItemGemID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item GemID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 4,
          },
          enableItemEnchantID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item EnchantID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 5,
          },
          enableItemEnchantSpellID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item Enchant Spell ID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 6,
          },
          enableItemEnchantSpellRPPM = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item Enchant Spell RPPM" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 7,
          },
        },
      },
      gSoulbind = {
        type = "group",
        name = "Soulbinds",
        inline = true,
        order = 2,
        args = {
          enableSoulbindID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable SoulbindID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 0,
          },
        },
      },
      gConduit = {
        type = "group",
        name = "Conduits",
        inline = true,
        order = 3,
        args = {
          enableConduitID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable ConduitsID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 0,
          },
          enableConduitSpellID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Conduits SpellID" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 1,
          },
          enableConduitRank = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Conduits rank" .. FONT_COLOR_CODE_CLOSE,
            descStyle = "inline",
            width = "full",
            order = 2,
          },
        },
      },
		},
  }
  local itemDPSPanel = {
		type = "group",
		name = "Item DPS options",
		order = 103,
		get = function(info) return cfg[ info[#info] ] end,
		set = function(info, value) cfg[ info[#info] ] = value; end,
		args = {
      enableItemDPS = {
        type = "toggle",
        name = NORMAL_FONT_COLOR_CODE .. "Enable Item Simulated DPS" .. FONT_COLOR_CODE_CLOSE,
        descStyle = "inline",
        width = "full",
        order = 0,
      },
		},
  }

  self.optionsFrame = ACD:AddToBlizOptions(addonName, addonName["MoreTooltipInfo"])
	self.optionsFrame = ACD:AddToBlizOptions("Tooltip options", addonName["TooltipOptions"], addonName)
	self.optionsFrame = ACD:AddToBlizOptions("Item DPS", addonName["ItemDPS"], addonName)

  ACR:RegisterOptionsTable(addonName, mainPanel, false)
	ACR:RegisterOptionsTable("Tooltip options", tooltipPanel, false)
  ACR:RegisterOptionsTable("Item DPS", itemDPSPanel, false)
end

-------------------
-- Tooltip hooks --
-------------------

-- Spells
GameTooltip:HookScript("OnTooltipSetSpell", function (...) MoreTooltipInfo.ManageTooltips("spell", "default", ...) end)
hooksecurefunc(GameTooltip, "SetUnitBuff", function (...) MoreTooltipInfo.ManageTooltips("spell", "buff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitDebuff", function (...) MoreTooltipInfo.ManageTooltips("spell", "debuff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitAura", function (...) MoreTooltipInfo.ManageTooltips("spell", "aura", ...) end)
hooksecurefunc(GameTooltip, "SetConduit", function (...) MoreTooltipInfo.ManageTooltips("spell", "conduit", ...) end)
hooksecurefunc("SetItemRef", function (...) MoreTooltipInfo.ManageTooltips("spell", "ref", ...) end)

-- Items
GameTooltip:HookScript("OnTooltipSetItem", function (...) MoreTooltipInfo.ManageTooltips("item", nil, ...) end)
ItemRefTooltip:HookScript("OnTooltipSetItem", function (...) MoreTooltipInfo.ManageTooltips("item", nil, ...) end)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", function (...) MoreTooltipInfo.ManageTooltips("item", nil, ...) end)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", function (...) MoreTooltipInfo.ManageTooltips("item", nil, ...) end)
ShoppingTooltip1:HookScript("OnTooltipSetItem", function (...) MoreTooltipInfo.ManageTooltips("item", nil, ...) end)
ShoppingTooltip2:HookScript("OnTooltipSetItem", function (...) MoreTooltipInfo.ManageTooltips("item", nil, ...) end)
GameTooltip:HookScript("OnTooltipSetUnit", function(...) MoreTooltipInfo.ManageTooltips("unit", nil, ...) end)

---------------------
--Events management -
---------------------
function f:ADDON_LOADED(event, addon)
  if addon == addonName then
    MoreTooltipInfoVars = MoreTooltipInfo:initDB(MoreTooltipInfoVars, dbDefaults)
    db = MoreTooltipInfoVars
    local playerName = UnitName("player")
    local playerRealm = GetRealmName()
    db.char[playerRealm] = db.char[playerRealm] or {}
		db.char[playerRealm][playerName] = MoreTooltipInfo:initDB(db.char[playerRealm][playerName], charDefaults)
		cfg = db.char[playerRealm][playerName]
    self:CreateOptions()
  end
end
