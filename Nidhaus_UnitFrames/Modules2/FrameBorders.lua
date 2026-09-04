local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- FrameBorders.lua
--
-- El borde de el UI de origen (MIT, (c) el UI de origen) alrededor de las barras de
-- accion, el micromenu, las bolsas, los marcos, la barra de casteo y las
-- auras, con sombra exterior opcional.
--
-- POR QUE NO SE COPIA SU CODIGO.
--
-- La version de el UI de origen que sirvio de referencia es de retail: usa
-- Mixin, SetColorTexture, SetShown y BackdropTemplate, y ninguno de los
-- cuatro existe en 3.3.5a. Pero no hace ninguna falta. Su Border.tga mide
-- 256x32, o sea OCHO casillas de 32x32 en el mismo orden que espera el
-- edgeFile de SetBackdrop: izquierda, derecha, arriba, abajo y las cuatro
-- esquinas. Se usa el arte tal cual y el backdrop nativo hace la division
-- solo, con dos lineas en vez de doscientas.
--
-- La unica diferencia con el original es que el backdrop ESTIRA los lados
-- y ellos los repiten. En un filo de uno o dos pixeles no se distingue.
--
-- CONVIVE CON LORTI UI, no compite. Lorti no dibuja bordes: tinta las
-- texturas de Blizzard para oscurecerlas. Esto no toca esas texturas:
-- agrega un marco propio por encima. Son dos capas distintas y juntas
-- quedan bien, arte oscurecido con filo nitido.
--
-- EL MINIMAPA NO ESTA ACA. Ya elige su borde en su propio desplegable, que
-- justamente trae la version Light de esta misma UI. Un solo dueño por
-- marco.
-- =========================================================

local ART = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\Border\\";

-- El grosor sale del propio el UI de origen (Core/Border.lua, onSizeChanged):
-- 12 para el estilo normal, 10 para el pixel.
local STYLES = {
	el UI de origen = { file = ART .. "Border_el UI de origen", edge = 12 },
	Pixel  = { file = ART .. "Border_Pixel",  edge = 10 },
};

local GLOW_FILE, GLOW_EDGE = ART .. "Border_Glow", 3;

local function Style()
	return STYLES[C.FrameBordersStyle] or STYLES.el UI de origen;
end

-- ---------------------------------------------------------
-- Listas de objetivos
--
-- Se guardan por NOMBRE y se resuelven al aplicar: muchos de estos marcos
-- los crea Blizzard tarde, o directamente no existen (la barra de mascota
-- sin mascota), asi que resolverlos al cargar dejaria medias listas.
-- ---------------------------------------------------------
local function Series(prefix, n, suffix)
	local t = {};
	for i = 1, n do t[#t + 1] = prefix .. i .. (suffix or ""); end
	return t;
end

local function Join(...)
	local out = {};
	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do out[#out + 1] = v; end
	end
	return out;
end

local GROUPS = {
	{
		key = "FrameBorders_ActionBars",
		label = "Action Bars",
		names = Join(
			Series("ActionButton", 12),
			Series("MultiBarBottomLeftButton", 12),
			Series("MultiBarBottomRightButton", 12),
			Series("MultiBarRightButton", 12),
			Series("MultiBarLeftButton", 12),
			Series("BonusActionButton", 12),
			Series("ShapeshiftButton", 10),
			Series("PetActionButton", 10)
		),
	},
	{
		key = "FrameBorders_MicroMenu",
		label = "Micro Menu",
		names = {
			"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
			"QuestLogMicroButton", "SocialsMicroButton", "AchievementMicroButton",
			"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
		},
	},
	{
		key = "FrameBorders_Bags",
		label = "Bags",
		names = Join(
			{ "MainMenuBarBackpackButton", "KeyRingButton" },
			Series("CharacterBag", 4, "Slot")   -- CharacterBag0Slot..3Slot, ver el ajuste abajo
		),
	},
	{
		key = "FrameBorders_UnitFrames",
		label = "Unit Frames",
		-- Las BARRAS y no los marcos: el marco del jugador es un grifo
		-- dorado con forma propia, y un rectangulo alrededor queda ridiculo.
		names = Join(
			{ "PlayerFrameHealthBar", "PlayerFrameManaBar",
			  "TargetFrameHealthBar", "TargetFrameManaBar",
			  "FocusFrameHealthBar",  "FocusFrameManaBar",
			  "PetFrameHealthBar",    "PetFrameManaBar" },
			Series("PartyMemberFrame", 4, "HealthBar"),
			Series("PartyMemberFrame", 4, "ManaBar")
		),
	},
	{
		key = "FrameBorders_CastBar",
		label = "Cast Bar",
		names = { "CastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar" },
	},
	{
		key = "FrameBorders_Auras",
		label = "Auras",
		names = Join(
			Series("BuffButton", 32),
			Series("DebuffButton", 16),
			Series("TempEnchant", 3)
		),
	},
};

-- CharacterBag va de 0 a 3, no de 1 a 4.
for _, g in ipairs(GROUPS) do
	if g.key == "FrameBorders_Bags" then
		g.names = { "MainMenuBarBackpackButton", "KeyRingButton",
			"CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot" };
	end
end

-- ---------------------------------------------------------
-- Pintado
-- ---------------------------------------------------------
local decorated = {};   -- [frame] = { border = , shadow = }

local function Ensure(frame)
	local d = decorated[frame];
	if d then return d; end

	local parent = frame:GetParent() or UIParent;
	local lvl = frame:GetFrameLevel() or 1;

	d = {};

	-- El borde cuelga del marco, un nivel por encima, para quedar sobre su
	-- arte y no debajo del icono.
	d.border = CreateFrame("Frame", nil, frame);
	d.border:SetFrameLevel(lvl + 1);
	d.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1);
	d.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1);
	d.border:Hide();

	-- La sombra cuelga del PADRE y no del marco, un nivel por DEBAJO. Si
	-- colgara del marco quedaria por encima de el y en vez de un halo se
	-- veria un recuadro sucio tapando el icono.
	d.shadow = CreateFrame("Frame", nil, parent);
	d.shadow:SetFrameLevel(lvl > 0 and lvl - 1 or 0);
	d.shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3);
	d.shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3);
	d.shadow:SetBackdrop({ edgeFile = GLOW_FILE, edgeSize = GLOW_EDGE });
	d.shadow:SetBackdropBorderColor(0, 0, 0, 0.8);
	d.shadow:Hide();

	decorated[frame] = d;
	return d;
end

local enabled = false;

local function ApplyToName(name, want)
	local frame = _G[name];
	if not frame or not frame.GetFrameLevel then return; end

	if not want then
		local d = decorated[frame];
		if d then d.border:Hide(); d.shadow:Hide(); end
		return;
	end

	local d = Ensure(frame);
	local st = Style();
	d.border:SetBackdrop({ edgeFile = st.file, edgeSize = st.edge });
	d.border:SetBackdropBorderColor(1, 1, 1, 1);
	d.border:Show();
	if C.FrameBordersShadow then d.shadow:Show(); else d.shadow:Hide(); end
end

function K.ApplyFrameBorders()
	for _, g in ipairs(GROUPS) do
		-- Una sub-opcion sin tocar cuenta como prendida, igual que en Lorti.
		local want = enabled and (C[g.key] ~= false);
		for _, name in ipairs(g.names) do
			ApplyToName(name, want);
		end
	end
end

-- Blizzard crea la barra de mascota, la de posturas y los botones de aura
-- tarde y a veces recien al usarlos, asi que se vuelve a pasar unas veces.
local retry = CreateFrame("Frame");
local retryAcc, retryCount = 0, 0;
retry:Hide();
retry:SetScript("OnUpdate", function(self, elapsed)
	retryAcc = retryAcc + elapsed;
	if retryAcc < 1 then return; end
	retryAcc = 0;
	retryCount = retryCount + 1;
	K.ApplyFrameBorders();
	if retryCount >= 6 then self:Hide(); end
end);

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function()
	if not enabled then return; end
	K.ApplyFrameBorders();
	retryAcc, retryCount = 0, 0;
	retry:Show();
end);

-- ---------------------------------------------------------
-- Sub-opciones en la pestaña Modules, con la misma forma que Lorti
-- ---------------------------------------------------------
local function CreateKkSubUI(container, yOffset, parentCheckbox)
	local wrapper = CreateFrame("Frame", nil, container);
	wrapper:SetPoint("TOPLEFT", 0, yOffset);
	wrapper:SetWidth(container:GetWidth() or 540);

	local localY = 0;

	local sep = wrapper:CreateTexture(nil, "ARTWORK");
	sep:SetHeight(1);
	sep:SetPoint("TOPLEFT", 36, localY + 4);
	sep:SetPoint("TOPRIGHT", -10, localY + 4);
	sep:SetTexture(1, 1, 1, 0.07);
	localY = localY - 6;

	local header = wrapper:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	header:SetPoint("TOPLEFT", 46, localY);
	header:SetText("|cff888888" .. (L["THINBORDER_STYLE"] or "Border art:") .. "|r");
	localY = localY - 20;

	-- Selector de estilo: dos casillas excluyentes, no un desplegable.
	local styleBoxes = {};
	local function RefreshStyles()
		local cur = C.FrameBordersStyle or "el UI de origen";
		for _, b in ipairs(styleBoxes) do b:SetChecked(b.value == cur); end
	end
	local function StyleCB(label, value, x)
		local nm = "NidhausKkStyleCB_" .. value;
		local cb = CreateFrame("CheckButton", nm, wrapper, "InterfaceOptionsCheckButtonTemplate");
		cb:SetPoint("TOPLEFT", x, localY);
		cb:SetHitRectInsets(0, -80, 0, 0);
		cb:SetScale(0.9);
		local lbl = _G[nm .. "Text"];
		if lbl then lbl:SetText(label); lbl:SetFontObject("GameFontHighlight"); end
		cb.value = value;
		cb:SetScript("OnClick", function(self)
			K.SaveConfig("FrameBordersStyle", self.value);
			C.FrameBordersStyle = self.value;
			RefreshStyles();
			K.ApplyFrameBorders();
		end);
		styleBoxes[#styleBoxes + 1] = cb;
	end
	StyleCB("el UI de origen", "el UI de origen", 46);
	StyleCB("Pixel",  "Pixel",  176);
	RefreshStyles();
	localY = localY - 24;

	local subOptions = {
		{ key = "FrameBordersShadow", label = "Outer shadow",
		  tip = "A soft dark halo just outside each frame. It is the glow the original UI draws." },
	};
	for _, g in ipairs(GROUPS) do
		subOptions[#subOptions + 1] = { key = g.key, label = g.label };
	end

	for _, opt in ipairs(subOptions) do
		local cbName = "NidhausKkSubCB_" .. opt.key;
		local cb = CreateFrame("CheckButton", cbName, wrapper, "InterfaceOptionsCheckButtonTemplate");
		cb:SetPoint("TOPLEFT", 46, localY);
		cb:SetHitRectInsets(0, -260, 0, 0);
		cb:SetScale(0.9);

		local lbl = _G[cbName .. "Text"];
		if lbl then lbl:SetText(opt.label); lbl:SetFontObject("GameFontHighlight"); end

		if C[opt.key] == nil then
			C[opt.key] = true;
			if NidhausUnitFramesDB then NidhausUnitFramesDB[opt.key] = true; end
		end
		cb:SetChecked(C[opt.key] ~= false);

		if opt.tip then
			cb:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(opt.label, 1, 1, 1);
				GameTooltip:AddLine(opt.tip, nil, nil, nil, true);
				GameTooltip:Show();
			end);
			cb:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		end

		cb:SetScript("OnClick", function(self)
			local checked = self:GetChecked() == 1 or self:GetChecked() == true;
			K.SaveConfig(opt.key, checked);
			C[opt.key] = checked;
			K.ApplyFrameBorders();
		end);

		localY = localY - 22;
	end

	localY = localY - 8;
	local subUIHeight = math.abs(localY);
	wrapper:SetHeight(subUIHeight);

	local function SetSubsVisible(show)
		if show then wrapper:Show() else wrapper:Hide() end
		local ct = K._moduleContainers and K._moduleContainers["FrameBorders"];
		if ct then
			ct:SetHeight(show and (ct._baseHeight + subUIHeight) or ct._baseHeight);
			if K.UpdateModulesScrollHeight then K.UpdateModulesScrollHeight() end
		end
	end

	if parentCheckbox then
		local origClick = parentCheckbox:GetScript("OnClick");
		parentCheckbox:SetScript("OnClick", function(self)
			if origClick then origClick(self) end
			SetSubsVisible(self:GetChecked() == 1 or self:GetChecked() == true);
		end);
	end

	if K.IsModuleEnabled("FrameBorders") then wrapper:Show() else wrapper:Hide() end
	return subUIHeight;
end

-- ---------------------------------------------------------
-- Registro
-- ---------------------------------------------------------
K.RegisterModule("FrameBorders", {
	name    = L["MOD_THINBORDER"] or "el UI de origen Border",
	desc    = L["MOD_THINBORDER_DESC"]
		or "Thin border and outer shadow around bars, micro menu, bags, frames and auras. Art from el UI de origen (MIT). Stacks with Lorti UI: Lorti tints, this outlines.",
	default = false,
	createUI = CreateKkSubUI,
	onEnable = function()
		enabled = true;
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
		events:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
		events:RegisterEvent("UNIT_PET");
		K.ApplyFrameBorders();
		retryAcc, retryCount = 0, 0;
		retry:Show();
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		retry:Hide();
		K.ApplyFrameBorders();   -- con enabled en false, esto los apaga a todos
	end,
});
