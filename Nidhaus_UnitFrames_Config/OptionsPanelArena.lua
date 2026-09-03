-- Este archivo vive en Nidhaus_UnitFrames_Config, un addon aparte que se
-- carga SOLO cuando abris el panel (LoadOnDemand). Por eso no recibe el
-- namespace por "...", que es privado de cada addon: lo toma de la global
-- que publica el addon principal en Core/Init.lua.
local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

local flatSubControls = {};
local castBarSubControls = {};
local castBarBody;   -- cuerpo desplegable de la seccion Cast Bar
local petStyleControls = {};
local arenaShowBtn;
local dropdownCount = 0;
-- FIX: Constante para loops de test mode (consistente con ArenaMover.MOVER_ARENA_COUNT)
local MOVER_ARENA_COUNT = 3;
local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;

local tooltips = {
	ArenaFrameOn            = "TIP_ArenaFrameOn",
	ArenaFrameScale         = "TIP_ArenaFrameScale",
	ArenaFrameSpacing       = "TIP_ArenaFrameSpacing",
	ArenaMirrorMode         = "TIP_ArenaMirrorMode",
	ArenaFrame_Trinkets     = "TIP_ArenaFrame_Trinkets",
	ArenaFrame_Trinket_Voice = "TIP_ArenaFrame_Trinket_Voice",
	ArenaFlatWidth          = "TIP_ArenaFlatWidth",
	ArenaFlatHealthBarHeight = "TIP_ArenaFlatHealthBarHeight",
	ArenaFlatPowerBarHeight = "TIP_ArenaFlatPowerBarHeight",
	ArenaFlatHealthFontSize = "TIP_ArenaFlatHealthFontSize",
	ArenaFlatPowerFontSize  = "TIP_ArenaFlatPowerFontSize",
	ArenaFlatMirrored       = "TIP_ArenaFlatMirrored",
	ArenaFlatStatusText     = "TIP_ArenaFlatStatusText",
	ArenaToTSquare          = "TIP_ArenaToTSquare",
	ArenaCastBarEnable      = "TIP_ArenaCastBarEnable",
	ArenaCastBarScale       = "TIP_ArenaCastBarScale",
	ArenaCastBarWidth       = "TIP_ArenaCastBarWidth",
};

local function AddTooltip(frame, setting)
	local tipKey = tooltips[setting];
	if not tipKey then return; end
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(setting, 1, 1, 1);
		GameTooltip:AddLine(L[tipKey] or tipKey, nil, nil, nil, true);
		GameTooltip:Show();
	end);
	frame:SetScript("OnLeave", function() GameTooltip:Hide(); end);
end

-- =========================================================
-- CreateCheckBox
-- =========================================================
local function CreateCheckBox(parent, label, setting, xOffset, yOffset)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
	cb:SetPoint("TOPLEFT", xOffset, yOffset);
	cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0);
	cb.text:SetText(label);
	cb:SetChecked(C[setting] or false);
	AddTooltip(cb, setting);

	cb:SetScript("OnClick", function(self)
		local checked = self:GetChecked() == 1 or self:GetChecked() == true;
		K.SaveConfig(setting, checked);
		if setting == "ArenaFrameOn" then
			-- Con el mod apagado se esconden TODAS las opciones del marco.
			-- La subpestaña Options (timers) sigue funcionando aparte.
			if K._UpdateArenaOptionsVisibility then K._UpdateArenaOptionsVisibility(); end
			if arenaShowBtn then
				if checked then arenaShowBtn:Show(); else arenaShowBtn:Hide(); end
			end
			-- FIX: Activar/desactivar el mod en vivo (antes no hacía nada)
			if checked then
				if K.EnableArenaFrameMod then K.EnableArenaFrameMod(); end
			else
				if K.DisableArenaFrameMod then K.DisableArenaFrameMod(); end
			end
		elseif setting == "ArenaFlatMirrored" then
			if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
		elseif setting == "ArenaFlatStatusText" then
			if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
		elseif setting == "ArenaToTSquare" or setting == "ArenaToTMirrored" then
			if K.RefreshArenaToTLayout then K.RefreshArenaToTLayout(); end
		elseif setting == "ArenaCastBarEnable" then
			if K.ToggleArenaCastBar then K.ToggleArenaCastBar(checked); end
			-- El cuerpo se encarga de mostrar/ocultar Y de colapsar el alto;
			-- despues hay que recalcular el alto de la seccion para que el
			-- scroll no quede con aire de mas (o de menos).
			if castBarBody then castBarBody:Refresh(); end
			if K._UpdateArenaLowerHeight then K._UpdateArenaLowerHeight(); end
			if K._RefreshArenaLayout then K._RefreshArenaLayout(); end
		elseif setting == "ArenaMirrorMode" then
			if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
		elseif setting == "ArenaFrame_Trinkets" then
			if K.ToggleArenaTrinketsTracking then K.ToggleArenaTrinketsTracking(checked); end
		elseif setting == "ArenaFrame_Trinket_Voice" then
			-- voice only applies on next trinket use
		elseif setting == "ArenaPetFrameShow" then
			-- Toggle pet frames in test mode - usar nombre global
			if NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown then
				for i = 1, MOVER_ARENA_COUNT do
					local petFrame = _G["ArenaEnemyFrame"..i.."PetFrame"];
					if petFrame then
						-- FIX: Capture Blizzard default before any modifications
						if not petFrame._blizzDefaultPoints then
							petFrame._blizzDefaultPoints = {};
							for p = 1, petFrame:GetNumPoints() do
								petFrame._blizzDefaultPoints[p] = {petFrame:GetPoint(p)};
							end
						end
						if checked then
							-- FIX NUCLEAR: Override Hide() para bloquear el auto-hide de Blizzard
							if not petFrame._origHide then
								petFrame._origHide = petFrame.Hide;
							end
							petFrame.Hide = function() end;
							petFrame._testMode = true;
							petFrame:Show();
							if petFrame.healthbar then
								petFrame.healthbar:SetMinMaxValues(0, 100);
								petFrame.healthbar:SetValue(100);
								petFrame.healthbar:SetStatusBarColor(0, 1, 0);
							end
							if petFrame.manabar then
								petFrame.manabar:SetMinMaxValues(0, 100);
								petFrame.manabar:SetValue(100);
								petFrame.manabar:SetStatusBarColor(0, 0, 1);
							end
						else
							-- FIX: Restaurar Hide original antes de ocultar
							if petFrame._origHide then
								petFrame.Hide = petFrame._origHide;
								petFrame._origHide = nil;
							end
							petFrame._testMode = nil;
							petFrame:Hide();
						end
					end
				end
				-- Aplicar flat pet style si está activo
				if checked and K.IsFlatModeActive and K.IsFlatModeActive() and C.ArenaFlatPetStyle then
					if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
				end
				-- FIX: Restore saved positions and create drag overlays
				if checked then
					if K.RestorePetFramePositions then K.RestorePetFramePositions(); end
					if K.CreatePetFrameDragOverlays then K.CreatePetFrameDragOverlays(); end
				else
					-- Hide drag overlays when pet frames disabled
					if K.HidePetFrameDragOverlays then K.HidePetFrameDragOverlays(); end
				end
			end
		elseif setting == "ArenaFlatPetStyle" then
			-- Aplicar/remover flat pet style en tiempo real
			if NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown then
				if checked then
					-- Asegurar que los pet frames estén visibles
					if C.ArenaPetFrameShow then
						for i = 1, MOVER_ARENA_COUNT do
							local petFrame = _G["ArenaEnemyFrame"..i.."PetFrame"];
							if petFrame then
								-- FIX: Asegurar que Hide override está activo
								if not petFrame._origHide then
									petFrame._origHide = petFrame.Hide;
								end
								petFrame.Hide = function() end;
								petFrame._testMode = true;
								petFrame:Show();
								if petFrame.healthbar then
									petFrame.healthbar:SetMinMaxValues(0, 100);
									petFrame.healthbar:SetValue(100);
									petFrame.healthbar:SetStatusBarColor(0, 1, 0);
								end
								if petFrame.manabar then
									petFrame.manabar:SetMinMaxValues(0, 100);
									petFrame.manabar:SetValue(100);
									petFrame.manabar:SetStatusBarColor(0, 0, 1);
								end
							end
						end
					end
					if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
				else
					-- Remover flat pet styles
					if K.RemoveAllFlatPetStyles then K.RemoveAllFlatPetStyles(); end
				end
			end
		end
	end);
	return cb;
end

-- =========================================================
-- FormatSliderValue
-- =========================================================
local function FormatSliderValue(step, value)
	if step >= 1 then
		return string.format("%d", value);
	elseif step >= 0.1 then
		return string.format("%.1f", value);
	else
		return string.format("%.2f", value);
	end
end

-- =========================================================
-- CreateSlider (sArena style - matching reference image)
-- Yellow title on top, white value centered below,
-- small min/max on left/right sides
-- =========================================================
local function CreateSlider(parent, label, setting, minVal, maxVal, step, xOffset, yOffset)
	local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate");
	slider:SetPoint("TOPLEFT", xOffset, yOffset);
	slider:SetWidth(160);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	slider:SetValue(C[setting] or minVal);
	slider.setting = setting;

	-- Topes minimo y maximo abajo en cada punta; el titulo de la plantilla
	-- se esconde porque abajo se dibuja uno propio, centrado.
	K.UI.SliderEnds(slider, FormatSliderValue(step, minVal), FormatSliderValue(step, maxVal));

	-- Title (yellow GameFontNormal, centered above slider)
	local title = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	title:SetPoint("BOTTOM", slider, "TOP", 0, 3);
	title:SetText(label);

	-- Current value (white, centered below slider)
	slider.ValueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	slider.ValueText:SetPoint("TOP", slider, "BOTTOM", 0, -2);
	slider.ValueText:SetText(FormatSliderValue(step, C[setting] or minVal));

	-- Min value (small, left of slider)

	AddTooltip(slider, setting);

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value / step + 0.5) * step;
		self:SetValue(value);
		slider.ValueText:SetText(FormatSliderValue(step, value));
		K.SaveConfig(setting, value);

		if setting == "ArenaFrameScale" then
			if K.ApplyArenaScale then K.ApplyArenaScale(value); end
		elseif setting == "ArenaFrameSpacing" then
			if C.ArenaFrameOn and K.ApplyArenaSpacing then K.ApplyArenaSpacing(); end
		elseif setting == "ArenaFlatWidth" or setting == "ArenaFlatHealthBarHeight"
			or setting == "ArenaFlatPowerBarHeight" or setting == "ArenaFlatHealthFontSize"
			or setting == "ArenaFlatPowerFontSize" then
			if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
		elseif setting == "ArenaCastBarScale" then
			if K.UpdateArenaCastBarScale then K.UpdateArenaCastBarScale(value); end
		elseif setting == "ArenaCastBarWidth" then
			if K.UpdateArenaCastBarWidth then K.UpdateArenaCastBarWidth(value); end
		end
	end);

	return slider;
end

-- =========================================================
-- CreateDropdown
-- =========================================================
local function CreateDropdown(parent, labelText, setting, options, xOff, yOff, onChange)
	dropdownCount = dropdownCount + 1;
	local ddName = "NidhausArenaDD"..dropdownCount;

	local container = CreateFrame("Frame", nil, parent);
	container:SetPoint("TOPLEFT", xOff or 20, yOff);
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
			info.text = opt.text;
			info.value = opt.value;
			info.func = function(btn)
				UIDropDownMenu_SetSelectedValue(dd, btn.value);
				UIDropDownMenu_SetText(dd, btn.value);
				K.SaveConfig(setting, btn.value);
				if onChange then onChange(btn.value); end
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

-- =========================================================
-- CreateSeparator (white horizontal line)
-- =========================================================
local function CreateSeparator(parent, xOffset, yOffset, width)
	local sep = parent:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.3);
	sep:SetPoint("TOPLEFT", xOffset, yOffset);
	sep:SetSize(width or 530, 1);
	return sep;
end


-- =========================================================
-- PopulateArenaTab - Main layout con ScrollFrame
-- ORDEN: Header > Modules > Scale/Spacing > Style(+Flat collapsible) > CastBar
-- =========================================================
function K.PopulateArenaTab(panel)

	-- ═══════════════════════════════════════════════════════════
	-- SUBPESTANAS: Frames | Timers | Modulos
	-- ═══════════════════════════════════════════════════════════
	-- Lista lateral: Frames | Options.
	-- El usuario pidio que Options y Timers vivan en un solo submenu, asi
	-- que ahora "Options" junta Target of Target + cronometros + puntos.
	local sub = K.CreateSideList(panel, {
		{ name = L["SUBTAB_ARENA_FRAMES"]  or "Frames" },
		{ name = L["SUBTAB_ARENA_OPTIONS"] or "Options" },
		{ name = L["SUBTAB_ARENA_POINTS"]  or "Arena Points" },
	});

	local paneFrames  = sub[1];
	-- Options y Timers comparten el mismo pane (sub[2]).
	local paneModules = sub[2];
	local paneTimers  = sub[2];
	-- Los puntos de arena tienen su propia entrada, debajo de Options.
	local panePoints  = sub[3];

	local fCol1 = 30;
	local fCol2 = 285;

	-- Checkbox atado a un modulo (K.RegisterModule) en vez de a un setting C[]
	local function CreateModuleCheckBox(parent, label, moduleId, xOffset, yOffset, tipText)
		local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
		cb:SetPoint("TOPLEFT", xOffset, yOffset);
		cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0);
		cb.text:SetText(label);
		cb:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled(moduleId) or false);

		if tipText then
			cb:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(label, 1, 1, 1);
				GameTooltip:AddLine(tipText, nil, nil, nil, true);
				GameTooltip:Show();
			end);
			cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		end

		cb:SetScript("OnClick", function(self)
			local checked = self:GetChecked() == 1 or self:GetChecked() == true;
			if K.SetModuleEnabled then K.SetModuleEnabled(moduleId, checked); end
			if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox(moduleId); end
		end);

		if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox(moduleId, cb); end
		return cb;
	end

	-- ═══════════════════════════════════════════════════════════
	-- SUBPESTANA 1 · FRAMES
	-- Orden pedido: activar -> estilo -> opciones flat -> escala -> castbar
	-- ═══════════════════════════════════════════════════════════
	local content = paneFrames;

	local moveHint = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	moveHint:SetPoint("TOPLEFT", 20, -8);
	moveHint:SetText(L["ARENA_MOVE_HINT"] or "|cffFFAA00\226\128\160Shift+Alt+Click to move various elements|r");

	local yPos = -30;
	CreateCheckBox(content, L["CB_ARENA_ON"], "ArenaFrameOn", 20, yPos);

	arenaShowBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
	arenaShowBtn:SetPoint("TOPLEFT", 280, yPos + 2);
	arenaShowBtn:SetSize(180, 25);
	arenaShowBtn:SetText(L["BTN_SHOW_ARENA"]);
	arenaShowBtn:SetScript("OnClick", function()
		if IsActiveBattlefieldArena and IsActiveBattlefieldArena() then return; end
		if K.ToggleArenaFramesMover then K.ToggleArenaFramesMover(); end
	end);

	local function UpdateArenaShowButtonState()
		if not arenaShowBtn then return; end
		if IsActiveBattlefieldArena and IsActiveBattlefieldArena() then
			arenaShowBtn:Disable(); arenaShowBtn:SetAlpha(0.5);
		else
			arenaShowBtn:Enable(); arenaShowBtn:SetAlpha(1.0);
		end
	end
	arenaShowBtn:SetScript("OnShow", function() UpdateArenaShowButtonState(); end);
	local btnEvt = CreateFrame("Frame");
	btnEvt:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	btnEvt:RegisterEvent("PLAYER_ENTERING_WORLD");
	btnEvt:SetScript("OnEvent", function() UpdateArenaShowButtonState(); end);
	UpdateArenaShowButtonState();
	if not C.ArenaFrameOn then arenaShowBtn:Hide(); end

	local arenaHint = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	arenaHint:SetPoint("TOP", arenaShowBtn, "BOTTOM", 0, -2);
	arenaHint:SetText(L["ARENA_HINT"]);
	arenaHint:SetJustifyH("CENTER");

	-- ── ESTILO (primera opcion debajo de activar/desactivar) ──
	local styleSep = CreateSeparator(content, 14, -96, 540);
	local styleStartY = -110;

	local styleOptions = {
		{text = "Blizzard", value = "Blizzard"},
		{text = "Custom",   value = "Custom"},
		-- Compact: el mismo armado que Custom pero sin el marco decorado.
		-- Es el equivalente del estilo Compact que ya existia en el party.
		-- OJO: el VALOR sigue siendo "Compact" — es la clave guardada en la
		-- config y en el codigo del estilo. Solo cambia como se lee: ese
		-- estilo es el que dibuja los marcos sin borde alrededor.
		{text = L["ARENA_STYLE_COMPACT"] or "Borderless", value = "Compact"},
		-- Compact 2: con el marco del tema pw, el del PlayerFrame compacto.
		-- Igual que arriba: el valor guardado sigue siendo "Compact2".
		{text = L["ARENA_STYLE_COMPACT2"] or "Compact", value = "Compact2"},
		{text = "Flat",     value = "Flat"},
	};

	-- ── OPCIONES FLAT (solo visibles con estilo Flat) ──
	local flatAnchorY = styleStartY - 62;

	local flatWrapper = CreateFrame("Frame", "NidhausArenaFlatWrapper", content);
	flatWrapper:SetPoint("TOPLEFT", 14, flatAnchorY);
	flatWrapper:SetWidth(530);

	local fY = 0;

	local flatSep = flatWrapper:CreateTexture(nil, "ARTWORK");
	flatSep:SetTexture(1, 1, 1, 0.15);
	flatSep:SetPoint("TOPLEFT", 20, fY);
	flatSep:SetSize(500, 1);
	fY = fY - 10;

	local flatW = CreateSlider(flatWrapper, L["SLIDER_FLAT_WIDTH_FULL"] or L["SLIDER_FLAT_WIDTH"],
		"ArenaFlatWidth", 40, 400, 10, fCol1, fY);
	flatW:SetWidth(200); flatW.setting = "ArenaFlatWidth";
	table.insert(flatSubControls, flatW);

	local resetBtn = CreateFrame("Button", nil, flatWrapper, "UIPanelButtonTemplate");
	resetBtn:SetPoint("TOPLEFT", fCol1 + 250, fY + 2);
	resetBtn:SetSize(60, 22);
	resetBtn:SetText(L["BTN_RESET_FLAT"] or "Reset");
	resetBtn:SetScript("OnClick", function()
		local defs = {
			ArenaFlatWidth = 120, ArenaFlatHealthBarHeight = 20,
			ArenaFlatPowerBarHeight = 8, ArenaFlatHealthFontSize = 9,
			ArenaFlatPowerFontSize = 9, ArenaFlatMirrored = false,
			ArenaFlatStatusText = true,
		};
		for k, v in pairs(defs) do K.SaveConfig(k, v); C[k] = v; end
		for _, ctrl in ipairs(flatSubControls) do
			if ctrl.SetValue and ctrl.setting and C[ctrl.setting] ~= nil then
				ctrl:SetValue(C[ctrl.setting]);
				if ctrl.ValueText then
					ctrl.ValueText:SetText(FormatSliderValue(ctrl:GetValueStep() or 1, C[ctrl.setting]));
				end
			end
			if ctrl.SetChecked then ctrl:SetChecked(false); end
		end
		if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
	end);
	table.insert(flatSubControls, resetBtn);

	fY = fY - 55;
	local flatHB = CreateSlider(flatWrapper, L["SLIDER_FLAT_HB_HEIGHT_FULL"] or L["SLIDER_FLAT_HB_HEIGHT"],
		"ArenaFlatHealthBarHeight", 1, 50, 1, fCol1, fY);
	flatHB:SetWidth(130); flatHB.setting = "ArenaFlatHealthBarHeight";
	table.insert(flatSubControls, flatHB);

	local flatPB = CreateSlider(flatWrapper, L["SLIDER_FLAT_PB_HEIGHT_FULL"] or L["SLIDER_FLAT_PB_HEIGHT"],
		"ArenaFlatPowerBarHeight", 1, 50, 1, fCol2, fY);
	flatPB:SetWidth(130); flatPB.setting = "ArenaFlatPowerBarHeight";
	table.insert(flatSubControls, flatPB);

	fY = fY - 55;
	local flatHF = CreateSlider(flatWrapper, L["SLIDER_FLAT_HB_FONT_FULL"] or L["SLIDER_FLAT_HB_FONT"],
		"ArenaFlatHealthFontSize", 0, 50, 1, fCol1, fY);
	flatHF:SetWidth(130); flatHF.setting = "ArenaFlatHealthFontSize";
	table.insert(flatSubControls, flatHF);

	local flatPF = CreateSlider(flatWrapper, L["SLIDER_FLAT_PB_FONT_FULL"] or L["SLIDER_FLAT_PB_FONT"],
		"ArenaFlatPowerFontSize", 0, 50, 1, fCol2, fY);
	flatPF:SetWidth(130); flatPF.setting = "ArenaFlatPowerFontSize";
	table.insert(flatSubControls, flatPF);

	fY = fY - 35;
	local mirCB = CreateCheckBox(flatWrapper, L["CB_FLAT_MIRRORED_FULL"] or L["CB_FLAT_MIRRORED"],
		"ArenaFlatMirrored", fCol1, fY);
	table.insert(flatSubControls, mirCB);

	fY = fY - 30;
	local statusTextCB = CreateCheckBox(flatWrapper, L["CB_FLAT_STATUS_TEXT"] or "Force Status Text",
		"ArenaFlatStatusText", fCol1, fY);
	table.insert(flatSubControls, statusTextCB);

	fY = fY - 30;
	local flatWrapperHeight = math.abs(fY);
	flatWrapper:SetHeight(flatWrapperHeight);

	-- ── SECCION INFERIOR: escala/espaciado + barra de casteo ──
	-- Va en un solo frame para poder moverla segun si el bloque Flat esta visible.
	local lowerSection = CreateFrame("Frame", "NidhausArenaLowerSection", content);
	lowerSection:SetWidth(540);

	local lY = 0;
	CreateSeparator(lowerSection, 14, lY, 540);
	lY = lY - 24;

	local scaleS = CreateSlider(lowerSection, L["SLIDER_ARENA_SCALE"],
		"ArenaFrameScale", 0.5, 2.0, 0.1, fCol1, lY);
	scaleS:SetWidth(200);

	local spaceS = CreateSlider(lowerSection, L["SLIDER_ARENA_SPACING"],
		"ArenaFrameSpacing", 0, 100, 5, fCol2, lY);
	spaceS:SetWidth(200);

	lY = lY - 62;
	CreateSeparator(lowerSection, 14, lY, 540);
	lY = lY - 8;

	local cbH = lowerSection:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	cbH:SetPoint("TOPLEFT", 20, lY);
	cbH:SetText(L["HEADER_CASTBAR"]);

	lY = lY - 22;
	CreateCheckBox(lowerSection, L["CB_CASTBAR_ENABLE"], "ArenaCastBarEnable", 20, lY);

	-- Cuerpo desplegable: antes las sub-opciones se escondian pero dejaban
	-- el hueco, porque estaban en coordenadas fijas de lowerSection. Ahora
	-- viven en un cuerpo que vale 1px de alto cuando esta cerrado.
	-- 52 y no 34: los sliders dibujan su titulo POR ENCIMA de la barra
	-- (BOTTOMLEFT -> TOPLEFT), asi que el cuerpo tiene que arrancar mas
	-- abajo o "Cast Bar Scale" termina pisando el checkbox de arriba.
	lY = lY - 52;
	local cbBody = K.UI.Collapsible(lowerSection, 0, lY, 540, 58, function()
		return C.ArenaCastBarEnable and true or false;
	end);
	castBarBody = cbBody;

	local cbS = CreateSlider(cbBody, L["SLIDER_CASTBAR_SCALE"],
		"ArenaCastBarScale", 0.1, 5.0, 0.1, fCol1, 0);
	cbS:SetWidth(130); cbS.setting = "ArenaCastBarScale";
	table.insert(castBarSubControls, cbS);

	local cbW = CreateSlider(cbBody, L["SLIDER_CASTBAR_WIDTH"],
		"ArenaCastBarWidth", 10, 400, 5, fCol2, 0);
	cbW:SetWidth(130); cbW.setting = "ArenaCastBarWidth";
	table.insert(castBarSubControls, cbW);

	local cbResetBtn = CreateFrame("Button", nil, cbBody, "UIPanelButtonTemplate");
	cbResetBtn:SetPoint("TOPLEFT", fCol2 + 170, 2);
	cbResetBtn:SetSize(60, 22);
	cbResetBtn:SetText(L["BTN_RESET_CASTBAR"] or "Reset");
	cbResetBtn:SetScript("OnClick", function()
		-- El reset de verdad lo hace K.ResetCastBarPositions (ArenaFrame.lua):
		-- borra las posiciones guardadas, devuelve escala y ancho, y vuelve
		-- a colocar las barras en el acto. Antes esto repetia a medias esa
		-- logica aca y se olvidaba justamente de reposicionar, asi que las
		-- barras se quedaban donde las habias dejado hasta el /reload.
		if K.ResetCastBarPositions then K.ResetCastBarPositions(); end

		-- Y los sliders del panel al dia con lo que quedo.
		local defs = { ArenaCastBarScale = 1.0, ArenaCastBarWidth = 80 };
		for _, ctrl in ipairs(castBarSubControls) do
			if ctrl.SetValue and ctrl.setting and defs[ctrl.setting] ~= nil then
				ctrl:SetValue(defs[ctrl.setting]);
				if ctrl.ValueText then
					ctrl.ValueText:SetText(FormatSliderValue(ctrl:GetValueStep() or 1, defs[ctrl.setting]));
				end
			end
		end
	end);
	table.insert(castBarSubControls, cbResetBtn);

	-- lY queda apuntando al tope del cuerpo desplegable. El alto final de
	-- lowerSection lo calcula UpdateLowerHeight, mas abajo.
	local lowerSectionHeight = math.abs(lY);


	-- ── LAYOUT DINAMICO ──
	local function UpdateLayout(flatVisible)
		local lowerY;
		if flatVisible then
			lowerY = flatAnchorY - flatWrapperHeight - 10;
		else
			lowerY = flatAnchorY - 5;
		end
		lowerSection:ClearAllPoints();
		lowerSection:SetPoint("TOPLEFT", 0, lowerY);
		sub.SetContentHeight(1, math.abs(lowerY) + lowerSectionHeight);
	end

	K._RefreshArenaLayout = function()
		UpdateLayout((C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true));
	end

	local function SetFlatVisible(show)
		if show then flatWrapper:Show(); else flatWrapper:Hide(); end
		UpdateLayout(show);
	end

	-- STYLE CHANGE (logica original sin tocar)
	local function OnStyleChange(value)
		local isFlat = (value == "Flat");

		-- La casilla de color de clase solo vive en el estilo Blizzard, y al
		-- cambiar de estilo hay que repintar las barras: la regla de quien
		-- lleva color depende justamente del estilo.
		if K._UpdateArenaBlizzClassColorBox then K._UpdateArenaBlizzClassColorBox(); end
		if K.ToggleClassColors then K.ToggleClassColors(); end

		if isFlat and C.ArenaMirrorMode then
			if K.ResetMirrorCastBars then K.ResetMirrorCastBars(); end
		end

		if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end
		if K.RemoveAllFlatPetStyles then K.RemoveAllFlatPetStyles(); end

		-- Compact va POR LA MISMA RAMA que Custom: comparte todo el armado y
		-- solo se diferencia en que esconde el marco decorado (eso lo
		-- resuelve ArenaFrame.lua leyendo el estilo).
		--
		-- ACA ESTABA EL BUG: Compact caia en el "else" de abajo, que apaga
		-- ArenaCustomTexture y devuelve las texturas de Blizzard. Por eso
		-- elegirlo no hacia absolutamente nada.
		if value == "Custom" or value == "Compact" or value == "Compact2" then
			K.SaveConfig("ArenaCustomTexture", true);
			K.SaveConfig("ArenaFlatMode", false);
			if K.ToggleArenaCustomTexture then K.ToggleArenaCustomTexture(true); end
		elseif isFlat then
			K.SaveConfig("ArenaCustomTexture", false);
			K.SaveConfig("ArenaFlatMode", true);
			if K.ToggleArenaFlatMode then K.ToggleArenaFlatMode(true); end
		else
			K.SaveConfig("ArenaCustomTexture", false);
			K.SaveConfig("ArenaFlatMode", false);
			if K.ToggleArenaCustomTexture then K.ToggleArenaCustomTexture(false); end
		end

		SetFlatVisible(isFlat);

		if NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown then
			if K.StyleSingleArenaFrame then
				for i = 1, MOVER_ARENA_COUNT do
					local af = _G["ArenaEnemyFrame"..i];
					if af and af:IsShown() then K.StyleSingleArenaFrame(af, i); end
				end
			end
			local mover = _G["NUF_ArenaMover"];
			if mover and mover.bg then
				if isFlat then
					mover.bg:Hide();
				elseif not IsActiveBattlefieldArena or not IsActiveBattlefieldArena() then
					mover.bg:Show();
				end
			end
		end

		if K.RepositionAllSpecIcons then K.RepositionAllSpecIcons(); end
		if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
	end

	local styleDDContainer = CreateDropdown(content, L["LABEL_ARENA_STYLE"] or "Arena Style", "ArenaFrameStyle",
		styleOptions, 20, styleStartY, OnStyleChange);

	-- Casilla de color de clase, pegada al desplegable.
	--
	-- En los estilos retocados el color de clase va SIEMPRE y no se
	-- pregunta: ahi no es decoracion, es como distingues de un vistazo a
	-- quien le estas pegando, y apagarlo deja los tres marcos iguales. En
	-- el estilo Blizzard los marcos son los de fabrica y forzarlo los deja
	-- distintos del resto de la interfaz, asi que ese caso se elige. Por lo
	-- mismo la casilla solo se muestra con Blizzard puesto: en los demas
	-- estilos no decidiria nada y seria una casilla mentirosa.
	local blizzCCBox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate");
	-- x=182 y no mas: el desplegable de Pet Style arranca en 280 y el texto
	-- de esta casilla llega hasta ~271. Correrla mas los pisa.
	blizzCCBox:SetPoint("TOPLEFT", 182, styleStartY - 12);
	blizzCCBox:SetWidth(24); blizzCCBox:SetHeight(24);
	blizzCCBox.text = blizzCCBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	blizzCCBox.text:SetPoint("LEFT", blizzCCBox, "RIGHT", 2, 0);
	blizzCCBox.text:SetText(L["CB_ARENA_BLIZZ_CLASSCOLOR"] or "Class color");
	blizzCCBox:SetScript("OnClick", function(self)
		local checked = self:GetChecked() == 1 or self:GetChecked() == true;
		K.SaveConfig("ArenaBlizzardClassColor", checked);
		if K.ToggleClassColors then K.ToggleClassColors(checked); end
	end);

	local function UpdateBlizzClassColorBox()
		if (C.ArenaFrameStyle or "Custom") == "Blizzard" then
			blizzCCBox:SetChecked(C.ArenaBlizzardClassColor or false);
			blizzCCBox:Show();
		else
			blizzCCBox:Hide();
		end
	end
	UpdateBlizzClassColorBox();
	-- La llama OnStyleChange, que se define mas arriba y no la tiene en scope.
	K._UpdateArenaBlizzClassColorBox = UpdateBlizzClassColorBox;

	-- Pet Style dropdown (a la derecha de Arena Style)
	local petContainerRef;
	do
		dropdownCount = dropdownCount + 1;
		local petDDName = "NidhausArenaDD"..dropdownCount;

		local petContainer = CreateFrame("Frame", nil, content);
		petContainer:SetPoint("TOPLEFT", 280, styleStartY);
		petContainer:SetSize(200, 50);
		petContainerRef = petContainer;

		local petLabel = petContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		petLabel:SetPoint("TOPLEFT", 0, 0);
		petLabel:SetText("|cffffd100" .. (L["ARENA_PET_STYLE"] or "Pet Style") .. "|r");

		local petDD = CreateFrame("Frame", petDDName, petContainer, "UIDropDownMenuTemplate");
		petDD:SetPoint("TOPLEFT", -16, -16);
		UIDropDownMenu_SetWidth(petDD, 110);

		local petOpts = {
			{text = "Default", flat = false},
			{text = "Flat",    flat = true},
		};
		local function PetDDInit(self, level)
			for _, opt in ipairs(petOpts) do
				local info = UIDropDownMenu_CreateInfo();
				info.text = opt.text;
				info.value = opt.text;
				info.func = function(btn)
					UIDropDownMenu_SetSelectedValue(petDD, btn.value);
					UIDropDownMenu_SetText(petDD, btn.value);
					local isFlat = (btn.value == "Flat");
					K.SaveConfig("ArenaFlatPetStyle", isFlat);
					if isFlat and C.ArenaPetFrameShow then
						if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
						if K.RestorePetFramePositions then K.RestorePetFramePositions(); end
					elseif not isFlat then
						if K.RemoveAllFlatPetStyles then K.RemoveAllFlatPetStyles(); end
					end
				end;
				info.checked = (opt.flat == C.ArenaFlatPetStyle);
				UIDropDownMenu_AddButton(info, level);
			end
		end
		UIDropDownMenu_Initialize(petDD, PetDDInit);
		local initText = C.ArenaFlatPetStyle and "Flat" or "Default";
		UIDropDownMenu_SetSelectedValue(petDD, initText);
		UIDropDownMenu_SetText(petDD, initText);

		local resetPetBtn = CreateFrame("Button", nil, petContainer, "UIPanelButtonTemplate");
		resetPetBtn:SetPoint("LEFT", petDD, "RIGHT", -10, 2);
		resetPetBtn:SetSize(80, 22);
		resetPetBtn:SetText(L["BTN_RESET_PET_POS"] or "Reset");
		resetPetBtn:SetScript("OnClick", function()
			if NidhausUnitFramesDB then
				NidhausUnitFramesDB.PetFramePositions = nil;
			end
			local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
			if isFlat and C.ArenaFlatPetStyle then
				if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
			else
				for i = 1, MOVER_ARENA_COUNT do
					local pf = _G["ArenaEnemyFrame"..i.."PetFrame"];
					if pf and pf._blizzDefaultPoints then
						pf:ClearAllPoints();
						for _, pt in ipairs(pf._blizzDefaultPoints) do
							pf:SetPoint(unpack(pt));
						end
					end
				end
			end
		end);
	end

	-- ── MODULOS DEL MARCO DE ARENA ──
	-- Van en su propio frame ANCLADO AL CUERPO del cast bar. Antes usaban
	-- coordenadas fijas de lowerSection, asi que al colapsar el desplegable
	-- quedaba el hueco y esto no subia.
	local tail = CreateFrame("Frame", nil, lowerSection);
	tail:SetPoint("TOPLEFT", cbBody, "BOTTOMLEFT", 0, -16);
	tail:SetWidth(540);
	tail:SetHeight(120);

	CreateSeparator(tail, 14, 0, 540);

	local modH = tail:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	modH:SetPoint("TOPLEFT", 20, -12);
	modH:SetText(L["HEADER_ARENA_MODULES"]);

	CreateCheckBox(tail, L["CB_MIRROR_MODE"],   "ArenaMirrorMode",       20, -38);
	CreateCheckBox(tail, L["CB_TRINKET_TRACK"], "ArenaFrame_Trinkets",  285, -38);

	CreateCheckBox(tail, L["CB_TRINKET_VOICE"], "ArenaFrame_Trinket_Voice", 20, -66);
	CreateCheckBox(tail, L["CB_PET_FRAME_SHOW"] or "Show Pet Frame (Test Mode)",
		"ArenaPetFrameShow", 285, -66);

	-- El alto de la seccion depende de si el cast bar esta desplegado.
	local function UpdateLowerHeight()
		local open = C.ArenaCastBarEnable and true or false;
		lowerSectionHeight = math.abs(lY) + (open and 58 or 0) + 136;
		lowerSection:SetHeight(lowerSectionHeight);
	end
	K._UpdateArenaLowerHeight = UpdateLowerHeight;
	UpdateLowerHeight();

	-- ── Con el mod de arena apagado, ninguna de estas opciones tiene sentido.
	-- La subpestaña Options (timers, cola, ToT) NO se toca: funciona siempre,
	-- independientemente de este checkbox.
	local function UpdateArenaOptionsVisibility()
		local on = (C.ArenaFrameOn == true);
		local isFlat = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);

		if styleSep then if on then styleSep:Show(); else styleSep:Hide(); end end
		if K._UpdateArenaBoxes then K._UpdateArenaBoxes(); end
		if styleDDContainer then if on then styleDDContainer:Show(); else styleDDContainer:Hide(); end end
		if petContainerRef then if on then petContainerRef:Show(); else petContainerRef:Hide(); end end
		if lowerSection then if on then lowerSection:Show(); else lowerSection:Hide(); end end
		if flatWrapper then
			if on and isFlat then flatWrapper:Show(); else flatWrapper:Hide(); end
		end
		if arenaHint then if on then arenaHint:Show(); else arenaHint:Hide(); end end
		if moveHint then if on then moveHint:Show(); else moveHint:Hide(); end end

		if on then
			UpdateLayout(isFlat);
		else
			sub.SetContentHeight(1, 120);
		end
	end
	K._UpdateArenaOptionsVisibility = UpdateArenaOptionsVisibility;

	-- ── Cajas de seccion decorativas (solo con el mod activo) ──
	local arenaBoxes = {};
	if K.UI and K.UI.SectionBox then
		-- Enable + Show Arena
		table.insert(arenaBoxes, K.UI.SectionBox(content, nil, 8, -24, 580, 66));
		-- Estilos (dropdowns). Sin titulo: el label "Arena Style" del
		-- dropdown ya lo dice y quedaba duplicado.
		local b = K.UI.SectionBox(content, nil,
			8, styleStartY + 8, 580, 62);
		table.insert(arenaBoxes, b);
	end

	local function UpdateArenaBoxes()
		local on = (C.ArenaFrameOn == true);
		for _, b in ipairs(arenaBoxes) do
			if on then b:Show(); else b:Hide(); end
		end
	end

	local isCurrentlyFlat = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);
	SetFlatVisible(isCurrentlyFlat);
	UpdateArenaOptionsVisibility();
	UpdateArenaBoxes();
	K._UpdateArenaBoxes = UpdateArenaBoxes;

	-- ═══════════════════════════════════════════════════════════
	-- SECCION 3 · TIMERS  (cronometros propios de cada arena)
	-- ═══════════════════════════════════════════════════════════
	local tY = -12;

	local timH = paneTimers:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	timH:SetPoint("TOPLEFT", 20, tY);
	timH:SetText(L["HEADER_ARENA_TIMERS"] or "|cffFFD100Arena Timers|r");

	tY = tY - 20;
	local timHint = paneTimers:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	timHint:SetPoint("TOPLEFT", 22, tY);
	timHint:SetWidth(430);
	timHint:SetJustifyH("LEFT");
	timHint:SetText("|cff8EAEC9" .. (L["TIMERS_MOVE_NOTE"]
		or "/nuftimers to show them, Alt + drag to move") .. "|r");

	tY = tY - 30;
	CreateCheckBox(paneTimers, L["CB_ARENA_COUNTDOWN"] or "Arena Countdown + Shadow Sight",
		"ArenaCountDown", 20, tY);
	tY = tY - 28;
	CreateCheckBox(paneTimers, L["CB_ARENA_END"] or "Arena Time Remaining",
		"ArenaEndTimer", 20, tY);
	tY = tY - 28;
	CreateCheckBox(paneTimers, L["CB_DALARAN_PIPE"] or "Dalaran Waterfall Timer",
		"ArenaDalaranPipeTimer", 20, tY);
	tY = tY - 28;
	CreateCheckBox(paneTimers, L["CB_ROV_PILLARS"] or "Ring of Valor Pillar Timer",
		"ArenaRoVPillarTimer", 20, tY);

	tY = tY - 28;
	if K.Modules and K.Modules["ArenaTimes"] then
		CreateModuleCheckBox(paneTimers, L["CB_ARENA_TIMES"] or "Queue timer + invite popup timer",
			"ArenaTimes", 20, tY,
			L["TIP_ArenaTimes"] or "Shows a countdown on the arena invite popup and the queue time next to the minimap.");
	end

	-- La calculadora de puntos ESTABA aca, partiendo en dos la seccion de
	-- timers. No tiene nada que ver con ellos, asi que se mudo al final del
	-- todo (ver "PUNTOS DE ARENA" mas abajo).

	-- ── Escalas de los timers ──
	-- Van en su propio bloque, DEBAJO del boton de la calculadora (antes se
	-- superponian). Titulos cortos para que no choquen con el valor.
	tY = tY - 46;
	CreateSeparator(paneTimers, 14, tY + 14, 440);
	local scH = paneTimers:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	scH:SetPoint("TOPLEFT", 20, tY);
	scH:SetText((K.UI and K.UI.Header(L["HEADER_TIMER_SCALES"] or "Timer size"))
		or "|cffFFD100Timer size|r");
	tY = tY - 34;

	if K.UI and K.UI.ScaleSlider then
		local sc1 = K.UI.ScaleSlider(paneTimers, "ArenaEndTimer", 24, tY, 150,
			L["CB_ARENA_END"] or "Arena Time");
		local sc2 = K.UI.ScaleSlider(paneTimers, "ArenaCountDown", 260, tY, 150,
			L["SCALE_COUNTDOWN"] or "Countdown");
		if sc1 or sc2 then tY = tY - 54; end

		local sc3 = K.UI.ScaleSlider(paneTimers, "ArenaDalaranPipeTimer", 24, tY, 150,
			L["SCALE_DALARAN"] or "Dalaran");
		local sc4 = K.UI.ScaleSlider(paneTimers, "ArenaRoVPillarTimer", 260, tY, 150,
			L["SCALE_ROV"] or "Ring of Valor");
		if sc3 or sc4 then tY = tY - 54; end
	end

	tY = tY - 20;

	-- ═══════════════════════════════════════════════════════════
	-- SECCION 2 · OPTIONS  (Target of Target y extras del marco)
	-- Ahora vive en el MISMO pane que Timers, encadenada debajo.
	-- ═══════════════════════════════════════════════════════════
	CreateSeparator(paneTimers, 14, tY + 12, 440);

	local mPane = paneModules;   -- = paneTimers (mismo pane)
	local mY = tY;

	local totH = mPane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	totH:SetPoint("TOPLEFT", 20, mY);
	totH:SetText("|cffFFD100" .. (L["ARENA_TOT"] or "Target of Target") .. "|r");

	mY = mY - 26;
	local totToggle;
	if K.Modules and K.Modules["ArenaToT"] then
		totToggle = CreateModuleCheckBox(mPane, L["CB_ARENA_TOT"] or "Enable Target of Target",
			"ArenaToT", 20, mY,
			L["TIP_ArenaToT"] or "Shows the target of each arena enemy.");
	end

	-- LOS SLIDERS DE ESTE PANEL DIBUJAN SU TITULO POR ENCIMA DE LA BARRA
	-- (BOTTOM -> TOP). O sea que un slider puesto en y = 0 escribe ARRIBA
	-- del borde de su seccion y se le monta a lo que haya antes: por eso
	-- "ToT Scale" salia pisando "Enable Target of Target".
	--
	-- Es el mismo detalle que ya esta anotado en el bloque de la barra de
	-- casteo ("52 y no 34"). Aca se arregla igual: la seccion arranca mas
	-- abajo y el slider va corrido dentro de ella, con lugar para su
	-- titulo.
	mY = mY - 34;
	local totSection = CreateFrame("Frame", "NidhausArenaToTSection", mPane);
	totSection:SetPoint("TOPLEFT", 0, mY);
	totSection:SetWidth(540);
	totSection:SetHeight(86);

	local totScaleSlider = CreateSlider(totSection, L["SLIDER_ARENA_TOT_SCALE"] or "Target of Target Scale",
		"ArenaToTScale", 0.5, 2.0, 0.1, fCol1, -16);
	totScaleSlider:SetWidth(130); totScaleSlider.setting = "ArenaToTScale";

	-- Las casillas van a la altura del slider, no del titulo.
	CreateCheckBox(totSection, L["CB_ARENA_TOT_CLASSICON"] or "Class Icon",
		"ArenaToTClassIcon", fCol2, -12);
	CreateCheckBox(totSection, L["CB_ARENA_TOT_MIRROR"] or "Mirror Frame",
		"ArenaToTMirrored",  fCol2 + 130, -12);

	-- Square es excluyente con Mirror: el cuadrado es simetrico, no hay
	-- lado al que mandar el retrato. El modulo hace ganar a Square; aca se
	-- deja el aviso en el tooltip para que no parezca que Mirror se rompio.
	CreateCheckBox(totSection, L["CB_ARENA_TOT_SQUARE"] or "Square Style",
		"ArenaToTSquare", fCol1, -44);

	local totResetBtn = CreateFrame("Button", nil, totSection, "UIPanelButtonTemplate");
	totResetBtn:SetPoint("TOPLEFT", fCol2, -44);
	totResetBtn:SetSize(80, 20);
	totResetBtn:SetText(L["BTN_RESET_SHORT"] or "Reset");
	totResetBtn:SetScript("OnClick", function()
		K.SaveConfig("ArenaToTScale", 1.0);
		totScaleSlider:SetValue(1.0);
		if K.ResetArenaToTPositions then K.ResetArenaToTPositions(); end
		if K.ApplyArenaToTScale then K.ApplyArenaToTScale(1.0); end
	end);

	local function RefreshToTSection()
		local on = K.IsModuleEnabled and K.IsModuleEnabled("ArenaToT");
		if on then totSection:Show(); else totSection:Hide(); end
	end
	RefreshToTSection();

	if totToggle then
		local oldOnClick = totToggle:GetScript("OnClick");
		totToggle:SetScript("OnClick", function(self)
			if oldOnClick then oldOnClick(self); end
			RefreshToTSection();
		end);
	end

	mY = mY - 90;

	-- ═══════════════════════════════════════════════════════════
	-- PUNTOS DE ARENA  (al final: no es un timer ni parte del marco)
	--
	-- El bloque ENTERO se esconde cuando el modulo esta apagado. Se prende
	-- desde la pestaña Addons, que es donde vive el modulo; aca solo hay un
	-- acceso rapido a la calculadora, y un acceso a algo apagado no sirve.
	-- Va ultimo justo por eso: al ocultarse no deja un hueco en el medio.
	-- ═══════════════════════════════════════════════════════════
	local apcBlock;
	if K.Modules and K.Modules["ArenaPointsCalc"] then
		-- Vive en su propia sub-pestana, asi que empieza arriba del todo y
		-- ya no necesita el separador que lo despegaba de los cronometros.
		apcBlock = CreateFrame("Frame", "NidhausArenaPointsBlock", panePoints);
		apcBlock:SetPoint("TOPLEFT", 0, -14);
		apcBlock:SetWidth(540);
		apcBlock:SetHeight(96);

		local ptsH = apcBlock:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		ptsH:SetPoint("TOPLEFT", 20, 0);
		ptsH:SetText(L["HEADER_ARENA_POINTS"] or "|cffFFD100Arena Points|r");

		CreateModuleCheckBox(apcBlock, L["MOD_APC"] or "Arena Points Calculator",
			"ArenaPointsCalc", 20, -40,
			L["MOD_APC_DESC"] or "Calculates the arena points you will get each week. /apc to open it.");

		local apcBtn = CreateFrame("Button", nil, apcBlock, "UIPanelButtonTemplate");
		apcBtn:SetPoint("TOPLEFT", 24, -70);
		apcBtn:SetSize(160, 22);
		apcBtn:SetText(L["BTN_APC_OPEN"] or "Open the calculator");
		apcBtn:SetScript("OnClick", function()
			if SlashCmdList and SlashCmdList["ARENACALC"] then SlashCmdList["ARENACALC"](""); end
		end);

	end

	-- Muestra u oculta el bloque segun el estado del modulo, y ajusta el
	-- alto del contenido para que la barra de scroll no sobre.
	local function RefreshAPCBlock()
		local on = K.IsModuleEnabled and K.IsModuleEnabled("ArenaPointsCalc");
		if apcBlock then
			if on then apcBlock:Show(); else apcBlock:Hide(); end
		end
		-- El pane de Options ya no lleva este bloque, asi que su alto es mY
		-- a secas. El de puntos ocupa lo que ocupe el bloque, o nada si el
		-- modulo esta apagado.
		sub.SetContentHeight(2, math.abs(mY));
		sub.SetContentHeight(3, on and 130 or 40);
	end
	K._RefreshArenaPointsBlock = RefreshAPCBlock;
	RefreshAPCBlock();

	-- El modulo tambien se prende desde la pestaña Addons. Si el panel ya
	-- estaba abierto, el OnShow del panel no vuelve a dispararse, asi que
	-- se refresca tambien al entrar a esta sub-pestaña.
	paneTimers:HookScript("OnShow", RefreshAPCBlock);
	panePoints:HookScript("OnShow", RefreshAPCBlock);

	-- Refrescar al abrir el panel (el usuario pudo cambiar cosas desde otro lado)
	panel:HookScript("OnShow", function()
		UpdateArenaOptionsVisibility();
		local isFlat = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);
		if C.ArenaFrameOn then UpdateLayout(isFlat); end
		RefreshToTSection();
		RefreshAPCBlock();
		if totToggle and K.IsModuleEnabled then
			totToggle:SetChecked(K.IsModuleEnabled("ArenaToT"));
		end
	end);

	return arenaShowBtn;
end
