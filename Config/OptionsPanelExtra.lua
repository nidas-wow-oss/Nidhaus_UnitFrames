local AddOnName, ns = ...;
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
-- Import/Export Popup Frame
-- =========================================================
local importExportFrame;

local function CreateImportExportFrame()
	if importExportFrame then return importExportFrame; end

	importExportFrame = CreateFrame("Frame", "NidhausProfileFrame", UIParent);
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

	local scrollFrame = CreateFrame("ScrollFrame", "NidhausProfileScrollFrame", importExportFrame, "UIPanelScrollFrameTemplate");
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

	local editBox = CreateFrame("EditBox", "NidhausProfileEditBox", scrollFrame);
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
	local frame = CreateImportExportFrame();
	frame.title:SetText(L["PROFILE_EXPORT_TITLE"] or "|cff00FF00Export Profile|r");
	frame.statusText:SetText(L["PROFILE_EXPORT_HINT"] or "|cffAAAAAA(Ctrl+A to select all, Ctrl+C to copy)|r");

	local data, err = K.ExportProfile();
	if not data then
		frame.editBox:SetText("Error: " .. tostring(err));
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
	local frame = CreateImportExportFrame();
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
		print("|cff00FF00NUF:|r " .. (L["PROFILE_IMPORT_SUCCESS"] or "Profile imported! Reloading..."));
		ReloadUI();
	end);

	frame:Show();
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
	profileBox:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 26,
		insets = { left = 9, right = 9, top = 9, bottom = 9 },
	});
	profileBox:SetBackdropColor(0.04, 0.06, 0.14, 0.95);
	profileBox:SetBackdropBorderColor(0.25, 0.50, 1.0, 0.85);



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
				info.text = "(No profiles yet)";
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
	end);

	-- Primer refresh (al crear el panel por primera vez)
	RefreshDropdown();

	-- ══════════════════════════════════════════════════════════
	-- SECTION 2: EXTRA OPTIONS
	-- ══════════════════════════════════════════════════════════
	local extraHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	extraHeader:SetPoint("TOPLEFT", profileBox, "BOTTOMLEFT", 4, -10);
	extraHeader:SetText(L["HEADER_EXTRA"]);

	local extraDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	extraDesc:SetPoint("TOPLEFT", extraHeader, "BOTTOMLEFT", 0, -4);
	extraDesc:SetText(L["DESC_EXTRA"]);

	local yPos = -162;

	-- Arena Countdown
	local acdHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	acdHeader:SetPoint("TOPLEFT", 20, yPos);
	acdHeader:SetText(L["HEADER_ARENA_COUNTDOWN"] or "|cff00FF00Arena Countdown|r");

	yPos = yPos - 22;
	CreateCheckBox(panel,
		L["CB_ARENA_COUNTDOWN"] or "Arena Countdown + Shadow Sight Timer",
		"ArenaCountDown", 20, yPos,
		L["TIP_ArenaCountDown"] or "Shows large countdown numbers before arena starts.\nAlso shows Shadow Sight orb spawn timer.");

	-- Utility Options
	yPos = yPos - 40;
	local utilHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	utilHeader:SetPoint("TOPLEFT", 20, yPos);
	utilHeader:SetText(L["HEADER_UTILITY"] or "|cff00FF00Utility|r");

	yPos = yPos - 22;
	CreateCheckBox(panel,
		L["CB_AUTO_SELL"] or "Auto Sell Gray Items",
		"AutoSellGray", 20, yPos,
		L["TIP_AutoSellGray"] or "Automatically sells all gray (junk) items when you open a vendor.");

	yPos = yPos - 26;
	CreateCheckBox(panel,
		L["CB_AUTO_REPAIR"] or "Auto Repair",
		"AutoRepair", 20, yPos,
		L["TIP_AutoRepair"] or "Automatically repairs all items when you open a vendor.\nUses guild bank first if available.\nHold Shift to skip.");

	yPos = yPos - 26;
	CreateCheckBox(panel,
		L["CB_ERROR_HIDE"] or "Hide Errors in Combat",
		"ErrorHideInCombat", 20, yPos,
		L["TIP_ErrorHideInCombat"] or "Hides red error messages during combat.\nShows them again when combat ends.");
end