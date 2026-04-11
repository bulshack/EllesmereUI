-------------------------------------------------------------------------------
--  EUI_MPlus_Panel.lua
--  Main panel frame: backdrop, header, sections, drag.
-------------------------------------------------------------------------------
local EMP = EllesmereUIMythicPlus
local Panel = EMP.Panel
local PP = EllesmereUI.PP

local PANEL_WIDTH  = 260
local PANEL_HEIGHT = 240  -- approximate; actual content determines visible area

function Panel:Create()
    if self.frame then return end

    local onePx = (PP and PP.mult) or 1

    local f = CreateFrame("Frame", "EllesmereUIMythicPlusPanel", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)

    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = onePx,
        insets   = { left = onePx, right = onePx, top = onePx, bottom = onePx },
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    -- Apply saved position + scale
    local p = EMP.db and EMP.db.profile and EMP.db.profile.position
    if p then
        f:ClearAllPoints()
        f:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
    end
    f:SetScale((EMP.db and EMP.db.profile and EMP.db.profile.scale) or 1.0)

    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(24)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if not (EMP.db.profile.locked) then f:StartMoving() end
    end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        EMP.db.profile.position = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", header, "LEFT", 8, 0)
    title:SetText("MYTHIC+")
    f.title = title

    local keyLevel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyLevel:SetPoint("RIGHT", header, "RIGHT", -8, 0)
    keyLevel:SetText("")
    f.keyLevel = keyLevel

    -- Timer section
    local timerText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    timerText:SetPoint("TOP", header, "BOTTOM", 0, -8)
    timerText:SetText("00:00")
    f.timerText = timerText

    local chestText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chestText:SetPoint("TOP", timerText, "BOTTOM", 0, -2)
    chestText:SetText("")
    f.chestText = chestText

    local splitText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    splitText:SetPoint("TOP", chestText, "BOTTOM", 0, -2)
    splitText:SetText("")
    f.splitText = splitText

    -- Enemy forces bar
    local forcesLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    forcesLabel:SetPoint("TOPLEFT", splitText, "BOTTOMLEFT", -60, -12)
    forcesLabel:SetText("Enemy Forces")
    f.forcesLabel = forcesLabel

    local forcesBar = CreateFrame("StatusBar", nil, f)
    forcesBar:SetHeight(12)
    forcesBar:SetPoint("TOPLEFT", forcesLabel, "BOTTOMLEFT", 0, -2)
    forcesBar:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    forcesBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    forcesBar:SetStatusBarColor(0.1, 0.7, 0.3, 1)
    forcesBar:SetMinMaxValues(0, 100)
    forcesBar:SetValue(0)
    f.forcesBar = forcesBar

    local forcesText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    forcesText:SetPoint("CENTER", forcesBar, "CENTER", 0, 0)
    forcesText:SetText("0%")
    f.forcesText = forcesText

    -- Boss list container
    local bossContainer = CreateFrame("Frame", nil, f)
    bossContainer:SetPoint("TOPLEFT", forcesBar, "BOTTOMLEFT", 0, -8)
    bossContainer:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    bossContainer:SetHeight(80)
    f.bossContainer = bossContainer
    f.bossRows = {}  -- reused font strings

    -- Deaths row
    local deathsText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deathsText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 8)
    deathsText:SetText("Deaths: 0")
    f.deathsText = deathsText

    self.frame = f
end

function Panel:Show()
    if self.frame then self.frame:Show() end
end

function Panel:Hide()
    if self.frame then self.frame:Hide() end
end

function Panel:SetLocked(locked)
    EMP.db.profile.locked = locked and true or false
end

function Panel:ResetPosition()
    EMP.db.profile.position = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -20, y = -200 }
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
    end
end
