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

local function ApplyState()
    if #textures == 0 then SetupTextures(); end
    -- Si UnifyActionBars está activo, no tocar — ActionBars maneja las texturas
    if K._unifyActive then return; end
    if habEnabled then
        HideDecorations();
    else
        ShowDecorations();
    end
end

-- Exponer función para que ActionBars pueda pedirle re-aplicar
K._habReapply = function()
    if habEnabled then
        if #textures == 0 then SetupTextures(); end
        HideDecorations();
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
        if habEnabled and not K._unifyActive then
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
    -- Si UnifyActionBars está activo, no pelear
    if K._unifyActive then return; end
    retryAttempts = 0;
    retryElapsed = 0;
    retryFrame:Show();
end);

SLASH_HIDEACTIONBAR1 = "/hidebar";
SlashCmdList["HIDEACTIONBAR"] = function()
    if habEnabled then
        habEnabled = false;
        if not K._unifyActive then ShowDecorations(); end
        print("HideBar: fondos visibles.");
    else
        habEnabled = true;
        if not K._unifyActive then HideDecorations(); end
        print("HideBar: fondos ocultos.");
    end
end

K.RegisterModule("HideActionBarTextures", {
    name = "Hide Action Bar Textures",
    desc = "Oculta decoraciones visuales de la barra de accion.",
    default = false,
    onEnable = function()
        habEnabled = true;
        ApplyState();
    end,
    onDisable = function()
        habEnabled = false;
        ApplyState();
    end,
});