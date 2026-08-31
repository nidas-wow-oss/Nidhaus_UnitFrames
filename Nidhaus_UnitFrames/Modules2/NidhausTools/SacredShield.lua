local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- SacredShield.lua  (integrado a NUF, de NidhausTools)
-- Portado de la WeakAura "SS".
--
-- Muestra un icono cuando tu OBJETIVO tiene el buff Sacred Shield (58597).
--
-- Comportamiento original que se respeta:
--   * icono 74x74, sin barrido de cooldown, sin glow, sin desaturar
--   * trigger aura2: unidad "target", HELPFUL, spellId 58597 exacto
--   * posicion inicial: centro de pantalla en (-132.27, 169.24)
--
-- Cambios respecto de la WA:
--   * sin texto (la WA pintaba "%s" = cargas, y este aura no acumula)
--   * movible, con la posicion guardada entre sesiones
--   * se prende/apaga como modulo de NUF: apagado no escucha UNIT_AURA
-- =========================================================

local SPELL_ID = 58597;   -- Sacred Shield (coincidencia exacta por ID)
local UNIT     = "target";
local FILTER   = "HELPFUL";
local SIZE     = 74;

-- OJO: WoW carga SavedVariables DESPUES de ejecutar este archivo, asi que
-- "X = X or {...}" no basta: si la tabla guardada llega vacia o incompleta los
-- campos quedan en nil. Los defaults se fusionan tambien en ADDON_LOADED.
local DEFAULTS = {
    point = "CENTER",
    x     = -132.26660218206,   -- xOffset de la WeakAura
    y     = 169.24457389997,    -- yOffset de la WeakAura
};

SacredShieldDB = SacredShieldDB or {};

local function ApplyDefaults()
    SacredShieldDB = SacredShieldDB or {};
    for k, v in pairs(DEFAULTS) do
        if SacredShieldDB[k] == nil then SacredShieldDB[k] = v; end
    end
end
ApplyDefaults();

-- ===== marco =====
local frame = CreateFrame("Frame", "NUF_SacredShieldFrame", UIParent);
frame:SetWidth(SIZE);
frame:SetHeight(SIZE);
frame:SetPoint(SacredShieldDB.point, UIParent, SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y);
frame:SetMovable(true);
frame:SetClampedToScreen(true);
frame:EnableMouse(false);
frame:Hide();

-- Escala configurable desde el panel, igual que DTSU.
if K.RegisterScalable then K.RegisterScalable("SacredShield", frame, 1.0); end

frame.bg = frame:CreateTexture(nil, "BACKGROUND");
frame.bg:SetAllPoints(frame);
frame.bg:SetTexture(0, 0, 0, 0.35);
frame.bg:Hide();

frame.icon = frame:CreateTexture(nil, "ARTWORK");
frame.icon:SetAllPoints(frame);
-- zoom = 0 y keepAspectRatio = false en la WA: textura completa, sin recortar.
frame.icon:SetTexCoord(0, 1, 0, 1);

frame.moveBorder = frame:CreateTexture(nil, "OVERLAY");
frame.moveBorder:SetAllPoints(frame);
frame.moveBorder:SetTexture(0, 1, 0, 0.30);
frame.moveBorder:Hide();

-- ===== icono del hechizo =====
-- Se resuelve una vez; se reintenta si el cliente aun no lo cacheo.
local iconTexture;
local function ResolveIcon()
    if iconTexture then return iconTexture; end
    local _, _, tex = GetSpellInfo(SPELL_ID);
    if tex then
        iconTexture = tex;
        frame.icon:SetTexture(tex);
    end
    return iconTexture;
end
ResolveIcon();

-- ===== deteccion del buff =====
-- En 3.3.5 UnitAura no permite filtrar por spellId, hay que recorrer los huecos
-- y comparar el id del ultimo retorno. Asi no salta con otro hechizo homonimo.
local function HasAura()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitAura(UNIT, i, FILTER);
        if not name then return false; end
        if spellId == SPELL_ID then return true; end
    end
    return false;
end

local moving = false;

local function Update()
    if moving then return; end   -- en modo mover el icono se queda fijo y visible
    if UnitExists(UNIT) and HasAura() then
        ResolveIcon();
        frame:Show();
    else
        frame:Hide();
    end
end

-- ===== eventos =====
local f = CreateFrame("Frame");

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "UNIT_AURA" and arg1 ~= UNIT then return; end
    Update();
end);

local dbLoader = CreateFrame("Frame");
dbLoader:RegisterEvent("ADDON_LOADED");
dbLoader:SetScript("OnEvent", function(self, event, addon)
    if addon ~= AddOnName then return; end
    ApplyDefaults();   -- ahora si, sobre la tabla que trajo SavedVariables
    frame:ClearAllPoints();
    frame:SetPoint(SacredShieldDB.point, UIParent, SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y);
    self:UnregisterEvent("ADDON_LOADED");
end);

-- ===== mover =====
local function SetMoving(on)
    moving = on;
    if on then
        ResolveIcon();
        frame.icon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark");
        frame:EnableMouse(true);
        frame:RegisterForDrag("LeftButton");
        frame:SetScript("OnDragStart", function(self) self:StartMoving(); end);
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing();
            local point, _, _, x, y = self:GetPoint();
            SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y = point, x, y;
        end);
        frame.bg:Show();
        frame.moveBorder:Show();
        frame:Show();
    else
        frame:EnableMouse(false);
        frame:RegisterForDrag();
        frame:SetScript("OnDragStart", nil);
        frame:SetScript("OnDragStop", nil);
        frame.bg:Hide();
        frame.moveBorder:Hide();
        Update();
    end
end

-- API que consume el panel (Interface > ... > Paladin).
function K.SetSacredShieldMove(on)
    SetMoving(on and true or false);
    return moving;
end

function K.IsSacredShieldMoving()
    return moving;
end

function K.ResetSacredShieldPosition()
    SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y = DEFAULTS.point, DEFAULTS.x, DEFAULTS.y;
    frame:ClearAllPoints();
    frame:SetPoint(SacredShieldDB.point, UIParent, SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y);
    print("|cff4FC3F7NUF:|r SacredShield - posicion restaurada a la de la WeakAura.");
end

SLASH_NUFSACREDSHIELD1 = "/ss";
SLASH_NUFSACREDSHIELD2 = "/sacredshield";
SlashCmdList["NUFSACREDSHIELD"] = function(msg)
    msg = (msg or ""):lower();
    msg = msg:gsub("^%s+", ""):gsub("%s+$", "");

    if msg == "reset" then
        SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y = DEFAULTS.point, DEFAULTS.x, DEFAULTS.y;
        frame:ClearAllPoints();
        frame:SetPoint(SacredShieldDB.point, UIParent, SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y);
        print("|cff4FC3F7NUF:|r SacredShield - posicion restaurada a la de la WeakAura.");
    else
        SetMoving(not moving);
    end
end

-- ===== integracion NUF: on/off del modulo =====
local function SS_SetEnabled(on)
    if on then
        f:RegisterEvent("PLAYER_ENTERING_WORLD");
        f:RegisterEvent("PLAYER_TARGET_CHANGED");
        f:RegisterEvent("UNIT_AURA");
        Update();
    else
        f:UnregisterAllEvents();
        if moving then SetMoving(false); end
        frame:Hide();
    end
end

K.RegisterModule("SacredShield", {
    name    = L["MOD_SACREDSHIELD"] or "Sacred Shield (target)",
    desc    = L["MOD_SACREDSHIELD_DESC"]
        or "Shows an icon while your target has Sacred Shield. /ss to move it.",
    default = false,
    hideFromModulesTab = true,  -- vive en Interface > ... > Paladin, como PaladinICD
    onEnable    = function() SS_SetEnabled(true); end,
    onDisable   = function() SS_SetEnabled(false); end,
});
