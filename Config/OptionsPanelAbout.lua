local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- OptionsPanelAbout.lua
-- Tab 6: About
-- Delegado desde OptionsPanel.lua
-- =========================================================

function K.PopulateAboutTab(panel)
	-- Logo / Nombre grande centrado
	local aboutName = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge");
	aboutName:SetPoint("TOP", 0, -20);
	aboutName:SetText(L["ABOUT_ADDON_NAME"]);

	-- Version debajo del nombre
	local aboutVersion = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	aboutVersion:SetPoint("TOP", aboutName, "BOTTOM", 0, -6);
	aboutVersion:SetText(L["ABOUT_VERSION"]);

	-- Descripcion PVP
	local aboutDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	aboutDesc:SetPoint("TOP", aboutVersion, "BOTTOM", 0, -14);
	aboutDesc:SetWidth(500);
	aboutDesc:SetJustifyH("CENTER");
	aboutDesc:SetText(L["ABOUT_DESCRIPTION"]);

	-- Separador 1
	local aboutSep1 = panel:CreateTexture(nil, "ARTWORK");
	aboutSep1:SetTexture(1, 1, 1, 0.15);
	aboutSep1:SetPoint("TOP", aboutDesc, "BOTTOM", 0, -14);
	aboutSep1:SetSize(400, 1);

	-- Slash Commands header
	local cmdHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	cmdHeader:SetPoint("TOP", aboutSep1, "BOTTOM", 0, -14);
	cmdHeader:SetText(L["ABOUT_COMMANDS_HEADER"]);

	local cmds = {
		L["ABOUT_CMD_OPTIONS"],
		L["ABOUT_CMD_CONFIG"],
		L["ABOUT_CMD_ARENA"],
		L["ABOUT_CMD_BOSS"],
		L["ABOUT_CMD_RESET"],
	};

	local prevCmd = cmdHeader;
	for _, cmdText in ipairs(cmds) do
		local cmdLine = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		cmdLine:SetPoint("TOP", prevCmd, "BOTTOM", 0, -4);
		cmdLine:SetText(cmdText);
		prevCmd = cmdLine;
	end

	-- Separador 2
	local aboutSep2 = panel:CreateTexture(nil, "ARTWORK");
	aboutSep2:SetTexture(1, 1, 1, 0.15);
	aboutSep2:SetPoint("TOP", prevCmd, "BOTTOM", 0, -14);
	aboutSep2:SetSize(400, 1);

	-- ── GitHub copiable ──────────────────────────────
	local githubLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	githubLabel:SetPoint("TOP", aboutSep2, "BOTTOM", 0, -14);
	githubLabel:SetText(L["ABOUT_GITHUB_LABEL"]);

	local githubBoxBorder = CreateFrame("Frame", nil, panel);
	githubBoxBorder:SetSize(300, 28);
	githubBoxBorder:SetPoint("TOP", githubLabel, "BOTTOM", 0, -8);
	githubBoxBorder:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile     = true,
		tileSize = 16,
		edgeSize = 14,
		insets   = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	githubBoxBorder:SetBackdropColor(0, 0, 0, 0.8);
	githubBoxBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8);

	local githubBox = CreateFrame("EditBox", nil, githubBoxBorder);
	githubBox:SetPoint("TOPLEFT", 6, -6);
	githubBox:SetPoint("BOTTOMRIGHT", -6, 6);
	githubBox:SetFontObject("GameFontHighlightSmall");
	githubBox:SetAutoFocus(false);
	githubBox:SetText(L["ABOUT_GITHUB_LINK"]);
	githubBox:SetCursorPosition(0);
	githubBox:SetScript("OnEditFocusGained", function(self) self:HighlightText(); end);
	githubBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0); end);
	githubBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
	githubBox:SetScript("OnTextChanged", function(self, userInput)
		if userInput then self:SetText(L["ABOUT_GITHUB_LINK"]); end
	end);

	-- ── Discord copiable ─────────────────────────────
	local contactLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	contactLabel:SetPoint("TOP", githubBoxBorder, "BOTTOM", 0, -14);
	contactLabel:SetText(L["ABOUT_CONTACT_LABEL"]);

	local editBoxBorder = CreateFrame("Frame", nil, panel);
	editBoxBorder:SetSize(300, 28);
	editBoxBorder:SetPoint("TOP", contactLabel, "BOTTOM", 0, -8);
	editBoxBorder:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile     = true,
		tileSize = 16,
		edgeSize = 14,
		insets   = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	editBoxBorder:SetBackdropColor(0, 0, 0, 0.8);
	editBoxBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8);

	local linkBox = CreateFrame("EditBox", nil, editBoxBorder);
	linkBox:SetPoint("TOPLEFT", 6, -6);
	linkBox:SetPoint("BOTTOMRIGHT", -6, 6);
	linkBox:SetFontObject("GameFontHighlightSmall");
	linkBox:SetAutoFocus(false);
	linkBox:SetText(L["ABOUT_CONTACT_LINK"]);
	linkBox:SetCursorPosition(0);
	linkBox:SetScript("OnEditFocusGained", function(self) self:HighlightText(); end);
	linkBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0); end);
	linkBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
	linkBox:SetScript("OnTextChanged", function(self, userInput)
		if userInput then self:SetText(L["ABOUT_CONTACT_LINK"]); end
	end);

	local copyHint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	copyHint:SetPoint("TOP", editBoxBorder, "BOTTOM", 0, -4);
	copyHint:SetText(L["ABOUT_COPY_HINT"]);
end