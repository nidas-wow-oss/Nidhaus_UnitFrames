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

local yaAgregada = {};

local function AddTexture(tex)
    if tex and tex.SetAlpha and not yaAgregada[tex] then
        yaAgregada[tex] = true;
        table.insert(textures, tex);
    end
end

-- BARRIDO POR MARCO, ADEMAS DE LA LISTA POR NOMBRE.
--
-- La lista de arriba nombra las texturas una por una, y por eso se le
-- escapaba lo que no estuviera nombrado -- que es la franja que quedaba
-- dibujada abajo aunque estuviera todo "oculto". Esto recorre el marco y
-- se lleva TODA textura que tenga, se llame como se llame.
--
-- SOLO REGIONES, NUNCA EL MARCO. MainMenuBarArtFrame es el padre de los
-- botones de accion y cuelga de MainMenuBar, que es protegido: esconder
-- el marco entero te tira "Interface action failed because of an AddOn"
-- en cuanto entres en combate. Las texturas de adentro no son protegidas
-- y se pueden tocar sin problema.
--
-- Y BAJA A LOS MARCOS HIJOS, PERO NO A LOS BOTONES.
--
-- La primera version solo miraba las regiones del propio marco, y por eso
-- se le seguia escapando la franja: el arte de nivel maximo no cuelga
-- directo de MainMenuBarArtFrame, vive en un marco propio adentro
-- (MainMenuBarMaxLevelBar). Ahora baja.
--
-- Los BOTONES se saltean a proposito: sus regiones son el icono, el borde
-- y el brillo. Barrerlos dejaria la barra de acciones en blanco. Con este
-- filtro pasan los marcos de adorno y no pasa nada con lo que se usa.
local function AddFrameTextures(frame, prof)
    if not frame or not frame.GetRegions then return; end
    prof = prof or 0;

    for _, reg in ipairs({ frame:GetRegions() }) do
        if reg and reg.GetObjectType and reg:GetObjectType() == "Texture" then
            AddTexture(reg);
        end
    end

    if prof >= 2 or not frame.GetChildren then return; end
    for _, hijo in ipairs({ frame:GetChildren() }) do
        if hijo and hijo.GetObjectType and hijo:GetObjectType() == "Frame" then
            AddFrameTextures(hijo, prof + 1);
        end
    end
end

local function AddDimmer(frame)
    if frame and frame.SetAlpha then
        table.insert(dimmers, frame);
    end
end

local function SetupTextures()
    textures    = {};
    dimmers     = {};
    yaAgregada  = {};

    for i = 0, 3 do AddTexture(_G["MainMenuBarTexture" .. i]); end

    -- Arte de nivel maximo: la que REEMPLAZA a la barra de experiencia al
    -- llegar a 80.
    --
    -- Aca estaba el bug de la franja gris que no se iba. Esta linea
    -- buscaba "MainMenuMaxLevelBar0..3" y ESE NOMBRE NO EXISTE: el marco
    -- se llama MainMenuBarMaxLevelBar (con "Bar" en el medio) y sus
    -- pedazos de 256x7 no tienen nombre propio. O sea que _G[...] devolvia
    -- nil cuatro veces y AddTexture no agregaba nada -- sin error, sin
    -- aviso, y pareciendo que el caso estaba cubierto.
    --
    -- Se lo trata por MARCO en vez de por nombre. Asi da igual como se
    -- llamen las texturas de adentro, que es justo lo que fallaba.
    AddFrameTextures(MainMenuBarMaxLevelBar);

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

    -- Y lo que quede suelto en los dos marcos de la barra. Va DESPUES de
    -- la lista por nombre a proposito: asi lo que ya estaba nombrado
    -- conserva su lugar y esto solo agrega lo que faltaba.
    AddFrameTextures(MainMenuBarArtFrame);
    AddFrameTextures(MainMenuBar);

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