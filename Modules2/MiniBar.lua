-- MiniBar — NUF Module
-- Compact action bar layout (half-width main bar, stacked bars, BagPackFrame)
-- Based on FriskesBar logic from FriskesUI by Friskes
-- Integrated into NidhausUnitFrames

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ============================================================
-- Bar stacking config
-- ============================================================
local config = {
	ShapeshiftBar = { offsetX = 20 },
	TotemBar      = { offsetX = 20 },
	LeaveButton   = { offsetX = -36 },
	PetBar        = { offsetX = 60 },
	PossessBar    = { offsetX = 0 },
};

local minibarEnabled = false;
local gridShown = false;
local initTime = 0;
local minibarHooked = false;
local _, playerClass = UnitClass("player");

-- Save/restore state
local mb_savedFrames    = {};  -- { point, rel, relPoint, x, y, width, height }
local mb_savedTextures  = {};  -- { obj, alpha, shown }
local mb_savedTexPaths  = {};  -- { obj, texture } for SetTexture("") cases
local mb_savedManaged   = {};  -- UIPARENT_MANAGED_FRAME_POSITIONS originals

-- ============================================================
-- BagPackFrame texture path (file lives in MiniBar addon folder)
-- ============================================================
local BAGPACK_TEXTURE = "Interface\\AddOns\\"..AddOnName.."\\Modules2\\Textures\\bagpack";

-- ============================================================
-- Shared: Create BagPackFrame (used by both MiniBar and Unify)
-- ============================================================
function K.CreateBagPackFrame()
	if BagPackFrame then
		-- FIX: Re-show frame (gets hidden by DisableMiniBar/DisableUnifyActionBars)
		BagPackFrame:Show();
		if BagPackFrame.texture then
			if C.ShowBagPackTexture == false then BagPackFrame.texture:Hide(); else BagPackFrame.texture:Show(); end
		end
		-- FIX: Always re-apply scale (frame may retain old scale from previous mode)
		local scale = C.ActionBarScale;
		if type(scale) == "number" and scale > 0 then
			BagPackFrame:SetScale(scale);
		end
		return BagPackFrame;
	end

	local XPOS = 107;
	local YPOS = -84.3;

	BagPackFrame = CreateFrame("Frame", "BagPackFrame", UIParent);
	BagPackFrame:SetFrameStrata("BACKGROUND");
	BagPackFrame:SetSize(512, 256);
	BagPackFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", XPOS, YPOS);

	local BagPackTexture = BagPackFrame:CreateTexture(nil, "BACKGROUND");
	BagPackTexture:SetTexture(BAGPACK_TEXTURE);
	BagPackTexture:SetAllPoints(BagPackFrame);
	BagPackFrame.texture = BagPackTexture;

	-- Show/hide TEXTURE only based on config (frame must stay visible for anchoring)
	BagPackFrame:Show();
	if C.ShowBagPackTexture == false then
		BagPackFrame.texture:Hide();
	else
		BagPackFrame.texture:Show();
	end

	-- FIX: Apply saved ActionBarScale immediately on creation.
	local scale = C.ActionBarScale;
	if type(scale) == "number" and scale > 0 then
		BagPackFrame:SetScale(scale);
	end

	return BagPackFrame;
end

-- ============================================================
-- Shared: Apply micro menu and bag positions onto BagPackFrame
-- ============================================================
local MicroButtons = {
	"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
	"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
};

function K.ApplyBagPackLayout()
	if not BagPackFrame then return; end
	if InCombatLockdown() then return; end
	if K._applyingBagPack then return; end -- guard against recursion
	K._applyingBagPack = true;

	-- FIX: Micro buttons are reparented to UIParent, so they don't inherit
	-- MainMenuBar's scale. Apply ActionBarScale explicitly to them only.
	-- Bags/backpack are children of MainMenuBarArtFrame (child of MainMenuBar)
	-- so they ALREADY inherit MainMenuBar:SetScale(scale) — do NOT double-scale them.
	local abScale = C.ActionBarScale;
	if type(abScale) ~= "number" or abScale <= 0 then abScale = 1.0; end

	-- Micro buttons → parented to UIParent (need explicit scale)
	for _, name in ipairs(MicroButtons) do
		local btn = _G[name];
		if btn then
			btn:SetParent(UIParent);
			btn:SetFrameStrata("MEDIUM");
			btn:SetScale(abScale);
			btn:Show();
		end
	end

	CharacterMicroButton:ClearAllPoints();
	CharacterMicroButton:SetPoint("CENTER", BagPackFrame, -93.5, -11.8);

	if SocialsMicroButton then
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("BOTTOMLEFT", QuestLogMicroButton, "BOTTOMRIGHT", -3, 0);
	end

	-- NOTE: Do NOT call UpdateMicroButtons() here — it causes infinite recursion
	-- via the hook in ActionBars.lua

	-- Bag slots → anchored to BagPackFrame but parented to MainMenuBarArtFrame
	-- They inherit MainMenuBar:SetScale() via parent chain — only set RELATIVE scale
	MainMenuBarBackpackButton:ClearAllPoints();
	MainMenuBarBackpackButton:SetPoint("CENTER", BagPackFrame, 124.8, 21.8);

	CharacterBag0Slot:ClearAllPoints();
	CharacterBag0Slot:SetPoint("CENTER", MainMenuBarBackpackButton, -39, -5.1);
	CharacterBag0Slot:SetScale(0.98);

	CharacterBag1Slot:ClearAllPoints();
	CharacterBag1Slot:SetPoint("CENTER", MainMenuBarBackpackButton, -72.3, -5.1);
	CharacterBag1Slot:SetScale(0.98);

	CharacterBag2Slot:ClearAllPoints();
	CharacterBag2Slot:SetPoint("CENTER", MainMenuBarBackpackButton, -105, -5.1);
	CharacterBag2Slot:SetScale(0.98);

	CharacterBag3Slot:ClearAllPoints();
	CharacterBag3Slot:SetPoint("CENTER", MainMenuBarBackpackButton, -137.9, -5.1);
	CharacterBag3Slot:SetScale(0.98);

	KeyRingButton:ClearAllPoints();
	KeyRingButton:SetPoint("CENTER", MainMenuBarBackpackButton, -177, -5.9);
	KeyRingButton:SetScale(0.91);

	K._applyingBagPack = false;
end

-- ============================================================
-- Shared: Gryphon toggle (works for any action bar mode)
-- ============================================================
function K.ApplyGryphons()
	if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then return; end

	-- If no bar mode is active, DO NOT TOUCH gryphons — let Blizzard handle them
	if not K._unifyActive and not K._minibarActive then return; end

	if C.HideGryphons then
		MainMenuBarLeftEndCap:Hide();
		MainMenuBarLeftEndCap:SetAlpha(0);
		MainMenuBarRightEndCap:Hide();
		MainMenuBarRightEndCap:SetAlpha(0);
	else
		MainMenuBarLeftEndCap:SetAlpha(1);
		MainMenuBarLeftEndCap:Show();
		MainMenuBarRightEndCap:SetAlpha(1);
		MainMenuBarRightEndCap:Show();
		-- Reposition gryphons based on active mode
		if K._unifyActive then
			local yOff = 0;
			if MainMenuExpBar and MainMenuExpBar:IsShown() then yOff = yOff + 5; end
			if ReputationWatchBar and ReputationWatchBar:IsShown() then yOff = yOff + 5; end
			MainMenuBarLeftEndCap:ClearAllPoints();
			MainMenuBarRightEndCap:ClearAllPoints();
			MainMenuBarLeftEndCap:SetPoint("BOTTOM", MainMenuBar, "BOTTOMLEFT", -30, yOff - 5);
			MainMenuBarRightEndCap:SetPoint("BOTTOM", MainMenuBar, "BOTTOMRIGHT", 280, yOff - 5);
		elseif K._minibarActive then
			MainMenuBarLeftEndCap:ClearAllPoints();
			MainMenuBarRightEndCap:ClearAllPoints();
			MainMenuBarLeftEndCap:SetPoint("BOTTOM", MainMenuBar, "BOTTOMLEFT", -30, 0);
			MainMenuBarRightEndCap:SetPoint("BOTTOM", MainMenuBar, "BOTTOMRIGHT", 30, 0);
		end
	end
end

-- ============================================================
-- Shared: Action bar scale (works for any action bar mode)
-- ============================================================
function K.ApplyActionBarScale(scale)
	if InCombatLockdown() then return; end
	if type(scale) ~= "number" or scale <= 0 then scale = 1.0; end
	-- Core bars — bags inherit scale from MainMenuBar via parent chain
	if MainMenuBar then MainMenuBar:SetScale(scale); end
	if VehicleMenuBar then VehicleMenuBar:SetScale(scale); end
	if MultiBarBottomRight then MultiBarBottomRight:SetScale(scale); end
	if MultiBarBottomLeft then MultiBarBottomLeft:SetScale(scale); end
	if MultiBarRight then MultiBarRight:SetScale(scale); end
	if MultiBarLeft then MultiBarLeft:SetScale(scale); end
	-- BagPackFrame is parented to UIParent — needs explicit scale
	if BagPackFrame and (K._minibarActive or K._unifyActive) then BagPackFrame:SetScale(scale); end
	-- FIX: Re-apply BagPackLayout for micro buttons (parented to UIParent,
	-- don't inherit MainMenuBar scale). Bags don't need this — they inherit.
	if (K._minibarActive or K._unifyActive) and K.ApplyBagPackLayout then
		K.ApplyBagPackLayout();
	end
end

-- ============================================================
-- Shared: BagPack texture visibility toggle
-- ============================================================
function K.ApplyBagPackTexture()
	if not BagPackFrame or not BagPackFrame.texture then return; end
	if C.ShowBagPackTexture then
		BagPackFrame.texture:Show();
	else
		BagPackFrame.texture:Hide();
	end
end

-- FIX: Helper — ¿algún modo de barra (MiniBar/Unify) está activo?
function K.IsAnyBarModeActive()
	return (K._minibarActive == true) or (K._unifyActive == true);
end

-- ============================================================
-- MiniBar internal: Save/Restore helpers
-- ============================================================
local function MB_SaveFrame(name, frame)
	if not frame or mb_savedFrames[name] then return; end
	local point, rel, relPoint, x, y = frame:GetPoint(1);
	mb_savedFrames[name] = {
		point    = point,
		rel      = rel,
		relPoint = relPoint,
		x        = x or 0,
		y        = y or 0,
		width    = frame.GetWidth  and frame:GetWidth()  or nil,
		height   = frame.GetHeight and frame:GetHeight() or nil,
		-- FIX: También guardar scale (antes no se guardaba, causaba rep bar bug al cambiar modo)
		scale    = frame.GetScale  and frame:GetScale()  or nil,
	};
	-- Guardar font si es un FontString
	if frame.GetFont then
		local f, s, fl = frame:GetFont();
		if f then mb_savedFrames[name].font = {f, s, fl}; end
	end
end

local function MB_RestoreFrame(name, frame)
	if not frame then return; end
	local s = mb_savedFrames[name];
	if not s then return; end
	frame:ClearAllPoints();
	if s.point then
		frame:SetPoint(s.point, s.rel, s.relPoint, s.x, s.y);
	end
	if s.width  and s.width  > 0 then frame:SetWidth(s.width);   end
	if s.height and s.height > 0 then frame:SetHeight(s.height); end
	-- FIX: Restaurar scale
	if s.scale and frame.SetScale then frame:SetScale(s.scale); end
	-- FIX: Restaurar font si fue guardada
	if s.font and frame.SetFont then frame:SetFont(unpack(s.font)); end
end

local function MB_SaveTexture(obj)
	if not obj then return; end
	table.insert(mb_savedTextures, {
		obj   = obj,
		alpha = obj:GetAlpha(),
		shown = obj:IsShown(),
	});
end

local function MB_SaveTexturePath(obj)
	if not obj then return; end
	table.insert(mb_savedTexPaths, {
		obj     = obj,
		texture = obj:GetTexture(),
	});
end

local function MB_RestoreAllTextures()
	for _, t in ipairs(mb_savedTextures) do
		t.obj:SetAlpha(t.alpha);
		if t.shown then t.obj:Show(); else t.obj:Hide(); end
	end
	for _, t in ipairs(mb_savedTexPaths) do
		t.obj:SetTexture(t.texture);
	end
end

local function MB_CaptureOriginals()
	mb_savedFrames   = {};
	mb_savedTextures = {};
	mb_savedTexPaths = {};
	mb_savedManaged  = {};

	-- Frame positions & sizes
	MB_SaveFrame("MainMenuBar",              MainMenuBar);
	MB_SaveFrame("MainMenuExpBar",           MainMenuExpBar);
	MB_SaveFrame("ReputationWatchBar",       ReputationWatchBar);
	MB_SaveFrame("MainMenuBarMaxLevelBar",   MainMenuBarMaxLevelBar);
	MB_SaveFrame("ReputationWatchStatusBar", ReputationWatchStatusBar);
	-- FIX: Guardar también los textos de rep y exp (Unify los modifica)
	if ReputationWatchStatusBarText then MB_SaveFrame("ReputationWatchStatusBarText", ReputationWatchStatusBarText); end
	if MainMenuBarExpText then MB_SaveFrame("MainMenuBarExpText", MainMenuBarExpText); end
	if ExhaustionTick then MB_SaveFrame("ExhaustionTick", ExhaustionTick); end
	MB_SaveFrame("MainMenuXPBarTexture0",    MainMenuXPBarTexture0);
	MB_SaveFrame("MainMenuXPBarTexture3",    MainMenuXPBarTexture3);
	MB_SaveFrame("ReputationWatchBarTexture3", ReputationWatchBarTexture3);
	MB_SaveFrame("ReputationXPBarTexture3",  ReputationXPBarTexture3);
	MB_SaveFrame("MainMenuMaxLevelBar0",     MainMenuMaxLevelBar0);
	MB_SaveFrame("MainMenuBarTexture0",      MainMenuBarTexture0);
	MB_SaveFrame("MainMenuBarTexture1",      MainMenuBarTexture1);
	if ActionBarUpButton       then MB_SaveFrame("ActionBarUpButton",       ActionBarUpButton);       end
	if ActionBarDownButton     then MB_SaveFrame("ActionBarDownButton",     ActionBarDownButton);     end
	if MainMenuBarPageNumber   then MB_SaveFrame("MainMenuBarPageNumber",   MainMenuBarPageNumber);   end
	if BonusActionButton1      then MB_SaveFrame("BonusActionButton1",      BonusActionButton1);      end
	if MultiBarBottomRight     then MB_SaveFrame("MultiBarBottomRight",     MultiBarBottomRight);     end
	if ShapeshiftButton1       then MB_SaveFrame("ShapeshiftButton1",       ShapeshiftButton1);       end
	if MultiCastActionBarFrame       then MB_SaveFrame("MultiCastActionBarFrame",       MultiCastActionBarFrame);       end
	if MainMenuBarVehicleLeaveButton then MB_SaveFrame("MainMenuBarVehicleLeaveButton", MainMenuBarVehicleLeaveButton); end
	if PetActionButton1 then MB_SaveFrame("PetActionButton1", PetActionButton1); end
	if PossessButton1   then MB_SaveFrame("PossessButton1",   PossessButton1);   end

	-- FIX: Guardar posicion original de gryphons (Blizzard las posiciona dinamicamente)
	if MainMenuBarLeftEndCap  then MB_SaveFrame("MainMenuBarLeftEndCap",  MainMenuBarLeftEndCap);  end
	if MainMenuBarRightEndCap then MB_SaveFrame("MainMenuBarRightEndCap", MainMenuBarRightEndCap); end

	-- Micro buttons
	local microNames = {
		"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
		"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
		"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
	};
	for _, name in ipairs(microNames) do
		local f = _G[name];
		if f then
			MB_SaveFrame(name, f);
			-- Guardar parent original también
			if not mb_savedFrames[name] then mb_savedFrames[name] = {}; end
			mb_savedFrames[name].parent = f:GetParent();
		end
	end

	-- Bag slots
	MB_SaveFrame("MainMenuBarBackpackButton", MainMenuBarBackpackButton);
	if CharacterBag0Slot then MB_SaveFrame("CharacterBag0Slot", CharacterBag0Slot); mb_savedFrames["CharacterBag0Slot"].scale = CharacterBag0Slot:GetScale(); end
	if CharacterBag1Slot then MB_SaveFrame("CharacterBag1Slot", CharacterBag1Slot); mb_savedFrames["CharacterBag1Slot"].scale = CharacterBag1Slot:GetScale(); end
	if CharacterBag2Slot then MB_SaveFrame("CharacterBag2Slot", CharacterBag2Slot); mb_savedFrames["CharacterBag2Slot"].scale = CharacterBag2Slot:GetScale(); end
	if CharacterBag3Slot then MB_SaveFrame("CharacterBag3Slot", CharacterBag3Slot); mb_savedFrames["CharacterBag3Slot"].scale = CharacterBag3Slot:GetScale(); end
	if KeyRingButton     then MB_SaveFrame("KeyRingButton",     KeyRingButton);     mb_savedFrames["KeyRingButton"].scale     = KeyRingButton:GetScale();     end

	-- Textures that get Hidden
	MB_SaveTexture(MainMenuXPBarTexture1);
	MB_SaveTexture(MainMenuXPBarTexture2);
	MB_SaveTexture(MainMenuBarTexture2);
	MB_SaveTexture(MainMenuBarTexture3);
	MB_SaveTexture(MainMenuMaxLevelBar2);
	MB_SaveTexture(MainMenuMaxLevelBar3);
	MB_SaveTexture(SlidingActionBarTexture0);
	MB_SaveTexture(SlidingActionBarTexture1);
	MB_SaveTexture(ShapeshiftBarLeft);
	MB_SaveTexture(ShapeshiftBarMiddle);
	MB_SaveTexture(ShapeshiftBarRight);
	MB_SaveTexture(PossessBackground1);
	MB_SaveTexture(PossessBackground2);
	if MainMenuBarPageNumber then MB_SaveTexture(MainMenuBarPageNumber); end

	-- Textures that get SetTexture("")
	MB_SaveTexturePath(ReputationWatchBarTexture1);
	MB_SaveTexturePath(ReputationWatchBarTexture2);
	MB_SaveTexturePath(ReputationXPBarTexture1);
	MB_SaveTexturePath(ReputationXPBarTexture2);

	-- UIPARENT_MANAGED_FRAME_POSITIONS entries
	local managedKeys = { "MultiBarBottomRight", "PetActionBarFrame", "ShapeshiftBarFrame", "PossessBarFrame", "MultiCastActionBarFrame", "MAIN_MENUBAR" };
	for _, key in ipairs(managedKeys) do
		mb_savedManaged[key] = UIPARENT_MANAGED_FRAME_POSITIONS[key];
	end
end

-- ============================================================
-- MiniBar internal: MakeInvisible helper
-- ============================================================
local function MakeInvisible(frame)
	if not frame then return; end
	frame:Hide();
	frame:SetAlpha(0);
end

-- ============================================================
-- MiniBar internal: UpdateActionBars (stack bars vertically)
-- ============================================================
local function MiniBar_UpdateActionBars()
	local anchor;
	local anchorOffset = 4;
	local repOffset = 0;

	if MainMenuExpBar:IsShown() then
		repOffset = 5;
		if ReputationWatchBar:IsShown() then
			repOffset = 9;
		end
	end

	if ReputationWatchBar:IsShown() then
		repOffset = repOffset + 5;
	end

	if MultiBarBottomLeft:IsShown() then
		anchor = MultiBarBottomLeft;
		anchorOffset = 4;
	else
		anchor = ActionButton1;
		anchorOffset = 12 + repOffset;
	end

	-- Stack MultiBarBottomRight above
	if MultiBarBottomRight:IsShown() then
		MultiBarBottomRight:ClearAllPoints();
		MultiBarBottomRight:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, anchorOffset);
		anchor = MultiBarBottomRight;
		anchorOffset = 4;
	end

	-- Shapeshift buttons (presencias para DK van más a la izquierda)
	if ShapeshiftButton1 and ShapeshiftButton1:IsShown() then
		ShapeshiftButton1:ClearAllPoints();
		local shapeshiftOffsetX = (playerClass == "DEATHKNIGHT") and -10 or config.ShapeshiftBar.offsetX;
		ShapeshiftButton1:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", shapeshiftOffsetX, anchorOffset - 0.5);
	end

	-- Totem bar
	if MultiCastActionBarFrame and MultiCastActionBarFrame:IsShown() then
		MultiCastActionBarFrame:ClearAllPoints();
		MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.TotemBar.offsetX, anchorOffset - 1.5);
		anchor = MultiCastActionBarFrame;
		anchorOffset = 4;
	end

	-- Vehicle leave button
	if MainMenuBarVehicleLeaveButton and MainMenuBarVehicleLeaveButton:IsShown() then
		MainMenuBarVehicleLeaveButton:ClearAllPoints();
		MainMenuBarVehicleLeaveButton:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.LeaveButton.offsetX, anchorOffset);
		anchor = MainMenuBarVehicleLeaveButton;
		anchorOffset = 4;
	end

	-- Pet bar (para DK va más a la derecha para no tapar las presencias)
	if PetActionButton1 then
		PetActionButton1:ClearAllPoints();
		local petOffsetX = (playerClass == "DEATHKNIGHT") and 130 or config.PetBar.offsetX;
		PetActionButton1:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", petOffsetX, anchorOffset - 0.5);
	end

	-- Possess bar
	if PossessButton1 then
		PossessButton1:ClearAllPoints();
		PossessButton1:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.PossessBar.offsetX, anchorOffset - 0.5);
	end
end

-- ============================================================
-- MiniBar internal: UpdateUI (main layout refresh)
-- ============================================================
local function MiniBar_UpdateUI()
	if InCombatLockdown() then return; end
	if not minibarEnabled then return; end

	-- FIX: Check vehicle state — hide BagPackFrame and skip layout during vehicle
	local inVehicle = UnitInVehicle and UnitInVehicle("player");
	if inVehicle then
		if BagPackFrame then BagPackFrame:Hide(); end
		return;
	end

	-- FIX: Re-enforce MainMenuBar at y=0 AND width=512
	-- UIParent_ManageFramePositions and vehicle exit can reset both.
	MainMenuBar:ClearAllPoints();
	MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0);
	MainMenuBar:SetWidth(512);

	MakeInvisible(SlidingActionBarTexture0);
	MakeInvisible(SlidingActionBarTexture1);
	MakeInvisible(ShapeshiftBarLeft);
	MakeInvisible(ShapeshiftBarMiddle);
	MakeInvisible(ShapeshiftBarRight);
	MakeInvisible(PossessBackground1);
	MakeInvisible(PossessBackground2);

	MiniBar_UpdateActionBars();

	-- Apply shared scale
	K.ApplyActionBarScale(C.ActionBarScale or 1.0);
end

-- ============================================================
-- MiniBar internal: Event handler
-- ============================================================
local function MiniBar_OnEvent(self, event, unit)
	if not minibarEnabled then return; end
	if event == "ACTIONBAR_SHOWGRID" then
		gridShown = true;
	elseif event == "ACTIONBAR_HIDEGRID" then
		gridShown = false;
	elseif event == "UNIT_ENTERED_VEHICLE" and unit == "player" then
		-- FIX: Hide BagPackFrame during vehicle (Blizzard uses VehicleMenuBar)
		if BagPackFrame then BagPackFrame:Hide(); end
		-- FIX: Reparent micro buttons to UIParent during vehicle.
		-- MainMenuBar gets hidden -> MainMenuBarArtFrame hidden -> micro buttons vanish.
		for _, name in ipairs(MicroButtons) do
			local btn = _G[name];
			if btn then btn:SetParent(UIParent); end
		end
		MiniBar_UpdateUI();
	elseif event == "UNIT_EXITED_VEHICLE" and unit == "player" then
		-- FIX: Restore BagPackFrame and full layout after vehicle exit
		if BagPackFrame then BagPackFrame:Show(); end
		-- FIX: Reparent micro buttons back to UIParent (not MainMenuBarArtFrame)
		for _, name in ipairs(MicroButtons) do
			local btn = _G[name];
			if btn then
				btn:SetParent(UIParent);
				btn:SetFrameStrata("MEDIUM");
			end
		end
		if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end
		-- Re-enforce bar width (Blizzard may reset to 1024 on vehicle exit)
		MainMenuBar:SetWidth(512);
		MainMenuExpBar:SetWidth(512);
		ReputationWatchBar:SetWidth(512);
		MainMenuBarMaxLevelBar:SetWidth(512);
		ReputationWatchStatusBar:SetWidth(512);
		-- Hide right-side art (Blizzard may re-show on vehicle exit)
		MainMenuXPBarTexture1:Hide();
		MainMenuXPBarTexture2:Hide();
		MainMenuBarTexture2:Hide();
		MainMenuBarTexture3:Hide();
		MainMenuMaxLevelBar2:Hide();
		MainMenuMaxLevelBar3:Hide();
		MiniBar_UpdateUI();
		-- Delayed retry: Blizzard may reset layout after a short delay
		if not self._vehicleRetryFrame then self._vehicleRetryFrame = CreateFrame("Frame"); end
		local vrf = self._vehicleRetryFrame;
		vrf._elapsed = 0;
		vrf._count = 0;
		vrf:SetScript("OnUpdate", function(s, dt)
			s._elapsed = s._elapsed + dt;
			if s._elapsed >= 0.3 then
				s._elapsed = 0;
				s._count = s._count + 1;
				if not InCombatLockdown() and minibarEnabled then
					MainMenuBar:SetWidth(512);
					MainMenuExpBar:SetWidth(512);
					ReputationWatchBar:SetWidth(512);
					MainMenuBarMaxLevelBar:SetWidth(512);
					ReputationWatchStatusBar:SetWidth(512);
					MainMenuXPBarTexture1:Hide();
					MainMenuXPBarTexture2:Hide();
					MainMenuBarTexture2:Hide();
					MainMenuBarTexture3:Hide();
					MainMenuMaxLevelBar2:Hide();
					MainMenuMaxLevelBar3:Hide();
					MiniBar_UpdateUI();
					if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end
					if K.ApplyGryphons then K.ApplyGryphons(); end
				end
				if s._count >= 5 then s:SetScript("OnUpdate", nil); end
			end
		end);
	elseif event == "PLAYER_ENTERING_WORLD" then
		initTime = GetTime();
		self:SetScript("OnUpdate", function(s)
			if GetTime() > initTime + 5 then
				s:SetScript("OnUpdate", nil);
			end
			MiniBar_UpdateUI();
		end);
	else
		MiniBar_UpdateUI();
	end
end

-- ============================================================
-- MiniBar internal: VehicleMenuBar hook for micro buttons
-- ============================================================
local function MiniBar_VehicleMicroHook(skinName)
	if not minibarEnabled then return; end
	if not BagPackFrame then return; end

	local microBtns = {
		CharacterMicroButton, SpellbookMicroButton, TalentMicroButton,
		AchievementMicroButton, QuestLogMicroButton, SocialsMicroButton,
		PVPMicroButton, LFDMicroButton, MainMenuMicroButton, HelpMicroButton,
	};

	if not skinName then
		for _, frame in pairs(microBtns) do
			frame:SetParent(UIParent);
			frame:SetFrameStrata("MEDIUM");
			frame:Show();
		end
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("CENTER", BagPackFrame, -93.5, -11.8);
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("BOTTOMLEFT", QuestLogMicroButton, "BOTTOMRIGHT", -3, 0);
		-- UpdateMicroButtons removed: handled by hooks
	elseif skinName == "Mechanical" then
		for _, frame in pairs(microBtns) do
			frame:SetParent(VehicleMenuBarArtFrame);
			frame:Show();
		end
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("BOTTOMLEFT", VehicleMenuBar, "BOTTOMRIGHT", -340, 41);
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("TOPLEFT", CharacterMicroButton, "BOTTOMLEFT", 0, 20);
		-- UpdateMicroButtons removed: handled by hooks
	elseif skinName == "Natural" then
		for _, frame in pairs(microBtns) do
			frame:SetParent(VehicleMenuBarArtFrame);
			frame:Show();
		end
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("BOTTOMLEFT", VehicleMenuBar, "BOTTOMRIGHT", -365, 41);
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("TOPLEFT", CharacterMicroButton, "BOTTOMLEFT", 0, 20);
		-- UpdateMicroButtons removed: handled by hooks
	end
end

-- ============================================================
-- MiniBar Event Frame (always exists, but events only when enabled)
-- ============================================================
local minibarEvtFrame = CreateFrame("Frame", "NidhausMiniBarFrame", UIParent);

-- ============================================================
-- ENABLE MiniBar
-- ============================================================
function K.EnableMiniBar()
	if minibarEnabled then return; end
	if InCombatLockdown() then return; end

	-- Capturar estado original ANTES de tocar nada (pcall por si algún frame no existe)
	local ok, err = pcall(MB_CaptureOriginals);
	if not ok then
		print("|cffFF0000NUF MiniBar:|r Error capturando estado original: " .. tostring(err));
	end

	minibarEnabled = true;
	K._minibarActive = true;

	-- Hook UIParent_ManageFramePositions (once, with guard)
	if not minibarHooked then
		hooksecurefunc("UIParent_ManageFramePositions", function()
			if minibarEnabled then MiniBar_UpdateUI(); end
		end);
		hooksecurefunc("VehicleMenuBar_MoveMicroButtons", MiniBar_VehicleMicroHook);
		minibarHooked = true;
	end

	-- Remove Blizzard managed frame positions for our bars
	UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomRight"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["PetActionBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["ShapeshiftBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["PossessBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["MultiCastActionBarFrame"] = nil;

	-- Hide page number
	if MainMenuBarPageNumber then MainMenuBarPageNumber:Hide(); end

	-- Hide right-side art textures
	MainMenuXPBarTexture1:Hide();
	MainMenuXPBarTexture2:Hide();
	MainMenuBarTexture2:Hide();
	MainMenuBarTexture3:Hide();
	MainMenuMaxLevelBar2:Hide();
	MainMenuMaxLevelBar3:Hide();
	ReputationWatchBarTexture1:SetTexture("");
	ReputationWatchBarTexture2:SetTexture("");
	ReputationXPBarTexture1:SetTexture("");
	ReputationXPBarTexture2:SetTexture("");

	-- Resize bars to half width (512)
	MainMenuBar:SetWidth(512);
	-- FIX: Forzar MainMenuBar a y=0 para que no se eleve
	MainMenuBar:ClearAllPoints();
	MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0);
	MainMenuExpBar:SetWidth(512);
	MainMenuExpBar:SetHeight(12);
	ReputationWatchBar:SetWidth(512);
	MainMenuBarMaxLevelBar:SetWidth(512);
	ReputationWatchStatusBar:SetWidth(512);

	-- Reposition textures to center on new width
	MainMenuXPBarTexture0:SetPoint("BOTTOM", "MainMenuExpBar", "BOTTOM", -128, 2);
	MainMenuXPBarTexture3:SetPoint("BOTTOM", "MainMenuExpBar", "BOTTOM", 128, 2);
	ReputationWatchBarTexture3:ClearAllPoints();
	ReputationWatchBarTexture3:SetPoint("BOTTOM", "ReputationWatchBar", "BOTTOM", 128, 2);
	ReputationXPBarTexture3:ClearAllPoints();
	ReputationXPBarTexture3:SetPoint("BOTTOM", "ReputationWatchBar", "BOTTOM", 128, 1);
	MainMenuMaxLevelBar0:SetPoint("BOTTOM", "MainMenuBarMaxLevelBar", "TOP", -128, 0);
	MainMenuBarTexture0:SetPoint("BOTTOM", "MainMenuBarArtFrame", "BOTTOM", -128, 0);
	MainMenuBarTexture1:SetPoint("BOTTOM", "MainMenuBarArtFrame", "BOTTOM", 128, 0);
	-- Gryphon positioning handled by K.ApplyGryphons()

	if PetActionBarFrame then
		PetActionBarFrame:SetAttribute("unit", "pet");
	end

	-- Fix blizzard misaligned positions
	if BonusActionButton1 then
		BonusActionButton1:ClearAllPoints();
		BonusActionButton1:SetPoint("BOTTOMLEFT", BonusActionBarFrame, "BOTTOMLEFT", 4, 4);
	end

	if ActionBarUpButton then
		ActionBarUpButton:SetPoint("CENTER", MainMenuBarArtFrame, "BOTTOMLEFT", 521, 30.2);
	end
	if ActionBarDownButton then
		ActionBarDownButton:SetPoint("CENTER", MainMenuBarArtFrame, "BOTTOMLEFT", 521, 11.1);
	end
	if MainMenuBarPageNumber then
		MainMenuBarPageNumber:ClearAllPoints();
		MainMenuBarPageNumber:SetPoint("CENTER", MainMenuBarArtFrame, "BOTTOMLEFT", 541, 21);
	end

	-- Create BagPackFrame and apply layout
	K.CreateBagPackFrame();
	K.ApplyBagPackLayout();

	-- Apply gryphons
	K.ApplyGryphons();

	-- Register events
	minibarEvtFrame:RegisterEvent("ACTIONBAR_SHOWGRID");
	minibarEvtFrame:RegisterEvent("ACTIONBAR_HIDEGRID");
	minibarEvtFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
	minibarEvtFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
	minibarEvtFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
	minibarEvtFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	-- FIX: Escuchar eventos de XP/Rep para re-enforzar posición de MainMenuBar
	minibarEvtFrame:RegisterEvent("PLAYER_XP_UPDATE");
	minibarEvtFrame:RegisterEvent("UPDATE_EXHAUSTION");
	minibarEvtFrame:RegisterEvent("PLAYER_LEVEL_UP");
	minibarEvtFrame:RegisterEvent("UPDATE_FACTION");
	minibarEvtFrame:SetScript("OnEvent", MiniBar_OnEvent);

	-- Initial layout
	MiniBar_UpdateUI();
end

-- ============================================================
-- DISABLE MiniBar (requires /reload for full restore)
-- ============================================================
function K.DisableMiniBar()
	if not minibarEnabled then return; end
	if InCombatLockdown() then return; end
	minibarEnabled = false;
	K._minibarActive = false;

	-- Unregister events
	minibarEvtFrame:UnregisterAllEvents();
	minibarEvtFrame:SetScript("OnEvent", nil);
	minibarEvtFrame:SetScript("OnUpdate", nil);

	-- Hide BagPackFrame
	if BagPackFrame then BagPackFrame:Hide(); end

	-- Restaurar UIPARENT_MANAGED_FRAME_POSITIONS
	for key, val in pairs(mb_savedManaged) do
		UIPARENT_MANAGED_FRAME_POSITIONS[key] = val;
	end

	-- Restaurar texturas (visibility + alpha + texture paths)
	MB_RestoreAllTextures();

	-- Restaurar posiciones y tamaños de frames
	MB_RestoreFrame("MainMenuBar",              MainMenuBar);
	MB_RestoreFrame("MainMenuExpBar",           MainMenuExpBar);
	MB_RestoreFrame("ReputationWatchBar",       ReputationWatchBar);
	MB_RestoreFrame("MainMenuBarMaxLevelBar",   MainMenuBarMaxLevelBar);
	MB_RestoreFrame("ReputationWatchStatusBar", ReputationWatchStatusBar);
	-- FIX: Restaurar textos de rep y exp
	if ReputationWatchStatusBarText then MB_RestoreFrame("ReputationWatchStatusBarText", ReputationWatchStatusBarText); end
	if MainMenuBarExpText then MB_RestoreFrame("MainMenuBarExpText", MainMenuBarExpText); end
	if ExhaustionTick then MB_RestoreFrame("ExhaustionTick", ExhaustionTick); end
	MB_RestoreFrame("MainMenuXPBarTexture0",    MainMenuXPBarTexture0);
	MB_RestoreFrame("MainMenuXPBarTexture3",    MainMenuXPBarTexture3);
	MB_RestoreFrame("ReputationWatchBarTexture3", ReputationWatchBarTexture3);
	MB_RestoreFrame("ReputationXPBarTexture3",  ReputationXPBarTexture3);
	MB_RestoreFrame("MainMenuMaxLevelBar0",     MainMenuMaxLevelBar0);
	MB_RestoreFrame("MainMenuBarTexture0",      MainMenuBarTexture0);
	MB_RestoreFrame("MainMenuBarTexture1",      MainMenuBarTexture1);
	if ActionBarUpButton       then MB_RestoreFrame("ActionBarUpButton",       ActionBarUpButton);       end
	if ActionBarDownButton     then MB_RestoreFrame("ActionBarDownButton",     ActionBarDownButton);     end
	if MainMenuBarPageNumber   then MB_RestoreFrame("MainMenuBarPageNumber",   MainMenuBarPageNumber);   end
	if BonusActionButton1      then MB_RestoreFrame("BonusActionButton1",      BonusActionButton1);      end
	if MultiBarBottomRight     then MB_RestoreFrame("MultiBarBottomRight",     MultiBarBottomRight);     end
	if ShapeshiftButton1       then MB_RestoreFrame("ShapeshiftButton1",       ShapeshiftButton1);       end
	if MultiCastActionBarFrame       then MB_RestoreFrame("MultiCastActionBarFrame",       MultiCastActionBarFrame);       end
	if MainMenuBarVehicleLeaveButton then MB_RestoreFrame("MainMenuBarVehicleLeaveButton", MainMenuBarVehicleLeaveButton); end
	if PetActionButton1 then MB_RestoreFrame("PetActionButton1", PetActionButton1); end
	if PossessButton1   then MB_RestoreFrame("PossessButton1",   PossessButton1);   end

	-- Micro buttons: restaurar parent Y posición
	local microNames = {
		"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
		"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
		"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
	};
	for _, name in ipairs(microNames) do
		local f = _G[name];
		if f then
			local s = mb_savedFrames[name];
			if s and s.parent then f:SetParent(s.parent); end
			-- FIX: Always reset scale to 1.0 BEFORE MB_RestoreFrame.
			-- ApplyBagPackLayout set explicit scale to ActionBarScale.
			-- Now buttons inherit scale from parent chain (MainMenuBarArtFrame → MainMenuBar).
			f:SetScale(1);
			MB_RestoreFrame(name, f);
		end
	end

	-- Bag slots: restaurar posición y escala
	MB_RestoreFrame("MainMenuBarBackpackButton", MainMenuBarBackpackButton);
	local bagSlots = { "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot", "KeyRingButton" };
	for _, name in ipairs(bagSlots) do
		local f = _G[name];
		if f then
			MB_RestoreFrame(name, f);
			local s = mb_savedFrames[name];
			if s and s.scale then f:SetScale(s.scale); else f:SetScale(1.0); end
		end
	end

	-- Forzar recalculo de Blizzard
	if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	if ShapeshiftBar_Update          then pcall(ShapeshiftBar_Update);          end
	if PetActionBar_Update           then pcall(PetActionBar_Update);           end
	if UpdateMicroButtons            then pcall(UpdateMicroButtons);            end

	-- FIX: Retry para que Blizzard re-posicione correctamente
	-- (Blizzard puede pisar nuestras posiciones restauradas async)
	local mbRestoreRetry = 0;
	local mbRestoreFrame = CreateFrame("Frame");
	mbRestoreFrame:SetScript("OnUpdate", function(self, dt)
		mbRestoreRetry = mbRestoreRetry + dt;
		if mbRestoreRetry >= 0.3 then
			self:SetScript("OnUpdate", nil);
			if not minibarEnabled and not InCombatLockdown() then
				if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
				if UpdateMicroButtons then pcall(UpdateMicroButtons); end
			end
		end
	end);

	-- Restore gryphons to Blizzard default (ApplyGryphons won't touch them with no mode active)
	-- FIX: Usar MB_RestoreFrame en vez de coordenadas hardcodeadas
	MB_RestoreFrame("MainMenuBarLeftEndCap",  MainMenuBarLeftEndCap);
	MB_RestoreFrame("MainMenuBarRightEndCap", MainMenuBarRightEndCap);
	if MainMenuBarLeftEndCap then
		MainMenuBarLeftEndCap:SetAlpha(1);
		MainMenuBarLeftEndCap:Show();
	end
	if MainMenuBarRightEndCap then
		MainMenuBarRightEndCap:SetAlpha(1);
		MainMenuBarRightEndCap:Show();
	end

	-- Limpiar estado guardado
	mb_savedFrames   = {};
	mb_savedTextures = {};
	mb_savedTexPaths = {};
	mb_savedManaged  = {};

	-- Re-apply action bar scale (scale works independently of bar modes)
	if C.ActionBarScale and C.ActionBarScale ~= 1.0 then
		K.ApplyActionBarScale(C.ActionBarScale);
	end
end

-- ============================================================
-- Init: enable at login if configured
-- ============================================================
local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");

	-- ONLY enable MiniBar if configured (mutually exclusive with Unify)
	-- If nothing is configured, DO NOT TOUCH any Blizzard bars (except scale)
	if C.MiniBarEnabled and not C.UnifyActionBars then
		K.EnableMiniBar();
	end

	-- Scale works regardless of mode — it's safe and doesn't break layout
	if C.ActionBarScale and C.ActionBarScale ~= 1.0 then
		K.ApplyActionBarScale(C.ActionBarScale);
	end
end);