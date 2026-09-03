----------------------------------------------------
-- PartyTargets
-- Shows who your party members are targeting.
-- Features:
--   - Optional mirror for PartyMemberFrames
--   - Target-of-Target style compact target frames
--   - ALT+drag to move target frames
--   - Config panel: /ptarget or /ptarget config
----------------------------------------------------
local addon = LibStub:NewLibrary("PartyTargets-3.3", 200912123.9)
assert(addon, "Failed to load library 'PartyTargets-3.3' with LibStub")

-- FIX: Capture NUF namespace to access K.IsNewPartyFrameActive
local _, _nufNS = ...;
local _nufK = _nufNS and _nufNS[1] or nil;

----------------------------------------------------
-- Saved Variables, Defaults & State
----------------------------------------------------
PartyTargetsDB = PartyTargetsDB or {}
local unlocked = false
PartyTargets_configOpen = false  -- global, set by Options.lua

local DEFAULTS = {
	mirror = false,
	anchor = true,
	scale = 1.0,
	locked = false,
	style = "Classic",   -- "Classic" (Target-of-Target) o "Square"
	hideName = false,    -- ocultar el nombre del objetivo
}

-- ---------------------------------------------------------
-- Escala, guardada POR ESTILO
--
-- Classic y Square son marcos de tamaño muy distinto, asi que una sola
-- escala obligaba a reajustar el slider cada vez que se cambiaba de uno al
-- otro. Ahora cada estilo recuerda la suya.
--
-- PartyTargetsDB.scale sigue existiendo: es lo que habia antes y sirve de
-- punto de partida para los dos estilos la primera vez.
--
-- OJO: en este archivo el namespace de NUF es _nufK, no K.
-- ---------------------------------------------------------
local function StyleKey()
	return (PartyTargetsDB.style == "Square") and "Square" or "Classic";
end

local function GetScale(style)
	local key = style or StyleKey();
	local t = PartyTargetsDB.scaleByStyle;
	if t and type(t[key]) == "number" then return t[key]; end
	return PartyTargetsDB.scale or 1.0;
end

local function SaveScale(value, style)
	local key = style or StyleKey();
	if type(PartyTargetsDB.scaleByStyle) ~= "table" then
		PartyTargetsDB.scaleByStyle = {};
	end
	PartyTargetsDB.scaleByStyle[key] = value;
	-- Se mantiene al dia por si algo viejo todavia lee .scale
	PartyTargetsDB.scale = value;
end

-- Los PartyTargetFrame heredan SecureUnitButtonTemplate, o sea que son
-- marcos protegidos y SetScale sobre ellos esta vedado en combate. Si toca
-- en plena pelea se anota y se aplica al salir, en vez de comerse un
-- "Interface action failed because of an AddOn" por cada marco.
local scalePending = false;

local function ApplyScale()
	local v = GetScale();
	if InCombatLockdown() then
		scalePending = true;
		return v;
	end
	scalePending = false;
	for i = 1, MAX_PARTY_MEMBERS do
		local f = _G["PartyTargetFrame" .. i];
		if f then f:SetScale(v); end
	end
	return v;
end

local scaleWatcher = CreateFrame("Frame");
scaleWatcher:RegisterEvent("PLAYER_REGEN_ENABLED");
scaleWatcher:SetScript("OnEvent", function()
	if scalePending then ApplyScale(); end
end);

if _nufK then
	_nufK.GetPartyTargetScale   = GetScale;
	_nufK.SavePartyTargetScale  = SaveScale;
	_nufK.ApplyPartyTargetScale = ApplyScale;
end

local function EnsureDefaults()
	for k, v in pairs(DEFAULTS) do
		if PartyTargetsDB[k] == nil then PartyTargetsDB[k] = v end
	end
end

local function SavePosition(self)
	local id = self:GetID()
	local point, relativeTo, relativePoint, x, y = self:GetPoint(1)
	local relName = relativeTo and relativeTo:GetName() or nil
	PartyTargetsDB["frame"..id] = {
		point = point,
		relativeTo = relName,
		relativePoint = relativePoint,
		x = x,
		y = y,
	}
end

local function LoadPosition(self)
	local id = self:GetID()
	if PartyTargetsDB.anchor then return false end
	local pos = PartyTargetsDB["frame"..id]
	if pos then
		self:ClearAllPoints()
		local rel = pos.relativeTo and _G[pos.relativeTo] or UIParent
		self:SetPoint(pos.point or "TOPLEFT", rel, pos.relativePoint or "BOTTOMLEFT", pos.x or 20, pos.y or 12)
		return true
	end
	return false
end

-- Default anchor offset (TOPLEFT of target -> BOTTOMLEFT of party frame)
local DEFAULT_ANCHOR_X = 105
local DEFAULT_ANCHOR_Y = 32

local function AnchorAllToParty(offX, offY)
	offX = offX or PartyTargetsDB.anchorX or DEFAULT_ANCHOR_X
	offY = offY or PartyTargetsDB.anchorY or DEFAULT_ANCHOR_Y
	for i = 1, MAX_PARTY_MEMBERS do
		local f = _G["PartyTargetFrame"..i]
		local parent = _G["PartyMemberFrame"..i]
		if f and parent then
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", offX, offY)
		end
	end
end

-- Offset del marco de objetivo respecto del marco de su compañero.
--
-- LAS ESCALAS. GetLeft/GetTop devuelven coordenadas en el espacio PROPIO de
-- cada frame, y ese espacio depende de su escala. El marco de objetivo tiene
-- la suya (PartyTargetsDB.scale) y el del compañero la suya — que ademas en
-- modo 3v3 es 1.5 o 1.3 segun el miembro.
--
-- Restar los valores crudos de dos frames con escalas distintas da un numero
-- que no significa nada. Ese era el "se imanta al techo": con el objetivo al
-- 1.0 y el compañero al 1.5, el offset vertical salia enorme y el marco se
-- iba arriba de todo.
--
-- Se pasa todo a pixeles de PANTALLA para restar, y el resultado se traduce
-- al espacio del marco de objetivo, que es donde SetPoint lo va a interpretar.
local function ComputeAnchorOffset(frame)
	local id = frame:GetID()
	local parent = _G["PartyMemberFrame"..id]
	if not parent then return DEFAULT_ANCHOR_X, DEFAULT_ANCHOR_Y end

	local fs = frame:GetEffectiveScale()
	local ps = parent:GetEffectiveScale()
	if not fs or fs == 0 then fs = 1 end
	if not ps or ps == 0 then ps = 1 end

	local fl, ft = frame:GetLeft(), frame:GetTop()
	local pl, pb = parent:GetLeft(), parent:GetBottom()
	if fl and ft and pl and pb then
		local dx = (fl * fs) - (pl * ps)
		local dy = (ft * fs) - (pb * ps)
		return dx / fs, dy / fs
	end
	return DEFAULT_ANCHOR_X, DEFAULT_ANCHOR_Y
end

local function MakeDraggable(frame)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	
	frame:HookScript("OnDragStart", function(self)
		-- Config panel open: always draggable
		if PartyTargets_configOpen then
			self:StartMoving()
			return
		end
		-- Shift+Alt: ALWAYS draggable (override lock & anchor)
		if IsShiftKeyDown() and IsAltKeyDown() then
			self:StartMoving()
			return
		end
		-- Locked: block
		if PartyTargetsDB.locked then return end
		-- Anchored: block normal drag
		if PartyTargetsDB.anchor then return end
		-- Free mode: drag if unlocked or ALT
		if unlocked or IsAltKeyDown() then
			self:StartMoving()
		end
	end)
	
	frame:HookScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		
		-- En modo anclado, mover uno mueve los cuatro. SIEMPRE.
		--
		-- Antes esto pedia ademas que el panel estuviera abierto, o que
		-- Shift+Alt siguieran apretados AL SOLTAR. Lo segundo es facil de
		-- fallar: arrastras con Shift+Alt, largas las teclas y despues el
		-- boton, y el marco quedaba solo, desalineado de los otros tres.
		--
		-- Si el arrastre llego hasta aca es porque OnDragStart lo permitio;
		-- no hace falta volver a preguntar por que.
		if PartyTargetsDB.anchor then
			local offX, offY = ComputeAnchorOffset(self)
			PartyTargetsDB.anchorX = offX
			PartyTargetsDB.anchorY = offY
			AnchorAllToParty(offX, offY)
		else
			SavePosition(self)
		end
	end)
end

----------------------------------------------------
-- PART 1: Mirror Party Member Frames (Optional)
----------------------------------------------------

local partyOrigState = {}
local partyMirrored = {}

local function MirrorPoint(point)
	if point == "LEFT" then return "RIGHT" end
	if point == "RIGHT" then return "LEFT" end
	if point == "TOPLEFT" then return "TOPRIGHT" end
	if point == "TOPRIGHT" then return "TOPLEFT" end
	if point == "BOTTOMLEFT" then return "BOTTOMRIGHT" end
	if point == "BOTTOMRIGHT" then return "BOTTOMLEFT" end
	return point
end

local function CapturePartyOriginals(index)
	if partyOrigState[index] then return end
	
	local pre = "PartyMemberFrame"..index
	local frame = _G[pre]
	if not frame then return end
	
	local s = {}
	
	local tex = _G[pre.."Texture"]
	if tex then
		s.texCoords = {tex:GetTexCoord()}
		s.texPoints = {}
		for p = 1, tex:GetNumPoints() do
			s.texPoints[p] = {tex:GetPoint(p)}
		end
		s.texW, s.texH = tex:GetWidth(), tex:GetHeight()
	end
	
	local portrait = _G[pre.."Portrait"]
	if portrait then
		s.portPoints = {}
		for p = 1, portrait:GetNumPoints() do
			s.portPoints[p] = {portrait:GetPoint(p)}
		end
		s.portW, s.portH = portrait:GetWidth(), portrait:GetHeight()
		s.portLayer = portrait:GetDrawLayer()
	end
	
	local hb = _G[pre.."HealthBar"]
	if hb then
		s.hbPoints = {}
		for p = 1, hb:GetNumPoints() do
			s.hbPoints[p] = {hb:GetPoint(p)}
		end
		s.hbW, s.hbH = hb:GetWidth(), hb:GetHeight()
		-- Health bar text
		local hbText = _G[pre.."HealthBarText"]
		if hbText then
			s.hbTextPoints = {}
			for p = 1, hbText:GetNumPoints() do
				s.hbTextPoints[p] = {hbText:GetPoint(p)}
			end
		end
	end
	
	local mb = _G[pre.."ManaBar"]
	if mb then
		s.mbPoints = {}
		for p = 1, mb:GetNumPoints() do
			s.mbPoints[p] = {mb:GetPoint(p)}
		end
		s.mbW, s.mbH = mb:GetWidth(), mb:GetHeight()
		local mbText = _G[pre.."ManaBarText"]
		if mbText then
			s.mbTextPoints = {}
			for p = 1, mbText:GetNumPoints() do
				s.mbTextPoints[p] = {mbText:GetPoint(p)}
			end
		end
	end
	
	local name = _G[pre.."Name"]
	if name then
		s.namePoints = {}
		for p = 1, name:GetNumPoints() do
			s.namePoints[p] = {name:GetPoint(p)}
		end
		s.nameJustify = name:GetJustifyH()
	end
	
	local flash = _G[pre.."Flash"]
	if flash then
		s.flashPoints = {}
		for p = 1, flash:GetNumPoints() do
			s.flashPoints[p] = {flash:GetPoint(p)}
		end
		s.flashCoords = {flash:GetTexCoord()}
	end
	
	local leader = _G[pre.."LeaderIcon"]
	if leader then
		s.leaderPoints = {}
		for p = 1, leader:GetNumPoints() do
			s.leaderPoints[p] = {leader:GetPoint(p)}
		end
	end
	
	local ml = _G[pre.."MasterIcon"]
	if ml then
		s.mlPoints = {}
		for p = 1, ml:GetNumPoints() do
			s.mlPoints[p] = {ml:GetPoint(p)}
		end
	end
	
	local pvp = _G[pre.."PVPIcon"]
	if pvp then
		s.pvpPoints = {}
		for p = 1, pvp:GetNumPoints() do
			s.pvpPoints[p] = {pvp:GetPoint(p)}
		end
	end
	
	partyOrigState[index] = s
end

local function ApplyMirrorToParty(index)
	local pre = "PartyMemberFrame"..index
	local frame = _G[pre]
	if not frame then return end
	
	CapturePartyOriginals(index)
	local s = partyOrigState[index]
	if not s then return end
	
	-- Mirror main texture
	local tex = _G[pre.."Texture"]
	if tex and s.texCoords then
		local ULx,ULy, LLx,LLy, URx,URy, LRx,LRy = unpack(s.texCoords)
		tex:SetTexCoord(URx,URy, LRx,LRy, ULx,ULy, LLx,LLy)
		tex:ClearAllPoints()
		for _, pt in ipairs(s.texPoints) do
			local point, rel, relPoint, x, y = unpack(pt)
			tex:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
		end
	end
	
	-- Mirror portrait (raise layer so texture doesn't cover it)
	local portrait = _G[pre.."Portrait"]
	if portrait and s.portPoints then
		portrait:ClearAllPoints()
		for _, pt in ipairs(s.portPoints) do
			local point, rel, relPoint, x, y = unpack(pt)
			portrait:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
		end
		portrait:SetDrawLayer("OVERLAY")
	end
	
	-- Mirror health bar
	local hb = _G[pre.."HealthBar"]
	if hb and s.hbPoints then
		hb:ClearAllPoints()
		for _, pt in ipairs(s.hbPoints) do
			local point, rel, relPoint, x, y = unpack(pt)
			hb:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
		end
	end
	
	-- Reposition health bar text to center of bar
	local hbText = _G[pre.."HealthBarText"]
	if hbText and hb then
		hbText:ClearAllPoints()
		hbText:SetPoint("CENTER", hb, "CENTER", 0, 0)
	end
	
	-- Mirror mana bar
	local mb = _G[pre.."ManaBar"]
	if mb and s.mbPoints then
		mb:ClearAllPoints()
		for _, pt in ipairs(s.mbPoints) do
			local point, rel, relPoint, x, y = unpack(pt)
			mb:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
		end
	end
	
	-- Reposition mana bar text to center of bar
	local mbText = _G[pre.."ManaBarText"]
	if mbText and mb then
		mbText:ClearAllPoints()
		mbText:SetPoint("CENTER", mb, "CENTER", 0, 0)
	end
	
	-- Mirror name
	local name = _G[pre.."Name"]
	if name and s.namePoints then
		name:ClearAllPoints()
		for _, pt in ipairs(s.namePoints) do
			local point, rel, relPoint, x, y = unpack(pt)
			name:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
		end
		name:SetJustifyH("RIGHT")
	end
	
	-- Mirror flash
	local flash = _G[pre.."Flash"]
	if flash and s.flashCoords then
		local ULx,ULy, LLx,LLy, URx,URy, LRx,LRy = unpack(s.flashCoords)
		flash:SetTexCoord(URx,URy, LRx,LRy, ULx,ULy, LLx,LLy)
		if s.flashPoints then
			flash:ClearAllPoints()
			for _, pt in ipairs(s.flashPoints) do
				local point, rel, relPoint, x, y = unpack(pt)
				flash:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
			end
		end
	end
	
	-- Mirror leader icon
	local leader = _G[pre.."LeaderIcon"]
	if leader and s.leaderPoints then
		leader:ClearAllPoints()
		for _, pt in ipairs(s.leaderPoints) do
			local point, rel, relPoint, x, y = unpack(pt)
			leader:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
		end
	end
	
	-- Mirror master looter
	local ml = _G[pre.."MasterIcon"]
	if ml and s.mlPoints then
		ml:ClearAllPoints()
		for _, pt in ipairs(s.mlPoints) do
			local point, rel, relPoint, x, y = unpack(pt)
			ml:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
		end
	end
	
	-- Mirror PvP icon
	local pvp = _G[pre.."PVPIcon"]
	if pvp and s.pvpPoints then
		pvp:ClearAllPoints()
		for _, pt in ipairs(s.pvpPoints) do
			local point, rel, relPoint, x, y = unpack(pt)
			pvp:SetPoint(MirrorPoint(point), rel, MirrorPoint(relPoint), -(x or 0), y or 0)
		end
	end
	
	partyMirrored[index] = true
end

-- Restore party frame to original state
local function RestorePartyFrame(index)
	local pre = "PartyMemberFrame"..index
	local frame = _G[pre]
	local s = partyOrigState[index]
	if not frame or not s then return end
	
	-- Restore texture
	local tex = _G[pre.."Texture"]
	if tex and s.texCoords then
		tex:SetTexCoord(unpack(s.texCoords))
		tex:ClearAllPoints()
		for _, pt in ipairs(s.texPoints) do
			tex:SetPoint(unpack(pt))
		end
	end
	
	-- Restore portrait
	local portrait = _G[pre.."Portrait"]
	if portrait and s.portPoints then
		portrait:ClearAllPoints()
		for _, pt in ipairs(s.portPoints) do
			portrait:SetPoint(unpack(pt))
		end
		if s.portLayer then portrait:SetDrawLayer(s.portLayer) end
	end
	
	-- Restore health bar
	local hb = _G[pre.."HealthBar"]
	if hb and s.hbPoints then
		hb:ClearAllPoints()
		for _, pt in ipairs(s.hbPoints) do
			hb:SetPoint(unpack(pt))
		end
	end
	
	-- Restore health bar text
	local hbText = _G[pre.."HealthBarText"]
	if hbText and s.hbTextPoints then
		hbText:ClearAllPoints()
		for _, pt in ipairs(s.hbTextPoints) do
			hbText:SetPoint(unpack(pt))
		end
	end
	
	-- Restore mana bar
	local mb = _G[pre.."ManaBar"]
	if mb and s.mbPoints then
		mb:ClearAllPoints()
		for _, pt in ipairs(s.mbPoints) do
			mb:SetPoint(unpack(pt))
		end
	end
	
	-- Restore mana bar text
	local mbText = _G[pre.."ManaBarText"]
	if mbText and s.mbTextPoints then
		mbText:ClearAllPoints()
		for _, pt in ipairs(s.mbTextPoints) do
			mbText:SetPoint(unpack(pt))
		end
	end
	
	-- Restore name
	local name = _G[pre.."Name"]
	if name and s.namePoints then
		name:ClearAllPoints()
		for _, pt in ipairs(s.namePoints) do
			name:SetPoint(unpack(pt))
		end
		name:SetJustifyH(s.nameJustify or "LEFT")
	end
	
	-- Restore flash
	local flash = _G[pre.."Flash"]
	if flash and s.flashCoords then
		flash:SetTexCoord(unpack(s.flashCoords))
		if s.flashPoints then
			flash:ClearAllPoints()
			for _, pt in ipairs(s.flashPoints) do
				flash:SetPoint(unpack(pt))
			end
		end
	end
	
	-- Restore leader icon
	local leader = _G[pre.."LeaderIcon"]
	if leader and s.leaderPoints then
		leader:ClearAllPoints()
		for _, pt in ipairs(s.leaderPoints) do
			leader:SetPoint(unpack(pt))
		end
	end
	
	-- Restore master looter
	local ml = _G[pre.."MasterIcon"]
	if ml and s.mlPoints then
		ml:ClearAllPoints()
		for _, pt in ipairs(s.mlPoints) do
			ml:SetPoint(unpack(pt))
		end
	end
	
	-- Restore PvP icon
	local pvp = _G[pre.."PVPIcon"]
	if pvp and s.pvpPoints then
		pvp:ClearAllPoints()
		for _, pt in ipairs(s.pvpPoints) do
			pvp:SetPoint(unpack(pt))
		end
	end
	
	partyMirrored[index] = false
end

local function ApplyMirrorSetting()
	-- FIX: NewPartyFrame uses custom textures that break when mirrored.
	-- Skip party frame mirroring if NPF is active to avoid garbled visuals.
	if _nufK and _nufK.IsNewPartyFrameActive and _nufK.IsNewPartyFrameActive() then
		-- Still allow un-mirroring (restore) in case it was enabled before NPF
		if not PartyTargetsDB.mirror then
			for i = 1, MAX_PARTY_MEMBERS do
				RestorePartyFrame(i)
			end
		end
		return;
	end
	for i = 1, MAX_PARTY_MEMBERS do
		if PartyTargetsDB.mirror then
			ApplyMirrorToParty(i)
		else
			RestorePartyFrame(i)
		end
	end
end

-- FIX PERF: Reusable delay timer (before: created a new frame per call)
-- Uses a pending-flags approach so multiple OnShow hooks don't overwrite each other.
-- When the timer fires, it applies mirror to ALL pending frames at once.
local _delayTimer = CreateFrame("Frame")
_delayTimer:Hide()
local _delayElapsed = 0
local _delayTarget = 0
local _delayPendingMirror = {}  -- indices pending mirror re-apply
local _delayPendingFull = false -- full ApplyMirrorSetting pending

_delayTimer:SetScript("OnUpdate", function(self, dt)
	_delayElapsed = _delayElapsed + dt
	if _delayElapsed >= _delayTarget then
		self:Hide()
		if _delayPendingFull then
			_delayPendingFull = false
			wipe(_delayPendingMirror)
			ApplyMirrorSetting()
		else
			for idx in pairs(_delayPendingMirror) do
				if PartyTargetsDB.mirror then
					ApplyMirrorToParty(idx)
				end
			end
			wipe(_delayPendingMirror)
		end
	end
end)

-- Queue a full mirror setting apply (from events)
local function DelayedApplyMirrorSetting(delay)
	_delayPendingFull = true
	_delayTarget = delay
	_delayElapsed = 0
	_delayTimer:Show()
end

-- Queue a single frame mirror apply (from OnShow hooks)
local function DelayedApplyMirrorToFrame(delay, index)
	_delayPendingMirror[index] = true
	_delayTarget = delay
	_delayElapsed = 0
	_delayTimer:Show()
end

local mirrorFrame = CreateFrame("Frame")
mirrorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mirrorFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
mirrorFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
mirrorFrame:SetScript("OnEvent", function(self, event)
	EnsureDefaults()
	DelayedApplyMirrorSetting(0.1)
end)

for i = 1, MAX_PARTY_MEMBERS do
	local frame = _G["PartyMemberFrame"..i]
	if frame then
		frame:HookScript("OnShow", function()
			if PartyTargetsDB.mirror then
				DelayedApplyMirrorToFrame(0.05, i)
			end
		end)
	end
end

----------------------------------------------------
-- Global API (used by Options.lua)
----------------------------------------------------
function PartyTargets_ApplyMirrorSetting()
	ApplyMirrorSetting()
end

function PartyTargets_AnchorToParty()
	AnchorAllToParty()
end

-- Recalcula el offset compartido a partir de donde quedo UN marco, y
-- reancla los cuatro.
--
-- Es lo mismo que hace OnDragStop, pero expuesto para que el modo mover
-- global de NUF lo pueda usar: ese arrastra el frame por su cuenta y
-- despues necesita que el modulo se entere.
function PartyTargets_AnchorFromFrame(frame)
	if not frame or not PartyTargetsDB.anchor then return end
	local offX, offY = ComputeAnchorOffset(frame)
	PartyTargetsDB.anchorX = offX
	PartyTargetsDB.anchorY = offY
	AnchorAllToParty(offX, offY)
end

function PartyTargets_LoadFreePositions()
	for i = 1, MAX_PARTY_MEMBERS do
		local f = _G["PartyTargetFrame"..i]
		if f then
			if not LoadPosition(f) then
				AnchorAllToParty()
				return
			end
		end
	end
end

function PartyTargets_ApplyAnchorSetting()
	if PartyTargetsDB.anchor then
		AnchorAllToParty()
	else
		PartyTargets_LoadFreePositions()
	end
end

-- Cambiar la escala NO tiene que mover el marco.
--
-- El offset guardado esta en el espacio del marco de objetivo, o sea que
-- depende de su escala: al pasar de 1.0 a 1.5, el mismo numero pasa a valer
-- un 50% mas de pixeles reales y los marcos se corrian solos.
--
-- Se anota donde estaba el primero EN PANTALLA, se escala, y se recalcula
-- el offset para dejarlo donde estaba. La escala cambia el tamaño; la
-- posicion la decide el usuario arrastrando, no el slider.
function PartyTargets_ApplyScale()
	local s = GetScale()

	local ref = _G["PartyTargetFrame1"]
	local keepL, keepT
	if ref and ref:GetLeft() and ref:GetTop() then
		local es = ref:GetEffectiveScale() or 1
		keepL, keepT = ref:GetLeft() * es, ref:GetTop() * es
	end

	for i = 1, MAX_PARTY_MEMBERS do
		local f = _G["PartyTargetFrame"..i]
		if f then f:SetScale(s) end
	end

	if keepL and PartyTargetsDB.anchor then
		local parent = _G["PartyMemberFrame1"]
		if parent and parent:GetLeft() and parent:GetBottom() then
			local es = ref:GetEffectiveScale();    if not es or es == 0 then es = 1 end
			local ps = parent:GetEffectiveScale(); if not ps or ps == 0 then ps = 1 end
			local offX = (keepL - parent:GetLeft()   * ps) / es
			local offY = (keepT - parent:GetBottom() * ps) / es
			PartyTargetsDB.anchorX, PartyTargetsDB.anchorY = offX, offY
			AnchorAllToParty(offX, offY)
		end
	end
end

----------------------------------------------------
-- Slash Commands
----------------------------------------------------
SLASH_PARTYTARGETS1 = "/ptarget"
SLASH_PARTYTARGETS2 = "/partytargets"
SlashCmdList["PARTYTARGETS"] = function(msg)
	msg = strlower(strtrim(msg))
	if msg == "config" or msg == "" then
		if PartyTargetsOptions then
			if PartyTargetsOptions:IsShown() then
				PartyTargetsOptions:Hide()
			else
				PartyTargetsOptions:Show()
			end
		end
	elseif msg == "reset" then
		PartyTargetsDB = {}
		ReloadUI()
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PartyTargets:|r /ptarget - Open config panel")
	end
end

----------------------------------------------------
-- PART 2: Party Target Frames (ToT style)
----------------------------------------------------

local NAME_MAX_CHARS = 12  -- max characters before truncation at font size 7

local function TruncateName(fontString)
	local fullName = fontString:GetText()
	if not fullName or fullName == "" then return end
	if string.len(fullName) > NAME_MAX_CHARS then
		fontString:SetText(string.sub(fullName, 1, NAME_MAX_CHARS).."...")
	end
end

local function StyleNameText(self)
	local nameText = _G[self:GetName().."Name"]
	if not nameText then return end

	-- Mostrar u ocultar va ACA y no en un sitio aparte porque esta funcion
	-- es el unico punto por el que pasa el nombre, y ya la llaman tanto
	-- OnLoad como OnEvent. Cualquier otro lugar habria quedado a merced de
	-- que Blizzard reescriba el texto en la proxima actualizacion.
	--
	-- Se oculta el FontString, no se le pone texto vacio: con SetText("")
	-- el nombre reaparece solo en cuanto UnitFrame_Update lo repinta.
	if PartyTargetsDB.hideName then
		nameText:Hide()
		return
	end
	nameText:Show()

	-- El estilo Square le pone su propia fuente y posicion. Si aca se
	-- forzara la de Classic, cambiar de objetivo se la pisaria.
	if PartyTargetsDB.style ~= "Square" then
		nameText:SetFont("Fonts\\FRIZQT__.TTF", 7)
		nameText:SetTextColor(1.0, 0.82, 0)
		nameText:SetShadowOffset(0.6, -0.6)
		nameText:SetShadowColor(0, 0, 0, 0.9)
	end
	TruncateName(nameText)
end

-- Reaplicar a los cuatro, para el checkbox del panel.
function PartyTargets_ApplyNameVisibility()
	for i = 1, MAX_PARTY_MEMBERS do
		local f = _G["PartyTargetFrame"..i]
		if f then StyleNameText(f) end
	end
end

addon.OnLoad = function(self)
	EnsureDefaults()
	
	self:SetAttribute("unit", "party" .. self:GetID() .. "target")
	self:SetAttribute("type", "party" .. self:GetID() .. "target")
	RegisterUnitWatch(self)
	
	self.statusCounter = 0
	self.statusSign = -1
	self.unitHPPercent = 1
	
	addon.HideBarText(self)
	addon.UpdateMember(self)
	
	MakeDraggable(self)
	
	-- Apply scale
	self:SetScale(GetScale())
	
	-- If anchored, apply saved anchor offset; otherwise load free position
	if PartyTargetsDB.anchor then
		local parent = _G["PartyMemberFrame"..self:GetID()]
		if parent and (PartyTargetsDB.anchorX or PartyTargetsDB.anchorY) then
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", parent, "BOTTOMLEFT",
				PartyTargetsDB.anchorX or DEFAULT_ANCHOR_X,
				PartyTargetsDB.anchorY or DEFAULT_ANCHOR_Y)
		end
	else
		LoadPosition(self)
	end
	
	-- Register Events
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("PARTY_MEMBER_ENABLE")
	self:RegisterEvent("PARTY_MEMBER_DISABLE")
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("UNIT_FACTION")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UNIT_PVP_UPDATE")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH")
	self:RegisterEvent("UNIT_MANA")
	self:RegisterEvent("UNIT_ENERGY")
	self:RegisterEvent("UNIT_FOCUS")
	self:RegisterEvent("UNIT_RAGE")
	self:RegisterEvent("UNIT_RUNIC_POWER")
	
	local showmenu = function()
		ToggleDropDownMenu(1, nil, _G["PartyTargetFrame" .. self:GetID() .. "DropDown"], self:GetName(), 47, 15)
	end
	SecureUnitButton_OnLoad(self, "party" .. self:GetID() .. "target", showmenu)
	
	-- Name styling
	StyleNameText(self)
end

addon.HideBarText = function(self)
	local prefix = self:GetName()
	local texts = {
		prefix.."HealthBarText",
		prefix.."HealthBarTextLeft",
		prefix.."HealthBarTextRight",
		prefix.."ManaBarText",
		prefix.."ManaBarTextLeft",
		prefix.."ManaBarTextRight",
	}
	for _, name in ipairs(texts) do
		local t = _G[name]
		if t then
			t:Hide()
			t:SetText("")
			t:SetAlpha(0)
		end
	end
end

addon.OnEvent = function(self, e, ...)
	UnitFrame_OnEvent(self, e, ...)
	addon.HideBarText(self)
	
	if (e == "VARIABLES_LOADED") then
		EnsureDefaults()
		self:SetScale(GetScale())
		if PartyTargetsDB.anchor then
			-- Apply saved anchor offset
			local parent = _G["PartyMemberFrame"..self:GetID()]
			if parent then
				self:ClearAllPoints()
				self:SetPoint("TOPLEFT", parent, "BOTTOMLEFT",
					PartyTargetsDB.anchorX or DEFAULT_ANCHOR_X,
					PartyTargetsDB.anchorY or DEFAULT_ANCHOR_Y)
			end
		else
			LoadPosition(self)
		end
	end
	
	local unit = select(1, ...)
	if (e == "PLAYER_ENTERING_WORLD") then
		if (GetPartyMember(self:GetID())) then
			addon.UpdateMember(self)
			return
		end
	end
	
	if (e == "PARTY_MEMBERS_CHANGED" or e == "UNIT_TARGET") then
		addon.UpdateMember(self)
		return
	end
	
	if (unit) then
		for i = 1, MAX_PARTY_MEMBERS, 1 do
			if (unit == "party" .. i .. "target" and UnitExists("party"..i.."target")) then
				addon.UpdateMember(self)
			end
		end
	else
		addon.UpdateMember(self)
	end
end

addon.UpdateMember = function(self)
	if (GetPartyMember(self:GetID()) and UnitExists("party"..self:GetID().."target")) then
		UnitFrameManaBar_UpdateType(self.manabar)
		UnitFrame_Update(self)
		addon.HideBarText(self)
		StyleNameText(self)
	end
end

addon.UpdateMemberHealth = function(self, e)
	if ((self.unitHPPercent > 0) and (self.unitHPPercent <= 0.2)) then
		local alpha = 255
		local counter = self.statusCounter + e
		local sign = self.statusSign
		
		if (counter > 0.5) then
			sign = -sign
			self.statusSign = sign
		end
		
		counter = mod(counter, 0.5)
		self.statusCounter = counter
		
		if (sign == 1) then
			alpha = (127 + (counter * 256)) / 255
		else
			alpha = (255 - (counter * 256)) / 255
		end
		
		_G[self:GetName().."Portrait"]:SetAlpha(alpha)
	end
end

addon.OnUpdate = function(self, e)
	addon.UpdateMemberHealth(self, e)
end

addon.HealthCheck = function(self, value)
	local UnitHealth, UnitHealthMax = self:GetMinMaxValues()
	local UnitHealthCurrent = self:GetValue()
	
	if (UnitHealthMax > 0) then
		self:GetParent().unitHPPercent = UnitHealthCurrent / UnitHealthMax
	else
		self:GetParent().unitHPPercent = 0
	end
	
	_G[self:GetParent():GetName() .. "Portrait"]:SetVertexColor(1, 1, 1, 1)
	addon.HideBarText(self:GetParent())
end

addon.DropDownOnLoad = function(self)
	UIDropDownMenu_Initialize(self, addon.DropDownInitialize, "MENU")
end

addon.DropDownInitialize = function(self)
	-- OJO: antes esto era "UIDROPDOWNMENU_OPEN_MENU or self".
	--
	-- Esa global apunta al menu desplegable que este abierto en ese momento,
	-- que NO tiene por que ser el nuestro: si el jugador abria el menu de un
	-- nombre del chat, era FriendsDropDown. Y UnitPopup_ShowMenu escribe
	-- .unit y .name en el frame que recibe, asi que le pisabamos al menu del
	-- chat su unidad con "partyNtarget".
	--
	-- Consecuencia: las opciones que dependen de resolver la unidad por
	-- nombre (Target y Report player Away) desaparecian de ese menu.
	--
	-- La funcion de inicializacion ya recibe el dropdown correcto en self.
	local parent = self and self:GetParent();
	if not (parent and parent.GetID) then return; end

	local id = parent:GetID();
	if not id or id < 1 then return; end

	UnitPopup_ShowMenu(self, "TARGET", "party" .. id .. "target")
end