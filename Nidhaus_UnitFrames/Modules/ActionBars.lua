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

-- FOTO DE LOS BOTONES, ANTES DE QUE NINGUN MODO LOS TOQUE.
--
-- Se declara aca arriba, con el resto de los stores, porque la captura
-- tiene que ocurrir en CaptureOriginals — o sea ANTES de aplicar el
-- modo. Si se capturara al momento de reanclar cada boton, y para
-- entonces el modo unificado ya lo hubiera movido, estariamos guardando
-- como "original" la posicion del modo. Al apagarlo, las barras
-- volverian... a la posicion del modo. Que es exactamente lo que
-- pasaba: la barra doblada no se desdoblaba, y la de auras quedaba a
-- otra altura que la de Blizzard.
local btnOrig = {};

local function CaptureButton(btn, name)
    if not btn or btnOrig[name] then return; end
    local pts = {};
    for i = 1, (btn:GetNumPoints() or 0) do pts[i] = { btn:GetPoint(i) }; end
    btnOrig[name] = { points = pts, parent = btn:GetParent() };
end

local function RestoreButton(btn, name)
    local o = btnOrig[name];
    if not btn or not o then return; end
    if o.parent then pcall(btn.SetParent, btn, o.parent); end
    if #o.points > 0 then
        btn:ClearAllPoints();
        for _, pt in ipairs(o.points) do pcall(btn.SetPoint, btn, unpack(pt)); end
    end
end

-- Todos los botones que algun modo puede llegar a reanclar.
local BUTTON_SETS = {
    { prefix = "ActionButton",              count = 12 },
    { prefix = "MultiBarBottomLeftButton",  count = 12 },
    { prefix = "MultiBarBottomRightButton", count = 12 },
    { prefix = "MultiBarRightButton",       count = 12 },
    { prefix = "MultiBarLeftButton",        count = 12 },
    { prefix = "ShapeshiftButton",          count = 10 },
};

local function CaptureAllButtons()
    for _, set in ipairs(BUTTON_SETS) do
        for i = 1, set.count do
            CaptureButton(_G[set.prefix .. i], set.prefix .. i);
        end
    end
end

-- Expuesta para MiniBar, que tambien mueve botones y necesita la foto
-- tomada antes de empezar.
function K.CaptureAllActionButtons()
    CaptureAllButtons();
end

function K.RestoreAllButtons()
    if InCombatLockdown() then return; end
    for _, set in ipairs(BUTTON_SETS) do
        for i = 1, set.count do
            RestoreButton(_G[set.prefix .. i], set.prefix .. i);
        end
    end
end

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
    -- Los BOTONES primero: el espaciado y el Holder de posturas los
    -- reanclan uno por uno y hace falta saber de donde salieron.
    CaptureAllButtons();

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

    -- SI EL USUARIO YA LA MOVIO CON "MOVER TODO", NO SE TOCA.
    --
    -- Este modulo la anclaba a MainMenuBar y ademas le ponia un candado
    -- sobre SetPoint. Resultado: arrastrarla en el modo mover no hacia
    -- absolutamente nada, porque el candado la devolvia al instante.
    -- Dos sistemas moviendo el mismo frame; gana el que tiene posicion
    -- guardada, que es el que eligio el usuario.
    -- EL FRAME DE BLIZZARD YA NO SE MUEVE NI SE TRABA.
    --
    -- En modo unificado los botones cuelgan del Holder (ver
    -- AttachStanceButtons), asi que reposicionar ShapeshiftBarFrame no
    -- cambia nada de lo que se ve, y el candado sobre SetPoint solo
    -- servia para impedir que el usuario la moviera.
    --
    -- Se lo deja suelto y en paz: la posicion la decide el Holder, que
    -- tiene UNA sola posicion por defecto — la misma que repone el
    -- boton Reset del modo mover.
    UnlockSetPoint(ShapeshiftBarFrame);
    if K.AttachStanceButtons then K.AttachStanceButtons(); end
    do return; end

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

-- Altura de MainMenuBar en modo Unify.
--
-- ACA ESTABA LO DE "queda muy alto al pasar de MiniBar a Unify": si no
-- estabas a nivel maximo, Unify subia la barra 11px para hacerle lugar a la
-- barra de XP. MiniBar nunca hizo eso — la deja siempre en 0 — asi que al
-- togglear entre los dos modos toda la barra (y con ella los grifos, que
-- cuelgan de MainMenuBar) pegaba un salto para arriba.
--
-- Ahora los dos modos quedan a la misma altura. Si con la barra de XP
-- visible algo se corta abajo, subir este numero.
local UNIFY_BAR_Y_BELOW_MAXLEVEL = 0;   -- antes 11
local UNIFY_BAR_Y_MAXLEVEL       = 0;
local UNIFY_BAR_X                = -128;

local function ApplyMainBar()
    if DeferIfCombat(ApplyMainBar) then return; end
    local y = (UnitLevel("player") < MAX_PLAYER_LEVEL)
        and UNIFY_BAR_Y_BELOW_MAXLEVEL or UNIFY_BAR_Y_MAXLEVEL;
    MainMenuBar:ClearAllPoints();
    MainMenuBar:SetPoint("BOTTOM", UIParent, UNIFY_BAR_X, y);
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
    --
    -- Los tres ajustes de abajo son los unicos que hay que tocar si algun dia
    -- quieres reubicarla. Ojo con XP_WIDEN: estira los anclajes, o sea que
    -- cambia el TAMANO del frame, no solo lo que se ve. Se deja moderado a
    -- proposito; pasarse de ahi puede descuadrar el reparto de las otras
    -- barras, porque Blizzard las coloca en funcion de este marco.
    -- Los tres valores de abajo van en PIXELES DE PANTALLA, medidos desde los
    -- bordes de MainMenuBar. La conversion la hace el codigo.
    --
    -- Por que hay que convertir: los offsets de SetPoint se expresan en el
    -- espacio del PROPIO frame, y ese espacio va escalado. Y no por 0.735,
    -- que es lo que le pasamos a SetScale, sino por su escala EFECTIVA: la
    -- suya multiplicada por la del padre (0.735 x 0.730 = 0.537). Usar 0.735
    -- dejaba todo un 27% corto, que es lo que pasaba antes.
    --
    -- Se lee con GetEffectiveScale en vez de escribir 0.537 a mano, para que
    -- siga cuadrando si cambia la escala de la barra de accion o de la UI.
    --
    -- Valores medidos sobre la geometria real de esta interfaz:
    --   MainMenuBar          izq  403   der  775
    --   MultiBarBottomLeft   izq  409
    --   MultiBarBottomRight              der 1143
    -- De ahi salen los 6 y 368: dejan la barra de experiencia justo de punta
    -- a punta de la fila de botones.
    local XP_SCALE      = 0.735;
    local XP_EDGE_LEFT  = 6;     -- alineada con el borde de MultiBarBottomLeft
    -- Medido: MainMenuBar acaba en 775 y las flechas empiezan en
    -- 959. 775 + 184 = 959 clavado, que es donde tiene que cortarse.
    local XP_EDGE_RIGHT = 184;   -- tope; el limite real lo ponen las flechas
    local XP_HEIGHT     = 31;    -- altura sobre MainMenuBar (la que estaba bien)
    -- A cero a proposito: asi la cuenta por constante y la cuenta por flechas
    -- dan EL MISMO borde. Con un hueco distinto, segun si al aplicar la
    -- posicion de las flechas ya estaba resuelta o no, la barra salia en un
    -- sitio u otro. Ahora da igual cual de los dos caminos gane.
    local XP_GAP_FLECHAS = 0;

    MainMenuExpBar:SetScale(XP_SCALE);
    if ExhaustionTick then ExhaustionTick:SetScale(XP_SCALE); end

    local es = MainMenuExpBar:GetEffectiveScale();
    if not es or es <= 0 then es = XP_SCALE; end

    -- Borde derecho: en vez de un numero fijo, se ata a las flechas de cambio
    -- de pagina. Si no, cada vez que cambia la escala de la UI o el numero de
    -- botones hay que volver a tantear a ojo, y la barra acaba pasandose de
    -- largo por detras de las flechas.
    --
    -- La constante de arriba queda como tope maximo: manda la que resulte
    -- MENOR de las dos, asi la barra nunca pisa las flechas ni se alarga sola.
    local edgeRight = XP_EDGE_RIGHT;
    local esBar     = MainMenuBar:GetEffectiveScale();
    local barRight  = MainMenuBar:GetRight();
    if ActionBarUpButton and barRight and esBar and esBar > 0 then
        local esUp   = ActionBarUpButton:GetEffectiveScale();
        local upLeft = ActionBarUpButton:GetLeft();
        if upLeft and esUp and esUp > 0 then
            -- Todo a pixeles de pantalla para poder compararlo.
            local limite = (upLeft * esUp) - XP_GAP_FLECHAS - (barRight * esBar);
            if limite < edgeRight then edgeRight = limite; end
        end
    end
    -- Suelo de seguridad: si algo devolviera basura, que no quede invisible.
    if edgeRight < 40 then edgeRight = 40; end

    MainMenuExpBar:ClearAllPoints();
    MainMenuExpBar:SetPoint("BOTTOMLEFT",  MainMenuBar, "BOTTOMLEFT",
        XP_EDGE_LEFT  / es, XP_HEIGHT / es);
    MainMenuExpBar:SetPoint("BOTTOMRIGHT", MainMenuBar, "BOTTOMRIGHT",
        edgeRight / es, XP_HEIGHT / es);
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
    -- Las flechas van ANTES que la barra de experiencia: esta lee su posicion
    -- para saber donde cortarse, asi que tienen que estar ya colocadas.
    ApplyPagingButtons();
    ApplyXPRepBars();
    ApplyMicroAndBags();
    ApplyShapeshiftBar();
    ApplyPetBar();
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
        if K.ApplyGryphons then K.ApplyGryphons(); end
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
--  CAJA QUE ABARCA TODAS LAS BARRAS
--
--  El recuadro de "Mover todo" apuntaba a MainMenuBar, que mide 510 de
--  ancho: con el modo unificado puesto, las barras se extienden bastante
--  mas a los costados y el cuadro tapaba solo el centro.
--
--  Este frame invisible calcula la union de todo lo que esta a la vista
--  y GlobalUnlock dibuja el recuadro encima (overlayOn). No se mueve ni
--  se ancla a nada: es puramente una caja de medida.
-- ──────────────────────────────────────────────────────────────
local barsBox;

function K.UpdateActionBarsBox()
    if not barsBox then
        barsBox = CreateFrame("Frame", "NUF_ActionBarsBox", UIParent);
        barsBox:SetFrameStrata("BACKGROUND");
        barsBox:EnableMouse(false);
    end

    -- Se mide sobre los BOTONES, no sobre los frames de las barras.
    --
    -- MainMenuBar mide 510 fijos y MultiBarBottomRight es mas ancho que
    -- los botones que tiene adentro, asi que midiendo los contenedores el
    -- recuadro sobraba bastante por la derecha. Los botones dan el ancho
    -- real de lo que se ve.
    local parts = {};
    for i = 1, 12 do
        parts[#parts + 1] = _G["ActionButton" .. i];
        parts[#parts + 1] = _G["MultiBarBottomLeftButton" .. i];
        parts[#parts + 1] = _G["MultiBarBottomRightButton" .. i];
    end

    local l, r, t, b;
    for _, f in ipairs(parts) do
        if f and f:IsVisible() and f:GetLeft() then
            l = math.min(l or f:GetLeft(),   f:GetLeft());
            r = math.max(r or f:GetRight(),  f:GetRight());
            b = math.min(b or f:GetBottom(), f:GetBottom());
            t = math.max(t or f:GetTop(),    f:GetTop());
        end
    end
    if not l then return barsBox; end

    barsBox:ClearAllPoints();
    barsBox:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b);
    barsBox:SetSize(math.max(r - l, 10), math.max(t - b, 10));
    return barsBox;
end

-- ──────────────────────────────────────────────────────────────
--  CAJA DE LA BARRA DE POSTURAS / AURAS / FORMAS
--
--  ShapeshiftBarFrame es MAS ANCHO que sus botones: tiene lugar para
--  diez y casi ninguna clase los usa todos. Un paladin tiene cuatro
--  auras, asi que el recuadro del modo mover, que se dibujaba sobre el
--  frame entero, quedaba corrido a la izquierda con la mitad vacia.
--
--  Esta caja mide solo los botones que se ven, igual que la de las
--  barras de accion.
-- ──────────────────────────────────────────────────────────────
-- Cuanto esta corrido ShapeshiftButton1 DENTRO de ShapeshiftBarFrame.
--
-- Importa porque el Holder reemplaza a ese frame: si lo anclaramos en el
-- mismo punto y despues pegaramos el boton en su esquina, la barra
-- quedaria desplazada respecto de donde la deja el modo unificado, justo
-- por ese margen interno. Sale de la foto que se toma antes de tocar
-- nada, asi que es el valor real, no uno estimado.
-- Separacion ORIGINAL entre dos botones de posturas.
--
-- El arte del marco de Blizzard trae las casillas dibujadas a una
-- distancia fija. Si encadenamos los botones con el valor del slider
-- (que es para las barras de accion), cada uno se corre un poco mas que
-- el anterior: el primero coincide con su casilla y el ultimo termina
-- afuera. Es exactamente el desfase acumulado que se ve en pantalla.
--
-- Este valor sale de la foto de fabrica: la distancia real entre el
-- boton 2 y el 1 antes de que nadie los tocara.
local function StanceButtonPitch()
    local o2 = btnOrig["ShapeshiftButton2"];
    if o2 and o2.points and o2.points[1] then
        local x = o2.points[1][4];
        if type(x) == "number" then return x; end
    end
    return 6;   -- respaldo, por si la foto no llego a tomarse
end

local function StanceButtonInset()
    local o = btnOrig["ShapeshiftButton1"];
    if not o or not o.points or not o.points[1] then return 0, 0; end
    local pt = o.points[1];
    -- { point, relativeTo, relativePoint, x, y }
    return (pt[4] or 0), (pt[5] or 0);
end

-- ──────────────────────────────────────────────────────────────
--  HOLDER DE LA BARRA DE POSTURAS / AURAS / FORMAS
--
--  Por que un contenedor propio y no mover ShapeshiftBarFrame:
--
--  Ese frame es de Blizzard, esta protegido, lo reposiciona
--  UIParent_ManageFramePositions y ademas este mismo modulo le ponia un
--  candado sobre SetPoint en el modo unificado. Arrastrarlo era pelear
--  contra tres sistemas a la vez.
--
--  La solucion es la de el UI de origen (el patron del Holder):
--  se crea un Holder, se le cuelgan los BOTONES, y se mueve el Holder.
--  Los botones son hijos nuestros, asi que nadie mas los reancla.
--
--  SetParent sobre botones protegidos solo se puede fuera de combate,
--  de ahi la comprobacion.
-- ──────────────────────────────────────────────────────────────
local stanceHolder;

-- La posicion POR DEFECTO sale de la MISMA cuenta que usa el modo
-- unificado para la barra de Blizzard (ApplyShapeshiftBar, mas arriba):
--
--     BOTTOMLEFT de MainMenuBar TOPLEFT, 30, 40 + GetBarOffset()
--
-- El GetBarOffset() no es decorativo: suma 6 por la barra de experiencia
-- y otros 6 por la de reputacion cuando estan a la vista. Yo lo habia
-- omitido al escribir el Holder, y por eso el Reset dejaba la barra unos
-- pixeles corrida respecto de donde la pone el modo unificado.
-- POSICION POR DEFECTO CON EL MODO UNIFICADO PUESTO.
--
-- Es LA MISMA cuenta que usa ApplyShapeshiftBar para la barra de
-- Blizzard, mas el margen interno del primer boton. Con esto, la barra
-- de estados queda exactamente donde el modo unificado la pone, y el
-- boton Reset del modo mover la devuelve a ese mismo lugar: una sola
-- posicion por defecto, no dos parecidas.
local function StanceDefaultPoint(holder)
    local ix, iy = StanceButtonInset();
    holder:ClearAllPoints();
    holder:SetPoint("BOTTOMLEFT", MainMenuBar or UIParent, "TOPLEFT",
        30 + ix, 40 + GetBarOffset() + iy);
end

function K.EnsureStanceHolder()
    if stanceHolder then return stanceHolder; end
    stanceHolder = CreateFrame("Frame", "NUF_StanceBarHolder", UIParent);
    stanceHolder:SetSize(40, 30);
    -- Por encima del marco de Blizzard: si no, el arte de las casillas se
    -- dibuja sobre los iconos y quedan opacados.
    stanceHolder:SetFrameStrata("MEDIUM");
    if ShapeshiftBarFrame then
        stanceHolder:SetFrameLevel((ShapeshiftBarFrame:GetFrameLevel() or 0) + 5);
    end
    StanceDefaultPoint(stanceHolder);
    return stanceHolder;
end

-- Crear el Holder AL CARGAR, no cuando alguien lo pide por primera vez.
-- CaptureOriginals de GlobalUnlock fotografia los frames al abrir el modo
-- mover; si el Holder no existia todavia, se quedaba sin "original" y el
-- Reset no tenia a donde devolverlo.
local holderInit = CreateFrame("Frame");
holderInit:RegisterEvent("PLAYER_LOGIN");
holderInit:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN");
    -- La foto va primero, siempre: si el Holder engancha los botones
    -- antes de capturarlos, se pierde la referencia de Blizzard.
    CaptureAllButtons();
    K.EnsureStanceHolder();
    -- AttachStanceButtons se autolimita al modo unificado; en los otros
    -- modos no hace nada y deja la barra como la dejo cada uno.
    K.AttachStanceButtons();
end);

function K.AttachStanceButtons()
    if InCombatLockdown() then return; end

    -- SOLO EN MODO UNIFICADO.
    --
    -- MiniBar apila la barra de posturas con su propia logica: ancla
    -- ShapeshiftButton1 a la fila de arriba en MiniBar_UpdateActionBars.
    -- Si ademas la colgaramos del Holder, los dos estarian anclando el
    -- mismo boton y ganaria el ultimo que corre — justo el tipo de
    -- pelea que rompio el cambio de modo.
    if C.UnifyActionBars ~= true then
        if K.DetachStanceButtons then K.DetachStanceButtons(); end
        return;
    end
    local holder = K.EnsureStanceHolder();

    -- Sin posicion guardada por el usuario, la barra va SIEMPRE al lugar
    -- por defecto del modo unificado. Con posicion guardada, manda la
    -- del usuario y aca no se toca.
    if not (K.HasGlobalPos and K.HasGlobalPos("StanceBar")) then
        StanceDefaultPoint(holder);
    end

    -- OJO: aca NO se usa el slider de separacion. Estos botones tienen
    -- que caer sobre las casillas del arte de Blizzard, que estan a una
    -- distancia fija. El slider vale para las barras de accion, que no
    -- tienen ese arte detras.
    local space = StanceButtonPitch();
    local shown, w, h = 0, 0, 0;

    for i = 1, 10 do
        local btn = _G["ShapeshiftButton" .. i];
        if btn then
            -- Foto ANTES de reparentar: el padre original es lo que hay
            -- que devolver al salir del modo.
            CaptureButton(btn, "ShapeshiftButton" .. i);
            btn:SetParent(holder);
            btn:ClearAllPoints();
            if i == 1 then
                btn:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0);
            else
                btn:SetPoint("LEFT", _G["ShapeshiftButton" .. (i - 1)], "RIGHT", space, 0);
            end
            if btn:IsShown() then
                shown = shown + 1;
                w = (btn:GetWidth() or 30);
                h = (btn:GetHeight() or 30);
            end
        end
    end

    -- El holder mide exactamente lo que ocupan los botones a la vista, asi
    -- el recuadro del modo mover calza sin calculos aparte.
    if shown > 0 then
        holder:SetSize((w * shown) + (space * (shown - 1)), h);
    end

    -- EL MARCO DE BLIZZARD SIGUE AL HOLDER.
    --
    -- Ese marco trae el arte de las casillas, que aparece cuando no
    -- tenes la barra inferior izquierda puesta. Si el Holder se mueve y
    -- el marco se queda, el arte queda como una fila fantasma abajo, sin
    -- botones adentro.
    --
    -- Se lo ancla al Holder corriendolo por el margen interno que tiene
    -- el primer boton dentro suyo: asi las casillas caen JUSTO detras de
    -- los botones, que es como se ve en la interfaz de Blizzard.
    if ShapeshiftBarFrame then
        local ix, iy = StanceButtonInset();
        UnlockSetPoint(ShapeshiftBarFrame);
        ShapeshiftBarFrame:ClearAllPoints();
        ShapeshiftBarFrame:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", -ix, -iy);
        -- Y el Holder por encima, cada vez: al reanclarse, el marco puede
        -- quedar en un nivel de dibujo distinto y tapar los iconos.
        holder:SetFrameLevel((ShapeshiftBarFrame:GetFrameLevel() or 0) + 5);
    end
end

local stanceBox;

-- Vuelve el Holder a su lugar de fabrica. Lo llama el Reset del modo
-- mover: como el Holder es un frame NUESTRO creado al vuelo, el sistema
-- de "originales" de GlobalUnlock puede no haberlo fotografiado todavia,
-- y sin esto quedaba donde lo hubieras dejado.
-- Devuelve los botones de posturas a ShapeshiftBarFrame. Sin esto,
-- cambiar de modo dejaba las auras colgadas del Holder, flotando.
function K.DetachStanceButtons()
    if InCombatLockdown() then return; end
    for i = 1, 10 do
        RestoreButton(_G["ShapeshiftButton" .. i], "ShapeshiftButton" .. i);
    end
end

function K.ResetStanceHolder()
    local holder = K.EnsureStanceHolder();
    if not holder then return; end
    if InCombatLockdown() then return; end
    StanceDefaultPoint(holder);
    holder:SetScale(1);
    K.AttachStanceButtons();
end

function K.UpdateStanceBarBox()
    if not stanceBox then
        stanceBox = CreateFrame("Frame", "NUF_StanceBarBox", UIParent);
        stanceBox:SetFrameStrata("BACKGROUND");
        stanceBox:EnableMouse(false);
    end

    local l, r, t, b;
    for i = 1, 10 do
        local btn = _G["ShapeshiftButton" .. i];
        if btn and btn:IsVisible() and btn:GetLeft() then
            l = math.min(l or btn:GetLeft(),   btn:GetLeft());
            r = math.max(r or btn:GetRight(),  btn:GetRight());
            b = math.min(b or btn:GetBottom(), btn:GetBottom());
            t = math.max(t or btn:GetTop(),    btn:GetTop());
        end
    end
    if not l then return stanceBox; end

    stanceBox:ClearAllPoints();
    stanceBox:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b);
    stanceBox:SetSize(math.max(r - l, 10), math.max(t - b, 10));
    return stanceBox;
end

-- ──────────────────────────────────────────────────────────────
--  SEPARACION ENTRE BOTONES  ("Buttons space")
--
--  Portado de la idea de el UI de origen (C.ActionBar.ButtonSpace): alla cada
--  boton se ancla al anterior con esa distancia. Aca hay que hacerlo
--  sobre las barras de Blizzard, que vienen con los botones pegados a
--  mano en su XML, asi que se los vuelve a anclar uno por uno.
--
--  Las barras verticales (MultiBarRight / MultiBarLeft) crecen hacia
--  ABAJO, de ahi que usen TOP/BOTTOM en vez de LEFT/RIGHT.
--
--  OJO CON EL COMBATE: los botones de accion son frames protegidos.
--  Reubicarlos en combate lo bloquea el juego, asi que si estamos
--  peleando se sale y se vuelve a intentar al terminar.
-- ──────────────────────────────────────────────────────────────
local SPACED_BARS = {
    { prefix = "ActionButton",              count = 12, vertical = false },
    { prefix = "MultiBarBottomLeftButton",  count = 12, vertical = false },
    { prefix = "MultiBarBottomRightButton", count = 12, vertical = false },
    { prefix = "MultiBarRightButton",       count = 12, vertical = true  },
    { prefix = "MultiBarLeftButton",        count = 12, vertical = true  },
};

local spaceWaiter;

function K.ApplyActionBarButtonSpace()
    -- Solo con alguno de los dos modos de barras puesto: sin eso las
    -- barras son las de Blizzard y no nos toca reacomodarlas.
    if not (C.UnifyActionBars == true or C.MiniBarEnabled == true) then return; end

    if InCombatLockdown() then
        if not spaceWaiter then
            spaceWaiter = CreateFrame("Frame");
            spaceWaiter:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED");
                K.ApplyActionBarButtonSpace();
            end);
        end
        spaceWaiter:RegisterEvent("PLAYER_REGEN_ENABLED");
        return;
    end

    local space = tonumber(C.ActionBarButtonSpace);
    if not space then space = 6; end

    for _, bar in ipairs(SPACED_BARS) do
        for i = 2, bar.count do
            local btn  = _G[bar.prefix .. i];
            local prev = _G[bar.prefix .. (i - 1)];
            if btn and prev then
                CaptureButton(btn, bar.prefix .. i);
                btn:ClearAllPoints();
                if bar.vertical then
                    btn:SetPoint("TOP", prev, "BOTTOM", 0, -space);
                else
                    btn:SetPoint("LEFT", prev, "RIGHT", space, 0);
                end
            end
        end
    end

    -- En MiniBar el espaciado tambien manda sobre la separacion ENTRE
    -- FILAS, asi que hay que re-armar el apilado.
    if C.MiniBarEnabled == true and K.RefreshMiniBarLayout then
        pcall(K.RefreshMiniBarLayout);
    end

    -- MultiBarBottomRightButton7 tiene ancla propia en el modo unificado
    -- (arranca la segunda fila), asi que se la vuelve a poner despues del
    -- bucle o queda pegada al boton 6.
    if C.UnifyActionBars == true and MultiBarBottomRightButton7 and MainMenuBar then
        MultiBarBottomRightButton7:ClearAllPoints();
        MultiBarBottomRightButton7:SetPoint("LEFT", MainMenuBar, "LEFT", 513, -5);
    end
end

-- Devuelve todos los botones a su anclaje de fabrica. La llaman los dos
-- modos de barra al apagarse, y el camino que deja las barras como las
-- tiene Blizzard.
function K.RestoreActionBarButtonSpace()
    K.RestoreAllButtons();
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

    -- Foto compartida del estado limpio (ver Core/BarBaseline.lua). La
    -- primera vez la saca; despues devuelve la que ya hay.
    if K.EnsureBarBaseline then K.EnsureBarBaseline(); end
    -- Se parte SIEMPRE del mismo punto: sin esto, la captura de abajo se
    -- quedaba con los restos que MiniBar no habia terminado de revertir.
    if K.RestoreBarBaseline then K.RestoreBarBaseline(); end

    -- FIX: Forzar que Blizzard recalcule TODAS las posiciones ANTES de capturar.
    if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
    if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end

    -- Capture originals FIRST, before touching anything
    CaptureOriginals();

    isEnabled = true;
    K._unifyActive = true;
    if K._habReapply then K._habReapply(); end

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

    -- Separacion entre botones (slider "Buttons space" del panel).
    if K.ApplyActionBarButtonSpace then K.ApplyActionBarButtonSpace(); end

    -- Los botones de posturas pasan a colgar de nuestro Holder.
    if K.AttachStanceButtons then K.AttachStanceButtons(); end

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
                if UnitInVehicle and UnitInVehicle("player") then return; end
                -- FIX (desalineo): cuando aparece o desaparece la barra de XP o
                -- de reputacion, MainMenuBar cambia de alto y GetBarOffset()
                -- cambia. Antes solo se reposicionaban las barras de XP/rep,
                -- pero la pet bar, la de formas y los grifos cuelgan del TOP de
                -- MainMenuBar y NO se movian: quedaban a distinta altura. Hay
                -- que re-aplicar TODO lo que depende de ese offset, en el mismo
                -- frame, para que suban o bajen juntos.
                ApplyXPRepBars();
                ApplyShapeshiftBar();
                ApplyPetBar();
                if K.ApplyGryphons then K.ApplyGryphons(); end
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
                -- Mismo motivo que arriba: re-aplicar todo el bloque dependiente
                -- del alto de MainMenuBar, no solo las barras de XP/rep.
                ApplyMainBar();
                ApplyXPRepBars();
                ApplyShapeshiftBar();
                ApplyPetBar();
                if K.ApplyGryphons then K.ApplyGryphons(); end
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

    -- LO PRIMERO: devolver los BOTONES a su anclaje y su padre.
    --
    -- Va antes de restaurar los frames de las barras porque los botones
    -- cuelgan de ellos: si se restaura al reves, quedan anclados a un
    -- frame que todavia esta en la posicion del modo.
    if K.RestoreActionBarButtonSpace then K.RestoreActionBarButtonSpace(); end
    if K.DetachStanceButtons then K.DetachStanceButtons(); end

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