-------------------------------------------------------------------------------
--  EUI_MPlus_Progress.lua
--  Reads scenario criteria, updates enemy forces bar and boss list.
-------------------------------------------------------------------------------
local EMP = EllesmereUIMythicPlus
local Progress = EMP.Progress

local BOSS_ROW_HEIGHT = 16

local function getOrCreateBossRow(container, rows, index)
    local row = rows[index]
    if row then return row end
    row = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -((index - 1) * BOSS_ROW_HEIGHT))
    row:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    row:SetJustifyH("LEFT")
    rows[index] = row
    return row
end

function Progress:Refresh()
    local f = EMP.Panel.frame
    if not f then return end
    if not C_Scenario or not C_Scenario.GetStepInfo then return end

    local _, _, numCriteria = C_Scenario.GetStepInfo()
    numCriteria = numCriteria or 0

    local bossIndex = 0
    for i = 1, numCriteria do
        local info = C_Scenario.GetCriteriaInfo(i)
        if info then
            if info.isWeightedProgress then
                -- Enemy forces criterion
                local qty, total = info.quantity or 0, info.totalQuantity or 1
                -- qty can come through as a percentage string like "12%"
                if type(qty) == "string" then
                    qty = tonumber(qty:match("(%d+)")) or 0
                end
                local pct = 0
                if total > 0 then pct = math.min(100, math.floor((qty / total) * 100 + 0.5)) end
                f.forcesBar:SetValue(pct)
                f.forcesText:SetText(pct .. "%")
            else
                -- Boss criterion
                bossIndex = bossIndex + 1
                local row = getOrCreateBossRow(f.bossContainer, f.bossRows, bossIndex)
                local mark = info.completed and "|cff00ff00[x]|r" or "[ ]"
                row:SetText(mark .. " " .. (info.description or "Boss"))
                row:Show()
                if info.completed then
                    row:SetTextColor(0.6, 1.0, 0.6)
                else
                    row:SetTextColor(0.8, 0.8, 0.8)
                end
            end
        end
    end

    -- Hide any extra rows beyond current boss count
    for i = bossIndex + 1, #f.bossRows do
        f.bossRows[i]:Hide()
    end
end

function Progress:RefreshDeaths()
    local f = EMP.Panel.frame
    if not f then return end
    local count = 0
    if C_ChallengeMode.GetDeathCount then
        count = C_ChallengeMode.GetDeathCount() or 0
    end
    f.deathsText:SetText(string.format("Deaths: %d  (+%ds)", count, count * 5))
end
