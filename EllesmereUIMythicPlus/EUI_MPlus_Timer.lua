-------------------------------------------------------------------------------
--  EUI_MPlus_Timer.lua
--  Counts elapsed time in the current keystone, colors by chest pace.
-------------------------------------------------------------------------------
local EMP = EllesmereUIMythicPlus
local Timer = EMP.Timer

local TICK_INTERVAL = 0.1  -- 10 Hz

-- Colors for chest pace tiers
local COLOR_PLUS3 = { 0.2, 1.0, 0.2 }
local COLOR_PLUS2 = { 1.0, 1.0, 0.2 }
local COLOR_PLUS1 = { 1.0, 1.0, 1.0 }
local COLOR_DEPLETED = { 1.0, 0.2, 0.2 }

local function formatTime(seconds)
    if seconds < 0 then seconds = 0 end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

local function paceColor(elapsed, limit)
    if limit <= 0 then return COLOR_PLUS1 end
    if elapsed < limit * 0.6 then return COLOR_PLUS3 end
    if elapsed < limit * 0.8 then return COLOR_PLUS2 end
    if elapsed < limit then return COLOR_PLUS1 end
    return COLOR_DEPLETED
end

local function chestLabel(elapsed, limit)
    if limit <= 0 then return "" end
    if elapsed < limit * 0.6 then return "+3" end
    if elapsed < limit * 0.8 then return "+2" end
    if elapsed < limit then return "+1" end
    return "depleted"
end

function Timer:Start()
    local mapID = C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
    if mapID and C_ChallengeMode.GetMapUIInfo then
        local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
        self.mapName  = name or "MYTHIC+"
        self.timeLimit = timeLimit or 0
    else
        self.mapName  = "MYTHIC+"
        self.timeLimit = 0
    end

    -- Only set startTime and ticker on the first Start() call.
    -- This guards against double-start (e.g. OnEnable + PLAYER_ENTERING_WORLD)
    -- resetting the elapsed timer mid-run.
    if not self.ticker then
        self.startTime = GetTime()
        self.ticker = C_Timer.NewTicker(TICK_INTERVAL, function() Timer:Tick() end)
    end

    local f = EMP.Panel.frame
    if f then
        f.title:SetText(string.upper(self.mapName))
        local level = C_ChallengeMode.GetActiveKeystoneInfo and C_ChallengeMode.GetActiveKeystoneInfo()
        f.keyLevel:SetText(level and ("+" .. level) or "")
    end
end

function Timer:Stop()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
end

function Timer:Tick()
    local f = EMP.Panel.frame
    if not f or not self.startTime then return end

    local elapsed = GetTime() - self.startTime
    local limit   = self.timeLimit or 0

    f.timerText:SetText(formatTime(elapsed))
    local c = paceColor(elapsed, limit)
    f.timerText:SetTextColor(c[1], c[2], c[3])
    f.chestText:SetText(chestLabel(elapsed, limit))

    -- Ask splits module for delta display
    if EMP.Splits and EMP.Splits.UpdateDelta then
        EMP.Splits:UpdateDelta(elapsed)
    end
end

function Timer:GetElapsed()
    if not self.startTime then return 0 end
    return GetTime() - self.startTime
end
