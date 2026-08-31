local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local _G, unpack = _G, unpack;
local flatOriginals = {};
local flatBackgrounds = {};

-- Compatibilidad con Cataclysm: definir MAX_ARENA_ENEMIES si no existe
local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;

local function CaptureFlatOriginals(arenaFrame, index)
	if flatOriginals[index] then return; end
	local orig = {};
	orig.frameW = arenaFrame:GetWidth();
	orig.frameH = arenaFrame:GetHeight();
	orig.portraitTexture = arenaFrame.classPortrait:GetTexture();
	orig.portraitW = arenaFrame.classPortrait:GetWidth();
	orig.portraitH = arenaFrame.classPortrait:GetHeight();
	orig.portraitTexCoord = {arenaFrame.classPortrait:GetTexCoord()};  -- NUEVO: Guardar texcoords
	orig.portraitPoints = {};
	for p = 1, arenaFrame.classPortrait:GetNumPoints() do
		orig.portraitPoints[p] = {arenaFrame.classPortrait:GetPoint(p)};
	end
	orig.hbW = arenaFrame.healthbar:GetWidth();
	orig.hbH = arenaFrame.healthbar:GetHeight();
	orig.hbPoints = {};
	for p = 1, arenaFrame.healthbar:GetNumPoints() do
		orig.hbPoints[p] = {arenaFrame.healthbar:GetPoint(p)};
	end
	orig.mbW = arenaFrame.manabar:GetWidth();
	orig.mbH = arenaFrame.manabar:GetHeight();
	orig.mbPoints = {};
	for p = 1, arenaFrame.manabar:GetNumPoints() do
		orig.mbPoints[p] = {arenaFrame.manabar:GetPoint(p)};
	end
	orig.namePoints = {};
	for p = 1, arenaFrame.name:GetNumPoints() do
		orig.namePoints[p] = {arenaFrame.name:GetPoint(p)};
	end
	orig.hbFont = {arenaFrame.healthbar.TextString:GetFont()};
	orig.mbFont = {arenaFrame.manabar.TextString:GetFont()};
	orig.hbTextPoints = {};
	for p = 1, arenaFrame.healthbar.TextString:GetNumPoints() do
		orig.hbTextPoints[p] = {arenaFrame.healthbar.TextString:GetPoint(p)};
	end
	orig.mbTextPoints = {};
	for p = 1, arenaFrame.manabar.TextString:GetNumPoints() do
		orig.mbTextPoints[p] = {arenaFrame.manabar.TextString:GetPoint(p)};
	end
	if arenaFrame.healthbar.GetStatusBarTexture then
		local sbTex = arenaFrame.healthbar:GetStatusBarTexture();
		if sbTex then orig.hbStatusBar = sbTex:GetTexture(); end
	end
	if arenaFrame.manabar.GetStatusBarTexture then
		local sbTex = arenaFrame.manabar:GetStatusBarTexture();
		if sbTex then orig.mbStatusBar = sbTex:GetTexture(); end
	end
	flatOriginals[index] = orig;
end

local function EnsureFlatBackground(arenaFrame, index)
	if flatBackgrounds[index] then return flatBackgrounds[index]; end
	local bg = CreateFrame("Frame", "NidhausArenaFlatBG"..index, arenaFrame);
	bg:SetFrameLevel(math.max(0, arenaFrame:GetFrameLevel() - 1));
	bg:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	});
	bg:SetBackdropColor(0, 0, 0, 0.80);
	bg:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.65);
	bg:Hide();
	flatBackgrounds[index] = bg;
	return bg;
end

function K.ApplyFlatStyle(arenaFrame, index)
	if not arenaFrame then return; end
	CaptureFlatOriginals(arenaFrame, index);

	-- FIX: Fallbacks sincronizados con ConfigManager defaults (antes: 150, 18, 12, 12)
	local width = C.ArenaFlatWidth or 120;
	local healthH = C.ArenaFlatHealthBarHeight or 20;
	local powerH = C.ArenaFlatPowerBarHeight or 8;
	local healthFont = C.ArenaFlatHealthFontSize or 9;
	local powerFont = C.ArenaFlatPowerFontSize or 9;
	-- ArenaFlatMirrored: controla qué lado va el portrait (izquierda/derecha de las barras).
	-- ArenaMirrorMode: también debe invertir el portrait para que sea consistente con
	-- la inversión de trinket/castbar.
	local mirrored = C.ArenaFlatMirrored or C.ArenaMirrorMode;
	local barTex = C.ArenaFlatBarTexture;
	local maxHeight = healthH + powerH;
	local portraitSize = maxHeight;

	local tex = _G["ArenaEnemyFrame"..index.."Texture"];
	if tex then tex:Hide(); end
	local blizzBG = _G["ArenaEnemyFrame"..index.."Background"];
	if blizzBG then blizzBG:Hide(); end

	arenaFrame:SetSize(width, maxHeight + 20);

	-- Contenedor de portrait por encima de las barras (z-order fix)
	if not arenaFrame._flatPortraitContainer then
		local pc = CreateFrame("Frame", nil, arenaFrame);
		pc:SetFrameLevel(arenaFrame:GetFrameLevel() + 10);
		arenaFrame._flatPortraitContainer = pc;
	end
	local pc = arenaFrame._flatPortraitContainer;
	pc:SetSize(portraitSize, portraitSize);
	pc:Show();

	arenaFrame.classPortrait:SetParent(pc);
	arenaFrame.classPortrait:ClearAllPoints();
	arenaFrame.classPortrait:SetAllPoints(pc);
	arenaFrame.classPortrait:SetSize(portraitSize, portraitSize);
	arenaFrame.classPortrait:SetTexture("Interface\\WorldStateFrame\\ICONS-CLASSES");
	arenaFrame.classPortrait:SetDrawLayer("OVERLAY");

	arenaFrame.healthbar:ClearAllPoints();
	arenaFrame.healthbar:SetSize(width - (portraitSize + 4), healthH);
	arenaFrame.manabar:ClearAllPoints();
	arenaFrame.manabar:SetSize(width - (portraitSize + 4), powerH);
	arenaFrame.name:ClearAllPoints();

	local textureToUse = barTex;
	if not textureToUse or textureToUse == "" then
		-- FIX: Usar textura propia del addon en vez de depender de sArena
		textureToUse = C.statusbarTexture or "Interface\\TargetingFrame\\UI-StatusBar";
	end
	if textureToUse and textureToUse ~= "" then
		arenaFrame.healthbar:SetStatusBarTexture(textureToUse);
		arenaFrame.manabar:SetStatusBarTexture(textureToUse);
	end

	local bg = EnsureFlatBackground(arenaFrame, index);
	bg:ClearAllPoints();
	bg:SetSize(width + 2, maxHeight + 6);
	bg:Show();

	if mirrored then
		pc:ClearAllPoints();
		pc:SetPoint("TOPLEFT", arenaFrame, "TOPLEFT", 0, 0);
		arenaFrame.name:SetPoint("TOPLEFT", pc, "TOPLEFT", 0, 18);
		bg:SetPoint("TOPLEFT", pc, "TOPLEFT", -2, 4);
		arenaFrame.healthbar:SetPoint("TOPLEFT", pc, "TOPRIGHT", 2, 0);
		arenaFrame.manabar:SetPoint("TOPLEFT", arenaFrame.healthbar, "BOTTOMLEFT", 0, -2);
	else
		arenaFrame.healthbar:SetPoint("TOPLEFT", arenaFrame, "TOPLEFT", 0, 0);
		arenaFrame.name:SetPoint("TOPLEFT", arenaFrame.healthbar, "TOPLEFT", 0, 16);
		bg:SetPoint("TOPLEFT", arenaFrame.healthbar, "TOPLEFT", -2, 2);
		pc:ClearAllPoints();
		pc:SetPoint("TOPLEFT", arenaFrame.healthbar, "TOPRIGHT", 2, 0);
		arenaFrame.manabar:SetPoint("TOPLEFT", arenaFrame.healthbar, "BOTTOMLEFT", 0, -2);
	end

	local font, _, flags = arenaFrame.healthbar.TextString:GetFont();
	font = font or "Fonts\\FRIZQT__.TTF"; flags = flags or "OUTLINE";
	arenaFrame.healthbar.TextString:ClearAllPoints();
	arenaFrame.healthbar.TextString:SetPoint("CENTER", arenaFrame.healthbar);
	arenaFrame.manabar.TextString:ClearAllPoints();
	arenaFrame.manabar.TextString:SetPoint("CENTER", arenaFrame.manabar);

	-- FIX: Override Hide() del TextString para evitar parpadeo.
	-- Blizzard llama TextStatusBar_UpdateTextString() en cada update de HP/mana,
	-- que oculta el TextString según el checkbox de Interface > Status Text.
	-- Si ArenaFlatStatusText está activo, bloqueamos ese Hide.
	-- Si está inactivo, respetamos el checkbox de Interface.
	local forceText = C.ArenaFlatStatusText;

	-- Guardar Hide original (una sola vez)
	local hbTS = arenaFrame.healthbar.TextString;
	local mbTS = arenaFrame.manabar.TextString;
	if not hbTS._origHideFlat then hbTS._origHideFlat = hbTS.Hide; end
	if not mbTS._origHideFlat then mbTS._origHideFlat = mbTS.Hide; end

	if healthFont > 0 then
		arenaFrame.healthbar.TextString:SetFont(font, healthFont, flags);
		if forceText then
			hbTS.Hide = function() end;  -- Bloquear Hide de Blizzard
			arenaFrame.healthbar.TextString:Show();
		else
			hbTS.Hide = hbTS._origHideFlat;  -- Respetar Interface settings
			-- FIX: NO llamar :Show() aquí. Si lo hacemos, Blizzard lo oculta
			-- en el siguiente tick via TextStatusBar_UpdateTextString() y se
			-- produce un parpadeo visible (Show→Hide→Show→Hide cada frame).
			-- Dejar que Blizzard decida según Interface > Status Text > Party.
		end
	else
		hbTS.Hide = hbTS._origHideFlat;
		arenaFrame.healthbar.TextString:Hide();
	end

	if powerFont > 0 then
		arenaFrame.manabar.TextString:SetFont(font, powerFont, flags);
		if forceText then
			mbTS.Hide = function() end;  -- Bloquear Hide de Blizzard
			arenaFrame.manabar.TextString:Show();
		else
			mbTS.Hide = mbTS._origHideFlat;  -- Respetar Interface settings
			-- FIX: Mismo fix que healthbar — no forzar Show().
		end
	else
		mbTS.Hide = mbTS._origHideFlat;
		arenaFrame.manabar.TextString:Hide();
	end

	-- ═══════════════════════════════════════════════════════════
	-- FIX: Posicionar cast bar y trinket según ArenaMirrorMode
	-- Esto DEBE estar dentro de ApplyFlatStyle porque es la única
	-- función que corre siempre al re-aplicar el estilo flat.
	-- MirrorMode.lua intentaba hacerlo por separado pero algo lo sobreescribía.
	-- ═══════════════════════════════════════════════════════════
	local castBar = _G["ArenaEnemyFrame"..index.."CastingBar"];
	if castBar then
		castBar:ClearAllPoints();
		-- Posición guardada para el modo actual tiene prioridad
		local savedCB = K.GetSavedCastBarPos and K.GetSavedCastBarPos();
		if savedCB then
			castBar:SetPoint(savedCB[1], arenaFrame, savedCB[2], savedCB[3], savedCB[4]);
		elseif C.ArenaMirrorMode then
			-- Mirror ON default: cast bar DERECHA (opuesto al trinket)
			castBar:SetPoint("BOTTOMLEFT", arenaFrame, "BOTTOMRIGHT", 8, 6);
			local icon = _G["ArenaEnemyFrame"..index.."CastingBarIcon"];
			if icon then
				icon:ClearAllPoints();
				icon:SetPoint("LEFT", castBar, "RIGHT", 2, 0);
			end
		else
			-- Mirror OFF default: cast bar IZQUIERDA (opuesto al trinket)
			castBar:SetPoint("BOTTOMRIGHT", arenaFrame, "BOTTOMLEFT", -8, 6);
			local icon = _G["ArenaEnemyFrame"..index.."CastingBarIcon"];
			if icon then
				icon:ClearAllPoints();
				icon:SetPoint("RIGHT", castBar, "LEFT", -2, 0);
			end
		end
	end

	-- Trinket: ArenaMirrorMode SIEMPRE gana sobre savedPos.
	-- savedPos solo se respeta cuando mirror mode está OFF (el usuario la arrastró manualmente).
	-- Usar _G primero (más fiable que ns.ArenaFrame_Trinkets.frames que puede ser nil en test mode).
	local trinketBorder = _G["NidhausArenaTrinketBorder"..index];
	if not trinketBorder then
		local trinketCore = ns and ns.ArenaFrame_Trinkets;
		if trinketCore and trinketCore.frames and trinketCore.frames[index] then
			trinketBorder = trinketCore.frames[index].border;
		end
	end
	if trinketBorder then
		trinketBorder:ClearAllPoints();
		-- Posición guardada para el modo actual tiene prioridad
		local savedPos = K.GetSavedTrinketPos and K.GetSavedTrinketPos();
		if savedPos then
			trinketBorder:SetPoint(savedPos[1], arenaFrame, savedPos[2], savedPos[3], savedPos[4]);
		elseif C.ArenaMirrorMode then
			-- Mirror ON default: trinket IZQUIERDA
			trinketBorder:SetPoint("BOTTOMRIGHT", arenaFrame, "BOTTOMLEFT", -8, 0);
		else
			-- Mirror OFF default: trinket DERECHA
			trinketBorder:SetPoint("BOTTOMLEFT", arenaFrame, "BOTTOMRIGHT", 8, 0);
		end
	end
end

function K.RemoveFlatStyle(index)
	local bg = flatBackgrounds[index];
	if bg then bg:Hide(); end
	local tex = _G["ArenaEnemyFrame"..index.."Texture"];
	if tex then tex:Show(); end
	local blizzBG = _G["ArenaEnemyFrame"..index.."Background"];
	if blizzBG then blizzBG:Show(); end

	local arenaFrame = _G["ArenaEnemyFrame"..index];
	local orig = flatOriginals[index];
	if not arenaFrame or not orig then return; end

	-- Restaurar portrait al frame original
	if arenaFrame._flatPortraitContainer then
		arenaFrame._flatPortraitContainer:Hide();
	end
	arenaFrame.classPortrait:SetParent(arenaFrame);
	arenaFrame.classPortrait:SetDrawLayer("ARTWORK");

	arenaFrame:SetSize(orig.frameW, orig.frameH);

	arenaFrame.classPortrait:ClearAllPoints();
	for _, pt in ipairs(orig.portraitPoints) do arenaFrame.classPortrait:SetPoint(unpack(pt)); end
	arenaFrame.classPortrait:SetSize(orig.portraitW, orig.portraitH);
	arenaFrame.classPortrait:SetTexture(orig.portraitTexture or "Interface\\TargetingFrame\\UI-Classes-Circles");
	if orig.portraitTexCoord and #orig.portraitTexCoord == 8 then
		arenaFrame.classPortrait:SetTexCoord(unpack(orig.portraitTexCoord));  -- NUEVO: Restaurar texcoords
	end

	arenaFrame.healthbar:ClearAllPoints();
	for _, pt in ipairs(orig.hbPoints) do arenaFrame.healthbar:SetPoint(unpack(pt)); end
	arenaFrame.healthbar:SetSize(orig.hbW, orig.hbH);

	arenaFrame.manabar:ClearAllPoints();
	if orig.mbPoints and #orig.mbPoints > 0 then
		for _, pt in ipairs(orig.mbPoints) do arenaFrame.manabar:SetPoint(unpack(pt)); end
	end
	arenaFrame.manabar:SetSize(orig.mbW, orig.mbH);

	arenaFrame.name:ClearAllPoints();
	for _, pt in ipairs(orig.namePoints) do arenaFrame.name:SetPoint(unpack(pt)); end

	arenaFrame.healthbar.TextString:ClearAllPoints();
	for _, pt in ipairs(orig.hbTextPoints) do arenaFrame.healthbar.TextString:SetPoint(unpack(pt)); end
	arenaFrame.manabar.TextString:ClearAllPoints();
	for _, pt in ipairs(orig.mbTextPoints) do arenaFrame.manabar.TextString:SetPoint(unpack(pt)); end
	if orig.hbFont[1] then arenaFrame.healthbar.TextString:SetFont(unpack(orig.hbFont)); end
	if orig.mbFont[1] then arenaFrame.manabar.TextString:SetFont(unpack(orig.mbFont)); end

	-- FIX: Restaurar Hide original del TextString
	local hbTS = arenaFrame.healthbar.TextString;
	local mbTS = arenaFrame.manabar.TextString;
	if hbTS._origHideFlat then hbTS.Hide = hbTS._origHideFlat; end
	if mbTS._origHideFlat then mbTS.Hide = mbTS._origHideFlat; end

	arenaFrame.healthbar.TextString:Show();
	arenaFrame.manabar.TextString:Show();

	if orig.hbStatusBar then arenaFrame.healthbar:SetStatusBarTexture(orig.hbStatusBar); end
	if orig.mbStatusBar then arenaFrame.manabar:SetStatusBarTexture(orig.mbStatusBar); end

	-- FIX: NO borrar flatOriginals[index] — se capturan una sola vez y se reutilizan
	-- (antes, al alternar Flat→Custom→Flat, se re-capturaban originals "contaminados")
end

function K.ApplyAllFlatStyles()
	for i = 1, MAX_ARENA_ENEMIES do
		local f = _G["ArenaEnemyFrame"..i];
		if f then K.ApplyFlatStyle(f, i); end
	end
	-- Also apply flat pet styles if enabled
	if C.ArenaFlatPetStyle then
		K.ApplyFlatPetFrames();
	end
end

function K.RemoveAllFlatStyles()
	for i = 1, MAX_ARENA_ENEMIES do K.RemoveFlatStyle(i); end
	K.RemoveAllFlatPetStyles();
end

-- Local helper (also defined globally in ArenaFrame.lua)
local function IsFlatModeActive()
	local style = C.ArenaFrameStyle or "Blizzard";
	return (style == "Flat") or (C.ArenaFlatMode == true);
end

function K.ResetFlatDefaults()
	-- FIX: Defaults sincronizados con ConfigManager.lua
	-- Antes: Width=150, HealthBarHeight=18, HealthFont=12, PowerFont=12
	-- ConfigManager: Width=120, HealthBarHeight=20, HealthFont=9, PowerFont=9
	local defaults = {
		ArenaFlatWidth = 120, ArenaFlatHealthBarHeight = 20, ArenaFlatPowerBarHeight = 8,
		ArenaFlatHealthFontSize = 9, ArenaFlatPowerFontSize = 9, ArenaFlatMirrored = false,
	};
	for key, val in pairs(defaults) do K.SaveConfig(key, val); end
	if IsFlatModeActive() then
		K.ApplyAllFlatStyles();
		if K.ApplyArenaSpacing then K.ApplyArenaSpacing(); end
	end
	return defaults;
end

-- =========================================================
-- FLAT PET FRAME STYLING
-- =========================================================

local flatPetOriginals = {};
local flatPetBackgrounds = {};

local function CapturePetOriginals(petFrame, index)
	if flatPetOriginals[index] then return; end
	local orig = {};
	orig.width = petFrame:GetWidth();
	orig.height = petFrame:GetHeight();

	local petTex = _G[petFrame:GetName().."Texture"];
	if petTex then
		orig.texShown = petTex:IsShown();
	end

	-- Guardar portrait original
	local petPortrait = _G[petFrame:GetName().."Portrait"];
	if petPortrait then
		orig.portraitW = petPortrait:GetWidth();
		orig.portraitH = petPortrait:GetHeight();
		orig.portraitPoints = {};
		for p = 1, petPortrait:GetNumPoints() do
			orig.portraitPoints[p] = {petPortrait:GetPoint(p)};
		end
	end

	if petFrame.healthbar then
		orig.hbW = petFrame.healthbar:GetWidth();
		orig.hbH = petFrame.healthbar:GetHeight();
		orig.hbPoints = {};
		for p = 1, petFrame.healthbar:GetNumPoints() do
			orig.hbPoints[p] = {petFrame.healthbar:GetPoint(p)};
		end
		if petFrame.healthbar.GetStatusBarTexture then
			local sbTex = petFrame.healthbar:GetStatusBarTexture();
			if sbTex then orig.hbStatusBar = sbTex:GetTexture(); end
		end
	end

	if petFrame.manabar then
		orig.mbW = petFrame.manabar:GetWidth();
		orig.mbH = petFrame.manabar:GetHeight();
		orig.mbPoints = {};
		for p = 1, petFrame.manabar:GetNumPoints() do
			orig.mbPoints[p] = {petFrame.manabar:GetPoint(p)};
		end
	end

	orig.points = {};
	for p = 1, petFrame:GetNumPoints() do
		orig.points[p] = {petFrame:GetPoint(p)};
	end

	flatPetOriginals[index] = orig;
end

local function EnsurePetFlatBackground(petFrame, index)
	if flatPetBackgrounds[index] then return flatPetBackgrounds[index]; end
	local bg = CreateFrame("Frame", "NidhausArenaPetFlatBG"..index, petFrame);
	bg:SetFrameLevel(math.max(0, petFrame:GetFrameLevel() - 1));
	bg:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 6,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	});
	bg:SetBackdropColor(0, 0, 0, 0.80);
	bg:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.65);
	bg:Hide();
	flatPetBackgrounds[index] = bg;
	return bg;
end

function K.ApplyFlatPetStyle(petFrame, index)
	if not petFrame then return; end
	CapturePetOriginals(petFrame, index);

	local arenaFrame = _G["ArenaEnemyFrame"..index];
	if not arenaFrame then return; end

	-- FIX MIRROR MODE: mismo OR logic que K.ApplyFlatStyle
	local mirrored = C.ArenaFlatMirrored or C.ArenaMirrorMode;

	-- Tamaños del pet: versión mini del frame principal
	local petBarH = 8;
	local petManaH = 4;
	local iconSize = petBarH + petManaH + 2; -- cuadrado = alto total de barras
	local petBarWidth = iconSize * 3; -- barras 3x más anchas que el icono
	local totalWidth = iconSize + 2 + petBarWidth;

	-- Hide Blizzard pet texture
	local petTex = _G[petFrame:GetName().."Texture"];
	if petTex then petTex:Hide(); end

	-- Resize pet frame
	petFrame:SetSize(totalWidth, iconSize + 4);
	petFrame:EnableMouse(true);

	-- Position pet below arena frame manabar
	petFrame:ClearAllPoints();
	petFrame:SetPoint("TOPLEFT", arenaFrame.manabar, "BOTTOMLEFT", 0, -3);

	-- Icono cuadrado del pet (portrait)
	if not petFrame._flatPetIcon then
		local icon = petFrame:CreateTexture(nil, "OVERLAY");
		petFrame._flatPetIcon = icon;
	end
	local icon = petFrame._flatPetIcon;
	icon:SetSize(iconSize, iconSize);
	icon:ClearAllPoints();

	-- Usar textura de la pet si existe, sino usar icono genérico
	local petPortrait = _G[petFrame:GetName().."Portrait"];
	if petPortrait then
		petPortrait:ClearAllPoints();
		petPortrait:SetSize(iconSize, iconSize);
		petPortrait:Show();
		icon:Hide(); -- usar el portrait real
	else
		icon:SetTexture("Interface\\Icons\\Ability_Hunter_Pet_Bear");
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
		icon:Show();
	end

	-- FIX: barTex era nil aquí porque era una variable local dentro de K.ApplyFlatStyle,
	-- no accesible en este scope. El fallback (C.statusbarTexture) salvaba de un crash
	-- pero C.ArenaFlatBarTexture se ignoraba silenciosamente para las barras del pet.
	local barTex = C.ArenaFlatBarTexture;
	-- Apply bar texture
	local textureToUse = barTex;
	if not textureToUse or textureToUse == "" then
		-- FIX: Usar textura propia del addon en vez de depender de sArena
		textureToUse = C.statusbarTexture or "Interface\\TargetingFrame\\UI-StatusBar";
	end

	-- Layout: mirrored = [Icon][Bars], normal = [Bars][Icon]
	if mirrored then
		icon:SetPoint("TOPLEFT", petFrame, "TOPLEFT", 0, 0);
		if petPortrait then petPortrait:SetAllPoints(icon); end

		if petFrame.healthbar then
			petFrame.healthbar:ClearAllPoints();
			petFrame.healthbar:SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0);
			petFrame.healthbar:SetSize(petBarWidth, petBarH);
		end
	else
		if petFrame.healthbar then
			petFrame.healthbar:ClearAllPoints();
			petFrame.healthbar:SetPoint("TOPLEFT", petFrame, "TOPLEFT", 0, 0);
			petFrame.healthbar:SetSize(petBarWidth, petBarH);
		end
		icon:SetPoint("TOPLEFT", petFrame.healthbar, "TOPRIGHT", 2, 0);
		if petPortrait then petPortrait:SetAllPoints(icon); end
	end

	if petFrame.healthbar and textureToUse and textureToUse ~= "" then
		petFrame.healthbar:SetStatusBarTexture(textureToUse);
	end

	-- Style manabar debajo de healthbar
	if petFrame.manabar then
		petFrame.manabar:ClearAllPoints();
		petFrame.manabar:SetPoint("TOPLEFT", petFrame.healthbar, "BOTTOMLEFT", 0, -2);
		petFrame.manabar:SetSize(petBarWidth, petManaH);
		if textureToUse and textureToUse ~= "" then
			petFrame.manabar:SetStatusBarTexture(textureToUse);
		end
	end

	-- Background con borde
	local bg = EnsurePetFlatBackground(petFrame, index);
	bg:ClearAllPoints();
	if mirrored then
		bg:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2);
	else
		bg:SetPoint("TOPLEFT", petFrame.healthbar, "TOPLEFT", -2, 2);
	end
	bg:SetSize(totalWidth + 4, iconSize + 4);
	bg:Show();
end

function K.RemoveFlatPetStyle(index)
	local bg = flatPetBackgrounds[index];
	if bg then bg:Hide(); end

	local petFrame = _G["ArenaEnemyFrame"..index.."PetFrame"];
	local orig = flatPetOriginals[index];
	if not petFrame or not orig then return; end

	-- Hide custom flat icon
	if petFrame._flatPetIcon then petFrame._flatPetIcon:Hide(); end

	-- Restore pet portrait to original position
	local petPortrait = _G[petFrame:GetName().."Portrait"];
	if petPortrait and orig.portraitPoints then
		petPortrait:ClearAllPoints();
		for _, pt in ipairs(orig.portraitPoints) do petPortrait:SetPoint(unpack(pt)); end
		if orig.portraitW and orig.portraitH then
			petPortrait:SetSize(orig.portraitW, orig.portraitH);
		end
	end

	-- Restore Blizzard texture
	local petTex = _G[petFrame:GetName().."Texture"];
	if petTex then petTex:Show(); end

	-- Restore size
	petFrame:SetSize(orig.width, orig.height);

	-- Restore position
	petFrame:ClearAllPoints();
	if orig.points then
		for _, pt in ipairs(orig.points) do petFrame:SetPoint(unpack(pt)); end
	end

	-- Restore healthbar
	if petFrame.healthbar and orig.hbPoints then
		petFrame.healthbar:ClearAllPoints();
		for _, pt in ipairs(orig.hbPoints) do petFrame.healthbar:SetPoint(unpack(pt)); end
		petFrame.healthbar:SetSize(orig.hbW, orig.hbH);
		if orig.hbStatusBar then petFrame.healthbar:SetStatusBarTexture(orig.hbStatusBar); end
	end

	-- Restore manabar
	if petFrame.manabar and orig.mbPoints then
		petFrame.manabar:ClearAllPoints();
		for _, pt in ipairs(orig.mbPoints) do petFrame.manabar:SetPoint(unpack(pt)); end
		petFrame.manabar:SetSize(orig.mbW, orig.mbH);
	end

	-- FIX: NO borrar flatPetOriginals[index] — se capturan una sola vez
end

function K.ApplyFlatPetFrames()
	-- FIX: Usar K.IsFlatModeActive (global) en vez de local IsFlatModeActive
	-- para garantizar consistencia con ArenaFrame.lua si la lógica diverge
	if not (K.IsFlatModeActive and K.IsFlatModeActive()) then return; end
	if not C.ArenaFlatPetStyle then return; end

	for i = 1, MAX_ARENA_ENEMIES do
		local petFrame = _G["ArenaEnemyFrame"..i.."PetFrame"];
		if petFrame then
			K.ApplyFlatPetStyle(petFrame, i);
		end
	end
end

function K.RemoveAllFlatPetStyles()
	for i = 1, MAX_ARENA_ENEMIES do
		K.RemoveFlatPetStyle(i);
	end
end