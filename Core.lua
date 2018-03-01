local addonName, MII = ...;

MoreItemInfo = MII

MoreItemInfo.Enum = {}

local function TooltipLine(tooltip, info, infoType)
  tooltip:AddDoubleLine(infoType .. ":", "|cffffffff" .. info)
  tooltip:Show()
end

local function GetSpecID()
  -- Spec Info
	local globalSpecID
	local specId = GetSpecialization()
	if specId then
		globalSpecID = GetSpecializationInfo(specId)
	end
	return globalSpecID
end

local function GetRace()
	-- Race info
	local _, playerRace = UnitRace('player')
  
  return playerRace
end

local function GetClassID()
	-- Class info
	local _, _, playerRace = UnitClass('player')
  
  return playerRace
end

local function GetHastePct()
  return GetHaste()
end

local function GetCritPct()
  return GetCritChance()
end

local function GetIDFromLink(linktype,Link)
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

local function GetItemSpellID(itemID)
  if MoreItemInfo.Enum.ItemSpell[itemID] ~= nil then
    return MoreItemInfo.Enum.ItemSpell[itemID]
  else
    return nil
  end
end

local function GetRPPM(spellID)
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

local function RPPMTooltip(destination, spellID)
  if spellID ~= nil then
    local rppm = GetRPPM(spellID)
    if rppm ~= nil then
      TooltipLine(destination, rppm, "RPPM")
    end
  end
end

local function ItemTooltipOverride(self)
  local itemLink = select(2, self:GetItem())
  if itemLink then
    local itemID = GetIDFromLink("item",itemLink)
    if itemID then
      TooltipLine(self, itemID, "ItemID")
      
      RPPMTooltip(self, GetItemSpellID(itemID))
    end
  end
end

local function SpellTooltipOverride(option, self, ...)
  local spellID
  
  if option == "default" then
    spellID = select(3, self:GetSpell())
  elseif option == "aura" then
    spellID = select(11, UnitAura(...))
  elseif option == "buff" then
    spellID = select(11, UnitBuff(...)) 
  elseif option == "debuff" then
    spellID = select(11, UnitDebuff(...))   
  elseif option == "ref" then
    spellID = GetIDFromLink("spell", self)
    self = ItemRefTooltip
  end
  
  if spellID ~= nil then
    TooltipLine(self, spellID, "SpellID")
    
    RPPMTooltip(self, spellID)
  end

end

local function ArtifactTooltipOverride(self, artifactPowerID)
  local powerInfo = C_ArtifactUI.GetPowerInfo(artifactPowerID)
  local spellID = powerInfo.spellID
  
  if artifactPowerID then 
    TooltipLine(self, artifactPowerID, "ArtifactPowerID") 
  end
  
  if spellID then 
    TooltipLine(self, spellID, "SpellID")
    
    RPPMTooltip(self, spellID)
  end
end

local function ManageTooltips(tooltipType, option, ...)
  -- print(tooltipType, option)
  if tooltipType == "artifact" then
    ArtifactTooltipOverride(...)
  elseif tooltipType =="spell" then
    SpellTooltipOverride(option, ...)
  elseif tooltipType =="item" then
    ItemTooltipOverride(...)
  end
end

-- Artifacts
hooksecurefunc(GameTooltip, "SetArtifactPowerByID", function (...) ManageTooltips("artifact", nil, ...) end)

-- Spells
GameTooltip:HookScript("OnTooltipSetSpell", function (...) ManageTooltips("spell", "default", ...) end)
hooksecurefunc(GameTooltip, "SetUnitBuff", function (...) ManageTooltips("spell", "buff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitDebuff", function (...) ManageTooltips("spell", "debuff", ...) end)
hooksecurefunc(GameTooltip, "SetUnitAura", function (...) ManageTooltips("spell", "aura", ...) end)
hooksecurefunc("SetItemRef", function (...) ManageTooltips("spell", "ref", ...) end)

-- Items
GameTooltip:HookScript("OnTooltipSetItem", function (...) ManageTooltips("item", nil, ...) end)
ItemRefTooltip:HookScript("OnTooltipSetItem", function (...) ManageTooltips("item", nil, ...) end)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", function (...) ManageTooltips("item", nil, ...) end)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", function (...) ManageTooltips("item", nil, ...) end)
ShoppingTooltip1:HookScript("OnTooltipSetItem", function (...) ManageTooltips("item", nil, ...) end)
ShoppingTooltip2:HookScript("OnTooltipSetItem", function (...) ManageTooltips("item", nil, ...) end)
GameTooltip:HookScript("OnTooltipSetUnit", function(...) ManageTooltips("unit", nil, ...) end)
