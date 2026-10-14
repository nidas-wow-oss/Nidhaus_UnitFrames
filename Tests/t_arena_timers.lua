-- =========================================================
-- Timers de arena: boton Mover (sin Alt), Fijar y /nuftimers
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_arena_timers.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
-- Los modulos de arena viven en el addon a pedido.
local DIR = ROOT .. "/Nidhaus_UnitFrames_Arena/Modules2"
local mt = {}
mt.__index = function(t, k) if type(k) == "string" and k:match("^%u") then return function() return nil end end end
local frames = {}
local function Obj(kind, name, parent)
	local o = setmetatable({ _kind = kind, _name = name, _parent = parent, _shown = true, _scripts = {}, _ev = {}, _w = 50, _h = 20 }, mt)
	function o:GetName() return self._name end
	function o:Show() self._shown = true end
	function o:Hide() self._shown = false end
	function o:IsShown() return self._shown end
	function o:IsVisible() return self._shown end
	function o:SetScript(k, f) self._scripts[k] = f end
	function o:GetScript(k) return self._scripts[k] end
	function o:HookScript(k, f) local p = self._scripts[k]; self._scripts[k] = function(...) if p then p(...) end f(...) end end
	function o:RegisterEvent(e) self._ev[e] = true end
	function o:UnregisterEvent(e) self._ev[e] = nil end
	function o:UnregisterAllEvents() self._ev = {} end
	function o:StartMoving() self._moving = true end
	function o:StopMovingOrSizing() self._moving = false end
	function o:SetText(t) self._text = t end
	function o:GetText() return self._text end
	function o:SetFormattedText(f, ...) self._text = string.format(f, ...) end
	function o:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
	function o:CreateTexture() return Obj("Texture", nil, self) end
	function o:CreateFontString() return Obj("FontString", nil, self) end
	function o:SetSize(w, h) self._w, self._h = w, h end
	function o:GetWidth() return self._w end
	function o:GetHeight() return self._h end
	function o:Enable() self._enabled = true end
	function o:GetFrameLevel() return 3 end
	function o:SetFrameLevel(v) self._level = v end
	function o:SetAllPoints() end
	function o:Disable() self._enabled = false end
	if name then _G[name] = o end
	frames[#frames + 1] = o
	return o
end
UIParent = Obj("Frame", "UIParent")
function CreateFrame(kind, name, parent) return Obj(kind, name, parent) end
local alt = false
function IsAltKeyDown() return alt end
function IsShiftKeyDown() return false end
function InCombatLockdown() return false end
function GetTime() return 1000 end
local _ObjLevel = 1
function IsInInstance() return false, "none" end
function UnitClass() return "Paladin", "PALADIN" end
function GetSpellInfo(id) return "Spell" .. tostring(id), nil, "Icon" end
function IsLoggedIn() return true end
function hooksecurefunc() end
function GetCVar() return "0" end
SlashCmdList = {}; NidhausUnitFramesDB = {}
local K = setmetatable({}, { __index = function(t, k) if type(k) == "string" and k:match("^_") then return nil end return nil end })
local C = {}
local L = setmetatable({}, { __index = function() return nil end })
K.RegisterConfigEvent = function() end
K.RegisterScalable = function() end
K.RegisterModuleZones = function() end
K.AfterCombat = function() return false end
K.IsModuleEnabled = function() return true end
K.RegisterModule = function() end
K.SaveConfig = function(k, v) C[k] = v; return true end
K.SaveConfigSilent = K.SaveConfig
local ns = { K, C, L }
NidhausUnitFramesNS = ns
for _, f in ipairs({ "ArenaCountDown.lua", "ArenaDalaranPipeTimer.lua", "ArenaRoVPillarTimer.lua", "ArenaEndTimer.lua" }) do
	local chunk, err = loadfile(DIR .. "/" .. f)
	if not chunk then print("LOAD FAIL " .. f .. ": " .. tostring(err)) else
		local ok, e = pcall(chunk, "Nidhaus_UnitFrames", ns)
		if not ok then print("RUN FAIL " .. f .. ": " .. tostring(e)) end
	end
end
local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
-- marcos de los cuatro timers: los que tienen OnDragStart
local drags = {}
for _, f in ipairs(frames) do if f._scripts.OnDragStart then drags[#drags + 1] = f end end
check(#drags >= 4, "los cuatro timers se arrastran (" .. #drags .. ")")
-- sin Alt y sin modo mover: no se mueve
for _, f in ipairs(drags) do f._moving = false; f._scripts.OnDragStart(f) end
local moved = 0; for _, f in ipairs(drags) do if f._moving then moved = moved + 1 end end
check(moved == 0, "sin Alt no se mueven (" .. moved .. ")")
-- con el boton "Mover"
check(type(K.SetArenaTimersMoving) == "function", "existe el modo mover")
if K.SetArenaTimersMoving then
	K.SetArenaTimersMoving(true)
	check(K.IsArenaTimersMoving(), "modo mover prendido")
	local shown = 0; for _, f in ipairs(drags) do if f._shown then shown = shown + 1 end end
	check(shown == #drags, "los timers se ven todos (" .. shown .. "/" .. #drags .. ")")
	for _, f in ipairs(drags) do f._moving = false; f._scripts.OnDragStart(f) end
	moved = 0; for _, f in ipairs(drags) do if f._moving then moved = moved + 1 end end
	check(moved == #drags, "se arrastran SIN Alt (" .. moved .. "/" .. #drags .. ")")
	-- el de pilares al llegar a 0 no los apaga: los reinicia
	K.StopArenaTimerTests()
	check(K.IsArenaTimersMoving(), "al terminar un ciclo sigue en modo mover")
	shown = 0; for _, f in ipairs(drags) do if f._shown then shown = shown + 1 end end
	check(shown == #drags, "y siguen a la vista (" .. shown .. ")")
	-- fijar
	K.SetArenaTimersMoving(false)
	check(not K.IsArenaTimersMoving(), "fijar: modo mover apagado")
	shown = 0; for _, f in ipairs(drags) do if f._shown then shown = shown + 1 end end
	check(shown == 0, "fijar: se esconden (" .. shown .. ")")
	for _, f in ipairs(drags) do f._moving = false; f._scripts.OnDragStart(f) end
	moved = 0; for _, f in ipairs(drags) do if f._moving then moved = moved + 1 end end
	check(moved == 0, "fijados ya no se arrastran sin Alt")
	-- Fijado: ni con Alt
	alt = true
	for _, f in ipairs(drags) do f._moving = false; f._scripts.OnDragStart(f) end
	moved = 0; for _, f in ipairs(drags) do if f._moving then moved = moved + 1 end end
	check(moved == 0, "fijado: ni con Alt se mueven (" .. moved .. ")")
	check(NidhausUnitFramesDB.ArenaTimersLocked == true, "el fijado queda guardado")
	alt = false
	-- y al desbloquear vuelve el Alt
	K.SetArenaTimersMoving(true); K.SetArenaTimersMoving(false)
	K.ArenaTimersLocked = false   -- (como si nunca hubiera tocado el boton)
	alt = true
	for _, f in ipairs(drags) do f._shown = true; f._moving = false; f._scripts.OnDragStart(f) end
	moved = 0; for _, f in ipairs(drags) do if f._moving then moved = moved + 1 end end
	check(moved == #drags, "sin fijar, Alt + arrastrar sigue funcionando (" .. moved .. ")")
	alt = false
	-- /nuftimers apaga el modo mover si estaba puesto
	K.SetArenaTimersMoving(true)
	SlashCmdList["NUFARENATIMERS"]()
	check(not K.IsArenaTimersMoving(), "/nuftimers con el modo mover puesto lo apaga")
end
print(("PASS %d  FAIL %d"):format(pass, fail))

