local AddOnName, ns = ...;
local K, C, L = unpack(ns);







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


local TEXTURE_PATH = "Interface\\AddOns\\" .. AddOnName .. "\\Modules2\\ClassIcons\\Textures\\";





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





local arenaFrame = CreateFrame("Frame");
arenaFrame:Hide();




local ARENA_THROTTLE = 0.2;

local function ArenaUpdate(self, elapsed)
    self.acc = (self.acc or 0) + (elapsed or 0);
    if self.acc < ARENA_THROTTLE then return; end
    self.acc = 0;

    if not isActive or iconStyle == "default" then return; end
    if not _G.ArenaEnemyFrames or not _G.ArenaEnemyFrames:IsShown() then return; end

    for i = 1, GetNumArenaOpponents() do
        SetPortrait(_G["ArenaEnemyFrame" .. i]);
    end
end

arenaFrame:SetScript("OnUpdate", ArenaUpdate);





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


K.ClassIcons_SetStyle = SetStyle;
K.ClassIcons_GetStyle = GetStyle;





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





local hooked = false;

local function EnsureHook()
    if hooked then return; end
    hooksecurefunc("UnitFramePortrait_Update", SetPortrait);
    hooked = true;
end





K.RegisterModule("ClassIcons", {
    name = "Class Icons",
    desc = "Replaces portraits with class icons (default, modern, hs, ex)",
    default = false,

    onEnable = function()
        isActive = true;
        iconStyle = GetStyle();
        EnsureHook();
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
        eventFrame:Show();


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


    createUI = function(parent, yPos)
        local STYLES = {
            { value = "default", label = "Default" },
            { value = "modern",  label = "Modern" },
            { value = "hs",      label = "HS" },
            { value = "ex",      label = "Exprmtl" },
        };

        local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        label:SetPoint("TOPLEFT", 36, yPos);
        label:SetText("|cffAAAAAA" .. (L["LBL_STYLE"] or "Style:") .. "|r");

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

                for _, b in ipairs(styleBtns) do
                    if b.style == iconStyle then
                        b:GetFontString():SetTextColor(0, 1, 0);
                    else
                        b:GetFontString():SetTextColor(1, 1, 1);
                    end
                end
            end);


            if s.value == iconStyle then
                fs:SetTextColor(0, 1, 0);
            end

            btnX = btnX + 78;
        end




        return 28;
    end,
});






local migrateFrame = CreateFrame("Frame");
migrateFrame:RegisterEvent("PLAYER_LOGIN");
migrateFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN");


    if ClassIconsSV and ClassIconsSV.style and NidhausUnitFramesDB then
        if not NidhausUnitFramesDB.ClassIconsStyle then
            NidhausUnitFramesDB.ClassIconsStyle = ClassIconsSV.style;
            iconStyle = ClassIconsSV.style;
        end
    end
end);