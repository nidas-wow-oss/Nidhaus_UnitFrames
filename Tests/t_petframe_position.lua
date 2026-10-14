-- =========================================================
-- Marco de la mascota: se mueve, se guarda y vuelve al mismo lugar al reloguear
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_petframe_position.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
local FILE = ROOT .. "/Nidhaus_UnitFrames/Modules2/GlobalUnlock.lua"
local mt = {}
local function Magic() return setmetatable({}, mt) end
mt.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() return nil end end end
mt.__call = function() return nil end
-- geometria: punto -> fraccion del ancho/alto
local FX = { TOPLEFT = 0, LEFT = 0, BOTTOMLEFT = 0, TOP = .5, CENTER = .5, BOTTOM = .5, TOPRIGHT = 1, RIGHT = 1, BOTTOMRIGHT = 1 }
local FY = { TOPLEFT = 1, TOP = 1, TOPRIGHT = 1, LEFT = .5, CENTER = .5, RIGHT = .5, BOTTOMLEFT = 0, BOTTOM = 0, BOTTOMRIGHT = 0 }
local SW, SH = 1600, 1000
local frames = {}
local function Frame(kind, name, parent)
	local f = setmetatable({ _kind = kind, _name = name, _parent = parent, _w = 100, _h = 40, _scale = 1, _pts = {}, _scripts = {}, _shown = true }, mt)
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
	end
	function f:SetAllPoints(r) self._pts = { { "TOPLEFT", r, "TOPLEFT", 0, 0 } } end
	function f:GetPoint(i) local q = self._pts[i or 1]; if q then return q[1], q[2], q[3], q[4], q[5] end end
	function f:GetNumPoints() return #self._pts end
	-- en pixeles de pantalla
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
	function f:GetCenter() local l, b = self:GetLeft(), self:GetBottom(); if l then return l + self._w / 2, b + self._h / 2 end end
	function f:SetScript(k, fn) self._scripts[k] = fn end
	function f:GetScript(k) return self._scripts[k] end
	function f:HookScript(k, fn) local o = self._scripts[k]; self._scripts[k] = function(...) if o then o(...) end fn(...) end end
	function f:Show() self._shown = true end
	function f:Hide() self._shown = false end
	function f:IsShown() return self._shown end
	function f:IsVisible() return self._shown end
	function f:IsProtected() return self._protected end
	function f:CreateTexture() return Frame("Texture", nil, self) end
	function f:CreateFontString() return Frame("FontString", nil, self) end
	if name then _G[name] = f end
	frames[#frames + 1] = f
	return f
end
UIParent = Frame("Frame", "UIParent"); UIParent._w, UIParent._h = SW, SH
function CreateFrame(kind, name, parent) return Frame(kind, name, parent or UIParent) end
local hooks = {}
function hooksecurefunc(a, b, c) if type(a) == "table" then local o = a[b]; a[b] = function(...) local r = { o(...) }; c(...); return unpack(r) end end end
local combat = false
function InCombatLockdown() return combat end
function UnitClass() return "Hunter", "HUNTER" end
function UnitExists() return true end
local cx, cy = 0, 0
function GetCursorPosition() return cx, cy end
function GetTime() return 0 end
function IsControlKeyDown() return false end
function GetCVar() return "0" end
SlashCmdList = {}; UIPARENT_MANAGED_FRAME_POSITIONS = {}
-- PlayerFrame en el medio de la pantalla (NUF lo mueve), PetFrame colgando de el
PlayerFrame = Frame("Frame", "PlayerFrame", UIParent); PlayerFrame:SetSize(232, 100)
PlayerFrame:SetPoint("CENTER", UIParent, "CENTER", -250, 150)
PetFrame = Frame("Button", "PetFrame", UIParent); PetFrame:SetSize(128, 53); PetFrame._protected = true
PetFrame:SetScale(1.5)
PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 80, -60)
local afterCombat = {}
local K = setmetatable({}, { __index = function(t, k) if type(k) == "string" and k:match("^_") then return nil end return function() return nil end end })
K.AfterCombat = function(key, fn) if not combat then return false end afterCombat[key] = fn; return true end
local C = { MoveGridStep = 0, PetFrameScale = 1.5 }
local L = setmetatable({}, { __index = function() return nil end })
NidhausUnitFramesDB = {}
assert(loadfile(FILE))("Nidhaus_UnitFrames", { K, C, L })
local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
-- abrir "Move" de la mascota
local ok, err = pcall(K.SetGlobalUnlock, true, "pet")
if not ok then print("SetGlobalUnlock:", err) end
local ov
for _, f in ipairs(frames) do if f.entry and f.entry.key == "Pet" and f._scripts.OnDragStart then ov = f end end
check(ov ~= nil, "recuadro de la mascota")
if ov then
	ov._scripts.OnDragStart(ov)
	cx, cy = 300, -200        -- arrastrar 300 px a la derecha y 200 abajo (pantalla)
	ov._scripts.OnUpdate(ov, 0.02)
	local dropL, dropB = PetFrame:_screen()
	ov._scripts.OnDragStop(ov)
	local l2, b2 = PetFrame:_screen()
	check(math.abs(l2 - dropL) < 0.01 and math.abs(b2 - dropB) < 0.01, "al soltar se queda donde lo dejaste")
	local pos = NidhausUnitFramesDB.globalPos and NidhausUnitFramesDB.globalPos.Pet
	check(pos and pos.point, "posicion guardada")
	-- RELOG: Blizzard la vuelve a colgar de PlayerFrame, y NUF repone
	PetFrame:ClearAllPoints(); PetFrame.NUFPoint = nil
	PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 80, -60)
	K.RestoreGlobalPositions()
	local l3, b3 = PetFrame:_screen()
	check(math.abs(l3 - dropL) < 0.01 and math.abs(b3 - dropB) < 0.01,
		("al reloguear vuelve al mismo lugar (%.0f,%.0f vs %.0f,%.0f)"):format(l3, b3, dropL, dropB))
	-- RELOG EN COMBATE: se repone al salir
	PetFrame:ClearAllPoints(); PetFrame.NUFPoint = nil
	PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 80, -60)
	combat = true
	K.RestoreGlobalPositions()
	local l4 = PetFrame:_screen()
	check(math.abs(l4 - dropL) > 1, "en combate no se toca (marco protegido)")
	combat = false
	for _, fn in pairs(afterCombat) do fn() end
	local l5, b5 = PetFrame:_screen()
	check(math.abs(l5 - dropL) < 0.01 and math.abs(b5 - dropB) < 0.01, "al salir del combate se repone")
end
print(("PASS %d  FAIL %d"):format(pass, fail))

