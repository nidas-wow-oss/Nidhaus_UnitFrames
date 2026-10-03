local AddOnName, ns = ...;
local K, C, L = unpack(ns);







































local MAX_ACTION_SLOTS = 120;
local KEYBIND_KEY      = 999;

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff4FC3F7[NUF]|r " .. tostring(msg or ""));
end













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



	local function NextNibble(read, map)
		local code = "";
		while read() == "1" do code = code .. "1"; end
		code = code .. "0" .. read();
		return map[code] or "X";
	end

	function Codec.dec(data)

		if string.len(data) < 16 then return nil; end

		local map = {};
		for i = 1, 16 do
			map[huffman[i - 1]] = string.sub(data, i, i);
		end

		local bits = {};
		for i = 17, string.len(data) do
			local chunk = b64bytes[string.sub(data, i, i)];
			if not chunk then return nil; end
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















local Parser = {};
do
	local MAX_DEPTH = 12;

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
		i = SkipSpace(s, i + 1);

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


	function Parser.Parse(body)
		if type(body) ~= "string" then return nil, "entrada vacia"; end

		local text = "{" .. body .. "}";
		local out, stop, err = ReadTable(text, 1, 0);
		if out == nil then return nil, err or "formato invalido"; end




		stop = SkipSpace(text, stop);
		if stop <= string.len(text) then
			return nil, "sobra texto despues de la tabla";
		end

		return out;
	end
end








local function LongBracket(body)
	local level = "";
	while string.find(body, "]" .. level .. "]", 1, true) do
		level = level .. "=";
	end


	return "[" .. level .. "[\n" .. body .. "]" .. level .. "]";
end

local function QuoteString(s)
	s = string.gsub(s, "\\", "\\\\");
	s = string.gsub(s, '"', '\\"');
	s = string.gsub(s, "\n", "\\n");
	s = string.gsub(s, "\r", "\\r");
	return '"' .. s .. '"';
end







local function EntryString(data)
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
	if data.n then extra = extra .. ',["n"]=' .. QuoteString(tostring(data.n)); end
	if data.v then extra = extra .. ',["v"]=' .. QuoteString(tostring(data.v)); end
	return string.format('{["a"]="%s",["b"]=%s%s,}', data.a, value, extra);
end











local macroIconMap;
local function GetMacroIconMap()
	if macroIconMap then return macroIconMap; end
	macroIconMap = {};
	local total = (GetNumMacroIcons and GetNumMacroIcons()) or 0;
	for i = 1, total do
		local tex = GetMacroIconInfo(i);
		if tex then
			if not macroIconMap[tex] then macroIconMap[tex] = i; end


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











local function SpellStringFor(slot, id)
	local wantTex = GetActionTexture(slot);


	local nameA, rankA = GetSpellName(id, BOOKTYPE_SPELL);
	local texA = nameA and GetSpellTexture(id, BOOKTYPE_SPELL) or nil;


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


local function ReadSlot(slot)
	local kind, id, subType = GetActionInfo(slot);
	if not kind then return nil; end

	if kind == "spell" then
		local text, spellId = SpellStringFor(slot, id);
		if not text then return nil; end



		return { a = "S", b = text, s = spellId };
	end

	if kind == "item" then
		return { a = "I", b = tostring(id) };
	end

	if kind == "macro" then
		local name, texture, body = GetMacroInfo(id);
		if not name or not body then return nil; end
		local icon = IconIndexFor(texture);


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




















local NEB_KEY = 1000;

local NEB_CONFIG_KEYS = {
	LeftEnabled      = "boolean", RightEnabled      = "boolean",
	LeftNumButtons   = "number",  RightNumButtons   = "number",
	LeftLockButtons  = "boolean", RightLockButtons  = "boolean",
	LeftShiftOnlyIfUsed = "boolean",
};

local NEB_BUTTONS = {};
for _, side in ipairs({ "Left", "Right" }) do
	for i = 1, 12 do NEB_BUTTONS[#NEB_BUTTONS + 1] = "NEB_Bar" .. side .. "Button" .. i; end
end




local function NEBSettings()
	if type(NEB_DB) ~= "table" or type(NEB_DB.Settings) ~= "table" then return nil; end
	return NEB_DB.Settings;
end


local function NEBLive()
	return type(NEB_ABT_SetCommand) == "function" and _G["NEB_BarLeftButton1"] ~= nil;
end

local function NEBHas(btn, s)
	local t = btn["set" .. s .. "type"];
	return t ~= nil and t ~= "" and t ~= "none";
end

local function NEBSpellId(fullName)
	if type(NEB_ABT_FindSpellID) ~= "function" or not GetSpellLink then return nil; end
	local book = NEB_ABT_FindSpellID(fullName);
	local link = book and GetSpellLink(book, BOOKTYPE_SPELL);
	return link and tonumber(string.match(link, "spell:(%d+)")) or nil;
end


local function ReadNEBSet(st, name, s)
	local pre   = name .. "Set" .. s;
	local kind  = st[pre .. "ActualType"];
	local value = st[pre .. "Value"];
	local nm    = st[pre .. "Name"];
	local id    = st[pre .. "Id"];

	if kind == "spell" then
		if type(value) ~= "string" or value == "" then return nil; end


		local text = string.gsub(value, "%(%)$", "");
		return { a = "S", b = text, s = NEBSpellId(value) };

	elseif kind == "item" then
		local itemId = tonumber(id);
		if itemId then return { a = "I", b = tostring(itemId) }; end
		if type(value) == "string" and value ~= "" then return { a = "I", b = value }; end

	elseif kind == "macro" then

		local idx = (type(nm) == "string" and nm ~= "") and GetMacroIndexByName(nm) or 0;
		if not idx or idx == 0 then return nil; end
		local mname, tex, body = GetMacroInfo(idx);
		if not mname or not body then return nil; end
		local icon = IconIndexFor(tex);
		if string.find(body, "#show") == 1 then icon = 1; end
		return { a = "M", b = { b = mname, c = icon, d = body, e = (idx > 36) and 1 or nil } };

	elseif kind == "MOUNT" or kind == "CRITTER" then

		if type(nm) ~= "string" or nm == "" then return nil; end
		return { a = "C", b = { b = kind, c = tonumber(id) or 0 }, n = nm, v = value };
	end
	return nil;
end

local function NEBSectionString()
	local st = NEBSettings();
	if not st then return nil; end

	local parts = {};
	for _, name in ipairs(NEB_BUTTONS) do
		local sets = {};
		for s = 1, 2 do
			local ok, data = pcall(ReadNEBSet, st, name, s);
			if ok and data then
				sets[#sets + 1] = string.format("[%d]=%s,", s, EntryString(data));
			end
		end
		if #sets > 0 then
			parts[#parts + 1] = string.format("[%s]={%s},", QuoteString(name), table.concat(sets));
		end
	end

	local cfg = {};
	local c = NEB_DB.Config;
	if type(c) == "table" then
		for key, kind in pairs(NEB_CONFIG_KEYS) do
			if type(c[key]) == kind then
				cfg[#cfg + 1] = string.format("[%s]=%s,", QuoteString(key), tostring(c[key]));
			end
		end
	end

	return string.format('[%d]={["b"]={%s},["c"]={%s},},',
		NEB_KEY, table.concat(parts), table.concat(cfg));
end




function K.SlotExport()
	local parts = {};

	for slot = 1, MAX_ACTION_SLOTS do
		local data = ReadSlot(slot);
		if data then
			parts[#parts + 1] = string.format("[%d]=%s,", slot, EntryString(data));
		end
	end


	local neb = NEBSectionString();
	if neb then parts[#parts + 1] = neb; end

	local binds = {};
	for key, command in pairs(ReadBindings()) do
		binds[#binds + 1] = string.format("[%s]=%s,", QuoteString(key), QuoteString(command));
	end
	parts[#parts + 1] = string.format("[%d]={%s},", KEYBIND_KEY, table.concat(binds));

	local header = {
		"@ NUF Slot Profile - " .. date(),
		"@ " .. (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?"),
		"@ " .. (UnitClass("player") or "?") .. " nivel " .. (UnitLevel("player") or 0),



		"@ CLASS " .. (select(2, UnitClass("player")) or "?"),
		"@ Formato compatible con MySlot.",
		"@ --------------------",
		"",
	};

	return table.concat(header, "\n") .. Codec.enc(table.concat(parts));
end








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
			fallback = fallback or i;
		end
		i = i + 1;
	end



	if not fallback and spellId then
		local byId = GetSpellInfo(spellId);
		if byId and byId ~= wanted then
			return FindSpellBookSlot(byId);
		end
	end

	return fallback;
end





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
		if not book then return; end
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


	if not CursorHasSpell() and not CursorHasItem() and not GetCursorInfo() then
		ClearCursor();
		return;
	end

	PlaceAction(slot);
	ClearCursor();
end









local function NEBResolve(entry)
	if entry.a == "S" then
		local book = FindSpellBookSlot(entry.b, entry.s);
		if not book then return nil; end


		local nm, rank = GetSpellName(book, BOOKTYPE_SPELL);
		if not nm then return nil; end
		return "spell", nm .. "(" .. (rank or "") .. ")", "spell", nm, "";

	elseif entry.a == "I" then
		local id = tonumber(entry.b);
		local itemName, link = GetItemInfo(id or entry.b);


		local value = itemName or (id and ("item:" .. id)) or entry.b;
		return "item", value, "item", link or "", id or "";

	elseif entry.a == "M" then
		local idx = EnsureMacro(entry.b);
		local mname = idx and GetMacroInfo(idx);
		if not mname then return nil; end
		return "macro", idx, "macro", mname, "";

	elseif entry.a == "C" then
		local kind = type(entry.b) == "table" and entry.b.b;
		if (kind ~= "MOUNT" and kind ~= "CRITTER") or not entry.n then return nil; end
		local id = type(NEB_ABT_FindCompanionID) == "function"
			and NEB_ABT_FindCompanionID(kind, entry.n);
		if not id then return nil; end
		local _, cname, spellId = GetCompanionInfo(kind, id);
		local spellName = (spellId and GetSpellInfo(spellId)) or entry.v;
		if not spellName then return nil; end
		return "spell", spellName, kind, cname or entry.n, id;
	end
	return nil;
end

local function NEBSet(btn, s, command, value, actualType, name, id)


	if s == GetActiveTalentGroup() and btn:GetAttribute("type") == nil then
		btn:SetAttribute("type", "none");
	end
	local ok = pcall(NEB_ABT_SetCommand, btn, command, value, actualType, name, id, false, s);
	return ok;
end

local function NEBImport(sec)
	if type(sec) ~= "table" or not NEBLive() then return 0; end

	local buttons = type(sec.b) == "table" and sec.b or {};
	local placed = 0;
	for _, name in ipairs(NEB_BUTTONS) do
		local btn = _G[name];
		if btn then
			local sets = buttons[name];
			for s = 1, 2 do
				local entry = type(sets) == "table" and sets[s] or nil;
				if type(entry) == "table" and entry.a then
					local command, value, actualType, nm, id = NEBResolve(entry);
					if command and NEBSet(btn, s, command, value, actualType, nm, id) then
						placed = placed + 1;
					end
				elseif NEBHas(btn, s) then

					NEBSet(btn, s, "none", "", "", "", "");
				end
			end
		end
	end


	if type(sec.c) == "table" and type(NEB_Config) == "table" then
		local changed = false;
		for key, kind in pairs(NEB_CONFIG_KEYS) do
			local v = sec.c[key];
			if type(v) == kind then
				if kind == "number" then v = math.max(1, math.min(12, math.floor(v))); end
				if NEB_Config[key] ~= v then NEB_Config[key] = v; changed = true; end
			end
		end


		if changed and type(NEB_ApplyConfig) == "function" then pcall(NEB_ApplyConfig); end
	end

	return placed;
end



local function NEBWipeActive()
	if not NEBLive() then return 0; end
	local s, n = GetActiveTalentGroup(), 0;
	for _, name in ipairs(NEB_BUTTONS) do
		local btn = _G[name];
		if btn and NEBHas(btn, s) then
			NEBSet(btn, s, "none", "", "", "", "");
			n = n + 1;
		end
	end
	return n;
end




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




function K.SlotImport(text)


	if InCombatLockdown() then
		return false, L["SLOT_ERR_COMBAT"] or "Can't do this in combat.";
	end

	if type(text) ~= "string" or text == "" then
		return false, L["SLOT_ERR_EMPTY"] or "Paste a string first.";
	end


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



	placed = placed + NEBImport(profile[NEB_KEY]);

	local bound = 0;
	local binds = profile[KEYBIND_KEY];
	if type(binds) == "table" then
		for key, command in pairs(binds) do
			if type(key) == "string" and type(command) == "string" then
				if SetBinding(key, command) then bound = bound + 1; end
			end
		end


		SaveBindings(GetCurrentBindingSet());
	end

	return true, placed, bound;
end




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
	n = n + NEBWipeActive();
	return true, n;
end

function K.SlotWipeMacros()
	if InCombatLockdown() then
		return false, L["SLOT_ERR_COMBAT"] or "Can't do this in combat.";
	end
	SaveBackup();


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








local function CharKey()
	return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?");
end

function K.SlotSaveCurrentChar()
	local ok, data = pcall(K.SlotExport);
	if not ok or not data then return false; end
	DB().SlotProfiles[CharKey()] = data;
	return true, CharKey();
end















local function ClassTokenOf(data)
	if type(data) ~= "string" then return nil; end
	local token = string.match(data, "@ CLASS (%u+)");
	if token then return token; end

	local shown = string.match(data, "@ ([^\n]-) nivel %d");
	if shown and shown ~= "" then return "LOC:" .. shown; end
	return nil;
end

function K.SlotGetCharNames()
	local names, hidden = {}, 0;
	local loc, mine = UnitClass("player");
	local mineLoc = loc and ("LOC:" .. loc) or nil;
	for key, data in pairs(DB().SlotProfiles) do
		local c = ClassTokenOf(data);


		if (not c) or c == mine or (mineLoc and c == mineLoc) then
			names[#names + 1] = key;
		else
			hidden = hidden + 1;
		end
	end
	table.sort(names);
	return names, hidden;
end

function K.SlotGetCharKey() return CharKey(); end

function K.SlotCopyFromChar(key)
	local data = DB().SlotProfiles[key];
	if not data then
		return false, L["SLOT_ERR_NOPROFILE"] or "That profile no longer exists.";
	end
	return K.SlotImport(data);
end


local init = CreateFrame("Frame");
init:RegisterEvent("PLAYER_LOGIN");






init:RegisterEvent("PLAYER_LOGOUT");
init:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGOUT" then
		pcall(K.SlotSaveCurrentChar);
		return;
	end
	self:UnregisterEvent("PLAYER_LOGIN");


	self:SetScript("OnUpdate", function(s)
		s:SetScript("OnUpdate", nil);
		pcall(K.SlotSaveCurrentChar);
	end);
end);




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
