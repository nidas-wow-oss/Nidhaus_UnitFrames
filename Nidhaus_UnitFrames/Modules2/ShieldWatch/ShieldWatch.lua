local AddOnName, ns = ...;
local K, C, L_NUF = unpack(ns);

-- =========================================================
-- ShieldWatch.lua  (integrado a NUF)
-- Fuente: ShieldWatch 1.0
--
-- QUE HACE: barra con el porcentaje / absorcion restante de los
-- escudos magicos (Palabra de poder: escudo, Egida divina, Barrera de
-- hielo, Escudo de mana, barreras de fuego/escarcha/sombras, Escudo
-- sagrado, Sacrificio). Avisa cuando queda poco tiempo o poco absorbido.
--
-- CAMBIOS respecto del addon suelto:
--   * Se prende y apaga desde Addons > HUD. Con el modulo apagado no
--     registra COMBAT_LOG_EVENT_UNFILTERED, que es el evento caro.
--   * Sus opciones guardadas viven en la DB de NUF, no en una
--     SavedVariable propia (NUF no puede declarar la del addon suelto).
--   * El boton "Abrir" del panel y /shieldwatch options siguen llevando
--     a su ventana de opciones propia.
--
-- OJO con la tabla L de aca abajo: es la del ADDON, no la de NUF.
-- Por eso arriba renombre la de NUF a L_NUF, si no una pisaba a la otra.
-- =========================================================

-- ============================================================================
-- ShieldWatch - Versión 1.0 con soporte para Español
-- ============================================================================

-- La SavedVariable original (Shieldwatch_Options) no se puede declarar
-- desde NUF, asi que se apunta a un sub-tabla de la DB del addon.
local function SW_DB()
    if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
    if not NidhausUnitFramesDB.ShieldWatch then NidhausUnitFramesDB.ShieldWatch = {} end
    return NidhausUnitFramesDB.ShieldWatch
end

-- VARIABLES GLOBALES
local swModuleEnabled = false
local shieldwatch_debugmsgs = false
local shieldwatch_MyGUID = 0
local shieldwatch_myclass = ""
local shieldpower = {}
local shieldstore = {}
local shieldwatch_lastcritheal = 0
local shieldwatch_elapsed = 0
local shieldstore_slotmax = 7
local shieldwatch_slotdisplayed = nil
local shieldwatch_enabled = true
local shieldwatch_timewarn = false
local shieldwatch_optionsedited = false
local shieldwatch_donetalentcheck = false

-- VERSIÓN DEL ADDON
local ADDON_VERSION = 1.0

-- Detectar idioma del cliente
local mylocale = GetLocale()

-- ============================================================================
-- LOCALIZACIÓN DE TEXTOS
-- ============================================================================

local L = {} -- Tabla de localización

-- Configurar textos según idioma
if mylocale == "esES" or mylocale == "esMX" then
    -- ESPAÑOL
    L.PWS = 'Palabra de poder: escudo'
    L.DA = 'Égida divina'
    L.IB = 'Barrera de hielo'
    L.MANA_SHIELD = 'Escudo de maná'
    L.FIRE_WARD = 'Barrera de fuego'
    L.FROST_WARD = 'Barrera de Escarcha'
    L.SACRIFICE = 'Sacrificio'
    L.SHADOW_WARD = 'Barrera de las Sombras'
    L.SACRED_SHIELD = 'Escudo sagrado'
    L.FEL_BLOSSOM = 'Flor vil'
    
    L.LOCKTXT = "Bloquear ventana"
    L.UNLOCKTXT = "Desbloquear ventana"
    L.USAGE = "¡Error! Comandos válidos:\n/shieldwatch options - acceder a las opciones\n/shieldwatch scale <num> - escalar la ventana (0.3 a 3)\n/shieldwatch disable - desactivar temporalmente\n/shieldwatch enable - reactivar\n(/swh puede usarse en lugar de /shieldwatch)"
    L.ENABLED = "ha sido reactivado."
    L.DISABLED = "ha sido desactivado para esta sesión.\nUsa /shieldwatch enable para reactivarlo"
    L.DISABLEMNU = "Desactivar"
    L.BADSCALE = "escala fuera de rango. Debe estar entre 0.3 y 3"
    L.SETSCALE = "escala establecida en "
    L.INIT = " activo. Usa '/shieldwatch (o /swh) options' para configurar"
    L.OPTIONMNU = "Opciones"
    L.BADTIME = "tiempo de aviso fuera de rango, debe estar entre 2 y 10"
    L.BADPCT = "porcentaje de aviso fuera de rango, debe estar entre 1 y 51"
    L.OPTTITLE = "Opciones de ShieldWatch"
    L.OPTTEXT1 = "Activar ShieldWatch (¡Se reactiva cada sesión!)"
    L.OPTTEXT2 = "Bloquear ventana"
    L.OPTTEXT3 = "Avisar si los segundos del escudo son menos de"
    L.OPTTEXT4 = "Avisar si el porcentaje del escudo es menos de"
    L.OPTTEXT5 = "Parpadear borde cuando ocurran avisos"
    L.OPTTEXT6 = "Ajustar escala de la barra"
    L.OPTSMALL = "Pequeño"
    L.OPTBIG = "Grande"
    
    -- Patrones para tooltips en español
    L.TIPREAD = {
        [1] = { line = "4", pattern = "[aA]bsorbe%a* (%d+) p.- de daño" },
        [2] = { line = "3", pattern = "Absorbe de %d+ a (%d+) p.- de daño" }
    }
else
    -- INGLÉS (por defecto)
    L.PWS = 'Power Word: Shield'
    L.DA = 'Divine Aegis'
    L.IB = 'Ice Barrier'
    L.MANA_SHIELD = 'Mana Shield'
    L.FIRE_WARD = 'Fire Ward'
    L.FROST_WARD = 'Frost Ward'
    L.SACRIFICE = 'Sacrifice'
    L.SHADOW_WARD = 'Shadow Ward'
    L.SACRED_SHIELD = 'Sacred Shield'
    L.FEL_BLOSSOM = 'Fel Blossom'
    
    L.LOCKTXT = "Lock Window"
    L.UNLOCKTXT = "Unlock Window"
    L.USAGE = "Error! Valid commands are:\n/shieldwatch options - access the options screen\n/shieldwatch scale <num> - to scale the shieldwatch frame (0.3 to 3)\n/shieldwatch disable - to temporarily disable Shieldwatch\n/shieldwatch enable - to re-enable shieldwatch\n(/swh can be used instead of /shieldwatch)"
    L.ENABLED = "has been re-enabled."
    L.DISABLED = "has been disabled for the rest of this session.\nUse /shieldwatch enable - to re-enable shieldwatch"
    L.DISABLEMNU = "Disable"
    L.BADSCALE = "scale out of range. Must be between 0.3 and 3"
    L.SETSCALE = "scale set to "
    L.INIT = " active. Use '/shieldwatch (or /swh) options' to configure"
    L.OPTIONMNU = "Options"
    L.BADTIME = "warning time out of range, must be between 2 and 10"
    L.BADPCT = "warning percent out of range, must be between 1 and 51"
    L.OPTTITLE = "shieldwatch Options"
    L.OPTTEXT1 = "Enable ShieldWatch (Re-Enables every session!)"
    L.OPTTEXT2 = "Lock Window"
    L.OPTTEXT3 = "Warn if seconds on shield less than"
    L.OPTTEXT4 = "Warn if percent on shield less than"
    L.OPTTEXT5 = "Flash Bars Border When Warnings Occur"
    L.OPTTEXT6 = "Adjust Bar Scale"
    L.OPTSMALL = "Small"
    L.OPTBIG = "Big"
    
    -- Patrones para tooltips en inglés
    L.TIPREAD = {
        [1] = { line = "4", pattern = "[aA]bsorb%a* (%d+) [^d]?%a*%s?damage" },
        [2] = { line = "3", pattern = "Absorbs %d+ to (%d+) damage" }
    }
end

-- ============================================================================
-- TABLA DE HECHIZOS
-- ============================================================================

local SPELLS = {
    -- Priest
    [L.PWS] = {tip=1, bonus=2, slot=5, icon='Spell_Holy_PowerWordShield', r=.7, g=.7, b=.3, tb={[1]=0,[2]=0,[3]=0}},
    [L.DA] = {slot=3, icon='Spell_Holy_DevineAegis', r=.7, g=.7, b=.6, tb={[4]=0}},
    -- Mage
    [L.IB] = {tip=1, bonus=5, slot=2, icon='Spell_Ice_Lament', r=0, g=.75, b=.75, gb=0},
    [L.MANA_SHIELD] = {tip=1, bonus=7, slot=6, icon='Spell_Shadow_DetectLesserInvisibility', r=.9, g=0, b=.9},
    [L.FIRE_WARD] = {tip=1, bonus=3, slot=4, school=4, icon='Spell_Fire_FireArmor', r=.9, g=0, b=0},
    [L.FROST_WARD] = {tip=1, bonus=5, slot=4, school=16, icon='Spell_Frost_FrostWard', r=.5, g=.5, b=1},
    -- Warlock
    [L.SACRIFICE] = {tip=1, slot=2, icon='Spell_Shadow_SacrificialShield', r=.5, g=.5, b=0},
    [L.SHADOW_WARD] = {tip=1, bonus=6, slot=4, school=32, icon='Spell_Shadow_AntiShadow', r=.6, g=0, b=.6},
    -- Paladin
    [L.SACRED_SHIELD] = {tip=1, bonus=2, slot=1, icon='Ability_Paladin_BlessedMending', r=.8, g=.8, b=.2},
    -- Herbalist
    [L.FEL_BLOSSOM] = {tip=2, slot=3, icon='INV_Misc_Herb_Felblossom', r=0, g=.5, b=0}
}

-- Configuración de talentos
local TALENT_CHECKS = {
    {tab=1, pos=2, name='Twin Disciplines', rankboost=0.01, spell=L.PWS},
    {tab=1, pos=9, name='Improved Power Word: Shield', rankboost=0.05, spell=L.PWS},
    {tab=1, pos=27, name='Borrowed Time', rankboost=0.0975, spell=L.PWS},
    {tab=1, pos=24, name='Divine Aegis', rankboost=0.1, spell=L.DA}
}

-- ============================================================================
-- FUNCIONES DE UTILIDAD
-- ============================================================================

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("shieldwatch " .. msg, 0.7, 0.7, 1.0)
end

local function Debug(msg)
    if shieldwatch_debugmsgs then
        DEFAULT_CHAT_FRAME:AddMessage("shieldwatch DEBUG: " .. msg, 0.5, 0.5, 1.0)
    end
end

-- ============================================================================
-- FUNCIONES DE OPCIONES
-- ============================================================================

function shieldwatch_optionsOnLoad(panel)
    panel.name = "ShieldWatch v" .. tostring(ADDON_VERSION)
    panel.okay = shieldwatch_optionsokay
    panel.cancel = shieldwatch_optionscancel
    InterfaceOptions_AddCategory(panel)

    -- NUF: tematica "arcane" (azul) para la ventana de opciones.
    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        panel:SetBackdropColor(0.04, 0.08, 0.18, 0.92)
        panel:SetBackdropBorderColor(0.25, 0.55, 1.0, 0.9)
    end

    shieldwatch_optionsFrameScale:SetMinMaxValues(-1, 1)
    shieldwatch_optionsFrameScale:SetValueStep(0.1)
    shieldwatch_optionsFrameScaleLow:SetText(L.OPTSMALL)
    shieldwatch_optionsFrameScaleHigh:SetText(L.OPTBIG)
    -- NUF: escala en tiempo real (antes solo se aplicaba al tocar OK).
    shieldwatch_optionsFrameScale:HookScript("OnValueChanged", function(self)
        local sc = exp(floor(self:GetValue() * 10 + .5) / 10)
        if shieldwatch_Frame then shieldwatch_Frame:SetScale(sc) end
        if shieldwatch_Options then shieldwatch_Options["scale"] = sc end
    end)
    shieldwatch_optionsFrameTitle:SetText(L.OPTTITLE)
    shieldwatch_optionsFrameOpttext1:SetText(L.OPTTEXT1)
    shieldwatch_optionsFrameOpttext2:SetText(L.OPTTEXT2)
    shieldwatch_optionsFrameOpttext3:SetText(L.OPTTEXT3)
    shieldwatch_optionsFrameOpttext4:SetText(L.OPTTEXT4)
    shieldwatch_optionsFrameOpttext5:SetText(L.OPTTEXT5)
    shieldwatch_optionsFrameOpttext6:SetText(L.OPTTEXT6)
end

function shieldwatch_optionsokay()
    if shieldwatch_optionsedited then
        Debug("okay pressed, options may have changed")
        
        local scale = exp(floor(shieldwatch_optionsFrameScale:GetValue() * 10 + .5) / 10)
        shieldwatch_Frame:SetScale(scale)
        shieldwatch_Options["scale"] = scale
        
        shieldwatch_Options["Lock"] = (shieldwatch_optionsFrameLock:GetChecked() == 1)
        shieldwatch_Options["enabletimewarn"] = (shieldwatch_optionsFrameEnableTime:GetChecked() == 1)
        shieldwatch_Options["enablepctwarn"] = (shieldwatch_optionsFrameEnablePct:GetChecked() == 1)
        shieldwatch_Options["flashborder"] = (shieldwatch_optionsFrameFlashBorder:GetChecked() == 1)
        
        local timetowarn = tonumber(shieldwatch_optionsFrameTimetowarn:GetText())
        if timetowarn and timetowarn > 0 and timetowarn < 11 then
            shieldwatch_Options["timetowarn"] = timetowarn
        else
            Print(L.BADTIME)
        end
        
        local pcttowarn = tonumber(shieldwatch_optionsFramePcttowarn:GetText())
        if pcttowarn and pcttowarn > 0 and pcttowarn < 52 then
            shieldwatch_Options["pcttowarn"] = pcttowarn
        else
            Print(L.BADPCT)
        end
        
        local enabled = (shieldwatch_optionsFrameEnable:GetChecked() == 1)
        if enabled ~= shieldwatch_enabled then
            if enabled then
                shieldwatch_Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                shieldwatch_enabled = true
                Print(L.ENABLED)
            else
                shieldwatch_Frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                shieldwatch_slotdisplayed = nil
                shieldwatch_Frame:Hide()
                shieldwatch_enabled = false
                Print(L.DISABLED)
            end
        end
        
        shieldwatch_Options["version"] = ADDON_VERSION
        shieldwatch_optionsedited = false
    else
        Debug("okay pressed, options unchanged")
    end
end

function shieldwatch_optionscancel()
    Debug("cancel pressed on the options screen")
    shieldwatch_optionsedited = false
end

-- EL BUG QUE TILDABA EL CLIENTE.
--
-- Esta funcion es el OnShow del marco de opciones, y ademas terminaba
-- llamando a InterfaceOptionsFrame_OpenToCategory. Pero abrir el panel
-- MUESTRA el marco, y mostrarlo dispara el OnShow, que vuelve a abrirlo:
-- recursion infinita entre las dos cosas.
--
-- Y saltaba SOLA al cargar, sin que nadie tocara nada, porque el marco de
-- opciones venia sin hidden en el XML: nacia mostrado, el OnShow se
-- disparaba de una y el WoW se colgaba antes de terminar de entrar. De ahi
-- que el sintoma fuera "tilda al login" y no hubiera ningun error en
-- pantalla: no era un error, era un bucle.
--
-- Ahora son dos funciones separadas. Esta SOLO refresca los controles, que
-- es lo unico que le corresponde a un OnShow. Abrir el panel es
-- shieldwatch_openoptions, que la llama el boton y el /shieldwatch options.
function shieldwatch_showoptions()
    if shieldwatch_Options then
        Debug("showing the options screen")
        shieldwatch_optionsFrameEnable:SetChecked(shieldwatch_enabled)
        shieldwatch_optionsFrameLock:SetChecked(shieldwatch_Options["Lock"])
        shieldwatch_optionsFrameEnableTime:SetChecked(shieldwatch_Options["enabletimewarn"])
        shieldwatch_optionsFrameEnablePct:SetChecked(shieldwatch_Options["enablepctwarn"])
        shieldwatch_optionsFrameFlashBorder:SetChecked(shieldwatch_Options["flashborder"])
        shieldwatch_optionsFrameTimetowarn:SetText(tostring(shieldwatch_Options["timetowarn"]))
        shieldwatch_optionsFramePcttowarn:SetText(tostring(shieldwatch_Options["pcttowarn"]))
        shieldwatch_optionsFrameScale:SetValue(log(shieldwatch_Options["scale"]))
        shieldwatch_optionsedited = true
    end
end

-- Abrir el panel. Esto SI llama a OpenToCategory, y por eso no puede ser
-- el OnShow.
--
-- La llamada va dos veces por el bug clasico de Blizzard: la primera abre
-- en la categoria equivocada. Como ya no estamos dentro del OnShow, las dos
-- llamadas terminan y no hay bucle. La guarda es por las dudas: si alguien
-- vuelve a colgar esto de un OnShow, corta en vez de tildar.
local swOpening = false

function shieldwatch_openoptions()
    if swOpening then return end
    if not (InterfaceOptionsFrame_OpenToCategory and shieldwatch_optionsFrame) then return end

    swOpening = true
    InterfaceOptionsFrame_OpenToCategory(shieldwatch_optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(shieldwatch_optionsFrame)
    swOpening = false
end

function shieldwatch_InitDropDown()
    local info
    local version = tostring(ADDON_VERSION)

    info = {}
    info.text = "ShieldWatch v" .. version
    info.justifyH = "CENTER"
    info.isTitle = 1
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info)
    
    info = {}
    info.text = shieldwatch_Options["Lock"] and L.UNLOCKTXT or L.LOCKTXT
    info.value = "LockMeter"
    info.notCheckable = 1
    info.func = function()
        shieldwatch_Options["Lock"] = not shieldwatch_Options["Lock"]
        shieldwatch_Options["version"] = ADDON_VERSION
    end
    UIDropDownMenu_AddButton(info)
    
    info = {}
    info.text = L.DISABLEMNU
    info.value = "disable"
    info.notCheckable = 1
    info.func = function()
        if shieldwatch_enabled then
            shieldwatch_Frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            shieldwatch_slotdisplayed = nil
            shieldwatch_Frame:Hide()
            shieldwatch_enabled = false
        end
        Print(L.DISABLED)
    end
    UIDropDownMenu_AddButton(info)
    
    info = {}
    info.text = L.OPTIONMNU
    info.value = "options"
    info.notCheckable = 1
    info.func = function() 
        InterfaceOptionsFrame_OpenToCategory(shieldwatch_optionsFrame) 
    end
    UIDropDownMenu_AddButton(info)
end

-- ============================================================================
-- FUNCIONES PRINCIPALES
-- ============================================================================

function shieldwatch_OnLoad(self)
    -- Los eventos los engancha el modulo al prenderse (SW_SetEnabled).
    -- Antes se registraba aca y corria aunque el usuario no lo quisiera.
    SLASH_shieldwatch1 = "/shieldwatch"
    SLASH_shieldwatch2 = "/swh"
    SlashCmdList["shieldwatch"] = function(msg)
        if not msg then return end
        
        local _, _, command, com2 = string.find(msg, "^(%w+)%s*(.*)$")
        command = string.lower(tostring(command))
        
        if command == "scale" then
            local scale = tonumber(com2)
            if not scale or scale < .3 or scale > 3 then
                Print(L.BADSCALE)
            else
                shieldwatch_Frame:SetScale(scale)
                shieldwatch_Options["scale"] = scale
                Print(L.SETSCALE .. tostring(scale))
            end
        elseif command == "options" then
            shieldwatch_openoptions()
        elseif command == "disable" then
            if shieldwatch_enabled then
                shieldwatch_Frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                shieldwatch_slotdisplayed = nil
                shieldwatch_Frame:Hide()
                shieldwatch_enabled = false
            end
            Print(L.DISABLED)
        elseif command == "enable" then
            if not shieldwatch_enabled then
                shieldwatch_Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                shieldwatch_enabled = true
            end
            Print(L.ENABLED)
        elseif command == "dbg" then
            shieldwatch_debugmsgs = not shieldwatch_debugmsgs
            Print("debug " .. tostring(shieldwatch_debugmsgs))
        elseif command == "mdchannel" then
            if com2 then
                shieldwatch_Options["mdchannel"] = string.upper(tostring(com2))
            end
        else
            Print(L.USAGE)
        end
    end
end

function shieldwatch_checktalents()
    if shieldwatch_debugmsgs then
        local numglyphs = GetNumGlyphSockets()
        Debug("reported glyph slots: " .. tostring(numglyphs))
        for i = 1, numglyphs do
            local enabled, _, glyphSpellID = GetGlyphSocketInfo(i)
            Debug("got glyph: " .. tostring(glyphSpellID) .. "(enabled: " .. tostring(enabled) .. ")")
        end
    end
    
    if shieldwatch_myclass == "MAGE" then
        -- SPELLS se indexa por NOMBRE localizado del hechizo. Si el nombre
        -- no resuelve (cliente en otro idioma), SPELLS[L.IB] es nil y esto
        -- reventaba. Mejor saltear el ajuste que romper.
        local ib = SPELLS[L.IB]
        if ib then
            ib.gb = 1
            local numglyphs = GetNumGlyphSockets()
            for i = 1, numglyphs do
                local enabled, _, glyphSpellID = GetGlyphSocketInfo(i)
                if enabled and glyphSpellID == 63095 then
                    ib.gb = 1.3
                end
            end
        end
    elseif shieldwatch_myclass == "PRIEST" then
        for i = 1, #TALENT_CHECKS do
            local check = TALENT_CHECKS[i]
            local _, _, _, _, currentRank = GetTalentInfo(check.tab, check.pos)
            SPELLS[check.spell].tb[i] = (currentRank * check.rankboost)
            Debug("talent boost " .. tostring(i) .. " is " .. tostring(SPELLS[check.spell].tb[i]))
        end
    end
    
    shieldwatch_donetalentcheck = true
end

function shieldwatch_shieldup(spellid, spelldata, caster_GUID)
    Debug("aura from spell " .. tostring(spellid))
    
    if spellid == 53601 then return end
    
    if not shieldwatch_donetalentcheck then
        shieldwatch_checktalents()
    end
    
    if not spelldata.tip then
        local stackshield = 0
        if shieldstore[spelldata.slot] and shieldstore[spelldata.slot].shieldspell and 
           shieldstore[spelldata.slot].shieldspell == spellid and shieldstore[spelldata.slot].shieldat > 0 then
            stackshield = shieldstore[spelldata.slot].shieldat
            Debug("stacking divine aegis, existing shield remaining: " .. tostring(stackshield))
        end
        
        if caster_GUID == shieldwatch_MyGUID then
            shieldpower[spellid] = floor(shieldwatch_lastcritheal * spelldata.tb[4]) + stackshield
        else
            shieldpower[spellid] = floor(shieldwatch_lastcritheal * 0.3) + stackshield
        end
        
        if shieldpower[spellid] > 10000 then
            shieldpower[spellid] = 10000
        end
    elseif not shieldpower[spellid] then
        shieldwatchTooltip:ClearLines()
        shieldwatchTooltip:SetHyperlink("spell:" .. tostring(spellid))
        local tiplines = shieldwatchTooltip:NumLines()
        Debug("tiplines " .. tostring(tiplines))
        
        if tiplines > 2 then
            local readline = tonumber(L.TIPREAD[spelldata.tip].line)
            if tiplines < readline then
                readline = readline - 1
            end
            
            local mytext = getglobal("shieldwatchTooltipTextLeft" .. tostring(readline))
            if mytext then
                local text = mytext:GetText()
                Debug("line: " .. tostring(text))
                local _, _, dmgab = strfind(text, L.TIPREAD[spelldata.tip].pattern)
                Debug("dmgab " .. tostring(dmgab))
                shieldpower[spellid] = tonumber(dmgab) or -1
            else
                Debug("failed reading spell")
                shieldpower[spellid] = -1
            end
        else
            Debug("failed reading spell")
            shieldpower[spellid] = -1
        end
    end
    
    local slot = spelldata.slot
    local spellname, spellrank = GetSpellInfo(spellid)
    
    shieldstore[slot] = {}
    
    if spellid == 58597 then
        local shieldTex = 'Interface\\Icons\\Ability_Paladin_GaurdedbytheLight'
        for i = 1, 40 do
            local _, _, imsiIcon, _, _, _, imsiTime = UnitBuff("player", i)
            if shieldTex == imsiIcon then
                shieldstore[slot].shieldexpires = imsiTime
                break
            end
        end
    else
        _, _, _, _, _, _, shieldstore[slot].shieldexpires = UnitBuff("player", spellname, spellrank)
    end
    
    shieldstore[slot].shieldduration = tostring(floor(shieldstore[slot].shieldexpires - GetTime() + .5))
    Debug("aura expires " .. tostring(shieldstore[slot].shieldexpires) .. " duration " .. shieldstore[slot].shieldduration)
    
    if spelldata.bonus then
        if spelldata.gb then
            shieldstore[slot].shieldat = shieldpower[spellid] + floor(GetSpellBonusDamage(spelldata.bonus) * 0.8067 * spelldata.gb)
        else
            shieldstore[slot].shieldat = shieldpower[spellid] + floor(GetSpellBonusDamage(spelldata.bonus) * 0.8067)
        end
    else
        shieldstore[slot].shieldat = shieldpower[spellid]
    end
    
    if spelldata.tb and spelldata.tip then
        shieldstore[slot].shieldat = shieldstore[slot].shieldat + floor(shieldstore[slot].shieldat * spelldata.tb[1])
        shieldstore[slot].shieldat = shieldstore[slot].shieldat + floor(shieldstore[slot].shieldat * spelldata.tb[2])
        shieldstore[slot].shieldat = shieldstore[slot].shieldat + floor(GetSpellBonusDamage(spelldata.bonus) * spelldata.tb[3])
    end
    
    shieldstore[slot].shieldmax = shieldstore[slot].shieldat
    shieldstore[slot].shieldspell = spellid
    shieldstore[slot].icon = spelldata.icon
    shieldstore[slot].r = spelldata.r
    shieldstore[slot].g = spelldata.g
    shieldstore[slot].b = spelldata.b
    
    if spelldata.school then
        shieldstore[slot].school = spelldata.school
    end
    
    if not shieldwatch_slotdisplayed or shieldwatch_slotdisplayed >= slot then
        shieldwatch_slotdisplayed = slot
        shieldwatch_FrameIcon1:SetTexture("Interface\\Icons\\" .. spelldata.icon)
        shieldwatch_Bar:SetStatusBarColor(spelldata.r, spelldata.g, spelldata.b, 1)
        shieldwatch_update(slot)
        shieldwatch_Frame:Show()
    end
end

-- NUF: barra suave. En vez de saltar de golpe al nuevo %, guardamos un
-- valor objetivo y cada frame acercamos el valor visible. Da la sensacion
-- de que el escudo baja en tiempo real. Solo corre mientras el frame esta
-- visible (con escudo activo), asi que no cuesta nada en reposo.
function shieldwatch_SetBarTarget(pct)
    local bar = shieldwatch_Bar
    bar._target = pct
    if bar._current == nil then   -- primer valor tras un reset: sin animacion
        bar._current = pct
        bar:SetValue(pct)
    end
end

function shieldwatch_ResetBar()
    shieldwatch_Bar._current = nil
    shieldwatch_Bar._target = nil
    shieldwatch_Bar:SetValue(0)
end

function shieldwatch_onupdate(self, elapsed)
    -- Deslizamiento del valor visible hacia el objetivo (cada frame).
    local bar = shieldwatch_Bar
    if not bar then return end
    if bar._current ~= nil and bar._target ~= nil and bar._current ~= bar._target then
        local diff = bar._target - bar._current
        if math.abs(diff) <= 0.5 then
            bar._current = bar._target
        else
            bar._current = bar._current + diff * math.min(elapsed * 10, 1)
        end
        bar:SetValue(bar._current)
    end

    shieldwatch_elapsed = shieldwatch_elapsed + elapsed
    if shieldwatch_elapsed > .25 then
        -- ================= LA GUARDA QUE FALTABA =================
        -- Aca antes se hacia directo:
        --     shieldstore[shieldwatch_slotdisplayed].pendingdestroy
        -- Con slotdisplayed en nil (o con la casilla ya vaciada) eso es
        -- shieldstore[nil] -> nil, e indexar nil tira error. Como esto es
        -- un OnUpdate, el error salia UNA VEZ POR FRAME: unos 60 por
        -- segundo. Con la ventana de errores abriendose sin parar el
        -- cliente parece colgado, y por eso el modulo quedo fuera del load.
        --
        -- El frame arranca oculto y OnUpdate no corre oculto, pero apenas
        -- aparecia un escudo se mostraba y ya no se volvia a ocultar en
        -- todos los caminos posibles.
        local slot = shieldwatch_slotdisplayed
        local data = slot and shieldstore[slot]
        if not data or not shieldwatch_Options then
            shieldwatch_slotdisplayed = nil
            shieldwatch_elapsed = 0
            self:Hide()
            return
        end

        if data.pendingdestroy then
            data.shieldat = -1
            shieldwatch_update(slot)
        else
            data.shieldduration = tostring(floor(data.shieldexpires - GetTime() + .5))
            shieldwatch_FrameDuration:SetText(data.shieldduration .. "s")
            
            if (shieldwatch_Options["enabletimewarn"] and tonumber(data.shieldduration) < shieldwatch_Options["timetowarn"]) or
               (shieldwatch_Options["enablepctwarn"] and (data.pct or 100) < shieldwatch_Options["pcttowarn"]) then
                shieldwatch_timewarn = not shieldwatch_timewarn
                if shieldwatch_timewarn then
                    if shieldwatch_Options["enabletimewarn"] and tonumber(data.shieldduration) < shieldwatch_Options["timetowarn"] then
                        shieldwatch_FrameDuration:SetTextColor(1, .3, .3, 1)
                    end
                    if shieldwatch_Options["enablepctwarn"] and (data.pct or 100) < shieldwatch_Options["pcttowarn"] then
                        shieldwatch_BarText:SetTextColor(1, .3, .3, 1)
                    end
                    if shieldwatch_Options["flashborder"] then
                        shieldwatch_Frame:SetBackdropBorderColor(1, .3, .3, 1)
                    end
                else
                    shieldwatch_FrameDuration:SetTextColor(1, 1, 1, 1)
                    shieldwatch_Frame:SetBackdropBorderColor(1, 1, 1, 1)
                    shieldwatch_BarText:SetTextColor(1, 1, 1, 1)
                end
            end
        end
        shieldwatch_elapsed = 0
    end
end

function shieldwatch_shielddown(spellid, spelldata)
    if spellid == 53601 then return end
    
    if shieldstore[spelldata.slot] then
        if spelldata.slot == shieldwatch_slotdisplayed then
            shieldstore[spelldata.slot].pendingdestroy = 1
            shieldwatch_elapsed = 0.15
        else
            shieldstore[spelldata.slot].shieldat = -1
            shieldwatch_update(spelldata.slot)
        end
    end
end

function shieldwatch_shielddmg(amount, school)
    local i = 1
    school = tonumber(school) or 0
    Debug("dmg is school: " .. tostring(school))
    
    while i <= shieldstore_slotmax and amount > 0 do
        if shieldstore[i] and (not shieldstore[i].school or (bit.band(shieldstore[i].school, school) > 0)) then
            shieldstore[i].shieldat = shieldstore[i].shieldat - amount
            if shieldstore[i].shieldat < 0 then
                amount = -shieldstore[i].shieldat
            else
                amount = 0
            end
            if i == shieldwatch_slotdisplayed then
                shieldwatch_update(i)
            end
        end
        i = i + 1
    end
    
    if amount > 0 then
        Debug("dmg not allocated to a shield!: " .. tostring(amount))
    end
end

function shieldwatch_update(slot)
    -- Misma historia: se llama desde el OnUpdate, desde shieldup/shielddown
    -- y desde su propia recursion, y la casilla puede estar vacia.
    if not slot or not shieldstore[slot] then
        shieldwatch_slotdisplayed = nil
        if shieldwatch_Frame then shieldwatch_Frame:Hide() end
        return
    end

    if shieldstore[slot].shieldat > -1 then
        shieldstore[slot].shieldduration = tostring(floor(shieldstore[slot].shieldexpires - GetTime() + .5))
        shieldwatch_timewarn = false
        shieldwatch_FrameDuration:SetText(shieldstore[slot].shieldduration .. "s")
        shieldwatch_FrameDuration:SetTextColor(1, 1, 1, 1)
        shieldwatch_Frame:SetBackdropBorderColor(1, 1, 1, 1)
        shieldwatch_BarText:SetTextColor(1, 1, 1, 1)
        local pct = floor((shieldstore[slot].shieldat / shieldstore[slot].shieldmax * 100) + 0.5)
        shieldstore[slot].pct = pct
        
        shieldwatch_BarText:SetText(tostring(pct) .. "% (" .. tostring(shieldstore[slot].shieldat) .. ")")
        shieldwatch_SetBarTarget(pct)
    else
        shieldstore[slot] = nil
        local i = 1
        local found = false
        
        while i <= shieldstore_slotmax and not found do
            if shieldstore[i] then
                found = true
                shieldwatch_slotdisplayed = i
                shieldwatch_FrameIcon1:SetTexture("Interface\\Icons\\" .. shieldstore[i].icon)
                shieldwatch_Bar:SetStatusBarColor(shieldstore[i].r, shieldstore[i].g, shieldstore[i].b, 1)
            end
            i = i + 1
        end
        
        if found then
            shieldwatch_update(shieldwatch_slotdisplayed)
        else
            shieldwatch_slotdisplayed = nil
            shieldwatch_Frame:Hide()
            shieldwatch_BarText:SetText(L["SW_NO_SHIELD"] or "no shield")
            shieldwatch_ResetBar()
        end
    end
end

function shieldwatch_onevent(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
    if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        if shieldwatch_Options["mdchannel"] ~= "OFF" and arg3 == shieldwatch_MyGUID and arg2 == "SPELL_CAST_SUCCESS" and arg9 == 34477 then
            local t = UnitName("target")
            if t and UnitIsEnemy("target", "player") then
                SendChatMessage(t .. " misdirected to " .. arg7, shieldwatch_Options['mdchannel'])
            else
                SendChatMessage("Misdirecting next target to " .. arg7, shieldwatch_Options['mdchannel'])
            end
        elseif arg6 ~= shieldwatch_MyGUID then
            return
        end
        
        if (arg2 == 'SPELL_AURA_APPLIED' or arg2 == 'SPELL_AURA_REFRESH') and SPELLS[arg10] then
            shieldwatch_shieldup(arg9, SPELLS[arg10], arg3)
        elseif tostring(arg9) == 'ABSORB' then
            shieldwatch_shielddmg(tonumber(arg10), 0)
        elseif tostring(arg12) == 'ABSORB' then
            shieldwatch_shielddmg(tonumber(arg13), arg11)
        elseif arg2 == 'ENVIRONMENTAL_DAMAGE' and arg15 and tonumber(arg15) > 0 then
            shieldwatch_shielddmg(tonumber(arg15), arg12)
        elseif arg2 == 'SPELL_AURA_REMOVED' and SPELLS[arg10] then
            shieldwatch_shielddown(arg9, SPELLS[arg10])
        elseif (arg2 == 'SPELL_HEAL' or arg2 == 'SPELL_PERIODIC_HEAL') and arg14 then
            shieldwatch_lastcritheal = tonumber(arg12)
        end
        return
    elseif event == 'PLAYER_ENTERING_WORLD' then
        -- Enganchar la tabla de opciones a la DB de NUF (ver comentario
        -- de arriba: en el addon suelto esto nunca llegaba a guardarse)
        shieldwatch_Options = SW_DB()

        -- Inicialización de opciones
        if not next(shieldwatch_Options) then
            shieldwatch_Options = {}
            shieldwatch_Options["Lock"] = false
            shieldwatch_Options["scale"] = 1
            shieldwatch_Options["timetowarn"] = 4
            shieldwatch_Options["enabletimewarn"] = true
            shieldwatch_Options["pcttowarn"] = 21
            shieldwatch_Options["enablepctwarn"] = true
            shieldwatch_Options["flashborder"] = true
            shieldwatch_Options["mdchannel"] = 'OFF'
            shieldwatch_Options["version"] = ADDON_VERSION
        else
            -- Solo agregar opciones nuevas, no sobrescribir existentes
            if not shieldwatch_Options["version"] or shieldwatch_Options["version"] < ADDON_VERSION then
                if shieldwatch_Options["timetowarn"] == nil then shieldwatch_Options["timetowarn"] = 4 end
                if shieldwatch_Options["enabletimewarn"] == nil then shieldwatch_Options["enabletimewarn"] = true end
                if shieldwatch_Options["pcttowarn"] == nil then shieldwatch_Options["pcttowarn"] = 21 end
                if shieldwatch_Options["enablepctwarn"] == nil then shieldwatch_Options["enablepctwarn"] = true end
                if shieldwatch_Options["flashborder"] == nil then shieldwatch_Options["flashborder"] = true end
                if not shieldwatch_Options["scale"] then shieldwatch_Options["scale"] = 1 end
                if not shieldwatch_Options["mdchannel"] then shieldwatch_Options["mdchannel"] = 'OFF' end
                shieldwatch_Options["version"] = ADDON_VERSION
            end
        end
        
        shieldwatch_Frame:SetScale(tonumber(shieldwatch_Options["scale"]))
        
        -- Sin aviso de arranque en el chat: el modulo se prende desde el
        -- panel, el usuario ya sabe que lo activo.
        shieldwatch_MyGUID = UnitGUID("player")
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("PLAYER_TALENT_UPDATE")
        Debug("guid is " .. shieldwatch_MyGUID)
        _, shieldwatch_myclass = UnitClass("player")
        
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        
        CreateFrame("GameTooltip", "shieldwatchTooltip")
        shieldwatchTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        shieldwatchTooltip:AddFontStrings(
            shieldwatchTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
            shieldwatchTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
        )
        
        UIDropDownMenu_Initialize(shieldwatch_FrameDropDown, shieldwatch_InitDropDown, "MENU")
        shieldwatch_Bar:SetMinMaxValues(0, 100)
    elseif event == 'CHAT_MSG_ADDON' then
        Debug(tostring(GetTime()) .. ":addonmsg from " .. tostring(arg4) .. " in " .. tostring(arg3) .. " (" .. tostring(arg1) .. ") " .. tostring(arg2))
    elseif event == 'PLAYER_LEVEL_UP' or event == 'PLAYER_TALENT_UPDATE' then
        Debug("event fired: " .. event)
        shieldpower = {}
        if shieldwatch_slotdisplayed then
            local i = 1
            local havebuffs = true
            while i <= shieldstore_slotmax and havebuffs do
                if shieldstore[i] and shieldstore[i].shieldspell then
                    local spellname, spellrank = GetSpellInfo(shieldstore[i].shieldspell)
                    havebuffs = UnitBuff("player", spellname, spellrank)
                end
                i = i + 1
            end
            if not havebuffs then
                shieldstore = {}
                shieldwatch_slotdisplayed = nil
                shieldwatch_Frame:Hide()
                shieldwatch_BarText:SetText(L["SW_NO_SHIELD"] or "no shield")
                shieldwatch_ResetBar()
            end
        end
        shieldwatch_donetalentcheck = false
    end
end

-- =========================================================
-- Registro del modulo en NUF
-- Vive en: Addons > HUD
-- =========================================================
local function SW_SetEnabled(state)
    swModuleEnabled = state and true or false
    if not shieldwatch_Frame then return end

    if swModuleEnabled then
        -- Si se prende a mitad de sesion, PLAYER_ENTERING_WORLD ya paso y
        -- no va a volver a dispararse: hay que correr la inicializacion a
        -- mano o shieldwatch_Options queda nil y revienta al primer escudo.
        if not shieldwatch_Options then
            shieldwatch_onevent(shieldwatch_Frame, "PLAYER_ENTERING_WORLD")
        end
        shieldwatch_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        shieldwatch_Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        shieldwatch_Frame:RegisterEvent("PLAYER_LEVEL_UP")
        shieldwatch_Frame:RegisterEvent("PLAYER_TALENT_UPDATE")
        shieldwatch_enabled = true
    else
        -- COMBAT_LOG_EVENT_UNFILTERED dispara cientos de veces por segundo
        -- en raid: con el modulo apagado no hay que dejarlo registrado.
        shieldwatch_Frame:UnregisterAllEvents()
        shieldwatch_enabled = false
        shieldwatch_Frame:Hide()
    end
end

K.RegisterModule("ShieldWatch", {
    name    = L_NUF["MOD_SHIELDWATCH"] or "ShieldWatch",
    desc    = L_NUF["MOD_SHIELDWATCH_DESC"]
        or "Bar showing how much is left on your magic shields and barriers. /shieldwatch options to configure it.",
    default = false,
    configLabel = L_NUF["BTN_MODULE_OPEN"] or "Open",
    configFunc = function()
        if shieldwatch_openoptions then shieldwatch_openoptions() end
    end,
    onEnable  = function() SW_SetEnabled(true) end,
    onDisable = function() SW_SetEnabled(false) end,
});
