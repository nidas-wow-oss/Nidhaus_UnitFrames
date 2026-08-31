local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- SacredShieldTracker.lua  (integrado a NUF, de NidhausTools)
-- Portado del grupo de WeakAuras "Sacred Shield Tracker" (wago sYPSLKSKx)
-- con sus DOS hijas.
--
-- 1) "Renew Reminder"  (uid vq7Jh1v9dcX)
--      aura 53601 = el Sacred Shield de 30 min que le pones al aliado.
--      Icono + nombre de la unidad abajo + cuenta atras, y se ilumina
--      cuando quedan 5 segundos o menos (condicion expirationTime <= 5).
--
-- 2) "Shield Buff"     (uid tluZ5zte8nK)
--      aura 58597 = el absorbe de 6s que salta mientras el 53601 esta
--      activo. Solo icono y barrido, sin numeros.
--
-- Comun a las dos, fiel al original:
--   * icono 65x65, coincidencia exacta por ID, solo auras tuyas (ownOnly),
--     sobre cualquier unidad del grupo, se muestra si la cuenta es > 0
--   * sin desaturar, alpha 1, color blanco, zoom 0
--   * solo cargan para PALADIN que conozca Sacred Shield (53601)
--
-- Contenedor (el dynamicgroup): anclado al centro de la pantalla por su
-- borde superior en (-302.81, -321.02), crecimiento hacia abajo, centrado,
-- 2px de separacion, y en el orden de controlledChildren: Renew primero.
--
-- Detalle: la WA traia una segunda condicion ("si show == 0, pintar de
-- rojo") que no puede darse nunca, porque con un unico trigger el icono ya
-- esta oculto cuando ese trigger no esta activo. No se porta por eso.
-- =========================================================

local SHIELD_ID   = 53601;   -- Sacred Shield, 30 min (Renew Reminder)
local ABSORB_ID   = 58597;   -- Sacred Shield, absorbe de 6s (Shield Buff)
local ICON_SIZE   = 65;
local SPACING     = 2;       -- "space" del dynamicgroup
local GLOW_AT     = 5;       -- condicion: expirationTime <= 5

local DEFAULTS = {
    point = "CENTER",
    x     = -302.81262135743,   -- xOffset del grupo
    y     = -321.01764151423,   -- yOffset del grupo
};

-- WoW carga SavedVariables DESPUES de este archivo: los defaults se fusionan
-- tambien en ADDON_LOADED, nunca con "X = X or {...}".
SacredShieldTrackerDB = SacredShieldTrackerDB or {};

local function ApplyDefaults()
    SacredShieldTrackerDB = SacredShieldTrackerDB or {};
    for k, v in pairs(DEFAULTS) do
        if SacredShieldTrackerDB[k] == nil then SacredShieldTrackerDB[k] = v; end
    end
end
ApplyDefaults();

-- ===== contenedor (el dynamicgroup) =====
local anchor = CreateFrame("Frame", "NUF_SacredShieldTracker", UIParent);
anchor:SetWidth(ICON_SIZE);
anchor:SetHeight(ICON_SIZE);
-- selfPoint = "TOP": se ancla por su borde superior y crece hacia abajo.
anchor:SetPoint("TOP", UIParent, SacredShieldTrackerDB.point,
    SacredShieldTrackerDB.x, SacredShieldTrackerDB.y);
anchor:SetMovable(true);
anchor:SetClampedToScreen(true);
anchor:EnableMouse(false);

if K.RegisterScalable then K.RegisterScalable("SacredShieldTracker", anchor, 1.0); end

anchor.bg = anchor:CreateTexture(nil, "BACKGROUND");
anchor.bg:SetAllPoints(anchor);
anchor.bg:SetTexture(0, 1, 0, 0.25);
anchor.bg:Hide();

-- ===== glow (glowType "buttonOverlay" de la WA) =====
-- En 3.3.5 el overlay de alerta de hechizo existe como ActionButton_*. Si no
-- estuviera disponible se cae a un borde amarillo, para no perder el aviso.
local function GlowOn(f)
    if f.glowing then return; end
    f.glowing = true;
    if type(ActionButton_ShowOverlayGlow) == "function" then
        local ok = pcall(ActionButton_ShowOverlayGlow, f);
        if ok then return; end
    end
    f.fallbackGlow:Show();
end

local function GlowOff(f)
    if not f.glowing then return; end
    f.glowing = nil;
    if type(ActionButton_HideOverlayGlow) == "function" then
        pcall(ActionButton_HideOverlayGlow, f);
    end
    f.fallbackGlow:Hide();
end

-- ===== hijas del grupo =====
local CHILDREN = {};

local function CreateChild(id, withText, hideCooldownNumbers)
    local f = CreateFrame("Frame", "NUF_SST_" .. id, anchor);
    f:SetWidth(ICON_SIZE);
    f:SetHeight(ICON_SIZE);

    f.bg = f:CreateTexture(nil, "BACKGROUND");        -- subbackground de la WA
    f.bg:SetAllPoints(f);
    f.bg:SetTexture(0, 0, 0, 0.35);

    f.icon = f:CreateTexture(nil, "ARTWORK");
    f.icon:SetAllPoints(f);
    f.icon:SetTexCoord(0, 1, 0, 1);                   -- zoom 0, sin recortar

    -- cooldown = true, cooldownSwipe = true
    f.cd = CreateFrame("Cooldown", "NUF_SST_" .. id .. "CD", f, "CooldownFrameTemplate");
    f.cd:SetAllPoints(f);
    f.cd:SetReverse(false);
    if hideCooldownNumbers then
        -- "Shield Buff" trae cooldownTextDisabled = true.
        if f.cd.SetHideCountdownNumbers then f.cd:SetHideCountdownNumbers(true); end
        f.cd.noCooldownCount = true;   -- OmniCC respeta esta bandera
        local t = _G[f.cd:GetName() .. "Text"];
        if t then t:Hide(); end
    end
    -- "Renew Reminder" trae cooldownTextDisabled = false: los numeros los
    -- pinta OmniCC sobre el Cooldown, que es como se ven en 3.3.5.

    f.fallbackGlow = f:CreateTexture(nil, "OVERLAY");
    f.fallbackGlow:SetPoint("TOPLEFT", -3, 3);
    f.fallbackGlow:SetPoint("BOTTOMRIGHT", 3, -3);
    f.fallbackGlow:SetTexture(1, 0.85, 0.1, 0.45);
    f.fallbackGlow:Hide();

    if withText then
        -- subtext "%1.unitName", INNER_BOTTOM, Friz Quadrata TT 12 OUTLINE
        f.text = f:CreateFontString(nil, "OVERLAY");
        f.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE");
        f.text:SetPoint("BOTTOM", f, "BOTTOM", 0, 2);
        f.text:SetWidth(ICON_SIZE);
        f.text:SetJustifyH("CENTER");
        f.text:SetTextColor(1, 1, 1, 1);
    end

    f:Hide();
    table.insert(CHILDREN, f);
    return f;
end

-- El orden importa: controlledChildren = { Renew Reminder, Shield Buff }.
local renew      = CreateChild("RenewReminder", true,  false);
local shieldBuff = CreateChild("ShieldBuff",    false, true);

-- Coloca las hijas visibles: hacia abajo, centradas, 2px entre ellas.
local function Layout()
    local y, shown = 0, 0;
    for _, child in ipairs(CHILDREN) do
        if child:IsShown() then
            child:ClearAllPoints();
            child:SetPoint("TOP", anchor, "TOP", 0, -y);
            y = y + child:GetHeight() + SPACING;
            shown = shown + 1;
        end
    end
    anchor:SetHeight(shown > 0 and (y - SPACING) or ICON_SIZE);
end

-- ===== iconos =====
local iconCache = {};
local function ResolveIcon(child, spellId)
    if iconCache[spellId] then
        child.icon:SetTexture(iconCache[spellId]);
        return iconCache[spellId];
    end
    local _, _, tex = GetSpellInfo(spellId);
    if tex then
        iconCache[spellId] = tex;
        child.icon:SetTexture(tex);
    end
    return tex;
end
ResolveIcon(renew, SHIELD_ID);
ResolveIcon(shieldBuff, ABSORB_ID);

-- ===== condiciones de carga (load de la WA) =====
local playerClass = select(2, UnitClass("player"));

local function IsLoadable()
    if playerClass ~= "PALADIN" then return false; end
    -- use_spellknown = 53601. Si la API no existe en este cliente, no bloqueamos.
    if type(IsSpellKnown) == "function" then
        local ok, known = pcall(IsSpellKnown, SHIELD_ID);
        if ok and known ~= nil then return known and true or false; end
    end
    return true;
end

-- ===== escaneo del grupo =====
-- unit = "group" en WeakAuras = jugador + companeros. En 3.3.5 hay que
-- recorrer las unidades a mano.
local scanUnits = {};

local function BuildScanUnits()
    wipe(scanUnits);
    table.insert(scanUnits, "player");
    local raid = (GetNumRaidMembers and GetNumRaidMembers()) or 0;
    if raid > 0 then
        for i = 1, raid do table.insert(scanUnits, "raid" .. i); end
    else
        local party = (GetNumPartyMembers and GetNumPartyMembers()) or 0;
        for i = 1, party do table.insert(scanUnits, "party" .. i); end
    end
end
BuildScanUnits();

-- Primera aparicion en el grupo del aura pedida, puesta por ti.
-- showClones = false: basta con la primera.
local function FindOwnAura(spellId)
    for _, unit in ipairs(scanUnits) do
        if UnitExists(unit) then
            for i = 1, 40 do
                local name, _, _, _, _, duration, expires, caster, _, _, id =
                    UnitAura(unit, i, "HELPFUL");
                if not name then break; end
                -- ownOnly = true: solo lo que hayas puesto tu.
                if id == spellId and caster == "player" then
                    return duration, expires, unit;
                end
            end
        end
    end
    return nil;
end

local moving = false;

local function UpdateChild(child, spellId, wantGlow)
    local duration, expires, unit = FindOwnAura(spellId);
    if not duration then
        GlowOff(child);
        child:Hide();
        return;
    end

    ResolveIcon(child, spellId);
    if duration > 0 and expires then
        child.cd:SetCooldown(expires - duration, duration);
    else
        child.cd:Hide();
    end

    if child.text then
        child.text:SetText(unit and UnitName(unit) or "");
    end

    -- condicion 1: expirationTime <= 5 -> encender el glow
    if wantGlow and expires then
        if (expires - GetTime()) <= GLOW_AT then GlowOn(child); else GlowOff(child); end
    end

    child:Show();
end

local function Update()
    if moving then return; end

    if not IsLoadable() then
        GlowOff(renew); GlowOff(shieldBuff);
        renew:Hide(); shieldBuff:Hide();
        Layout();
        return;
    end

    UpdateChild(renew,      SHIELD_ID, true);
    UpdateChild(shieldBuff, ABSORB_ID, false);
    Layout();
end

-- ===== eventos =====
local ev = CreateFrame("Frame");

ev:SetScript("OnEvent", function(self, event)
    if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE"
       or event == "PLAYER_ENTERING_WORLD" then
        BuildScanUnits();
    end
    Update();
end);

-- El glow depende del tiempo restante, no de un evento: hace falta un
-- repaso periodico. 0.25s alcanza y no cuesta nada.
local ticker = CreateFrame("Frame");
ticker.elapsed = 0;
ticker:Hide();
ticker:SetScript("OnUpdate", function(self, dt)
    self.elapsed = self.elapsed + dt;
    if self.elapsed < 0.25 then return; end
    self.elapsed = 0;
    if moving then return; end
    Update();
end);

local dbLoader = CreateFrame("Frame");
dbLoader:RegisterEvent("ADDON_LOADED");
dbLoader:SetScript("OnEvent", function(self, event, addon)
    if addon ~= AddOnName then return; end
    ApplyDefaults();
    anchor:ClearAllPoints();
    anchor:SetPoint("TOP", UIParent, SacredShieldTrackerDB.point,
        SacredShieldTrackerDB.x, SacredShieldTrackerDB.y);
    self:UnregisterEvent("ADDON_LOADED");
end);

-- ===== mover =====
local function SetMoving(on)
    moving = on and true or false;
    if moving then
        for _, child in ipairs(CHILDREN) do
            GlowOff(child);
            child.cd:Hide();
            child:Show();
        end
        ResolveIcon(renew, SHIELD_ID);
        ResolveIcon(shieldBuff, ABSORB_ID);
        if renew.text then renew.text:SetText(UnitName("player") or "Nombre"); end
        Layout();
        anchor.bg:Show();
        anchor:EnableMouse(true);
        anchor:RegisterForDrag("LeftButton");
        anchor:SetScript("OnDragStart", function(self) self:StartMoving(); end);
        anchor:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing();
            local point, _, _, x, y = self:GetPoint();
            SacredShieldTrackerDB.point, SacredShieldTrackerDB.x, SacredShieldTrackerDB.y = point, x, y;
        end);
    else
        anchor.bg:Hide();
        anchor:EnableMouse(false);
        anchor:RegisterForDrag();
        anchor:SetScript("OnDragStart", nil);
        anchor:SetScript("OnDragStop", nil);
        Update();
    end
end

-- API que consume el panel de Paladin.
function K.SetSacredShieldTrackerMove(on)
    SetMoving(on);
    return moving;
end

function K.IsSacredShieldTrackerMoving()
    return moving;
end

function K.ResetSacredShieldTrackerPosition()
    SacredShieldTrackerDB.point = DEFAULTS.point;
    SacredShieldTrackerDB.x     = DEFAULTS.x;
    SacredShieldTrackerDB.y     = DEFAULTS.y;
    anchor:ClearAllPoints();
    anchor:SetPoint("TOP", UIParent, SacredShieldTrackerDB.point,
        SacredShieldTrackerDB.x, SacredShieldTrackerDB.y);
    print("|cff4FC3F7NUF:|r Sacred Shield Tracker - posicion restaurada a la de la WeakAura.");
end

SLASH_NUFSSTRACKER1 = "/sst";
SlashCmdList["NUFSSTRACKER"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "");
    if msg == "reset" then
        K.ResetSacredShieldTrackerPosition();
    else
        SetMoving(not moving);
    end
end

-- ===== integracion NUF =====
local function SST_SetEnabled(on)
    if on then
        ev:RegisterEvent("UNIT_AURA");
        ev:RegisterEvent("PLAYER_ENTERING_WORLD");
        ev:RegisterEvent("PARTY_MEMBERS_CHANGED");
        ev:RegisterEvent("RAID_ROSTER_UPDATE");
        BuildScanUnits();
        ticker:Show();
        Update();
    else
        ev:UnregisterAllEvents();
        ticker:Hide();
        if moving then SetMoving(false); end
        for _, child in ipairs(CHILDREN) do
            GlowOff(child);
            child:Hide();
        end
        Layout();
    end
end

K.RegisterModule("SacredShieldTracker", {
    name    = L["MOD_SS_TRACKER"] or "Sacred Shield tracker (group)",
    desc    = L["MOD_SS_TRACKER_DESC"]
        or "Tracks your Sacred Shield on the group: who has it with a countdown (glows under 5s) and the 6s absorb. /sst to move it.",
    default = false,
    hideFromModulesTab = true,   -- vive en Interface > ... > Paladin
    onEnable  = function() SST_SetEnabled(true); end,
    onDisable = function() SST_SetEnabled(false); end,
});
