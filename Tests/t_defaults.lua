-- =========================================================
-- Valores de fabrica de DR y DoT, reset de las tablas propias, guardas de comandos
--
-- Se corre desde la raiz del repo:   Tests/run.sh
-- o a mano:                          lua5.1 Tests/t_defaults.lua .
-- =========================================================
local ROOT = (arg[1] or "."):gsub("/+$", "")
local F = ROOT
local pass, fail = 0, 0
local function check(c, m) if c then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. m) end end
-- 1) defaults de DR y DoT
do
	local src = io.open(F .. "/Nidhaus_UnitFrames/Config/ConfigManager.lua"):read("*a")
	local function val(k)
		return src:match("\n%s*" .. k .. "%s*=%s*([^,\n]+)")
	end
	check(val("ArenaDR") == "true", "DR prendido de fabrica")
	check(val("ArenaDRSize") == "25", "DR tamano 25")
	check(val("ArenaDRGrow") == '"LEFT"', "DR crece a la izquierda")
	check(val("ArenaDRBorder") == "false" and val("ArenaDRText") == "false", "DR sin borde ni texto 1/2")
	check(val("ArenaDRTimer") == "true", "DR con reloj")
	local hide = src:match('ArenaDRHideCats = "([^"]*)"')
	local set = {}
	for c in (hide or ""):gmatch("[^,]+") do set[c] = true end
	local ALL = { "ctrlstun", "openstun", "rndstun", "disorient", "fear", "horror", "silence", "cyclone",
		"ctrlroot", "rndroot", "sleep", "disarm", "entrapment", "scatter", "mc", "banish", "charge", "intimidation" }
	local shown = {}
	for _, c in ipairs(ALL) do if not set[c] then shown[#shown + 1] = c end end
	table.sort(shown)
	check(table.concat(shown, ",") == "ctrlstun,disorient", "DR: solo stuns e incapacitaciones (" .. table.concat(shown, ",") .. ")")
	check(val("ArenaDoTWarn") == "true", "DoT prendido")
	check(val("ArenaDoTSize") == "14" and val("ArenaDoTSpacing") == "0" and val("ArenaDoTMax") == "3", "DoT 14 / 0 / 3")
	check(val("ArenaDoTLabel") == "false" and val("ArenaDoTBorder") == "false", "DoT sin texto ni borde rojo")
	-- las tablas propias que el reset olvidaba
	for _, t in ipairs({ "PartyTargetsDB", "PartyCastingBarsDB", "SacredShieldDB", "SacredShieldTrackerDB", "SeductionAlertDB" }) do
		check(src:find("if " .. t, 1, true) ~= nil, "reset limpia " .. t)
	end
end
-- 2) CommandGuard protege los tres comandos nuevos
do
	local src = io.open(F .. "/Nidhaus_UnitFrames/Core/CommandGuard.lua"):read("*a")
	for _, k in ipairs({ "NUFSACREDSHIELD", "NUFSSTRACKER", "NUFSEDUCTION" }) do
		check(src:find('key = "' .. k .. '"', 1, true) ~= nil, "guard " .. k)
	end
end
-- 3) duelos por K.InDuel
do
	for _, f in ipairs({ "Nidhaus_UnitFrames/Modules2/GargoyleTracker/GargoyleTracker.lua", "Nidhaus_UnitFrames/Modules2/EnemySpellAlert.lua" }) do
		local src = io.open(F .. "/" .. f):read("*a")
		check(not src:find("DuelOutOfBoundsTimer", 1, true), "sin DuelOutOfBoundsTimer: " .. f:match("([^/]+)$"))
		check(src:find("K.InDuel", 1, true) ~= nil, "usa K.InDuel: " .. f:match("([^/]+)$"))
	end
end
print(("PASS %d  FAIL %d"):format(pass, fail))

