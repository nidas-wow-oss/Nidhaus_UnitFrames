local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ============================================================
-- ClassIcons — Retratos de clase en lugar de portraits
-- Integrado como Module2 de Nidhaus_UnitFrames
-- Estilos: default (Blizzard circles), modern, hs, ex
-- ============================================================

local isActive = false;
local iconStyle = "default";

local _G = _G;
local unpack = unpack;
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS;
local GetNumArenaOpponents = GetNumArenaOpponents;
local SetPortraitToTexture = SetPortraitToTexture;
local UnitClass = UnitClass;
local UnitIsPlayer = UnitIsPlayer;
local UnitExists = UnitExists;

-- Ruta a las texturas dentro de Nidhaus_UnitFrames
local TEXTURE_PATH = "Interface\\AddOns\\" .. AddOnName .. "\\Modules2\\ClassIcons\\Textures\\";

-- ──────────────────────────────────────────────────────────────
--  CORE: Set Portrait
-- ──────────────────────────────────────────────────────────────

local function SetPortrait(self)
    if not isActive then return; end

    local portrait = self and (self.portrait or self.classPortrait);
    if not portrait then return; end

    if UnitIsPlayer(self.unit) then
        local _, playerClass = UnitClass(self.unit);
        if playerClass then
            if iconStyle == "default" then
                portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles");
                portrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[playerClass]));
            else
                SetPortraitToTexture(portrait, TEXTURE_PATH .. iconStyle .. "\\" .. playerClass);
                portrait:SetTexCoord(0, 1, 0, 1);
            end
        end
    else
        if not UnitExists(self.unit) then
            portrait:SetTexture("Interface\\CharacterFrame\\TempPortrait");
        end
        portrait:SetTexCoord(0, 1, 0, 1);
    end
end

-- ──────────────────────────────────────────────────────────────
--  ARENA OnUpdate (solo en arena)
-- ──────────────────────────────────────────────────────────────

local arenaFrame = CreateFrame("Frame");
arenaFrame:Hide();

-- FIX PERF: Throttle arena portrait updates to 5x/sec.
-- Portraits don't change 60+ times per second — class icons only need
-- refreshing when opponents appear or UnitFramePortrait_Update fires.
local arenaUpdateElapsed = 0;

local function ArenaUpdate(self, dt)
    if not isActive or iconStyle == "default" then return; end
    arenaUpdateElapsed = arenaUpdateElapsed + dt;
    if arenaUpdateElapsed < 0.2 then return; end
    arenaUpdateElapsed = 0;
    if not _G.ArenaEnemyFrames or not _G.ArenaEnemyFrames:IsShown() then return; end

    for i = 1, GetNumArenaOpponents() do
        SetPortrait(_G["ArenaEnemyFrame" .. i]);
    end
end

arenaFrame:SetScript("OnUpdate", ArenaUpdate);

-- ──────────────────────────────────────────────────────────────
--  REFRESH: Aplicar a todos los frames visibles
-- ──────────────────────────────────────────────────────────────

local function RefreshAllPortraits()
    if not isActive then return; end

    SetPortrait(PlayerFrame);
    SetPortrait(TargetFrame);
    SetPortrait(FocusFrame);

    for i = 1, (GetNumPartyMembers and GetNumPartyMembers() or 0) do
        SetPortrait(_G["PartyMemberFrame" .. i]);
    end

    if IsAddOnLoaded("Blizzard_ArenaUI") then
        for i = 1, GetNumArenaOpponents() do
            SetPortrait(_G["ArenaEnemyFrame" .. i]);
        end
    end
end

-- ──────────────────────────────────────────────────────────────
--  STYLE: Guardar y cargar estilo
-- ──────────────────────────────────────────────────────────────

local function GetStyle()
    if NidhausUnitFramesDB and NidhausUnitFramesDB.ClassIconsStyle then
        return NidhausUnitFramesDB.ClassIconsStyle;
    end
    return "default";
end

local function SetStyle(style)
    iconStyle = style;
    if NidhausUnitFramesDB then
        NidhausUnitFramesDB.ClassIconsStyle = style;
    end
    RefreshAllPortraits();
end

-- Exponer para uso externo
K.ClassIcons_SetStyle = SetStyle;
K.ClassIcons_GetStyle = GetStyle;

-- ──────────────────────────────────────────────────────────────
--  EVENTS: Detectar arena para OnUpdate
-- ──────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame");
eventFrame:Hide();

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        local _, instanceType = IsInInstance();
        if instanceType == "arena" and isActive then
            arenaFrame:Show();
        else
            arenaFrame:Hide();
        end
    end
end);

-- ──────────────────────────────────────────────────────────────
--  HOOK (una sola vez, permanente)
-- ──────────────────────────────────────────────────────────────

local hooked = false;

local function EnsureHook()
    if hooked then return; end
    hooksecurefunc("UnitFramePortrait_Update", SetPortrait);
    hooked = true;
end

-- ──────────────────────────────────────────────────────────────
--  MODULE REGISTRATION
-- ──────────────────────────────────────────────────────────────

K.RegisterModule("ClassIcons", {
    name = "Class Icons",
    desc = "Reemplaza los retratos por iconos de clase (default, modern, hs, ex)",
    default = false,

    onEnable = function()
        isActive = true;
        iconStyle = GetStyle();
        EnsureHook();
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
        eventFrame:Show();

        -- Activar arena OnUpdate si ya estamos en arena
        local _, instanceType = IsInInstance();
        if instanceType == "arena" then
            arenaFrame:Show();
        end

        RefreshAllPortraits();
    end,

    onDisable = function()
        isActive = false;
        eventFrame:UnregisterAllEvents();
        eventFrame:Hide();
        arenaFrame:Hide();

        -- Restaurar portraits originales manualmente
        local function RestorePortrait(frame)
            if not frame or not frame.portrait or not frame.unit then return; end
            if not UnitExists(frame.unit) then return; end
            frame.portrait:SetTexCoord(0, 1, 0, 1);
            SetPortraitTexture(frame.portrait, frame.unit);
        end

        RestorePortrait(PlayerFrame);
        RestorePortrait(TargetFrame);
        RestorePortrait(FocusFrame);
        for i = 1, (GetNumPartyMembers and GetNumPartyMembers() or 0) do
            RestorePortrait(_G["PartyMemberFrame" .. i]);
        end
    end,

    -- UI extra: dropdown de estilos (llamado por OptionsPanel)
    createUI = function(parent, yPos)
        local STYLES = {
            { value = "default", label = "Default" },
            { value = "modern",  label = "Modern" },
            { value = "hs",      label = "HS" },
            { value = "ex",      label = "Exprmtl" },
        };

        local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        label:SetPoint("TOPLEFT", 36, yPos);
        label:SetText("|cffAAAAAAEstilo:|r");

        local btnX = 85;
        local styleBtns = {};

        for _, s in ipairs(STYLES) do
            local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
            btn:SetPoint("TOPLEFT", btnX, yPos + 3);
            btn:SetSize(72, 18);
            btn:SetText(s.label);

            local fs = btn:GetFontString();
            if fs then fs:SetFont("Fonts\\FRIZQT__.TTF", 9, ""); end

            btn.style = s.value;
            styleBtns[#styleBtns + 1] = btn;

            btn:SetScript("OnClick", function(self)
                SetStyle(self.style);
                -- Highlight botón activo
                for _, b in ipairs(styleBtns) do
                    if b.style == iconStyle then
                        b:GetFontString():SetTextColor(0, 1, 0);
                    else
                        b:GetFontString():SetTextColor(1, 1, 1);
                    end
                end
            end);

            -- Highlight inicial
            if s.value == iconStyle then
                fs:SetTextColor(0, 1, 0);
            end

            btnX = btnX + 78;
        end

        return yPos - 28;
    end,
});

-- ──────────────────────────────────────────────────────────────
--  MIGRACIÓN: Si el usuario tenía ClassIcons standalone con
--  ClassIconsSV, migrar el estilo
-- ──────────────────────────────────────────────────────────────

local migrateFrame = CreateFrame("Frame");
migrateFrame:RegisterEvent("PLAYER_LOGIN");
migrateFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN");

    -- Migrar desde ClassIconsSV si existe y no hay estilo guardado
    if ClassIconsSV and ClassIconsSV.style and NidhausUnitFramesDB then
        if not NidhausUnitFramesDB.ClassIconsStyle then
            NidhausUnitFramesDB.ClassIconsStyle = ClassIconsSV.style;
            iconStyle = ClassIconsSV.style;
        end
    end
end);