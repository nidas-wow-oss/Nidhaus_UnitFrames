local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooksecurefunc = hooksecurefunc;
local MAX_BOSS_FRAMES = MAX_BOSS_FRAMES;
local _G = _G;

-- NidhausBossFrame ES el drag container para los boss frames.
-- Tiene nombre global para que Commands.lua lo acceda via _G["NUF_BossMover"].
local NidhausBossFrame = CreateFrame("Frame", "NUF_BossMover", UIParent);
NidhausBossFrame:SetSize(180, 20);
NidhausBossFrame:SetMovable(true);
NidhausBossFrame:EnableMouse(true);
NidhausBossFrame:RegisterForDrag("LeftButton");
NidhausBossFrame:SetClampedToScreen(true);
NidhausBossFrame:Hide();

-- Fondo visible: la barra azul que sirve de handle de drag
NidhausBossFrame.bg = NidhausBossFrame:CreateTexture(nil, "BACKGROUND");
NidhausBossFrame.bg:SetAllPoints(true);
NidhausBossFrame.bg:SetTexture(0.2, 0.6, 0.8, 0.7);

local label = NidhausBossFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
label:SetAllPoints();
label:SetText("|cffFFFF00BOSS FRAMES [drag]|r");
label:SetJustifyH("CENTER");

NidhausBossFrame:SetScript("OnDragStart", function(self)
	self:StartMoving();
end);

NidhausBossFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing();
	-- Guardar posición en el sistema estándar de positions
	local point, relativeTo, relativePoint, x, y = self:GetPoint();
	if point then
		if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
		if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
		local relName = relativeTo and relativeTo:GetName() or "UIParent";
		-- FIX: Usar formato con nombres (consistente con FrameDragger.SaveFramePosition)
		NidhausUnitFramesDB.positions["BossMover"] = {
			point = point,
			relativeTo = relName,
			relativePoint = relativePoint,
			x = x,
			y = y,
		};
		-- Actualizar C.BossTargetFramePoint para que FramePositions.lua lo use
		C.BossTargetFramePoint = { point, relativeTo or UIParent, relativePoint, x, y };
	end
end);

K.NidhausBossFrame = NidhausBossFrame;
local isInitialized = false;

local function Nidhaus_UnitFrames_Style_BossFrame(self)
	if C.statusbarOn then
		self.healthbar:SetStatusBarTexture(C.statusbarTexture);
	end;
	if C.darkFrames then 
		self.borderTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\UI-TargetingFrame");
	else
		self.borderTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\UI-TargetingFrame");
	end;
	
	self.threatIndicator:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash");
	self.threatIndicator:SetTexCoord(0, 0.9453125, 0, 0.181640625);
	self.threatIndicator:SetWidth(242);
	self.threatIndicator:SetHeight(93);
	self.threatIndicator:SetPoint(K.SetOffset(self.threatIndicator, 0, 0));

	self.nameBackground:Hide();
	self.name:SetPoint(K.SetOffset(self.name, 0, 1));
	self.name:SetFont("Fonts\\FRIZQT__.TTF", 12);

	self.healthbar:SetSize(119, 28);
	self.healthbar:SetPoint("TOPLEFT", 5, -24);
	self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
	self.deadText:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
	
	self.levelText:SetPoint(K.SetOffset(self.levelText, 51, 0));
	
	self.portrait = _G[self:GetName().."Portrait"];

	local scale = C.BossFrameScale or 0.65;
	if type(scale) == "number" and scale > 0 and scale <= 3 then
		self:SetScale(scale);
	else
		self:SetScale(0.65);
	end
end;

local function InitializeBossFrames()
	if isInitialized then return; end
	
	for i = 1, MAX_BOSS_FRAMES do
		local bossFrame = _G["Boss"..i.."TargetFrame"];
		if bossFrame then
			if C.SetPositions then 
				K.MoveFrame(bossFrame, "NidhausBoss"..i.."TargetFrame", "Boss"..i, 0, 0, NidhausBossFrame);
			end;
			
			Nidhaus_UnitFrames_Style_BossFrame(bossFrame);
			
			if C.statusbarBackdrop then
				K.CreateBackdrop(bossFrame);
			end;
		end
	end;
	
	isInitialized = true;
end

function K.ApplyBossFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	for i = 1, MAX_BOSS_FRAMES do
		local bossFrame = _G["Boss"..i.."TargetFrame"];
		if bossFrame then bossFrame:SetScale(scale); end
	end
end

function K.ApplyBossFrameSpacing()
	if not isInitialized then return; end
	local spacing = C.BossTargetFrameSpacing or 0;
	if type(spacing) ~= "number" then spacing = 0; end
	-- FIX: Negate so positive slider values = more separation (downward)
	-- Before: positive = overlap (UP), negative = separate (DOWN) — counter-intuitive
	local offset = -spacing;

	-- Si BossMover está activo, reposicionar relativo a él
	if NidhausBossFrame:IsShown() then
		for i = 1, MAX_BOSS_FRAMES do
			-- Usar NidhausBoss frames (SetPositions=true) o Boss frames (SetPositions=false)
			local frameName = C.SetPositions and ("NidhausBoss"..i.."TargetFrame") or ("Boss"..i.."TargetFrame");
			local bossFrame = _G[frameName];
			if bossFrame then
				bossFrame:ClearAllPoints();
				if i == 1 then
					bossFrame:SetPoint("TOPLEFT", NidhausBossFrame, "BOTTOMLEFT", 0, 0);
				else
					local prevName = C.SetPositions and ("NidhausBoss"..(i-1).."TargetFrame") or ("Boss"..(i-1).."TargetFrame");
					local prev = _G[prevName];
					if prev then
						bossFrame:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, offset);
					end
				end
			end
		end
	end

	-- También aplicar cuando están en SetPositions normal
	if C.SetPositions then
		for i = 2, MAX_BOSS_FRAMES do
			local frameName = "NidhausBoss"..i.."TargetFrame";
			local bossFrame = _G[frameName];
			local prevName = "NidhausBoss"..(i-1).."TargetFrame";
			local prev = _G[prevName];
			if bossFrame and prev and not NidhausBossFrame:IsShown() then
				bossFrame:ClearAllPoints();
				bossFrame:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, offset);
			end
		end
	end
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	-- Cargar posición guardada de BossMover
	if NidhausUnitFramesDB and NidhausUnitFramesDB.positions and NidhausUnitFramesDB.positions["BossMover"] then
		local saved = NidhausUnitFramesDB.positions["BossMover"];
		-- FIX: Leer con nombres (nuevo formato) o con índices (formato viejo) para compatibilidad
		local point = saved.point or saved[1];
		local relName = saved.relativeTo or saved[2];
		local relPoint = saved.relativePoint or saved[3];
		local x = saved.x or saved[4];
		local y = saved.y or saved[5];
		NidhausBossFrame:ClearAllPoints();
		NidhausBossFrame:SetPoint(point, _G[relName] or UIParent, relPoint, x, y);
		-- FIX: Actualizar C.BossTargetFramePoint para que FramePositions.lua no lo pise con el default
		C.BossTargetFramePoint = { point, _G[relName] or UIParent, relPoint, x, y };
	elseif C.BossTargetFramePoint then
		NidhausBossFrame:ClearAllPoints();
		NidhausBossFrame:SetPoint(unpack(C.BossTargetFramePoint));
	else
		NidhausBossFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -200, -220);
	end

	InitializeBossFrames();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized and C.BossFrameScale then
		K.ApplyBossFrameScale(C.BossFrameScale);
	end
	if isInitialized and C.BossTargetFrameSpacing ~= nil then
		K.ApplyBossFrameSpacing();
	end
end);