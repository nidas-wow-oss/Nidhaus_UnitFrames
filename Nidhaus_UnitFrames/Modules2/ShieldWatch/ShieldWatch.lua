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
--
-- LOS VALORES POR DEFECTO SE COMPLETAN ACA, no en PLAYER_ENTERING_WORLD
-- como antes. El panel de opciones se dibuja cuando el usuario abre la
-- pestana, que puede ser antes o despues de ese evento: si los defaults
-- llegaran tarde, los controles arrancarian leyendo nil.
-- Declarada aca arriba a proposito: el comando /shieldwatch scale la usa
-- mucho antes de donde se define. Un local declarado despues no lo ve el
-- codigo escrito antes, se compila como acceso a global y lee nil.
local SW_RefreshScale

local SW_DEFAULTS = {
    Lock           = false,
    scale          = 1,
    timetowarn     = 4,
    enabletimewarn = true,
    pcttowarn      = 21,
    enablepctwarn  = true,
    flashborder    = true,
    mdchannel      = 'OFF',
}

local function SW_DB()
    if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
    if not NidhausUnitFramesDB.ShieldWatch then NidhausUnitFramesDB.ShieldWatch = {} end
    local db = NidhausUnitFramesDB.ShieldWatch
    for k, v in pairs(SW_DEFAULTS) do
        if db[k] == nil then db[k] = v end
    end
    return db
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

-- Rango del slider de escala. Es el mismo que ya aceptaba el comando
-- /shieldwatch scale, para que las dos vias coincidan.
local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.3, 3.0, 0.05

-- Redondea al paso del slider. Sin esto GetValue devuelve cosas como
-- 1.2000000476837 y el numero de abajo queda ilegible.
local function SW_RoundScale(v)
    v = tonumber(v) or 1
    v = floor(v / SCALE_STEP + 0.5) * SCALE_STEP
    if v < SCALE_MIN then v = SCALE_MIN end
    if v > SCALE_MAX then v = SCALE_MAX end
    return v
end

local function SW_FormatScale(v)
    return string.format("%.2f", v)
end

-- LAS OPCIONES VIVEN EN EL PANEL DE NUF.
--
-- Antes eran un marco propio de 250 lineas de XML colgado del panel de
-- Interface de Blizzard: el unico modulo del addon que quedaba afuera de
-- /nufconfig. Y era justo el codigo que tildaba el cliente, asi que
-- mudarlo no es solo prolijidad, saca de encima la superficie donde
-- aparecio el bug.
--
-- Ahora son sub-opciones de la fila ShieldWatch en Addons, como Lorti UI.
-- Ver CreateShieldWatchSubUI mas abajo.
local function SW_OpenPanel()
    if K.ToggleOptionsPanel then K.ToggleOptionsPanel() end
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
        SW_OpenPanel() 
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
            if not scale or scale < SCALE_MIN or scale > SCALE_MAX then
                Print(L.BADSCALE)
            else
                -- Mismo redondeo que el slider: si no, escribir 1.234 por
                -- comando dejaba un valor que el slider no puede representar
                -- y al abrir las opciones saltaba solo al paso mas cercano.
                scale = SW_RoundScale(scale)
                shieldwatch_Frame:SetScale(scale)
                shieldwatch_Options["scale"] = scale
                if SW_RefreshScale then SW_RefreshScale(scale) end
                Print(L.SETSCALE .. SW_FormatScale(scale))
            end
        elseif command == "options" then
            SW_OpenPanel()
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
        -- EL DESCARTE VA PRIMERO Y ES EL MAS BARATO.
        --
        -- Este evento salta cientos de veces por segundo en banda, y casi
        -- ninguno es nuestro. Antes la primera condicion evaluada era
        -- shieldwatch_Options["mdchannel"] ~= "OFF": una indexacion de tabla
        -- global mas una comparacion de cadenas, en TODOS los eventos.
        -- Ahora primero se compara el GUID, que es una sola comparacion, y
        -- lo ajeno se va sin tocar la tabla.
        if arg6 ~= shieldwatch_MyGUID and arg3 ~= shieldwatch_MyGUID then
            return
        end

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
        -- Los valores por defecto ya los completa SW_DB(); aca solo se
        -- toma la referencia y se anota la version.
        shieldwatch_Options = SW_DB()
        shieldwatch_Options["version"] = ADDON_VERSION

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

-- ---------------------------------------------------------
-- Sub-opciones en la pestana Addons
--
-- Mismo formato que Lorti UI: se despliegan debajo de la fila del modulo.
-- Los valores no viven en C sino en la sub-tabla propia (SW_DB), asi que
-- se guardan a mano en vez de con K.SaveConfig.
-- ---------------------------------------------------------
local function CreateShieldWatchSubUI(container, yOffset, parentCheckbox)
    local wrapper = CreateFrame("Frame", nil, container)
    wrapper:SetPoint("TOPLEFT", 0, yOffset)
    wrapper:SetWidth(container:GetWidth() or 540)

    local y = 0

    local sep = wrapper:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 36, y + 4)
    sep:SetPoint("TOPRIGHT", -10, y + 4)
    sep:SetTexture(1, 1, 1, 0.07)
    y = y - 10

    local n = 0
    local function CheckBox(label, tip, get, set)
        n = n + 1
        local nm = "NidhausSWSubCB_" .. n
        local cb = CreateFrame("CheckButton", nm, wrapper, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 46, y)
        cb:SetHitRectInsets(0, -260, 0, 0)
        cb:SetScale(0.9)
        local lbl = _G[nm .. "Text"]
        if lbl then lbl:SetText(label); lbl:SetFontObject("GameFontHighlight") end
        cb:SetChecked(get() and true or false)
        if tip then
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(label, 1, 1, 1)
                GameTooltip:AddLine(tip, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        cb:SetScript("OnClick", function(self)
            set(self:GetChecked() == 1 or self:GetChecked() == true)
        end)
        y = y - 24
        return cb
    end

    local function Slider(label, minV, maxV, step, fmt, get, set)
        n = n + 1
        local nm = "NidhausSWSubSlider_" .. n
        local sl = CreateFrame("Slider", nm, wrapper, "OptionsSliderTemplate")
        sl:SetPoint("TOPLEFT", 64, y - 12)
        sl:SetWidth(180)
        sl:SetMinMaxValues(minV, maxV)
        sl:SetValueStep(step)

        local txt  = _G[nm .. "Text"]
        local low  = _G[nm .. "Low"]
        local high = _G[nm .. "High"]
        if txt  then txt:SetText(label) end
        if low  then low:SetText(tostring(minV)) end
        if high then high:SetText(tostring(maxV)) end

        local val = sl:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        val:SetPoint("TOP", sl, "BOTTOM", 0, -3)
        sl.nufValue = val

        sl:SetValue(get())
        val:SetText(fmt(get()))

        sl:SetScript("OnValueChanged", function(self)
            local v = floor(self:GetValue() / step + 0.5) * step
            if v < minV then v = minV end
            if v > maxV then v = maxV end
            self.nufValue:SetText(fmt(v))
            set(v)
        end)

        y = y - 56
        return sl
    end

    CheckBox(L_NUF["SW_LOCK"] or "Lock the bar",
        L_NUF["SW_LOCK_TIP"] or "While unlocked you can drag the bar with the left mouse button.",
        function() return SW_DB()["Lock"] end,
        function(v) SW_DB()["Lock"] = v end)

    CheckBox(L_NUF["SW_FLASH"] or "Flash the border on warning",
        nil,
        function() return SW_DB()["flashborder"] end,
        function(v) SW_DB()["flashborder"] = v end)

    CheckBox(L_NUF["SW_WARN_TIME"] or "Warn when little time is left",
        nil,
        function() return SW_DB()["enabletimewarn"] end,
        function(v) SW_DB()["enabletimewarn"] = v end)

    Slider(L_NUF["SW_WARN_TIME_VALUE"] or "Seconds left", 1, 15, 1,
        function(v) return string.format("%d s", v) end,
        function() return tonumber(SW_DB()["timetowarn"]) or 4 end,
        function(v) SW_DB()["timetowarn"] = v end)

    CheckBox(L_NUF["SW_WARN_PCT"] or "Warn when the shield runs low",
        nil,
        function() return SW_DB()["enablepctwarn"] end,
        function(v) SW_DB()["enablepctwarn"] = v end)

    Slider(L_NUF["SW_WARN_PCT_VALUE"] or "Remaining %", 5, 90, 5,
        function(v) return string.format("%d%%", v) end,
        function() return tonumber(SW_DB()["pcttowarn"]) or 21 end,
        function(v) SW_DB()["pcttowarn"] = v end)

    local scaleSlider = Slider(L_NUF["SW_SCALE"] or "Bar scale",
        SCALE_MIN, SCALE_MAX, SCALE_STEP, SW_FormatScale,
        function() return SW_RoundScale(SW_DB()["scale"]) end,
        function(v)
            SW_DB()["scale"] = v
            if shieldwatch_Frame then shieldwatch_Frame:SetScale(v) end
        end)

    -- Para que /shieldwatch scale mueva tambien el slider.
    SW_RefreshScale = function(v)
        if scaleSlider then scaleSlider:SetValue(v) end
    end

    y = y - 8
    local h = math.abs(y)
    wrapper:SetHeight(h)

    local function SetVisible(show)
        if show then wrapper:Show() else wrapper:Hide() end
        local ct = K._moduleContainers and K._moduleContainers["ShieldWatch"]
        if ct then
            ct:SetHeight(show and (ct._baseHeight + h) or ct._baseHeight)
            if K.UpdateModulesScrollHeight then K.UpdateModulesScrollHeight() end
        end
    end

    if parentCheckbox then
        local orig = parentCheckbox:GetScript("OnClick")
        parentCheckbox:SetScript("OnClick", function(self)
            if orig then orig(self) end
            SetVisible(self:GetChecked() == 1 or self:GetChecked() == true)
        end)
    end

    if K.IsModuleEnabled and K.IsModuleEnabled("ShieldWatch") then
        wrapper:Show()
    else
        wrapper:Hide()
    end

    return h
end

K.RegisterModule("ShieldWatch", {
    name    = L_NUF["MOD_SHIELDWATCH"] or "ShieldWatch",
    desc    = L_NUF["MOD_SHIELDWATCH_DESC"]
        or "Bar showing how much is left on your magic shields and barriers. /shieldwatch options to configure it.",
    default = false,
    createUI  = CreateShieldWatchSubUI,
    onEnable  = function() SW_SetEnabled(true) end,
    onDisable = function() SW_SetEnabled(false) end,
});
