local AddOnName, ns = ...;
local K, C, L = unpack(ns);








local HISTORY_LIMIT = 128;

local tinsert, tremove, floor = table.insert, table.remove, math.floor;




local scroll  = CreateFrame("ScrollFrame", "NUF_ChatCopyScroll", UIParent);
local slider  = CreateFrame("Slider", "NUF_ChatCopyScrollBar", scroll);
local editbox = CreateFrame("EditBox", "NUF_ChatCopyBox", scroll);

scroll:SetScrollChild(editbox);
scroll:SetFrameStrata("DIALOG");
scroll:Hide();
scroll:EnableMouseWheel(1);

scroll.bg = scroll:CreateTexture(nil, "BACKGROUND");
scroll.bg:SetTexture(0, 0, 0, 1);
scroll.bg:SetPoint("TOPLEFT", -3, 3);
scroll.bg:SetPoint("BOTTOMRIGHT", 3, -3);



















local function TargetScroll(self, yrange)
	local off = self.nufOffset or 0;
	if off <= 0 then return yrange; end
	local v = yrange - off * (self.nufLineH or 15);
	if v < 0 then return 0; end
	if v > yrange then return yrange; end
	return v;
end

scroll:SetScript("OnScrollRangeChanged", function(self, xrange, yrange)
	yrange = yrange or self:GetVerticalScrollRange();
	local value = slider:GetValue();
	slider:SetMinMaxValues(0, yrange);




	if self.nufPlaceScroll then
		self.nufPlaceScroll = nil;
		local target = TargetScroll(self, yrange);
		slider:SetValue(target);
		self:SetVerticalScroll(target);
	else
		slider:SetValue(value > yrange and yrange or value);
	end

	local total   = self:GetHeight() + yrange;
	local visible = self:GetHeight();
	local ratio   = visible / total;
	if ratio < 1 then
		slider.thumb:SetHeight(floor(visible * ratio));
		slider:Show();
	else
		slider:Hide();
	end
end);

scroll:SetScript("OnMouseWheel", function(self, delta)
	slider:SetValue(slider:GetValue() - delta * slider:GetHeight() / 2);
end);

scroll:SetScript("OnShow", function(self)
	local chatFrame = _G["ChatFrame" .. (self:GetID() or 1)];
	if not chatFrame then self:Hide(); return; end

	self:ClearAllPoints();
	self:SetAllPoints(chatFrame);

	editbox:SetFont(chatFrame:GetFont());
	editbox:SetWidth(chatFrame:GetWidth());
	editbox:SetHeight(chatFrame:GetHeight());
	editbox:SetText("");



	local offset = 0;
	if chatFrame.GetScrollOffset then
		offset = chatFrame:GetScrollOffset() or 0;
	end
	local _, fontH = chatFrame:GetFont();
	self.nufOffset = offset;
	self.nufLineH  = (fontH or 14) + 1;

	self.nufPlaceScroll = true;
	self:SetVerticalScroll(0);

	local history = chatFrame.NUFHistory;
	if history then
		for i = #history, 1, -1 do
			editbox:Insert(history[i] .. (i ~= 1 and "\n" or ""));
		end
	end

	editbox.cached = editbox:GetText();
	editbox:SetCursorPosition(editbox:GetNumLetters() or 0);



	self:UpdateScrollChildRect();
	local yrange = self:GetVerticalScrollRange() or 0;
	if yrange > 0 and self.nufPlaceScroll then
		self.nufPlaceScroll = nil;
		local target = TargetScroll(self, yrange);
		slider:SetMinMaxValues(0, yrange);
		slider:SetValue(target);
		self:SetVerticalScroll(target);
	end

	editbox:SetScript("OnChar", function(self) self:SetText(self.cached or ""); end);
end);

scroll:SetScript("OnHide", function()
	editbox:SetText("");
	editbox:SetScript("OnChar", nil);
end);


slider:Hide();
slider:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0);
slider:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 1);
slider:SetWidth(10);
slider:SetOrientation("VERTICAL");
slider:SetMinMaxValues(0, 0);
slider:SetValueStep(1);
slider:SetValue(0);
slider:SetAlpha(0.6);
slider:SetBackdrop({
	bgFile   = "Interface\\BUTTONS\\WHITE8X8",
	edgeFile = "Interface\\BUTTONS\\WHITE8X8",
	tile = false, tileSize = 0, edgeSize = 1,
	insets = { left = -1, right = -1, top = -1, bottom = -1 },
});
slider:SetBackdropColor(0, 0, 0, 0.7);
slider:SetBackdropBorderColor(0.2, 0.2, 0.2, 1);
slider:SetThumbTexture("");
slider.thumb = slider:GetThumbTexture();
slider.thumb:SetHeight(50);
slider.thumb:SetTexture(1, 0.82, 0, 1);
slider:SetScript("OnValueChanged", function(self, value)
	scroll:SetVerticalScroll(value);
end);


editbox:SetTextColor(1, 1, 1, 1);
editbox:SetFontObject(ChatFontNormal);
editbox:SetAutoFocus(true);
editbox:SetMultiLine(true);
editbox:SetMaxLetters(0);
editbox:SetScript("OnEscapePressed", function(self)
	self:ClearFocus();
	scroll:Hide();
end);















local function HookChatFrame(index)
	local chatFrame = _G["ChatFrame" .. index];
	if not chatFrame then return; end

	if not chatFrame.NUFHistory then
		chatFrame.NUFHistory = {};

		hooksecurefunc(chatFrame, "AddMessage", function(self, msg, r, g, b)



			if not C.ChatCopyEnabled then return; end
			if type(msg) ~= "string" then return; end
			local history = self.NUFHistory;
			if not history then return; end

			if r and g and b then
				local col = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255);
				tinsert(history, 1, col .. string.gsub(msg, "|r", col));
			else
				tinsert(history, 1, "|cffffffff" .. msg);
			end

			if history[HISTORY_LIMIT + 1] then
				tremove(history, HISTORY_LIMIT + 1);
			end
		end);
	end

	local tab = _G["ChatFrame" .. index .. "Tab"];
	if not tab or tab.NUFCopyHooked then return; end
	tab.NUFCopyHooked = true;

	tab:HookScript("OnDoubleClick", function(self, button)
		if button ~= "LeftButton" then return; end
		if not C.ChatCopyEnabled then return; end
		if scroll:IsShown() then
			scroll:Hide();
		else
			scroll:SetID(self:GetID());
			scroll:Show();
		end
	end);

	tab:HookScript("OnClick", function(self, button)
		if button ~= "LeftButton" then return; end
		if not scroll:IsShown() then return; end
		if scroll:GetID() == self:GetID() then return; end
		scroll:Hide();
	end);
end











local function HookAllChatFrames()
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		HookChatFrame(i);
	end
	if type(CHAT_FRAMES) == "table" then
		for _, name in ipairs(CHAT_FRAMES) do
			local index = tonumber(string.match(name or "", "^ChatFrame(%d+)$"));
			if index then HookChatFrame(index); end
		end
	end
end

HookAllChatFrames();





















local rehook = CreateFrame("Frame");
rehook:Hide();
rehook:SetScript("OnUpdate", function(self)
	self:Hide();
	HookAllChatFrames();
end);

local function HookSoon()



	HookAllChatFrames();
	rehook:Show();
end

for _, fname in ipairs({ "FCF_OpenTemporaryWindow", "FCF_OpenNewWindow",
	"FCF_DockFrame", "FCF_SetWindowName", "FCF_RestoreChatsToFrame" }) do
	if type(_G[fname]) == "function" then
		hooksecurefunc(fname, HookSoon);
	end
end



local rehookLogin = CreateFrame("Frame");
rehookLogin:RegisterEvent("PLAYER_ENTERING_WORLD");
rehookLogin:SetScript("OnEvent", HookSoon);







if type(FCF_SetTemporaryWindowType) == "function" then
	hooksecurefunc("FCF_SetTemporaryWindowType", function(chatFrame, chatType, chatTarget)
		if not chatFrame then return; end
		local key = tostring(chatType) .. "/" .. tostring(chatTarget);
		if chatFrame.NUFCopyTarget == key then return; end
		chatFrame.NUFCopyTarget = key;
		if chatFrame.NUFHistory then wipe(chatFrame.NUFHistory); end
	end);
end




if K.RegisterConfigEvent then
	local lastState = C.ChatCopyEnabled;
	K.RegisterConfigEvent("CONFIG_CHANGED", function()
		local now = C.ChatCopyEnabled and true or false;
		if now == lastState then return; end
		lastState = now;

		if not now then
			if scroll:IsShown() then scroll:Hide(); end
			for i = 1, (NUM_CHAT_WINDOWS or 10) + 20 do
				local cf = _G["ChatFrame" .. i];
				if cf and cf.NUFHistory then wipe(cf.NUFHistory); end
			end
		end
	end);
end

SLASH_NUFCHATCOPY1 = "/nufcopy";
SlashCmdList["NUFCHATCOPY"] = function()
	if not C.ChatCopyEnabled then
		print("|cff4FC3F7NUF:|r " .. (L["CHATCOPY_DISABLED"] or "Chat copy is disabled in the options."));
		return;
	end
	if scroll:IsShown() then
		scroll:Hide();
	else
		scroll:SetID((SELECTED_DOCK_FRAME and SELECTED_DOCK_FRAME:GetID()) or 1);
		scroll:Show();
	end
end
