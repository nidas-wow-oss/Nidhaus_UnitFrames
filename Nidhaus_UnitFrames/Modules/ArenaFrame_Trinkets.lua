local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local select, pairs, _G, UnitFactionGroup, IsInInstance, GetSpellInfo, GetTime =
	select, pairs, _G, UnitFactionGroup, IsInInstance, GetSpellInfo, GetTime;
local CooldownFrame_SetTimer = CooldownFrame_SetTimer;
local PlaySoundFile = PlaySoundFile;

local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;
local MAX_PARTY = MAX_PARTY_MEMBERS or 4;
















local WOTF_COOLDOWN = 120;

local TRINKET_SPELLS = {
	[42292] = { cd = 120, voice = "Trinket" },
	[59752] = { cd = 120, voice = "Trinket" },
	[7744]  = { cd = WOTF_COOLDOWN, voice = "WillOfTheForsaken" },
};

ns.ArenaFrame_Trinkets = CreateFrame("Frame");
local Core = ns.ArenaFrame_Trinkets;

Core:RegisterEvent("ADDON_LOADED");
Core:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end);

Core.addonLoaded = false;
Core.created = false;
Core.frames = {};


Core.cooldowns = {};
Core.partyFrames = {};

Core.guidCache = {};

local function IsEnabled()
	return C.ArenaFrameOn and C.ArenaFrame_Trinkets;
end




local function AnyTrinketEnabled()
	return IsEnabled() or (C.PartyTrinketsEnabled == true);
end










local FLAT_DEFAULT = { "CENTER", "CENTER", 78.2, 9 };

function K.GetSavedTrinketPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.TrinketPositions;



	local isFlat = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);
	if isFlat then
		local key = K.GetArenaPositionKey and K.GetArenaPositionKey() or "Flat_normal";
		if not (db and db[key]) then return FLAT_DEFAULT; end
	end

	if not db then return nil; end

	if K.GetArenaPositionKey then
		local compositeKey = K.GetArenaPositionKey();
		if db[compositeKey] then return db[compositeKey]; end
	end

	local key = C.ArenaMirrorMode and "mirror" or "normal";
	return db[key] or db.global;
end

function Core:CreateTrinket(Frame, Index)
	if not Frame then 
		return;
	end
	
	local Border = CreateFrame("Frame", "NidhausArenaTrinketBorder"..Index, Frame);
	Border:SetFrameStrata("MEDIUM");




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



	Border:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return; end
		if InCombatLockdown() then return; end

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


	Border:SetScript("OnHide", function(self)
		if self._isMoving then
			self:StopMovingOrSizing();
			self._isMoving = false;
		end
	end);


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
	Core.cooldowns["arena"..Index] = CoolDownFrame;

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

	if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
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




	if not self.addonLoaded then
		if IsAddOnLoaded("Blizzard_ArenaUI") then
			self.addonLoaded = true;
		else
			LoadAddOn("Blizzard_ArenaUI");

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


	self:SetupPartyTrinkets();
	self:ShowPartyTrinkets(C.PartyTrinketsEnabled);

	if not AnyTrinketEnabled() then
		if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
		return
	end

	local _, instanceType = IsInInstance();
	if instanceType == "arena" then
		if not self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end

		self:WipeGUIDCache();
		if not self:IsEventRegistered("ARENA_OPPONENT_UPDATE") then
			self:RegisterEvent("ARENA_OPPONENT_UPDATE");
		end
		if not self:IsEventRegistered("PARTY_MEMBERS_CHANGED") then
			self:RegisterEvent("PARTY_MEMBERS_CHANGED");
		end
		self:RefreshGUIDCache();
	else

		if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
		if self:IsEventRegistered("ARENA_OPPONENT_UPDATE") then
			self:UnregisterEvent("ARENA_OPPONENT_UPDATE");
		end
		if self:IsEventRegistered("PARTY_MEMBERS_CHANGED") then
			self:UnregisterEvent("PARTY_MEMBERS_CHANGED");
		end
		self:WipeGUIDCache();
		for i = 1, MAX_ARENA_ENEMIES do
			if self["arena"..i] then
				CooldownFrame_SetTimer(self["arena"..i], GetTime(), 0, 1);
			end
		end
	end
end

















local function PartyTrinketDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.PartyTrinket then
		NidhausUnitFramesDB.PartyTrinket = {};
	end
	return NidhausUnitFramesDB.PartyTrinket;
end

local PT_DEFAULT_X, PT_DEFAULT_Y = 4, 0;

function Core:ApplyPartyTrinketLayout()
	local db   = PartyTrinketDB();
	local x    = db.x or PT_DEFAULT_X;
	local y    = db.y or PT_DEFAULT_Y;
	local size = C.PartyTrinketSize or 20;

	for i = 1, MAX_PARTY do
		local f = self.partyFrames[i];
		if f then
			f.holder:SetSize(size, size);
			f.holder:ClearAllPoints();
			f.holder:SetPoint("LEFT", f.holder:GetParent(), "RIGHT", x, y);
		end
	end
end

function Core:SetupPartyTrinkets()
	if not C.PartyTrinketsEnabled then return; end

	for i = 1, MAX_PARTY do
		local parent = _G["PartyMemberFrame"..i];
		if parent and not self.partyFrames[i] then
			local holder = CreateFrame("Frame", "NidhausPartyTrinket"..i, parent);
			holder:SetSize(C.PartyTrinketSize or 20, C.PartyTrinketSize or 20);
			holder:SetPoint("LEFT", parent, "RIGHT", PT_DEFAULT_X, PT_DEFAULT_Y);
			holder:SetFrameStrata("MEDIUM");
			holder:SetMovable(true);
			holder:EnableMouse(false);

			holder.icon = holder:CreateTexture(nil, "BACKGROUND");
			holder.icon:SetAllPoints();



			local faction = select(1, UnitFactionGroup("player"));
			if faction == "Horde" then
				holder.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_02");
			else
				holder.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_01");
			end

			local cd = CreateFrame("Cooldown", nil, holder, "CooldownFrameTemplate");
			cd:SetAllPoints(holder);


			holder.dragHint = holder:CreateTexture(nil, "OVERLAY");
			holder.dragHint:SetAllPoints();
			holder.dragHint:SetTexture(0, 0.7, 1, 0.35);
			holder.dragHint:Hide();


			holder:SetScript("OnMouseDown", function(self, button)
				if button ~= "LeftButton" or not Core.partyMoveMode then return; end
				if InCombatLockdown() then return; end
				self:StartMoving();
				self._moving = true;
			end);
			holder:SetScript("OnMouseUp", function(self, button)
				if not self._moving then return; end
				self:StopMovingOrSizing();
				self._moving = false;

				local parentFrame = self:GetParent();
				if not parentFrame then return; end










				local pRight            = parentFrame:GetRight();
				local sLeft             = self:GetLeft();
				local _,      pCenterY  = parentFrame:GetCenter();
				local _,      sCenterY  = self:GetCenter();
				if not (pRight and sLeft and pCenterY and sCenterY) then return; end

				local db = PartyTrinketDB();
				db.x = sLeft    - pRight;
				db.y = sCenterY - pCenterY;
				Core:ApplyPartyTrinketLayout();
			end);
			holder:SetScript("OnHide", function(self)
				if self._moving then
					self:StopMovingOrSizing();
					self._moving = false;
				end
			end);

			self.partyFrames[i]         = { holder = holder, cd = cd };
			self.cooldowns["party"..i]  = cd;
		end
	end

	self:ApplyPartyTrinketLayout();
end

function Core:ShowPartyTrinkets(show)
	show = show and C.PartyTrinketsEnabled;
	for i = 1, MAX_PARTY do
		local f = self.partyFrames[i];
		if f then
			if show then f.holder:Show(); else f.holder:Hide(); end
		end
	end
end


Core.partyMoveMode = false;

function K.SetPartyTrinketMoveMode(state)
	Core.partyMoveMode = state and true or false;
	Core:SetupPartyTrinkets();




	if K.SetPartyTestMode and not InCombatLockdown() then
		if Core.partyMoveMode then
			if not (K.IsPartyTestMode and K.IsPartyTestMode()) then
				Core._startedTestMode = true;
				K.SetPartyTestMode(true);
			end
		elseif Core._startedTestMode then
			Core._startedTestMode = nil;
			K.SetPartyTestMode(false);
		end
	end

	for i = 1, MAX_PARTY do
		local f = Core.partyFrames[i];
		if f then
			f.holder:EnableMouse(Core.partyMoveMode);
			if Core.partyMoveMode then
				f.holder.dragHint:Show();
				f.holder:Show();

				CooldownFrame_SetTimer(f.cd, GetTime(), 120, 1);
			else
				f.holder.dragHint:Hide();
				CooldownFrame_SetTimer(f.cd, GetTime(), 0, 1);
				if not C.PartyTrinketsEnabled then f.holder:Hide(); end
			end
		end
	end
end

function K.IsPartyTrinketMoveMode()
	return Core.partyMoveMode;
end

function K.ResetPartyTrinketPosition()
	local db = PartyTrinketDB();
	db.x, db.y = nil, nil;
	Core:ApplyPartyTrinketLayout();
end

function K.ApplyPartyTrinketSettings()
	Core:SetupPartyTrinkets();
	Core:ApplyPartyTrinketLayout();
	Core:ShowPartyTrinkets(C.PartyTrinketsEnabled);
end


























function Core:RefreshGUIDCache()
	for unit in pairs(self.cooldowns) do
		if UnitExists(unit) then
			local guid = UnitGUID(unit);
			if guid then self.guidCache[guid] = unit; end
		end
	end
end

function Core:WipeGUIDCache()
	for k in pairs(self.guidCache) do self.guidCache[k] = nil; end
end


function Core:FindCooldownByGUID(guid)
	if not guid then return nil; end


	local unit = self.guidCache[guid];
	if unit and self.cooldowns[unit] then
		return self.cooldowns[unit];
	end


	for u, cdFrame in pairs(self.cooldowns) do
		if UnitExists(u) and UnitGUID(u) == guid then
			self.guidCache[guid] = u;
			return cdFrame;
		end
	end

	return nil;
end


function Core:ARENA_OPPONENT_UPDATE()
	if AnyTrinketEnabled() then self:RefreshGUIDCache(); end
end

function Core:PARTY_MEMBERS_CHANGED()
	if AnyTrinketEnabled() then
		self:RefreshGUIDCache();
		self:SetupPartyTrinkets();
	end
end

function Core:COMBAT_LOG_EVENT_UNFILTERED(timestamp, eventType,
	srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID)

	if not AnyTrinketEnabled() then return; end
	if eventType ~= "SPELL_CAST_SUCCESS" then return; end

	local info = TRINKET_SPELLS[spellID];
	if not info then return; end

	local cdFrame = self:FindCooldownByGUID(srcGUID);
	if not cdFrame then return; end

	CooldownFrame_SetTimer(cdFrame, GetTime(), info.cd, 1);

	if C.ArenaFrame_Trinket_Voice and info.voice then
		pcall(function()
			PlaySoundFile("Interface\\Addons\\"..AddOnName.."\\Media\\Voice\\"..info.voice..".mp3");
		end);
	end
end

function K.ToggleArenaTrinketsTracking(enabled)
	C.ArenaFrame_Trinkets = enabled and true or false;
	if ns and ns.ArenaFrame_Trinkets and ns.ArenaFrame_Trinkets.ApplyState then
		ns.ArenaFrame_Trinkets:ApplyState();
	end
end


function K.SetTrinketMouseState(state)
	if not Core.frames then return; end


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