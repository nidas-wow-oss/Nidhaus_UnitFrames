local AddOnName, ns = ...
local K = ns[1]
local L = ns[3]   -- tabla de traducciones

local cfg = CreateFrame("Frame")
local kill = function() end
local initialized = false

local function SubOpt(key)
	local C = ns[2]
	if C[key] == nil then return true end
	return C[key]
end

-- =============================================
-- EL TINTE, PARA QUE LO USEN LOS ESTILOS DE NUF
--
-- Lorti oscurece los marcos con SetVertexColor sobre la textura que trae
-- Blizzard. Pero los estilos Compact del grupo y de arena REEMPLAZAN esa
-- textura y le ponen su propio color (blanco neutro), asi que le pisaban
-- el tinte y Lorti parecia no aplicarse en esos modos.
--
-- En vez de que cada estilo copie los numeros, los pide aca. Si Lorti esta
-- apagado — el modulo o esa parte suya — devuelve nil y el estilo usa su
-- color de siempre.
--
--   grupo  0.05  (casi negro, es el valor de Lorti)
--   arena  0.10  (un punto mas claro, tambien de Lorti)
-- =============================================
function K.LortiTint(key)
	if K.IsModuleEnabled and not K.IsModuleEnabled("LortiUI") then return nil; end
	if not SubOpt(key) then return nil; end
	if key == "LortiUI_Arena" then return 0.1, 0.1, 0.1; end
	return 0.05, 0.05, 0.05;
end

-- =============================================
-- TEÑIR UNA TEXTURA
--
-- Un solo camino: el mismo SetVertexColor que Lorti le aplica al arte de
-- Blizzard. Devuelve true si tiño y false si Lorti esta apagado, para que
-- el llamador sepa si tiene que reponer el blanco.
--
-- NOTA PARA EL FUTURO: hubo un intento de desaturar la textura antes de
-- oscurecerla, partiendo de que multiplicar un arte "de color" daba un
-- tono raro. Medi las texturas y NO ES ASI: Light promedia R93 G89 B70,
-- Dark R28 G27 B21 y las de pw R111 G106 B87 — grises calidos, sin nada
-- de verde. Multiplicarlas por 0.05 da negro, no otro color.
--
-- Ademas SetDesaturated devuelve nil cuando la textura no lo soporta, y
-- dar eso por bueno terminaba ACLARANDO el marco en vez de oscurecerlo:
-- fue lo que rompio el grupo. Si algun dia vuelve a hacer falta, tiene
-- que mirarse ese valor de retorno.
-- =============================================
function K.ApplyLortiTint(tex, key)
	if not tex then return false; end
	local r, g, b = K.LortiTint(key);
	if not r then
		tex:SetVertexColor(1, 1, 1);
		return false;
	end
	tex:SetVertexColor(r, g, b);
	return true;
end

-- Compatibilidad WoW 3.3.5: Show/Hide en cualquier objeto de UI
local function SafeShow(obj) if obj and obj.Show then obj:Show() end end
local function SafeHide(obj) if obj and obj.Hide then obj:Hide() end end

-- =============================================
-- PLAYER / TARGET / FOCUS
-- =============================================

local function ApplyDarkPlayerTargetFocusTextures()
	for _, v in pairs({
		PlayerFrameTexture,
		TargetFrameTextureFrameTexture,
		PetFrameTexture,
		FocusFrameTextureFrameTexture,
		TargetFrameToTTextureFrameTexture,
		FocusFrameToTTextureFrameTexture,
		CastingBarFrameBorder,
		FocusFrameSpellBarBorder,
		TargetFrameSpellBarBorder,
	}) do
		if v then v:SetVertexColor(.05, .05, .05) end
	end
	if TimeManagerClockButton then
		local region = select(1, TimeManagerClockButton:GetRegions())
		if region then region:SetVertexColor(.05, .05, .05) end
	end
	if GameTimeFrame then
		local region = select(1, GameTimeFrame:GetRegions())
		if region then region:SetVertexColor(.05, .05, .05) end
	end
end

local function InitPlayerTargetFocus()
	if not SubOpt("LortiUI_PlayerTargetFocus") then return end
	if IsAddOnLoaded("Blizzard_TimeManager") then
		ApplyDarkPlayerTargetFocusTextures()
	else
		local ef = CreateFrame("Frame")
		ef:RegisterEvent("ADDON_LOADED")
		ef:SetScript("OnEvent", function(self, event, addon)
			if addon == "Blizzard_TimeManager" then
				if SubOpt("LortiUI_PlayerTargetFocus") then ApplyDarkPlayerTargetFocusTextures() end
				self:UnregisterEvent("ADDON_LOADED")
				self:SetScript("OnEvent", nil)
			end
		end)
	end
end

-- =============================================
-- PARTY
-- =============================================

local function ApplyDarkPartyTextures()
	for _, v in pairs({
		PartyMemberFrame1Texture,
		PartyMemberFrame2Texture,
		PartyMemberFrame3Texture,
		PartyMemberFrame4Texture,
		PartyMemberFrame1PetFrameTexture,
		PartyMemberFrame2PetFrameTexture,
		PartyMemberFrame3PetFrameTexture,
		PartyMemberFrame4PetFrameTexture,
	}) do
		if v then v:SetVertexColor(.05, .05, .05) end
	end
end

local function InitParty()
	if not SubOpt("LortiUI_Party") then return end
	ApplyDarkPartyTextures()
end

-- =============================================
-- ARENA
-- =============================================

local function ApplyDarkArenaTextures()
	for i = 1, 5 do
		local tex = _G["ArenaEnemyFrame"..i.."Texture"]
		if tex then tex:SetVertexColor(0.1, 0.1, 0.1) end

		-- LAS MASCOTAS TAMBIEN.
		--
		-- Lorti solo oscurecia el marco del enemigo y se olvidaba del de su
		-- mascota, que es un marco chico aparte con su propia textura. En
		-- arena quedaba el jugador oscuro y al lado su felguard o su gargola
		-- con el marco dorado de Blizzard, cantando.
		--
		-- En el grupo si las contemplaba (mira ApplyDarkPartyTextures), asi
		-- que era un olvido y no una decision.
		local petTex = _G["ArenaEnemyFrame"..i.."PetFrameTexture"]
		if petTex then petTex:SetVertexColor(0.1, 0.1, 0.1) end
	end
end

local function InitArena()
	if not SubOpt("LortiUI_Arena") then return end
	if IsAddOnLoaded("Blizzard_ArenaUI") then
		ApplyDarkArenaTextures()
	else
		local s = CreateFrame("Frame")
		s:RegisterEvent("ADDON_LOADED")
		s:SetScript("OnEvent", function(self, event, addon)
			if addon == "Blizzard_ArenaUI" then
				if SubOpt("LortiUI_Arena") then ApplyDarkArenaTextures() end
				self:UnregisterEvent("ADDON_LOADED")
				self:SetScript("OnEvent", nil)
			end
		end)
	end
end

-- =============================================
-- ACTION BARS
-- =============================================

local function InitActionBars()
	if not SubOpt("LortiUI_ActionBars") then return end
	for _, v in pairs({
		BonusActionBarTexture0, BonusActionBarTexture1,
		MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2, MainMenuBarTexture3,
		MainMenuMaxLevelBar0, MainMenuMaxLevelBar1, MainMenuMaxLevelBar2, MainMenuMaxLevelBar3,
		MainMenuXPBarTextureLeftCap, MainMenuXPBarTextureRightCap, MainMenuXPBarTextureMid,
		MainMenuXPBarTexture0, MainMenuXPBarTexture1, MainMenuXPBarTexture2, MainMenuXPBarTexture3,
		ReputationWatchBarTexture0, ReputationWatchBarTexture1, ReputationWatchBarTexture2, ReputationWatchBarTexture3,
		ReputationXPBarTexture0, ReputationXPBarTexture1, ReputationXPBarTexture2, ReputationXPBarTexture3,
	}) do
		v:SetVertexColor(.2, .2, .2)
	end
	for _, v in pairs({ MainMenuBarLeftEndCap, MainMenuBarRightEndCap }) do
		v:SetVertexColor(.35, .35, .35)
	end
end

-- =============================================
-- MINIMAP
-- =============================================

local function InitMinimap()
	if not SubOpt("LortiUI_Minimap") then return end
	local ok, err = pcall(function()
		-- Oscurecer el borde del minimapa
		if MinimapBorder then MinimapBorder:SetVertexColor(.05, .05, .05) end
		if MinimapBorderTop then MinimapBorderTop:Hide() end
		-- Mantener botones visibles
		if MinimapZoomIn then MinimapZoomIn:Show() end
		if MinimapZoomOut then MinimapZoomOut:Show() end
		if MiniMapWorldMapButton then MiniMapWorldMapButton:Show() end
		if MiniMapTracking then
			MiniMapTracking:Show()
			MiniMapTracking.Show = kill
			MiniMapTracking:UnregisterAllEvents()
		end
		if Minimap then
			Minimap:EnableMouseWheel(true)
			Minimap:SetScript("OnMouseWheel", function(self, z)
				local c = Minimap:GetZoom()
				if z > 0 and c < 5 then Minimap:SetZoom(c + 1)
				elseif z < 0 and c > 0 then Minimap:SetZoom(c - 1) end
			end)
			Minimap:SetScript("OnMouseUp", function(self, btn)
				if btn == "RightButton" then
					if _G.GameTimeFrame then _G.GameTimeFrame:Click() end
				elseif btn == "MiddleButton" then
					_G.ToggleDropDownMenu(1, nil, _G.MiniMapTrackingDropDown, self)
				else
					_G.Minimap_OnClick(self)
				end
			end)
		end
	end)
	if not ok then
		print("|cffFF0000NUF Lorti:|r Minimap init error: " .. tostring(err))
	end
end

-- =============================================
-- MAIN INIT
-- =============================================

local function Init()
	if initialized then return end
	initialized = true

	InitMinimap()
	InitActionBars()
	InitPlayerTargetFocus()
	InitParty()
	InitArena()

	if K.RegisterConfigEvent then
		K.RegisterConfigEvent("CONFIG_LOADED", function()
			if SubOpt("LortiUI_PlayerTargetFocus") then ApplyDarkPlayerTargetFocusTextures() end
			if SubOpt("LortiUI_Party")             then ApplyDarkPartyTextures() end
			if SubOpt("LortiUI_Arena") and IsAddOnLoaded("Blizzard_ArenaUI") then ApplyDarkArenaTextures() end
		end)
	end
end

-- =============================================
-- Config
-- =============================================
cfg.textures = {
	normal         = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\gloss",
	flash          = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\flash",
	hover          = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\hover",
	pushed         = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\pushed",
	checked        = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\checked",
	equipped       = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\gloss_grey",
	buttonback     = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\button_background",
	buttonbackflat = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\button_background_flat",
	outer_shadow   = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\outer_shadow",
}
cfg.background = {
	showbg = true, showshadow = true, useflatbackground = false,
	backgroundcolor = { r=0.3, g=0.3, b=0.3, a=0.7 },
	shadowcolor     = { r=0,   g=0,   b=0,   a=0.9 },
	classcolored = false, inset = 5,
}
cfg.color = {
	normal   = { r=0,   g=0,    b=0,   a=0.9 },
	equipped = { r=0.3, g=0.55, b=0.1 },
	classcolored = false,
}
cfg.hotkeys   = { show=true, fontsize=12, pos1={a1="TOPRIGHT",x=0,y=0}, pos2={a1="TOPLEFT",x=0,y=0} }
cfg.macroname = { show=true, fontsize=11, pos1={a1="BOTTOMLEFT",x=-4,y=0}, pos2={a1="BOTTOMRIGHT",x=4,y=0} }
cfg.itemcount = { show=true, fontsize=12, pos1={a1="BOTTOMRIGHT",x=0,y=0} }
cfg.cooldown  = { spacing=0 }
cfg.font      = "Fonts\\FRIZQT__.TTF"
ns.cfg = cfg

-- =============================================
-- SUB-OPTION UI (inyectada en el tab Modules)
-- API: createUI(container, yOffset, parentCheckbox) -> subUIHeight
-- =============================================
local function CreateLortiSubUI(container, yOffset, parentCheckbox)
	local C = ns[2]

	-- Wrapper frame para todas las sub-opciones (se muestra/oculta como grupo)
	local wrapper = CreateFrame("Frame", nil, container)
	wrapper:SetPoint("TOPLEFT", 0, yOffset)
	wrapper:SetWidth(container:GetWidth() or 540)

	local localY = 0

	-- Separador visual
	local sep = wrapper:CreateTexture(nil, "ARTWORK")
	sep:SetHeight(1)
	sep:SetPoint("TOPLEFT", 36, localY + 4)
	sep:SetPoint("TOPRIGHT", -10, localY + 4)
	sep:SetTexture(1, 1, 1, 0.07)
	localY = localY - 6

	local header = wrapper:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	header:SetPoint("TOPLEFT", 46, localY)
	header:SetText("|cff888888" .. (L["LORTI_SUBOPTIONS"] or "Sub-options (requires /reload):") .. "|r")
	localY = localY - 20

	local subOptions = {
		{ key="LortiUI_PlayerTargetFocus", label="Player / Target / Focus", tip="Darkens Player, Target and Focus frame textures\n(including castbars and ToT)." },
		{ key="LortiUI_Party",             label="Party",                   tip="Darkens the 4 party frames and their pet textures." },
		{ key="LortiUI_Arena",             label="Arena",                   tip="Darkens enemy arena frame textures." },
		{ key="LortiUI_ActionBars",        label="Action Bars",             tip="Darkens action bar, bonus, XP and Reputation textures." },
		{ key="LortiUI_Minimap",           label="Minimap",                 tip="Scroll zoom with mouse wheel + right-click for calendar." },
	}

	local subCheckboxes = {}

	for _, opt in ipairs(subOptions) do
		local cbName = "NidhausLortiSubCB_" .. opt.key
		local cb = CreateFrame("CheckButton", cbName, wrapper, "InterfaceOptionsCheckButtonTemplate")
		cb:SetPoint("TOPLEFT", 46, localY)
		cb:SetHitRectInsets(0, -260, 0, 0)
		cb:SetScale(0.9)

		local lbl = _G[cbName .. "Text"]
		if lbl then
			lbl:SetText(opt.label)
			lbl:SetFontObject("GameFontHighlight")
		end

		-- Si la sub-opción nunca fue tocada (nil), inicializar como true
		if C[opt.key] == nil then
			C[opt.key] = true
			if NidhausUnitFramesDB then NidhausUnitFramesDB[opt.key] = true end
		end
		cb:SetChecked(C[opt.key] ~= false)

		local tipText = opt.tip .. "\n\n|cffFFAA00⚠ Requires /reload|r"
		cb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(opt.label, 1, 1, 1)
			GameTooltip:AddLine(tipText, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
		cb:SetScript("OnClick", function(self)
			local checked = self:GetChecked() == 1 or self:GetChecked() == true
			K.SaveConfig(opt.key, checked)
		end)

		table.insert(subCheckboxes, cb)
		localY = localY - 22
	end

	localY = localY - 8
	local subUIHeight = math.abs(localY)
	wrapper:SetHeight(subUIHeight)

	-- Mostrar/ocultar según estado del módulo
	local function SetSubsVisible(show)
		if show then
			wrapper:Show()
			-- Al activar, asegurar que todos los checkboxes estén checkeados por default
			for _, cb in ipairs(subCheckboxes) do
				if cb:GetChecked() == nil or cb:GetChecked() == false then
					-- Si nunca fue tocado, activar por default
				end
			end
		else
			wrapper:Hide()
		end
		-- Ajustar altura del contenedor y re-calcular scroll
		local ct = K._moduleContainers and K._moduleContainers["LortiUI"]
		if ct then
			if show then
				ct:SetHeight(ct._baseHeight + subUIHeight)
			else
				ct:SetHeight(ct._baseHeight)
			end
			if K.UpdateModulesScrollHeight then K.UpdateModulesScrollHeight() end
		end
	end

	-- Hook del checkbox padre
	if parentCheckbox then
		local origClick = parentCheckbox:GetScript("OnClick")
		parentCheckbox:SetScript("OnClick", function(self)
			if origClick then origClick(self) end
			local enabled = self:GetChecked() == 1 or self:GetChecked() == true
			SetSubsVisible(enabled)
		end)
	end

	-- Estado inicial
	if K.IsModuleEnabled("LortiUI") then
		wrapper:Show()
	else
		wrapper:Hide()
	end

	return subUIHeight
end

-- =============================================
-- REGISTRO
-- =============================================
K.RegisterModule("LortiUI", {
	name     = "Lorti UI",
	desc     = "Darkens frame textures and styles action bars. Requires /reload to apply changes.",
	default  = false,
	onEnable = Init,
	createUI = CreateLortiSubUI,
})