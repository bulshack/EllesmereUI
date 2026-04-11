-------------------------------------------------------------------------------
--  EUI_MPlus_Options.lua
--  Settings panel for the Mythic+ addon. Top-level category in Blizzard
--  Settings UI. Includes preview mode so user can see the panel without a key.
-------------------------------------------------------------------------------
local EMP = EllesmereUIMythicPlus
local Options = EMP.Options

local Widgets = EllesmereUI_Widgets

local function makeCheckbox(parent, label, dbKey, y, onChange)
    local cb
    if Widgets and Widgets.CreateCheckbox then
        cb = Widgets.CreateCheckbox(parent, label)
    else
        cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        if cb.text then cb.text:SetText(label) end
    end
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    cb:SetChecked(EMP.db.profile[dbKey] and true or false)
    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked() and true or false
        EMP.db.profile[dbKey] = v
        if onChange then onChange(v) end
    end)
    return cb
end

local function makeButton(parent, label, y, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(160, 24)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    btn:SetText(label)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function makeSlider(parent, label, dbKey, min, max, step, y)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    slider:SetWidth(200)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(EMP.db.profile[dbKey] or 1.0)
    _G[slider:GetName() and slider:GetName() .. "Low" or ""] = nil
    if slider.Text then slider.Text:SetText(label) end
    slider:SetScript("OnValueChanged", function(self, value)
        EMP.db.profile[dbKey] = value
        if EMP.Panel and EMP.Panel.frame then
            EMP.Panel.frame:SetScale(value)
        end
    end)
    return slider
end

function Options:Create()
    if self.frame then return end

    local panel = CreateFrame("Frame", "EllesmereUIMythicPlusOptionsPanel", UIParent)
    panel.name = "EllesmereUI Mythic+"

    -- -----------------------------------------------------------------------
    -- Title + description
    -- -----------------------------------------------------------------------
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("EllesmereUI Mythic+")

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("Custom Mythic+ keystone panel. Type /euimplus to open this screen.")
    subtitle:SetTextColor(0.7, 0.7, 0.7)

    -- -----------------------------------------------------------------------
    -- Enable master toggle
    -- -----------------------------------------------------------------------
    local enableCb = makeCheckbox(panel, "Enable Mythic+ panel", "enabled", -50, function(v)
        if not v and EMP.Panel then
            EMP.Panel:Hide()
            EMP.Panel.previewMode = false
            if EMP.Panel.frame and EMP.Panel.frame.previewBadge then
                EMP.Panel.frame.previewBadge:SetText("")
            end
        end
    end)

    -- -----------------------------------------------------------------------
    -- Preview + movement controls
    -- -----------------------------------------------------------------------
    local previewBtn = makeButton(panel, "Preview Panel", -90, function()
        if EMP.Panel then EMP.Panel:TogglePreview() end
    end)

    local lockCb = makeCheckbox(panel, "Lock position (unlock to drag)", "locked", -125, function(v)
        if EMP.Panel then EMP.Panel:SetLocked(v) end
    end)

    local resetPosBtn = makeButton(panel, "Reset Position", -160, function()
        if EMP.Panel then EMP.Panel:ResetPosition() end
    end)

    -- -----------------------------------------------------------------------
    -- Display toggles
    -- -----------------------------------------------------------------------
    local displayHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayHeader:SetPoint("TOPLEFT", 16, -200)
    displayHeader:SetText("Display")
    displayHeader:SetTextColor(
        EllesmereUI.DEFAULT_ACCENT_R or 0.05,
        EllesmereUI.DEFAULT_ACCENT_G or 0.82,
        EllesmereUI.DEFAULT_ACCENT_B or 0.61
    )

    makeCheckbox(panel, "Show boss list",        "showBossList",     -225)
    makeCheckbox(panel, "Show death counter",    "showDeathCounter", -250)
    makeCheckbox(panel, "Show best-time delta",  "showSplits",       -275)

    -- -----------------------------------------------------------------------
    -- Best times reset
    -- -----------------------------------------------------------------------
    local resetBestBtn = makeButton(panel, "Reset All Best Times", -315, function()
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

    -- -----------------------------------------------------------------------
    -- Register with Blizzard settings
    -- -----------------------------------------------------------------------
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        self.category = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    self.frame = panel
end

-- Slash commands
SLASH_EUIMPLUS1 = "/euimplus"
SLASH_EUIMPLUS2 = "/euimythic"
SlashCmdList["EUIMPLUS"] = function(msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""
    if msg == "preview" or msg == "test" then
        if EMP.Panel then EMP.Panel:TogglePreview() end
        return
    end
    if Options.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(Options.category:GetID())
    elseif Options.frame and InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(Options.frame)
    else
        print("|cff0cd29f[EllesmereUI Mythic+]|r Options not available.")
    end
end
