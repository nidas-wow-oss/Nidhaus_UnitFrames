local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ChatURLs.lua
-- Convierte las URLs escritas en el chat en links clicables.
-- Al hacer click se abre una ventanita con el texto ya
-- seleccionado para copiar con Ctrl+C.
-- Opcion: C.ChatClickableURLs
-- =========================================================

local LINK_COLOR = "ff7fd5ff";

-- Dominios de primer nivel mas usados (suficiente para links de WoW)
local TLD_LIST = [[
com net org edu gov mil int info biz name pro io gg tv me co cc ws tk
ru ua by kz pl de fr es it uk us ca br ar cl mx pe uy co nl se no fi dk
cz sk hu ro bg gr pt tr il in cn jp kr tw hk sg au nz za ch at be ie is
gg gl app dev xyz online site shop club live wiki fun space store tech
]];

local tlds = {};
for tld in string.gmatch(TLD_LIST, "%a+") do
	tlds[tld] = true;
end

-- Patron 1: dominio "pelado" (wowhead.com/spell=123)
local PATTERN_DOMAIN = "(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))";
-- Patron 2: con protocolo (https://...)
local PATTERN_PROTO  = "((%f[%w]%a+://)(%w[-.%w]*)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))";

local protocols = {
	[""]         = 0,
	["http://"]  = 0,
	["https://"] = 0,
	["ftp://"]   = 0,
};

-- ---------------------------------------------------------
-- EL TIPO DE LINK
--
-- Antes esto usaba un tipo propio, "nufurl:". ERROR MIO: yo daba por hecho
-- que a Blizzard un tipo desconocido no le decia nada y lo dejaba pasar sin
-- hacer nada. No es asi. El SetItemRef de FrameXML, cuando no reconoce el
-- tipo, cae en un ultimo recurso:
--
--     ItemRefTooltip:SetHyperlink(link)
--
-- y eso revienta en C con "Unknown link type". Peor: revienta ANTES de que
-- corra nuestro post-hook, asi que la ventanita de copiar no aparecia nunca.
--
-- Y no podemos volver a REEMPLAZAR la global SetItemRef, porque es
-- exactamente lo que ensuciaba (taint) el camino del menu de click derecho
-- del chat y bloqueaba la opcion Target.
--
-- Solucion: usar un tipo que Blizzard SI acepte — un link de hechizo real —
-- y llevar la URL en el TEXTO VISIBLE, que el hook tambien recibe. Blizzard
-- abre el tooltip de ese hechizo, nuestro hook lo cierra en el mismo frame
-- (no se alcanza a dibujar) y muestra la ventanita de copiar.
-- ---------------------------------------------------------
local SENTINEL_ID;
for _, id in ipairs({ 6603, 75, 2098, 133 }) do
	if GetSpellInfo(id) then SENTINEL_ID = id; break; end
end
SENTINEL_ID = SENTINEL_ID or 6603;

local SENTINEL_LINK = "spell:" .. SENTINEL_ID;

local function FormatURL(url)
	return string.format("|c%s|H%s|h[%s]|h|r", LINK_COLOR, SENTINEL_LINK, url);
end

local function EscapePattern(text)
	return (string.gsub(text, "([%%%+%-%*%(%)%?%[%]%^%$%.])", "%%%1"));
end

local function MakeClickable(self, event, msg, ...)
	if not C.ChatClickableURLs then return false, msg, ...; end
	if type(msg) ~= "string" or msg == "" then return false, msg, ...; end
	-- No tocar mensajes que ya traen links de Blizzard
	if string.find(msg, "|H") then return false, msg, ...; end

	local done = {};

	for url, prot, subdomain, tld, colon, port, slash, path in string.gmatch(msg, PATTERN_DOMAIN) do
		if not done[url]
			and protocols[string.lower(prot)] == (1 - string.len(slash)) * string.len(path)
			and not string.find(subdomain, "%W%W")
			and (colon == "" or (port ~= "" and tonumber(port) and tonumber(port) < 65536))
			and tlds[string.lower(tld)]
		then
			done[url] = true;
			msg = string.gsub(msg, EscapePattern(url), FormatURL("%1"));
		end
	end

	for url, prot, domain, colon, port, slash, path in string.gmatch(msg, PATTERN_PROTO) do
		if not done[url]
			and not string.find(domain .. ".", "%W%W")
			and protocols[string.lower(prot)] == (1 - string.len(slash)) * string.len(path)
			and (colon == "" or (port ~= "" and tonumber(port) and tonumber(port) < 65536))
		then
			done[url] = true;
			msg = string.gsub(msg, EscapePattern(url), FormatURL("%1"));
		end
	end

	return false, msg, ...;
end

-- ---------------------------------------------------------
-- Popup para copiar la URL
-- ---------------------------------------------------------
-- La URL a mostrar. En 3.3.5a el OnShow de un StaticPopup NO recibe el
-- parametro "data": hay que leerlo de self.data. Guardamos ademas una copia
-- aca porque algunos servers tampoco propagan bien self.data.
local pendingURL = "";

local function FillPopupEditBox(dialog)
	if not dialog then return; end

	local url = pendingURL;
	if (not url or url == "") and type(dialog.data) == "table" then
		url = dialog.data.url;
	end
	url = url or "";

	-- Con hasWideEditBox el cuadro es $parentWideEditBox, no dialog.editBox
	local name = dialog.GetName and dialog:GetName();
	local box  = (name and _G[name .. "WideEditBox"]) or dialog.editBox;
	if not box then return; end

	box:SetText(url);
	box:SetCursorPosition(0);
	box:SetFocus();
	box:HighlightText();
end

StaticPopupDialogs["NUF_COPY_URL"] = {
	text         = L["URL_POPUP_TEXT"] or "Copy the link (Ctrl+C):",
	button1      = L["BTN_CLOSE"] or "Close",
	timeout      = 0,
	whileDead    = true,
	hideOnEscape = 1,
	preferredIndex = 3,
	hasEditBox     = true,
	hasWideEditBox = true,
	OnShow = function(self)
		FillPopupEditBox(self or this);
	end,
	OnHide = function()
		pendingURL = "";
	end,
	-- Que no se pueda editar: si escribis algo, se repone la URL
	EditBoxOnTextChanged = function(self)
		if self:GetText() ~= pendingURL and pendingURL ~= "" then
			self:SetText(pendingURL);
			self:HighlightText();
		end
	end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide(); end,
	EditBoxOnEnterPressed  = function(self) self:GetParent():Hide(); end,
};

-- ---------------------------------------------------------
-- Interceptar el click en el link
-- ---------------------------------------------------------
-- OJO CON ESTO: antes se REEMPLAZABA la global SetItemRef por una funcion
-- nuestra que, si el link no era nuestro, llamaba a la original.
-- (Ver arriba por que el tipo de link tampoco puede ser propio.)
--
-- El problema: en 3.3.5a el click derecho sobre un NOMBRE del chat pasa por
-- SetItemRef, que es quien abre el menu del jugador. Al reemplazar la global,
-- toda esa cadena quedaba ejecutandose desde codigo de addon, o sea TAINTED.
-- Y las acciones protegidas que cuelgan de ese menu — justamente Target —
-- el cliente las bloquea, con el cartel "Interface action failed because of
-- an AddOn".
--
-- La solucion es un POST-HOOK: la global sigue siendo la de Blizzard, asi
-- que el camino del menu queda limpio. Blizzard atiende el link como el
-- hechizo centinela que es (sin errores), y despues corre nuestro hook, que
-- cierra ese tooltip y abre el popup de copiar.
local function OnItemRef(link, text, button)
	if type(link) ~= "string" or type(text) ~= "string" then return; end
	if link ~= SENTINEL_LINK then return; end

	-- Shift+click: Blizzard ya inserto el link en la caja de chat. Es util
	-- (pega la URL tal cual), asi que no abrimos el popup encima.
	if IsModifiedClick("CHATLINK") then return; end

	-- La URL viene en el texto visible, entre corchetes.
	local url = string.match(text, "%[(.+)%]");
	-- Que sea realmente una URL y no el hechizo centinela linkeado de verdad
	-- por alguien: tiene que tener un punto o dos puntos.
	if not url or not string.find(url, "[%.:]") then return; end

	-- Matar el tooltip del hechizo centinela antes de que se dibuje.
	if ItemRefTooltip and ItemRefTooltip.Hide then ItemRefTooltip:Hide(); end

	pendingURL = url;
	local dialog = StaticPopup_Show("NUF_COPY_URL", "", "", { url = pendingURL });
	-- Rellenar tambien despues de abrir: si el popup ya estaba visible,
	-- OnShow no se vuelve a disparar y el cuadro quedaria con lo anterior.
	if dialog then
		dialog.data = { url = pendingURL };
		FillPopupEditBox(dialog);
	end
end

if type(SetItemRef) == "function" then
	hooksecurefunc("SetItemRef", OnItemRef);
end

-- ---------------------------------------------------------
-- Filtros
-- ---------------------------------------------------------
local CHAT_TYPES = {
	"SAY", "YELL", "EMOTE", "GUILD", "OFFICER", "PARTY", "PARTY_LEADER",
	"RAID", "RAID_LEADER", "RAID_WARNING", "BATTLEGROUND", "BATTLEGROUND_LEADER",
	"WHISPER", "WHISPER_INFORM", "CHANNEL", "AFK", "DND", "SYSTEM",
};

for _, chatType in ipairs(CHAT_TYPES) do
	ChatFrame_AddMessageEventFilter("CHAT_MSG_" .. chatType, MakeClickable);
end
