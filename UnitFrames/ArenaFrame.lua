local AddOnName, ns = ...;
local K, C, L = unpack(ns);
local hooksecurefunc = hooksecurefunc;
local _G, unpack = _G, unpack;
local IsAddOnLoaded, LoadAddOn = IsAddOnLoaded, LoadAddOn;

local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;

local NidhausArenaEnemyFrames;
local isInitialized = false;
local hookRegistered = false;

local Path;

local function GetArenaTexturePath()
	if C.darkFrames then
		return "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\UI-TargetingFrame";
	else
		return "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\UI-TargetingFrame";
	end
end

local function ArenaFramesSettings()
	if not isInitialized then return; end
	if not NidhausArenaEnemyFrames then return; end
	if not ArenaEnemyFrames then return; end
	if not ArenaEnemyFrame1 then return; end

	-- SetParent: previene que Blizzard reposicione el contenedor
	ArenaEnemyFrames:SetParent(NidhausArenaEnemyFrames);

	ArenaEnemyFrame1:ClearAllPoints();
	ArenaEnemyFrame1:SetPoint("TOPLEFT", NidhausArenaEnemyFrames, "TOPLEFT", 0, 0);

	local scale = C.ArenaFrameScale;
	if type(scale) == "number" and scale > 0 and scale <= 3 then
		ArenaEnemyFrames:SetScale(scale);
	end
end

local arenaOriginals = {};

local function CaptureOriginals(index)
	if arenaOriginals[index] then return; end
	local arenaFrame = _G["ArenaEnemyFrame"..index];
	if not arenaFrame then return; end

	local orig = {};

	orig.frameWidth = arenaFrame:GetWidth();
	orig.frameHeight = arenaFrame:GetHeight();

	local tex = _G["ArenaEnemyFrame"..index.."Texture"];
	if tex then
		orig.tex = {
			texture = tex:GetTexture(),
			points = {},
			texCoords = {tex:GetTexCoord()},
			width = tex:GetWidth(),
			height = tex:GetHeight(),
			shown = tex:IsShown(),
		};
		for p = 1, tex:GetNumPoints() do
			orig.tex.points[p] = {tex:GetPoint(p)};
		end
	end

	local hb = arenaFrame.healthbar;
	orig.healthbar = { points = {}, width = hb:GetWidth(), height = hb:GetHeight() };
	for p = 1, hb:GetNumPoints() do
		orig.healthbar.points[p] = {hb:GetPoint(p)};
	end

	orig.name = {};
	for p = 1, arenaFrame.name:GetNumPoints() do
		orig.name[p] = {arenaFrame.name:GetPoint(p)};
	end

	orig.manabar = { points = {}, width = arenaFrame.manabar:GetWidth(), height = arenaFrame.manabar:GetHeight() };
	for p = 1, arenaFrame.manabar:GetNumPoints() do
		orig.manabar.points[p] = {arenaFrame.manabar:GetPoint(p)};
	end

	orig.hbText = {};
	for p = 1, hb.TextString:GetNumPoints() do
		orig.hbText[p] = {hb.TextString:GetPoint(p)};
	end
	orig.mbText = {};
	for p = 1, arenaFrame.manabar.TextString:GetNumPoints() do
		orig.mbText[p] = {arenaFrame.manabar.TextString:GetPoint(p)};
	end

	orig.hbFont = {hb.TextString:GetFont()};
	orig.mbFont = {arenaFrame.manabar.TextString:GetFont()};

	orig.portrait = {
		width = arenaFrame.classPortrait:GetWidth(),
		height = arenaFrame.classPortrait:GetHeight(),
		texture = arenaFrame.classPortrait:GetTexture(),
		points = {},
	};
	for p = 1, arenaFrame.classPortrait:GetNumPoints() do
		orig.portrait.points[p] = {arenaFrame.classPortrait:GetPoint(p)};
	end

	if hb.GetStatusBarTexture then
		local sbTex = hb:GetStatusBarTexture();
		if sbTex then orig.hbStatusBar = sbTex:GetTexture(); end
	end
	if arenaFrame.manabar.GetStatusBarTexture then
		local sbTex = arenaFrame.manabar:GetStatusBarTexture();
		if sbTex then orig.mbStatusBar = sbTex:GetTexture(); end
	end

	local castBar = _G["ArenaEnemyFrame"..index.."CastingBar"];
	if castBar then
		orig.castBar = {
			width = castBar:GetWidth(),
			height = castBar:GetHeight(),
			scale = castBar:GetScale(),
		};
	end

	arenaOriginals[index] = orig;
end

local function RestoreDefaultArenaTextures()
	for i = 1, MAX_ARENA_ENEMIES do
		local arenaFrame = _G["ArenaEnemyFrame"..i];
		local orig = arenaOriginals[i];
		if not arenaFrame or not orig then break; end

		if orig.frameWidth and orig.frameHeight then
			arenaFrame:SetSize(orig.frameWidth, orig.frameHeight);
		end

		local tex = _G["ArenaEnemyFrame"..i.."Texture"];
		if tex and orig.tex then
			tex:SetTexture(orig.tex.texture);
			tex:ClearAllPoints();
			for _, pt in ipairs(orig.tex.points) do
				tex:SetPoint(unpack(pt));
			end
			tex:SetTexCoord(unpack(orig.tex.texCoords));
			tex:SetSize(orig.tex.width, orig.tex.height);
			tex:Show();
		end

		arenaFrame.healthbar:ClearAllPoints();
		for _, pt in ipairs(orig.healthbar.points) do
			arenaFrame.healthbar:SetPoint(unpack(pt));
		end
		arenaFrame.healthbar:SetSize(orig.healthbar.width, orig.healthbar.height);

		arenaFrame.name:ClearAllPoints();
		for _, pt in ipairs(orig.name) do
			arenaFrame.name:SetPoint(unpack(pt));
		end

		arenaFrame.manabar:ClearAllPoints();
		if orig.manabar.points then
			for _, pt in ipairs(orig.manabar.points) do
				arenaFrame.manabar:SetPoint(unpack(pt));
			end
		end
		arenaFrame.manabar:SetSize(orig.manabar.width, orig.manabar.height);

		arenaFrame.healthbar.TextString:ClearAllPoints();
		for _, pt in ipairs(orig.hbText) do
			arenaFrame.healthbar.TextString:SetPoint(unpack(pt));
		end
		arenaFrame.manabar.TextString:ClearAllPoints();
		for _, pt in ipairs(orig.mbText) do
			arenaFrame.manabar.TextString:SetPoint(unpack(pt));
		end

		if orig.hbFont[1] then arenaFrame.healthbar.TextString:SetFont(unpack(orig.hbFont)); end
		if orig.mbFont[1] then arenaFrame.manabar.TextString:SetFont(unpack(orig.mbFont)); end
		arenaFrame.healthbar.TextString:Show();
		arenaFrame.manabar.TextString:Show();

		arenaFrame.classPortrait:ClearAllPoints();
		for _, pt in ipairs(orig.portrait.points) do
			arenaFrame.classPortrait:SetPoint(unpack(pt));
		end
		arenaFrame.classPortrait:SetSize(orig.portrait.width, orig.portrait.height);
		if orig.portrait.texture then
			arenaFrame.classPortrait:SetTexture(orig.portrait.texture);
		else
			arenaFrame.classPortrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles");
		end

		if orig.hbStatusBar then arenaFrame.healthbar:SetStatusBarTexture(orig.hbStatusBar); end
		if orig.mbStatusBar then arenaFrame.manabar:SetStatusBarTexture(orig.mbStatusBar); end

		local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
		if castBar and orig.castBar then
			castBar:SetWidth(orig.castBar.width);
			castBar:SetHeight(orig.castBar.height);
			castBar:SetScale(orig.castBar.scale);
		end

		local blizzBG = _G["ArenaEnemyFrame"..i.."Background"];
		if blizzBG then blizzBG:Show(); end
	end
end

local function ApplyArenaTextures()
	if not ArenaEnemyFrame1 then return; end
	if not Path then Path = GetArenaTexturePath(); end

	for i = 1, MAX_ARENA_ENEMIES do
		if _G["ArenaEnemyFrame"..i] then CaptureOriginals(i); end
	end

	local style = C.ArenaFrameStyle or "Blizzard";
	local isFlat = (style == "Flat") or C.ArenaFlatMode;
	local isCustom = (style == "Custom") or (C.ArenaCustomTexture and not isFlat);

	if isFlat then
		RestoreDefaultArenaTextures();
		if K.ApplyAllFlatStyles then K.ApplyAllFlatStyles(); end
		return;
	end

	if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end

	if not isCustom then
		RestoreDefaultArenaTextures();
		return;
	end

	local Font = C.ArenaFrameFont or {"Fonts\\FRIZQT__.TTF", 7, "OUTLINE"};
	local statusbarOn = C.statusbarOn;
	local statusbarTexture = C.statusbarTexture;

	for i = 1, MAX_ARENA_ENEMIES do
		local arenaFrame = _G["ArenaEnemyFrame"..i];
		if not arenaFrame then break; end

		local tex = _G["ArenaEnemyFrame"..i.."Texture"];
		if tex then
			tex:SetTexture(Path);
			tex:ClearAllPoints();
			tex:SetPoint("TOPLEFT", arenaFrame, "TOPLEFT", 0, 5);
			tex:SetTexCoord(0.09375, 1.0, 0, 0.78125);
			tex:SetSize(124, 48);
			tex:Show();
		end

		arenaFrame.healthbar:SetPoint("TOPLEFT", arenaFrame, "TOPLEFT", 4, -6);
		arenaFrame.healthbar:SetSize(62, 14);
		arenaFrame.name:ClearAllPoints();
		arenaFrame.name:SetPoint("BOTTOM", arenaFrame.healthbar, "TOP", 0, 1);
		arenaFrame.manabar:SetSize(62, 6);
		arenaFrame.healthbar.TextString:SetPoint("CENTER", arenaFrame.healthbar);
		arenaFrame.manabar.TextString:SetPoint("CENTER", arenaFrame.manabar);
		arenaFrame.healthbar.TextString:SetFont(unpack(Font));
		arenaFrame.manabar.TextString:SetFont(unpack(Font));
		arenaFrame.classPortrait:SetSize(34, 34);
		arenaFrame.classPortrait:ClearAllPoints();
		arenaFrame.classPortrait:SetPoint("RIGHT", arenaFrame, "RIGHT", 0, 0);

		if statusbarOn and statusbarTexture then
			arenaFrame.healthbar:SetStatusBarTexture(statusbarTexture);
			arenaFrame.manabar:SetStatusBarTexture(statusbarTexture);
		end

		local blizzBG = _G["ArenaEnemyFrame"..i.."Background"];
		if blizzBG then blizzBG:Hide(); end
	end
end

function K.ApplyArenaSpacing()
	local spacing = C.ArenaFrameSpacing;
	if type(spacing) ~= "number" then spacing = 0; end

	-- Re-anclar frame 1 explícitamente al top del contenedor.
	-- Sin esto, si Blizzard mueve ArenaEnemyFrame1 (centrado u otra cosa),
	-- los frames 2 y 3 se posicionan desde ahí y el spacing expande desde el medio.
	local frame1 = _G["ArenaEnemyFrame1"];
	if frame1 then
		local mover = _G["NUF_ArenaMover"];
		if mover and mover:IsShown() then
			frame1:ClearAllPoints();
			frame1:SetPoint("TOPLEFT", mover, "TOPLEFT", 0, 0);
		elseif _G["NidhausArenaEnemyFrames"] then
			frame1:ClearAllPoints();
			frame1:SetPoint("TOPLEFT", _G["NidhausArenaEnemyFrames"], "TOPLEFT", 0, 0);
		end
	end

	-- Frames 2+ se posicionan hacia abajo desde el anterior
	for i = 2, MAX_ARENA_ENEMIES do
		local frame = _G["ArenaEnemyFrame"..i];
		local prevFrame = _G["ArenaEnemyFrame"..(i-1)];
		if frame and prevFrame then
			frame:ClearAllPoints();
			frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -20 - spacing);
		end
	end

	if K.UpdateArenaMoverSize then
		local scale = C.ArenaFrameScale or 1.5;
		if type(scale) ~= "number" or scale <= 0 or scale > 3 then scale = 1.5; end
		K.UpdateArenaMoverSize(scale);
	end
end

local function ArenaFrames_OnLoad()
	ArenaFramesSettings();
	ApplyArenaTextures();
	K.ApplyArenaSpacing();
	if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
end

K.ArenaFrames_OnLoad = ArenaFrames_OnLoad;

-- Forzar la escala correcta en el contenedor y frames individuales
local function EnforceArenaScale()
	local scale = C.ArenaFrameScale;
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	-- Contenedor Blizzard
	if ArenaEnemyFrames then
		local curScale = ArenaEnemyFrames:GetScale();
		if math.abs(curScale - scale) > 0.01 then
			ArenaEnemyFrames:SetScale(scale);
		end
	end
	-- Individual frames solo si están reparenteados FUERA de ArenaEnemyFrames
	-- Si son hijos de ArenaEnemyFrames, la scale del contenedor ya cascadea.
	local moverActive = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown;
	if moverActive then
		for i = 1, 3 do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame and frame:GetParent() ~= ArenaEnemyFrames then
				local cur = frame:GetScale();
				if math.abs(cur - scale) > 0.01 then
					frame:SetScale(scale);
				end
			end
		end
	end
end

-- Hook OnShow de cada arena frame para verificar escala
local scaleHooked = {};
local function HookArenaFrameScale(index)
	if scaleHooked[index] then return; end
	local frame = _G["ArenaEnemyFrame"..index];
	if not frame then return; end
	frame:HookScript("OnShow", function()
		-- FIX: Don't re-apply scale if mod is disabled
		if not isInitialized then return; end
		if C.ArenaFrameScale then
			K.ApplyArenaScale(C.ArenaFrameScale);
		end
		-- Re-aplicar flat pet si corresponde
		if K.IsFlatModeActive and K.IsFlatModeActive() and C.ArenaFlatPetStyle then
			local petFrame = _G["ArenaEnemyFrame"..index.."PetFrame"];
			if petFrame and petFrame:IsShown() then
				K.ApplyFlatPetStyle(petFrame, index);
			end
		end
	end);
	scaleHooked[index] = true;
end

K.StyleSingleArenaFrame = function(frame, index)
	if not frame then return; end
	if not Path then Path = GetArenaTexturePath(); end

	local style = C.ArenaFrameStyle or "Blizzard";
	local isFlat = (style == "Flat") or C.ArenaFlatMode;

	if isFlat then
		if K.ApplyFlatStyle then K.ApplyFlatStyle(frame, index); end
		return;
	end

	local isCustom = (style == "Custom") or C.ArenaCustomTexture;
	if not isCustom then return; end

	local Font = C.ArenaFrameFont or {"Fonts\\FRIZQT__.TTF", 7, "OUTLINE"};
	local tex = _G["ArenaEnemyFrame"..index.."Texture"];
	if tex then
		tex:SetTexture(Path);
		tex:ClearAllPoints();
		tex:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 5);
		tex:SetTexCoord(0.09375, 1.0, 0, 0.78125);
		tex:SetSize(124, 48);
		tex:Show();
	end
	frame.healthbar:ClearAllPoints();
	frame.healthbar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -6);
	frame.healthbar:SetSize(62, 14);
	frame.name:ClearAllPoints();
	frame.name:SetPoint("BOTTOM", frame.healthbar, "TOP", 0, 1);
	frame.manabar:SetSize(62, 6);
	frame.healthbar.TextString:ClearAllPoints();
	frame.healthbar.TextString:SetPoint("CENTER", frame.healthbar);
	frame.manabar.TextString:ClearAllPoints();
	frame.manabar.TextString:SetPoint("CENTER", frame.manabar);
	frame.healthbar.TextString:SetFont(unpack(Font));
	frame.manabar.TextString:SetFont(unpack(Font));
	frame.classPortrait:SetSize(34, 34);
	frame.classPortrait:ClearAllPoints();
	frame.classPortrait:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
	if C.statusbarOn and C.statusbarTexture then
		frame.healthbar:SetStatusBarTexture(C.statusbarTexture);
		frame.manabar:SetStatusBarTexture(C.statusbarTexture);
	end
	local blizzBG = _G["ArenaEnemyFrame"..index.."Background"];
	if blizzBG then blizzBG:Hide(); end
end

function K.ApplyArenaScale(scale)
	-- FIX: Don't apply custom scale if mod is disabled
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	-- Contenedor Blizzard: siempre setear scale aquí
	if ArenaEnemyFrames then
		ArenaEnemyFrames:SetScale(scale);
	end
	
	local anchor = _G["NidhausArenaEnemyFrames"];
	if anchor then
		local spacing = C.ArenaFrameSpacing or 0;
		local height = (60 * 3 + (20 + spacing) * 2) * scale;
		anchor:SetSize(180 * scale, height);
	end
	
	-- Scale individual SOLO cuando el mover está activo Y los frames fueron
	-- reparenteados FUERA de ArenaEnemyFrames. Si son hijos de ArenaEnemyFrames,
	-- la scale del contenedor ya los afecta por herencia parent→child.
	-- Setear ambos causaría effectiveScale = scale × scale (doble escala).
	local moverActive = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown;
	if moverActive then
		for i = 1, 3 do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame and frame:GetParent() ~= ArenaEnemyFrames then
				frame:SetScale(scale);
			end
		end
		local mover = _G["NUF_ArenaMover"];
		if mover and K.UpdateArenaMoverSize then
			K.UpdateArenaMoverSize(scale);
		end
	end
	
	-- Re-aplicar flat styles para que se ajusten al nuevo scale
	if K.IsFlatModeActive and K.IsFlatModeActive() then
		if K.UpdateFlatStyle then K.UpdateFlatStyle(); end
	end
end

function K.ToggleArenaCustomTexture(enabled)
	if not ArenaEnemyFrame1 then return; end
	if C.ArenaFlatMode then return; end
	
	if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end
	
	if enabled then
		ApplyArenaTextures();
		if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
	else
		RestoreDefaultArenaTextures();
		if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
	end
	
	if K.ApplyArenaSpacing then K.ApplyArenaSpacing(); end
end

function K.ToggleArenaFlatMode(enabled)
	if not ArenaEnemyFrame1 then return; end
	
	if enabled then
		if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end
		RestoreDefaultArenaTextures();
		if K.ApplyAllFlatStyles then K.ApplyAllFlatStyles(); end
	else
		if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end
		if C.ArenaCustomTexture then
			ApplyArenaTextures();
		else
			RestoreDefaultArenaTextures();
		end
	end
	
	K.ApplyArenaSpacing();
	if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
end

function K.UpdateFlatStyle()
	if not C.ArenaFlatMode and C.ArenaFrameStyle ~= "Flat" then return; end
	if not ArenaEnemyFrame1 then return; end
	if K.ApplyAllFlatStyles then K.ApplyAllFlatStyles(); end
	K.ApplyArenaSpacing();
	if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
end

function K.IsFlatModeActive()
	return (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);
end
function K.ToggleArenaCastBar(enabled)
	if not ArenaEnemyFrame1 then return; end
	for i = 1, MAX_ARENA_ENEMIES do
		local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
		if castBar then
			if enabled then
				local scale = C.ArenaCastBarScale or 1.0;
				local width = C.ArenaCastBarWidth or 80;
				castBar:SetScale(scale);
				castBar:SetWidth(width);
				-- Fix text overlap: reposition text elements
				local text = _G["ArenaEnemyFrame"..i.."CastingBarText"];
				if text then
					text:ClearAllPoints();
					text:SetPoint("CENTER", castBar, "CENTER", 0, 1);
					text:SetWidth(width - 10);
					text:SetHeight(12);
				end
				local timer = _G["ArenaEnemyFrame"..i.."CastingBarTimer"];
				if timer then
					timer:ClearAllPoints();
					timer:SetPoint("RIGHT", castBar, "RIGHT", -2, 0);
				end
			else
				local orig = arenaOriginals[i];
				if orig and orig.castBar then
					castBar:SetScale(orig.castBar.scale);
					castBar:SetWidth(orig.castBar.width);
					castBar:SetHeight(orig.castBar.height);
				end
			end
		end
	end
end

function K.UpdateArenaCastBarScale(scale)
	if not ArenaEnemyFrame1 then return; end
	for i = 1, MAX_ARENA_ENEMIES do
		local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
		if castBar then
			castBar:SetScale(scale);
		end
	end
end

function K.UpdateArenaCastBarWidth(width)
	if not ArenaEnemyFrame1 then return; end
	for i = 1, MAX_ARENA_ENEMIES do
		local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
		if castBar then
			castBar:SetWidth(width);
			-- Also fix text width to prevent overlap
			local text = _G["ArenaEnemyFrame"..i.."CastingBarText"];
			if text then
				text:SetWidth(width - 10);
			end
		end
	end
end
local arenaMovementHooked = false;
local castBarDragSetup = false;

-- ═══════════════════════════════════════════════════════════
-- CastBar dual position helper (mirror/normal)
-- Misma lógica que trinkets: guarda posición separada para
-- mirror mode ON y mirror mode OFF, con fallback a .global
-- ═══════════════════════════════════════════════════════════
function K.GetSavedCastBarPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.CastBarPositions;
	if not db then return nil; end
	-- Try composite key first (style + mirror), fallback to legacy keys
	if K.GetArenaPositionKey then
		local compositeKey = K.GetArenaPositionKey();
		if db[compositeKey] then return db[compositeKey]; end
	end
	-- Legacy fallback: mirror/normal keys
	local key = C.ArenaMirrorMode and "mirror" or "normal";
	return db[key] or db.global;
end

-- ═══════════════════════════════════════════════════════════
-- CastBar drag: sArena-style OnMouseDown/OnMouseUp
-- Solo funciona en Flat mode con Shift+Ctrl+Click
-- ═══════════════════════════════════════════════════════════

local function SetupCastBarDrag()
	if castBarDragSetup then return; end

	for i = 1, MAX_ARENA_ENEMIES do
		local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
		if castBar then
			castBar:SetMovable(true);
			castBar:EnableMouse(false); -- Se activa solo en test mode + Flat

			castBar:HookScript("OnMouseDown", function(self, button)
				if button ~= "LeftButton" then return; end
				if InCombatLockdown() then return; end
				-- Solo en Flat mode o test mode
				local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
				local isTestMode = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
					and NidhausUnitFramesDB.ArenaMover.IsShown;
				if not (isFlat or isTestMode) then return; end
				-- Shift+Alt (consistente con trinkets y overlay)
				if IsShiftKeyDown() and IsAltKeyDown() and not self._isMoving then
					self:StartMoving();
					self:SetUserPlaced(false);
					self._isMoving = true;
				end
			end);

			castBar:HookScript("OnMouseUp", function(self, button)
				if button ~= "LeftButton" then return; end
				if not self._isMoving then return; end
				self:StopMovingOrSizing();
				self._isMoving = false;

				local arenaFrame = _G["ArenaEnemyFrame"..i];
				if not arenaFrame then return; end

				local parentX, parentY = arenaFrame:GetCenter();
				local frameX, frameY = self:GetCenter();
				if not parentX or not frameX then return; end

				local scale = self:GetScale();
				local offsetX = ((frameX * scale) - parentX) / scale;
				local offsetY = ((frameY * scale) - parentY) / scale;

				offsetX = math.floor(offsetX * 10 + 0.5) / 10;
				offsetY = math.floor(offsetY * 10 + 0.5) / 10;

				self:ClearAllPoints();
				self:SetPoint("CENTER", arenaFrame, "CENTER", offsetX, offsetY);

				if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
				if not NidhausUnitFramesDB.CastBarPositions then NidhausUnitFramesDB.CastBarPositions = {}; end
				local posKey = K.GetArenaPositionKey and K.GetArenaPositionKey() or (C.ArenaMirrorMode and "mirror" or "normal");
				NidhausUnitFramesDB.CastBarPositions[posKey] = {"CENTER", "CENTER", offsetX, offsetY};

				-- Sync ALL cast bars via single source of truth
				for j = 1, MAX_ARENA_ENEMIES do
					if K.PositionArenaCastBar then
						K.PositionArenaCastBar(j);
					end
				end
			end);

			castBar:HookScript("OnHide", function(self)
				if self._isMoving then
					self:StopMovingOrSizing();
					self._isMoving = false;
				end
			end);
		end
	end

	castBarDragSetup = true;
end

function K.RestoreCastBarPositions()
	-- FIX 4: Delegate to single source of truth in MirrorMode.lua
	-- K.PositionArenaCastBar reads saved positions, mirror state, flat state
	for i = 1, MAX_ARENA_ENEMIES do
		if K.PositionArenaCastBar then
			K.PositionArenaCastBar(i);
		end
	end
end

function K.SetCastBarMouseState(state)
	-- Habilitar mouse en Flat mode o test mode
	local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
	local isTestMode = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
		and NidhausUnitFramesDB.ArenaMover.IsShown;
	local enableMouse = state and (isFlat or isTestMode);
	for i = 1, MAX_ARENA_ENEMIES do
		local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
		if castBar then
			castBar:EnableMouse(enableMouse or false);
			if not enableMouse and castBar._isMoving then
				castBar:StopMovingOrSizing();
				castBar._isMoving = false;
			end
		end
	end
end

function K.ResetCastBarPositions()
	if NidhausUnitFramesDB then
		NidhausUnitFramesDB.CastBarPositions = nil;
	end
end

function K.SetupArenaCtrlShiftDrag()
	if arenaMovementHooked then return; end
	if not NidhausArenaEnemyFrames then return; end

	local anchor = NidhausArenaEnemyFrames;
	anchor:SetMovable(true);

	for i = 1, MAX_ARENA_ENEMIES do
		local arenaFrame = _G["ArenaEnemyFrame"..i];
		if arenaFrame then
			local function HookDragStart(clickFrame)
				clickFrame:HookScript("OnMouseDown", function()
					if IsShiftKeyDown() and IsControlKeyDown() and not anchor._isMoving then
						if InCombatLockdown() then return; end
						anchor:StartMoving();
						anchor:SetUserPlaced(false);
						anchor._isMoving = true;
					end
				end);
				clickFrame:HookScript("OnMouseUp", function()
					if anchor._isMoving then
						anchor:StopMovingOrSizing();
						anchor._isMoving = false;
						if NidhausUnitFramesDB and NidhausUnitFramesDB.positions then
							local point, relativeTo, relativePoint, x, y = anchor:GetPoint(1);
							local relName = "UIParent";
							if relativeTo and relativeTo.GetName then
								relName = relativeTo:GetName() or "UIParent";
							end
							-- FIX: Formato con nombres, consistente con ArenaMover.SaveArenaMoverPosition
							NidhausUnitFramesDB.positions["ArenaMover"] = {
								point = point,
								relativeTo = relName,
								relativePoint = relativePoint,
								x = x,
								y = y,
							};
						end
					end
				end);
			end

			HookDragStart(arenaFrame);
			if arenaFrame.healthbar then HookDragStart(arenaFrame.healthbar); end
			if arenaFrame.manabar then HookDragStart(arenaFrame.manabar); end
		end
	end

	-- Configurar drag para castbars
	SetupCastBarDrag();

	arenaMovementHooked = true;
end

local function CreateArenaAnchor()
	if NidhausArenaEnemyFrames then return; end

	NidhausArenaEnemyFrames = CreateFrame("Frame", "NidhausArenaEnemyFrames", UIParent);
	local scale = C.ArenaFrameScale or 1.5;
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then scale = 1.5; end
	-- FIX: Altura consistente con ArenaMover.CalcMoverHeight:
	-- (60*3 + 20*2) * scale = 220*scale (antes era 200*scale, 20px corto)
	local frameH = 60;
	local count = 3;
	local spacing = C.ArenaFrameSpacing or 0;
	local height = (frameH * count + (20 + spacing) * (count - 1)) * scale;
	NidhausArenaEnemyFrames:SetSize(180 * scale, height);

	local savedPos;
	if NidhausUnitFramesDB and NidhausUnitFramesDB.positions then
		savedPos = NidhausUnitFramesDB.positions["ArenaMover"]
		        or NidhausUnitFramesDB.positions["NidhausArenaAnchor"];
	end

	if savedPos then
		-- FIX: Leer con nombres (nuevo formato de ArenaMover) o con índices (legacy)
		local point = savedPos.point or savedPos[1];
		local relName = savedPos.relativeTo or savedPos[2];
		local relPoint = savedPos.relativePoint or savedPos[3];
		local x = savedPos.x or savedPos[4];
		local y = savedPos.y or savedPos[5];
		local relFrame = _G[relName] or UIParent;
		NidhausArenaEnemyFrames:SetPoint(point, relFrame, relPoint, x, y);
	elseif C.ArenaFramePoint then
		NidhausArenaEnemyFrames:SetPoint(unpack(C.ArenaFramePoint));
	else
		NidhausArenaEnemyFrames:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -390, -330);
	end
end

local retryTimerFrame = nil;
local retryTimerIndex = 0;

local function ApplyWithRetries()
	-- FIX RELOG: Más intentos y más tiempo para cubrir relogs en arena
	-- Blizzard puede resetear arte/escala hasta 5-6 segundos después del relog
	local delays = {0.05, 0.15, 0.3, 0.5, 1.0, 2.0, 3.0, 5.0};
	retryTimerIndex = 0;
	if not retryTimerFrame then
		retryTimerFrame = CreateFrame("Frame");
	end
	local elapsed = 0;
	retryTimerFrame:SetScript("OnUpdate", function(self, dt)
		-- FIX: Stop retries if mod was disabled (prevents re-parenting after toggle off)
		if not isInitialized then
			self:SetScript("OnUpdate", nil);
			return;
		end
		elapsed = elapsed + dt;
		local nextDelay = delays[retryTimerIndex + 1];
		if not nextDelay then
			self:SetScript("OnUpdate", nil);
			return;
		end
		if elapsed >= nextDelay then
			retryTimerIndex = retryTimerIndex + 1;
			elapsed = 0;
			if ArenaEnemyFrame1 and ArenaEnemyFrames then
				ArenaFrames_OnLoad();
				for i = 1, (MAX_ARENA_ENEMIES or 5) do
					HookArenaFrameScale(i);
				end
				EnforceArenaScale();
			end
			if retryTimerIndex >= #delays then
				self:SetScript("OnUpdate", nil);
			end
		end
	end);
end

-- Hooks diferidos de funciones de Blizzard_ArenaUI
-- (pueden no existir si Blizzard_ArenaUI aún no cargó)
local blizzHooksRegistered = false;
local function RegisterBlizzardArenaHooks()
	if blizzHooksRegistered then return; end

	-- ArenaEnemyFrame_UpdatePlayer: Blizzard llama esto cuando actualiza un frame
	if ArenaEnemyFrame_UpdatePlayer then
		hooksecurefunc("ArenaEnemyFrame_UpdatePlayer", function(self)
			if not isInitialized or not self then return; end
			ArenaFrames_OnLoad();
		end);
	end

	-- ArenaEnemyFrame_Lock: Blizzard llama esto cuando confirma un oponente
	if ArenaEnemyFrame_Lock then
		hooksecurefunc("ArenaEnemyFrame_Lock", function(self)
			if not isInitialized or not self then return; end
			ArenaFrames_OnLoad();
		end);
	end

	-- ArenaEnemyFrame_SetMysteryPlayer: Blizzard llama esto durante prep phase
	if ArenaEnemyFrame_SetMysteryPlayer then
		hooksecurefunc("ArenaEnemyFrame_SetMysteryPlayer", function(self)
			if not isInitialized or not self then return; end
			ArenaFrames_OnLoad();
		end);
	end

	-- ArenaEnemyFrame_Unlock: Blizzard llama esto al resetear frames
	if ArenaEnemyFrame_Unlock then
		hooksecurefunc("ArenaEnemyFrame_Unlock", function(self)
			if not isInitialized or not self then return; end
			ArenaFrames_OnLoad();
		end);
	end

	-- Solo marcar como registrado si las funciones existían
	if ArenaEnemyFrame_UpdatePlayer or ArenaEnemyFrame_Lock then
		blizzHooksRegistered = true;
	end
end

-- Hooks diferidos para contenedores (ArenaEnemyFrames, ArenaPrepFrames)
K._hookArenaContainers = function()
	if K._arenaContainersHooked then return; end
	if ArenaEnemyFrames then
		ArenaEnemyFrames:HookScript("OnShow", function()
			if not isInitialized then return; end
			ArenaFrames_OnLoad();
			if C.ArenaFrameScale then
				K.ApplyArenaScale(C.ArenaFrameScale);
			end
		end);
	end
	if ArenaPrepFrames then
		ArenaPrepFrames:HookScript("OnShow", function()
			if not isInitialized then return; end
			ArenaFrames_OnLoad();
		end);
	end
	if ArenaEnemyFrames or ArenaPrepFrames then
		K._arenaContainersHooked = true;
	end
end

local function RegisterArenaHook()
	if hookRegistered then return; end

	-- Hook Arena_LoadUI: cuando Blizzard carga la arena UI por primera vez
	-- Este es el momento clave para registrar los hooks que dependen de Blizzard_ArenaUI
	hooksecurefunc("Arena_LoadUI", function()
		-- Ahora Blizzard_ArenaUI está cargado — registrar hooks de funciones
		RegisterBlizzardArenaHooks();
		K._hookArenaContainers();
		ArenaFrames_OnLoad();
		ApplyWithRetries();
	end);

	-- Intentar registrar hooks ahora (si Blizzard_ArenaUI ya está cargado)
	if IsAddOnLoaded("Blizzard_ArenaUI") then
		RegisterBlizzardArenaHooks();
		K._hookArenaContainers();
	end

	hookRegistered = true;
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	if not C.ArenaFrameOn then return; end

	-- Set Path now that config is loaded
	Path = GetArenaTexturePath();

	CreateArenaAnchor();

	RegisterArenaHook();

	if IsAddOnLoaded("Blizzard_ArenaUI") then
		ApplyWithRetries();
	end

	isInitialized = true;
end);

local worldHandler = CreateFrame("Frame");
worldHandler:RegisterEvent("PLAYER_ENTERING_WORLD");
worldHandler:RegisterEvent("PLAYER_LOGIN");
worldHandler:RegisterEvent("ZONE_CHANGED_NEW_AREA");
worldHandler:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS");
worldHandler:RegisterEvent("ARENA_OPPONENT_UPDATE");
worldHandler:SetScript("OnEvent", function(self, event)
	if not IsAddOnLoaded("Blizzard_ArenaUI") then return; end

	-- FIX: Verificar ArenaFrameOn ANTES de isInitialized
	-- (cuando el mod está desactivado, isInitialized es false pero
	-- igual necesitamos restaurar defaults al entrar a arena)
	if not C.ArenaFrameOn then
		RestoreDefaultArenaTextures();
		if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end
		if ArenaEnemyFrames then
			ArenaEnemyFrames:SetScale(1);
			ArenaEnemyFrames:SetParent(UIParent);
			ArenaEnemyFrames:ClearAllPoints();
			ArenaEnemyFrames:SetPoint("RIGHT", UIParent, "RIGHT", -50, -110);
			ArenaEnemyFrames:Show();
		end
		-- Reset individual frame scales
		for i = 1, (MAX_ARENA_ENEMIES or 5) do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame then frame:SetScale(1); end
		end
		if NidhausArenaEnemyFrames then NidhausArenaEnemyFrames:Hide(); end
		return;
	end

	-- FIX RELOG: Si CONFIG_LOADED ya corrió pero isInitialized quedó en false
	-- (puede pasar si Blizzard_ArenaUI no estaba cargado cuando CONFIG_LOADED disparó),
	-- re-inicializar ahora que Blizzard_ArenaUI ya está disponible.
	if not isInitialized then
		Path = GetArenaTexturePath();
		if not NidhausArenaEnemyFrames then CreateArenaAnchor(); end
		RegisterArenaHook();
		isInitialized = true;
	end

	-- FIX /RELOAD: Registrar hooks de Blizzard y contenedores si aún no se hicieron
	RegisterBlizzardArenaHooks();
	if K._hookArenaContainers then K._hookArenaContainers(); end

	-- Mostrar anchor si estaba oculto
	if NidhausArenaEnemyFrames then NidhausArenaEnemyFrames:Show(); end
	ApplyWithRetries();
	if C.ArenaFrameScale then
		K.ApplyArenaScale(C.ArenaFrameScale);
	end

	-- FIX RELOG: Enforcer periódico al entrar a arena.
	-- Blizzard puede resetear parent/escala/arte múltiples veces tras un relog.
	-- Correr cada 2s durante 15s para garantizar estabilidad.
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
		-- Hookear contenedores y funciones Blizzard (por si aún no estaban)
		RegisterBlizzardArenaHooks();
		if K._hookArenaContainers then K._hookArenaContainers(); end

		if not self._enforcerFrame then
			self._enforcerFrame = CreateFrame("Frame");
		end
		local ef = self._enforcerFrame;
		ef._elapsed = 0;
		ef._remaining = 15;
		ef:SetScript("OnUpdate", function(s, dt)
			s._elapsed = s._elapsed + dt;
			if s._elapsed >= 2 then
				s._elapsed = 0;
				s._remaining = s._remaining - 2;
				if isInitialized and ArenaEnemyFrames and NidhausArenaEnemyFrames then
					-- Re-parentear si Blizzard lo cambió
					local curParent = ArenaEnemyFrames:GetParent();
					if curParent ~= NidhausArenaEnemyFrames then
						ArenaFrames_OnLoad();
					end
					-- Re-aplicar escala si cambió
					if C.ArenaFrameScale then
						local curScale = ArenaEnemyFrames:GetScale();
						if math.abs(curScale - C.ArenaFrameScale) > 0.01 then
							K.ApplyArenaScale(C.ArenaFrameScale);
						end
					end
				end
				if s._remaining <= 0 then
					s:SetScript("OnUpdate", nil);
				end
			end
		end);
	end
end);

-- ═══════════════════════════════════════════════════════════
-- Enable/Disable Arena Frame Mod (para toggle en vivo desde OptionsPanel)
-- ═══════════════════════════════════════════════════════════

function K.EnableArenaFrameMod()
	Path = GetArenaTexturePath();

	if not NidhausArenaEnemyFrames then
		CreateArenaAnchor();
	else
		NidhausArenaEnemyFrames:Show();
	end

	RegisterArenaHook();

	-- Mark as initialized BEFORE calling functions that check isInitialized
	isInitialized = true;

	if IsAddOnLoaded("Blizzard_ArenaUI") then
		-- FIX: Reset individual frame scales to 1 before applying container scale.
		for i = 1, (MAX_ARENA_ENEMIES or 5) do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame and frame:GetParent() == ArenaEnemyFrames then
				frame:SetScale(1);
			end
		end

		-- Re-parentear ArenaEnemyFrames al anchor custom
		ArenaFramesSettings();
		ApplyWithRetries();
		EnforceArenaScale();
	end
end

function K.DisableArenaFrameMod()
	-- FIX: Marcar como no inicializado SIEMPRE (antes retornaba si Blizzard_ArenaUI no estaba cargado)
	-- Esto previene que el worldHandler re-aplique estilos al entrar a arena
	isInitialized = false;

	-- FIX: Cancel any pending retry timers (these would re-parent ArenaEnemyFrames
	-- back to the hidden anchor after ~1 second, making frames disappear)
	if retryTimerFrame then
		retryTimerFrame:SetScript("OnUpdate", nil);
	end

	-- Si Blizzard_ArenaUI está cargado, restaurar visualmente
	if IsAddOnLoaded("Blizzard_ArenaUI") then
		-- Quitar estilos flat
		if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end

		-- Restaurar texturas originales de Blizzard
		RestoreDefaultArenaTextures();

		-- Restaurar escala del contenedor Blizzard a 1
		if ArenaEnemyFrames then
			ArenaEnemyFrames:SetScale(1);
			-- Restaurar parent al UIParent
			ArenaEnemyFrames:SetParent(UIParent);
			-- FIX: Restaurar posición default de Blizzard
			ArenaEnemyFrames:ClearAllPoints();
			ArenaEnemyFrames:SetPoint("RIGHT", UIParent, "RIGHT", -50, -110);
			ArenaEnemyFrames:Show();
		end

		-- FIX: Reset individual frame scales to 1 (may have been set incorrectly)
		for i = 1, MAX_ARENA_ENEMIES do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame then
				frame:SetScale(1);
			end
		end

		-- Restaurar spacing a default de Blizzard (sin spacing extra)
		for i = 2, MAX_ARENA_ENEMIES do
			local frame = _G["ArenaEnemyFrame"..i];
			local prevFrame = _G["ArenaEnemyFrame"..(i-1)];
			if frame and prevFrame then
				frame:ClearAllPoints();
				frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -20);
			end
		end

		-- Restaurar ArenaEnemyFrame1 al contenedor Blizzard
		if ArenaEnemyFrame1 and ArenaEnemyFrames then
			ArenaEnemyFrame1:ClearAllPoints();
			ArenaEnemyFrame1:SetPoint("TOPLEFT", ArenaEnemyFrames, "TOPLEFT", 0, 0);
		end

		-- Restaurar mirror mode (texturas normales)
		if K.ResetMirrorCastBars then K.ResetMirrorCastBars(); end

		-- Let Blizzard recalculate positions
		if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	end

	-- Ocultar anchor custom (siempre, aunque no haya ArenaUI)
	if NidhausArenaEnemyFrames then
		NidhausArenaEnemyFrames:Hide();
	end
end

function K.ApplyArenaCustomPosition(enable)
	if enable then
		if not NidhausArenaEnemyFrames then
			CreateArenaAnchor();
		end
		if ArenaEnemyFrames then
			ArenaFramesSettings();
		end
	end
end