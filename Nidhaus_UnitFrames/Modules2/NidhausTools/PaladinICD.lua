local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- SOLO PALADIN. Para las demas clases el archivo termina aca, antes de crear
-- nada: Lua descarta todo su codigo y el modulo no ocupa memoria. El panel,
-- el modo mover y los comandos ya preguntan si el modulo existe.
if select(2, UnitClass("player")) ~= "PALADIN" then return; end

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
-- Los nombres salen de GetSpellInfo (vienen en el idioma del cliente): el
-- combat log y UnitBuff los dan traducidos, y en ingles fijo no coincidian.
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

-- Escala con slider en el panel (y Ctrl + rueda en "Mover todo", que ahora
-- escribe en el mismo lugar). Antes solo tenia la rueda.
if K.RegisterScalable then K.RegisterScalable("PaladinICD", frame, 1.0) end

local enabled = false

-- Donde se muestra (Arena / BG / Duelos / Mundo, ver ModuleManager). El
-- cooldown se sigue contando aunque no se vea: si entras a una zona
-- tildada con el CD corriendo, aparece con el tiempo que le queda.
local function ZoneOK()
    if not K.ModuleZoneAllowed then return true end
    return K.ModuleZoneAllowed("PaladinICD")
end

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
    if name == AVENGING_WRATH then
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
    if ZoneOK() or frame.dragMode or frame.preview then
        frame:Show()
    end
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

-- ===== mover / reset (expuesto para el panel de NUF y el slash) =====
function K.TogglePaladinICDMove()
    frame.dragMode = not frame.dragMode
    frame:EnableMouse(frame.dragMode)
    if frame.dragMode then
        frame.dragBg:Show()
        frame:Show()
    else
        frame.dragBg:Hide()
        -- Al fijar queda como corresponde: con el CD corriendo, con
        -- "dejarlo en pantalla" o escondido. Antes se escondia siempre que
        -- no hubiera CD, aunque tuvieras tildado dejarlo a la vista.
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

-- Muestra el icono "listo" (a color) cuando la opcion de dejarlo a la vista
-- esta activada y no hay ningun cooldown corriendo.
function K.ApplyPaladinICDVisibility()
    -- Mientras lo estas moviendo (o en "Mover todo") se queda a la vista.
    if frame.dragMode or frame.preview then return end
    -- Fuera de las zonas elegidas no se muestra.
    if not ZoneOK() then
        frame:Hide()
        return
    end
    local onCD = (expire - GetTime()) > 0
    if onCD then                     -- si corre el CD, que se vea
        frame:Show()
        return
    end
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

-- Cambiar una casilla de zona, o de zona, lo pone al dia en el acto.
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
    hideFromModulesTab = true,  -- vive en Interface > General > Paladin
    onEnable  = function() PICD_SetEnabled(true) end,
    onDisable = function() PICD_SetEnabled(false) end,
});