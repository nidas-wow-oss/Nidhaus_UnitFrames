

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hidden = false;
local countdown = -1;


local EyeFromCountdown;


local ACDFrame = CreateFrame("Frame", "NUF_ACDFrame", UIParent)
function ACDFrame:OnEvent(event, ...)
	self[event](self, ...)
end
ACDFrame:SetScript("OnEvent", ACDFrame.OnEvent)
ACDFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")

ACDFrame:Hide()

local ACDNumFrame = CreateFrame("Frame", "ACDNumFrame", UIParent)

if K.RegisterScalable then K.RegisterScalable("ArenaCountDown", ACDNumFrame, 1.0); end
ACDNumFrame:SetHeight(256)
ACDNumFrame:SetWidth(256)
ACDNumFrame:SetPoint("CENTER", 0, 128)
ACDNumFrame:Show()

local ACDNumTens = ACDNumFrame:CreateTexture("ACDNumTens", "HIGH")
ACDNumTens:SetWidth(256)
ACDNumTens:SetHeight(128)
ACDNumTens:SetPoint("CENTER", ACDNumFrame, "CENTER", -48, 0)

local ACDNumOnes = ACDNumFrame:CreateTexture("ACDNumOnes", "HIGH")
ACDNumOnes:SetWidth(256)
ACDNumOnes:SetHeight(128)
ACDNumOnes:SetPoint("CENTER", ACDNumFrame, "CENTER", 48, 0)

local ACDNumOne = ACDNumFrame:CreateTexture("ACDNumOne", "HIGH")
ACDNumOne:SetWidth(256)
ACDNumOne:SetHeight(128)
ACDNumOne:SetPoint("CENTER", ACDNumFrame, "CENTER", 0, 0)

ACDFrame:SetScript("OnUpdate", function(self, elapse )
	if (countdown > 0) then
		hidden = false;

		if ((math.floor(countdown) ~= math.floor(countdown - elapse)) and (math.floor(countdown - elapse) >= 0)) then
			local str = tostring(math.floor(countdown - elapse));

			if (math.floor(countdown - elapse) == 0) then

				ACDNumTens:Hide();
				ACDNumOnes:Hide();
				ACDNumOne:Show();
				ACDNumOne:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\fight");
				ACDNumFrame:SetScale(1.0);
				if EyeFromCountdown then EyeFromCountdown(); end
			elseif (string.len(str) == 2) then

				ACDNumTens:Show();
				ACDNumOnes:Show();

				ACDNumTens:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\".. string.sub(str,0,1));
				ACDNumOnes:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\".. string.sub(str,2,2));
				ACDNumFrame:SetScale(0.7)
			elseif (string.len(str) == 1) then

				ACDNumOne:Show();
				ACDNumOne:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\".. string.sub(str,0,1));
				ACDNumOnes:Hide();
				ACDNumTens:Hide();
				ACDNumFrame:SetScale(1.0)
			end
		end
		countdown = countdown - elapse;
	elseif (not hidden) then
		hidden = true;
		ACDNumTens:Hide();
		ACDNumOnes:Hide();
		ACDNumOne:Hide();

		ACDFrame:Hide();
	end

end)


local function StartCountdown(seconds)
	countdown = seconds;
	hidden = false;
	ACDFrame:Show();
end

function ACDFrame:CHAT_MSG_BG_SYSTEM_NEUTRAL(arg1)
	if not C.ArenaCountDown then return; end





	if (string.find(arg1, "One minute until the Arena battle begins")) then
		StartCountdown(61);
		return;
	end
	if (string.find(arg1, "Thirty seconds until the Arena battle begins")) then
		StartCountdown(31);
		return;
	end
	if (string.find(arg1, "Fifteen seconds until the Arena battle begins")) then
		StartCountdown(16);
		return;
	end


	if (string.find(arg1, "60 secon")) or (string.find(arg1, "60 seg")) then
		StartCountdown(61);
		return;
	end
	if (string.find(arg1, "30 secon")) or (string.find(arg1, "30 seg")) then
		StartCountdown(31);
		return;
	end
	if (string.find(arg1, "15 secon")) or (string.find(arg1, "15 seg")) then
		StartCountdown(16);
		return;
	end


	if (string.find(arg1, "Un minuto")) or (string.find(arg1, "un minuto")) then
		StartCountdown(61);
		return;
	end
	if (string.find(arg1, "Treinta segundos")) or (string.find(arg1, "treinta segundos")) then
		StartCountdown(31);
		return;
	end
	if (string.find(arg1, "Quince segundos")) or (string.find(arg1, "quince segundos")) then
		StartCountdown(16);
		return;
	end
end

















local EYE_SPELL_ID = 34709;
local EYE_TIME     = 90;
local EYE_ICON_FALLBACK = "Interface\\Icons\\Spell_Shadow_EvilEye";
local _, _, eyeIconTex = GetSpellInfo(EYE_SPELL_ID);

local timer = 0
local total = 0
local eyeTest = false

local frame = CreateFrame("Frame", "NUF_ShadowSightTimer", UIParent)
frame:SetHeight(32)
frame:SetWidth(92)
frame:SetPoint("TOP", UIParent, "TOP", 0, -30)
frame:Hide()

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetWidth(30)
frame.icon:SetHeight(30)
frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
frame.icon:SetTexture(eyeIconTex or EYE_ICON_FALLBACK)
frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

frame.text = frame:CreateFontString(nil, "OVERLAY", "PVPInfoTextFont")
frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 6, 0)
frame.text:SetJustifyH("LEFT")

local function EyeEnabled()
	return C.ShadowSightTimer ~= false;
end

local function InArena()
	local _, instanceType = IsInInstance();
	return instanceType == "arena";
end

local function StopEye()
	frame:SetScript("OnUpdate", nil)
	frame:Hide()
	eyeTest = false
end

local function OnUpdate(self, elapsed)
	total = total + elapsed
	if total >= 1.0 then
		total = total - 1
		timer = timer - 1
		frame.text:SetText(timer)
		if timer <= 0 then
			StopEye()
		end
	end
end

local function StartEye(seconds)
	timer = seconds
	total = 0
	frame.text:SetText(timer)
	frame:Show()
	frame:SetScript("OnUpdate", OnUpdate)
end



EyeFromCountdown = function()
	if not EyeEnabled() or not InArena() then return; end
	if frame:IsShown() and not eyeTest then return; end
	eyeTest = false
	StartEye(EYE_TIME)
end

local function EventHandler(self, event, msg)
	if event == "PLAYER_ENTERING_WORLD" then
		StopEye()
		return
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		if not eyeTest and not InArena() then StopEye() end
		return
	elseif event == "UPDATE_BATTLEFIELD_STATUS" then

		if frame:IsShown() and not eyeTest and GetBattlefieldWinner and GetBattlefieldWinner() then
			StopEye()
		end
		return
	end


	if not EyeEnabled() or type(msg) ~= "string" or not InArena() then return; end
	if string.find(msg, "has begun") or string.find(msg, "ha comenzado") then
		eyeTest = false
		StartEye(EYE_TIME)
	end
end

frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
frame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:SetScript("OnEvent", EventHandler)



function K.ApplyShadowSightSetting()
	if not EyeEnabled() then StopEye(); end
end


function K_TestShadowSight()
	StartEye(30)
	eyeTest = true
end
