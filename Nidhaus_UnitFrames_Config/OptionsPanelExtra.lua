-- Este archivo vive en Nidhaus_UnitFrames_Config, un addon aparte que se
-- carga SOLO cuando abris el panel (LoadOnDemand). Por eso no recibe el
-- namespace por "...", que es privado de cada addon: lo toma de la global
-- que publica el addon principal en Core/Init.lua.
local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

-- =========================================================
-- OptionsPanelExtra.lua
-- Tab 5: Profiles (Export/Import + Save/Load slots) + Extra Options
-- =========================================================

local checkboxCount = 0;

local function CreateCheckBox(parent, labelText, setting, xOffset, yOffset, tooltipText)
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausExtraCB" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", xOffset, yOffset);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local label = _G[cbName .. "Text"];
	if label then
		label:SetText(labelText);
	else
		label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		label:SetPoint("LEFT", cb, "RIGHT", 2, 0);
		label:SetText(labelText);
	end

	cb.setting = setting;

	if tooltipText then
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(labelText, 1, 1, 1);
			GameTooltip:AddLine(tooltipText, nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end

	cb.refresh = function(self)
		local value = C[setting];
		if type(value) == "number" then value = (value == 1); end
		self:SetChecked(value == true);
	end;
	cb:refresh();

	cb:SetScript("OnClick", function(self)
		local isChecked = self:GetChecked();
		local boolValue = (isChecked == 1 or isChecked == true);
		K.SaveConfig(setting, boolValue);
	end);

	return cb;
end

-- =========================================================
-- CreateModeSelector
-- Fila compacta de botones tipo "pill" para settings de texto.
-- Ocupa 24px de alto (vs ~50 de un dropdown).
-- =========================================================
local function CreateModeSelector(parent, setting, options, xOffset, yOffset, tooltipText, onChange)
	local btnW, btnH, gap = 76, 22, 4;
	local buttons = {};

	local container = CreateFrame("Frame", nil, parent);
	container:SetPoint("TOPLEFT", xOffset, yOffset);
	container:SetSize((#options * btnW) + ((#options - 1) * gap), btnH);

	local function Refresh()
		local current = C[setting] or options[1].value;
		for _, btn in ipairs(buttons) do
			if btn.value == current then
				btn:SetBackdropColor(0.10, 0.35, 0.60, 0.90);
				btn:SetBackdropBorderColor(0.35, 0.70, 1.00, 0.95);
				btn.labelFS:SetTextColor(1, 1, 1);
			else
				btn:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
				btn:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.60);
				btn.labelFS:SetTextColor(0.55, 0.55, 0.55);
			end
		end
	end

	for i, opt in ipairs(options) do
		local btn = CreateFrame("Button", nil, container);
		btn:SetSize(btnW, btnH);
		btn:SetPoint("LEFT", container, "LEFT", (i - 1) * (btnW + gap), 0);
		btn:SetBackdrop({
			bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile     = true, tileSize = 16, edgeSize = 12,
			insets   = { left = 3, right = 3, top = 3, bottom = 3 },
		});

		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		fs:SetPoint("CENTER", btn, "CENTER", 0, 0);
		fs:SetText(opt.text);
		btn.labelFS = fs;
		btn.value   = opt.value;

		btn:SetScript("OnClick", function(self)
			K.SaveConfig(setting, self.value);
			Refresh();
			if onChange then onChange(self.value); end
		end);

		if tooltipText then
			btn:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(opt.text, 1, 1, 1);
				GameTooltip:AddLine(tooltipText, nil, nil, nil, true);
				GameTooltip:Show();
			end);
			btn:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		end

		table.insert(buttons, btn);
	end

	Refresh();
	container.Refresh = Refresh;
	return container;
end

-- =========================================================
-- Import/Export Popup Frame
-- =========================================================
-- Hay DOS ventanas independientes, y tienen que seguir siendolo:
--   "Profile" -> configuracion del addon (K.ExportProfile)
--   "Slot"    -> barras, macros y bindeos del personaje (K.SlotExport)
-- Son cosas distintas y mezclarlas seria confuso, asi que cada una tiene su
-- propio frame cacheado por clave.
local ioFrames = {};

local function CreateImportExportFrame(key)
	key = key or "Profile";
	if ioFrames[key] then return ioFrames[key]; end

	local importExportFrame = CreateFrame("Frame", "Nidhaus" .. key .. "Frame", UIParent);
	ioFrames[key] = importExportFrame;
	importExportFrame:SetSize(500, 320);
	importExportFrame:SetPoint("CENTER");
	importExportFrame:SetFrameStrata("FULLSCREEN_DIALOG");
	importExportFrame:SetMovable(true);
	importExportFrame:EnableMouse(true);
	importExportFrame:RegisterForDrag("LeftButton");
	importExportFrame:SetScript("OnDragStart", importExportFrame.StartMoving);
	importExportFrame:SetScript("OnDragStop", importExportFrame.StopMovingOrSizing);
	importExportFrame:SetClampedToScreen(true);
	importExportFrame:Hide();

	importExportFrame:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	});

	importExportFrame.title = importExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	importExportFrame.title:SetPoint("TOP", 0, -16);

	local closeBtn = CreateFrame("Button", nil, importExportFrame, "UIPanelCloseButton");
	closeBtn:SetPoint("TOPRIGHT", -5, -5);
	closeBtn:SetScript("OnClick", function() importExportFrame:Hide(); end);

	local scrollFrame = CreateFrame("ScrollFrame", "Nidhaus" .. key .. "ScrollFrame", importExportFrame, "UIPanelScrollFrameTemplate");
	scrollFrame:SetPoint("TOPLEFT", 20, -42);
	scrollFrame:SetPoint("BOTTOMRIGHT", -38, 56);

	local scrollBG = CreateFrame("Frame", nil, importExportFrame);
	scrollBG:SetPoint("TOPLEFT", scrollFrame, -4, 4);
	scrollBG:SetPoint("BOTTOMRIGHT", scrollFrame, 24, -4);
	scrollBG:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 14,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	scrollBG:SetBackdropColor(0, 0, 0, 0.8);
	scrollBG:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8);

	local editBox = CreateFrame("EditBox", "Nidhaus" .. key .. "EditBox", scrollFrame);
	editBox:SetMultiLine(true);
	editBox:SetAutoFocus(false);
	editBox:SetFontObject("ChatFontNormal");
	editBox:SetWidth(scrollFrame:GetWidth() - 10);
	editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
	scrollFrame:SetScrollChild(editBox);

	-- FIX: Set minimum height so entire scroll area is clickable
	local function UpdateEditBoxHeight()
		local scrollH = scrollFrame:GetHeight() or 200;
		local textH = editBox:GetHeight() or 0;
		if textH < scrollH then editBox:SetHeight(scrollH); end
	end
	editBox:SetScript("OnTextChanged", function(self, userInput) UpdateEditBoxHeight(); end);
	editBox:SetScript("OnShow", function(self) UpdateEditBoxHeight(); end);

	-- FIX: Click on background area focuses editbox
	scrollBG:EnableMouse(true);
	scrollBG:SetScript("OnMouseDown", function() editBox:SetFocus(); end);

	importExportFrame.editBox = editBox;

	local actionBtn = CreateFrame("Button", nil, importExportFrame, "UIPanelButtonTemplate");
	actionBtn:SetPoint("BOTTOMRIGHT", -20, 18);
	actionBtn:SetSize(120, 25);
	importExportFrame.actionBtn = actionBtn;

	local cancelBtn = CreateFrame("Button", nil, importExportFrame, "UIPanelButtonTemplate");
	cancelBtn:SetPoint("RIGHT", actionBtn, "LEFT", -10, 0);
	cancelBtn:SetSize(120, 25);
	cancelBtn:SetText(L["PROFILE_CANCEL"] or "Cancel");
	cancelBtn:SetScript("OnClick", function() importExportFrame:Hide(); end);
	importExportFrame.cancelBtn = cancelBtn;

	importExportFrame.statusText = importExportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	importExportFrame.statusText:SetPoint("BOTTOMLEFT", 20, 24);
	importExportFrame.statusText:SetText("");

	return importExportFrame;
end

local function ShowExportProfile()
	local frame = CreateImportExportFrame("Profile");
	frame.title:SetText(L["PROFILE_EXPORT_TITLE"] or "|cffFFD100Export Profile|r");
	frame.statusText:SetText(L["PROFILE_EXPORT_HINT"] or "|cffAAAAAA(Ctrl+A to select all, Ctrl+C to copy)|r");

	local data, err = K.ExportProfile();
	if not data then
		frame.editBox:SetText((L["ERR_PREFIX"] or "Error: ") .. tostring(err));
	else
		frame.editBox:SetText(data);
	end

	frame.actionBtn:SetText(L["BTN_CLOSE"] or "Close");
	frame.actionBtn:SetScript("OnClick", function() frame:Hide(); end);
	frame.cancelBtn:Hide();
	frame:Show();
	frame.editBox:SetFocus();
	frame.editBox:HighlightText();
end

local function ShowImportProfile()
	local frame = CreateImportExportFrame("Profile");
	frame.title:SetText(L["PROFILE_IMPORT_TITLE"] or "|cffFFAA00Import Profile|r");
	frame.statusText:SetText(L["PROFILE_IMPORT_HINT"] or "|cffAAAAAA(Paste your profile string, then click Import)|r");
	frame.editBox:SetText("");
	frame.editBox:SetFocus();
	frame.cancelBtn:Show();

	frame.actionBtn:SetText(L["PROFILE_IMPORT_BTN"] or "Import");
	frame.actionBtn:SetScript("OnClick", function()
		local text = frame.editBox:GetText();
		if not text or text == "" then
			frame.statusText:SetText("|cffFF0000" .. (L["PROFILE_IMPORT_EMPTY"] or "Paste a profile string first!") .. "|r");
			return;
		end

		local ok, err = K.ImportProfile(text);
		if not ok then
			frame.statusText:SetText("|cffFF0000" .. (L["PROFILE_IMPORT_ERROR"] or "Error: ") .. tostring(err) .. "|r");
			return;
		end

		frame:Hide();
		print("|cffFFD100NUF:|r " .. (L["PROFILE_IMPORT_SUCCESS"] or "Profile imported! Reloading..."));
		ReloadUI();
	end);

	frame:Show();
end



-- =========================================================
-- CHARACTER SETUP (barras / macros / bindeos)
--
-- OJO: esto NO son los perfiles de arriba. Los perfiles guardan la
-- configuracion del ADDON. Esto guarda lo del PERSONAJE: que hechizo hay en
-- cada casilla, las macros y las teclas. Son dos sistemas separados a
-- proposito, con su propio almacenamiento y su propia ventana.
-- =========================================================
local slotStatus;   -- fontstring de feedback, se asigna al armar el panel

local function SlotSay(text, isError)
	if not slotStatus then return; end
	slotStatus:SetText((isError and "|cffFF5555" or "|cff88FF88") .. tostring(text) .. "|r");
end

local function ShowSlotExport()
	local frame = CreateImportExportFrame("Slot");
	frame.title:SetText(L["SLOT_EXPORT_TITLE"] or "|cffFFD100Export Character Setup|r");
	frame.statusText:SetText(L["SLOT_EXPORT_HINT"] or "");

	local ok, data = pcall(K.SlotExport);
	frame.editBox:SetText((ok and data) or ("Error: " .. tostring(data)));

	frame.actionBtn:SetText(L["BTN_CLOSE"] or "Close");
	frame.actionBtn:SetScript("OnClick", function() frame:Hide(); end);
	frame.cancelBtn:Hide();
	frame:Show();
	frame.editBox:SetFocus();
	frame.editBox:HighlightText();
end

StaticPopupDialogs["NUF_SLOT_IMPORT"] = {
	text = "%s", button1 = ACCEPT or "Accept", button2 = CANCEL or "Cancel",
	timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
	OnAccept = function(self)
		local data = self and self.data;
		if type(data) ~= "table" then return; end
		local ok, a, b = K.SlotImport(data.text);
		if ok then
			SlotSay(string.format(L["SLOT_DONE_IMPORT"] or "Setup applied: %d slots, %d keybinds.", a or 0, b or 0));
			if data.frame then data.frame:Hide(); end
		else
			SlotSay(tostring(a), true);
		end
	end,
};

local function ShowSlotImport()
	local frame = CreateImportExportFrame("Slot");
	frame.title:SetText(L["SLOT_IMPORT_TITLE"] or "|cffFFAA00Import Character Setup|r");
	frame.statusText:SetText(L["SLOT_IMPORT_HINT"] or "");
	frame.editBox:SetText("");
	frame.cancelBtn:Show();

	frame.actionBtn:SetText(L["SLOT_BTN_IMPORT"] or "Import Setup");
	frame.actionBtn:SetScript("OnClick", function()
		local text = frame.editBox:GetText();
		if not text or text == "" then
			frame.statusText:SetText("|cffFF5555" .. (L["SLOT_ERR_EMPTY"] or "Paste a string first.") .. "|r");
			return;
		end
		local dialog = StaticPopup_Show("NUF_SLOT_IMPORT",
			string.format(L["SLOT_CONFIRM_IMPORT"] or "Apply this setup to %s?", UnitName("player") or "?"));
		if dialog then dialog.data = { text = text, frame = frame }; end
	end);

	frame:Show();
	frame.editBox:SetFocus();
end

K.OpenSlotProfiles = ShowSlotExport;

-- Los tres borrados, cada uno con su confirmacion. Todos hacen backup
-- automatico antes, asi que Deshacer siempre tiene a que volver.
StaticPopupDialogs["NUF_SLOT_WIPEBARS"] = {
	text = "%s", button1 = ACCEPT or "Accept", button2 = CANCEL or "Cancel",
	timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
	OnAccept = function()
		local ok, n = K.SlotWipeBars();
		if ok then SlotSay(string.format(L["SLOT_DONE_WIPEBARS"] or "Cleared %d slots.", n or 0));
		else SlotSay(tostring(n), true); end
	end,
};

StaticPopupDialogs["NUF_SLOT_WIPEMACROS"] = {
	text = "%s", button1 = ACCEPT or "Accept", button2 = CANCEL or "Cancel",
	timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
	OnAccept = function()
		local ok, n = K.SlotWipeMacros();
		if ok then SlotSay(string.format(L["SLOT_DONE_WIPEMACROS"] or "Deleted %d macros.", n or 0));
		else SlotSay(tostring(n), true); end
	end,
};

StaticPopupDialogs["NUF_SLOT_RESETBINDS"] = {
	text = "%s", button1 = ACCEPT or "Accept", button2 = CANCEL or "Cancel",
	timeout = 0, whileDead = 1, hideOnEscape = 1, preferredIndex = 3,
	OnAccept = function()
		K.SlotResetBindings();
		SlotSay(L["SLOT_DONE_RESETBINDS"] or "Default keybinds restored.");
	end,
};

-- Cuenta lo que se va a perder, para que la confirmacion diga un numero
-- concreto en vez de un "todo" abstracto.
local function CountSlots()
	local n = 0;
	for i = 1, 120 do if GetActionInfo(i) then n = n + 1; end end
	return n;
end

local function CountMacros()
	local g, c = GetNumMacros();
	return (g or 0) + (c or 0);
end

-- =========================================================
-- CHARACTER PROFILE SYSTEM
-- Cada personaje auto-guarda su config al login bajo
-- "Nombre - Reino [tipo]". El dropdown lista todos los
-- personajes que alguna vez usaron el addon.
-- =========================================================

local function GetRealmTag()
	-- Detecta el tipo de reino para el tag
	local realmType = tonumber(GetCVar("realmType")) or 0;
	if realmType == 1 then
		return " [PvP only]";
	elseif realmType == 4 then
		return " [RP]";
	elseif realmType == 6 then
		return " [RP-PvP]";
	end
	return "";
end

local function GetCurrentCharKey()
	local name = UnitName("player") or "Unknown";
	local realm = GetRealmName() or "Unknown";
	local tag = GetRealmTag();
	return name .. " - " .. realm .. tag;
end

local function GetCharProfiles()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.CharProfiles then NidhausUnitFramesDB.CharProfiles = {}; end
	return NidhausUnitFramesDB.CharProfiles;
end

-- Guarda la config del personaje actual en CharProfiles
function K.SaveCurrentCharProfile()
	local data, err = K.ExportProfile();
	if not data then return false, err; end
	local key = GetCurrentCharKey();
	GetCharProfiles()[key] = data;
	return true, key;
end

-- Copia la config de otro personaje al actual (requiere ReloadUI)
local function CopyCharProfile(key)
	local profiles = GetCharProfiles();
	if not profiles[key] then return false, "Profile not found"; end
	local ok, err = K.ImportProfile(profiles[key]);
	if not ok then return false, err; end
	return true;
end

local function GetCharProfileNames()
	local names = {};
	for key in pairs(GetCharProfiles()) do
		table.insert(names, key);
	end
	table.sort(names);
	return names;
end

-- Auto-save al login (después de que ConfigManager carga la DB)
local charProfileInit = CreateFrame("Frame");
charProfileInit:RegisterEvent("PLAYER_LOGIN");
charProfileInit:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		-- Esperar un frame para asegurarse de que ConfigManager terminó
		self:SetScript("OnUpdate", function(s)
			s:SetScript("OnUpdate", nil);
			K.SaveCurrentCharProfile();
		end);
	end
end);

-- =========================================================
-- PopulateExtraTab
-- =========================================================
function K.PopulateExtraTab(panel)
	-- Declarada aca arriba a proposito: el OnShow del panel se arma antes
	-- que la seccion Character Setup, y sin esto la referencia caeria en una
	-- global inexistente en vez de en esta local.
	local RefreshSlotDropdown;

	-- ══════════════════════════════════════════════════════════
	-- SECTION 1: PROFILES
	-- Layout igual a DebuffFilter:
	--   Fila 1: [titulo]  [descripcion]
	--   Fila 2: "Copy profile from:"
	--   Fila 3: [dropdown_____________] [Copy] [Export Profile] [Import Profile]
	-- ══════════════════════════════════════════════════════════

	-- Caja con fondo oscuro y borde azul
	local profileBox = CreateFrame("Frame", nil, panel);
	profileBox:SetPoint("TOPLEFT", 10, -10);
	profileBox:SetPoint("TOPRIGHT", -10, -10);
	profileBox:SetHeight(96);
	-- Borde fino tipo tooltip, igual que el resto de los recuadros del panel
	profileBox:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	});
	profileBox:SetBackdropColor(0.05, 0.07, 0.14, 0.85);
	profileBox:SetBackdropBorderColor(0.30, 0.55, 0.95, 0.70);



	-- FILA 1: titulo + descripcion
	local profileTitle = profileBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	profileTitle:SetPoint("TOPLEFT", 16, -18);
	profileTitle:SetText(L["HEADER_PROFILES"] or "|cff4FC3F7Profiles|r");

	local profileSub = profileBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	profileSub:SetPoint("LEFT", profileTitle, "RIGHT", 12, -1);
	profileSub:SetText("|cff8EAEC9" .. (L["DESC_PROFILES"] or "Export your config to share or backup, import to restore.") .. "|r");

	-- FILA 2: label "Copy profile from:"
	local copyLabel = profileBox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	copyLabel:SetPoint("TOPLEFT", 16, -44);
	copyLabel:SetText(L["PROFILE_COPY_FROM"] or "Copy profile from:");

	-- Status de feedback (mismo nivel que el label, lado derecho)
	local profileStatus = profileBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	profileStatus:SetPoint("BOTTOMRIGHT", profileBox, "BOTTOMRIGHT", -16, 10);
	profileStatus:SetText("");

	local selectedProfile = nil;

	-- FILA 3: [dropdown] [Copy] [Export Profile] [Import Profile]
	-- Anclados desde la DERECHA para garantizar que siempre entren ambos idiomas
	local importBtn = CreateFrame("Button", nil, profileBox, "UIPanelButtonTemplate");
	importBtn:SetPoint("BOTTOMRIGHT", profileBox, "BOTTOMRIGHT", -14, 10);
	importBtn:SetSize(120, 24);
	importBtn:SetText(L["BTN_IMPORT"] or "Import Profile");
	importBtn:SetScript("OnClick", ShowImportProfile);

	local exportBtn = CreateFrame("Button", nil, profileBox, "UIPanelButtonTemplate");
	exportBtn:SetPoint("RIGHT", importBtn, "LEFT", -5, 0);
	exportBtn:SetSize(120, 24);
	exportBtn:SetText(L["BTN_EXPORT"] or "Export Profile");
	exportBtn:SetScript("OnClick", ShowExportProfile);

	local copyBtn = CreateFrame("Button", nil, profileBox, "UIPanelButtonTemplate");
	copyBtn:SetPoint("RIGHT", exportBtn, "LEFT", -5, 0);
	copyBtn:SetSize(72, 24);
	copyBtn:SetText(L["BTN_COPY"] or "Copy");
	copyBtn:SetScript("OnClick", function()
		if not selectedProfile then
			profileStatus:SetText("|cffFF5555" .. (L["PROFILE_ERR_SELECT"] or "Select a profile first!") .. "|r");
			return;
		end
		local currentKey = GetCurrentCharKey();
		if selectedProfile == currentKey then
			profileStatus:SetText("|cffFFAA00" .. (L["PROFILE_ERR_CURRENT"] or "That is your current profile!") .. "|r");
			return;
		end
		local ok, err = CopyCharProfile(selectedProfile);
		if ok then
			print("|cff4FC3F7[NUF]|r " .. (L["PROFILE_COPYING"] or "Copying profile from") .. " '" .. selectedProfile .. "'...");
			ReloadUI();
		else
			profileStatus:SetText("|cffFF5555" .. tostring(err) .. "|r");
		end
	end);

	-- Dropdown — ocupa el espacio restante desde el borde izquierdo hasta el botón Copy
	-- UIDropDownMenu tiene 32px extra de padding propio, compensar con ancho lógico
	local copyDD = CreateFrame("Frame", "NidhausProfileCopyDD", profileBox, "UIDropDownMenuTemplate");
	copyDD:SetPoint("BOTTOMLEFT", profileBox, "BOTTOMLEFT", 6, 4);
	-- El ancho se calcula para llegar hasta el botón Copy sin solaparse
	-- Anclar el borde derecho del frame del DD al borde izquierdo del copyBtn
	copyDD:SetPoint("RIGHT", copyBtn, "LEFT", 18, 0);

	local function RefreshDropdown()
		-- Calcular ancho real disponible para el dropdown
		local ddWidth = copyBtn:GetLeft() and (copyBtn:GetLeft() - profileBox:GetLeft() - 40) or 240;
		if ddWidth < 120 then ddWidth = 120; end
		UIDropDownMenu_SetWidth(copyDD, ddWidth - 32); -- compensar padding interno

		local names = GetCharProfileNames();
		local currentKey = GetCurrentCharKey();
		UIDropDownMenu_Initialize(copyDD, function(self, level)
			if #names == 0 then
				local info = UIDropDownMenu_CreateInfo();
				info.text = L["PROFILE_NONE_YET"] or "(No profiles yet)";
				info.disabled = true;
				info.notCheckable = true;
				UIDropDownMenu_AddButton(info, level);
			else
				for _, name in ipairs(names) do
					local info = UIDropDownMenu_CreateInfo();
					if name == currentKey then
						info.text = "|cffFFD700[" .. (L["PROFILE_CURRENT"] or "current") .. "] " .. name .. "|r";
					else
						info.text = name;
					end
					info.value = name;
					info.func = function(btn)
						selectedProfile = btn.value;
						UIDropDownMenu_SetText(copyDD, btn.value);
					end;
					info.checked = (selectedProfile == name);
					UIDropDownMenu_AddButton(info, level);
				end
			end
		end);
		UIDropDownMenu_SetText(copyDD, selectedProfile or "");
	end

	-- Actualizar al abrir el panel
	panel:SetScript("OnShow", function()
		K.SaveCurrentCharProfile();
		RefreshDropdown();
		if K.SlotSaveCurrentChar then K.SlotSaveCurrentChar(); end
		RefreshSlotDropdown();
	end);

	-- Primer refresh (al crear el panel por primera vez)
	RefreshDropdown();

	-- ══════════════════════════════════════════════════════════
	-- SECTION 2: CHARACTER SETUP
	-- Barras, macros y bindeos. Va en una caja aparte y con otro color de
	-- borde porque NO es lo mismo que los perfiles de arriba: aquellos son
	-- la config del addon, esto es el personaje.
	-- ══════════════════════════════════════════════════════════
	local slotBox = CreateFrame("Frame", nil, panel);
	slotBox:SetPoint("TOPLEFT", profileBox, "BOTTOMLEFT", 0, -14);
	slotBox:SetPoint("TOPRIGHT", profileBox, "BOTTOMRIGHT", 0, -14);
	slotBox:SetHeight(132);
	slotBox:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	});
	slotBox:SetBackdropColor(0.14, 0.09, 0.05, 0.85);
	slotBox:SetBackdropBorderColor(0.95, 0.70, 0.30, 0.70);

	local slotTitle = slotBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	slotTitle:SetPoint("TOPLEFT", 16, -14);
	slotTitle:SetText(L["HEADER_SLOTS"] or "|cffFFD100Character Setup|r");

	local slotSub = slotBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	slotSub:SetPoint("LEFT", slotTitle, "RIGHT", 12, -1);
	slotSub:SetText("|cffC9AE8E" .. (L["DESC_SLOTS"]
		or "Action bars, macros and keybinds. This is your character, not the addon settings.") .. "|r");

	slotStatus = slotBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	slotStatus:SetPoint("TOPLEFT", 16, -36);
	slotStatus:SetText("|cff8A8A8A" .. (L["SLOT_NOTE_LOGOUT"] or "") .. "|r");
	slotStatus:SetWidth(540);
	slotStatus:SetJustifyH("LEFT");

	-- FILA 1: [dropdown de personajes] [Copiar] [Exportar] [Importar]
	local slotImportBtn = CreateFrame("Button", nil, slotBox, "UIPanelButtonTemplate");
	slotImportBtn:SetPoint("TOPRIGHT", slotBox, "TOPRIGHT", -14, -66);
	slotImportBtn:SetSize(110, 24);
	slotImportBtn:SetText(L["SLOT_BTN_IMPORT"] or "Import Setup");
	slotImportBtn:SetScript("OnClick", ShowSlotImport);

	local slotExportBtn = CreateFrame("Button", nil, slotBox, "UIPanelButtonTemplate");
	slotExportBtn:SetPoint("RIGHT", slotImportBtn, "LEFT", -5, 0);
	slotExportBtn:SetSize(110, 24);
	slotExportBtn:SetText(L["SLOT_BTN_EXPORT"] or "Export Setup");
	slotExportBtn:SetScript("OnClick", ShowSlotExport);

	local selectedSlotChar = nil;

	local slotCopyBtn = CreateFrame("Button", nil, slotBox, "UIPanelButtonTemplate");
	slotCopyBtn:SetPoint("RIGHT", slotExportBtn, "LEFT", -5, 0);
	slotCopyBtn:SetSize(72, 24);
	slotCopyBtn:SetText(L["BTN_COPY"] or "Copy");
	slotCopyBtn:SetScript("OnClick", function()
		if not selectedSlotChar then
			SlotSay(L["PROFILE_ERR_SELECT"] or "Select a profile first!", true);
			return;
		end
		if selectedSlotChar == K.SlotGetCharKey() then
			SlotSay(L["PROFILE_ERR_CURRENT"] or "That is your current profile!", true);
			return;
		end
		local ok, a, b = K.SlotCopyFromChar(selectedSlotChar);
		if ok then
			SlotSay(string.format(L["SLOT_DONE_IMPORT"] or "Setup applied: %d slots, %d keybinds.", a or 0, b or 0));
		else
			SlotSay(tostring(a), true);
		end
	end);

	local slotDD = CreateFrame("Frame", "NidhausSlotCopyDD", slotBox, "UIDropDownMenuTemplate");
	slotDD:SetPoint("TOPLEFT", slotBox, "TOPLEFT", 6, -64);
	slotDD:SetPoint("RIGHT", slotCopyBtn, "LEFT", 18, 0);

	function RefreshSlotDropdown()
		local width = slotCopyBtn:GetLeft() and (slotCopyBtn:GetLeft() - slotBox:GetLeft() - 40) or 240;
		if width < 120 then width = 120; end
		UIDropDownMenu_SetWidth(slotDD, width - 32);

		local names = K.SlotGetCharNames();
		local current = K.SlotGetCharKey();
		UIDropDownMenu_Initialize(slotDD, function(self, level)
			if #names == 0 then
				local info = UIDropDownMenu_CreateInfo();
				info.text = L["SLOT_NONE_YET"] or "(No characters yet)";
				info.disabled = true;
				info.notCheckable = true;
				UIDropDownMenu_AddButton(info, level);
				return;
			end
			for _, name in ipairs(names) do
				local info = UIDropDownMenu_CreateInfo();
				if name == current then
					info.text = "|cffFFD700[" .. (L["PROFILE_CURRENT"] or "current") .. "] " .. name .. "|r";
				else
					info.text = name;
				end
				info.value = name;
				info.func = function(btn)
					selectedSlotChar = btn.value;
					UIDropDownMenu_SetText(slotDD, btn.value);
				end;
				info.checked = (selectedSlotChar == name);
				UIDropDownMenu_AddButton(info, level);
			end
		end);
		UIDropDownMenu_SetText(slotDD, selectedSlotChar or "");
	end

	-- FILA 2: los borrados + deshacer
	local undoBtn = CreateFrame("Button", nil, slotBox, "UIPanelButtonTemplate");
	undoBtn:SetPoint("BOTTOMRIGHT", slotBox, "BOTTOMRIGHT", -14, 12);
	undoBtn:SetSize(90, 24);
	undoBtn:SetText(L["SLOT_BTN_UNDO"] or "Undo");
	undoBtn:SetScript("OnClick", function()
		local ok, a = K.SlotRestoreBackup();
		if ok then SlotSay(L["SLOT_BACKUP_DONE"] or "Backup restored.");
		else SlotSay(tostring(a), true); end
	end);

	local bindsBtn = CreateFrame("Button", nil, slotBox, "UIPanelButtonTemplate");
	bindsBtn:SetPoint("RIGHT", undoBtn, "LEFT", -5, 0);
	bindsBtn:SetSize(120, 24);
	bindsBtn:SetText(L["SLOT_BTN_RESETBINDS"] or "Default Keys");
	bindsBtn:SetScript("OnClick", function()
		StaticPopup_Show("NUF_SLOT_RESETBINDS",
			L["SLOT_CONFIRM_RESETBINDS"] or "Restore default keybinds?");
	end);

	local macrosBtn = CreateFrame("Button", nil, slotBox, "UIPanelButtonTemplate");
	macrosBtn:SetPoint("RIGHT", bindsBtn, "LEFT", -5, 0);
	macrosBtn:SetSize(110, 24);
	macrosBtn:SetText(L["SLOT_BTN_WIPEMACROS"] or "Delete Macros");
	macrosBtn:SetScript("OnClick", function()
		StaticPopup_Show("NUF_SLOT_WIPEMACROS",
			string.format(L["SLOT_CONFIRM_WIPEMACROS"] or "Delete ALL %d macros?", CountMacros()));
	end);

	local barsBtn = CreateFrame("Button", nil, slotBox, "UIPanelButtonTemplate");
	barsBtn:SetPoint("RIGHT", macrosBtn, "LEFT", -5, 0);
	barsBtn:SetSize(110, 24);
	barsBtn:SetText(L["SLOT_BTN_WIPEBARS"] or "Clear Bars");
	barsBtn:SetScript("OnClick", function()
		StaticPopup_Show("NUF_SLOT_WIPEBARS",
			string.format(L["SLOT_CONFIRM_WIPEBARS"] or "Clear ALL %d slots?", CountSlots()));
	end);

	RefreshSlotDropdown();

	-- ══════════════════════════════════════════════════════════
	-- NOTA: las "Extra Options" (auto reparar, vender basura, chat)
	-- se mudaron a Interface > General Settings y Interface > Chat.
	-- ══════════════════════════════════════════════════════════
	local movedNote = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	movedNote:SetPoint("TOPLEFT", slotBox, "BOTTOMLEFT", 6, -14);
	movedNote:SetWidth(560);
	movedNote:SetJustifyH("LEFT");
	movedNote:SetText("|cff8A8A8A" .. (L["NOTE_EXTRA_MOVED"]
		or "Auto repair, sell junk and the chat options moved to Interface > General Settings and Interface > Chat.") .. "|r");
end
