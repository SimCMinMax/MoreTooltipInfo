local addonName, MII = ...;

MoreItemInfo = MII

MoreItemInfo.Enum = {}

MoreItemInfo.SettingsLoaded = false
MoreItemInfo.UserSettings = {}

function MoreItemInfo.MergeTables(defaultTable, settingsTable, destinationTable)
	for k,v in pairs(defaultTable) do
		if settingsTable[k] == nil then
			destinationTable[k] = v
		else
			destinationTable[k] = settingsTable[k]
		end
	end
	return destinationTable
end

function MoreItemInfo.HandleSettings()
  if not MoreItemInfo.SettingsLoaded then
    if not MoreItemInfoVars then MoreItemInfoVars = {} end
    MoreItemInfo.MergeTables(MoreItemInfo.Settings,MoreItemInfoVars,MoreItemInfo.UserSettings)
    MoreItemInfo.SettingsLoaded = true
  end
end

function MoreItemInfo.TooltipLine(tooltip, info, infoType)
  local found = false

  -- Check if we already added to this tooltip. Happens on the talent frame
  for i = 1,15 do
    local frame = _G[tooltip:GetName() .. "TextLeft" .. i]
    local text
    if frame then text = frame:GetText() end
    if text and text == infoType then found = true break end
  end

  if not found then
    tooltip:AddDoubleLine(infoType, "|cffffffff" .. info)
    tooltip:Show()
  end
end

function MoreItemInfo.GetSpecID()
  -- Spec Info
	local globalSpecID
	local specId = GetSpecialization()
	if specId then
		globalSpecID = GetSpecializationInfo(specId)
	end
	return globalSpecID
end

function MoreItemInfo.GetRace()
	-- Race info
	local _, playerRace = UnitRace('player')
  
  return playerRace
end

function MoreItemInfo.GetClassID()
	-- Class info
	local _, _, playerRace = UnitClass('player')
  
  return playerRace
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

function MoreItemInfo.GetItemSpellID(itemID)
  if MoreItemInfo.Enum.ItemSpell[itemID] ~= nil then
    return MoreItemInfo.Enum.ItemSpell[itemID]
  else
    return nil
  end
end

function MoreItemInfo.GetRPPM(spellID)
  local rppmtable = {}
  if MoreItemInfo.Enum.RPPM[spellID] ~= nil then
    rppmtable = MoreItemInfo.Enum.RPPM[spellID]
  else
    return nil
  end
  
  local specID = GetSpecID()
  local classID = GetClassID()
  local race = GetRace()
  
  local baseRPPM = rppmtable[0]
  
  local modHaste = false
  if rppmtable[1] ~= nil then
    modHaste = true
  end
  local modCrit = false
  if rppmtable[2] ~= nil then
    modCrit = true
  end
  
  local modRace = nil
  if rppmtable[5] ~= nil then
    if rppmtable[5][race] ~= nil then
      modRace = rppmtable[5][race]
    end
  end
  
  local modClass = nil
  if rppmtable[3] ~= nil then
    if rppmtable[3][classID] ~= nil then
      modClass = rppmtable[3][classID]
    end
  end
  
  local modSpec = nil
  if rppmtable[4] ~= nil then
    if rppmtable[4][specID] ~= nil then
      modSpec = rppmtable[4][bspecID]
    end
  end
    
  local rppmString = ""
  
  if modRace ~= nil then
    rppmString = modRace
  elseif modClass~= nil then
    rppmString = modClass
  elseif modSpec~= nil then
    rppmString = modSpec
  else
    rppmString = baseRPPM
  end
  if modHaste then
    local currentHasteRating = GetHastePct()
    local hastedRPPM = rppmString * (1 + (currentHasteRating / 100))
    rppmString = rppmString .. " (Hasted : " .. string.format("%.4f", hastedRPPM) ..")"
  elseif modCrit then
    local currentCritRating = GetCritPct()
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

function MoreItemInfo.RPPMTooltip(destination, spellID)
  if spellID ~= nil then
    local rppm = MoreItemInfo.GetRPPM(spellID)
    if rppm ~= nil then
      MoreItemInfo.TooltipLine(destination, rppm, "RPPM")
    end
  end
end

function MoreItemInfo.GCDTooltip(destination, spellID)
  if spellID ~= nil then
    local gcd = MoreItemInfo.GetGCD(spellID)
    if gcd ~= nil then
      gcd = gcd / 1000
      MoreItemInfo.TooltipLine(destination, gcd, "GCD")
    end
  end
end

function MoreItemInfo.ItemTooltipOverride(self)
  local itemLink = select(2, self:GetItem())
  if itemLink then
    local itemID = MoreItemInfo.GetIDFromLink("item",itemLink)
    if itemID then
      MoreItemInfo.TooltipLine(self, itemID, "ItemID")
      
      local spellID = MoreItemInfo.GetItemSpellID(itemID)
      if spellID then
        MoreItemInfo.TooltipLine(self, spellID, "SpellID")
        MoreItemInfo.RPPMTooltip(self, spellID)
      end     
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
  
  if spellID ~= nil then
    MoreItemInfo.TooltipLine(self, spellID, "SpellID")
    MoreItemInfo.RPPMTooltip(self, spellID)
    MoreItemInfo.GCDTooltip(self, spellID)
  end

end

function MoreItemInfo.ArtifactTooltipOverride(self, artifactPowerID)
  local powerInfo = C_ArtifactUI.GetPowerInfo(artifactPowerID)
  local spellID = powerInfo.spellID
  
  if artifactPowerID then 
    MoreItemInfo.TooltipLine(self, artifactPowerID, "ArtifactPowerID")
  end
  
  if spellID then 
    MoreItemInfo.TooltipLine(self, spellID, "SpellID")
    MoreItemInfo.RPPMTooltip(self, spellID)
    MoreItemInfo.GCDTooltip(self, spellID)
  end
end

function MoreItemInfo.ManageTooltips(tooltipType, option, ...)
  -- HandleSettings()
  -- print(tooltipType, option)
  if tooltipType == "artifact" then
    MoreItemInfo.ArtifactTooltipOverride(...)
  elseif tooltipType =="spell" then
    MoreItemInfo.SpellTooltipOverride(option, ...)
  elseif tooltipType =="item" then
    MoreItemInfo.ItemTooltipOverride(...)
  end
end

-- Load Settings
-- local eventFrame = CreateFrame("Frame")
-- eventFrame:RegisterEvent("ADDON_LOADED")
-- eventFrame:SetScript("OnEvent", function(self, event, ...)
--   if event == "ADDON_LOADED" then
--     if not MoreItemInfo.SettingsLoaded then
--       MoreItemInfo.HandleSettings()
--       MoreItemInfo.CreateSettings()
--     end
--   end
-- end)

-- Spells
GameTooltip:HookScript("OnTooltipSetSpell", function (...) MoreItemInfo.ManageTooltips("spell", "default", ...) end)
hooksecurefunc(GameTooltip, "SetUnitBuff", function (...) MoreItemInfo.ManageTooltips("spell", "buff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitDebuff", function (...) MoreItemInfo.ManageTooltips("spell", "debuff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitAura", function (...) MoreItemInfo.ManageTooltips("spell", "aura", ...) end)
hooksecurefunc(GameTooltip, "SetAzeritePowerBySpellID", function (...) MoreItemInfo.ManageTooltips("spell", "azerite", ...) end)
-- hooksecurefunc(GameTooltip, "SetTalent", function (...) MoreItemInfo.ManageTooltips("spell", "talent", ...) end)
hooksecurefunc(GameTooltip, "SetArtifactPowerByID", function (...) MoreItemInfo.ManageTooltips("artifact", nil, ...) end)

hooksecurefunc("SetItemRef", function (...) MoreItemInfo.ManageTooltips("spell", "ref", ...) end)

-- Items
GameTooltip:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ItemRefTooltip:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ShoppingTooltip1:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
ShoppingTooltip2:HookScript("OnTooltipSetItem", function (...) MoreItemInfo.ManageTooltips("item", nil, ...) end)
GameTooltip:HookScript("OnTooltipSetUnit", function(...) MoreItemInfo.ManageTooltips("unit", nil, ...) end)
