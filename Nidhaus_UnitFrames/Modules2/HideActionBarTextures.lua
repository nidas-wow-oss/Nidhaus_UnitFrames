local AddOnName, ns = ...;
local K, C, L = unpack(ns);










































local textures = {};

local dimmers  = {};

local habEnabled = false;


local prevShown = {};
local prevAlpha = {};

local yaAgregada = {};





local retryFrame, retryAttempts, retryElapsed;

local function ArmarRafaga()
    if not retryFrame then return; end
    retryAttempts = 0;
    retryElapsed  = 0;
    retryFrame:Show();
end

local function AddTexture(tex)
    if tex and tex.SetAlpha and not yaAgregada[tex] then
        yaAgregada[tex] = true;
        table.insert(textures, tex);
    end
end
























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




    AddFrameTextures(MainMenuBarArtFrame);
    AddFrameTextures(MainMenuBar);


    AddDimmer(MainMenuExpBar);
    AddDimmer(ReputationWatchBar);
end

local function HideDecorations()
    for _, tex in ipairs(textures) do



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











local function ReleaseAll()
    for obj, shown in pairs(prevShown) do
        if obj.SetAlpha then obj:SetAlpha(prevAlpha[obj] or 1); end
        if shown then obj:Show(); else obj:Hide(); end
        prevAlpha[obj] = nil;
    end
    prevShown = {};



    for obj, a in pairs(prevAlpha) do
        if obj.SetAlpha then obj:SetAlpha(a); end
    end
    prevAlpha = {};
end

local function ShowDecorations()
    ReleaseAll();
end





local function AnyBarModeActive()
    return (K._unifyActive == true) or (K._minibarActive == true);
end
































local function Release()
    if retryFrame then retryFrame:Hide(); end
    ReleaseAll();
end



K._habRelease = Release;

local function ApplyState()
    if #textures == 0 then SetupTextures(); end
    if AnyBarModeActive() then Release(); return; end
    if habEnabled then
        HideDecorations();
    else
        ShowDecorations();
    end
end




K._habReapply = function()

    SetupTextures();
    if AnyBarModeActive() then Release(); return; end
    if habEnabled then
        HideDecorations();







        ArmarRafaga();
    else
        ShowDecorations();
    end
end


retryFrame    = CreateFrame("Frame");
retryAttempts = 0;
retryElapsed  = 0;

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


local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("PLAYER_LOGIN");
eventFrame:SetScript("OnEvent", function()
    if not habEnabled then return; end
    if AnyBarModeActive() then return; end
    ArmarRafaga();
end);



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

    if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("HideActionBarTextures"); end
end

K.RegisterModule("HideActionBarTextures", {
    name = "Hide Action Bar Textures",
    desc = "Hides action bar decorative textures.",
    default = false,

    hideFromModulesTab = true,
    onEnable = function()
        habEnabled = true;



        SetupTextures();
        ApplyState();


        if not AnyBarModeActive() then ArmarRafaga(); end
    end,
    onDisable = function()
        habEnabled = false;
        retryFrame:Hide();
        ApplyState();
    end,
});