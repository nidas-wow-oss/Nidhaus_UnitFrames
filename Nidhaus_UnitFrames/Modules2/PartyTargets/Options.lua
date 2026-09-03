local AddOnName, ns = ...;
local K = ns[1];
local L = ns[3];   -- tabla de traducciones

----------------------------------------------------
-- PartyTargets - Options Panel
-- /ptarget to open
-- All checkboxes apply in real-time
----------------------------------------------------

local function CreateOptionsPanel()
	local f = CreateFrame("Frame", "PartyTargetsOptions", UIParent)
	-- Cajita con el valor debajo de cada slider (UIKit).
	if K and K.UI and K.UI.AutoRestyle then K.UI.AutoRestyle(f); end
	-- Mas ancha y mas alta que antes (240x240): el contenido entraba justo,
	-- las filas se tocaban y el slider no tenia lugar para su cajita.
	f:SetWidth(300)
	f:SetHeight(336)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
	-- Por ENCIMA del panel principal de NUF.
	--
	-- Los dos estaban en "DIALOG", asi que quien quedaba arriba lo decidia
	-- el nivel de frame, y el panel — que es mas grande y se dibuja despues
	-- — tapaba esta ventana. Se abria desde ahi y no se veia.
	--
	-- FULLSCREEN_DIALOG esta una capa mas arriba, y SetToplevel hace que se
	-- eleve sobre sus hermanas al hacerle click.
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:Hide()

	-- FONDO SOLIDO.
	--
	-- Antes usaba UI-DialogBox-Background, que es la textura de pergamino de
	-- Blizzard — y esa textura YA trae transparencia. Ponerle alfa 0.85
	-- encima no la tapaba: se seguia viendo el panel de atras a traves, y
	-- con el panel principal abierto justo detras, sus botones se colaban
	-- entre el texto y no se leia nada.
	--
	-- WHITE8x8 es un pixel blanco liso: teñido de gris muy oscuro y con
	-- alfa 1 queda opaco de verdad. El borde de dialogo se conserva porque
	-- ese si se ve bien.
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = false, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	})
	f:SetBackdropColor(0.05, 0.06, 0.09, 1)

	-- Title
	local title = f:CreateTexture(nil, "ARTWORK")
	title:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	title:SetWidth(200)
	title:SetHeight(44)
	title:SetPoint("TOP", 0, 10)

	local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleText:SetPoint("TOP", 0, 2)
	titleText:SetText(L["PT_TITLE"] or "Party Targets")

	local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", -4, -4)

	-- Helper to check a CheckButton state (3.3.5 compat)
	local function IsChecked(cb)
		local v = cb:GetChecked()
		return v == 1 or v == true
	end

	-- ========================
	-- Estilo del marco
	--
	-- Va primero porque define la FORMA: no tiene sentido acomodar escala
	-- y anclado y despues cambiar el marco entero.
	-- ========================
	local styleLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	styleLbl:SetPoint("TOPLEFT", 18, -40)
	styleLbl:SetText(L["PT_STYLE"] or "Frame style:")

	local styleDD = CreateFrame("Frame", "PTOptionsStyleDD", f, "UIDropDownMenuTemplate")
	styleDD:SetPoint("TOPLEFT", styleLbl, "TOPRIGHT", -8, 6)
	UIDropDownMenu_SetWidth(styleDD, 120)

	local STYLES = {
		{ value = "Classic", text = L["PT_STYLE_CLASSIC"] or "Classic (wide)" },
		{ value = "Square",  text = L["PT_STYLE_SQUARE"]  or "Square (compact)" },
	}

	local function StyleText(v)
		for _, o in ipairs(STYLES) do
			if o.value == v then return o.text end
		end
		return STYLES[1].text
	end

	UIDropDownMenu_Initialize(styleDD, function()
		for _, o in ipairs(STYLES) do
			local info = UIDropDownMenu_CreateInfo()
			info.text  = o.text
			info.value = o.value
			info.func  = function(btn)
				UIDropDownMenu_SetSelectedValue(styleDD, btn.value)
				UIDropDownMenu_SetText(styleDD, StyleText(btn.value))
				if K and K.SetPartyTargetStyle then K.SetPartyTargetStyle(btn.value) end
			end
			info.checked = (o.value == (K and K.GetPartyTargetStyle and K.GetPartyTargetStyle() or "Classic"))
			UIDropDownMenu_AddButton(info)
		end
	end)

	do
		local cur = (K and K.GetPartyTargetStyle and K.GetPartyTargetStyle()) or "Classic"
		UIDropDownMenu_SetSelectedValue(styleDD, cur)
		UIDropDownMenu_SetText(styleDD, StyleText(cur))
	end

	-- ========================
	-- Mirror Checkbox (real-time)
	-- ========================
	local mirrorCB = CreateFrame("CheckButton", "PTOptionsMirror", f, "UICheckButtonTemplate")
	mirrorCB:SetPoint("TOPLEFT", 16, -74)
	mirrorCB:SetWidth(24)
	mirrorCB:SetHeight(24)
	_G[mirrorCB:GetName().."Text"]:SetText(L["PT_MIRROR"] or "Mirror Party Frames")
	_G[mirrorCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	mirrorCB:SetScript("OnClick", function(self)
		PartyTargetsDB.mirror = IsChecked(self)
		if PartyTargets_ApplyMirrorSetting then
			PartyTargets_ApplyMirrorSetting()
		end
	end)

	-- ========================
	-- Anchor Checkbox (real-time)
	-- ========================
	local anchorCB = CreateFrame("CheckButton", "PTOptionsAnchor", f, "UICheckButtonTemplate")
	anchorCB:SetPoint("TOPLEFT", 16, -102)
	anchorCB:SetWidth(24)
	anchorCB:SetHeight(24)
	_G[anchorCB:GetName().."Text"]:SetText(L["PT_ANCHOR"] or "Anchor to Party Frames")
	_G[anchorCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	anchorCB:SetScript("OnClick", function(self)
		PartyTargetsDB.anchor = IsChecked(self)
		if PartyTargets_ApplyAnchorSetting then
			PartyTargets_ApplyAnchorSetting()
		end
	end)

	local anchorHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	anchorHint:SetPoint("TOPLEFT", 44, -122)
	anchorHint:SetText(L["PT_ANCHOR_HINT"] or "ON: drag one moves all | OFF: move each")

	-- ========================
	-- Lock Checkbox (real-time)
	-- ========================
	local lockCB = CreateFrame("CheckButton", "PTOptionsLock", f, "UICheckButtonTemplate")
	lockCB:SetPoint("TOPLEFT", 16, -142)
	lockCB:SetWidth(24)
	lockCB:SetHeight(24)
	_G[lockCB:GetName().."Text"]:SetText(L["PT_LOCK"] or "Lock Frames")
	_G[lockCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	lockCB:SetScript("OnClick", function(self)
		PartyTargetsDB.locked = IsChecked(self)
	end)

	local lockHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	lockHint:SetPoint("TOPLEFT", 44, -162)
	lockHint:SetText(L["PT_LOCK_HINT"] or "Shift+Alt+drag always overrides lock")

	-- ========================
	-- Ocultar el nombre
	-- ========================
	local nameCB = CreateFrame("CheckButton", "PTOptionsHideName", f, "UICheckButtonTemplate")
	nameCB:SetPoint("TOPLEFT", 16, -182)
	nameCB:SetWidth(24)
	nameCB:SetHeight(24)
	_G[nameCB:GetName().."Text"]:SetText(L["PT_HIDE_NAME"] or "Hide target name")
	_G[nameCB:GetName().."Text"]:SetFontObject("GameFontNormalSmall")
	nameCB:SetChecked(PartyTargetsDB.hideName and true or false)
	nameCB:SetScript("OnClick", function(self)
		PartyTargetsDB.hideName = IsChecked(self)
		if PartyTargets_ApplyNameVisibility then
			PartyTargets_ApplyNameVisibility()
		end
	end)

	-- ========================
	-- Scale Slider (live preview)
	-- ========================
	local sliderLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sliderLabel:SetPoint("TOPLEFT", 18, -216)
	sliderLabel:SetText((K and K.UI and K.UI.Label(L["PT_SCALE"] or "Scale:"))
		or (L["PT_SCALE"] or "Scale:"))

	local slider = CreateFrame("Slider", "PTOptionsScale", f, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", 22, -236)
	slider:SetWidth(250)
	slider:SetHeight(16)
	slider:SetMinMaxValues(0.5, 2.0)
	slider:SetValueStep(0.05)
	_G[slider:GetName().."Low"]:SetText("0.5")
	_G[slider:GetName().."High"]:SetText("2.0")
	_G[slider:GetName().."Text"]:SetText("")

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value * 20 + 0.5) / 20
		-- Se guarda en el estilo activo, no en un unico numero compartido.
		if K and K.SavePartyTargetScale then K.SavePartyTargetScale(value) end
		for i = 1, MAX_PARTY_MEMBERS do
			local frame = _G["PartyTargetFrame"..i]
			if frame then frame:SetScale(value) end
		end
	end)

	-- Lo llama SetPartyTargetStyle al cambiar de estilo, para que el slider
	-- salte a la escala guardada del estilo nuevo.
	function K.RefreshPartyTargetScaleSlider()
		if not f:IsShown() then return end
		slider:SetValue((K.GetPartyTargetScale and K.GetPartyTargetScale()) or 1.0)
	end

	-- La cajita con el valor. DESPUES del SetScript de arriba, no antes.
	--
	-- Aca me equivoque una vez y vale dejarlo escrito: AttachSliderValue se
	-- engancha con HookScript("OnValueChanged"). Si el slider todavia no
	-- tiene script, HookScript lo instala COMO script — y el SetScript que
	-- viene despues lo pisa y se lleva el enganche puesto. Resultado: la
	-- caja aparecia pero el numero no se movia al arrastrar.
	--
	-- Llamandola despues, HookScript encuentra el script del panel ya puesto
	-- y se encadena detras de el, que es como tiene que ser.
	--
	-- Va a mano y no via AutoRestyle porque ese recorre el frame en el OnShow
	-- y aca no llegaba a ver este slider.
	if K and K.UI and K.UI.AttachSliderValue then
		K.UI.AttachSliderValue(slider);
	end

	-- ========================
	-- Save Button
	-- ========================
	local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	saveBtn:SetWidth(110)
	saveBtn:SetHeight(22)
	saveBtn:SetPoint("BOTTOMLEFT", 22, 16)
	saveBtn:SetText(L["BTN_SAVE"] or "Save")
	saveBtn:SetScript("OnClick", function()
		-- Values already saved in real-time, just confirm and close
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PartyTargets:|r Settings saved!")
		f:Hide()
	end)

	-- ========================
	-- Reset Button
	-- ========================
	local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	resetBtn:SetWidth(110)
	resetBtn:SetHeight(22)
	resetBtn:SetPoint("BOTTOMRIGHT", -22, 16)
	resetBtn:SetText(L["BTN_RESET_SHORT"] or "Reset")
	resetBtn:SetScript("OnClick", function()
		StaticPopup_Show("PARTYTARGETS_RESET_CONFIRM")
	end)

	StaticPopupDialogs["PARTYTARGETS_RESET_CONFIRM"] = {
		text = "Reset all PartyTargets settings to defaults?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			PartyTargetsDB = {}
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	-- ========================
	-- OnShow: enable config drag, load values
	-- ========================
	f:SetScript("OnShow", function(self)
		PartyTargets_configOpen = true

		mirrorCB:SetChecked(PartyTargetsDB.mirror and true or false)
		anchorCB:SetChecked(PartyTargetsDB.anchor and true or false)
		lockCB:SetChecked(PartyTargetsDB.locked and true or false)
		slider:SetValue((K and K.GetPartyTargetScale and K.GetPartyTargetScale()) or 1.0)
		-- La cajita del valor la sincroniza UIKit desde el OnValueChanged
		-- del propio slider, no hay que repintarla a mano.

		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PartyTargets:|r Config open - drag target frames to reposition.")
	end)

	-- ========================
	-- OnHide: disable config drag
	-- ========================
	f:SetScript("OnHide", function(self)
		PartyTargets_configOpen = false
	end)

	tinsert(UISpecialFrames, "PartyTargetsOptions")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
	CreateOptionsPanel()
	self:UnregisterAllEvents()
end)