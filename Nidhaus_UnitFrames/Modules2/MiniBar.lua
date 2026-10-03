




local AddOnName, ns = ...;
local K, C, L = unpack(ns);




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


local mb_savedFrames    = {};
local mb_savedTextures  = {};
local mb_savedTexPaths  = {};
local mb_savedManaged   = {};




local BAGPACK_TEXTURE = "Interface\\AddOns\\"..AddOnName.."\\Modules2\\Textures\\bagpack";




function K.CreateBagPackFrame()
	if BagPackFrame then

		BagPackFrame:Show();
		if BagPackFrame.texture then
			if C.ShowBagPackTexture == false then BagPackFrame.texture:Hide(); else BagPackFrame.texture:Show(); end
		end


		local scale = C.MiniBarExtrasScale;
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


	BagPackFrame:Show();
	if C.ShowBagPackTexture == false then
		BagPackFrame.texture:Hide();
	else
		BagPackFrame.texture:Show();
	end


	local scale = C.MiniBarExtrasScale;
	if type(scale) == "number" and scale > 0 then
		BagPackFrame:SetScale(scale);
	end

	return BagPackFrame;
end




local MicroButtons = {
	"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
	"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
};

function K.ApplyBagPackLayout()
	if not BagPackFrame then return; end
	if InCombatLockdown() then return; end
	if K._applyingBagPack then return; end
	K._applyingBagPack = true;











	local abScale = C.MiniBarExtrasScale;
	if type(abScale) ~= "number" or abScale <= 0 then abScale = 1.0; end


	local microLevel = ((MainMenuBar and MainMenuBar:GetFrameLevel()) or 0) + 5;
	for _, name in ipairs(MicroButtons) do
		local btn = _G[name];
		if btn then
			btn:SetParent(UIParent);
			btn:SetFrameStrata("MEDIUM");


			btn:SetFrameLevel(microLevel);
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














	for _, n in ipairs({ "MainMenuBarBackpackButton", "CharacterBag0Slot",
	                     "CharacterBag1Slot", "CharacterBag2Slot",
	                     "CharacterBag3Slot", "KeyRingButton" }) do
		local b = _G[n];
		if b then
			b:SetParent(BagPackFrame);
			b:SetFrameStrata("MEDIUM");
		end
	end

	MainMenuBarBackpackButton:SetScale(abScale);
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











local MINIBAR_GRYPHON_LEFT_X  = -30;
local MINIBAR_GRYPHON_RIGHT_X =  35;




local UNIFY_GRYPHON_LEFT_X    = -30;



local UNIFY_GRYPHON_RIGHT_X   = 286;
local UNIFY_GRYPHON_Y_BASE    =  -5;
local UNIFY_GRYPHON_Y_PER_BAR =   5;

function K.ApplyGryphons()
	if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then return; end





	local anyBarMode = K._unifyActive or K._minibarActive;

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

		if not anyBarMode then

		elseif K._unifyActive then
			local yOff = UNIFY_GRYPHON_Y_BASE;
			if MainMenuExpBar and MainMenuExpBar:IsShown() then
				yOff = yOff + UNIFY_GRYPHON_Y_PER_BAR;
			end
			if ReputationWatchBar and ReputationWatchBar:IsShown() then
				yOff = yOff + UNIFY_GRYPHON_Y_PER_BAR;
			end
			MainMenuBarLeftEndCap:ClearAllPoints();
			MainMenuBarRightEndCap:ClearAllPoints();
			MainMenuBarLeftEndCap:SetPoint("BOTTOM", MainMenuBar, "BOTTOMLEFT", UNIFY_GRYPHON_LEFT_X, yOff);
			MainMenuBarRightEndCap:SetPoint("BOTTOM", MainMenuBar, "BOTTOMRIGHT", UNIFY_GRYPHON_RIGHT_X, yOff);
		elseif K._minibarActive then





			local gAnchor = _G["MainMenuBarArtFrame"] or MainMenuBar;
			pcall(MainMenuBarLeftEndCap.SetParent,  MainMenuBarLeftEndCap,  gAnchor);
			pcall(MainMenuBarRightEndCap.SetParent, MainMenuBarRightEndCap, gAnchor);
			MainMenuBarLeftEndCap:ClearAllPoints();
			MainMenuBarRightEndCap:ClearAllPoints();
			MainMenuBarLeftEndCap:SetPoint("BOTTOM", gAnchor, "BOTTOMLEFT", MINIBAR_GRYPHON_LEFT_X, 0);
			MainMenuBarRightEndCap:SetPoint("BOTTOM", gAnchor, "BOTTOMRIGHT", MINIBAR_GRYPHON_RIGHT_X, 0);
		end
	end
end




function K.ApplyActionBarScale(scale)
	if InCombatLockdown() then return; end
	if type(scale) ~= "number" or scale <= 0 then scale = 1.0; end














	if C.MiniBarEnabled == true then
		K.ApplyBarHolderScales(scale);
		if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end
		return;
	end


	if MainMenuBar then MainMenuBar:SetScale(scale); end
	if VehicleMenuBar then VehicleMenuBar:SetScale(scale); end
	if MultiBarBottomRight then MultiBarBottomRight:SetScale(scale); end
	if MultiBarBottomLeft then MultiBarBottomLeft:SetScale(scale); end
	if MultiBarRight then MultiBarRight:SetScale(scale); end
	if MultiBarLeft then MultiBarLeft:SetScale(scale); end

	if BagPackFrame and (K._minibarActive or K._unifyActive) then BagPackFrame:SetScale(scale); end


	if (K._minibarActive or K._unifyActive) and K.ApplyBagPackLayout then
		K.ApplyBagPackLayout();
	end
end




function K.ApplyBagPackTexture()
	if not BagPackFrame or not BagPackFrame.texture then return; end
	if C.ShowBagPackTexture then
		BagPackFrame.texture:Show();
	else
		BagPackFrame.texture:Hide();
	end
end


function K.IsAnyBarModeActive()
	return (K._minibarActive == true) or (K._unifyActive == true);
end




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

		scale    = frame.GetScale  and frame:GetScale()  or nil,





		parent   = frame.GetParent and frame:GetParent() or nil,
	};

	if frame.GetFont then
		local f, s, fl = frame:GetFont();
		if f then mb_savedFrames[name].font = {f, s, fl}; end
	end
end

local function MB_RestoreFrame(name, frame)
	if not frame then return; end
	local s = mb_savedFrames[name];
	if not s then return; end

	if s.parent and frame.SetParent and frame:GetParent() ~= s.parent then
		pcall(frame.SetParent, frame, s.parent);
	end
	frame:ClearAllPoints();
	if s.point then
		frame:SetPoint(s.point, s.rel, s.relPoint, s.x, s.y);
	end
	if s.width  and s.width  > 0 then frame:SetWidth(s.width);   end
	if s.height and s.height > 0 then frame:SetHeight(s.height); end

	if s.scale and frame.SetScale then frame:SetScale(s.scale); end

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


	MB_SaveFrame("MainMenuBar",              MainMenuBar);





	MB_SaveFrame("MainMenuExpBar",           MainMenuExpBar);
	MB_SaveFrame("ReputationWatchBar",       ReputationWatchBar);
	MB_SaveFrame("MainMenuBarMaxLevelBar",   MainMenuBarMaxLevelBar);
	MB_SaveFrame("ReputationWatchStatusBar", ReputationWatchStatusBar);

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


	if MainMenuBarLeftEndCap  then MB_SaveFrame("MainMenuBarLeftEndCap",  MainMenuBarLeftEndCap);  end
	if MainMenuBarRightEndCap then MB_SaveFrame("MainMenuBarRightEndCap", MainMenuBarRightEndCap); end


	local microNames = {
		"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
		"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
		"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
	};
	for _, name in ipairs(microNames) do
		local f = _G[name];
		if f then
			MB_SaveFrame(name, f);

			if not mb_savedFrames[name] then mb_savedFrames[name] = {}; end
			mb_savedFrames[name].parent = f:GetParent();
		end
	end


	MB_SaveFrame("MainMenuBarBackpackButton", MainMenuBarBackpackButton);
	if CharacterBag0Slot then MB_SaveFrame("CharacterBag0Slot", CharacterBag0Slot); mb_savedFrames["CharacterBag0Slot"].scale = CharacterBag0Slot:GetScale(); end
	if CharacterBag1Slot then MB_SaveFrame("CharacterBag1Slot", CharacterBag1Slot); mb_savedFrames["CharacterBag1Slot"].scale = CharacterBag1Slot:GetScale(); end
	if CharacterBag2Slot then MB_SaveFrame("CharacterBag2Slot", CharacterBag2Slot); mb_savedFrames["CharacterBag2Slot"].scale = CharacterBag2Slot:GetScale(); end
	if CharacterBag3Slot then MB_SaveFrame("CharacterBag3Slot", CharacterBag3Slot); mb_savedFrames["CharacterBag3Slot"].scale = CharacterBag3Slot:GetScale(); end
	if KeyRingButton     then MB_SaveFrame("KeyRingButton",     KeyRingButton);     mb_savedFrames["KeyRingButton"].scale     = KeyRingButton:GetScale();     end


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


	MB_SaveTexturePath(ReputationWatchBarTexture1);
	MB_SaveTexturePath(ReputationWatchBarTexture2);
	MB_SaveTexturePath(ReputationXPBarTexture1);
	MB_SaveTexturePath(ReputationXPBarTexture2);


	local managedKeys = { "MultiBarBottomRight", "PetActionBarFrame", "ShapeshiftBarFrame", "PossessBarFrame", "MultiCastActionBarFrame", "MAIN_MENUBAR" };
	for _, key in ipairs(managedKeys) do
		mb_savedManaged[key] = UIPARENT_MANAGED_FRAME_POSITIONS[key];
	end
end











local bgTextures;











function K.InvalidateMiniBarBackgroundCache()
	bgTextures = nil;
end

local function MiniBar_BackgroundTextures()
	if bgTextures then return bgTextures; end
	bgTextures = {};
	local function add(tex)
		if tex and tex.SetAlpha then









			table.insert(bgTextures, {
				tex   = tex,
				alpha = tex:GetAlpha(),
				shown = tex:IsShown(),
			});
		end
	end











	local function addFrameTextures(frame)
		if not frame or not frame.GetRegions then return; end
		for _, reg in ipairs({ frame:GetRegions() }) do
			if reg and reg.GetObjectType and reg:GetObjectType() == "Texture" then
				add(reg);
			end
		end
	end

	for i = 0, 3 do add(_G["MainMenuBarTexture" .. i]); end
	add(MainMenuXPBarTextureLeftCap);
	add(MainMenuXPBarTextureRightCap);
	add(MainMenuXPBarTextureMid);
	for i = 0, 8 do add(_G["ReputationWatchBarTexture" .. i]); end
	addFrameTextures(MainMenuBarMaxLevelBar);
	return bgTextures;
end

function K.ApplyMiniBarBackground()



	if C.MiniBarEnabled ~= true then return; end

	local ocultar = (C.MiniBarHideBackground == true);
	for _, e in ipairs(MiniBar_BackgroundTextures()) do
		if ocultar then
			e.tex:Hide();
			e.tex:SetAlpha(0);
		else

			e.tex:SetAlpha(e.alpha);
			if e.shown then e.tex:Show(); else e.tex:Hide(); end
		end
	end
end




local function MakeInvisible(frame)
	if not frame then return; end
	frame:Hide();
	frame:SetAlpha(0);
end















local function RowGap()
	local v = tonumber(C.ActionBarButtonSpace);
	if not v or v < 0 then v = 6; end
	return v;
end




local MiniBar_UpdateActionBars;

function K.RefreshMiniBarLayout(force)
	if C.MiniBarEnabled ~= true then return; end
	if InCombatLockdown() then return; end
	if MiniBar_UpdateActionBars then MiniBar_UpdateActionBars(force); end
end




local MB_STACK = {
	{ frame = "NUF_ActionBarHolder1",         key = "MainBar"     },
	{ frame = "NUF_ActionBarHolder2",         key = "ActionBar2"  },
	{ frame = "NUF_ActionBarHolder3",         key = "ActionBar3"  },
	{ frame = "NUF_StanceBarHolder",          key = "StanceBar"   },
	{ frame = "MultiCastActionBarFrame",      key = "TotemBar"    },
	{ frame = "MainMenuBarVehicleLeaveButton" },
	{ frame = "PetActionButton1",             key = "PetBar"      },
	{ frame = "PossessButton1",               key = "PossessBar"  },
};

























local function MB_ToUIParent(frame)
	local l, b = frame:GetLeft(), frame:GetBottom();
	if not l or not b then return nil; end























	return l, b;
end







local function MB_ScreenPos(frame)
	local l, b = frame:GetLeft(), frame:GetBottom();
	if not l or not b then return nil; end
	local s = frame:GetEffectiveScale() or 1;
	return l * s, b * s, (frame:GetHeight() or 30) * s;
end




local function MB_PlaceAtScreen(frame, sx, sy)
	local s = frame:GetEffectiveScale() or 1;
	if s == 0 then return; end
	frame:ClearAllPoints();
	frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", sx / s, sy / s);
end

function K.MiniBarDetachStack()
	if not minibarEnabled then return; end

	if InCombatLockdown() then return; end

	for _, item in ipairs(MB_STACK) do
		local f = _G[item.frame];
		if f and f:IsShown() then
			local x, y = MB_ToUIParent(f);
			if x then
				f:ClearAllPoints();
				f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y);
			end
		end
	end
end























local BAR_KEYS = { "MainBar", "ActionBar2", "ActionBar3" };



































local artOrig = nil;

local function MB_SaveArt(art)
	if artOrig or not art then return; end
	local pts = {};
	for i = 1, (art:GetNumPoints() or 0) do
		local p, rel, rp, x, y = art:GetPoint(i);
		if p then pts[#pts + 1] = { p, rel, rp, x or 0, y or 0 }; end
	end
	artOrig = {
		parent = art:GetParent(),
		points = pts,
		width  = art:GetWidth(),
	};
end

function K.RestoreArtFrame()
	local art = _G["MainMenuBarArtFrame"];
	if not art or not artOrig then return; end
	if InCombatLockdown() then return; end

	if artOrig.parent and art:GetParent() ~= artOrig.parent then
		pcall(art.SetParent, art, artOrig.parent);
	end

	art:ClearAllPoints();
	for _, p in ipairs(artOrig.points) do
		pcall(art.SetPoint, art, p[1], p[2], p[3], p[4], p[5]);
	end



	if #artOrig.points < 2 and artOrig.width and artOrig.width > 0 then
		art:SetWidth(artOrig.width);
	end

	artOrig = nil;
end

function K.PinMainMenuBarToRow1()
	if C.MiniBarEnabled ~= true then return; end



	if MainMenuBar then MainMenuBar.ignoreFramePositionManager = true; end


	if InCombatLockdown() then return; end

	local h1  = K.GetBarHolder and K.GetBarHolder(1);
	local art = _G["MainMenuBarArtFrame"];
	if not h1 or not art then return; end






















	if art:GetParent() ~= h1 then

		MB_SaveArt(art);
		art:SetParent(h1);
		art:SetFrameStrata("MEDIUM");


		art:SetFrameLevel(math.max(0, (h1:GetFrameLevel() or 1) - 1));
	end
























	local ix, iy = 0, 0;
	if K.BarHolderInset then ix, iy = K.BarHolderInset(1); end

	art:ClearAllPoints();
	art:SetPoint("BOTTOMLEFT", h1, "BOTTOMLEFT", -ix, -iy);


















	MainMenuBar:ClearAllPoints();
	MainMenuBar:SetPoint("BOTTOMLEFT", h1, "BOTTOMLEFT", -ix, -iy);




	if art.SetWidth and (art:GetWidth() or 0) ~= 512 then art:SetWidth(512); end
end















local mbScalePending = false;

function K.ApplyBarHolderScales(scale)
















	if InCombatLockdown() then mbScalePending = true; return; end
	if type(scale) ~= "number" or scale <= 0 then scale = 1.0; end

	local firstScale = scale;
	for row = 1, 3 do
		local h = K.GetBarHolder and K.GetBarHolder(row);
		if h then
			local own = K.GetGlobalScale and K.GetGlobalScale(BAR_KEYS[row]);
			local use = (type(own) == "number" and own > 0) and own or scale;
			h:SetScale(use);
			if row == 1 then firstScale = use; end
		end
	end

	if not MainMenuBar then return; end




	MainMenuBar:SetScale(firstScale);


	K.PinMainMenuBarToRow1();
end

function K.ResetMiniBarLayout()
	if C.MiniBarEnabled ~= true then return; end
	if InCombatLockdown() then return; end

	local scale = (K.GetConfigDefault and K.GetConfigDefault("ActionBarScale")) or 1.0;

	for row = 1, 3 do
		local h = K.GetBarHolder and K.GetBarHolder(row);
		if h then
			h:SetScale(scale);
			h:ClearAllPoints();
		end
	end

	if MainMenuBar then MainMenuBar:SetScale(scale); end




	for _, item in ipairs(MB_STACK) do
		local f = _G[item.frame];
		if f then
			f:SetScale(scale);
			f:ClearAllPoints();
		end
	end



	MiniBar_UpdateActionBars(true);




	K.PinMainMenuBarToRow1();
end

function K.MiniBarStackKeys()
	local out = {};
	for _, item in ipairs(MB_STACK) do
		if item.key then out[#out + 1] = item.key; end
	end
	return out;
end

function MiniBar_UpdateActionBars(force)











	if (not force) and K.IsGlobalUnlocked and K.IsGlobalUnlocked() then return; end









	if K.AttachStanceButtons then K.AttachStanceButtons(); end




	if K.AttachActionBarButtons then K.AttachActionBarButtons(); end




	if K.ApplyBarHolderScales then
		K.ApplyBarHolderScales(C.ActionBarScale or 1.0);
	end

	local anchor;
	local anchorOffset = RowGap();
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
















	local h1 = K.GetBarHolder and K.GetBarHolder(1);
	local h2 = K.GetBarHolder and K.GetBarHolder(2);
	local h3 = K.GetBarHolder and K.GetBarHolder(3);

	if h1 and not (K.HasGlobalPos and K.HasGlobalPos("MainBar")) then
		if K.BarHolderDefaultPoint then K.BarHolderDefaultPoint(1); end
	end














	anchor = h1 or ActionButton1;
	anchorOffset = RowGap() + 6 + repOffset;






















	local baseX, sy, sh = MB_ScreenPos(anchor);
	local gapScale = (UIParent:GetEffectiveScale() or 1);

	if h2 and MultiBarBottomLeft:IsShown()
	   and not (K.HasGlobalPos and K.HasGlobalPos("ActionBar2")) then
		if baseX then
			MB_PlaceAtScreen(h2, baseX, sy + sh + (anchorOffset * gapScale));
			local _, y2, h2h = MB_ScreenPos(h2);
			sy, sh = y2 or sy, h2h or sh;
			anchorOffset = RowGap();
		end
		anchor = h2;
	end

	if h3 and MultiBarBottomRight:IsShown()
	   and not (K.HasGlobalPos and K.HasGlobalPos("ActionBar3")) then
		if baseX then
			MB_PlaceAtScreen(h3, baseX, sy + sh + (anchorOffset * gapScale));
			local _, y3, h3h = MB_ScreenPos(h3);
			sy, sh = y3 or sy, h3h or sh;
			anchorOffset = RowGap();
		end
		anchor = h3;
	end







	local stanceHolder = _G["NUF_StanceBarHolder"];
	local stanceTarget = stanceHolder or ShapeshiftButton1;
	if stanceTarget and ShapeshiftButton1 and ShapeshiftButton1:IsShown()
	   and not (K.HasGlobalPos and K.HasGlobalPos("StanceBar")) then
		stanceTarget:ClearAllPoints();
		local shapeshiftOffsetX = (playerClass == "DEATHKNIGHT") and -10 or config.ShapeshiftBar.offsetX;


		local nebShift = (K.NEBClassBarShift and K.NEBClassBarShift()) or 0;
		stanceTarget:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", shapeshiftOffsetX, anchorOffset - 0.5 + nebShift);
	end


	if MultiCastActionBarFrame and MultiCastActionBarFrame:IsShown()
	   and not (K.HasGlobalPos and K.HasGlobalPos("TotemBar")) then
		MultiCastActionBarFrame:ClearAllPoints();
		MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.TotemBar.offsetX, anchorOffset - 1.5);
		anchor = MultiCastActionBarFrame;
		anchorOffset = RowGap();
	end


	if MainMenuBarVehicleLeaveButton and MainMenuBarVehicleLeaveButton:IsShown() then
		MainMenuBarVehicleLeaveButton:ClearAllPoints();
		MainMenuBarVehicleLeaveButton:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.LeaveButton.offsetX, anchorOffset);
		anchor = MainMenuBarVehicleLeaveButton;
		anchorOffset = 4;
	end






	if PetActionButton1 then
		PetActionButton1:ClearAllPoints();
		if K.HasGlobalPos and K.HasGlobalPos("PetBar") and PetActionBarFrame then
			PetActionButton1:SetPoint("BOTTOMLEFT", PetActionBarFrame, "BOTTOMLEFT", 0, 0);
		else
			local petOffsetX = (playerClass == "DEATHKNIGHT") and 130 or config.PetBar.offsetX;
			PetActionButton1:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", petOffsetX, anchorOffset - 0.5);
		end
	end


	if PossessButton1 then
		PossessButton1:ClearAllPoints();
		if K.HasGlobalPos and K.HasGlobalPos("PossessBar") and PossessBarFrame then
			PossessButton1:SetPoint("BOTTOMLEFT", PossessBarFrame, "BOTTOMLEFT", 0, 0);
		else
			PossessButton1:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", config.PossessBar.offsetX,
				anchorOffset - 0.5 + ((K.NEBClassBarShift and K.NEBClassBarShift()) or 0));
		end
	end
end




local function MiniBar_UpdateUI()
	if InCombatLockdown() then return; end
	if not minibarEnabled then return; end


	local inVehicle = UnitInVehicle and UnitInVehicle("player");
	if inVehicle then
		if BagPackFrame then BagPackFrame:Hide(); end
		return;
	end




















	MainMenuBar:SetWidth(512);

	MakeInvisible(SlidingActionBarTexture0);
	MakeInvisible(SlidingActionBarTexture1);
	MakeInvisible(ShapeshiftBarLeft);
	MakeInvisible(ShapeshiftBarMiddle);
	MakeInvisible(ShapeshiftBarRight);
	MakeInvisible(PossessBackground1);
	MakeInvisible(PossessBackground2);

	MiniBar_UpdateActionBars();


	if K.ApplyMiniBarBackground then K.ApplyMiniBarBackground(); end


	K.ApplyActionBarScale(C.ActionBarScale or 1.0);
end




local function MiniBar_OnEvent(self, event, unit)
	if not minibarEnabled then return; end
	if event == "ACTIONBAR_SHOWGRID" then
		gridShown = true;
	elseif event == "ACTIONBAR_HIDEGRID" then
		gridShown = false;
	elseif event == "UNIT_ENTERED_VEHICLE" and unit == "player" then

		if BagPackFrame then BagPackFrame:Hide(); end




		if K.MiniBarPlaceVehicleMicro then K.MiniBarPlaceVehicleMicro(); end
		MiniBar_UpdateUI();
	elseif event == "UNIT_EXITED_VEHICLE" and unit == "player" then

		if BagPackFrame then BagPackFrame:Show(); end








		local microLevel = ((MainMenuBar and MainMenuBar:GetFrameLevel()) or 0) + 5;
		for _, name in ipairs(MicroButtons) do
			local btn = _G[name];
			if btn then
				btn:SetParent(UIParent);
				btn:SetFrameStrata("MEDIUM");
				btn:SetFrameLevel(microLevel);
			end
		end
		if K.ApplyBagPackLayout then K.ApplyBagPackLayout(); end

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






























function K.MiniBarPlaceVehicleMicro()
	local art = _G["VehicleMenuBarArtFrame"];
	for _, name in ipairs(MicroButtons) do
		local btn = _G[name];
		if btn then
			if art then
				btn:SetParent(art);
				btn:SetFrameStrata(art:GetFrameStrata() or "MEDIUM");
				btn:SetFrameLevel((art:GetFrameLevel() or 0) + 5);
			else


				btn:SetParent(UIParent);
				btn:SetFrameStrata("HIGH");
			end
			btn:Show();
		end
	end
end

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

	elseif skinName == "Mechanical" then

		K.MiniBarPlaceVehicleMicro();
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("BOTTOMLEFT", VehicleMenuBar, "BOTTOMRIGHT", -340, 41);
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("TOPLEFT", CharacterMicroButton, "BOTTOMLEFT", 0, 20);

	elseif skinName == "Natural" then

		K.MiniBarPlaceVehicleMicro();
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("BOTTOMLEFT", VehicleMenuBar, "BOTTOMRIGHT", -365, 41);
		SocialsMicroButton:ClearAllPoints();
		SocialsMicroButton:SetPoint("TOPLEFT", CharacterMicroButton, "BOTTOMLEFT", 0, 20);

	end
end




local minibarEvtFrame = CreateFrame("Frame", "NidhausMiniBarFrame", UIParent);















function K.MiniBarMarkOff()
	minibarEnabled   = false;
	K._minibarActive = false;
end

function K.EnableMiniBar()




	if K.CaptureAllActionButtons then K.CaptureAllActionButtons(); end

	if minibarEnabled then return; end
	if InCombatLockdown() then return; end



	if K._unifyActive and K.DisableUnifyActionBars then
		K.DisableUnifyActionBars();
	end



	if K.EnsureBarBaseline then K.EnsureBarBaseline(); end

	if K.RestoreBarBaseline then K.RestoreBarBaseline(); end









	if K._habRelease then K._habRelease(); end
	if K.InvalidateMiniBarBackgroundCache then K.InvalidateMiniBarBackgroundCache(); end


	local ok, err = pcall(MB_CaptureOriginals);
	if not ok then
		print("|cffFF0000NUF MiniBar:|r " .. (L["MINIBAR_CAPTURE_ERR"] or "Error capturing the original state:") .. " " .. tostring(err));
	end

	minibarEnabled = true;
	K._minibarActive = true;

	if K._habReapply then K._habReapply(); end


	if not minibarHooked then
		hooksecurefunc("UIParent_ManageFramePositions", function()
			if not minibarEnabled then return; end
			MiniBar_UpdateUI();





			if K.PinMainMenuBarToRow1 then K.PinMainMenuBarToRow1(); end
		end);
		hooksecurefunc("VehicleMenuBar_MoveMicroButtons", MiniBar_VehicleMicroHook);






		if MainMenuBar_UpdateExperienceBars then
			hooksecurefunc("MainMenuBar_UpdateExperienceBars", function()
				if minibarEnabled and not InCombatLockdown() then
					if UnitInVehicle and UnitInVehicle("player") then return; end
					MiniBar_UpdateUI();
				end
			end);
		end
		minibarHooked = true;
	end


	UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomRight"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["PetActionBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["ShapeshiftBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["PossessBarFrame"] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS["MultiCastActionBarFrame"] = nil;


	if MainMenuBarPageNumber then MainMenuBarPageNumber:Hide(); end


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


	MainMenuBar:SetWidth(512);


	if MainMenuBarArtFrame then MainMenuBarArtFrame:SetWidth(512); end















	K.PinMainMenuBarToRow1();
	MainMenuExpBar:SetWidth(512);
	MainMenuExpBar:SetHeight(12);
	ReputationWatchBar:SetWidth(512);
	MainMenuBarMaxLevelBar:SetWidth(512);
	ReputationWatchStatusBar:SetWidth(512);


	MainMenuXPBarTexture0:SetPoint("BOTTOM", "MainMenuExpBar", "BOTTOM", -128, 2);
	MainMenuXPBarTexture3:SetPoint("BOTTOM", "MainMenuExpBar", "BOTTOM", 128, 2);
	ReputationWatchBarTexture3:ClearAllPoints();
	ReputationWatchBarTexture3:SetPoint("BOTTOM", "ReputationWatchBar", "BOTTOM", 128, 2);
	ReputationXPBarTexture3:ClearAllPoints();
	ReputationXPBarTexture3:SetPoint("BOTTOM", "ReputationWatchBar", "BOTTOM", 128, 1);
	MainMenuMaxLevelBar0:SetPoint("BOTTOM", "MainMenuBarMaxLevelBar", "TOP", -128, 0);
	MainMenuBarTexture0:SetPoint("BOTTOM", "MainMenuBarArtFrame", "BOTTOM", -128, 0);
	MainMenuBarTexture1:SetPoint("BOTTOM", "MainMenuBarArtFrame", "BOTTOM", 128, 0);















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


	K.CreateBagPackFrame();
	K.ApplyBagPackLayout();


	K.ApplyGryphons();


	minibarEvtFrame:RegisterEvent("ACTIONBAR_SHOWGRID");
	minibarEvtFrame:RegisterEvent("ACTIONBAR_HIDEGRID");
	minibarEvtFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
	minibarEvtFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
	minibarEvtFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
	minibarEvtFrame:RegisterEvent("PLAYER_ENTERING_WORLD");

	minibarEvtFrame:RegisterEvent("PLAYER_XP_UPDATE");
	minibarEvtFrame:RegisterEvent("UPDATE_EXHAUSTION");
	minibarEvtFrame:RegisterEvent("PLAYER_LEVEL_UP");
	minibarEvtFrame:RegisterEvent("UPDATE_FACTION");
	minibarEvtFrame:SetScript("OnEvent", MiniBar_OnEvent);


	MiniBar_UpdateUI();
end




function K.DisableMiniBar()
	if not minibarEnabled then return; end
	if InCombatLockdown() then return; end
	minibarEnabled = false;
	K._minibarActive = false;



	if K.RestoreActionBarButtonSpace then K.RestoreActionBarButtonSpace(); end
	if K.DetachStanceButtons then K.DetachStanceButtons(); end


	if K.HideBarHolders then K.HideBarHolders(); end










	minibarEvtFrame:UnregisterAllEvents();
	minibarEvtFrame:SetScript("OnEvent", nil);
	minibarEvtFrame:SetScript("OnUpdate", nil);


	if BagPackFrame then BagPackFrame:Hide(); end


	for key, val in pairs(mb_savedManaged) do
		UIPARENT_MANAGED_FRAME_POSITIONS[key] = val;
	end


	MB_RestoreAllTextures();


	MB_RestoreFrame("MainMenuBar",              MainMenuBar);



	if K.RestoreArtFrame then K.RestoreArtFrame(); end
	MB_RestoreFrame("MainMenuExpBar",           MainMenuExpBar);
	MB_RestoreFrame("ReputationWatchBar",       ReputationWatchBar);
	MB_RestoreFrame("MainMenuBarMaxLevelBar",   MainMenuBarMaxLevelBar);
	MB_RestoreFrame("ReputationWatchStatusBar", ReputationWatchStatusBar);

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



			f:SetScale(1);
			MB_RestoreFrame(name, f);
		end
	end


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


	if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	if ShapeshiftBar_Update          then pcall(ShapeshiftBar_Update);          end
	if PetActionBar_Update           then pcall(PetActionBar_Update);           end
	if UpdateMicroButtons            then pcall(UpdateMicroButtons);            end



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
























	if K.RestoreBarBaseline then pcall(K.RestoreBarBaseline); end


	mb_savedFrames   = {};
	mb_savedTextures = {};
	mb_savedTexPaths = {};
	mb_savedManaged  = {};


	if C.ActionBarScale and C.ActionBarScale ~= 1.0 then
		K.ApplyActionBarScale(C.ActionBarScale);
	end












	if K.InvalidateMiniBarBackgroundCache then K.InvalidateMiniBarBackgroundCache(); end
	if K._habReapply then K._habReapply(); end
end




local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");



	if C.MiniBarEnabled and not C.UnifyActionBars then
		K.EnableMiniBar();
	end


	if C.ActionBarScale and C.ActionBarScale ~= 1.0 then
		K.ApplyActionBarScale(C.ActionBarScale);
	end
end);







local mbCombat = CreateFrame("Frame");
mbCombat:RegisterEvent("PLAYER_REGEN_ENABLED");
mbCombat:SetScript("OnEvent", function()
	if C.MiniBarEnabled ~= true then return; end


	if mbScalePending then
		mbScalePending = false;
		if K.ApplyBarHolderScales then
			K.ApplyBarHolderScales(C.ActionBarScale or 1.0);
		end
	end
	if K.PinMainMenuBarToRow1 then K.PinMainMenuBarToRow1(); end
end);
