local ADDON, ns = ...;

-- =========================================================
-- Options.lua  --  el panel
--
-- Ventana propia y chica, con /nfb. No se mete en el panel de Nidhaus
-- UnitFrames a proposito: este addon no depende de aquel y tiene que poder
-- configurarse aunque NUF no este instalado.
-- =========================================================

local panel;

local function CheckBox(parent, label, x, y, get, set)
	local nm = "NFB_CB_" .. label:gsub("%W", "");
	local cb = CreateFrame("CheckButton", nm, parent, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb:SetHitRectInsets(0, -160, 0, 0);
	local txt = _G[nm .. "Text"];
	if txt then txt:SetText(label); txt:SetFontObject("GameFontHighlight"); end
	cb:SetChecked(get() and true or false);
	cb:SetScript("OnClick", function(self)
		set(self:GetChecked() == 1 or self:GetChecked() == true);
	end);
	return cb;
end

local function Build()
	if panel then return panel; end

	panel = CreateFrame("Frame", "NidhausFrameBordersPanel", UIParent);
	panel:SetWidth(300);
	panel:SetHeight(360);
	panel:SetPoint("CENTER");
	panel:SetFrameStrata("DIALOG");
	panel:SetMovable(true);
	panel:EnableMouse(true);
	panel:RegisterForDrag("LeftButton");
	panel:SetScript("OnDragStart", function(self) self:StartMoving(); end);
	panel:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing(); end);
	panel:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	});
	panel:Hide();

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	title:SetPoint("TOP", 0, -18);
	title:SetText("Frame Borders");

	local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton");
	close:SetPoint("TOPRIGHT", -6, -6);

	local y = -48;

	CheckBox(panel, "Prender", 22, y,
		function() return ns.Get("enabled"); end,
		function(v) ns.Set("enabled", v); end);
	y = y - 30;

	CheckBox(panel, "Sombra exterior", 22, y,
		function() return ns.Get("shadow"); end,
		function(v) ns.Set("shadow", v); end);
	y = y - 34;

	local hdr = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	hdr:SetPoint("TOPLEFT", 24, y);
	hdr:SetText("|cff888888Donde:|r");
	y = y - 22;

	for _, g in ipairs(ns.GROUPS) do
		local key = g.key;
		CheckBox(panel, g.label, 34, y,
			function() return ns.Get(key) ~= false; end,
			function(v) ns.Set(key, v); end);
		y = y - 26;
	end

	y = y - 12;
	local fhdr = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	fhdr:SetPoint("TOPLEFT", 24, y);
	fhdr:SetText("|cff888888Letra de los botones:|r");
	y = y - 22;

	-- Casillas excluyentes. La primera es el apagado: sin ella no habria
	-- forma de volver a la letra de Blizzard.
	local fontBoxes = {};
	local function Refresh()
		local cur = tonumber(ns.Get("font")) or 1;
		for _, b in ipairs(fontBoxes) do b:SetChecked(b.value == cur); end
	end

	for i, f in ipairs(ns.FONTS) do
		local nm = "NFB_Font_" .. i;
		local cb = CreateFrame("CheckButton", nm, panel, "InterfaceOptionsCheckButtonTemplate");
		cb:SetPoint("TOPLEFT", 34, y);
		cb:SetHitRectInsets(0, -160, 0, 0);
		local txt = _G[nm .. "Text"];
		if txt then txt:SetText(f.name); txt:SetFontObject("GameFontHighlight"); end
		cb.value = i;
		cb:SetScript("OnClick", function(self)
			ns.Set("font", self.value);
			Refresh();
		end);
		fontBoxes[#fontBoxes + 1] = cb;
		y = y - 26;
	end
	Refresh();

	panel:SetHeight(math.abs(y) + 40);
	return panel;
end

function ns.TogglePanel()
	local p = Build();
	if p:IsShown() then p:Hide() else p:Show() end
end
