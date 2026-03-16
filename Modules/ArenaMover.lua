local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local _G, unpack = _G, unpack;
local IsAddOnLoaded, LoadAddOn = IsAddOnLoaded, LoadAddOn;
local IsActiveBattlefieldArena = IsActiveBattlefieldArena;

local ArenaMover;
local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;
-- FIX: Constante para el mover/test mode (antes hardcodeado como 3 en 6 lugares)
-- Cambiar a MAX_ARENA_ENEMIES si se quiere soportar 5v5 en el test mode
local MOVER_ARENA_COUNT = 3;

local classIcons = {"DRUID","HUNTER","MAGE","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR","DEATHKNIGHT"};
local classColors = {
	DRUID = {1.00, 0.49, 0.04}, HUNTER = {0.67, 0.83, 0.45}, MAGE = {0.41, 0.80, 0.94},
	PALADIN = {0.96, 0.55, 0.73}, PRIEST = {1, 1, 1}, ROGUE = {1.00, 0.96, 0.41},
	SHAMAN = {0, 0.44, 0.87}, WARLOCK = {0.58, 0.51, 0.79}, WARRIOR = {0.78, 0.61, 0.43},
	DEATHKNIGHT = {0.77, 0.12, 0.23},
};

local function EnsureArenaMoverDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ArenaMover then
		NidhausUnitFramesDB.ArenaMover = { IsShown = false };
	end
end

local function LoadArenaMoverPosition()
	if not ArenaMover then return; end
	ArenaMover:ClearAllPoints();
	if NidhausUnitFramesDB and NidhausUnitFramesDB.positions then
		local savedPos = NidhausUnitFramesDB.positions["ArenaMover"]
		              or NidhausUnitFramesDB.positions["NidhausArenaAnchor"];
		if savedPos then
			-- FIX: Leer con nombres (nuevo) o con índices (legacy)
			local point = savedPos.point or savedPos[1];
			local relName = savedPos.relativeTo or savedPos[2];
			local relPoint = savedPos.relativePoint or savedPos[3];
			local x = savedPos.x or savedPos[4];
			local y = savedPos.y or savedPos[5];
			ArenaMover:SetPoint(point, _G[relName] or UIParent, relPoint, x, y);
			return;
		end
	end
	local anchor = _G["NidhausArenaEnemyFrames"];
	if anchor then
		local point, relativeTo, relPoint, x, y = anchor:GetPoint();
		if point then
			ArenaMover:SetPoint(point, relativeTo or UIParent, relPoint, x, y);
			return;
		end
	end
	if C.ArenaFramePoint then
		ArenaMover:SetPoint(unpack(C.ArenaFramePoint));
	else
		ArenaMover:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -180, -180);
	end
end

local function SaveArenaMoverPosition()
	if not ArenaMover then return; end
	local point, relativeTo, relativePoint, x, y = ArenaMover:GetPoint();
	if not point then return; end
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
	local relName = relativeTo and relativeTo:GetName() or "UIParent";
	-- FIX: Formato con nombres, consistente con FrameDragger.SaveFramePosition
	NidhausUnitFramesDB.positions["ArenaMover"] = {
		point = point,
		relativeTo = relName,
		relativePoint = relativePoint,
		x = x,
		y = y,
	};
	local anchor = _G["NidhausArenaEnemyFrames"];
	if anchor then
		anchor:ClearAllPoints();
		anchor:SetPoint(point, _G[relName] or UIParent, relativePoint, x, y);
	end
	if K.UpdateArenaPosition then
		K.UpdateArenaPosition(point, relName, relativePoint, x, y);
	end
end

local function CalcMoverHeight(scale, spacing)
	local frameH = 60;
	local s = spacing or C.ArenaFrameSpacing or 0;
	-- FIX: Usar constante en vez de hardcoded 3
	return (frameH * MOVER_ARENA_COUNT + (20 + s) * (MOVER_ARENA_COUNT - 1)) * scale;
end

local function UpdateArenaMoverSize(scale)
	if not ArenaMover then return; end
	local spacing = C.ArenaFrameSpacing or 0;
	ArenaMover:SetSize(180 * scale, CalcMoverHeight(scale, spacing));
end

local function HideMoverBG()
	if not ArenaMover or not ArenaMover.bg then return; end
	ArenaMover.bg:Hide();
end

local function ShowMoverBG()
	if not ArenaMover or not ArenaMover.bg then return; end
	ArenaMover.bg:Show();
end

local function UpdateArenaMoverBackground()
	if not ArenaMover then return; end
	if IsActiveBattlefieldArena() then
		HideMoverBG();
	elseif ArenaMover:IsShown() then
		if K.IsFlatModeActive and K.IsFlatModeActive() then
			HideMoverBG();
		else
			ShowMoverBG();
		end
	else
		HideMoverBG();
	end
end

local function CreateArenaMover()
	if ArenaMover then return; end
	ArenaMover = CreateFrame("Frame", "NUF_ArenaMover", UIParent);
	ArenaMover:SetSize(180, 200);
	ArenaMover:SetMovable(true);
	ArenaMover:EnableMouse(true);
	ArenaMover:RegisterForDrag("LeftButton");
	ArenaMover:Hide();
	ArenaMover:SetScript("OnDragStart", function(self) self:StartMoving(); end);
	ArenaMover:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
		SaveArenaMoverPosition();
	end);
	ArenaMover.bg = ArenaMover:CreateTexture(nil, "BACKGROUND");
	ArenaMover.bg:SetAllPoints(true);
	ArenaMover.bg:SetTexture(0.2, 0.8, 0.2, 0.25);
	LoadArenaMoverPosition();
end

local function ForceCreateArenaFrames()
	for i = 1, MOVER_ARENA_COUNT do
		if not _G["ArenaEnemyFrame"..i] then
			CreateFrame("Button", "ArenaEnemyFrame"..i, UIParent, "ArenaEnemyFrameTemplate");
		end
	end
end

local function EnsureArenaAnchor()
	if _G["NidhausArenaEnemyFrames"] then return; end
	local anchor = CreateFrame("Frame", "NidhausArenaEnemyFrames", UIParent);
	local scale = C.ArenaFrameScale or 1.5;
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then scale = 1.5; end
	anchor:SetSize(180 * scale, CalcMoverHeight(scale, nil));
	local savedPos;
	if NidhausUnitFramesDB and NidhausUnitFramesDB.positions then
		savedPos = NidhausUnitFramesDB.positions["ArenaMover"]
		        or NidhausUnitFramesDB.positions["NidhausArenaAnchor"];
	end
	if savedPos then
		-- FIX: Leer con nombres (nuevo) o con índices (legacy)
		local point = savedPos.point or savedPos[1];
		local relName = savedPos.relativeTo or savedPos[2];
		local relPoint = savedPos.relativePoint or savedPos[3];
		local x = savedPos.x or savedPos[4];
		local y = savedPos.y or savedPos[5];
		anchor:SetPoint(point, _G[relName] or UIParent, relPoint, x, y);
	elseif C.ArenaFramePoint then
		anchor:SetPoint(unpack(C.ArenaFramePoint));
	else
		anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -390, -330);
	end
end

-- FIX: Detectar si estamos en arena activa
local function InLiveArena()
	local _, instanceType = IsInInstance();
	return instanceType == "arena";
end

local function HideTestFrames()
	-- sArena pattern: frames nunca se reparentearon ni se les cambió la escala.
	-- Solo hay que ocultarlos y limpiar datos fake.
	for i = 1, MOVER_ARENA_COUNT do
		local frame = _G["ArenaEnemyFrame"..i];
		if frame then
			-- Pet frame: restaurar Hide original y ocultar
			local petFrame = _G["ArenaEnemyFrame"..i.."PetFrame"];
			if petFrame then
				if petFrame._origHide then
					petFrame.Hide = petFrame._origHide;
					petFrame._origHide = nil;
				end
				petFrame._testMode = nil;
				petFrame:Hide();
			end
			-- Cast bar: ocultar
			local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
			if castBar then
				castBar.fadeOut = nil;
				castBar.flash = nil;
				if CastingBarFrame_FinishSpell then
					pcall(CastingBarFrame_FinishSpell, castBar);
				else
					castBar:Hide();
				end
			end
			-- Ocultar el frame (no reparentar — ya está en ArenaEnemyFrames)
			frame:Hide();
		end
	end
end

local function RestoreTrinketPositions()
	local saved = K.GetSavedTrinketPos and K.GetSavedTrinketPos();
	if not saved then return; end
	local trinketCore = ns.ArenaFrame_Trinkets;
	if not trinketCore or not trinketCore.frames then return; end
	for i = 1, MAX_ARENA_ENEMIES do
		local tf = trinketCore.frames[i];
		if tf and tf.border then
			local arenaFrame = _G["ArenaEnemyFrame"..i];
			if arenaFrame then
				tf.border:ClearAllPoints();
				tf.border:SetPoint(saved[1], arenaFrame, saved[2], saved[3], saved[4]);
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════
-- "Drag to move" overlay — estilo Gladius
-- Barra de título oscura arriba del anchor, draggable, con botón X
-- ═══════════════════════════════════════════════════════════
local dragOverlay;

local function CreateDragOverlay(anchor)
	if dragOverlay then return dragOverlay; end

	-- Barra de título (estilo Gladius): fondo oscuro, texto blanco, arriba del anchor
	dragOverlay = CreateFrame("Frame", "NUF_ArenaDragOverlay", UIParent);
	dragOverlay:SetFrameStrata("HIGH");
	dragOverlay:SetFrameLevel(10);
	dragOverlay:SetHeight(36);
	dragOverlay:EnableMouse(true);
	dragOverlay:SetMovable(true);
	dragOverlay:RegisterForDrag("LeftButton");
	dragOverlay:SetClampedToScreen(true);
	dragOverlay:Hide();

	-- Fondo oscuro sólido (estilo Gladius)
	dragOverlay:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	dragOverlay:SetBackdropColor(0.1, 0.1, 0.1, 0.92);
	dragOverlay:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8);

	-- Title text: "NUF - drag to move" (top portion)
	local text = dragOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	text:SetPoint("TOP", dragOverlay, "TOP", 0, -6);
	text:SetText("NUF - drag to move");
	text:SetTextColor(1, 1, 1, 1);
	text:SetShadowOffset(1, -1);
	text:SetShadowColor(0, 0, 0, 1);
	dragOverlay.text = text;

	-- Hint text: "†Shift+Alt+Click to move various elements" (below title)
	local hint = dragOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	hint:SetPoint("TOP", text, "BOTTOM", 0, -1);
	hint:SetText("|cffFFAA00\226\128\160Shift+Alt+Click to move various elements|r");
	hint:SetFont("Fonts\\FRIZQT__.TTF", 8, "");
	dragOverlay.hint = hint;

	-- Botón X para cerrar (estilo Gladius)
	local closeBtn = CreateFrame("Button", nil, dragOverlay, "UIPanelCloseButton");
	closeBtn:SetPoint("TOPRIGHT", dragOverlay, "TOPRIGHT", 2, 2);
	closeBtn:SetWidth(22);
	closeBtn:SetHeight(22);
	closeBtn:SetScript("OnClick", function()
		if K.ToggleArenaFramesMover then
			K.ToggleArenaFramesMover();
		end
	end);
	dragOverlay.closeBtn = closeBtn;

	-- Drag handlers: mover el anchor desde la barra de título
	dragOverlay:SetScript("OnDragStart", function(self)
		local a = self._anchor;
		if a then a:StartMoving(); end
	end);
	dragOverlay:SetScript("OnDragStop", function(self)
		local a = self._anchor;
		if not a then return; end
		a:StopMovingOrSizing();
		-- Guardar posición
		local point, relativeTo, relativePoint, x, y = a:GetPoint();
		if point then
			if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
			if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
			local relName = relativeTo and relativeTo:GetName() or "UIParent";
			NidhausUnitFramesDB.positions["ArenaMover"] = {
				point = point, relativeTo = relName,
				relativePoint = relativePoint, x = x, y = y,
			};
		end
		-- Sincronizar anchor → position saver
		if K.UpdateArenaPosition then
			local p2, r2, rp2, x2, y2 = a:GetPoint();
			if p2 then
				local rn2 = r2 and r2:GetName() or "UIParent";
				K.UpdateArenaPosition(p2, rn2, rp2, x2, y2);
			end
		end
	end);

	return dragOverlay;
end

local function ShowDragOverlay(anchor)
	local overlay = CreateDragOverlay(anchor);
	overlay._anchor = anchor;
	-- Posicionar: barra de título ARRIBA del anchor, mismo ancho
	overlay:ClearAllPoints();
	local scale = C.ArenaFrameScale or 1.5;
	overlay:SetWidth(180 * scale);
	overlay:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2);
	overlay:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 2);
	overlay:Show();
end

local function HideDragOverlay()
	if dragOverlay then dragOverlay:Hide(); end
end

local liveArenaOverlayActive = false;

-- ═══════════════════════════════════════════════════════════
-- FORCE HIDE (llamado desde FrameDragger, eventos, etc.)
-- ═══════════════════════════════════════════════════════════
function K.ForceHideArenaMover()
	if InCombatLockdown() then
		if not K._moverCombatClose then
			K._moverCombatClose = CreateFrame("Frame");
			K._moverCombatClose:RegisterEvent("PLAYER_REGEN_ENABLED");
			K._moverCombatClose:SetScript("OnEvent", function(s)
				s:UnregisterEvent("PLAYER_REGEN_ENABLED");
				K.ForceHideArenaMover();
			end);
		else
			K._moverCombatClose:RegisterEvent("PLAYER_REGEN_ENABLED");
		end
		return;
	end
	EnsureArenaMoverDB();

	-- Ocultar drag overlay (ambos modos)
	HideDragOverlay();
	liveArenaOverlayActive = false;

	-- Bloquear el anchor
	local anchor = _G["NidhausArenaEnemyFrames"];
	if anchor then
		anchor:SetMovable(false);
		anchor:EnableMouse(false);
	end

	-- Ocultar frames fake del test mode
	HideTestFrames();
	for i = 1, MOVER_ARENA_COUNT do
		local overlay = _G["NUF_CastBarDragOverlay"..i];
		if overlay then overlay:Hide(); end
	end
	if K.SetTrinketMouseState then K.SetTrinketMouseState(false); end

	NidhausUnitFramesDB.ArenaMover.IsShown = false;
	K._testModeActive = false;
end

-- ═══════════════════════════════════════════════════════════
-- ARENA EN VIVO: Solo mover el anchor, no tocar frames (sArena pattern)
-- ═══════════════════════════════════════════════════════════

local function ToggleLiveArena()
	local anchor = _G["NidhausArenaEnemyFrames"];
	if not anchor then return; end

	if not liveArenaOverlayActive then
		-- ACTIVAR: hacer anchor movible + mostrar overlay
		anchor:SetMovable(true);
		anchor:SetClampedToScreen(true);
		anchor:EnableMouse(true);
		ShowDragOverlay(anchor);
		liveArenaOverlayActive = true;
		-- FIX: NO setear IsShown = true. Eso activa escala individual
		-- en K.ApplyArenaScale y causa compound scale.
		print("|cff00ff00NUF:|r Arena frames unlocked. Drag to reposition.");
	else
		-- DESACTIVAR: guardar posición + bloquear anchor
		HideDragOverlay();

		-- Guardar posición del anchor
		local point, relativeTo, relativePoint, x, y = anchor:GetPoint();
		if point then
			if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
			if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
			local relName = relativeTo and relativeTo:GetName() or "UIParent";
			NidhausUnitFramesDB.positions["ArenaMover"] = {
				point = point, relativeTo = relName,
				relativePoint = relativePoint, x = x, y = y,
			};
		end

		anchor:SetMovable(false);
		anchor:EnableMouse(false);
		liveArenaOverlayActive = false;
		print("|cff00ff00NUF:|r Arena frames locked.");
	end
end

-- ═══════════════════════════════════════════════════════════
-- FUERA DE ARENA: Test mode completo con datos fake
-- ═══════════════════════════════════════════════════════════
local function ToggleTestMode()
	EnsureArenaMoverDB();
	local anchor = _G["NidhausArenaEnemyFrames"];
	if not anchor then return; end

	if not NidhausUnitFramesDB.ArenaMover.IsShown then
		-- sArena pattern: asegurar jerarquía normal ANTES de mostrar frames.
		-- ArenaFrames_OnLoad setea: ArenaEnemyFrames:SetParent(anchor),
		-- ArenaEnemyFrame1:SetPoint("TOPLEFT", anchor), y ArenaEnemyFrames:SetScale(C.ArenaFrameScale).
		-- IMPORTANTE: llamar ANTES de _testModeActive para que ArenaFramesSettings no sea bloqueado.
		if K.ArenaFrames_OnLoad and ArenaEnemyFrame1 and ArenaEnemyFrames then
			K.ArenaFrames_OnLoad();
		end

		-- AHORA bloquear hooks de escala (frame:Show dispara OnShow → K.ApplyArenaScale)
		K._testModeActive = true;

		-- Asegurar que el anchor sea visible
		anchor:Show();
		if ArenaEnemyFrames then ArenaEnemyFrames:Show(); end

		-- Hacer el anchor draggable + mostrar overlay
		anchor:SetMovable(true);
		anchor:SetClampedToScreen(true);
		anchor:EnableMouse(true);
		ShowDragOverlay(anchor);

		-- Mostrar frames con datos fake (NO reparentar, NO cambiar escala)
		for i = 1, MOVER_ARENA_COUNT do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame then
				frame:Show();

				if frame.name then frame.name:SetText("arena"..i); end

				local randomClass = classIcons[math.random(1, #classIcons)];
				if frame.classPortrait then
					if K.IsFlatModeActive and K.IsFlatModeActive() then
						frame.classPortrait:SetTexture("Interface\\WorldStateFrame\\ICONS-CLASSES");
					else
						frame.classPortrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles");
					end
					if CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[randomClass] then
						frame.classPortrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[randomClass]));
					end
				end

				local cc = classColors[randomClass] or {0, 1, 0};
				if frame.healthbar then
					frame.healthbar:SetMinMaxValues(0, 100);
					frame.healthbar:SetValue(100);
					if C.classColor then
						frame.healthbar:SetStatusBarColor(cc[1], cc[2], cc[3]);
					else
						frame.healthbar:SetStatusBarColor(0, 1, 0);
					end
					if frame.healthbar.TextString then
						frame.healthbar.TextString:SetText("28000 / 35000");
					end
				end
				if frame.manabar then
					frame.manabar:SetMinMaxValues(0, 100);
					frame.manabar:SetValue(100);
					frame.manabar:SetStatusBarColor(0, 0, 1);
					if frame.manabar.TextString then
						frame.manabar.TextString:SetText("100 / 100");
					end
				end

				local petFrame = _G["ArenaEnemyFrame"..i.."PetFrame"];
				if petFrame then
					if C.ArenaPetFrameShow then
						if not petFrame._origHide then
							petFrame._origHide = petFrame.Hide;
						end
						petFrame.Hide = function() end;
						petFrame._testMode = true;
						petFrame:Show();
						if petFrame.healthbar then
							petFrame.healthbar:SetMinMaxValues(0, 100);
							petFrame.healthbar:SetValue(100);
							petFrame.healthbar:SetStatusBarColor(0, 1, 0);
						end
						if petFrame.manabar then
							petFrame.manabar:SetMinMaxValues(0, 100);
							petFrame.manabar:SetValue(100);
							petFrame.manabar:SetStatusBarColor(0, 0, 1);
						end
					else
						petFrame:Hide();
					end
				end
			end
		end

		-- Aplicar estilos (flat/custom/blizzard) sin tocar escala
		if K.StyleSingleArenaFrame then
			for i = 1, MOVER_ARENA_COUNT do
				local af = _G["ArenaEnemyFrame"..i];
				if af then K.StyleSingleArenaFrame(af, i); end
			end
		end

		-- Mostrar cast bars con datos fake
		for i = 1, MOVER_ARENA_COUNT do
			local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
			if castBar then
				castBar.fadeOut = nil;
				castBar.flash = nil;
				castBar:SetAlpha(1);
				castBar:SetMinMaxValues(0, 100);
				castBar:SetValue(50);
				castBar:Show();
				local barIcon = _G[castBar:GetName().."Icon"];
				if barIcon then
					local numIcons = GetNumMacroIcons and GetNumMacroIcons() or 100;
					if numIcons > 0 then
						local iconTex = GetMacroIconInfo and GetMacroIconInfo(math.random(1, numIcons));
						if iconTex then barIcon:SetTexture(iconTex); end
					end
					barIcon:Show();
				end
				local barText = _G[castBar:GetName().."Text"];
				if barText then barText:SetText(GetSpellInfo(118) or "Polymorph"); end
				local barSpark = _G[castBar:GetName().."Spark"];
				if barSpark then
					barSpark:SetPoint("CENTER", castBar, "LEFT", castBar:GetWidth() * 0.5, barSpark.offsetY or 2);
					barSpark:Show();
				end
			end
		end

		-- Aplicar tamaño/escala de castbar (solo castbar, no frames)
		if C.ArenaCastBarEnable then
			for i = 1, MOVER_ARENA_COUNT do
				local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
				if castBar then
					if C.ArenaCastBarScale then castBar:SetScale(C.ArenaCastBarScale); end
					if C.ArenaCastBarWidth then castBar:SetWidth(C.ArenaCastBarWidth); end
				end
			end
		end

		RestoreTrinketPositions();
		if K.ApplyArenaSpacing then K.ApplyArenaSpacing(); end
		if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
		if C.ArenaPetFrameShow and K.IsFlatModeActive and K.IsFlatModeActive() and C.ArenaFlatPetStyle then
			if K.ApplyFlatPetFrames then K.ApplyFlatPetFrames(); end
		end

		-- Crear overlay frames para drag de castbars (Shift+Alt+Click)
		for i = 1, MOVER_ARENA_COUNT do
			local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
			if castBar then
				local overlayName = "NUF_CastBarDragOverlay"..i;
				local overlay = _G[overlayName];
				if not overlay then
					overlay = CreateFrame("Frame", overlayName, castBar);
					overlay:SetAllPoints(castBar);
					overlay:SetFrameStrata("TOOLTIP");
					overlay:EnableMouse(true);
					overlay:SetMovable(true);
					overlay._castBar = castBar;
					overlay._index = i;

					overlay:SetScript("OnMouseDown", function(self, button)
						if button ~= "LeftButton" then return; end
						if InCombatLockdown() then return; end
						if IsShiftKeyDown() and IsAltKeyDown() then
							local cb = self._castBar;
							cb:SetMovable(true);
							cb:StartMoving();
							cb:SetUserPlaced(false);
							cb._isMoving = true;
						end
					end);

					overlay:SetScript("OnMouseUp", function(self, button)
						if button ~= "LeftButton" then return; end
						local cb = self._castBar;
						if not cb._isMoving then return; end
						cb:StopMovingOrSizing();
						cb._isMoving = false;

						local idx = self._index;
						local arenaFrame = _G["ArenaEnemyFrame"..idx];
						if not arenaFrame then return; end

						local parentX, parentY = arenaFrame:GetCenter();
						local frameX, frameY = cb:GetCenter();
						if not parentX or not frameX then return; end

						local scale = cb:GetScale();
						local offsetX = ((frameX * scale) - parentX) / scale;
						local offsetY = ((frameY * scale) - parentY) / scale;
						offsetX = math.floor(offsetX * 10 + 0.5) / 10;
						offsetY = math.floor(offsetY * 10 + 0.5) / 10;

						cb:ClearAllPoints();
						cb:SetPoint("CENTER", arenaFrame, "CENTER", offsetX, offsetY);

						if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
						if not NidhausUnitFramesDB.CastBarPositions then NidhausUnitFramesDB.CastBarPositions = {}; end
						local posKey = K.GetArenaPositionKey and K.GetArenaPositionKey() or (C.ArenaMirrorMode and "mirror" or "normal");
						NidhausUnitFramesDB.CastBarPositions[posKey] = {"CENTER", "CENTER", offsetX, offsetY};

						-- Sync ALL cast bars via single source of truth
						for j = 1, MOVER_ARENA_COUNT do
							if K.PositionArenaCastBar then
								K.PositionArenaCastBar(j);
							end
						end
					end);
				end
				overlay:Show();
			end
		end

		if K.RestoreCastBarPositions then K.RestoreCastBarPositions(); end

		if K.SetTrinketMouseState then K.SetTrinketMouseState(true); end

		NidhausUnitFramesDB.ArenaMover.IsShown = true;
	else
		-- CERRAR TEST MODE
		-- Guardar posición del anchor
		local point, relativeTo, relativePoint, x, y = anchor:GetPoint();
		if point then
			if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
			local relName = relativeTo and relativeTo:GetName() or "UIParent";
			NidhausUnitFramesDB.positions["ArenaMover"] = {
				point = point, relativeTo = relName,
				relativePoint = relativePoint, x = x, y = y,
			};
			if K.UpdateArenaPosition then
				K.UpdateArenaPosition(point, relName, relativePoint, x, y);
			end
		end

		HideDragOverlay();
		anchor:SetMovable(false);
		anchor:EnableMouse(false);

		HideTestFrames();
		for i = 1, MOVER_ARENA_COUNT do
			local overlay = _G["NUF_CastBarDragOverlay"..i];
			if overlay then overlay:Hide(); end
		end
		NidhausUnitFramesDB.ArenaMover.IsShown = false;
		K._testModeActive = false;
		if K.SetTrinketMouseState then K.SetTrinketMouseState(false); end
	end
end

-- ═══════════════════════════════════════════════════════════
-- TOGGLE PRINCIPAL: decide qué camino tomar
-- ═══════════════════════════════════════════════════════════
function K.ToggleArenaFramesMover()
	if not C then return; end
	if InCombatLockdown() then
		print("|cffFF0000NUF:|r Cannot toggle arena mover in combat.");
		return;
	end
	EnsureArenaMoverDB();
	if not C.ArenaFrameOn then
		if NidhausUnitFramesDB.ArenaMover.IsShown then K.ForceHideArenaMover(); end
		return;
	end
	if not IsAddOnLoaded("Blizzard_ArenaUI") then LoadAddOn("Blizzard_ArenaUI"); end

	if InLiveArena() then
		ToggleLiveArena();
	else
		-- Fuera de arena: test mode con datos fake (sArena pattern)
		ForceCreateArenaFrames();
		EnsureArenaAnchor();
		ToggleTestMode();
	end
end

function K.ResetArenaMoverPosition()
	if not ArenaMover then return; end
	EnsureArenaMoverDB();
	HideDragOverlay();
	if K.ResetArenaPosition then K.ResetArenaPosition(); end
	if C.ArenaFramePoint then
		ArenaMover:ClearAllPoints();
		ArenaMover:SetPoint(unpack(C.ArenaFramePoint));
	end
	HideTestFrames();
	ArenaMover:Hide();
	NidhausUnitFramesDB.ArenaMover.IsShown = false;
	HideMoverBG();
end

function K.UpdateArenaMoverSize(scale) UpdateArenaMoverSize(scale); end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	if not C.ArenaFrameOn then return; end
	CreateArenaMover();
end);

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS");
eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE");
eventFrame:RegisterEvent("PLAYER_LOGOUT");
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD");

eventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" then
		-- FIX: Guardar desde el ANCHOR (NidhausArenaEnemyFrames), no desde NUF_ArenaMover.
		-- En test mode el drag overlay mueve el anchor directamente, pero NUF_ArenaMover
		-- nunca se actualiza. Si guardamos desde NUF_ArenaMover, sobreescribimos la
		-- posición correcta con datos stale y el /reload pierde la posición del usuario.
		local anchor = _G["NidhausArenaEnemyFrames"];
		if anchor then
			local point, relativeTo, relativePoint, x, y = anchor:GetPoint();
			if point then
				if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
				if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
				local relName = relativeTo and relativeTo:GetName() or "UIParent";
				NidhausUnitFramesDB.positions["ArenaMover"] = {
					point = point, relativeTo = relName,
					relativePoint = relativePoint, x = x, y = y,
				};
				if K.UpdateArenaPosition then
					K.UpdateArenaPosition(point, relName, relativePoint, x, y);
				end
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- FIX: Cerrar mover/overlay al entrar a cualquier zona nueva.
		if NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover then
			if NidhausUnitFramesDB.ArenaMover.IsShown then
				K.ForceHideArenaMover();
			end
		end
		-- FIX: Aplicar escala guardada al entrar al mundo/arena.
		-- Antes la escala solo se aplicaba cuando se movía el slider o se usaba el test mode.
		-- En una arena real (sin haber abierto el mover antes), los frames quedaban en escala 1.0.
		if C and C.ArenaFrameOn and C.ArenaFrameScale then
			if K.UpdateArenaScale then
				K.UpdateArenaScale(C.ArenaFrameScale);
			end
		end
		UpdateArenaMoverBackground();
	else
		UpdateArenaMoverBackground();
		if event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" or event == "ARENA_OPPONENT_UPDATE" then
			-- FIX 1 (Gladius pattern): Auto-disable test mode when real opponents detected.
			-- Gladius does this explicitly to prevent fake data from overwriting real enemy info.
			if K._testModeActive or (NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
				and NidhausUnitFramesDB.ArenaMover.IsShown) then
				K.ForceHideArenaMover();
			end
			if K.SetupArenaCtrlShiftDrag then K.SetupArenaCtrlShiftDrag(); end
			-- FIX: Re-aplicar escala en cada evento de arena. Blizzard puede resetear
			-- los frames al hacer show/hide, lo que elimina la escala aplicada previamente.
			-- Esto también corrige el caso en que el slider se mueve y el valor queda
			-- guardado pero no se refleja hasta la siguiente arena.
			if C and C.ArenaFrameOn and C.ArenaFrameScale then
				if K.ApplyArenaScale then
					K.ApplyArenaScale(C.ArenaFrameScale);
				elseif K.UpdateArenaScale then
					K.UpdateArenaScale(C.ArenaFrameScale);
				end
			end
		end
	end
end);