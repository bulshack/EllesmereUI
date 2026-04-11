-------------------------------------------------------------------------------
--  EllesmereUIMythicPlus.lua
--  Main addon: lifecycle, shared namespace, event routing.
-------------------------------------------------------------------------------
local ADDON_NAME = ...
local EMP = EllesmereUI.Lite.NewAddon(ADDON_NAME)

-- Shared namespace. Each component file attaches its module table here.
EllesmereUIMythicPlus = EMP
EMP.Panel    = {}
EMP.Timer    = {}
EMP.Progress = {}
EMP.Splits   = {}
EMP.Options  = {}

-- Default SavedVariables layout.
local defaults = {
    profile = {
        enabled         = true,
        position        = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -20, y = -200 },
        locked          = false,
        scale           = 1.0,
        showAffixes     = true,
        showBossList    = true,
        showDeathCounter = true,
        showSplits      = true,
        bestTimes       = {},
    }
}

-------------------------------------------------------------------------------
-- Hide Blizzard's ScenarioObjectiveTracker M+ block while our panel is active.
-------------------------------------------------------------------------------
local blizzTrackerHidden = false

local function hideBlizzardMPlusTracker()
    if blizzTrackerHidden then return end
    local tracker = ScenarioObjectiveTracker
    if tracker and tracker.ChallengeModeBlock then
        tracker.ChallengeModeBlock:Hide()
        blizzTrackerHidden = true
    end
end

local function showBlizzardMPlusTracker()
    if not blizzTrackerHidden then return end
    local tracker = ScenarioObjectiveTracker
    if tracker and tracker.ChallengeModeBlock then
        tracker.ChallengeModeBlock:Show()
        blizzTrackerHidden = false
    end
end

function EMP:OnInitialize()
    self.db = EllesmereUI.Lite.NewDB("EllesmereUIMythicPlusDB", defaults)
end

function EMP:OnEnable()
    -- Bail if API missing (very old client)
    if not C_ChallengeMode then
        return
    end

    -- Create the panel (hidden by default)
    self.Panel:Create()
    self.Panel:Hide()

    -- Register options panel
    self.Options:Create()

    -- If the player reloads UI mid-keystone, show the panel now
    if C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
        self:StartRun()
    end

    -- Events
    self:RegisterEvent("CHALLENGE_MODE_START",               "OnChallengeStart")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED",           "OnChallengeComplete")
    self:RegisterEvent("CHALLENGE_MODE_RESET",               "OnChallengeReset")
    self:RegisterEvent("SCENARIO_CRITERIA_UPDATE",           "OnCriteriaUpdate")
    self:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED", "OnDeathCountChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD",              "OnEnteringWorld")
end

function EMP:StartRun()
    self.Panel:Show()
    self.Timer:Start()
    self.Progress:Refresh()
    hideBlizzardMPlusTracker()
end

function EMP:StopRun(completed)
    self.Timer:Stop()
    showBlizzardMPlusTracker()
    if completed then
        -- Leave panel visible for a moment so the player can see the final state
        C_Timer.After(10, function() self.Panel:Hide() end)
        self.Splits:RecordRun()
    else
        self.Panel:Hide()
    end
end

function EMP:OnChallengeStart()       self:StartRun() end
function EMP:OnChallengeComplete()    self:StopRun(true) end
function EMP:OnChallengeReset()       self:StopRun(false) end
function EMP:OnCriteriaUpdate()       self.Progress:Refresh() end
function EMP:OnDeathCountChanged()    self.Progress:RefreshDeaths() end

function EMP:OnEnteringWorld()
    if C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
        -- Guard against double-start from OnEnable + PLAYER_ENTERING_WORLD race
        if not self.Timer.ticker then
            self:StartRun()
        end
    else
        -- Not in a keystone — make sure we clean up if we were running
        if self.Timer.ticker then
            self:StopRun(false)
        else
            self.Panel:Hide()
        end
    end
end
