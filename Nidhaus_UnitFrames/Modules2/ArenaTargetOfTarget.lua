-- ArenaTargetOfTarget.lua
-- Shows who each arena enemy is targeting using Blizzard ToT-style frames.
-- Features: draggable (Shift+Alt+Click), scale, class icon / portrait toggle.
-- Position saved per arena style + mirror mode key.

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;
local MOVER_ARENA_COUNT = 3;

local moduleActive = false;
local eventFrame = CreateFrame("Frame");
local totFrames = {};     -- [index] = frame
local dragOverlays = {};  -- [index] = overlay

local FRAME_W, FRAME_H = 96, 46;
local PORTRAIT_SIZE = 28;
local BAR_W, BAR_H = 33, 4;
local BORDER_TEXTURE = "Interface\\TargetingFrame\\UI-TargetofTargetFrame";
local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar";

-- ══════════════════════════════════════════════════════════════
-- ESTILO SQUARE
--
-- El mismo que ya usa Party Targets: en vez de la barrita horizontal
-- estilo Target-of-Target de Blizzard, un cuadradito vertical con el
-- retrato al medio.
--
--     Classic (96x46)            Square (70x75)
--     +----------------+              Nombre
--     |(o) ====== 85%  |             +------+
--     |    ------      |             |  o   |
--     +----------------+             +------+
--          Nombre                     ======
--                                     ------
--
-- Los numeros salen de pw_unitframes/modules/partytarget.lua, tal cual
-- estan en Modules2/PartyTargets/SquareStyle.lua. No los deduje mirando
-- capturas: eso ya lo intente tres veces con el de party y las tres
-- salieron mal.
--
-- Aca es MUCHO mas facil que en party: estos marcos los crea este mismo
-- archivo, no Blizzard, y ApplyFrameLayout vuelve a anclar todas las
-- piezas desde cero en cada llamada. Por eso no hace falta el sistema de
-- "foto original": para volver a Classic alcanza con que la otra rama
-- deje las medidas y las texturas de siempre, cosa que ya hacia.
-- ══════════════════════════════════════════════════════════════
local SQ = {
	frame    = { w = 70, h = 75 },
	border   = { w = 64, h = 64, y = -2 },
	portrait = { size = 32, y = 9 },
	health   = { w = 30, h = 10, y = -10 },
	mana     = { w = 30, h = 10 },
	name     = { w = 84 },
};

local TEXPATH       = "Interface\\AddOns\\" .. AddOnName .. "\\Textures\\";
local SQUARE_TEX    = TEXPATH .. "TargetOfTargetSquare.tga";
local SQUARE_BAR    = TEXPATH .. "beige.tga";

-- ══════════════════════════════════════════════════════════════
-- CLASS COLORS
-- ══════════════════════════════════════════════════════════════
local function GetClassColorRGB(class)
	if not class then return 0.7, 0.7, 0.7; end
	local cc = RAID_CLASS_COLORS[class];
	if cc then return cc.r, cc.g, cc.b; end
	return 0.7, 0.7, 0.7;
end

-- ══════════════════════════════════════════════════════════════
-- POSITION SAVE / RESTORE (per style + ToT mirror key)
-- ══════════════════════════════════════════════════════════════
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
	if not saved then return; end
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
	if NidhausUnitFramesDB then
		NidhausUnitFramesDB.ArenaToTPositions = nil;
	end
	for i = 1, MAX_ARENA_ENEMIES do
		PositionToTFrame(i);
	end
end

-- ══════════════════════════════════════════════════════════════
-- VISUAL MIRROR — flips frame contents (portrait right, bars left)
-- Same concept as PartyTargets mirror: flip border texture + reanchor elements
-- ══════════════════════════════════════════════════════════════
local function ApplyFrameLayout(f, mirrored)
	if not f then return; end

	f.portrait:ClearAllPoints();
	f.healthbar:ClearAllPoints();
	f.manabar:ClearAllPoints();
	f.nameText:ClearAllPoints();

	-- ── Square ──
	--
	-- Sale antes que las otras dos ramas porque el espejado no aplica: el
	-- cuadrado es simetrico, el retrato ya esta centrado y no hay un lado
	-- al que mandarlo. Si estan las dos opciones puestas, manda esta.
	if C.ArenaToTSquare then
		f:SetSize(SQ.frame.w, SQ.frame.h);

		local tex = f.borderTex;
		tex:SetTexture(SQUARE_TEX);
		tex:SetTexCoord(0, 1, 0, 1);
		tex:ClearAllPoints();
		tex:SetSize(SQ.border.w, SQ.border.h);
		tex:SetPoint("CENTER", f, "CENTER", 0, SQ.border.y);
		tex:SetVertexColor(1, 1, 1, 1);

		-- Retrato y barras van DENTRO del cuadrado, anclados a EL y no al
		-- marco. La textura del cuadrado tiene el centro transparente y
		-- solo dibuja el contorno, asi que a simple vista parece rodear
		-- solo el retrato; pero es una caja que contiene todo.
		f.portrait:SetSize(SQ.portrait.size, SQ.portrait.size);
		f.portrait:SetPoint("CENTER", tex, "CENTER", 0, SQ.portrait.y);

		f.healthbar:SetSize(SQ.health.w, SQ.health.h);
		f.healthbar:SetPoint("CENTER", tex, "CENTER", 0, SQ.health.y);
		f.healthbar:SetStatusBarTexture(SQUARE_BAR);

		f.manabar:SetSize(SQ.mana.w, SQ.mana.h);
		f.manabar:SetPoint("TOPLEFT", f.healthbar, "BOTTOMLEFT", 0, 0);
		f.manabar:SetStatusBarTexture(SQUARE_BAR);

		-- El nombre colgado del CUADRADO, no de la barra de vida: la barra
		-- esta descentrada dentro del marco y el nombre heredaba ese
		-- corrimiento. Es el mismo detalle que ya esta anotado en el
		-- Square de party.
		f.nameText:SetSize(SQ.name.w, 10);
		f.nameText:SetPoint("BOTTOM", tex, "TOP", 0, -2);
		f.nameText:SetJustifyH("CENTER");
		return;
	end

	-- ── Classic: volver a las medidas y texturas de siempre ──
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
		-- Portrait on the RIGHT
		f.portrait:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -2);
		-- Bars on the LEFT (TOPLEFT anchored so StatusBar renders correctly)
		f.healthbar:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -11);
		f.manabar:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -18);
		-- Name on the LEFT
		f.nameText:SetSize(60, 10);
		f.nameText:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -22);
		f.nameText:SetJustifyH("LEFT");
		-- Flip border texture horizontally (swap UL↔UR, LL↔LR)
		-- 8-arg: ULx,ULy, LLx,LLy, URx,URy, LRx,LRy
		f.borderTex:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1);
	else
		-- Portrait on the LEFT (default Blizzard layout)
		f.portrait:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -2);
		-- Bars on the RIGHT
		f.healthbar:SetPoint("TOPLEFT", f, "TOPLEFT", 35, -11);
		f.manabar:SetPoint("TOPLEFT", f, "TOPLEFT", 35, -18);
		-- Name on the RIGHT
		f.nameText:SetSize(60, 10);
		f.nameText:SetPoint("TOPLEFT", f, "TOPLEFT", 35, -22);
		f.nameText:SetJustifyH("LEFT");
		-- Normal border texture
		f.borderTex:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1);
	end
end

local function ApplyMirrorToAll()
	local mirrored = C.ArenaToTMirrored;
	for i = 1, MAX_ARENA_ENEMIES do
		if totFrames[i] then ApplyFrameLayout(totFrames[i], mirrored); end
	end
end

-- Publica: la llama el panel al tocar Square o Mirror.
--
-- Ademas de reacomodar las piezas hay que volver a colocar los marcos:
-- Square mide 70x75 contra los 96x46 de Classic, asi que el anclaje por
-- defecto respecto del marco de arena cambia de lugar. Sin esto, cambiar
-- de estilo dejaba el cuadrado corrido.
function K.RefreshArenaToTLayout()
	ApplyMirrorToAll();
	if K.RepositionAllArenaToT then K.RepositionAllArenaToT(); end
end

-- ══════════════════════════════════════════════════════════════
-- FRAME CREATION
-- ══════════════════════════════════════════════════════════════
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

	-- Portrait
	local portrait = f:CreateTexture(name.."Portrait", "BACKGROUND");
	portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE);
	portrait:SetPoint("TOPLEFT", 4, -2);
	f.portrait = portrait;

	-- Health bar
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

	-- Mana bar
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

	-- Border
	local border = f:CreateTexture(name.."Texture", "ARTWORK");
	border:SetSize(FRAME_W, FRAME_H);
	border:SetPoint("TOPLEFT", 0, 0);
	border:SetTexture(BORDER_TEXTURE);
	f.borderTex = border;

	-- Name
	local nameFS = f:CreateFontString(name.."Name", "OVERLAY", "GameFontNormalSmall");
	nameFS:SetSize(60, 10);
	nameFS:SetPoint("TOPLEFT", 35, -22);
	nameFS:SetJustifyH("LEFT");
	nameFS:SetTextColor(1, 0.82, 0);
	f.nameText = nameFS;

	-- Apply saved scale
	local scale = C.ArenaToTScale or 1.0;
	if scale > 0 then f:SetScale(scale); end

	f:EnableMouse(false);
	f:SetMovable(true);
	f:Hide();
	totFrames[index] = f;

	-- Apply mirror layout
	ApplyFrameLayout(f, C.ArenaToTMirrored);

	return f;
end

-- ══════════════════════════════════════════════════════════════
-- POSITIONING (default, before any drag offset)
-- ══════════════════════════════════════════════════════════════
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
	-- Re-apply saved drag offset after default positioning
	K.RestoreArenaToTPositions();
end

-- ══════════════════════════════════════════════════════════════
-- SCALE
-- ══════════════════════════════════════════════════════════════
function K.ApplyArenaToTScale(scale)
	if type(scale) ~= "number" or scale <= 0 then scale = 1.0; end
	for i = 1, MAX_ARENA_ENEMIES do
		if totFrames[i] then totFrames[i]:SetScale(scale); end
	end
end

-- ══════════════════════════════════════════════════════════════
-- PORTRAIT / CLASS ICON
-- ══════════════════════════════════════════════════════════════
local function SetPortraitOrClassIcon(f, unit, class)
	if not f or not f.portrait then return; end
	if C.ArenaToTClassIcon and class then
		local coords = CLASS_ICON_TCOORDS[class];
		if coords then
			f.portrait:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
			f.portrait:SetTexCoord(unpack(coords));
			return;
		end
	end
	-- Portrait mode (or class icon fallback)
	if unit and UnitExists(unit) then
		SetPortraitTexture(f.portrait, unit);
		f.portrait:SetTexCoord(0, 1, 0, 1);
	end
end

-- ══════════════════════════════════════════════════════════════
-- DRAG OVERLAYS (Shift+Alt+Click, same pattern as castbar/trinket)
-- ══════════════════════════════════════════════════════════════
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

		-- Save and apply to all ToT frames
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
	for i = 1, MOVER_ARENA_COUNT do
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

-- ══════════════════════════════════════════════════════════════
-- UPDATE (live arena)
-- ══════════════════════════════════════════════════════════════
local function UpdateToTFrame(index)
	local f = totFrames[index];
	if not f then return; end
	local arenaFrame = _G["ArenaEnemyFrame"..index];
	if not arenaFrame or not arenaFrame:IsShown() then f:Hide(); return; end

	local targetUnit = "arena"..index.."target";
	if not UnitExists(targetUnit) then f:Hide(); return; end

	-- Portrait / class icon
	local _, targetClass = UnitClass(targetUnit);
	SetPortraitOrClassIcon(f, targetUnit, targetClass);

	-- Name
	local targetName = UnitName(targetUnit) or "?";
	if #targetName > 10 then targetName = targetName:sub(1, 9) .. ".."; end
	local r, g, b = GetClassColorRGB(targetClass);
	f.nameText:SetText(targetName);
	f.nameText:SetTextColor(r, g, b);

	-- Health
	local hp = UnitHealth(targetUnit) or 0;
	local hpMax = UnitHealthMax(targetUnit); if not hpMax or hpMax <= 0 then hpMax = 1; end
	f.healthbar:SetMinMaxValues(0, hpMax); f.healthbar:SetValue(hp);
	f.healthbar:SetStatusBarColor(r, g, b);

	-- Power
	local mp = UnitMana(targetUnit) or 0;
	local mpMax = UnitManaMax(targetUnit); if not mpMax or mpMax <= 0 then mpMax = 1; end
	f.manabar:SetMinMaxValues(0, mpMax); f.manabar:SetValue(mp);
	local pt = UnitPowerType(targetUnit);
	if pt == 0 then f.manabar:SetStatusBarColor(0, 0, 1);
	elseif pt == 1 then f.manabar:SetStatusBarColor(1, 0, 0);
	elseif pt == 3 then f.manabar:SetStatusBarColor(1, 1, 0);
	elseif pt == 6 then f.manabar:SetStatusBarColor(0, 0.82, 1);
	else f.manabar:SetStatusBarColor(0, 0, 1); end

	-- Glow if targeting player
	if UnitIsUnit(targetUnit, "player") then
	else
	end
	f:Show();
end

local function UpdateAll()
	for i = 1, MAX_ARENA_ENEMIES do UpdateToTFrame(i); end
end

-- ══════════════════════════════════════════════════════════════
-- TEST MODE
-- ══════════════════════════════════════════════════════════════
local testData = {
	{name = "Nidhaus",  class = "WARLOCK",     hp = 18000, hpMax = 22000, mp = 8500,  mpMax = 12000, power = 0, me = true},
	{name = "Arthas",   class = "DEATHKNIGHT", hp = 30000, hpMax = 35000, mp = 80,    mpMax = 100,   power = 6, me = false},
	{name = "Thrall",   class = "SHAMAN",      hp = 25000, hpMax = 28000, mp = 9000,  mpMax = 15000, power = 0, me = false},
};

local function ShowTestMode()
	local scale = C.ArenaToTScale or 1.0;
	for i = 1, MOVER_ARENA_COUNT do
		local f = CreateToTFrame(i);
		if not f then break; end
		PositionToTFrame(i);
		if scale > 0 then f:SetScale(scale); end
		local d = testData[i]; if not d then break; end

		-- Portrait / class icon
		if C.ArenaToTClassIcon then
			local coords = CLASS_ICON_TCOORDS[d.class];
			if coords and f.portrait then
				f.portrait:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
				f.portrait:SetTexCoord(unpack(coords));
			end
		else
			-- Test mode: no unit exists, use class icon as fallback
			local coords = CLASS_ICON_TCOORDS[d.class];
			if coords and f.portrait then
				f.portrait:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
				f.portrait:SetTexCoord(unpack(coords));
			end
		end

		local r, g, b = GetClassColorRGB(d.class);
		f.nameText:SetText(d.name); f.nameText:SetTextColor(r, g, b);
		f.healthbar:SetMinMaxValues(0, d.hpMax); f.healthbar:SetValue(d.hp); f.healthbar:SetStatusBarColor(r, g, b);
		f.manabar:SetMinMaxValues(0, d.mpMax); f.manabar:SetValue(d.mp);
		if d.power == 0 then f.manabar:SetStatusBarColor(0, 0, 1);
		elseif d.power == 1 then f.manabar:SetStatusBarColor(1, 0, 0);
		elseif d.power == 6 then f.manabar:SetStatusBarColor(0, 0.82, 1); end

		f:Show();
	end
	-- Apply mirror layout to all frames
	ApplyMirrorToAll();
	-- Restore saved positions
	K.RestoreArenaToTPositions();
	-- Show drag overlays
	ShowDragOverlays();
end

local function HideAll()
	HideDragOverlays();
	for i = 1, MAX_ARENA_ENEMIES do if totFrames[i] then totFrames[i]:Hide(); end end
end

K._ShowArenaToTTest = ShowTestMode;
K._HideArenaToTTest = HideAll;

-- ══════════════════════════════════════════════════════════════
-- EVENTS
-- ══════════════════════════════════════════════════════════════
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
				-- FIX: Restore saved drag position + scale for this frame.
				-- Without this, frames created via ARENA_OPPONENT_UPDATE use
				-- default positions because PLAYER_ENTERING_WORLD ran before
				-- the ArenaEnemyFrames existed.
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
			if not self._polling then
				self._polling = true;
				local el = 0;
				self:SetScript("OnUpdate", function(s, dt)
					el = el + dt;
					if el >= 0.5 then el = 0; UpdateAll(); end
				end);
			end
		else
			HideAll(); self:SetScript("OnUpdate", nil); self._polling = false;
		end
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		local _, iType = IsInInstance();
		if iType ~= "arena" then HideAll(); self:SetScript("OnUpdate", nil); self._polling = false; end
	end
end

-- ══════════════════════════════════════════════════════════════
-- TEST MODE WATCHER
-- ══════════════════════════════════════════════════════════════
local testModeWatcher = CreateFrame("Frame");
testModeWatcher:Hide();
local twElapsed, lastState = 0, false;

testModeWatcher:SetScript("OnUpdate", function(self, dt)
	if not moduleActive then return; end
	twElapsed = twElapsed + dt;
	if twElapsed < 0.3 then return; end
	twElapsed = 0;
	local isTest = K._testModeActive or
		(NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown);
	if isTest and not lastState then
		lastState = true;
		local d = CreateFrame("Frame"); local e = 0;
		d:SetScript("OnUpdate", function(s, dt2)
			e = e + dt2;
			if e >= 0.4 then s:SetScript("OnUpdate", nil); if moduleActive then ShowTestMode(); end end
		end);
	elseif not isTest and lastState then
		lastState = false; HideAll();
	end
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if not moduleActive then return; end
	ApplyMirrorToAll();
	K.ApplyArenaToTScale(C.ArenaToTScale or 1.0);
	-- If in test mode, re-show to pick up changes
	local isTest = K._testModeActive or
		(NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown);
	if isTest then
		ShowTestMode();
	else
		K.RepositionAllArenaToT();
	end
end);

-- ══════════════════════════════════════════════════════════════
-- ENABLE / DISABLE
-- ══════════════════════════════════════════════════════════════
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
	end
	if K._testModeActive or
		(NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover and NidhausUnitFramesDB.ArenaMover.IsShown) then
		ShowTestMode(); lastState = true;
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

-- ══════════════════════════════════════════════════════════════
-- REGISTER
-- ══════════════════════════════════════════════════════════════
K.RegisterModule("ArenaToT", {
	name      = "Arena Target of Target",
	desc      = "Shows who each arena enemy is targeting with Blizzard ToT-style frames.",
	default   = false,
	onEnable  = Enable,
	onDisable = Disable,
});