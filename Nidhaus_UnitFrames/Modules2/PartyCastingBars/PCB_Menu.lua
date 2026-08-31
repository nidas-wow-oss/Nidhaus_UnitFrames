local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PCB_Menu.lua  -  ventana de opciones de /pcb
--
-- Antes todo lo de PartyCastingBars se manejaba escribiendo
-- subcomandos: /pcb icon, /pcb scale 0.8, /pcb parent, /pcb drag,
-- /pcb set FRIENDLY CAST... Ocho colores a mano, con dos palabras
-- en mayuscula cada uno, que habia que sacar de /pcb help.
--
-- Ahora /pcb abre esta ventana y estan todos ahi. Los subcomandos
-- siguen andando: no cuestan nada y hay gente con macros.
--
-- Vive en un archivo aparte del de la logica (830 lineas) porque no
-- comparte nada con el: lee y escribe SOLO por las funciones
-- publicas de PartyCastingBars.
-- =========================================================

local PANEL_W, PANEL_H = 320, 372;

local menu;          -- la ventana, creada la primera vez que se pide
local swatches = {}; -- [reaction][type] = textura del cuadradito

local REACTIONS = { "FRIENDLY", "HOSTILE" };
local TYPES     = { "CAST", "CHANNEL", "SUCCESS", "FAILURE" };

local TYPE_LABEL = {
	CAST    = L["PCB_TYPE_CAST"]    or "Casting",
	CHANNEL = L["PCB_TYPE_CHANNEL"] or "Channeling",
	SUCCESS = L["PCB_TYPE_SUCCESS"] or "Success",
	FAILURE = L["PCB_TYPE_FAILURE"] or "Failure",
};

-- ---------------------------------------------------------
-- Posicion de la ventana
--
-- Se guarda en la misma SavedVariable que el resto de PCB, y
-- SIEMPRE por PartyCastingBars.GetDB(): la tabla recien existe en
-- ADDON_LOADED, despues de que corren los .lua.
-- ---------------------------------------------------------
local function SavePoint()
	if not menu then return; end
	local point, _, relPoint, x, y = menu:GetPoint(1);
	if not point then return; end
	PartyCastingBars.GetDB().panel = {
		point = point, relPoint = relPoint, x = x, y = y,
	};
end

local function PlaceFromDB()
	if not menu then return; end
	local p = PartyCastingBars.GetDB().panel;
	menu:ClearAllPoints();
	if type(p) == "table" and p.point then
		menu:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x or 0, p.y or 0);
	else
		menu:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	end
end

-- ---------------------------------------------------------
-- Construccion
-- ---------------------------------------------------------
local function Build()
	if menu then return menu; end

	menu = CreateFrame("Frame", "PCB_MenuFrame", UIParent);
	-- Cajita con el valor debajo del slider, misma que el resto del addon.
	if K.UI and K.UI.AutoRestyle then K.UI.AutoRestyle(menu); end

	menu:SetSize(PANEL_W, PANEL_H);
	menu:SetFrameStrata("DIALOG");
	menu:SetClampedToScreen(true);
	menu:EnableMouse(true);
	menu:SetMovable(true);
	menu:Hide();

	if menu.SetBackdrop then
		menu:SetBackdrop({
			bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		});
		menu:SetBackdropColor(0, 0, 0, 0.80);
	end

	-- ── Cabecera arrastrable ──
	local header = CreateFrame("Frame", nil, menu);
	header:SetPoint("TOPLEFT", 0, 0);
	header:SetPoint("TOPRIGHT", 0, 0);
	header:SetHeight(18);
	header:EnableMouse(true);
	header:RegisterForDrag("LeftButton");
	header:SetScript("OnDragStart", function()
		-- ClearAllPoints antes de arrastrar: StartMoving le puede cambiar
		-- el tipo de punto al frame, y con anclajes viejos mezclados la
		-- ventana pelea contra si misma. Mismo motivo que en PartyBuffs.
		menu:ClearAllPoints();
		menu:StartMoving();
	end);
	header:SetScript("OnDragStop", function()
		menu:StopMovingOrSizing();
		SavePoint();
	end);

	local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	title:SetPoint("TOPLEFT", 8, -4);
	title:SetText("|cff66CCFF" .. (L["PCB_TITLE"] or "Party Cast Bars") .. "|r");

	local sep0 = menu:CreateTexture(nil, "ARTWORK");
	sep0:SetTexture(1, 1, 1, 0.12);
	sep0:SetPoint("TOPLEFT", 4, -18);
	sep0:SetPoint("TOPRIGHT", -4, -18);
	sep0:SetHeight(1);

	-- ── Escala ──
	local lblScale = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	lblScale:SetPoint("TOPLEFT", 10, -26);
	lblScale:SetText("|cffaaaaaa" .. (L["PCB_SCALE_LABEL"] or "Bar scale:") .. "|r");

	local slider = CreateFrame("Slider", "PCB_MenuScaleSlider", menu, "OptionsSliderTemplate");
	slider:SetWidth(230); slider:SetHeight(14);
	slider:SetPoint("TOPLEFT", 40, -46);
	slider:SetMinMaxValues(0.5, 2.0);
	slider:SetValueStep(0.05);
	for _, suffix in ipairs({ "Low", "High", "Text" }) do
		local fs = _G["PCB_MenuScaleSlider" .. suffix];
		if fs then fs:SetText(""); fs:Hide(); end
	end
	slider:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v / 0.05 + 0.5) * 0.05;
		v = tonumber(string.format("%.2f", v)) or 1;
		if self._last == v then return; end
		self._last = v;
		PartyCastingBars.SetScales(v);
	end);
	menu.scaleSlider = slider;

	-- ── Casillas ──
	local function MakeCheck(name, y, label, getFn, setFn)
		local cb = CreateFrame("CheckButton", name, menu, "UICheckButtonTemplate");
		cb:SetPoint("TOPLEFT", 10, y);
		cb:SetWidth(24); cb:SetHeight(24);
		local fs = _G[name .. "Text"];
		if fs then
			fs:SetText(label);
			fs:SetFontObject("GameFontHighlightSmall");
		end
		cb:SetScript("OnClick", function(self)
			setFn(self:GetChecked() and true or false);
		end);
		cb._get = getFn;
		return cb;
	end

	menu.iconCB = MakeCheck("PCB_MenuIconCB", -84,
		L["PCB_CB_ICONS"] or "Show spell icons",
		function() return PartyCastingBars.GetIcons(); end,
		function(v) PartyCastingBars.EnableIcons(v); end);

	menu.parentCB = MakeCheck("PCB_MenuParentCB", -110,
		L["PCB_CB_PARENT"] or "Attach bars to party frames",
		function() return PartyCastingBars.GetParented(); end,
		function(v) PartyCastingBars.SetParents(v); end);

	local sep1 = menu:CreateTexture(nil, "ARTWORK");
	sep1:SetTexture(1, 1, 1, 0.08);
	sep1:SetPoint("TOPLEFT", 4, -140);
	sep1:SetPoint("TOPRIGHT", -4, -140);
	sep1:SetHeight(1);

	-- ── Colores ──
	--
	-- Cuadricula de 2 filas (amistoso / hostil) por 4 columnas. Cada
	-- cuadradito abre el selector de color de Blizzard y se repinta
	-- solo, porque el modulo llama a RefreshMenu al aceptar o cancelar.
	local lblColor = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	lblColor:SetPoint("TOPLEFT", 10, -148);
	lblColor:SetText("|cffaaaaaa" .. (L["PCB_COLORS_LABEL"] or "Bar colours:") .. "|r");

	local COL_X, COL_W = 96, 54;
	local ROW_Y = { -184, -216 };

	for c, typeString in ipairs(TYPES) do
		local head = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		head:SetPoint("TOPLEFT", COL_X + (c - 1) * COL_W, -166);
		head:SetWidth(COL_W);
		head:SetJustifyH("LEFT");
		head:SetText("|cff8EAEC9" .. (TYPE_LABEL[typeString] or typeString) .. "|r");
	end

	for r, reaction in ipairs(REACTIONS) do
		swatches[reaction] = {};

		local rowLabel = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		rowLabel:SetPoint("TOPLEFT", 12, ROW_Y[r] - 4);
		rowLabel:SetText(reaction == "FRIENDLY"
			and (L["PCB_FRIENDLY"] or "Friendly")
			or  (L["PCB_HOSTILE"]  or "Hostile"));

		for c, typeString in ipairs(TYPES) do
			local btn = CreateFrame("Button", nil, menu);
			btn:SetSize(22, 22);
			btn:SetPoint("TOPLEFT", COL_X + (c - 1) * COL_W, ROW_Y[r]);

			local bg = btn:CreateTexture(nil, "BACKGROUND");
			bg:SetPoint("TOPLEFT", -1, 1);
			bg:SetPoint("BOTTOMRIGHT", 1, -1);
			bg:SetTexture(0, 0, 0, 1);

			local fill = btn:CreateTexture(nil, "ARTWORK");
			fill:SetAllPoints(btn);
			swatches[reaction][typeString] = fill;

			btn:SetScript("OnClick", function()
				local info = PartyCastingBars_Colors[reaction][typeString];
				if info then PartyCastingBars.OpenColorPicker(info); end
			end);
			btn:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText((reaction == "FRIENDLY"
					and (L["PCB_FRIENDLY"] or "Friendly")
					or  (L["PCB_HOSTILE"]  or "Hostile"))
					.. " - " .. (TYPE_LABEL[typeString] or typeString), 1, 1, 1);
				GameTooltip:AddLine(L["PCB_SWATCH_TIP"] or "Click to change this colour.",
					nil, nil, nil, true);
				GameTooltip:Show();
			end);
			btn:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		end
	end

	local colorReset = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate");
	colorReset:SetSize(140, 20);
	colorReset:SetPoint("TOPLEFT", 10, -250);
	colorReset:SetText(L["PCB_BTN_RESET_COLORS"] or "Reset colours");
	colorReset:SetScript("OnClick", function()
		PartyCastingBars.ResetAllColors();
		PartyCastingBars.RefreshMenu();
	end);

	local sep2 = menu:CreateTexture(nil, "ARTWORK");
	sep2:SetTexture(1, 1, 1, 0.08);
	sep2:SetPoint("TOPLEFT", 4, -280);
	sep2:SetPoint("TOPRIGHT", -4, -280);
	sep2:SetHeight(1);

	-- ── Posicion de las barras ──
	--
	-- El modo arrastre muestra las cuatro barras con un casteo falso
	-- para poder agarrarlas. Se apaga solo al cerrar la ventana: si
	-- quedara puesto, las barras taparian el grupo en combate.
	local dragBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate");
	dragBtn:SetSize(140, 22);
	dragBtn:SetPoint("TOPLEFT", 10, -290);
	dragBtn:SetScript("OnClick", function()
		PartyCastingBars.EnableDragging(not PartyCastingBars.IsDragging());
		PartyCastingBars.RefreshMenu();
	end);
	menu.dragBtn = dragBtn;

	local resetPos = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate");
	resetPos:SetSize(140, 22);
	resetPos:SetPoint("TOPLEFT", 162, -290);
	resetPos:SetText(L["PCB_BTN_RESET_POS"] or "Reset positions");
	resetPos:SetScript("OnClick", function()
		PartyCastingBars.ResetBarLocations();
	end);

	-- ── Cerrar ──
	local closeBtn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate");
	closeBtn:SetSize(100, 22);
	closeBtn:SetPoint("BOTTOMRIGHT", -10, 10);
	closeBtn:SetText(L["BTN_CLOSE"] or "Close");
	closeBtn:SetScript("OnClick", function() PartyCastingBars.CloseMenu(); end);

	return menu;
end

-- ---------------------------------------------------------
-- Refrescar
--
-- Publica porque el selector de color la llama desde el otro
-- archivo cada vez que se acepta, se cancela o se resetea.
-- ---------------------------------------------------------
function PartyCastingBars.RefreshMenu()
	if not menu or not menu:IsShown() then return; end

	local sc = PartyCastingBars.GetScale() or 1;
	menu.scaleSlider._last = sc;
	menu.scaleSlider:SetValue(sc);

	menu.iconCB:SetChecked(PartyCastingBars.GetIcons() and true or false);
	menu.parentCB:SetChecked(PartyCastingBars.GetParented() and true or false);

	for reaction, types in pairs(swatches) do
		for typeString, fill in pairs(types) do
			local info = PartyCastingBars_Colors[reaction][typeString];
			if info then fill:SetTexture(info.r, info.g, info.b, 1); end
		end
	end

	menu.dragBtn:SetText(PartyCastingBars.IsDragging()
		and (L["PCB_BTN_DRAG_OFF"] or "Stop moving")
		or  (L["PCB_BTN_DRAG_ON"]  or "Move bars"));
end

-- ---------------------------------------------------------
-- Abrir / cerrar
-- ---------------------------------------------------------
function PartyCastingBars.OpenMenu()
	Build();
	PlaceFromDB();
	menu:Show();
	PartyCastingBars.RefreshMenu();
end

function PartyCastingBars.CloseMenu()
	if not menu then return; end
	-- El modo arrastre no se queda puesto: fuera de la ventana no hay
	-- forma de darse cuenta de que esta activo hasta que las barras
	-- aparecen en medio de una pelea.
	if PartyCastingBars.IsDragging() then
		PartyCastingBars.EnableDragging(false);
	end
	menu:Hide();
end

function PartyCastingBars.ToggleMenu()
	if menu and menu:IsShown() then
		PartyCastingBars.CloseMenu();
	else
		PartyCastingBars.OpenMenu();
	end
end

function PartyCastingBars.IsMenuShown()
	return menu and menu:IsShown() and true or false;
end
