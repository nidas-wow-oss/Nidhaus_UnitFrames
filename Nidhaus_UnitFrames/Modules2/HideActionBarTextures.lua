local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local textures = {};
local habEnabled = false;

local function AddTexture(tex)
    if tex and tex.SetAlpha then
        table.insert(textures, tex);
    end
end

local function SetupTextures()
    textures = {};
    for i = 0, 3 do AddTexture(_G["MainMenuBarTexture" .. i]); end
    AddTexture(MainMenuXPBarTextureLeftCap);
    AddTexture(MainMenuXPBarTextureRightCap);
    AddTexture(MainMenuXPBarTextureMid);
    AddTexture(MainMenuExpBar);
    for i = 0, 8 do AddTexture(_G["ReputationWatchBarTexture" .. i]); end
    AddTexture(ReputationWatchBar);
    AddTexture(MainMenuBarLeftEndCap);
    AddTexture(MainMenuBarRightEndCap);
    AddTexture(MainMenuBarBackpackButtonBorder);
    AddTexture(KeyRingButtonBorder);
    AddTexture(CharacterBag0SlotBorder);
    AddTexture(CharacterBag1SlotBorder);
    AddTexture(CharacterBag2SlotBorder);
    AddTexture(CharacterBag3SlotBorder);
end

local function HideDecorations()
    for _, tex in ipairs(textures) do
        tex:Hide();
        tex:SetAlpha(0);
    end
end

local function ShowDecorations()
    for _, tex in ipairs(textures) do
        tex:Show();
        tex:SetAlpha(1);
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