local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local ExecutePhase = {
	["MAGE"]		=	0,
	["PRIEST"]		=	0,
	["WARLOCK"]		=	25,
	["DRUID"]		=	0,
	["ROGUE"]		=	0,
	["HUNTER"]		=	20,
	["SHAMAN"]		=	0,
	["DEATHKNIGHT"]		=	0,
	["PALADIN"]		=	20,
	["WARRIOR"]		=	20,
};

local select		=	select;
local UnitClass		=	UnitClass;
local math_ceil		=	math.ceil;
local hooksecurefunc = hooksecurefunc;

local Core = CreateFrame("FRAME", "TargetFramePercent", TargetFrameTextureFrame);
local isInitialized = false;
local playerExecutePhase = 0;
local frameCreated = false;
-- FIX: Cachear estado de execute phase para evitar GetBackdropColor() en cada tick de vida
-- (antes: select(1, Core:GetBackdropColor()) se llamaba en cada update de health bar)
local isExecutePhase = false;

local function CreateMainFrame()
	if frameCreated then return; end

	Core:SetSize(46, 19);
	Core:SetBackdrop({bgFile = "Interface\\AddOns\\"..AddOnName.."\\Media\\Statusbar\\whoa"});
	Core:SetBackdropColor(0, 0, 0, .8);
	Core:SetPoint("TOPLEFT", 17, -2);
	Core:SetFrameLevel(TargetFrameTextureFrame:GetFrameLevel()-1);
	
	Core.edge = Core:CreateTexture(nil, "ARTWORK");
	Core.edge:SetTexture([[Interface\TARGETINGFRAME\NumericThreatBorder]]);
	Core.edge:SetPoint("TOPLEFT", Core, "TOPLEFT", -8, 3);
	Core.edge:SetSize(80, 40);
	
	Core.Text = Core:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	Core.Text:SetPoint("CENTER", 0, 0);
	
	Core:Hide();
	frameCreated = true;
end

local function SetupThreatIndicators()
	TargetFrameNumericalThreat:ClearAllPoints();
	TargetFrameNumericalThreat:SetPoint("TOPLEFT", 68, -4);
	TargetFrameNumericalThreat:SetFrameLevel(TargetFrameTextureFrame:GetFrameLevel()-1);
	select(2, TargetFrameNumericalThreat:GetRegions()):SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Statusbar\\whoa");
	FocusFrameNumericalThreat:SetFrameLevel(FocusFrameTextureFrame:GetFrameLevel()-1);
end

local function GetPlayerExecutePhase()
	-- FIX: Acceso directo por key en vez de iterar toda la tabla
	playerExecutePhase = ExecutePhase[select(2, UnitClass("player"))] or 0;
end

local function TextStatusBar_Update(self)
	if self ~= TargetFrameHealthBar then return end;
	if not Core.Text then return; end
	
	if not C.HealthPercentage then
		if Core:IsShown() then
			Core:Hide();
		end
		return;
	end
	
	if not Core:IsShown() then
		Core:Show();
	end
	
	local Value = self.currValue;
	local _, MaxValue = self:GetMinMaxValues();
	
	if MaxValue == 0 then
		Core.Text:SetText("N/A");
		return;
	end
	
	local HealthPercent = (Value / MaxValue) * 100;
	
	if Value == 0 then
		Core.Text:SetText("Dead");
	else
		Core.Text:SetText(math_ceil(HealthPercent).."%");
	end;
	
	if HealthPercent < playerExecutePhase and not isExecutePhase then
		Core:SetBackdropColor(1, 0, 0, .8);
		isExecutePhase = true;
	elseif HealthPercent >= playerExecutePhase and isExecutePhase then
		Core:SetBackdropColor(0, 0, 0, .8);
		isExecutePhase = false;
	end;
end;

local function InitializeHealthPercentage()
	if isInitialized then return; end
	
	CreateMainFrame();
	SetupThreatIndicators();
	GetPlayerExecutePhase();
	
	hooksecurefunc("TextStatusBar_UpdateTextString", TextStatusBar_Update);
	
	if C.HealthPercentage then
		Core:Show();
		if TargetFrameHealthBar then
			TextStatusBar_Update(TargetFrameHealthBar);
		end
	else
		Core:Hide();
	end
	
	isInitialized = true;
end

function K.ToggleHealthPercentage(enabled)
	if not isInitialized then return; end
	
	if enabled then
		Core:Show();
		if TargetFrameHealthBar then
			TextStatusBar_Update(TargetFrameHealthBar);
		end
	else
		Core:Hide();
	end
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	InitializeHealthPercentage();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized and TargetFrameHealthBar then
		TextStatusBar_Update(TargetFrameHealthBar);
	end
end);