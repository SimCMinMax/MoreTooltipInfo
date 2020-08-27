local addonName, MII = ...;

MoreTooltipInfo = MII

MoreTooltipInfo.Enum = {}

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
    if itemlevel and specID and classID and itemData then
      if itemData[classID][specID][itemlevel] then
        dps = MoreTooltipInfo.FormatSpace(itemData[classID][specID][itemlevel])
      end
    end
  end

  return dps
end

function MoreTooltipInfo.RPPMTooltip(destination, spellID)
  if spellID then
    local rppm = MoreTooltipInfo.GetRPPM(spellID)
    if rppm then
      MoreTooltipInfo.TooltipLine(destination, rppm, "RPPM")
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
      MoreTooltipInfo.TooltipLine(self, itemID, "Item ID")
      
      local spellID = MoreTooltipInfo.GetItemSpellID(itemID)
      if spellID then
        MoreTooltipInfo.TooltipLine(self, spellID, "Spell ID")
        MoreTooltipInfo.RPPMTooltip(self, spellID)
      end    

      MoreTooltipInfo.DPSTooltip(self, itemID) 
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
  elseif option == "azerite" then
    spellID = select(3, ...)      
  elseif option == "conduit" then
    local conduitID = select(1, ...)
    --get spell id from game file
    --print(select(1, ...),select(2, ...))
    spellID = MoreTooltipInfo.GetConduitSpellID(select(1, ...))   
  elseif option == "ref" then
    spellID = MoreTooltipInfo.GetIDFromLink("spell", self)
    self = ItemRefTooltip
  end
  
  if spellID then
    MoreTooltipInfo.TooltipLine(self, spellID, "Spell ID")
    MoreTooltipInfo.RPPMTooltip(self, spellID)
    MoreTooltipInfo.GCDTooltip(self, spellID)
    if option == "azerite" then
      MoreTooltipInfo.AzeritePowerTooltip(self, spellID)
    end
    if option == "conduit" then
      MoreTooltipInfo.TooltipLine(self, select(1, ...), "ConduitID")
      MoreTooltipInfo.TooltipLine(self, select(2, ...), "ConduitRank")
    end
    local enchantID = MoreTooltipInfo.Enum.SpellEnchants[spellID]
    if enchantID then --echant, we put enchant id and rppm
      MoreTooltipInfo.TooltipLine(self, enchantID, "Enchant Spell ID")
      MoreTooltipInfo.RPPMTooltip(self, enchantID)
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

-------------------
-- Tooltip hooks --
-------------------

-- Spells
GameTooltip:HookScript("OnTooltipSetSpell", function (...) MoreTooltipInfo.ManageTooltips("spell", "default", ...) end)
hooksecurefunc(GameTooltip, "SetUnitBuff", function (...) MoreTooltipInfo.ManageTooltips("spell", "buff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitDebuff", function (...) MoreTooltipInfo.ManageTooltips("spell", "debuff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitAura", function (...) MoreTooltipInfo.ManageTooltips("spell", "aura", ...) end)
hooksecurefunc(GameTooltip, "SetAzeritePower", function (...) MoreTooltipInfo.ManageTooltips("spell", "azerite", ...) end)
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
