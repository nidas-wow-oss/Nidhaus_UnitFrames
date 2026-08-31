local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- CommandGuard.lua
--
-- Si un modulo esta APAGADO, su comando no tiene que hacer nada.
--
-- Antes cada comando corria igual sin importar el estado del checkbox.
-- Podias tener PaladinICD destildado y hacer /paladinicd, y te aparecia el
-- icono igual — o peor, entrabas en su modo mover sin que el modulo
-- existiera del todo. Lo mismo con los otros quince.
--
-- COMO SE HACE
--
-- No se toca ningun modulo. Se envuelve el handler que cada uno ya dejo en
-- SlashCmdList, agregandole el chequeo adelante. La ventaja de hacerlo
-- desde afuera es que un modulo nuevo no tiene que acordarse de nada: se
-- agrega una linea a la tabla de abajo y listo.
--
-- Se envuelve en PLAYER_LOGIN, cuando todos los archivos ya registraron
-- lo suyo. Antes de ese momento SlashCmdList todavia no esta completo.
-- =========================================================

-- La clave es la de SlashCmdList (no el texto del comando), sacada de leer
-- cada archivo. El comando que ve el usuario va al lado como referencia.
local GUARDED = {
	{ key = "ARENACALC",     module = "ArenaPointsCalc"      },  -- /apc, /arenapts
	{ key = "NUFARROWCOUNT", module = "ArrowCount"           },  -- /arrowcount
	{ key = "NUFAUTOSHOT",   module = "AutoShotTimer"        },  -- /nufshot
	{ key = "HIDEACTIONBAR", module = "HideActionBarTextures"},  -- /hidebar
	{ key = "HCB",           module = "HideChatButton"       },  -- /hcb
	{ key = "NUFPETBUFFS",   module = "HunterPetBuffs"       },  -- /nufpetbuffs
	{ key = "NUFSWING",      module = "MeleeSwingTimer"      },  -- /nufswing
	{ key = "NUFMINIMAP",    module = "MinimapIconToggle"    },  -- /nufminimap
	{ key = "PARTYBUFFS",    module = "PartyBuffs"           },  -- /pbuffs, /partybuffs
	{ key = "NUFPOWERBAR",   module = "PowerBar"             },  -- /nufpower
	{ key = "NUFCOMBO",      module = "ComboWatch"           },  -- /nufcombo
	{ key = "GT",            module = "GargoyleTracker"      },  -- /gt
	{ key = "NICEDAMAGE",    module = "NiceDamage"           },  -- /nicedamage, /nd
	{ key = "DTSU",          module = "DTSU"                 },  -- /dtsu
	{ key = "PALADINICD",    module = "PaladinICD"           },  -- /paladinicd
	{ key = "PARTYPETFRAME", module = "PartyPetFrame"        },  -- /ppf, /partypetframe
	-- ShieldWatch esta sacado del XML (cuelga el cliente, causa sin
	-- identificar). Al no cargarse tampoco registra su comando, asi que es
	-- normal que no aparezca: por eso va como opcional y no se cuenta como
	-- faltante. Cuando vuelva al XML, esta linea ya lo protege sola.
	{ key = "shieldwatch",   module = "ShieldWatch", optional = true },  -- /shieldwatch, /swh

	-- /nufpal maneja DOS modulos (Paladin auras y Turn Evil). Alcanza con
	-- que uno este prendido para que el comando tenga sentido, asi que se
	-- pasa una lista en vez de un solo id.
	{ key = "NUFPALAURAS",   module = { "PaladinAuras", "TurnEvil" } },  -- /nufpal
};

local function AnyEnabled(mod)
	if not K.IsModuleEnabled then return true; end
	if type(mod) == "table" then
		for _, id in ipairs(mod) do
			if K.IsModuleEnabled(id) then return true; end
		end
		return false;
	end
	return K.IsModuleEnabled(mod) and true or false;
end

-- Nombre legible para el aviso.
local function ModuleLabel(mod)
	local id = (type(mod) == "table") and mod[1] or mod;
	local m = K.Modules and K.Modules[id];
	return (m and m.name) or id;
end

-- Registro de los que ya envolvimos.
--
-- Al principio marcaba la funcion misma (wrapped._nufGuarded = true), y eso
-- era un error: en Lua 5.1 las funciones NO se pueden indexar, asi que el
-- solo hecho de leer handler._nufGuarded tiraba
-- "attempt to index local 'handler' (a function value)".
-- Una tabla comun al costado hace lo mismo sin tocar la funcion.
local wrappedFns = {};

local function GuardOne(entry)
	local handler = SlashCmdList and SlashCmdList[entry.key];
	if type(handler) ~= "function" then return false; end
	if wrappedFns[handler] then return true; end   -- ya envuelto

	local wrapped = function(...)
		if not AnyEnabled(entry.module) then
			DEFAULT_CHAT_FRAME:AddMessage("|cff4FC3F7[NUF]|r " .. string.format(
				L["CMD_MODULE_OFF"]
					or "%s is turned off. Enable it in the options panel to use its commands.",
				ModuleLabel(entry.module)));
			return;
		end
		return handler(...);
	end;
	wrappedFns[wrapped] = true;

	SlashCmdList[entry.key] = wrapped;
	return true;
end

local guard = CreateFrame("Frame");
guard:RegisterEvent("PLAYER_LOGIN");
guard:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");

	local ok, total, miss = 0, 0, {};
	for _, entry in ipairs(GUARDED) do
		if GuardOne(entry) then
			ok    = ok + 1;
			total = total + 1;
		elseif entry.optional then
			-- El modulo no esta cargado. Esperable, no cuenta como faltante.
		else
			total = total + 1;
			miss[#miss + 1] = entry.key;
		end
	end

	K._cmdGuardOK    = ok;
	K._cmdGuardTotal = total;
	K._cmdGuardMiss  = miss;
end);

-- Diagnostico: /nufcmd dice cuales quedaron protegidos y cuales no.
-- Sirve para detectar a tiempo si alguien renombra una clave de
-- SlashCmdList y la tabla de arriba queda desincronizada.
SLASH_NUFCMD1 = "/nufcmd";
SlashCmdList["NUFCMD"] = function()
	print("|cff4FC3F7NUF comandos:|r");
	print("   protegidos: " .. tostring(K._cmdGuardOK or 0)
		.. " de " .. tostring(K._cmdGuardTotal or #GUARDED));
	local miss = K._cmdGuardMiss;
	if miss and #miss > 0 then
		print("   |cffFF5555sin encontrar:|r " .. table.concat(miss, ", "));
	end
	for _, entry in ipairs(GUARDED) do
		-- Un opcional que no se cargo no se lista: no tiene comando que usar.
		if SlashCmdList[entry.key] or not entry.optional then
			print(string.format("   %-16s %s", entry.key,
				AnyEnabled(entry.module) and "|cff88FF88activo|r" or "|cff8A8A8Aapagado|r"));
		end
	end
end
