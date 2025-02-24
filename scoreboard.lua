
--mythic+ extension for Details! Damage Meter
--[[
    This file show a frame at the end of a mythic+ run with a breakdown of the players performance.
    It shows the player name, the score, deaths, damage taken, dps, hps, interrupts, dispels and cc casts.
]]

---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
local addon = private.addon
local _ = nil

---@class details_mythicplus_breakdown : table
---@field lines details_mythicbreakdown_line[]
---@field CreateBigBreakdownFrame fun():details_mythicbreakdown_bigframe
---@field CreateLineForBigBreakdownFrame fun(parent:details_mythicbreakdown_bigframe, header:details_mythicbreakdown_headerframe, index:number):details_mythicbreakdown_line
---@field RefreshBigBreakdownFrame fun()

---@class details_mythicbreakdown_bigframe : frame
---@field HeaderFrame details_mythicbreakdown_headerframe
---@field TitleString fontstring
---@field DungeonBackdropTexture texture
---@field ElapsedTimeIcon texture
---@field ElapsedTimeText fontstring
---@field OutOfCombatIcon texture
---@field OutOfCombatText fontstring
---@field SandTimeIcon texture
---@field KeylevelText fontstring
---@field StrongArmIcon texture
---@field RantingLabel fontstring
---@field LeftFiligree texture
---@field RightFiligree texture
---@field BottomFiligree texture
---@field YellowSpikeCircle texture
---@field YellowFlash texture
---@field Level fontstring

---@class details_mythicbreakdown_headerframe : df_headerframe
---@field lines table<number, details_mythicbreakdown_line>

---@class details_mythicbreakdown_line : button, df_headerfunctions

---@type details_mythicplus_breakdown
---@diagnostic disable-next-line: missing-fields
local mythicPlusBreakdown = {
    lines = {},
}

local GetItemInfo = GetItemInfo or C_Item.GetItemInfo
local GetItemIcon = GetItemIcon or C_Item.GetItemIcon
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo or C_Item.GetDetailedItemLevelInfo

local Loc = _G.LibStub("AceLocale-3.0"):GetLocale("Details")

--local mythicDungeonCharts = Details222.MythicPlus.Charts.Listener
--local mythicDungeonFrames = Details222.MythicPlus.Frames

local CONST_DEBUG_MODE = false
local LOOT_DEBUG_MODE = false

local lineTextSettings = {
    color = "white",
    size = 12,
    outline = "NONE",
}
local lineHoverSettings = {
    color = "orange",
    size = 12,
    outline = "NONE",
}
local lineStandoutSettings = {
    color = {230/255, 204/255, 128/255},
    size = 12,
    outline = "NONE",
}

--main frame settings
local mainFrameName = "DetailsMythicPlusBreakdownFrame"
local mainFrameWidth = 1200
local mainFrameHeight = 420
--where the header is positioned in the Y axis from the top of the frame
local headerY = -70
--the amount of lines to be created to show player data
local lineAmount = 6
--player info area width (a.k.a the width of each line)
local lineWidth = mainFrameWidth - 6
local lineOffset = 3
--the height of each line
local lineHeight = 40
--two backdrop colors
local lineColor1 = {1, 1, 1, 0.05}
local lineColor2 = {1, 1, 1, 0.1}
local lineBackdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true}

---store spell names of interrupt spells
---the table is filled when the main frame is created
---@type table<string, boolean>
local interruptSpellNameCache = {}

function addon.OpenMythicPlusBreakdownBigFrame()
    if (not _G[mainFrameName]) then
        mythicPlusBreakdown.CreateBigBreakdownFrame()
    end

    local mainFrame = _G[mainFrameName]
    mythicPlusBreakdown.RefreshBigBreakdownFrame()
    mainFrame:Show()
end

function Details.OpenMythicPlusBreakdownBigFrame()
    addon.OpenMythicPlusBreakdownBigFrame()
end

function mythicPlusBreakdown.CreateBigBreakdownFrame()
    --quick exit if the frame already exists
    if (_G[mainFrameName]) then
        return _G[mainFrameName]
    end

    ---@type details_mythicbreakdown_bigframe
    local readyFrame = CreateFrame("frame", mainFrameName, UIParent, "BackdropTemplate")
    readyFrame:SetSize(mainFrameWidth, mainFrameHeight)
    readyFrame:SetPoint("center", UIParent, "center", 0, 0)
    readyFrame:SetFrameStrata("HIGH")
    readyFrame:EnableMouse(true)
    readyFrame:SetMovable(true)

    table.insert(UISpecialFrames, mainFrameName)

    readyFrame:SetBackdropColor(.1, .1, .1, 0)
    readyFrame:SetBackdropBorderColor(.1, .1, .1, 0)
    detailsFramework:AddRoundedCornersToFrame(readyFrame, Details.PlayerBreakdown.RoundedCornerPreset)

    local backgroundDungeonTexture = readyFrame:CreateTexture("$parentDungeonBackdropTexture", "background")
    backgroundDungeonTexture:SetPoint("topleft", readyFrame, "topleft", 3, -3)
    backgroundDungeonTexture:SetPoint("bottomright", readyFrame, "bottomright", -3, 3)
    readyFrame.DungeonBackdropTexture = backgroundDungeonTexture

    --detailsFramework:ApplyStandardBackdrop(readyFrame)
    detailsFramework:MakeDraggable(readyFrame)

    local closeButton = detailsFramework:CreateCloseButton(readyFrame, "$parentCloseButton")
    closeButton:SetScript("OnClick", function()
        readyFrame:Hide()
    end)
    closeButton:SetPoint("topright", readyFrame, "topright", -5, -5)

    --title string
    local titleString = readyFrame:CreateFontString("$parentTitle", "overlay", "GameFontNormalLarge")
    titleString:SetPoint("top", readyFrame, "top", 0, -14)
    readyFrame.TitleString = titleString

    --elapsed fontstring

	--update the run time and time not in combat
    --[=[
	local elapsedTime = Details222.MythicPlus.time or 1507
	readyFrame.ElapsedTimeText:SetText(detailsFramework:IntegerToTimer(elapsedTime))

	if (overallMythicDungeonCombat:GetCombatType() == DETAILS_SEGMENTTYPE_MYTHICDUNGEON_OVERALL) then
		local combatTime = overallMythicDungeonCombat:GetCombatTime()
		local notInCombat = elapsedTime - combatTime
		readyFrame.OutOfCombatText:SetText(detailsFramework:IntegerToTimer(notInCombat))
	else
		readyFrame.OutOfCombatText:SetText("00:00")
	end
    --]=]

    do
        local topFrame = CreateFrame("frame", "$parentTopFrame", readyFrame, "BackdropTemplate")
        topFrame:SetPoint("topleft", readyFrame, "topleft", 0, 0)
        topFrame:SetPoint("topright", readyFrame, "topright", 0, 0)
        topFrame:SetHeight(1)
        topFrame:SetFrameLevel(readyFrame:GetFrameLevel() - 1)

        --use the same textures from the original end of dungeon panel
        local spikes = topFrame:CreateTexture("$parentSkullCircle", "overlay")
        spikes:SetSize(100, 100)
        spikes:SetPoint("center", readyFrame, "top", 0, 27)
        spikes:SetAtlas("ChallengeMode-SpikeyStar")
        spikes:SetAlpha(1)
        spikes:SetIgnoreParentAlpha(true)
        readyFrame.YellowSpikeCircle = spikes

        local yellowFlash = topFrame:CreateTexture("$parentYellowFlash", "artwork")
        yellowFlash:SetSize(120, 120)
        yellowFlash:SetPoint("center", readyFrame, "top", 0, 27)
        yellowFlash:SetAtlas("BossBanner-RedFlash")
        yellowFlash:SetAlpha(0)
        yellowFlash:SetBlendMode("ADD")
        yellowFlash:SetIgnoreParentAlpha(true)
        readyFrame.YellowFlash = yellowFlash

        readyFrame.Level = topFrame:CreateFontString("$parentLevelText", "overlay", "GameFontNormalWTF2Outline")
        readyFrame.Level:SetPoint("center", readyFrame.YellowSpikeCircle, "center", 0, 0)
        readyFrame.Level:SetText("12")

        --create the animation for the yellow flash
        local flashAnimHub = detailsFramework:CreateAnimationHub(yellowFlash, function() yellowFlash:SetAlpha(0) end, function() yellowFlash:SetAlpha(0) end)
        local flashAnim1 = detailsFramework:CreateAnimation(flashAnimHub, "Alpha", 1, 0.5, 0, 1)
        local flashAnim2 = detailsFramework:CreateAnimation(flashAnimHub, "Alpha", 2, 0.5, 1, 0)

        --create the animation for the yellow spike circle
        local spikeCircleAnimHub = detailsFramework:CreateAnimationHub(spikes, function() spikes:SetAlpha(0); spikes:SetScale(1) end, function() flashAnimHub:Play(); spikes:SetSize(100, 100); spikes:SetScale(1); spikes:SetAlpha(1) end)
        local alphaAnim1 = detailsFramework:CreateAnimation(spikeCircleAnimHub, "Alpha", 1, 0.2960000038147, 0, 1)
        local scaleAnim1 = detailsFramework:CreateAnimation(spikeCircleAnimHub, "Scale", 1, 0.21599999070168, 5, 5, 1, 1, "center", 0, 0)
        readyFrame.YellowSpikeCircle.OnShowAnimation = spikeCircleAnimHub

        readyFrame.LeftFiligree = topFrame:CreateTexture("$parentLeftFiligree", "artwork")
        readyFrame.LeftFiligree:SetAtlas("BossBanner-LeftFillagree")
        readyFrame.LeftFiligree:SetSize(72, 43)
        readyFrame.LeftFiligree:SetPoint("bottom", readyFrame, "top", -50, -2)

        readyFrame.RightFiligree = topFrame:CreateTexture("$parentRightFiligree", "artwork")
        readyFrame.RightFiligree:SetAtlas("BossBanner-RightFillagree")
        readyFrame.RightFiligree:SetSize(72, 43)
        readyFrame.RightFiligree:SetPoint("bottom", readyFrame, "top", 50, -2)

        --create the bottom filligree using BossBanner-BottomFillagree atlas
        readyFrame.BottomFiligree = topFrame:CreateTexture("$parentBottomFiligree", "artwork")
        readyFrame.BottomFiligree:SetAtlas("BossBanner-BottomFillagree")
        readyFrame.BottomFiligree:SetSize(66, 28)
        readyFrame.BottomFiligree:SetPoint("bottom", readyFrame, "bottom", 0, -19)

    end

    --header frame
    local headerTable = {
        {text = "", width = 50}, --player portrait
        {text = "", width = 20}, --spec icon
        {text = "Player Name", width = 100},
        {text = "M+ Score", width = 100},
        {text = "Deaths", width = 100},
        {text = "Damage Taken", width = 100},
        {text = "DPS", width = 100},
        {text = "HPS", width = 100},
        {text = "Interrupts", width = 100},
        {text = "Dispels", width = 100},
        {text = "CC Casts", width = 100},
        {text = "Empty Space", width = 200},
    }
    local headerOptions = {
        padding = 2,
    }

    ---@type details_mythicbreakdown_headerframe
    local headerFrame = detailsFramework:CreateHeader(readyFrame, headerTable, headerOptions)
    headerFrame:SetPoint("topleft", readyFrame, "topleft", 5, headerY)
    headerFrame.lines = {}
    readyFrame.HeaderFrame = headerFrame

    do --mythic+ run data
		local textColor = {1, 0.8196, 0, 1}
		local textSize = 11

		--clock texture and icon to show the total time elapsed
		local elapsedTimeIcon = readyFrame:CreateTexture("$parentClockIcon", "artwork", nil, 2)
		elapsedTimeIcon:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
		elapsedTimeIcon:SetTexCoord(172/512, 235/512, 84/512, 147/512)
		readyFrame.ElapsedTimeIcon = elapsedTimeIcon

		local elapsedTimeText = readyFrame:CreateFontString("$parentClockText", "artwork", "GameFontNormal")
		elapsedTimeText:SetTextColor(1, 1, 1)
		detailsFramework:SetFontSize(elapsedTimeText, 11)
		elapsedTimeText:SetText("00:00")
		elapsedTimeText:SetPoint("left", elapsedTimeIcon, "right", 3, 0)
		readyFrame.ElapsedTimeText = elapsedTimeText

		--another clock texture and icon to show the wasted time (time out of combat)
		local outOfCombatIcon = readyFrame:CreateTexture("$parentClockIcon2", "artwork", nil, 2)
		outOfCombatIcon:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
		outOfCombatIcon:SetTexCoord(172/512, 235/512, 84/512, 147/512)
		outOfCombatIcon:SetVertexColor(detailsFramework:ParseColors("orangered"))
		readyFrame.OutOfCombatIcon = outOfCombatIcon

		local outOfCombatText = readyFrame:CreateFontString("$parentClockText2", "artwork", "GameFontNormal")
		outOfCombatText:SetTextColor(1, 1, 1)
		detailsFramework:SetFontSize(outOfCombatText, 11)
		detailsFramework:SetFontColor(outOfCombatText, "orangered")
		outOfCombatText:SetText("00:00")
		outOfCombatText:SetPoint("left", outOfCombatIcon, "right", 3, 0)
		readyFrame.OutOfCombatText = outOfCombatText

		--create the sandtime icon and a text to show the keystone level
		local sandTimeIcon = readyFrame:CreateTexture("$parentSandTimeIcon", "artwork", nil, 2)
		sandTimeIcon:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
		sandTimeIcon:SetTexCoord(81/512, 137/512, 83/512, 143/512)
		readyFrame.SandTimeIcon = sandTimeIcon

		local keyLevelText = readyFrame:CreateFontString("$parentKeyLevelText", "artwork", "GameFontNormal")
		keyLevelText:SetTextColor(1, 1, 1)
		detailsFramework:SetFontSize(keyLevelText, 11)
		keyLevelText:SetText("0")
		keyLevelText:SetPoint("left", sandTimeIcon, "right", 1, 0)
		readyFrame.KeylevelText = keyLevelText

		--create a strong arm texture and a text to show the ranting of the player
		local strongArmIcon = readyFrame:CreateTexture("$parentStrongArmIcon", "artwork", nil, 2)
		strongArmIcon:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
		strongArmIcon:SetTexCoord(84/512, 145/512, 151/512, 215/512)
		readyFrame.StrongArmIcon = strongArmIcon

		local rantingLabel = detailsFramework:CreateLabel(readyFrame, "0", textSize, textColor)
		rantingLabel:SetPoint("left", strongArmIcon, "right", 3, 0)
		readyFrame.RantingLabel = rantingLabel

        local buttonSize = 24

        readyFrame.ElapsedTimeIcon:SetSize(buttonSize, buttonSize)
        readyFrame.OutOfCombatIcon:SetSize(buttonSize, buttonSize)
        readyFrame.ElapsedTimeIcon:SetPoint("bottomleft", headerFrame, "topleft", 50, 12)
        readyFrame.OutOfCombatIcon:SetPoint("left", readyFrame.ElapsedTimeIcon, "right", 70, 0)

        readyFrame.SandTimeIcon:SetSize(buttonSize, buttonSize) --original size is 32x60, need to adjust to the correct size
        readyFrame.SandTimeIcon:SetPoint("left", readyFrame.OutOfCombatIcon, "right", 70, 0)

        readyFrame.StrongArmIcon:SetSize(buttonSize, buttonSize)
        readyFrame.StrongArmIcon:SetPoint("left", readyFrame.SandTimeIcon, "right", 70, 0)
    end

    --create 6 rows to show data of the player, it only require 5 lines, the last one can be used on exception cases.
    for i = 1, lineAmount do
        mythicPlusBreakdown.CreateLineForBigBreakdownFrame(readyFrame, headerFrame, i)
    end

    return readyFrame
end

--this function get the overall mythic+ segment created after a mythic+ run has finished
--then it fill the lines with data from the overall segment
function mythicPlusBreakdown.RefreshBigBreakdownFrame()
    ---@type details_mythicbreakdown_bigframe
    local mainFrame = _G[mainFrameName]
    local headerFrame = mainFrame.HeaderFrame
    local lines = headerFrame.lines

    mythicPlusBreakdown.SetFontSettings()

    local mythicPlusOverallSegment = Details:GetCurrentCombat()

	if (mythicPlusOverallSegment:GetCombatType() ~= DETAILS_SEGMENTTYPE_MYTHICDUNGEON_OVERALL) then
		--get a table with all segments
		local segmentsTable = Details:GetCombatSegments()
		for i = 1, #segmentsTable do
			local segment = segmentsTable[i]
			if (segment:GetCombatType() == DETAILS_SEGMENTTYPE_MYTHICDUNGEON_OVERALL) then
				mythicPlusOverallSegment = segment
				break
			end
		end
	end

    --local mythicPlusOverallSegment = Details:GetOverallCombat()
    local combatTime = mythicPlusOverallSegment:GetCombatTime()

    local damageContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
    local healingContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_HEAL)
    local utilityContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_MISC)

    local data = {}

    for actorIndex, actorObject in damageContainer:ListActors() do
        ---@cast actorObject actor
        if (actorObject:IsGroupPlayer()) then
            local unitId
            for i = 1, #Details.PartyUnits do
                if (Details:GetFullName(Details.PartyUnits[i]) == actorObject.nome) then
                    unitId = Details.PartyUnits[i]
                end
            end
            unitId = unitId or actorObject.nome

            if (type(actorObject.mrating) == "table") then
                actorObject.mrating = actorObject.mrating.currentSeasonScore
            end

            local rating = actorObject.mrating or 0
            local ratingColor = C_ChallengeMode.GetDungeonScoreRarityColor(rating)
            if (not ratingColor) then
                ratingColor = _G["HIGHLIGHT_FONT_COLOR"]
            end

            local deathAmount = 0
            local deathTable = mythicPlusOverallSegment:GetDeaths()
            for i = 1, #deathTable do
                local thisDeathTable = deathTable[i]
                local playerName = thisDeathTable[3]
                if (playerName == actorObject.nome) then
                    deathAmount = deathAmount + 1
                end
            end

            ---@cast actorObject actordamage

            local thisPlayerData = {
                name = actorObject.nome,
                class = actorObject.classe,
                spec = actorObject.spec,
                role = actorObject.role or UnitGroupRolesAssigned(unitId),
                score = rating,
                scoreColor = ratingColor,
                deaths = deathAmount,
                damageTaken = actorObject.damage_taken,
                dps = actorObject.total / combatTime,
                hps = 0,
                interrupts = 0,
                interruptCasts = mythicPlusOverallSegment:GetInterruptCastAmount(actorObject.nome),
                dispels = 0,
                ccCasts = mythicPlusOverallSegment:GetCCCastAmount(actorObject.nome),
                unitId = unitId,
                combatUid = mythicPlusOverallSegment:GetCombatUID(),
            }

            if (thisPlayerData.role == "NONE") then
                thisPlayerData.role = "DAMAGER"
            end

            data[#data+1] = thisPlayerData
        end
    end

    for actorIndex, actorObject in healingContainer:ListActors() do
        local playerData
        for i = 1, #data do
            if (data[i].name == actorObject.nome) then
                playerData = data[i]
                break
            end
        end

        if (playerData) then
            ---@cast actorObject actorheal
            playerData.hps = actorObject.total / combatTime
        end
    end

    for actorIndex, actorObject in utilityContainer:ListActors() do
        local playerData
        for i = 1, #data do
            if (data[i].name == actorObject.nome) then
                playerData = data[i]
                break
            end
        end

        if (playerData) then
            ---@cast actorObject actorutility
            playerData.interrupts = actorObject.interrupt or 0
            playerData.dispels = actorObject.dispell or 0
        end
    end

    table.sort(data, function(t1, t2) return t1.role > t2.role end)

    for i = 1, lineAmount do
        lines[i]:Hide()
    end

    local playerRatingScore = 0

    local topScores = {
        [6] = {key = "damageTaken", line = 0, best = 0},
        [7] = {key = "dps", line = 0, best = 0},
        [8] = {key = "hps", line = 0, best = 0},
        [9] = {key = "interrupts", line = 0, best = 0},
        [10] = {key = "dispels", line = 0, best = 0},
        [11] = {key = "ccCasts", line = 0, best = 0},
    }

    for i = 1, lineAmount do
        local line = lines[i]
        local frames = line:GetFramesFromHeaderAlignment()
        local playerData = data[i]

        --(re)set the line contents
        for j = 1, #frames do
            local frame = frames[j]
            if (frame:GetObjectType() == "FontString" or frame:GetObjectType() == "Button") then
                frame:SetText("")
            elseif (frame:GetObjectType() == "Texture") then
                frame:SetTexture(nil)
            end
            if (playerData and frame.SetPlayerData) then
                frame:SetPlayerData(playerData)
            end
        end

        if (playerData) then
            line:Show()
            --dumpt(playerData)
            local playerPortrait = frames[1]
            local specIcon = frames[2]
            local playerScore = frames[4]

            if (GetUnitName("player", true) == playerData.name) then
                playerRatingScore = playerData.score
            end

            SetPortraitTexture(playerPortrait.Portrait, playerData.unitId)
            local portraitTexture = playerPortrait.Portrait:GetTexture()
            if (not portraitTexture) then
                local class = playerData.class
                playerPortrait.Portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
                playerPortrait.Portrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
            end

            local role = playerData.role
            if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
                playerPortrait.RoleIcon:SetAtlas(GetMicroIconForRole(role), TextureKitConstants.IgnoreAtlasSize)
                playerPortrait.RoleIcon:Show()
            else
                playerPortrait.RoleIcon:Hide()
            end

            -- manually setting the labels, buttons are set through SetPlayerData
            specIcon:SetTexture(select(4, GetSpecializationInfoByID(playerData.spec)))
            playerScore:SetTextColor(playerData.scoreColor.r, playerData.scoreColor.g, playerData.scoreColor.b)

            for _, value in pairs(topScores) do
                if (value.best < playerData[value.key]) then
                    value.best = playerData[value.key]
                    value.line = i
                end
            end
        end
    end

    for frameId, value in pairs(topScores) do
        if (value.best > 0) then
            local frames = lines[value.line] and lines[value.line]:GetFramesFromHeaderAlignment() or {}
            if (frames[frameId] and frames[frameId].MarkTop) then
                frames[frameId]:MarkTop()
            end
        end
    end

    local mythicPlusData = mythicPlusOverallSegment:GetMythicDungeonInfo()
    --dumpt(mythicPlusData)

    if (mythicPlusData) then
        local runTime = mythicPlusData.RunTime
        local notInCombat = runTime - combatTime

        mainFrame.ElapsedTimeText:SetText(detailsFramework:IntegerToTimer(runTime))
        mainFrame.OutOfCombatText:SetText(detailsFramework:IntegerToTimer(notInCombat))
        mainFrame.KeylevelText:SetText(mythicPlusData.Level) --the level at the run displays above the header
        mainFrame.Level:SetText(mythicPlusData.Level) --the level in the big circle at the top

        mainFrame.TitleString:SetText(mythicPlusData.DungeonName)
    end

    --mainFrame.RantingLabel:SetText(Details.LastMythicPlusData.Level or (mythicPlusData and mythicPlusData.Level) or 0)

    if (Details.LastMythicPlusData) then
        if (Details.LastMythicPlusData.NewDungeonScore and Details.LastMythicPlusData.OldDungeonScore) then
            local gainedScore = Details.LastMythicPlusData.NewDungeonScore - Details.LastMythicPlusData.OldDungeonScore
            local color = C_ChallengeMode.GetDungeonScoreRarityColor(Details.LastMythicPlusData.NewDungeonScore)
            if (not color) then
                color = _G["HIGHLIGHT_FONT_COLOR"]
            end
            local text = ""
            if (gainedScore >= 1) then
                local textToFormat = "%d (+%d)"
                text = textToFormat:format(Details.LastMythicPlusData.NewDungeonScore, gainedScore)
            else
                local textToFormat = "%d"
                text = textToFormat:format(Details.LastMythicPlusData.NewDungeonScore)
            end
            mainFrame.RantingLabel:SetText(color:WrapTextInColorCode(text))
            mainFrame.RantingLabel:SetTextColor(detailsFramework:ParseColors("limegreen"))
        else
            mainFrame.RantingLabel:SetText(playerRatingScore)
        end
    end

    ---@type details_instanceinfo
	local instanceInfo = mythicPlusData and Details:GetInstanceInfo(mythicPlusData.MapID) or Details:GetInstanceInfo(Details:GetCurrentCombat().mapId)
    if (instanceInfo) then
        mainFrame.DungeonBackdropTexture:SetTexture(instanceInfo.iconLore)
    else
        mainFrame.DungeonBackdropTexture:SetTexture(mythicPlusOverallSegment.is_mythic_dungeon.DungeonTexture)
    end

    mainFrame.DungeonBackdropTexture:SetTexCoord(35/512, 291/512, 49/512, 289/512)

end

local function OpenLineBreakdown(self, mainAttribute, subAttribute)
    local playerData = self.MyObject:GetPlayerData()
    if (not playerData or not playerData.name or not playerData.combatUid) then
        return
    end

    Details:OpenSpecificBreakdownWindow(Details:GetCombatByUID(playerData.combatUid), playerData.name, mainAttribute, subAttribute)
end

local function OnEnterLineBreakdownButton(self)
    local text = self.MyObject.button.text
    text.originalColor = {text:GetTextColor()}
    detailsFramework:SetFontSize(text, lineHoverSettings.size)
    detailsFramework:SetFontColor(text, lineHoverSettings.color)
    detailsFramework:SetFontOutline(text, lineHoverSettings.outline)
end

local function OnLeaveLineBreakdownButton(self)
    local text = self.MyObject.button.text
    detailsFramework:SetFontSize(text, lineTextSettings.size)
    detailsFramework:SetFontColor(text, text.originalColor)
    detailsFramework:SetFontOutline(text, lineTextSettings.outline)
end

function mythicPlusBreakdown.SetFontSettings()
    for i = 1, #mythicPlusBreakdown.lines do
        local line = mythicPlusBreakdown.lines[i]

        local region = {line:GetRegions()}
        for j = 1, #region do
            local child = region[j]
            if (child:GetObjectType() == "FontString") then
                detailsFramework:SetFontSize(child, lineTextSettings.size)
                detailsFramework:SetFontColor(child, lineTextSettings.color)
                detailsFramework:SetFontOutline(child, lineTextSettings.outline)
            end
        end

        --include framework buttons
        local children = {line:GetChildren()}
        for j = 1, #children do
            local child = children[j]
            if (child:GetObjectType() == "Button" and child.MyObject) then --.MyObject is a button from the framework
                local buttonObject = child.MyObject
                buttonObject:SetFontSize(lineTextSettings.size)
                buttonObject:SetTextColor(lineTextSettings.color)
                detailsFramework:SetFontOutline(child.text, lineTextSettings.outline)
            end
        end
    end
end

local function CreateBreakdownButton(line, mainAttribute,  subAttribute, onSetPlayerData)
    local button = detailsFramework:CreateButton(line, function (self)
        OpenLineBreakdown(self, mainAttribute, subAttribute)
    end, 80, 22, nil, nil, nil, nil, nil, nil, nil, nil, {font = "GameFontNormal", size = 12})

    button:SetHook("OnEnter", OnEnterLineBreakdownButton)
    button:SetHook("OnLeave", OnLeaveLineBreakdownButton)
    button.button.text:ClearAllPoints("left", button.button, "left")
    button.button.text:SetPoint("left", button.button, "left")
    button.button.text.originalColor = {button.button.text:GetTextColor()}

    function button.SetPlayerData(self, playerData)
        self.PlayerData = playerData
        onSetPlayerData(self, playerData)
    end
    function button.GetPlayerData(self)
        return self.PlayerData
    end
    function button.MarkTop(self)
        detailsFramework:SetFontSize(self.button.text, lineStandoutSettings.size)
        detailsFramework:SetFontColor(self.button.text, lineStandoutSettings.color)
        detailsFramework:SetFontOutline(self.button.text, lineStandoutSettings.outline)
    end

    return button
end

local function CreateBreakdownLabel(line, onSetPlayerData)
    local label = line:CreateFontString(nil, "overlay", "GameFontNormal")

    function label.SetPlayerData(self, playerData)
        self.PlayerData = playerData
        if (onSetPlayerData) then
            detailsFramework:SetFontSize(self, lineTextSettings.size)
            detailsFramework:SetFontColor(self, lineTextSettings.color)
            detailsFramework:SetFontOutline(self, lineTextSettings.outline)
            onSetPlayerData(self, playerData)
        end
    end
    function label.GetPlayerData(self)
        return self.PlayerData
    end
    function label.MarkTop(self)
        detailsFramework:SetFontSize(self, lineStandoutSettings.size)
        detailsFramework:SetFontColor(self, lineStandoutSettings.color)
        detailsFramework:SetFontOutline(self, lineStandoutSettings.outline)
    end

    return label
end

function mythicPlusBreakdown.CreateLineForBigBreakdownFrame(mainFrame, headerFrame, index)
    ---@type details_mythicbreakdown_line
    local line = CreateFrame("button", "$parentLine" .. index, mainFrame, "BackdropTemplate")
    detailsFramework:Mixin(line, detailsFramework.HeaderFunctions)
    mythicPlusBreakdown.lines[#mythicPlusBreakdown.lines+1] = line

    local yPosition = -((index-1)*(lineHeight+1)) - 1
    line:SetPoint("topleft", headerFrame, "bottomleft", lineOffset, yPosition)
    line:SetSize(lineWidth, lineHeight)

    line:SetBackdrop(lineBackdrop)
    if (index % 2 == 0) then
        line:SetBackdropColor(unpack(lineColor1))
    else
        line:SetBackdropColor(unpack(lineColor2))
    end

    --player portrait
    local playerPortrait = Details:CreatePlayerPortrait(line, "$parentPortrait")
    playerPortrait.Portrait:SetSize(lineHeight-2, lineHeight-2)
    playerPortrait:SetSize(lineHeight-2, lineHeight-2)
    playerPortrait.RoleIcon:SetSize(18, 18)
    playerPortrait.RoleIcon:ClearAllPoints()
    playerPortrait.RoleIcon:SetPoint("bottomleft", playerPortrait.Portrait, "bottomright", -9, -2)

    --texture to show the specialization of the player
    local specIcon = line:CreateTexture(nil, "overlay")
    specIcon:SetSize(20, 20)

    local playerName = CreateBreakdownLabel(line, function(self, playerData)
        local classColor = RAID_CLASS_COLORS[playerData.class]
        self:SetTextColor(classColor.r, classColor.g, classColor.b)
        self:SetText(detailsFramework:RemoveRealmName(playerData.name))
    end)

    local playerScore = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(playerData.score)
    end)

    local playerDeaths = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(playerData.deaths)
    end)

    local playerDamageTaken = CreateBreakdownButton(line, DETAILS_ATTRIBUTE_DAMAGE, DETAILS_SUBATTRIBUTE_DAMAGETAKEN, function(self, playerData)
        self:SetText(Details:Format(math.floor(playerData.damageTaken)))
    end)

    local playerDps = CreateBreakdownButton(line, DETAILS_ATTRIBUTE_DAMAGE, DETAILS_SUBATTRIBUTE_DPS, function(self, playerData)
        self:SetText(Details:Format(math.floor(playerData.dps)))
    end)

    local playerHps = CreateBreakdownButton(line, DETAILS_ATTRIBUTE_HEAL, DETAILS_SUBATTRIBUTE_HPS, function(self, playerData)
        self:SetText(Details:Format(math.floor(playerData.hps)))
    end)

    local playerInterrupts = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(math.floor(playerData.interrupts))
        self.InterruptCasts:SetText("/ " .. math.floor(playerData.interruptCasts))
    end)

    playerInterrupts.InterruptCasts = CreateBreakdownLabel(line)

    local playerDispels = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(math.floor(playerData.dispels))
    end)

    local playerCcCasts = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(math.floor(playerData.ccCasts))
    end)

    local playerEmptyField = CreateBreakdownLabel(line)

    --add each widget create to the header alignment
    line:AddFrameToHeaderAlignment(playerPortrait)
    line:AddFrameToHeaderAlignment(specIcon)
    line:AddFrameToHeaderAlignment(playerName)
    line:AddFrameToHeaderAlignment(playerScore)
    line:AddFrameToHeaderAlignment(playerDeaths)
    line:AddFrameToHeaderAlignment(playerDamageTaken)
    line:AddFrameToHeaderAlignment(playerDps)
    line:AddFrameToHeaderAlignment(playerHps)
    line:AddFrameToHeaderAlignment(playerInterrupts)
    line:AddFrameToHeaderAlignment(playerDispels)
    line:AddFrameToHeaderAlignment(playerCcCasts)
    line:AddFrameToHeaderAlignment(playerEmptyField)

    line:AlignWithHeader(headerFrame, "left")

    --set the point of the interrupt casts
    local a, b, c, d, e = playerInterrupts:GetPoint(1)
    playerInterrupts.InterruptCasts:SetPoint(a, b, c, d + 20, e)

    headerFrame.lines[index] = line

    return line
end
