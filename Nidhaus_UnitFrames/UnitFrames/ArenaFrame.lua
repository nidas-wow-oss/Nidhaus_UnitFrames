local AddOnName, ns = ...;
local K, C, L = unpack(ns);
local hooksecurefunc = hooksecurefunc;
local _G, unpack = _G, unpack;
local IsAddOnLoaded, LoadAddOn = IsAddOnLoaded, LoadAddOn;

local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;







local function ApplyArenaTint(tex)
	if not tex then return; end












	if not K.ApplyLortiTint then return; end
	if not (K.LortiTint and K.LortiTint("LortiUI_Arena")) then return; end
	K.ApplyLortiTint(tex, "LortiUI_Arena");
end


local NidhausArenaEnemyFrames;
local isInitialized = false;
local hookRegistered = false;

local Path;














local CASTBAR_FLAT_DEFAULT = { "CENTER", "CENTER", -106.1, 1.2 };

local TEX_W, TEX_H = 124, 53;
local TEX_X, TEX_Y = 0, 5;







local BAR_X, BAR_Y = 4, -8;
local BAR_W        = 62;
local BAR_HP_H     = 14;
local BAR_MP_H     = 6;




local BAR_MP_GAP   = -1;



local PORT_X, PORT_Y = 0, -4;

local function GetArenaTexturePath()










	if C.ArenaFrameStyle == "Compact2" then
		return "Interface\\AddOns\\"..AddOnName.."\\Media\\pw\\UI-TargetingFrame";
	end
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
	if K.AfterCombat("ArenaFramesSettings", ArenaFramesSettings) then return; end


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











		local pts = {};
		for p = 1, (castBar:GetNumPoints() or 0) do pts[p] = { castBar:GetPoint(p) }; end

		local iconPts;
		local icon = castBar.Icon or _G["ArenaEnemyFrame"..index.."CastingBarIcon"];
		if icon then
			iconPts = {};
			for p = 1, (icon:GetNumPoints() or 0) do iconPts[p] = { icon:GetPoint(p) }; end
		end

		orig.castBar = {
			width = castBar:GetWidth(),
			height = castBar:GetHeight(),
			scale = castBar:GetScale(),
			points = (#pts > 0) and pts or nil,
			iconPoints = (iconPts and #iconPts > 0) and iconPts or nil,
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
			if not K.AfterCombat("ArenaFrames_OnLoad", function() if K.ArenaFrames_OnLoad then K.ArenaFrames_OnLoad(); end end) then
				arenaFrame:SetSize(orig.frameWidth, orig.frameHeight);
			end
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


			ApplyArenaTint(tex);
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







	Path = GetArenaTexturePath();

	for i = 1, MAX_ARENA_ENEMIES do
		if _G["ArenaEnemyFrame"..i] then CaptureOriginals(i); end
	end

	local style = C.ArenaFrameStyle or "Blizzard";
	local isFlat = (style == "Flat") or C.ArenaFlatMode;



	local isCompact = (style == "Compact");
	local isCustom = isCompact or (style == "Custom") or (style == "Compact2")
		or (C.ArenaCustomTexture and not isFlat);

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
		if tex and isCompact then
			tex:Hide();
		elseif tex then
			tex:SetTexture(Path);
			tex:ClearAllPoints();
			tex:SetPoint("TOPLEFT", arenaFrame, "TOPLEFT", TEX_X, TEX_Y);
			tex:SetTexCoord(0.09375, 1.0, 0, 0.78125);
			tex:SetSize(TEX_W, TEX_H);
			ApplyArenaTint(tex);
			tex:Show();
		end

		arenaFrame.healthbar:SetPoint("TOPLEFT", arenaFrame, "TOPLEFT", BAR_X, BAR_Y);
		arenaFrame.healthbar:SetSize(BAR_W, BAR_HP_H);
		arenaFrame.name:ClearAllPoints();
		arenaFrame.name:SetPoint("BOTTOM", arenaFrame.healthbar, "TOP", 0, 1);
		arenaFrame.manabar:SetSize(BAR_W, BAR_MP_H);
		arenaFrame.manabar:ClearAllPoints();
		arenaFrame.manabar:SetPoint("TOPLEFT", arenaFrame.healthbar, "BOTTOMLEFT", 0, BAR_MP_GAP);
		arenaFrame.healthbar.TextString:SetPoint("CENTER", arenaFrame.healthbar);
		arenaFrame.manabar.TextString:SetPoint("CENTER", arenaFrame.manabar);
		arenaFrame.healthbar.TextString:SetFont(unpack(Font));
		arenaFrame.manabar.TextString:SetFont(unpack(Font));
		arenaFrame.classPortrait:SetSize(34, 34);
		arenaFrame.classPortrait:ClearAllPoints();
		arenaFrame.classPortrait:SetPoint("RIGHT", arenaFrame, "RIGHT", PORT_X, PORT_Y);

		if statusbarOn and statusbarTexture then
			arenaFrame.healthbar:SetStatusBarTexture(statusbarTexture);
			arenaFrame.manabar:SetStatusBarTexture(statusbarTexture);
		end

		local blizzBG = _G["ArenaEnemyFrame"..i.."Background"];
		if blizzBG then blizzBG:Hide(); end
	end
end

function K.ApplyArenaSpacing()
	if K.AfterCombat("ApplyArenaSpacing", K.ApplyArenaSpacing) then return; end
	local spacing = C.ArenaFrameSpacing;
	if type(spacing) ~= "number" then spacing = 0; end




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






	if InCombatLockdown() then
		pcall(ApplyArenaTextures);
		K.AfterCombat("ArenaFrames_OnLoad", ArenaFrames_OnLoad);
		return;
	end
	ArenaFramesSettings();
	ApplyArenaTextures();
	K.ApplyArenaSpacing();
	if K.ApplyMirrorMode then K.ApplyMirrorMode(); end
end

K.ArenaFrames_OnLoad = ArenaFrames_OnLoad;


local function EnforceArenaScale()
	if K.AfterCombat("EnforceArenaScale", EnforceArenaScale) then return; end
	local scale = C.ArenaFrameScale;
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end

	if ArenaEnemyFrames then
		local curScale = ArenaEnemyFrames:GetScale();
		if math.abs(curScale - scale) > 0.01 then
			ArenaEnemyFrames:SetScale(scale);
		end
	end


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


local scaleHooked = {};
local function HookArenaFrameScale(index)
	if scaleHooked[index] then return; end
	local frame = _G["ArenaEnemyFrame"..index];
	if not frame then return; end
	frame:HookScript("OnShow", function()

		if not isInitialized then return; end
		if C.ArenaFrameScale then
			K.ApplyArenaScale(C.ArenaFrameScale);
		end

		if K.IsFlatModeActive and K.IsFlatModeActive() and C.ArenaFlatPetStyle then
			local petFrame = _G["ArenaEnemyFrame"..index.."PetFrame"];
			if petFrame and petFrame:IsShown() then
				K.ApplyFlatPetStyle(petFrame, index);

				if K.RestorePetFramePositions then K.RestorePetFramePositions(); end
			end
		end
	end);
	scaleHooked[index] = true;
end

K.StyleSingleArenaFrame = function(frame, index)
	if not frame then return; end







	Path = GetArenaTexturePath();

	local style = C.ArenaFrameStyle or "Blizzard";
	local isFlat = (style == "Flat") or C.ArenaFlatMode;

	if isFlat then
		if K.ApplyFlatStyle then K.ApplyFlatStyle(frame, index); end
		return;
	end








	local isCompact = (style == "Compact");
	local isCustom  = isCompact or (style == "Custom") or (style == "Compact2")
		or C.ArenaCustomTexture;
	if not isCustom then return; end

	local Font = C.ArenaFrameFont or {"Fonts\\FRIZQT__.TTF", 7, "OUTLINE"};
	local tex = _G["ArenaEnemyFrame"..index.."Texture"];
	if tex then
		if isCompact then
			tex:Hide();
		else
			tex:SetTexture(Path);
			tex:ClearAllPoints();
			tex:SetPoint("TOPLEFT", frame, "TOPLEFT", TEX_X, TEX_Y);
			tex:SetTexCoord(0.09375, 1.0, 0, 0.78125);
			tex:SetSize(TEX_W, TEX_H);
			ApplyArenaTint(tex);
			tex:Show();
		end
	end
	frame.healthbar:ClearAllPoints();
	frame.healthbar:SetPoint("TOPLEFT", frame, "TOPLEFT", BAR_X, BAR_Y);
	frame.healthbar:SetSize(BAR_W, BAR_HP_H);
	frame.name:ClearAllPoints();
	frame.name:SetPoint("BOTTOM", frame.healthbar, "TOP", 0, 1);
	frame.manabar:SetSize(BAR_W, BAR_MP_H);
	frame.manabar:ClearAllPoints();
	frame.manabar:SetPoint("TOPLEFT", frame.healthbar, "BOTTOMLEFT", 0, BAR_MP_GAP);
	frame.healthbar.TextString:ClearAllPoints();
	frame.healthbar.TextString:SetPoint("CENTER", frame.healthbar);
	frame.manabar.TextString:ClearAllPoints();
	frame.manabar.TextString:SetPoint("CENTER", frame.manabar);
	frame.healthbar.TextString:SetFont(unpack(Font));
	frame.manabar.TextString:SetFont(unpack(Font));
	frame.classPortrait:SetSize(34, 34);
	frame.classPortrait:ClearAllPoints();
	frame.classPortrait:SetPoint("RIGHT", frame, "RIGHT", PORT_X, PORT_Y);
	if C.statusbarOn and C.statusbarTexture then
		frame.healthbar:SetStatusBarTexture(C.statusbarTexture);
		frame.manabar:SetStatusBarTexture(C.statusbarTexture);
	end
	local blizzBG = _G["ArenaEnemyFrame"..index.."Background"];
	if blizzBG then blizzBG:Hide(); end
end

function K.ApplyArenaScale(scale)

	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	if K.AfterCombat("ApplyArenaScale", function() K.ApplyArenaScale(scale); end) then return; end
	

	if ArenaEnemyFrames then
		ArenaEnemyFrames:SetScale(scale);
	end
	
	local anchor = _G["NidhausArenaEnemyFrames"];
	if anchor then
		local spacing = C.ArenaFrameSpacing or 0;
		local height = (60 * 3 + (20 + spacing) * 2) * scale;
		anchor:SetSize(180 * scale, height);
	end
	




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


	if K.RestorePetFramePositions then K.RestorePetFramePositions(); end
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

			local text = _G["ArenaEnemyFrame"..i.."CastingBarText"];
			if text then
				text:SetWidth(width - 10);
			end
		end
	end
end
local arenaMovementHooked = false;
local castBarDragSetup = false;






function K.GetSavedCastBarPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.CastBarPositions;



	local isFlatNow = (C.ArenaFrameStyle == "Flat") or (C.ArenaFlatMode == true);
	if isFlatNow then
		local fkey = K.GetArenaPositionKey and K.GetArenaPositionKey() or "Flat_normal";
		if not (db and db[fkey]) then return CASTBAR_FLAT_DEFAULT; end
	end
	if not db then return nil; end

	if K.GetArenaPositionKey then
		local compositeKey = K.GetArenaPositionKey();
		if db[compositeKey] then return db[compositeKey]; end
	end

	local key = C.ArenaMirrorMode and "mirror" or "normal";
	return db[key] or db.global;
end






local function SetupCastBarDrag()
	if castBarDragSetup then return; end

	for i = 1, MAX_ARENA_ENEMIES do
		local castBar = _G["ArenaEnemyFrame"..i.."CastingBar"];
		if castBar then
			castBar:SetMovable(true);
			castBar:EnableMouse(false);

			castBar:HookScript("OnMouseDown", function(self, button)
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






function K.GetArenaCastBarOriginalPoints(index)
	local o = arenaOriginals[index];
	if not o or not o.castBar then return nil; end
	return o.castBar.points, o.castBar.iconPoints;
end

function K.RestoreCastBarPositions()


	for i = 1, MAX_ARENA_ENEMIES do
		if K.PositionArenaCastBar then
			K.PositionArenaCastBar(i);
		end
	end
end

function K.SetCastBarMouseState(state)

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

	local scale = 1.0;
	local width = 80;

	if K.SaveConfig then
		K.SaveConfig("ArenaCastBarScale", scale);
		K.SaveConfig("ArenaCastBarWidth", width);
	end
	C.ArenaCastBarScale = scale;
	C.ArenaCastBarWidth = width;

	if K.UpdateArenaCastBarScale then K.UpdateArenaCastBarScale(scale); end
	if K.UpdateArenaCastBarWidth then K.UpdateArenaCastBarWidth(width); end



	if K.RestoreCastBarPositions then K.RestoreCastBarPositions(); end
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


	SetupCastBarDrag();

	arenaMovementHooked = true;
end

local function CreateArenaAnchor()
	if NidhausArenaEnemyFrames then return; end

	NidhausArenaEnemyFrames = CreateFrame("Frame", "NidhausArenaEnemyFrames", UIParent);
	local scale = C.ArenaFrameScale or 1.5;
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then scale = 1.5; end


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


	local delays = {0.05, 0.15, 0.3, 0.5, 1.0, 2.0, 3.0, 5.0};
	retryTimerIndex = 0;
	if not retryTimerFrame then
		retryTimerFrame = CreateFrame("Frame");
	end
	local elapsed = 0;
	retryTimerFrame:SetScript("OnUpdate", function(self, dt)

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



local blizzHooksRegistered = false;
local function RegisterBlizzardArenaHooks()
	if blizzHooksRegistered then return; end


	if ArenaEnemyFrame_UpdatePlayer then
		hooksecurefunc("ArenaEnemyFrame_UpdatePlayer", function(self)
			if not isInitialized or not self then return; end
			ArenaFrames_OnLoad();
		end);
	end


	if ArenaEnemyFrame_Lock then
		hooksecurefunc("ArenaEnemyFrame_Lock", function(self)
			if not isInitialized or not self then return; end
			ArenaFrames_OnLoad();
		end);
	end


	if ArenaEnemyFrame_SetMysteryPlayer then
		hooksecurefunc("ArenaEnemyFrame_SetMysteryPlayer", function(self)
			if not isInitialized or not self then return; end
			ArenaFrames_OnLoad();
		end);
	end


	if ArenaEnemyFrame_Unlock then
		hooksecurefunc("ArenaEnemyFrame_Unlock", function(self)
			if not isInitialized or not self then return; end
			ArenaFrames_OnLoad();
		end);
	end


	if ArenaEnemyFrame_UpdatePlayer or ArenaEnemyFrame_Lock then
		blizzHooksRegistered = true;
	end
end


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



	hooksecurefunc("Arena_LoadUI", function()

		RegisterBlizzardArenaHooks();
		K._hookArenaContainers();
		ArenaFrames_OnLoad();
		ApplyWithRetries();
	end);


	if IsAddOnLoaded("Blizzard_ArenaUI") then
		RegisterBlizzardArenaHooks();
		K._hookArenaContainers();
	end

	hookRegistered = true;
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	if not C.ArenaFrameOn then return; end


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




	if InCombatLockdown() then
		local handler, ev = self:GetScript("OnEvent"), event;
		K.AfterCombat("ArenaWorldEvent", function() handler(self, ev); end);
		return;
	end




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

		for i = 1, (MAX_ARENA_ENEMIES or 5) do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame then frame:SetScale(1); end
		end
		if NidhausArenaEnemyFrames then NidhausArenaEnemyFrames:Hide(); end
		return;
	end




	if not isInitialized then
		Path = GetArenaTexturePath();
		if not NidhausArenaEnemyFrames then CreateArenaAnchor(); end
		RegisterArenaHook();
		isInitialized = true;
	end


	RegisterBlizzardArenaHooks();
	if K._hookArenaContainers then K._hookArenaContainers(); end


	if NidhausArenaEnemyFrames then NidhausArenaEnemyFrames:Show(); end
	ApplyWithRetries();
	if C.ArenaFrameScale then
		K.ApplyArenaScale(C.ArenaFrameScale);
	end




	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then

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

					local curParent = ArenaEnemyFrames:GetParent();
					if curParent ~= NidhausArenaEnemyFrames then
						ArenaFrames_OnLoad();
					end

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





function K.EnableArenaFrameMod()
	if K.AfterCombat("ArenaFrameMod", K.EnableArenaFrameMod) then return; end
	Path = GetArenaTexturePath();

	if not NidhausArenaEnemyFrames then
		CreateArenaAnchor();
	else
		NidhausArenaEnemyFrames:Show();
	end

	RegisterArenaHook();


	isInitialized = true;

	if IsAddOnLoaded("Blizzard_ArenaUI") then

		for i = 1, (MAX_ARENA_ENEMIES or 5) do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame and frame:GetParent() == ArenaEnemyFrames then
				frame:SetScale(1);
			end
		end


		ArenaFramesSettings();
		ApplyWithRetries();
		EnforceArenaScale();
	end
end

function K.DisableArenaFrameMod()
	if K.AfterCombat("ArenaFrameMod", K.DisableArenaFrameMod) then return; end


	isInitialized = false;



	if retryTimerFrame then
		retryTimerFrame:SetScript("OnUpdate", nil);
	end


	if IsAddOnLoaded("Blizzard_ArenaUI") then

		if K.RemoveAllFlatStyles then K.RemoveAllFlatStyles(); end


		RestoreDefaultArenaTextures();


		if ArenaEnemyFrames then
			ArenaEnemyFrames:SetScale(1);

			ArenaEnemyFrames:SetParent(UIParent);

			ArenaEnemyFrames:ClearAllPoints();
			ArenaEnemyFrames:SetPoint("RIGHT", UIParent, "RIGHT", -50, -110);
			ArenaEnemyFrames:Show();
		end


		for i = 1, MAX_ARENA_ENEMIES do
			local frame = _G["ArenaEnemyFrame"..i];
			if frame then
				frame:SetScale(1);
			end
		end


		for i = 2, MAX_ARENA_ENEMIES do
			local frame = _G["ArenaEnemyFrame"..i];
			local prevFrame = _G["ArenaEnemyFrame"..(i-1)];
			if frame and prevFrame then
				frame:ClearAllPoints();
				frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -20);
			end
		end


		if ArenaEnemyFrame1 and ArenaEnemyFrames then
			ArenaEnemyFrame1:ClearAllPoints();
			ArenaEnemyFrame1:SetPoint("TOPLEFT", ArenaEnemyFrames, "TOPLEFT", 0, 0);
		end


		if K.ResetMirrorCastBars then K.ResetMirrorCastBars(); end


		if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	end


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