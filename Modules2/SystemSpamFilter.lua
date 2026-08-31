local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- SystemSpamFilter.lua
-- Quita del chat los mensajes de sistema que solo hacen ruido:
-- resultados de duelo ajenos, borracheras y "has aprendido X".
--
-- Portado de la idea de el UI de origen (Modules/Chat/Filters.lua), pero NO de su
-- implementacion. Alli se vacian las cadenas globales de Blizzard:
--
--     DUEL_WINNER_KNOCKOUT = ""
--     DUEL_WINNER_RETREAT  = ""
--
-- Eso tiene dos problemas: es global (cualquier otro addon que lea esas
-- cadenas se las encuentra vacias) y es irreversible sin recargar, asi que
-- no se puede apagar el modulo de verdad.
--
-- Aca se usa ChatFrame_AddMessageEventFilter, que es reversible y no toca
-- nada de fuera. Los patrones se construyen leyendo las MISMAS cadenas
-- globales en runtime, asi que funciona en cualquier idioma de cliente sin
-- escribir el texto a mano.
-- =========================================================

local gsub, format = string.gsub, string.format;

-- Cadenas de Blizzard que queremos silenciar, por grupo.
local GRUPOS = {
	duelos = {
		"DUEL_WINNER_KNOCKOUT",   -- "%s ha derrotado a %s en un duelo"
		"DUEL_WINNER_RETREAT",    -- "%s ha huido de %s, abandonando el duelo"
	},
	borrachos = {
		"DRUNK_MESSAGE_OTHER1", "DRUNK_MESSAGE_OTHER2", "DRUNK_MESSAGE_OTHER3", "DRUNK_MESSAGE_OTHER4",
		"DRUNK_MESSAGE_ITEM_OTHER1", "DRUNK_MESSAGE_ITEM_OTHER2", "DRUNK_MESSAGE_ITEM_OTHER3", "DRUNK_MESSAGE_ITEM_OTHER4",
	},
	aprendizajes = {
		"ERR_LEARN_ABILITY_S", "ERR_LEARN_SPELL_S", "ERR_LEARN_PASSIVE_S", "ERR_SPELL_UNLEARNED_S",
		"ERR_PET_LEARN_ABILITY_S", "ERR_PET_LEARN_SPELL_S", "ERR_PET_SPELL_UNLEARNED_S",
	},
};

-- Convierte una cadena de formato de Blizzard en un patron de Lua.
-- "%s ha derrotado a %s en un duelo"  ->  "^.- ha derrotado a .- en un duelo$"
-- Se hace en tres pasos y en este orden a proposito. Intentarlo al reves
-- (escapar primero, sustituir despues) no funciona: al escapar, el "$" de
-- los marcadores posicionales "%1$s" se convierte en "%$" y ya no hay forma
-- limpia de reconocerlos. Por eso los marcadores se apartan ANTES de
-- escapar, usando dos caracteres de control que jamas aparecen en un texto
-- del juego.
local MARCA_TXT = "\1";
local MARCA_NUM = "\2";

local function AFormato(cadena)
	if type(cadena) ~= "string" or cadena == "" then return nil; end

	-- 1) apartar los marcadores: posicionales primero ("%1$s"), luego simples
	local p = gsub(cadena, "%%%d%$s", MARCA_TXT);
	p = gsub(p, "%%%d%$d", MARCA_NUM);
	p = gsub(p, "%%s", MARCA_TXT);
	p = gsub(p, "%%d", MARCA_NUM);

	-- 2) escapar todo lo que Lua considera magico
	p = gsub(p, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1");

	-- 3) devolver los marcadores como comodines
	p = gsub(p, MARCA_TXT, ".-");
	p = gsub(p, MARCA_NUM, "%%d+");

	return "^" .. p .. "$";
end

local patrones = {};   -- lista plana, ya compilada
local construido = false;

local function Construir()
	if construido then return; end
	construido = true;
	for grupo, claves in pairs(GRUPOS) do
		for _, clave in ipairs(claves) do
			local p = AFormato(_G[clave]);
			if p then table.insert(patrones, p); end
		end
	end
end

local activo = false;

local function Filtro(self, event, msg)
	if not activo or not msg then return false; end
	for i = 1, #patrones do
		if msg:match(patrones[i]) then
			return true;   -- true = tragarse el mensaje
		end
	end
	return false;
end

-- El filtro se registra UNA sola vez: quitarlo y ponerlo en cada toggle es
-- innecesario, y ChatFrame_RemoveMessageEventFilter necesita exactamente la
-- misma referencia de funcion. Con la bandera "activo" ya alcanza.
local registrado = false;

local function SetEnabled(on)
	activo = on and true or false;
	if activo then
		Construir();
		if not registrado then
			registrado = true;
			ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", Filtro);
		end
	end
end

-- /nufspam test  -> muestra que patrones quedaron armados con tu cliente
SLASH_NUFSPAMFILTER1 = "/nufspam";
SlashCmdList["NUFSPAMFILTER"] = function(msg)
	Construir();
	print("|cff4FC3F7NUF:|r filtro de spam de sistema - " ..
		(activo and "|cff00ff00activo|r" or "|cffff0000apagado|r") ..
		", " .. #patrones .. " patrones.");
	if (msg or ""):lower():find("test") then
		for i = 1, #patrones do print("   " .. patrones[i]); end
	end
end

K.RegisterModule("SystemSpamFilter", {
	name    = L["MOD_SYSTEM_SPAM"] or "Hide system spam",
	desc    = L["MOD_SYSTEM_SPAM_DESC"]
		or "Removes system chat spam: other people's duel results, drunk messages and 'you have learned' lines.",
	default = false,
	hideFromModulesTab = true,   -- vive en Interface > Chat
	onEnable  = function() SetEnabled(true); end,
	onDisable = function() SetEnabled(false); end,
});
