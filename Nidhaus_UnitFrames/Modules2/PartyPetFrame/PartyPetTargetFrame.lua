local AddOnName, ns = ...;
local K, C, L = unpack(ns);













































local addonName = "PartyPetTargetFrame"
local frame = CreateFrame("Frame", addonName.."Frame", UIParent)

local NUM_PETS   = 4
local FRAME_W    = 160
local FRAME_H    = 80
local STACK_GAP  = 4
local DEF_X, DEF_Y = 300, 100


local function TimerAfter(delay, func)
    local t = CreateFrame("Frame")
    local elapsed = 0
    t:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            func()
        end
    end)
end


local settings = {
    locked = false,
    clickable = true
}








local function PPF_ArenaOnly()
    return C.PartyPetArenaOnly ~= false
end

local function PPF_InArena()
    if type(IsActiveBattlefieldArena) == "function" then
        local ok, res = pcall(IsActiveBattlefieldArena)
        if ok and res then return true end
    end
    local _, itype = IsInInstance()
    return itype == "arena"
end

local function PPF_ZoneAllows()
    if not PPF_ArenaOnly() then return true end
    return PPF_InArena()
end









local function PPF_DB()
    if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
    NidhausUnitFramesDB.PartyPetPos = NidhausUnitFramesDB.PartyPetPos or {}
    return NidhausUnitFramesDB.PartyPetPos
end

local petFrames = {}

















local PPF_HasUnitWatch = (type(RegisterUnitWatch) == "function")
	and (type(UnregisterUnitWatch) == "function")
local PPF_WantVisible  = false
local PPF_Pending      = nil

local PPF_ApplyVisibility

local ppfCombat = CreateFrame("Frame")
ppfCombat:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	if PPF_Pending ~= nil then
		local want = PPF_Pending
		PPF_Pending = nil
		PPF_ApplyVisibility(want)
	end
end)

function PPF_ApplyVisibility(on)
	if InCombatLockdown() then
		PPF_Pending = on
		ppfCombat:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	PPF_WantVisible = on




	local show = on and PPF_ZoneAllows()

	for i = 1, NUM_PETS do
		local f = petFrames[i]
		if f then
			if PPF_HasUnitWatch then
				if show and not f.ppfWatching then
					RegisterUnitWatch(f)
					f.ppfWatching = true
				elseif (not show) and f.ppfWatching then
					UnregisterUnitWatch(f)
					f.ppfWatching = false
				end
				if not show then f:Hide() end
			else
				local should = show and UnitExists(f.unit) and true or false
				if should and not f:IsShown() then
					f:Show()
				elseif (not should) and f:IsShown() then
					f:Hide()
				end
			end
		end
	end
end


local hiddenAuras = {
    ["Devotion Aura"] = true,
    ["Crusader Aura"] = true,
    ["Concentration Aura"] = true,
    ["Retribution Aura"] = true,
    ["Resistance Aura"] = true,
    ["Trueshot Aura"] = true,
    ["Fire Resistance Aura"] = true,
    ["Frost Resistance Aura"] = true,
    ["Shadow Resistance Aura"] = true,
    ["Aspect of the Pack"] = true,
    ["Aspect of the Wild"] = true,
}


local ccDebuffs = {
    ["Stun"] = true,
    ["Fear"] = true,
    ["Incapacitate"] = true,
    ["Root"] = true,
    ["Sleep"] = true,
    ["Polymorph"] = true,
}

local function IsUnitCC(unit)
    for i = 1, 16 do
        local name, _, _, debuffType = UnitDebuff(unit, i)
        if name and debuffType and ccDebuffs[debuffType] then
            return true
        end
    end
    return false
end


local function IsVisibleBuff(unit, index)
    local name, _, _, _, _, _, caster = UnitBuff(unit, index)
    if not name then return false end
    if hiddenAuras[name] then return false end
    if caster == "player" then return true end
    return GetCVar("showCastableBuffs") == "1" and UnitCanAssist("player", unit)
end










local function ApplyPetLortiTint(pf)
	if not K.ApplyLortiTint then return; end
	K.ApplyLortiTint(pf.bg, "LortiUI_PartyPet");
end




local function PPF_Build(i)
	local unit = "party" .. i .. "pet"

	local petFrame = CreateFrame("Button", "CustomParty" .. i .. "PetFrame",
		UIParent, "SecureUnitButtonTemplate")





	petFrame:SetSize(FRAME_W, FRAME_H)
	petFrame.index = i
	petFrame.unit  = unit










	petFrame:Hide()


	petFrame:SetAttribute("type1", "target")
	petFrame:SetAttribute("unit", unit)
	petFrame:RegisterForClicks("AnyUp")
	petFrame:EnableMouse(true)


	petFrame.bg = petFrame:CreateTexture(nil, "BACKGROUND")
	petFrame.bg:SetAllPoints(true)
	petFrame.bg:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\PartyPetFrame\\Media\\UI-PetFrame")
	petFrame.bg:SetDrawLayer("BACKGROUND", 0)


	petFrame.lockIndicator = petFrame:CreateTexture(nil, "OVERLAY")
	petFrame.lockIndicator:SetSize(24, 24)
	petFrame.lockIndicator:SetPoint("TOPRIGHT", petFrame, "TOPRIGHT", -5, -5)
	petFrame.lockIndicator:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
	petFrame.lockIndicator:Hide()


	petFrame.ccGlow = petFrame:CreateTexture(nil, "OVERLAY")
	petFrame.ccGlow:SetAllPoints(true)


	petFrame.ccGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
	petFrame.ccGlow:Hide()


	petFrame.portraitFrame = CreateFrame("Frame", nil, petFrame)
	petFrame.portraitFrame:SetSize(40, 40)
	petFrame.portraitFrame:SetPoint("LEFT", 12, 12)
	petFrame.portraitFrame:SetFrameLevel(0)

	petFrame.portraitIcon = petFrame.portraitFrame:CreateTexture(nil, "ARTWORK")
	petFrame.portraitIcon:SetAllPoints(true)
	petFrame.portraitIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	petFrame.portraitBG = petFrame.portraitFrame:CreateTexture(nil, "BACKGROUND")
	petFrame.portraitBG:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	petFrame.portraitBG:SetAllPoints(true)
	petFrame.portraitBG:SetVertexColor(0, 0, 0, 1)


	petFrame.name = petFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	petFrame.name:SetPoint("TOPLEFT", 65, -10)


	petFrame.healthBar = CreateFrame("StatusBar", nil, petFrame)
	petFrame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	petFrame.healthBar:SetSize(85, 24)
	petFrame.healthBar:SetPoint("TOPLEFT", 60, -10)
	petFrame.healthBar:SetStatusBarColor(0, 1, 0)
	petFrame.healthBar:SetFrameLevel(0)


	petFrame.manaBar = CreateFrame("StatusBar", nil, petFrame)
	petFrame.manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	petFrame.manaBar:SetSize(85, 10)
	petFrame.manaBar:SetPoint("TOPLEFT", petFrame.healthBar, "BOTTOMLEFT", 0, -4)
	petFrame.manaBar:SetFrameLevel(0)





	petFrame.targetText = petFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")


	petFrame.debuffs = {}
	for n = 1, 8 do
		local icon = CreateFrame("Frame", nil, petFrame)
		icon:SetSize(28, 28)
		if n == 1 then
			icon:SetPoint("LEFT", petFrame.healthBar, "RIGHT", 5, 0)
		else
			icon:SetPoint("LEFT", petFrame.debuffs[n-1], "RIGHT", 4, 0)
		end
		icon.texture = icon:CreateTexture(nil, "ARTWORK")
		icon.texture:SetAllPoints(true)
		icon.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		icon.border = icon:CreateTexture(nil, "OVERLAY")
		icon.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		icon.border:SetAllPoints(true)
		icon.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
		icon.border:Hide()

		petFrame.debuffs[n] = icon
	end


	petFrame.buffs = {}
	for n = 1, 8 do
		local icon = CreateFrame("Frame", nil, petFrame)
		icon:SetSize(24, 24)

		icon.texture = icon:CreateTexture(nil, "ARTWORK")
		icon.texture:SetAllPoints(true)
		icon.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		icon.border = icon:CreateTexture(nil, "OVERLAY")
		icon.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		icon.border:SetAllPoints(true)
		icon.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
		icon.border:SetVertexColor(1, 0.82, 0)
		icon.border:Hide()

		petFrame.buffs[n] = icon
	end


	local castBar = CreateFrame("StatusBar", nil, petFrame)
	castBar:SetSize(110, 14)
	castBar:SetPoint("TOPLEFT", petFrame.manaBar, "BOTTOMLEFT", 0, -4)
	castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	castBar:SetStatusBarColor(1, 0.7, 0.2)
	castBar:Hide()
	petFrame.castBar = castBar




	local castBarBG = castBar:CreateTexture(nil, "BACKGROUND")
	castBarBG:SetTexture("Interface\\Buttons\\WHITE8X8")
	castBarBG:SetPoint("TOPLEFT", castBar, "TOPLEFT", -1, 1)
	castBarBG:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 1, -1)
	castBarBG:SetVertexColor(0, 0, 0, 0.7)


	castBar.icon = castBar:CreateTexture(nil, "ARTWORK")
	castBar.icon:SetSize(14, 14)
	castBar.icon:SetPoint("RIGHT", castBar, "LEFT", -3, 0)
	castBar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)


	petFrame.targetText:SetPoint("TOPLEFT", castBar, "BOTTOMLEFT", 0, -2)

	local spark = castBar:CreateTexture(nil, "OVERLAY")
	spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	spark:SetBlendMode("ADD")
	spark:SetSize(24, 24)
	spark:SetPoint("CENTER", castBar:GetStatusBarTexture(), "RIGHT", 0, 0)
	castBar.spark = spark

	castBar.text = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	castBar.text:SetPoint("LEFT", castBar, "LEFT", 4, 0)
	castBar.text:SetJustifyH("LEFT")


	castBar.timeText = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	castBar.timeText:SetPoint("RIGHT", castBar, "RIGHT", -4, 0)
	castBar.timeText:SetJustifyH("RIGHT")









	castBar:SetScript("OnUpdate", function(self)
		if not self.endTime then return end
		local now = GetTime()
		if now >= self.endTime then
			self.endTime = nil
			self:Hide()
			return
		end
		if self.isChannel then

			self:SetValue(self.startTime + self.endTime - now)
		else
			self:SetValue(now)
		end
		self.timeText:SetText(string.format("%.1f", self.endTime - now))
	end)

	return petFrame
end








local function PPF_Layout()
	if InCombatLockdown() then return end
	local pos = PPF_DB()
	local f1 = petFrames[1]
	if not f1 then return end

	f1:ClearAllPoints()
	f1:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER",
		pos.x or DEF_X, pos.y or DEF_Y)

	for i = 2, NUM_PETS do
		local f = petFrames[i]
		if f then
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", petFrames[i-1], "BOTTOMLEFT", 0, -STACK_GAP)
		end
	end
end

local function PPF_SavePosition()
	local f1 = petFrames[1]
	if not f1 then return end
	local point, rel, relPoint, x, y = f1:GetPoint(1)
	if not point then return end





	if rel and rel ~= UIParent then return end
	local pos = PPF_DB()
	pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
end







local function PPF_MakeDraggable(f)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if settings.locked then return end
		if InCombatLockdown() then return end
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		PPF_SavePosition()
		PPF_Layout()
	end)
end

for i = 1, NUM_PETS do
	petFrames[i] = PPF_Build(i)
end
PPF_MakeDraggable(petFrames[1])
PPF_Layout()




local function UpdatePetFrame(pf)
    local unit = pf.unit


    if not UnitExists(unit) then
        if not PPF_HasUnitWatch then PPF_ApplyVisibility(PPF_WantVisible) end
        return
    end
    if not PPF_HasUnitWatch then PPF_ApplyVisibility(PPF_WantVisible) end
    SetPortraitTexture(pf.portraitIcon, unit)
    pf.name:SetText(UnitName(unit) or "Mascota")

    local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
    pf.healthBar:SetMinMaxValues(0, hpMax)
    pf.healthBar:SetValue(hp)

    local powerType = UnitPowerType(unit)
    local power, powerMax = UnitPower(unit), UnitPowerMax(unit)
    pf.manaBar:SetMinMaxValues(0, powerMax)
    pf.manaBar:SetValue(power)

    local colors = {
        [0] = {0, 0, 1},
        [1] = {1, 0, 0},
        [2] = {1, 0.5, 0},
        [3] = {1, 1, 0},
        [6] = {0, 0.8, 1},
    }
    pf.manaBar:SetStatusBarColor(unpack(colors[powerType] or {0,0,1}))


    local targetUnit = unit.."target"
    if UnitExists(targetUnit) then
        local targetName = UnitName(targetUnit) or "Desconocido"
        if #targetName > 15 then
            targetName = strsub(targetName,1,12).."..."
        end


        local _, class = UnitClass(targetUnit)
        local col = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if col and UnitIsPlayer(targetUnit) then
            targetName = string.format("|cff%02x%02x%02x%s|r",
                col.r * 255, col.g * 255, col.b * 255, targetName)
        end
        pf.targetText:SetText((L["PETTARGET_PREFIX"] or "Target: ")..targetName)
    else


        pf.targetText:SetText("")
    end


    local buffIndex = 1
    for i = 1, 16 do
        if IsVisibleBuff(unit, i) then
            local icon = pf.buffs[buffIndex]



            if not icon then break end
            local name, _, texture = UnitBuff(unit, i)
            icon.texture:SetTexture(texture)
            icon:ClearAllPoints()
            if buffIndex == 1 then
                icon:SetPoint("TOPLEFT", pf.portraitFrame, "TOPRIGHT", 8, 30)
            else
                icon:SetPoint("LEFT", pf.buffs[buffIndex-1], "RIGHT", 4, 0)
            end

            icon.border:Show()
            icon.border:SetVertexColor(1, 0.82, 0)

            icon:Show()
            buffIndex = buffIndex + 1
        end
    end
    for j = buffIndex, #pf.buffs do
        pf.buffs[j]:Hide()
        pf.buffs[j].border:Hide()
    end


    for i = 1, 8 do
        local icon = pf.debuffs[i]
        local name, _, texture, debuffType = UnitDebuff(unit, i)
        if name then
            icon:Show()
            icon.texture:SetTexture(texture)

            local colorsDebuff = {
                Magic   = {0.2, 0.6, 1},
                Curse   = {0.6, 0, 1},
                Disease = {0.6, 0.4, 0},
                Poison  = {0, 0.6, 0},
            }

            if debuffType and colorsDebuff[debuffType] then
                icon.border:Show()
                icon.border:SetVertexColor(unpack(colorsDebuff[debuffType]))
            else

                icon.border:Show()
                icon.border:SetVertexColor(0.8, 0.1, 0.1)
            end
        else
            icon:Hide()
            icon.border:Hide()
        end
    end


    if IsUnitCC(unit) then
        pf.ccGlow:Show()
    else
        pf.ccGlow:Hide()
    end

	ApplyPetLortiTint(pf);
end


local function UpdateCastBar(pf)
    local unit    = pf.unit
    local castBar = pf.castBar














    local name, nameSubtext, text, texture, startTime, endTime,
          isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    local isChannel = false
    if not name then
        name, nameSubtext, text, texture, startTime, endTime,
            isTradeSkill, notInterruptible = UnitChannelInfo(unit)
        isChannel = true
    end

    if name and type(startTime) == "number" and type(endTime) == "number" then

        castBar.startTime = startTime / 1000
        castBar.endTime   = endTime / 1000
        castBar.isChannel = isChannel



        castBar:SetMinMaxValues(castBar.startTime, castBar.endTime)
        castBar.text:SetText(name)
        if castBar.icon then
            castBar.icon:SetTexture(texture)
            if texture then castBar.icon:Show() else castBar.icon:Hide() end
        end
        castBar:SetStatusBarColor(notInterruptible and 1 or 0.7, notInterruptible and 0.3 or 0.7, notInterruptible and 0.3 or 0.2)
        castBar:Show()
    else
        castBar.endTime = nil
        castBar:Hide()
    end
end

local function UpdateAll()
    for i = 1, NUM_PETS do
        local pf = petFrames[i]
        if pf then
            UpdatePetFrame(pf)
            UpdateCastBar(pf)
        end
    end
end














local timeSinceLastUpdate = 0
local function PPF_OnUpdate(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate < 0.1 then return end
    timeSinceLastUpdate = 0
    for i = 1, NUM_PETS do
        local pf = petFrames[i]
        if pf and pf:IsShown() then
            UpdatePetFrame(pf)
            UpdateCastBar(pf)
        end
    end
end







local PPF_EVENTS = { "UNIT_HEALTH", "UNIT_MANA", "UNIT_MAXMANA", "UNIT_FOCUS", "UNIT_ENERGY", "UNIT_RAGE", "UNIT_HAPPINESS", "UNIT_TARGET", "UNIT_PET", "PLAYER_ENTERING_WORLD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_DELAYED", "UNIT_AURA", "GROUP_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_BATTLEGROUND", "PLAYER_LEAVING_BATTLEGROUND", "DUEL_FINISHED", "INSTANCE_GROUP_SIZE_CHANGED", "UPDATE_INSTANCE_INFO" };





local function PetFrameFor(unitID)
    if type(unitID) ~= "string" then return nil end
    local n = string.match(unitID, "^party(%d)pet$")
    if not n then return nil end
    return petFrames[tonumber(n)]
end


local function PetFrameForOwner(unitID)
    if type(unitID) ~= "string" then return nil end
    local n = string.match(unitID, "^party(%d)$")
    if not n then return nil end
    return petFrames[tonumber(n)]
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then

        PPF_ApplyVisibility(PPF_WantVisible)
        UpdateAll()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "DUEL_FINISHED" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_LEAVING_BATTLEGROUND" or event == "INSTANCE_GROUP_SIZE_CHANGED" or event == "UPDATE_INSTANCE_INFO" then



        TimerAfter(0.5, function()
            PPF_ApplyVisibility(PPF_WantVisible)
            UpdateAll()
        end)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        UpdateAll()
    elseif event == "UNIT_PET" then
        local pf = PetFrameForOwner(arg1)
        if pf then UpdatePetFrame(pf) end
    elseif event == "UNIT_TARGET" or event == "UNIT_AURA"
        or event == "UNIT_HEALTH" or event == "UNIT_MANA" or event == "UNIT_MAXMANA"
        or event == "UNIT_FOCUS" or event == "UNIT_ENERGY" or event == "UNIT_RAGE"
        or event == "UNIT_HAPPINESS" then
        local pf = PetFrameFor(arg1)
        if pf then UpdatePetFrame(pf) end
    elseif string.find(event, "UNIT_SPELLCAST") then
        local pf = PetFrameFor(arg1)
        if pf then UpdateCastBar(pf) end
    end
end)


local function ToggleLock()
    settings.locked = not settings.locked

    for i = 1, NUM_PETS do
        local f = petFrames[i]
        if f then
            if settings.locked then
                f:EnableMouse(settings.clickable)
                f.lockIndicator:Show()
            else
                f:EnableMouse(true)
                f.lockIndicator:Hide()
            end
        end
    end

    petFrames[1]:SetMovable(not settings.locked)


end

local function ToggleClickable()
    settings.clickable = not settings.clickable

    for i = 1, NUM_PETS do
        local f = petFrames[i]
        if f then
            if settings.clickable then
                f:SetAttribute("type1", "target")
            else
                f:SetAttribute("type1", nil)
            end

            if settings.locked then f:EnableMouse(settings.clickable) end
        end
    end

    if settings.clickable then
        print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_CLICK_ON"] or "Click enabled - click to target the pet"))
    else
        print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_CLICK_OFF"] or "Click disabled"))
    end
end

local function ResetPosition()
    local pos = PPF_DB()
    pos.point, pos.relPoint, pos.x, pos.y = "CENTER", "CENTER", DEF_X, DEF_Y
    PPF_Layout()
end


SLASH_PARTYPETFRAME1 = "/ppf"
SLASH_PARTYPETFRAME2 = "/partypetframe"
SlashCmdList["PARTYPETFRAME"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "lock" or msg == "bloquear" then
        ToggleLock()
    elseif msg == "click" or msg == "clic" then
        ToggleClickable()
    elseif msg == "arena" then
        local on = not PPF_ArenaOnly()
        if K.SaveConfig then K.SaveConfig("PartyPetArenaOnly", on) else C.PartyPetArenaOnly = on end
        PPF_ApplyVisibility(PPF_WantVisible)
        if on then
            print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_ARENA_ONLY"] or "Arenas only"))
        else
            print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_EVERYWHERE"] or "Everywhere"))
        end
    elseif msg == "reset" then
        ResetPosition()
        print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_POS_RESET"] or "Position reset"))
    else
        print("|cff00ff00[PartyPetFrame] " .. (L["CMD_COMMANDS_TITLE"] or "Commands:") .. "|r")
        print("  /ppf lock - " .. (L["PPF_HELP_LOCK"] or "Lock/unlock the row"))
        print("  /ppf click - " .. (L["PPF_HELP_CLICK"] or "Enable/disable click to target"))
        print("  /ppf arena - " .. (L["PPF_HELP_ARENA"] or "Switch between arenas only and everywhere"))
        print("  /ppf reset - " .. (L["PPF_HELP_RESET"] or "Reset the row position"))
        print("  |cff8A8A8A" .. (L["PPF_HELP_DRAG"] or "Drag the top frame: the other three follow it.") .. "|r")
    end
end




local function PPF_SetEnabled(on)
    if on then
        for _, e in ipairs(PPF_EVENTS) do pcall(frame.RegisterEvent, frame, e) end
        frame:SetScript("OnUpdate", PPF_OnUpdate)
        PPF_Layout()
        PPF_ApplyVisibility(true)
        UpdateAll()
    else
        frame:UnregisterAllEvents()
        frame:SetScript("OnUpdate", nil)
        PPF_ApplyVisibility(false)
    end
end

function K.TogglePartyPetFrameLock()
    ToggleLock()
end

function K.ResetPartyPetFramePosition()
    ResetPosition()
end



if K.LayoutRegisterStore then
    K.LayoutRegisterStore("PartyPetFrames", function()
        PPF_Layout()
    end)
end

K.RegisterModule("PartyPetFrame", {
    name    = L["MOD_PARTYPETFRAME"] or "Party pet enhanced",
    desc    = L["MOD_PARTYPETFRAME_DESC"]
        or "Custom frames for your party members' pets (party 1-4): portrait, health/mana, cast bar and CC warning. Arena only by default; /ppf for commands.",
    default = false,
    hideFromModulesTab = true,
    onEnable  = function() PPF_SetEnabled(true) end,
    onDisable = function() PPF_SetEnabled(false) end,
});
