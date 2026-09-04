local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- FrameBorders.lua
--
-- Borde fino de esquina redonda y sombra exterior alrededor de las barras
-- de accion, el micromenu, las bolsas, la barra de casteo y las auras.
--
-- Los marcos de unidad NO estan: un rectangulo alrededor de las barras de
-- vida quedaba mal contra el arte dorado de Blizzard.
--
-- ARTE PROPIO. Las cuatro texturas de Media/Border (Soft, Pixel, Glow y
-- la Light que usa el minimapa) las dibuja Tools/mkborders.py: geometria
-- pura, un perfil de alfa segun la distancia al filo. No hay nada de
-- terceros adentro.
--
-- COMO SE ARMA EL EDGEFILE.
--
-- Cada .tga es una tira de OCHO casillas cuadradas, en el orden que
-- espera SetBackdrop: izquierda, derecha, arriba, abajo y las cuatro
-- esquinas. Las de arriba y abajo son copia de las de izquierda y
-- derecha, porque el motor las rota solo al dibujarlas. Con eso el
-- backdrop nativo reparte el borde y no hace falta una sola linea de
-- dibujo a mano.
--
-- La banda va pegada al filo EXTERIOR de la casilla. El marco del borde
-- se crea a 1 px del objetivo, asi que una banda dibujada mas adentro
-- terminaba cruzando por arriba de los botones.
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

-- Grosor: cuantos pixeles de pantalla ocupa cada casilla del edgeFile.
-- El nucleo macizo de la textura ocupa 2.8 de 32 texeles, asi que con 10
-- da algo menos de un pixel de filo lleno mas la pluma. Con 12 la banda
-- se iba a casi dos pixeles y los botones quedaban encajonados.
local STYLES = {
	Soft = { file = ART .. "Border_Soft", edge = 10 },
};

local GLOW_FILE, GLOW_EDGE = ART .. "Border_Glow", 3;

local function Style()
	return STYLES.Soft;
end

-- EL EDGESIZE NO PUEDE SER MAS GRANDE QUE MEDIO MARCO.
--
-- Cada casilla de esquina se dibuja a edgeSize x edgeSize. En una barra
-- de casteo de 13 px de alto, las dos esquinas de un lado son 20 px y no
-- entran: el backdrop las encima y salen esas puntas raras en los
-- extremos. Aca se recorta al vuelo segun el lado mas corto.
--
-- El marco del borde va 1 px por fuera del objetivo de cada lado, de ahi
-- el +2.
local function EdgeFor(frame, edge)
	local w = (frame.GetWidth  and frame:GetWidth())  or 0;
	local h = (frame.GetHeight and frame:GetHeight()) or 0;
	local small = math.min(w, h) + 2;
	if small <= 0 then return edge; end

	local maxEdge = math.floor(small / 2);
	if maxEdge < 2 then maxEdge = 2; end
	if edge > maxEdge then return maxEdge; end
	return edge;
end

-- COLOR DEL FILO.
--
-- Las texturas se dibujan en blanco a proposito, para que el color lo
-- ponga SetBackdropBorderColor y no haya que tener dos juegos de .tga.
--
-- El filo va en blanco. La textura tambien esta dibujada en blanco, asi
-- que esto es solo la opacidad; se deja escrito para no tener que
-- adivinar de donde sale el color si alguna vez hay que cambiarlo.
local BORDER_R, BORDER_G, BORDER_B = 1, 1, 1;

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
		key = "FrameBorder_ActionBars",
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
		key = "FrameBorder_MicroMenu",
		label = "Micro Menu",
		names = {
			"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
			"QuestLogMicroButton", "SocialsMicroButton", "AchievementMicroButton",
			"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
		},
	},
	{
		key = "FrameBorder_Bags",
		label = "Bags",
		names = Join(
			{ "MainMenuBarBackpackButton", "KeyRingButton" },
			Series("CharacterBag", 4, "Slot")   -- CharacterBag0Slot..3Slot, ver el ajuste abajo
		),
	},
	{
		key = "FrameBorder_CastBar",
		label = "Cast Bar",
		names = { "CastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar" },
	},
	{
		key = "FrameBorder_Auras",
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
	if g.key == "FrameBorder_Bags" then
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
	d.shadow:SetBackdrop({ edgeFile = GLOW_FILE, edgeSize = EdgeFor(frame, GLOW_EDGE) });
	d.shadow:SetBackdropBorderColor(0, 0, 0, 0.8);
	d.shadow:Hide();

	-- LOS RECUADROS FANTASMA.
	--
	-- El borde es HIJO del marco, asi que cuando el marco se esconde el
	-- borde se va solo. La sombra no: cuelga del padre, que sigue
	-- visible, y quedaba flotando en el aire.
	--
	-- Por eso aparecian recuadros sueltos por toda la pantalla: los
	-- botones de aura sin aura, las ranuras vacias, la barra de mascota
	-- sin mascota. Todos marcos escondidos que dejaban su sombra puesta.
	--
	-- HookScript sobre OnShow/OnHide es un agregado, no un reemplazo: no
	-- pisa el guion de Blizzard ni ensucia el marco, asi que se puede
	-- usar sobre botones protegidos y en combate.
	if frame.HookScript then
		frame:HookScript("OnShow", function()
			if d.wantShadow then d.shadow:Show(); end
		end);
		frame:HookScript("OnHide", function() d.shadow:Hide(); end);
	end

	decorated[frame] = d;
	return d;
end

local enabled = false;

-- HAY ALGO DIBUJADO AHI?
--
-- Un boton vacio sigue "mostrado": Blizzard solo le apaga la imagen. Con
-- el borde puesto quedaba un recuadro alrededor de la nada, que es
-- justo lo que se veia en la fila del micromenu y en las ranuras de
-- bolsa sin bolsa.
--
-- Cada familia de botones nombra su imagen distinto, de ahi los tres
-- casos:
--
--   <nombre>Icon          botones de accion, postura y mascota
--   <nombre>IconTexture   ranuras de bolsa y la mochila
--   GetNormalTexture()    micromenu y cualquier boton comun
--
-- Se mira la imagen y no HasAction porque asi entran los tres de una.
-- Lo que no es un boton (las barras, la de casteo) no tiene ninguna de
-- las tres y pasa derecho.
local function HasArt(frame, name)
	local icon = _G[name .. "Icon"] or _G[name .. "IconTexture"];
	if icon and icon.GetTexture then
		return (icon:IsShown() and icon:GetTexture()) and true or false;
	end

	if frame.GetNormalTexture then
		local nt = frame:GetNormalTexture();
		if nt and nt.GetTexture then
			return (nt:IsShown() and nt:GetTexture()) and true or false;
		end
	end

	return true;
end

local function ApplyToName(name, want)
	local frame = _G[name];
	if not frame or not frame.GetFrameLevel then return; end

	if want and not HasArt(frame, name) then want = false; end

	if not want then
		local d = decorated[frame];
		if d then d.wantShadow = false; d.border:Hide(); d.shadow:Hide(); end
		return;
	end

	local d = Ensure(frame);
	local st = Style();
	d.border:SetBackdrop({ edgeFile = st.file, edgeSize = EdgeFor(frame, st.edge) });
	d.border:SetBackdropBorderColor(BORDER_R, BORDER_G, BORDER_B, 1);
	d.border:Show();

	-- La sombra solo si el marco esta a la vista. wantShadow se guarda para
	-- que el OnShow de mas arriba sepa si tiene que volver a mostrarla.
	d.wantShadow = (C.FrameBorderShadow ~= false);
	if d.wantShadow and frame:IsVisible() then
		d.shadow:Show();
	else
		d.shadow:Hide();
	end
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

-- ACTIONBAR_SLOT_CHANGED y compania: al arrastrar un hechizo a una ranura
-- vacia (o al vaciarla) hay que rehacer el barrido, si no el borde queda
-- como estaba en el ultimo repaso.
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
local function CreateBorderSubUI(container, yOffset, parentCheckbox)
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

	local subOptions = {
		{ key = "FrameBorderShadow", label = "Outer shadow",
		  tip = "A soft dark halo just outside each frame. It is the glow the original UI draws." },
	};
	for _, g in ipairs(GROUPS) do
		subOptions[#subOptions + 1] = { key = g.key, label = g.label };
	end

	for _, opt in ipairs(subOptions) do
		local cbName = "NidhausBorderSubCB_" .. opt.key;
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
	name    = L["MOD_FRAMEBORDERS"] or "Frame Borders",
	desc    = L["MOD_FRAMEBORDERS_DESC"]
		or "Thin rounded border and outer shadow around action bars, micro menu, bags, cast bar and auras. Stacks with Lorti UI: Lorti tints, this outlines.",
	default = false,
	createUI = CreateBorderSubUI,
	onEnable = function()
		enabled = true;
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
		events:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
		events:RegisterEvent("UNIT_PET");
		events:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
		events:RegisterEvent("ACTIONBAR_PAGE_CHANGED");
		events:RegisterEvent("UPDATE_BONUS_ACTIONBAR");
		events:RegisterEvent("PET_BAR_UPDATE");
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
