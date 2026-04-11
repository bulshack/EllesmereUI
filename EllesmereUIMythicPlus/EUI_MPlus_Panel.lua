-------------------------------------------------------------------------------
--  EUI_MPlus_Panel.lua
--  Main panel frame: EllesmereUI-styled backdrop, header, timer, forces bar,
--  boss list, deaths, plus preview mode.
-------------------------------------------------------------------------------
local EMP = EllesmereUIMythicPlus
local Panel = EMP.Panel
local PP = EllesmereUI.PP

local PANEL_WIDTH  = 280
local PANEL_HEIGHT = 260

local ACCENT_R = EllesmereUI.DEFAULT_ACCENT_R or (12 / 255)
local ACCENT_G = EllesmereUI.DEFAULT_ACCENT_G or (210 / 255)
local ACCENT_B = EllesmereUI.DEFAULT_ACCENT_B or (157 / 255)

local BG_TEX        = "Interface\\ChatFrame\\ChatFrameBackground"
local STATUSBAR_TEX = "Interface\\TargetingFrame\\UI-StatusBar"

local function getAccent()
    if EllesmereUI.GetCurrentAccent then
        local r, g, b = EllesmereUI.GetCurrentAccent()
        if r then return r, g, b end
    end
    return ACCENT_R, ACCENT_G, ACCENT_B
end

local function pixelBorder(frame, onePx)
    frame:SetBackdrop({
        bgFile   = BG_TEX,
        edgeFile = BG_TEX,
        edgeSize = onePx,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 },
    })
end

function Panel:Create()
    if self.frame then return end

    local onePx = (PP and PP.mult) or 1
    local ar, ag, ab = getAccent()

    -- -----------------------------------------------------------------------
    -- Root frame
    -- -----------------------------------------------------------------------
    local f = CreateFrame("Frame", "EllesmereUIMythicPlusPanel", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)

    pixelBorder(f, onePx)
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.92)
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

    -- -----------------------------------------------------------------------
    -- Header bar (accent colored strip + title + key level)
    -- -----------------------------------------------------------------------
    local header = CreateFrame("Frame", nil, f, "BackdropTemplate")
    header:SetHeight(26)
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if not (EMP.db and EMP.db.profile and EMP.db.profile.locked) then f:StartMoving() end
    end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        if EMP.db and EMP.db.profile then
            EMP.db.profile.position = { point = point, relativePoint = relativePoint, x = x, y = y }
        end
    end)
    header:SetScript("OnEnter", function(self)
        if EMP.db and EMP.db.profile and not EMP.db.profile.locked then
            SetCursor("UI_MOVE_CURSOR")
        end
    end)
    header:SetScript("OnLeave", function() SetCursor(nil) end)

    -- Accent strip behind header
    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.03, 0.03, 0.03, 0.9)

    local accentLine = header:CreateTexture(nil, "BORDER")
    accentLine:SetHeight(2 * onePx)
    accentLine:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    accentLine:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accentLine:SetColorTexture(ar, ag, ab, 1)
    f.accentLine = accentLine

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", header, "LEFT", 10, 0)
    title:SetText("EllesmereUI  M+")
    title:SetTextColor(1, 1, 1, 1)
    f.title = title

    local keyLevel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyLevel:SetPoint("RIGHT", header, "RIGHT", -10, 0)
    keyLevel:SetText("")
    keyLevel:SetTextColor(ar, ag, ab, 1)
    f.keyLevel = keyLevel

    -- -----------------------------------------------------------------------
    -- Timer section
    -- -----------------------------------------------------------------------
    local timerText = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
    timerText:SetPoint("TOP", header, "BOTTOM", 0, -10)
    timerText:SetText("00:00")
    timerText:SetTextHeight(28)
    f.timerText = timerText

    local chestText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chestText:SetPoint("TOP", timerText, "BOTTOM", 0, -2)
    chestText:SetText("")
    chestText:SetTextColor(0.7, 0.7, 0.7)
    f.chestText = chestText

    local splitText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    splitText:SetPoint("TOP", chestText, "BOTTOM", 0, -1)
    splitText:SetText("")
    f.splitText = splitText

    -- -----------------------------------------------------------------------
    -- Enemy Forces section
    -- -----------------------------------------------------------------------
    local sectionHeader1 = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sectionHeader1:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -110)
    sectionHeader1:SetText("ENEMY FORCES")
    sectionHeader1:SetTextColor(ar, ag, ab, 1)
    f.sectionHeader1 = sectionHeader1

    local forcesBarBG = CreateFrame("Frame", nil, f, "BackdropTemplate")
    forcesBarBG:SetHeight(16)
    forcesBarBG:SetPoint("TOPLEFT", sectionHeader1, "BOTTOMLEFT", 0, -3)
    forcesBarBG:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    pixelBorder(forcesBarBG, onePx)
    forcesBarBG:SetBackdropColor(0.1, 0.1, 0.1, 1)
    forcesBarBG:SetBackdropBorderColor(0, 0, 0, 1)

    local forcesBar = CreateFrame("StatusBar", nil, forcesBarBG)
    forcesBar:SetPoint("TOPLEFT", forcesBarBG, "TOPLEFT", onePx, -onePx)
    forcesBar:SetPoint("BOTTOMRIGHT", forcesBarBG, "BOTTOMRIGHT", -onePx, onePx)
    forcesBar:SetStatusBarTexture(STATUSBAR_TEX)
    forcesBar:SetStatusBarColor(ar, ag, ab, 1)
    forcesBar:SetMinMaxValues(0, 100)
    forcesBar:SetValue(0)
    f.forcesBar = forcesBar
    f.forcesBarBG = forcesBarBG

    local forcesText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    forcesText:SetPoint("CENTER", forcesBarBG, "CENTER", 0, 0)
    forcesText:SetText("0 / 0  (0%)")
    forcesText:SetTextColor(1, 1, 1)
    f.forcesText = forcesText

    -- -----------------------------------------------------------------------
    -- Bosses section
    -- -----------------------------------------------------------------------
    local sectionHeader2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sectionHeader2:SetPoint("TOPLEFT", forcesBarBG, "BOTTOMLEFT", 0, -8)
    sectionHeader2:SetText("BOSSES")
    sectionHeader2:SetTextColor(ar, ag, ab, 1)
    f.sectionHeader2 = sectionHeader2

    local bossContainer = CreateFrame("Frame", nil, f)
    bossContainer:SetPoint("TOPLEFT", sectionHeader2, "BOTTOMLEFT", 0, -3)
    bossContainer:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    bossContainer:SetHeight(72)
    f.bossContainer = bossContainer
    f.bossRows = {}

    -- -----------------------------------------------------------------------
    -- Deaths footer
    -- -----------------------------------------------------------------------
    local footerLine = f:CreateTexture(nil, "BORDER")
    footerLine:SetHeight(onePx)
    footerLine:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 22)
    footerLine:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 22)
    footerLine:SetColorTexture(ar, ag, ab, 0.5)

    local deathsText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deathsText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 6)
    deathsText:SetText("Deaths: 0")
    f.deathsText = deathsText

    -- "PREVIEW" badge (shown in preview mode)
    local previewBadge = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewBadge:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 6)
    previewBadge:SetText("")
    previewBadge:SetTextColor(1, 0.6, 0.2, 1)
    f.previewBadge = previewBadge

    self.frame = f
end

function Panel:Show()
    if self.frame then self.frame:Show() end
end

function Panel:Hide()
    if self.frame then self.frame:Hide() end
end

function Panel:IsShown()
    return self.frame and self.frame:IsShown()
end

function Panel:SetLocked(locked)
    if EMP.db and EMP.db.profile then
        EMP.db.profile.locked = locked and true or false
    end
end

function Panel:ResetPosition()
    if EMP.db and EMP.db.profile then
        EMP.db.profile.position = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -20, y = -200 }
    end
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
    end
end

-- -----------------------------------------------------------------------
-- PREVIEW MODE: fills the panel with fake data so the user can see layout
-- without being in an actual keystone.
-- -----------------------------------------------------------------------
function Panel:ShowPreview()
    if not self.frame then self:Create() end
    local f = self.frame

    self.previewMode = true
    f.title:SetText("NECROTIC WAKE")
    f.keyLevel:SetText("+15")

    f.timerText:SetText("12:34")
    f.timerText:SetTextColor(0.2, 1.0, 0.2)
    f.chestText:SetText("+3")
    f.splitText:SetText("-2:15")
    f.splitText:SetTextColor(0.4, 1.0, 0.4)

    f.forcesBar:SetValue(72)
    f.forcesText:SetText("254 / 353  (72%)")

    -- Fake boss list
    local fakeBosses = {
        { name = "Blightbone",              done = true  },
        { name = "Amarth",                  done = true  },
        { name = "Surgeon Stitchflesh",     done = false },
        { name = "Nalthor the Rimebinder",  done = false },
    }
    for i, row in ipairs(self.frame.bossRows) do row:Hide() end
    for i, b in ipairs(fakeBosses) do
        local row = self.frame.bossRows[i]
        if not row then
            row = self.frame.bossContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row:SetPoint("TOPLEFT", self.frame.bossContainer, "TOPLEFT", 0, -((i - 1) * 16))
            row:SetPoint("RIGHT", self.frame.bossContainer, "RIGHT", 0, 0)
            row:SetJustifyH("LEFT")
            self.frame.bossRows[i] = row
        end
        local mark = b.done and "|cff00ff00[X]|r" or "|cff888888[ ]|r"
        row:SetText(mark .. " " .. b.name)
        if b.done then row:SetTextColor(0.6, 1.0, 0.6) else row:SetTextColor(0.8, 0.8, 0.8) end
        row:Show()
    end

    f.deathsText:SetText("Deaths: 2  (+10s)")
    f.previewBadge:SetText("PREVIEW")

    f:Show()
end

function Panel:StopPreview()
    self.previewMode = false
    if self.frame and self.frame.previewBadge then
        self.frame.previewBadge:SetText("")
    end
    -- Clear text back to idle state; the real run flow will repopulate as needed
    if self.frame then
        self.frame.title:SetText("EllesmereUI  M+")
        self.frame.keyLevel:SetText("")
        self.frame.timerText:SetText("00:00")
        self.frame.timerText:SetTextColor(1, 1, 1)
        self.frame.chestText:SetText("")
        self.frame.splitText:SetText("")
        self.frame.forcesBar:SetValue(0)
        self.frame.forcesText:SetText("0 / 0  (0%)")
        self.frame.deathsText:SetText("Deaths: 0")
        for _, row in ipairs(self.frame.bossRows) do row:Hide() end
    end
    self:Hide()
end

function Panel:TogglePreview()
    if self.previewMode then
        self:StopPreview()
    else
        self:ShowPreview()
    end
end
