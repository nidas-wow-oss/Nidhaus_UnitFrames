local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- SeductionAlert.lua  (integrado a NUF, de NidhausTools)
-- Portado de la WeakAura "Seduction >>> Player".
--
-- Que hace: avisa cuando la succubus de un rival de arena empieza a
-- lanzarte Seduccion A TI, con icono en pantalla y un sonido.
--
-- Fiel al original:
--   * icono 64x64 anclado al centro de la pantalla en (0, 164.62)
--   * tres triggers unidos por "any": arenapet1, arenapet2 y arenapet3
--   * castType = "cast" y destUnit = "player": solo si el objetivo del
--     lanzamiento eres tu
--   * sonido al aparecer, sin barrido de cooldown, sin glow
--
-- Cambios inevitables:
--   * el sonido de la WA apuntaba a WeakAuras\Media\Sounds\Brass.mp3, que
--     no existe sin WeakAuras instalado. Se usa un sonido del cliente.
--   * la WA pintaba "%s" (cargas) en el icono; en un trigger de lanzamiento
--     no hay cargas, asi que no se pinta nada.
-- =========================================================

local SPELL_NAME = GetSpellInfo(6358) or "Seduction";   -- 6358 = Seduction
local ICON_SIZE  = 64;
local UNITS      = { "arenapet1", "arenapet2", "arenapet3" };
local SOUND      = "Sound\\Interface\\RaidWarning.wav";

local DEFAULTS = {
    point = "CENTER",
    x     = 0,                    -- xOffset de la WA
    y     = 164.61526768373,      -- yOffset de la WA
};

SeductionAlertDB = SeductionAlertDB or {};

local function ApplyDefaults()
    SeductionAlertDB = SeductionAlertDB or {};
    for k, v in pairs(DEFAULTS) do
        if SeductionAlertDB[k] == nil then SeductionAlertDB[k] = v; end
    end
end
ApplyDefaults();

-- ===== marco =====
local frame = CreateFrame("Frame", "NUF_SeductionAlert", UIParent);
frame:SetWidth(ICON_SIZE);
frame:SetHeight(ICON_SIZE);
frame:SetPoint(SeductionAlertDB.point, UIParent, SeductionAlertDB.point,
    SeductionAlertDB.x, SeductionAlertDB.y);
frame:SetMovable(true);
frame:SetClampedToScreen(true);
frame:EnableMouse(false);
frame:Hide();

if K.RegisterScalable then K.RegisterScalable("SeductionAlert", frame, 1.0); end

frame.bg = frame:CreateTexture(nil, "BACKGROUND");
frame.bg:SetAllPoints(frame);
frame.bg:SetTexture(0, 0, 0, 0.35);

frame.icon = frame:CreateTexture(nil, "ARTWORK");
frame.icon:SetAllPoints(frame);
frame.icon:SetTexCoord(0, 1, 0, 1);

frame.moveBorder = frame:CreateTexture(nil, "OVERLAY");
frame.moveBorder:SetAllPoints(frame);
frame.moveBorder:SetTexture(0, 1, 0, 0.30);
frame.moveBorder:Hide();

local iconTexture;
local function ResolveIcon()
    if iconTexture then return iconTexture; end
    local _, _, tex = GetSpellInfo(6358);
    if tex then
        iconTexture = tex;
        frame.icon:SetTexture(tex);
    end
    return iconTexture;
end
ResolveIcon();

local moving  = false;
local playing = nil;   -- unidad cuyo lanzamiento estamos mostrando

-- ===== deteccion =====
-- destUnit = "player" en la WA: el objetivo del lanzamiento debe ser el
-- jugador. Se comprueba con la unidad "<pet>target".
local function IsCastingAtMe(unit)
    local name = UnitCastingInfo(unit);
    if name ~= SPELL_NAME then return false; end
    return UnitIsUnit(unit .. "target", "player") and true or false;
end

local function Show(unit)
    ResolveIcon();
    frame:Show();
    if playing ~= unit then
        playing = unit;
        PlaySoundFile(SOUND);
    end
end

local function Update()
    if moving then return; end
    for _, unit in ipairs(UNITS) do
        if UnitExists(unit) and IsCastingAtMe(unit) then
            Show(unit);
            return;
        end
    end
    playing = nil;
    frame:Hide();
end

-- ===== eventos =====
local ev = CreateFrame("Frame");

ev:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        playing = nil;
        frame:Hide();
        return;
    end
    -- Los UNIT_SPELLCAST_* de arenapetN llegan con su propia unidad; se
    -- reevalua todo igualmente por si el objetivo del lanzamiento cambio.
    Update();
end);

local dbLoader = CreateFrame("Frame");
dbLoader:RegisterEvent("ADDON_LOADED");
dbLoader:SetScript("OnEvent", function(self, event, addon)
    if addon ~= AddOnName then return; end
    ApplyDefaults();
    frame:ClearAllPoints();
    frame:SetPoint(SeductionAlertDB.point, UIParent, SeductionAlertDB.point,
        SeductionAlertDB.x, SeductionAlertDB.y);
    self:UnregisterEvent("ADDON_LOADED");
end);

-- ===== mover =====
local function SetMoving(on)
    moving = on and true or false;
    if moving then
        ResolveIcon();
        frame.icon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark");
        frame.moveBorder:Show();
        frame:EnableMouse(true);
        frame:RegisterForDrag("LeftButton");
        frame:SetScript("OnDragStart", function(self) self:StartMoving(); end);
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing();
            local point, _, _, x, y = self:GetPoint();
            SeductionAlertDB.point, SeductionAlertDB.x, SeductionAlertDB.y = point, x, y;
        end);
        frame:Show();
    else
        frame.moveBorder:Hide();
        frame:EnableMouse(false);
        frame:RegisterForDrag();
        frame:SetScript("OnDragStart", nil);
        frame:SetScript("OnDragStop", nil);
        Update();
    end
end

function K.SetSeductionAlertMove(on)
    SetMoving(on);
    return moving;
end

function K.IsSeductionAlertMoving()
    return moving;
end

function K.ResetSeductionAlertPosition()
    SeductionAlertDB.point = DEFAULTS.point;
    SeductionAlertDB.x     = DEFAULTS.x;
    SeductionAlertDB.y     = DEFAULTS.y;
    frame:ClearAllPoints();
    frame:SetPoint(SeductionAlertDB.point, UIParent, SeductionAlertDB.point,
        SeductionAlertDB.x, SeductionAlertDB.y);
    print("|cff4FC3F7NUF:|r Seduction alert - posicion restaurada a la de la WeakAura.");
end

SLASH_NUFSEDUCTION1 = "/seduction";
SlashCmdList["NUFSEDUCTION"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "");
    if msg == "reset" then
        K.ResetSeductionAlertPosition();
    elseif msg == "test" then
        ResolveIcon();
        frame.icon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark");
        frame:Show();
        PlaySoundFile(SOUND);
        print("|cff4FC3F7NUF:|r Seduction alert - prueba. /seduction test otra vez o cambia de zona para ocultarlo.");
    else
        SetMoving(not moving);
    end
end

-- ===== integracion NUF =====
local function SA_SetEnabled(on)
    if on then
        ev:RegisterEvent("UNIT_SPELLCAST_START");
        ev:RegisterEvent("UNIT_SPELLCAST_STOP");
        ev:RegisterEvent("UNIT_SPELLCAST_FAILED");
        ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        ev:RegisterEvent("UNIT_SPELLCAST_DELAYED");
        ev:RegisterEvent("UNIT_TARGET");
        ev:RegisterEvent("PLAYER_ENTERING_WORLD");
        Update();
    else
        ev:UnregisterAllEvents();
        if moving then SetMoving(false); end
        playing = nil;
        frame:Hide();
    end
end

K.RegisterModule("SeductionAlert", {
    name    = L["MOD_SEDUCTION"] or "Seduction on you (arena)",
    desc    = L["MOD_SEDUCTION_DESC"]
        or "Warns with icon and sound when an enemy succubus starts casting Seduction on you in arena. /seduction to move it.",
    default = false,
    hideFromModulesTab = true,   -- vive en la seccion PvP
    configLabel = L["BTN_MODULE_MOVE"] or "Move",
    configFunc  = function() SetMoving(not moving); end,
    onEnable  = function() SA_SetEnabled(true); end,
    onDisable = function() SA_SetEnabled(false); end,
});
