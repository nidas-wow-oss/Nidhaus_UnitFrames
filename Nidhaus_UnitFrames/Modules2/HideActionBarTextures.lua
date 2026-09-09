local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- EL BUG DE LA BARRA VIOLETA.
--
-- Al DESTILDAR "Hide Action Bar Textures" (sin Unify ni MiniBar activos)
-- aparecia una franja violeta sobre las barras y la fila de abajo se
-- corria hacia arriba, aunque el personaje no tuviera ninguna barra de
-- experiencia ni de reputacion a la vista. Con /reload se acomodaba solo.
--
-- LA CAUSA: la lista de "adornos" mezclaba DOS cosas distintas.
--
--   ADORNO      MainMenuBarTexture0..3, los grifos, los bordes de las
--               mochilas. Arte fija: Blizzard la muestra siempre.
--
--   NO ADORNO   MainMenuExpBar (la barra de experiencia, que es violeta)
--               y ReputationWatchBar. Estas NO estan siempre: las prende
--               y las apaga el juego segun el personaje -- nivel maximo,
--               experiencia desactivada, si estas siguiendo una faccion o
--               no -- desde MainMenuBar_UpdateExperienceBars.
--
-- ShowDecorations hacia Show() sobre TODA la lista por igual. En un 80 sin
-- faccion seguida, Blizzard tenia la barra de experiencia apagada con
-- razon y nosotros la prendiamos igual: de ahi la franja violeta. Y como
-- al aparecer ocupa alto, lo de al lado se corria.
--
-- Volvia a la normalidad con /reload porque al arrancar nadie llama a
-- ShowDecorations: el error se cometia SOLO en el toggle en vivo. Por eso
-- parecia intermitente y por eso "funcionaba bien" despues de recargar.
--
-- EL ARREGLO, en dos partes:
--
--   1. Las barras de experiencia y reputacion no se prenden ni se apagan
--      nunca desde aca. Solo se les baja el alfa a 0, que las vuelve
--      invisibles junto con todo lo que les cuelga, sin tocar quien decide
--      si estan. Ese dueño sigue siendo el juego.
--
--   2. Del arte fija se ANOTA como estaba antes de esconderla y se repone
--      TAL CUAL estaba, no "visible" a lo bruto. Y si nosotros no la
--      escondimos, no se toca: no hay nada que restaurar.
-- =========================================================

-- Arte decorativa: se puede prender y apagar sin consecuencias.
local textures = {};
-- Marcos que decide Blizzard: SOLO alfa, nunca Show/Hide.
local dimmers  = {};

local habEnabled = false;

-- Como estaba cada cosa justo antes de que la escondieramos nosotros.
local prevShown = {};
local prevAlpha = {};

local function AddTexture(tex)
    if tex and tex.SetAlpha then
        table.insert(textures, tex);
    end
end

local function AddDimmer(frame)
    if frame and frame.SetAlpha then
        table.insert(dimmers, frame);
    end
end

local function SetupTextures()
    textures = {};
    dimmers  = {};

    for i = 0, 3 do AddTexture(_G["MainMenuBarTexture" .. i]); end

    -- Arte de nivel maximo: es la que REEMPLAZA a la barra de experiencia
    -- al llegar a 80. Faltaba en la lista, asi que con la opcion activada
    -- quedaba igual una franja colgada abajo.
    for i = 0, 3 do AddTexture(_G["MainMenuMaxLevelBar" .. i]); end

    AddTexture(MainMenuXPBarTextureLeftCap);
    AddTexture(MainMenuXPBarTextureRightCap);
    AddTexture(MainMenuXPBarTextureMid);
    for i = 0, 8 do AddTexture(_G["ReputationWatchBarTexture" .. i]); end

    AddTexture(MainMenuBarLeftEndCap);
    AddTexture(MainMenuBarRightEndCap);
    AddTexture(MainMenuBarBackpackButtonBorder);
    AddTexture(KeyRingButtonBorder);
    AddTexture(CharacterBag0SlotBorder);
    AddTexture(CharacterBag1SlotBorder);
    AddTexture(CharacterBag2SlotBorder);
    AddTexture(CharacterBag3SlotBorder);

    -- Estas dos NO van arriba. Mira la nota del encabezado.
    AddDimmer(MainMenuExpBar);
    AddDimmer(ReputationWatchBar);
end

local function HideDecorations()
    for _, tex in ipairs(textures) do
        -- Anotar como estaba, UNA sola vez. Si se anotara en cada pasada,
        -- la rafaga de reintentos guardaria nuestro propio estado ya
        -- escondido y al restaurar no volveria nada nunca mas.
        if prevShown[tex] == nil then
            prevShown[tex] = (tex:IsShown() and true) or false;
            prevAlpha[tex] = tex:GetAlpha();
        end
        tex:Hide();
        tex:SetAlpha(0);
    end

    for _, f in ipairs(dimmers) do
        if prevAlpha[f] == nil then
            prevAlpha[f] = f:GetAlpha();
        end
        f:SetAlpha(0);
    end
end

local function ShowDecorations()
    for _, tex in ipairs(textures) do
        -- Si no la escondimos nosotros no la tocamos. Prenderla a ciegas
        -- es exactamente lo que hacia aparecer arte que no correspondia.
        if prevShown[tex] ~= nil then
            tex:SetAlpha(prevAlpha[tex] or 1);
            if prevShown[tex] then tex:Show(); else tex:Hide(); end
            prevShown[tex] = nil;
            prevAlpha[tex] = nil;
        end
    end

    for _, f in ipairs(dimmers) do
        if prevAlpha[f] ~= nil then
            f:SetAlpha(prevAlpha[f]);
            prevAlpha[f] = nil;
        end
    end
end

-- Con Unify o MiniBar activos, esos modos manejan las texturas ellos mismos.
-- FIX: antes solo se miraba _unifyActive; MiniBar quedaba afuera y los dos
-- terminaban peleando por las mismas texturas (de ahi que solo se acomodara
-- con /reload).
local function AnyBarModeActive()
    return (K._unifyActive == true) or (K._minibarActive == true);
end

local function ApplyState()
    if #textures == 0 then SetupTextures(); end
    if AnyBarModeActive() then return; end
    if habEnabled then
        HideDecorations();
    else
        ShowDecorations();
    end
end

-- Exponer función para que ActionBars pueda pedirle re-aplicar
-- La llaman ActionBars y MiniBar despues de cambiar de modo, para que las
-- texturas queden como corresponde sin necesidad de /reload.
K._habReapply = function()
    -- Reconstruir la lista: al cambiar de modo algunas texturas se recrean
    SetupTextures();
    if AnyBarModeActive() then return; end
    if habEnabled then
        HideDecorations();
    else
        ShowDecorations();
    end
end

-- FIX RELOG: Más intentos y más frecuentes para cubrir relogs en arena
local retryFrame = CreateFrame("Frame");
local retryAttempts = 0;
local retryElapsed = 0;

retryFrame:Hide();
retryFrame:SetScript("OnUpdate", function(self, dt)
    retryElapsed = retryElapsed + dt;
    if retryElapsed >= 0.4 then
        if habEnabled and not AnyBarModeActive() then
            if #textures == 0 then SetupTextures(); end
            HideDecorations();
        end
        retryAttempts = retryAttempts + 1;
        retryElapsed = 0;
        if retryAttempts >= 8 then self:Hide(); end
    end
end);

-- Blizzard restores textures after login, retry to override
local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("PLAYER_LOGIN");
eventFrame:SetScript("OnEvent", function()
    if not habEnabled then return; end
    if AnyBarModeActive() then return; end
    retryAttempts = 0;
    retryElapsed = 0;
    retryFrame:Show();
end);

-- FIX: el slash ahora pasa por SetModuleEnabled para que quede guardado en la DB
-- y el checkbox del panel no se desincronice.
SLASH_HIDEACTIONBAR1 = "/hidebar";
SlashCmdList["HIDEACTIONBAR"] = function()
    local newState = not habEnabled;
    if K.SetModuleEnabled then
        K.SetModuleEnabled("HideActionBarTextures", newState);
    else
        habEnabled = newState;
        ApplyState();
    end
    if newState then
        print("|cff4FC3F7NUF:|r HideBar: textures hidden.");
    else
        print("|cff4FC3F7NUF:|r HideBar: textures visible.");
    end
    -- Refrescar el checkbox del panel si esta creado
    if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("HideActionBarTextures"); end
end

K.RegisterModule("HideActionBarTextures", {
    name = "Hide Action Bar Textures",
    desc = "Hides action bar decorative textures.",
    default = false,
    -- El checkbox vive en General > Barras, no repetirlo en la pestaña Modules
    hideFromModulesTab = true,
    onEnable = function()
        habEnabled = true;
        -- FIX: una sola pasada no alcanzaba (Blizzard vuelve a mostrar las
        -- texturas justo despues), por eso solo funcionaba tras /reload.
        -- Se rearma la rafaga de reintentos igual que al entrar al mundo.
        SetupTextures();
        ApplyState();
        retryAttempts = 0;
        retryElapsed = 0;
        retryFrame:Show();
    end,
    onDisable = function()
        habEnabled = false;
        retryFrame:Hide();
        ApplyState();
    end,
});