-- =========================================================
-- Un solo dueño por posicion: "Mover todo" no le pisa la posicion a los
-- modulos que guardan la suya (Sacred Shield, Seduction, los timers de
-- arena, la gargola...).
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_ownpos.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
local GU = ROOT .. "/Nidhaus_UnitFrames/Modules2/GlobalUnlock.lua"

local mt = {}
mt.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() return nil end end end
local FX = { TOPLEFT = 0, LEFT = 0, BOTTOMLEFT = 0, TOP = .5, CENTER = .5, BOTTOM = .5, TOPRIGHT = 1, RIGHT = 1, BOTTOMRIGHT = 1 }
local FY = { TOPLEFT = 1, TOP = 1, TOPRIGHT = 1, LEFT = .5, CENTER = .5, RIGHT = .5, BOTTOMLEFT = 0, BOTTOM = 0, BOTTOMRIGHT = 0 }
local SW, SH = 1600, 1000
local frames = {}
local function Frame(kind, name, parent)
	local f = setmetatable({ _kind = kind, _name = name, _parent = parent, _w = 100, _h = 40,
		_scale = 1, _pts = {}, _scripts = {}, _shown = true }, mt)
	function f:GetName() return self._name end
	function f:GetParent() return self._parent end
	function f:SetParent(p) self._parent = p end
	function f:SetScale(s) self._scale = s end
	function f:GetScale() return self._scale end
	function f:GetEffectiveScale() local s, p = self._scale, self._parent; while p do s = s * (p._scale or 1); p = p._parent end return s end
	function f:SetSize(w, h) self._w, self._h = w, h end
	function f:SetWidth(w) self._w = w end
	function f:SetHeight(h) self._h = h end
	function f:GetWidth() return self._w end
	function f:GetHeight() return self._h end
	function f:ClearAllPoints() self._pts = {} end
	function f:SetPoint(p, rel, rp, x, y)
		if type(rel) == "string" then rel = _G[rel] end
		if type(rel) == "number" then rel, rp, x, y = self._parent, p, rel, rp end
		self._pts[#self._pts + 1] = { p, rel or self._parent, rp or p, x or 0, y or 0 }
		if self._onSetPoint then self._onSetPoint(self) end
	end
	function f:SetAllPoints(r) self._pts = { { "TOPLEFT", r or self._parent, "TOPLEFT", 0, 0 } } end
	function f:GetPoint(i) local q = self._pts[i or 1]; if q then return q[1], q[2], q[3], q[4], q[5] end end
	function f:GetNumPoints() return #self._pts end
	function f:_screen()
		if self == UIParent then return 0, 0 end
		local q = self._pts[1]
		if not q then return nil end
		local rl, rb = q[2]:_screen()
		if not rl then return nil end
		local rw, rh = q[2]._w * q[2]:GetEffectiveScale(), q[2]._h * q[2]:GetEffectiveScale()
		local es = self:GetEffectiveScale()
		local ax, ay = rl + FX[q[3]] * rw + q[4] * es, rb + FY[q[3]] * rh + q[5] * es
		return ax - FX[q[1]] * self._w * es, ay - FY[q[1]] * self._h * es
	end
	function f:GetLeft() local l = self:_screen(); return l and l / self:GetEffectiveScale() end
	function f:GetBottom() local _, b = self:_screen(); return b and b / self:GetEffectiveScale() end
	function f:GetTop() local b = self:GetBottom(); return b and b + self._h end
	function f:GetRight() local l = self:GetLeft(); return l and l + self._w end
	function f:SetScript(k, fn) self._scripts[k] = fn end
	function f:GetScript(k) return self._scripts[k] end
	function f:HookScript(k, fn) local o = self._scripts[k]; self._scripts[k] = function(...) if o then o(...) end fn(...) end end
	function f:Show() self._shown = true end
	function f:Hide() self._shown = false end
	function f:IsShown() return self._shown end
	function f:IsVisible() return self._shown end
	function f:IsProtected() return false end
	function f:CreateTexture() return Frame("Texture", nil, self) end
	function f:CreateFontString() return Frame("FontString", nil, self) end
	if name then _G[name] = f end
	frames[#frames + 1] = f
	return f
end
UIParent = Frame("Frame", "UIParent"); UIParent._w, UIParent._h = SW, SH
function CreateFrame(kind, name, parent) return Frame(kind, name, parent or UIParent) end
-- hooksecurefunc sobre un metodo: lo usamos para detectar el candado
local hooked = {}
function hooksecurefunc(a, b, c)
	if type(a) == "table" then hooked[a] = (hooked[a] or 0) + 1; local o = a[b]; a[b] = function(...) local r = { o(...) }; c(...); return unpack(r) end
	end
end
function InCombatLockdown() return false end
function UnitClass() return "Hunter", "HUNTER" end
function UnitExists() return true end
local cx, cy = 0, 0
function GetCursorPosition() return cx, cy end
function GetTime() return 0 end
function IsControlKeyDown() return false end
function GetCVar() return "0" end
SlashCmdList = {}; UIPARENT_MANAGED_FRAME_POSITIONS = {}
NidhausUnitFramesDB = {}

-- El marco del timer del tubo de Dalaran, con SU propio guardado (lo mismo
-- que hace el modulo de verdad: guarda en NidhausUnitFramesDB.timerPos).
local pipe = Frame("Frame", "NUF_DalaranPipeTimer", UIParent)
pipe:SetSize(120, 42)
pipe:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
local ownSaves = 0
pipe:SetScript("OnDragStop", function(self)
	local point, _, relativePoint, x, y = self:GetPoint()
	if not point then return end
	NidhausUnitFramesDB.timerPos = NidhausUnitFramesDB.timerPos or {}
	NidhausUnitFramesDB.timerPos.pipe = { point = point, relativePoint = relativePoint, x = x, y = y }
	ownSaves = ownSaves + 1
end)

local K = setmetatable({}, { __index = function(t, k) if type(k) == "string" and k:match("^_") then return nil end return function() return nil end end })
K.AfterCombat = function() return false end
local C = { MoveGridStep = 0 }
local L = setmetatable({}, { __index = function() return nil end })
assert(loadfile(GU))("Nidhaus_UnitFrames", { K, C, L })

local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end

-- abrir el modo mover y encontrar el recuadro del timer
pcall(K.SetGlobalUnlock, true, "all")
local ov
for _, f in ipairs(frames) do if f.entry and f.entry.key == "DalaranPipe" and f._scripts.OnDragStart then ov = f end end
check(ov ~= nil, "hay recuadro para el timer del tubo")
if ov then
	ov._scripts.OnDragStart(ov)
	cx, cy = 240, -120
	ov._scripts.OnUpdate(ov, 0.02)
	local dropL, dropB = pipe:_screen()
	ov._scripts.OnDragStop(ov)

	check(ownSaves == 1, "al soltarlo guarda SU modulo (" .. ownSaves .. " veces)")
	local own = NidhausUnitFramesDB.timerPos and NidhausUnitFramesDB.timerPos.pipe
	check(own and own.point, "la posicion quedo en la tabla del modulo")
	local gp = NidhausUnitFramesDB.globalPos and NidhausUnitFramesDB.globalPos.DalaranPipe
	check(not (gp and gp.point), "y NO quedo en globalPos")
	check(rawget(pipe, "NUFPoint") == nil, "sin candado sobre SetPoint")

	-- RELOGUEO: el modulo repone lo suyo y "Mover todo" no lo pisa
	pipe:ClearAllPoints()
	pipe:SetPoint(own.point, UIParent, own.relativePoint, own.x, own.y)
	local l1, b1 = pipe:_screen()
	K.RestoreGlobalPositions()
	local l2, b2 = pipe:_screen()
	check(math.abs(l2 - l1) < 0.01 and math.abs(b2 - b1) < 0.01,
		"al entrar, Mover todo no le toca la posicion")
	check(math.abs(l2 - dropL) < 0.01, "y es donde lo soltaste")

	-- el Reset de su modulo manda: borra su tabla y lo reancla
	NidhausUnitFramesDB.timerPos.pipe = nil
	pipe:ClearAllPoints(); pipe:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	local l3 = pipe:_screen()
	K.RestoreGlobalPositions()
	local l4 = pipe:_screen()
	check(math.abs(l4 - l3) < 0.01, "despues del Reset del modulo no vuelve la vieja")
end

-- un marco SIN tabla propia sigue como siempre (lo guarda Mover todo)
local tgt = _G.TargetFrame or Frame("Frame", "TargetFrame", UIParent)
if not tgt._pts[1] then tgt:SetPoint("CENTER", UIParent, "CENTER", 100, 100) end
local ov2
for _, f in ipairs(frames) do if f.entry and f.entry.key == "Target" and f._scripts.OnDragStart then ov2 = f end end
if ov2 then
	ov2._scripts.OnDragStart(ov2)
	cx, cy = 60, 60
	ov2._scripts.OnUpdate(ov2, 0.02)
	ov2._scripts.OnDragStop(ov2)
	local gp = NidhausUnitFramesDB.globalPos and NidhausUnitFramesDB.globalPos.Target
	check(gp and gp.point, "sin tabla propia: lo sigue guardando Mover todo")
	check(rawget(tgt, "NUFPoint") ~= nil, "y le pone su candado")
end
print(("PASS %d  FAIL %d"):format(pass, fail))
