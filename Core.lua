local addonName, MII = ...;

MoreItemInfo = MII

MoreItemInfo.Enum = {}
MoreItemInfo.Enum.Hotfixes = {}

local function tooltipLine(tooltip, id, type)
  tooltip:AddDoubleLine(type, "|cffffffff" .. id)
  tooltip:Show()
end

local function getSpecID()
	local globalSpecID
	local specId = GetSpecialization()
	if specId then
		globalSpecID = GetSpecializationInfo(specId)
	end
	return globalSpecID
end

local function getRPPM(itemID)
  local rppmtable = {}

  if MoreItemInfo.Enum.RPPM[itemID] ~= nil then
    if MoreItemInfo.Enum.Hotfixes.RPPM[itemID] ~= nil then
      rppmtable = MoreItemInfo.Enum.Hotfixes.RPPM[itemID]
    else
      rppmtable = MoreItemInfo.Enum.RPPM[itemID]
    end
  else
    return nil
  end
  
  local specID = getSpecID()
  if rppmtable[specID] ~= nil then
    return rppmtable[specID]
  else
    return rppmtable[0]
  end
end

local function itemTooltipOverride(self)
  local itemLink = select(2, self:GetItem())
  local itemString = string.match(itemLink, "item:([%-?%d:]+)")
	local itemSplit = {}

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

GameTooltip:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefTooltip:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", itemTooltipOverride)
ShoppingTooltip1:HookScript("OnTooltipSetItem", itemTooltipOverride)
ShoppingTooltip2:HookScript("OnTooltipSetItem", itemTooltipOverride)