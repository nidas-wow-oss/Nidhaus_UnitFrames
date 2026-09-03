-- Este archivo vive en Nidhaus_UnitFrames_Config, un addon aparte que se
-- carga SOLO cuando abris el panel (LoadOnDemand). Por eso no recibe el
-- namespace por "...", que es privado de cada addon: lo toma de la global
-- que publica el addon principal en Core/Init.lua.
local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

-- =========================================================
-- OptionsPanelFrames.lua
-- Tab 2: Frames — Localización Restaurada (Verde / Blanco)
-- =========================================================

local tooltips = {
	PlayerFrameScale        = "TIP_PlayerFrameScale",
	TargetFrameScale        = "TIP_TargetFrameScale",
	FocusScale              = "TIP_FocusScale",
	FocusSpellBarScale      = "TIP_FocusSpellBarScale",
	PartyFrameScale         = "TIP_PartyFrameScale",
	PartyMemberFrameSpacing = "TIP_PartyMemberFrameSpacing",
	BossFrameScale          = "TIP_BossFrameScale",
	BossTargetFrameSpacing  = "TIP_BossTargetFrameSpacing",
	NewPartyFrame           = "TIP_NewPartyFrame",
	PartyTargetsEnabled     = "TIP_PartyTargets",
};

local function AddTooltip(frame, setting)
	local tipKey = tooltips[setting];
	if not tipKey then return; end
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L[setting] or setting, 1, 1, 1);
		GameTooltip:AddLine(L[tipKey] or tipKey, nil, nil, nil, true);
		GameTooltip:Show();
	end);
	frame:SetScript("OnLeave", function() GameTooltip:Hide(); end);
end

local checkboxCount = 0;

local function CreateFeatureCheckBox(parent, labelText, xOffset, yOffset, tooltipText, setting)
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausFramesCB" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "UICheckButtonTemplate");
	cb:SetPoint("TOPLEFT", xOffset, yOffset);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local label = _G[cbName .. "Text"];
	if label then
		label:SetText((K.UI and K.UI.Label(labelText)) or labelText);
		label:SetFontObject("GameFontHighlightSmall");
	else
		label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		label:SetPoint("LEFT", cb, "RIGHT", 2, 0);
		label:SetText((K.UI and K.UI.Label(labelText)) or labelText);
	end

	if tooltipText then
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(labelText, 1, 1, 1);
			GameTooltip:AddLine(tooltipText, nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	end

	return cb;
end

local function FormatSliderValue(step, value)
	if step >= 1 then
		return string.format("%d", value);
	elseif step >= 0.1 then
		return string.format("%.1f", value);
	else
		return string.format("%.2f", value);
	end
end

-- Registro de sliders de escala, para poder refrescarlos cuando el usuario
-- escala un frame con Ctrl + rueda desde el modo mover.
local scaleSliders = {};

function K.RefreshScaleSliders()
	for _, s in ipairs(scaleSliders) do
		local value = C[s.setting];
		if type(value) == "number" then
			s._lastValue = value;
			s:SetValue(value);
			if s.ValueText and s._fmt then
				local t = s._fmt(value);
				s.ValueText:SetText((K.UI and K.UI.Value(t)) or t);
			end
		end
	end
end

local function CreateSlider(parent, label, setting, minVal, maxVal, step, xOffset, yOffset)
	local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate");
	slider:SetPoint("TOPLEFT", xOffset, yOffset);
	slider:SetWidth(210);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	slider:SetValue(C[setting] or minVal);
	slider.setting = setting;

	-- Topes minimo y maximo abajo, titulo propio arriba (UIKit).
	K.UI.SliderEnds(slider, FormatSliderValue(step, minVal), FormatSliderValue(step, maxVal));

	-- COMPACTO: titulo a la izquierda y valor pegado a la derecha, en la
	-- misma linea. Antes cada slider gastaba ~60px de alto (titulo arriba,
	-- valor abajo, min/max a los costados); asi baja a la mitad y entran
	-- el doble de opciones sin scroll.
	local title = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 2);
	title:SetText((K.UI and K.UI.Label(K.UI.Strip(label))) or label);

	slider.ValueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	slider.ValueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 2);
	slider.ValueText:SetText((K.UI and K.UI.Value(FormatSliderValue(step, C[setting] or minVal)))
		or FormatSliderValue(step, C[setting] or minVal));

	-- UIKit le cuelga a TODO slider del addon una cajita editable con el
	-- valor, debajo. Sin esta marca quedaban los dos numeros: el de aca
	-- arriba a la derecha y el de la cajita abajo. La marca le dice a
	-- UIKit cual es "el nuestro" para que lo esconda.
	--
	-- Se sigue actualizando aunque este oculto: RefreshScaleSliders lo
	-- lee, y si algun dia se saca la cajita vuelve a aparecer al dia.
	slider._nufOwnValue = slider.ValueText;

	AddTooltip(slider, setting);

	-- FIX PERF: Apply visual changes immediately during drag, but only save
	-- to DB (with CONFIG_CHANGED event) on mouse release. This eliminates
	-- ~120-240 callback executions/sec while dragging sliders.
	slider._lastValue = C[setting] or minVal;

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value / step + 0.5) * step;
		-- FIX: Guard against double-fire (SetValue inside OnValueChanged)
		if self._lastValue == value then return; end
		self._lastValue = value;
		self:SetValue(value);
		slider.ValueText:SetText((K.UI and K.UI.Value(FormatSliderValue(step, value))) or FormatSliderValue(step, value));

		-- Apply visual effect immediately (no DB save, no CONFIG_CHANGED)
		C[setting] = value;

		-- ═══════════════════════════════════════════════════════════
		-- UN SOLO DUEÑO DEL NUMERO
		--
		-- Si este frame se puede escalar con Ctrl + rueda en el modo
		-- mover, la escala se guarda en globalPos y se aplica desde
		-- ahi al entrar al juego. El slider tiene que escribir EN ESE
		-- MISMO LUGAR, no llamar a SetScale por su cuenta.
		--
		-- Antes hacia lo segundo, y el resultado era: movias el
		-- slider, se veia bien, relogueabas, y RestoreGlobalPositions
		-- volvia a aplicar la escala vieja de globalPos. El marco
		-- quedaba del tamaño de antes y el slider mostraba el numero
		-- nuevo. Parecia que el slider no guardaba.
		-- ═══════════════════════════════════════════════════════════
		local movables = K.GetMovablesForSetting and K.GetMovablesForSetting(setting);
		if movables and K.SetGlobalFrameScale then
			for _, mk in ipairs(movables) do
				K.SetGlobalFrameScale(mk, value);
			end

		elseif setting == "FocusSpellBarScale" then
			if FocusFrameSpellBar then FocusFrameSpellBar:SetScale(value); end
		elseif setting == "PartyMemberFrameSpacing" then
			if K.ApplyPartyFrameSpacing then K.ApplyPartyFrameSpacing(); end
		elseif setting == "BossFrameScale" then
			-- Los marcos de jefe no estan en el modo mover, asi que este
			-- slider es su unico dueño.
			if K.ApplyBossFrameScale then K.ApplyBossFrameScale(value); end
		elseif setting == "BossTargetFrameSpacing" then
			if K.ApplyBossFrameSpacing then K.ApplyBossFrameSpacing(); end
		end
	end);

	-- FIX PERF: Save to DB only when user releases the slider
	-- This triggers CONFIG_CHANGED exactly ONCE instead of 30+ times per drag
	slider:SetScript("OnMouseUp", function(self)
		if K.SaveConfig then K.SaveConfig(setting, C[setting]); end
	end);

	slider._fmt = function(v) return FormatSliderValue(step, v); end;
	table.insert(scaleSliders, slider);

	return slider;
end


-- =========================================================
-- Checkboxes de Party Features (se usan en Escalas y en Party)
-- =========================================================
-- NOTA: el checkbox "New Party" se fue de aca. El aspecto de los marcos
-- ahora se elige con el selector de 3 estilos (Default / New / Improved),
-- porque los dos addons retexturizan lo mismo y no pueden convivir.
function K.BuildPartyFeatureCheckboxes(parent, x, y)
	-- UNA FILA POR FUNCION, no dos columnas.
	--
	-- Antes iban Buffs y Targets en la misma linea y Castbars solo debajo:
	-- con el boton al lado de cada uno eso no cierra, porque las etiquetas
	-- miden distinto y los botones quedaban a distinta altura y en distinta
	-- x. En columna, los tres botones se alinean solos.
	--
	--   [x] Party Buffs      [ Open ]
	--   [x] Party Targets    [ Open ]
	--   [x] Party Castbars   [ Open ]
	local ROW_H  = 28;
	local BTN_X  = x + 150;   -- misma x para los tres

	-- Boton "Open" al lado de un checkbox.
	--
	-- Se apaga cuando la funcion esta destildada: abrir la ventana de
	-- opciones de algo que no esta corriendo no sirve de nada, y encima
	-- confunde porque los cambios no se ven.
	local function OpenButton(row, slashKey, isOn)
		local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
		b:SetPoint("TOPLEFT", BTN_X, y - row * ROW_H + 2);
		b:SetSize(70, 20);
		b:SetText(L["BTN_OPEN"] or "Open");
		b:SetScript("OnClick", function()
			if SlashCmdList and SlashCmdList[slashKey] then
				SlashCmdList[slashKey]("");
			end
		end);
		b.Sync = function()
			if isOn() then b:Enable(); else b:Disable(); end
		end;
		b:Sync();
		return b;
	end

	local buttons = {};

	-- ── Party Buffs ──
	if K.Modules and K.Modules["PartyBuffs"] then
		local pbCB = CreateFeatureCheckBox(parent, L["CB_PARTY_BUFFS_SHORT"] or "Party Buffs",
			x, y, L["TIP_PartyBuffs"], "PartyBuffs");
		pbCB:SetChecked(K.IsModuleEnabled("PartyBuffs"));

		local pbBtn = OpenButton(0, "PARTYBUFFS", function()
			return K.IsModuleEnabled and K.IsModuleEnabled("PartyBuffs");
		end);
		buttons[#buttons + 1] = pbBtn;

		pbCB:SetScript("OnClick", function(self)
			local val = self:GetChecked() and true or false;
			K.SetModuleEnabled("PartyBuffs", val);
			if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("PartyBuffs"); end
			pbBtn:Sync();
		end);
		if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox("PartyBuffs", pbCB); end
	end

	-- ── Party Targets ──
	local ptCB = CreateFeatureCheckBox(parent, L["CB_PARTY_TARGETS_SHORT"] or "Party Targets",
		x, y - ROW_H, L["TIP_PartyTargets"], "PartyTargetsEnabled");
	ptCB:SetChecked(C.PartyTargetsEnabled);

	local ptBtn = OpenButton(1, "PARTYTARGETS", function()
		return C.PartyTargetsEnabled and true or false;
	end);
	buttons[#buttons + 1] = ptBtn;

	ptCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.PartyTargetsEnabled = val;
		if K.SaveConfig then K.SaveConfig("PartyTargetsEnabled", val); end
		if K.ApplyPartyTargetsState then K.ApplyPartyTargetsState(val); end
		ptBtn:Sync();
	end);

	-- ── Party Castbars ──
	local pcbCB = CreateFeatureCheckBox(parent, L["CB_PARTY_CASTBARS_SHORT"] or "Party Castbars",
		x, y - ROW_H * 2, L["TIP_PartyCastingBars"] or "", "PartyCastingBars");
	pcbCB:SetChecked(C.PCB_Enabled == true);

	local pcbBtn = OpenButton(2, "PARTYCASTINGBARS", function()
		return C.PCB_Enabled and true or false;
	end);
	buttons[#buttons + 1] = pcbBtn;

	pcbCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		K.SaveConfig("PCB_Enabled", val);
		if PartyCastingBars and PartyCastingBars.EnableToggle then
			PartyCastingBars.EnableToggle(val);
		end
		pcbBtn:Sync();
	end);

	-- Los checkbox tambien se tocan desde otras pestañas y desde Reset, asi
	-- que al abrir el panel hay que repasar el estado de los tres botones.
	if parent.HookScript then
		parent:HookScript("OnShow", function()
			for _, b in ipairs(buttons) do b:Sync(); end
		end);
	end
end

-- =========================================================
-- EL MODO 3v3 CUELGA DE "USE CUSTOM POSITIONS"
--
-- El 3v3 reacomoda los marcos del grupo, y eso solo tiene sentido si el
-- addon es el que manda las posiciones. Con "Use Custom Positions"
-- apagado el checkbox se podia tildar igual y no pasaba nada: parecia
-- roto. Ahora se apaga y se atenua, como cualquier opcion que depende
-- de otra.
--
-- Los checkbox del 3v3 estan en DOS paneles (Interfaz y Move Everything)
-- y son el mismo setting, asi que se guardan todos en una lista y se
-- refrescan juntos.
-- =========================================================
K._3v3Checkboxes = K._3v3Checkboxes or {};

function K.Register3v3Checkbox(cb)
	if not cb then return; end
	table.insert(K._3v3Checkboxes, cb);
	if K.Update3v3Enabled then K.Update3v3Enabled(); end
end

function K.Update3v3Enabled()
	local ok = (C.SetPositions == true);
	for _, cb in ipairs(K._3v3Checkboxes) do
		if cb.Enable then
			if ok then cb:Enable(); else cb:Disable(); end
			cb:SetAlpha(ok and 1 or 0.4);
			if cb.text then cb.text:SetAlpha(ok and 1 or 0.4); end
		end
	end
end

-- =========================================================
-- Checkbox "Use Custom Positions" reutilizable.
-- Se usa en Frames y, en espejo, en la pestaña Interfaz: es el
-- MISMO setting y se sincronizan solos via RegisterSettingCheckbox.
-- =========================================================
function K.CreateCustomPosCheckbox(parent, x, y)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0);
	cb.text:SetText(L["CB_CUSTOM_POS"] or "Use Custom Positions");
	cb:SetChecked(C.SetPositions and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("SetPositions", cb); end

	cb:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_CUSTOM_POS"] or "Use Custom Positions", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_SetPositions"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	cb:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("SetPositions", v); end
		-- Reaccion en cadena: el 3v3 se habilita o se apaga con esta.
		if K.Update3v3Enabled then K.Update3v3Enabled(); end

		if v then
			-- Una sola fuente de verdad: si se usan las posiciones custom,
			-- se descartan las guardadas por el modo mover para estos marcos.
			local gp = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;
			if gp then gp.Player, gp.Target, gp.Party = nil, nil, nil; end
			if K.InitializePartyFrames then K.InitializePartyFrames(); end
			if K.ApplyFramePositions then K.ApplyFramePositions(); end
			if C.PartyMode3v3 and K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
			if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(true); end
		else
			if C.PartyMode3v3 and K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
			if K.ApplyFramePositions then K.ApplyFramePositions(); end
			if K.ApplyArenaCustomPosition then K.ApplyArenaCustomPosition(false); end
		end

		if K.PartyBuffs_OnFramesMoved then pcall(K.PartyBuffs_OnFramesMoved); end
	end);

	return cb;
end

-- =========================================================
-- PopulateFramesTab
--
-- Lista lateral con 4 secciones. "Jugador, Objetivo y Foco" van
-- juntos a pedido del usuario: son los tres marcos que se acomodan
-- de una sentada y no tiene sentido separarlos.
-- =========================================================
local function FHeader(parent, text, x, y)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetText((K.UI and K.UI.Header(K.UI.Strip(text))) or text);
	return fs;
end

local function FNote(parent, text, x, y, width)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetWidth(width or 430);
	fs:SetJustifyH("LEFT");
	fs:SetText("|cff8EAEC9" .. (text or "") .. "|r");
	return fs;
end

function K.PopulateFramesTab(panel)
	local side = K.CreateSideList(panel, {
		{ name = L["SIDE_PTF"]    or "Player, Target and Focus" },
		{ name = L["SIDE_PARTY"]  or "Party" },
		{ name = L["SIDE_AURAS"]  or "Buffs and Debuffs" },
		{ name = L["SIDE_BOSS"]   or "Boss" },
		{ name = L["SIDE_PET"]    or "Pet" },
	});
	panel.sideList = side;

	local paneMain, paneParty, paneAuras, paneBoss, panePet =
		side[1], side[2], side[3], side[4], side[5];

	local x        = 20;
	local sliderH  = 46;

	-- ══════════════════════════════════════════════════════
	-- 1) JUGADOR, OBJETIVO Y FOCO
	--
	-- DOS COLUMNAS. Antes era una sola tira de ~280px de ancho dentro
	-- de un panel de 460: media pestaña quedaba vacia y aun asi habia
	-- que scrollear para llegar al bloque de posicion.
	--
	--   izquierda -> las escalas
	--   derecha   -> mover y bloquear
	-- ══════════════════════════════════════════════════════
	local xR = 250;
	local y  = -14;    -- cursor de la columna izquierda
	local ry = -14;    -- cursor de la columna derecha

	-- ── Columna izquierda: escalas ──
	FHeader(paneMain, L["HEADER_SCALES"] or "Scale", x, y);

	y = y - 30;
	CreateSlider(paneMain, L["SLIDER_PLAYER_SCALE"], "PlayerFrameScale", 0.5, 1.5, 0.05, x, y);
	y = y - sliderH;
	CreateSlider(paneMain, L["SLIDER_TARGET_SCALE"], "TargetFrameScale", 0.5, 1.5, 0.05, x, y);
	y = y - sliderH;
	CreateSlider(paneMain, L["SLIDER_FOCUS_SCALE"], "FocusScale", 0.5, 1.5, 0.05, x, y);
	-- "Focus Spellbar Scale" se fue de aca a Interface > Cast Bar. Es una
	-- barra de casteo, no un marco de unidad, y ahora que esa seccion
	-- existe habia dos lugares distintos para escalar barras de casteo.
	--
	-- Pero sin decir nada parecia que faltaba, asi que queda el cartelito
	-- de abajo indicando donde esta. Un slider duplicado seria peor: dos
	-- controles para el mismo numero, y el que no tocaste mostrando el
	-- valor viejo hasta reabrir el panel.
	y = y - sliderH + 6;
	FNote(paneMain, L["NOTE_FOCUS_SPELLBAR"]
		or "Focus cast bar scale lives in Interface > Cast Bar.", x, y, 220);

	y = y - 34;

	-- ═══════════════════════════════════════════════════════════════
	-- Boton de reset
	--
	-- Se llamaba "Reset Scales & Positions" y era enganoso por partida
	-- doble:
	--
	--   * No reseteaba la posicion de NINGUN marco. Eso lo hace el otro
	--     boton, el de la derecha. Lo unico de "posiciones" que tocaba
	--     era ResetTimerBarPositions, o sea las barras de timers de
	--     clase, que no estan en esta pestana ni son marcos de unidad.
	--     Ya no se llama.
	--
	--   * Si resetea las escalas de Party, Boss y Pet, que viven en
	--     otras secciones. Eso se deja — es util tener un boton que
	--     devuelva todo a 1 — pero ahora el nombre lo dice.
	--
	-- Ademas ahora borra la escala guardada en el modo mover. Antes solo
	-- escribia en C, asi que al reloguear volvia la vieja.
	-- ═══════════════════════════════════════════════════════════════
	local resetScalesBtn = CreateFrame("Button", nil, paneMain, "UIPanelButtonTemplate");
	resetScalesBtn:SetPoint("TOPLEFT", x, y);
	resetScalesBtn:SetSize(210, 24);
	resetScalesBtn:SetText(L["BTN_RESET_SCALES"] or "Reset All Scales");
	resetScalesBtn:SetScript("OnClick", function()
		local defaults = {
			PlayerFrameScale = 1.0, TargetFrameScale = 1.0,
			FocusScale = 1.0, FocusSpellBarScale = 1.2,
			PartyFrameScale = 1.0, PartyMemberFrameSpacing = 0,
			BossFrameScale = 0.65, BossTargetFrameSpacing = 0,
			PetFrameScale = 1.0,
		};
		for k, v in pairs(defaults) do
			C[k] = v;
			if K.SaveConfigSilent then K.SaveConfigSilent(k, v); end
			-- Y en el mismo lugar donde escribe Ctrl + rueda, si el
			-- frame es movible. Sin esto el reset duraba hasta el
			-- proximo login.
			local movables = K.GetMovablesForSetting and K.GetMovablesForSetting(k);
			if movables and K.SetGlobalFrameScale then
				for _, mk in ipairs(movables) do K.SetGlobalFrameScale(mk, v); end
			end
		end
		if K.FlushConfigChanges then K.FlushConfigChanges(); end

		-- Los que no estan en el modo mover se aplican a mano.
		if FocusFrameSpellBar then FocusFrameSpellBar:SetScale(1.2); end
		if K.ApplyPartyFrameSpacing then K.ApplyPartyFrameSpacing(); end
		if K.ApplyBossFrameScale then K.ApplyBossFrameScale(0.65); end
		if K.ApplyBossFrameSpacing then K.ApplyBossFrameSpacing(); end
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		if K.RefreshCastBarScaleSlider then K.RefreshCastBarScaleSlider(); end
		print("|cff4FC3F7NUF:|r " .. (L["SCALES_RESET_DONE"]
			or "Scales reset. /reload to fully restore the defaults."));
	end);

	-- ── Columna derecha: posicion ──
	FHeader(paneMain, L["HEADER_MOVE_FRAMES"] or "Move Unit Frames", xR, ry);

	ry = ry - 22;
	FNote(paneMain, L["DESC_MOVE_FRAMES"] or "", xR + 2, ry, 205);

	ry = ry - 74;
	local unlockBtn = CreateFrame("Button", nil, paneMain, "UIPanelButtonTemplate");
	unlockBtn:SetPoint("TOPLEFT", xR, ry);
	unlockBtn:SetSize(210, 24);
	unlockBtn:SetText(L["BTN_MOVE_FRAMES"] or "Unlock Unit Frames");
	unlockBtn:SetScript("OnClick", function(self)
		if not K.ToggleGlobalUnlock then return; end
		K.ToggleGlobalUnlock("frames");
		if K.IsGlobalUnlocked and K.IsGlobalUnlocked() then
			self:SetText(L["BTN_MOVE_ALL_DONE"] or "Lock All Frames");
		else
			self:SetText(L["BTN_MOVE_FRAMES"] or "Unlock Unit Frames");
		end
	end);

	-- Este reset y el de las escalas son cosas distintas y antes se
	-- leian igual: los dos decian "Reset" y estaban a la vista al mismo
	-- tiempo. Ahora cada uno dice que resetea.
	ry = ry - 30;
	local unlockResetBtn = CreateFrame("Button", nil, paneMain, "UIPanelButtonTemplate");
	unlockResetBtn:SetPoint("TOPLEFT", xR, ry);
	unlockResetBtn:SetSize(210, 24);
	unlockResetBtn:SetText(L["BTN_RESET_POSITIONS"] or "Reset Positions");
	unlockResetBtn:SetScript("OnClick", function()
		if K.ResetGlobalPositions then K.ResetGlobalPositions(); end
	end);

	ry = ry - 36;
	K.CreateCustomPosCheckbox(paneMain, xR, ry);

	side.SetContentHeight(1, math.min(y, ry) - 60);

	-- ══════════════════════════════════════════════════════
	-- 2) PARTY
	-- ══════════════════════════════════════════════════════
	local py = -14;

	-- Modo prueba, primero de todo: es lo que se aprieta ANTES de tocar
	-- cualquier otra cosa de esta pestaña, porque sin grupo real no hay
	-- marcos que mirar mientras elegis estilo, escala o posicion.
	-- No depende del 3v3 ni de ningun estilo: sirve para todos.
	-- Mismo recuadro que Move Everything en el pie del panel: fondo azul
	-- oscuro, borde de un pixel en cuatro texturas y texto celeste. En
	-- 3.3.5a los Button no aceptan SetBackdrop, de ahi las cuatro texturas.
	local testBtn = CreateFrame("Button", nil, paneParty);
	testBtn:SetPoint("TOPLEFT", x, py);
	testBtn:SetSize(200, 24);
	testBtn:SetFrameLevel(paneParty:GetFrameLevel() + 3);
	testBtn:EnableMouse(true);

	local tbBg = testBtn:CreateTexture(nil, "ARTWORK");
	tbBg:SetTexture("Interface\\Buttons\\WHITE8X8");
	tbBg:SetAllPoints(testBtn);
	tbBg:SetVertexColor(0.03, 0.08, 0.20, 0.95);

	local TB_BW = 1;
	local function TBEdge()
		local t = testBtn:CreateTexture(nil, "OVERLAY");
		t:SetTexture("Interface\\Buttons\\WHITE8X8");
		return t;
	end
	local tbTop = TBEdge();
	tbTop:SetPoint("TOPLEFT", testBtn, "TOPLEFT", 0, 0);
	tbTop:SetPoint("TOPRIGHT", testBtn, "TOPRIGHT", 0, 0);
	tbTop:SetHeight(TB_BW);
	local tbBot = TBEdge();
	tbBot:SetPoint("BOTTOMLEFT", testBtn, "BOTTOMLEFT", 0, 0);
	tbBot:SetPoint("BOTTOMRIGHT", testBtn, "BOTTOMRIGHT", 0, 0);
	tbBot:SetHeight(TB_BW);
	local tbLeft = TBEdge();
	tbLeft:SetPoint("TOPLEFT", testBtn, "TOPLEFT", 0, 0);
	tbLeft:SetPoint("BOTTOMLEFT", testBtn, "BOTTOMLEFT", 0, 0);
	tbLeft:SetWidth(TB_BW);
	local tbRight = TBEdge();
	tbRight:SetPoint("TOPRIGHT", testBtn, "TOPRIGHT", 0, 0);
	tbRight:SetPoint("BOTTOMRIGHT", testBtn, "BOTTOMRIGHT", 0, 0);
	tbRight:SetWidth(TB_BW);

	local tbLabel = testBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	tbLabel:SetPoint("CENTER", testBtn, "CENTER", 0, 0);
	tbLabel:SetText("|cff4fc3f7" .. (L["BTN_PARTY_TEST"] or "Test mode (4 fake members)") .. "|r");

	local function TestBtnRest()
		tbBg:SetVertexColor(0.03, 0.08, 0.20, 0.95);
		tbTop:SetVertexColor(0.30, 0.65, 1.00, 1.00);
		tbBot:SetVertexColor(0.25, 0.55, 0.90, 0.80);
		tbLeft:SetVertexColor(0.25, 0.55, 0.90, 0.80);
		tbRight:SetVertexColor(0.25, 0.55, 0.90, 0.80);
	end
	TestBtnRest();

	testBtn:SetScript("OnEnter", function()
		tbTop:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		tbBot:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		tbLeft:SetVertexColor(0.60, 0.85, 1.00, 1.00);
		tbRight:SetVertexColor(0.60, 0.85, 1.00, 1.00);
	end);
	testBtn:SetScript("OnLeave", TestBtnRest);
	testBtn:SetScript("OnClick", function()
		if K.TogglePartyTestMode then K.TogglePartyTestMode(); end
	end);
	py = py - 34;

	-- ── ESTILO DE LOS MARCOS (excluyente) ──
	FHeader(paneParty, L["HEADER_PARTY_STYLE"] or "Frame Style", x, py);
	py = py - 20;
	FNote(paneParty, L["NOTE_PARTY_STYLE"]
		or "Pick one. The two custom styles retexture the same frames, so they cannot be on at the same time.",
		x + 2, py, 430);

	py = py - 30;
	do
		local styles = {
			{ value = "Default",  text = L["PARTY_STYLE_DEFAULT"]  or "Blizzard" },
			-- Big Blizzard va pegado a Blizzard: es el mismo marco de siempre
			-- pero con el arte grande, asi que se leen como un par.
			{ value = "PW",       text = L["PARTY_STYLE_PW"]       or "Big Blizzard" },
			{ value = "New",      text = L["PARTY_STYLE_NEW"]      or "New Party" },
			{ value = "Improved", text = L["PARTY_STYLE_IMPROVED"] or "Improved" },
			{ value = "PW2",      text = L["PARTY_STYLE_PW2"]      or "Compact 2" },
		};
		-- Cuatro botones en el mismo ancho: 80 en vez de 100.
		local btnW, btnH, gap = 66, 22, 4;
		local styleButtons = {};

		local container = CreateFrame("Frame", nil, paneParty);
		container:SetPoint("TOPLEFT", x + 2, py);
		container:SetSize((#styles * btnW) + ((#styles - 1) * gap), btnH);

		local function RefreshStyle()
			local current = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
			for _, b in ipairs(styleButtons) do
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
		-- El coordinador la llama cuando el estilo cambia desde otro lado
		K.RefreshPartyStyleSelector = RefreshStyle;

		for i, opt in ipairs(styles) do
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
				if K.SetPartyFrameStyle then K.SetPartyFrameStyle(self.value); end
				RefreshStyle();
				-- Con el estilo Blizzard la seccion de fuente se esconde.
				if K._UpdatePartyFontVisibility then K._UpdatePartyFontVisibility(); end
			end);
			b:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(opt.text, 1, 1, 1);
				GameTooltip:AddLine(L["TIP_PartyStyle_" .. opt.value] or "", nil, nil, nil, true);
				GameTooltip:Show();
			end);
			b:SetScript("OnLeave", function() GameTooltip:Hide(); end);

			table.insert(styleButtons, b);
		end
		RefreshStyle();
	end

	-- ── Contorno del texto (idea tomada de KPack) ──
	-- Solo cambia el FLAG de la fuente, no el tipo ni el tamaño: asi sirve
	-- para los tres estilos sin romper los tamaños de cada uno.
	-- Con el estilo Blizzard no hay nada que tocar acá: manda el default del
	-- juego. Antes la seccion se ocultaba widget por widget, pero el hueco
	-- quedaba igual porque todo lo de abajo estaba anclado a coordenadas
	-- fijas. Ahora va en un cuerpo desplegable: cerrado mide 1px y lo que
	-- sigue sube solo, porque se ancla AL CUERPO y no a un numero.
	py = py - 44;
	-- Alto del cuerpo: cabecera en 0, etiqueta y desplegable en -30, slider en
	-- -66. El slider mide 16 y ademas UIKit le cuelga DEBAJO la cajita con el
	-- valor (otros 17), asi que el contenido llega a -99. Con 92 la cajita se
	-- salia del cuerpo y pisaba la casilla de abajo.
	local fontBody = K.UI.Collapsible(paneParty, x, py, 440, 104, function()
		local style = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
		return style ~= "Default";
	end);

	FHeader(fontBody, L["HEADER_PARTY_FONT"] or "Text Outline", 0, 0);

	do
		local outlines = {
			{ value = "",                  text = L["OUTLINE_NONE"]      or "None" },
			{ value = "OUTLINE",           text = L["OUTLINE_NORMAL"]    or "Outline" },
			{ value = "THICKOUTLINE",      text = L["OUTLINE_THICK"]     or "Thick outline" },
			{ value = "Blizz",             text = L["OUTLINE_BLIZZ"]     or "Like health / mana text" },
		};
		local function OutText(v)
			for _, o in ipairs(outlines) do if o.value == v then return o.text; end end
			return outlines[1].text;
		end

		local lbl = fontBody:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		lbl:SetPoint("TOPLEFT", 2, -30);
		lbl:SetText((K.UI and K.UI.Label(L["LBL_PARTY_FONT"] or "Font outline"))
			or (L["LBL_PARTY_FONT"] or "Font outline"));

		local dd = CreateFrame("Frame", "NidhausPartyOutlineDD", fontBody, "UIDropDownMenuTemplate");
		dd:SetPoint("LEFT", lbl, "RIGHT", 4, -2);
		UIDropDownMenu_SetWidth(dd, 150);
		UIDropDownMenu_Initialize(dd, function(self, level)
			for _, opt in ipairs(outlines) do
				local info = UIDropDownMenu_CreateInfo();
				info.text  = opt.text;
				info.value = opt.value;
				info.func  = function(btn)
					UIDropDownMenu_SetSelectedValue(dd, btn.value);
					UIDropDownMenu_SetText(dd, OutText(btn.value));
					if K.SaveConfig then K.SaveConfig("PartyFontOutline", btn.value); end
					if K.RestylePartyFrames then K.RestylePartyFrames(); end
					if K.PFI_Restyle then K.PFI_Restyle(); end
				end;
				info.checked = (opt.value == (C.PartyFontOutline or "OUTLINE"));
				UIDropDownMenu_AddButton(info, level);
			end
		end);
		UIDropDownMenu_SetSelectedValue(dd, C.PartyFontOutline or "OUTLINE");
		UIDropDownMenu_SetText(dd, OutText(C.PartyFontOutline or "OUTLINE"));

	end

	-- Tamaño del texto de vida/mana del grupo. 0 = el de cada estilo.
	do
		local fsSlider = CreateFrame("Slider", "NidhausPartyFontSizeSlider", fontBody,
			"OptionsSliderTemplate");
		fsSlider:SetPoint("TOPLEFT", 8, -66);
		fsSlider:SetWidth(200);
		-- 0 = Auto; de ahi salta a 6, que es el minimo legible.
		fsSlider:SetMinMaxValues(0, 20);
		fsSlider:SetValueStep(1);
		local start = tonumber(C.PartyFontSize) or 0;
		fsSlider:SetValue(start);
		_G[fsSlider:GetName() .. "Low"]:SetText(L["PARTY_FONT_AUTO"] or "Auto");
		_G[fsSlider:GetName() .. "High"]:SetText("20");
		_G[fsSlider:GetName() .. "Text"]:SetText(L["SLIDER_PARTY_FONT_SIZE"] or "Text size");
		fsSlider:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v + 0.5);
			if v > 0 and v < 6 then v = 6; end
			if K.SaveConfig then K.SaveConfig("PartyFontSize", v); end
			if K.RestylePartyFrames then K.RestylePartyFrames(); end
			if K.PFI_Restyle then K.PFI_Restyle(); end
		end);
		fsSlider:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["SLIDER_PARTY_FONT_SIZE"] or "Text size", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_PartyFontSize"] or "", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		fsSlider:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	end

	-- Los botones de estilo llaman a esto al cambiar de modo.
	local function UpdatePartyFontVisibility()
		fontBody:Refresh();
	end
	K._UpdatePartyFontVisibility = UpdatePartyFontVisibility;

	-- Ocultar los numeros de vida/mana del grupo (portado de Zyrokof)
	--
	-- DE ACA PARA ABAJO TODO SE ANCLA AL ANTERIOR, no a un "py" fijo. Ese es
	-- el unico motivo por el que la seccion de fuente puede cerrarse y lo de
	-- abajo sube: si siguieran en coordenadas absolutas, quedaria el hueco.
	local cbHide;
	do
		cbHide = CreateFrame("CheckButton", "NidhausPartyHideTextCB", paneParty,
			"InterfaceOptionsCheckButtonTemplate");
		-- Oculta los NUMEROS de vida y mana, o sea que es parte de "Text".
		-- Va a la DERECHA del slider de tamaño, no debajo del bloque: los
		-- dos ocupaban una fila entera cada uno y sobraba media pantalla a
		-- la derecha. El parent sigue siendo paneParty, no fontBody, para
		-- que no se esconda cuando el bloque de fuente se colapsa.
		cbHide:SetPoint("TOPLEFT", fontBody, "TOPLEFT", 250, -62);
		cbHide:SetHitRectInsets(0, 0, 0, 0);
		local fs = _G["NidhausPartyHideTextCBText"];
		if fs then fs:SetText(L["CB_PARTY_HIDE_TEXT"] or "Hide health / mana numbers"); end
		cbHide:SetChecked(C.PartyHideHealthManaText and true or false);
		if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyHideHealthManaText", cbHide); end
		cbHide:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["CB_PARTY_HIDE_TEXT"] or "Hide health / mana numbers", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_PartyHideHealthManaText"] or "", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cbHide:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		cbHide:SetScript("OnClick", function(self)
			local v = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SaveConfig then K.SaveConfig("PartyHideHealthManaText", v); end
			if K.ApplyHealthTextFormat then K.ApplyHealthTextFormat(); end
		end);
	end

	-- Modulo: marco propio para la mascota del compa 1.
	-- Va ARRIBA del checkbox de mostrar/ocultar mascotas: primero elegis
	-- que marco usar, despues si se ve o no.
	-- ── MASCOTAS ──
	-- Antes las dos opciones de mascota flotaban sueltas entre el bloque de
	-- texto y el de Mode, sin encabezado, asi que se leian como si fueran
	-- parte de cualquiera de los dos.
	local petSep = K.UI.Separator(paneParty, 0, 0, 440);
	petSep:ClearAllPoints();
	-- Colgaba de cbHide, que ahora esta arriba, al lado del slider. Cuelga
	-- del bloque de fuente, que es lo que de verdad cierra esta seccion.
	petSep:SetPoint("TOPLEFT", fontBody, "BOTTOMLEFT", -4, -10);

	local petHeader = FHeader(paneParty, L["HEADER_PARTY_PETS"] or "Pets", 0, 0);
	petHeader:ClearAllPoints();
	petHeader:SetPoint("TOPLEFT", petSep, "BOTTOMLEFT", 4, -10);

	local cbPPF;
	do
		cbPPF = CreateFrame("CheckButton", "NidhausParty1PetCB", paneParty, "UICheckButtonTemplate");
		cbPPF:SetPoint("TOPLEFT", petHeader, "BOTTOMLEFT", 0, -10);
		cbPPF.text = cbPPF:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		cbPPF.text:SetPoint("LEFT", cbPPF, "RIGHT", 4, 0);
		cbPPF.text:SetText(L["MOD_PARTYPETFRAME"] or "Party pet enhanced");
		cbPPF:SetChecked(K.IsModuleEnabled and K.IsModuleEnabled("PartyPetFrame") or false);
		if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox("PartyPetFrame", cbPPF); end
		cbPPF:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["MOD_PARTYPETFRAME"] or "Party pet enhanced", 1, 1, 1);
			GameTooltip:AddLine(L["MOD_PARTYPETFRAME_DESC"] or "", nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cbPPF:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		cbPPF:SetScript("OnClick", function(self)
			local v = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SetModuleEnabled then K.SetModuleEnabled("PartyPetFrame", v); end
			if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("PartyPetFrame"); end
		end);
	end

	-- ── Mascotas de los compañeros ──
	local cbPet;
	do
		cbPet = CreateFrame("CheckButton", "NidhausPartyPetCB", paneParty, "UICheckButtonTemplate");
		-- Al lado del anterior, no debajo: son dos opciones cortas y la
		-- columna de la derecha estaba vacia.
		cbPet:SetPoint("LEFT", cbPPF, "LEFT", 230, 0);
		cbPet.text = cbPet:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		cbPet.text:SetPoint("LEFT", cbPet, "RIGHT", 4, 0);
		-- Redactado en NEGATIVO, como sus vecinos ("Hide health / mana
		-- numbers"). Tres opciones seguidas donde una dice "Show" y las
		-- otras "Hide" hacen dudar cada vez que tildas.
		--
		-- El setting guardado sigue siendo PartyShowPetFrames, en positivo:
		-- lo lee ApplyPartyPetFrames y esta en los perfiles de la gente.
		-- Darlo vuelta habria roto todo eso por un texto. La inversion vive
		-- solo en la presentacion, marcada con nufInverted para que el
		-- refresco central tampoco se confunda.
		cbPet.text:SetText(L["CB_PARTY_PETS_HIDE"] or "Hide party pet frames");
		cbPet.nufInverted = true;
		cbPet:SetChecked(C.PartyShowPetFrames == false);
		if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyShowPetFrames", cbPet); end
		cbPet:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["CB_PARTY_PETS_HIDE"] or "Hide party pet frames", 1, 1, 1);
			GameTooltip:AddLine(L["TIP_PartyPets"]
				or "The small frames of your party members' pets (hunter, warlock, DK...). Hiding them cleans up the screen in arena.",
				nil, nil, nil, true);
			GameTooltip:Show();
		end);
		cbPet:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		cbPet:SetScript("OnClick", function(self)
			-- Tildado = OCULTAR, o sea PartyShowPetFrames en false.
			local hide = (self:GetChecked() == 1 or self:GetChecked() == true);
			if K.SaveConfig then K.SaveConfig("PartyShowPetFrames", not hide); end
			if K.ApplyPartyPetFrames then K.ApplyPartyPetFrames(); end
		end);
	end

	local modeSep = K.UI.Separator(paneParty, 0, 0, 440);
	modeSep:ClearAllPoints();
	-- Cuelga del checkbox de la IZQUIERDA: cbPet ahora esta en la segunda
	-- columna y anclarse a el corria el separador media pantalla.
	modeSep:SetPoint("TOPLEFT", cbPPF, "BOTTOMLEFT", -4, -14);

	local modeHeader = FHeader(paneParty, L["HEADER_PARTY_MODE"] or "Mode", 0, 0);
	modeHeader:ClearAllPoints();
	modeHeader:SetPoint("TOPLEFT", modeSep, "BOTTOMLEFT", 4, -10);

	local cb3v3 = CreateFrame("CheckButton", "NidhausFrames3v3CB", paneParty, "UICheckButtonTemplate");
	cb3v3:SetPoint("TOPLEFT", modeHeader, "BOTTOMLEFT", 0, -10);
	cb3v3.text = cb3v3:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	cb3v3.text:SetPoint("LEFT", cb3v3, "RIGHT", 4, 0);
	cb3v3.text:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3");
	cb3v3:SetChecked(C.PartyMode3v3 and true or false);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyMode3v3", cb3v3); end
	cb3v3:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["CB_PARTY_3V3"] or "Party Mode 3v3", 1, 1, 1);
		GameTooltip:AddLine(L["TIP_PartyMode3v3"] or "", nil, nil, nil, true);
		GameTooltip:Show();
	end);
	cb3v3:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	-- ── Sliders chicos por miembro (solo con 3v3 activo) ──
	local mini = CreateFrame("Frame", nil, paneParty);
	mini:SetPoint("TOPLEFT", cb3v3, "BOTTOMLEFT", 0, -12);
	mini:SetSize(460, 58);

	for i = 1, 4 do
		local s = CreateFrame("Slider", "NidhausMini3v3Slider"..i, mini, "OptionsSliderTemplate");
		s:SetPoint("TOPLEFT", (i - 1) * 115, -18);
		s:SetWidth(96);
		s:SetMinMaxValues(0.5, 2.0);
		s:SetValueStep(0.05);
		s.setting = "Party3v3Scale"..i;
		s:SetValue(C["Party3v3Scale"..i] or 1.0);

		-- Estos cuatro van en fila y miden 96 px: los topes no entran sin
		-- pisarse entre si. Son los unicos del addon que quedan sin ellos.
		K.UI.SliderEnds(s, "", "");

		local t = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		t:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
		t:SetText((K.UI and K.UI.Label((L["LABEL_PARTY_MEMBER"] or "Party") .. " " .. i))
			or ((L["LABEL_PARTY_MEMBER"] or "Party") .. " " .. i));

		s.ValueText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		s.ValueText:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);
		s.ValueText:SetText((K.UI and K.UI.Value(string.format("%.2f", C["Party3v3Scale"..i] or 1.0)))
			or string.format("%.2f", C["Party3v3Scale"..i] or 1.0));

		s._last = C["Party3v3Scale"..i] or 1.0;
		s:SetScript("OnValueChanged", function(self, value)
			value = math.floor(value / 0.05 + 0.5) * 0.05;
			if self._last == value then return; end
			self._last = value;
			self:SetValue(value);
			local txt = string.format("%.2f", value);
			self.ValueText:SetText((K.UI and K.UI.Value(txt)) or txt);
			C[self.setting] = value;
			if K.Apply3v3MemberScale then K.Apply3v3MemberScale(i); end
		end);
		s:SetScript("OnMouseUp", function(self)
			if K.SaveConfig then K.SaveConfig(self.setting, C[self.setting]); end
		end);
	end

	-- ── Escala general (contenedor propio, para poder ocultarlo) ──
	-- Con Party Mode 3v3 activo, Party Frame Scale y Spacing no hacen nada:
	-- el modo 3v3 maneja la escala de cada miembro por su cuenta. Van en un
	-- frame para poder mostrarlos u ocultarlos como bloque, al reves que los
	-- mini-sliders por miembro.
	-- Anclado al fondo de "mini": los dos grupos son excluyentes y cada uno
	-- vale 1px de alto cuando esta cerrado, asi que lo de abajo sube solo.
	local scaleGroup = CreateFrame("Frame", nil, paneParty);
	scaleGroup:SetPoint("TOPLEFT", mini, "BOTTOMLEFT", 0, -10);
	scaleGroup:SetWidth(440);
	scaleGroup:SetHeight(sliderH * 2 + 40);

	FHeader(scaleGroup, L["HEADER_SCALES"] or "Scale", 0, 0);
	CreateSlider(scaleGroup, L["SLIDER_PARTY_SCALE"], "PartyFrameScale", 0.5, 1.5, 0.05, 0, -30);
	CreateSlider(scaleGroup, L["SLIDER_PARTY_SPACING"], "PartyMemberFrameSpacing", 0, 80, 2, 0, -30 - sliderH);

	local MINI_H  = 58;
	local SCALE_H = sliderH * 2 + 40;

	-- Ademas de mostrar/ocultar hay que COLAPSAR el alto: escondiendolo sin
	-- mas, el grupo seguia ocupando su lugar y quedaba el hueco.
	local function Update3v3Visibility()
		if C.PartyMode3v3 then
			mini:Show();       mini:SetHeight(MINI_H);
			scaleGroup:Hide(); scaleGroup:SetHeight(1);
		else
			mini:Hide();       mini:SetHeight(1);
			scaleGroup:Show(); scaleGroup:SetHeight(SCALE_H);
		end
	end
	Update3v3Visibility();
	K.Update3v3SlidersVisibility = Update3v3Visibility;
	if K.RegisterConfigEvent then
		K.RegisterConfigEvent("CONFIG_CHANGED", Update3v3Visibility);
	end

	cb3v3:SetScript("OnClick", function(self)
		local v = self:GetChecked() == 1 or self:GetChecked() == true;
		if K.SaveConfig then K.SaveConfig("PartyMode3v3", v); end
		if v then
			if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
		else
			if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
		end
		Update3v3Visibility();
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		if K.ScheduleGlobalPositionReapply then K.ScheduleGlobalPositionReapply(); end
	end);

	-- ── Extras del party ──
	-- Anclado al grupo de escala para acompañar el colapso del modo 3v3.
	local featBox = CreateFrame("Frame", nil, paneParty);
	featBox:SetPoint("TOPLEFT", scaleGroup, "BOTTOMLEFT", 0, -20);
	featBox:SetWidth(460);
	-- Encabezado + TRES filas de 28. Antes eran dos columnas y entraba en
	-- 90; ahora cada funcion tiene su fila para que los botones "Open"
	-- queden alineados.
	featBox:SetHeight(116);

	FHeader(featBox, L["HEADER_PARTY_FEATURES"] or "Party Features", 0, 0);
	K.BuildPartyFeatureCheckboxes(featBox, 0, -26);
	py = py - 74 - SCALE_H - 110;

	-- ── Cola de la seccion ──────────────────────────────────────
	-- Va en su propio frame anclado a "Party Features", que a su vez cuelga
	-- del grupo de escala. Antes usaba coordenadas fijas del pane, asi que
	-- al colapsar el modo 3v3 (que cambia el alto en ~74px) todo esto
	-- quedaba corrido o encimado. Adentro las coordenadas son locales.
	local tailBox = CreateFrame("Frame", nil, paneParty);
	tailBox:SetPoint("TOPLEFT", featBox, "BOTTOMLEFT", 0, -10);
	tailBox:SetWidth(460);
	tailBox:SetHeight(300);
	py = 0;

	-- Los tres sub-addons de party tienen su propia ventana de opciones.
	-- Sin esto no habia forma de enterarse salvo leyendo el tooltip.
	-- La nota ya no explica que cada uno tiene su ventana — eso ahora se ve
	-- solo, con el boton al lado. Queda unicamente el comando, para quien
	-- prefiera escribirlo.
	FNote(tailBox, L["NOTE_PARTY_SUBADDONS"]
		or "Commands: /pbuffs, /ptarget, /pcb",
		2, py, 430);
	py = py - 26;

	-- ── Trinkets de party ──
	-- Checkbox propio, independiente del rastreo de arena: se puede
	-- querer ver el trinket del healer sin los marcos de arena tocados.
	K.UI.Separator(tailBox, -4, py + 14, 440);
	FHeader(tailBox, L["HEADER_PARTY_TRINKET"] or "Party Trinkets", 0, py);
	py = py - 20;
	FNote(tailBox, L["NOTE_PARTY_TRINKET"]
		or "PvP trinket cooldown next to each party member. The position is shared by all four.",
		2, py, 430);

	py = py - 32;
	local ptCB = CreateFeatureCheckBox(tailBox, L["CB_PARTY_TRINKETS"] or "Show party trinkets",
		0, py, L["TIP_PartyTrinkets"], "PartyTrinketsEnabled");
	ptCB:SetChecked(C.PartyTrinketsEnabled);
	ptCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.PartyTrinketsEnabled = val;
		if K.SaveConfig then K.SaveConfig("PartyTrinketsEnabled", val); end
		if K.ApplyPartyTrinketSettings then K.ApplyPartyTrinketSettings(); end
	end);
	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox("PartyTrinketsEnabled", ptCB); end

	-- Sub-opciones desplegables: mover, resetear y tamaño solo tienen sentido
	-- con los trinkets prendidos. Antes estaban siempre visibles y quedaban
	-- botones que no hacian nada.
	py = py - 30;
	local ptBody = K.UI.Collapsible(tailBox, 0, py, 440, 96, function()
		return C.PartyTrinketsEnabled == true;
	end);

	local ptMoveBtn = CreateFrame("Button", nil, ptBody, "UIPanelButtonTemplate");
	ptMoveBtn:SetPoint("TOPLEFT", 0, 0);
	ptMoveBtn:SetSize(150, 22);
	ptMoveBtn:SetText(L["BTN_MOVE_TRINKETS"] or "Move them");
	ptMoveBtn:SetScript("OnClick", function(self)
		local on = not (K.IsPartyTrinketMoveMode and K.IsPartyTrinketMoveMode());
		if K.SetPartyTrinketMoveMode then K.SetPartyTrinketMoveMode(on); end
		self:SetText(on and (L["BTN_LOCK_TRINKETS"] or "Done")
			or (L["BTN_MOVE_TRINKETS"] or "Move them"));
	end);

	local ptResetBtn = CreateFrame("Button", nil, ptBody, "UIPanelButtonTemplate");
	ptResetBtn:SetPoint("LEFT", ptMoveBtn, "RIGHT", 8, 0);
	ptResetBtn:SetSize(100, 22);
	ptResetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
	ptResetBtn:SetScript("OnClick", function()
		if K.ResetPartyTrinketPosition then K.ResetPartyTrinketPosition(); end
	end);

	local ptSize = CreateSlider(ptBody, L["SLIDER_PARTY_TRINKET_SIZE"] or "Trinket Size",
		"PartyTrinketSize", 12, 40, 1, 0, -46);
	ptSize:SetWidth(210);
	ptSize:HookScript("OnValueChanged", function()
		if K.ApplyPartyTrinketSettings then K.ApplyPartyTrinketSettings(); end
	end);

	-- Al apagar, salir del modo mover: si no, el boton queda diciendo "Done"
	-- y los iconos arrastrables sueltos por ahi.
	ptCB:HookScript("OnClick", function(self)
		if not self:GetChecked() then
			if K.SetPartyTrinketMoveMode then K.SetPartyTrinketMoveMode(false); end
			ptMoveBtn:SetText(L["BTN_MOVE_TRINKETS"] or "Move them");
		end
		ptBody:Refresh();
	end);

	py = py - 110;

	-- py es local a tailBox (arranca en 0), asi que hay que sumarle lo que
	-- ocupa todo lo de arriba. Se toma el caso mas alto (3v3 apagado).
	-- +90 sobre lo de antes: la seccion crecio con los dos encabezados
	-- nuevos (Pets y su separador, el separador de Mode) y con el boton de
	-- prueba, que paso de ir al lado del checkbox a su propio renglon.
	side.SetContentHeight(2, -810 + py - 30);

	-- ══════════════════════════════════════════════════════
	-- 3) BUFFS Y DEBUFFS
	-- ══════════════════════════════════════════════════════
	local ay = -14;
	FHeader(paneAuras, L["HEADER_AURAS"] or "Player Buffs and Debuffs", x, ay);

	ay = ay - 22;
	FNote(paneAuras, L["DESC_AURAS"]
		or "Unlock to drag the buff and debuff blocks anywhere on the screen.",
		x + 2, ay, 215);

	ay = ay - 48;
	local auraBtn = CreateFrame("Button", nil, paneAuras, "UIPanelButtonTemplate");
	auraBtn:SetPoint("TOPLEFT", x, ay);
	auraBtn:SetSize(145, 24);
	auraBtn:SetText(L["BTN_MOVE_AURAS"] or "Unlock buffs / debuffs");
	auraBtn:SetScript("OnClick", function()
		if K.ToggleGlobalUnlock then K.ToggleGlobalUnlock("extra"); end
	end);

	local auraReset = CreateFrame("Button", nil, paneAuras, "UIPanelButtonTemplate");
	auraReset:SetPoint("LEFT", auraBtn, "RIGHT", 8, 0);
	auraReset:SetSize(75, 24);
	auraReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
	auraReset:SetScript("OnClick", function()
		if K.ResetAuraAnchor then K.ResetAuraAnchor(); end
	end);

	-- ── Iconos por fila (buffs del jugador) ──
	ay = ay - 62;
	do
		local s = CreateFrame("Slider", nil, paneAuras, "OptionsSliderTemplate");
		s:SetPoint("TOPLEFT", x + 4, ay);
		s:SetWidth(215);
		s:SetMinMaxValues(4, 16);
		s:SetValueStep(1);
		K.UI.SliderEnds(s, "4", "16");
		local title = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		title:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
		title:SetText((K.UI and K.UI.Label(L["SLIDER_ICONS_PER_ROW"] or "Icons per row"))
			or (L["SLIDER_ICONS_PER_ROW"] or "Icons per row"));
		local val = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		val:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);

		local cur = (K.GetAuraIconsPerRow and K.GetAuraIconsPerRow()) or 8;
		s:SetValue(cur);
		val:SetText(tostring(cur));
		s._last = cur;
		s:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v + 0.5);
			if self._last == v then return; end
			self._last = v;
			val:SetText(tostring(v));
			if K.SaveConfig then K.SaveConfig("AuraIconsPerRow", v); end
			if K.ApplyAuraIconsPerRow then K.ApplyAuraIconsPerRow(); end
		end);

		FNote(paneAuras, L["NOTE_ICONS_PER_ROW"]
			or "How many buff icons fit in one row before wrapping to the next.",
			x + 4, ay - 34, 215);
	end

	-- ── Escala de los bloques ──
	-- Son DOS sliders porque los buffs y los debuffs se mueven por separado:
	-- tiene sentido poder agrandar uno sin tocar el otro.
	-- UNA DEBAJO DE LA OTRA.
	--
	-- Antes iban lado a lado (x+4 y x+240) y entre las dos median 440 px:
	-- con la segunda columna arrancando en 250, la de debuffs se le metia
	-- encima. En una columna de ~230 entran apiladas sin achicarlas.
	ay = ay - 84;
	if K.UI and K.UI.ScaleSlider then
		K.UI.ScaleSlider(paneAuras, "PlayerBuffs",   x + 4, ay, 215,
			L["SLIDER_BUFF_SCALE"] or "Buff scale");
		ay = ay - 56;
		K.UI.ScaleSlider(paneAuras, "PlayerDebuffs", x + 4, ay, 215,
			L["SLIDER_DEBUFF_SCALE"] or "Debuff scale");
	end

	ay = ay - 60;

	-- ══ COLUMNA DERECHA ══════════════════════════════════
	--
	-- Antes todo esto iba abajo, en una sola columna: la pestaña ocupaba
	-- dos pantallas de scroll con media pantalla vacia a la derecha. Son
	-- dos temas distintos — arriba DONDE se ubican TUS auras, aca COMO se
	-- ven las del que estas mirando — asi que uno en cada columna se lee
	-- mejor y entra todo de una. Mismo criterio que la pestaña Minimapa.
	local ry = -14;
	FHeader(paneAuras, L["HEADER_AURA_BORDERS"] or "Target and Focus Auras", xR, ry);

	ry = ry - 24;
	local abCB = CreateFeatureCheckBox(paneAuras, L["CB_AURA_BORDERS"] or "Custom aura borders",
		xR, ry, L["TIP_AuraBordersEnabled"], "AuraBordersEnabled");
	abCB:SetChecked(C.AuraBordersEnabled and true or false);

	ry = ry - 24;
	FNote(paneAuras, L["NOTE_AURA_BORDERS"] or "", xR + 24, ry, 210);

	ry = ry - 56;
	local abPurgeCB = CreateFeatureCheckBox(paneAuras, L["CB_AURA_PURGE"] or "Highlight purgeable buffs",
		xR + 16, ry, L["TIP_AuraBordersPurge"], "AuraBordersPurge");
	abPurgeCB:SetChecked(C.AuraBordersPurge ~= false);

	-- El resplandor no hace nada sin los bordes puestos: se apaga solo.
	local function SyncAuraBorderRow()
		local on = C.AuraBordersEnabled and true or false;
		if on then abPurgeCB:Enable(); else abPurgeCB:Disable(); end
		abPurgeCB:SetAlpha(on and 1 or 0.4);
	end
	SyncAuraBorderRow();

	abCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.AuraBordersEnabled = val;
		if K.SaveConfig then K.SaveConfig("AuraBordersEnabled", val); end
		if K.ApplyAuraBorders then K.ApplyAuraBorders(); end
		SyncAuraBorderRow();
	end);

	abPurgeCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.AuraBordersPurge = val;
		if K.SaveConfig then K.SaveConfig("AuraBordersPurge", val); end
		if K.ApplyAuraBorders then K.ApplyAuraBorders(); end
	end);

	-- ── Quien lanzo el aura ──
	-- No depende de los bordes custom: funciona con el tooltip de
	-- cualquier icono de buff o debuff, sea de Blizzard o de NUF.
	ry = ry - 46;
	K.UI.Separator(paneAuras, xR, ry + 12, 215);

	ry = ry - 16;
	local castByCB = CreateFeatureCheckBox(paneAuras,
		L["CB_AURA_CAST_BY"] or "Show who cast the aura",
		xR, ry, L["TIP_AuraCastBy"], "AuraCastBy");
	castByCB:SetChecked(C.AuraCastBy and true or false);

	ry = ry - 24;
	FNote(paneAuras, L["NOTE_AURA_CAST_BY"] or "", xR + 24, ry, 210);

	castByCB:SetScript("OnClick", function(self)
		local val = self:GetChecked() and true or false;
		C.AuraCastBy = val;
		if K.SaveConfig then K.SaveConfig("AuraCastBy", val); end
	end);

	ry = ry - 40;

	-- Manda la columna mas larga: con la corta el scroll cortaba la otra.
	side.SetContentHeight(3, math.min(ay, ry) - 30);

	-- ══════════════════════════════════════════════════════
	-- 4) BOSS (PvE)
	-- ══════════════════════════════════════════════════════
	local vy = -14;
	FHeader(paneBoss, L["HEADER_BOSS"] or "Boss Frames (PvE)", x, vy);

	local showBossBtn = CreateFrame("Button", nil, paneBoss, "UIPanelButtonTemplate");
	showBossBtn:SetPoint("TOPLEFT", x + 190, vy - 3);
	showBossBtn:SetSize(140, 20);
	showBossBtn:SetText(L["BTN_SHOW_BOSS"] or "Show Boss Frame");
	showBossBtn:SetScript("OnClick", function()
		if SlashCmdList and SlashCmdList["NUF"] then SlashCmdList["NUF"]("boss"); end
	end);

	vy = vy - 36;
	CreateSlider(paneBoss, L["SLIDER_BOSS_SCALE"], "BossFrameScale", 0.3, 1.5, 0.05, x, vy);
	vy = vy - sliderH;
	CreateSlider(paneBoss, L["SLIDER_BOSS_SPACING"], "BossTargetFrameSpacing", -50, 100, 5, x, vy);
	vy = vy - sliderH;

	side.SetContentHeight(4, vy - 40);

	-- ══════════════════════════════════════════════════════
	-- 5) PET (mascota del jugador)
	-- ══════════════════════════════════════════════════════
	local pv = -14;
	FHeader(panePet, L["HEADER_PET"] or "Pet Frame", x, pv);

	pv = pv - 24;
	FNote(panePet, L["NOTE_PET"]
		or "Scale of your pet frame (hunter, warlock, mage water elemental, death knight ghoul).",
		x + 2, pv, 430);

	pv = pv - 36;
	CreateSlider(panePet, L["SLIDER_PET_SCALE"] or "Pet Frame Scale", "PetFrameScale",
		0.5, 1.5, 0.05, x, pv);
	pv = pv - sliderH - 6;

	local petResetBtn = CreateFrame("Button", nil, panePet, "UIPanelButtonTemplate");
	petResetBtn:SetPoint("TOPLEFT", x, pv);
	petResetBtn:SetSize(140, 22);
	petResetBtn:SetText(L["BTN_RESET"] or "Reset");
	petResetBtn:SetScript("OnClick", function()
		C.PetFrameScale = 1.0;
		if K.SaveConfig then K.SaveConfig("PetFrameScale", 1.0); end
		if K.ApplyPetFrameScale then K.ApplyPetFrameScale(1.0); end
		if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
		-- Tambien la POSICION: antes solo volvia la escala y si habias
		-- movido el marco con "Mover todo" se quedaba donde lo dejaste.
		if K.ResetGlobalPositions then K.ResetGlobalPositions({ Pet = true }); end
	end);
	pv = pv - 40;

	side.SetContentHeight(5, pv - 30);

	-- Compatibilidad: OptionsPanel.lua ya no dibuja nada aca, pero dejamos
	-- los campos por si algun modulo viejo los consulta.
	panel.positionsPane   = paneMain;
	panel.positionsStartY = 0;
	panel.framesSubTabs   = nil;
end
