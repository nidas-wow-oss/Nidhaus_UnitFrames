local AddOnName, ns = ...;
local K, C, L = unpack(ns);


















local format = format or string.format;
local max = math.max;
local hooksecurefunc = hooksecurefunc;

local isInitialized = false;
local displayTimers = false;


local countDownText;
local countDownTargetText;




local function CreateTimerTexts()
	if countDownText then return; end


	if CastingBarFrame then
		countDownText = CastingBarFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		countDownText:SetPoint("TOPRIGHT", 2, 5);
		countDownText:SetPoint("BOTTOMLEFT", CastingBarFrame, "BOTTOMRIGHT", -56, 2);
		CastingBarFrame.nufCountDownText = countDownText;
		CastingBarFrame.nufCtElapsed = 0;
	end


	if TargetFrameSpellBar then
		countDownTargetText = TargetFrameSpellBar:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		countDownTargetText:SetPoint("TOPRIGHT", 0, 5);
		countDownTargetText:SetPoint("BOTTOMLEFT", TargetFrameSpellBar, "BOTTOMRIGHT", -60, 0);
		TargetFrameSpellBar.nufCountDownText = countDownTargetText;
		TargetFrameSpellBar.nufCtElapsed = 0;
	end
end








local function CastTimer_OnUpdate(self, secondsElapsed)

	local cd = self.nufCountDownText;
	if not cd then return; end
	if not displayTimers then return; end

	local elapsed = (self.nufCtElapsed or 0) - (secondsElapsed or 0);
	if elapsed < 0 then
		if self.casting then

			cd:SetText(format("(%.1fs)", max((self.maxValue or 0) - (self.value or 0), 0)));
		elseif self.channeling then

			cd:SetText(format("(%.1fs)", max(self.value or 0, 0)));
		else
			cd:SetText("");
		end
		self.nufCtElapsed = 0.1;
	else
		self.nufCtElapsed = elapsed;
	end
end





local function ApplyCastingTimers(enable)
	displayTimers = enable and true or false;

	local castingBarText = CastingBarFrameText;
	local castingBarTargetText = TargetFrameSpellBarText;

	if castingBarText then castingBarText:ClearAllPoints(); end
	if castingBarTargetText then castingBarTargetText:ClearAllPoints(); end

	if displayTimers then
		if countDownText then countDownText:Show(); end
		if countDownTargetText then countDownTargetText:Show(); end












		local custom = C and C.CastBarPWEnabled;

		if custom then
			if countDownText then
				countDownText:ClearAllPoints();
				countDownText:SetPoint("LEFT", CastingBarFrame, "RIGHT", 4, 0);
				countDownText:SetJustifyH("LEFT");
			end
			if castingBarText then
				castingBarText:SetWidth(0);
				castingBarText:SetPoint("TOP", 0, 5);
			end
		else
			if countDownText then
				countDownText:ClearAllPoints();
				countDownText:SetPoint("TOPRIGHT", 2, 5);
				countDownText:SetPoint("BOTTOMLEFT", CastingBarFrame, "BOTTOMRIGHT", -56, 2);
				countDownText:SetJustifyH("CENTER");
			end




			if castingBarText and countDownText then
				castingBarText:SetPoint("TOPLEFT", 0, 5);
				castingBarText:SetPoint("BOTTOMRIGHT", countDownText, "BOTTOMLEFT", -4, 0);
			end
		end

		if castingBarTargetText and countDownTargetText then
			castingBarTargetText:SetPoint("TOPLEFT", 2, 5);
			castingBarTargetText:SetPoint("BOTTOMRIGHT", countDownTargetText, "BOTTOMLEFT", -4, 0);
		end
	else
		if countDownText then
			countDownText:Hide();
			countDownText:SetText("");
		end
		if countDownTargetText then
			countDownTargetText:Hide();
			countDownTargetText:SetText("");
		end


		if castingBarText then
			castingBarText:SetWidth(0);
			castingBarText:SetPoint("TOP", 0, 5);
		end
		if castingBarTargetText then
			castingBarTargetText:SetWidth(0);
			castingBarTargetText:SetPoint("TOP", 0, 5);
		end
	end
end


function K.ToggleCastingTimers(enable)
	if not isInitialized then return; end
	ApplyCastingTimers(enable);
end




function K.RefreshCastingTimerLayout()
	if not isInitialized then return; end
	ApplyCastingTimers(displayTimers);
end




local function InitializeCastingTimers()
	if isInitialized then return; end


	if not CastingBarFrame then return; end

	CreateTimerTexts();


	hooksecurefunc("CastingBarFrame_OnUpdate", CastTimer_OnUpdate);

	isInitialized = true;


	ApplyCastingTimers(C.CastingTimers);
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	InitializeCastingTimers();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized then
		ApplyCastingTimers(C.CastingTimers);
	end
end);
