local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- SlotProfiles.lua
--
-- Copiar barras de accion, macros y bindeos de un personaje a otro.
-- Portado del addon MySlot (tg123 / farmer1992@gmail.com, v3.2), que
-- funcionaba pero tenia la interfaz entera en chino y cuatro bugs reales.
--
-- SE MANTIENE EL FORMATO DE LA CADENA de MySlot a proposito, para que las
-- cadenas que ya tengas guardadas o las que te pasen sigan sirviendo. Eso
-- incluye el codec (huffman por nibbles + base64 propio) copiado tal cual.
--
-- QUE SE ARREGLO respecto del original:
--
--   1. Los bindeos no se guardaban. Hacia SetBinding() y nunca
--      SaveBindings(), asi que se perdian al desloguear.
--
--   2. El chequeo de combate no cortaba. Imprimia "no uses esto en
--      combate" y seguia adelante igual (le faltaba el return).
--
--   3. Todos los iconos de macro salian iguales. Armaba el mapa
--      textura->indice al cargar el archivo, cuando la lista de iconos
--      todavia no existe. Ahora se arma la primera vez que se usa.
--
--   4. loadstring() sobre el texto pegado. La cadena viene en base64, o
--      sea que no ves lo que trae, y se ejecutaba como codigo. Ahora hay
--      un parser estricto que solo entiende tablas y valores literales:
--      no puede ejecutar nada.
--
-- Y dos cambios de criterio:
--
--   - findMacro comparaba SOLO el cuerpo y hacia EditMacro sobre la
--     primera coincidencia, asi que podia pisar una macro ajena que
--     tuviera el mismo texto. Ahora exige que coincidan nombre Y cuerpo.
--
--   - Antes de importar o borrar se guarda un backup automatico,
--     recuperable con /nufslot backup.
-- =========================================================

local MAX_ACTION_SLOTS = 120;
local KEYBIND_KEY      = 999;   -- indice reservado para los bindeos

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff4FC3F7[NUF]|r " .. tostring(msg or ""));
end

-- =========================================================
-- 1. CODEC
--
-- Copia literal del humbase64.lua de MySlot: cuenta la frecuencia de cada
-- nibble, les asigna codigos huffman de largo creciente y empaqueta el
-- resultado en base64 con alfabeto propio (usa - y _ en vez de + y /).
-- Los primeros 16 caracteres de la cadena son la tabla de frecuencias.
--
-- No se toca la logica porque de eso depende poder leer las cadenas
-- viejas. Lo unico que cambio: en el original las variables n, a y b del
-- encoder eran GLOBALES (se filtraban al _G). Aca son locales.
-- =========================================================
local Codec = {};
do
	local b64chars = {
		[0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='G',[7]='H',
		[8]='I',[9]='J',[10]='K',[11]='L',[12]='M',[13]='N',[14]='O',[15]='P',
		[16]='Q',[17]='R',[18]='S',[19]='T',[20]='U',[21]='V',[22]='W',[23]='X',
		[24]='Y',[25]='Z',[26]='a',[27]='b',[28]='c',[29]='d',[30]='e',[31]='f',
		[32]='g',[33]='h',[34]='i',[35]='j',[36]='k',[37]='l',[38]='m',[39]='n',
		[40]='o',[41]='p',[42]='q',[43]='r',[44]='s',[45]='t',[46]='u',[47]='v',
		[48]='w',[49]='x',[50]='y',[51]='z',[52]='0',[53]='1',[54]='2',[55]='3',
		[56]='4',[57]='5',[58]='6',[59]='7',[60]='8',[61]='9',[62]='-',[63]='_',
	};

	-- Tabla inversa: caracter -> sus 6 bits. Se arma desde b64chars para no
	-- repetir 64 constantes escritas a mano (en el original estaban las dos
	-- listas duplicadas, con el riesgo de que se desincronizaran).
	local b64bytes = {};
	for value, chr in pairs(b64chars) do
		local bits = "";
		for bit = 5, 0, -1 do
			bits = bits .. (math.floor(value / (2 ^ bit)) % 2);
		end
		b64bytes[chr] = bits;
	end

	local huffman = {
		[0]="00", [1]="01", [2]="100", [3]="101", [4]="1100", [5]="1101",
		[6]="11100", [7]="11101", [8]="111100", [9]="111101",
		[10]="1111100", [11]="1111101", [12]="11111100", [13]="11111101",
		[14]="111111100", [15]="111111101",
	};

	local function ToB64Char(bits)
		while string.len(bits) ~= 6 do bits = bits .. "1"; end
		return b64chars[tonumber(bits, 2)];
	end

	function Codec.enc(data)
		local counts = {};
		for i = 1, 16 do
			counts[i] = { n = string.format("%x", i - 1), p = 0 };
		end

		local nibbles = {};
		for i = 1, string.len(data) do
			local byte = string.byte(data, i);
			local lo = byte % 16;
			local hi = (byte - lo) / 16;
			counts[lo + 1].p = counts[lo + 1].p + 1;
			counts[hi + 1].p = counts[hi + 1].p + 1;
			nibbles[#nibbles + 1] = hi;
			nibbles[#nibbles + 1] = lo;
		end

		table.sort(counts, function(a, b) return a.p > b.p; end);

		local out, codeFor = {}, {};
		for i, v in ipairs(counts) do
			codeFor[tonumber(v.n, 16)] = huffman[i - 1];
			out[#out + 1] = v.n;
		end

		for i, v in ipairs(nibbles) do nibbles[i] = codeFor[v]; end

		local bits = table.concat(nibbles);
		for i = 1, string.len(bits), 6 do
			out[#out + 1] = ToB64Char(string.sub(bits, i, i + 5));
		end
		return table.concat(out);
	end

	local function BitReader(s)
		local i = 0;
		return function()
			i = i + 1;
			return string.sub(s, i, i) or "";
		end
	end

	-- Los codigos huffman son todos "1"*k .. "0" .. bit, asi que se leen
	-- contando unos hasta el primer cero y tomando un bit mas.
	local function NextNibble(read, map)
		local code = "";
		while read() == "1" do code = code .. "1"; end
		code = code .. "0" .. read();
		return map[code] or "X";
	end

	function Codec.dec(data)
		-- 16 caracteres = solo la tabla de frecuencias, carga vacia.
		if string.len(data) < 16 then return nil; end

		local map = {};
		for i = 1, 16 do
			map[huffman[i - 1]] = string.sub(data, i, i);
		end

		local bits = {};
		for i = 17, string.len(data) do
			local chunk = b64bytes[string.sub(data, i, i)];
			if not chunk then return nil; end   -- caracter invalido
			bits[#bits + 1] = chunk;
		end

		local read = BitReader(table.concat(bits));
		local out  = {};
		local hi   = NextNibble(read, map);

		while hi ~= "X" do
			local lo = NextNibble(read, map);
			if lo == "X" then break; end
			local byte = tonumber(hi .. lo, 16);
			if not byte then break; end
			out[#out + 1] = string.char(byte);
			hi = NextNibble(read, map);
		end

		return table.concat(out);
	end
end

-- =========================================================
-- 2. PARSER
--
-- Reemplaza al loadstring del original. Entiende un subconjunto de la
-- sintaxis de tablas de Lua — el que usa este formato y nada mas:
--
--     tabla   := '{' campo* '}'
--     campo   := '[' valor ']' '=' valor (',' | ';')?
--     valor   := cadena | numero | nil | true | false | tabla
--
-- No hay llamadas a funciones, ni operadores, ni nombres: no hay forma de
-- que una cadena pegada ejecute nada. Si algo no encaja, devuelve nil y el
-- motivo con la posicion, en vez de romper.
-- =========================================================
local Parser = {};
do
	local MAX_DEPTH = 12;   -- corta tablas anidadas hasta el infinito

	local function SkipSpace(s, i)
		local _, stop = string.find(s, "^[ \t\r\n]*", i);
		return (stop or (i - 1)) + 1;
	end

	local escapes = {
		a = "\a", b = "\b", f = "\f", n = "\n",
		r = "\r", t = "\t", v = "\v",
		["\\"] = "\\", ['"'] = '"', ["'"] = "'", ["\n"] = "\n",
	};

	local function ReadQuoted(s, i)
		local quote = string.sub(s, i, i);
		local out = {};
		i = i + 1;
		while true do
			local chr = string.sub(s, i, i);
			if chr == "" then return nil, i, "cadena sin cerrar"; end
			if chr == quote then return table.concat(out), i + 1; end

			if chr == "\\" then
				local nxt = string.sub(s, i + 1, i + 1);
				if escapes[nxt] then
					out[#out + 1] = escapes[nxt];
					i = i + 2;
				elseif string.find(nxt, "%d") then
					local digits = string.match(s, "^%d%d?%d?", i + 1);
					out[#out + 1] = string.char(tonumber(digits) % 256);
					i = i + 1 + string.len(digits);
				else
					out[#out + 1] = nxt;
					i = i + 2;
				end
			else
				out[#out + 1] = chr;
				i = i + 1;
			end
		end
	end

	-- Cadena larga [[...]] / [=[...]=]. Como en Lua, si el primer caracter
	-- del contenido es un salto de linea, se descarta.
	local function ReadLongString(s, i)
		local level = string.match(s, "^%[(=*)%[", i);
		if not level then return nil, i, "no es cadena larga"; end

		local open  = string.len(level) + 2;
		local close = "]" .. level .. "]";
		local from  = i + open;
		local stop  = string.find(s, close, from, true);
		if not stop then return nil, i, "cadena larga sin cerrar"; end

		local body = string.sub(s, from, stop - 1);
		if string.sub(body, 1, 1) == "\n" then body = string.sub(body, 2); end
		return body, stop + string.len(close);
	end

	local ReadValue;

	local function ReadTable(s, i, depth)
		if depth > MAX_DEPTH then return nil, i, "demasiada anidacion"; end

		local out = {};
		i = SkipSpace(s, i + 1);   -- saltar '{'

		while true do
			local chr = string.sub(s, i, i);
			if chr == "" then return nil, i, "tabla sin cerrar"; end
			if chr == "}" then return out, i + 1; end

			if chr ~= "[" then return nil, i, "se esperaba '[' de una clave"; end

			local key, err;
			key, i, err = ReadValue(s, i + 1, depth + 1);
			if key == nil then return nil, i, err or "clave invalida"; end

			i = SkipSpace(s, i);
			if string.sub(s, i, i) ~= "]" then return nil, i, "se esperaba ']'"; end
			i = SkipSpace(s, i + 1);

			if string.sub(s, i, i) ~= "=" then return nil, i, "se esperaba '='"; end

			local value;
			value, i, err = ReadValue(s, i + 1, depth + 1);
			if value == nil and err then return nil, i, err; end

			out[key] = value;

			i = SkipSpace(s, i);
			local sep = string.sub(s, i, i);
			if sep == "," or sep == ";" then i = SkipSpace(s, i + 1); end
		end
	end

	-- Devuelve valor, posicionSiguiente, error.
	-- Ojo: nil es un valor valido, por eso el error va aparte.
	function ReadValue(s, i, depth)
		depth = depth or 0;
		i = SkipSpace(s, i);
		local chr = string.sub(s, i, i);

		if chr == "" then return nil, i, "fin inesperado"; end

		if chr == '"' or chr == "'" then
			local v, ni, err = ReadQuoted(s, i);
			if v == nil then return nil, ni, err; end
			return v, ni;
		end

		if chr == "[" and string.match(s, "^%[=*%[", i) then
			local v, ni, err = ReadLongString(s, i);
			if v == nil then return nil, ni, err; end
			return v, ni;
		end

		if chr == "{" then
			local v, ni, err = ReadTable(s, i, depth);
			if v == nil then return nil, ni, err; end
			return v, ni;
		end

		local num = string.match(s, "^%-?%d+%.?%d*", i);
		if num then return tonumber(num), i + string.len(num); end

		if string.sub(s, i, i + 2) == "nil"  then return nil, i + 3; end
		if string.sub(s, i, i + 3) == "true" then return true, i + 4; end
		if string.sub(s, i, i + 4) == "false" then return false, i + 5; end

		return nil, i, "valor no reconocido cerca de '" ..
			string.sub(s, i, i + 12) .. "'";
	end

	-- Entrada: el cuerpo sin las llaves exteriores, como lo guarda MySlot.
	function Parser.Parse(body)
		if type(body) ~= "string" then return nil, "entrada vacia"; end

		local text = "{" .. body .. "}";
		local out, stop, err = ReadTable(text, 1, 0);
		if out == nil then return nil, err or "formato invalido"; end

		-- Y que no sobre nada despues de la llave de cierre. Sin esto, una
		-- entrada como "} basura {" se leia como una tabla vacia valida en
		-- vez de rechazarse.
		stop = SkipSpace(text, stop);
		if stop <= string.len(text) then
			return nil, "sobra texto despues de la tabla";
		end

		return out;
	end
end

-- =========================================================
-- 3. SERIALIZAR
-- =========================================================

-- Elige el nivel de corchetes largos que no choque con el contenido, para
-- que una macro con "]]" adentro no rompa la cadena. El MySlot original
-- concatenaba "[[" .. body .. "]]" a lo bruto y en ese caso se rompia.
local function LongBracket(body)
	local level = "";
	while string.find(body, "]" .. level .. "]", 1, true) do
		level = level .. "=";
	end
	-- El salto inicial se descarta al leer, asi que agregarlo preserva
	-- cuerpos que empiezan con linea en blanco.
	return "[" .. level .. "[\n" .. body .. "]" .. level .. "]";
end

local function QuoteString(s)
	s = string.gsub(s, "\\", "\\\\");
	s = string.gsub(s, '"', '\\"');
	s = string.gsub(s, "\n", "\\n");
	s = string.gsub(s, "\r", "\\r");
	return '"' .. s .. '"';
end

-- =========================================================
-- 4. LEER EL ESTADO ACTUAL
-- =========================================================

-- Mapa textura -> indice de icono de macro.
-- BUG ORIGINAL: MySlot armaba esto en la linea 4 del archivo, al cargar,
-- cuando GetNumMacroIcons() todavia devuelve 0. El mapa quedaba vacio y
-- CreateMacro recibia siempre 1, o sea que todas las macros importadas
-- salian con el mismo icono. Aca se arma la primera vez que hace falta,
-- que siempre es despues del login.
local macroIconMap;
local function GetMacroIconMap()
	if macroIconMap then return macroIconMap; end
	macroIconMap = {};
	local total = (GetNumMacroIcons and GetNumMacroIcons()) or 0;
	for i = 1, total do
		local tex = GetMacroIconInfo(i);
		if tex then
			if not macroIconMap[tex] then macroIconMap[tex] = i; end
			-- Tambien en mayusculas: GetMacroInfo y GetMacroIconInfo no
			-- siempre devuelven la ruta con la misma capitalizacion.
			local up = string.upper(tex);
			if not macroIconMap[up] then macroIconMap[up] = i; end
		end
	end
	return macroIconMap;
end

local function IconIndexFor(texture)
	if not texture then return 1; end
	local map = GetMacroIconMap();
	return map[texture] or map[string.upper(texture)] or 1;
end

-- Nombre "Hechizo(Rango N)" a partir de lo que devuelve GetActionInfo.
--
-- OJO, ACA HAY UNA AMBIGUEDAD REAL: el segundo valor de GetActionInfo para
-- un hechizo puede interpretarse como indice del libro de hechizos o como
-- spellID, y la respuesta cambia entre versiones del cliente. MySlot asumia
-- lo primero (GetSpellName con BOOKTYPE_SPELL).
--
-- En vez de elegir a ciegas, se prueban las dos y se desempata comparando
-- el icono contra el que realmente muestra la casilla. Si una coincide,
-- esa es. Asi no depende de que yo acierte cual es.
local function SpellStringFor(slot, id)
	local wantTex = GetActionTexture(slot);

	-- Candidata A: indice del libro de hechizos.
	local nameA, rankA = GetSpellName(id, BOOKTYPE_SPELL);
	local texA = nameA and GetSpellTexture(id, BOOKTYPE_SPELL) or nil;

	-- Candidata B: spellID global.
	local nameB, rankB, texB = GetSpellInfo(id);

	local name, rank, isSpellId;
	if wantTex and texA == wantTex and nameA then
		name, rank = nameA, rankA;
	elseif wantTex and texB == wantTex and nameB then
		name, rank, isSpellId = nameB, rankB, true;
	elseif nameA then
		name, rank = nameA, rankA;
	elseif nameB then
		name, rank, isSpellId = nameB, rankB, true;
	end

	if not name then return nil; end
	if rank and rank ~= "" then
		return name .. "(" .. rank .. ")", isSpellId and id or nil;
	end
	return name, isSpellId and id or nil;
end

-- Devuelve una tabla describiendo la casilla, o nil si esta vacia.
local function ReadSlot(slot)
	local kind, id, subType = GetActionInfo(slot);
	if not kind then return nil; end

	if kind == "spell" then
		local text, spellId = SpellStringFor(slot, id);
		if not text then return nil; end
		-- "s" es un agregado nuestro: el spellID, cuando lo sabemos con
		-- certeza. MySlot ignora las claves que no conoce, asi que la
		-- cadena le sigue sirviendo.
		return { a = "S", b = text, s = spellId };
	end

	if kind == "item" then
		return { a = "I", b = tostring(id) };
	end

	if kind == "macro" then
		local name, texture, body = GetMacroInfo(id);
		if not name or not body then return nil; end
		local icon = IconIndexFor(texture);
		-- Las macros con #show usan icono dinamico: el indice 1 es el
		-- signo de pregunta, que es justo lo que corresponde.
		if string.find(body, "#show") == 1 then icon = 1; end
		return {
			a = "M",
			b = { b = name, c = icon, d = body, e = (tonumber(id) > 36) and 1 or nil },
		};
	end

	if kind == "companion" then
		return { a = "C", b = { b = subType, c = id } };
	end

	return nil;
end

local function ReadBindings()
	local out = {};
	for i = 1, GetNumBindings() do
		local command, key1, key2 = GetBinding(i);
		if command then
			if key1 then out[key1] = command; end
			if key2 then out[key2] = command; end
		end
	end
	return out;
end

-- =========================================================
-- 5. EXPORTAR
-- =========================================================
function K.SlotExport()
	local parts = {};

	for slot = 1, MAX_ACTION_SLOTS do
		local data = ReadSlot(slot);
		if data then
			local value;
			if type(data.b) == "table" then
				if data.a == "M" then
					value = string.format(
						'{["b"]=%s,["c"]=%d,["d"]=%s,["e"]=%s,}',
						QuoteString(data.b.b), data.b.c,
						LongBracket(data.b.d),
						data.b.e and "1" or "nil");
				else
					value = string.format('{["b"]=%s,["c"]=%d,}',
						QuoteString(tostring(data.b.b)), tonumber(data.b.c) or 0);
				end
			else
				value = QuoteString(tostring(data.b));
			end

			local extra = data.s and string.format(',["s"]=%d', data.s) or "";
			parts[#parts + 1] = string.format('[%d]={["a"]="%s",["b"]=%s%s,},',
				slot, data.a, value, extra);
		end
	end

	local binds = {};
	for key, command in pairs(ReadBindings()) do
		binds[#binds + 1] = string.format("[%s]=%s,", QuoteString(key), QuoteString(command));
	end
	parts[#parts + 1] = string.format("[%d]={%s},", KEYBIND_KEY, table.concat(binds));

	local header = {
		"@ NUF Slot Profile - " .. date(),
		"@ " .. (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?"),
		"@ " .. (UnitClass("player") or "?") .. " nivel " .. (UnitLevel("player") or 0),
		"@ Formato compatible con MySlot.",
		"@ --------------------",
		"",
	};

	return table.concat(header, "\n") .. Codec.enc(table.concat(parts));
end

-- =========================================================
-- 6. APLICAR
-- =========================================================

-- Indice del libro de hechizos a partir del nombre guardado.
-- Se busca por nombre porque es lo unico portable entre personajes: los
-- indices no coinciden y el spellID solo sirve si el hechizo es el mismo.
local function FindSpellBookSlot(text, spellId)
	if not text then return nil; end

	local wanted, wantedRank = string.match(text, "^(.+)%((.+)%)$");
	if not wanted then wanted, wantedRank = text, nil; end

	local fallback;
	local i = 1;
	while true do
		local name, rank = GetSpellName(i, BOOKTYPE_SPELL);
		if not name then break; end
		if name == wanted then
			if not wantedRank or rank == wantedRank then return i; end
			fallback = fallback or i;   -- mismo hechizo, otro rango
		end
		i = i + 1;
	end

	-- Si el nombre no aparecio (por ejemplo, cadena exportada en otro
	-- idioma) probamos recuperarlo desde el spellID que guardamos.
	if not fallback and spellId then
		local byId = GetSpellInfo(spellId);
		if byId and byId ~= wanted then
			return FindSpellBookSlot(byId);
		end
	end

	return fallback;
end

-- BUG ORIGINAL: findMacro comparaba solo el CUERPO y le hacia EditMacro a
-- la primera coincidencia. Dos macros distintas con el mismo texto (algo
-- comun: varias "/cast X" con nombres distintos) hacian que se pisara la
-- equivocada. Ahora tienen que coincidir nombre y cuerpo.
local function FindMacro(info)
	for i = 1, 54 do
		local name, _, body = GetMacroInfo(i);
		if name == info.b and body == info.d then return i; end
	end
	return nil;
end

local function EnsureMacro(info)
	if type(info) ~= "table" then return info; end

	local existing = FindMacro(info);
	if existing then return existing; end

	local globalCount, charCount = GetNumMacros();
	if (info.e and charCount >= 18) or (not info.e and globalCount >= 36) then
		Print("|cffFFAA00" .. string.format(
			L["SLOT_MACRO_FULL"] or "Macro '%s' skipped: no free macro slots.",
			tostring(info.b)) .. "|r");
		return nil;
	end

	-- Se llama igual que en MySlot (cinco argumentos) a proposito: es la
	-- forma que esta probada en este cliente.
	return CreateMacro(info.b, info.c, info.d, info.e, 1);
end

local function PlaceOnSlot(slot, entry)
	ClearCursor();

	if entry == nil or entry.a == nil then
		PickupAction(slot);
		ClearCursor();
		return;
	end

	if entry.a == "S" then
		local book = FindSpellBookSlot(entry.b, entry.s);
		if not book then return; end          -- no lo tiene: dejar como esta
		PickupSpell(book, BOOKTYPE_SPELL);

	elseif entry.a == "I" then
		PickupItem(entry.b);

	elseif entry.a == "M" then
		local id = EnsureMacro(entry.b);
		if not id then return; end
		PickupMacro(id);

	elseif entry.a == "C" then
		if type(entry.b) ~= "table" then return; end
		PickupCompanion(entry.b.b, entry.b.c);

	else
		return;
	end

	-- Si el pickup no puso nada en el cursor, no pisamos la casilla.
	if not CursorHasSpell() and not CursorHasItem() and not GetCursorInfo() then
		ClearCursor();
		return;
	end

	PlaceAction(slot);
	ClearCursor();
end

-- =========================================================
-- 7. BACKUP
-- =========================================================
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.SlotProfiles then
		NidhausUnitFramesDB.SlotProfiles = {};
	end
	return NidhausUnitFramesDB;
end

local function SaveBackup()
	local ok, data = pcall(K.SlotExport);
	if ok and data then DB().SlotBackup = data; end
end

function K.SlotHasBackup()
	return DB().SlotBackup ~= nil;
end

-- =========================================================
-- 8. IMPORTAR
-- =========================================================
function K.SlotImport(text)
	-- BUG ORIGINAL: esto imprimia el aviso y seguia igual, le faltaba el
	-- return. Colocar acciones en combate esta bloqueado por el cliente.
	if InCombatLockdown() then
		return false, L["SLOT_ERR_COMBAT"] or "Can't do this in combat.";
	end

	if type(text) ~= "string" or text == "" then
		return false, L["SLOT_ERR_EMPTY"] or "Paste a string first.";
	end

	-- Sacar las lineas de cabecera (@) y todo el espacio en blanco.
	local body = string.gsub(text, "@[^\n]*\n?", "");
	body = string.gsub(body, "[ \t\r\n]", "");
	if body == "" then
		return false, L["SLOT_ERR_EMPTY"] or "Paste a string first.";
	end

	local decoded = Codec.dec(body);
	if not decoded or decoded == "" then
		return false, L["SLOT_ERR_DECODE"] or "The string is corrupt or incomplete.";
	end

	local profile, err = Parser.Parse(decoded);
	if not profile then
		return false, (L["SLOT_ERR_PARSE"] or "Invalid string: ") .. tostring(err);
	end

	SaveBackup();

	local placed = 0;
	for slot = 1, MAX_ACTION_SLOTS do
		local entry = profile[slot];
		if entry ~= nil or GetActionInfo(slot) then
			PlaceOnSlot(slot, entry);
			if entry then placed = placed + 1; end
		end
	end

	local bound = 0;
	local binds = profile[KEYBIND_KEY];
	if type(binds) == "table" then
		for key, command in pairs(binds) do
			if type(key) == "string" and type(command) == "string" then
				if SetBinding(key, command) then bound = bound + 1; end
			end
		end
		-- BUG ORIGINAL: faltaba esta linea, asi que los bindeos se aplicaban
		-- pero no se guardaban y se perdian al desloguear.
		SaveBindings(GetCurrentBindingSet());
	end

	return true, placed, bound;
end

-- =========================================================
-- 9. BORRADOS
-- =========================================================
function K.SlotWipeBars()
	if InCombatLockdown() then
		return false, L["SLOT_ERR_COMBAT"] or "Can't do this in combat.";
	end
	SaveBackup();
	local n = 0;
	for slot = 1, MAX_ACTION_SLOTS do
		if GetActionInfo(slot) then
			PickupAction(slot);
			ClearCursor();
			n = n + 1;
		end
	end
	return true, n;
end

function K.SlotWipeMacros()
	if InCombatLockdown() then
		return false, L["SLOT_ERR_COMBAT"] or "Can't do this in combat.";
	end
	SaveBackup();
	-- De atras para adelante: al borrar una macro se corren los indices de
	-- las siguientes, asi que hacia adelante se saltearia una si o si.
	local n = 0;
	for i = 54, 1, -1 do
		if GetMacroInfo(i) then
			DeleteMacro(i);
			n = n + 1;
		end
	end
	return true, n;
end

function K.SlotResetBindings()
	SaveBackup();
	-- Se cargan los bindeos POR DEFECTO en vez de dejarlos vacios: sin
	-- bindeos el personaje no puede ni caminar.
	LoadBindings(DEFAULT_BINDINGS);
	SaveBindings(GetCurrentBindingSet());
	return true;
end

function K.SlotRestoreBackup()
	local backup = DB().SlotBackup;
	if not backup then
		return false, L["SLOT_ERR_NOBACKUP"] or "There is no backup yet.";
	end
	return K.SlotImport(backup);
end

-- =========================================================
-- 10. PERFILES POR PERSONAJE
-- Se guardan en NidhausUnitFramesDB, que es de CUENTA, asi que otro
-- personaje los ve. Detalle importante: las SavedVariables recien se
-- escriben a disco al DESLOGUEAR, no con /reload. Para pasar de un
-- personaje a otro hay que salir del juego en el medio.
-- =========================================================
local function CharKey()
	return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?");
end

function K.SlotSaveCurrentChar()
	local ok, data = pcall(K.SlotExport);
	if not ok or not data then return false; end
	DB().SlotProfiles[CharKey()] = data;
	return true, CharKey();
end

function K.SlotGetCharNames()
	local names = {};
	for key in pairs(DB().SlotProfiles) do names[#names + 1] = key; end
	table.sort(names);
	return names;
end

function K.SlotGetCharKey() return CharKey(); end

function K.SlotCopyFromChar(key)
	local data = DB().SlotProfiles[key];
	if not data then
		return false, L["SLOT_ERR_NOPROFILE"] or "That profile no longer exists.";
	end
	return K.SlotImport(data);
end

-- Guardar el estado del personaje al entrar, para que aparezca en la lista.
local init = CreateFrame("Frame");
init:RegisterEvent("PLAYER_LOGIN");
init:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	-- Un frame de espera: al momento del login las barras todavia pueden
	-- no estar pobladas.
	self:SetScript("OnUpdate", function(s)
		s:SetScript("OnUpdate", nil);
		pcall(K.SlotSaveCurrentChar);
	end);
end);

-- =========================================================
-- 11. SLASH
-- =========================================================
SLASH_NUFSLOT1 = "/nufslot";
SlashCmdList["NUFSLOT"] = function(msg)
	msg = string.lower(msg or "");

	if msg == "backup" then
		local ok, a = K.SlotRestoreBackup();
		if ok then Print(L["SLOT_BACKUP_DONE"] or "Backup restored.");
		else Print("|cffFF5555" .. tostring(a) .. "|r"); end
		return;
	end

	if msg == "wipebars" then
		local ok, n = K.SlotWipeBars();
		Print(ok and ("Casillas limpiadas: " .. n) or tostring(n));
		return;
	end

	if K.OpenSlotProfiles then
		K.OpenSlotProfiles();
	else
		Print("Panel: /nuf > Profiles");
	end
end
