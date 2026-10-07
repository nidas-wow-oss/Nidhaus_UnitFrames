local AddOnName, ns = ...;
local K, C, L = unpack(ns);







local isEnabled  = false;
local inCombat   = false;
local uabEventsFrame;
local _, playerClass = UnitClass("player");
local MAX_PLAYER_LEVEL = 80;




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





local disableWaiter = CreateFrame("Frame");
disableWaiter:SetScript("OnEvent", function(s)
    s:UnregisterAllEvents();
    if isEnabled then
        K.DisableUnifyActionBars();
    end
end);





local enableWaiter = CreateFrame("Frame");
enableWaiter:SetScript("OnEvent", function(s)
    s:UnregisterAllEvents();
    if not isEnabled and C.UnifyActionBars then
        K.EnableUnifyActionBars();
    end
end);






local saved = {};

local savedTextures = {};

local origSetPoints = {};











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




end

local function UnlockSetPoint(frame)
    if not frame then return; end
    if origSetPoints[frame] then


        frame.SetPoint = nil;
        origSetPoints[frame] = nil;
    end
end





local function CaptureOriginals()


    CaptureAllButtons();


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


    if MainMenuBarLeftEndCap  then SaveFrame("MainMenuBarLeftEndCap",  MainMenuBarLeftEndCap);  end
    if MainMenuBarRightEndCap then SaveFrame("MainMenuBarRightEndCap", MainMenuBarRightEndCap); end


    if CharacterBag0Slot then SaveFrame("CharacterBag0Slot", CharacterBag0Slot); end
    if CharacterBag1Slot then SaveFrame("CharacterBag1Slot", CharacterBag1Slot); end
    if CharacterBag2Slot then SaveFrame("CharacterBag2Slot", CharacterBag2Slot); end
    if CharacterBag3Slot then SaveFrame("CharacterBag3Slot", CharacterBag3Slot); end
    if KeyRingButton      then SaveFrame("KeyRingButton",     KeyRingButton);     end


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





local function GetBarOffset()
    local o = 0;
    if MainMenuExpBar and MainMenuExpBar:IsShown() then o = o + 6; end
    if ReputationWatchBar and ReputationWatchBar:IsShown() then o = o + 6; end
    return o;
end


local deferQueue = {};
local deferFrame = CreateFrame("Frame");
deferFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
deferFrame:SetScript("OnEvent", function()

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

    if UnitInVehicle and UnitInVehicle("player") then return; end

    if K.CreateBagPackFrame then K.CreateBagPackFrame(); end

    if K.ApplyBagPackLayout then
        K.ApplyBagPackLayout();
    else

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
    if K.AttachStanceButtons then K.AttachStanceButtons(); end
    do return; end

    UnlockSetPoint(ShapeshiftBarFrame);
    ShapeshiftBarFrame:ClearAllPoints();
    ShapeshiftBarFrame:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", 30, 40 + GetBarOffset());
    ShapeshiftBarFrame:SetScale(1);
    LockSetPoint(ShapeshiftBarFrame);
end






local PET_BAR_NORMAL = {
    DEATHKNIGHT = { x = 290, y = 43 },
    PRIEST      = { x = 250, y = 43 },
    WARLOCK     = { x = 200, y = 43 },
    SHAMAN      = { x = 250, y = 43 },
    HUNTER      = { x = 35, y = 43 },
    MAGE        = { x = 35, y = 43 },
    DRUID       = { x = 250, y = 43 },
}


local PET_BAR_SHIFTED = {
    DEATHKNIGHT = { x = 290, y = 43 },
    PRIEST      = { x = 250, y = 43 },
    WARLOCK     = { x = 250, y = 43 },
    SHAMAN      = { x = 250, y = 43 },
    HUNTER      = { x = 250, y = 43 },
    MAGE        = { x = 250, y = 43 },
    DRUID       = { x = 250, y = 43 },
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











local UNIFY_BAR_Y_BELOW_MAXLEVEL = 0;
local UNIFY_BAR_Y_MAXLEVEL       = 0;
local UNIFY_BAR_X                = -128;

local function ApplyMainBar()
    if DeferIfCombat(ApplyMainBar) then return; end
    local y = (UnitLevel("player") < MAX_PLAYER_LEVEL)
        and UNIFY_BAR_Y_BELOW_MAXLEVEL or UNIFY_BAR_Y_MAXLEVEL;
    MainMenuBar:ClearAllPoints();
    MainMenuBar:SetPoint("BOTTOM", UIParent, UNIFY_BAR_X, y);
end





local function ApplyXPRepBars()
    if DeferIfCombat(ApplyXPRepBars) then return; end


    UnlockSetPoint(MainMenuExpBar);



























    local XP_SCALE      = 0.735;
    local XP_EDGE_LEFT  = 6;


    local XP_EDGE_RIGHT = 184;
    local XP_HEIGHT     = 31;




    local XP_GAP_FLECHAS = 0;

    MainMenuExpBar:SetScale(XP_SCALE);
    if ExhaustionTick then ExhaustionTick:SetScale(XP_SCALE); end

    local es = MainMenuExpBar:GetEffectiveScale();
    if not es or es <= 0 then es = XP_SCALE; end








    local edgeRight = XP_EDGE_RIGHT;
    local esBar     = MainMenuBar:GetEffectiveScale();
    local barRight  = MainMenuBar:GetRight();
    if ActionBarUpButton and barRight and esBar and esBar > 0 then
        local esUp   = ActionBarUpButton:GetEffectiveScale();
        local upLeft = ActionBarUpButton:GetLeft();
        if upLeft and esUp and esUp > 0 then

            local limite = (upLeft * esUp) - XP_GAP_FLECHAS - (barRight * esBar);
            if limite < edgeRight then edgeRight = limite; end
        end
    end

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


    ReputationWatchBar:SetScale(0.9);
    ReputationWatchBar:SetWidth(500);
    ReputationWatchStatusBar:SetScale(0.82);
    ReputationWatchStatusBar:SetPoint("LEFT", ReputationWatchBar, -35, -54);
    if ReputationWatchStatusBarText then
        ReputationWatchStatusBarText:SetFont("Fonts\\FRIZQT__.TTF", 11.5, "OUTLINE");
        ReputationWatchStatusBarText:SetPoint("TOP", ReputationWatchStatusBar, 0, 2);
    end


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


    ActionBarUpButton:SetAlpha(1);    ActionBarUpButton:Show();
    ActionBarDownButton:SetAlpha(1);  ActionBarDownButton:Show();
end

local function ApplyAll()

    if InCombatLockdown() then return; end

    if UnitInVehicle and UnitInVehicle("player") then
        if BagPackFrame then BagPackFrame:Hide(); end
        return;
    end
    ApplyMainBar();


    ApplyPagingButtons();
    ApplyXPRepBars();
    ApplyMicroAndBags();
    ApplyShapeshiftBar();
    ApplyPetBar();


    if K.ApplyGryphons then K.ApplyGryphons(); end
end





local function UAB_OnEvent(self, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        inCombat = false;



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


        StartRetry(function()
            if isEnabled then HideAllTextures(); ApplyAll(); if K.ApplyGryphons then K.ApplyGryphons(); end end
        end, 5, 0.3);
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" then



        StartRetry(function()
            if isEnabled and not InCombatLockdown() then
                HideAllTextures();
                ApplyAll();
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end, 8, 0.4);
    elseif event == "DISPLAY_SIZE_CHANGED" then


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


        ApplyMainBar(); ApplyXPRepBars(); ApplyShapeshiftBar(); ApplyPetBar();
        if K.ApplyGryphons then K.ApplyGryphons(); end
    elseif event == "UNIT_PET" then

        if isEnabled and not InCombatLockdown() then
            ApplyPetBar();
        end
    elseif event == "UNIT_ENTERED_VEHICLE" and unit == "player" then

        if BagPackFrame then BagPackFrame:Hide(); end

        UnlockSetPoint(ShapeshiftBarFrame);
        UnlockSetPoint(PetActionBarFrame);
        UnlockSetPoint(ActionBarUpButton);
        UnlockSetPoint(ActionBarDownButton);
        UnlockSetPoint(MainMenuExpBar);
    elseif event == "UNIT_EXITED_VEHICLE" and unit == "player" then

        if BagPackFrame then BagPackFrame:Show(); end
        StartRetry(function()
            if isEnabled and not InCombatLockdown() then
                HideAllTextures();
                ApplyAll();

                if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end, 5, 0.3);
    elseif not inCombat then

        if not InCombatLockdown() then
            HideAllTextures();
            ApplyAll();
        end
    end
end












local barsBox;

function K.UpdateActionBarsBox()
    if not barsBox then
        barsBox = CreateFrame("Frame", "NUF_ActionBarsBox", UIParent);
        barsBox:SetFrameStrata("BACKGROUND");
        barsBox:EnableMouse(false);
    end







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

    if K.UpdateActionBarBoxes then K.UpdateActionBarBoxes(); end
    return barsBox;
end

































local ROW_SETS = {
    { prefix = "ActionButton"              },
    { prefix = "MultiBarBottomLeftButton"  },
    { prefix = "MultiBarBottomRightButton" },
};

local barHolders = {};

























local VEHICLE_RULE = "[vehicleui] hide; show";

local function SetVehicleHide(frame, on)
    if not frame then return; end
    if type(RegisterStateDriver) ~= "function" then return; end
    if on then
        if frame.nufVehDriver then return; end
        frame.nufVehDriver = true;
        pcall(RegisterStateDriver, frame, "visibility", VEHICLE_RULE);
    else
        if not frame.nufVehDriver then return; end
        frame.nufVehDriver = nil;
        if type(UnregisterStateDriver) == "function" then
            pcall(UnregisterStateDriver, frame, "visibility");
        end
    end
end

function K.GetBarHolder(row)
    return barHolders[row];
end

function K.EnsureBarHolder(row)
    if barHolders[row] then return barHolders[row]; end
    local h = CreateFrame("Frame", "NUF_ActionBarHolder" .. row, UIParent);
    h:SetSize(500, 30);










    h:SetFrameStrata("MEDIUM");
    if MainMenuBar then
        h:SetFrameLevel((MainMenuBar:GetFrameLevel() or 0) + 5);
    end
    barHolders[row] = h;
    return h;
end

function K.AttachActionBarButtons()
    if InCombatLockdown() then return; end





    for row = 1, 3 do
        SetVehicleHide(barHolders[row], true);
    end





    if K.GetStanceHolder then SetVehicleHide(K.GetStanceHolder(), true); end
    if C.MiniBarEnabled ~= true then return; end

    local space = tonumber(C.ActionBarButtonSpace) or 6;

    for row, set in ipairs(ROW_SETS) do
        local holder = K.EnsureBarHolder(row);
        local shown, w, h = 0, 0, 0;

        for i = 1, 12 do
            local btn = _G[set.prefix .. i];
            if btn then


                CaptureButton(btn, set.prefix .. i);




















                if i == 1 then
                    local op = btn:GetParent();
                    local page = op and op.GetAttribute and op:GetAttribute("actionpage");
                    if page ~= nil and holder.SetAttribute then
                        holder:SetAttribute("actionpage", page);
                    end
                end

                btn:SetParent(holder);
                btn:ClearAllPoints();
                if i == 1 then
                    btn:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0);
                else
                    btn:SetPoint("LEFT", _G[set.prefix .. (i - 1)], "RIGHT", space, 0);
                end
                if btn:IsShown() then
                    shown = shown + 1;
                    w = btn:GetWidth()  or 36;
                    h = btn:GetHeight() or 36;
                end
            end
        end



        if shown > 0 then
            holder:SetSize((w * shown) + (space * (shown - 1)), h);
            holder:Show();
        else
            holder:Hide();
        end






        if row == 1 and shown > 0 then
            local prev = _G[set.prefix .. 12];
            local up, down = _G["ActionBarUpButton"], _G["ActionBarDownButton"];




            if up   then UnlockSetPoint(up);   end
            if down then UnlockSetPoint(down); end





            if down and prev then
                CaptureButton(down, "ActionBarDownButton");
                down:SetParent(holder);
                down:ClearAllPoints();
                down:SetPoint("LEFT", prev, "RIGHT", 2, -8);
            end
            if up and down then
                CaptureButton(up, "ActionBarUpButton");
                up:SetParent(holder);
                up:ClearAllPoints();
                up:SetPoint("BOTTOM", down, "TOP", 0, -12);
            end
        end
    end
end




function K.HideBarHolders()


    for _, h in pairs(barHolders) do SetVehicleHide(h, false); end
    if K.GetStanceHolder then SetVehicleHide(K.GetStanceHolder(), false); end

    for _, h in pairs(barHolders) do h:Hide(); end










    if K.RestoreArtFrame then K.RestoreArtFrame(); end




end








function K.BarHolderInset(row)
    local set = ROW_SETS[row];
    if not set then return 0, 0; end
    local o = btnOrig[set.prefix .. "1"];
    if o and o.points and o.points[1] then
        return (o.points[1][4] or 0), (o.points[1][5] or 0);
    end
    return 0, 0;
end

function K.BarHolderDefaultPoint(row)
    local holder = barHolders[row];
    if not holder then return; end
    local set = ROW_SETS[row];
    if not set then return; end

    local o  = btnOrig[set.prefix .. "1"];
    local ix, iy = 0, 0;
    if o and o.points and o.points[1] then
        ix = o.points[1][4] or 0;
        iy = o.points[1][5] or 0;
    end














    local uw = UIParent:GetWidth() or 1024;
    local us = UIParent:GetEffectiveScale() or 1;
    local hs = holder:GetEffectiveScale() or us;
    if hs == 0 then hs = us; end

    local sx = (((uw - 512) / 2) + ix) * us;












    local sy = iy * math.max(us, hs);

    holder:ClearAllPoints();
    holder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", sx / hs, sy / hs);
end















local ROW_PREFIX = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
};

local rowBoxes = {};

function K.UpdateActionBarBoxes()




    local perRow = (C.MiniBarEnabled == true);

    for row = 1, 3 do
        local box = rowBoxes[row];
        if not box then
            box = CreateFrame("Frame", "NUF_ActionBar" .. row .. "Box", UIParent);
            box:SetFrameStrata("BACKGROUND");
            box:EnableMouse(false);
            rowBoxes[row] = box;
        end

        local prefixes;
        if perRow or row > 1 then
            prefixes = { ROW_PREFIX[row] };
        else
            prefixes = ROW_PREFIX;
        end

        local l, r, t, b;
        for _, prefix in ipairs(prefixes) do
        for i = 1, 12 do
            local f = _G[prefix .. i];
            if f and f:IsVisible() and f:GetLeft() then
                l = math.min(l or f:GetLeft(),   f:GetLeft());
                r = math.max(r or f:GetRight(),  f:GetRight());
                b = math.min(b or f:GetBottom(), f:GetBottom());
                t = math.max(t or f:GetTop(),    f:GetTop());
            end
        end
        end



        if l then
            box:ClearAllPoints();
            box:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b);
            box:SetSize(math.max(r - l, 10), math.max(t - b, 10));
        end
    end
end





























local function StanceButtonPitch()
    local o2 = btnOrig["ShapeshiftButton2"];
    if o2 and o2.points and o2.points[1] then
        local x = o2.points[1][4];
        if type(x) == "number" then return x; end
    end
    return 6;
end

local function StanceButtonInset()
    local o = btnOrig["ShapeshiftButton1"];
    if not o or not o.points or not o.points[1] then return 0, 0; end
    local pt = o.points[1];

    return (pt[4] or 0), (pt[5] or 0);
end


















local stanceHolder;



































local function NEBClassBarShift()
    local shifted;
    if type(NEB_ClassBarsShifted) == "function" then
        local ok, res = pcall(NEB_ClassBarsShifted);
        shifted = ok and res;
    else
        shifted = type(NEB_Config) == "table" and NEB_Config.LeftEnabled and _G["NEB_BarLeft"];
    end
    if shifted then
        return tonumber(_G.NEB_CLASSBAR_OFFSET) or 45;
    end
    return 0;
end
K.NEBClassBarShift = NEBClassBarShift;

local function StanceDefaultPoint(holder)
    local ix, iy = StanceButtonInset();
    holder:ClearAllPoints();
    holder:SetPoint("BOTTOMLEFT", MainMenuBar or UIParent, "TOPLEFT",
        30 + ix, 40 + GetBarOffset() + iy + NEBClassBarShift());
end

function K.GetStanceHolder()
    return stanceHolder;
end

function K.EnsureStanceHolder()
    if stanceHolder then return stanceHolder; end
    stanceHolder = CreateFrame("Frame", "NUF_StanceBarHolder", UIParent);
    stanceHolder:SetSize(40, 30);


    stanceHolder:SetFrameStrata("MEDIUM");
    if ShapeshiftBarFrame then
        stanceHolder:SetFrameLevel((ShapeshiftBarFrame:GetFrameLevel() or 0) + 5);
    end
    StanceDefaultPoint(stanceHolder);
    return stanceHolder;
end





local holderInit = CreateFrame("Frame");
holderInit:RegisterEvent("PLAYER_LOGIN");
holderInit:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN");


    CaptureAllButtons();
    K.EnsureStanceHolder();


    K.AttachStanceButtons();



    local neb = _G["NEB_BarLeft"];
    if neb and neb.HookScript then
        local function Relayout()
            if InCombatLockdown() then return; end
            if C.MiniBarEnabled == true and K.RefreshMiniBarLayout then
                K.RefreshMiniBarLayout(true);
            else
                K.AttachStanceButtons();
            end
        end
        neb:HookScript("OnShow", Relayout);
        neb:HookScript("OnHide", Relayout);


        if type(NEB_ClassBarShiftChanged) == "function" then
            hooksecurefunc("NEB_ClassBarShiftChanged", function()
                if not K.AfterCombat("NEBShiftRelayout", Relayout) then Relayout(); end
            end);
        end
    end
end);

function K.AttachStanceButtons()
    if InCombatLockdown() then return; end



















    if C.UnifyActionBars ~= true and C.MiniBarEnabled ~= true then
        if K.DetachStanceButtons then K.DetachStanceButtons(); end
        return;
    end
    local holder = K.EnsureStanceHolder();




    if not (K.HasGlobalPos and K.HasGlobalPos("StanceBar")) then
        StanceDefaultPoint(holder);
    end
















    local space = tonumber(C.ActionBarButtonSpace);
    if not space then space = StanceButtonPitch(); end
    local shown, w, h = 0, 0, 0;

    for i = 1, 10 do
        local btn = _G["ShapeshiftButton" .. i];
        if btn then


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



    if shown > 0 then
        holder:SetSize((w * shown) + (space * (shown - 1)), h);
    end











    if ShapeshiftBarFrame then
        local ix, iy = StanceButtonInset();
        UnlockSetPoint(ShapeshiftBarFrame);
        ShapeshiftBarFrame:ClearAllPoints();
        ShapeshiftBarFrame:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", -ix, -iy);


        holder:SetFrameLevel((ShapeshiftBarFrame:GetFrameLevel() or 0) + 5);
    end
end

local stanceBox;







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
















local SPACED_BARS = {
    { prefix = "ActionButton",              count = 12, vertical = false },
    { prefix = "MultiBarBottomLeftButton",  count = 12, vertical = false },
    { prefix = "MultiBarBottomRightButton", count = 12, vertical = false },
    { prefix = "MultiBarRightButton",       count = 12, vertical = true  },
    { prefix = "MultiBarLeftButton",        count = 12, vertical = true  },
};

local spaceWaiter;

function K.ApplyActionBarButtonSpace()


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



    if C.MiniBarEnabled == true and K.RefreshMiniBarLayout then
        pcall(K.RefreshMiniBarLayout);
    end




    if C.UnifyActionBars == true and MultiBarBottomRightButton7 and MainMenuBar then
        MultiBarBottomRightButton7:ClearAllPoints();
        MultiBarBottomRightButton7:SetPoint("LEFT", MainMenuBar, "LEFT", 513, -5);
    end
end




function K.RestoreActionBarButtonSpace()
    K.RestoreAllButtons();
end
















function K.UnifyMarkOff()
    isEnabled      = false;
    K._unifyActive = false;
end

function K.EnableUnifyActionBars()
    if isEnabled then return; end




    if InCombatLockdown() then
        enableWaiter:RegisterEvent("PLAYER_REGEN_ENABLED");
        return;
    end


    if K._minibarActive then
        if K.DisableMiniBar then K.DisableMiniBar(); end
        K.SaveConfig("MiniBarEnabled", false);
    end



    if K.EnsureBarBaseline then K.EnsureBarBaseline(); end


    if K.RestoreBarBaseline then K.RestoreBarBaseline(); end




    if K._habRelease then K._habRelease(); end


    if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
    if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end


    CaptureOriginals();

    isEnabled = true;
    K._unifyActive = true;
    if K._habReapply then K._habReapply(); end


    HideAllTextures();


    local scale = C.ActionBarScale or 1.0;
    MainMenuBar:SetScale(scale);
    MainMenuBar:SetWidth(510);
    MultiBarBottomLeft:SetScale(scale); MultiBarBottomRight:SetScale(scale);
    MultiBarRight:SetScale(scale);      MultiBarLeft:SetScale(scale);


    ApplyXPRepBars();


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


    MultiBarBottomRight:SetPoint("LEFT", MultiBarBottomLeft, "RIGHT", 5, 0);
    MultiBarBottomRightButton7:SetPoint("LEFT", MainMenuBar, "LEFT", 513, -5);

    ApplyAll();


    if K.ApplyActionBarButtonSpace then K.ApplyActionBarButtonSpace(); end


    if K.AttachStanceButtons then K.AttachStanceButtons(); end


    if K.ApplyGryphons then K.ApplyGryphons(); end


    if K.CreateBagPackFrame then K.CreateBagPackFrame(); end


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



    if UpdateMicroButtons and not K._uabMicroHooked then
        hooksecurefunc("UpdateMicroButtons", function()
            if isEnabled and not InCombatLockdown() then


                if UnitInVehicle and UnitInVehicle("player") then return; end
                ApplyMicroAndBags();
            end
        end);
        K._uabMicroHooked = true;
    end




    if VehicleMenuBar_MoveMicroButtons and not K._uabVehicleMicroHooked then
        hooksecurefunc("VehicleMenuBar_MoveMicroButtons", function(skinName)
            if not isEnabled then return; end
            if not skinName then

                if not InCombatLockdown() then
                    ApplyMicroAndBags();
                end
            else



                if K.MicroVehicleScale then K.MicroVehicleScale(); end
            end
        end);
        K._uabVehicleMicroHooked = true;
    end



    if PetActionBar_Update and not K._uabPetHooked then
        hooksecurefunc("PetActionBar_Update", function()
            if isEnabled and not InCombatLockdown() then
                ApplyPetBar();
            end
        end);
        K._uabPetHooked = true;
    end


    if ShapeshiftBar_Update and not K._uabShapeshiftHooked then
        hooksecurefunc("ShapeshiftBar_Update", function()
            if isEnabled and not InCombatLockdown() then
                ApplyShapeshiftBar();
            end
        end);
        K._uabShapeshiftHooked = true;
    end




    if MainMenuBar_UpdateExperienceBars and not K._uabExpBarHooked then
        hooksecurefunc("MainMenuBar_UpdateExperienceBars", function()
            if isEnabled and not InCombatLockdown() then
                if UnitInVehicle and UnitInVehicle("player") then return; end







                ApplyXPRepBars();
                ApplyShapeshiftBar();
                ApplyPetBar();
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end);
        K._uabExpBarHooked = true;
    end



    if UIParent_ManageFramePositions and not K._uabManageHooked then
        hooksecurefunc("UIParent_ManageFramePositions", function()
            if isEnabled and not InCombatLockdown() then

                if UnitInVehicle and UnitInVehicle("player") then return; end


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





function K.DisableUnifyActionBars()
    if not isEnabled then return; end



    if InCombatLockdown() then
        disableWaiter:RegisterEvent("PLAYER_REGEN_ENABLED");
        return;
    end

    isEnabled = false;
    K._unifyActive = false;






    if K.RestoreActionBarButtonSpace then K.RestoreActionBarButtonSpace(); end
    if K.DetachStanceButtons then K.DetachStanceButtons(); end


    if uabEventsFrame then
        uabEventsFrame:UnregisterAllEvents();
        uabEventsFrame:SetScript("OnEvent", nil);
    end


    UnlockSetPoint(ShapeshiftBarFrame);
    UnlockSetPoint(PetActionBarFrame);
    UnlockSetPoint(ActionBarUpButton);
    UnlockSetPoint(ActionBarDownButton);

    UnlockSetPoint(MainMenuExpBar);


    if BagPackFrame then BagPackFrame:Hide(); end














    RestoreAllTextures();


    RestoreFrame("MainMenuBar",               MainMenuBar);
    RestoreFrame("MainMenuBarBackpackButton",  MainMenuBarBackpackButton);
    RestoreFrame("CharacterMicroButton",       CharacterMicroButton);

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


    if CharacterBag0Slot then RestoreFrame("CharacterBag0Slot", CharacterBag0Slot); end
    if CharacterBag1Slot then RestoreFrame("CharacterBag1Slot", CharacterBag1Slot); end
    if CharacterBag2Slot then RestoreFrame("CharacterBag2Slot", CharacterBag2Slot); end
    if CharacterBag3Slot then RestoreFrame("CharacterBag3Slot", CharacterBag3Slot); end
    if KeyRingButton      then RestoreFrame("KeyRingButton",     KeyRingButton);     end



    if UIParent_ManageFramePositions then
        pcall(UIParent_ManageFramePositions);
    end

    if MainMenuBar_UpdateExperienceBars then
        pcall(MainMenuBar_UpdateExperienceBars);
    end
    if ShapeshiftBarFrame and ShapeshiftBar_Update then
        pcall(ShapeshiftBar_Update);
    end
    if PetActionBarFrame and PetActionBar_Update then
        pcall(PetActionBar_Update);
    end



    StartRetry(function()
        if not isEnabled and not InCombatLockdown() then
            if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
            if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end
            if ShapeshiftBar_Update then pcall(ShapeshiftBar_Update); end
            if PetActionBar_Update then pcall(PetActionBar_Update); end
            if UpdateMicroButtons then pcall(UpdateMicroButtons); end
        end
    end, 5, 0.3);



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






    if K.RestoreBarBaseline then pcall(K.RestoreBarBaseline); end


    saved = {};
    savedTextures = {};
    origSetPoints = {};


    if C.ActionBarScale and C.ActionBarScale ~= 1.0 then
        K.ApplyActionBarScale(C.ActionBarScale);
    end








    if K._habReapply then K._habReapply(); end
end



local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)


    if isEnabled then

        StartRetry(function()
            if isEnabled and not InCombatLockdown() then
                HideAllTextures(); ApplyAll();
                if K.ApplyGryphons then K.ApplyGryphons(); end
            end
        end, 8, 0.4);
        return;
    end

    local elapsed = 0;
    self:SetScript("OnUpdate", function(s, dt)
        elapsed = elapsed + dt;
        if elapsed >= 0.5 then
            s:SetScript("OnUpdate", nil);
            if C.UnifyActionBars and not C.MiniBarEnabled then


                K.EnableUnifyActionBars();
            end
        end
    end);
end);
