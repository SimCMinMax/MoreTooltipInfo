local addonName, MII = ...;

MoreItemInfo = MII

MoreItemInfo.Enum = {}

local function tooltipLine(tooltip, info, infoType)
  tooltip:AddDoubleLine(infoType, "|cffffffff" .. info)
  tooltip:Show()
end

local function getSpecID()
  -- Spec Info
	local globalSpecID
	local specId = GetSpecialization()
	if specId then
		globalSpecID = GetSpecializationInfo(specId)
	end
	return globalSpecID
end

local function getRace()
	-- Race info
	local _, playerRace = UnitRace('player')
  
  return playerRace
end

local function getClassID()
	-- Class info
	local _, _, playerRace = UnitClass('player')
  
  return playerRace
end

local function getHaste()
  return UnitSpellHaste('player')
end

local function getRPPM(itemID)
  local rppmtable = {}
  if MoreItemInfo.Enum.RPPM[itemID] ~= nil then
    rppmtable = MoreItemInfo.Enum.RPPM[itemID]
  else
    return nil
  end
  
  local specID = getSpecID()
  local classID = getClassID()
  local race = getRace()
  
  local baseRPPM = rppmtable[0]
  
  local modHaste = false
  if rppmtable["HASTE"] ~= nil then
    modHaste = true
  end
  local modCrit = false
  if rppmtable["CRIT"] ~= nil then
    modCrit = true
  end
  
  local modRace = nil
  if rppmtable["RACE"] ~= nil then
    if rppmtable["RACE"][race] ~= nil then
      modRace = rppmtable["RACE"][race]
    end
  end
  
  local modClass = nil
  if rppmtable["CLASS"] ~= nil then
    if rppmtable["CLASS"][classID] ~= nil then
      modClass = rppmtable["CLASS"][classID]
    end
  end
  
  local modSpec = nil
  if rppmtable["SPEC"] ~= nil then
    if rppmtable["SPEC"][specID] ~= nil then
      modSpec = rppmtable["SPEC"][bspecID]
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
    local currentHasteRating = GetHaste()
    local hastedRPPM = rppmString + rppmString * (currentHasteRating / 100)
    
    rppmString = rppmString .. " (Hasted : " .. string.format("%.4f", hastedRPPM) ..")"
  elseif modCrit then
    rppmString = rppmString .. " (Crit)"
  end
  
  return rppmString
end

local function itemTooltipOverride(self)
  local itemLink = select(2, self:GetItem())
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
    
    local rppm = getRPPM(itemID)
    if rppm ~= nil then
      tooltipLine(self, getRPPM(itemID), "RPPM")
    end
  end
end

GameTooltip:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefTooltip:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", itemTooltipOverride)
ShoppingTooltip1:HookScript("OnTooltipSetItem", itemTooltipOverride)
ShoppingTooltip2:HookScript("OnTooltipSetItem", itemTooltipOverride)