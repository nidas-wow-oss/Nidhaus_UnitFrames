local AddOnName, ns = ...;
local K, C, L = unpack(ns);














local isInitialized = false;
local dragOverlays = {};
local draggers = {};
local isShowingOverlays = false;



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



function K.ResetPositionsAndScale()
	EnsurePositionsTable();


	NidhausUnitFramesDB.positions = {};










	local scaleKeys = {
		"PlayerFrameScale", "TargetFrameScale",
		"FocusScale", "FocusSpellBarScale",
		"PetFrameScale",
		"PartyFrameScale", "PartyMemberFrameSpacing",
		"ArenaFrameScale",
		"BossFrameScale", "BossTargetFrameSpacing",
		"Party3v3Scale1", "Party3v3Scale2", "Party3v3Scale3", "Party3v3Scale4",
	};
	for _, key in ipairs(scaleKeys) do
		local val = K.GetConfigDefault and K.GetConfigDefault(key);
		if val ~= nil then
			C[key] = val;
			NidhausUnitFramesDB[key] = val;
		end
	end




	if NidhausPlayerFrame then NidhausPlayerFrame:SetScale(C.PlayerFrameScale or 1.0); end
	if TargetFrame then TargetFrame:SetScale(C.TargetFrameScale or 1.0); end
	if FocusFrame then FocusFrame:SetScale(C.FocusScale or 1.0); end
	if FocusFrameSpellBar then FocusFrameSpellBar:SetScale(C.FocusSpellBarScale or 1.2); end
	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then pf:SetScale(C.PartyFrameScale or 1.0); end
	end



	for key, pt in pairs(K.DEFAULT_FRAME_POINTS or {}) do
		C[key] = { unpack(pt) };
	end



	if K.Is3v3Active and K.Is3v3Active() and K.Apply3v3PartyMode then
		K.Apply3v3PartyMode();
	else

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



	if NidhausPlayerFrame and C.SetPositions then
		NidhausPlayerFrame:ClearAllPoints();
		NidhausPlayerFrame:SetPoint(unpack(C.PlayerFramePoint));
	elseif NidhausPlayerFrame and C.PlayerFrame_BlizzardDefault then
		NidhausPlayerFrame:ClearAllPoints();
		local pos = C.PlayerFrame_BlizzardDefault;
		local relFrame = _G[pos.relativeTo] or UIParent;
		NidhausPlayerFrame:SetPoint(pos.point, relFrame, pos.relativePoint, pos.x, pos.y);
	end


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


	if not (K.Is3v3Active and K.Is3v3Active()) then
		if K.NidhausPartyFrame and C.SetPositions and C.PartyMemberFramePoint then
			K.NidhausPartyFrame:ClearAllPoints();
			K.NidhausPartyFrame:SetPoint(unpack(C.PartyMemberFramePoint));
		end
	end


	if K.NidhausBossFrame and C.SetPositions and C.BossTargetFramePoint then
		K.NidhausBossFrame:ClearAllPoints();
		K.NidhausBossFrame:SetPoint(unpack(C.BossTargetFramePoint));
	end


	local arenaAnchor = _G["NidhausArenaEnemyFrames"];
	if arenaAnchor and C.ArenaFramePoint then
		arenaAnchor:ClearAllPoints();
		arenaAnchor:SetPoint(unpack(C.ArenaFramePoint));
	end


	if NidhausUnitFramesDB.ArenaMover then
		NidhausUnitFramesDB.ArenaMover = { IsShown = false };
	end


	NidhausUnitFramesDB.CastBarPositions = nil;
	NidhausUnitFramesDB.TrinketPositions = nil;

	NidhausUnitFramesDB.ArenaDRPositions = nil;
	if K.RefreshArenaDRLayout then K.RefreshArenaDRLayout(); end
	NidhausUnitFramesDB.ArenaDoTPositions = nil;
	if K.RefreshArenaDoTLayout then K.RefreshArenaDoTLayout(); end


	if K.ForceHideArenaMover then
		K.ForceHideArenaMover();
	end






end



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

			if self.isPartyIndividual then
				local pf = self.targetFrame;

				if pf:GetParent() ~= UIParent then
					pf:SetParent(UIParent);
				end

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


	dragger:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then StopDragging(self); end
	end);

	dragger:SetScript("OnClick", function(self, button)

	end);

	return dragger;
end



local function EnableDragMode()
	local individualMode = C.PartyIndividualMove;

	for key, dragger in pairs(draggers) do
		local isPartyGroup = (key == "PartyMemberFrame");
		local isPartyIndiv = key:find("^PartyMemberFrame%d$");


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










	if K.IsGlobalUnlocked and K.IsGlobalUnlocked() then
		shiftAlt = false;
	end
	if shiftAlt and not isShowingOverlays then
		EnableDragMode();
		isShowingOverlays = true;
	elseif not shiftAlt and isShowingOverlays then

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









local posPending, groupPending = false, false;

local posWatcher = CreateFrame("Frame");
posWatcher:RegisterEvent("PLAYER_REGEN_ENABLED");
posWatcher:SetScript("OnEvent", function()
	if posPending then
		posPending = false;
		K.ApplyIndividualPartyPositions();
	end
	if groupPending then
		groupPending = false;
		K.RestorePartyToGroup();
	end
end);

function K.ApplyIndividualPartyPositions()
	if not C.PartyIndividualMove then return; end
	if InCombatLockdown() then posPending = true; return; end
	posPending = false;

	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then
			local key = "PartyMemberFrame"..i;





			if K.Is3v3Active and K.Is3v3Active() then
				local saved = K.GetSavedPosition(key);
				if saved then
					pf:SetParent(UIParent);
					pf:ClearAllPoints();
					local relFrame = _G[saved.relativeTo] or UIParent;
					pf:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				end

			else

				local saved = K.GetSavedPosition(key);

				if not saved then

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


function K.RestorePartyToGroup()
	if InCombatLockdown() then groupPending = true; return; end
	groupPending = false;


	if K.Is3v3Active and K.Is3v3Active() and K.Apply3v3PartyMode then
		K.Apply3v3PartyMode();
		return;
	end

	if not K.NidhausPartyFrame then return; end


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



local function InitFrameDragger()
	if isInitialized then return; end


	local playerFrame = _G["NidhausPlayerFrame"];
	if playerFrame then
		draggers["PlayerFrame"] = MakeFrameDraggable(playerFrame, "PlayerFrame", "Player");
	end


	if TargetFrame then
		draggers["TargetFrame"] = MakeFrameDraggable(TargetFrame, "TargetFrame", "Target");
	end


	if K.NidhausPartyFrame then
		draggers["PartyMemberFrame"] = MakeFrameDraggable(
			K.NidhausPartyFrame, "PartyMemberFrame", "Party (All)", 130, 400
		);
	end


	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then
			local key = "PartyMemberFrame"..i;
			local dragger = MakeFrameDraggable(pf, key, "Party "..i);
			dragger.isPartyIndividual = true;
			draggers[key] = dragger;
		end
	end


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


K.RegisterConfigEvent("CONFIG_LOADED", function()
	local delayFrame = CreateFrame("Frame");
	delayFrame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil);
		InitFrameDragger();
	end);
end);