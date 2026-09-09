local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PaladinICD.lua  (integrado a NUF, de NidhausTools)
-- CD interno visual de las defensivas de paladin (Divine Protection,
-- Escudo Divino, Mano de Proteccion, Ira Vengadora, Imposicion de Manos).
--
-- CAMBIOS respecto del addon suelto:
--   * Se prende/apaga como modulo de NUF; COMBAT_LOG solo se registra con
--     el modulo activo. Si no sos paladin, ni se crea ni aparece.
-- =========================================================

local _, class = UnitClass("player")
if class ~= "PALADIN" then return end

local DURATION = 30
local ICON_DEFAULT = "Interface\\Icons\\Spell_Holy_AvengineWrath"
local ICON_AVENGING_WRATH = "Interface\\Icons\\Spell_Holy_DivineIntervention"

-- nombres que ponen el CD en marcha via SPELL_AURA_APPLIED sobre uno mismo
-- (se agrego Avenging Wrath, que en el WeakAura original faltaba en esta lista
-- aunque tenia logica de icono para el - bug del autor)
local WATCHED_SELF_BUFFS = {
    ["Divine Protection"] = true,
    ["Divine Shield"] = true,
    ["Hand of Protection"] = true,
    ["Avenging Wrath"] = true,
}

local playerName = UnitName("player")

-- Mismo caso que DTSU: SavedVariables se carga DESPUES de este archivo, asi que
-- "X = X or {...}" no sirve si la tabla guardada viene vacia o incompleta.
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

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetAllPoints()
frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
-- MISMA LOGICA QUE PAB: mientras el cooldown corre el icono va en gris
-- (SetDesaturated(true)) y al quedar listo vuelve a color
-- (SetDesaturated(false)). Antes estaba fijo en gris siempre.
frame.icon:SetDesaturated(true)
frame.icon:SetVertexColor(0.45, 0.45, 0.45)

frame.border = frame:CreateTexture(nil, "BACKGROUND")
frame.border:SetPoint("TOPLEFT", frame.icon, -1, 1)
frame.border:SetPoint("BOTTOMRIGHT", frame.icon, 1, -1)
frame.border:SetTexture("Interface\\Buttons\\WHITE8x8")
frame.border:SetVertexColor(0, 0, 0, 1)

-- Cooldown nativo: sin numero/barra propios - lo maneja OmniCC (el usuario ya
-- tiene OmniCC para los numeros, aca solo damos el swipe/animacion estandar)
frame.cooldown = CreateFrame("Cooldown", "PaladinICDCooldown", frame, "CooldownFrameTemplate")
frame.cooldown:SetAllPoints(frame.icon)
frame.cooldown:SetDrawEdge(false)
frame.cooldown:SetReverse(true)

-- fondo verde para el modo mover
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

-- Gris de "en cooldown", igual que PAB.
-- SetDesaturated depende de que el cliente tenga los efectos de shader
-- activados: si estan apagados NO hace nada y el icono queda a color. Por eso
-- se combina con SetVertexColor, que oscurece siempre. Con shaders queda gris
-- puro; sin shaders, igual se ve apagado.
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
    if name == "Avenging Wrath" then
        frame.icon:SetTexture(ICON_AVENGING_WRATH)
    else
        frame.icon:SetTexture(ICON_DEFAULT)
    end
end

-- remaining: por si el relog necesita arrancar con menos tiempo restante que el DURATION completo
local function StartCooldown(name, remaining)
    remaining = remaining or DURATION
    if remaining <= 0 then return end
    expire = GetTime() + remaining
    SetIconForName(name)
    frame.cooldown:SetCooldown(GetTime() - (DURATION - remaining), DURATION)
    SetIconGray(true)                 -- en cooldown = gris (como PAB)
    frame:Show()
end

frame:SetScript("OnUpdate", function(self)
    if not self:IsShown() or self.dragMode then return end
    if expire - GetTime() <= 0 then
        -- Cooldown terminado: vuelve a COLOR (logica de PAB). Si esta
        -- activada la opcion de dejarlo a la vista, se queda mostrando el
        -- icono a color para saber que ya lo tenes listo; si no, se oculta
        -- como antes.
        SetIconGray(false)
        if not C.PaladinICDKeepVisible then
            self:Hide()
        end
    end
end)

-- El registro de eventos lo maneja el modulo (onEnable/onDisable): con el
-- modulo apagado no escucha COMBAT_LOG.
local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- funcion de relog: si el buff ya esta activo cuando entras/recargas,
        -- restauramos el icono con el tiempo restante real del buff
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

        -- Lay on Hands no deja buff propio, pero si aplica el debuff Forbearance
        -- lo usamos como aproximacion de que se uso alguna de las defensivas
        if not frame:IsShown() then
            for i = 1, 40 do
                local name, _, _, _, _, _, expirationTime = UnitDebuff("player", i)
                if not name then break end
                if name == "Forbearance" then
                    local remaining = expirationTime - GetTime()
                    if remaining > 0 then
                        StartCooldown("Lay on Hands", math.min(remaining, DURATION))
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
        if sourceName == playerName and destName == playerName and spellName == "Lay on Hands" then
            StartCooldown(spellName)
        end
    end
end)

-- ===== mover / reset (expuesto para el panel de NUF y el slash) =====
function K.TogglePaladinICDMove()
    frame.dragMode = not frame.dragMode
    frame:EnableMouse(frame.dragMode)
    if frame.dragMode then
        frame.dragBg:Show()
        frame:Show()
    else
        frame.dragBg:Hide()
        if expire - GetTime() <= 0 then
            frame:Hide()
        end
    end
    return frame.dragMode
end

-- Preview para el modo "Mover todo": sin esto el icono esta oculto
-- mientras no corre ningun cooldown, y el recuadro azul apuntaba a un
-- frame invisible — no habia forma de ver donde lo estabas poniendo.
function K.SetPaladinICDPreview(state)
    if state then
        frame.preview = true
        SetIconForName(nil)
        SetIconGray(false)
        frame.cooldown:SetCooldown(0, 0)
        frame:Show()
    else
        frame.preview = false
        if not frame.dragMode and (expire - GetTime()) <= 0
           and not C.PaladinICDKeepVisible then
            frame:Hide()
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
    print(on and "|cff00ff00PaladinICD|r: modo mover activado, arrastra. /paladinicd de nuevo para fijar."
        or "|cff00ff00PaladinICD|r: posicion fijada.")
end

-- Muestra el icono "listo" (a color) cuando la opcion de dejarlo a la vista
-- esta activada y no hay ningun cooldown corriendo.
function K.ApplyPaladinICDVisibility()
    local onCD = (expire - GetTime()) > 0
    if onCD then return end          -- si corre el CD, no tocar nada
    if C.PaladinICDKeepVisible then
        SetIconForName(nil)          -- icono por defecto
        SetIconGray(false)
        frame.cooldown:SetCooldown(0, 0)
        frame:Show()
    elseif not frame.dragMode then
        frame:Hide()
    end
end

-- ===== integracion NUF: on/off del modulo =====
local function PICD_SetEnabled(on)
    if on then
        ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        ev:RegisterEvent("PLAYER_ENTERING_WORLD")
        K.ApplyPaladinICDVisibility()
    else
        ev:UnregisterAllEvents()
        frame:Hide()
    end
end

K.RegisterModule("PaladinICD", {
    name    = L["MOD_PALADIN_ICD"] or "Paladin ICD",
    desc    = L["MOD_PALADIN_ICD_DESC"]
        or "Visual internal cooldown of your paladin defensives (Divine Protection, Divine Shield, Hand of Protection, Avenging Wrath, Lay on Hands). /paladinicd to move it.",
    default = false,
    hideFromModulesTab = true,  -- vive en Interface > General > Paladin
    onEnable  = function() PICD_SetEnabled(true) end,
    onDisable = function() PICD_SetEnabled(false) end,
});