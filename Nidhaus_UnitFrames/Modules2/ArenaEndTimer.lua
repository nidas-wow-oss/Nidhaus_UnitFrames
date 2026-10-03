local AddOnName, ns = ...;
local K, C, L = unpack(ns);











local DURATION_SYSTEM = 1800;
local DURATION_EMOTE  = 2700;
local KEY             = "ArenaEnd";




local function IsArenaStartMessage(msg)
	if not msg or msg == "" then return false; end
	return string.find(msg, "battle in the arena has begun")
		or string.find(msg, "Arena battle has begun")
		or string.find(msg, "arena has begun")
		or string.find(msg, "batalla de arena ha comenzado")
		or string.find(msg, "batalla en la arena ha comenzado")
		or string.find(msg, "combate en la arena ha comenzado");
end

local function FormatTime(seconds)
	if seconds < 0 then seconds = 0; end
	local minutes = math.floor(seconds / 60);
	local secs    = math.floor(seconds % 60);
	return string.format("%02d:%02d", minutes, secs);
end




local frame = CreateFrame("Frame", "NUF_ArenaEndTimer", UIParent);

if K.RegisterScalable then K.RegisterScalable("ArenaEndTimer", frame, 1.0); end
frame:SetSize(90, 20);
frame:Hide();

frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0);


frame.text:SetTextHeight(10);
frame.text:SetText("");




local function SavePosition()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.timerPos then NidhausUnitFramesDB.timerPos = {}; end
	local point, _, relativePoint, x, y = frame:GetPoint();







	if not point then
		NidhausUnitFramesDB.timerPos[KEY] = nil;
		return;
	end
	NidhausUnitFramesDB.timerPos[KEY] = {
		point = point, relativePoint = relativePoint, x = x, y = y,
	};
end

local function RestorePosition()
	local pos = NidhausUnitFramesDB and NidhausUnitFramesDB.timerPos and NidhausUnitFramesDB.timerPos[KEY];
	frame:ClearAllPoints();


	if pos and pos.point then
		frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y);
	else







		frame:SetPoint("TOP", UIParent, "TOP", 24, -72);
	end
end


function K.ResetArenaEndTimerPosition()
	if NidhausUnitFramesDB and NidhausUnitFramesDB.timerPos then
		NidhausUnitFramesDB.timerPos[KEY] = nil;
	end
	RestorePosition();
end

frame:SetMovable(true);
frame:EnableMouse(true);
frame:SetClampedToScreen(true);
frame:RegisterForDrag("LeftButton");
frame:SetScript("OnDragStart", function(self)
	if IsAltKeyDown() then self:StartMoving(); end
end);
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing();
	SavePosition();
end);




local endTime  = 0;
local updAcc   = 0;

local function Stop()
	frame:Hide();
	frame:SetScript("OnUpdate", nil);
	frame.text:SetText("");
	endTime = 0;
	updAcc  = 0;
end

local function OnUpdate(self, elapsed)
	updAcc = updAcc + elapsed;
	if updAcc < 0.2 then return; end
	updAcc = 0;

	local remaining = endTime - GetTime();
	if remaining <= 0 then
		Stop();
		return;
	end

	local label = (L["ARENA_END_PREFIX"] or "Arena: ");
	if remaining <= 60 then
		self.text:SetText("|cffFF4444" .. label .. FormatTime(remaining) .. "|r");
	elseif remaining <= 300 then
		self.text:SetText("|cffFFAA00" .. label .. FormatTime(remaining) .. "|r");
	else
		self.text:SetText(label .. FormatTime(remaining));
	end
end

local function Start(duration)
	local newEnd = GetTime() + duration;

	if frame:IsShown() and newEnd <= endTime then return; end
	endTime = newEnd;
	RestorePosition();
	frame:Show();
	updAcc = 1;
	frame:SetScript("OnUpdate", OnUpdate);
end

K.ArenaTimerTests = K.ArenaTimerTests or {};
K.ArenaTimerTests[KEY] = function()
	if frame:IsShown() then Stop(); else Start(DURATION_EMOTE); end
end;

local events = CreateFrame("Frame");
events:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL");
events:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if not IsActiveBattlefieldArena() then Stop(); end
		return;
	end

	if not C.ArenaEndTimer then return; end

	local msg = select(1, ...);
	if not IsArenaStartMessage(msg) then return; end

	if event == "CHAT_MSG_RAID_BOSS_EMOTE" then
		Start(DURATION_EMOTE);
	else
		Start(DURATION_SYSTEM);
	end
end);

RestorePosition();





SLASH_NUFARENATIMERS1 = "/nuftimers";
SlashCmdList["NUFARENATIMERS"] = function()
	if not K.ArenaTimerTests then return; end
	for _, fn in pairs(K.ArenaTimerTests) do
		local ok, err = pcall(fn);
		if not ok then print("|cffFF0000NUF:|r " .. tostring(err)); end
	end
	print("|cff4FC3F7NUF:|r " .. (L["TIMERS_TEST_HINT"] or "Arena timers test mode toggled. Alt + drag to move them."));
end
