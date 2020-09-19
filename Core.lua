local addonName, MTI = ...;
MoreTooltipInfo = MTI
MoreTooltipInfo.Enum = {}

local _G = _G
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local IUI = LibStub("LibItemUpgradeInfo-1.0")
local AGUI= LibStub("AceGUI-3.0")

local dataVersion = "9.0.2.35854"
local dataDate = "2020-09-10_08:47"

local cfg
local profiles
local dbDefaults = {
  char = {},
  profiles = {},
}
local charDefaults = { 
  enableSpellID = true,
  enableSpellRPPM = true,
  enableSpellGCD = true,
  enableSpellTalentID = true,
  enableItemID = true,
  enableItemSpellID = true,
  enableItemRPPM = true,
  enableItemBonusID = true,
  enableItemGemID = true,
  enableItemEnchantID = true,
  enableItemEnchantSpellID = true,
  enableItemEnchantSpellRPPM = true,
  enableBaseItemDPS = true,
  enableBaseTalentDPS = true,
  enableBestTalentDPS = true,
  enableSoulbindID = true,
  enableConduitID = true,
  enableConduitSpellID = true,
  enableConduitRank = true
}
local profileDefaults = { 
  trinket = {},
  soulbind={},
  conduit={},
  legendary={},
  talent={}
}
local UIElements={
  mainframe,
  mainGroup,
  scroll1,
  tableLabel={},
  spacerTable={},
  detailsGroup,
  scroll2,
  titleLabel,
  renameButton,
  deleteButton,
  importButton,
  typeDropdown,
  enablecheckbox,
  colorpicker,
}
local UIParameters={
	--Consts
	OFFSET_ITEM_ID 		= 1,
	OFFSET_ENCHANT_ID = 2,
	OFFSET_GEM_ID_1 	= 3,
	OFFSET_GEM_ID_2 	= 4,
	OFFSET_GEM_ID_3 	= 5,
	OFFSET_GEM_ID_4 	= 6,
	OFFSET_SUFFIX_ID 	= 7,
	OFFSET_FLAGS 		  = 11,
	OFFSET_BONUS_ID 	= 13,
  
  detailsLoaded=false,
  detailsDrawn=false,
  mainframeCreated=false,
  currentProfile="",
  currentType="trinket",
  currentTypeIndex=1,
  currentClassID=0,
  currentSpecID=0,
  availableOption = {
		[1] = "trinket",
		[2] = "talent"
  }
}

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)
f:RegisterEvent("ADDON_LOADED")

-- Command UI
SLASH_MORETOOLTIPINFOSLASH1 = "/mti"
SlashCmdList["MORETOOLTIPINFOSLASH"] = function (arg)
	if UIParameters.mainframeCreated and UIElements.mainframe:IsShown() then
		UIElements.mainframe:Hide()
	else		
		OpenProfileUI()
		UIParameters.mainframeCreated = true
	end
end

function MoreTooltipInfo.TooltipLine(tooltip, info, infoType, textColor)
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
    local color = "ffffffff"
    if textColor ~= nil then color = textColor end
    tooltip:AddDoubleLine(infoType, "|c" .. color .. info)
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

  for index=1, itemSplit[UIParameters.OFFSET_BONUS_ID] do
    bonuses[#bonuses + 1] = itemSplit[UIParameters.OFFSET_BONUS_ID + index]
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
    for index=1, gemSplit[UIParameters.OFFSET_BONUS_ID] do
      bonuses[#bonuses + 1] = gemSplit[UIParameters.OFFSET_BONUS_ID + index]
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

  for gemOffset = UIParameters.OFFSET_GEM_ID_1, UIParameters.OFFSET_GEM_ID_4 do
    local gemIndex = (gemOffset - UIParameters.OFFSET_GEM_ID_1) + 1
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

function MoreTooltipInfo.GetDPS(itemLink,itemID,tooltip)
  local dps
  local specID = MoreTooltipInfo.GetSpecID()
  local classID = MoreTooltipInfo.GetClassID()
  if MoreTooltipInfo.Enum.ItemDPS[itemID] then
    local itemData = MoreTooltipInfo.Enum.ItemDPS[itemID]
    local itemlevel = IUI:GetUpgradedItemLevel(itemLink) or 0
    if itemlevel and specID and classID then
      if itemData[classID] and itemData[classID][specID] and itemData[classID][specID][itemlevel] then
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

function MoreTooltipInfo.ItemDPSTooltip(destination, itemLink, itemID, personnalData)
  if itemID then
    local _, _, itemRarity, _, _, _, _, _, itemEquipLoc, _, _ = GetItemInfo(itemLink)
    local InfoType
    local specID = MoreTooltipInfo.GetSpecID()
    local classID = MoreTooltipInfo.GetClassID()

    if itemEquipLoc == "INVTYPE_TRINKET" then --trinkets
      InfoType = "trinket"
      if not personnalData then
        local dps = MoreTooltipInfo.GetDPS(itemLink, itemID, destination)
        if dps then
          MoreTooltipInfo.TooltipLine(destination, dps, "Base simDPS")
        end
      else --check profiles
        
        local itemlevel = IUI:GetUpgradedItemLevel(itemLink) or 0
        if profiles[InfoType][classID] == nil then return end
        if profiles[InfoType][classID][specID] == nil then return end
        for i, v in pairs(profiles[InfoType][classID][specID]) do
          if v["enable"] and v["data"] and v["data"][itemID] and v["data"][itemID][itemlevel] then
            dps = MoreTooltipInfo.FormatSpace(v["data"][itemID][itemlevel])
            MoreTooltipInfo.TooltipLine(destination, dps, i, v["color"])
          end
        end
      end
    elseif itemRarity == 5 then --legendaries
      InfoType = "legendary"
    end
  end
end

function MoreTooltipInfo.SpellDPSTooltip(destination, spellID, personnalData)
  if spellID then
    local InfoType = "talent"
    local specID = MoreTooltipInfo.GetSpecID()
    local classID = MoreTooltipInfo.GetClassID()

    if profiles[InfoType][classID] == nil then return end
    if profiles[InfoType][classID][specID] == nil then return end
    for i, v in pairs(profiles[InfoType][classID][specID]) do
      if v["enable"] and v["data"] and v["data"][spellID] and v["data"][spellID]["Base"] then
        dps = MoreTooltipInfo.FormatSpace(v["data"][spellID]["Base"])
        MoreTooltipInfo.TooltipLine(destination, dps, i.." Base", v["color"])
      end
      if v["enable"] and v["data"] and v["data"][spellID] and v["data"][spellID]["Best"] then
        dps = MoreTooltipInfo.FormatSpace(v["data"][spellID]["Best"])
        MoreTooltipInfo.TooltipLine(destination, dps, i.." Best", v["color"])
      end
    end
  end
end

function MoreTooltipInfo.GetDefaultColor(classID)
  return MoreTooltipInfo.SpecNames[classID]["color"]
end

function MoreTooltipInfo.NewProfile(type, classID, specID, profileName, data, enable, color, string) 
  profiles[type][classID][specID][profileName] = {}
  profiles[type][classID][specID][profileName]["enable"] = enable
  profiles[type][classID][specID][profileName]["color"] = color
  profiles[type][classID][specID][profileName]["data"] = data
  profiles[type][classID][specID][profileName]["string"] = string
end

function MoreTooltipInfo.ValidateItemPersonnalData(info,value)
  -- Split data into a table
  local stringSplit = {strsplit(":",value)}

  -- check MTI string
  if stringSplit[1] ~= "MoreTooltipInfo" then return false end

  -- check class
  if tonumber(stringSplit[2]) == 0 or tonumber(stringSplit[2]) > 12 then return false end
  local classID = tonumber(stringSplit[2])

  -- check specs
  if tonumber(stringSplit[3]) < 62 or tonumber(stringSplit[2]) > 581 then return false end
  local specID = tonumber(stringSplit[3])

  --Profile Name
  local profileName = stringSplit[4]:gsub('"', '')

  -- Split data into a table
  local dpsData = {strsplit("^",stringSplit[5])}
  
  local data = {}
  local infoType = ""
  local color = MoreTooltipInfo.GetDefaultColor(classID) .. "ff" --add alpha at the end
  if dpsData[1] == "trinket" then
    infoType = "trinket"
    -- MoreTooltipInfo:8:63:"X.com-patchwerk":trinket^[174103]125=1234;130=1250;150=9999^[174500]125=123;130=456;135=789
    if profiles[infoType][classID] == nil then profiles[infoType][classID] = {} end
    if profiles[infoType][classID][specID] == nil then profiles[infoType][classID][specID] = {} end

    for i, v in ipairs(dpsData) do
      if i ~= 1 then -- 1 is the type
        local itemID, dpsData = strsplit("]",v)
        itemID = tonumber(string.sub(itemID,2))--remove the first[
        if itemID then
          data[itemID] = {}       
          for _, w in ipairs({strsplit(";", dpsData)}) do
            local ilvl,dps = strsplit("=",w)
            data[tonumber(itemID)][tonumber(ilvl)] = tonumber(dps)
          end
        end
      end
    end
  elseif dpsData[1] == "talent" then
    infoType = "talent"
    --MoreTooltipInfo:8:64:\"X.com-patchwerk\":talent^[56377]Base=1234;Best=9999^[153595]Base=5678;Best=8888
    if profiles[infoType][classID] == nil then profiles[infoType][classID] = {} end
    if profiles[infoType][classID][specID] == nil then profiles[infoType][classID][specID] = {} end

    for i, v in ipairs(dpsData) do
      if i ~= 1 then -- 1 is the type
        local talentID, dpsData = strsplit("]",v)
        talentID = tonumber(string.sub(talentID,2))--remove the first[
        if talentID then
          data[talentID] = {}       
          for _, w in ipairs({strsplit(";", dpsData)}) do
            local talentType,dps = strsplit("=",w)
            data[tonumber(talentID)][talentType] = tonumber(dps)
          end
        end
      end
    end
  end

  if profiles[infoType][classID][specID][profileName] ~= nil then 
    local tempdata = {}
    tempdata["type"] = infoType
    tempdata["classID"] = classID
    tempdata["specID"] = specID
    tempdata["profileName"] = profileName
    tempdata["data"] = data
    tempdata["enable"] = true
    tempdata["color"] = color
    tempdata["string"] = value

    StaticPopup_Show("MTI_CONFIRM_EXISTS_POPUP","","",tempdata)
    
    return false
  end

  MoreTooltipInfo.NewProfile(infoType, classID, specID, profileName, data, true, color, value) 

  return true
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

      if cfg.enableBaseItemDPS then MoreTooltipInfo.ItemDPSTooltip(self, itemLink, itemID, false) end
      MoreTooltipInfo.ItemDPSTooltip(self, itemLink, itemID, true)
    end
  end
end

function MoreTooltipInfo.SpellTooltipOverride(option, self, ...)
  local spellID
  local talentID = 0
  
  if option == "default" then
    spellID = select(2, self:GetSpell())
    --Todo : disable when in talent tooltip to let the talent part manage itself
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
  elseif option == "talent" then
    talentID = select(1, ...)
    spellID = select(6, GetTalentInfoByID(talentID)) 
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
    if talentID > 0 then
      if cfg.enableSpellTalentID then MoreTooltipInfo.TooltipLine(self, talentID, "TalentID") end
      MoreTooltipInfo.SpellDPSTooltip(self, spellID, true)
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

StaticPopupDialogs["MTI_CONFIRM_EXISTS_POPUP"] = {
  text = "The profile %s already exists. Do you want to overwrite it?",

  button1 = "Yes",
  button2 = "No",
  OnAccept = function(self, data, data2)
    DeleteProfile(data["classID"],data["specID"],data["profileName"])
    MoreTooltipInfo.NewProfile(data["type"], data["classID"], data["specID"], data["profileName"], data["data"], data["enable"], data["color"], data["string"])
    OpenProfileUI()
  end,
  timeout = 0,
  cancels = "MTI_IMPORT_POPUP",
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

StaticPopupDialogs["MTI_EXISTS_POPUP"] = {
  text = "The profile %s already exists. ",
  button1 = "Cancel",
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

StaticPopupDialogs["MTI_RENAME_POPUP"] = {
  text = "New profile name for %s?",

  button1 = "Validate",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(UIParameters.currentProfile)
  end,
  OnAccept = function(self, data, data2)
    if profiles[UIParameters.currentType][UIParameters.currentClassID][UIParameters.currentSpecID][self.editBox:GetText()] ~= nil then   
      StaticPopup_Show("MTI_EXISTS_POPUP",self.editBox:GetText())
      return false
    end
    RenameProfile(UIParameters.currentClassID,UIParameters.currentSpecID,UIParameters.currentProfile,self.editBox:GetText())
    OpenProfileUI()
  end,
  timeout = 0,
  hasEditBox = true,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

StaticPopupDialogs["MTI_DELETE_POPUP"] = {
  text = "Are you sure you want to delete the profile %s?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function()
    DeleteProfile(UIParameters.currentClassID,UIParameters.currentSpecID,UIParameters.currentProfile)
    OpenProfileUI()
  end,
  timeout = 0,
  showAlert = true,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

StaticPopupDialogs["MTI_IMPORT_POPUP"] = {
  text = "New Profile",
  button1 = "Validate",
  button2 = "Cancel",
  OnAccept = function(self, data, data2)
    MoreTooltipInfo.ValidateItemPersonnalData("test",self.editBox:GetText())
    OpenProfileUI()
  end,
  timeout = 0,
  exclusive = true,
  hasEditBox = true,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

function DrawOptionGroup(classID, specID, profileName)
  if UIParameters.detailsLoaded then
    if not UIParameters.detailsDrawn then
      UIElements.mainframe:AddChild(UIElements.detailsGroup)
      UIParameters.detailsDrawn = true
    end
    --print("draw "..classID.." "..specID.." "..profileName)
    UIParameters.currentProfile = profileName
    UIParameters.currentClassID = classID
    UIParameters.currentSpecID = specID
    UIElements.titleLabel:SetText(profileName)
    UIElements.enablecheckbox:SetCallback("OnValueChanged", function(widget)
      if profiles[UIParameters.currentType][classID][specID][profileName]["enable"] then 
        DisableProfile(classID, specID, profileName)
      else
        EnableProfile(classID, specID, profileName)
      end
    end)
    UIElements.enablecheckbox:SetValue(profiles[UIParameters.currentType][classID][specID][profileName]["enable"])
    local r,g,b = hex2rgb(profiles[UIParameters.currentType][classID][specID][profileName]["color"])
    UIElements.colorpicker:SetColor(r/255,g/255,b/255,1)
  else
    print("settings not loaded")
  end
end

function RenameProfile(classID, specID, profileName, newName)
  --print("rename "..classID.." "..specID.." "..profileName.." to "..newName)
  profiles[UIParameters.currentType][classID][specID][newName] = profiles[UIParameters.currentType][classID][specID][profileName];
  profiles[UIParameters.currentType][classID][specID][profileName] = nil
end

function DeleteProfile(classID, specID, profileName)
  --print("delete "..classID.." "..specID.." "..profileName)
  profiles[UIParameters.currentType][classID][specID][profileName] = nil

  --clean Empty tables
  local profilesCountClass = 0
  local profilesCountSpec = 0
  for k1, v1 in pairs(profiles[UIParameters.currentType]) do
    profilesCountClass = 0
    for k2, v2 in pairs(v1) do
      profilesCountSpec = 0
      for k3, v3 in pairs(v2) do
        profilesCountClass = profilesCountClass + 1
        profilesCountSpec = profilesCountSpec + 1
      end

      if profilesCountSpec == 0 then
        profiles[UIParameters.currentType][k1][k2] = nil
      end
    end

    if profilesCountClass == 0 then
      profiles[UIParameters.currentType][k1] = nil
    end
  end
end

function EnableProfile(classID, specID, profileName)
  --print("enable "..classID.." "..specID.." "..profileName)
  profiles[UIParameters.currentType][classID][specID][profileName]["enable"] = true
end

function SetProfileColor(classID, specID, profileName, color)
  --print("color "..classID.." "..specID.." "..profileName.." "..color)
  profiles[UIParameters.currentType][classID][specID][profileName]["color"] = color
end

function DisableProfile(classID, specID, profileName)
  --print("disable "..classID.." "..specID.." "..profileName)
  profiles[UIParameters.currentType][classID][specID][profileName]["enable"] = false
end

function AddSpacer(targetFrame,full,width,height)
	UIElements.spacerTable[#UIElements.spacerTable+1] = AGUI:Create("Label")
	if full then
		UIElements.spacerTable[#UIElements.spacerTable]:SetFullWidth(true)
	else
		if width<=1 then
			UIElements.spacerTable[#UIElements.spacerTable]:SetRelativeWidth(width)
		else
			UIElements.spacerTable[#UIElements.spacerTable]:SetWidth(width)
		end
	end
	if height then
		UIElements.spacerTable[#UIElements.spacerTable]:SetHeight(height)
	end
	targetFrame:AddChild(UIElements.spacerTable[#UIElements.spacerTable])
end

function OpenProfileUI()
  --Init Vars
  UIParameters.detailsLoaded = false
  UIParameters.detailsDrawn = false
  UIParameters.currentProfile = ""
  UIParameters.currentClassID = 0
  UIParameters.currentSpecID = 0

  --replace frame if already opened
  if UIElements.mainframe and UIElements.mainframe:IsVisible() then
    UIElements.mainframe:Release()
  end
  UIElements.mainframe = AGUI:Create("Frame")
  UIElements.mainframe:SetTitle("MoreTooltipInfo")
  UIElements.mainframe:SetPoint("CENTER")
  UIElements.mainframe:SetCallback("OnClose", function(widget) 
    if UIElements.mainframe:IsVisible() then
      widget:Release()
    end
  end)
  UIElements.mainframe:SetLayout("Flow")
  UIElements.mainframe:SetWidth(700)
  UIElements.mainframe:SetHeight(400)
  
  UIElements.mainGroup = AGUI:Create("SimpleGroup")
  UIElements.mainGroup:SetLayout("Flow")
  UIElements.mainGroup:SetRelativeWidth(0.3)
  UIElements.mainGroup:SetFullHeight(true)
  UIElements.mainframe:AddChild(UIElements.mainGroup)
	
	local scrollcontainer1 = AGUI:Create("SimpleGroup")
  scrollcontainer1:SetRelativeWidth(1)
  scrollcontainer1:SetFullHeight(true)
	scrollcontainer1:SetLayout("Fill")
	UIElements.mainGroup:AddChild(scrollcontainer1)
	
	UIElements.scroll1 = AGUI:Create("ScrollFrame")
	UIElements.scroll1:SetLayout("Flow")
  scrollcontainer1:AddChild(UIElements.scroll1)

  UIElements.importButton = AGUI:Create("Button")
  UIElements.importButton:SetText("Import")
  UIElements.importButton:SetCallback("OnClick", function(widget)
    StaticPopup_Show ("MTI_IMPORT_POPUP")
  end)
  UIElements.importButton:SetRelativeWidth(1)
  UIElements.scroll1:AddChild(UIElements.importButton)

  UIElements.typeDropdown = AGUI:Create("Dropdown")
  UIElements.typeDropdown:SetList(UIParameters.availableOption)
  UIElements.typeDropdown:SetValue(UIParameters.currentTypeIndex)
  UIElements.typeDropdown:SetCallback("OnValueChanged", function (this, event, item)
    UIParameters.currentTypeIndex = item
		UIParameters.currentType=UIParameters.availableOption[item]
		OpenProfileUI()
  end)
  UIElements.typeDropdown:SetRelativeWidth(1)
  UIElements.scroll1:AddChild(UIElements.typeDropdown)

  local profilesCount = 1
  for k1, v1 in pairs(profiles[UIParameters.currentType]) do
    for k2, v2 in pairs(v1) do
        local classLabel = AGUI:Create("InteractiveLabel")
        classLabel:SetText(MoreTooltipInfo.SpecNames[k1]["name"] .. " - " .. MoreTooltipInfo.SpecNames[k1][k2])
        local r,g,b = hex2rgb(MoreTooltipInfo.SpecNames[k1]["color"])
        classLabel:SetColor(r/255,g/255,b/255)
        classLabel:SetRelativeWidth(1)
        UIElements.scroll1:AddChild(classLabel)
      for k3, v3 in pairs(v2) do
        UIElements.tableLabel[profilesCount] = AGUI:Create("InteractiveLabel")
        UIElements.tableLabel[profilesCount]:SetText(k3)
        UIElements.tableLabel[profilesCount]:SetRelativeWidth(1)
        UIElements.tableLabel[profilesCount]:SetCallback("OnClick", function(widget)
          UIParameters.currentProfile = k3
          DrawOptionGroup(k1, k2, k3)
        end)
        UIElements.scroll1:AddChild(UIElements.tableLabel[profilesCount])
        profilesCount = profilesCount + 1
      end
    end
  end
  
  -- First load of the Details pannel
  if not UIParameters.detailsLoaded then
    UIElements.detailsGroup = AGUI:Create("SimpleGroup")
    UIElements.detailsGroup:SetLayout("Flow")
    UIElements.detailsGroup:SetRelativeWidth(0.7)

    UIElements.titleLabel = AGUI:Create("Heading")
    UIElements.titleLabel:SetText("")
    UIElements.titleLabel:SetRelativeWidth(1)
    UIElements.detailsGroup:AddChild(UIElements.titleLabel)

    UIElements.renameButton = AGUI:Create("Button")
    UIElements.renameButton:SetText("Rename")
    UIElements.renameButton:SetCallback("OnClick", function(widget)
      StaticPopup_Show ("MTI_RENAME_POPUP",UIParameters.currentProfile)
    end)
    UIElements.renameButton:SetRelativeWidth(0.5)
    UIElements.detailsGroup:AddChild(UIElements.renameButton)

    UIElements.deleteButton = AGUI:Create("Button")
    UIElements.deleteButton:SetText("Delete")
    UIElements.deleteButton:SetCallback("OnClick", function(widget)
      StaticPopup_Show ("MTI_DELETE_POPUP",UIParameters.currentProfile)
    end)
    UIElements.deleteButton:SetRelativeWidth(0.5)
    UIElements.detailsGroup:AddChild(UIElements.deleteButton)

    UIElements.enablecheckbox = AGUI:Create("CheckBox")
    UIElements.enablecheckbox:SetLabel("Enable")
    UIElements.enablecheckbox:SetRelativeWidth(1)
    UIElements.detailsGroup:AddChild(UIElements.enablecheckbox)

    UIElements.colorpicker = AGUI:Create("ColorPicker")
    UIElements.colorpicker:SetLabel("Color")
    UIElements.colorpicker:SetRelativeWidth(1)
    UIElements.colorpicker:SetCallback("OnValueConfirmed", function(widget, event, r, g, b, a)
      local newColor = rgb2hex(r*255,g*255,b*255) .. "ff"
      SetProfileColor(UIParameters.currentClassID,UIParameters.currentSpecID,UIParameters.currentProfile,newColor)
    end)
    UIElements.detailsGroup:AddChild(UIElements.colorpicker)

    UIParameters.detailsLoaded = true
  end

end

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
            width = "full",
            order = 0,
          },
          enableSpellRPPM = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Spell RPPM" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 1,
          },
          enableSpellGCD = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Spell GCD" .. FONT_COLOR_CODE_CLOSE,
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
            width = "full",
            order = 0,
          },
          enableItemSpellID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item Spell ID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 1,
          },
          enableItemRPPM = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item Spell RPPM" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 2,
          },
          enableItemBonusID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item BonusID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 3,
          },
          enableItemGemID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item GemID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 4,
          },
          enableItemEnchantID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item EnchantID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 5,
          },
          enableItemEnchantSpellID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item Enchant Spell ID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 6,
          },
          enableItemEnchantSpellRPPM = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Item Enchant Spell RPPM" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 7,
          },
        },
      },
      gTalent = {
        type = "group",
        name = "Talents",
        inline = true,
        order = 2,
        args = {
          enableSpellTalentID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Talent ID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 0,
          },
        },
      },
      gSoulbind = {
        type = "group",
        name = "Soulbinds",
        inline = true,
        order = 3,
        args = {
          enableSoulbindID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable SoulbindID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 0,
          },
        },
      },
      gConduit = {
        type = "group",
        name = "Conduits",
        inline = true,
        order = 4,
        args = {
          enableConduitID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable ConduitID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 0,
          },
          enableConduitSpellID = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Conduit SpellID" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 1,
          },
          enableConduitRank = {
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Conduit rank" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
            order = 2,
          },
        },
      },
		},
  }
  local DPSPanel = {
		type = "group",
		name = "DPS options",
		order = 103,
		get = function(info) return cfg[ info[#info] ] end,
		set = function(info, value) cfg[ info[#info] ] = value; end,
		args = {
      customdataButton = {
        order = 0,
        type = "execute",
        name = "Manage DPS profiles",
        func = function(info) if InterfaceOptionsFrame:IsShown() then InterfaceOptionsFrame:Hide() end  OpenProfileUI() end,
      },
      gItems = {
        type = "group",
        name = "Items",
        inline = true,
        order = 1,
        args = {
          enableBaseItemDPS = {
            order = 1,
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Base Item Simulated DPS" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
          },
        },
      },
      gTalents = {
        type = "group",
        name = "Talents",
        inline = true,
        order = 2,
        args = {
          enableBaseTalentDPS = {
            order = 0,
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Base talent Simulated DPS" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
          },
          enableBestTalentDPS = {
            order = 1,
            type = "toggle",
            name = NORMAL_FONT_COLOR_CODE .. "Enable Best talent Simulated DPS" .. FONT_COLOR_CODE_CLOSE,
            width = "full",
          },
        },
      },
		},
  }

  self.optionsFrame = ACD:AddToBlizOptions(addonName, addonName["MoreTooltipInfo"])
	self.optionsFrame = ACD:AddToBlizOptions("Tooltip options", addonName["TooltipOptions"], addonName)
	self.optionsFrame = ACD:AddToBlizOptions("DPS", addonName["DPS"], addonName)

  ACR:RegisterOptionsTable(addonName, mainPanel, false)
	ACR:RegisterOptionsTable("Tooltip options", tooltipPanel, false)
  ACR:RegisterOptionsTable("DPS", DPSPanel, false)
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
hooksecurefunc(GameTooltip, "SetTalent", function(...) MoreTooltipInfo.ManageTooltips("spell", "talent", ...) end)
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
    db.profiles = MoreTooltipInfo:initDB(db.profiles, profileDefaults)
    cfg = db.char[playerRealm][playerName]
    profiles = db.profiles
    self:CreateOptions()
  end
end

---------------------
------- Data --------
---------------------
MoreTooltipInfo.SpecNames = {
  [6] = {
    ["name"] = "Death Knight",
    ["color"] = "c41f3b",
    [250] = 'Blood',
    [251] = 'Frost',
    [252] = 'Unholy',
  },
  [12] = {
    ["name"] = "Demon Hunter",
    ["color"] = "a330c9",
    [577] = 'Havoc',
    [581] = 'Vengeance',
  },
  [11] = {
    ["name"] = "Druid",
    ["color"] = "ff7d0a",
    [102] = 'Balance',
    [103] = 'Feral',
    [104] = 'Guardian',
    [105] = 'Restoration',
  },
  [3] = {
    ["name"] = "Hunter",
    ["color"] = "a9d271",
    [253] = 'Beast Mastery',
    [254] = 'Marksmanship',
    [255] = 'Survival',
  },
  [8] = {
    ["name"] = "Mage",
    ["color"] = "40c7eb",
    [62] = 'Arcane',
    [63] = 'Fire',
    [64] = 'Frost',
  },
  [10] = {
    ["name"] = "Monk",
    ["color"] = "00ff96",
    [268] = 'Brewmaster',
    [269] = 'Windwalker',
    [270] = 'Mistweaver',
  },
  [2] = {
    ["name"] = "Paladin",
    ["color"] = "f58cba",
    [65] = 'Holy',
    [66] = 'Protection',
    [70] = 'Retribution',
  },
  [5] = {
    ["name"] = "Priest",
    ["color"] = "ffffff",
    [256] = 'Discipline',
    [257] = 'Holy',
    [258] = 'Shadow',
  },
  [4] = {
    ["name"] = "Rogue",
    ["color"] = "fff569",
    [259] = 'Assassination',
    [260] = 'Outlaw',
    [261] = 'Subtlety',
  },
  [12] = {
    ["name"] = "Shaman",
    ["color"] = "0070de",
    [262] = 'Elemental',
    [263] = 'Enhancement',
    [264] = 'Restoration',
  },
  [9] = {
    ["name"] = "Warlock",
    ["color"] = "8787ed",
    [265] = 'Affliction',
    [266] = 'Demonology',
    [267] = 'Destruction',
  },
  [1] = {
    ["name"] = "Warrior",
    ["color"] = "c79c6e",
    [71] = 'Arms',
    [72] = 'Fury',
    [73] = 'Protection'
  },
}

---------------------
------- Util --------
---------------------

function hex2rgb(hex)
  return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

function rgb2hex(r, g, b)
  local r_h, g_h, b_h
  r_h = string.format("%x", r)
  if #r_h < 2 then r_h = "0" .. r_h end
  g_h = string.format("%x", g)
  if #g_h < 2 then g_h = "0" .. g_h end
  b_h = string.format("%x", b)
  if #b_h < 2 then b_h = "0" .. b_h end

  return r_h .. g_h .. b_h
end