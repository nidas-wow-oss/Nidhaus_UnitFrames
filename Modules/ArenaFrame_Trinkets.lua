local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local select, pairs, _G, UnitFactionGroup, IsInInstance, GetSpellInfo, GetTime =
	select, pairs, _G, UnitFactionGroup, IsInInstance, GetSpellInfo, GetTime;
local CooldownFrame_SetTimer = CooldownFrame_SetTimer;
local PlaySoundFile = PlaySoundFile;

local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;

ns.ArenaFrame_Trinkets = CreateFrame("Frame");
local Core = ns.ArenaFrame_Trinkets;

Core:RegisterEvent("ADDON_LOADED");
Core:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end);

Core.addonLoaded = false;
Core.created = false;
Core.frames = {};

local function IsEnabled()
	return C.ArenaFrameOn and C.ArenaFrame_Trinkets;
end

-- Helper — obtener posición guardada de trinket según mirror mode actual
-- Misma lógica que castbar: guarda posición separada para mirror/normal
function K.GetSavedTrinketPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.TrinketPositions;
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

function Core:CreateTrinket(Frame, Index)
	if not Frame then 
		return;
	end
	
	local Border = CreateFrame("Frame", "NidhausArenaTrinketBorder"..Index, Frame);
	Border:SetFrameStrata("MEDIUM");

	-- FIX: Posición inicial según mirror mode y flat mode
	-- Sin esto, el trinket se crea SIEMPRE a la derecha y las funciones de
	-- reposicionamiento pueden no ejecutarse a tiempo.
	local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
	if isFlat and C.ArenaMirrorMode then
		Border:SetPoint("BOTTOMRIGHT", Frame, "BOTTOMLEFT", -8, 0);
	elseif isFlat then
		Border:SetPoint("BOTTOMLEFT", Frame, "BOTTOMRIGHT", 8, 0);
	elseif C.ArenaMirrorMode then
		Border:SetPoint("BOTTOMRIGHT", Frame, "BOTTOMLEFT", -8, 8);
	else
		Border:SetPoint("BOTTOMLEFT", Frame, "BOTTOMRIGHT", 8, 8);
	end

	Border:SetSize(32, 32);
	Border:SetMovable(true);
	-- Mouse deshabilitado por defecto; se activa solo en test mode + Flat style
	Border:EnableMouse(false);

	Border:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 4,
		insets = {left = 2, right = 2, top = 2, bottom = 2}
	});

	if C.darkFrames then
		Border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1);
	else
		Border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1);
	end

	local Trinket = CreateFrame("Frame", nil, Frame);
	Trinket:SetFrameStrata("MEDIUM");
	Trinket:SetFrameLevel(Border:GetFrameLevel() - 2);
	Trinket:SetPoint("CENTER", Border, 0, 0);
	Trinket:SetSize(32, 32);

	Trinket.icon = Trinket:CreateTexture(nil, "BACKGROUND");
	Trinket.icon:SetAllPoints();

	local faction = select(1, UnitFactionGroup("player"));
	if faction == "Alliance" then
		Trinket.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_01");
	elseif faction == "Horde" then
		Trinket.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_02");
	end

	local CoolDownFrame = CreateFrame("Cooldown", nil, Trinket, "CooldownFrameTemplate");
	CoolDownFrame:SetAllPoints(Trinket);

	-- sArena-style drag: OnMouseDown/OnMouseUp (NO OnUpdate)
	-- Funciona en Flat mode y en Test mode (Shift+Alt+Click)
	Border:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return; end
		if InCombatLockdown() then return; end
		-- Permitir drag en Flat mode O en test mode
		local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
		local isTestMode = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
			and NidhausUnitFramesDB.ArenaMover.IsShown;
		if not (isFlat or isTestMode) then return; end
		if IsShiftKeyDown() and IsAltKeyDown() and not self._isMoving then
			self:StartMoving();
			self:SetUserPlaced(false);
			self._isMoving = true;
		end
	end);

	Border:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then return; end
		if not self._isMoving then return; end
		self:StopMovingOrSizing();
		self._isMoving = false;

		local arenaFrame = self:GetParent();
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
		if not NidhausUnitFramesDB.TrinketPositions then NidhausUnitFramesDB.TrinketPositions = {}; end
		local posKey = K.GetArenaPositionKey and K.GetArenaPositionKey() or (C.ArenaMirrorMode and "mirror" or "normal");
		NidhausUnitFramesDB.TrinketPositions[posKey] = {"CENTER", "CENTER", offsetX, offsetY};

		for i = 1, MAX_ARENA_ENEMIES do
			local trinketFrame = Core.frames[i];
			if trinketFrame and trinketFrame.border then
				local af = _G["ArenaEnemyFrame"..i];
				if af then
					trinketFrame.border:ClearAllPoints();
					trinketFrame.border:SetPoint("CENTER", af, "CENTER", offsetX, offsetY);
				end
			end
		end
	end);

	-- Failsafe: stop drag si el frame se oculta
	Border:SetScript("OnHide", function(self)
		if self._isMoving then
			self:StopMovingOrSizing();
			self._isMoving = false;
		end
	end);

	-- Restaurar posición guardada o aplicar mirror mode en Flat
	if K.IsFlatModeActive and K.IsFlatModeActive() then
		local saved = K.GetSavedTrinketPos();
		if saved then
			Border:ClearAllPoints();
			Border:SetPoint(saved[1], Frame, saved[2], saved[3], saved[4]);
		elseif C.ArenaMirrorMode then
			Border:ClearAllPoints();
			Border:SetPoint("BOTTOMRIGHT", Frame, "BOTTOMLEFT", -8, 0);
		else
			Border:ClearAllPoints();
			Border:SetPoint("BOTTOMLEFT", Frame, "BOTTOMRIGHT", 8, 0);
		end
	end

	Core["arena"..Index] = CoolDownFrame;
	Core.frames[Index] = { border = Border, trinket = Trinket };

	if not IsEnabled() then
		Border:Hide();
		Trinket:Hide();
	end
end

function Core:TryCreate()
	if self.created then return end
	if not self.addonLoaded then return end
	
	local allFramesExist = true;
	for i = 1, MAX_ARENA_ENEMIES do
		if not _G["ArenaEnemyFrame"..i] then
			allFramesExist = false;
			break;
		end
	end
	
	if not allFramesExist then return end

	local success, err = pcall(function()
		for i = 1, MAX_ARENA_ENEMIES do
			self:CreateTrinket(_G["ArenaEnemyFrame"..i], i);
		end
	end);
	
	if not success then
		return;
	end

	self.created = true;
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:PLAYER_ENTERING_WORLD();
end

function Core:ShowAll()
	for i = 1, MAX_ARENA_ENEMIES do
		local f = self.frames[i];
		if f then
			f.border:Show();
			f.trinket:Show();
		end
	end
end

function Core:HideAll()
	for i = 1, MAX_ARENA_ENEMIES do
		local f = self.frames[i];
		if f then
			f.border:Hide();
			f.trinket:Hide();
		end
	end

	if self:IsEventRegistered("UNIT_SPELLCAST_SUCCEEDED") then
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	end

	for i = 1, MAX_ARENA_ENEMIES do
		if self["arena"..i] then
			CooldownFrame_SetTimer(self["arena"..i], GetTime(), 0, 1);
		end
	end
end

function Core:ApplyState()
	if not IsEnabled() then
		if self.created then
			self:HideAll();
		end
		return
	end

	-- FIX: Si Blizzard_ArenaUI ya está cargado pero ADDON_LOADED no se disparó
	-- (porque el addon se habilitó después del load), setear el flag manualmente.
	-- Sin esto, addonLoaded quedaba en false y TryCreate() nunca se ejecutaba.
	if not self.addonLoaded then
		if IsAddOnLoaded("Blizzard_ArenaUI") then
			self.addonLoaded = true;
		else
			LoadAddOn("Blizzard_ArenaUI");
			-- Si LoadAddOn tuvo éxito, setear flag (ADDON_LOADED puede no dispararse sincrónicamente)
			if IsAddOnLoaded("Blizzard_ArenaUI") then
				self.addonLoaded = true;
			end
		end
	end

	self:TryCreate();
	if self.created then
		self:ShowAll();
		self:PLAYER_ENTERING_WORLD();
	end
end

function Core:ADDON_LOADED(addonName)
	if addonName ~= "Blizzard_ArenaUI" then return; end
	self.addonLoaded = true;
	self:UnregisterEvent("ADDON_LOADED");
	self:ApplyState();
end

function Core:PLAYER_ENTERING_WORLD()
	if not IsEnabled() then
		if self:IsEventRegistered("UNIT_SPELLCAST_SUCCEEDED") then
			self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
		end
		return
	end

	local _, instanceType = IsInInstance();
	if instanceType == "arena" then
		if not self:IsEventRegistered("UNIT_SPELLCAST_SUCCEEDED") then
			self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
		end
	else
		if self:IsEventRegistered("UNIT_SPELLCAST_SUCCEEDED") then
			self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
		end
		for i = 1, MAX_ARENA_ENEMIES do
			if self["arena"..i] then
				CooldownFrame_SetTimer(self["arena"..i], GetTime(), 0, 1);
			end
		end
	end
end

function Core:UNIT_SPELLCAST_SUCCEEDED(unitID, spell)
	if not IsEnabled() then return end
	if not unitID:find("arena") or unitID:find("pet") then return end
	if not self[unitID] then return end

	local Voice = C.ArenaFrame_Trinket_Voice;

	if spell == GetSpellInfo(59752) or spell == GetSpellInfo(42292) then
		CooldownFrame_SetTimer(self[unitID], GetTime(), 120, 1);
		if Voice then
			local success, err = pcall(function()
				PlaySoundFile("Interface\\Addons\\"..AddOnName.."\\Media\\Voice\\Trinket.mp3");
			end);
		end
	elseif spell == GetSpellInfo(7744) then
		CooldownFrame_SetTimer(self[unitID], GetTime(), 45, 1);
		if Voice then
			local success, err = pcall(function()
				PlaySoundFile("Interface\\Addons\\"..AddOnName.."\\Media\\Voice\\WillOfTheForsaken.mp3");
			end);
		end
	end
end

function K.ToggleArenaTrinketsTracking(enabled)
	C.ArenaFrame_Trinkets = enabled and true or false;
	if ns and ns.ArenaFrame_Trinkets and ns.ArenaFrame_Trinkets.ApplyState then
		ns.ArenaFrame_Trinkets:ApplyState();
	end
end

-- Habilita/deshabilita mouse en trinkets. Funciona en Flat mode y Test mode.
function K.SetTrinketMouseState(state)
	if not Core.frames then return; end
	-- FIX: Also check K._testModeActive — the DB flag IsShown may not be set yet
	-- when this is called during test mode setup (timing issue)
	local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
	local isTestMode = K._testModeActive or (NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
		and NidhausUnitFramesDB.ArenaMover.IsShown);
	local enableMouse = state and (isFlat or isTestMode);
	for i = 1, MAX_ARENA_ENEMIES do
		local f = Core.frames[i];
		if f and f.border then
			f.border:EnableMouse(enableMouse or false);
			if not enableMouse and f.border._isMoving then
				f.border:StopMovingOrSizing();
				f.border._isMoving = false;
			end
		end
	end
end

-- FIX: Actualizar color del borde de trinkets cuando cambia darkFrames
-- Sin esto, cambiar el tema dark/light no actualiza los bordes hasta /reload
function K.UpdateTrinketBorderColors()
	if not Core.frames then return; end
	for i = 1, MAX_ARENA_ENEMIES do
		local f = Core.frames[i];
		if f and f.border then
			if C.darkFrames then
				f.border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1);
			else
				f.border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1);
			end
		end
	end
end