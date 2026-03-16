local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- FrameDragger.lua
--
-- Permite arrastrar frames cuando:
--   SetPositions = true  AND  LockPositions = false
--
-- Modos de Party:
--   PartyIndividualMove = false → mueve todo el grupo junto
--   PartyIndividualMove = true  → mueve cada party frame por separado
--
-- Controles:
--   Shift + Alt + Click Izquierdo = Arrastrar frame
--   La posición se guarda automáticamente al soltar

local isInitialized = false;
local dragOverlays = {};
local draggers = {};
local isShowingOverlays = false;

-- POSITION SAVING / LOADING

local function EnsurePositionsTable()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
end

local function SaveFramePosition(key, frame)
	EnsurePositionsTable();
	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1);
	local relName = "UIParent";
	if relativeTo and relativeTo.GetName then
		relName = relativeTo:GetName() or "UIParent";
	end
	NidhausUnitFramesDB.positions[key] = {
		point = point,
		relativeTo = relName,
		relativePoint = relativePoint,
		x = x,
		y = y,
	};
end

function K.GetSavedPosition(key)
	if NidhausUnitFramesDB and NidhausUnitFramesDB.positions and NidhausUnitFramesDB.positions[key] then
		return NidhausUnitFramesDB.positions[key];
	end
	return nil;
end

function K.ClearSavedPosition(key)
	if NidhausUnitFramesDB and NidhausUnitFramesDB.positions then
		NidhausUnitFramesDB.positions[key] = nil;
	end
end

-- RESET POSITIONS & SCALE

function K.ResetPositionsAndScale()
	EnsurePositionsTable();

	-- Clear ALL saved positions
	NidhausUnitFramesDB.positions = {};

	-- FIX: Setear valores directamente en vez de llamar SaveConfig 7 veces
	-- (cada SaveConfig dispara CONFIG_CHANGED → callbacks se ejecutan 7 veces)
	local scaleDefaults = {
		PlayerFrameScale = 1.0,
		TargetFrameScale = 1.0,
		FocusScale = 1.0,
		FocusSpellBarScale = 1.2,
		PartyFrameScale = 1.0,
		ArenaFrameScale = 1.5,
		BossFrameScale = 0.65,
	};
	for key, val in pairs(scaleDefaults) do
		C[key] = val;
		NidhausUnitFramesDB[key] = val;
	end

	-- Apply scales immediately
	if NidhausPlayerFrame then NidhausPlayerFrame:SetScale(1.0); end
	if TargetFrame then TargetFrame:SetScale(1.0); end
	if FocusFrame then FocusFrame:SetScale(1.0); end
	if FocusFrameSpellBar then FocusFrameSpellBar:SetScale(1.2); end
	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then pf:SetScale(1.0); end
	end

	-- Reset C[] position tables to original defaults from Settings.lua
	C.PlayerFramePoint = {"TOPLEFT", UIParent, "TOPLEFT", 239, -4};
	C.TargetFramePoint = {"TOPLEFT", UIParent, "TOPLEFT", 509, -4};
	C.PartyMemberFramePoint = {"TOPLEFT", UIParent, "TOPLEFT", 10, -160};
	C.BossTargetFramePoint = {"TOPLEFT", UIParent, "TOPLEFT", 1300, -220};
	C.ArenaFramePoint = {"TOPRIGHT", UIParent, "TOPRIGHT", -390, -330};

	-- FIX: Si PartyMode3v3 está activo, re-aplicar 3v3 en vez de reparentar al container
	if C.SetPositions and C.PartyMode3v3 and K.Apply3v3PartyMode then
		K.Apply3v3PartyMode();
	else
		-- Re-anchor party frames to the container (undo individual move)
		if K.NidhausPartyFrame then
			for i = 1, MAX_PARTY_MEMBERS do
				local pf = _G["PartyMemberFrame"..i];
				if pf then
					pf:SetParent(K.NidhausPartyFrame);
					pf:ClearAllPoints();
					if i == 1 then
						pf:SetPoint("TOPLEFT", K.NidhausPartyFrame, "TOPLEFT");
					else
						local prevPet = _G["PartyMemberFrame"..(i-1).."PetFrame"];
						if prevPet then
							pf:SetPoint("TOPLEFT", prevPet, "BOTTOMLEFT", -23, -10 - (C.PartyMemberFrameSpacing or 0));
						else
							pf:SetPoint("TOPLEFT", _G["PartyMemberFrame"..(i-1)], "BOTTOMLEFT", 0, -10 - (C.PartyMemberFrameSpacing or 0));
						end
					end
				end
			end
		end
	end

	-- Force re-position ALL frames using the reset C[] values
	-- Player frame
	if NidhausPlayerFrame and C.SetPositions then
		NidhausPlayerFrame:ClearAllPoints();
		NidhausPlayerFrame:SetPoint(unpack(C.PlayerFramePoint));
	elseif NidhausPlayerFrame and C.PlayerFrame_BlizzardDefault then
		NidhausPlayerFrame:ClearAllPoints();
		local pos = C.PlayerFrame_BlizzardDefault;
		local relFrame = _G[pos.relativeTo] or UIParent;
		NidhausPlayerFrame:SetPoint(pos.point, relFrame, pos.relativePoint, pos.x, pos.y);
	end

	-- Target frame
	if TargetFrame then
		TargetFrame:ClearAllPoints();
		if C.SetPositions then
			TargetFrame:SetPoint(unpack(C.TargetFramePoint));
		elseif C.TargetFrame_BlizzardDefault then
			local pos = C.TargetFrame_BlizzardDefault;
			local relFrame = _G[pos.relativeTo] or UIParent;
			TargetFrame:SetPoint(pos.point, relFrame, pos.relativePoint, pos.x, pos.y);
		end
	end

	-- Party container (skip if 3v3 is active, since 3v3 parents frames to UIParent directly)
	if not (C.SetPositions and C.PartyMode3v3) then
		if K.NidhausPartyFrame and C.SetPositions and C.PartyMemberFramePoint then
			K.NidhausPartyFrame:ClearAllPoints();
			K.NidhausPartyFrame:SetPoint(unpack(C.PartyMemberFramePoint));
		end
	end

	-- Boss container
	if K.NidhausBossFrame and C.SetPositions and C.BossTargetFramePoint then
		K.NidhausBossFrame:ClearAllPoints();
		K.NidhausBossFrame:SetPoint(unpack(C.BossTargetFramePoint));
	end

	-- Arena anchor
	local arenaAnchor = _G["NidhausArenaEnemyFrames"];
	if arenaAnchor and C.ArenaFramePoint then
		arenaAnchor:ClearAllPoints();
		arenaAnchor:SetPoint(unpack(C.ArenaFramePoint));
	end

	-- Reset arena mover position too
	if NidhausUnitFramesDB.ArenaMover then
		NidhausUnitFramesDB.ArenaMover = { IsShown = false };
	end

	-- Reset castbar and trinket saved positions
	NidhausUnitFramesDB.CastBarPositions = nil;
	NidhausUnitFramesDB.TrinketPositions = nil;

	-- Hide arena mover if shown
	if K.ForceHideArenaMover then
		K.ForceHideArenaMover();
	end

	-- NOTA: No se necesita disparar CONFIG_CHANGED aquí porque esta función
	-- ya aplica todos los cambios de escala y posición directamente arriba.
	-- (Antes cada SaveConfig disparaba CONFIG_CHANGED 7 veces innecesariamente)

	print("|cff00FF00NUF:|r " .. (L["RESET_POS_DONE"] or "Positions & scale reset!"));
end

-- DRAG OVERLAY

local function CreateDragOverlay(frame, key, displayName, customWidth, customHeight)
	local overlay = CreateFrame("Frame", "NidhausDragOverlay_"..key, frame);
	if customWidth then
		overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
		overlay:SetSize(customWidth, customHeight);
	else
		overlay:SetAllPoints(frame);
	end
	overlay:SetFrameLevel(frame:GetFrameLevel() + 10);
	overlay:EnableMouse(false);
	overlay:Hide();

	local bg = overlay:CreateTexture(nil, "OVERLAY");
	bg:SetAllPoints();
	bg:SetTexture(0, 0.8, 0, 0.25);
	bg:SetDrawLayer("OVERLAY", 0);
	overlay.bg = bg;

	local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	text:SetPoint("CENTER");
	text:SetText(displayName);
	text:SetTextColor(1, 1, 1, 0.9);
	text:SetDrawLayer("OVERLAY", 1);
	overlay.text = text;

	overlay.key = key;
	overlay.targetFrame = frame;
	overlay.displayName = displayName;

	return overlay;
end

-- MAKE FRAME DRAGGABLE

local function MakeFrameDraggable(frame, key, displayName, customWidth, customHeight)
	if not frame then return; end

	local overlay = CreateDragOverlay(frame, key, displayName, customWidth, customHeight);
	dragOverlays[key] = overlay;

	frame:SetMovable(true);
	frame:SetClampedToScreen(true);

	local dragger = CreateFrame("Button", "NidhausDragger_"..key, frame);
	if customWidth then
		dragger:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
		dragger:SetSize(customWidth, customHeight);
	else
		dragger:SetAllPoints(frame);
	end
	dragger:SetFrameLevel(frame:GetFrameLevel() + 11);
	dragger:RegisterForDrag("LeftButton");
	dragger:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	dragger:EnableMouse(false);
	dragger:Hide();

	dragger.key = key;
	dragger.targetFrame = frame;
	dragger.overlay = overlay;
	dragger.displayName = displayName;

	dragger:SetScript("OnDragStart", function(self)
		if not C.SetPositions or C.LockPositions then return; end
		if IsShiftKeyDown() and IsAltKeyDown() then
			-- Para party frames individuales, re-anclar a UIParent antes de mover
			if self.isPartyIndividual then
				local pf = self.targetFrame;
				-- FIX: Solo re-parentar si aún no es hijo de UIParent (en 3v3 ya lo es)
				if pf:GetParent() ~= UIParent then
					pf:SetParent(UIParent);
				end
				-- Obtener posición actual en pantalla para no saltar
				local scale = pf:GetEffectiveScale();
				local left, bottom = pf:GetLeft(), pf:GetBottom();
				if left and bottom then
					pf:ClearAllPoints();
					pf:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom);
				end
			end
			self.targetFrame:StartMoving();
			self.isDragging = true;
			self.overlay.bg:SetTexture(1, 0.8, 0, 0.35);
			self.overlay.text:SetText(self.displayName .. " (...)");
		end
	end);

	-- Función compartida para detener el drag
	local function StopDragging(self)
		if not self.isDragging then return; end
		self.targetFrame:StopMovingOrSizing();
		self.isDragging = false;
		self.overlay.bg:SetTexture(0, 0.8, 0, 0.25);
		self.overlay.text:SetText(self.displayName);

		SaveFramePosition(self.key, self.targetFrame);

		local pos = K.GetSavedPosition(self.key);
		if pos and not self.isPartyIndividual then
			local cKey = key.."Point";
			C[cKey] = {pos.point, _G[pos.relativeTo] or UIParent, pos.relativePoint, pos.x, pos.y};
		end
	end

	dragger:SetScript("OnDragStop", function(self) StopDragging(self); end);

	-- Fallback: OnMouseUp también detiene el drag (fix party individual bug)
	dragger:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then StopDragging(self); end
	end);

	dragger:SetScript("OnClick", function(self, button)
		-- Passthrough
	end);

	return dragger;
end

-- ENABLE / DISABLE DRAG MODE

local function EnableDragMode()
	local individualMode = C.PartyIndividualMove;

	for key, dragger in pairs(draggers) do
		local isPartyGroup = (key == "PartyMemberFrame");
		local isPartyIndiv = key:find("^PartyMemberFrame%d$");

		-- Mostrar según el modo
		local shouldShow = true;
		if isPartyGroup and individualMode then shouldShow = false; end
		if isPartyIndiv and not individualMode then shouldShow = false; end

		if shouldShow then
			dragger:EnableMouse(true);
			dragger:Show();
			if dragOverlays[key] then
				dragOverlays[key]:Show();
			end
		else
			dragger:EnableMouse(false);
			dragger:Hide();
			if dragOverlays[key] then
				dragOverlays[key]:Hide();
			end
		end
	end
end

local function DisableDragMode()
	for key, dragger in pairs(draggers) do
		if dragger.isDragging then
			dragger.targetFrame:StopMovingOrSizing();
			dragger.isDragging = false;
		end
		dragger:EnableMouse(false);
		dragger:Hide();
		if dragOverlays[key] then
			dragOverlays[key]:Hide();
		end
	end
end

-- FIX: Usar MODIFIER_STATE_CHANGED en vez de OnUpdate cada frame
-- (antes corría ~60-144 veces/segundo constantemente)
local pollFrame = CreateFrame("Frame");
pollFrame:RegisterEvent("MODIFIER_STATE_CHANGED");

pollFrame:SetScript("OnEvent", function(self, event, key, state)
	if not isInitialized then return; end
	if not C.SetPositions or C.LockPositions then
		if isShowingOverlays then
			DisableDragMode();
			isShowingOverlays = false;
		end
		return;
	end

	local shiftAlt = IsShiftKeyDown() and IsAltKeyDown();
	if shiftAlt and not isShowingOverlays then
		EnableDragMode();
		isShowingOverlays = true;
	elseif not shiftAlt and isShowingOverlays then
		-- Force-stop any stuck drag first
		for _, dragger in pairs(draggers) do
			if dragger.isDragging then
				dragger.targetFrame:StopMovingOrSizing();
				dragger.isDragging = false;
				dragger.overlay.bg:SetTexture(0, 0.8, 0, 0.25);
				dragger.overlay.text:SetText(dragger.displayName);
				SaveFramePosition(dragger.key, dragger.targetFrame);
			end
		end
		DisableDragMode();
		isShowingOverlays = false;
	end
end);

-- APPLY INDIVIDUAL PARTY POSITIONS (from saved)

function K.ApplyIndividualPartyPositions()
	if not C.PartyIndividualMove then return; end

	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then
			local key = "PartyMemberFrame"..i;

			-- FIX: Si 3v3 está activo, cargar posición guardada si existe.
			-- Si no hay posición guardada, dejar el frame donde 3v3 lo puso
			-- (ya está parented a UIParent con la escala correcta).
			-- NO limpiar posiciones — eso borraba posiciones arrastradas.
			if C.PartyMode3v3 and C.SetPositions then
				local saved = K.GetSavedPosition(key);
				if saved then
					pf:SetParent(UIParent);
					pf:ClearAllPoints();
					local relFrame = _G[saved.relativeTo] or UIParent;
					pf:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				end
				-- If no saved position: frame is already at 3v3 position, don't touch
			else
				-- Modo normal (sin 3v3): comportamiento original
				local saved = K.GetSavedPosition(key);

				if not saved then
					-- No hay posición guardada → capturar posición actual en pantalla
					local scale = pf:GetEffectiveScale();
					local left, top = pf:GetLeft(), pf:GetTop();
					if left and top then
						local uiScale = UIParent:GetEffectiveScale();
						local x = left * scale / uiScale;
						local y = top * scale / uiScale - UIParent:GetHeight();
						pf:SetParent(UIParent);
						pf:ClearAllPoints();
						pf:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y);
						SaveFramePosition(key, pf);
					end
				else
					pf:SetParent(UIParent);
					pf:ClearAllPoints();
					local relFrame = _G[saved.relativeTo] or UIParent;
					pf:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				end
			end
		end
	end
end

-- Restaurar party frames al contenedor grupal
function K.RestorePartyToGroup()
	-- FIX: Si 3v3 está activo, restaurar a posiciones 3v3 en vez del container
	if C.SetPositions and C.PartyMode3v3 and K.Apply3v3PartyMode then
		K.Apply3v3PartyMode();
		return;
	end

	if not K.NidhausPartyFrame then return; end

	-- FIX #6: Asegurar posición del container antes de reparentar
	local containerSaved = K.GetSavedPosition("PartyMemberFrame");
	if containerSaved then
		K.NidhausPartyFrame:ClearAllPoints();
		local relFrame = _G[containerSaved.relativeTo] or UIParent;
		K.NidhausPartyFrame:SetPoint(containerSaved.point, relFrame, containerSaved.relativePoint,
			containerSaved.x, containerSaved.y);
	end

	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then
			pf:SetParent(K.NidhausPartyFrame);
			pf:ClearAllPoints();
			if i == 1 then
				pf:SetPoint("TOPLEFT", K.NidhausPartyFrame, "TOPLEFT");
			else
				local prevPet = _G["PartyMemberFrame"..(i-1).."PetFrame"];
				local spacing = C.PartyMemberFrameSpacing or 0;
				if prevPet then
					pf:SetPoint("TOPLEFT", prevPet, "BOTTOMLEFT", -23, -10 - spacing);
				else
					pf:SetPoint("TOPLEFT", _G["PartyMemberFrame"..(i-1)], "BOTTOMLEFT", 0, -10 - spacing);
				end
			end
		end
	end
end

-- INITIALIZATION

local function InitFrameDragger()
	if isInitialized then return; end

	-- PlayerFrame
	local playerFrame = _G["NidhausPlayerFrame"];
	if playerFrame then
		draggers["PlayerFrame"] = MakeFrameDraggable(playerFrame, "PlayerFrame", "Player");
	end

	-- TargetFrame
	if TargetFrame then
		draggers["TargetFrame"] = MakeFrameDraggable(TargetFrame, "TargetFrame", "Target");
	end

	-- PartyFrame grupo (contenedor)
	if K.NidhausPartyFrame then
		draggers["PartyMemberFrame"] = MakeFrameDraggable(
			K.NidhausPartyFrame, "PartyMemberFrame", "Party (All)", 130, 400
		);
	end

	-- PartyFrames individuales
	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then
			local key = "PartyMemberFrame"..i;
			local dragger = MakeFrameDraggable(pf, key, "Party "..i);
			dragger.isPartyIndividual = true;
			draggers[key] = dragger;
		end
	end

	-- Si hay posiciones individuales guardadas, aplicarlas
	if C.PartyIndividualMove then
		K.ApplyIndividualPartyPositions();
	end

	isInitialized = true;
end

function K.RegisterPartyDragger()
	if not isInitialized then return; end
	if K.NidhausPartyFrame and not draggers["PartyMemberFrame"] then
		draggers["PartyMemberFrame"] = MakeFrameDraggable(
			K.NidhausPartyFrame, "PartyMemberFrame", "Party (All)", 130, 400
		);
	end
end

-- Inicializar después de que todos los frames estén creados
K.RegisterConfigEvent("CONFIG_LOADED", function()
	local delayFrame = CreateFrame("Frame");
	delayFrame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil);
		InitFrameDragger();
	end);
end);