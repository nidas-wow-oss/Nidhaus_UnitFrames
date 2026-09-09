-- MiniBar — NUF Module
-- Compact action bar layout (half-width main bar, stacked bars, BagPackFrame)
-- Based on FriskesBar logic from FriskesUI by Friskes
-- Integrated into NidhausUnitFrames

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ============================================================
-- Bar stacking config
-- ============================================================
local config = {
	ShapeshiftBar = { offsetX = 20 },
	TotemBar      = { offsetX = 20 },
	LeaveButton   = { offsetX = -36 },
	PetBar        = { offsetX = 60 },
	PossessBar    = { offsetX = 0 },
};

local minibarEnabled = false;
local gridShown = false;
local initTime = 0;
local minibarHooked = false;
local _, playerClass = UnitClass("player");

-- Save/restore state
local mb_savedFrames    = {};  -- { point, rel, relPoint, x, y, width, height }
local mb_savedTextures  = {};  -- { obj, alpha, shown }
local mb_savedTexPaths  = {};  -- { obj, texture } for SetTexture("") cases
local mb_savedManaged   = {};  -- UIPARENT_MANAGED_FRAME_POSITIONS originals

-- ============================================================
-- BagPackFrame texture path (file lives in MiniBar addon folder)
-- ============================================================
local BAGPACK_TEXTURE = "Interface\\AddOns\\"..AddOnName.."\\Modules2\\Textures\\bagpack";

-- ============================================================
-- Shared: Create BagPackFrame (used by both MiniBar and Unify)
-- ============================================================
function K.CreateBagPackFrame()
	if BagPackFrame then
		-- FIX: Re-show frame (gets hidden by DisableMiniBar/DisableUnifyActionBars)
		BagPackFrame:Show();
		if BagPackFrame.texture then
			if C.ShowBagPackTexture == false then BagPackFrame.texture:Hide(); else BagPackFrame.texture:Show(); end
		end
		-- FIX: Always re-apply scale (frame may retain old scale from previous mode)
		-- SU PROPIA ESCALA, no la de las barras (ver MiniBarExtrasScale).
		local scale = C.MiniBarExtrasScale;
		if type(scale) == "number" and scale > 0 then
			BagPackFrame:SetScale(scale);
		end
		return BagPackFrame;
	end

	local XPOS = 107;
	local YPOS = -84.3;

	BagPackFrame = CreateFrame("Frame", "BagPackFrame", UIParent);
	BagPackFrame:SetFrameStrata("BACKGROUND");
	BagPackFrame:SetSize(512, 256);
	BagPackFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", XPOS, YPOS);

	local BagPackTexture = BagPackFrame:CreateTexture(nil, "BACKGROUND");
	BagPackTexture:SetTexture(BAGPACK_TEXTURE);
	BagPackTexture:SetAllPoints(BagPackFrame);
	BagPackFrame.texture = BagPackTexture;

	-- Show/hide TEXTURE only based on config (frame must stay visible for anchoring)
	BagPackFrame:Show();
	if C.ShowBagPackTexture == false then
		BagPackFrame.texture:Hide();
	else
		BagPackFrame.texture:Show();
	end

	-- FIX: Apply saved scale immediately on creation.
	local scale = C.MiniBarExtrasScale;
	if type(scale) == "number" and scale > 0 then
		BagPackFrame:SetScale(scale);
	end

	return BagPackFrame;
end

-- ============================================================
-- Shared: Apply micro menu and bag positions onto BagPackFrame
-- ============================================================
local MicroButtons = {
	"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
	"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
};

function K.ApplyBagPackLayout()
	if not BagPackFrame then return; end
	if InCombatLockdown() then return; end
	if K._applyingBagPack then return; end -- guard against recursion
	K._applyingBagPack = true;

	-- LAS BOLSAS Y EL MICROMENU TIENEN SU PROPIA ESCALA.
	--
	-- Antes esto leia C.ActionBarScale, que es la de las barras de accion.
	-- Ctrl + rueda sobre la barra 1 escribe ese ajuste, asi que agrandar
	-- la barra te agrandaba la mochila (en el acto) y el micromenu (al
	-- soltar, cuando se repintaba). No es lo que uno pide al escalar una
	-- barra de accion.
	--
	-- Ahora van por MiniBarExtrasScale, un valor aparte que arranca en 1.0
	-- y que nadie mueve al escalar barras.
	local abScale = C.MiniBarExtrasScale;
	if type(abScale) ~= "number" or abScale <= 0 then abScale = 1.0; end

	-- Micro buttons → parented to UIParent (need explicit scale)
	for _, name in ipairs(MicroButtons) do
		local btn = _G[name];
		if btn then
			btn:SetParent(UIParent);
			btn:SetFrameStrata("MEDIUM");
			btn:SetScale(abScale);
			btn:Show();
		end
	end

	CharacterMicroButton:ClearAllPoints();
	CharacterMicroButton:SetPoint("CENTER", BagPackFrame, -93.5, -11.8);

	if SocialsMicroButton then
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("BOTTOMLEFT", QuestLogMicroButton, "BOTTOMRIGHT", -3, 0);
	end

	-- NOTE: Do NOT call UpdateMicroButtons() here — it causes infinite recursion
	-- via the hook in ActionBars.lua

	-- LAS BOLSAS SALEN DE MainMenuBar.
	--
	-- Estaban colgadas de MainMenuBarArtFrame, hijo de MainMenuBar, asi que
	-- heredaban su escala por cadena de padres -- el comentario viejo lo
	-- decia. Mientras sigan ahi, cualquier escala sobre la barra principal
	-- se les aplica quiera uno o no.
	--
	-- Pasan a colgar de BagPackFrame, que es hijo de UIParent y ya es el
	-- frame contra el que estaban ancladas. Asi su tamaño lo decide
	-- MiniBarExtrasScale y nada mas.
	for _, n in ipairs({ "MainMenuBarBackpackButton", "CharacterBag0Slot",
	                     "CharacterBag1Slot", "CharacterBag2Slot",
	                     "CharacterBag3Slot", "KeyRingButton" }) do
		local b = _G[n];
		if b then
			b:SetParent(BagPackFrame);
			b:SetFrameStrata("MEDIUM");
		end
	end

	MainMenuBarBackpackButton:SetScale(abScale);
	MainMenuBarBackpackButton:ClearAllPoints();
	MainMenuBarBackpackButton:SetPoint("CENTER", BagPackFrame, 124.8, 21.8);

	CharacterBag0Slot:ClearAllPoints();
	CharacterBag0Slot:SetPoint("CENTER", MainMenuBarBackpackButton, -39, -5.1);
	CharacterBag0Slot:SetScale(0.98);

	CharacterBag1Slot:ClearAllPoints();
	CharacterBag1Slot:SetPoint("CENTER", MainMenuBarBackpackButton, -72.3, -5.1);
	CharacterBag1Slot:SetScale(0.98);

	CharacterBag2Slot:ClearAllPoints();
	CharacterBag2Slot:SetPoint("CENTER", MainMenuBarBackpackButton, -105, -5.1);
	CharacterBag2Slot:SetScale(0.98);

	CharacterBag3Slot:ClearAllPoints();
	CharacterBag3Slot:SetPoint("CENTER", MainMenuBarBackpackButton, -137.9, -5.1);
	CharacterBag3Slot:SetScale(0.98);

	KeyRingButton:ClearAllPoints();
	KeyRingButton:SetPoint("CENTER", MainMenuBarBackpackButton, -177, -5.9);
	KeyRingButton:SetScale(0.91);

	K._applyingBagPack = false;
end

-- ============================================================
-- Shared: Gryphon toggle (works for any action bar mode)
--
-- Offsets de los grifos en modo MiniBar. Van aca arriba y con nombre
-- porque son puro ajuste visual y se tocan a ojo.
-- Los dos se miden desde el borde correspondiente de MainMenuBar: el
-- izquierdo hacia afuera (negativo) y el derecho hacia afuera (positivo).
-- No tienen por que ser simetricos: las dos texturas de grifo no traen
-- el mismo margen interno.
-- ============================================================
local MINIBAR_GRYPHON_LEFT_X  = -30;
local MINIBAR_GRYPHON_RIGHT_X =  35;   -- estaba en 30, corrido un poco mas afuera

-- Modo Unify. El Y no es fijo: sube 5px por cada barra visible (XP y
-- reputacion) y despues resta 5. Con solo la de XP queda en 0, o sea igual
-- que MiniBar; con las dos, 5px mas arriba.
local UNIFY_GRYPHON_LEFT_X    = -30;
-- OJO con las unidades: este numero NO son pixeles de pantalla. El offset de
-- SetPoint va en el espacio del propio grifo, y ese espacio esta escalado a
-- 0.730 (la escala de MainMenuBar). O sea que 3 aca son ~2 px en pantalla.
local UNIFY_GRYPHON_RIGHT_X   = 286;   -- 280 -> 283 -> 286: dos tandas de ~2 px a la derecha
local UNIFY_GRYPHON_Y_BASE    =  -5;
local UNIFY_GRYPHON_Y_PER_BAR =   5;

function K.ApplyGryphons()
	if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then return; end

	-- FIX: antes salia de una si no habia modo de barra activo, asi que
	-- "Hide Gryphons" no hacia NADA con Unify y MiniBar apagados.
	-- Ahora ocultar/mostrar siempre funciona; lo unico que depende del modo
	-- es el reposicionamiento.
	local anyBarMode = K._unifyActive or K._minibarActive;

	if C.HideGryphons then
		MainMenuBarLeftEndCap:Hide();
		MainMenuBarLeftEndCap:SetAlpha(0);
		MainMenuBarRightEndCap:Hide();
		MainMenuBarRightEndCap:SetAlpha(0);
	else
		MainMenuBarLeftEndCap:SetAlpha(1);
		MainMenuBarLeftEndCap:Show();
		MainMenuBarRightEndCap:SetAlpha(1);
		MainMenuBarRightEndCap:Show();
		-- Reposition gryphons based on active mode
		if not anyBarMode then
			-- Sin modo de barra: Blizzard los coloca, no tocamos posicion
		elseif K._unifyActive then
			local yOff = UNIFY_GRYPHON_Y_BASE;
			if MainMenuExpBar and MainMenuExpBar:IsShown() then
				yOff = yOff + UNIFY_GRYPHON_Y_PER_BAR;
			end
			if ReputationWatchBar and ReputationWatchBar:IsShown() then
				yOff = yOff + UNIFY_GRYPHON_Y_PER_BAR;
			end
			MainMenuBarLeftEndCap:ClearAllPoints();
			MainMenuBarRightEndCap:ClearAllPoints();
			MainMenuBarLeftEndCap:SetPoint("BOTTOM", MainMenuBar, "BOTTOMLEFT", UNIFY_GRYPHON_LEFT_X, yOff);
			MainMenuBarRightEndCap:SetPoint("BOTTOM", MainMenuBar, "BOTTOMRIGHT", UNIFY_GRYPHON_RIGHT_X, yOff);
		elseif K._minibarActive then
			-- LOS GRIFOS VAN CON EL ARTE.
			--
			-- El fondo ahora cuelga del contenedor de la fila 1 (mira
			-- PinMainMenuBarToRow1). Anclados a MainMenuBar, los grifos se
			-- quedaban donde Blizzard dejara ese marco, sueltos del resto.
			local gAnchor = _G["MainMenuBarArtFrame"] or MainMenuBar;
			pcall(MainMenuBarLeftEndCap.SetParent,  MainMenuBarLeftEndCap,  gAnchor);
			pcall(MainMenuBarRightEndCap.SetParent, MainMenuBarRightEndCap, gAnchor);
			MainMenuBarLeftEndCap:ClearAllPoints();
			MainMenuBarRightEndCap:ClearAllPoints();
			MainMenuBarLeftEndCap:SetPoint("BOTTOM", gAnchor, "BOTTOMLEFT", MINIBAR_GRYPHON_LEFT_X, 0);
			MainMenuBarRightEndCap:SetPoint("BOTTOM", gAnchor, "BOTTOMRIGHT", MINIBAR_GRYPHON_RIGHT_X, 0);
		end
	end
end

-- ============================================================
-- Shared: Action bar scale (works for any action bar mode)
-- ============================================================
function K.ApplyActionBarScale(scale)
	if InCombatLockdown() then return; end
	if type(scale) ~= "number" or scale <= 0 then scale = 1.0; end

	-- ── CON MINIBAR, LA ESCALA ES DE LOS CONTENEDORES ──
	--
	-- Aca estaba el resto del problema. Esta funcion repartia la escala de
	-- las barras de accion sobre MainMenuBar (padre del arte, las flechas
	-- y, hasta hace poco, las bolsas), sobre BagPackFrame, y sobre
	-- MultiBarRight/Left, que son las barras LATERALES y no tienen nada
	-- que ver con la barra 1. Por eso agrandarla te agrandaba la mochila,
	-- el micromenu y las laterales.
	--
	-- Con MiniBar la escala va a los tres contenedores, que solo tienen
	-- sus 12 botones. MainMenuBar acompaña UNICAMENTE para que su arte
	-- quede del tamaño de la fila 1; ya no cuelgan de el ni las bolsas ni
	-- el micromenu, asi que no arrastra a nadie mas.
	if C.MiniBarEnabled == true then
		K.ApplyBarHolderScales(scale);
		if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end
		return;
	end

	-- Core bars — bags inherit scale from MainMenuBar via parent chain
	if MainMenuBar then MainMenuBar:SetScale(scale); end
	if VehicleMenuBar then VehicleMenuBar:SetScale(scale); end
	if MultiBarBottomRight then MultiBarBottomRight:SetScale(scale); end
	if MultiBarBottomLeft then MultiBarBottomLeft:SetScale(scale); end
	if MultiBarRight then MultiBarRight:SetScale(scale); end
	if MultiBarLeft then MultiBarLeft:SetScale(scale); end
	-- BagPackFrame is parented to UIParent — needs explicit scale
	if BagPackFrame and (K._minibarActive or K._unifyActive) then BagPackFrame:SetScale(scale); end
	-- FIX: Re-apply BagPackLayout for micro buttons (parented to UIParent,
	-- don't inherit MainMenuBar scale). Bags don't need this — they inherit.
	if (K._minibarActive or K._unifyActive) and K.ApplyBagPackLayout then
		K.ApplyBagPackLayout();
	end
end

-- ============================================================
-- Shared: BagPack texture visibility toggle
-- ============================================================
function K.ApplyBagPackTexture()
	if not BagPackFrame or not BagPackFrame.texture then return; end
	if C.ShowBagPackTexture then
		BagPackFrame.texture:Show();
	else
		BagPackFrame.texture:Hide();
	end
end

-- FIX: Helper — ¿algún modo de barra (MiniBar/Unify) está activo?
function K.IsAnyBarModeActive()
	return (K._minibarActive == true) or (K._unifyActive == true);
end

-- ============================================================
-- MiniBar internal: Save/Restore helpers
-- ============================================================
local function MB_SaveFrame(name, frame)
	if not frame or mb_savedFrames[name] then return; end
	local point, rel, relPoint, x, y = frame:GetPoint(1);
	mb_savedFrames[name] = {
		point    = point,
		rel      = rel,
		relPoint = relPoint,
		x        = x or 0,
		y        = y or 0,
		width    = frame.GetWidth  and frame:GetWidth()  or nil,
		height   = frame.GetHeight and frame:GetHeight() or nil,
		-- FIX: También guardar scale (antes no se guardaba, causaba rep bar bug al cambiar modo)
		scale    = frame.GetScale  and frame:GetScale()  or nil,
		-- Y EL PADRE.
		--
		-- Faltaba, y con el arte colgada del contenedor de la fila 1 pasa a
		-- ser imprescindible: sin esto, al apagar MiniBar el marco del
		-- fondo se quedaba colgado de un contenedor escondido.
		parent   = frame.GetParent and frame:GetParent() or nil,
	};
	-- Guardar font si es un FontString
	if frame.GetFont then
		local f, s, fl = frame:GetFont();
		if f then mb_savedFrames[name].font = {f, s, fl}; end
	end
end

local function MB_RestoreFrame(name, frame)
	if not frame then return; end
	local s = mb_savedFrames[name];
	if not s then return; end
	-- El padre ANTES que los anclajes: reparentar borra los puntos.
	if s.parent and frame.SetParent and frame:GetParent() ~= s.parent then
		pcall(frame.SetParent, frame, s.parent);
	end
	frame:ClearAllPoints();
	if s.point then
		frame:SetPoint(s.point, s.rel, s.relPoint, s.x, s.y);
	end
	if s.width  and s.width  > 0 then frame:SetWidth(s.width);   end
	if s.height and s.height > 0 then frame:SetHeight(s.height); end
	-- FIX: Restaurar scale
	if s.scale and frame.SetScale then frame:SetScale(s.scale); end
	-- FIX: Restaurar font si fue guardada
	if s.font and frame.SetFont then frame:SetFont(unpack(s.font)); end
end

local function MB_SaveTexture(obj)
	if not obj then return; end
	table.insert(mb_savedTextures, {
		obj   = obj,
		alpha = obj:GetAlpha(),
		shown = obj:IsShown(),
	});
end

local function MB_SaveTexturePath(obj)
	if not obj then return; end
	table.insert(mb_savedTexPaths, {
		obj     = obj,
		texture = obj:GetTexture(),
	});
end

local function MB_RestoreAllTextures()
	for _, t in ipairs(mb_savedTextures) do
		t.obj:SetAlpha(t.alpha);
		if t.shown then t.obj:Show(); else t.obj:Hide(); end
	end
	for _, t in ipairs(mb_savedTexPaths) do
		t.obj:SetTexture(t.texture);
	end
end

local function MB_CaptureOriginals()
	mb_savedFrames   = {};
	mb_savedTextures = {};
	mb_savedTexPaths = {};
	mb_savedManaged  = {};

	-- Frame positions & sizes
	MB_SaveFrame("MainMenuBar",              MainMenuBar);
	-- MainMenuBarArtFrame NO va en esta lista. MB_SaveFrame guarda UN SOLO
	-- punto de anclaje (GetPoint(1)) y ese marco usa DOS esquinas: asi es
	-- como se estira solo con MainMenuBar. Reponerlo con un unico punto lo
	-- deja con ancho fijo y ya no vuelve a seguir a la barra nunca mas.
	-- Tiene su propia foto, completa: mira MB_SaveArt / K.RestoreArtFrame.
	MB_SaveFrame("MainMenuExpBar",           MainMenuExpBar);
	MB_SaveFrame("ReputationWatchBar",       ReputationWatchBar);
	MB_SaveFrame("MainMenuBarMaxLevelBar",   MainMenuBarMaxLevelBar);
	MB_SaveFrame("ReputationWatchStatusBar", ReputationWatchStatusBar);
	-- FIX: Guardar también los textos de rep y exp (Unify los modifica)
	if ReputationWatchStatusBarText then MB_SaveFrame("ReputationWatchStatusBarText", ReputationWatchStatusBarText); end
	if MainMenuBarExpText then MB_SaveFrame("MainMenuBarExpText", MainMenuBarExpText); end
	if ExhaustionTick then MB_SaveFrame("ExhaustionTick", ExhaustionTick); end
	MB_SaveFrame("MainMenuXPBarTexture0",    MainMenuXPBarTexture0);
	MB_SaveFrame("MainMenuXPBarTexture3",    MainMenuXPBarTexture3);
	MB_SaveFrame("ReputationWatchBarTexture3", ReputationWatchBarTexture3);
	MB_SaveFrame("ReputationXPBarTexture3",  ReputationXPBarTexture3);
	MB_SaveFrame("MainMenuMaxLevelBar0",     MainMenuMaxLevelBar0);
	MB_SaveFrame("MainMenuBarTexture0",      MainMenuBarTexture0);
	MB_SaveFrame("MainMenuBarTexture1",      MainMenuBarTexture1);
	if ActionBarUpButton       then MB_SaveFrame("ActionBarUpButton",       ActionBarUpButton);       end
	if ActionBarDownButton     then MB_SaveFrame("ActionBarDownButton",     ActionBarDownButton);     end
	if MainMenuBarPageNumber   then MB_SaveFrame("MainMenuBarPageNumber",   MainMenuBarPageNumber);   end
	if BonusActionButton1      then MB_SaveFrame("BonusActionButton1",      BonusActionButton1);      end
	if MultiBarBottomRight     then MB_SaveFrame("MultiBarBottomRight",     MultiBarBottomRight);     end
	if ShapeshiftButton1       then MB_SaveFrame("ShapeshiftButton1",       ShapeshiftButton1);       end
	if MultiCastActionBarFrame       then MB_SaveFrame("MultiCastActionBarFrame",       MultiCastActionBarFrame);       end
	if MainMenuBarVehicleLeaveButton then MB_SaveFrame("MainMenuBarVehicleLeaveButton", MainMenuBarVehicleLeaveButton); end
	if PetActionButton1 then MB_SaveFrame("PetActionButton1", PetActionButton1); end
	if PossessButton1   then MB_SaveFrame("PossessButton1",   PossessButton1);   end

	-- FIX: Guardar posicion original de gryphons (Blizzard las posiciona dinamicamente)
	if MainMenuBarLeftEndCap  then MB_SaveFrame("MainMenuBarLeftEndCap",  MainMenuBarLeftEndCap);  end
	if MainMenuBarRightEndCap then MB_SaveFrame("MainMenuBarRightEndCap", MainMenuBarRightEndCap); end

	-- Micro buttons
	local microNames = {
		"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
		"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
		"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
	};
	for _, name in ipairs(microNames) do
		local f = _G[name];
		if f then
			MB_SaveFrame(name, f);
			-- Guardar parent original también
			if not mb_savedFrames[name] then mb_savedFrames[name] = {}; end
			mb_savedFrames[name].parent = f:GetParent();
		end
	end

	-- Bag slots
	MB_SaveFrame("MainMenuBarBackpackButton", MainMenuBarBackpackButton);
	if CharacterBag0Slot then MB_SaveFrame("CharacterBag0Slot", CharacterBag0Slot); mb_savedFrames["CharacterBag0Slot"].scale = CharacterBag0Slot:GetScale(); end
	if CharacterBag1Slot then MB_SaveFrame("CharacterBag1Slot", CharacterBag1Slot); mb_savedFrames["CharacterBag1Slot"].scale = CharacterBag1Slot:GetScale(); end
	if CharacterBag2Slot then MB_SaveFrame("CharacterBag2Slot", CharacterBag2Slot); mb_savedFrames["CharacterBag2Slot"].scale = CharacterBag2Slot:GetScale(); end
	if CharacterBag3Slot then MB_SaveFrame("CharacterBag3Slot", CharacterBag3Slot); mb_savedFrames["CharacterBag3Slot"].scale = CharacterBag3Slot:GetScale(); end
	if KeyRingButton     then MB_SaveFrame("KeyRingButton",     KeyRingButton);     mb_savedFrames["KeyRingButton"].scale     = KeyRingButton:GetScale();     end

	-- Textures that get Hidden
	MB_SaveTexture(MainMenuXPBarTexture1);
	MB_SaveTexture(MainMenuXPBarTexture2);
	MB_SaveTexture(MainMenuBarTexture2);
	MB_SaveTexture(MainMenuBarTexture3);
	MB_SaveTexture(MainMenuMaxLevelBar2);
	MB_SaveTexture(MainMenuMaxLevelBar3);
	MB_SaveTexture(SlidingActionBarTexture0);
	MB_SaveTexture(SlidingActionBarTexture1);
	MB_SaveTexture(ShapeshiftBarLeft);
	MB_SaveTexture(ShapeshiftBarMiddle);
	MB_SaveTexture(ShapeshiftBarRight);
	MB_SaveTexture(PossessBackground1);
	MB_SaveTexture(PossessBackground2);
	if MainMenuBarPageNumber then MB_SaveTexture(MainMenuBarPageNumber); end

	-- Textures that get SetTexture("")
	MB_SaveTexturePath(ReputationWatchBarTexture1);
	MB_SaveTexturePath(ReputationWatchBarTexture2);
	MB_SaveTexturePath(ReputationXPBarTexture1);
	MB_SaveTexturePath(ReputationXPBarTexture2);

	-- UIPARENT_MANAGED_FRAME_POSITIONS entries
	local managedKeys = { "MultiBarBottomRight", "PetActionBarFrame", "ShapeshiftBarFrame", "PossessBarFrame", "MultiCastActionBarFrame", "MAIN_MENUBAR" };
	for _, key in ipairs(managedKeys) do
		mb_savedManaged[key] = UIPARENT_MANAGED_FRAME_POSITIONS[key];
	end
end

-- ============================================================
-- FONDO DE LAS BARRAS DE ACCION
--
-- Es el arte de MainMenuBar: la chapa de fondo y las barras de
-- experiencia y reputacion. El modo MiniBar lo dejaba a la vista; con
-- este interruptor se puede sacar y quedan solo los botones.
--
-- No toca los grifos: esos tienen su propia opcion (Hide Gryphons), y
-- mezclar las dos hacia imposible entender cual apagaba que.
-- ============================================================
local bgTextures;

local function MiniBar_BackgroundTextures()
	if bgTextures then return bgTextures; end
	bgTextures = {};
	local function add(tex)
		if tex and tex.SetAlpha then
			-- FOTO DEL ESTADO QUE LE DEJO MINIBAR.
			--
			-- Aca estaba el bug: al apagar el interruptor yo hacia
			-- Show() + SetAlpha(1) sobre todas, y varias de estas
			-- texturas MiniBar las esconde a proposito. O sea que
			-- "no ocultar el fondo" terminaba REVELANDO arte que
			-- antes no se veia, y aparecia ese marco feo.
			--
			-- Ahora se guarda como estaba y se repone eso mismo.
			table.insert(bgTextures, {
				tex   = tex,
				alpha = tex:GetAlpha(),
				shown = tex:IsShown(),
			});
		end
	end
	for i = 0, 3 do add(_G["MainMenuBarTexture" .. i]); end
	add(MainMenuXPBarTextureLeftCap);
	add(MainMenuXPBarTextureRightCap);
	add(MainMenuXPBarTextureMid);
	for i = 0, 8 do add(_G["ReputationWatchBarTexture" .. i]); end
	return bgTextures;
end

function K.ApplyMiniBarBackground()
	-- Solo manda en modo MiniBar: con el modo unificado el fondo ya lo
	-- maneja ActionBars.lua, y con las barras de Blizzard sin tocar no
	-- somos nadie para esconderle nada.
	if C.MiniBarEnabled ~= true then return; end

	local ocultar = (C.MiniBarHideBackground == true);
	for _, e in ipairs(MiniBar_BackgroundTextures()) do
		if ocultar then
			e.tex:Hide();
			e.tex:SetAlpha(0);
		else
			-- Se repone EXACTAMENTE como estaba, no "visible del todo".
			e.tex:SetAlpha(e.alpha);
			if e.shown then e.tex:Show(); else e.tex:Hide(); end
		end
	end
end

-- ============================================================
-- MiniBar internal: MakeInvisible helper
-- ============================================================
local function MakeInvisible(frame)
	if not frame then return; end
	frame:Hide();
	frame:SetAlpha(0);
end

-- ============================================================
-- MiniBar internal: UpdateActionBars (stack bars vertically)
-- ============================================================
-- SEPARACION ENTRE FILAS
--
-- La primera tecla de cada fila se ancla a la primera de la fila de
-- abajo con la MISMA distancia que se usa entre botones vecinos:
--
--     b:SetPoint("BOTTOM", ActionButton1, "TOP", 0, ButtonSpace)
--
-- Antes esta separacion vertical estaba fija en 4 pixeles, asi que el
-- slider "Separacion entre botones" abria los botones a lo ancho pero
-- las filas quedaban siempre igual de pegadas. Ahora el mismo numero
-- vale para los dos ejes.
local function RowGap()
	local v = tonumber(C.ActionBarButtonSpace);
	if not v or v < 0 then v = 6; end
	return v;
end

-- Se expone para que el slider de separacion entre botones pueda volver
-- a apilar las filas sin recargar: la distancia vertical sale del mismo
-- numero (ver RowGap).
local MiniBar_UpdateActionBars;

function K.RefreshMiniBarLayout(force)
	if C.MiniBarEnabled ~= true then return; end
	if InCombatLockdown() then return; end
	if MiniBar_UpdateActionBars then MiniBar_UpdateActionBars(force); end
end

-- Las cosas que MiniBar apila, de abajo hacia arriba, y la clave con la
-- que cada una se guarda en "Move Everything". La usan el aplanado y el
-- pin de hermanas.
local MB_STACK = {
	{ frame = "NUF_ActionBarHolder1",         key = "MainBar"     },
	{ frame = "NUF_ActionBarHolder2",         key = "ActionBar2"  },
	{ frame = "NUF_ActionBarHolder3",         key = "ActionBar3"  },
	{ frame = "NUF_StanceBarHolder",          key = "StanceBar"   },
	{ frame = "MultiCastActionBarFrame",      key = "TotemBar"    },
	{ frame = "MainMenuBarVehicleLeaveButton" },
	{ frame = "PetActionButton1",             key = "PetBar"      },
	{ frame = "PossessButton1",               key = "PossessBar"  },
};

-- ============================================================
-- APLANAR LA PILA
--
-- EL PROBLEMA DE FONDO. MiniBar apila con anclajes RELATIVOS: la fila 3
-- se ancla a la 2, la 2 a la 1, y postura/totem/mascota a la ultima. En
-- WoW un anclaje relativo es un vinculo VIVO y permanente: si el frame de
-- referencia se mueve, el otro se mueve con el para siempre.
--
-- Por eso arrastrar la fila 1 se llevaba las tres, la 2 se llevaba la 3, y
-- la 3 se llevaba la barra de auras. No era el guardado: era el anclaje.
--
-- Las guardas de HasGlobalPos no alcanzaban, y conviene entender por que:
-- solo evitan RE-anclar en el proximo repintado. No cortan el vinculo que
-- ya esta puesto, y en el primer arrastre todavia no hay nada guardado que
-- mirar.
--
-- LA SOLUCION es cortar el vinculo: cada elemento pasa a estar anclado a
-- UIParent en coordenadas absolutas, en el mismo lugar donde ya se ve. A
-- ojo no cambia nada; por dentro deja de haber cadena.
--
-- Se hace al ENCENDER el modo mover, que es el unico momento en que la
-- cadena estorba. Fuera de ese modo la cadena es justamente lo que arma la
-- pila por defecto, asi que se la deja en paz.
-- ============================================================
local function MB_ToUIParent(frame)
	local l, b = frame:GetLeft(), frame:GetBottom();
	if not l or not b then return nil; end

	-- SIN CONVERSION DE ESCALA. Y esto es contraintuitivo, asi que va
	-- escrito para no volver a equivocarse:
	--
	--   GetLeft() devuelve en las coordenadas DEL PROPIO FRAME, o sea
	--   pixeles de pantalla divididos por SU escala efectiva.
	--
	--   Los offsets de SetPoint se miden TAMBIEN en las coordenadas del
	--   propio frame: la pantalla sale de multiplicarlos por esa misma
	--   escala.
	--
	-- Las dos divisiones son la misma, asi que se cancelan: para dejar el
	-- frame donde ya esta, el offset contra UIParent es GetLeft() tal cual.
	--
	-- Yo habia metido una conversion multiplicando por la escala del frame
	-- y dividiendo por la de UIParent. Con ActionBarScale en 1 no se
	-- notaba, pero apenas agrandabas una barra con Ctrl + rueda las dos
	-- escalas dejaban de coincidir y al abrir "Move Everything" las barras
	-- saltaban: parecia que se olvidaba la escala, y en realidad era este
	-- factor de mas.
	--
	-- Es ademas la convencion del resto del addon: SavePosition guarda con
	-- GetLeft() crudo y funciona.
	return l, b;
end

-- Posicion y alto de un frame EN PIXELES DE PANTALLA.
--
-- Hace falta cuando se apila un frame sobre otro que puede tener OTRA
-- escala -- que es justo lo que pasa desde que cada fila tiene la suya.
-- Comparar GetLeft() entre dos frames de escalas distintas es comparar
-- unidades distintas.
local function MB_ScreenPos(frame)
	local l, b = frame:GetLeft(), frame:GetBottom();
	if not l or not b then return nil; end
	local s = frame:GetEffectiveScale() or 1;
	return l * s, b * s, (frame:GetHeight() or 30) * s;
end

-- Deja el frame en esa posicion de pantalla, anclado a UIParent.
-- El offset se divide por SU escala, porque SetPoint mide en el espacio
-- del propio frame.
local function MB_PlaceAtScreen(frame, sx, sy)
	local s = frame:GetEffectiveScale() or 1;
	if s == 0 then return; end
	frame:ClearAllPoints();
	frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", sx / s, sy / s);
end

function K.MiniBarDetachStack()
	if not minibarEnabled then return; end
	-- Frames protegidos: mover o desanclar en combate contamina.
	if InCombatLockdown() then return; end

	for _, item in ipairs(MB_STACK) do
		local f = _G[item.frame];
		if f and f:IsShown() then
			local x, y = MB_ToUIParent(f);
			if x then
				f:ClearAllPoints();
				f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y);
			end
		end
	end
end

-- Para que GlobalUnlock sepa que hay pila que aplanar sin conocer MiniBar.
-- ============================================================
-- RESET: TODO EL MINIBAR A SU LUGAR ORIGINAL
--
-- Borrar las posiciones guardadas no alcanza. Al abrir el modo mover la
-- pila se APLANA -- cada cosa pasa a estar anclada a UIParent en
-- coordenadas absolutas -- y el arrastre encima las deja donde las
-- soltaste. Sin deshacer las dos cosas, el reset borraba datos y en
-- pantalla no se movia nada.
--
-- Aca se rehace desde cero: escalas a la de fabrica, y un reacomodo
-- forzado que vuelve a encadenar la pila entera porque ya no hay ninguna
-- posicion propia que respetar.
-- ============================================================
-- LA ESCALA DE CADA FILA.
--
-- El valor que llega es el GENERAL, el del slider del panel. Pero si una
-- fila tiene escala propia -- puesta con Ctrl + rueda sobre ella -- manda
-- la suya: para eso se la puso el usuario.
--
-- Sin esto, escalar la barra 1 con la rueda terminaba aplicandole el mismo
-- numero a las tres en el siguiente repintado.
local BAR_KEYS = { "MainBar", "ActionBar2", "ActionBar3" };

-- ---------------------------------------------------------
-- EL ARTE DE LA FILA 1 VA PEGADO A LA FILA 1.
--
-- MainMenuBar es el marco del que cuelga el FONDO: la barra oscura y los
-- dos grifos. Los botones ya no viven ahi -- estan en NUF_ActionBarHolder1
-- --, asi que lo unico que falta es que el marco siga al contenedor.
--
-- Se escribe en UN solo lugar y se puede volver a pedir cuando haga falta.
-- Lo pide ApplyBarHolderScales despues de cambiar escalas, y lo pide el
-- enganche de UIParent_ManageFramePositions.
--
-- Esa segunda llamada es la receta de MiniMainBar: ese addon no discute
-- con el gestor de posiciones de Blizzard, se cuelga de el y vuelve a
-- aplicar lo suyo cada vez que corre. Blizzard reacomoda seguido y por
-- motivos que no controlamos -- abrir una bolsa, montar, un vehiculo --,
-- asi que no alcanza con acomodar una vez: hay que ir siempre despues.
-- ---------------------------------------------------------
-- ---------------------------------------------------------
-- LA FOTO DEL MARCO DEL ARTE
--
-- POR QUE NECESITA UNA APARTE.
--
-- MainMenuBarArtFrame no se posiciona con un punto: se ESTIRA entre dos
-- esquinas de MainMenuBar. Por eso el addon viejo podia hacer
-- MainMenuBar:SetWidth(512) y listo -- el arte se achicaba sola -- y por
-- eso nunca hubo problema al alternar modos.
--
-- Cuando lo cuelgo del contenedor de la fila 1 le rompo ese par de
-- anclajes. Si despues lo repongo con uno solo, el marco queda con ancho
-- fijo y NO vuelve a seguir a la barra: ese es el pedazo de barra suelto
-- que aparecia al apagar MiniBar.
--
-- Asi que la foto se saca ANTES de tocarlo y se guardan TODOS los puntos.
-- ---------------------------------------------------------
local artOrig = nil;

local function MB_SaveArt(art)
	if artOrig or not art then return; end
	local pts = {};
	for i = 1, (art:GetNumPoints() or 0) do
		local p, rel, rp, x, y = art:GetPoint(i);
		if p then pts[#pts + 1] = { p, rel, rp, x or 0, y or 0 }; end
	end
	artOrig = {
		parent = art:GetParent(),
		points = pts,
		width  = art:GetWidth(),
	};
end

function K.RestoreArtFrame()
	local art = _G["MainMenuBarArtFrame"];
	if not art or not artOrig then return; end
	if InCombatLockdown() then return; end

	if artOrig.parent and art:GetParent() ~= artOrig.parent then
		pcall(art.SetParent, art, artOrig.parent);
	end

	art:ClearAllPoints();
	for _, p in ipairs(artOrig.points) do
		pcall(art.SetPoint, art, p[1], p[2], p[3], p[4], p[5]);
	end

	-- El ancho SOLO si tenia un unico anclaje. Con dos esquinas el tamaño
	-- lo manda el anclaje, y escribirlo a mano volveria a romperlo.
	if #artOrig.points < 2 and artOrig.width and artOrig.width > 0 then
		art:SetWidth(artOrig.width);
	end

	artOrig = nil;
end

function K.PinMainMenuBarToRow1()
	if C.MiniBarEnabled ~= true then return; end

	-- Con MiniBar puesto esta barra es nuestra. Es una marca, no una
	-- posicion, asi que se escribe tambien en combate.
	if MainMenuBar then MainMenuBar.ignoreFramePositionManager = true; end

	-- Reparentar toca marcos: en combate, no.
	if InCombatLockdown() then return; end

	local h1  = K.GetBarHolder and K.GetBarHolder(1);
	local art = _G["MainMenuBarArtFrame"];
	if not h1 or not art then return; end

	-- =====================================================
	-- EL FONDO ES HIJO DE LA FILA 1. NO SE ANCLA: SE CUELGA.
	--
	-- Vengo arreglando esto por anclaje y vuelve una y otra vez, siempre
	-- por el mismo motivo: un anclaje es un dato que ALGUIEN MAS PUEDE
	-- PISAR. Lo piso el gestor de posiciones de Blizzard, lo piso un
	-- SetPoint viejo que habia quedado en EnableMiniBar, lo pisaba yo con
	-- un inset heredado, y cuando no lo pisaba nadie no se podia reponer
	-- porque estabamos en combate.
	--
	-- Ser HIJO no es un dato: es una relacion. Un marco hijo sigue a su
	-- padre en posicion, en escala y en visibilidad, siempre, sin que
	-- nadie tenga que reponer nada y sin que nadie pueda quitarselo con un
	-- SetPoint. No hay repintado que valga, ni /reload, ni combate.
	--
	-- Es lo mismo que hace MiniMainBar: una sola familia de marcos.
	--
	-- MainMenuBar deja de importar para el fondo. Sigue existiendo como
	-- padre de la barra de experiencia y la de reputacion, y que Blizzard
	-- la mande donde quiera: el arte ya no esta ahi.
	-- =====================================================
	if art:GetParent() ~= h1 then
		-- La foto ANTES de tocarlo, una sola vez.
		MB_SaveArt(art);
		art:SetParent(h1);
		art:SetFrameStrata("MEDIUM");
		-- Un nivel POR DEBAJO del contenedor, para que el arte quede
		-- detras de los botones y no encima.
		art:SetFrameLevel(math.max(0, (h1:GetFrameLevel() or 1) - 1));
	end

	art:ClearAllPoints();
	art:SetPoint("BOTTOMLEFT", h1, "BOTTOMLEFT", 0, 0);

	-- Y con el ancho de la barra, no con el de fabrica: MiniBar la achica a
	-- 512 y las dos mitades del fondo se cuelgan del CENTRO del ArtFrame,
	-- asi que en 1024 el arte se dibujaba corrida a la derecha.
	if art.SetWidth and (art:GetWidth() or 0) ~= 512 then art:SetWidth(512); end
end


-- ---------------------------------------------------------
-- LA ESCALA DE LAS TRES FILAS
--
-- El valor que llega es el GENERAL, el del slider del panel. Pero si una
-- fila tiene escala propia -- puesta con Ctrl + rueda sobre ella -- manda
-- la suya: para eso se la puso el usuario.
--
-- Sin esto, escalar la barra 1 con la rueda terminaba aplicandole el mismo
-- numero a las tres en el siguiente repintado.
-- ---------------------------------------------------------
function K.ApplyBarHolderScales(scale)
	if type(scale) ~= "number" or scale <= 0 then scale = 1.0; end

	local firstScale = scale;
	for row = 1, 3 do
		local h = K.GetBarHolder and K.GetBarHolder(row);
		if h then
			local own = K.GetGlobalScale and K.GetGlobalScale(BAR_KEYS[row]);
			local use = (type(own) == "number" and own > 0) and own or scale;
			h:SetScale(use);
			if row == 1 then firstScale = use; end
		end
	end

	if not MainMenuBar then return; end

	-- MainMenuBar sigue a la FILA 1. Ya no por el arte -- esa cuelga del
	-- contenedor y hereda su escala sola -- sino porque de MainMenuBar
	-- todavia cuelgan la barra de experiencia y la de reputacion.
	MainMenuBar:SetScale(firstScale);

	-- Y el arte se asegura de estar colgada donde va.
	K.PinMainMenuBarToRow1();
end

function K.ResetMiniBarLayout()
	if C.MiniBarEnabled ~= true then return; end
	if InCombatLockdown() then return; end

	local scale = (K.GetConfigDefault and K.GetConfigDefault("ActionBarScale")) or 1.0;

	for row = 1, 3 do
		local h = K.GetBarHolder and K.GetBarHolder(row);
		if h then
			h:SetScale(scale);
			h:ClearAllPoints();
		end
	end

	if MainMenuBar then MainMenuBar:SetScale(scale); end
	-- Las escalas propias ya se borraron con globalPos, asi que las tres
	-- vuelven a la general.

	-- Lo que se apila encima tambien quedo suelto por el aplanado.
	for _, item in ipairs(MB_STACK) do
		local f = _G[item.frame];
		if f then
			f:SetScale(scale);
			f:ClearAllPoints();
		end
	end

	-- Y ahora si, la pila se rearma sola. force = true porque el reset se
	-- aprieta con el modo mover abierto.
	MiniBar_UpdateActionBars(true);

	-- Y el arte se vuelve a pegar a la fila 1. Recien aca, con los
	-- contenedores ya colocados: pegarlo antes seria pegarlo a una
	-- posicion que todavia no existe.
	K.PinMainMenuBarToRow1();
end

function K.MiniBarStackKeys()
	local out = {};
	for _, item in ipairs(MB_STACK) do
		if item.key then out[#out + 1] = item.key; end
	end
	return out;
end

function MiniBar_UpdateActionBars(force)
	-- CON EL MODO MOVER ENCENDIDO, NO SE RE-ARMA NADA.
	--
	-- Estas arrastrando; re-anclar por debajo te mueve las barras solas.
	-- Es lo que pasaba al apretar Shift+Alt en medio de un arrastre: el
	-- otro sistema de movimiento disparaba UIParent_ManageFramePositions,
	-- eso llamaba aca, y la barra de auras volvia de un salto a la pila.
	--
	-- Salvo que se pida a proposito (force): el boton Reset se aprieta
	-- justamente con el modo abierto, y sin esto no reacomodaba nada --
	-- era la razon por la que la barra de auras quedaba en cualquier lado
	-- despues de resetear.
	if (not force) and K.IsGlobalUnlocked and K.IsGlobalUnlocked() then return; end

	-- El Holder de posturas tiene que EXISTIR antes de anclarlo.
	--
	-- Estaba solo en el camino de Unify: MiniBar llamaba a
	-- DetachStanceButtons al apagarse pero nunca a Attach al encenderse.
	-- Por eso NUF_StanceBarHolder no existia en MiniBar, la entrada
	-- "Stance Bar" del modo mover no encontraba frame y la barra de auras
	-- del paladin no se podia mover -- justo lo que si funciona en Unify.
	-- Es idempotente: reancla los mismos botones al mismo Holder.
	if K.AttachStanceButtons then K.AttachStanceButtons(); end

	-- Y las tres filas a SUS contenedores (ver el comentario largo en
	-- Modules/ActionBars.lua). Es lo que hace que escalar una barra no
	-- toque las bolsas ni el micromenu.
	if K.AttachActionBarButtons then K.AttachActionBarButtons(); end

	-- Las escalas ANTES de posicionar: los offsets de SetPoint se miden en
	-- la escala del propio frame, asi que cambiarla despues correria las
	-- filas de lugar.
	if K.ApplyBarHolderScales then
		K.ApplyBarHolderScales(C.ActionBarScale or 1.0);
	end

	local anchor;
	local anchorOffset = RowGap();
	local repOffset = 0;

	if MainMenuExpBar:IsShown() then
		repOffset = 5;
		if ReputationWatchBar:IsShown() then
			repOffset = 9;
		end
	end

	if ReputationWatchBar:IsShown() then
		repOffset = repOffset + 5;
	end

	-- UNA FILA QUE MOVISTE A MANO SALE DE LA PILA.
	--
	-- MiniBar apila las tres: la 3 encima de la 2, la 2 encima de la 1, y
	-- lo que va arriba (postura, mascota, totem) se cuelga de la ultima.
	-- Si arrastraste una a otro lado y siguieramos usandola de referencia,
	-- todo eso la seguiria hasta alla.
	--
	-- Es la misma regla que ya usa la barra de posturas: con posicion
	-- guardada manda la tuya y el modulo no la toca.
	-- LAS TRES FILAS, CADA UNA EN SU CONTENEDOR.
	--
	-- Antes se apilaban los frames de Blizzard. Ahora se apilan los
	-- contenedores, que es lo unico que se mueve y se escala; los botones
	-- cuelgan de ellos. Una fila con posicion propia sale de la pila y no
	-- sirve de referencia para las de arriba.
	local h1 = K.GetBarHolder and K.GetBarHolder(1);
	local h2 = K.GetBarHolder and K.GetBarHolder(2);
	local h3 = K.GetBarHolder and K.GetBarHolder(3);

	if h1 and not (K.HasGlobalPos and K.HasGlobalPos("MainBar")) then
		if K.BarHolderDefaultPoint then K.BarHolderDefaultPoint(1); end
	end

	-- EL FONDO SIGUE A LA FILA 1, EN TIEMPO REAL.
	--
	-- MainMenuBar es el marco cuyo arte se ve como fondo de la barra, y
	-- cuelga DEL CONTENEDOR: es un anclaje vivo, asi que el fondo acompaña
	-- mientras arrastras, sin codigo extra.
	--
	-- El anclaje NO se escribe aca: lo hace ApplyBarHolderScales, que ya
	-- corrio unas lineas mas arriba. Tiene que ir junto al SetScale porque
	-- el desplazamiento se mide en la escala de MainMenuBar, y separarlos
	-- era lo que desfasaba el fondo al recargar con la barra agrandada.

	-- Sin segunda fila, la primera queda pegada a las barras de
	-- experiencia y reputacion: ahi hace falta despegarla un poco mas.
	anchor = h1 or ActionButton1;
	anchorOffset = RowGap() + 6 + repOffset;

	-- LA PILA SE CALCULA, NO SE ENCADENA.
	--
	-- Aca volvi a meter la pata: al pasar a contenedores los apile otra vez
	-- con SetPoint contra el de abajo. En WoW eso es un vinculo VIVO, asi
	-- que mover la fila 1 se llevaba la 2 y la 3 para siempre.
	--
	-- Ahora se calcula: se mide donde termina la fila de abajo EN PIXELES
	-- DE PANTALLA y se coloca la siguiente ahi arriba, anclada a UIParent.
	-- Queda igual a la vista y no hay ningun vinculo que arrastre.
	--
	-- En pixeles de pantalla y no en GetLeft() crudo porque cada fila puede
	-- tener SU escala: comparar coordenadas de frames con escalas distintas
	-- es comparar unidades distintas.
	-- LA X SALE SIEMPRE DE LA MISMA BASE.
	--
	-- Encadenar tambien la horizontal -- medir la fila 2 para colocar la 3
	-- -- acumulaba el redondeo de dividir y multiplicar por escalas, y las
	-- filas quedaban corridas un par de pixeles cada una. Con una sola
	-- base no hay nada que acumular: las tres arrancan alineadas.
	--
	-- La vertical si se encadena, que es lo que hace que sea una pila.
	local baseX, sy, sh = MB_ScreenPos(anchor);
	local gapScale = (UIParent:GetEffectiveScale() or 1);

	if h2 and MultiBarBottomLeft:IsShown()
	   and not (K.HasGlobalPos and K.HasGlobalPos("ActionBar2")) then
		if baseX then
			MB_PlaceAtScreen(h2, baseX, sy + sh + (anchorOffset * gapScale));
			local _, y2, h2h = MB_ScreenPos(h2);
			sy, sh = y2 or sy, h2h or sh;
			anchorOffset = RowGap();
		end
		anchor = h2;
	end

	if h3 and MultiBarBottomRight:IsShown()
	   and not (K.HasGlobalPos and K.HasGlobalPos("ActionBar3")) then
		if baseX then
			MB_PlaceAtScreen(h3, baseX, sy + sh + (anchorOffset * gapScale));
			local _, y3, h3h = MB_ScreenPos(h3);
			sy, sh = y3 or sy, h3h or sh;
			anchorOffset = RowGap();
		end
		anchor = h3;
	end

	-- Posturas / auras / presencias / Shadowform.
	--
	-- Se ancla el HOLDER, no ShapeshiftButton1. El Holder es nuestro, los
	-- botones cuelgan de el (K.AttachStanceButtons) y es lo que apunta la
	-- entrada "Stance Bar" del modo mover: anclando el boton, el Holder
	-- quedaba vacio de sentido y la barra no se podia mover.
	local stanceHolder = _G["NUF_StanceBarHolder"];
	local stanceTarget = stanceHolder or ShapeshiftButton1;
	if stanceTarget and ShapeshiftButton1 and ShapeshiftButton1:IsShown()
	   and not (K.HasGlobalPos and K.HasGlobalPos("StanceBar")) then
		stanceTarget:ClearAllPoints();
		local shapeshiftOffsetX = (playerClass == "DEATHKNIGHT") and -10 or config.ShapeshiftBar.offsetX;
		stanceTarget:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", shapeshiftOffsetX, anchorOffset - 0.5);
	end

	-- Totem bar
	if MultiCastActionBarFrame and MultiCastActionBarFrame:IsShown()
	   and not (K.HasGlobalPos and K.HasGlobalPos("TotemBar")) then
		MultiCastActionBarFrame:ClearAllPoints();
		MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.TotemBar.offsetX, anchorOffset - 1.5);
		anchor = MultiCastActionBarFrame;
		anchorOffset = RowGap();
	end

	-- Vehicle leave button
	if MainMenuBarVehicleLeaveButton and MainMenuBarVehicleLeaveButton:IsShown() then
		MainMenuBarVehicleLeaveButton:ClearAllPoints();
		MainMenuBarVehicleLeaveButton:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.LeaveButton.offsetX, anchorOffset);
		anchor = MainMenuBarVehicleLeaveButton;
		anchorOffset = 4;
	end

	-- Mascota (para DK va más a la derecha para no tapar las presencias).
	--
	-- Movida a mano, los botones pasan a colgar de SU PROPIO marco, que es
	-- el que arrastras. Si siguieran colgando de la pila, mover PetBar no
	-- haria nada visible.
	if PetActionButton1 then
		PetActionButton1:ClearAllPoints();
		if K.HasGlobalPos and K.HasGlobalPos("PetBar") and PetActionBarFrame then
			PetActionButton1:SetPoint("BOTTOMLEFT", PetActionBarFrame, "BOTTOMLEFT", 0, 0);
		else
			local petOffsetX = (playerClass == "DEATHKNIGHT") and 130 or config.PetBar.offsetX;
			PetActionButton1:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", petOffsetX, anchorOffset - 0.5);
		end
	end

	-- Possess bar
	if PossessButton1 then
		PossessButton1:ClearAllPoints();
		if K.HasGlobalPos and K.HasGlobalPos("PossessBar") and PossessBarFrame then
			PossessButton1:SetPoint("BOTTOMLEFT", PossessBarFrame, "BOTTOMLEFT", 0, 0);
		else
			PossessButton1:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.PossessBar.offsetX, anchorOffset - 0.5);
		end
	end
end

-- ============================================================
-- MiniBar internal: UpdateUI (main layout refresh)
-- ============================================================
local function MiniBar_UpdateUI()
	if InCombatLockdown() then return; end
	if not minibarEnabled then return; end

	-- FIX: Check vehicle state — hide BagPackFrame and skip layout during vehicle
	local inVehicle = UnitInVehicle and UnitInVehicle("player");
	if inVehicle then
		if BagPackFrame then BagPackFrame:Hide(); end
		return;
	end

	-- FIX: Re-enforce MainMenuBar at y=0 AND width=512
	-- UIParent_ManageFramePositions and vehicle exit can reset both.
	--
	-- SALVO QUE VOS LA HAYAS MOVIDO. Este reancle existe porque Blizzard y
	-- la salida de vehiculo devuelven la barra al centro; pero corriendo
	-- siempre, tambien pisaba la posicion que elegiste y la barra 1 volvia
	-- sola al medio. Con posicion guardada, o con el modo mover encendido
	-- (que es cuando la estas arrastrando), no se toca.
	--
	-- El ancho SI se reafirma siempre: no es posicion, y si se pierde la
	-- barra se dibuja partida.
	-- LA POSICION DE MainMenuBar YA NO SE DECIDE ACA.
	--
	-- La manda el contenedor de la fila 1, del que cuelga (ver
	-- MiniBar_UpdateActionBars). Reanclarla aca la arrancaba de ahi en
	-- cada repintado y el fondo se despegaba de la barra.
	--
	-- El ancho SI se reafirma: no es posicion, y si se pierde el arte se
	-- dibuja partido.
	MainMenuBar:SetWidth(512);

	MakeInvisible(SlidingActionBarTexture0);
	MakeInvisible(SlidingActionBarTexture1);
	MakeInvisible(ShapeshiftBarLeft);
	MakeInvisible(ShapeshiftBarMiddle);
	MakeInvisible(ShapeshiftBarRight);
	MakeInvisible(PossessBackground1);
	MakeInvisible(PossessBackground2);

	MiniBar_UpdateActionBars();

	-- Fondo de las barras segun el interruptor del panel.
	if K.ApplyMiniBarBackground then K.ApplyMiniBarBackground(); end

	-- Apply shared scale
	K.ApplyActionBarScale(C.ActionBarScale or 1.0);
end

-- ============================================================
-- MiniBar internal: Event handler
-- ============================================================
local function MiniBar_OnEvent(self, event, unit)
	if not minibarEnabled then return; end
	if event == "ACTIONBAR_SHOWGRID" then
		gridShown = true;
	elseif event == "ACTIONBAR_HIDEGRID" then
		gridShown = false;
	elseif event == "UNIT_ENTERED_VEHICLE" and unit == "player" then
		-- FIX: Hide BagPackFrame during vehicle (Blizzard uses VehicleMenuBar)
		if BagPackFrame then BagPackFrame:Hide(); end
		-- FIX: Reparent micro buttons to UIParent during vehicle.
		-- MainMenuBar gets hidden -> MainMenuBarArtFrame hidden -> micro buttons vanish.
		for _, name in ipairs(MicroButtons) do
			local btn = _G[name];
			if btn then btn:SetParent(UIParent); end
		end
		MiniBar_UpdateUI();
	elseif event == "UNIT_EXITED_VEHICLE" and unit == "player" then
		-- FIX: Restore BagPackFrame and full layout after vehicle exit
		if BagPackFrame then BagPackFrame:Show(); end
		-- FIX: Reparent micro buttons back to UIParent (not MainMenuBarArtFrame)
		for _, name in ipairs(MicroButtons) do
			local btn = _G[name];
			if btn then
				btn:SetParent(UIParent);
				btn:SetFrameStrata("MEDIUM");
			end
		end
		if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end
		-- Re-enforce bar width (Blizzard may reset to 1024 on vehicle exit)
		MainMenuBar:SetWidth(512);
		MainMenuExpBar:SetWidth(512);
		ReputationWatchBar:SetWidth(512);
		MainMenuBarMaxLevelBar:SetWidth(512);
		ReputationWatchStatusBar:SetWidth(512);
		-- Hide right-side art (Blizzard may re-show on vehicle exit)
		MainMenuXPBarTexture1:Hide();
		MainMenuXPBarTexture2:Hide();
		MainMenuBarTexture2:Hide();
		MainMenuBarTexture3:Hide();
		MainMenuMaxLevelBar2:Hide();
		MainMenuMaxLevelBar3:Hide();
		MiniBar_UpdateUI();
		-- Delayed retry: Blizzard may reset layout after a short delay
		if not self._vehicleRetryFrame then self._vehicleRetryFrame = CreateFrame("Frame"); end
		local vrf = self._vehicleRetryFrame;
		vrf._elapsed = 0;
		vrf._count = 0;
		vrf:SetScript("OnUpdate", function(s, dt)
			s._elapsed = s._elapsed + dt;
			if s._elapsed >= 0.3 then
				s._elapsed = 0;
				s._count = s._count + 1;
				if not InCombatLockdown() and minibarEnabled then
					MainMenuBar:SetWidth(512);
					MainMenuExpBar:SetWidth(512);
					ReputationWatchBar:SetWidth(512);
					MainMenuBarMaxLevelBar:SetWidth(512);
					ReputationWatchStatusBar:SetWidth(512);
					MainMenuXPBarTexture1:Hide();
					MainMenuXPBarTexture2:Hide();
					MainMenuBarTexture2:Hide();
					MainMenuBarTexture3:Hide();
					MainMenuMaxLevelBar2:Hide();
					MainMenuMaxLevelBar3:Hide();
					MiniBar_UpdateUI();
					if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end
					if K.ApplyGryphons then K.ApplyGryphons(); end
				end
				if s._count >= 5 then s:SetScript("OnUpdate", nil); end
			end
		end);
	elseif event == "PLAYER_ENTERING_WORLD" then
		initTime = GetTime();
		self:SetScript("OnUpdate", function(s)
			if GetTime() > initTime + 5 then
				s:SetScript("OnUpdate", nil);
			end
			MiniBar_UpdateUI();
		end);
	else
		MiniBar_UpdateUI();
	end
end

-- ============================================================
-- MiniBar internal: VehicleMenuBar hook for micro buttons
-- ============================================================
local function MiniBar_VehicleMicroHook(skinName)
	if not minibarEnabled then return; end
	if not BagPackFrame then return; end

	local microBtns = {
		CharacterMicroButton, SpellbookMicroButton, TalentMicroButton,
		AchievementMicroButton, QuestLogMicroButton, SocialsMicroButton,
		PVPMicroButton, LFDMicroButton, MainMenuMicroButton, HelpMicroButton,
	};

	if not skinName then
		for _, frame in pairs(microBtns) do
			frame:SetParent(UIParent);
			frame:SetFrameStrata("MEDIUM");
			frame:Show();
		end
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("CENTER", BagPackFrame, -93.5, -11.8);
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("BOTTOMLEFT", QuestLogMicroButton, "BOTTOMRIGHT", -3, 0);
		-- UpdateMicroButtons removed: handled by hooks
	elseif skinName == "Mechanical" then
		for _, frame in pairs(microBtns) do
			frame:SetParent(VehicleMenuBarArtFrame);
			frame:Show();
		end
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("BOTTOMLEFT", VehicleMenuBar, "BOTTOMRIGHT", -340, 41);
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("TOPLEFT", CharacterMicroButton, "BOTTOMLEFT", 0, 20);
		-- UpdateMicroButtons removed: handled by hooks
	elseif skinName == "Natural" then
		for _, frame in pairs(microBtns) do
			frame:SetParent(VehicleMenuBarArtFrame);
			frame:Show();
		end
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("BOTTOMLEFT", VehicleMenuBar, "BOTTOMRIGHT", -365, 41);
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("TOPLEFT", CharacterMicroButton, "BOTTOMLEFT", 0, 20);
		-- UpdateMicroButtons removed: handled by hooks
	end
end

-- ============================================================
-- MiniBar Event Frame (always exists, but events only when enabled)
-- ============================================================
local minibarEvtFrame = CreateFrame("Frame", "NidhausMiniBarFrame", UIParent);

-- ============================================================
-- ENABLE MiniBar
-- ============================================================
function K.EnableMiniBar()
	-- Foto de los botones ANTES de acomodar nada: MiniBar reancla
	-- ShapeshiftButton1 y el espaciado reancla el resto. Sin esta
	-- captura previa, al apagar el modo se restauraria la posicion
	-- del propio modo en vez de la de Blizzard.
	if K.CaptureAllActionButtons then K.CaptureAllActionButtons(); end

	if minibarEnabled then return; end
	if InCombatLockdown() then return; end

	-- Unify y MiniBar son excluyentes. Si el otro esta puesto hay que
	-- apagarlo ANTES de fotografiar nada, o la foto sale contaminada.
	if K._unifyActive and K.DisableUnifyActionBars then
		K.DisableUnifyActionBars();
	end

	-- Foto compartida del estado limpio (ver Core/BarBaseline.lua). La
	-- primera vez la saca; despues devuelve la que ya hay.
	if K.EnsureBarBaseline then K.EnsureBarBaseline(); end
	-- Y se parte SIEMPRE del mismo punto, sin restos del modo anterior.
	if K.RestoreBarBaseline then K.RestoreBarBaseline(); end

	-- Capturar estado original ANTES de tocar nada (pcall por si algún frame no existe)
	local ok, err = pcall(MB_CaptureOriginals);
	if not ok then
		print("|cffFF0000NUF MiniBar:|r Error capturando estado original: " .. tostring(err));
	end

	minibarEnabled = true;
	K._minibarActive = true;
	-- Avisar a HideActionBarTextures: ahora las texturas las maneja MiniBar
	if K._habReapply then K._habReapply(); end

	-- Hook UIParent_ManageFramePositions (once, with guard)
	if not minibarHooked then
		hooksecurefunc("UIParent_ManageFramePositions", function()
			if not minibarEnabled then return; end
			MiniBar_UpdateUI();
			-- Y REPONER EL ANCLA DEL FONDO, SIEMPRE.
			--
			-- Blizzard acaba de reescribirle la posicion a MainMenuBar. Si
			-- no se repone aca mismo, el fondo se queda en el borde de
			-- abajo y los botones donde vos los pusiste: separados.
			if K.PinMainMenuBarToRow1 then K.PinMainMenuBarToRow1(); end
		end);
		hooksecurefunc("VehicleMenuBar_MoveMicroButtons", MiniBar_VehicleMicroHook);
		-- FIX (barra XP/rep que "sube"): MiniBar_UpdateActionBars calcula el
		-- offset de apilado segun si la barra de XP y la de reputacion estan
		-- visibles. Cuando aparecen o desaparecen, Blizzard dispara
		-- MainMenuBar_UpdateExperienceBars — NO siempre ManageFramePositions —
		-- asi que sin este hook las barras de accion no se re-apilaban y
		-- quedaban corridas hacia arriba.
		if MainMenuBar_UpdateExperienceBars then
			hooksecurefunc("MainMenuBar_UpdateExperienceBars", function()
				if minibarEnabled and not InCombatLockdown() then
					if UnitInVehicle and UnitInVehicle("player") then return; end
					MiniBar_UpdateUI();
				end
			end);
		end
		minibarHooked = true;
	end

	-- Remove Blizzard managed frame positions for our bars
	UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomRight"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["PetActionBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["ShapeshiftBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["PossessBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["MultiCastActionBarFrame"] = nil;

	-- Hide page number
	if MainMenuBarPageNumber then MainMenuBarPageNumber:Hide(); end

	-- Hide right-side art textures
	MainMenuXPBarTexture1:Hide();
	MainMenuXPBarTexture2:Hide();
	MainMenuBarTexture2:Hide();
	MainMenuBarTexture3:Hide();
	MainMenuMaxLevelBar2:Hide();
	MainMenuMaxLevelBar3:Hide();
	ReputationWatchBarTexture1:SetTexture("");
	ReputationWatchBarTexture2:SetTexture("");
	ReputationXPBarTexture1:SetTexture("");
	ReputationXPBarTexture2:SetTexture("");

	-- Resize bars to half width (512)
	MainMenuBar:SetWidth(512);
	-- Y el marco del arte con el mismo ancho, o el fondo se dibuja
	-- centrado en 1024 mientras la barra mide 512 (ver PinMainMenuBarToRow1).
	if MainMenuBarArtFrame then MainMenuBarArtFrame:SetWidth(512); end
	-- ACA HABIA UN SEGUNDO DUEÑO DEL ANCLA DE MainMenuBar.
	--
	-- Decia asi, de una epoca en la que los botones todavia colgaban de
	-- MainMenuBar y no existian los contenedores:
	--
	--     MainMenuBar:ClearAllPoints();
	--     MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0);
	--
	-- O sea: clavaba el arte al borde de abajo de la pantalla. Con el
	-- sistema de contenedores eso es exactamente el bug de "el fondo queda
	-- anclado abajo y mover la barra 1 ya no lo mueve": el ancla al
	-- contenedor quedaba borrada y el arte se despegaba de los botones
	-- para siempre.
	--
	-- El ancla la escribe UN solo lugar: PinMainMenuBarToRow1.
	K.PinMainMenuBarToRow1();
	MainMenuExpBar:SetWidth(512);
	MainMenuExpBar:SetHeight(12);
	ReputationWatchBar:SetWidth(512);
	MainMenuBarMaxLevelBar:SetWidth(512);
	ReputationWatchStatusBar:SetWidth(512);

	-- Reposition textures to center on new width
	MainMenuXPBarTexture0:SetPoint("BOTTOM", "MainMenuExpBar", "BOTTOM", -128, 2);
	MainMenuXPBarTexture3:SetPoint("BOTTOM", "MainMenuExpBar", "BOTTOM", 128, 2);
	ReputationWatchBarTexture3:ClearAllPoints();
	ReputationWatchBarTexture3:SetPoint("BOTTOM", "ReputationWatchBar", "BOTTOM", 128, 2);
	ReputationXPBarTexture3:ClearAllPoints();
	ReputationXPBarTexture3:SetPoint("BOTTOM", "ReputationWatchBar", "BOTTOM", 128, 1);
	MainMenuMaxLevelBar0:SetPoint("BOTTOM", "MainMenuBarMaxLevelBar", "TOP", -128, 0);
	MainMenuBarTexture0:SetPoint("BOTTOM", "MainMenuBarArtFrame", "BOTTOM", -128, 0);
	MainMenuBarTexture1:SetPoint("BOTTOM", "MainMenuBarArtFrame", "BOTTOM", 128, 0);
	-- Gryphon positioning handled by K.ApplyGryphons()

	-- SACADO A PROPOSITO: aca habia
	--     PetActionBarFrame:SetAttribute("unit", "pet");
	--
	-- PetActionBarFrame es un frame PROTEGIDO de Blizzard. Escribirle un
	-- atributo seguro desde codigo de addon lo mancha (taint) de forma
	-- PERMANENTE, y desde ahi cualquier accion protegida que pase por el
	-- queda bloqueada con "Interface action failed because of an AddOn".
	--
	-- Ademas no hacia falta: el "unit" de esa barra ya lo pone el propio
	-- FrameXML de Blizzard, y no cambia nunca. Era una linea copiada de
	-- otro addon que solo servia para ensuciar la ejecucion.

	-- Fix blizzard misaligned positions
	if BonusActionButton1 then
		BonusActionButton1:ClearAllPoints();
		BonusActionButton1:SetPoint("BOTTOMLEFT", BonusActionBarFrame, "BOTTOMLEFT", 4, 4);
	end

	if ActionBarUpButton then
		ActionBarUpButton:SetPoint("CENTER", MainMenuBarArtFrame, "BOTTOMLEFT", 521, 30.2);
	end
	if ActionBarDownButton then
		ActionBarDownButton:SetPoint("CENTER", MainMenuBarArtFrame, "BOTTOMLEFT", 521, 11.1);
	end
	if MainMenuBarPageNumber then
		MainMenuBarPageNumber:ClearAllPoints();
		MainMenuBarPageNumber:SetPoint("CENTER", MainMenuBarArtFrame, "BOTTOMLEFT", 541, 21);
	end

	-- Create BagPackFrame and apply layout
	K.CreateBagPackFrame();
	K.ApplyBagPackLayout();

	-- Apply gryphons
	K.ApplyGryphons();

	-- Register events
	minibarEvtFrame:RegisterEvent("ACTIONBAR_SHOWGRID");
	minibarEvtFrame:RegisterEvent("ACTIONBAR_HIDEGRID");
	minibarEvtFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
	minibarEvtFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
	minibarEvtFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
	minibarEvtFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	-- FIX: Escuchar eventos de XP/Rep para re-enforzar posición de MainMenuBar
	minibarEvtFrame:RegisterEvent("PLAYER_XP_UPDATE");
	minibarEvtFrame:RegisterEvent("UPDATE_EXHAUSTION");
	minibarEvtFrame:RegisterEvent("PLAYER_LEVEL_UP");
	minibarEvtFrame:RegisterEvent("UPDATE_FACTION");
	minibarEvtFrame:SetScript("OnEvent", MiniBar_OnEvent);

	-- Initial layout
	MiniBar_UpdateUI();
end

-- ============================================================
-- DISABLE MiniBar (requires /reload for full restore)
-- ============================================================
function K.DisableMiniBar()
	if not minibarEnabled then return; end
	if InCombatLockdown() then return; end
	minibarEnabled = false;
	K._minibarActive = false;

	-- Mismo motivo que en Unify: los botones se reanclan uno por uno y
	-- hay que devolverlos ANTES de restaurar los frames de las barras.
	if K.RestoreActionBarButtonSpace then K.RestoreActionBarButtonSpace(); end
	if K.DetachStanceButtons then K.DetachStanceButtons(); end
	-- Los botones ya volvieron con RestoreActionBarButtonSpace; los
	-- contenedores se esconden para que no queden cajas vacias sueltas.
	if K.HideBarHolders then K.HideBarHolders(); end
	-- MiniBar solto las texturas: que HideActionBarTextures vuelva a aplicar
	if K._habReapply then K._habReapply(); end

	-- Unregister events
	minibarEvtFrame:UnregisterAllEvents();
	minibarEvtFrame:SetScript("OnEvent", nil);
	minibarEvtFrame:SetScript("OnUpdate", nil);

	-- Hide BagPackFrame
	if BagPackFrame then BagPackFrame:Hide(); end

	-- Restaurar UIPARENT_MANAGED_FRAME_POSITIONS
	for key, val in pairs(mb_savedManaged) do
		UIPARENT_MANAGED_FRAME_POSITIONS[key] = val;
	end

	-- Restaurar texturas (visibility + alpha + texture paths)
	MB_RestoreAllTextures();

	-- Restaurar posiciones y tamaños de frames
	MB_RestoreFrame("MainMenuBar",              MainMenuBar);
	-- El marco del arte va por su propia puerta, con TODOS sus anclajes.
	-- Y antes que las texturas que cuelgan de el: si se reponen sobre un
	-- marco que todavia mide 512, caen centradas donde no va.
	if K.RestoreArtFrame then K.RestoreArtFrame(); end
	MB_RestoreFrame("MainMenuExpBar",           MainMenuExpBar);
	MB_RestoreFrame("ReputationWatchBar",       ReputationWatchBar);
	MB_RestoreFrame("MainMenuBarMaxLevelBar",   MainMenuBarMaxLevelBar);
	MB_RestoreFrame("ReputationWatchStatusBar", ReputationWatchStatusBar);
	-- FIX: Restaurar textos de rep y exp
	if ReputationWatchStatusBarText then MB_RestoreFrame("ReputationWatchStatusBarText", ReputationWatchStatusBarText); end
	if MainMenuBarExpText then MB_RestoreFrame("MainMenuBarExpText", MainMenuBarExpText); end
	if ExhaustionTick then MB_RestoreFrame("ExhaustionTick", ExhaustionTick); end
	MB_RestoreFrame("MainMenuXPBarTexture0",    MainMenuXPBarTexture0);
	MB_RestoreFrame("MainMenuXPBarTexture3",    MainMenuXPBarTexture3);
	MB_RestoreFrame("ReputationWatchBarTexture3", ReputationWatchBarTexture3);
	MB_RestoreFrame("ReputationXPBarTexture3",  ReputationXPBarTexture3);
	MB_RestoreFrame("MainMenuMaxLevelBar0",     MainMenuMaxLevelBar0);
	MB_RestoreFrame("MainMenuBarTexture0",      MainMenuBarTexture0);
	MB_RestoreFrame("MainMenuBarTexture1",      MainMenuBarTexture1);
	if ActionBarUpButton       then MB_RestoreFrame("ActionBarUpButton",       ActionBarUpButton);       end
	if ActionBarDownButton     then MB_RestoreFrame("ActionBarDownButton",     ActionBarDownButton);     end
	if MainMenuBarPageNumber   then MB_RestoreFrame("MainMenuBarPageNumber",   MainMenuBarPageNumber);   end
	if BonusActionButton1      then MB_RestoreFrame("BonusActionButton1",      BonusActionButton1);      end
	if MultiBarBottomRight     then MB_RestoreFrame("MultiBarBottomRight",     MultiBarBottomRight);     end
	if ShapeshiftButton1       then MB_RestoreFrame("ShapeshiftButton1",       ShapeshiftButton1);       end
	if MultiCastActionBarFrame       then MB_RestoreFrame("MultiCastActionBarFrame",       MultiCastActionBarFrame);       end
	if MainMenuBarVehicleLeaveButton then MB_RestoreFrame("MainMenuBarVehicleLeaveButton", MainMenuBarVehicleLeaveButton); end
	if PetActionButton1 then MB_RestoreFrame("PetActionButton1", PetActionButton1); end
	if PossessButton1   then MB_RestoreFrame("PossessButton1",   PossessButton1);   end

	-- Micro buttons: restaurar parent Y posición
	local microNames = {
		"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
		"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
		"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
	};
	for _, name in ipairs(microNames) do
		local f = _G[name];
		if f then
			local s = mb_savedFrames[name];
			if s and s.parent then f:SetParent(s.parent); end
			-- FIX: Always reset scale to 1.0 BEFORE MB_RestoreFrame.
			-- ApplyBagPackLayout set explicit scale to ActionBarScale.
			-- Now buttons inherit scale from parent chain (MainMenuBarArtFrame → MainMenuBar).
			f:SetScale(1);
			MB_RestoreFrame(name, f);
		end
	end

	-- Bag slots: restaurar posición y escala
	MB_RestoreFrame("MainMenuBarBackpackButton", MainMenuBarBackpackButton);
	local bagSlots = { "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot", "KeyRingButton" };
	for _, name in ipairs(bagSlots) do
		local f = _G[name];
		if f then
			MB_RestoreFrame(name, f);
			local s = mb_savedFrames[name];
			if s and s.scale then f:SetScale(s.scale); else f:SetScale(1.0); end
		end
	end

	-- Forzar recalculo de Blizzard
	if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	if ShapeshiftBar_Update          then pcall(ShapeshiftBar_Update);          end
	if PetActionBar_Update           then pcall(PetActionBar_Update);           end
	if UpdateMicroButtons            then pcall(UpdateMicroButtons);            end

	-- FIX: Retry para que Blizzard re-posicione correctamente
	-- (Blizzard puede pisar nuestras posiciones restauradas async)
	local mbRestoreRetry = 0;
	local mbRestoreFrame = CreateFrame("Frame");
	mbRestoreFrame:SetScript("OnUpdate", function(self, dt)
		mbRestoreRetry = mbRestoreRetry + dt;
		if mbRestoreRetry >= 0.3 then
			self:SetScript("OnUpdate", nil);
			if not minibarEnabled and not InCombatLockdown() then
				if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
				if UpdateMicroButtons then pcall(UpdateMicroButtons); end
			end
		end
	end);

	-- Restore gryphons to Blizzard default (ApplyGryphons won't touch them with no mode active)
	-- FIX: Usar MB_RestoreFrame en vez de coordenadas hardcodeadas
	MB_RestoreFrame("MainMenuBarLeftEndCap",  MainMenuBarLeftEndCap);
	MB_RestoreFrame("MainMenuBarRightEndCap", MainMenuBarRightEndCap);
	if MainMenuBarLeftEndCap then
		MainMenuBarLeftEndCap:SetAlpha(1);
		MainMenuBarLeftEndCap:Show();
	end
	if MainMenuBarRightEndCap then
		MainMenuBarRightEndCap:SetAlpha(1);
		MainMenuBarRightEndCap:Show();
	end


	-- ── Y LA FOTO DE FABRICA, AL FINAL DE TODO ──
	--
	-- ESTE ERA EL BUG DE APAGAR EL MODO.
	--
	-- BarBaseline guarda una foto del estado limpio, tomada UNA vez por
	-- sesion antes de que ningun modo tocara nada, y sabe reponer padre,
	-- anclajes, ancho, alto, escala, alfa y visibilidad.
	--
	-- Pero solo se la llamaba al ENCENDER un modo. Si apagabas MiniBar y
	-- no entraba ningun otro, nadie la llamaba: quedaba lo que este modulo
	-- pudiera reponer con su propia lista, y esa lista solo tiene lo que
	-- alguien se acordo de agregar. Medido: al apagar,
	--
	--     MainMenuBar  w=512   (tendria que ser 1024)
	--     ArtFrame     w=512   (idem)
	--
	-- Peor todavia: la lista propia se captura AL ENCENDER, asi que si una
	-- sesion anterior dejo la barra en 512, la foto siguiente guardaba 512
	-- como si fuera el original. Una vez contaminada no se recuperaba mas.
	--
	-- Reponiendo la foto de fabrica al final, la barra vuelve SIEMPRE a lo
	-- que trae el juego, y de paso se limpia esa contaminacion sola.
	if K.RestoreBarBaseline then pcall(K.RestoreBarBaseline); end

	-- Limpiar estado guardado
	mb_savedFrames   = {};
	mb_savedTextures = {};
	mb_savedTexPaths = {};
	mb_savedManaged  = {};

	-- Re-apply action bar scale (scale works independently of bar modes)
	if C.ActionBarScale and C.ActionBarScale ~= 1.0 then
		K.ApplyActionBarScale(C.ActionBarScale);
	end
end

-- ============================================================
-- Init: enable at login if configured
-- ============================================================
local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");

	-- ONLY enable MiniBar if configured (mutually exclusive with Unify)
	-- If nothing is configured, DO NOT TOUCH any Blizzard bars (except scale)
	if C.MiniBarEnabled and not C.UnifyActionBars then
		K.EnableMiniBar();
	end

	-- Scale works regardless of mode — it's safe and doesn't break layout
	if C.ActionBarScale and C.ActionBarScale ~= 1.0 then
		K.ApplyActionBarScale(C.ActionBarScale);
	end
end);

-- =========================================================
-- /nufbg  --  REGLA PARA MEDIR EL DESFASAJE DEL FONDO
--
-- Llevo varios intentos corrigiendo esto de oido y el bug vuelve. Basta.
-- Esto no arregla nada: MIDE. Imprime, en pixeles de pantalla, donde esta
-- cada pieza y -- lo unico que importa de verdad -- la DISTANCIA entre el
-- boton 1 y el arte del fondo.
--
-- Esa distancia tiene que ser SIEMPRE la misma. Es la unica cuenta que no
-- puede cambiar: si el fondo se ve corrido, es porque cambio.
--
-- COMO USARLO:
--   1. Move la barra 1 hasta que se vea BIEN. Escribi /nufbg.
--   2. Escribi /reload. Cuando termine, /nufbg otra vez.
--   3. Pasame las dos salidas.
--
-- Comparando las dos listas se ve exactamente QUE numero se movio, y con
-- eso el arreglo sale derecho en vez de a tientas.
-- =========================================================
local function BG_Say(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff4FC3F7nufbg|r " .. msg);
	end
end

-- Todo en pixeles de PANTALLA (coordenada propia x escala efectiva). Asi
-- dos marcos con escalas distintas se pueden comparar entre si; en sus
-- coordenadas propias, no.
local function BG_Screen(f)
	if not f or not f.GetLeft then return nil; end
	local l, b = f:GetLeft(), f:GetBottom();
	if not l or not b then return nil; end
	local e = f:GetEffectiveScale() or 1;
	return l * e, b * e, (f:GetWidth() or 0) * e, (f:GetHeight() or 0) * e, e;
end

local function BG_Line(name, f)
	local l, b, w, h, e = BG_Screen(f);
	if not l then
		BG_Say(name .. " = |cffFF5555sin posicion|r");
		return;
	end
	BG_Say(string.format("%-22s x=%7.1f  y=%7.1f  w=%6.1f  h=%5.1f  esc=%.3f",
		name, l, b, w, h, e));
end

local function BG_Anchor(name, f)
	if not f or not f.GetNumPoints or (f:GetNumPoints() or 0) == 0 then
		BG_Say(name .. " |cffFF5555sin anclaje|r");
		return;
	end
	local p, rel, rp, x, y = f:GetPoint(1);
	local rn = "UIParent";
	if rel and rel.GetName then rn = rel:GetName() or "?"; end
	BG_Say(string.format("%-22s %s -> %s.%s  (%.1f, %.1f)",
		name, tostring(p), tostring(rn), tostring(rp), x or 0, y or 0));
end

-- AL SALIR DE COMBATE, REPONER.
--
-- Todo lo que mueve marcos protegidos esta prohibido en combate, asi que
-- si algo desacomodo el fondo peleando, la correccion no podia aplicarse
-- y quedaba corrido hasta el siguiente repintado -- que podia tardar.
-- Apenas termina el combate se vuelve a pegar.
local mbCombat = CreateFrame("Frame");
mbCombat:RegisterEvent("PLAYER_REGEN_ENABLED");
mbCombat:SetScript("OnEvent", function()
	if C.MiniBarEnabled ~= true then return; end
	if K.PinMainMenuBarToRow1 then K.PinMainMenuBarToRow1(); end
end);

SLASH_NUFBG1 = "/nufbg";
SlashCmdList["NUFBG"] = function()
	BG_Say("--------------------------------------------");

	local h1  = K.GetBarHolder and K.GetBarHolder(1);
	local b1  = _G["ActionButton1"];
	local art = _G["MainMenuBarArtFrame"];

	local ix, iy = 0, 0;
	if K.BarHolderInset then ix, iy = K.BarHolderInset(1); end
	BG_Say(string.format("inset guardado del boton 1:  ix=%.1f  iy=%.1f", ix, iy));

	BG_Line("Holder1",        h1);
	BG_Line("ActionButton1",  b1);
	BG_Line("MainMenuBar",    MainMenuBar);
	BG_Line("ArtFrame",       art);
	if art and art.GetParent then
		local p = art:GetParent();
		local pn = (p and p.GetName and p:GetName()) or tostring(p);
		BG_Say("ArtFrame cuelga de:   " .. tostring(pn));
	end
	BG_Line("GrifoIzq",       _G["MainMenuBarLeftEndCap"]);
	BG_Line("GrifoDer",       _G["MainMenuBarRightEndCap"]);

	BG_Say(" ");
	BG_Anchor("Holder1",     h1);
	BG_Anchor("ActionButton1", b1);
	BG_Anchor("MainMenuBar", MainMenuBar);
	BG_Anchor("ArtFrame",    art);

	-- LA CUENTA QUE IMPORTA.
	--
	-- Cuanto hay del arte al boton 1. Si este par de numeros es igual
	-- antes y despues del /reload, el fondo NO se movio y el problema esta
	-- en otro lado. Si cambia, cambio justo por lo que cambio.
	BG_Say(" ");
	local bx, by = BG_Screen(b1);
	local mx, my = BG_Screen(MainMenuBar);
	local ax, ay = BG_Screen(art);
	if bx and mx then
		BG_Say(string.format("|cffFFD100boton1 - MainMenuBar = (%.1f, %.1f)|r", bx - mx, by - my));
	end
	if bx and ax then
		BG_Say(string.format("|cffFFD100boton1 - ArtFrame    = (%.1f, %.1f)|r", bx - ax, by - ay));
	end
	BG_Say("--------------------------------------------");
end
