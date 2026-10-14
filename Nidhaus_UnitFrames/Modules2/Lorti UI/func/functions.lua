local addon, ns = ...
local K = ns[1]
local cfg = ns.cfg
local _G = _G

local nomoreplay = function() end

local classcolor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

-- FIX: Cache del estado de LortiUI para evitar DB lookups en cada ActionButton_Update
-- (antes se llamaba K.IsModuleEnabled("LortiUI") decenas de veces por segundo en combate)
local lortiEnabled = false;

-- =========================================================
-- EL CONTORNO DE LOS BOTONES, DEL COLOR ELEGIDO
--
-- Lo que lleva el color propio es la SOMBRA de alrededor de cada boton
-- (el borde "outer_shadow" del fondo, negro en Lorti). Con la zona
-- "Barras de accion" con "Lorti" y "Color" tildadas, ese contorno va de su
-- color, como en el Lorti UI "frost". Con Unify o MiniBar el arte de la
-- barra de Blizzard esta escondido, asi que esto es lo que se ve.
--
-- El borde de adentro del boton (el "gloss") queda negro, como siempre:
-- hubo una version que lo pintaba a el y no era lo que se queria.
-- =========================================================
local function NormalColor()
	return cfg.color.normal.r, cfg.color.normal.g, cfg.color.normal.b;
end

local function ShadowColor()
	local C = ns[2];
	local sc = cfg.background.shadowcolor;
	if K.LortiZoneColor then
		local r, g, b = K.LortiZoneColor("ActionBars");
		if r then return r, g, b, sc.a or 0.9; end
	end
	return sc.r, sc.g, sc.b, sc.a;
end

local shadowButtons = {};   -- [boton] = true, los que tienen fondo/contorno

-- =========================================================
-- CONTORNO ROJO FUERA DE RANGO (Button Range > "Lorti UI red border")
--
-- Es el MISMO contorno que lleva el color de "Action Bars": un solo aro.
-- Mientras el boton esta fuera de rango el rojo ocupa su lugar (no se
-- dibuja otro aro encima) y al volver al rango se repone el color que
-- corresponda en ese momento: el elegido o el negro de siempre.
--
-- rangeRed marca los botones que estan en rojo, para que cambiar el color
-- de Lorti mientras tanto no les borre el rojo (K.ApplyLortiButtonColor
-- los saltea) y para poder apagarlos todos de una (LortiRangeBorderReset).
-- =========================================================
local RANGE_RED = { 1, 0.1, 0.1, 1 };
local rangeRed = {};   -- [boton] = true mientras su contorno esta en rojo

local styledButtons = {};   -- [boton] = true, los que ya tienen el estilo
-- Blizzard repone el borde a blanco y el gancho de abajo lo vuelve a
-- pintar. Si el color elegido fuera justo blanco, el gancho se llamaria a
-- si mismo sin fin: esto lo corta.
local inHook = false;

local function UpdateLortiCache()
	lortiEnabled = K.IsModuleEnabled and K.IsModuleEnabled("LortiUI") or false;
end

-- Actualizar cache cuando cambia la config
if K.RegisterConfigEvent then
	K.RegisterConfigEvent("CONFIG_LOADED", UpdateLortiCache);
	K.RegisterConfigEvent("CONFIG_CHANGED", UpdateLortiCache);
end

-- También actualizar en PLAYER_LOGIN por si los módulos se inicializan después
local lortiCacheFrame = CreateFrame("Frame");
lortiCacheFrame:RegisterEvent("PLAYER_LOGIN");
lortiCacheFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	UpdateLortiCache();
end);

if cfg.color.classcolored then
	cfg.color.normal = classcolor
end

local bgfile, edgefile = "", ""
if cfg.background.showshadow then edgefile = cfg.textures.outer_shadow end
if cfg.background.useflatbackground and cfg.background.showbg then bgfile = cfg.textures.buttonbackflat end

local backdrop = {
	bgFile = bgfile,
	edgeFile = edgefile,
	tile = false,
	tileSize = 32,
	edgeSize = cfg.background.inset,
	insets = {
		left = cfg.background.inset,
		right = cfg.background.inset,
		top = cfg.background.inset,
		bottom = cfg.background.inset,
	},
}

local function applyBackground(bu)
	if cfg.background.showbg or cfg.background.showshadow then
		bu.bg = CreateFrame("Frame", nil, bu)
		bu.bg:SetAllPoints(bu)
		bu.bg:SetPoint("TOPLEFT", bu, "TOPLEFT", -4, 4)
		bu.bg:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", 4, -4)
		bu.bg:SetFrameLevel(bu:GetFrameLevel() - 1)

		if cfg.background.classcolored then
			cfg.background.backgroundcolor = classcolor
			cfg.background.shadowcolor = classcolor
		end

		if cfg.background.showbg and not cfg.background.useflatbackground then
			local t = bu.bg:CreateTexture(nil, "BACKGROUND", -8)
			t:SetTexture(cfg.textures.buttonback)
			t:SetAllPoints(bu)
			t:SetVertexColor(cfg.background.backgroundcolor.r, cfg.background.backgroundcolor.g, cfg.background.backgroundcolor.b, cfg.background.backgroundcolor.a)
		end

		bu.bg:SetBackdrop(backdrop)
		if cfg.background.useflatbackground then
			bu.bg:SetBackdropColor(cfg.background.backgroundcolor.r, cfg.background.backgroundcolor.g, cfg.background.backgroundcolor.b, cfg.background.backgroundcolor.a)
		end
		if cfg.background.showshadow then
			bu.bg:SetBackdropBorderColor(ShadowColor())
			shadowButtons[bu] = true
		end
	end
end

local function ntSetVertexColorFunc(nt, r, g, b, a)
	if inHook or not nt then return end
	inHook = true
	local self = nt:GetParent()
	local action = self.action
	if r == 1 and g == 1 and b == 1 and action and IsEquippedAction(action) then
		nt:SetVertexColor(cfg.color.equipped.r, cfg.color.equipped.g, cfg.color.equipped.b, 1)
	elseif r == 0.5 and g == 0.5 and b == 1 then
		local nr, ng, nb = NormalColor()
		nt:SetVertexColor(nr, ng, nb, 1)
	elseif r == 1 and g == 1 and b == 1 then
		local nr, ng, nb = NormalColor()
		nt:SetVertexColor(nr, ng, nb, 1)
	end
	inHook = false
end

local function rActionButtonStyler_AB_style(self)
	if not lortiEnabled then return end

	if not self.rABS_Styled and self:GetParent() and self:GetParent():GetName() ~= "MultiCastActionBarFrame" and self:GetParent():GetName() ~= "MultiCastActionPage1" and self:GetParent():GetName() ~= "MultiCastActionPage2" and self:GetParent():GetName() ~= "MultiCastActionPage3" then

		local action = self.action
		local name = self:GetName()
		local bu  = _G[name]
		local ic  = _G[name.."Icon"]
		local co  = _G[name.."Count"]
		local bo  = _G[name.."Border"]
		local ho  = _G[name.."HotKey"]
		local cd  = _G[name.."Cooldown"]
		local na  = _G[name.."Name"]
		local fl  = _G[name.."Flash"]
		local nt  = _G[name.."NormalTexture"]

		bo:Hide()
		bo.Show = nomoreplay

		-- LA FAMILIA PUEDE NO SER NUESTRA.
		--
		-- El addon Nidhaus Frame Borders tambien cambia la letra de estos
		-- tres textos. Antes se los peleaban: ganaba el que corriera
		-- ultimo, y como esto reaplica en cada actualizacion de boton, casi
		-- siempre ganaba Lorti. Ahora Lorti pone TAMANO y POSICION, que es
		-- lo suyo, y pregunta la familia.
		--
		-- Es una global porque el otro es un addon aparte. Si no esta
		-- instalado, fam queda nil y todo sigue como siempre.
		local fam = NidhausFrameBorders_ButtonFont
			and NidhausFrameBorders_ButtonFont() or nil;

		if cfg.hotkeys.show then
			ho:SetFont(fam or cfg.font, cfg.hotkeys.fontsize, "OUTLINE")
			ho:ClearAllPoints()
			ho:SetPoint(cfg.hotkeys.pos1.a1, bu, cfg.hotkeys.pos1.x, cfg.hotkeys.pos1.y)
			ho:SetPoint(cfg.hotkeys.pos2.a1, bu, cfg.hotkeys.pos2.x, cfg.hotkeys.pos2.y)
		else
			ho:Hide()
			ho.Show = nomoreplay
		end

		if cfg.macroname.show then
			na:SetFont(fam or cfg.font, cfg.macroname.fontsize, "OUTLINE")
			na:ClearAllPoints()
			na:SetPoint(cfg.macroname.pos1.a1, bu, cfg.macroname.pos1.x, cfg.macroname.pos1.y)
			na:SetPoint(cfg.macroname.pos2.a1, bu, cfg.macroname.pos2.x, cfg.macroname.pos2.y)
		else
			na:Hide()
		end

		if cfg.itemcount.show then
			co:SetFont(fam or cfg.font, cfg.itemcount.fontsize, "OUTLINE")
			co:ClearAllPoints()
			co:SetPoint(cfg.itemcount.pos1.a1, bu, cfg.itemcount.pos1.x, cfg.itemcount.pos1.y)
		else
			co:Hide()
		end

		fl:SetTexture(cfg.textures.flash)
		bu:SetHighlightTexture(cfg.textures.hover)
		bu:SetPushedTexture(cfg.textures.pushed)
		bu:SetCheckedTexture(cfg.textures.checked)
		bu:SetNormalTexture(cfg.textures.normal)

		ic:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
		ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)

		cd:SetPoint("TOPLEFT", bu, "TOPLEFT", cfg.cooldown.spacing, -cfg.cooldown.spacing)
		cd:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -cfg.cooldown.spacing, cfg.cooldown.spacing)

		if IsEquippedAction(action) then
			bu:SetNormalTexture(cfg.textures.equipped)
			nt:SetVertexColor(cfg.color.equipped.r, cfg.color.equipped.g, cfg.color.equipped.b, 1)
		else
			bu:SetNormalTexture(cfg.textures.normal)
			local nr, ng, nb = NormalColor()
			nt:SetVertexColor(nr, ng, nb, 1)
		end

		nt:SetAllPoints(bu)

		fl.SetTexture = nomoreplay
		bu.SetHighlightTexture = nomoreplay
		bu.SetPushedTexture = nomoreplay
		bu.SetCheckedTexture = nomoreplay
		bu.SetNormalTexture = nomoreplay

		hooksecurefunc(nt, "SetVertexColor", ntSetVertexColorFunc)

		if not bu.bg then applyBackground(bu) end

		styledButtons[bu] = true
		self.rABS_Styled = true
	end
end

local function rActionButtonStyler_AB_stylepet()
	if not lortiEnabled then return end

	for i = 1, NUM_PET_ACTION_SLOTS do
		local name = "PetActionButton"..i
		local bu  = _G[name]
		local ic  = _G[name.."Icon"]
		local fl  = _G[name.."Flash"]

		if not bu.rABS_Styled then
			fl:SetTexture(cfg.textures.flash)
			bu:SetHighlightTexture(cfg.textures.hover)
			bu:SetPushedTexture(cfg.textures.pushed)
			bu:SetCheckedTexture(cfg.textures.checked)

			ic:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
			ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)

			if not bu.bg then applyBackground(bu) end

			bu.rABS_Styled = true
		end

		-- Style NormalTexture2 directly — do NOT use SetNormalTexture().
		-- Blizzard resets NormalTexture2 every PetActionBar_Update.
		-- Using SetNormalTexture creates a SECOND texture that fights with
		-- NormalTexture2, causing visual corruption. Style the one Blizzard
		-- owns so there's only one texture, no conflict.
		local nt2 = _G[name.."NormalTexture2"]
		if nt2 then
			nt2:SetTexture(cfg.textures.normal)
			nt2:SetAllPoints(bu)
			local nr, ng, nb = NormalColor()
			nt2:SetVertexColor(nr, ng, nb, 1)
		end
	end
end

local function rActionButtonStyler_AB_styleshapeshift()
	if not lortiEnabled then return end

	for i = 1, NUM_SHAPESHIFT_SLOTS do
		local name = "ShapeshiftButton"..i
		local bu  = _G[name]
		local ic  = _G[name.."Icon"]
		local fl  = _G[name.."Flash"]

		if not bu.rABS_Styled then
			fl:SetTexture(cfg.textures.flash)
			bu:SetHighlightTexture(cfg.textures.hover)
			bu:SetPushedTexture(cfg.textures.pushed)
			bu:SetCheckedTexture(cfg.textures.checked)

			ic:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			ic:SetPoint("TOPLEFT", bu, "TOPLEFT", 2, -2)
			ic:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -2, 2)

			if not bu.bg then applyBackground(bu) end

			bu.rABS_Styled = true
		end

		-- Style NormalTexture directly (same approach as pet bar)
		local nt = _G[name.."NormalTexture"]
		if nt then
			nt:SetTexture(cfg.textures.normal)
			nt:SetAllPoints(bu)
			local nr, ng, nb = NormalColor()
			nt:SetVertexColor(nr, ng, nb, 1)
		end
	end
end

-- Repinta en el acto el contorno de todos los botones ya estilizados (lo
-- llama K.ApplyLortiColor al cambiar el color o la casilla). De paso deja
-- el borde de adentro en su negro (por si quedo pintado de la version
-- anterior, sin tener que hacer /reload).
function K.ApplyLortiButtonColor()
	if not lortiEnabled then return end
	local sr, sg, sb, sa = ShadowColor()
	for bu in pairs(shadowButtons) do
		-- Los que estan fuera de rango siguen en rojo: el color nuevo les
		-- llega solo al volver al rango.
		if not rangeRed[bu] and bu.bg and bu.bg.SetBackdropBorderColor then
			bu.bg:SetBackdropBorderColor(sr, sg, sb, sa)
		end
	end
	local nr, ng, nb = NormalColor()
	for bu in pairs(styledButtons) do
		local name = bu:GetName()
		local nt = name and _G[name.."NormalTexture"]
		if nt and not (bu.action and IsEquippedAction(bu.action)) then
			inHook = true
			nt:SetVertexColor(nr, ng, nb, 1)
			inHook = false
		end
	end
	rActionButtonStyler_AB_styleshapeshift()
	rActionButtonStyler_AB_stylepet()
end

-- Lo llama Button Range en cada chequeo de rango (cada 0.2 s por boton).
-- out = true: fuera de rango -> contorno rojo. Devuelve true si el boton
-- tiene contorno de Lorti y lo pinto (si no, Button Range sigue como
-- siempre). out = false: si estaba en rojo, vuelve a su color.
-- Solo se toca el contorno cuando el estado CAMBIA.
function K.LortiRangeBorder(bu, out)
	if not bu then return false end
	if out then
		local bg = bu.bg
		if not (lortiEnabled and bg and shadowButtons[bu]) then return false end
		if not rangeRed[bu] then
			rangeRed[bu] = true
			bg:SetBackdropBorderColor(RANGE_RED[1], RANGE_RED[2], RANGE_RED[3], RANGE_RED[4])
		end
		return true
	end
	if rangeRed[bu] then
		rangeRed[bu] = nil
		if bu.bg then bu.bg:SetBackdropBorderColor(ShadowColor()) end
	end
	return false
end

-- Apagar Button Range o su sub-opcion: todos los contornos a su color.
function K.LortiRangeBorderReset()
	for bu in pairs(rangeRed) do
		rangeRed[bu] = nil
		if bu.bg then bu.bg:SetBackdropBorderColor(ShadowColor()) end
	end
end

hooksecurefunc("ActionButton_Update",       rActionButtonStyler_AB_style)
hooksecurefunc("ShapeshiftBar_Update",      rActionButtonStyler_AB_styleshapeshift)
hooksecurefunc("ShapeshiftBar_UpdateState", rActionButtonStyler_AB_styleshapeshift)
hooksecurefunc("PetActionBar_Update",       rActionButtonStyler_AB_stylepet)