-- Este archivo vive en Nidhaus_UnitFrames_Config, un addon aparte que se
-- carga SOLO cuando abris el panel (LoadOnDemand). Por eso no recibe el
-- namespace por "...", que es privado de cada addon: lo toma de la global
-- que publica el addon principal en Core/Init.lua.
local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

local mainFrame;
local currentTab  = 1;
local tabs        = {};
local tabPanels   = {};
local checkboxes  = {};
local sliders     = {};
local checkboxCount = 0;
local sliderCount   = 0;
local showArenaBtn;
local partyMode3v3Checkbox;
local lockPosCheckbox;
local dragHintText;
local partyIndivCheckbox;
local resetPosBtnRef;   -- botón "Resetear posiciones" (vive en la pestaña Frames)

-- ── Theme-aware module-level frame refs ──────────────────
local titleBoxRef;   -- saved from CreateMainFrame for ThemeManager
local tabBarRef;     -- saved from CreateTabs for ThemeManager

local tooltips = {
	-- Tab 1 (General)
	classColor          = "TIP_classColor",
	statusbarBackdrop   = "TIP_statusbarBackdrop",
	HealthPercentage    = "TIP_HealthPercentage",
	CastingTimers       = "TIP_CastingTimers",
	CastBarPWEnabled    = "TIP_CastBarPWEnabled",
	CastBarPWIcon       = "TIP_CastBarPWIcon",
	CastBarPWIconSize   = "TIP_CastBarPWIconSize",
	CastBarPWDark       = "TIP_CastBarPWDark",
	CastBarPWTarget     = "TIP_CastBarPWTarget",
	CastBarPWFocus      = "TIP_CastBarPWFocus",
	TabBinderEnabled    = "TIP_TabBinderEnabled",
	MiniBarHideBackground = "TIP_MiniBarHideBackground",
	TooltipArenaExp     = "TIP_TooltipArenaExp",
	TooltipTalents      = "TIP_TooltipTalents",
	TooltipQualityBorder = "TIP_TooltipQualityBorder",
	TooltipIcons        = "TIP_TooltipIcons",
	CastBarPWScale      = "TIP_CastBarPWScale",
	FocusSpellBarScale  = "TIP_FocusSpellBarScale",
	UnitFrameCustomTexture = "TIP_UnitFrameCustomTexture",
	ShowCurrentValueOnly = "TIP_ShowCurrentValueOnly",
	SetPositions        = "TIP_SetPositions",
	LockPositions       = "TIP_LockPositions",
	PartyIndividualMove = "TIP_PartyIndividualMove",
	PartyMode3v3        = "TIP_PartyMode3v3",
	UnifyActionBars     = "TIP_UnifyActionBars",
	-- Mudados desde Extra Options
	AutoSellGray        = "TIP_AutoSellGray",
	AutoRepair          = "TIP_AutoRepair",
	BlockDuels          = "TIP_BlockDuels",
	ChatCopyEnabled     = "TIP_ChatCopyEnabled",
	ChatClickableURLs   = "TIP_ChatClickableURLs",
	HideKeybindText     = "TIP_HideKeybindText",
	HideMacroText       = "TIP_HideMacroText",
};

-- ── Backdrop helper ───────────────────────────────────────
local function ApplyBackdrop(frame, inset)
	inset = inset or 4;
	frame:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile     = true,
		tileSize = 16,
		edgeSize = 16,
		insets   = {left=inset, right=inset, top=inset, bottom=inset},
	});
	frame:SetBackdropColor(0, 0, 0, 0.35);
	frame:SetBackdropBorderColor(0, 0, 0, 0.85);
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateMainFrame
-- ────────────────────────────────────────────────────────────────────────────
local function CreateMainFrame()
	mainFrame = CreateFrame("Frame", "NidhausUnitFramesConfigFrame", UIParent);
	-- 820 de ancho: 900 se comia media pantalla. Con la lista lateral en
	-- 140px quedan ~600 utiles de contenido, que es exactamente el ancho
	-- con el que estan armados los scrollChild.
	mainFrame:SetSize(820, 620);
	mainFrame:SetPoint("CENTER");
	mainFrame:SetFrameStrata("DIALOG");
	mainFrame:EnableMouse(true);
	mainFrame:SetMovable(true);
	mainFrame:RegisterForDrag("LeftButton");
	mainFrame:SetScript("OnDragStart", mainFrame.StartMoving);
	mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing);
	mainFrame:SetClampedToScreen(true);
	mainFrame:Hide();

	-- ── Redimensionado por la esquina inferior derecha ─────────────────────
	--
	-- Mismo mecanismo que usa AceGUI en la ventana de Threat Plates: un frame
	-- transparente en la esquina que llama a StartSizing("BOTTOMRIGHT"), con
	-- las dos rayitas diagonales dibujadas a partir de la textura del borde
	-- de tooltip. No hace falta arte nueva.
	--
	-- El tamano se guarda: si no, cada vez que abrieras el panel volveria a
	-- los 820x620 de fabrica y habria que reajustarlo.
	mainFrame:SetResizable(true);
	mainFrame:SetMinResize(640, 420);    -- por debajo de esto el contenido no cabe

	-- Techo de tamano: NUNCA mas grande que la pantalla.
	-- Con el maximo fijo de 1600x1200 que habia antes, en una pantalla mas
	-- chica la esquina de agarre terminaba fuera de la vista y ya no habia
	-- manera de volver a achicar la ventana.
	local function MaxPanelSize()
		local w = math.floor((UIParent:GetWidth()  or 1024) - 20);
		local h = math.floor((UIParent:GetHeight() or 768)  - 20);
		if w < 640 then w = 640; end
		if h < 420 then h = 420; end
		return w, h;
	end

	-- Recorta el tamano actual dentro de los limites y devuelve el resultado.
	local function ClampPanelSize()
		local maxW, maxH = MaxPanelSize();
		mainFrame:SetMaxResize(maxW, maxH);
		local w, h = mainFrame:GetWidth(), mainFrame:GetHeight();
		local nw = (w < 640) and 640 or ((w > maxW) and maxW or w);
		local nh = (h < 420) and 420 or ((h > maxH) and maxH or h);
		if nw ~= w then mainFrame:SetWidth(nw); end
		if nh ~= h then mainFrame:SetHeight(nh); end
		return nw, nh;
	end

	-- Si el marco quedo (total o parcialmente) fuera de la pantalla, se
	-- recentra. Es la unica via de rescate cuando el sizer queda inalcanzable.
	local function EnsureOnScreen()
		local sw, sh = UIParent:GetWidth(), UIParent:GetHeight();
		local l, r = mainFrame:GetLeft(), mainFrame:GetRight();
		local b, t = mainFrame:GetBottom(), mainFrame:GetTop();
		if not l or not r or not b or not t
			or l < 0 or b < 0 or r > sw or t > sh then
			mainFrame:ClearAllPoints();
			mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		end
	end

	mainFrame:SetMaxResize(MaxPanelSize());
	K.ResetOptionsPanelSize = function()
		mainFrame:ClearAllPoints();
		mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		mainFrame:SetWidth(820);
		mainFrame:SetHeight(620);
		if K.SaveConfig then
			K.SaveConfig("PanelWidth",  820);
			K.SaveConfig("PanelHeight", 620);
		end
	end

	local sizer = CreateFrame("Frame", nil, mainFrame);
	sizer:SetPoint("BOTTOMRIGHT", -2, 2);
	sizer:SetWidth(20);
	sizer:SetHeight(20);
	sizer:EnableMouse(true);
	sizer:SetFrameLevel(mainFrame:GetFrameLevel() + 10);

	local function Rayita(size, offset)
		local t = sizer:CreateTexture(nil, "OVERLAY");
		t:SetWidth(size);
		t:SetHeight(size);
		t:SetPoint("BOTTOMRIGHT", -offset, offset);
		t:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border");
		local x = 0.1 * size / 17;
		t:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5);
		return t;
	end
	Rayita(14, 4);
	Rayita(8, 4);

	-- Cierre del redimensionado. Se llama desde tres sitios distintos porque
	-- el OnMouseUp del sizer NO es fiable: si sueltas el boton con el cursor
	-- fuera de la esquina (cosa facilisima, porque al agrandar el cursor va
	-- siempre por delante del marco) ese script no llega a dispararse nunca,
	-- el marco se queda en modo sizing pegado al raton y crece solo hasta el
	-- tope. Eso es exactamente lo que paso: parpadeo, se disparo y quedo
	-- fuera de pantalla, con el sizer inalcanzable.
	local function StopSizing()
		if not mainFrame.nufSizing then return; end
		mainFrame.nufSizing = nil;
		sizer:SetScript("OnUpdate", nil);
		mainFrame:StopMovingOrSizing();
		mainFrame:SetClampedToScreen(true);
		ClampPanelSize();
		EnsureOnScreen();
		if K.SaveConfig then
			K.SaveConfig("PanelWidth",  math.floor(mainFrame:GetWidth()  + 0.5));
			K.SaveConfig("PanelHeight", math.floor(mainFrame:GetHeight() + 0.5));
		end
	end

	sizer:SetScript("OnMouseDown", function(self, button)
		if button and button ~= "LeftButton" then return; end
		if mainFrame.nufSizing then return; end
		mainFrame.nufSizing = true;
		-- El clamp a pantalla peleaba contra el redimensionado y producia el
		-- tiron hacia abajo del principio. Se apaga mientras se arrastra y se
		-- vuelve a encender al soltar.
		mainFrame:SetClampedToScreen(false);
		mainFrame:StartSizing("BOTTOMRIGHT");
		-- Red de seguridad: en cuanto el boton izquierdo deja de estar
		-- pulsado se corta, haya llegado o no el OnMouseUp.
		self:SetScript("OnUpdate", function()
			if not IsMouseButtonDown("LeftButton") then StopSizing(); end
		end);
	end);
	sizer:SetScript("OnMouseUp", StopSizing);
	sizer:SetScript("OnHide",    StopSizing);

	mainFrame:SetScript("OnShow", function()
		-- Reponer el tamano guardado. Va aca y no al crear el frame porque
		-- C todavia no esta poblado cuando se construye el panel.
		if C and C.PanelWidth and C.PanelHeight then
			mainFrame:SetWidth(C.PanelWidth);
			mainFrame:SetHeight(C.PanelHeight);
		end
		-- Recorte de seguridad: un tamano guardado invalido (mas grande que
		-- la pantalla) se corrige solo al abrir, sin tocar nada a mano.
		ClampPanelSize();
		EnsureOnScreen();
		if K._UpdateBagPackVisibility then K._UpdateBagPackVisibility(); end
		if K._UpdateHideTexVisibility then K._UpdateHideTexVisibility(); end
	end);

	mainFrame:SetScript("OnHide", StopSizing);

	-- Default backdrop (will be overridden by ThemeManager on first show)
	mainFrame:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile     = true, tileSize = 32, edgeSize = 32,
		insets   = {left=11, right=12, top=12, bottom=11},
	});

	-- ── Title Box (DarkGold y ArcaneBlue usan su backdrop; Classic lo hace transparente) ──
	local titleBox = CreateFrame("Frame", nil, mainFrame);
	titleBox:SetSize(500, 32);
	titleBox:SetPoint("TOP", mainFrame, "TOP", 0, 6);
	titleBox:SetFrameLevel(mainFrame:GetFrameLevel() + 5);
	titleBox:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
		tile     = true, tileSize = 32, edgeSize = 16,
		insets   = {left=4, right=4, top=4, bottom=4},
	});
	titleBox:SetBackdropColor(0.10, 0.10, 0.10, 1.0);

	-- Título: hijo de titleBox para heredar su FrameLevel (siempre visible)
	local title = titleBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	title:SetPoint("CENTER", titleBox, "CENTER", 0, 1);
	title:SetText(L["PANEL_TITLE"]);

	-- ── Title Header Texture (Classic solamente) ──────────────
	-- Textura gris metalica nativa de Blizzard. Se muestra encima del titleBox
	-- cuando el tema es Classic (el backdrop de titleBox queda transparente).
	local titleHeaderTex = mainFrame:CreateTexture(nil, "ARTWORK");
	titleHeaderTex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header");
	titleHeaderTex:SetWidth(500);
	titleHeaderTex:SetHeight(64);
	titleHeaderTex:SetPoint("TOP", mainFrame, "TOP", 0, 14);
	titleHeaderTex:Hide(); -- ThemeManager lo muestra solo en Classic

	-- Save references for ThemeManager
	titleBoxRef               = titleBox;
	mainFrame._titleHeaderTex = titleHeaderTex;

	-- Version label
	local version = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	version:SetPoint("TOPRIGHT", -40, -16);
	version:SetText(L["PANEL_VERSION"]);

	-- Subtitle
	local subtitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	subtitle:SetPoint("TOP", titleBox, "BOTTOM", 0, -4);
	subtitle:SetText("|cffAAAAAA" .. (L["PANEL_SUBTITLE"] or "") .. "|r");

	-- Close button
	local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton");
	closeButton:SetPoint("TOPRIGHT", -5, -5);
	closeButton:SetScript("OnClick", function() mainFrame:Hide(); end);

	-- Tab bar container
	local tabBar = CreateFrame("Frame", nil, mainFrame);
	tabBar:SetPoint("TOPLEFT",  18, -48);
	tabBar:SetPoint("TOPRIGHT", -18, -48);
	tabBar:SetHeight(32);
	ApplyBackdrop(tabBar, 4);
	tabBar:SetBackdropColor(0, 0, 0, 0.20);
	mainFrame.TabBar = tabBar;
	tabBarRef = tabBar;

	-- Bottom separator (sits above the two-row footer)
	local sepBottom = mainFrame:CreateTexture(nil, "ARTWORK");
	sepBottom:SetTexture(1, 1, 1, 0.08);
	sepBottom:SetPoint("BOTTOMLEFT",  mainFrame, "BOTTOMLEFT",  20, 78);
	sepBottom:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -20, 78);
	sepBottom:SetHeight(1);

	return mainFrame;
end

-- ────────────────────────────────────────────────────────────────────────────
-- SelectTab  (theme-aware)
-- ────────────────────────────────────────────────────────────────────────────
local function SelectTab(id)
	currentTab = id;

	for i, panel in ipairs(tabPanels) do
		if i == id then panel:Show() else panel:Hide() end
	end

	local theme = K.GetActiveTheme and K.GetActiveTheme();

	for i, tab in ipairs(tabs) do
		if i == id then
			tab.selected = true;
			if theme then
				tab:SetBackdropColor(unpack(theme.tabSelBGColor));
				tab:SetBackdropBorderColor(unpack(theme.tabSelBorderColor));
			else
				tab:SetBackdropColor(0.2, 0.2, 0.2, 0.9);
				tab:SetBackdropBorderColor(0.8, 0.7, 0.0, 0.9);
			end
			if tab.label then tab.label:SetFontObject("GameFontNormal"); end
		else
			tab.selected = false;
			if theme then
				tab:SetBackdropColor(unpack(theme.tabBGColor));
				tab:SetBackdropBorderColor(unpack(theme.tabBorderColor));
			else
				tab:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
				tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
			end
			if tab.label then tab.label:SetFontObject("GameFontHighlightSmall"); end
		end
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateTabs
-- ────────────────────────────────────────────────────────────────────────────
local function CreateTabs()
	-- 5 pestañas. "Modules" paso a llamarse "Addons", "Extra" quedo solo
	-- como Profiles, y PvP dejo de ser pestaña: ahora son dos secciones
	-- dentro de Interface (PvP + el nombre de tu clase).
	-- PESTAÑAS VISIBLES Y PESTAÑAS DE FONDO.
	--
	-- Profiles y About tienen su panel como cualquier otra pestaña, pero NO
	-- ocupan lugar en la barra de arriba: se llega a ellas desde los botones
	-- del pie. Son cosas que se abren de vez en cuando — elegir un perfil,
	-- mirar la version — y estaban comiendo el mismo espacio que Interface o
	-- Arena, que se usan todo el tiempo.
	--
	-- About ademas dejo de ser una ventana flotante aparte: es un panel mas,
	-- asi que hereda el tema y el tamaño del resto y no tapa nada.
	local tabNames = {
		L["TAB_GENERAL"], L["TAB_FRAMES"], L["TAB_ARENA"],
		L["TAB_ADDONS"] or "Addons",
		L["TAB_PROFILES"] or "Profiles",     -- 5: solo desde el pie
		L["TAB_ABOUT"] or "About",           -- 6: solo desde el pie
	};
	local HIDDEN_TABS = { [5] = true, [6] = true };

	mainFrame.numTabs    = #tabNames;
	mainFrame.selectedTab = 1;

	local visibleCount = 0;
	for i = 1, #tabNames do
		if not HIDDEN_TABS[i] then visibleCount = visibleCount + 1; end
	end

	local tabBarWidth = mainFrame.TabBar:GetWidth() or (mainFrame:GetWidth() - 36);
	local tabWidth    = tabBarWidth / visibleCount;
	local prevVisible;

	for i, name in ipairs(tabNames) do
		local tab = CreateFrame("Button", mainFrame:GetName().."Tab"..i, mainFrame.TabBar);
		tab:SetID(i);
		tab:SetSize(tabWidth, 28);

		if HIDDEN_TABS[i] then
			-- Existe (SelectTab y el ThemeManager recorren la lista entera)
			-- pero no se dibuja ni ocupa lugar en la barra.
			tab:SetPoint("BOTTOMLEFT", mainFrame.TabBar, "BOTTOMLEFT", 0, 2);
			tab:Hide();
		elseif not prevVisible then
			tab:SetPoint("BOTTOMLEFT", mainFrame.TabBar, "BOTTOMLEFT", 0, 2);
			prevVisible = tab;
		else
			tab:SetPoint("LEFT", prevVisible, "RIGHT", 0, 0);
			prevVisible = tab;
		end

		tab:SetBackdrop({
			bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile     = true, tileSize = 16, edgeSize = 12,
			insets   = {left=2, right=2, top=2, bottom=2},
		});

		local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		label:SetPoint("CENTER", 0, 0);
		label:SetText(name);
		tab.label = label;

		-- Hover scripts (theme-aware)
		tab:SetScript("OnEnter", function(self)
			if self.selected then return; end
			local theme = K.GetActiveTheme and K.GetActiveTheme();
			if theme then
				self:SetBackdropColor(unpack(theme.tabHoverBGColor));
			else
				self:SetBackdropColor(0.3, 0.3, 0.3, 0.8);
			end
		end);
		tab:SetScript("OnLeave", function(self)
			if self.selected then return; end
			local theme = K.GetActiveTheme and K.GetActiveTheme();
			if theme then
				self:SetBackdropColor(unpack(theme.tabBGColor));
				self:SetBackdropBorderColor(unpack(theme.tabBorderColor));
			else
				self:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
				self:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
			end
		end);

		-- Default (unselected) colors
		tab:SetBackdropColor(0.1, 0.1, 0.1, 0.6);
		tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
		tab.selected = false;

		tab:SetScript("OnClick", function(self) SelectTab(self:GetID()); end);
		tabs[i] = tab;

		-- Content panel
		local panel = CreateFrame("Frame", "NidhausUFTabPanel"..i, mainFrame);
		panel:SetPoint("TOPLEFT",     22,  -82);
		panel:SetPoint("BOTTOMRIGHT", -22,  88);
		ApplyBackdrop(panel, 6);
		panel:SetBackdropColor(0, 0, 0, 0.18);
		panel:SetBackdropBorderColor(0, 0, 0, 0.70);
		panel:Hide();
		tabPanels[i] = panel;
	end

	SelectTab(1);

	-- Los botones del pie necesitan poder saltar a las pestañas de fondo.
	K.SelectPanelTab = SelectTab;
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateCheckBox
-- ────────────────────────────────────────────────────────────────────────────
local function CreateCheckBox(parent, labelText, setting, xOffset, yOffset)
	checkboxCount = checkboxCount + 1;
	local checkboxName = "NidhausUFCheckBox"..checkboxCount;
	local check = CreateFrame("CheckButton", checkboxName, parent, "InterfaceOptionsCheckButtonTemplate");
	check:SetPoint("TOPLEFT", xOffset or 20, yOffset);
	check:SetHitRectInsets(0, 0, 0, 0);

	local label = _G[checkboxName.."Text"];
	if label then
		label:SetText(labelText);
	else
		label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		label:SetPoint("LEFT", check, "RIGHT", 2, 0);
		label:SetText(labelText);
	end

	check.setting = setting;

	local tipKey = tooltips[setting];
	if tipKey and L[tipKey] then
		check:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(labelText, 1, 1, 1);
			GameTooltip:AddLine(L[tipKey], nil, nil, nil, true);
			GameTooltip:Show();
		end);
		check:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end

	check.refresh = function(self)
		local value = C[setting];
		if type(value) == "number" then value = (value == 1); end
		self:SetChecked(value == true);
	end;
	check:refresh();

	-- Registrar el checkbox para que, si el mismo setting aparece en otra
	-- seccion (ej: Hide Macros en General y en Barras de accion), al tocar
	-- uno se refresque el otro. SaveConfig llama RefreshSettingCheckboxes.
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox(setting, check); end

	check:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked();
		local boolValue = (isChecked == 1 or isChecked == true);

		local success = K.SaveConfig(setting, boolValue);
		if not success then self:refresh(); return; end

		if setting == "UnifyActionBars" or setting == "MiniBarEnabled" then
			-- ═══════════════════════════════════════════════════════════
			-- Cambiar de modo de barras, EN CALIENTE (sin recargar).
			--
			-- Antes esto forzaba un ReloadUI. El motivo era que cada modo
			-- sacaba su propia foto del "antes" al activarse: si el otro ya
			-- habia corrido y habia revertido de forma incompleta, la foto
			-- salia contaminada y la basura se acumulaba en cada cambio.
			--
			-- Ahora hay UNA foto compartida del estado limpio de Blizzard
			-- (Core/BarBaseline.lua) y los dos modos vuelven siempre a ella
			-- antes de aplicar lo suyo. El punto de partida es identico en
			-- cada cambio, asi que ya no hay deriva y la recarga sobra.
			-- ═══════════════════════════════════════════════════════════
			local other = (setting == "UnifyActionBars") and "MiniBarEnabled" or "UnifyActionBars";

			if boolValue then
				-- Excluyentes: apagar el otro, tanto en la config como en el panel.
				K.SaveConfig(other, false);
				C[other] = false;
				for _, cb in ipairs(checkboxes) do
					if cb.setting == other then cb:SetChecked(false); end
				end
			end

			-- Apagar lo que este puesto. Cada Enable vuelve ademas a la foto
			-- compartida, asi que no depende de que estos reviertan perfecto.
			if K._minibarActive and K.DisableMiniBar then K.DisableMiniBar(); end
			if K._unifyActive and K.DisableUnifyActionBars then K.DisableUnifyActionBars(); end

			if boolValue then
				if setting == "UnifyActionBars" then
					if K.EnableUnifyActionBars then K.EnableUnifyActionBars(); end
				else
					if K.EnableMiniBar then K.EnableMiniBar(); end
				end
			else
				-- Los dos apagados: dejar las barras como las tiene Blizzard.
				if K.RestoreBarBaseline then K.RestoreBarBaseline(); end
			end

			if K._UpdateBagPackVisibility then K._UpdateBagPackVisibility(); end
			if K._UpdateHideTexVisibility then K._UpdateHideTexVisibility(); end
			-- El slider de separacion solo existe con un modo de barras
			-- puesto, y hay que reaplicarlo al entrar a ese modo.
			if K._UpdateButtonSpaceVisibility then K._UpdateButtonSpaceVisibility(); end
			if K._UpdateMiniBgVisibility then K._UpdateMiniBgVisibility(); end
			if K.ApplyActionBarButtonSpace then K.ApplyActionBarButtonSpace(); end
		elseif setting == "HideGryphons" then
			if K.ApplyGryphons then K.ApplyGryphons(); end
		elseif setting == "ShowBagPackTexture" then
			if K.ApplyBagPackTexture then K.ApplyBagPackTexture(); end
		elseif setting == "MiniBarHideBackground" then
			if K.ApplyMiniBarBackground then K.ApplyMiniBarBackground(); end
		elseif setting == "TabBinderEnabled" then
			if K.ApplyTabBinder then K.ApplyTabBinder(); end
		elseif setting == "HealthPercentage" then
			if K.ToggleHealthPercentage then K.ToggleHealthPercentage(boolValue); end
		elseif setting == "CastingTimers" then
			if K.ToggleCastingTimers then K.ToggleCastingTimers(boolValue); end
		elseif setting == "CastBarPWEnabled" then
			if K.ApplyCastBarPW then K.ApplyCastBarPW(); end
			if K._UpdateCastBarVisibility then K._UpdateCastBarVisibility(); end
			-- El contador se coloca distinto segun la barra: con la custom va
			-- fuera, a la derecha, porque dentro no cabe junto al nombre. Hay
			-- que recolocarlo aqui o se queda con el reparto de la otra.
			if K.RefreshCastingTimerLayout then K.RefreshCastingTimerLayout(); end
		elseif setting == "CastBarPWIcon" or setting == "CastBarPWDark"
			or setting == "CastBarPWTarget" or setting == "CastBarPWFocus" then
			-- Solo tienen sentido con la barra custom puesta; re-aplicar
			-- vuelve a estilar las tres barras con el valor nuevo.
			-- Los de objetivo y foco tambien pasan por aca: al destildarlos,
			-- ApplyCastBarPW les devuelve el aspecto de Blizzard en el acto.
			if K.ApplyCastBarPW then K.ApplyCastBarPW(); end
			if K._UpdateCastBarVisibility then K._UpdateCastBarVisibility(); end
		elseif setting == "ShowCurrentValueOnly" then
			-- Excluyente con el texto abreviado: si se prende esta, la otra
			-- se apaga sola (formatean el mismo texto y se pisaban).
			if boolValue and K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus") then
				if K.SetModuleEnabled then K.SetModuleEnabled("AbbreviatedStatus", false); end
				if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("AbbreviatedStatus"); end
			end
			if K._SyncStatusTextExclusive then K._SyncStatusTextExclusive(); end
			if K.ApplyHealthTextFormat then K.ApplyHealthTextFormat(); end
			-- Y limpiar los anclajes del abreviado: si venias de tenerlo
			-- activo, los textos podian quedar corridos.
			if K.InvalidateAbbrevAnchors then K.InvalidateAbbrevAnchors(); end
		elseif setting == "UnitFrameCustomTexture" then
			if K.ApplyPlayerFrameSkin then K.ApplyPlayerFrameSkin(); end
			if K.RefreshClassOutlines then K.RefreshClassOutlines(); end
			if K.ApplyTargetFrameSkin then K.ApplyTargetFrameSkin(); end
			if K._UpdateThemeVisibility then K._UpdateThemeVisibility(); end
		elseif setting == "ArenaFrameOn" then
			if showArenaBtn then
				if boolValue then showArenaBtn:Show();
				else
					showArenaBtn:Hide();
					local arenaMover = _G["NUF_ArenaMover"];
					if arenaMover and arenaMover:IsShown() then
						if K.ForceHideArenaMover then K.ForceHideArenaMover(); end
					end
				end
			end
			if K.ToggleArenaFrames then K.ToggleArenaFrames(boolValue); end
		elseif setting == "ArenaFrame_Trinkets" then
			if K.ToggleArenaTrinketsTracking then K.ToggleArenaTrinketsTracking(boolValue); end
		elseif setting == "ArenaMirrorMode" then
			if K.ToggleMirrorMode then K.ToggleMirrorMode(boolValue); end
		elseif setting == "ArenaCustomTexture" then
			if K.ToggleArenaCustomTexture then K.ToggleArenaCustomTexture(boolValue); end
		elseif setting == "SetPositions" then
			if boolValue then
				if K.InitializePartyFrames then K.InitializePartyFrames(); end
				if K.ApplyFramePositions   then K.ApplyFramePositions(); end
				if lockPosCheckbox   then lockPosCheckbox:Show(); end
				if not C.LockPositions and dragHintText then dragHintText:Show(); end
				if partyIndivCheckbox    then partyIndivCheckbox:Show(); end
				if partyMode3v3Checkbox  then partyMode3v3Checkbox:Show(); end
				if resetPosBtnRef then resetPosBtnRef:Show(); end
				if C.PartyMode3v3 and K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
				if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(true); end
				if K.RegisterPartyDragger then K.RegisterPartyDragger(); end
			else
				if C.PartyMode3v3 and K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
				if K.ApplyFramePositions then K.ApplyFramePositions(); end
				if lockPosCheckbox  then lockPosCheckbox:Hide(); end
				if dragHintText     then dragHintText:Hide(); end
				if partyIndivCheckbox   then partyIndivCheckbox:Hide(); end
				if partyMode3v3Checkbox then partyMode3v3Checkbox:Hide(); end
				if resetPosBtnRef then resetPosBtnRef:Hide(); end
				if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(false); end
			end
		elseif setting == "LockPositions" then
			-- dragHintText removed; hint is in the static alert box
		elseif setting == "PartyIndividualMove" then
			if boolValue then
				if K.ApplyIndividualPartyPositions then K.ApplyIndividualPartyPositions(); end
			else
				if K.RestorePartyToGroup then K.RestorePartyToGroup(); end
			end
		elseif setting == "PartyMode3v3" then
			if boolValue then
				if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
			else
				if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
			end
		elseif setting == "NewPartyFrame" then
			if boolValue then
				if K.EnableNewPartyFrame then K.EnableNewPartyFrame(); end
			else
				if K.DisableNewPartyFrame then K.DisableNewPartyFrame(); end
			end
		end
	end);

	table.insert(checkboxes, check);
	return check;
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateSlider
-- ────────────────────────────────────────────────────────────────────────────
local function FormatSliderValue(step, value)
	if step >= 1 then      return string.format("%d",   value);
	elseif step >= 0.1 then return string.format("%.1f", value);
	else                    return string.format("%.2f", value);
	end
end

local function CreateSlider(parent, labelText, setting, minVal, maxVal, step, xOffset, yOffset)
	sliderCount = sliderCount + 1;
	local sliderName = "NidhausUFSlider"..sliderCount;
	local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate");
	slider:SetPoint("TOPLEFT", xOffset or 20, yOffset);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	slider:SetWidth(200);
	slider.setting = setting;

	local initialValue = C[setting];
	if type(initialValue) ~= "number" then initialValue = minVal; end
	slider:SetValue(initialValue);

	local tipKey = tooltips[setting];
	if tipKey and L[tipKey] then
		slider:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(labelText, 1, 1, 1);
			GameTooltip:AddLine(L[tipKey], nil, nil, nil, true);
			GameTooltip:Show();
		end);
		slider:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end

	local sliderText = _G[sliderName.."Text"];
	local sliderLow  = _G[sliderName.."Low"];
	local sliderHigh = _G[sliderName.."High"];
	if sliderText then sliderText:SetText(labelText); end
	if sliderLow  then sliderLow:SetText(minVal); end
	if sliderHigh then sliderHigh:SetText(maxVal); end

	-- Este FontString es el valor "viejo" del slider. UIKit le pone encima
	-- una cajita editable en el mismo lugar, asi que queda marcado para que
	-- UIKit lo esconda: si no, se ven los dos numeros superpuestos.
	local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	valueText:SetPoint("TOP", slider, "BOTTOM", 0, -5);
	valueText:SetText(FormatSliderValue(step, slider:GetValue()));
	slider._nufOwnValue = valueText;

	slider:SetScript("OnValueChanged", function(self, value)
		if not value or value < minVal or value > maxVal then return; end
		valueText:SetText(FormatSliderValue(step, value));
		K.SaveConfig(setting, value);
		if setting == "ActionBarScale" then
			if K.ApplyActionBarScale then K.ApplyActionBarScale(value); end
		end
	end);

	table.insert(sliders, slider);
	return slider;
end

-- ────────────────────────────────────────────────────────────────────────────
-- DROPDOWN HELPER
-- ────────────────────────────────────────────────────────────────────────────
local dropdownCount = 0;

local function CreateDropdown(parent, labelText, setting, options, xOffset, yOffset, onChangeCallback)
	dropdownCount = dropdownCount + 1;
	local ddName = "NidhausUFDropdown"..dropdownCount;

	local container = CreateFrame("Frame", nil, parent);
	container:SetPoint("TOPLEFT", xOffset or 20, yOffset);
	container:SetSize(200, 50);

	local label = container:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	label:SetPoint("TOPLEFT", 0, 0);
	label:SetText(labelText);

	local dd = CreateFrame("Frame", ddName, container, "UIDropDownMenuTemplate");
	dd:SetPoint("TOPLEFT", -16, -16);
	UIDropDownMenu_SetWidth(dd, 140);

	local function Initialize(self, level)
		for _, opt in ipairs(options) do
			local info = UIDropDownMenu_CreateInfo();
			info.text  = opt.text;
			info.value = opt.value;
			info.func  = function(btn)
				UIDropDownMenu_SetSelectedValue(dd, btn.value);
				UIDropDownMenu_SetText(dd, btn.value);
				K.SaveConfig(setting, btn.value);
				if onChangeCallback then onChangeCallback(btn.value); end
			end;
			info.checked = (C[setting] == opt.value);
			UIDropDownMenu_AddButton(info, level);
		end
	end

	UIDropDownMenu_Initialize(dd, Initialize);
	UIDropDownMenu_SetSelectedValue(dd, C[setting] or options[1].value);
	UIDropDownMenu_SetText(dd, C[setting] or options[1].value);

	container.dropdown = dd;
	return container;
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateThemeSwitcher
-- Builds the 3 pill-buttons that sit in the footer of the panel.
-- Returns a table of {id -> button} for ThemeManager registration.
-- ────────────────────────────────────────────────────────────────────────────
local function CreateThemeSwitcher()
	if not K.GetPanelThemes then return {}; end
	local THEMES, THEME_ORDER = K.GetPanelThemes();
	if not THEMES or not THEME_ORDER then return {}; end

	local themeButtons = {};
	local btnW, btnH = 98, 24;
	local gap  = 6;
	local totalW = (#THEME_ORDER * btnW) + ((#THEME_ORDER - 1) * gap);

	-- FILA DE ARRIBA DEL PIE, PEGADA A LA DERECHA.
	--
	-- Estaba centrada y dejaba los dos costados de esa fila sin usar,
	-- mientras abajo los botones se pisaban por falta de ancho. Contra la
	-- derecha libera toda la mitad izquierda, que ahora ocupan Profiles y
	-- About.
	local container = CreateFrame("Frame", nil, mainFrame);
	container:SetSize(totalW + 14, btnH + 10);
	container:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -20, 50);

	-- Optional: dim label to the left
	local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	label:SetPoint("RIGHT", container, "LEFT", -6, 0);
	label:SetText("|cff888888" .. (L["PANEL_STYLE"] or "Style") .. "|r");

	for i, id in ipairs(THEME_ORDER) do
		local t = THEMES[id];
		local btn = CreateFrame("Button", nil, container);
		btn:SetSize(btnW, btnH);

		-- Position relative to container left edge
		btn:SetPoint("LEFT", container, "LEFT", (i-1) * (btnW + gap), 0);

		-- Backdrop for pill shape
		btn:SetBackdrop({
			bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile     = true, tileSize = 16, edgeSize = 12,
			insets   = {left=3, right=3, top=3, bottom=3},
		});
		btn:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
		btn:SetBackdropBorderColor(
			t.accent[1]*0.38, t.accent[2]*0.38, t.accent[3]*0.38, 0.55);

		-- Colored dot (small circle indicator)
		local dot = btn:CreateTexture(nil, "ARTWORK");
		dot:SetSize(8, 8);
		dot:SetPoint("LEFT", btn, "LEFT", 7, 0);
		dot:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Coin-Down");
		dot:SetVertexColor(
			t.accent[1]*0.48, t.accent[2]*0.48, t.accent[3]*0.48, 0.65);
		btn.dot = dot;

		-- Label text
		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		fs:SetPoint("LEFT", dot, "RIGHT", 5, 0);
		fs:SetText(t.label);
		fs:SetTextColor(0.48, 0.48, 0.48);
		btn.labelFS = fs;

		-- Hover
		btn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP");
			GameTooltip:SetText(t.label, t.accent[1], t.accent[2], t.accent[3]);
			GameTooltip:AddLine(L["TIP_PANEL_THEME"] or "Switch panel theme", 0.7, 0.7, 0.7);
			GameTooltip:Show();
			-- Brighten border slightly on hover
			if NidhausUnitFramesDB and NidhausUnitFramesDB.PanelTheme ~= id then
				self:SetBackdropBorderColor(
					t.accent[1]*0.65, t.accent[2]*0.65, t.accent[3]*0.65, 0.75);
			end
		end);
		btn:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
			-- Restore dim (ThemeManager will set the correct state)
			if NidhausUnitFramesDB and NidhausUnitFramesDB.PanelTheme ~= id then
				self:SetBackdropBorderColor(
					t.accent[1]*0.38, t.accent[2]*0.38, t.accent[3]*0.38, 0.55);
			end
		end);

		btn:SetScript("OnClick", function()
			K.ApplyPanelTheme(id);
		end);

		themeButtons[id] = btn;
	end

	return themeButtons;
end

-- ────────────────────────────────────────────────────────────────────────────
-- Helpers compartidos por las secciones
-- ────────────────────────────────────────────────────────────────────────────

-- Checkbox que prende/apaga un MODULO (no un setting de C).
-- Se registra para que los espejos en otras secciones se sincronicen solos.
local function CreateModuleCB(parent, label, moduleId, x, y, tip)
	if not (K.Modules and K.Modules[moduleId]) then return nil; end
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausUFCheckBox" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local labelFS = _G[cbName .. "Text"];
	if labelFS then labelFS:SetText(label); end

	cb:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled(moduleId) or false);
	if tip then
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(label, 1, 1, 1);
			GameTooltip:AddLine(tip, nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end
	cb:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SetModuleEnabled then K.SetModuleEnabled(moduleId, v); end
		if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox(moduleId); end
	end);
	if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox(moduleId, cb); end
	return cb;
end

-- Encabezado dorado de sub-bloque dentro de una seccion
local function SectionHeader(parent, text, x, y)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetText((K.UI and K.UI.Header(K.UI.Strip(text))) or text);
	return fs;
end

-- Nota gris explicativa
local function SectionNote(parent, text, x, y, width)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetWidth(width or 430);
	fs:SetJustifyH("LEFT");
	fs:SetText("|cff8EAEC9" .. (text or "") .. "|r");
	return fs;
end

-- ────────────────────────────────────────────────────────────────────────────
-- PopulateTabs
-- ────────────────────────────────────────────────────────────────────────────
local function PopulateTabs()

	-- ══════════════════════════════════════════════════════════════════
	-- PESTAÑA 1: INTERFACE
	-- Lista lateral: General Settings / Action Bars / Minimap / Chat /
	-- Mover Todo.
	-- ══════════════════════════════════════════════════════════════════
	local panel1 = tabPanels[1];

	-- El ultimo item lleva el nombre de TU clase (Mago, Cazador, ...):
	-- ahi van los modulos que solo esa clase puede usar.
	local className = (K.GetClassSectionName and K.GetClassSectionName())
		or (L["SIDE_CLASSOPT"] or "Class Options");

	local sideUI = K.CreateSideList(panel1, {
		{ name = L["SIDE_GENERAL"]    or "General Settings" },
		{ name = L["SIDE_ACTIONBARS"] or "Action Bars" },
		{ name = L["SIDE_MINIMAP"]    or "Minimap" },
		{ name = L["SIDE_CHAT"]       or "Chat" },
		{ name = L["SIDE_CASTBAR"]    or "Cast Bar" },
		{ name = L["SIDE_TOOLTIP"]    or "Tooltip" },
		-- Separador: de aca para abajo es todo de combate
		{ separator = true },
		{ name = L["TAB_PVP"] or "PvP" },
		{ name = className },
		-- MOVE EVERYTHING NO VA EN LA COLUMNA.
		--
		-- No es una seccion de ajustes como las de arriba: es una
		-- herramienta que se abre, se acomodan los marcos y se cierra.
		-- Su panel existe igual, pero se llega desde el boton del pie,
		-- al lado de Reload UI y Reset Defaults, que es donde estan las
		-- otras acciones.
		{ name = L["SIDE_MOVEALL"] or "Move Everything", hidden = true },
	});
	panel1.sideList = sideUI;

	-- Ojo con los indices: los separadores NO cuentan (ver CreateSideList),
	-- asi que son correlativos con el orden de los items con nombre.
	local paneGen, paneBars, paneMap, paneChat, paneCast, paneTip, panePvP, paneClass, paneMove =
		sideUI[1], sideUI[2], sideUI[3], sideUI[4], sideUI[5], sideUI[6], sideUI[7],
		sideUI[8], sideUI[9];

	local xL = 16;

	-- ── 1.1 GENERAL SETTINGS ──────────────────────────────────────
	-- DOS COLUMNAS: antes era una sola tira vertical y habia que scrollear
	-- media pantalla para llegar a lo de abajo. Ahora entra todo de una.
	--   izquierda (xL) -> Appearance, Name Color, Utility
	--   derecha  (xR) -> Action Bars, Unit Frames, Status Text
	local xR = 300;
	local gY = -14;   -- cursor de la columna izquierda
	local rY = -14;   -- cursor de la columna derecha

	SectionHeader(paneGen, L["HEADER_APPEARANCE"] or "Appearance", xL, gY);

	gY = gY - 24;
	CreateCheckBox(paneGen, L["CB_UNITFRAME_CUSTOM_TEX"], "UnitFrameCustomTexture", xL, gY);

	-- Tema visual: solo tiene sentido con el skin custom encendido
	gY = gY - 30;
	local themeLabel = paneGen:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	themeLabel:SetPoint("TOPLEFT", xL + 22, gY - 5);
	themeLabel:SetText((K.UI and K.UI.Header(K.UI.Strip(L["HEADER_THEME"]))) or L["HEADER_THEME"]);

	local themeOptions = {
		{text = L["THEME_OPT_LIGHT"] or "Light", value = "Light"},
		{text = L["THEME_OPT_DARK"]  or "Dark",  value = "Dark"},
		{text = L["THEME_OPT_ASURI"] or "Asuri", value = "Asuri"},
		{text = L["THEME_OPT_PW"]    or "Compact", value = "Compact"},
	};
	-- Asuri es un tema aparte, no una variante de color: por eso tiene su
	-- propio flag y gana sobre darkFrames cuando esta puesto.
	-- Los tres flags son excluyentes; el orden decide quien gana si por
	-- alguna razon quedaran dos puestos a la vez.
	local currentTheme = C.AsuriFrames and "Asuri"
		or (C.pwFrames and "Compact")
		or (C.darkFrames and "Dark")
		or "Light";

	dropdownCount = dropdownCount + 1;
	local themeDD = CreateFrame("Frame", "NidhausUFDropdown"..dropdownCount, paneGen, "UIDropDownMenuTemplate");
	themeDD:SetPoint("LEFT", themeLabel, "RIGHT", -8, -2);
	UIDropDownMenu_SetWidth(themeDD, 100);

	UIDropDownMenu_Initialize(themeDD, function(self, level)
		for _, opt in ipairs(themeOptions) do
			local info = UIDropDownMenu_CreateInfo();
			info.text  = opt.text;
			info.value = opt.value;
			info.func  = function(btn)
				UIDropDownMenu_SetSelectedValue(themeDD, btn.value);
				UIDropDownMenu_SetText(themeDD, btn.value);
				currentTheme = btn.value;

				-- Se guardan los TRES, siempre. Poner solo el elegido dejaba
				-- el anterior en true y quedaban dos temas compitiendo.
				K.SaveConfig("darkFrames",  btn.value == "Dark");
				K.SaveConfig("AsuriFrames", btn.value == "Asuri");
				K.SaveConfig("pwFrames",    btn.value == "Compact");
				if K._UpdateThemeVisibility then K._UpdateThemeVisibility(); end

				if K.ApplyPlayerFrameSkin then K.ApplyPlayerFrameSkin(); end
				if K.ApplyTargetFrameSkin then K.ApplyTargetFrameSkin(); end
				print(L["THEME_CHANGED"] or "|cffFFD100NUF:|r Theme changed. /reload to apply.");
			end;
			info.checked = (opt.value == currentTheme);
			UIDropDownMenu_AddButton(info, level);
		end
	end);
	UIDropDownMenu_SetSelectedValue(themeDD, currentTheme);
	UIDropDownMenu_SetText(themeDD, currentTheme);

	local function UpdateThemeVisibility()
		local on = C.UnitFrameCustomTexture and true or false;
		if on then
			UIDropDownMenu_EnableDropDown(themeDD);
			themeLabel:SetAlpha(1);
		else
			UIDropDownMenu_DisableDropDown(themeDD);
			themeLabel:SetAlpha(0.4);
		end
	end
	K._UpdateThemeVisibility = UpdateThemeVisibility;
	UpdateThemeVisibility();

	gY = gY - 34;
	CreateCheckBox(paneGen, L["CB_CLASS_COLOR"],    "classColor",        xL, gY); gY = gY - 27;
	CreateCheckBox(paneGen, L["CB_BACKDROP"],       "statusbarBackdrop", xL, gY); gY = gY - 27;
	CreateCheckBox(paneGen, L["CB_HEALTH_PCT"],     "HealthPercentage",  xL, gY); gY = gY - 27;
	-- El contador de segundos se fue a la seccion Cast Bar, que es donde
	-- esta todo lo de la barra de casteo.
	CreateCheckBox(paneGen, L["CB_ERROR_HIDE"] or "Hide Errors in Combat",
		"ErrorHideInCombat", xL, gY);

	-- ── Color de nombres ──
	gY = gY - 40;
	SectionHeader(paneGen, L["HEADER_NAME_COLOR"] or "Name Color", xL, gY);

	gY = gY - 24;
	do
		local modes = {
			{ value = "Default", text = L["NAME_COLOR_DEFAULT"] or "Default" },
			{ value = "White",   text = L["NAME_COLOR_WHITE"]   or "White"   },
			{ value = "Class",   text = L["NAME_COLOR_CLASS"]   or "Class"   },
		};
		local btnW, btnH, gap = 76, 22, 4;
		local nameButtons = {};

		local container = CreateFrame("Frame", nil, paneGen);
		container:SetPoint("TOPLEFT", xL + 2, gY);
		container:SetSize((#modes * btnW) + ((#modes - 1) * gap), btnH);

		local function RefreshNameButtons()
			local current = C.UnitNameColorMode or "Default";
			for _, b in ipairs(nameButtons) do
				if b.value == current then
					b:SetBackdropColor(0.10, 0.35, 0.60, 0.90);
					b:SetBackdropBorderColor(0.35, 0.70, 1.00, 0.95);
					b.labelFS:SetTextColor(1, 1, 1);
				else
					b:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
					b:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.60);
					b.labelFS:SetTextColor(0.55, 0.55, 0.55);
				end
			end
		end

		for i, opt in ipairs(modes) do
			local b = CreateFrame("Button", nil, container);
			b:SetSize(btnW, btnH);
			b:SetPoint("LEFT", container, "LEFT", (i - 1) * (btnW + gap), 0);
			b:SetBackdrop({
				bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile     = true, tileSize = 16, edgeSize = 12,
				insets   = { left = 3, right = 3, top = 3, bottom = 3 },
			});
			local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			fs:SetPoint("CENTER", b, "CENTER", 0, 0);
			fs:SetText(opt.text);
			b.labelFS = fs;
			b.value   = opt.value;

			b:SetScript("OnClick", function(self)
				K.SaveConfig("UnitNameColorMode", self.value);
				RefreshNameButtons();
				if K.ApplyUnitNameColorNow then K.ApplyUnitNameColorNow(); end
			end);
			b:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(opt.text, 1, 1, 1);
				GameTooltip:AddLine(L["TIP_UnitNameColorMode"] or "", nil, nil, nil, true);
				GameTooltip:Show();
			end);
			b:SetScript("OnLeave", function() GameTooltip:Hide(); end);

			table.insert(nameButtons, b);
		end
		RefreshNameButtons();
	end

	-- ── Submenu: borde/contorno del nombre (se despliega debajo del color) ──
	do
		local borderOpts = {
			{ value = "None",    text = L["NAME_BORDER_NONE"]    or "None" },
			{ value = "Outline", text = L["NAME_BORDER_OUTLINE"] or "Outline" },
			{ value = "Thick",   text = L["NAME_BORDER_THICK"]   or "Thick Outline" },
			{ value = "Shadow",  text = L["NAME_BORDER_SHADOW"]  or "Like health / mana text" },
		};
		local function OptText(v)
			for _, o in ipairs(borderOpts) do if o.value == v then return o.text; end end
			return v;
		end

		gY = gY - 34;
		local borderLabel = paneGen:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		borderLabel:SetPoint("TOPLEFT", xL + 2, gY - 4);
		borderLabel:SetText((K.UI and K.UI.Label(L["NAME_BORDER"] or "Name border"))
			or (L["NAME_BORDER"] or "Name border"));

		dropdownCount = dropdownCount + 1;
		local borderDD = CreateFrame("Frame", "NidhausUFDropdown" .. dropdownCount, paneGen, "UIDropDownMenuTemplate");
		borderDD:SetPoint("LEFT", borderLabel, "RIGHT", 4, -2);
		UIDropDownMenu_SetWidth(borderDD, 150);
		UIDropDownMenu_Initialize(borderDD, function(self, level)
			for _, opt in ipairs(borderOpts) do
				local info = UIDropDownMenu_CreateInfo();
				info.text  = opt.text;
				info.value = opt.value;
				info.func  = function(btn)
					UIDropDownMenu_SetSelectedValue(borderDD, btn.value);
					UIDropDownMenu_SetText(borderDD, OptText(btn.value));
					if K.SaveConfig then K.SaveConfig("UnitNameBorder", btn.value); end
					if K.ApplyUnitNameColorNow then K.ApplyUnitNameColorNow(); end
				end;
				info.checked = (opt.value == (C.UnitNameBorder or "None"));
				UIDropDownMenu_AddButton(info, level);
			end
		end);
		UIDropDownMenu_SetSelectedValue(borderDD, C.UnitNameBorder or "None");
		UIDropDownMenu_SetText(borderDD, OptText(C.UnitNameBorder or "None"));
	end

	-- NOTA: aca habia un espejo de las 3 opciones de Action Bars.
	-- Se saco: ya viven en su propia seccion del sidebar y tener el mismo
	-- checkbox en dos lados solo confunde.

	-- ══ COLUMNA IZQUIERDA (sigue) ════════════════════════════════
	-- ── Contorno del color de clase (adaptado de RougeUI) ──
	local coBody;   -- lo usa la seccion Utility de abajo para anclarse
	if K.Modules and K.Modules["ClassOutline"] then
		gY = gY - 44;
		SectionHeader(paneGen, L["HEADER_CLASS_INDICATORS"] or "Class Colored Indicators", xL, gY);

		gY = gY - 26;
		checkboxCount = checkboxCount + 1;
		local coName = "NidhausUFCheckBox" .. checkboxCount;
		local coCB = CreateFrame("CheckButton", coName, paneGen, "InterfaceOptionsCheckButtonTemplate");
		coCB:SetPoint("TOPLEFT", xL, gY);
		coCB:SetHitRectInsets(0, 0, 0, 0);
		local coFS = _G[coName .. "Text"];
		if coFS then coFS:SetText(L["MOD_CLASSOUTLINE"] or "Class Colored Outlines"); end
		coCB:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled("ClassOutline") or false);
		coCB:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MOD_CLASSOUTLINE"] or "Class Colored Outlines", 1, 1, 1);
			GameTooltip:AddLine(L["MOD_CLASSOUTLINE_DESC"] or "", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		coCB:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		coCB:SetScript("OnClick", function(self)
			local v = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SetModuleEnabled then K.SetModuleEnabled("ClassOutline", v); end
			if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("ClassOutline"); end
		end);
		if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox("ClassOutline", coCB); end

		-- Cuerpo desplegable: el slider del tamaño solo aparece con el
		-- modulo encendido, y al cerrarse Utility sube solo (va anclado
		-- al cuerpo, no a una coordenada).
		gY = gY - 30;
		coBody = K.UI.Collapsible(paneGen, xL + 8, gY, 210, 46, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("ClassOutline");
		end);

		local coSlider = CreateFrame("Slider", "NidhausClassOutlineSizeSlider", coBody,
			"OptionsSliderTemplate");
		coSlider:SetPoint("TOPLEFT", 0, 0);
		coSlider:SetWidth(190);
		coSlider:SetMinMaxValues(40, 90);
		coSlider:SetValueStep(1);
		local coStart = (K.GetClassOutlineSize and K.GetClassOutlineSize()) or 62;
		coSlider:SetValue(coStart);
		_G[coSlider:GetName() .. "Low"]:SetText("40");
		_G[coSlider:GetName() .. "High"]:SetText("90");
		_G[coSlider:GetName() .. "Text"]:SetText(L["SLIDER_OUTLINE_SIZE"] or "Ring size");
		coSlider:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v + 0.5);
			if K.SetClassOutlineSize then K.SetClassOutlineSize(v); end
		end);

		coCB:HookScript("OnClick", function() coBody:Refresh(); end);
	end

	-- ── Automatizaciones (mudadas desde Extra Options) ──
	-- Anclado al cuerpo de arriba cuando existe: asi acompaña el colapso
	-- en vez de dejar el hueco.
	local utilHdr = paneGen:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	if coBody then
		utilHdr:SetPoint("TOPLEFT", coBody, "BOTTOMLEFT", -8, -26);
	else
		gY = gY - 44;
		utilHdr:SetPoint("TOPLEFT", xL, gY);
	end
	utilHdr:SetText((K.UI and K.UI.Header(K.UI.Strip(L["HEADER_UTILITY"] or "Utility")))
		or (L["HEADER_UTILITY"] or "Utility"));

	local utilBox = CreateFrame("Frame", nil, paneGen);
	utilBox:SetPoint("TOPLEFT", utilHdr, "BOTTOMLEFT", 0, -6);
	utilBox:SetWidth(240);
	utilBox:SetHeight(106);

	CreateCheckBox(utilBox, L["CB_AUTO_SELL"] or "Auto Sell Gray Items", "AutoSellGray", 0, 0);
	CreateCheckBox(utilBox, L["CB_AUTO_REPAIR"] or "Auto Repair", "AutoRepair", 0, -26);
	CreateCheckBox(utilBox, L["CB_BLOCK_DUELS"] or "Decline Duels", "BlockDuels", 0, -52);
	CreateCheckBox(utilBox, L["CB_TAB_BINDER"] or "Tab targets enemy players in PvP",
		"TabBinderEnabled", 0, -78);
	gY = gY - 140;

	-- ══ COLUMNA DERECHA ══════════════════════════════════════════
	-- ── Marcos (espejo de Frames) ──
	-- Van PRIMERAS: son las dos que mas se tocan.
	SectionHeader(paneGen, L["HEADER_FRAMES_MIRROR"] or "Unit Frames", xR, rY);

	-- "Use Custom Positions" va PRIMERO: es la que habilita todo lo demas
	-- de posicionamiento, asi que tenerla arriba del modo 3v3 se lee mejor.
	rY = rY - 28;
	if K.CreateCustomPosCheckbox then
		K.CreateCustomPosCheckbox(paneGen, xR, rY);
	end

	rY = rY - 30;
	local cb3v3Gen = CreateFrame("CheckButton", "NidhausGeneralMirror3v3CB", paneGen, "UICheckButtonTemplate");
	cb3v3Gen:SetPoint("TOPLEFT", xR, rY);
	cb3v3Gen.text = cb3v3Gen:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb3v3Gen.text:SetPoint("LEFT", cb3v3Gen, "RIGHT", 4, 0);
	cb3v3Gen.text:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3");
	cb3v3Gen:SetChecked(C.PartyMode3v3 and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyMode3v3", cb3v3Gen); end
	if K.Register3v3Checkbox then K.Register3v3Checkbox(cb3v3Gen); end
	cb3v3Gen:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_PartyMode3v3"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb3v3Gen:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	cb3v3Gen:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("PartyMode3v3", v); end
		if v then
			if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
		else
			if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
		end
		if K.Update3v3SlidersVisibility then K.Update3v3SlidersVisibility(); end
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		if K.ScheduleGlobalPositionReapply then K.ScheduleGlobalPositionReapply(); end
	end);

	-- ── Texto de vida/mana abreviado (AbbreviatedStatus) ──
	-- El modulo se prende aca; el boton "Abrir" lleva a SU propio menu
	-- (panel del addon en las Opciones de Interfaz de Blizzard).
	rY = rY - 44;
	SectionHeader(paneGen, L["HEADER_STATUS_TEXT"] or "Status Text", xR, rY);
	rY = rY - 26;
	-- Vida Completa (portado de ZyrokofArenaFrames): "33401" en vez de
	-- "33401 / 33401". Vive aca porque es del mismo tema que el abreviado.
	local fullValueCB = CreateCheckBox(paneGen, L["CB_FULL_VALUE"] or "Current value only (no /max)",
		"ShowCurrentValueOnly", xR, rY);
	K._FullValueCB = fullValueCB;

	rY = rY - 28;
	local abbrevCB = CreateModuleCB(paneGen, L["CB_ABBREV_STATUS"] or "Abbreviated health / mana text",
		"AbbreviatedStatus", xR, rY, L["TIP_ABBREV_STATUS"]);
	local abbrevBody;
	if abbrevCB then
		-- El boton "Abrir" solo existe con el modulo prendido: apagado no hay
		-- nada que configurar y el menu que abria quedaba huerfano.
		-- Va en un cuerpo desplegable, igual que el resto del panel, asi que
		-- ademas no deja el hueco al ocultarse.
		--
		-- El boton va DEBAJO de la casilla: en columna angosta no entra al lado.
		abbrevBody = K.UI.Collapsible(paneGen, xR + 26, rY - 22, 200, 24, function()
			return (K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus")) or false;
		end);

		local abbrevBtn = CreateFrame("Button", nil, abbrevBody, "UIPanelButtonTemplate");
		abbrevBtn:SetSize(80, 20);
		abbrevBtn:SetPoint("TOPLEFT", 0, 0);
		abbrevBtn:SetText(L["BTN_MODULE_OPEN"] or "Open");
		abbrevBtn:SetScript("OnClick", function()
			-- Segunda guarda: el boton ya esta escondido con el modulo
			-- apagado, pero si alguna vez se lo llama desde otro lado que no
			-- sea este click, que no abra un menu sin sentido.
			if not (K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus")) then return; end
			if K.OpenAbbreviatedStatusMenu then K.OpenAbbreviatedStatusMenu(); end
		end);
		rY = rY - 28;
	end
	K._AbbrevCB = abbrevCB;

	-- Las dos formatean el MISMO texto de las barras. Con las dos activas se
	-- pisan entre si y los numeros quedan corridos o a medio formatear, asi
	-- que son excluyentes: una, la otra, o ninguna.
	local function SyncStatusTextExclusive()
		local full   = C.ShowCurrentValueOnly and true or false;
		local abbrev = (K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus")) or false;
		local fv, ab = K._FullValueCB, K._AbbrevCB;
		if fv then
			-- EL TILDE, ADEMAS DE HABILITAR/DESHABILITAR.
			--
			-- Aca estaba el bug del toggle. Al prender el abreviado, su
			-- onEnable apaga "Current value only" por dentro (son excluyentes)
			-- pero NADIE destildaba la casilla. Quedaba marcada mintiendo:
			-- el usuario la clickeaba para apagar algo que ya estaba apagado,
			-- no pasaba nada visible, y parecia que se habia trabado.
			--
			-- Sincronizar el tilde con el estado real arregla los dos sentidos
			-- de una, sin importar por que camino se haya cambiado.
			fv:SetChecked(full);
			if abbrev then fv:Disable(); else fv:Enable(); end
			fv:SetAlpha(abbrev and 0.4 or 1);
		end
		if ab then
			ab:SetChecked(abbrev);
			if full then ab:Disable(); else ab:Enable(); end
			ab:SetAlpha(full and 0.4 or 1);
		end
		-- Mostrar u ocultar el boton "Abrir" segun el modulo. Se hace aca
		-- porque esta funcion ya la llaman los dos caminos que pueden
		-- cambiar el estado: el click en la casilla y el excluyente de
		-- "Current value only".
		if abbrevBody then abbrevBody:Refresh(); end
	end
	K._SyncStatusTextExclusive = SyncStatusTextExclusive;
	paneGen:HookScript("OnShow", SyncStatusTextExclusive);
	if abbrevCB then abbrevCB:HookScript("OnClick", SyncStatusTextExclusive); end
	SyncStatusTextExclusive();
	rY = rY - 6;

	-- El alto scrolleable es el de la columna mas larga
	sideUI.SetContentHeight(1, math.min(gY, rY) - 40);

	-- ── 1.2 ACTION BARS ───────────────────────────────────────────
	local bY = -14;
	SectionHeader(paneBars, L["HEADER_BAR_STYLE"] or "Bar Style", xL, bY);

	bY = bY - 24;
	CreateCheckBox(paneBars, L["CB_UNIFY_ACTIONBARS"], "UnifyActionBars", xL, bY); bY = bY - 26;
	CreateCheckBox(paneBars, L["CB_MINIBAR"] or "MiniBar", "MiniBarEnabled", xL, bY); bY = bY - 26;
	CreateCheckBox(paneBars, L["CB_MINIBAR_NO_BG"] or "Hide bar background",
		"MiniBarHideBackground", xL + 16, bY);
	local miniBgCB = checkboxes[#checkboxes]; bY = bY - 26;
	local function UpdateMiniBgVisibility()
		if not miniBgCB then return; end
		if C.MiniBarEnabled == true then miniBgCB:Show(); else miniBgCB:Hide(); end
	end
	K._UpdateMiniBgVisibility = UpdateMiniBgVisibility;
	UpdateMiniBgVisibility();
	CreateCheckBox(paneBars, L["CB_HIDE_GRYPHONS"] or "Hide Gryphons", "HideGryphons", xL, bY); bY = bY - 26;
	CreateCheckBox(paneBars, L["CB_BAGPACK"] or "BagPack Background", "ShowBagPackTexture", xL, bY);
	local bagpackCheckbox = checkboxes[#checkboxes];

	local function UpdateBagPackCheckboxVisibility()
		local anyBarActive = K.IsAnyBarModeActive and K.IsAnyBarModeActive()
			or (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
		if anyBarActive then bagpackCheckbox:Show(); else bagpackCheckbox:Hide(); end
	end
	K._UpdateBagPackVisibility = UpdateBagPackCheckboxVisibility;
	UpdateBagPackCheckboxVisibility();

	bY = bY - 26;
	local hideTexCB = CreateModuleCB(paneBars, L["CB_HIDE_BAR_TEXTURES"] or "Hide Action Bar Textures",
		"HideActionBarTextures", xL, bY, L["TIP_HideBarTextures"]);

	-- Con Unify o MiniBar activos, esos modos ya manejan las texturas.
	local function UpdateHideTexVisibility()
		if not hideTexCB then return; end
		local anyBarActive = (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
		if anyBarActive then hideTexCB:Hide(); else hideTexCB:Show(); end
	end
	K._UpdateHideTexVisibility = UpdateHideTexVisibility;
	UpdateHideTexVisibility();

	-- ── Separacion entre botones ──
	-- Solo tiene sentido con alguno de los dos modos de barras puesto: con
	-- las barras de Blizzard sin tocar, el addon no reubica los botones.
	bY = bY - 46;
	local btnSpaceSlider = CreateSlider(paneBars, L["SLIDER_BUTTON_SPACE"] or "Buttons space",
		"ActionBarButtonSpace", 0, 20, 1, xL + 4, bY);
	btnSpaceSlider:HookScript("OnValueChanged", function()
		if K.ApplyActionBarButtonSpace then K.ApplyActionBarButtonSpace(); end
	end);

	local function UpdateButtonSpaceVisibility()
		local anyBarActive = (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
		if anyBarActive then btnSpaceSlider:Show(); else btnSpaceSlider:Hide(); end
	end
	K._UpdateButtonSpaceVisibility = UpdateButtonSpaceVisibility;
	UpdateButtonSpaceVisibility();

	-- ── Textos y feedback ──
	-- COLUMNA DERECHA: la izquierda tenia todo apilado y sobraba media
	-- pantalla a la derecha. Asi Size y Position suben y entra todo sin
	-- scroll. bT es el cursor de esta columna, independiente de bY.
	local xBarR = 300;
	local bT = -14;
	SectionHeader(paneBars, L["HEADER_BAR_TEXT"] or "Text and Feedback", xBarR, bT);

	bT = bT - 24;
	CreateModuleCB(paneBars, L["CB_BUTTON_RANGE"] or "Button Range", "ButtonRange",
		xBarR, bT, L["TIP_ButtonRange"]);
	bT = bT - 26;
	CreateCheckBox(paneBars, L["CB_HIDE_KEYBIND"] or "Hide Keybind Text", "HideKeybindText", xBarR, bT);
	bT = bT - 26;
	CreateCheckBox(paneBars, L["CB_HIDE_MACRO"] or "Hide Macro Names", "HideMacroText", xBarR, bT);

	-- Barras laterales solo al pasar el mouse
	bT = bT - 26;
	do
		CreateCheckBox(paneBars, L["CB_SIDEBARS_HOVER"] or "Show side bars on mouseover",
			"SideBarsHover", xBarR, bT);
		local cb = checkboxes[#checkboxes];
		cb:HookScript("OnClick", function()
			if K.ApplySideBarHover then K.ApplySideBarHover(); end
		end);
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["CB_SIDEBARS_HOVER"] or "Show side bars on mouseover", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_SideBarsHover"]
				or "The right side bars stay hidden and only appear when the mouse is over them. They still work while hidden.",
				nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end

	-- Vuelve a la columna IZQUIERDA, justo debajo de Bar Style.
	bY = bY - 46;
	SectionHeader(paneBars, L["HEADER_BAR_SIZE"] or "Size", xL, bY);
	bY = bY - 34;
	local abScaleSlider = CreateSlider(paneBars,
		L["SLIDER_ACTIONBAR_SCALE"] or "Action Bar Scale",
		"ActionBarScale", 0.65, 1.14, 0.01, xL, bY);
	abScaleSlider:SetWidth(210);

	-- ── Mover las barras de accion ──
	-- Usa el mismo modo mover que "Move Everything", pero acotado al grupo
	-- "extra" (barras + cast bar), para no llenar la pantalla de cajas.
	bY = bY - 60;
	SectionHeader(paneBars, L["HEADER_BAR_MOVE"] or "Position", xL, bY);
	bY = bY - 20;
	-- Ancho recortado: la columna derecha empieza en 300.
	SectionNote(paneBars, L["NOTE_BAR_MOVE"]
		or "Turns on move mode: drag the blue box to place the action bars. Click again to lock and save.",
		xL + 2, bY, 262);

	bY = bY - 34;
	local barMoveBtn = CreateFrame("Button", nil, paneBars, "UIPanelButtonTemplate");
	barMoveBtn:SetPoint("TOPLEFT", xL + 2, bY);
	barMoveBtn:SetSize(170, 22);
	barMoveBtn:SetText(L["BTN_MOVE_BARS"] or "Move action bars");
	barMoveBtn:SetScript("OnClick", function(self)
		if not K.ToggleGlobalUnlock then return; end
		K.ToggleGlobalUnlock("extra");
		local on = K.IsGlobalUnlocked and K.IsGlobalUnlocked();
		self:SetText(on and (L["BTN_LOCK_BARS"] or "Lock bars")
			or (L["BTN_MOVE_BARS"] or "Move action bars"));
	end);

	local barResetBtn = CreateFrame("Button", nil, paneBars, "UIPanelButtonTemplate");
	barResetBtn:SetPoint("LEFT", barMoveBtn, "RIGHT", 8, 0);
	barResetBtn:SetSize(100, 22);
	barResetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
	barResetBtn:SetScript("OnClick", function()
		-- Solo las barras: antes llamaba al reset global y te borraba
		-- tambien la posicion de buffs, debuffs y todo lo demas.
		if K.ResetGlobalPositions then
			K.ResetGlobalPositions({ MainBar = true, CastBar = true });
		end
	end);

	-- La columna mas larga manda: si no, con la derecha mas alta que la
	-- izquierda el scroll cortaba las ultimas opciones.
	sideUI.SetContentHeight(2, math.min(bY, bT) - 60);

	-- ── 1.3 MINIMAP ───────────────────────────────────────────────
	local mmY = -14;
	SectionHeader(paneMap, L["HEADER_MINIMAP_SHAPE"] or "Shape", xL, mmY);

	mmY = mmY - 24;
	do
		local shapes = {
			{ value = false, text = L["MINIMAP_ROUND"]  or "Round" },
			{ value = true,  text = L["MINIMAP_SQUARE"] or "Square" },
		};
		local btnW, btnH, gap = 86, 22, 4;
		local shapeButtons = {};

		local container = CreateFrame("Frame", nil, paneMap);
		container:SetPoint("TOPLEFT", xL + 2, mmY);
		container:SetSize((#shapes * btnW) + ((#shapes - 1) * gap), btnH);

		local function RefreshShape()
			local current = C.MinimapSquare and true or false;
			for _, b in ipairs(shapeButtons) do
				if b.value == current then
					b:SetBackdropColor(0.10, 0.35, 0.60, 0.90);
					b:SetBackdropBorderColor(0.35, 0.70, 1.00, 0.95);
					b.labelFS:SetTextColor(1, 1, 1);
				else
					b:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
					b:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.60);
					b.labelFS:SetTextColor(0.55, 0.55, 0.55);
				end
			end
		end

		for i, opt in ipairs(shapes) do
			local b = CreateFrame("Button", nil, container);
			b:SetSize(btnW, btnH);
			b:SetPoint("LEFT", container, "LEFT", (i - 1) * (btnW + gap), 0);
			b:SetBackdrop({
				bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile     = true, tileSize = 16, edgeSize = 12,
				insets   = { left = 3, right = 3, top = 3, bottom = 3 },
			});
			local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			fs:SetPoint("CENTER", b, "CENTER", 0, 0);
			fs:SetText(opt.text);
			b.labelFS = fs;
			b.value   = opt.value;
			b:SetScript("OnClick", function(self)
				K.SaveConfig("MinimapSquare", self.value);
				RefreshShape();
				if K.ApplyMinimapSettings then K.ApplyMinimapSettings(); end
				-- El Light Border solo vale en cuadrado, asi que el aviso
				-- debajo del selector cambia con la forma.
				if K._UpdateBorderNote then K._UpdateBorderNote(); end
			end);
			table.insert(shapeButtons, b);
		end
		RefreshShape();
	end

	-- Checkbox de adornos: al tocarlos hay que reaplicar en caliente
	local function MinimapCB(label, setting, y, tip)
		CreateCheckBox(paneMap, label, setting, xL, y, tip);
		local cb = checkboxes[#checkboxes];
		cb:HookScript("OnClick", function()
			if K.ApplyMinimapSettings then K.ApplyMinimapSettings(); end
		end);
		return cb;
	end

	-- ESTILO DE BORDE.
	--
	-- Va justo debajo del selector de forma porque es lo mismo: el aspecto
	-- del marco del mapa. Antes era un solo checkbox ("Light Border"); ahora
	-- son cinco opciones excluyentes, asi que va en un desplegable.
	mmY = mmY - 40;
	SectionHeader(paneMap, L["HEADER_MINIMAP_BORDER"] or "Border", xL, mmY);

	mmY = mmY - 30;
	do
		-- MIGRACION DEL CHECKBOX VIEJO.
		--
		-- Quien tenia el Light Border prendido arranca con ese estilo
		-- elegido, sin tener que volver a tocarlo.
		if (C.MinimapBorderStyle == nil or C.MinimapBorderStyle == "")
			and C.MinimapThinBorder == true then
			C.MinimapBorderStyle = "Light";
			if K.SaveConfig then K.SaveConfig("MinimapBorderStyle", "Light"); end
		end

		local opts = {
			{ text = L["MINIMAP_BORDER_DEFAULT"]  or "Default",  value = "Default"  },
			{ text = L["MINIMAP_BORDER_LIGHT"]    or "Light",    value = "Light"    },
			{ text = L["MINIMAP_BORDER_TOOLTIP"]  or "Tooltip",  value = "Tooltip"  },
			{ text = L["MINIMAP_BORDER_THIN"]     or "Thin",     value = "Thin"     },
			{ text = L["MINIMAP_BORDER_FLAT"]     or "Flat",     value = "Flat"     },
			{ text = L["MINIMAP_BORDER_BLIZZARD"] or "Blizzard", value = "Blizzard" },
		};
		CreateDropdown(paneMap, L["DD_MINIMAP_BORDER"] or "Border style",
			"MinimapBorderStyle", opts, xL, mmY, function()
				if K.ApplyMinimapSettings then K.ApplyMinimapSettings(); end
				if K._UpdateBorderNote then K._UpdateBorderNote(); end
			end);

		-- El Light Border es un marco cuadrado: con la forma redonda no se
		-- dibuja. En vez de sacarlo de la lista, se avisa aca.
		mmY = mmY - 46;
		local note = SectionNote(paneMap, "", xL + 2, mmY, 260);
		local function UpdateBorderNote()
			if not note then return; end
			local style = C.MinimapBorderStyle or "Default";
			if style == "Light" and C.MinimapSquare ~= true then
				note:SetText("|cffFFD100" .. (L["NOTE_MINIMAP_BORDER_SQUARE"]
					or "Light only works with the square shape.") .. "|r");
			else
				note:SetText("|cff8EAEC9" .. (L["NOTE_MINIMAP_BORDER"]
					or "Tooltip, Thin, Flat and Blizzard work with both shapes.") .. "|r");
			end
		end
		K._UpdateBorderNote = UpdateBorderNote;
		UpdateBorderNote();
	end

	mmY = mmY - 44;
	SectionHeader(paneMap, L["HEADER_MINIMAP_DECOR"] or "Decorations", xL, mmY);

	mmY = mmY - 24;
	MinimapCB(L["CB_MINIMAP_HIDE_ZONE"]    or "Hide Zone Name",      "MinimapHideZone",   mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_ZONEBG"]  or "Hide Zone Name Background", "MinimapHideZoneBG", mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_CLOCK"]    or "Hide Clock",          "MinimapHideClock",    mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_ZOOM"]     or "Hide Zoom Buttons",   "MinimapHideZoom",     mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_CALENDAR"] or "Hide Calendar",       "MinimapHideCalendar", mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_HIDE_WORLDMAP"] or "Hide World Map",      "MinimapHideWorldMap", mmY); mmY = mmY - 26;
	MinimapCB(L["CB_MINIMAP_WHEEL"]         or "Mouse Wheel Zoom",    "MinimapWheelZoom",    mmY);

	-- ── COLUMNA DERECHA ──
	--
	-- Forma, borde y adornos ocupaban una sola columna y dejaban media
	-- pantalla vacia a la derecha, con la ultima seccion cayendose abajo
	-- del scroll. Iconos y tamaño se mudan a la segunda columna: entra
	-- todo de una y no hace falta scrollear.
	local mmR = -14;
	SectionHeader(paneMap, L["HEADER_MINIMAP_ICONS"] or "Addon Icons", xR, mmR);

	mmR = mmR - 26;
	do
		CreateCheckBox(paneMap, L["CB_MINIMAP_HIDE_ICONS"] or "Hide addon icons",
			"MinimapHideAddonIcons", xR, mmR);
		local cb = checkboxes[#checkboxes];
		cb:HookScript("OnClick", function()
			if K.ApplyMinimapSettings then K.ApplyMinimapSettings(); end
		end);
	end

	mmR = mmR - 30;
	SectionNote(paneMap, L["NOTE_MINIMAP_ICONS"]
		or "The module below adds a small button on the minimap corner to hide and show the icons on the fly, without opening this panel.",
		xR + 2, mmR, 230);
	mmR = mmR - 52;
	CreateModuleCB(paneMap, L["MOD_MINIMAP_TOGGLE"] or "Minimap Icon Toggle",
		"MinimapIconToggle", xR, mmR, L["MOD_MINIMAP_TOGGLE_DESC"]);

	mmR = mmR - 52;
	SectionHeader(paneMap, L["HEADER_MINIMAP_SIZE"] or "Size", xR, mmR);
	mmR = mmR - 30;
	local mapScale = CreateSlider(paneMap, L["SLIDER_MINIMAP_SCALE"] or "Minimap Scale",
		"MinimapScale", 0.6, 1.6, 0.05, xR, mmR);
	mapScale:SetWidth(210);
	mapScale:HookScript("OnMouseUp", function()
		if K.ApplyMinimapScale then K.ApplyMinimapScale(); end
	end);
	mapScale:HookScript("OnValueChanged", function()
		if K.ApplyMinimapScale then K.ApplyMinimapScale(); end
	end);

	-- Manda la columna mas larga, si no el scroll corta la de abajo.
	sideUI.SetContentHeight(3, math.min(mmY, mmR) - 60);

	-- ── 1.4 CHAT ──────────────────────────────────────────────────
	local cY = -14;
	SectionHeader(paneChat, L["HEADER_CHAT"] or "Chat", xL, cY);

	cY = cY - 24;
	CreateCheckBox(paneChat, L["CB_CHAT_COPY"] or "Copy Chat Text", "ChatCopyEnabled",
		xL, cY, L["TIP_ChatCopyEnabled"]);
	cY = cY - 26;
	CreateCheckBox(paneChat, L["CB_CHAT_URLS"] or "Clickable Links", "ChatClickableURLs",
		xL, cY, L["TIP_ChatClickableURLs"]);
	cY = cY - 26;
	CreateModuleCB(paneChat, L["CB_HIDE_CHAT_BUTTON"] or "Hide Chat Buttons",
		"HideChatButton", xL, cY, L["TIP_HideChatButton"]);
	cY = cY - 26;
	CreateModuleCB(paneChat, L["MOD_SYSTEM_SPAM"] or "Hide system spam",
		"SystemSpamFilter", xL, cY, L["MOD_SYSTEM_SPAM_DESC"]
			or "Removes system chat spam: other people's duel results, drunk messages and 'you have learned' lines.");

	sideUI.SetContentHeight(4, cY - 40);

	-- ── 1.5 CAST BAR ──────────────────────────────────────────────
	-- Todo lo de la barra de casteo junto. Antes el contador de segundos
	-- estaba perdido en General, entre cosas que no tienen nada que ver.
	local kY = -14;
	SectionHeader(paneCast, L["HEADER_CASTBAR"] or "Cast Bar", xL, kY);

	kY = kY - 24;
	CreateCheckBox(paneCast, L["CB_CASTING_TIMERS"], "CastingTimers", xL, kY);

	kY = kY - 34;
	K.UI.Separator(paneCast, xL, kY, 440);

	-- ── Barra custom (port de pw_unitframes) ──
	kY = kY - 18;
	local castPWCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW"] or "Custom Cast Bar",
		"CastBarPWEnabled", xL, kY);

	kY = kY - 26;
	SectionNote(paneCast, L["NOTE_CASTBAR_PW"] or "", xL + 24, kY, 400);

	kY = kY - 44;
	local castIconCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW_ICON"] or "Show spell icon",
		"CastBarPWIcon", xL + 16, kY);

	kY = kY - 26;
	local castDarkCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW_DARK"] or "Dark border",
		"CastBarPWDark", xL + 16, kY);

	-- A que barras se les aplica el estilo custom. La del jugador va
	-- siempre; estas dos se pueden dejar con el aspecto de Blizzard.
	kY = kY - 26;
	local castTargetCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW_TARGET"] or "Apply to target",
		"CastBarPWTarget", xL + 16, kY);

	kY = kY - 26;
	local castFocusCB = CreateCheckBox(paneCast, L["CB_CASTBAR_PW_FOCUS"] or "Apply to focus",
		"CastBarPWFocus", xL + 16, kY);

	kY = kY - 42;
	local castIconSlider = CreateSlider(paneCast, L["SLIDER_CASTBAR_PW_SIZE"] or "Icon Size",
		"CastBarPWIconSize", 18, 48, 1, xL + 20, kY);
	castIconSlider:HookScript("OnValueChanged", function()
		if K.ApplyCastBarPW then K.ApplyCastBarPW(); end
	end);

	-- La del foco vino de Frames > General. Alla estaba entre las escalas
	-- de los MARCOS, y es una barra de casteo. Ahora las dos escalas de
	-- barras de casteo estan juntas, que es donde uno las busca.
	--
	-- Ojo: esta NO depende del modo custom, funciona con la barra de
	-- Blizzard igual. Por eso queda afuera del grupo que se apaga.
	kY = kY - 56;
	local focusBarSlider = CreateSlider(paneCast, L["SLIDER_FOCUS_SPELLBAR"] or "Focus Cast Bar Scale",
		"FocusSpellBarScale", 0.5, 1.5, 0.05, xL + 20, kY);
	focusBarSlider:HookScript("OnValueChanged", function(self, value)
		if K.ApplyFocusSpellBarScale then K.ApplyFocusSpellBarScale(value); end
	end);

	kY = kY - 56;
	local castScaleSlider = CreateSlider(paneCast, L["SLIDER_CASTBAR_PW_SCALE"] or "Cast Bar Scale",
		"CastBarPWScale", 0.5, 2.0, 0.05, xL + 20, kY);
	castScaleSlider:HookScript("OnValueChanged", function(self, value)
		-- Ojo: NO llamamos a SetScale desde aca. La escala de la barra del
		-- jugador la guarda Move Everything, y si la escribieramos por
		-- afuera el proximo login volveria al valor viejo y pareceria que
		-- el slider no guarda nada.
		if K.ApplyCastBarPWScale then K.ApplyCastBarPWScale(value); end
	end);

	-- Ctrl + rueda sobre la barra en el modo mover cambia el mismo numero:
	-- que el slider lo muestre al toque, sin tener que cerrar y abrir.
	function K.RefreshCastBarScaleSlider()
		local v = C.CastBarPWScale;
		if type(v) ~= "number" then return; end
		if castScaleSlider:GetValue() ~= v then
			castScaleSlider:SetValue(v);
		end
	end

	-- Los tres controles de abajo son del modo custom: sin el puesto no
	-- hacen nada, asi que se apagan en vez de quedar clickeables al pedo.
	local function UpdateCastBarVisibility()
		local on = C.CastBarPWEnabled and true or false;
		for _, obj in ipairs({ castIconCB, castDarkCB, castTargetCB, castFocusCB,
			castIconSlider, castScaleSlider }) do
			if on then obj:Enable(); else obj:Disable(); end
			obj:SetAlpha(on and 1 or 0.4);
		end
		-- El tamaño del icono solo importa si el icono se muestra.
		if on and C.CastBarPWIcon == false then
			castIconSlider:Disable();
			castIconSlider:SetAlpha(0.4);
		end
	end
	K._UpdateCastBarVisibility = UpdateCastBarVisibility;
	UpdateCastBarVisibility();

	-- El checkbox maestro tambien tiene que repintar a los hijos: el
	-- despachador lo llama, pero si algun dia se lo saltea, esto lo cubre.
	castPWCB:HookScript("OnClick", UpdateCastBarVisibility);

	sideUI.SetContentHeight(5, kY - 70);

	-- ── 1.6 TOOLTIP ───────────────────────────────────────────────
	-- Tres agregados portados de el UI de origen. La logica esta en
	-- Modules2/TooltipExtras.lua; aca solo estan los interruptores.
	local tY = -14;
	SectionHeader(paneTip, L["HEADER_TOOLTIP"] or "Tooltip", xL, tY);

	tY = tY - 26;
	CreateCheckBox(paneTip, L["CB_TOOLTIP_ARENA_EXP"] or "Arena experience",
		"TooltipArenaExp", xL, tY);

	tY = tY - 24;
	SectionNote(paneTip, L["NOTE_TOOLTIP_ARENA_EXP"] or "", xL + 24, tY, 420);

	tY = tY - 46;
	CreateCheckBox(paneTip, L["CB_TOOLTIP_TALENTS"] or "Show talents",
		"TooltipTalents", xL, tY);

	tY = tY - 24;
	SectionNote(paneTip, L["NOTE_TOOLTIP_TALENTS"] or "", xL + 24, tY, 420);

	tY = tY - 46;
	CreateCheckBox(paneTip, L["CB_TOOLTIP_QUALITY"] or "Item quality border",
		"TooltipQualityBorder", xL, tY);

	tY = tY - 24;
	SectionNote(paneTip, L["NOTE_TOOLTIP_QUALITY"] or "", xL + 24, tY, 420);

	tY = tY - 34;
	CreateCheckBox(paneTip, L["CB_TOOLTIP_ICONS"] or "Show tooltip icons",
		"TooltipIcons", xL, tY, L["TIP_TooltipIcons"]);
	tY = tY - 24;
	SectionNote(paneTip, L["NOTE_TOOLTIP_ICONS"] or "", xL + 24, tY, 420);

	sideUI.SetContentHeight(6, tY - 60);

	-- ── 1.6 MOVER TODO ────────────────────────────────────────────
	local vY = -14;
	SectionHeader(paneMove, L["HEADER_MOVE_ALL"] or "Move Everything", xL, vY);

	vY = vY - 22;
	SectionNote(paneMove, L["DESC_MOVE_ALL"] or "", xL + 2, vY, 430);

	vY = vY - 48;
	local unlockAllBtn = CreateFrame("Button", nil, paneMove, "UIPanelButtonTemplate");
	unlockAllBtn:SetPoint("TOPLEFT", xL + 2, vY);
	unlockAllBtn:SetSize(200, 24);
	unlockAllBtn:SetText(L["BTN_MOVE_ALL"] or "Unlock Everything");
	unlockAllBtn:SetScript("OnClick", function(self)
		if not K.ToggleGlobalUnlock then return; end
		K.ToggleGlobalUnlock("all");
		if K.IsGlobalUnlocked and K.IsGlobalUnlocked() then
			self:SetText(L["BTN_MOVE_ALL_DONE"] or "Lock All Frames");
		else
			self:SetText(L["BTN_MOVE_ALL"] or "Unlock Everything");
		end
	end);

	local unlockAllReset = CreateFrame("Button", nil, paneMove, "UIPanelButtonTemplate");
	unlockAllReset:SetPoint("LEFT", unlockAllBtn, "RIGHT", 8, 0);
	unlockAllReset:SetSize(120, 24);
	unlockAllReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
	unlockAllReset:SetScript("OnClick", function()
		if K.ResetGlobalPositions then K.ResetGlobalPositions(); end
	end);

	-- ── Cuadricula ──
	-- Tres botones en vez de un slider: son tres valores y nada mas, y asi
	-- se ve de un vistazo cual esta puesto.
	vY = vY - 34;
	local gridLbl = paneMove:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	gridLbl:SetPoint("TOPLEFT", xL + 2, vY);
	gridLbl:SetText(L["LBL_MOVE_GRID"] or "Grid");

	local gridNote = paneMove:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	gridNote:SetPoint("TOPLEFT", xL + 2, vY - 42);
	gridNote:SetWidth(430);
	gridNote:SetJustifyH("LEFT");
	gridNote:SetText("|cff8EAEC9" .. (L["DESC_MOVE_GRID"]
		or "Frames snap to a grid while you drag them, so lining two of them up is easy. Smaller steps move more freely.") .. "|r");

	local gridBtns = {};
	local function RefreshGridButtons()
		local cur = (C and C.MoveGridStep) or 10;
		for step, b in pairs(gridBtns) do
			-- El elegido queda hundido; los otros, normales.
			if step == cur then b:LockHighlight(); else b:UnlockHighlight(); end
		end
	end

	local gx = xL + 50;
	for _, step in ipairs({ 2, 5, 10 }) do
		local b = CreateFrame("Button", nil, paneMove, "UIPanelButtonTemplate");
		b:SetPoint("TOPLEFT", gx, vY + 4);
		b:SetSize(52, 22);
		b:SetText("x" .. step);
		b:SetScript("OnClick", function()
			if K.SaveConfig then K.SaveConfig("MoveGridStep", step); end
			RefreshGridButtons();
		end);
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("x" .. step, 1, 1, 1);
			GameTooltip:AddLine(string.format(L["TIP_MOVE_GRID"]
				or "Cells of %d pixels a side.", step), nil, nil, nil, true);
			GameTooltip:Show();
		end);
		b:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		gridBtns[step] = b;
		gx = gx + 58;
	end
	RefreshGridButtons();
	K._RefreshMoveGridButtons = RefreshGridButtons;

	-- Espejos utiles: se tocan mucho junto con el modo mover
	vY = vY - 92;
	K.UI.Separator(paneMove, xL, vY + 12, 440);

	-- "Use Custom Positions" VA PRIMERO.
	--
	-- No es solo orden visual: el modo 3v3 depende de ella (mira
	-- K.Update3v3Enabled), asi que leerla despues del efecto que habilita
	-- confundia. Arriba la causa, abajo la consecuencia.
	vY = vY - 8;
	if K.CreateCustomPosCheckbox then
		K.CreateCustomPosCheckbox(paneMove, xL, vY);
	end

	vY = vY - 30;
	local cb3v3General = CreateFrame("CheckButton", "NidhausGeneral3v3CB", paneMove, "UICheckButtonTemplate");
	cb3v3General:SetPoint("TOPLEFT", xL, vY);
	cb3v3General.text = cb3v3General:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb3v3General.text:SetPoint("LEFT", cb3v3General, "RIGHT", 4, 0);
	cb3v3General.text:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3");
	cb3v3General:SetChecked(C.PartyMode3v3 and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyMode3v3", cb3v3General); end
	if K.Register3v3Checkbox then K.Register3v3Checkbox(cb3v3General); end
	cb3v3General:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_PartyMode3v3"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb3v3General:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	cb3v3General:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("PartyMode3v3", v); end
		if v then
			if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
		else
			if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
		end
		if K.Update3v3SlidersVisibility then K.Update3v3SlidersVisibility(); end
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		if K.ScheduleGlobalPositionReapply then K.ScheduleGlobalPositionReapply(); end
	end);

	-- Move Everything paso a ser el ultimo item de la lista (9).
	sideUI.SetContentHeight(9, vY - 50);

	-- ── 1.6 PVP  (comun a todas las clases) ───────────────────────
	if K.BuildPvPSection then
		sideUI.SetContentHeight(7, K.BuildPvPSection(panePvP) - 30);
	end

	-- ── 1.7 <CLASE DETECTADA> ─────────────────────────────────────
	if K.BuildClassSection then
		sideUI.SetContentHeight(8, K.BuildClassSection(paneClass) - 30);
	end

	-- ══════════════════════════════════════════════════════════════════
	-- PESTAÑA 2: FRAMES
	-- ══════════════════════════════════════════════════════════════════
	if K.PopulateFramesTab then K.PopulateFramesTab(tabPanels[2]); end

	-- ══════════════════════════════════════════════════════════════════
	-- PESTAÑA 3: ARENA
	-- ══════════════════════════════════════════════════════════════════
	if K.PopulateArenaTab then
		showArenaBtn = K.PopulateArenaTab(tabPanels[3]);
	end

	-- ══════════════════════════════════════════════════════════════════
	-- PESTAÑA 4: ADDONS  (antes "Modules")
	-- Agrupados por categoria en la lista lateral, en vez de una lista
	-- plana de 12 modulos donde no se encuentra nada.
	-- ══════════════════════════════════════════════════════════════════
	local panel4 = tabPanels[4];

	-- UNA sola lista, sin submenu lateral: el usuario no quiere categorias.
	-- El orden y que entra lo decide K.GetAddonTabIds (Core/ModuleManager).
	local allIds = (K.GetAddonTabIds and K.GetAddonTabIds()) or {};

	local addonScroll = CreateFrame("ScrollFrame", "NidhausAddonsScroll", panel4, "UIPanelScrollFrameTemplate");
	addonScroll:SetPoint("TOPLEFT", 6, -6);
	addonScroll:SetPoint("BOTTOMRIGHT", -28, 6);

	local addonPane = CreateFrame("Frame", "NidhausAddonsScrollChild", addonScroll);
	addonPane:SetWidth(560);
	addonPane:SetHeight(1);
	addonScroll:SetScrollChild(addonPane);

	local moduleCount = 0;
	K._moduleContainers = {};

	local function UpdateModulesScrollHeight()
		local total = 10;
		for _, id in ipairs(allIds) do
			local ct = K._moduleContainers[id];
			if ct then total = total + ct:GetHeight(); end
		end
		addonPane:SetHeight(total + 40);
	end
	K.UpdateModulesScrollHeight = UpdateModulesScrollHeight;

	do
		local pane = addonPane;
		local prevContainer = nil;

		for _, id in ipairs(allIds) do
			local mod = K.Modules[id];
			if mod and not mod.hideFromModulesTab then
				moduleCount   = moduleCount + 1;
				checkboxCount = checkboxCount + 1;

				local container = CreateFrame("Frame", "NidhausModuleContainer_"..id, pane);
				container:SetWidth(548);

				-- Linea fina arriba de cada fila (menos la primera).
				--
				-- La lista era un bloque de texto corrido: nombre, descripcion,
				-- nombre, descripcion... y no se veia donde terminaba un modulo
				-- y empezaba el otro. La linea cuesta un pixel y ordena todo.
				if prevContainer then
					local sep = container:CreateTexture(nil, "ARTWORK");
					sep:SetTexture(1, 1, 1, 0.07);
					sep:SetPoint("TOPLEFT", container, "TOPLEFT", 6, 2);
					sep:SetPoint("TOPRIGHT", container, "TOPRIGHT", -6, 2);
					sep:SetHeight(1);
				end
				if prevContainer then
					container:SetPoint("TOPLEFT", prevContainer, "BOTTOMLEFT", 0, 0);
				else
					container:SetPoint("TOPLEFT", 6, -8);
				end

				local cbName = "NidhausUFModuleCB"..moduleCount;
				local check  = CreateFrame("CheckButton", cbName, container,
					"InterfaceOptionsCheckButtonTemplate");
				check:SetPoint("TOPLEFT", 6, 0);
				check:SetHitRectInsets(0, 0, 0, 0);

				local mlabel = _G[cbName.."Text"];
				if mlabel then
					mlabel:SetText(mod.name);
					mlabel:SetFontObject("GameFontNormal");
				end

				if mod.desc and mod.desc ~= "" then
					check:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(mod.name, 1, 1, 1);
						GameTooltip:AddLine(mod.desc, nil, nil, nil, true);
						GameTooltip:AddLine(" ");
						if K.IsModuleEnabled(id) then
							GameTooltip:AddLine(L["MODULES_ENABLED"]);
						else
							GameTooltip:AddLine(L["MODULES_DISABLED"]);
						end
						GameTooltip:Show();
					end);
					check:SetScript("OnLeave", function() GameTooltip:Hide(); end);
				end

				check:SetChecked(K.IsModuleEnabled(id));
				check.moduleId = id;
				check:SetScript("OnClick", function(self)
					local isChecked = self:GetChecked();
					K.SetModuleEnabled(id, isChecked == 1 or isChecked == true);
					if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox(id); end
				end);
				if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox(id, check); end

				if mod.configFunc then
					local cfgBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate");
					-- PEGADO A LA DERECHA, no a 290 px del checkbox.
					--
					-- Con el offset fijo el boton caia en medio de la fila y
					-- se le montaba a la descripcion de los modulos de nombre
					-- largo. Anclado al borde derecho queda una columna prolija
					-- de botones y la descripcion tiene todo el ancho restante.
					cfgBtn:SetSize(90, 20);
					cfgBtn:SetPoint("TOPRIGHT", container, "TOPRIGHT", -10, -1);
					cfgBtn:SetText(mod.configLabel or (L["BTN_MODULE_CONFIG"] or "Configure"));
					cfgBtn:SetScript("OnClick", function()
						local ok, err = pcall(mod.configFunc);
						if not ok then print("|cffFF0000NUF:|r " .. tostring(err)); end
					end);
					local function RefreshCfgBtn()
						if K.IsModuleEnabled(id) then
							cfgBtn:Enable(); cfgBtn:SetAlpha(1);
						else
							cfgBtn:Disable(); cfgBtn:SetAlpha(0.4);
						end
					end
					RefreshCfgBtn();
					check:HookScript("OnClick", RefreshCfgBtn);
				end

				local baseHeight = 0;
				if mod.desc and mod.desc ~= "" then
					local descText = container:CreateFontString(nil, "ARTWORK",
						"GameFontHighlightSmall");
					descText:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 26, 2);
					descText:SetText("|cff888888"..mod.desc.."|r");
					-- El ancho llega hasta antes de la columna de botones.
					descText:SetWidth(mod.configFunc and 400 or 500);
					descText:SetJustifyH("LEFT");

					-- ALTO MEDIDO, NO ADIVINADO.
					--
					-- Estaba fijo en 40, que alcanza para una linea de
					-- descripcion. Los modulos con descripcion larga (DTSU,
					-- Dungeon Finder Roles) ocupan dos o tres, y se le metian
					-- encima a la fila de abajo o al slider de escala.
					--
					-- GetStringHeight devuelve el alto REAL despues de partir
					-- el texto al ancho de arriba, asi que la fila mide lo que
					-- tiene que medir sea cual sea el largo.
					local h = descText:GetStringHeight() or 12;
					baseHeight = 26 + h + 6;
					if baseHeight < 40 then baseHeight = 40; end
				else
					baseHeight = 28;
				end

				local subUIHeight = 0;
				container._collapsed = false;

				-- ESCALA AUTOMATICA: si el modulo se registro con
				-- K.RegisterScalable, el panel le dibuja el slider solo.
				-- Asi no hay que escribir UI a mano para cada uno.
				-- OJO: el alto de este slider NO se suma a baseHeight. Antes si,
				-- y por eso el slider quedaba siempre a la vista aunque el
				-- modulo estuviera apagado (el caso de DTSU). Ahora lo maneja
				-- UpdateContainerState junto con el resto de sub-opciones.
				local autoScaleH = 0;
				if K.IsScalable and K.IsScalable(id) and K.UI and K.UI.ScaleSlider then
					local sc = K.UI.ScaleSlider(container, id, 30, -baseHeight - 14, 180);
					if sc then
						container._autoScale = sc;
						autoScaleH = 52;
					end
				end

				if mod.createUI then
					local beforeChildren = {};
					for _, child in pairs({container:GetChildren()}) do
						beforeChildren[child] = true;
					end
					local beforeRegions = {};
					for _, region in pairs({container:GetRegions()}) do
						beforeRegions[region] = true;
					end

					subUIHeight = mod.createUI(container, -baseHeight - autoScaleH, check) or 0;

					container._subUIAll = {};
					for _, child in pairs({container:GetChildren()}) do
						if not beforeChildren[child] then
							table.insert(container._subUIAll, child);
						end
					end
					for _, region in pairs({container:GetRegions()}) do
						if not beforeRegions[region] then
							table.insert(container._subUIAll, region);
						end
					end

					if type(subUIHeight) ~= "number" or subUIHeight < 0 then
						subUIHeight = 0;
					end

					if subUIHeight > 100 then
						local subUIElements = container._subUIAll;

						local collapseBtn = CreateFrame("Button", nil, container);
						collapseBtn:SetSize(20, 16);
						collapseBtn:SetPoint("LEFT", _G[cbName.."Text"] or check, "RIGHT", 6, 0);
						collapseBtn:SetNormalFontObject("GameFontNormalSmall");

						local collapsed = true;

						local function UpdateCollapseVisual()
							if collapsed then
								collapseBtn:SetText("|cffAAAAAA[+]|r");
								for _, elem in ipairs(subUIElements) do
									if elem.Hide then elem:Hide(); end
								end
								container:SetHeight(baseHeight);
							else
								collapseBtn:SetText("|cffAAAAAA[-]|r");
								if K.IsModuleEnabled(id) then
									for _, elem in ipairs(subUIElements) do
										if elem.Show then elem:Show(); end
									end
									container:SetHeight(baseHeight + subUIHeight);
								else
									container:SetHeight(baseHeight);
								end
							end
							container._collapsed = collapsed;
							UpdateModulesScrollHeight();
						end

						collapseBtn:SetScript("OnClick", function()
							collapsed = not collapsed;
							UpdateCollapseVisual();
						end);
						collapseBtn:SetScript("OnEnter", function(self)
							GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
							GameTooltip:SetText(collapsed
								and (L["MODULE_EXPAND"]   or "Click to expand")
								or  (L["MODULE_COLLAPSE"] or "Click to collapse"),
								0.8, 0.8, 0.8);
							GameTooltip:Show();
						end);
						collapseBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

						UpdateCollapseVisual();
					end
				end

				container._baseHeight  = baseHeight;
				container._subUIHeight = subUIHeight;
				container._moduleId    = id;

				local function UpdateContainerState()
					local on = K.IsModuleEnabled(id);
					if container._subUIAll then
						for _, elem in ipairs(container._subUIAll) do
							if on and not container._collapsed then
								if elem.Show then elem:Show(); end
							else
								if elem.Hide then elem:Hide(); end
							end
						end
					end

					-- El slider de escala se despliega con el checkbox, igual que
					-- el resto de las opciones del modulo.
					local scaleH = 0;
					if container._autoScale then
						if on and not container._collapsed then
							container._autoScale:Show();
							scaleH = autoScaleH;
						else
							container._autoScale:Hide();
						end
					end

					local h = baseHeight + scaleH;
					if not (container._collapsed or not on or subUIHeight <= 0) then
						h = h + subUIHeight;
					end
					container:SetHeight(h);
					if K.UpdateModulesScrollHeight then K.UpdateModulesScrollHeight(); end
				end
				container._UpdateState = UpdateContainerState;
				check:HookScript("OnClick", UpdateContainerState);
				UpdateContainerState();

				K._moduleContainers[id] = container;
				prevContainer = container;
			end
		end

		if not prevContainer then
			local empty = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
			empty:SetPoint("TOPLEFT", 10, -10);
			empty:SetText("|cff888888" .. (L["MODULES_NONE"] or "No addons in this group yet.") .. "|r");
		end
	end

	UpdateModulesScrollHeight();

	-- ══════════════════════════════════════════════════════════════════
	-- PESTAÑA 5: PROFILES
	-- ══════════════════════════════════════════════════════════════════
	if K.PopulateExtraTab then K.PopulateExtraTab(tabPanels[5]); end
	-- Panel 6: About. Mismo contenido que tenia la ventana flotante, pero
	-- dentro del panel, asi hereda el tema y el tamaño.
	if K.PopulateAboutTab then K.PopulateAboutTab(tabPanels[6]); end
end

-- ────────────────────────────────────────────────────────────────────────────
-- CreateBottomButtons
-- ────────────────────────────────────────────────────────────────────────────
local function CreateBottomButtons()
	-- Left buttons
	-- Footer: solo Close mantiene el tamaño completo; el resto son
	-- acciones secundarias, mas chicas y atenuadas para no competir.
	local function MakeSecondary(btn)
		btn:SetAlpha(0.75);
		btn:HookScript("OnEnter", function(self) self:SetAlpha(1); end);
		btn:HookScript("OnLeave", function(self) self:SetAlpha(0.75); end);
	end

	local reloadButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	reloadButton:SetPoint("BOTTOMLEFT", 20, 18);
	reloadButton:SetSize(104, 22);
	reloadButton:SetText(L["BTN_RELOAD"]);
	reloadButton:SetScript("OnClick", function() ReloadUI(); end);
	MakeSecondary(reloadButton);

	local resetButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	resetButton:SetPoint("LEFT", reloadButton, "RIGHT", 8, 0);
	resetButton:SetSize(114, 22);
	resetButton:SetText(L["BTN_RESET"]);
	resetButton:SetScript("OnClick", function()
		StaticPopup_Show("NIDHAUS_RESET_CONFIRM");
	end);
	MakeSecondary(resetButton);

	-- ══ PIE, DOS FILAS ═══════════════════════════════════════════
	--
	-- Antes entraban seis botones en una sola fila y no daba el ancho: el
	-- de Move Everything terminaba montado sobre el de Profiles.
	--
	--   fila de arriba:  Profiles  About              [ Estilo ]
	--   fila de abajo:   Reload UI  Reset Defaults  Move Everything ... Close
	--
	-- Arriba lo que se abre de vez en cuando, abajo las acciones.

	-- MOVE EVERYTHING: ABRE EL MODO MOVER Y CIERRA EL PANEL.
	--
	-- Antes solo saltaba a su seccion, y ahi tenias que apretar otro boton
	-- mas — con el panel tapando justo los marcos que ibas a acomodar. El
	-- boton hace lo que dice: desbloquea y se corre del medio.
	local moveButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	moveButton:SetPoint("LEFT", resetButton, "RIGHT", 8, 0);
	moveButton:SetSize(130, 22);
	moveButton:SetText(L["SIDE_MOVEALL"] or "Move Everything");
	moveButton:SetScript("OnClick", function()
		mainFrame:Hide();
		if K.ToggleGlobalUnlock then K.ToggleGlobalUnlock(); end
	end);
	MakeSecondary(moveButton);

	-- Right buttons
	local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	closeButton:SetPoint("BOTTOMRIGHT", -20, 18);
	closeButton:SetSize(120, 25);
	closeButton:SetText(L["BTN_CLOSE"]);
	closeButton:SetScript("OnClick", function() mainFrame:Hide(); end);

	-- "Show Config" ya no esta.
	--
	-- Volcaba las ~200 opciones guardadas por el chat, comparandolas contra
	-- los valores en memoria. Es una herramienta de diagnostico, no algo de
	-- uso diario, y ocupaba un lugar caro del pie. Sigue disponible con
	-- /nufconfig db para cuando haga falta.

	-- ── Fila de arriba: a la izquierda del selector de estilo ──
	local profilesButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	profilesButton:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 20, 50);
	profilesButton:SetSize(100, 22);
	profilesButton:SetText(L["TAB_PROFILES"] or "Profiles");
	MakeSecondary(profilesButton);
	profilesButton:SetScript("OnClick", function()
		if K.SelectPanelTab then K.SelectPanelTab(5); end
	end);

	-- About vuelve a ser una PESTAÑA, no una ventana flotante.
	--
	-- Como ventana aparte se dibujaba encima del panel, con su propio
	-- backdrop y sin heredar el tema: quedaba fuera de tono y tapaba lo que
	-- estabas mirando. Ahora salta al panel 6, que existe pero no ocupa
	-- lugar en la barra de arriba.
	local aboutButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate");
	aboutButton:SetPoint("LEFT", profilesButton, "RIGHT", 8, 0);
	aboutButton:SetSize(100, 22);
	aboutButton:SetText(L["TAB_ABOUT"] or "About");
	MakeSecondary(aboutButton);
	aboutButton:SetScript("OnClick", function()
		if K.SelectPanelTab then K.SelectPanelTab(6); end
	end);

	-- ── Popup dialogs ─────────────────────────────────────────
	StaticPopupDialogs["NIDHAUS_RESET_CONFIRM"] = {
		text           = L["RESET_CONFIRM"],
		button1        = L["RESET_BTN_YES"],
		button2        = L["RESET_BTN_NO"],
		OnAccept       = function() K.ResetConfig(); ReloadUI(); end,
		timeout        = 0,
		whileDead      = true,
		hideOnEscape   = true,
		preferredIndex = 3,
	};

	StaticPopupDialogs["NIDHAUS_RESET_POS_CONFIRM"] = {
		text           = L["RESET_POS_CONFIRM"],
		button1        = L["RESET_POS_BTN_YES"],
		button2        = L["RESET_POS_BTN_NO"],
		OnAccept       = function()
			if K.ResetPositionsAndScale then K.ResetPositionsAndScale(); end
			for _, slider in pairs(sliders) do
				if slider.setting and C[slider.setting] then
					slider:SetValue(C[slider.setting]);
				end
			end
		end,
		timeout        = 0,
		whileDead      = true,
		hideOnEscape   = true,
		preferredIndex = 3,
	};
end

-- ────────────────────────────────────────────────────────────────────────────
-- InitializePanel
-- ────────────────────────────────────────────────────────────────────────────
local function InitializePanel()
	CreateMainFrame();
	CreateTabs();

	-- DIFERIDO: el contenido de las pestañas se arma la PRIMERA vez que se
	-- abre el panel, no al loguear. Construir TODO en PLAYER_LOGIN es lo que
	-- estaba colgando el juego al entrar. Asi el login queda liviano y, si el
	-- bug esta en el panel, recien aparece al abrirlo (no al jugar).
	local built = false;
	mainFrame:HookScript("OnShow", function()
		if built then return; end
		built = true;
		local ok, err = pcall(PopulateTabs);
		if not ok then
			print("|cffFF0000NUF:|r error armando el panel: " .. tostring(err));
		end
		-- Todos los sliders del addon reciben la cajita con el valor debajo.
		-- Se hace en UNA pasada al final en vez de slider por slider: son 17
		-- repartidos en 9 archivos y varios se crean dentro de submenus.
		if K.UI and K.UI.RestyleSliders then
			pcall(K.UI.RestyleSliders, mainFrame);
		end
		if K.LoadSavedTheme then pcall(K.LoadSavedTheme); end
	end);

	CreateBottomButtons();

	-- ── Build theme switcher and register frames with ThemeManager ──
	local themeButtons = CreateThemeSwitcher();

	if K.RegisterThemeFrames then
		K.RegisterThemeFrames({
			mainFrame    = mainFrame,
			titleBox     = titleBoxRef,
			tabBar       = tabBarRef,
			tabs         = tabs,
			tabPanels    = tabPanels,
			themeButtons = themeButtons,
		});
	end

	-- ── Apply the saved (or default) panel theme ─────────────
	if K.LoadSavedTheme then
		K.LoadSavedTheme();
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Initialization trigger
-- ────────────────────────────────────────────────────────────────────────────
-- DOS CAMINOS, PORQUE ESTE ADDON PUEDE CARGAR DESPUES DEL LOGIN.
--
-- Antes esto esperaba PLAYER_LOGIN y listo. Ahora el panel es LoadOnDemand:
-- cuando lo pedis con /nuf, ese evento YA PASO y no va a volver a dispararse,
-- asi que la ventana no se construia nunca.
--
-- IsLoggedIn() responde justamente eso: si ya estamos adentro, se arma en el
-- acto; si el addon se cargo antes (por ejemplo si alguien lo deja activado a
-- mano), se espera al evento como toda la vida.
if IsLoggedIn and IsLoggedIn() then
	InitializePanel();
else
	local initFrame = CreateFrame("Frame");
	initFrame:RegisterEvent("PLAYER_LOGIN");
	initFrame:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LOGIN" then
			self:UnregisterEvent("PLAYER_LOGIN");
			InitializePanel();
		end
	end);
end

SLASH_NUFCONFIG1 = "/nufconfig";
SLASH_NUFCONFIG2 = "/nufoptions";

SlashCmdList["NUFCONFIG"] = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "");
	if msg == "db" or msg == "database" then
		K.ShowConfig();
	elseif msg == "reset" or msg == "size" then
		-- Rescate: devuelve la ventana a 820x620 y al centro de la pantalla.
		if K.ResetOptionsPanelSize then
			K.ResetOptionsPanelSize();
			print("|cff4FC3F7NUF:|r " .. (L["PANEL_SIZE_RESET"]
				or "Ventana de opciones restaurada a 820x620 y centrada."));
			if mainFrame and not mainFrame:IsShown() then mainFrame:Show(); end
		end
	else
		if not mainFrame then return; end
		if mainFrame:IsShown() then mainFrame:Hide(); else mainFrame:Show(); end
	end
end;

function K.ToggleOptionsPanel()
	if mainFrame then
		if mainFrame:IsShown() then mainFrame:Hide(); else mainFrame:Show(); end
	end
end