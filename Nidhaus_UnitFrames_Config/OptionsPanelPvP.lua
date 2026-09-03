-- Este archivo vive en Nidhaus_UnitFrames_Config, un addon aparte que se
-- carga SOLO cuando abris el panel (LoadOnDemand). Por eso no recibe el
-- namespace por "...", que es privado de cada addon: lo toma de la global
-- que publica el addon principal en Core/Init.lua.
local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

-- Selector de estilo de borde: tres botones excluyentes con el activo
-- resaltado, el mismo patron que el selector de estilo de marco de grupo.
-- getFn devuelve el estilo actual, setFn lo cambia.
-- Selector de opciones excluyentes: una fila de botones donde el elegido
-- queda azul y los otros apagados. Nacio para los tres estilos de borde de
-- los timers; ahora tambien lo usa la posicion de las auras de la Power
-- Bar, asi que las opciones y el titulo vienen por parametro.
local function ChoiceSelector(parent, px, py, labelText, opts, getFn, setFn, bw)
	bw = bw or 88;
	local bh, gap = 22, 4;
	local buttons = {};

	local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	lbl:SetPoint("TOPLEFT", px, py);
	lbl:SetText((K.UI and K.UI.Label(labelText)) or labelText);

	local box = CreateFrame("Frame", nil, parent);
	box:SetPoint("TOPLEFT", px, py - 16);
	box:SetSize((#opts * bw) + ((#opts - 1) * gap), bh);

	local function Refresh()
		local cur = getFn();
		for _, b in ipairs(buttons) do
			if b.value == cur then
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

	for i, opt in ipairs(opts) do
		local b = CreateFrame("Button", nil, box);
		b:SetSize(bw, bh);
		b:SetPoint("LEFT", box, "LEFT", (i - 1) * (bw + gap), 0);
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
			setFn(self.value);
			Refresh();
		end);
		buttons[i] = b;
	end
	Refresh();
	return box, Refresh;
end

local function BorderStyleSelector(parent, px, py, getFn, setFn)
	return ChoiceSelector(parent, px, py, L["BTN_BORDER_LABEL"] or "Border:", {
		{ value = "Tooltip",  text = L["BORDER_TOOLTIP"]  or "Tooltip" },
		{ value = "None",     text = L["BORDER_NONE"]     or "No border" },
		{ value = "Blizzard", text = L["BORDER_BLIZZARD"] or "Blizzard" },
	}, function() return getFn() or "Tooltip"; end, setFn);
end

-- =========================================================
-- OptionsPanelPvP.lua
-- Pestaña PvP.
--
-- Secciones:
--   Class Options -> DETECTA la clase del personaje y muestra solo
--                    los modulos que esa clase puede usar. Un mago no
--                    tiene por que ver el contador de flechas.
--   Enemigos / Yo -> avisos y contadores pensados para arena.
--
-- Como se agrega una clase nueva: sumar una entrada a CLASS_MODULES
-- con sus checkboxes. No hay que tocar nada mas.
-- =========================================================

local checkboxCount = 0;

-- ---------------------------------------------------------
-- Helpers locales (mismos estilos que el resto del panel)
-- ---------------------------------------------------------
local function Header(parent, text, x, y)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetText((K.UI and K.UI.Header(K.UI.Strip(text))) or text);
	return fs;
end

local function Note(parent, text, x, y, width)
	local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	fs:SetPoint("TOPLEFT", x, y);
	fs:SetWidth(width or 420);
	fs:SetJustifyH("LEFT");
	fs:SetText("|cff8EAEC9" .. (text or "") .. "|r");
	return fs;
end

-- Checkbox de un setting de C
local function SettingCB(parent, label, setting, x, y, tip, onChange)
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausPvPCB" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local fs = _G[cbName .. "Text"];
	if fs then fs:SetText(label); end

	local v = C[setting];
	if type(v) == "number" then v = (v == 1); end
	cb:SetChecked(v == true);

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
		local val = (self:GetChecked() == 1 or self:GetChecked() == true);
		K.SaveConfig(setting, val);
		if onChange then onChange(val); end
	end);

	if K.RegisterSettingCheckbox then K.RegisterSettingCheckbox(setting, cb); end
	return cb;
end

-- Checkbox de un modulo
local function ModuleCB(parent, label, moduleId, x, y, tip)
	if not (K.Modules and K.Modules[moduleId]) then return nil; end
	checkboxCount = checkboxCount + 1;
	local cbName = "NidhausPvPCB" .. checkboxCount;
	local cb = CreateFrame("CheckButton", cbName, parent, "InterfaceOptionsCheckButtonTemplate");
	cb:SetPoint("TOPLEFT", x, y);
	cb:SetHitRectInsets(0, 0, 0, 0);

	local fs = _G[cbName .. "Text"];
	if fs then fs:SetText(label); end

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

	-- LA DESCRIPCION, VISIBLE.
	--
	-- Antes solo salia en el tooltip, y por eso las pestañas de clase se
	-- veian peladas al lado de la pestaña PvP: aquella usa ModuleBlock, que
	-- si la dibuja. Los textos ya existian y ya estaban traducidos — no se
	-- mostraban, nada mas.
	--
	-- Se devuelve el alto que ocupo para que quien llama sepa cuanto bajar:
	-- las descripciones tienen largos distintos y un numero fijo dejaria
	-- huecos en unas y superposiciones en otras.
	--
	-- Se ancla AL CHECKBOX, no a coordenadas fijas: hay llamadas que despues
	-- reubican el checkbox (Paladin auras lo hace), y con coordenadas fijas
	-- la descripcion se quedaba sola en el lugar viejo.
	local descH, descFS = 0, nil;
	if tip and tip ~= "" then
		descFS = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		descFS:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 26, -2);
		descFS:SetWidth(420);
		descFS:SetJustifyH("LEFT");
		descFS:SetText("|cff8EAEC9" .. tip .. "|r");
		descH = math.max(14, descFS:GetStringHeight() or 14) + 6;
	end

	cb:SetScript("OnClick", function(self)
		local val = (self:GetChecked() == 1 or self:GetChecked() == true);
		if K.SetModuleEnabled then K.SetModuleEnabled(moduleId, val); end
		if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox(moduleId); end
	end);
	if K.RegisterModuleCheckbox then K.RegisterModuleCheckbox(moduleId, cb); end
	return cb, descH, descFS;
end

-- ---------------------------------------------------------
-- BLOQUE DE MODULO (desplegable)
--
-- Cada addon/modulo vive en su propio bloque: una franja divisoria
-- arriba, el checkbox que lo prende, y un "cuerpo" con sus opciones que
-- SOLO se despliega cuando el modulo esta activo. Con el modulo apagado
-- el cuerpo se oculta y el bloque se achica, asi que los bloques de abajo
-- suben solos (van anclados uno al otro, no a coordenadas fijas).
--
-- Uso:
--   local blk, body = ModuleBlock(pane, prev, "PowerBar", "Power Bar", desc)
--   ... crear controles con parent = body ...
--   blk:SetBodyHeight(140)   -- alto del cuerpo desplegado
--   blk:Refresh()
-- ---------------------------------------------------------
local BLOCK_W = 470;

local function ModuleBlock(pane, prev, moduleId, label, desc, tip)
	local blk = CreateFrame("Frame", nil, pane);
	blk:SetWidth(BLOCK_W);
	if prev then
		blk:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -10);
	else
		blk:SetPoint("TOPLEFT", 16, -14);
	end

	-- Franja divisoria que separa este addon del anterior
	local sep = blk:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.13);
	sep:SetPoint("TOPLEFT", 0, 0);
	sep:SetPoint("TOPRIGHT", 0, 0);
	sep:SetHeight(1);

	local headH = 26;

	-- Checkbox del modulo
	local cb = ModuleCB(blk, label, moduleId, 0, -10, tip);
	if not cb then
		-- El modulo no existe (no cargado): bloque vacio pero valido
		blk:SetHeight(1);
		blk.Refresh = function() end;
		blk.SetBodyHeight = function() end;
		return blk, blk;
	end

	local descFS;
	if desc and desc ~= "" then
		descFS = blk:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		descFS:SetPoint("TOPLEFT", 26, -34);
		descFS:SetWidth(BLOCK_W - 40);
		descFS:SetJustifyH("LEFT");
		descFS:SetText("|cff8EAEC9" .. desc .. "|r");
		headH = 34 + math.max(14, descFS:GetStringHeight() or 14) + 6;
	end

	-- Cuerpo desplegable
	local body = CreateFrame("Frame", nil, blk);
	body:SetPoint("TOPLEFT", 0, -headH);
	body:SetWidth(BLOCK_W);
	body:SetHeight(1);

	blk._headH = headH;
	blk._bodyH = 0;

	function blk:SetBodyHeight(h)
		self._bodyH = h or 0;
		body:SetHeight(math.max(1, self._bodyH));
	end

	function blk:Refresh()
		local on = K.IsModuleEnabled and K.IsModuleEnabled(moduleId);
		if on then
			body:Show();
			self:SetHeight(self._headH + self._bodyH + 4);
		else
			body:Hide();
			self:SetHeight(self._headH);
		end
	end

	cb:HookScript("OnClick", function() blk:Refresh(); end);
	pane:HookScript("OnShow", function() blk:Refresh(); end);

	blk.checkbox = cb;
	return blk, body;
end

-- Bloque "solo texto" (encabezado de seccion), mismo sistema de anclaje
local function HeaderBlock(pane, prev, title, note)
	local blk = CreateFrame("Frame", nil, pane);
	blk:SetWidth(BLOCK_W);
	if prev then
		blk:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -14);
	else
		blk:SetPoint("TOPLEFT", 16, -14);
	end

	local h = 0;
	local fs = blk:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fs:SetPoint("TOPLEFT", 0, 0);
	fs:SetText((K.UI and K.UI.Header(K.UI.Strip(title))) or title);
	h = 20;

	if note and note ~= "" then
		local n = blk:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		n:SetPoint("TOPLEFT", 2, -h);
		n:SetWidth(BLOCK_W - 20);
		n:SetJustifyH("LEFT");
		n:SetText("|cff8EAEC9" .. note .. "|r");
		h = h + math.max(14, n:GetStringHeight() or 14) + 4;
	end

	blk:SetHeight(h);
	return blk;
end

-- NOTA: aca vivia SoonRow(), que dibujaba las filas de "coming soon".
-- Se borraron todas: la pestaña anuncia lo que hace, no lo que va a hacer.

-- ---------------------------------------------------------
-- Modulos por clase
-- ---------------------------------------------------------
local CLASS_COLORS = {
	MAGE        = "|cff69CCF0", HUNTER = "|cffABD473", ROGUE   = "|cffFFF569",
	WARRIOR     = "|cffC79C6E", PRIEST = "|cffFFFFFF", WARLOCK = "|cff9482C9",
	PALADIN     = "|cffF58CBA", SHAMAN = "|cff0070DE", DRUID   = "|cffFF7D0A",
	DEATHKNIGHT = "|cffC41F3B",
};


	-- Picaro y druida comparten el mismo bloque: son las unicas dos
	-- clases con puntos de combo, asi que la UI es identica.
	local function ComboSection(pane, x, y)
		Header(pane, L["PVP_COMBO"] or "Combo Points", x, y);
		y = y - 24;

		local _, cwH = ModuleCB(pane, L["MOD_COMBOWATCH"] or "Combo Points", "ComboWatch",
			x, y, L["MOD_COMBOWATCH_DESC"]);
		y = y - 26 - (cwH or 0);

		SettingCB(pane, L["CB_LOCK_COMBO"] or "Lock it in place", "ComboWatchLocked",
			x + 22, y, L["TIP_ComboWatchLocked"]
			or "While locked it ignores the mouse: you can click through it.",
			function() if K.ApplyComboWatchLock then K.ApplyComboWatchLock(); end end);
		y = y - 52;

		local showBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		showBtn:SetPoint("TOPLEFT", x + 2, y);
		showBtn:SetSize(150, 22);
		showBtn:SetText(L["BTN_SHOW_BARS"] or "Show to position");
		showBtn:SetScript("OnClick", function(self)
			local on = not (K.IsComboWatchPreview and K.IsComboWatchPreview());
			if K.SetComboWatchPreview then K.SetComboWatchPreview(on); end
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_SHOW_BARS"] or "Show to position"));
		end);

		local resetBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		resetBtn:SetPoint("LEFT", showBtn, "RIGHT", 8, 0);
		resetBtn:SetSize(100, 22);
		resetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
		resetBtn:SetScript("OnClick", function()
			if K.ResetComboWatchPosition then K.ResetComboWatchPosition(); end
		end);

		return y - 44;
	end

-- Cada entrada dibuja su bloque y devuelve el nuevo yPos.
local CLASS_MODULES = {

	ROGUE = function(pane, x, y)
		y = ComboSection(pane, x, y);


		return y;
	end,

	DRUID = function(pane, x, y)
		y = ComboSection(pane, x, y);


		return y;
	end,


	MAGE = function(pane, x, y)
		Header(pane, L["PVP_TIMERS"] or "Timers", x, y);
		y = y - 24;

		SettingCB(pane, L["BAR_WATER_ELE"] or "Water Elemental", "MageWaterEleTimer",
			x, y, L["TIP_MageWaterEle"]
			or "Duration bar for the Water Elemental. Hidden automatically if you have the Glyph of Eternal Water, since the pet is permanent.");
		y = y - 26;

		SettingCB(pane, L["BAR_MIRROR"] or "Mirror Image", "MageMirrorTimer",
			x, y, L["TIP_MageMirror"] or "30 second duration bar for Mirror Image.");
		y = y - 34;

		-- Las barras se arrastran solas con el boton izquierdo; esto solo
		-- las fija cuando ya quedaron donde uno quiere (igual que el
		-- "Lock Frames" del MageNuggets original).
		SettingCB(pane, L["CB_LOCK_CLASS_BARS"] or "Lock the bars", "ClassTimersLocked",
			x, y, L["TIP_ClassTimersLocked"]
			or "While locked the bars ignore the mouse: you can click through them.",
			function() if K.ApplyClassTimersLock then K.ApplyClassTimersLock(); end end);
		y = y - 48;

		-- Escala de las barras de clase
		do
			local cs = CreateFrame("Slider", nil, pane, "OptionsSliderTemplate");
			cs:SetPoint("TOPLEFT", x + 2, y);
			cs:SetWidth(200);
			cs:SetMinMaxValues(0.5, 2.0);
			cs:SetValueStep(0.05);
			K.UI.SliderEnds(cs, "0.50", "2.00");
			local ct = cs:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
			ct:SetPoint("BOTTOMLEFT", cs, "TOPLEFT", 0, 2);
			ct:SetText((K.UI and K.UI.Label(L["SLIDER_SCALE"] or "Scale")) or "Scale");
			local cv = cs:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			cv:SetPoint("BOTTOMRIGHT", cs, "TOPRIGHT", 0, 2);
			local cur = (K.GetClassTimersScale and K.GetClassTimersScale()) or 1.0;
			cs:SetValue(cur); cv:SetText(string.format("%.2f", cur)); cs._last = cur;
			cs:SetScript("OnValueChanged", function(self, v)
				v = math.floor(v * 20 + 0.5) / 20;
				if self._last == v then return; end
				self._last = v;
				cv:SetText(string.format("%.2f", v));
				if K.SetClassTimersScale then K.SetClassTimersScale(v); end
			end);
		end
		y = y - 34;

		local showBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		showBtn:SetPoint("TOPLEFT", x + 2, y);
		showBtn:SetSize(150, 22);
		showBtn:SetText(L["BTN_SHOW_BARS"] or "Show to position");
		showBtn:SetScript("OnClick", function(self)
			local on = not (K.IsClassTimersPreview and K.IsClassTimersPreview());
			if K.SetClassTimersPreview then K.SetClassTimersPreview(on); end
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_SHOW_BARS"] or "Show to position"));
		end);

		local resetBtn = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate");
		resetBtn:SetPoint("LEFT", showBtn, "RIGHT", 8, 0);
		resetBtn:SetSize(100, 22);
		resetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
		resetBtn:SetScript("OnClick", function()
			if K.ResetClassTimerPositions then K.ResetClassTimerPositions(); end
		end);
		y = y - 44;

		-- ── Apariencia: skin "Icy Portrait" del marco del jugador ──
		Header(pane, L["PVP_MAGE_APPEARANCE"] or "Appearance", x, y);
		y = y - 24;
		-- El tooltip decia "necesita Custom Skin activado". Ya no: Icy es un
		-- skin propio y se aplica solo. Dejarlo habria mandado a la gente a
		-- prender una opcion que no hace falta.
		SettingCB(pane, L["CB_MAGE_ICY"] or "Icy player frame", "MageIcyFrame",
			x, y, L["TIP_MageIcy"]
			or "Frost / ice skin for your player frame. Works on its own, no other option needed.",
			function() if K.ApplyPlayerFrameSkin then K.ApplyPlayerFrameSkin(); end end);
		y = y - 34;


		return y;
	end,

	HUNTER = function(pane, x, y)
		Header(pane, L["PVP_SHOOTING"] or "Shooting", x, y);
		y = y - 24;

		local asCB, asH = ModuleCB(pane, L["MOD_AUTOSHOT"] or "Auto Shot Timer", "AutoShotTimer",
			x, y, L["MOD_AUTOSHOT_DESC"]);
		y = y - 26 - (asH or 0);

		-- Cuerpo desplegable con la unica opcion de la barra: el borde,
		-- que cicla entre tooltip, sin marco y barra de casteo.
		local asBody = K.UI.Collapsible(pane, x, y, 440, 44, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("AutoShotTimer");
		end);
		if asCB then asCB:HookScript("OnClick", function() asBody:Refresh(); end); end

		BorderStyleSelector(asBody, 22, 0,
			function() return (K.GetAutoShotBorderStyle and K.GetAutoShotBorderStyle()) or "Tooltip"; end,
			function(v) if K.SetAutoShotBorderStyle then K.SetAutoShotBorderStyle(v); end end);

		y = y - 32;

		local _, acH = ModuleCB(pane, L["MOD_ARROWCOUNT"] or "Arrow / Bullet Count", "ArrowCount",
			x, y, L["MOD_ARROWCOUNT_DESC"]);
		y = y - 42 - (acH or 0);

		-- ── Buffs de la mascota ──
		Header(pane, L["PVP_HUNTER_PETSECTION"] or "Pet", x, y);
		y = y - 24;

		local pbCB, pbH = ModuleCB(pane, L["MOD_PETBUFFS"] or "Pet Buffs", "HunterPetBuffs",
			x, y, L["MOD_PETBUFFS_DESC"]);
		y = y - 26 - (pbH or 0);

		-- Cuerpo desplegable: las opciones solo se ven con el modulo
		-- encendido. Todo lo de adentro va con parent = pbBody y
		-- coordenadas locales.
		local pbBody = K.UI.Collapsible(pane, x, y, 440, 130, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("HunterPetBuffs");
		end);
		if pbCB then pbCB:HookScript("OnClick", function() pbBody:Refresh(); end); end

		SettingCB(pbBody, L["CB_LOCK_PETBUFFS"] or "Lock them in place", "PetBuffsLocked",
			22, 0, L["TIP_PetBuffsLocked"]
			or "While locked they ignore the mouse: you can click through them.");

		local pbShow = CreateFrame("Button", nil, pbBody, "UIPanelButtonTemplate");
		pbShow:SetPoint("TOPLEFT", 2, -32);
		pbShow:SetSize(150, 22);
		pbShow:SetText(L["BTN_SHOW_BARS"] or "Show to position");
		pbShow:SetScript("OnClick", function(self)
			local on = not (K.IsPetBuffsPreview and K.IsPetBuffsPreview());
			if K.SetPetBuffsPreview then K.SetPetBuffsPreview(on); end
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_SHOW_BARS"] or "Show to position"));
		end);

		local pbReset = CreateFrame("Button", nil, pbBody, "UIPanelButtonTemplate");
		pbReset:SetPoint("LEFT", pbShow, "RIGHT", 8, 0);
		pbReset:SetSize(100, 22);
		pbReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		pbReset:SetScript("OnClick", function()
			if K.ResetPetBuffsPosition then K.ResetPetBuffsPosition(); end
		end);

		local pbSize = CreateFrame("Slider", nil, pbBody, "OptionsSliderTemplate");
		pbSize:SetPoint("TOPLEFT", 0, -84);
		pbSize:SetWidth(210);
		pbSize:SetMinMaxValues(16, 48);
		pbSize:SetValueStep(1);
		pbSize:SetValue(C.PetBuffsIconSize or 32);
		K.UI.SliderEnds(pbSize, "16", "48");
		local pbSizeTitle = pbSize:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		pbSizeTitle:SetPoint("BOTTOMLEFT", pbSize, "TOPLEFT", 0, 2);
		pbSizeTitle:SetText((K.UI and K.UI.Label(L["SLIDER_PETBUFF_SIZE"] or "Icon Size"))
			or (L["SLIDER_PETBUFF_SIZE"] or "Icon Size"));
		pbSize.ValueText = pbSize:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		pbSize.ValueText:SetPoint("BOTTOMRIGHT", pbSize, "TOPRIGHT", 0, 2);
		pbSize.ValueText:SetText(tostring(C.PetBuffsIconSize or 32));
		pbSize._last = C.PetBuffsIconSize or 32;
		pbSize:SetScript("OnValueChanged", function(self, value)
			value = math.floor(value + 0.5);
			if self._last == value then return; end
			self._last = value;
			self:SetValue(value);
			self.ValueText:SetText(tostring(value));
			C.PetBuffsIconSize = value;
			if K.ApplyPetBuffsLayout then K.ApplyPetBuffsLayout(); end
		end);
		pbSize:SetScript("OnMouseUp", function(self)
			if K.SaveConfig then K.SaveConfig("PetBuffsIconSize", C.PetBuffsIconSize); end
		end);

		return y - 130;
	end,

	PALADIN = function(pane, x, y)
		-- ── Defensivas: CD interno visual (de NidhausTools) ──
		Header(pane, L["PVP_PALADIN_DEF"] or "Defensives", x, y);
		y = y - 24;

		local icdCB, icdH = ModuleCB(pane, L["MOD_PALADIN_ICD"] or "Paladin ICD", "PaladinICD",
			x, y, L["MOD_PALADIN_ICD_DESC"]);
		y = y - 24 - (icdH or 0);

		-- Sub-opciones dentro de un cuerpo desplegable: solo se ven con el
		-- modulo encendido. Lo que sigue se ancla AL CUERPO, asi que al
		-- colapsarlo (alto 1) sube solo en vez de dejar un hueco.
		local body = CreateFrame("Frame", nil, pane);
		body:SetPoint("TOPLEFT", x, y);
		body:SetWidth(440);

		-- Aca habia una segunda descripcion que repetia casi lo mismo que la
		-- del modulo (incluida la lista de hechizos, dos veces) y ademas se
		-- le superponia. Con la descripcion ya visible arriba, sobra.

		SettingCB(body, L["CB_PALADIN_ICD_KEEP"] or "Keep it on screen when ready",
			"PaladinICDKeepVisible", 22, -6, L["TIP_PaladinICDKeep"]
			or "Leaves the icon visible in color once the cooldown is over, so you can see at a glance that it is up. Otherwise it hides until you use it again.",
			function() if K.ApplyPaladinICDVisibility then K.ApplyPaladinICDVisibility(); end end);

		local moveBtn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate");
		moveBtn:SetPoint("TOPLEFT", 2, -38);
		moveBtn:SetSize(150, 22);
		moveBtn:SetText(L["BTN_MOVE_IT"] or "Move it");
		moveBtn:SetScript("OnClick", function(self)
			if not K.TogglePaladinICDMove then return; end
			local on = K.TogglePaladinICDMove();
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local resetBtn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate");
		resetBtn:SetPoint("LEFT", moveBtn, "RIGHT", 8, 0);
		resetBtn:SetSize(100, 22);
		resetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
		resetBtn:SetScript("OnClick", function()
			if K.ResetPaladinICDPosition then K.ResetPaladinICDPosition(); end
		end);

		local BODY_H = 68;
		local function RefreshICD()
			local on = K.IsModuleEnabled and K.IsModuleEnabled("PaladinICD");
			if on then
				body:Show();
				body:SetHeight(BODY_H);
			else
				body:Hide();
				body:SetHeight(1);
			end
		end
		if icdCB then icdCB:HookScript("OnClick", RefreshICD); end
		pane:HookScript("OnShow", RefreshICD);
		RefreshICD();

		-- ── Auras portadas del grupo de WeakAuras "paladin wa" ──
		local auraHdr = pane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		auraHdr:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -20);
		auraHdr:SetText((K.UI and K.UI.Header(K.UI.Strip(L["PVP_PALADIN_AURAS"] or "Auras")))
			or (L["PVP_PALADIN_AURAS"] or "Auras"));

		local auraCB, _, auraDesc = ModuleCB(pane, L["MOD_PALADIN_AURAS"] or "Paladin tracker",
			"PaladinAuras", x, 0, L["MOD_PALADIN_AURAS_DESC"]);
		if auraCB then
			auraCB:ClearAllPoints();
			auraCB:SetPoint("TOPLEFT", auraHdr, "BOTTOMLEFT", 0, -6);
		end

		local auraBody = K.UI.Collapsible(pane, x, 0, 440, 34, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("PaladinAuras");
		end);
		auraBody:ClearAllPoints();
		-- Debajo de la DESCRIPCION si la hay; si no, del checkbox.
		auraBody:SetPoint("TOPLEFT", auraDesc or auraCB or auraHdr, "BOTTOMLEFT",
			auraDesc and -26 or 0, -6);
		if auraCB then auraCB:HookScript("OnClick", function() auraBody:Refresh(); end); end

		-- Idem: la descripcion del modulo ya dice esto mismo.

		local paMove = CreateFrame("Button", nil, auraBody, "UIPanelButtonTemplate");
		paMove:SetPoint("TOPLEFT", 2, -6);
		paMove:SetSize(150, 22);
		paMove:SetText(L["BTN_MOVE_IT"] or "Move it");
		paMove:SetScript("OnClick", function(self)
			if not K.SetPaladinAurasPreview then return; end
			local on = K.SetPaladinAurasPreview(not (K.IsPaladinAurasPreview and K.IsPaladinAurasPreview()));
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local paReset = CreateFrame("Button", nil, auraBody, "UIPanelButtonTemplate");
		paReset:SetPoint("LEFT", paMove, "RIGHT", 8, 0);
		paReset:SetSize(100, 22);
		paReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		paReset:SetScript("OnClick", function()
			if K.ResetPaladinAurasPosition then K.ResetPaladinAurasPosition(); end
		end);

		-- Turn Evil es un modulo APARTE, no un sub-ajuste de Paladin auras:
		-- rastrea otra cosa y tiene su propia posicion en pantalla.
		--
		-- Antes su checkbox vivia DENTRO de auraBody, y como auraBody se
		-- pliega cuando Paladin auras esta destildado, Turn Evil desaparecia
		-- con el. Quedaba imposible prenderlo sin prender el otro primero.
		-- Ahora cuelga de "pane" igual que auraCB, asi que se ve siempre, y
		-- lo unico que se pliega es su propio cuerpo de botones.
		local teCB, _, teDesc = ModuleCB(pane, L["MOD_TURN_EVIL"] or "Turn Evil tracker",
			"TurnEvil", x, 0, L["MOD_TURN_EVIL_DESC"]);
		if teCB then
			teCB:ClearAllPoints();
			teCB:SetPoint("TOPLEFT", auraBody, "BOTTOMLEFT", 0, -10);
		end

		local teBody = K.UI.Collapsible(pane, x, 0, 440, 34, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("TurnEvil");
		end);
		teBody:ClearAllPoints();
		teBody:SetPoint("TOPLEFT", teDesc or teCB or auraBody, "BOTTOMLEFT",
			teDesc and -26 or 0, -6);
		if teCB then teCB:HookScript("OnClick", function() teBody:Refresh(); end); end

		local teMove = CreateFrame("Button", nil, teBody, "UIPanelButtonTemplate");
		teMove:SetPoint("TOPLEFT", 2, -6);
		teMove:SetSize(150, 22);
		teMove:SetText(L["BTN_MOVE_IT"] or "Move it");
		teMove:SetScript("OnClick", function(self)
			if not K.SetTurnEvilPreview then return; end
			local on = K.SetTurnEvilPreview(not (K.IsTurnEvilPreview and K.IsTurnEvilPreview()));
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local teReset = CreateFrame("Button", nil, teBody, "UIPanelButtonTemplate");
		teReset:SetPoint("LEFT", teMove, "RIGHT", 8, 0);
		teReset:SetSize(100, 22);
		teReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		teReset:SetScript("OnClick", function()
			if K.ResetTurnEvilPosition then K.ResetTurnEvilPosition(); end
		end);

		-- Sacred Shield sobre el objetivo (portado de la WeakAura "SS").
		-- Mismo esquema que Turn Evil: checkbox siempre visible colgando de
		-- "pane", y solo se pliega su propio cuerpo de botones.
		local ssCB, _, ssDesc = ModuleCB(pane, L["MOD_SACREDSHIELD"] or "Sacred Shield (target)",
			"SacredShield", x, 0, L["MOD_SACREDSHIELD_DESC"]);
		if ssCB then
			ssCB:ClearAllPoints();
			ssCB:SetPoint("TOPLEFT", teBody, "BOTTOMLEFT", 0, -10);
		end

		local ssBody = K.UI.Collapsible(pane, x, 0, 440, 34, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("SacredShield");
		end);
		ssBody:ClearAllPoints();
		ssBody:SetPoint("TOPLEFT", ssDesc or ssCB or teBody, "BOTTOMLEFT",
			ssDesc and -26 or 0, -6);
		if ssCB then ssCB:HookScript("OnClick", function() ssBody:Refresh(); end); end

		local ssMove = CreateFrame("Button", nil, ssBody, "UIPanelButtonTemplate");
		ssMove:SetPoint("TOPLEFT", 2, -6);
		ssMove:SetSize(150, 22);
		ssMove:SetText(L["BTN_MOVE_IT"] or "Move it");
		ssMove:SetScript("OnClick", function(self)
			if not K.SetSacredShieldMove then return; end
			local on = K.SetSacredShieldMove(not (K.IsSacredShieldMoving and K.IsSacredShieldMoving()));
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local ssReset = CreateFrame("Button", nil, ssBody, "UIPanelButtonTemplate");
		ssReset:SetPoint("LEFT", ssMove, "RIGHT", 8, 0);
		ssReset:SetSize(100, 22);
		ssReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		ssReset:SetScript("OnClick", function()
			if K.ResetSacredShieldPosition then K.ResetSacredShieldPosition(); end
		end);

		-- Sacred Shield sobre el GRUPO (portado del grupo de WeakAuras
		-- "Sacred Shield Tracker"). Mismo esquema que los de arriba.
		local sstCB, _, sstDesc = ModuleCB(pane, L["MOD_SS_TRACKER"] or "Sacred Shield tracker (group)",
			"SacredShieldTracker", x, 0, L["MOD_SS_TRACKER_DESC"]);
		if sstCB then
			sstCB:ClearAllPoints();
			sstCB:SetPoint("TOPLEFT", ssBody, "BOTTOMLEFT", 0, -10);
		end

		local sstBody = K.UI.Collapsible(pane, x, 0, 440, 34, function()
			return K.IsModuleEnabled and K.IsModuleEnabled("SacredShieldTracker");
		end);
		sstBody:ClearAllPoints();
		sstBody:SetPoint("TOPLEFT", sstDesc or sstCB or ssBody, "BOTTOMLEFT",
			sstDesc and -26 or 0, -6);
		if sstCB then sstCB:HookScript("OnClick", function() sstBody:Refresh(); end); end

		local sstMove = CreateFrame("Button", nil, sstBody, "UIPanelButtonTemplate");
		sstMove:SetPoint("TOPLEFT", 2, -6);
		sstMove:SetSize(150, 22);
		sstMove:SetText(L["BTN_MOVE_IT"] or "Move it");
		sstMove:SetScript("OnClick", function(self)
			if not K.SetSacredShieldTrackerMove then return; end
			local on = K.SetSacredShieldTrackerMove(not (K.IsSacredShieldTrackerMoving and K.IsSacredShieldTrackerMoving()));
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local sstReset = CreateFrame("Button", nil, sstBody, "UIPanelButtonTemplate");
		sstReset:SetPoint("LEFT", sstMove, "RIGHT", 8, 0);
		sstReset:SetSize(100, 22);
		sstReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		sstReset:SetScript("OnClick", function()
			if K.ResetSacredShieldTrackerPosition then K.ResetSacredShieldTrackerPosition(); end
		end);

		-- Aca habia un bloque "Planned" anunciando un aviso de Alas/Burbuja.
		-- Se saco: anunciar algo que no existe solo ocupa lugar.
		-- Alto del bloque de auras: encabezado + Paladin auras (checkbox,
		-- descripcion y cuerpo) + Turn Evil (idem) + Sacred Shield (idem).
		-- Cada uno ocupa su propio lugar, ninguno vive dentro del otro.
		return y - BODY_H - 375;
	end,

	WARRIOR = function(pane, x, y)
		-- El Melee Swing Timer no va aca: lo usan tambien picaro, cazador y
		-- druida, asi que vive en la seccion PvP general.

		return y;
	end,
};

-- ---------------------------------------------------------
-- Nombre de la clase para el item de la lista lateral
-- ---------------------------------------------------------
function K.GetClassSectionName()
	local class = (K.GetPlayerClass and K.GetPlayerClass()) or select(2, UnitClass("player"));
	local localized = UnitClass("player");
	return localized or class or (L["SIDE_CLASSOPT"] or "Class Options"), class;
end

-- ---------------------------------------------------------
-- SECCION "PvP"  (lo que sirve para cualquier clase)
-- ---------------------------------------------------------
function K.BuildPvPSection(pane)
	local prev = nil;

	-- ══════════ HUD DE COMBATE ══════════
	prev = HeaderBlock(pane, nil, L["PVP_HUD"] or "Combat HUD",
		L["PVP_HUD_NOTE"]
		or "Bars that sit next to your character so you do not have to look at the unit frames.");

	-- ── Power Bar ──
	local pbBlk, pbBody = ModuleBlock(pane, prev, "PowerBar",
		L["MOD_POWERBAR"] or "Power Bar", L["MOD_POWERBAR_DESC"]);
	prev = pbBlk;
	do
		local by = 0;
		SettingCB(pbBody, L["CB_POWERBAR_COMBAT"] or "Only show it in combat", "PowerBarCombatOnly",
			22, by, L["TIP_PowerBarCombatOnly"]
			or "Hides the power bar out of combat so it does not clutter the screen.",
			function() if K.UpdatePowerBar then K.UpdatePowerBar(); end end);
		by = by - 26;
		SettingCB(pbBody, L["CB_POWERBAR_PCT"] or "Show percentage instead of current / max",
			"PowerBarShowPercent", 22, by, nil,
			function() if K.UpdatePowerBar then K.UpdatePowerBar(); end end);
		by = by - 26;
		SettingCB(pbBody, L["CB_POWERBAR_HIDETEXT"] or "Hide the numbers on both bars",
			"PowerBarHideText", 22, by, L["TIP_PowerBarHideText"]
			or "Turns the numbers off entirely. The bar alone already tells you how much is left.",
			function() if K.UpdatePowerBar then K.UpdatePowerBar(); end end);
		by = by - 26;
		SettingCB(pbBody, L["CB_POWERBAR_HEALTH"] or "Also show a health bar", "PowerBarShowHealth",
			22, by, L["TIP_PowerBarHealth"]
			or "Adds a health bar above the resource bar, so the Power Bar works like a mini player frame.",
			function() if K.ApplyPowerBarHealth then K.ApplyPowerBarHealth(); end end);
		by = by - 26;
		SettingCB(pbBody, L["CB_POWERBAR_GRADIENT"] or "Health bar changes color as it drops",
			"PowerBarHealthGradient", 22, by, L["TIP_PowerBarGradient"]
			or "The health bar goes green > yellow > red as you lose health.",
			function() if K.UpdatePowerBar then K.UpdatePowerBar(); end end);
		by = by - 26;
		SettingCB(pbBody, L["CB_POWERBAR_CLASSCOLOR"] or "Health bar in your class color",
			"PowerBarHealthClassColor", 22, by, L["TIP_PowerBarClassColor"]
			or "Paints the health bar with your class color instead of green. It wins over the gradient above.",
			function() if K.UpdatePowerBar then K.UpdatePowerBar(); end end);
		by = by - 26;
		SettingCB(pbBody, L["CB_POWERBAR_HIDEFULL"] or "Hide it when full out of combat",
			"PowerBarHideWhenFull", 22, by, L["TIP_PowerBarHideFull"]
			or "Hides the bar while you are at full health and resource outside combat.",
			function() if K.ApplyPowerBarHealth then K.ApplyPowerBarHealth(); end end);
		by = by - 26;
		SettingCB(pbBody, L["CB_POWERBAR_AURAS"] or "Show your buffs and debuffs",
			"PowerBarShowAuras", 22, by, L["TIP_PowerBarAuras"]
			or "Two rows of small icons: buffs on top, debuffs below. Unlike the Blizzard frame it shows all of them, not a chosen few.",
			function() if K.ApplyPowerBarAuraToggle then K.ApplyPowerBarAuraToggle(); end end);

		local function PBSlider(label, sx, sy, minV, maxV, step, getFn, setFn)
			local s = CreateFrame("Slider", nil, pbBody, "OptionsSliderTemplate");
			s:SetPoint("TOPLEFT", sx, sy);
			s:SetWidth(180);
			s:SetMinMaxValues(minV, maxV);
			s:SetValueStep(step);
			K.UI.SliderEnds(s, tostring(minV), tostring(maxV));
			local title = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
			title:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
			title:SetText(label);
			local val = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
			val:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);
			local function Fmt(v) return (step >= 1) and tostring(v) or string.format("%.2f", v); end
			s:SetValue(getFn());
			val:SetText(Fmt(getFn()));
			s._last = getFn();
			s:SetScript("OnValueChanged", function(self, v)
				if step >= 1 then v = math.floor(v + 0.5); end
				if self._last == v then return; end
				self._last = v;
				self:SetValue(v);
				val:SetText(Fmt(v));
				setFn(v);
			end);
			return s;
		end

		by = by - 52;
		PBSlider(L["SLIDER_POWERBAR_SCALE"] or "Scale", 26, by, 0.5, 2.0, 0.05,
			function() return (K.GetPowerBarScale and K.GetPowerBarScale()) or 1; end,
			function(v) if K.SavePowerBarScale then K.SavePowerBarScale(v); end end);
		PBSlider(L["SLIDER_POWERBAR_WIDTH"] or "Width", 260, by, 80, 320, 5,
			function() return (K.GetPowerBarWidth and K.GetPowerBarWidth()) or 160; end,
			function(v) if K.SavePowerBarWidth then K.SavePowerBarWidth(v); end end);
		by = by - 52;
		PBSlider(L["SLIDER_POWERBAR_HEIGHT"] or "Bar height", 26, by, 8, 40, 1,
			function() return (K.GetPowerBarBarHeight and K.GetPowerBarBarHeight()) or 14; end,
			function(v) if K.SavePowerBarBarHeight then K.SavePowerBarBarHeight(v); end end);
		PBSlider(L["SLIDER_POWERBAR_AURASIZE"] or "Aura icon size", 260, by, 10, 32, 1,
			function() return (K.GetPowerBarAuraSize and K.GetPowerBarAuraSize()) or 16; end,
			function(v) if K.SavePowerBarAuraSize then K.SavePowerBarAuraSize(v); end end);
		by = by - 52;
		PBSlider(L["SLIDER_POWERBAR_AURAROW"] or "Auras per row", 26, by, 2, 16, 1,
			function() return (K.GetPowerBarAuraPerRow and K.GetPowerBarAuraPerRow()) or 8; end,
			function(v) if K.SavePowerBarAuraPerRow then K.SavePowerBarAuraPerRow(v); end end);

		-- Donde se cuelgan las dos filas. Botones angostos para que la fila
		-- entera entre al lado de los sliders sin desbordar el cuerpo.
		by = by - 42;
		ChoiceSelector(pbBody, 26, by, L["BTN_AURAPOS_LABEL"] or "Auras:", {
			{ value = "RIGHT",  text = L["AURAPOS_RIGHT"]  or "Right" },
			{ value = "BOTTOM", text = L["AURAPOS_BOTTOM"] or "Below" },
			{ value = "TOP",    text = L["AURAPOS_TOP"]    or "Above" },
		},
			function() return (K.GetPowerBarAuraPos and K.GetPowerBarAuraPos()) or "RIGHT"; end,
			function(v) if K.SetPowerBarAuraPos then K.SetPowerBarAuraPos(v); end end,
			74);

		pbBlk:SetBodyHeight(math.abs(by) + 62);
		pbBlk:Refresh();
	end

	-- ── Melee Swing Timer ──
	local swBlk, swBody = ModuleBlock(pane, prev, "MeleeSwingTimer",
		L["MOD_MELEESWING"] or "Melee Swing Timer", L["MOD_MELEESWING_DESC"]);
	prev = swBlk;
	do
		local swMove = CreateFrame("Button", nil, swBody, "UIPanelButtonTemplate");
		swMove:SetPoint("TOPLEFT", 24, 0);
		swMove:SetSize(150, 22);
		swMove:SetText((K.IsMeleeSwingUnlocked and K.IsMeleeSwingUnlocked())
			and (L["BTN_LOCK_IT"] or "Lock it") or (L["BTN_MOVE_IT"] or "Move it"));
		swMove:SetScript("OnClick", function(self)
			if not K.ToggleMeleeSwingUnlock then return; end
			local on = K.ToggleMeleeSwingUnlock();
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local swReset = CreateFrame("Button", nil, swBody, "UIPanelButtonTemplate");
		swReset:SetPoint("LEFT", swMove, "RIGHT", 8, 0);
		swReset:SetSize(100, 22);
		swReset:SetText(L["BTN_MOVE_RESET"] or "Reset");

		local swScale = CreateFrame("Slider", nil, swBody, "OptionsSliderTemplate");
		swScale:SetPoint("TOPLEFT", 24, -48);
		swScale:SetWidth(200);
		swScale:SetMinMaxValues(0.5, 2.5);
		swScale:SetValueStep(0.05);
		K.UI.SliderEnds(swScale, "0.50", "2.50");
		local swTitle = swScale:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		swTitle:SetPoint("BOTTOMLEFT", swScale, "TOPLEFT", 0, 2);
		swTitle:SetText((K.UI and K.UI.Label(L["SLIDER_SWING_SCALE"] or "Scale"))
			or (L["SLIDER_SWING_SCALE"] or "Scale"));
		local swVal = swScale:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		swVal:SetPoint("BOTTOMRIGHT", swScale, "TOPRIGHT", 0, 2);

		local function RefreshSwingScale()
			local v = (K.GetMeleeSwingScale and K.GetMeleeSwingScale()) or 1.0;
			swScale._last = v;
			swScale:SetValue(v);
			swVal:SetText(string.format("%.2f", v));
		end
		K.RefreshSwingScaleSlider = RefreshSwingScale;
		RefreshSwingScale();

		swScale:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v * 20 + 0.5) / 20;
			if self._last == v then return; end
			self._last = v;
			swVal:SetText(string.format("%.2f", v));
			if K.SaveMeleeSwingScale then K.SaveMeleeSwingScale(v); end
		end);

		swReset:SetScript("OnClick", function()
			if K.ResetMeleeSwingTimerPosition then K.ResetMeleeSwingTimerPosition(); end
			swMove:SetText(L["BTN_MOVE_IT"] or "Move it");
			RefreshSwingScale();
		end);

		-- Cicla entre los tres bordes: tooltip, sin marco (como arena) y
		-- el de la barra de casteo de Blizzard.
		BorderStyleSelector(swBody, 24, -84,
			function() return (K.GetMeleeSwingBorderStyle and K.GetMeleeSwingBorderStyle()) or "Tooltip"; end,
			function(v) if K.SetMeleeSwingBorderStyle then K.SetMeleeSwingBorderStyle(v); end end);

		swBlk:SetBodyHeight(136);
		swBlk:Refresh();
	end

	-- ══════════ ENEMIGOS ══════════
	-- Sin subtitulo: el encabezado ya dice de que va la seccion y cada modulo
	-- trae su propia descripcion abajo.
	prev = HeaderBlock(pane, prev, L["PVP_ENEMY_HEADER"] or "Enemy awareness");

	local eaBlk, eaBody = ModuleBlock(pane, prev, "EnemySpellAlert",
		L["MOD_ENEMYALERT"] or "Enemy Spell Alert",
		L["PVP_ENEMYALERT_NOTE"] or L["MOD_ENEMYALERT_DESC"]);
	prev = eaBlk;
	do
		SettingCB(eaBody, L["CB_LOCK_ENEMYALERT"] or "Lock it in place", "EnemySpellAlertLocked",
			22, 0, L["TIP_EnemyAlertLocked"]
			or "While locked it ignores the mouse: you can click through it.",
			function() if K.ApplyEnemyAlertLock then K.ApplyEnemyAlertLock(); end end);

		local eaShow = CreateFrame("Button", nil, eaBody, "UIPanelButtonTemplate");
		eaShow:SetPoint("TOPLEFT", 24, -32);
		eaShow:SetSize(150, 22);
		eaShow:SetText(L["BTN_SHOW_BARS"] or "Show to position");
		eaShow:SetScript("OnClick", function(self)
			local on = not (K.IsEnemyAlertPreview and K.IsEnemyAlertPreview());
			if K.SetEnemyAlertPreview then K.SetEnemyAlertPreview(on); end
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_SHOW_BARS"] or "Show to position"));
		end);

		local eaReset = CreateFrame("Button", nil, eaBody, "UIPanelButtonTemplate");
		eaReset:SetPoint("LEFT", eaShow, "RIGHT", 8, 0);
		eaReset:SetSize(100, 22);
		eaReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		eaReset:SetScript("OnClick", function()
			if K.ResetEnemyAlertPosition then K.ResetEnemyAlertPosition(); end
		end);

		local eaList = CreateFrame("Button", nil, eaBody, "UIPanelButtonTemplate");
		eaList:SetPoint("LEFT", eaReset, "RIGHT", 8, 0);
		eaList:SetSize(110, 22);
		eaList:SetText(L["BTN_SPELL_LIST"] or "Spell list");
		eaList:SetScript("OnClick", function()
			if K.OpenEnemyAlertMenu then K.OpenEnemyAlertMenu(); end
		end);

		-- Donde mostrarse (mismo esquema que el Gargoyle)
		local eaWhere = eaBody:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		eaWhere:SetPoint("TOPLEFT", 24, -62);
		eaWhere:SetText((K.UI and K.UI.Label(L["GARG_WHERE"] or "Show it in:"))
			or (L["GARG_WHERE"] or "Show it in:"));

		local eaZones = {
			{ key = "inArena", text = L["GARG_ARENA"] or "Arena",         x = 26,  y = -80 },
			{ key = "inBG",    text = L["GARG_BG"]    or "Battlegrounds", x = 150, y = -80 },
			{ key = "inDuel",  text = L["GARG_DUEL"]  or "Duels",         x = 300, y = -80 },
			{ key = "inWorld", text = L["GARG_WORLD"] or "Open world",    x = 26,  y = -106 },
		};
		for _, z in ipairs(eaZones) do
			checkboxCount = checkboxCount + 1;
			local cbName = "NidhausEAZoneCB" .. checkboxCount;
			local cb = CreateFrame("CheckButton", cbName, eaBody, "InterfaceOptionsCheckButtonTemplate");
			cb:SetPoint("TOPLEFT", z.x, z.y);
			cb:SetHitRectInsets(0, 0, 0, 0);
			local fs = _G[cbName .. "Text"];
			if fs then fs:SetText(z.text); end
			cb:SetChecked(K.GetEnemyAlertZone and K.GetEnemyAlertZone(z.key));
			cb:SetScript("OnClick", function(self)
				local v = (self:GetChecked() == 1 or self:GetChecked() == true);
				if K.SetEnemyAlertZone then K.SetEnemyAlertZone(z.key, v); end
			end);
		end

		-- Escala del icono. Usa el slider comun del addon, que ya guarda y
		-- aplica solo a traves de ScaleAPI.
		if K.UI and K.UI.ScaleSlider then
			K.UI.ScaleSlider(eaBody, "EnemySpellAlert", 26, -142, 200,
				L["SLIDER_SCALE"] or "Scale");
		end

		eaBlk:SetBodyHeight(180);
		eaBlk:Refresh();
	end

	-- ── Seduccion sobre ti (portado de WeakAuras) ──
	local sdBlk, sdBody = ModuleBlock(pane, prev, "SeductionAlert",
		L["MOD_SEDUCTION"] or "Seduction on you (arena)", L["MOD_SEDUCTION_DESC"]);
	prev = sdBlk;
	do
		local sdMove = CreateFrame("Button", nil, sdBody, "UIPanelButtonTemplate");
		sdMove:SetPoint("TOPLEFT", 24, -4);
		sdMove:SetSize(150, 22);
		sdMove:SetText(L["BTN_MOVE_IT"] or "Move it");
		sdMove:SetScript("OnClick", function(self)
			if not K.SetSeductionAlertMove then return; end
			local on = K.SetSeductionAlertMove(not (K.IsSeductionAlertMoving and K.IsSeductionAlertMoving()));
			self:SetText(on and (L["BTN_LOCK_IT"] or "Lock it")
				or (L["BTN_MOVE_IT"] or "Move it"));
		end);

		local sdReset = CreateFrame("Button", nil, sdBody, "UIPanelButtonTemplate");
		sdReset:SetPoint("LEFT", sdMove, "RIGHT", 8, 0);
		sdReset:SetSize(100, 22);
		sdReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		sdReset:SetScript("OnClick", function()
			if K.ResetSeductionAlertPosition then K.ResetSeductionAlertPosition(); end
		end);

		if K.UI and K.UI.ScaleSlider then
			K.UI.ScaleSlider(sdBody, "SeductionAlert", 26, -40, 200,
				L["SLIDER_SCALE"] or "Scale");
		end

		sdBlk:SetBodyHeight(80);
		sdBlk:Refresh();
	end

	-- ── Gargoyle Tracker ──
	local gtBlk, gtBody = ModuleBlock(pane, prev, "GargoyleTracker",
		L["MOD_GARGOYLE"] or "Gargoyle Tracker", L["MOD_GARGOYLE_DESC"]);
	prev = gtBlk;
	do
		-- Estilo: Blizzard / Custom
		local styleLbl = gtBody:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		styleLbl:SetPoint("TOPLEFT", 24, -4);
		styleLbl:SetText((K.UI and K.UI.Label(L["GARG_MODE"] or "Style"))
			or (L["GARG_MODE"] or "Style"));

		local styleBtns = {};
		local function RefreshStyle()
			local cur = (K.GetGargoyleMode and K.GetGargoyleMode()) or "blizzard";
			for _, b in ipairs(styleBtns) do
				if b.value == cur then
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

		local modes = {
			{ value = "blizzard", text = L["GARG_MODE_BLIZZ"]  or "Blizzard" },
			{ value = "custom",   text = L["GARG_MODE_CUSTOM"] or "Custom" },
		};
		for i, m in ipairs(modes) do
			local b = CreateFrame("Button", nil, gtBody);
			b:SetSize(84, 22);
			b:SetPoint("TOPLEFT", 90 + (i - 1) * 90, -2);
			b:SetBackdrop({
				bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 12,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
			});
			b.value = m.value;
			b.labelFS = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
			b.labelFS:SetPoint("CENTER");
			b.labelFS:SetText(m.text);
			b:SetScript("OnClick", function(self)
				if K.SetGargoyleMode then K.SetGargoyleMode(self.value); end
				RefreshStyle();
			end);
			table.insert(styleBtns, b);
		end
		RefreshStyle();

		-- Donde mostrarse
		local whereLbl = gtBody:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		whereLbl:SetPoint("TOPLEFT", 24, -34);
		whereLbl:SetText((K.UI and K.UI.Label(L["GARG_WHERE"] or "Show it in:"))
			or (L["GARG_WHERE"] or "Show it in:"));

		local zones = {
			{ key = "inArena", text = L["GARG_ARENA"] or "Arena",         x = 26,  y = -52 },
			{ key = "inBG",    text = L["GARG_BG"]    or "Battlegrounds", x = 150, y = -52 },
			{ key = "inDuel",  text = L["GARG_DUEL"]  or "Duels",         x = 300, y = -52 },
			{ key = "inWorld", text = L["GARG_WORLD"] or "Open world",    x = 26,  y = -78 },
		};
		for _, z in ipairs(zones) do
			checkboxCount = checkboxCount + 1;
			local cbName = "NidhausGargCB" .. checkboxCount;
			local cb = CreateFrame("CheckButton", cbName, gtBody, "InterfaceOptionsCheckButtonTemplate");
			cb:SetPoint("TOPLEFT", z.x, z.y);
			cb:SetHitRectInsets(0, 0, 0, 0);
			local fs = _G[cbName .. "Text"];
			if fs then fs:SetText(z.text); end
			cb:SetChecked(K.GetGargoyleZoneOption and K.GetGargoyleZoneOption(z.key));
			cb:SetScript("OnClick", function(self)
				local v = (self:GetChecked() == 1 or self:GetChecked() == true);
				if K.SetGargoyleZoneOption then K.SetGargoyleZoneOption(z.key, v); end
			end);
		end

		-- Modo test + reset de posicion
		local gtTest = CreateFrame("Button", nil, gtBody, "UIPanelButtonTemplate");
		gtTest:SetPoint("TOPLEFT", 26, -106);
		gtTest:SetSize(150, 22);
		gtTest:SetText(L["BTN_TEST_MODE"] or "Test mode");
		gtTest:SetScript("OnClick", function(self)
			if not K.ToggleGargoyleTest then return; end
			local on = K.ToggleGargoyleTest();
			self:SetText(on and (L["BTN_HIDE_BARS"] or "Hide")
				or (L["BTN_TEST_MODE"] or "Test mode"));
		end);

		local gtReset = CreateFrame("Button", nil, gtBody, "UIPanelButtonTemplate");
		gtReset:SetPoint("LEFT", gtTest, "RIGHT", 8, 0);
		gtReset:SetSize(100, 22);
		gtReset:SetText(L["BTN_MOVE_RESET"] or "Reset");
		gtReset:SetScript("OnClick", function()
			if K.ResetGargoylePosition then K.ResetGargoylePosition(); end
		end);

		-- Escala (registro central)
		if K.UI and K.UI.ScaleSlider then
			K.UI.ScaleSlider(gtBody, "GargoyleTracker", 26, -140, 200);
		end

		gtBlk:SetBodyHeight(180);
		gtBlk:Refresh();
	end

	-- Aca habia dos bloques "Planned" anunciando cosas que no existen
	-- (avisos de dispel, resurreccion, control de masas, DR, buffs). Se
	-- sacaron junto con los de cada clase: anunciar lo que no esta hecho
	-- solo ocupa lugar y hace parecer que falta algo.

	-- Alto para el scroll. Se devuelve un valor generoso y fijo: los bloques
	-- cambian de alto al desplegarse, y recalcularlo en vivo daria un scroll
	-- que salta. Con este alto entra todo aunque esten todos desplegados.
	return -1000;
end

-- ---------------------------------------------------------
-- SECCION de la CLASE detectada
-- ---------------------------------------------------------
function K.BuildClassSection(pane)
	local x = 16;
	local y = -14;

	local class = (K.GetPlayerClass and K.GetPlayerClass()) or select(2, UnitClass("player"));
	local className = UnitClass("player") or class or "?";
	local color = CLASS_COLORS[class] or "|cffFFFFFF";

	-- Cartel de clase detectada
	local banner = CreateFrame("Frame", nil, pane);
	banner:SetPoint("TOPLEFT", x - 4, y);
	banner:SetSize(440, 40);
	banner:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile     = true, tileSize = 16, edgeSize = 12,
		insets   = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	banner:SetBackdropColor(0.07, 0.06, 0.04, 0.85);
	banner:SetBackdropBorderColor(0.35, 0.32, 0.24, 0.8);

	local bannerText = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	bannerText:SetPoint("TOPLEFT", banner, "TOPLEFT", 12, -8);
	bannerText:SetText((L["PVP_DETECTED"] or "Detected class:") .. " " .. color .. className .. "|r");

	local bannerSub = banner:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
	bannerSub:SetPoint("TOPLEFT", bannerText, "BOTTOMLEFT", 0, -2);
	bannerSub:SetText(L["PVP_DETECTED_SUB"]
		or "Only the modules your class can actually use are shown here.");

	y = y - 54;

	local builder = CLASS_MODULES[class];
	if builder then
		y = builder(pane, x, y);
	else
		Note(pane, L["PVP_NO_CLASS_MODULES"]
			or "There are no class specific modules for this class yet. The list grows as they get added.",
			x + 2, y, 430);
		y = y - 60;
	end

	return y;
end
