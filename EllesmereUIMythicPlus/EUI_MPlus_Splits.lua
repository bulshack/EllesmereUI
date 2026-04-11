-------------------------------------------------------------------------------
--  EUI_MPlus_Splits.lua
--  Persists best total time per dungeon, shows delta vs PB.
-------------------------------------------------------------------------------
local EMP = EllesmereUIMythicPlus
local Splits = EMP.Splits

local function formatDelta(delta)
    local sign = "+"
    if delta < 0 then sign = "-" end
    local abs = math.abs(delta)
    local m = math.floor(abs / 60)
    local s = math.floor(abs % 60)
    return string.format("%s%d:%02d", sign, m, s)
end

function Splits:GetBestFor(mapID)
    if not EMP.db or not EMP.db.profile or not EMP.db.profile.bestTimes then return nil end
    local entry = EMP.db.profile.bestTimes[mapID]
    if entry and entry.totalTime then return entry.totalTime end
    return nil
end

function Splits:UpdateDelta(elapsed)
    local f = EMP.Panel.frame
    if not f then return end
    if not (EMP.db and EMP.db.profile and EMP.db.profile.showSplits) then
        f.splitText:SetText("")
        return
    end

    local mapID = C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
    if not mapID then
        f.splitText:SetText("")
        return
    end
    local best = self:GetBestFor(mapID)
    if not best then
        f.splitText:SetText("")
        return
    end

    local delta = elapsed - best
    f.splitText:SetText(formatDelta(delta))
    if delta < 0 then
        f.splitText:SetTextColor(0.4, 1.0, 0.4)
    else
        f.splitText:SetTextColor(1.0, 0.4, 0.4)
    end
end

function Splits:RecordRun()
    -- Called by main addon on CHALLENGE_MODE_COMPLETED
    local mapID = C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID()
    if not mapID then return end

    local elapsed = EMP.Timer:GetElapsed()
    if elapsed <= 0 then return end

    EMP.db.profile.bestTimes = EMP.db.profile.bestTimes or {}
    local best = EMP.db.profile.bestTimes[mapID]
    if not best or elapsed < (best.totalTime or math.huge) then
        EMP.db.profile.bestTimes[mapID] = {
            totalTime  = elapsed,
            recordedAt = time(),
        }
    end
end

function Splits:ResetAll()
    if EMP.db and EMP.db.profile then
        EMP.db.profile.bestTimes = {}
    end
end
