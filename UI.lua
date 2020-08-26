-- AethysCore
local AC = AethysCore;
-- File Locals
local GUI = AC.GUI;
local CreatePanel = GUI.CreatePanel;
local CreateChildPanel = GUI.CreateChildPanel;
local CreatePanelOption = GUI.CreatePanelOption;
  
function MoreTooltipInfo.CreateSettings()
  local ARPanel = CreatePanel(MoreTooltipInfo, "MoreTooltipInfo", "PanelFrame", MoreTooltipInfo.Settings, MoreTooltipInfoVars);
  CreatePanelOption("CheckButton", ARPanel, "Tooltip.Item.ItemID", "Item ItemID", "Enable if you want to see item ID.");

  -- MoreTooltipInfo.panel = CreateFrame( "Frame", "MyAddonPanel", UIParent );
  -- MoreTooltipInfo.panel.name = "MoreTooltipInfo";
   -- Add the panel to the Interface Options
  -- InterfaceOptions_AddCategory(MoreTooltipInfo.panel);
  
  -- MoreTooltipInfo.AddCheckBox(MoreTooltipInfo.panel,"MoreTooltipInfoVars.Tooltip.Spell.SpellID","Spell SpellID","Enable Spell SpellID")
end
local LastOptionAttached = {};
function MoreTooltipInfo.AddCheckBox(Parent, Setting, Text, Tooltip, Optionals)
    -- Constructor
    local CheckButton = CreateFrame("CheckButton", "$parent_"..Setting, Parent, "InterfaceOptionsCheckButtonTemplate");
    Parent[Setting] = CheckButton;
    -- CheckButton.SettingTable, CheckButton.SettingKey = FindSetting(Parent.SettingsTable, strsplit(".", Setting));
    -- CheckButton.SavedVariablesTable, CheckButton.SavedVariablesKey = Parent.SavedVariablesTable, Setting;

    -- Frame init
    if not LastOptionAttached[Parent.name] then
      CheckButton:SetPoint("TOPLEFT", 15, -15);
    else
      CheckButton:SetPoint("TOPLEFT", LastOptionAttached[Parent.name][1], "BOTTOMLEFT", LastOptionAttached[Parent.name][2], LastOptionAttached[Parent.name][3]-5);
    end
    LastOptionAttached[Parent.name] = {CheckButton, 0, 0};

    -- CheckButton:SetChecked(CheckButton.SettingTable[CheckButton.SettingKey]);

    _G[CheckButton:GetName().."Text"]:SetText("|c00dfb802" .. Text .. "|r");

    -- AnchorTooltip(CheckButton, FilterTooltip(Tooltip, Optionals));

    -- Setting update
    -- local UpdateSetting;
    -- Setting
    -- if Optionals and Optionals["ReloadRequired"] then
      -- UpdateSetting = function (self)
        -- self.SavedVariablesTable[self.SavedVariablesKey] = not self.SettingTable[self.SettingKey];
      -- end
    -- else
      -- UpdateSetting = function (self)
        -- local NewValue = not self.SettingTable[self.SettingKey];
        -- self.SettingTable[self.SettingKey] = NewValue;
        -- self.SavedVariablesTable[self.SavedVariablesKey] = NewValue;
      -- end
    -- end
    -- CheckButton:SetScript("onClick", UpdateSetting);
end
