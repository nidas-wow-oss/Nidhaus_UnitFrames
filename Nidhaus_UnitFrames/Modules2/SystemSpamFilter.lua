local AddOnName, ns = ...;
local K, C, L = unpack(ns);






















local gsub, format = string.gsub, string.format;


local GRUPOS = {
	duelos = {
		"DUEL_WINNER_KNOCKOUT",
		"DUEL_WINNER_RETREAT",
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









local MARCA_TXT = "\1";
local MARCA_NUM = "\2";

local function AFormato(cadena)
	if type(cadena) ~= "string" or cadena == "" then return nil; end


	local p = gsub(cadena, "%%%d%$s", MARCA_TXT);
	p = gsub(p, "%%%d%$d", MARCA_NUM);
	p = gsub(p, "%%s", MARCA_TXT);
	p = gsub(p, "%%d", MARCA_NUM);


	p = gsub(p, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1");


	p = gsub(p, MARCA_TXT, ".-");
	p = gsub(p, MARCA_NUM, "%%d+");

	return "^" .. p .. "$";
end

local patrones = {};
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
			return true;
		end
	end
	return false;
end




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
	hideFromModulesTab = true,
	onEnable  = function() SetEnabled(true); end,
	onDisable = function() SetEnabled(false); end,
});
