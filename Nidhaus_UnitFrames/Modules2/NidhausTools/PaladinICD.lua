local AddOnName, ns = ...;
local K, C, L = unpack(ns);

if select(2, UnitClass("player")) ~= "PALADIN" then return; end

local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local DURATION = 30
local ICON_DEFAULT = "Interface\\Icons\\Spell_Holy_AvengineWrath"
local ICON_AVENGING_WRATH = "Interface\\Icons\\Spell_Holy_DivineIntervention"

local function SpellName(id, fallback) return GetSpellInfo(id) or fallback end
local DIVINE_PROTECTION  = SpellName(498,   "Divine Protection")
local DIVINE_SHIELD      = SpellName(642,   "Divine Shield")
local HAND_OF_PROTECTION = SpellName(1022,  "Hand of Protection")
local AVENGING_WRATH     = SpellName(31884, "Avenging Wrath")
local LAY_ON_HANDS       = SpellName(633,   "Lay on Hands")
local FORBEARANCE        = SpellName(25771, "Forbearance")

local WATCHED_SELF_BUFFS = {
    [DIVINE_PROTECTION] = true,
    [DIVINE_SHIELD] = true,
    [HAND_OF_PROTECTION] = true,
    [AVENGING_WRATH] = true,
}

local playerName = UnitName("player")

local ICD_DEFAULTS = { point = "CENTER", x = 0, y = -168 }

PaladinICD_DB = PaladinICD_DB or {}

local function ApplyICDDefaults()
    PaladinICD_DB = PaladinICD_DB or {}
    for k, v in pairs(ICD_DEFAULTS) do
        if PaladinICD_DB[k] == nil then PaladinICD_DB[k] = v end
    end
end
ApplyICDDefaults()

local icdLoader = CreateFrame("Frame")
icdLoader:RegisterEvent("ADDON_LOADED")
icdLoader:SetScript("OnEvent", function(self, event, addon)
    if addon ~= AddOnName then return end
    ApplyICDDefaults()
    if PaladinICDFrame then
        PaladinICDFrame:ClearAllPoints()
        PaladinICDFrame:SetPoint(PaladinICD_DB.point, UIParent, PaladinICD_DB.point, PaladinICD_DB.x, PaladinICD_DB.y)
    end
    self:UnregisterEvent("ADDON_LOADED")
end)

local frame = CreateFrame("Frame", "PaladinICDFrame", UIParent)
frame:SetSize(50, 50)
frame:SetPoint(PaladinICD_DB.point, UIParent, PaladinICD_DB.point, PaladinICD_DB.x, PaladinICD_DB.y)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(false)
frame:Hide()

if K.RegisterScalable then K.RegisterScalable("PaladinICD", frame, 1.0) end

local enabled = false

local function ZoneOK()
    if not K.ModuleZoneAllowed then return true end
    return K.ModuleZoneAllowed("PaladinICD")
end

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetAllPoints()
frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

frame.icon:SetDesaturated(true)
frame.icon:SetVertexColor(0.45, 0.45, 0.45)

frame.border = frame:CreateTexture(nil, "BACKGROUND")
frame.border:SetPoint("TOPLEFT", frame.icon, -1, 1)
frame.border:SetPoint("BOTTOMRIGHT", frame.icon, 1, -1)
frame.border:SetTexture("Interface\\Buttons\\WHITE8x8")
frame.border:SetVertexColor(0, 0, 0, 1)

frame.cooldown = CreateFrame("Cooldown", "PaladinICDCooldown", frame, "CooldownFrameTemplate")
frame.cooldown:SetAllPoints(frame.icon)
frame.cooldown:SetDrawEdge(false)
frame.cooldown:SetReverse(true)

frame.dragBg = frame:CreateTexture(nil, "BACKGROUND")
frame.dragBg:SetAllPoints()
frame.dragBg:SetTexture(0, 1, 0, 0.3)
frame.dragBg:Hide()

frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
    if self.dragMode then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    PaladinICD_DB.point = point
    PaladinICD_DB.x = x
    PaladinICD_DB.y = y
end)

local expire = 0

local function SetIconGray(gray)
    if gray then
        frame.icon:SetDesaturated(true)
        frame.icon:SetVertexColor(0.45, 0.45, 0.45)
    else
        frame.icon:SetDesaturated(false)
        frame.icon:SetVertexColor(1, 1, 1)
    end
end

local function SetIconForName(name)
    if name == AVENGING_WRATH then
        frame.icon:SetTexture(ICON_AVENGING_WRATH)
    else
        frame.icon:SetTexture(ICON_DEFAULT)
    end
end

local function StartCooldown(name, remaining)
    remaining = remaining or DURATION
    if remaining <= 0 then return end
    expire = GetTime() + remaining
    SetIconForName(name)
    frame.cooldown:SetCooldown(GetTime() - (DURATION - remaining), DURATION)
    SetIconGray(true)
    if ZoneOK() or frame.dragMode or frame.preview then
        frame:Show()
    end
end

frame:SetScript("OnUpdate", function(self)
    if not self:IsShown() or self.dragMode then return end
    if expire - GetTime() <= 0 then

        SetIconGray(false)
        if not C.PaladinICDKeepVisible then
            self:Hide()
        end
    end
end)

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then

        for i = 1, 40 do
            local name, _, _, _, _, _, expirationTime = UnitBuff("player", i)
            if not name then break end
            if WATCHED_SELF_BUFFS[name] then
                local remaining = expirationTime - GetTime()
                if remaining > 0 then
                    StartCooldown(name, math.min(remaining, DURATION))
                end
            end
        end

        if not frame:IsShown() then
            for i = 1, 40 do
                local name, _, _, _, _, _, expirationTime = UnitDebuff("player", i)
                if not name then break end
                if name == FORBEARANCE then
                    local remaining = expirationTime - GetTime()
                    if remaining > 0 then
                        StartCooldown(LAY_ON_HANDS, math.min(remaining, DURATION))
                    end
                    break
                end
            end
        end
        return
    end

    local _, subevent, _, sourceName, _, _, destName, _, a1, a2 = ...

    if subevent == "SPELL_AURA_APPLIED" then
        local spellName = a2
        if destName == playerName and WATCHED_SELF_BUFFS[spellName] then
            StartCooldown(spellName)
        end
    elseif subevent == "SPELL_CAST_SUCCESS" then
        local spellName = a2
        if sourceName == playerName and destName == playerName and spellName == LAY_ON_HANDS then
            StartCooldown(spellName)
        end
    end
end)

function K.TogglePaladinICDMove()
    frame.dragMode = not frame.dragMode
    frame:EnableMouse(frame.dragMode)
    if frame.dragMode then
        frame.dragBg:Show()

        if (expire - GetTime()) <= 0 then
            SetIconForName(nil)
            SetIconGray(false)
            frame.cooldown:SetCooldown(0, 0)
        end
        frame:Show()
    else
        frame.dragBg:Hide()

        if enabled and K.ApplyPaladinICDVisibility then
            K.ApplyPaladinICDVisibility()
        elseif expire - GetTime() <= 0 then
            frame:Hide()
        end
    end
    return frame.dragMode
end

function K.IsPaladinICDMoving() return frame.dragMode and true or false end

function K.SetPaladinICDMove(state)
    if (state and true or false) ~= (frame.dragMode and true or false) then
        K.TogglePaladinICDMove()
    end
    return frame.dragMode and true or false
end

function K.SetPaladinICDPreview(state)
    if state then
        frame.preview = true
        SetIconForName(nil)
        SetIconGray(false)
        frame.cooldown:SetCooldown(0, 0)
        frame:Show()
    else
        frame.preview = false
        if not frame.dragMode then
            if enabled and K.ApplyPaladinICDVisibility then
                K.ApplyPaladinICDVisibility()
            elseif (expire - GetTime()) <= 0 and not C.PaladinICDKeepVisible then
                frame:Hide()
            end
        end
    end
end

function K.ResetPaladinICDPosition()
    PaladinICD_DB.point, PaladinICD_DB.x, PaladinICD_DB.y = "CENTER", 0, -168
    frame:ClearAllPoints()
    frame:SetPoint(PaladinICD_DB.point, UIParent, PaladinICD_DB.point, PaladinICD_DB.x, PaladinICD_DB.y)
end

SLASH_PALADINICD1 = "/paladinicd"
SlashCmdList["PALADINICD"] = function()
    local on = K.TogglePaladinICDMove()
    print("|cff00ff00PaladinICD|r: " .. (on
        and (L["PALADINICD_MOVE_ON"] or "Move mode on: drag it, then /paladinicd again to lock it.")
        or (L["PALADINICD_MOVE_OFF"] or "Position locked.")))
end

function K.ApplyPaladinICDVisibility()

    if frame.dragMode or frame.preview then return end

    if not ZoneOK() then
        frame:Hide()
        return
    end
    local onCD = (expire - GetTime()) > 0
    if onCD then
        frame:Show()
        return
    end
    if C.PaladinICDKeepVisible then
        SetIconForName(nil)
        SetIconGray(false)
        frame.cooldown:SetCooldown(0, 0)
        frame:Show()
    elseif not frame.dragMode then
        frame:Hide()
    end
end

local function PICD_SetEnabled(on)
    enabled = on and true or false
    if on then
        ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        ev:RegisterEvent("PLAYER_ENTERING_WORLD")
        K.ApplyPaladinICDVisibility()
    else
        ev:UnregisterAllEvents()
        frame:Hide()
    end
end

if K.RegisterModuleZones then
    K.RegisterModuleZones("PaladinICD",
        function()
            PaladinICD_DB = PaladinICD_DB or {}
            return PaladinICD_DB
        end,
        function()
            if enabled then K.ApplyPaladinICDVisibility() end
        end)
end

K.RegisterModule("PaladinICD", {
    name    = L["MOD_PALADIN_ICD"] or "Paladin ICD",
    desc    = L["MOD_PALADIN_ICD_DESC"]
        or "Visual internal cooldown of your paladin defensives (Divine Protection, Divine Shield, Hand of Protection, Avenging Wrath, Lay on Hands). /paladinicd to move it.",
    default = false,
    hideFromModulesTab = true,
    onEnable  = function() PICD_SetEnabled(true) end,
    onDisable = function() PICD_SetEnabled(false) end,
});
