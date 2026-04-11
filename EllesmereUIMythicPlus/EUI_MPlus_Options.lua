-------------------------------------------------------------------------------
--  EUI_MPlus_Options.lua
--  Settings panel for the Mythic+ addon.
-------------------------------------------------------------------------------
local EMP = EllesmereUIMythicPlus
local Options = EMP.Options

local Widgets = EllesmereUI_Widgets  -- shared library; falls back to simple CreateFrame if missing

local function makeCheckbox(parent, label, dbKey, y)
    local cb
    if Widgets and Widgets.CreateCheckbox then
        cb = Widgets.CreateCheckbox(parent, label)
    else
        cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb.Text:SetText(label)
    end
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    cb:SetChecked(EMP.db.profile[dbKey] and true or false)
    cb:SetScript("OnClick", function(self)
        EMP.db.profile[dbKey] = self:GetChecked() and true or false
    end)
    return cb
end

local function makeButton(parent, label, y, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(140, 22)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    btn:SetText(label)
    btn:SetScript("OnClick", onClick)
    return btn
end

function Options:Create()
    if self.frame then return end

    local panel = CreateFrame("Frame", "EllesmereUIMythicPlusOptionsPanel", UIParent)
    panel.name = "Mythic+"
    panel.parent = "EllesmereUI"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("EllesmereUI Mythic+")

    makeCheckbox(panel, "Show affixes row",     "showAffixes",     -50)
    makeCheckbox(panel, "Show boss list",       "showBossList",    -75)
    makeCheckbox(panel, "Show death counter",   "showDeathCounter",-100)
    makeCheckbox(panel, "Show best-time delta", "showSplits",      -125)

    local lockCb = makeCheckbox(panel, "Lock position", "locked", -160)
    lockCb:HookScript("OnClick", function(self)
        EMP.Panel:SetLocked(self:GetChecked())
    end)

    makeButton(panel, "Reset Position", -200, function()
        EMP.Panel:ResetPosition()
    end)

    makeButton(panel, "Reset Best Times", -230, function()
        StaticPopup_Show("ELLESMEREUI_MPLUS_RESET_BEST")
    end)

    StaticPopupDialogs["ELLESMEREUI_MPLUS_RESET_BEST"] = {
        text = "Reset all Mythic+ best times?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function() EMP.Splits:ResetAll() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    if Settings and Settings.RegisterCanvasLayoutSubcategory and SettingsPanel then
        local category = Settings.GetCategory("EllesmereUI")
        if category then
            Settings.RegisterCanvasLayoutSubcategory(category, panel, panel.name)
        end
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    self.frame = panel
end
