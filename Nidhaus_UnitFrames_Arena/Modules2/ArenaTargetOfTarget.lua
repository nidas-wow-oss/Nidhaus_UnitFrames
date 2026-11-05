local AddOnName = ...;

local ns = NidhausUnitFramesNS;
local K, C, L = unpack(ns);

K.DeferModule("ArenaToT", {
	name      = "Arena Target of Target",
	desc      = "Shows who each arena enemy is targeting with Blizzard ToT-style frames.",
	default   = false,
}, function()
	local MEDIA_ADDON = "Nidhaus_UnitFrames";

	local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;

	local function TestCount()
		local n = K.GetArenaTestCount and K.GetArenaTestCount();
		if n == 2 or n == 3 or n == 5 then return n; end
		return 3;
	end

	local PositionToTFrame;

	local moduleActive = false;
	local eventFrame = CreateFrame("Frame");
	local totFrames = {};
	local dragOverlays = {};

	local FRAME_W, FRAME_H = 96, 46;
	local PORTRAIT_SIZE = 28;
	local BAR_W, BAR_H = 33, 4;
	local BORDER_TEXTURE = "Interface\\TargetingFrame\\UI-TargetofTargetFrame";
	local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar";

	local SQ = {
		frame    = { w = 70, h = 75 },
		border   = { w = 64, h = 64, y = -2 },
		portrait = { size = 32, y = 9 },
		health   = { w = 30, h = 10, y = -10 },
		mana     = { w = 30, h = 10 },
		name     = { w = 84 },
	};

	local TEXPATH       = "Interface\\AddOns\\" .. MEDIA_ADDON .. "\\Textures\\";

	local ICON_SIZE = 30;
	local function IconBorder(f)
		if f.nufIconBorder then return f.nufIconBorder; end
		local b = CreateFrame("Frame", nil, f);
		b:SetAllPoints(f);
		b:SetFrameLevel((f:GetFrameLevel() or 1) + 3);
		b:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 2 });
		b:SetBackdropBorderColor(0, 0, 0, 1);
		f.nufIconBorder = b;
		return b;
	end
	local SQUARE_TEX    = TEXPATH .. "TargetOfTargetSquare.tga";
	local SQUARE_BAR    = TEXPATH .. "beige.tga";

	local function GetClassColorRGB(class)
		if not class then return 0.7, 0.7, 0.7; end
		local cc = RAID_CLASS_COLORS[class];
		if cc then return cc.r, cc.g, cc.b; end
		return 0.7, 0.7, 0.7;
	end

	local function ApplyName(f, name, class)

		if C.ArenaToTHideName or C.ArenaToTIconOnly then
			f.nameText:SetText("");
			f.nameText:Hide();
			return;
		end
		f.nameText:SetText(name);
		local mode = C.ArenaToTNameColor;
		if mode == "white" then
			f.nameText:SetTextColor(1, 1, 1);
		elseif mode == "blizzard" then
			f.nameText:SetTextColor(1, 0.82, 0);
		else
			f.nameText:SetTextColor(GetClassColorRGB(class));
		end
		f.nameText:Show();
	end

	local function ShortName(name)
		local n, cut = 0, nil;
		for pos in name:gmatch("()[^\128-\191]") do
			n = n + 1;
			if n == 10 then cut = pos; end
			if n > 10 then return name:sub(1, cut - 1) .. ".."; end
		end
		return name;
	end

	local POWER_RGB = {
		[0] = { 0, 0, 1 }, [1] = { 1, 0, 0 }, [2] = { 1, 0.5, 0.25 },
		[3] = { 1, 1, 0 }, [6] = { 0, 0.82, 1 },
	};
	local function ColorPower(bar, pt)
		local c = POWER_RGB[pt] or POWER_RGB[0];
		bar:SetStatusBarColor(c[1], c[2], c[3]);
	end

	local function GetToTPositionKey()
		local style = C.ArenaFrameStyle or "Custom";
		local mirror = C.ArenaToTMirrored and "mirror" or "normal";
		return "tot_" .. style .. "_" .. mirror;
	end

	function K.GetSavedArenaToTPos()
		local db = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaToTPositions;
		if not db then return nil; end
		local key = GetToTPositionKey();
		return db[key];
	end

	local function SaveToTPosition(offsetX, offsetY)
		if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
		if not NidhausUnitFramesDB.ArenaToTPositions then NidhausUnitFramesDB.ArenaToTPositions = {}; end
		local posKey = GetToTPositionKey();
		NidhausUnitFramesDB.ArenaToTPositions[posKey] = {"CENTER", "CENTER", offsetX, offsetY};
	end

	function K.RestoreArenaToTPositions()
		local saved = K.GetSavedArenaToTPos();

		if not saved then
			for i = 1, MAX_ARENA_ENEMIES do
				if totFrames[i] then PositionToTFrame(i); end
			end
			return;
		end
		for i = 1, MAX_ARENA_ENEMIES do
			local f = totFrames[i];
			local af = _G["ArenaEnemyFrame"..i];
			if f and af then
				f:ClearAllPoints();
				f:SetPoint(saved[1], af, saved[2], saved[3], saved[4]);
			end
		end
	end

	function K.ResetArenaToTPositions()
		local db = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaToTPositions;
		if type(db) == "table" then db[GetToTPositionKey()] = nil; end
		for i = 1, MAX_ARENA_ENEMIES do
			PositionToTFrame(i);
		end
	end

	local function ApplyFrameLayout(f, mirrored)
		if not f then return; end

		f.portrait:ClearAllPoints();
		f.healthbar:ClearAllPoints();
		f.manabar:ClearAllPoints();
		f.nameText:ClearAllPoints();

		if C.ArenaToTIconOnly then
			f:SetSize(ICON_SIZE, ICON_SIZE);
			f.borderTex:Hide();
			f.healthbar:Hide();
			f.manabar:Hide();
			f.nameText:Hide();
			f.portrait:SetAllPoints(f);
			IconBorder(f):Show();
			return;
		end
		f.borderTex:Show();
		f.healthbar:Show();
		f.manabar:Show();
		if f.nufIconBorder then f.nufIconBorder:Hide(); end

		if C.ArenaToTSquare then
			f:SetSize(SQ.frame.w, SQ.frame.h);

			local tex = f.borderTex;
			tex:SetTexture(SQUARE_TEX);
			tex:SetTexCoord(0, 1, 0, 1);
			tex:ClearAllPoints();
			tex:SetSize(SQ.border.w, SQ.border.h);
			tex:SetPoint("CENTER", f, "CENTER", 0, SQ.border.y);
			tex:SetVertexColor(1, 1, 1, 1);

			f.portrait:SetSize(SQ.portrait.size, SQ.portrait.size);
			f.portrait:SetPoint("CENTER", tex, "CENTER", 0, SQ.portrait.y);

			f.healthbar:SetSize(SQ.health.w, SQ.health.h);
			f.healthbar:SetPoint("CENTER", tex, "CENTER", 0, SQ.health.y);
			f.healthbar:SetStatusBarTexture(SQUARE_BAR);

			f.manabar:SetSize(SQ.mana.w, SQ.mana.h);
			f.manabar:SetPoint("TOPLEFT", f.healthbar, "BOTTOMLEFT", 0, 0);
			f.manabar:SetStatusBarTexture(SQUARE_BAR);

			f.nameText:SetSize(SQ.name.w, 10);
			f.nameText:SetPoint("BOTTOM", tex, "TOP", 0, -2);
			f.nameText:SetJustifyH("CENTER");
			return;
		end

		f:SetSize(FRAME_W, FRAME_H);
		f.borderTex:SetTexture(BORDER_TEXTURE);
		f.borderTex:ClearAllPoints();
		f.borderTex:SetSize(FRAME_W, FRAME_H);
		f.borderTex:SetPoint("TOPLEFT", 0, 0);
		f.borderTex:SetVertexColor(1, 1, 1, 1);
		f.portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE);
		f.healthbar:SetSize(BAR_W, BAR_H);
		f.healthbar:SetStatusBarTexture(BAR_TEXTURE);
		f.manabar:SetSize(BAR_W, BAR_H);
		f.manabar:SetStatusBarTexture(BAR_TEXTURE);

		if mirrored then

			f.portrait:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -2);

			f.healthbar:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -11);
			f.manabar:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -18);

			f.nameText:SetSize(60, 10);
			f.nameText:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -22);
			f.nameText:SetJustifyH("LEFT");

			f.borderTex:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1);
		else

			f.portrait:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -2);

			f.healthbar:SetPoint("TOPLEFT", f, "TOPLEFT", 35, -11);
			f.manabar:SetPoint("TOPLEFT", f, "TOPLEFT", 35, -18);

			f.nameText:SetSize(60, 10);
			f.nameText:SetPoint("TOPLEFT", f, "TOPLEFT", 35, -22);
			f.nameText:SetJustifyH("LEFT");

			f.borderTex:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1);
		end
	end

	local function ApplyMirrorToAll()
		local mirrored = C.ArenaToTMirrored;
		for i = 1, MAX_ARENA_ENEMIES do
			if totFrames[i] then ApplyFrameLayout(totFrames[i], mirrored); end
		end
	end

	function K.RefreshArenaToTLayout()
		ApplyMirrorToAll();
		if K.RepositionAllArenaToT then K.RepositionAllArenaToT(); end
	end

	local function CreateToTFrame(index)
		if totFrames[index] then return totFrames[index]; end
		local arenaFrame = _G["ArenaEnemyFrame"..index];
		if not arenaFrame then return nil; end

		local name = "NUF_ArenaToTFrame"..index;
		local f = CreateFrame("Button", name, arenaFrame);
		f:SetSize(FRAME_W, FRAME_H);
		f:SetFrameStrata("MEDIUM");
		f:SetFrameLevel(10);
		f:SetID(index);

		local portrait = f:CreateTexture(name.."Portrait", "BACKGROUND");
		portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE);
		portrait:SetPoint("TOPLEFT", 4, -2);
		f.portrait = portrait;

		local hb = CreateFrame("StatusBar", name.."HealthBar", f);
		hb:SetSize(BAR_W, BAR_H);
		hb:SetPoint("TOPLEFT", 35, -11);
		hb:SetStatusBarTexture(BAR_TEXTURE);
		hb:SetMinMaxValues(0, 1); hb:SetValue(1);
		hb:SetStatusBarColor(0, 1, 0);
		hb:SetFrameLevel(f:GetFrameLevel() + 1);
		f.healthbar = hb;

		local hbBG = hb:CreateTexture(nil, "BACKGROUND");
		hbBG:SetAllPoints(); hbBG:SetTexture(0, 0, 0, 0.5);

		local mb = CreateFrame("StatusBar", name.."ManaBar", f);
		mb:SetSize(BAR_W, BAR_H);
		mb:SetPoint("TOPLEFT", 35, -18);
		mb:SetStatusBarTexture(BAR_TEXTURE);
		mb:SetMinMaxValues(0, 1); mb:SetValue(1);
		mb:SetStatusBarColor(0, 0, 1);
		mb:SetFrameLevel(f:GetFrameLevel() + 1);
		f.manabar = mb;

		local mbBG = mb:CreateTexture(nil, "BACKGROUND");
		mbBG:SetAllPoints(); mbBG:SetTexture(0, 0, 0, 0.5);

		local border = f:CreateTexture(name.."Texture", "ARTWORK");
		border:SetSize(FRAME_W, FRAME_H);
		border:SetPoint("TOPLEFT", 0, 0);
		border:SetTexture(BORDER_TEXTURE);
		f.borderTex = border;

		local nameFS = f:CreateFontString(name.."Name", "OVERLAY", "GameFontNormalSmall");
		nameFS:SetSize(60, 10);
		nameFS:SetPoint("TOPLEFT", 35, -22);
		nameFS:SetJustifyH("LEFT");
		nameFS:SetTextColor(1, 0.82, 0);
		f.nameText = nameFS;

		local scale = C.ArenaToTScale or 1.0;
		if scale > 0 then f:SetScale(scale); end

		f:EnableMouse(false);
		f:SetMovable(true);
		f:Hide();
		totFrames[index] = f;

		ApplyFrameLayout(f, C.ArenaToTMirrored);

		return f;
	end

	function PositionToTFrame(index)
		local f = totFrames[index];
		if not f then return; end
		local arenaFrame = _G["ArenaEnemyFrame"..index];
		if not arenaFrame then return; end

		f:SetParent(arenaFrame);
		f:ClearAllPoints();

		local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
		local isMirror = C.ArenaToTMirrored;

		if isFlat then
			if isMirror then
				f:SetPoint("TOPRIGHT", arenaFrame, "TOPLEFT", -4, 0);
			else
				f:SetPoint("TOPLEFT", arenaFrame, "TOPRIGHT", 4, 0);
			end
		else
			if isMirror then
				f:SetPoint("TOPRIGHT", arenaFrame, "TOPLEFT", 10, -4);
			else
				f:SetPoint("TOPLEFT", arenaFrame, "TOPRIGHT", -10, -4);
			end
		end
	end

	function K.RepositionAllArenaToT()
		if not moduleActive then return; end
		for i = 1, MAX_ARENA_ENEMIES do
			PositionToTFrame(i);
		end

		K.RestoreArenaToTPositions();
	end

	function K.ApplyArenaToTScale(scale)
		if type(scale) ~= "number" or scale <= 0 then scale = 1.0; end
		for i = 1, MAX_ARENA_ENEMIES do
			if totFrames[i] then totFrames[i]:SetScale(scale); end
		end
	end

	local function SetPortraitOrClassIcon(f, unit, class)
		if not f or not f.portrait then return; end
		if (C.ArenaToTClassIcon or C.ArenaToTIconOnly) and class then
			local coords = CLASS_ICON_TCOORDS[class];
			if coords then
				f.portrait:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
				f.portrait:SetTexCoord(unpack(coords));
				return;
			end
		end

		if unit and UnitExists(unit) then
			SetPortraitTexture(f.portrait, unit);
			f.portrait:SetTexCoord(0, 1, 0, 1);
		end
	end

	local function CreateDragOverlay(index)
		local f = totFrames[index];
		if not f then return; end
		if dragOverlays[index] then return dragOverlays[index]; end

		local overlayName = "NUF_ArenaToTDragOverlay"..index;
		local overlay = CreateFrame("Frame", overlayName, f);
		overlay:SetAllPoints(f);
		overlay:SetFrameStrata("TOOLTIP");
		overlay:EnableMouse(true);
		overlay:SetMovable(true);
		overlay._totFrame = f;
		overlay._index = index;

		overlay:SetScript("OnMouseDown", function(self, button)
			if button ~= "LeftButton" then return; end
			if InCombatLockdown() then return; end
			if IsShiftKeyDown() and IsAltKeyDown() then
				local tot = self._totFrame;
				tot:StartMoving();
				tot:SetUserPlaced(false);
				tot._isMoving = true;
			end
		end);

		overlay:SetScript("OnMouseUp", function(self, button)
			if button ~= "LeftButton" then return; end
			local tot = self._totFrame;
			if not tot._isMoving then return; end
			tot:StopMovingOrSizing();
			tot._isMoving = false;

			local idx = self._index;
			local arenaFrame = _G["ArenaEnemyFrame"..idx];
			if not arenaFrame then return; end

			local parentX, parentY = arenaFrame:GetCenter();
			local frameX, frameY = tot:GetCenter();
			if not parentX or not frameX then return; end

			local totScale = tot:GetEffectiveScale();
			local afScale = arenaFrame:GetEffectiveScale();
			local offsetX = (frameX * totScale - parentX * afScale) / totScale;
			local offsetY = (frameY * totScale - parentY * afScale) / totScale;
			offsetX = math.floor(offsetX * 10 + 0.5) / 10;
			offsetY = math.floor(offsetY * 10 + 0.5) / 10;

			tot:ClearAllPoints();
			tot:SetPoint("CENTER", arenaFrame, "CENTER", offsetX, offsetY);

			SaveToTPosition(offsetX, offsetY);
			for j = 1, MAX_ARENA_ENEMIES do
				if totFrames[j] and j ~= idx then
					local af = _G["ArenaEnemyFrame"..j];
					if af then
						totFrames[j]:ClearAllPoints();
						totFrames[j]:SetPoint("CENTER", af, "CENTER", offsetX, offsetY);
					end
				end
			end
		end);

		overlay:SetScript("OnHide", function(self)
			local tot = self._totFrame;
			if tot and tot._isMoving then
				tot:StopMovingOrSizing();
				tot._isMoving = false;
			end
		end);

		overlay:Hide();
		dragOverlays[index] = overlay;
		return overlay;
	end

	local function ShowDragOverlays()
		for i = 1, TestCount() do
			if totFrames[i] and totFrames[i]:IsShown() then
				local ov = CreateDragOverlay(i);
				if ov then ov:Show(); end
			end
		end
	end

	local function HideDragOverlays()
		for i = 1, MAX_ARENA_ENEMIES do
			if dragOverlays[i] then dragOverlays[i]:Hide(); end
		end
	end

	K.ShowArenaToTDragOverlays = ShowDragOverlays;
	K.HideArenaToTDragOverlays = HideDragOverlays;

	local function UpdateToTFrame(index)
		local f = totFrames[index];
		if not f then return; end
		local arenaFrame = _G["ArenaEnemyFrame"..index];
		if not arenaFrame or not arenaFrame:IsShown() then f:Hide(); return; end

		local targetUnit = "arena"..index.."target";
		if not UnitExists(targetUnit) then f:Hide(); return; end

		local _, targetClass = UnitClass(targetUnit);
		SetPortraitOrClassIcon(f, targetUnit, targetClass);

		ApplyName(f, ShortName(UnitName(targetUnit) or "?"), targetClass);

		local hp = UnitHealth(targetUnit) or 0;
		local hpMax = UnitHealthMax(targetUnit); if not hpMax or hpMax <= 0 then hpMax = 1; end
		f.healthbar:SetMinMaxValues(0, hpMax); f.healthbar:SetValue(hp);
		f.healthbar:SetStatusBarColor(GetClassColorRGB(targetClass));

		local mp = UnitMana(targetUnit) or 0;
		local mpMax = UnitManaMax(targetUnit); if not mpMax or mpMax <= 0 then mpMax = 1; end
		f.manabar:SetMinMaxValues(0, mpMax); f.manabar:SetValue(mp);
		ColorPower(f.manabar, UnitPowerType(targetUnit));

		f:Show();
	end

	local function UpdateAll()
		for i = 1, MAX_ARENA_ENEMIES do UpdateToTFrame(i); end
	end

	local function StartPolling()
		if eventFrame._polling then return; end
		eventFrame._polling = true;
		local el = 0;
		eventFrame:SetScript("OnUpdate", function(s, dt)
			el = el + dt;
			if el >= 0.5 then el = 0; UpdateAll(); end
		end);
	end

	local testData = {
		{name = "target1", class = "WARLOCK",     hp = 18000, hpMax = 22000, mp = 8500, mpMax = 12000, power = 0},
		{name = "target2", class = "DEATHKNIGHT", hp = 30000, hpMax = 35000, mp = 80,   mpMax = 100,   power = 6},
		{name = "target3", class = "SHAMAN",      hp = 25000, hpMax = 28000, mp = 9000, mpMax = 15000, power = 0},
		{name = "target4", class = "ROGUE",       hp = 20000, hpMax = 24000, mp = 70,   mpMax = 100,   power = 3},
		{name = "target5", class = "WARRIOR",     hp = 32000, hpMax = 36000, mp = 40,   mpMax = 100,   power = 1},
	};

	local function ShowTestMode()
		local scale = C.ArenaToTScale or 1.0;
		local count = TestCount();
		for i = 1, MAX_ARENA_ENEMIES do
			local f = CreateToTFrame(i);
			local d = testData[i];
			if f and d and i <= count then
				PositionToTFrame(i);
				if scale > 0 then f:SetScale(scale); end

				local coords = CLASS_ICON_TCOORDS[d.class];
				if coords and f.portrait then
					f.portrait:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
					f.portrait:SetTexCoord(unpack(coords));
				end

				ApplyName(f, d.name, d.class);
				f.healthbar:SetMinMaxValues(0, d.hpMax); f.healthbar:SetValue(d.hp);
				f.healthbar:SetStatusBarColor(GetClassColorRGB(d.class));
				f.manabar:SetMinMaxValues(0, d.mpMax); f.manabar:SetValue(d.mp);
				ColorPower(f.manabar, d.power);

				f:Show();
			elseif f then

				f:Hide();
				if dragOverlays[i] then dragOverlays[i]:Hide(); end
			end
		end

		ApplyMirrorToAll();

		K.RestoreArenaToTPositions();

		ShowDragOverlays();
	end

	local function HideAll()
		HideDragOverlays();
		for i = 1, MAX_ARENA_ENEMIES do if totFrames[i] then totFrames[i]:Hide(); end end
	end

	K._ShowArenaToTTest = ShowTestMode;
	K._HideArenaToTTest = HideAll;

	local function OnEvent(self, event, unit)
		if event == "UNIT_TARGET" then
			if not unit or not unit:find("^arena") or unit:find("pet") then return; end
			local idx = tonumber(unit:match("(%d+)$"));
			if idx then UpdateToTFrame(idx); end
		elseif event == "UNIT_HEALTH" or event == "UNIT_MANA" or event == "UNIT_RAGE"
			or event == "UNIT_ENERGY" or event == "UNIT_RUNIC_POWER" then
			if not unit then return; end
			for i = 1, MAX_ARENA_ENEMIES do
				if UnitIsUnit(unit, "arena"..i.."target") then UpdateToTFrame(i); break; end
			end
		elseif event == "ARENA_OPPONENT_UPDATE" then
			if unit then
				local idx = tonumber(unit:match("(%d+)$"));
				if idx then
					CreateToTFrame(idx);
					PositionToTFrame(idx);

					K.RestoreArenaToTPositions();
					K.ApplyArenaToTScale(C.ArenaToTScale or 1.0);
					UpdateToTFrame(idx);
				end
			end
		elseif event == "PLAYER_ENTERING_WORLD" then
			local _, iType = IsInInstance();
			if iType == "arena" then
				for i = 1, MAX_ARENA_ENEMIES do CreateToTFrame(i); PositionToTFrame(i); end
				K.RestoreArenaToTPositions();
				K.ApplyArenaToTScale(C.ArenaToTScale or 1.0);
				StartPolling();
			else
				HideAll(); self:SetScript("OnUpdate", nil); self._polling = false;
			end
		elseif event == "ZONE_CHANGED_NEW_AREA" then
			local _, iType = IsInInstance();
			if iType ~= "arena" then HideAll(); self:SetScript("OnUpdate", nil); self._polling = false; end
		end
	end

	local testModeWatcher = CreateFrame("Frame");
	testModeWatcher:Hide();
	local twElapsed, lastState, lastCount = 0, false, nil;

	local showDelay = CreateFrame("Frame");
	showDelay:Hide();
	showDelay:SetScript("OnUpdate", function(s, dt)
		s.e = (s.e or 0) + dt;
		if s.e >= 0.4 then
			s:Hide();
			if moduleActive then ShowTestMode(); end
		end
	end);
	local function ShowTestSoon()
		showDelay.e = 0;
		showDelay:Show();
	end

	testModeWatcher:SetScript("OnUpdate", function(self, dt)
		if not moduleActive then return; end
		twElapsed = twElapsed + dt;
		if twElapsed < 0.3 then return; end
		twElapsed = 0;
		local isTest = K._testModeActive or
			(NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown);
		local count = TestCount();
		if isTest and (not lastState or count ~= lastCount) then

			lastState, lastCount = true, count;
			ShowTestSoon();
		elseif not isTest and lastState then
			lastState = false; HideAll();
		end
	end);

	K.RegisterConfigEvent("CONFIG_CHANGED", function()
		if not moduleActive then return; end
		ApplyMirrorToAll();
		K.ApplyArenaToTScale(C.ArenaToTScale or 1.0);

		local isTest = K._testModeActive or
			(NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown);
		if isTest then
			ShowTestMode();
		else
			K.RepositionAllArenaToT();

			local _, iType = IsInInstance();
			if iType == "arena" then UpdateAll(); end
		end
	end);

	local function Enable()
		moduleActive = true;
		eventFrame:RegisterEvent("UNIT_TARGET");
		eventFrame:RegisterEvent("UNIT_HEALTH");
		eventFrame:RegisterEvent("UNIT_MANA");
		eventFrame:RegisterEvent("UNIT_RAGE");
		eventFrame:RegisterEvent("UNIT_ENERGY");
		eventFrame:RegisterEvent("UNIT_RUNIC_POWER");
		eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE");
		eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
		eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
		eventFrame:SetScript("OnEvent", OnEvent);
		testModeWatcher:Show();

		local _, iType = IsInInstance();
		if iType == "arena" then
			for i = 1, MAX_ARENA_ENEMIES do CreateToTFrame(i); PositionToTFrame(i); end
			K.RestoreArenaToTPositions();
			StartPolling();
		end
		if K._testModeActive or
			(NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown) then
			ShowTestMode(); lastState, lastCount = true, TestCount();
		end
	end

	local function Disable()
		moduleActive = false;
		eventFrame:UnregisterAllEvents();
		eventFrame:SetScript("OnEvent", nil);
		eventFrame:SetScript("OnUpdate", nil);
		eventFrame._polling = false;
		testModeWatcher:Hide();
		lastState = false;
		HideAll();
	end

	K.RegisterModule("ArenaToT", {
		onEnable  = Enable,
		onDisable = Disable,
	});
end);
