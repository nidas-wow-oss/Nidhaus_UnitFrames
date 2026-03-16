-- /script countdown = 60

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hidden = false;
local countdown = -1;
-- local eyesTime = -1;

local ACDFrame = CreateFrame("Frame", "NUF_ACDFrame", UIParent)
function ACDFrame:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	self[event](self, ...) -- route event parameters to LoseControl:event methods
end
ACDFrame:SetScript("OnEvent", ACDFrame.OnEvent)
ACDFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
-- FIX PERF: Start hidden — OnUpdate only runs when countdown is active
ACDFrame:Hide()

local ACDNumFrame = CreateFrame("Frame", "ACDNumFrame", UIParent)
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
				-- FIX: Show "Fight!" texture instead of hiding
				ACDNumTens:Hide();
				ACDNumOnes:Hide();
				ACDNumOne:Show();
				ACDNumOne:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\fight");
				ACDNumFrame:SetScale(1.0);
			elseif (string.len(str) == 2) then
				-- Display has 2 digits
				ACDNumTens:Show();
				ACDNumOnes:Show();

				ACDNumTens:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\".. string.sub(str,0,1));
				ACDNumOnes:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\".. string.sub(str,2,2));
				ACDNumFrame:SetScale(0.7)
			elseif (string.len(str) == 1) then
				-- Display has 1 digit
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
		-- FIX PERF: Stop OnUpdate — no reason to keep running
		ACDFrame:Hide();
	end

end)

-- FIX PERF: Helper to set countdown AND activate OnUpdate
local function StartCountdown(seconds)
	countdown = seconds;
	hidden = false;
	ACDFrame:Show(); -- activates OnUpdate
end

function ACDFrame:CHAT_MSG_BG_SYSTEM_NEUTRAL(arg1)
	if not C.ArenaCountDown then return; end
	-- FIX: Removed redundant "if (event == ...)" check — the OnEvent router
	-- already dispatches by event name. The global "event" variable doesn't
	-- exist in this scope on some servers, which caused the ENTIRE handler to fail.

	-- English patterns
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

	-- FIX: Numeric patterns (some servers use "60 seconds", "30 seconds", etc.)
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

	-- FIX: Spanish patterns
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

-- let's add eyes (shadow sight)

local timer = 0
local total = 0
local frame = CreateFrame("Frame", "NUF_ShadowSightTimer")
frame:ClearAllPoints()
frame:SetHeight(50)
frame:SetWidth(50)
frame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
frame.text = frame:CreateFontString(nil, "BACKGROUND", "PVPInfoTextFont")
frame.text:SetAllPoints()
frame:SetPoint("TOP", UIParent, "TOP", 0, -30)
frame:SetAlpha(1)

local function OnUpdate(self,elapsed)
  total = total + elapsed
  if (total >= 1.0) then
    total = total - 1
    timer = timer - 1
    frame.text:SetText(timer)
    if(timer == 0) then
      frame:Hide()
      frame:SetScript("OnUpdate", nil)
    end
  end

end

local function EventHandler(self, event, ...)
		if not C.ArenaCountDown then return; end
		-- FIX: Use varargs instead of global arg1 (unreliable on some servers)
		local msg = select(1, ...);
		if not msg then return; end
		if(string.find(msg, "Arena battle has begun"))
			or (string.find(msg, "batalla de arena ha comenzado"))
			or (string.find(msg, "battle has begun")) then
			timer = 90
			total = 0  -- FIX: Reset accumulator
			frame.text:SetText(timer)
			frame:Show()
			frame:SetScript("OnUpdate", OnUpdate)
		end
end
frame:SetScript("OnEvent", EventHandler)