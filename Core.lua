local addonName, MII = ...;

MoreItemInfo = MII

MoreItemInfo.Enum = {}
MoreItemInfo.Enum.Hotfixes = {}

local function tooltipLine(tooltip, id, type)
  tooltip:AddDoubleLine(type, "|cffffffff" .. id)
  tooltip:Show()
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
  
  if MoreItemInfo.Enum.RPPM[itemID] ~= nil then
    if MoreItemInfo.Enum.Hotfixes.RPPM[itemID] ~= nil then
      tooltipLine(self, MoreItemInfo.Enum.Hotfixes.RPPM[itemID], "RPPM")
    else
      tooltipLine(self, MoreItemInfo.Enum.RPPM[itemID], "RPPM")
    end
  end
  
end

GameTooltip:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefTooltip:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", itemTooltipOverride)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", itemTooltipOverride)
ShoppingTooltip1:HookScript("OnTooltipSetItem", itemTooltipOverride)
ShoppingTooltip2:HookScript("OnTooltipSetItem", itemTooltipOverride)