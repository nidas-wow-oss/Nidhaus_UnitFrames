local AddOnName, ns = ...;
local K, C, L = unpack(ns);

if select(2, UnitClass("player")) ~= "PALADIN" then return; end

local SPELL_ID = 58597;
local UNIT     = "target";
local FILTER   = "HELPFUL";
local SIZE     = 74;

local DEFAULTS = {
    point = "CENTER",
    x     = -132.26660218206,
    y     = 169.24457389997,
};

SacredShieldDB = SacredShieldDB or {};

local function ApplyDefaults()
    SacredShieldDB = SacredShieldDB or {};
    for k, v in pairs(DEFAULTS) do
        if SacredShieldDB[k] == nil then SacredShieldDB[k] = v; end
    end
end
ApplyDefaults();

local frame = CreateFrame("Frame", "NUF_SacredShieldFrame", UIParent);
frame:SetWidth(SIZE);
frame:SetHeight(SIZE);
frame:SetPoint(SacredShieldDB.point, UIParent, SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y);
frame:SetMovable(true);
frame:SetClampedToScreen(true);
frame:EnableMouse(false);
frame:Hide();

if K.RegisterScalable then K.RegisterScalable("SacredShield", frame, 1.0); end

frame.bg = frame:CreateTexture(nil, "BACKGROUND");
frame.bg:SetAllPoints(frame);
frame.bg:SetTexture(0, 0, 0, 0.35);
frame.bg:Hide();

frame.icon = frame:CreateTexture(nil, "ARTWORK");
frame.icon:SetAllPoints(frame);

frame.icon:SetTexCoord(0, 1, 0, 1);

frame.judgeBorder = CreateFrame("Frame", nil, frame);
frame.judgeBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3);
frame.judgeBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3);
frame.judgeBorder:SetFrameLevel(frame:GetFrameLevel() + 1);
frame.judgeBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 3 });
frame.judgeBorder:SetBackdropBorderColor(1, 0.82, 0, 1);

frame.moveBorder = frame:CreateTexture(nil, "OVERLAY");
frame.moveBorder:SetAllPoints(frame);
frame.moveBorder:SetTexture(0, 1, 0, 0.30);
frame.moveBorder:Hide();

local iconTexture;
local function ResolveIcon()
    if iconTexture then return iconTexture; end
    local _, _, tex = GetSpellInfo(SPELL_ID);
    if tex then
        iconTexture = tex;
        frame.icon:SetTexture(tex);
    end
    return iconTexture;
end
ResolveIcon();

local function HasAura()
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitAura(UNIT, i, FILTER);
        if not name then return false; end
        if spellId == SPELL_ID then return true; end
    end
    return false;
end

local JUDGEMENT_IDS = {
    [20187] = true,
    [20467] = true,
    [31804] = true,
    [53733] = true,
    [31898] = true,
    [53726] = true,
    [54158] = true,
};
local SHIELD_DURATION = 6;
local MAX_SAMPLES     = 5;
local PLAYER_FLAG     = 0x400;

local shields      = {};
local learnedCap   = {};
local recentAbsT   = {};
local recentAbsA   = {};
local judgeSamples = {};
local playerGUID;

local function MyJudgementDamage()
    local n = #judgeSamples;
    if n == 0 then return nil; end
    local m = judgeSamples[1];
    for i = 2, n do
        if judgeSamples[i] < m then m = judgeSamples[i]; end
    end
    return m;
end

local function AddSample(v)
    if not v or v <= 0 then return; end
    judgeSamples[#judgeSamples + 1] = v;
    if #judgeSamples > MAX_SAMPLES then table.remove(judgeSamples, 1); end
end

local function OnAbsorb(guid, amount, flags)

    if not amount or amount <= 0 or bit.band(flags or 0, PLAYER_FLAG) == 0 then return; end
    local st = shields[guid];
    local now = GetTime();
    if st then
        st.used, st.lastAbs = st.used + amount, now;
    elseif recentAbsT[guid] == now then
        recentAbsA[guid] = recentAbsA[guid] + amount;
    else
        recentAbsT[guid], recentAbsA[guid] = now, amount;
    end
end

local function CloseShield(guid, st)
    local now = GetTime();
    if st.used > 0 and st.caster then
        local broken = (now - st.t) < (SHIELD_DURATION - 0.3)
            and st.lastAbs and (now - st.lastAbs) < 0.3;
        if broken or st.used > (learnedCap[st.caster] or 0) then
            learnedCap[st.caster] = st.used;
        end
    end
    shields[guid] = nil;
end

local function BorderColor()
    local guid = UnitGUID(UNIT);
    local st   = guid and shields[guid];
    local cap  = st and st.caster and learnedCap[st.caster];
    local dmg  = MyJudgementDamage();
    if not cap or not dmg then return 1, 0.82, 0; end
    local left = cap - st.used;

    if left <= 0 then return 1, 0.82, 0; end
    if dmg > left then return 0, 1, 0; end
    return 1, 0, 0;
end

local moving = false;
local enabled = false;

local function ZoneOK()
    if not K.ModuleZoneAllowed then return true; end
    return K.ModuleZoneAllowed("SacredShield");
end

local function Update()
    if moving then return; end

    if enabled and ZoneOK() and UnitExists(UNIT) and HasAura() then
        ResolveIcon();
        frame.judgeBorder:SetBackdropBorderColor(BorderColor());
        frame:Show();
    else
        frame:Hide();
    end
end

local f = CreateFrame("Frame");

local function OnCombatLog(_, sub, srcGUID, _, _, dstGUID, _, dstFlags, a9, a10, _, a12, a13, a14, _, _, a17, a18)
    if sub == "SWING_DAMAGE" then
        OnAbsorb(dstGUID, a14, dstFlags);
    elseif sub == "SPELL_DAMAGE" or sub == "SPELL_PERIODIC_DAMAGE" or sub == "RANGE_DAMAGE"
        or sub == "DAMAGE_SHIELD" or sub == "DAMAGE_SPLIT" then
        OnAbsorb(dstGUID, a17, dstFlags);
        if srcGUID == playerGUID and JUDGEMENT_IDS[a9] and not a18
            and bit.band(dstFlags or 0, PLAYER_FLAG) > 0 then
            AddSample(a12 + (a17 or 0));
        end
    elseif sub == "SWING_MISSED" then
        if a9 == "ABSORB" then OnAbsorb(dstGUID, a10, dstFlags); end
    elseif sub == "SPELL_MISSED" or sub == "SPELL_PERIODIC_MISSED" or sub == "RANGE_MISSED" then
        if a12 ~= "ABSORB" then return; end
        OnAbsorb(dstGUID, a13, dstFlags);
        if srcGUID == playerGUID and JUDGEMENT_IDS[a9] and bit.band(dstFlags or 0, PLAYER_FLAG) > 0 then
            AddSample(a13);
        end
    elseif sub == "SPELL_AURA_APPLIED" or sub == "SPELL_AURA_REFRESH" then
        if a9 ~= SPELL_ID then return; end
        local old = shields[dstGUID];
        if old then CloseShield(dstGUID, old); end
        local now = GetTime();
        local st = { caster = srcGUID, used = 0, t = now };

        if recentAbsT[dstGUID] and (now - recentAbsT[dstGUID]) < 0.3 then
            st.used, st.lastAbs = recentAbsA[dstGUID], recentAbsT[dstGUID];
        end
        shields[dstGUID] = st;
    elseif sub == "SPELL_AURA_REMOVED" then
        if a9 ~= SPELL_ID then return; end
        local st = shields[dstGUID];
        if st then CloseShield(dstGUID, st); end
    else
        return;
    end
    if frame:IsShown() and dstGUID == UnitGUID(UNIT) then Update(); end
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLog(...);
        return;
    end
    if event == "UNIT_AURA" and ... ~= UNIT then return; end
    if event == "PLAYER_ENTERING_WORLD" then

        playerGUID = UnitGUID("player");
        wipe(shields); wipe(recentAbsT); wipe(recentAbsA);
    end
    Update();
end);

local dbLoader = CreateFrame("Frame");
dbLoader:RegisterEvent("ADDON_LOADED");
dbLoader:SetScript("OnEvent", function(self, event, addon)
    if addon ~= AddOnName then return; end
    ApplyDefaults();
    frame:ClearAllPoints();
    frame:SetPoint(SacredShieldDB.point, UIParent, SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y);
    self:UnregisterEvent("ADDON_LOADED");
end);

local function SetMoving(on)
    moving = on;
    if on then
        ResolveIcon();
        frame.icon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark");
        frame:EnableMouse(true);
        frame:RegisterForDrag("LeftButton");
        frame:SetScript("OnDragStart", function(self) self:StartMoving(); end);
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing();
            local point, _, _, x, y = self:GetPoint();
            SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y = point, x, y;
        end);
        frame.bg:Show();
        frame.moveBorder:Show();
        frame.judgeBorder:SetBackdropBorderColor(1, 0.82, 0, 1);
        frame:Show();
    else
        frame:EnableMouse(false);
        frame:RegisterForDrag();
        frame:SetScript("OnDragStart", nil);
        frame:SetScript("OnDragStop", nil);
        frame.bg:Hide();
        frame.moveBorder:Hide();
        Update();
    end
end

function K.SetSacredShieldMove(on)
    SetMoving(on and true or false);
    return moving;
end

function K.IsSacredShieldMoving()
    return moving;
end

function K.ResetSacredShieldPosition()
    SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y = DEFAULTS.point, DEFAULTS.x, DEFAULTS.y;
    frame:ClearAllPoints();
    frame:SetPoint(SacredShieldDB.point, UIParent, SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y);

end

SLASH_NUFSACREDSHIELD1 = "/ss";
SLASH_NUFSACREDSHIELD2 = "/sacredshield";
SlashCmdList["NUFSACREDSHIELD"] = function(msg)
    msg = (msg or ""):lower();
    msg = msg:gsub("^%s+", ""):gsub("%s+$", "");

    if msg == "reset" then
        SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y = DEFAULTS.point, DEFAULTS.x, DEFAULTS.y;
        frame:ClearAllPoints();
        frame:SetPoint(SacredShieldDB.point, UIParent, SacredShieldDB.point, SacredShieldDB.x, SacredShieldDB.y);
        print("|cff4FC3F7NUF:|r " .. (L["SS_POS_RESET"] or "Sacred Shield - position restored to the WeakAura's."));
    else
        SetMoving(not moving);
    end
end

local function SS_SetEnabled(on)
    enabled = on and true or false;
    if on then
        f:RegisterEvent("PLAYER_ENTERING_WORLD");
        f:RegisterEvent("PLAYER_TARGET_CHANGED");
        f:RegisterEvent("UNIT_AURA");
        f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        playerGUID = UnitGUID("player");
        Update();
    else
        f:UnregisterAllEvents();
        if moving then SetMoving(false); end
        frame:Hide();
    end
end

if K.RegisterModuleZones then
    K.RegisterModuleZones("SacredShield",
        function()
            SacredShieldDB = SacredShieldDB or {};
            return SacredShieldDB;
        end,
        function()
            if enabled then Update(); end
        end);
end

K.RegisterModule("SacredShield", {
    name    = L["MOD_SACREDSHIELD"] or "Sacred Shield (target)",
    desc    = L["MOD_SACREDSHIELD_DESC"]
        or "Shows an icon while your target has Sacred Shield. /ss to move it.",
    default = false,
    hideFromModulesTab = true,
    onEnable    = function() SS_SetEnabled(true); end,
    onDisable   = function() SS_SetEnabled(false); end,
});
