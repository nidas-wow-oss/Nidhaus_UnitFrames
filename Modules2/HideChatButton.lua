local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local HCBframe = nil;
local HCBActivateChat = ChatEdit_ActivateChat;

-- FIX: Variables locales en vez de globales sueltas
-- Se cargan desde NidhausUnitFramesDB en ADDON_LOADED
local HCBxpos = 0;
local HCBypos = 0;
local HCBkeyable = false;
local HCBuseralpha = .25;

-- FIX: Helpers para persistir en NidhausUnitFramesDB (ya es SavedVariable)
local function SaveHCBSettings()
    if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
    NidhausUnitFramesDB.HCBxpos = HCBxpos;
    NidhausUnitFramesDB.HCBypos = HCBypos;
    NidhausUnitFramesDB.HCBkeyable = HCBkeyable;
    NidhausUnitFramesDB.HCBuseralpha = HCBuseralpha;
end

local function LoadHCBSettings()
    if not NidhausUnitFramesDB then return; end
    if NidhausUnitFramesDB.HCBxpos ~= nil then HCBxpos = NidhausUnitFramesDB.HCBxpos; end
    if NidhausUnitFramesDB.HCBypos ~= nil then HCBypos = NidhausUnitFramesDB.HCBypos; end
    if NidhausUnitFramesDB.HCBkeyable ~= nil then HCBkeyable = NidhausUnitFramesDB.HCBkeyable; end
    if NidhausUnitFramesDB.HCBuseralpha ~= nil then HCBuseralpha = NidhausUnitFramesDB.HCBuseralpha; end
end

if not HCBframe then
    HCBframe = CreateFrame("Button", "HCBframe", UIParent, "UIPanelButtonTemplate");
    HCBframe:SetClampedToScreen(true);
    HCBframe:SetMovable(true);
    HCBframe:EnableMouse(true);
    HCBframe:RegisterForDrag("RightButton");
    HCBframe:SetScript("OnDragStart", HCBframe.StartMoving);
    -- FIX: Guardar posición al soltar el drag
    HCBframe:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        local _, _, _, x, y = self:GetPoint(1);
        HCBxpos = x or 0;
        HCBypos = y or 0;
        SaveHCBSettings();
    end);
    HCBframe:SetWidth(24);
    HCBframe:SetHeight(24);
    HCBframe:SetPoint("BOTTOMLEFT", HCBxpos, HCBypos);
    HCBframe.ChatIsShown = true;
    HCBframe.ActiveTabs = { [1] = true };
    HCBframe:EnableMouseWheel(true);
    HCBframe:Hide();
end

HCBframe.ToggleKeyable = function(frame)
    if HCBkeyable == false then
        HCBkeyable = true;
    else
        HCBkeyable = false;
    end
    SaveHCBSettings();
    HCBframe:Paint();
end

HCBframe.AlphaUpdate = function(frame, delta)
    if delta == 1 and HCBuseralpha < 1 then
       HCBuseralpha = HCBuseralpha + .05;
    elseif delta == -1 and HCBuseralpha > 0 then
        HCBuseralpha = HCBuseralpha - .05;
    end
    SaveHCBSettings();
    HCBframe:Paint();
end

HCBframe.Paint = function(frame, text)
    HCBframe:SetAlpha(HCBkeyable and 1.0 or (HCBuseralpha or .25));
    HCBframe:SetText(text or "");
end

HCBframe.RestoreDefaults = function(frame)
    HCBkeyable = true;
    HCBxpos = 0;
    HCBypos = 0;
    HCBuseralpha = .25;
    HCBframe:ClearAllPoints();
    HCBframe:SetPoint("BOTTOMLEFT", HCBxpos, HCBypos);
    SaveHCBSettings();
    HCBframe:Paint();
end

HCBframe.HideChat = function(frame)
    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i];
        if f then
            if f.minimized then
                local fm = _G["ChatFrame"..i.."Minimized"];
                if fm then
                    fm.HCBOverrideShow = fm.Show;
                    fm.Show = fm.Hide;
                    fm:Hide();
                end
                frame.ActiveTabs[i] = false;
            elseif f:IsVisible() then
                frame.ActiveTabs[i] = true;
                f:Hide();
            else
                frame.ActiveTabs[i] = false;
            end
            f.HCBOverrideShow = f.Show;
            f.Show = f.Hide;
        end
    end
    GeneralDockManager.HCBOverrideShow = GeneralDockManager.Show;
    GeneralDockManager.Show = GeneralDockManager.Hide;
    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i.."Tab"];
        if f then
            if frame.ActiveTabs[i] == true and f:IsVisible() then
                f:Hide();
            end
            f.HCBOverrideShow = f.Show;
            f.Show = f.Hide;
        end
    end
    GeneralDockManager:Hide();
    ChatFrameMenuButton:Hide();
    FriendsMicroButton:Hide();
    frame.ChatIsShown = false;
end

HCBframe.ShowChat = function(frame)
    GeneralDockManager.Show = GeneralDockManager.HCBOverrideShow;
    GeneralDockManager:Show();
    ChatFrameMenuButton:Show();
    FriendsMicroButton:Show();
    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i];
        if f then
            f.Show = f.HCBOverrideShow;
            if f.minimized then
                local fm = _G["ChatFrame"..i.."Minimized"];
                if fm then
                    fm.Show = fm.HCBOverrideShow;
                    fm:Show();
                end
            elseif frame.ActiveTabs[i] == true then
                f:Show();
            end
        end
        local ft = _G["ChatFrame"..i.."Tab"];
        if ft then
            ft.Show = ft.HCBOverrideShow;
            if frame.ActiveTabs[i] == true then
                ft:Show();
            end
        end
    end
    frame.ChatIsShown = true;
end

HCBframe.ToggleVisible = function(frame)
    if HCBframe.ChatIsShown == false then
        HCBframe:ShowChat();
    else
        HCBframe:HideChat();
    end
    HCBframe:Paint();
end

HCBframe:SetScript("OnMouseUp", function(frame, button)
    if IsControlKeyDown() then
        HCBframe:RestoreDefaults();
    elseif IsShiftKeyDown() then
        HCBframe:ToggleKeyable();
    elseif button == "LeftButton" then
        HCBframe:ToggleVisible();
    end
end);

HCBframe:SetScript("OnMouseWheel", function(frame, delta)
    if IsShiftKeyDown() then
        HCBframe.ToggleKeyable();
    elseif IsAltKeyDown() then
        HCBframe.AlphaUpdate(frame, delta);
    else
        HCBframe.ToggleVisible();
    end
end);

-- FIX: Nil guard en caso de que otro addon haya modificado la referencia
function ChatEdit_ActivateChat(frame)
    if HCBkeyable == true and HCBframe.ChatIsShown == false then
        HCBframe:ToggleVisible();
    end
    if HCBActivateChat then HCBActivateChat(frame); end
end

HCBframe:RegisterEvent("CHAT_MSG_BATTLEGROUND");
HCBframe:RegisterEvent("CHAT_MSG_BATTLEGROUND_LEADER");
HCBframe:RegisterEvent("CHAT_MSG_GUILD");
HCBframe:RegisterEvent("CHAT_MSG_OFFICER");
HCBframe:RegisterEvent("CHAT_MSG_PARTY");
HCBframe:RegisterEvent("CHAT_MSG_PARTY_LEADER");
HCBframe:RegisterEvent("CHAT_MSG_RAID");
HCBframe:RegisterEvent("CHAT_MSG_RAID_LEADER");
HCBframe:RegisterEvent("CHAT_MSG_WHISPER");
HCBframe:RegisterEvent("ADDON_LOADED");

-- FIX: Tabla movida fuera de OnEvent (no recrearla en cada evento)
-- FIX: Key corregida — CHAT_MSG_OFFICER (no CHAT_MSG_GUILD_OFFICER) para matchear el evento registrado
local eventcolors = {
    CHAT_MSG_BATTLEGROUND        = "cc6633B",
    CHAT_MSG_BATTLEGROUND_LEADER = "cc6633B",
    CHAT_MSG_GUILD               = "66cc00G",
    CHAT_MSG_OFFICER             = "66cc00O",   -- FIX: era CHAT_MSG_GUILD_OFFICER, no matcheaba
    CHAT_MSG_PARTY               = "6666FFP",
    CHAT_MSG_PARTY_LEADER        = "6666FFP",
    CHAT_MSG_RAID                = "cc6600R",
    CHAT_MSG_RAID_LEADER         = "cc6600R",
    CHAT_MSG_WHISPER             = "ff00ffW",
};

HCBframe.OnEvent = function(frame, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...;
        if addonName == AddOnName then
            -- FIX: Cargar settings persistidos y reposicionar
            LoadHCBSettings();
            HCBframe:ClearAllPoints();
            HCBframe:SetPoint("BOTTOMLEFT", HCBxpos, HCBypos);
        end
        HCBframe:Paint();
    elseif HCBframe.ChatIsShown == false and eventcolors[event] then
        HCBframe:Paint("|cff" .. eventcolors[event] .. "|r");
    end
end

HCBframe:SetScript("OnEvent", HCBframe.OnEvent);

BINDING_HEADER_HIDECHATBUTTON = "Hide Chat Button";
BINDING_NAME_HCB_TOGGLE = "Toggle Chat Visibility";

SLASH_HCB1 = "/hcb";
SlashCmdList["HCB"] = function(arg)
    if arg == "default" or arg == "reset" then
        HCBframe:RestoreDefaults();
    else
        HCBframe:ToggleVisible();
    end
end

K.RegisterModule("HideChatButton", {
    name = "Hide Chat Button",
    desc = "Boton para ocultar/mostrar el chat.",
    default = true,
    onEnable = function()
        HCBframe:Show();
        HCBframe:Paint();
    end,
    onDisable = function()
        if HCBframe.ChatIsShown == false then
            HCBframe:ShowChat();
        end
        HCBframe:Hide();
    end,
});