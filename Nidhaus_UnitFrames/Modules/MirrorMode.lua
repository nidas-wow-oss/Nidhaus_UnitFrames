local AddOnName, ns = ...;
local K, C, L = unpack(ns);



local _G, unpack, pairs, type, tostring = _G, unpack, pairs, type, tostring;

local petOrigTexCoords = {};
local petHooked = {};
local castBarCache = {};
local castBarHooked = {};
local arenaFrameHooked = {};
local arenaOrigState = {};


local function FindCastBar(index)
	if castBarCache[index] then return castBarCache[index]; end

	local pre = "ArenaEnemyFrame"..index;
	local arenaFrame = _G[pre];
	if not arenaFrame then return nil; end


	local names = {
		pre.."CastingBar",
		pre.."SpellBar",
		pre.."Castbar",
	};
	for _, name in pairs(names) do
		if _G[name] then
			castBarCache[index] = _G[name];
			return _G[name];
		end
	end


	if arenaFrame.spellbar then castBarCache[index] = arenaFrame.spellbar; return arenaFrame.spellbar; end
	if arenaFrame.castBar then castBarCache[index] = arenaFrame.castBar; return arenaFrame.castBar; end
	if arenaFrame.CastingBar then castBarCache[index] = arenaFrame.CastingBar; return arenaFrame.CastingBar; end


	for _, child in pairs({arenaFrame:GetChildren()}) do
		local name = child:GetName() or "";
		local nameLower = name:lower();
		if nameLower:find("cast") or nameLower:find("spell") then
			castBarCache[index] = child;
			return child;
		end
	end

	return nil;
end

local bgOrigPositions = {};







function K.PositionArenaCastBar(index)
	local castBar = FindCastBar(index);
	local arenaFrame = _G["ArenaEnemyFrame"..index];
	if not castBar or not arenaFrame then return; end

	local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
	local isMirror = C.ArenaMirrorMode;
	local saved = K.GetSavedCastBarPos and K.GetSavedCastBarPos();


	if saved then
		castBar:ClearAllPoints();
		castBar:SetPoint(saved[1], arenaFrame, saved[2], saved[3], saved[4]);

		local icon = castBar.Icon or _G[castBar:GetName().."Icon"];
		if icon then
			icon:ClearAllPoints();
			if saved[3] and saved[3] > 0 then

				icon:SetPoint("LEFT", castBar, "RIGHT", 2, 0);
			else

				icon:SetPoint("RIGHT", castBar, "LEFT", -2, 0);
			end
		end
	elseif isMirror then

		castBar:ClearAllPoints();
		castBar:SetPoint("BOTTOMLEFT", arenaFrame, "BOTTOMRIGHT", 8, 6);
		local icon = castBar.Icon or _G[castBar:GetName().."Icon"];
		if icon then
			icon:ClearAllPoints();
			icon:SetPoint("LEFT", castBar, "RIGHT", 2, 0);
		end
	elseif isFlat then

		castBar:ClearAllPoints();
		castBar:SetPoint("BOTTOMRIGHT", arenaFrame, "BOTTOMLEFT", -8, 6);
		local icon = castBar.Icon or _G[castBar:GetName().."Icon"];
		if icon then
			icon:ClearAllPoints();
			icon:SetPoint("RIGHT", castBar, "LEFT", -2, 0);
		end
	else















		local s = arenaOrigState[index];
		local cbPoints, cbIconPoints = s and s.cbPoints, s and s.cbIconPoints;

		if not cbPoints and K.GetArenaCastBarOriginalPoints then
			cbPoints, cbIconPoints = K.GetArenaCastBarOriginalPoints(index);
		end

		if cbPoints then
			castBar:ClearAllPoints();
			for _, pt in ipairs(cbPoints) do castBar:SetPoint(unpack(pt)); end
			local icon = castBar.Icon or _G[castBar:GetName().."Icon"];
			if icon then
				icon:ClearAllPoints();
				if cbIconPoints then
					for _, pt in ipairs(cbIconPoints) do icon:SetPoint(unpack(pt)); end
				else
					icon:SetPoint("RIGHT", castBar, "LEFT", -2, 0);
				end
			end
		end
	end
end





local function HookCastBarOnShow(castBar, index)
	if castBarHooked[index] then return; end
	castBar:HookScript("OnShow", function(self)


		K.PositionArenaCastBar(index);
	end);
	castBarHooked[index] = true;
end








local function ApplyFlatMirrorToExtras(frame, index)

	local trinketBorder = _G["NidhausArenaTrinketBorder"..index];
	if trinketBorder then
		trinketBorder:ClearAllPoints();
		trinketBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -8, 0);
	end


	local castBar = FindCastBar(index);
	if castBar then
		HookCastBarOnShow(castBar, index);
		K.PositionArenaCastBar(index);
	end
end


local function ApplyFlatNormalToExtras(frame, index)

	local trinketBorder = _G["NidhausArenaTrinketBorder"..index];
	if trinketBorder then
		local savedT = K.GetSavedTrinketPos and K.GetSavedTrinketPos();
		trinketBorder:ClearAllPoints();
		if savedT then
			trinketBorder:SetPoint(savedT[1], frame, savedT[2], savedT[3], savedT[4]);
		else
			trinketBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 8, 0);
		end
	end


	local castBar = FindCastBar(index);
	if castBar then
		HookCastBarOnShow(castBar, index);
		K.PositionArenaCastBar(index);
	end
end

local function MirrorPoint(point)
	if point == "LEFT" then return "RIGHT"; end
	if point == "RIGHT" then return "LEFT"; end
	if point == "TOPLEFT" then return "TOPRIGHT"; end
	if point == "TOPRIGHT" then return "TOPLEFT"; end
	if point == "BOTTOMLEFT" then return "BOTTOMRIGHT"; end
	if point == "BOTTOMRIGHT" then return "BOTTOMLEFT"; end
	return point;
end


local ApplyMirrorToFrame;
local ApplyMirrorToPet;
local UpdateTrinketPositions;


local mirrorPendingFrames = {};
local mirrorTimerElapsed = 0;
local sharedMirrorTimer = CreateFrame("Frame");
sharedMirrorTimer:Hide();
sharedMirrorTimer:SetScript("OnUpdate", function(self, dt)
	mirrorTimerElapsed = mirrorTimerElapsed + dt;
	if mirrorTimerElapsed >= 0.05 then
		self:Hide();
		for idx, frame in pairs(mirrorPendingFrames) do
			if frame:IsShown() and C.ArenaMirrorMode and not (K.IsFlatModeActive and K.IsFlatModeActive()) then
				ApplyMirrorToFrame(frame, idx);
				ApplyMirrorToPet(idx);
			end
		end
		UpdateTrinketPositions();
		wipe(mirrorPendingFrames);
	end
end);


local function CaptureArenaOriginals(frame, index)
	if arenaOrigState[index] then return; end
	local s = {};
	local tex = _G["ArenaEnemyFrame"..index.."Texture"];
	if tex then
		s.texW, s.texH = tex:GetWidth(), tex:GetHeight();
		s.texCoords = {tex:GetTexCoord()};
		s.texPoints = {};
		for p = 1, tex:GetNumPoints() do s.texPoints[p] = {tex:GetPoint(p)}; end
	end
	s.portW, s.portH = frame.classPortrait:GetWidth(), frame.classPortrait:GetHeight();
	s.portPoints = {};
	for p = 1, frame.classPortrait:GetNumPoints() do s.portPoints[p] = {frame.classPortrait:GetPoint(p)}; end
	s.hbW, s.hbH = frame.healthbar:GetWidth(), frame.healthbar:GetHeight();
	s.hbPoints = {};
	for p = 1, frame.healthbar:GetNumPoints() do s.hbPoints[p] = {frame.healthbar:GetPoint(p)}; end
	s.namePoints = {};
	for p = 1, frame.name:GetNumPoints() do s.namePoints[p] = {frame.name:GetPoint(p)}; end
	s.mbW, s.mbH = frame.manabar:GetWidth(), frame.manabar:GetHeight();
	s.mbPoints = {};
	for p = 1, frame.manabar:GetNumPoints() do s.mbPoints[p] = {frame.manabar:GetPoint(p)}; end
	s.hbTextPoints = {};
	for p = 1, frame.healthbar.TextString:GetNumPoints() do s.hbTextPoints[p] = {frame.healthbar.TextString:GetPoint(p)}; end
	s.mbTextPoints = {};
	for p = 1, frame.manabar.TextString:GetNumPoints() do s.mbTextPoints[p] = {frame.manabar.TextString:GetPoint(p)}; end
	local castBar = FindCastBar(index);
	if castBar then
		s.cbPoints = {};
		for p = 1, castBar:GetNumPoints() do s.cbPoints[p] = {castBar:GetPoint(p)}; end
		local icon = castBar.Icon or _G[castBar:GetName().."Icon"];
		if icon then
			s.cbIconPoints = {};
			for p = 1, icon:GetNumPoints() do s.cbIconPoints[p] = {icon:GetPoint(p)}; end
		end
	end
	arenaOrigState[index] = s;
end

ApplyMirrorToFrame = function(frame, index)
	if not frame then return; end

	CaptureArenaOriginals(frame, index);
	local s = arenaOrigState[index];
	local isCustom = C.ArenaCustomTexture;
	local Font = C.ArenaFrameFont or {"Fonts\\FRIZQT__.TTF", 7, "OUTLINE"};


	local tex = _G["ArenaEnemyFrame"..index.."Texture"];
	if tex then
		tex:ClearAllPoints();
		if isCustom then
			tex:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 5);
			tex:SetTexCoord(1.0, 0.09375, 0, 0.78125);
			tex:SetSize(124, 48);
		elseif s and s.texCoords then

			for _, pt in ipairs(s.texPoints) do
				local point, rel, relPoint, x, y = unpack(pt);
				tex:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0);
			end
			local ULx,ULy, LLx,LLy, URx,URy, LRx,LRy = unpack(s.texCoords);
			tex:SetTexCoord(URx,URy, LRx,LRy, ULx,ULy, LLx,LLy);
			tex:SetSize(s.texW, s.texH);
		end
	end


	frame.classPortrait:ClearAllPoints();
	if isCustom then
		frame.classPortrait:SetPoint("LEFT", frame, "LEFT", 0, 0);
		frame.classPortrait:SetSize(34, 34);
	elseif s then

		for _, pt in ipairs(s.portPoints) do
			local point, rel, relPoint, x, y = unpack(pt);
			frame.classPortrait:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0);
		end
		frame.classPortrait:SetSize(s.portW, s.portH);
	end

	if isCustom then
		frame.healthbar:ClearAllPoints();
		frame.healthbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -6);
		frame.healthbar:SetSize(62, 14);
	elseif s then

		frame.healthbar:ClearAllPoints();
		for _, pt in ipairs(s.hbPoints) do
			local point, rel, relPoint, x, y = unpack(pt);
			frame.healthbar:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0);
		end
		frame.healthbar:SetSize(s.hbW, s.hbH);
	end

	frame.name:ClearAllPoints();
	if isCustom then
		frame.name:SetPoint("BOTTOM", frame.healthbar, "TOP", 0, 1);
	elseif s then
		for _, pt in ipairs(s.namePoints) do
			local point, rel, relPoint, x, y = unpack(pt);
			frame.name:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0);
		end
	end

	if isCustom then
		frame.manabar:ClearAllPoints();
		frame.manabar:SetPoint("TOPRIGHT", frame.healthbar, "BOTTOMRIGHT", 0, 0);
		frame.manabar:SetSize(62, 6);
	elseif s then
		frame.manabar:ClearAllPoints();
		for _, pt in ipairs(s.mbPoints) do
			local point, rel, relPoint, x, y = unpack(pt);
			frame.manabar:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0);
		end
		frame.manabar:SetSize(s.mbW, s.mbH);
	end

	frame.healthbar.TextString:ClearAllPoints();
	frame.healthbar.TextString:SetPoint("CENTER", frame.healthbar);
	frame.manabar.TextString:ClearAllPoints();
	frame.manabar.TextString:SetPoint("CENTER", frame.manabar);

	if isCustom then
		frame.healthbar.TextString:SetFont(unpack(Font));
		frame.manabar.TextString:SetFont(unpack(Font));
	end

	if isCustom and C.statusbarOn and C.statusbarTexture then
		frame.healthbar:SetStatusBarTexture(C.statusbarTexture);
		frame.manabar:SetStatusBarTexture(C.statusbarTexture);
	end


	local bg = _G["ArenaEnemyFrame"..index.."Background"];
	if bg then
		if not bgOrigPositions[index] then
			bgOrigPositions[index] = {};
			for p = 1, bg:GetNumPoints() do bgOrigPositions[index][p] = {bg:GetPoint(p)}; end
		end
		bg:ClearAllPoints();
		bg:SetPoint("TOPLEFT", frame.healthbar, "TOPLEFT", 0, 0);
		bg:SetPoint("BOTTOMRIGHT", frame.manabar, "BOTTOMRIGHT", 0, 0);
	end


	if frame.Backdrop then
		frame.Backdrop:ClearAllPoints();
		frame.Backdrop:SetPoint("TOPLEFT", frame.healthbar, "TOPLEFT");
		frame.Backdrop:SetPoint("BOTTOMRIGHT", frame.manabar, "BOTTOMRIGHT");
	end


	local castBar = FindCastBar(index);
	if castBar then
		HookCastBarOnShow(castBar, index);
		K.PositionArenaCastBar(index);
	end


	if not arenaFrameHooked[index] then
		frame:HookScript("OnShow", function(self)
			if C.ArenaMirrorMode and not (K.IsFlatModeActive and K.IsFlatModeActive()) then

				mirrorPendingFrames[index] = self;
				mirrorTimerElapsed = 0;
				sharedMirrorTimer:Show();
			end
		end);
		arenaFrameHooked[index] = true;
	end
end

local function ApplyNormalToFrame(frame, index)
	if not frame then return; end

	if C.ArenaCustomTexture and K.StyleSingleArenaFrame then
		K.StyleSingleArenaFrame(frame, index);
	else
		local s = arenaOrigState[index];
		if s then
			local tex = _G["ArenaEnemyFrame"..index.."Texture"];
			if tex then
				if s.texCoords then tex:SetTexCoord(unpack(s.texCoords)); end
				tex:ClearAllPoints();
				if s.texPoints then
					for _, pt in ipairs(s.texPoints) do tex:SetPoint(unpack(pt)); end
				end
				tex:SetSize(s.texW, s.texH);
			end
			frame.classPortrait:ClearAllPoints();
			for _, pt in ipairs(s.portPoints) do frame.classPortrait:SetPoint(unpack(pt)); end
			frame.classPortrait:SetSize(s.portW, s.portH);
			frame.healthbar:ClearAllPoints();
			for _, pt in ipairs(s.hbPoints) do frame.healthbar:SetPoint(unpack(pt)); end
			frame.healthbar:SetSize(s.hbW, s.hbH);
			frame.name:ClearAllPoints();
			for _, pt in ipairs(s.namePoints) do frame.name:SetPoint(unpack(pt)); end
			frame.manabar:ClearAllPoints();
			for _, pt in ipairs(s.mbPoints) do frame.manabar:SetPoint(unpack(pt)); end
			frame.manabar:SetSize(s.mbW, s.mbH);
			frame.healthbar.TextString:ClearAllPoints();
			for _, pt in ipairs(s.hbTextPoints) do frame.healthbar.TextString:SetPoint(unpack(pt)); end
			frame.manabar.TextString:ClearAllPoints();
			for _, pt in ipairs(s.mbTextPoints) do frame.manabar.TextString:SetPoint(unpack(pt)); end
		end
	end


	local bg = _G["ArenaEnemyFrame"..index.."Background"];
	if bg and bgOrigPositions[index] then
		bg:ClearAllPoints();
		for _, pt in pairs(bgOrigPositions[index]) do bg:SetPoint(unpack(pt)); end
	end


	if frame.Backdrop then
		frame.Backdrop:ClearAllPoints();
		frame.Backdrop:SetPoint("TOPLEFT", frame.healthbar, "TOPLEFT");
		frame.Backdrop:SetPoint("BOTTOMRIGHT", frame.manabar, "BOTTOMRIGHT");
	end


	local castBar = FindCastBar(index);
	if castBar then
		K.PositionArenaCastBar(index);
	end
end




local function CapturePetMirrorOriginals(petFrame)
	if petFrame._mirrorCaptured then return; end

	petFrame._mirrorRegions = {};
	petFrame._mirrorChildren = {};

	local borderTex = _G[petFrame:GetName() .. "Texture"];

	for _, region in pairs({petFrame:GetRegions()}) do
		if region ~= borderTex then
			local entry = { element = region };
			local numPts = region:GetNumPoints();
			entry.points = {};
			for p = 1, numPts do
				entry.points[p] = {region:GetPoint(p)};
			end
			entry.usesAllPoints = (numPts == 0);
			if region:GetObjectType() == "Texture" then
				entry.texCoords = {region:GetTexCoord()};
			end
			petFrame._mirrorRegions[#petFrame._mirrorRegions + 1] = entry;
		end
	end

	for _, child in pairs({petFrame:GetChildren()}) do
		local entry = { element = child };
		local numPts = child:GetNumPoints();
		entry.points = {};
		for p = 1, numPts do
			entry.points[p] = {child:GetPoint(p)};
		end
		entry.usesAllPoints = (numPts == 0);
		petFrame._mirrorChildren[#petFrame._mirrorChildren + 1] = entry;
	end

	petFrame._mirrorCaptured = true;
end

local function MirrorElement(el, entry)
	el:ClearAllPoints();
	if entry.usesAllPoints then
		el:SetAllPoints();
	else
		for _, pt in pairs(entry.points) do
			if type(pt) == "table" and pt[1] then
				local point, relativeTo, relativePoint, x, y = unpack(pt);
				el:SetPoint(MirrorPoint(point), relativeTo, MirrorPoint(relativePoint), -(x or 0), y or 0);
			end
		end
	end
end

local function RestoreElement(el, entry)
	el:ClearAllPoints();
	if entry.usesAllPoints then
		el:SetAllPoints();
	else
		for _, pt in pairs(entry.points) do
			if type(pt) == "table" and pt[1] then
				el:SetPoint(unpack(pt));
			end
		end
	end
end

ApplyMirrorToPet = function(index)
	local pre = "ArenaEnemyFrame"..index.."PetFrame";
	local petFrame = _G[pre];
	if not petFrame then return; end

	CapturePetMirrorOriginals(petFrame);


	local petTex = _G[pre.."Texture"];
	if petTex then
		if not petOrigTexCoords[index] then
			petOrigTexCoords[index] = {petTex:GetTexCoord()};
		end
		local ULx,ULy, LLx,LLy, URx,URy, LRx,LRy = unpack(petOrigTexCoords[index]);
		petTex:SetTexCoord(URx,URy, LRx,LRy, ULx,ULy, LLx,LLy);
	end


	for _, entry in pairs(petFrame._mirrorRegions) do
		if entry.texCoords then
			local ULx,ULy, LLx,LLy, URx,URy, LRx,LRy = unpack(entry.texCoords);
			entry.element:SetTexCoord(URx,URy, LRx,LRy, ULx,ULy, LLx,LLy);
		end
		MirrorElement(entry.element, entry);
	end


	for _, entry in pairs(petFrame._mirrorChildren) do
		MirrorElement(entry.element, entry);
	end


	if not petHooked[index] then
		petFrame:HookScript("OnShow", function()
			if C.ArenaMirrorMode and petFrame._mirrorCaptured then

				local tex = _G[pre.."Texture"];
				if tex and petOrigTexCoords[index] then
					local ULx,ULy, LLx,LLy, URx,URy, LRx,LRy = unpack(petOrigTexCoords[index]);
					tex:SetTexCoord(URx,URy, LRx,LRy, ULx,ULy, LLx,LLy);
				end

				for _, entry in pairs(petFrame._mirrorRegions) do
					if entry.texCoords then
						local ULx,ULy, LLx,LLy, URx,URy, LRx,LRy = unpack(entry.texCoords);
						entry.element:SetTexCoord(URx,URy, LRx,LRy, ULx,ULy, LLx,LLy);
					end
					MirrorElement(entry.element, entry);
				end

				for _, entry in pairs(petFrame._mirrorChildren) do
					MirrorElement(entry.element, entry);
				end
			end
		end);
		petHooked[index] = true;
	end
end

local function ApplyNormalToPet(index)
	local pre = "ArenaEnemyFrame"..index.."PetFrame";
	local petFrame = _G[pre];
	if not petFrame then return; end


	local petTex = _G[pre.."Texture"];
	if petTex and petOrigTexCoords[index] then
		petTex:SetTexCoord(unpack(petOrigTexCoords[index]));
	end


	if petFrame._mirrorRegions then
		for _, entry in pairs(petFrame._mirrorRegions) do
			if entry.texCoords then
				entry.element:SetTexCoord(unpack(entry.texCoords));
			end
			RestoreElement(entry.element, entry);
		end
	end


	if petFrame._mirrorChildren then
		for _, entry in pairs(petFrame._mirrorChildren) do
			RestoreElement(entry.element, entry);
		end
	end
end

UpdateTrinketPositions = function()
	local trinketCore = ns.ArenaFrame_Trinkets;
	local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();

	for i = 1, (MAX_ARENA_ENEMIES or 5) do
		local arenaFrame = _G["ArenaEnemyFrame"..i];
		if not arenaFrame then break; end


		local border = _G["NidhausArenaTrinketBorder"..i];
		if not border then
			if trinketCore and trinketCore.frames and trinketCore.frames[i] then
				border = trinketCore.frames[i].border;
			end
		end

		if border then
			border:ClearAllPoints();

			local saved = isFlat and K.GetSavedTrinketPos and K.GetSavedTrinketPos();
			if saved then
				border:SetPoint(saved[1], arenaFrame, saved[2], saved[3], saved[4]);
			elseif C.ArenaMirrorMode then

				border:SetPoint("BOTTOMRIGHT", arenaFrame, "BOTTOMLEFT", -8, 0);
			else

				border:SetPoint("BOTTOMLEFT", arenaFrame, "BOTTOMRIGHT", 8, 0);
			end
		end
	end
end




local function RepositionFlatCastBars()
	for i = 1, (MAX_ARENA_ENEMIES or 5) do
		local castBar = FindCastBar(i);
		if castBar then
			HookCastBarOnShow(castBar, i);
			K.PositionArenaCastBar(i);
		end
	end
end

function K.ApplyMirrorMode()
	if not C.ArenaFrameOn then return; end










	if K.IsFlatModeActive and K.IsFlatModeActive() then
		for i = 1, (MAX_ARENA_ENEMIES or 5) do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame then
				if K.ApplyFlatStyle then K.ApplyFlatStyle(frame, i); end
			end
		end




		if C.ArenaFlatPetStyle and K.ApplyFlatPetFrames then
			K.ApplyFlatPetFrames();
		end


		UpdateTrinketPositions();



		RepositionFlatCastBars();
		return;
	end

	for i = 1, (MAX_ARENA_ENEMIES or 0) do
		local frame = _G["ArenaEnemyFrame"..i];
		if frame then
			if C.ArenaMirrorMode then
				ApplyMirrorToFrame(frame, i);
				ApplyMirrorToPet(i);
			else
				ApplyNormalToFrame(frame, i);
				ApplyNormalToPet(i);
			end
		end
	end

	UpdateTrinketPositions();
end

function K.ToggleMirrorMode(enabled)
	K.ApplyMirrorMode();
end


function K.ResetMirrorCastBars()
	for i = 1, (MAX_ARENA_ENEMIES or 5) do
		K.PositionArenaCastBar(i);
	end
end


function K.DebugPetFrame()
	local arenaFrame = _G["ArenaEnemyFrame1"];
	if not arenaFrame then
		print("|cffFF0000NUF:|r ArenaEnemyFrame1 nil");
		return;
	end

	print("|cff00FF00NUF Arena1 frame:|r "..math.floor(arenaFrame:GetWidth()+0.5).."x"..math.floor(arenaFrame:GetHeight()+0.5));
	print("  .Backdrop = "..tostring(arenaFrame.Backdrop ~= nil));
	print("  .background = "..tostring(arenaFrame.background ~= nil));
	print("  .nameBackground = "..tostring(arenaFrame.nameBackground ~= nil));


	local hb = arenaFrame.healthbar;
	if hb then
		local p,_,rp,x,y = hb:GetPoint(1);
		print("  healthbar: "..tostring(p).."("..tostring(x)..","..tostring(y)..") "..math.floor(hb:GetWidth()+0.5).."x"..math.floor(hb:GetHeight()+0.5));

		for ri, region in pairs({hb:GetRegions()}) do
			local name = region:GetName() or "nil";
			local w = math.floor(region:GetWidth()+0.5);
			local h = math.floor(region:GetHeight()+0.5);
			local layer = region:GetDrawLayer() or "nil";
			local objType = region:GetObjectType();
			local texInfo = "";
			if objType == "Texture" then
				texInfo = " tex="..tostring(region:GetTexture());
			end
			print("    hb_reg["..ri.."] "..objType.." \""..name.."\" "..w.."x"..h.." layer="..layer..texInfo);
		end
	end


	print("|cff00FF00NUF Arena1 ALL regions:|r");
	for ri, region in pairs({arenaFrame:GetRegions()}) do
		local name = region:GetName() or "nil";
		local w = math.floor(region:GetWidth()+0.5);
		local h = math.floor(region:GetHeight()+0.5);
		local layer = region:GetDrawLayer() or "nil";
		local objType = region:GetObjectType();
		local vis = region:IsVisible() and "V" or "H";
		local texInfo = "";
		if objType == "Texture" then
			texInfo = " tex="..tostring(region:GetTexture());
		end
		print("  ["..ri.."] "..objType.." \""..name.."\" "..w.."x"..h.." "..layer.." "..vis..texInfo);
	end
end