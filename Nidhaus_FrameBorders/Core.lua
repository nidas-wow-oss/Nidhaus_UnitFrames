local ADDON, ns = ...;

-- =========================================================
-- Nidhaus Frame Borders
--
-- Borde fino de esquina redonda y sombra exterior alrededor de las barras
-- de accion, el micromenu, las bolsas, la barra de casteo y las auras.
--
-- ADDON APARTE, no un modulo. No depende de Nidhaus UnitFrames ni de
-- ningun otro: si NUF no esta instalado, esto anda igual.
--
-- CONVIVE CON LORTI UI, no compite. Lorti no dibuja bordes: tinta las
-- texturas de Blizzard para oscurecerlas. Esto no toca esas texturas,
-- agrega un marco propio por encima. Son dos capas distintas.
--
-- ARTE PROPIO. Las texturas de Media/Border las dibuja Tools/mkborders.py:
-- geometria pura, un perfil de alfa segun la distancia al filo. La fuente
-- Prototype es freeware de Neale Davidson y viaja con su nota, que es lo
-- que su licencia pide (Media/Fonts/Prototype.txt).
-- =========================================================

ns.MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\";

-- ---------------------------------------------------------
-- Ajustes
--
-- Los grupos arrancan en true y el addon en false: prenderlo una vez
-- tiene que mostrar el estilo completo, no una lista vacia que hay que ir
-- tildando.
-- ---------------------------------------------------------
local DEFAULTS = {
	enabled    = false,
	shadow     = true,
	font       = 1,      -- 1 sin cambiar, 2 Prototype, 3 Prototype Outline
	ActionBars = true,
	MicroMenu  = true,
	Bags       = true,
	CastBar    = true,
	Auras      = true,
};

-- La tabla guardada no existe hasta ADDON_LOADED, asi que NADIE puede
-- llamar a esto al cargar el archivo: se pide siempre en el momento.
function ns.DB()
	if type(NidhausFrameBordersDB) ~= "table" then NidhausFrameBordersDB = {}; end
	local db = NidhausFrameBordersDB;
	for k, v in pairs(DEFAULTS) do
		if db[k] == nil then db[k] = v; end
	end
	return db;
end

function ns.Get(key)
	return ns.DB()[key];
end

function ns.Set(key, value)
	ns.DB()[key] = value;
	ns.Apply();
end

-- Un solo punto de reaplicacion. Cada archivo cuelga lo suyo de ns y este
-- los llama sin saber que hacen.
function ns.Apply()
	if ns.ApplyBorders then ns.ApplyBorders(); end
	if ns.ApplyFont    then ns.ApplyFont();    end
end

-- ---------------------------------------------------------
-- Arranque
-- ---------------------------------------------------------
local boot = CreateFrame("Frame");
boot:RegisterEvent("ADDON_LOADED");
boot:RegisterEvent("PLAYER_LOGIN");
boot:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" and name ~= ADDON then return; end
	ns.DB();
	if event == "PLAYER_LOGIN" then ns.Apply(); end
end);

-- ---------------------------------------------------------
-- /nfb
-- ---------------------------------------------------------
SLASH_NIDHAUSFRAMEBORDERS1 = "/nfb";
SlashCmdList["NIDHAUSFRAMEBORDERS"] = function(msg)
	msg = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"));

	if msg == "on" or msg == "off" then
		ns.Set("enabled", msg == "on");
		print("|cff00FF00Frame Borders|r " .. (msg == "on" and "prendido" or "apagado"));
		return;
	end

	if msg == "list" and ns.ListDrawn then ns.ListDrawn(); return; end
	if msg == "what" and ns.WhatIsUnder then ns.WhatIsUnder(); return; end

	if ns.TogglePanel then ns.TogglePanel(); return; end

	print("|cff00FF00Frame Borders|r  /nfb on | off | list | what");
end
