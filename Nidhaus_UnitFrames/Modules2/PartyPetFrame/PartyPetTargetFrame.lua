local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PartyPetTargetFrame.lua  (integrado a NUF)
-- Marco propio para la mascota del compañero 1 (party1pet): retrato,
-- vida/mana, casteo, buffs/debuffs y aviso de CC.
--
-- CAMBIOS respecto del addon suelto:
--   * Es un modulo de NUF: checkbox propio en Frames > Party y los
--     eventos solo se registran con el modulo activo.
--   * UNIT_POWER_UPDATE no existe en 3.3.5a (es de retail): se cambio
--     por los eventos de recurso reales de WotLK.
--   * La textura CC-Glow no venia en el paquete: se usa una nativa.
--   * Se saco el print de carga.
-- =========================================================

local addonName = "PartyPetTargetFrame"
local frame = CreateFrame("Frame", addonName.."Frame", UIParent)

-- C_Timer.After is not available in WotLK (3.x); use a frame-based fallback
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

-- Variables de configuración
local settings = {
    locked = false,
    clickable = true
}

local petFrame = CreateFrame("Button", "CustomParty1PetFrame", UIParent, "SecureUnitButtonTemplate")
petFrame:SetSize(160, 80)
petFrame:SetPoint("CENTER", UIParent, "CENTER", 300, 100)
petFrame:SetMovable(true)
petFrame:EnableMouse(true)
petFrame:RegisterForDrag("LeftButton")
petFrame:SetScript("OnDragStart", petFrame.StartMoving)
petFrame:SetScript("OnDragStop", petFrame.StopMovingOrSizing)
petFrame.unit = "party1pet"

-- Configurar atributos para clic
petFrame:SetAttribute("type1", "target")
petFrame:SetAttribute("unit", "party1pet")
petFrame:RegisterForClicks("AnyUp")

-- Fondo
petFrame.bg = petFrame:CreateTexture(nil, "BACKGROUND")
petFrame.bg:SetAllPoints(true)
petFrame.bg:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\PartyPetFrame\\Media\\UI-PetFrame")
petFrame.bg:SetDrawLayer("BACKGROUND", 0)

-- Indicador de bloqueo
petFrame.lockIndicator = petFrame:CreateTexture(nil, "OVERLAY")
petFrame.lockIndicator:SetSize(24, 24)
petFrame.lockIndicator:SetPoint("TOPRIGHT", petFrame, "TOPRIGHT", -5, -5)
petFrame.lockIndicator:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
petFrame.lockIndicator:Hide()

-- Glow CC
petFrame.ccGlow = petFrame:CreateTexture(nil, "OVERLAY")
petFrame.ccGlow:SetAllPoints(true)
-- La textura CC-Glow no venia incluida en el addon: se usa el aro de
-- seleccion de Blizzard, que existe siempre.
petFrame.ccGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
petFrame.ccGlow:Hide()

-- Retrato
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

-- Nombre
petFrame.name = petFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
petFrame.name:SetPoint("TOPLEFT", 65, -10)

-- Vida
petFrame.healthBar = CreateFrame("StatusBar", nil, petFrame)
petFrame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
petFrame.healthBar:SetSize(85, 24)
petFrame.healthBar:SetPoint("TOPLEFT", 60, -10)
petFrame.healthBar:SetStatusBarColor(0, 1, 0)
petFrame.healthBar:SetFrameLevel(0)

-- Mana / Rage / Focus / Energy
petFrame.manaBar = CreateFrame("StatusBar", nil, petFrame)
petFrame.manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
petFrame.manaBar:SetSize(85, 10)
petFrame.manaBar:SetPoint("TOPLEFT", petFrame.healthBar, "BOTTOMLEFT", 0, -4)
petFrame.manaBar:SetFrameLevel(0)

-- Texto objetivo
petFrame.targetText = petFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
petFrame.targetText:SetPoint("BOTTOMLEFT", 40, 10)

-- Debuffs
petFrame.debuffs = {}
for i = 1, 8 do
    local icon = CreateFrame("Frame", nil, petFrame)
    icon:SetSize(28, 28)
    if i == 1 then
        icon:SetPoint("LEFT", petFrame.healthBar, "RIGHT", 5, 0)
    else
        icon:SetPoint("LEFT", petFrame.debuffs[i-1], "RIGHT", 4, 0)
    end
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints(true)
    icon.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    icon.border = icon:CreateTexture(nil, "OVERLAY")
    icon.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    icon.border:SetAllPoints(true)
    icon.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    icon.border:Hide()

    petFrame.debuffs[i] = icon
end

-- Buffs (CON BORDES AGREGADOS)
petFrame.buffs = {}
for i = 1, 8 do
    local icon = CreateFrame("Frame", nil, petFrame)
    icon:SetSize(24, 24)
    
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints(true)
    icon.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    
    -- NUEVO: Borde para buffs
    icon.border = icon:CreateTexture(nil, "OVERLAY")
    icon.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    icon.border:SetAllPoints(true)
    icon.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    icon.border:SetVertexColor(1, 0.82, 0) -- Color dorado por defecto
    icon.border:Hide()
    
    petFrame.buffs[i] = icon
end

-- Castbar
local castBar = CreateFrame("StatusBar", nil, petFrame)
castBar:SetSize(110, 14)
castBar:SetPoint("TOPLEFT", petFrame.manaBar, "BOTTOMLEFT", 0, -4)
castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
castBar:SetStatusBarColor(1, 0.7, 0.2)
castBar:Hide()
petFrame.castBar = castBar

local border = castBar:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
border:SetSize(138, 54)
border:SetPoint("CENTER", castBar, "CENTER", 0, 0)

-- ---------------------------------------------------------
-- Tinte de Lorti UI
--
-- El marco de la mascota y el borde de su barra de casteo son arte de
-- Blizzard sin tocar, asi que con Lorti puesto quedaban dorados y
-- brillantes al lado del resto oscurecido. Piden el tinte por el mismo
-- camino que el grupo, arena y los target de grupo: si Lorti esta
-- apagado, ApplyLortiTint repone el blanco y todo queda como antes.
-- ---------------------------------------------------------
local function ApplyPetLortiTint()
	if not K.ApplyLortiTint then return; end
	K.ApplyLortiTint(petFrame.bg, "LortiUI_PartyPet");
	K.ApplyLortiTint(border,      "LortiUI_PartyPet");
end

local spark = castBar:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetBlendMode("ADD")
spark:SetSize(24, 24)
spark:SetPoint("CENTER", castBar:GetStatusBarTexture(), "RIGHT", 0, 0)
castBar.spark = spark

castBar.text = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
castBar.text:SetPoint("CENTER", castBar, "CENTER", 0, 0)
castBar.text:SetJustifyH("CENTER")

-- Auras a ocultar
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

-- CC detection
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

-- Buff visible según Castable Buffs
local function IsVisibleBuff(unit, index)
    local name, _, _, _, _, _, caster = UnitBuff(unit, index)
    if not name then return false end
    if hiddenAuras[name] then return false end
    if caster == "player" then return true end
    return GetCVar("showCastableBuffs") == "1" and UnitCanAssist("player", unit)
end

-- Actualización del frame de mascota
local function UpdatePetFrame()
    local unit = "party1pet"
    if not UnitExists(unit) then
        petFrame:Hide()
        return
    end

    petFrame:Show()
    SetPortraitTexture(petFrame.portraitIcon, unit)
    petFrame.name:SetText(UnitName(unit) or "Mascota")

    local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
    petFrame.healthBar:SetMinMaxValues(0, hpMax)
    petFrame.healthBar:SetValue(hp)

    local powerType = UnitPowerType(unit)
    local power, powerMax = UnitPower(unit), UnitPowerMax(unit)
    petFrame.manaBar:SetMinMaxValues(0, powerMax)
    petFrame.manaBar:SetValue(power)

    local colors = {
        [0] = {0, 0, 1},
        [1] = {1, 0, 0},
        [2] = {1, 0.5, 0},
        [3] = {1, 1, 0},
        [6] = {0, 0.8, 1},
    }
    petFrame.manaBar:SetStatusBarColor(unpack(colors[powerType] or {0,0,1}))

    -- Objetivo
    local targetUnit = unit.."target"
    if UnitExists(targetUnit) then
        local targetName = UnitName(targetUnit) or "Desconocido"
        if #targetName > 15 then
            targetName = strsub(targetName,1,12).."..."
        end
        petFrame.targetText:SetText((L["PETTARGET_PREFIX"] or "Target: ")..targetName)
    else
        petFrame.targetText:SetText(L["PETTARGET_NONE"] or "Target: None")
    end

    -- Buffs con bordes
    local buffIndex = 1
    for i = 1, 16 do
        if IsVisibleBuff(unit, i) then
            local icon = petFrame.buffs[buffIndex]
            -- El pool son 8 iconos y este bucle recorre hasta 16 buffs.
            -- Con 9 o mas buffs visibles 'icon' venia nil y tiraba
            -- "attempt to index local 'icon'" en cada OnUpdate.
            if not icon then break end
            local name, _, texture = UnitBuff(unit, i)
            icon.texture:SetTexture(texture)
            icon:ClearAllPoints()
            if buffIndex == 1 then
                icon:SetPoint("TOPLEFT", petFrame.portraitFrame, "TOPRIGHT", 8, 30)
            else
                icon:SetPoint("LEFT", petFrame.buffs[buffIndex-1], "RIGHT", 4, 0)
            end
            
            -- NUEVO: Mostrar borde dorado en buffs
            icon.border:Show()
            icon.border:SetVertexColor(1, 0.82, 0) -- Dorado
            
            icon:Show()
            buffIndex = buffIndex + 1
        end
    end
    for j = buffIndex, #petFrame.buffs do
        petFrame.buffs[j]:Hide()
        petFrame.buffs[j].border:Hide()
    end

    -- Debuffs con bordes de colores según tipo
    for i = 1, 8 do
        local icon = petFrame.debuffs[i]
        local name, _, texture, debuffType = UnitDebuff(unit, i)
        if name then
            icon:Show()
            icon.texture:SetTexture(texture)
            
            local colorsDebuff = {
                Magic   = {0.2, 0.6, 1},      -- Azul
                Curse   = {0.6, 0, 1},        -- Morado
                Disease = {0.6, 0.4, 0},      -- Marrón
                Poison  = {0, 0.6, 0},        -- Verde
            }
            
            if debuffType and colorsDebuff[debuffType] then
                icon.border:Show()
                icon.border:SetVertexColor(unpack(colorsDebuff[debuffType]))
            else
                -- Si no tiene tipo específico, mostrar borde rojo genérico
                icon.border:Show()
                icon.border:SetVertexColor(0.8, 0.1, 0.1) -- Rojo
            end
        else
            icon:Hide()
            icon.border:Hide()
        end
    end

    -- CC Glow
    if IsUnitCC(unit) then
        petFrame.ccGlow:Show()
    else
        petFrame.ccGlow:Hide()
    end

	ApplyPetLortiTint();
end

-- Castbar
local function UpdateCastBar()
    local unit = "party1pet"
    local name, _, _, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
    local isChannel = false
    if not name then
        name, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
        isChannel = true
    end

    if name and type(startTime) == "number" and type(endTime) == "number" then
        local now = GetTime()*1000
        if isChannel then
            castBar:SetMinMaxValues(endTime/1000, startTime/1000)
            castBar:SetValue(endTime/1000 - now/1000 + startTime/1000)
        else
            castBar:SetMinMaxValues(startTime/1000, endTime/1000)
            castBar:SetValue(now/1000)
        end
        castBar.text:SetText(name)
        castBar:SetStatusBarColor(notInterruptible and 1 or 0.7, notInterruptible and 0.3 or 0.7, notInterruptible and 0.3 or 0.2)
        castBar:Show()
    else
        castBar:Hide()
    end
end

-- OnUpdate
local timeSinceLastUpdate = 0
petFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= 0.1 then
        timeSinceLastUpdate = 0
        UpdatePetFrame()
        UpdateCastBar()
    end
end)

-- Eventos
-- OJO: UNIT_POWER_UPDATE es de retail. En 3.3.5a el recurso se avisa con
-- un evento por tipo; se registran todos para cubrir cualquier mascota.


-- Los eventos NO se registran al cargar: los engancha el modulo al
-- prenderse (ver el final del archivo). Asi, apagado, no escucha nada.
local PPF_EVENTS = { "UNIT_HEALTH", "UNIT_MANA", "UNIT_MAXMANA", "UNIT_FOCUS", "UNIT_ENERGY", "UNIT_RAGE", "UNIT_HAPPINESS", "UNIT_TARGET", "UNIT_PET", "PLAYER_ENTERING_WORLD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_AURA", "GROUP_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_BATTLEGROUND", "PLAYER_LEAVING_BATTLEGROUND", "DUEL_FINISHED", "INSTANCE_GROUP_SIZE_CHANGED", "UPDATE_INSTANCE_INFO" };

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        UpdatePetFrame()
        UpdateCastBar()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "DUEL_FINISHED" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_LEAVING_BATTLEGROUND" or event == "INSTANCE_GROUP_SIZE_CHANGED" or event == "UPDATE_INSTANCE_INFO" then
        -- Forzar actualización después de cambios de zona/duelo/instancia
        TimerAfter(0.5, function()
            UpdatePetFrame()
            UpdateCastBar()
        end)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        UpdatePetFrame()
        UpdateCastBar()
    elseif event == "UNIT_PET" and arg1 == "party1" then
        UpdatePetFrame()
    elseif event == "UNIT_TARGET" and arg1 == "party1pet" then
        UpdatePetFrame()
    elseif event == "UNIT_AURA" and arg1 == "party1pet" then
        UpdatePetFrame()
    elseif (event == "UNIT_HEALTH" or event == "UNIT_MANA" or event == "UNIT_MAXMANA"
        or event == "UNIT_FOCUS" or event == "UNIT_ENERGY" or event == "UNIT_RAGE"
        or event == "UNIT_HAPPINESS") and arg1 == "party1pet" then
        UpdatePetFrame()
    elseif string.find(event,"UNIT_SPELLCAST") and arg1 == "party1pet" then
        UpdateCastBar()
    end
end)

-- Funciones de configuración
local function ToggleLock()
    settings.locked = not settings.locked
    
    if settings.locked then
        petFrame:SetMovable(false)
        petFrame:EnableMouse(settings.clickable)
        petFrame.lockIndicator:Show()
        print("|cff00ff00[PartyPetFrame]|r Frame bloqueado")
    else
        petFrame:SetMovable(true)
        petFrame:EnableMouse(true)
        petFrame.lockIndicator:Hide()
        print("|cff00ff00[PartyPetFrame]|r Frame desbloqueado - Arrastra para mover")
    end
end

local function ToggleClickable()
    settings.clickable = not settings.clickable
    
    if settings.clickable then
        petFrame:SetAttribute("type1", "target")
        print("|cff00ff00[PartyPetFrame]|r Clic habilitado - Click para seleccionar mascota")
    else
        petFrame:SetAttribute("type1", nil)
        print("|cff00ff00[PartyPetFrame]|r Clic deshabilitado")
    end
    
    -- Si está bloqueado, ajustar el mouse según clickable
    if settings.locked then
        petFrame:EnableMouse(settings.clickable)
    end
end

-- Comandos slash
SLASH_PARTYPETFRAME1 = "/ppf"
SLASH_PARTYPETFRAME2 = "/partypetframe"
SlashCmdList["PARTYPETFRAME"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "lock" or msg == "bloquear" then
        ToggleLock()
    elseif msg == "click" or msg == "clic" then
        ToggleClickable()
    elseif msg == "reset" then
        petFrame:ClearAllPoints()
        petFrame:SetPoint("CENTER", UIParent, "CENTER", 300, 100)
        print("|cff00ff00[PartyPetFrame]|r Posición reiniciada")
    else
        print("|cff00ff00[PartyPetFrame] Comandos:|r")
        print("  /ppf lock - Bloquear/desbloquear frame")
        print("  /ppf click - Habilitar/deshabilitar clic para seleccionar")
        print("  /ppf reset - Reiniciar posición del frame")
    end
end

-- (print de carga quitado: lo maneja el panel de NUF)

-- =========================================================
-- INTEGRACION NUF
-- =========================================================
local function PPF_SetEnabled(on)
    if on then
        for _, e in ipairs(PPF_EVENTS) do pcall(frame.RegisterEvent, frame, e) end
        UpdatePetFrame()
    else
        frame:UnregisterAllEvents()
        petFrame:Hide()
    end
end

function K.TogglePartyPetFrameLock()
    ToggleLock()
end

function K.ResetPartyPetFramePosition()
    petFrame:ClearAllPoints()
    petFrame:SetPoint("CENTER", UIParent, "CENTER", 300, 100)
end

K.RegisterModule("PartyPetFrame", {
    name    = L["MOD_PARTYPETFRAME"] or "Party pet enhanced",
    desc    = L["MOD_PARTYPETFRAME_DESC"]
        or "Custom frame for your first party member's pet: portrait, health/mana, cast bar and CC warning. /ppf for commands.",
    default = false,
    hideFromModulesTab = true,   -- vive en Frames > Party
    onEnable  = function() PPF_SetEnabled(true) end,
    onDisable = function() PPF_SetEnabled(false) end,
});
