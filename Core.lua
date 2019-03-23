local addonName, MII = ...;

MoreItemInfo = MII

MoreItemInfo.Enum = {}

function MoreItemInfo.TooltipLine(tooltip, info, infoType)
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

function MoreItemInfo.FormatSpace(number)
  local formatted = number

  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
    if (k == 0) then
      return formatted
    end
  end
end

function MoreItemInfo.GetSpecID()
  -- Spec Info
	local globalSpecID
	local specId = GetSpecialization()
	if specId then
		globalSpecID = GetSpecializationInfo(specId)
	end
	return tonumber(globalSpecID)
end

function MoreItemInfo.GetRace()
	-- Race info
	local _, playerRace = UnitRace('player')
  
  return tonumber(playerRace)
end

function MoreItemInfo.GetClassID()
	-- Class info
	local _, _, playerRace = UnitClass('player')
  
  return tonumber(playerRace)
end

function MoreItemInfo.GetHastePct()
  return GetHaste()
end

function MoreItemInfo.GetCritPct()
  return GetCritChance()
end

function MoreItemInfo.GetIDFromLink(linktype,Link)
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

function MoreItemInfo.GetItemLevelFromTooltip(tooltip)
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

function MoreItemInfo.GetItemSpellID(itemID)
  local spellID = MoreItemInfo.Enum.ItemSpell[itemID]
  if spellID then
    return spellID
  end
end

function MoreItemInfo.GetRPPM(spellID)
  local rppmtable = MoreItemInfo.Enum.RPPM[spellID]
  if not rppmtable then
    return nil
  end
  
  local specID = MoreItemInfo.GetSpecID()
  local classID = MoreItemInfo.GetClassID()
  local race = MoreItemInfo.GetRace()
  
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
    local currentHasteRating = MoreItemInfo.GetHastePct()
    local hastedRPPM = rppmString * (1 + (currentHasteRating / 100))
    rppmString = rppmString .. " (Hasted : " .. string.format("%.4f", hastedRPPM) ..")"
  elseif modCrit then
    local currentCritRating = MoreItemInfo.GetCritPct()
    local critRPPM = rppmString * (1 + (currentCritRating / 100))
    rppmString = rppmString .. " (Crit : " .. string.format("%.4f", critRPPM) ..")"
  end
  
  return rppmString
end

function MoreItemInfo.GetGCD(spellID)
  local gcd = 0
  if MoreItemInfo.Enum.TriggerGCD[spellID] ~= nil then
    gcd = MoreItemInfo.Enum.TriggerGCD[spellID]
  else
    return nil
  end
  return gcd
end

function MoreItemInfo.GetDPS(itemID,tooltip)
  local dps
  local specID = MoreItemInfo.GetSpecID()
  local classID = MoreItemInfo.GetClassID()

  if MoreItemInfo.Enum.ItemDPS[itemID] then
    local itemData = MoreItemInfo.Enum.ItemDPS[itemID]
    local itemlevel = MoreItemInfo.GetItemLevelFromTooltip(tooltip)
    if itemlevel and specID and classID and itemData then
      if itemData[classID][specID][itemlevel] then
        dps = MoreItemInfo.FormatSpace(itemData[classID][specID][itemlevel])
      end
    end
  end

  return dps
end

function MoreItemInfo.RPPMTooltip(destination, spellID)
  if spellID then
    local rppm = MoreItemInfo.GetRPPM(spellID)
    if rppm then
      MoreItemInfo.TooltipLine(destination, rppm, "RPPM")
    end
  end
end

function MoreItemInfo.GCDTooltip(destination, spellID)
  if spellID then
    local gcd = MoreItemInfo.GetGCD(spellID)
    if gcd then
      gcd = gcd / 1000
      MoreItemInfo.TooltipLine(destination, gcd, "GCD")
    end
  end
end

function MoreItemInfo.DPSTooltip(destination, itemID)
  if itemID then
    local dps = MoreItemInfo.GetDPS(itemID,destination)
    if dps then
      MoreItemInfo.TooltipLine(destination, dps, "simDPS")
    end
  end
end

function MoreItemInfo.AzeritePowerTooltip(destination, azeritePowerID)
  if azeritePowerID then
    MoreItemInfo.TooltipLine(destination, azeritePowerID, "Azerite Power ID")
  end
end

function MoreItemInfo.ItemTooltipOverride(self)
  local itemLink = select(2, self:GetItem())
  if itemLink then
    local itemID = tonumber(MoreItemInfo.GetIDFromLink("item",itemLink))
    if itemID then
      MoreItemInfo.TooltipLine(self, itemID, "Item ID")
      
      local spellID = MoreItemInfo.GetItemSpellID(itemID)
      if spellID then
        MoreItemInfo.TooltipLine(self, spellID, "Spell ID")
        MoreItemInfo.RPPMTooltip(self, spellID)
      end    

      MoreItemInfo.DPSTooltip(self, itemID) 
    end
  end
end

function MoreItemInfo.SpellTooltipOverride(option, self, ...)
  local spellID
  
  if option == "default" then
    spellID = select(2, self:GetSpell())
  elseif option == "aura" then
    spellID = select(10, UnitAura(...))
  elseif option == "buff" then
    spellID = select(10, UnitBuff(...)) 
  elseif option == "debuff" then
    spellID = select(10, UnitDebuff(...))  
  elseif option == "azerite" then
    spellID = select(3, ...)      
  elseif option == "ref" then
    spellID = MoreItemInfo.GetIDFromLink("spell", self)
    self = ItemRefTooltip
  end
  
  if spellID then
    MoreItemInfo.TooltipLine(self, spellID, "Spell ID")
    MoreItemInfo.RPPMTooltip(self, spellID)
    MoreItemInfo.GCDTooltip(self, spellID)
    if option == "azerite" then
      MoreItemInfo.AzeritePowerTooltip(self, spellID)
    end
    local enchantID = MoreItemInfo.Enum.SpellEnchants[spellID]
    if enchantID then --echant, we put enchant id and rppm
      MoreItemInfo.TooltipLine(self, enchantID, "Enchant Spell ID")
      MoreItemInfo.RPPMTooltip(self, enchantID)
    end
  end
end

function MoreItemInfo.ManageTooltips(tooltipType, option, ...)
  -- print(tooltipType, option)
  if tooltipType =="spell" then
    MoreItemInfo.SpellTooltipOverride(option, ...)
  elseif tooltipType =="item" then
    MoreItemInfo.ItemTooltipOverride(...)
  end
end

-------------------
-- Tooltip hooks --
-------------------

-- Spells
GameTooltip:HookScript("OnTooltipSetSpell", function (...) MoreItemInfo.ManageTooltips("spell", "default", ...) end)
hooksecurefunc(GameTooltip, "SetUnitBuff", function (...) MoreItemInfo.ManageTooltips("spell", "buff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitDebuff", function (...) MoreItemInfo.ManageTooltips("spell", "debuff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitAura", function (...) MoreItemInfo.ManageTooltips("spell", "aura", ...) end)
hooksecurefunc(GameTooltip, "SetAzeritePower", function (...) MoreItemInfo.ManageTooltips("spell", "azerite", ...) end)
hooksecurefunc("SetItemRef", function (...) MoreItemInfo.ManageTooltips("spell", "ref", ...) end)

-- Items
GameTooltip:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ItemRefTooltip:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ShoppingTooltip1:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ShoppingTooltip2:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
GameTooltip:HookScript("OnTooltipSetUnit", function(...) MoreItemInfo.ManageTooltips("unit", nil, ...) end)
