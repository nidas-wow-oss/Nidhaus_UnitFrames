local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ============================================================
-- ActionBars.lua — Unify Action Bars
-- Saves ALL original state before touching anything.
-- On disable: restores exactly the saved state, in real-time.
-- ============================================================

local isEnabled  = false;
local inCombat   = false;
local uabEventsFrame;
local _, playerClass = UnitClass("player");
local MAX_PLAYER_LEVEL = 80;

-- ──────────────────────────────────────────────────────────────
--  REUSABLE RETRY FRAME (FIX: antes se creaba un frame nuevo en cada evento)
-- ──────────────────────────────────────────────────────────────
local uabRetryFrame = CreateFrame("Frame");
local uabRetryCount = 0;
local uabRetryMaxTries = 5;
local uabRetryInterval = 0.3;
local uabRetryElapsed = 0;
local uabRetryAction = nil;

uabRetryFrame:Hide();
uabRetryFrame:SetScript("OnUpdate", function(self, dt)
    uabRetryElapsed = uabRetryElapsed + dt;
    if uabRetryElapsed >= uabRetryInterval then
        uabRetryElapsed = 0;
        uabRetryCount = uabRetryCount + 1;
        if uabRetryAction then uabRetryAction(); end
        if uabRetryCount >= uabRetryMaxTries then
            self:Hide();
            uabRetryAction = nil;
        end
    end
end);

local function StartRetry(fn, maxTries, interval)
    uabRetryCount = 0;
    uabRetryMaxTries = maxTries or 5;
    uabRetryInterval = interval or 0.3;
    uabRetryElapsed = 0;
    uabRetryAction = fn;
    uabRetryFrame:Show();
end

-- ──────────────────────────────────────────────────────────────
--  FIX: Reusable waiter for DisableUnifyActionBars combat defer
--  (before: created a NEW frame each time it was called in combat)
-- ──────────────────────────────────────────────────────────────
local disableWaiter = CreateFrame("Frame");
disableWaiter:SetScript("OnEvent", function(s)
    s:UnregisterAllEvents();
    if isEnabled then
        K.DisableUnifyActionBars();
    end
end);

-- ──────────────────────────────────────────────────────────────
--  FIX: Reusable waiter for EnableUnifyActionBars combat defer
--  (same pattern as disableWaiter above)
-- ──────────────────────────────────────────────────────────────
local enableWaiter = CreateFrame("Frame");
enableWaiter:SetScript("OnEvent", function(s)
    s:UnregisterAllEvents();
    if not isEnabled and C.UnifyActionBars then
        K.EnableUnifyActionBars();
    end
end);

-- ──────────────────────────────────────────────────────────────
--  STATE STORAGE
-- ──────────────────────────────────────────────────────────────

-- saved[frameName] = { point, relativeTo, relativePoint, x, y, scale, width }
local saved = {};
-- saved textures: { obj, originalAlpha, wasShown }
local savedTextures = {};
-- original SetPoint overrides
local origSetPoints = {};

-- ──────────────────────────────────────────────────────────────
--  SAVE / RESTORE HELPERS
-- ──────────────────────────────────────────────────────────────

local function SaveFrame(name, frame)
    if not frame or saved[name] then return; end
    local point, rel, relPoint, x, y = frame:GetPoint(1);
    saved[name] = {
        point      = point,
        rel        = rel,
        relPoint   = relPoint,
        x          = x or 0,
        y          = y or 0,
        scale      = frame.GetScale and frame:GetScale() or nil,
        width      = frame.GetWidth and frame:GetWidth() or nil,
    };
    -- Guardar font si es un FontString
    if frame.GetFont then
        local f, s, fl = frame:GetFont();
        if f then saved[name].font = {f, s, fl}; end
    end
end

local function RestoreFrame(name, frame)
    if not frame then return; end
    local s = saved[name];
    if not s then return; end
    frame:ClearAllPoints();
    if s.point then
        frame:SetPoint(s.point, s.rel, s.relPoint, s.x, s.y);
    end
    if s.scale and frame.SetScale then
        frame:SetScale(s.scale);
    end
    if s.width and s.width > 0 and frame.SetWidth then
        frame:SetWidth(s.width);
    end
    -- Restaurar font si fue guardada
    if s.font and frame.SetFont then
        frame:SetFont(unpack(s.font));
    end
end

local function SaveTexture(obj)
    if not obj then return; end
    table.insert(savedTextures, {
        obj       = obj,
        alpha     = obj:GetAlpha(),
        shown     = obj:IsShown(),
    });
end

local function HideAllTextures()
    if InCombatLockdown() then return; end
    for _, t in ipairs(savedTextures) do
        t.obj:Hide();
        t.obj:SetAlpha(0);
    end
end

local function RestoreAllTextures()
    for _, t in ipairs(savedTextures) do
        t.obj:SetAlpha(t.alpha);
        if t.shown then t.obj:Show(); else t.obj:Hide(); end
    end
end

local function LockSetPoint(frame)
    if not frame then return; end
    if InCombatLockdown() then return; end
    if not origSetPoints[frame] then
        origSetPoints[frame] = frame.SetPoint;
    end
    frame.SetPoint = function() end;
end

local function UnlockSetPoint(frame)
    if not frame then return; end
    if origSetPoints[frame] then
        frame.SetPoint = origSetPoints[frame];
    end
end

-- ──────────────────────────────────────────────────────────────
--  COLLECT ALL ORIGINALS (called once, before any changes)
-- ──────────────────────────────────────────────────────────────

local function CaptureOriginals()
    -- Frames with positions
    SaveFrame("MainMenuBar",              MainMenuBar);
    SaveFrame("MainMenuBarBackpackButton",MainMenuBarBackpackButton);
    SaveFrame("CharacterMicroButton",     CharacterMicroButton);
    SaveFrame("MultiBarBottomLeft",       MultiBarBottomLeft);
    SaveFrame("MultiBarBottomRight",      MultiBarBottomRight);
    SaveFrame("MultiBarBottomRightButton7", MultiBarBottomRightButton7);
    SaveFrame("MultiBarRight",            MultiBarRight);
    SaveFrame("MultiBarLeft",             MultiBarLeft);
    SaveFrame("MainMenuExpBar",           MainMenuExpBar);
    SaveFrame("ExhaustionTick",           ExhaustionTick);
    SaveFrame("MainMenuBarExpText",       MainMenuBarExpText);
    SaveFrame("ReputationWatchBar",       ReputationWatchBar);
    SaveFrame("ReputationWatchStatusBar", ReputationWatchStatusBar);
    SaveFrame("ReputationWatchStatusBarText", ReputationWatchStatusBarText);
    if PossessBarFrame  then SaveFrame("PossessBarFrame",  PossessBarFrame);  end
    if PossessButton1   then SaveFrame("PossessButton1",   PossessButton1);   end
    if ShapeshiftBarFrame then SaveFrame("ShapeshiftBarFrame", ShapeshiftBarFrame); end
    if PetActionBarFrame  then SaveFrame("PetActionBarFrame",  PetActionBarFrame);  end
    if PetActionBarHealthBar then SaveFrame("PetActionBarHealthBar", PetActionBarHealthBar); end
    if PetActionBarManaBar   then SaveFrame("PetActionBarManaBar",   PetActionBarManaBar);   end
    if ActionBarUpButton   then SaveFrame("ActionBarUpButton",   ActionBarUpButton);   end
    if ActionBarDownButton then SaveFrame("ActionBarDownButton", ActionBarDownButton); end

    -- FIX: Guardar posicion original de gryphons (Blizzard las posiciona dinamicamente)
    if MainMenuBarLeftEndCap  then SaveFrame("MainMenuBarLeftEndCap",  MainMenuBarLeftEndCap);  end
    if MainMenuBarRightEndCap then SaveFrame("MainMenuBarRightEndCap", MainMenuBarRightEndCap); end

    -- FIX: Guardar posición y escala de bag slots (antes no se restauraban al desactivar)
    if CharacterBag0Slot then SaveFrame("CharacterBag0Slot", CharacterBag0Slot); end
    if CharacterBag1Slot then SaveFrame("CharacterBag1Slot", CharacterBag1Slot); end
    if CharacterBag2Slot then SaveFrame("CharacterBag2Slot", CharacterBag2Slot); end
    if CharacterBag3Slot then SaveFrame("CharacterBag3Slot", CharacterBag3Slot); end
    if KeyRingButton      then SaveFrame("KeyRingButton",     KeyRingButton);     end

    -- Decorative textures/frames to hide
    savedTextures = {};
    local texNames = {
        "MainMenuBarTexture0","MainMenuBarTexture1","MainMenuBarTexture2","MainMenuBarTexture3",
        "MainMenuXPBarTexture0","MainMenuXPBarTexture1","MainMenuXPBarTexture2","MainMenuXPBarTexture3",
        "ReputationWatchBarTexture0","ReputationWatchBarTexture1","ReputationWatchBarTexture2","ReputationWatchBarTexture3",
        "ReputationXPBarTexture0","ReputationXPBarTexture1","ReputationXPBarTexture2","ReputationXPBarTexture3",
        "MainMenuMaxLevelBar0","MainMenuMaxLevelBar1","MainMenuMaxLevelBar2","MainMenuMaxLevelBar3",
        "MainMenuBarLeftEndCap","MainMenuBarRightEndCap",
        "PossessBackground1","PossessBackground2",
        "BonusActionBarTexture0","BonusActionBarTexture1",
        "MainMenuBarPageNumber","MainMenuBarPerformanceBarFrame",
    };
    for _, name in ipairs(texNames) do
        SaveTexture(_G[name]);
    end
end

-- ──────────────────────────────────────────────────────────────
--  LAYOUT (applied while enabled, re-applied on world events)
-- ──────────────────────────────────────────────────────────────

local function GetBarOffset()
    local o = 0;
    if MainMenuExpBar and MainMenuExpBar:IsShown() then o = o + 6; end
    if ReputationWatchBar and ReputationWatchBar:IsShown() then o = o + 6; end
    return o;
end

-- FIX: Cola de funciones pendientes por combate (antes creaba un frame nuevo cada vez)
local deferQueue = {};
local deferFrame = CreateFrame("Frame");
deferFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
deferFrame:SetScript("OnEvent", function()
    -- FIX PERF: Reuse table instead of creating new one (avoids GC)
    local n = #deferQueue;
    if n == 0 then return; end
    for i = 1, n do pcall(deferQueue[i]); end
    wipe(deferQueue);
end);

local function DeferIfCombat(fn)
    if InCombatLockdown() then
        table.insert(deferQueue, fn);
        return true;
    end
    return false;
end

local function ApplyMicroAndBags()
    if DeferIfCombat(ApplyMicroAndBags) then return; end
    -- FIX: Skip during vehicle — Blizzard controls micro button layout
    if UnitInVehicle and UnitInVehicle("player") then return; end
    -- Create BagPackFrame if it doesn't exist (shared with MiniBar)
    if K.CreateBagPackFrame then K.CreateBagPackFrame(); end
    -- Use BagPackFrame layout (shared with MiniBar)
    if K.ApplyBagPackLayout then
        K.ApplyBagPackLayout();
    else
        -- Fallback: simple positioning
        MainMenuBarBackpackButton:ClearAllPoints();
        MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -5, 42);
        if CharacterMicroButton then
            CharacterMicroButton:ClearAllPoints();
            CharacterMicroButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -227, 2);
        end
    end
end

local function ApplyShapeshiftBar()
    if DeferIfCombat(ApplyShapeshiftBar) then return; end
    if not ShapeshiftBarFrame then return; end
    UnlockSetPoint(ShapeshiftBarFrame);
    ShapeshiftBarFrame:ClearAllPoints();
    ShapeshiftBarFrame:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", 30, 40 + GetBarOffset());
    ShapeshiftBarFrame:SetScale(1);
    LockSetPoint(ShapeshiftBarFrame);
end

-- Posición de la pet bar por clase
-- DOS modos: normal (sin aura/forma) y con shapeshift (shadowform, metamorfosis, auras, etc)
-- Anchor: BOTTOMLEFT, MainMenuBar, TOPLEFT para todas las clases

-- Sin shapeshift visible (posición normal)
local PET_BAR_NORMAL = {
    DEATHKNIGHT = { x = 290, y = 43 },
    PRIEST      = { x = 250, y = 43 },  -- shadowfiend SIN shadowform
    WARLOCK     = { x = 200, y = 43 },  -- pet SIN metamorfosis
    SHAMAN      = { x = 250, y = 43 },  -- lobos/elemental
    HUNTER      = { x = 35, y = 43 },  -- pet completa
    MAGE        = { x = 35, y = 43 },  -- elemental de agua
    DRUID       = { x = 250, y = 43 },  -- treants
}

-- Con shapeshift visible (shadowform, metamorfosis, auras, stances)
local PET_BAR_SHIFTED = {
    DEATHKNIGHT = { x = 290, y = 43 },
    PRIEST      = { x = 250, y = 43 },  -- shadowfiend CON shadowform
    WARLOCK     = { x = 250, y = 43 },  -- pet CON metamorfosis (misma que priest shadow)
    SHAMAN      = { x = 250, y = 43 },  -- (no debería pasar, pero por si acaso)
    HUNTER      = { x = 250, y = 43 },  -- (no tiene shapeshift)
    MAGE        = { x = 250, y = 43 },  -- (no tiene shapeshift)
    DRUID       = { x = 250, y = 43 },  -- formas
}

local PET_BAR_DEFAULT = { x = 250, y = 43 };

local function ApplyPetBar()
    if DeferIfCombat(ApplyPetBar) then return; end
    if not PetActionBarFrame then return; end
    UnlockSetPoint(PetActionBarFrame);
    PetActionBarFrame:ClearAllPoints();

    local shifted = ShapeshiftBarFrame and ShapeshiftBarFrame:IsShown();
    local tbl = shifted and PET_BAR_SHIFTED or PET_BAR_NORMAL;
    local pos = tbl[playerClass] or PET_BAR_DEFAULT;

    local offset = GetBarOffset();
    PetActionBarFrame:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", pos.x, pos.y + offset);

    PetActionBarFrame:SetScale(1);
    LockSetPoint(PetActionBarFrame);
    if PetActionBarHealthBar then
        PetActionBarHealthBar:ClearAllPoints();
        PetActionBarHealthBar:SetPoint("BOTTOMLEFT", PetActionBarFrame, "TOPLEFT", 0, 4);
        PetActionBarHealthBar:Show();
    end
    if PetActionBarManaBar then
        PetActionBarManaBar:ClearAllPoints();
        PetActionBarManaBar:SetPoint("TOPLEFT", PetActionBarHealthBar or PetActionBarFrame, "BOTTOMLEFT", 0, -2);
        PetActionBarManaBar:Show();
    end
end

local function ApplyMainBar()
    if DeferIfCombat(ApplyMainBar) then return; end
    if UnitLevel("player") < MAX_PLAYER_LEVEL then
        MainMenuBar:ClearAllPoints();
        MainMenuBar:SetPoint("BOTTOM", UIParent, -128, 11);
    else
        MainMenuBar:ClearAllPoints();
        MainMenuBar:SetPoint("BOTTOM", UIParent, -128, 0);
    end
end

-- FIX: Función dedicada para re-posicionar XP y Rep bars.
-- La XP bar se ancla DIRECTAMENTE a MainMenuBar (no a RepBar).
-- Esto elimina la dependencia frágil de RepBar que causaba que la 
-- posición cambiara entre /reload y toggle del checkbox.
local function ApplyXPRepBars()
    if DeferIfCombat(ApplyXPRepBars) then return; end

    -- Desbloquear para poder re-posicionar
    UnlockSetPoint(MainMenuExpBar);

    -- XP bar: anclada directamente a MainMenuBar, entre las dos filas de botones.
    -- Los action buttons son ~36px de alto; la barra va justo encima.
    MainMenuExpBar:SetScale(0.735);
    if ExhaustionTick then ExhaustionTick:SetScale(0.735); end
    MainMenuExpBar:ClearAllPoints();
    MainMenuExpBar:SetPoint("BOTTOMLEFT",  MainMenuBar, "BOTTOMLEFT",  0, 38);
    MainMenuExpBar:SetPoint("BOTTOMRIGHT", MainMenuBar, "BOTTOMRIGHT", 0, 38);
    if MainMenuBarExpText then
        MainMenuBarExpText:ClearAllPoints();
        MainMenuBarExpText:SetPoint("TOP", MainMenuExpBar, 0, 1);
        MainMenuBarExpText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE");
    end

    -- Rep bar: escala y ancho, sin tocar posición (Blizzard la maneja)
    ReputationWatchBar:SetScale(0.9);
    ReputationWatchBar:SetWidth(500);
    ReputationWatchStatusBar:SetScale(0.82);
    ReputationWatchStatusBar:SetPoint("LEFT", ReputationWatchBar, -35, -54);
    if ReputationWatchStatusBarText then
        ReputationWatchStatusBarText:SetFont("Fonts\\FRIZQT__.TTF", 11.5, "OUTLINE");
        ReputationWatchStatusBarText:SetPoint("TOP", ReputationWatchStatusBar, 0, 2);
    end

    -- Bloquear SetPoint en XP bar para que Blizzard no la mueva
    LockSetPoint(MainMenuExpBar);
end

local function ApplyPagingButtons()
    if DeferIfCombat(ApplyPagingButtons) then return; end
    UnlockSetPoint(ActionBarUpButton);
    UnlockSetPoint(ActionBarDownButton);
    ActionBarUpButton:ClearAllPoints();
    ActionBarDownButton:ClearAllPoints();
    local last = _G["MultiBarBottomRightButton12"] or MultiBarBottomRight;
    ActionBarDownButton:SetPoint("LEFT", last, "RIGHT", 2, -8);
    ActionBarUpButton:SetPoint("BOTTOM", ActionBarDownButton, "TOP", 0, -12);
    ActionBarUpButton:SetScale(1);
    ActionBarDownButton:SetScale(1);
    LockSetPoint(ActionBarUpButton);
    LockSetPoint(ActionBarDownButton);
    -- FIX: NO llamar SetScript en frames protegidos — taintea los botones
    -- y los deja sin respuesta en combate. Blizzard ya les asigna sus handlers.
    ActionBarUpButton:SetAlpha(1);    ActionBarUpButton:Show();
    ActionBarDownButton:SetAlpha(1);  ActionBarDownButton:Show();
end

local function ApplyAll()
    -- FIX: Never touch protected frames during combat
    if InCombatLockdown() then return; end
    -- FIX: Skip layout during vehicle (Blizzard uses VehicleMenuBar)
    if UnitInVehicle and UnitInVehicle("player") then
        if BagPackFrame then BagPackFrame:Hide(); end
        return;
    end
    ApplyMainBar();
    ApplyXPRepBars();
    ApplyMicroAndBags();
    ApplyShapeshiftBar();
    ApplyPetBar();
    ApplyPagingButtons();
    -- Apply gryphon visibility (Unify hides them via HideAllTextures,
    -- but user may want them shown if HideGryphons is false)
    if K.ApplyGryphons then K.ApplyGryphons(); end
end

-- ──────────────────────────────────────────────────────────────
--  EVENT HANDLER (only active while enabled)
-- ──────────────────────────────────────────────────────────────

local function UAB_OnEvent(self, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        inCombat = false;
        -- FIX: Re-apply everything after combat. Use a short retry sequence
        -- to ensure Blizzard has fully cleared combat lockdown and finished
        -- its own post-combat layout updates before we re-apply ours.
        StartRetry(function()
            if isEnabled and not InCombatLockdown() then
                HideAllTextures();
                ApplyAll();
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end, 4, 0.2);
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true;
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Blizzard restores textures on world enter — fight back with retries
        -- FIX: Reusar retry frame (antes se creaba uno nuevo cada vez)
        StartRetry(function()
            if isEnabled then HideAllTextures(); ApplyAll(); if K.ApplyGryphons then K.ApplyGryphons(); end end
        end, 5, 0.3);
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        -- Cambio de spec: Blizzard resetea el micromenu y layout completo
        -- Re-aplicar agresivamente con múltiples retries
        -- FIX: Reusar retry frame (antes se creaba uno nuevo cada vez)
        StartRetry(function()
            if isEnabled and not InCombatLockdown() then
                HideAllTextures();
                ApplyAll();
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end, 8, 0.4);
    elseif event == "DISPLAY_SIZE_CHANGED" then
        -- Volver de minimizar el juego
        -- FIX: Reusar retry frame (antes se creaba uno nuevo cada vez)
        StartRetry(function()
            if isEnabled and not InCombatLockdown() then
                HideAllTextures();
                ApplyAll();
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end, 5, 0.3);
    elseif event == "UI_SCALE_CHANGED" then
        ApplyMicroAndBags();
    elseif event == "PLAYER_XP_UPDATE" or event == "UPDATE_EXHAUSTION"
        or event == "PLAYER_LEVEL_UP" or event == "UPDATE_FACTION" then
        -- FIX: Re-aplicar TODAS las barras afectadas, no solo shapeshift/pet
        -- Blizzard reposiciona XP/Rep bars en estos eventos, hay que forzarlas de vuelta
        ApplyMainBar(); ApplyXPRepBars(); ApplyShapeshiftBar(); ApplyPetBar();
    elseif event == "UNIT_PET" then
        -- Pet apareció/desapareció (shadowfiend, ghoul, etc)
        if isEnabled and not InCombatLockdown() then
            ApplyPetBar();
        end
    elseif event == "UNIT_ENTERED_VEHICLE" and unit == "player" then
        -- FIX: Hide BagPackFrame and let Blizzard fully control layout during vehicle
        if BagPackFrame then BagPackFrame:Hide(); end
        -- Unlock all overrides so Blizzard can reparent/reposition freely
        UnlockSetPoint(ShapeshiftBarFrame);
        UnlockSetPoint(PetActionBarFrame);
        UnlockSetPoint(ActionBarUpButton);
        UnlockSetPoint(ActionBarDownButton);
        UnlockSetPoint(MainMenuExpBar);
    elseif event == "UNIT_EXITED_VEHICLE" and unit == "player" then
        -- FIX: Restore BagPackFrame and full layout after vehicle exit
        if BagPackFrame then BagPackFrame:Show(); end
        StartRetry(function()
            if isEnabled and not InCombatLockdown() then
                HideAllTextures();
                ApplyAll();
                -- FIX: Explicit micro button re-apply after vehicle
                if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end, 5, 0.3);
    elseif not inCombat then
        -- Catch-all for other events (UPDATE_SHAPESHIFT_FORMS, etc.)
        if not InCombatLockdown() then
            HideAllTextures();
            ApplyAll();
        end
    end
end

-- ──────────────────────────────────────────────────────────────
--  ENABLE
-- ──────────────────────────────────────────────────────────────

function K.EnableUnifyActionBars()
    if isEnabled then return; end

    -- FIX: Never run during combat — all SetScale/SetPoint/ClearAllPoints
    -- on protected frames (MainMenuBar, PossessBarFrame, etc.) cause taint.
    -- Defer to PLAYER_REGEN_ENABLED.
    if InCombatLockdown() then
        enableWaiter:RegisterEvent("PLAYER_REGEN_ENABLED");
        return;
    end

    -- Disable MiniBar if it's active (mutually exclusive)
    if K._minibarActive then
        if K.DisableMiniBar then K.DisableMiniBar(); end
        K.SaveConfig("MiniBarEnabled", false);
    end

    -- FIX: Forzar que Blizzard recalcule TODAS las posiciones ANTES de capturar.
    if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
    if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end

    -- Capture originals FIRST, before touching anything
    CaptureOriginals();

    isEnabled = true;
    K._unifyActive = true;

    -- Hide decorations
    HideAllTextures();

    -- Scaling: use shared ActionBarScale
    local scale = C.ActionBarScale or 1.0;
    MainMenuBar:SetScale(scale);
    MainMenuBar:SetWidth(510);
    MultiBarBottomLeft:SetScale(scale); MultiBarBottomRight:SetScale(scale);
    MultiBarRight:SetScale(scale);      MultiBarLeft:SetScale(scale);

    -- XP bar + Rep bar: usar función dedicada (FIX: antes era inline y no se re-aplicaba)
    ApplyXPRepBars();

    -- PossessBar
    if PossessBarFrame then
        PossessBarFrame:ClearAllPoints();
        PossessBarFrame:SetPoint("BOTTOMLEFT", 250, 132);
        PossessBarFrame:SetScale(1);
    end
    if PossessButton1 then
        PossessButton1:ClearAllPoints();
        PossessButton1:SetPoint("BOTTOMLEFT", 0, 60);
        PossessButton1:SetScale(1);
    end

    -- Multi-bar
    MultiBarBottomRight:SetPoint("LEFT", MultiBarBottomLeft, "RIGHT", 5, 0);
    MultiBarBottomRightButton7:SetPoint("LEFT", MainMenuBar, "LEFT", 513, -5);

    ApplyAll();

    -- Apply gryphons (shared with MiniBar, must be after HideAllTextures)
    if K.ApplyGryphons then K.ApplyGryphons(); end

    -- Create BagPackFrame for Unify mode too
    if K.CreateBagPackFrame then K.CreateBagPackFrame(); end

    -- Register events
    if not uabEventsFrame then uabEventsFrame = CreateFrame("Frame"); end
    uabEventsFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    uabEventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    uabEventsFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
    uabEventsFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
    uabEventsFrame:RegisterEvent("UI_SCALE_CHANGED");
    uabEventsFrame:RegisterEvent("DISPLAY_SIZE_CHANGED");
    uabEventsFrame:RegisterEvent("PLAYER_XP_UPDATE");
    uabEventsFrame:RegisterEvent("UPDATE_EXHAUSTION");
    uabEventsFrame:RegisterEvent("PLAYER_LEVEL_UP");
    uabEventsFrame:RegisterEvent("UPDATE_FACTION");
    uabEventsFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
    uabEventsFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
    uabEventsFrame:RegisterEvent("UNIT_PET");
    uabEventsFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
    uabEventsFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
    uabEventsFrame:SetScript("OnEvent", UAB_OnEvent);

    -- Hook UpdateMicroButtons: Blizzard lo llama durante cambio de spec
    -- y resetea la posición del micromenu
    if UpdateMicroButtons and not K._uabMicroHooked then
        hooksecurefunc("UpdateMicroButtons", function()
            if isEnabled and not InCombatLockdown() then
                -- FIX: Do NOT re-apply during vehicle — Blizzard handles
                -- micro button layout inside VehicleMenuBarArtFrame.
                if UnitInVehicle and UnitInVehicle("player") then return; end
                ApplyMicroAndBags();
            end
        end);
        K._uabMicroHooked = true;
    end

    -- FIX: Hook VehicleMenuBar_MoveMicroButtons: Blizzard llama esto al entrar/salir
    -- de vehículos y reparenta los micro buttons a VehicleMenuBarArtFrame.
    -- Sin este hook, al salir del vehículo los botones quedan en el frame equivocado.
    if VehicleMenuBar_MoveMicroButtons and not K._uabVehicleMicroHooked then
        hooksecurefunc("VehicleMenuBar_MoveMicroButtons", function(skinName)
            if not isEnabled then return; end
            if not skinName then
                -- Saliendo del vehículo: re-aplicar layout
                if not InCombatLockdown() then
                    ApplyMicroAndBags();
                end
            end
        end);
        K._uabVehicleMicroHooked = true;
    end

    -- Hook PetActionBar_Update: Blizzard lo llama cuando aparece/desaparece pet
    -- y resetea la posición de la pet bar
    if PetActionBar_Update and not K._uabPetHooked then
        hooksecurefunc("PetActionBar_Update", function()
            if isEnabled and not InCombatLockdown() then
                ApplyPetBar();
            end
        end);
        K._uabPetHooked = true;
    end

    -- Hook ShapeshiftBar_Update: evita que Blizzard mueva la shapeshift bar
    if ShapeshiftBar_Update and not K._uabShapeshiftHooked then
        hooksecurefunc("ShapeshiftBar_Update", function()
            if isEnabled and not InCombatLockdown() then
                ApplyShapeshiftBar();
            end
        end);
        K._uabShapeshiftHooked = true;
    end

    -- FIX: Hook MainMenuBar_UpdateExperienceBars: Blizzard llama esta función
    -- en XP update, level up, faction change, etc. y reposiciona XP/Rep bars.
    -- Este era el bug que causaba que las barras "se eleven".
    if MainMenuBar_UpdateExperienceBars and not K._uabExpBarHooked then
        hooksecurefunc("MainMenuBar_UpdateExperienceBars", function()
            if isEnabled and not InCombatLockdown() then
                ApplyXPRepBars();
            end
        end);
        K._uabExpBarHooked = true;
    end

    -- FIX: Hook UIParent_ManageFramePositions: Blizzard llama esto al cambiar
    -- de zona, entrar/salir de vehículo, etc. y mueve MainMenuBar y barras de XP
    if UIParent_ManageFramePositions and not K._uabManageHooked then
        hooksecurefunc("UIParent_ManageFramePositions", function()
            if isEnabled and not InCombatLockdown() then
                -- FIX: Skip during vehicle — Blizzard manages all frame positions
                if UnitInVehicle and UnitInVehicle("player") then return; end
                ApplyMainBar();
                ApplyXPRepBars();
            end
        end);
        K._uabManageHooked = true;
    end
end

-- ──────────────────────────────────────────────────────────────
--  DISABLE — restore everything exactly as it was
-- ──────────────────────────────────────────────────────────────

function K.DisableUnifyActionBars()
    if not isEnabled then return; end

    -- FIX: Defer to after combat if called during combat lockdown
    -- (Reuses single waiter frame instead of creating a new one each call)
    if InCombatLockdown() then
        disableWaiter:RegisterEvent("PLAYER_REGEN_ENABLED");
        return;
    end

    isEnabled = false;
    K._unifyActive = false;

    -- Stop events
    if uabEventsFrame then
        uabEventsFrame:UnregisterAllEvents();
        uabEventsFrame:SetScript("OnEvent", nil);
    end

    -- Unlock all overridden SetPoints FIRST
    UnlockSetPoint(ShapeshiftBarFrame);
    UnlockSetPoint(PetActionBarFrame);
    UnlockSetPoint(ActionBarUpButton);
    UnlockSetPoint(ActionBarDownButton);
    -- FIX: Desbloquear XP bar (ahora se bloquea en ApplyXPRepBars)
    UnlockSetPoint(MainMenuExpBar);

    -- Hide BagPackFrame if we created it
    if BagPackFrame then BagPackFrame:Hide(); end

    -- Restore decorative textures/frames to original alpha/visibility
    -- Si HideActionBarTextures está activo, no restaurar — dejar ocultas
    if K.IsModuleEnabled and K.IsModuleEnabled("HideActionBarTextures") then
        if K._habReapply then K._habReapply(); end
    else
        RestoreAllTextures();
    end

    -- Restore every saved frame to its exact original position & scale
    RestoreFrame("MainMenuBar",               MainMenuBar);
    RestoreFrame("MainMenuBarBackpackButton",  MainMenuBarBackpackButton);
    RestoreFrame("CharacterMicroButton",       CharacterMicroButton);
    -- FIX: Reparent micro buttons back to MainMenuBarArtFrame (Blizzard default)
    local uabMicroNames = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
        "AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
        "PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
    };
    for _, name in ipairs(uabMicroNames) do
        local btn = _G[name];
        if btn then
            btn:SetParent(MainMenuBarArtFrame);
            btn:SetFrameStrata("MEDIUM");
            -- FIX: Reset explicit scale to 1.0 — ApplyBagPackLayout set it to
            -- ActionBarScale, but now the button inherits scale from MainMenuBar
            -- via parent chain. Without this reset, scale doubles.
            btn:SetScale(1);
        end
    end
    RestoreFrame("MultiBarBottomLeft",         MultiBarBottomLeft);
    RestoreFrame("MultiBarBottomRight",        MultiBarBottomRight);
    RestoreFrame("MultiBarBottomRightButton7", MultiBarBottomRightButton7);
    RestoreFrame("MultiBarRight",              MultiBarRight);
    RestoreFrame("MultiBarLeft",               MultiBarLeft);
    RestoreFrame("MainMenuExpBar",             MainMenuExpBar);
    RestoreFrame("ExhaustionTick",             ExhaustionTick);
    RestoreFrame("MainMenuBarExpText",         MainMenuBarExpText);
    RestoreFrame("ReputationWatchBar",         ReputationWatchBar);
    RestoreFrame("ReputationWatchStatusBar",   ReputationWatchStatusBar);
    RestoreFrame("ReputationWatchStatusBarText", ReputationWatchStatusBarText);
    if PossessBarFrame   then RestoreFrame("PossessBarFrame",   PossessBarFrame);   end
    if PossessButton1    then RestoreFrame("PossessButton1",    PossessButton1);    end
    if ShapeshiftBarFrame then RestoreFrame("ShapeshiftBarFrame", ShapeshiftBarFrame); end
    if PetActionBarFrame  then RestoreFrame("PetActionBarFrame",  PetActionBarFrame);  end
    if PetActionBarHealthBar then RestoreFrame("PetActionBarHealthBar", PetActionBarHealthBar); end
    if PetActionBarManaBar   then RestoreFrame("PetActionBarManaBar",   PetActionBarManaBar);   end
    if ActionBarUpButton   then RestoreFrame("ActionBarUpButton",   ActionBarUpButton);   end
    if ActionBarDownButton then RestoreFrame("ActionBarDownButton", ActionBarDownButton); end

    -- FIX: Restaurar bag slots (posición + escala originales)
    if CharacterBag0Slot then RestoreFrame("CharacterBag0Slot", CharacterBag0Slot); end
    if CharacterBag1Slot then RestoreFrame("CharacterBag1Slot", CharacterBag1Slot); end
    if CharacterBag2Slot then RestoreFrame("CharacterBag2Slot", CharacterBag2Slot); end
    if CharacterBag3Slot then RestoreFrame("CharacterBag3Slot", CharacterBag3Slot); end
    if KeyRingButton      then RestoreFrame("KeyRingButton",     KeyRingButton);     end

    -- Forzar que Blizzard recalcule posiciones de ShapeshiftBar y PetBar
    -- Esto corrige que la Shadowform quede debajo de la barra al desactivar
    if UIParent_ManageFramePositions then
        pcall(UIParent_ManageFramePositions);
    end
    -- FIX: También forzar recalculo de XP/Rep bars para que queden en posición Blizzard
    if MainMenuBar_UpdateExperienceBars then
        pcall(MainMenuBar_UpdateExperienceBars);
    end
    if ShapeshiftBarFrame and ShapeshiftBar_Update then
        pcall(ShapeshiftBar_Update);
    end
    if PetActionBarFrame and PetActionBar_Update then
        pcall(PetActionBar_Update);
    end

    -- Retry: Blizzard puede re-posicionar después de nuestro restore
    -- FIX: Reusar retry frame (antes se creaba uno nuevo cada vez)
    StartRetry(function()
        if not isEnabled and not InCombatLockdown() then
            if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
            if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end
            if ShapeshiftBar_Update then pcall(ShapeshiftBar_Update); end
            if PetActionBar_Update then pcall(PetActionBar_Update); end
            if UpdateMicroButtons then pcall(UpdateMicroButtons); end
        end
    end, 5, 0.3);

    -- Restore gryphons to Blizzard default positions
    -- FIX: Usar RestoreFrame en vez de coordenadas hardcodeadas
    RestoreFrame("MainMenuBarLeftEndCap",  MainMenuBarLeftEndCap);
    RestoreFrame("MainMenuBarRightEndCap", MainMenuBarRightEndCap);
    if MainMenuBarLeftEndCap then
        MainMenuBarLeftEndCap:SetAlpha(1);
        MainMenuBarLeftEndCap:Show();
    end
    if MainMenuBarRightEndCap then
        MainMenuBarRightEndCap:SetAlpha(1);
        MainMenuBarRightEndCap:Show();
    end

    -- Clear saved data so next Enable() captures fresh originals
    saved = {};
    savedTextures = {};
    origSetPoints = {};

    -- Re-apply action bar scale (scale works independently of bar modes)
    if C.ActionBarScale and C.ActionBarScale ~= 1.0 then
        K.ApplyActionBarScale(C.ActionBarScale);
    end
end



local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
    -- FIX RELOG: No unregistrar PLAYER_ENTERING_WORLD — necesitamos que corra en CADA relog.
    -- Solo ignorar si ya está enabled (para no re-capturar originals contaminados).
    if isEnabled then
        -- Ya habilitado — solo re-aplicar para cubrir resets de Blizzard post-relog
        StartRetry(function()
            if isEnabled and not InCombatLockdown() then
                HideAllTextures(); ApplyAll();
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end, 8, 0.4);
        return;
    end
    -- Primera vez: delay 0.5s para que Blizzard termine de posicionar XP/Rep bars
    local elapsed = 0;
    self:SetScript("OnUpdate", function(s, dt)
        elapsed = elapsed + dt;
        if elapsed >= 0.5 then
            s:SetScript("OnUpdate", nil);
            if C.UnifyActionBars and not C.MiniBarEnabled then
                -- FIX: EnableUnifyActionBars has its own combat guard,
                -- but also check here to avoid unnecessary function call overhead
                K.EnableUnifyActionBars();
            end
        end
    end);
end);