local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- DTSU.lua  (integrado a NUF, de NidhausTools)
-- Tracker de daño saliente: swing, directo y periodico, con iconos
-- flotantes que muestran total / ultimo golpe / cantidad de hits.
--
-- CAMBIOS respecto del addon suelto:
--   * Se prende/apaga como modulo de NUF. COMBAT_LOG_EVENT_UNFILTERED
--     (el evento caro) solo se registra con el modulo activo; apagado no
--     escucha nada y el ticker queda oculto.
--   * La fuente apunta a la copia dentro de NUF.
-- =========================================================

-- Valores por defecto. OJO: no basta con "DTSU_DB = DTSU_DB or {...}".
-- WoW carga el archivo de SavedVariables DESPUES de ejecutar este .lua, asi que
-- lo que se asigne aqui lo pisa la tabla guardada. Si esa tabla venia de una
-- version vieja (o guardada vacia, DTSU_DB = {}) los campos quedaban en nil y
-- reventaba en IsIgnored. Por eso los defaults se fusionan en ADDON_LOADED.
local DTSU_DEFAULTS = {
    static = false,        -- true = no autohide/duration, queda fijo
    short_numbers = false,
    ignored_names_direct = {},
    ignored_ids_direct = {},
    ignored_names_dot = {},
    ignored_ids_dot = {},
    point = "CENTER",
    x = 573,
    y = -305,
}

DTSU_DB = DTSU_DB or {}

local function ApplyDefaults()
    DTSU_DB = DTSU_DB or {}
    for k, v in pairs(DTSU_DEFAULTS) do
        if DTSU_DB[k] == nil then
            if type(v) == "table" then DTSU_DB[k] = {} else DTSU_DB[k] = v end
        end
    end
end
ApplyDefaults()   -- para que el resto del archivo pueda leer el DB al cargar

local dbLoader = CreateFrame("Frame")
dbLoader:RegisterEvent("ADDON_LOADED")
dbLoader:SetScript("OnEvent", function(self, event, addon)
    if addon ~= AddOnName then return end
    ApplyDefaults()   -- ahora si, sobre la tabla que trajo SavedVariables
    if DTSU_Anchor then
        DTSU_Anchor:ClearAllPoints()
        DTSU_Anchor:SetPoint(DTSU_DB.point, UIParent, DTSU_DB.point, DTSU_DB.x, DTSU_DB.y)
    end
    self:UnregisterEvent("ADDON_LOADED")
end)

local DURATION = 4.5
local HIT_WINDOW = 0.2
-- Iconos rectangulares (como el WeakAura original), no cuadrados.
local ICON_W = 34
local ICON_H = 22
local SPACING = 4
local MAX_ICONS = 8
local ICON_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"

-- fuente: intenta usar Fira Mono Medium (la que usaba el WeakAura original),
-- si el archivo no esta presente cae al font por defecto de la UI
local CUSTOM_FONT = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\NidhausTools\\FiraMono-Medium.ttf"
local FALLBACK_FONT = select(1, GameFontNormal:GetFont())

local function SetCustomFont(fontString, size, flags)
    local ok = fontString:SetFont(CUSTOM_FONT, size, flags)
    if not ok then
        fontString:SetFont(FALLBACK_FONT, size, flags)
    end
end

local anchor = CreateFrame("Frame", "DTSU_Anchor", UIParent)
-- Escala configurable desde el panel (registro central en ScaleAPI).
if K.RegisterScalable then K.RegisterScalable("DTSU", anchor, 1.0); end
anchor:SetSize(ICON_W, ICON_H)
anchor:SetPoint(DTSU_DB.point, UIParent, DTSU_DB.point, DTSU_DB.x, DTSU_DB.y)
anchor:SetMovable(true)
anchor.bg = anchor:CreateTexture(nil, "BACKGROUND")
anchor.bg:SetAllPoints()
anchor.bg:SetTexture(0, 1, 0, 0.3)
anchor.bg:Hide()

local function ShortNumber(n)
    n = math.floor(n)
    if not DTSU_DB.short_numbers then return tostring(n) end
    if n >= 1000000 then return string.format("%.2fM", n / 1000000)
    elseif n >= 1000 then return string.format("%.2fK", n / 1000)
    else return tostring(n) end
end

-- ===== widget pool =====
local pool = {}
local active = {}   -- lista ordenada de keys activas
local states = {}   -- key -> state

local function CreateWidget()
    local f = CreateFrame("Frame", nil, anchor)
    f:SetSize(ICON_W, ICON_H)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()
    -- Recorte para que el icono rectangular no se deforme (crop vertical).
    f.icon:SetTexCoord(0.08, 0.92, 0.23, 0.77)

    f.border = f:CreateTexture(nil, "BACKGROUND")
    f.border:SetPoint("TOPLEFT", -1, 1)
    f.border:SetPoint("BOTTOMRIGHT", 1, -1)
    f.border:SetTexture("Interface\\Buttons\\WHITE8x8")
    f.border:SetVertexColor(0, 0, 0, 1)

    -- Total acumulado a la DERECHA del icono (como el WeakAura original).
    f.total = f:CreateFontString(nil, "OVERLAY")
    f.total:SetPoint("LEFT", f, "RIGHT", 4, 0)
    SetCustomFont(f.total, 14, "OUTLINE")

    -- Rafaga / ultimo golpe a la IZQUIERDA (se pinta de amarillo si fue crit).
    f.current = f:CreateFontString(nil, "OVERLAY")
    f.current:SetPoint("RIGHT", f, "LEFT", -4, 0)
    SetCustomFont(f.current, 14, "OUTLINE")

    f.hits = f:CreateFontString(nil, "OVERLAY")
    f.hits:SetPoint("TOP", f, "BOTTOM", 0, -2)
    SetCustomFont(f.hits, 12, "OUTLINE")

    f:Hide()
    return f
end

local function GetWidget()
    for _, f in ipairs(pool) do
        if not f.inUse then
            f.inUse = true
            return f
        end
    end
    local f = CreateWidget()
    f.inUse = true
    table.insert(pool, f)
    return f
end

local function ReleaseWidget(f)
    f.inUse = false
    f:Hide()
end

local function Layout()
    -- Ordenar por total descendente: el daño mas grande se acumula arriba.
    table.sort(active, function(k1, k2)
        local s1, s2 = states[k1], states[k2]
        if not (s1 and s2) then return false end
        return s1.total > s2.total
    end)

    local shown = 0
    for _, key in ipairs(active) do
        local st = states[key]
        if st then
            shown = shown + 1
            st.widget:ClearAllPoints()
            st.widget:SetPoint("TOP", anchor, "TOP", 0, -(shown - 1) * (ICON_H + SPACING))
        end
    end
end

local function RemoveState(key)
    local st = states[key]
    if not st then return end
    ReleaseWidget(st.widget)
    states[key] = nil
    for i, k in ipairs(active) do
        if k == key then
            table.remove(active, i)
            break
        end
    end
end

local function UpdateWidget(st)
    local w = st.widget
    w.icon:SetTexture(st.icon)
    w.total:SetText(ShortNumber(st.total))
    w.current:SetText(ShortNumber(st.current))

    if st.hits > 1 then
        w.hits:SetText(st.hits)
        w.hits:Show()
    else
        w.hits:SetText("")
    end

    -- El crit colorea la rafaga (numero de la izquierda); el total va blanco.
    if st.crit then
        w.current:SetTextColor(1, 1, 0)
    else
        w.current:SetTextColor(1, 1, 1)
    end
    w.total:SetTextColor(1, 1, 1)

    w:Show()
end

-- ===== combate =====
local function TouchState(key, icon, amount, crit)
    local now = GetTime()
    local st = states[key]
    local iconMissing = not icon
    icon = icon or ICON_FALLBACK

    if not st then
        if #active >= MAX_ICONS then return end
        st = {
            total = amount,
            current = amount,
            crit = crit,
            hits = 1,
            lastHit = now,
            expire = now + DURATION,
            icon = icon,
            iconMissing = iconMissing,
            widget = GetWidget(),
        }
        states[key] = st
        table.insert(active, key)
    else
        st.total = st.total + amount
        st.crit = crit
        st.current = amount
        st.icon = icon
        st.iconMissing = iconMissing
        if not DTSU_DB.static then
            st.expire = now + DURATION
        end
        if now - st.lastHit > HIT_WINDOW then
            st.hits = 1
            st.lastHit = now
        else
            st.current = st.current + amount
            st.hits = st.hits + 1
        end
    end

    UpdateWidget(st)
    Layout()
end

local function IsIgnored(name, id, ignoredNames, ignoredIds)
    -- Defensivo: si el DB llega incompleto no se debe reventar en pleno combate.
    if name and ignoredNames and ignoredNames[name] then return true end
    if id and ignoredIds and ignoredIds[id] then return true end
    return false
end

-- El registro de eventos lo maneja el modulo (onEnable/onDisable), no se
-- deja enganchado al cargar: COMBAT_LOG_EVENT_UNFILTERED dispara cientos
-- de veces por segundo y con el modulo apagado no debe escuchar nada.
local f = CreateFrame("Frame")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        local toRemove = {}
        for key in pairs(states) do table.insert(toRemove, key) end
        for _, key in ipairs(toRemove) do RemoveState(key) end
        Layout()
        return
    end

    if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end
    if not InCombatLockdown() then return end

    local _, subevent, sourceGUID, _, _, _, _, _,
          a1, a2, a3, a4, a5, a6, a7, a8, a9, a10 = ...

    if sourceGUID ~= UnitGUID("player") then return end

    if subevent == "SWING_DAMAGE" then
        -- a1=amount a2=overkill a3=school a4=resisted a5=blocked a6=absorbed a7=critical
        local amount, critical = a1, a7
        -- Icono del arma ORIGINAL, no la transfiguracion. GetInventoryItemTexture
        -- devuelve la textura MOSTRADA (con transmog en Warmane) y esa trae un
        -- borde blanco incorporado; GetItemIcon del item real equipado da el
        -- icono limpio del arma de verdad.
        local icon
        local itemId = GetInventoryItemID("player", 16)
        if itemId then icon = GetItemIcon(itemId) end
        icon = icon or GetInventoryItemTexture("player", 16)
        TouchState("swing", icon, amount, critical)

    elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
        -- a1=spellId a2=spellName a3=school a4=amount ... a10=critical
        local spellId, spellName, amount, critical = a1, a2, a4, a10
        if IsIgnored(spellName, spellId, DTSU_DB.ignored_names_direct, DTSU_DB.ignored_ids_direct) then return end
        local icon = select(3, GetSpellInfo(spellId))
        TouchState(spellId, icon, amount, critical)

    elseif subevent == "SPELL_PERIODIC_DAMAGE" then
        local spellId, spellName, amount, critical = a1, a2, a4, a10
        if IsIgnored(spellName, spellId, DTSU_DB.ignored_names_dot, DTSU_DB.ignored_ids_dot) then return end
        local icon = select(3, GetSpellInfo(spellId))
        TouchState(spellId, icon, amount, critical)
    end
end)

-- ticker de expiracion + reintento de iconos que fallaron la primera vez
-- (a veces GetSpellInfo devuelve nil si el cliente todavia no cacheo ese spellId)
local ticker = CreateFrame("Frame")
ticker.elapsed = 0
ticker:Hide()  -- oculto hasta que el modulo se active
ticker:SetScript("OnUpdate", function(self, dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed < 0.2 then return end
    self.elapsed = 0

    local now = GetTime()
    local toRemove = {}
    for key, st in pairs(states) do
        if now >= st.expire then
            table.insert(toRemove, key)
        elseif st.iconMissing and type(key) == "number" then
            local icon = select(3, GetSpellInfo(key))
            if icon then
                st.icon = icon
                st.iconMissing = false
                UpdateWidget(st)
            end
        end
    end
    if #toRemove > 0 then
        for _, key in ipairs(toRemove) do RemoveState(key) end
        Layout()
    end
end)

-- ===== slash commands =====
SLASH_DTSU1 = "/dtsu"
SlashCmdList["DTSU"] = function(msg)
    msg = msg:lower():trim()
    if msg == "move" then
        if anchor:IsMovable() and not anchor.moving then
            anchor.bg:Show()
            anchor:EnableMouse(true)
            anchor:RegisterForDrag("LeftButton")
            anchor:SetScript("OnDragStart", anchor.StartMoving)
            anchor:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                local point, _, relPoint, x, y = self:GetPoint()
                DTSU_DB.point = point
                DTSU_DB.x = x
                DTSU_DB.y = y
            end)
            anchor.moving = true
            print("|cff00ff00DTSU|r: modo mover activado, arrastra el cuadro verde. /dtsu move de nuevo para fijar.")
        else
            anchor.bg:Hide()
            anchor:EnableMouse(false)
            anchor.moving = false
            print("|cff00ff00DTSU|r: anchor fijado.")
        end
    elseif msg == "static" then
        DTSU_DB.static = not DTSU_DB.static
        print("|cff00ff00DTSU|r: static = " .. tostring(DTSU_DB.static))
    elseif msg == "short" then
        DTSU_DB.short_numbers = not DTSU_DB.short_numbers
        print("|cff00ff00DTSU|r: numeros cortos = " .. tostring(DTSU_DB.short_numbers))
    else
        print("|cff00ff00DTSU|r: /dtsu move | /dtsu static | /dtsu short")
    end
end

-- ===== integracion NUF: on/off del modulo =====
local function ClearAll()
    local toRemove = {}
    for key in pairs(states) do table.insert(toRemove, key) end
    for _, key in ipairs(toRemove) do RemoveState(key) end
    Layout()
end

local function DTSU_SetEnabled(on)
    if on then
        f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        ticker:Show()
    else
        f:UnregisterAllEvents()
        ClearAll()
        ticker:Hide()
    end
end

K.RegisterModule("DTSU", {
    name    = L["MOD_DTSU"] or "DTSU - Damage Tracker",
    desc    = L["MOD_DTSU_DESC"]
        or "Floating icons with your outgoing swing / spell / dot damage (total, last hit, hits). /dtsu move to reposition.",
    default = false,
    onEnable  = function() DTSU_SetEnabled(true) end,
    onDisable = function() DTSU_SetEnabled(false) end,
});