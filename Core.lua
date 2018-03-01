local addonName, MII = ...;

MoreItemInfo = MII

MoreItemInfo.Enum = {}

local function TooltipLine(tooltip, info, infoType)
  tooltip:AddDoubleLine(infoType, "|cffffffff" .. info)
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

local function GetSpellID(itemID)
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

local function ItemTooltipOverride(self)
  local itemLink = select(2, self:GetItem())
  if itemLink then
    local itemString = string.match(itemLink, "item:([%-?%d:]+)")
    local itemSplit = {}
    
    if itemString then
      -- Split data into a table
      for v in string.gmatch(itemString, "(%d*:?)") do
        if v == ":" then
          itemSplit[#itemSplit + 1] = 0
        else
          itemSplit[#itemSplit + 1] = string.gsub(v, ':', '')
        end
      end

      local itemID = tonumber(itemSplit[1])
      local spellID = GetSpellID(itemID)
      if spellID ~= nil then
        local rppm = GetRPPM(spellID)
        if rppm ~= nil then
          TooltipLine(self, rppm, "RPPM")
        end
      end
    end
  end
end

local function SpellTooltipOverride(self)
  local spellID = select(3, self:GetSpell())
  if spellID ~= nil then
    local rppm = GetRPPM(spellID)
    if rppm ~= nil then
      TooltipLine(self, rppm, "RPPM")
    end
  end
end

local function ArtifactTooltipOverride(self,powerID)
  local powerInfo = C_ArtifactUI.GetPowerInfo(powerID)
  local spellID = powerInfo.spellID
  if powerID then TooltipLine(self, powerID, "ArtifactPowerID") end
  if spellID then 
    local rppm = GetRPPM(spellID)
    if rppm ~= nil then
      TooltipLine(self, rppm, "RPPM")
    end 
  end
end

hooksecurefunc(GameTooltip, "SetArtifactPowerByID", ArtifactTooltipOverride)
GameTooltip:HookScript("OnTooltipSetSpell", SpellTooltipOverride)
GameTooltip:HookScript("OnTooltipSetItem", ItemTooltipOverride)
ItemRefTooltip:HookScript("OnTooltipSetItem", ItemTooltipOverride)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", ItemTooltipOverride)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", ItemTooltipOverride)
ShoppingTooltip1:HookScript("OnTooltipSetItem", ItemTooltipOverride)
ShoppingTooltip2:HookScript("OnTooltipSetItem", ItemTooltipOverride)