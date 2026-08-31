local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- NUF_AbbreviatedStatus.lua  (reimplementacion propia)
-- Idea original: Abbreviated Status Text (RomanSpector).
--
-- QUE HACE: acorta el numero de vida/mana de los marcos de unidad
-- (12.3k en vez de 12345) y puede mostrar el porcentaje al lado.
--
-- POR QUE UN SOLO ARCHIVO: el addon suelto arrastraba toda la suite Ace3
-- (AceAddon/AceDB/AceConsole/CallbackHandler/LibStub), LibBetterBlizzOptions
-- y archivos de idioma, mas un panel en las Opciones de Interfaz de
-- Blizzard. Todo ese andamiaje era para guardar dos ajustes y dibujar su
-- menu. Dentro de NUF no hace falta: usamos la DB y el menu de NUF. Asi
-- que esta version reescribe la logica sin ninguna dependencia externa y
-- SIN registrar nada en las Opciones de Blizzard (por eso ya no aparece
-- ahi; solo se abre desde el panel de NUF).
-- =========================================================

-- Sufijos de abreviacion. Son globales de Blizzard (localizados); dejamos
-- un fallback por las dudas.
local CAP1 = FIRST_NUMBER_CAP_NO_SPACE  or "k";
local CAP2 = SECOND_NUMBER_CAP_NO_SPACE or "m";
local CAP3 = THIRD_NUMBER_CAP_NO_SPACE  or "b";
local CAP4 = FOURTH_NUMBER_CAP_NO_SPACE or "t";

local DATA = {
	{ breakpoint = 10000000000000, abbr = CAP4, sig = 1000000000000, frac = 1  },
	{ breakpoint = 1000000000000,  abbr = CAP4, sig = 100000000000,  frac = 10 },
	{ breakpoint = 10000000000,    abbr = CAP3, sig = 1000000000,    frac = 1  },
	{ breakpoint = 1000000000,     abbr = CAP3, sig = 100000000,     frac = 10 },
	{ breakpoint = 10000000,       abbr = CAP2, sig = 1000000,       frac = 1  },
	{ breakpoint = 1000000,        abbr = CAP2, sig = 100000,        frac = 10 },
	{ breakpoint = 10000,          abbr = CAP1, sig = 1000,          frac = 1  },
	{ breakpoint = 1000,           abbr = CAP1, sig = 100,           frac = 10 },
};

-- ---------------------------------------------------------
-- DB (una sub-tabla de la propia de NUF: no necesita SavedVariable aparte)
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	local db = NidhausUnitFramesDB.AbbrevStatus;
	if not db then
		db = { prefix = 3, remainder = 1, units = {} };
		NidhausUnitFramesDB.AbbrevStatus = db;
	end
	return db;
end

-- =========================================================
-- UNA POSICION POR TEMA VISUAL
--
-- El problema: los marcos de cada tema tienen las barras en distinto
-- lugar y de distinto tamaño. Un offset que centra el texto en el tema
-- Light lo deja corrido en Compact, y en el marco de grupo Compact 2 la
-- barra ni siquiera mide lo mismo que la de Blizzard.
--
-- Antes los 8 offsets vivian sueltos en la config de la unidad, o sea uno
-- solo para todos los temas: acomodabas el texto en uno y lo rompias en
-- los otros. Es el mismo problema que tenian los buffs de grupo.
--
-- Ahora cada unidad guarda un juego de offsets POR TEMA:
--
--     db.units.player.pos["uf:Light"]   = { hpNumX = ..., ... }
--     db.units.party.pos["party:PW2"]   = { ... }
--
-- Que tema manda depende de la unidad:
--
--     player / target / focus / pet  -> el desplegable "Visual Theme"
--     party                          -> el estilo de marco de grupo
--     arena                          -> el estilo de marco de arena
--
-- Y si el "Custom Skin" esta apagado, los marcos son los de Blizzard
-- pelados: ese es un tema mas, aparte de los otros.
-- =========================================================
local function VisualTheme()
	if C.UnitFrameCustomTexture ~= true then return "Blizzard"; end
	-- Mismo orden de prioridad que el desplegable en OptionsPanel.lua.
	if C.AsuriFrames then return "Asuri"; end
	if C.pwFrames    then return "Compact"; end
	if C.darkFrames  then return "Dark"; end
	return "Light";
end

-- SIN CONCATENAR EN CALIENTE.
--
-- ThemeKey se llama en cada refresco de barra de estado — jugador,
-- objetivo, grupo, arena Y todas las placas de nombre — o sea cientos de
-- veces por segundo en pelea. Armar la cadena ahi ("uf:" .. tema) creaba
-- un string nuevo cada vez y le daba trabajo al recolector de basura al
-- pedo.
--
-- Estas tablas memorizan la cadena la primera vez que se pide cada tema y
-- despues la devuelven hecha. Son cinco o seis valores en total.
local function KeyCache(prefix)
	return setmetatable({}, { __index = function(self, k)
		local v = prefix .. tostring(k);
		rawset(self, k, v);
		return v;
	end });
end
local UF_KEYS    = KeyCache("uf:");
local PARTY_KEYS = KeyCache("party:");
local ARENA_KEYS = KeyCache("arena:");

local function ThemeKey(unit)
	if unit == "party" then
		return PARTY_KEYS[(K.GetPartyFrameStyle and K.GetPartyFrameStyle())
			or C.PartyFrameStyle or "Default"];
	end
	if unit == "arena" then
		if C.ArenaFlatMode then return ARENA_KEYS["Flat"]; end
		return ARENA_KEYS[C.ArenaFrameStyle or "Default"];
	end
	return UF_KEYS[VisualTheme()];
end

-- Nombre lindo para mostrar arriba de los sliders, asi se ve que ranura
-- se esta editando.
local function ThemeLabel(unit)
	local k = ThemeKey(unit);
	return (k:gsub("^uf:", ""):gsub("^party:", ""):gsub("^arena:", ""));
end

local POS_FIELDS = {
	"hpNumX", "hpNumY", "hpPctX", "hpPctY",
	"mpNumX", "mpNumY", "mpPctX", "mpPctY",
};

-- DEFAULTS POR TEMA.
--
-- Aca se hornean las posiciones que quedaron bien probadas en el juego.
-- Clave = la de ThemeKey; adentro, una entrada por unidad. Lo que no
-- figure arranca en cero, que es el centro natural de la barra.
-- El juego que quedo probado en el marco del jugador. Los marcos de
-- Asuri y de Compact ponen las barras en el mismo sitio en las tres
-- unidades (jugador, objetivo y foco), asi que el mismo offset les sirve
-- a las tres y no hay que acomodarlas una por una.
local PLAYER_LIKE = {
	hpNumX = -1, hpNumY = -6, hpPctX =  1, hpPctY = -6,
	mpNumX = -3, mpNumY =  0, mpPctX =  2, mpPctY =  0,
};

-- Los cuatro temas de marcos custom comparten el mismo juego: las barras
-- estan en el mismo sitio en todos, lo que cambia es el arte de alrededor.
-- El tema "Blizzard" (Custom Skin apagado) NO figura a proposito: ahi los
-- marcos son los del juego pelados y el texto va donde lo pone Blizzard.
local POS_DEFAULTS = {
	["uf:Asuri"] = {
		player = PLAYER_LIKE, target = PLAYER_LIKE, focus = PLAYER_LIKE,
	},
	["uf:Compact"] = {
		player = PLAYER_LIKE, target = PLAYER_LIKE, focus = PLAYER_LIKE,
	},
	["uf:Light"] = {
		player = PLAYER_LIKE, target = PLAYER_LIKE, focus = PLAYER_LIKE,
	},
	["uf:Dark"] = {
		player = PLAYER_LIKE, target = PLAYER_LIKE, focus = PLAYER_LIKE,
	},
};

-- Config por unidad. Por defecto viene TODO activado (numero y porcentaje,
-- vida y mana) y la unidad habilitada.
local function UnitCfg(unit)
	local db = DB();
	if not db.units[unit] then
		db.units[unit] = {
			on = true,
			hpNum = true, hpPct = true, mpNum = true, mpPct = true,
		};
	end
	-- 'on' no existia en versiones viejas de la config: por defecto encendida.
	if db.units[unit].on == nil then db.units[unit].on = true; end
	return db.units[unit];
end

-- Los offsets de la unidad para el tema que este activo.
--
-- La primera vez que se pide una ranura, se siembra con el default
-- horneado del tema (POS_DEFAULTS) y, si no hay, en cero.
local function UnitPos(unit)
	local cfg = UnitCfg(unit);
	if not cfg.pos then cfg.pos = {}; end

	-- MIGRACION DE LA CONFIG VIEJA.
	--
	-- Antes los offsets estaban sueltos en cfg. Se mudan UNA sola vez a la
	-- ranura del tema activo, que es el que el usuario tenia puesto cuando
	-- los acomodo. Asi nadie pierde lo que ya tenia ajustado.
	if not cfg._posMigrated then
		local old, any = {}, false;
		for _, f in ipairs(POS_FIELDS) do
			if type(cfg[f]) == "number" and cfg[f] ~= 0 then old[f] = cfg[f]; any = true; end
			cfg[f] = nil;
		end
		if any then cfg.pos[ThemeKey(unit)] = old; end
		cfg._posMigrated = true;
	end

	local key = ThemeKey(unit);
	local slot = cfg.pos[key];

	-- UNA RANURA VACIA CUENTA COMO "NUNCA TOCADA".
	--
	-- Si visitaste un tema antes de que ese tema tuviera default horneado,
	-- te quedo la ranura creada y sin campos. Como existe, el default nuevo
	-- no entraba nunca y el texto seguia en el centro de la barra.
	--
	-- Vacia solo puede significar eso — cualquier ajuste tuyo, aunque sea
	-- un cero explicito, deja los ocho campos escritos — asi que se puede
	-- sembrar sin pisarle nada a nadie.
	if slot then
		local empty = true;
		for _ in pairs(slot) do empty = false; break; end
		if empty then slot = nil; end
	end

	if not slot then
		local d = POS_DEFAULTS[key] and POS_DEFAULTS[key][unit];
		slot = {};
		if d then for _, f in ipairs(POS_FIELDS) do slot[f] = d[f] or 0; end end
		cfg.pos[key] = slot;
	end
	return slot;
end

local VALID = {
	player = true, target = true, focus = true,
	pet = true, party = true, arena = true,
};



-- ---------------------------------------------------------
-- Formateo del numero
-- ---------------------------------------------------------
local function Abbrev(value, remainder, prefix)
	remainder = remainder or 1;
	prefix    = prefix or 3;
	local index = (prefix >= 3) and (prefix - 3) or 0;
	for _, d in ipairs(DATA) do
		if value >= d.breakpoint then
			local finalValue = string.format("%." .. remainder .. "f", (value / d.sig) / d.frac);
			local cur = DATA[#DATA - index].breakpoint;
			if prefix > 1 and cur <= d.breakpoint then
				return finalValue .. d.abbr;
			else
				return finalValue;
			end
		end
	end
	return tostring(value);
end

-- Solo para la etiqueta del slider "Abreviar desde".
local function AbbrevThreshold(value)
	for _, d in ipairs(DATA) do
		if value >= d.breakpoint then
			return (math.floor(value / d.sig) / d.frac) .. d.abbr;
		end
	end
	return tostring(value);
end

local function IsOn()
	return K.IsModuleEnabled and K.IsModuleEnabled("AbbreviatedStatus");
end

-- ---------------------------------------------------------
-- El hook: corre despues del texto normal de Blizzard
-- ---------------------------------------------------------
-- Guarda los anclajes ORIGINALES del texto de Blizzard (la primera vez, antes
-- de tocarlo). Cada barra tiene los suyos y NO son "centrados": por eso, al
-- apagar el modulo, recentrar a mano dejaba el texto corrido hacia arriba.
local function CaptureOrigPoints(self, fs)
	-- Se recaptura SIEMPRE que el texto este en su posicion natural (o sea,
	-- mientras nosotros no lo hayamos movido). Es clave por el "Custom Skin":
	-- con el skin activo NUF ancla el texto con su propio offset (CENTER 0,-5)
	-- y ese es el punto bueno; si guardaramos solo el de Blizzard, al aplicar
	-- la abreviacion el texto quedaba corrido hacia arriba.
	if self._nufMoved then return; end
	local pts = {};
	for i = 1, (fs:GetNumPoints() or 0) do
		local p, rel, rp, x, y = fs:GetPoint(i);
		if p then pts[#pts + 1] = { p, rel, rp, x, y }; end
	end
	if #pts > 0 then self._nufOrigPts = pts; end
end

-- Reancla el texto CENTRADO en la barra, mas el offset del panel.
--
-- Antes se usaba como base el anclaje que hubiera en ese momento. La idea
-- era respetar el ajuste del skin custom, pero el resultado era que el
-- texto terminaba en un lugar distinto segun estuviera el Custom Skin
-- prendido o apagado (el skin lo baja 5px, y ademas la barra cambia de
-- alto) — y al togglear se notaba el salto.
--
-- Ahora la base es siempre el centro de la barra: como el anclaje es
-- RELATIVO a la barra, sigue funcionando con la barra alta del skin y con
-- la baja de Blizzard, y queda en el mismo lugar en los dos casos.
local function SetWithOffset(self, fs, dx, dy)
	fs:ClearAllPoints();
	fs:SetPoint("CENTER", self, "CENTER", dx, dy);
end

-- Devuelve el texto exactamente a donde lo tenia Blizzard.
local function RestoreOrigPoints(self, fs)
	local pts = self._nufOrigPts;

	-- SIN POSICION GUARDADA: centrar en la barra, que es donde la ponen
	-- tanto Blizzard como el skin custom.
	--
	-- Antes esto hacia "return" y no tocaba nada, y ahi estaba el bug del
	-- texto corrido: CaptureOrigPoints solo guarda si el texto TENIA
	-- anclajes en ese instante (#pts > 0). Si justo no los tenia, quedaba
	-- nil, y entonces al apagar el modulo no habia nada que restaurar: el
	-- texto se quedaba donde lo habia dejado la abreviacion, corrido, y de
	-- ahi no salia mas ni apagando la opcion.
	--
	-- Como el anclaje es RELATIVO a la barra, centrar sirve igual con la
	-- barra alta del skin y con la baja de Blizzard.
	if not pts or #pts == 0 then
		fs:ClearAllPoints();
		fs:SetPoint("CENTER", self, "CENTER", 0, 0);
		return;
	end

	fs:ClearAllPoints();
	for _, pt in ipairs(pts) do
		pcall(fs.SetPoint, fs, pt[1], pt[2] or self, pt[3] or pt[1], pt[4] or 0, pt[5] or 0);
	end
end

local function ApplyBar(self)
	local statusText = self.TextString;
	if not statusText then return; end

	CaptureOrigPoints(self, statusText);

	-- Modulo apagado: dejamos el texto normal de Blizzard y escondemos lo
	-- nuestro. Restauramos el anclaje ORIGINAL (no un centrado inventado).
	if not IsOn() then
		if self._nufPct then self._nufPct:Hide(); end
		if self._nufMoved then
			RestoreOrigPoints(self, statusText);
			self._nufMoved = false;
		end
		return;
	end

	local unit = self.unit;
	if not unit then return; end

	-- CACHEADA EN LA BARRA, como _nufIsHealth de mas abajo.
	--
	-- gsub devuelve un string NUEVO cada vez que corre, y esto corre en
	-- cada refresco de cada barra con texto del juego. La unidad de una
	-- barra no cambia nunca ("party3" es siempre "party3"), asi que se
	-- calcula una vez y queda guardada.
	local ukey = self._nufUKey;
	if ukey == nil or self._nufUKeyFor ~= unit then
		ukey = string.gsub(unit, "%d", "");
		self._nufUKey = ukey;
		self._nufUKeyFor = unit;
	end
	if not VALID[ukey] then return; end

	-- Unidad desactivada desde el menu: se deja tal cual la trae Blizzard.
	local ucfg = UnitCfg(ukey);
	if not ucfg.on then
		if self._nufPct then self._nufPct:Hide(); end
		if self._nufMoved then
			RestoreOrigPoints(self, statusText);
			self._nufMoved = false;
		end
		return;
	end

	-- Vida o mana? (cacheado)
	local isHealth = self._nufIsHealth;
	if isHealth == nil then
		local n = self:GetName();
		isHealth = (n and string.find(n, "HealthBar")) and true or false;
		self._nufIsHealth = isHealth;
	end

	local cfg = UnitCfg(ukey);
	local wantNum = isHealth and cfg.hpNum or cfg.mpNum;
	local wantPct = isHealth and cfg.hpPct or cfg.mpPct;

	local db = DB();
	local value = self:GetValue() or 0;
	local _, vmax = self:GetMinMaxValues();

	-- FontString propia para el porcentaje (creada la primera vez)
	local pctFS = self._nufPct;
	if wantPct and not pctFS then
		pctFS = self:CreateFontString(nil, "OVERLAY", "TextStatusBarText");
		self._nufPct = pctFS;
	end

	-- Numero abreviado
	if wantNum then
		if value > 0 then
			statusText:SetText(Abbrev(value, db.remainder, db.prefix));
		end
		statusText:Show();
	else
		statusText:Hide();
	end

	-- Porcentaje
	local pctShown = false;
	if wantPct and pctFS then
		if vmax and vmax > 0 and value > 0 then
			pctFS:SetText(string.format("%d%%", value / vmax * 100 + 0.5));
			pctFS:Show();
			pctShown = true;
		else
			pctFS:Hide();
		end
	elseif pctFS then
		pctFS:Hide();
	end

	-- Offsets configurables por texto (numero / porcentaje) segun la barra.
	local numX, numY, pctX, pctY;
	local pos = UnitPos(ukey);   -- ranura del tema visual activo
	if isHealth then
		numX, numY = pos.hpNumX or 0, pos.hpNumY or 0;
		pctX, pctY = pos.hpPctX or 0, pos.hpPctY or 0;
	else
		numX, numY = pos.mpNumX or 0, pos.mpNumY or 0;
		pctX, pctY = pos.mpPctX or 0, pos.mpPctY or 0;
	end

	-- Posicion: si se ven los dos, numero a la derecha y % a la izquierda;
	-- si no, todo centrado. En ambos casos se suman los offsets del panel.
	if wantNum and pctShown then
		statusText:ClearAllPoints();
		statusText:SetPoint("RIGHT", self, "RIGHT", numX, numY);
		pctFS:ClearAllPoints();
		pctFS:SetPoint("LEFT", self, "LEFT", pctX, pctY);
		self._nufMoved = true;
	else
		-- Un solo texto visible: se respeta el anclaje natural de la barra
		-- (Blizzard o el del skin custom) y se le suma el offset del panel.
		SetWithOffset(self, statusText, numX, numY);
		if pctFS then
			SetWithOffset(self, pctFS, pctX, pctY);
		end
		-- Marcamos como movido solo si el usuario puso algun offset; si no,
		-- queda en su sitio natural y se puede seguir recapturando.
		self._nufMoved = (numX ~= 0 or numY ~= 0 or pctX ~= 0 or pctY ~= 0);
	end
end

-- Envuelto en pcall: este hook corre en CADA actualizacion de barra de
-- estado del juego (jugador, objetivo, party, arena y TODAS las placas de
-- nombre). Si ApplyBar tirara un error, se repetiria cientos de veces por
-- segundo y podria congelar el cliente. Con pcall, un error puntual se
-- traga y no frena el juego.
hooksecurefunc("TextStatusBar_UpdateTextString", function(self)
	pcall(ApplyBar, self);
end);

-- ---------------------------------------------------------
-- Refresco de todas las barras (al prender/apagar o al cambiar ajustes)
-- ---------------------------------------------------------
local UNIT_BARS = {
	"PlayerFrameHealthBar", "PlayerFrameManaBar",
	"PetFrameHealthBar",    "PetFrameManaBar",
	"TargetFrameHealthBar", "TargetFrameManaBar",
	"FocusFrameHealthBar",  "FocusFrameManaBar",
};
for i = 1, 4 do
	table.insert(UNIT_BARS, "PartyMemberFrame" .. i .. "HealthBar");
	table.insert(UNIT_BARS, "PartyMemberFrame" .. i .. "ManaBar");
end
for i = 1, 5 do
	table.insert(UNIT_BARS, "ArenaEnemyFrame" .. i .. "HealthBar");
	table.insert(UNIT_BARS, "ArenaEnemyFrame" .. i .. "ManaBar");
end

local function RefreshAllBars()
	if not TextStatusBar_UpdateTextString then return; end
	for _, name in ipairs(UNIT_BARS) do
		local bar = _G[name];
		if bar then pcall(TextStatusBar_UpdateTextString, bar); end
	end
end
K.RefreshAbbreviatedStatusBars = RefreshAllBars;

-- La llama PlayerFrame al prender/apagar el "Custom Skin": ese skin reancla
-- los textos, asi que hay que olvidar la posicion guardada y volver a
-- capturarla, si no el texto queda con el anclaje del modo anterior.
function K.InvalidateAbbrevAnchors()
	for _, name in ipairs(UNIT_BARS) do
		local bar = _G[name];
		if bar then
			-- PRIMERO devolver el texto a su lugar, MIENTRAS todavia tenemos
			-- guardado cual era. Si se borra la posicion con el texto todavia
			-- movido, la proxima captura toma la posicion CORRIDA como si
			-- fuera la original — y el desplazamiento se vuelve permanente.
			if bar._nufMoved and bar.TextString then
				pcall(RestoreOrigPoints, bar, bar.TextString);
			end
			bar._nufOrigPts = nil;
			bar._nufMoved   = false;
		end
	end
	RefreshAllBars();
end

-- ---------------------------------------------------------
-- Menu propio (estilo NUF)
-- Arriba el formato (decimales + desde que numero abreviar); abajo una
-- grilla unidad x (vida nº, vida %, mana nº, mana %).
-- ---------------------------------------------------------
local win;

local UNITS = {
	{ key = "player", label = PLAYER or "Player" },
	{ key = "target", label = TARGET or "Target" },
	{ key = "focus",  label = FOCUS  or "Focus"  },
	{ key = "pet",    label = PET    or "Pet"    },
	{ key = "party",  label = PARTY  or "Party"  },
	{ key = "arena",  label = ARENA  or "Arena"  },
};

-- head = texto de la columna; field = campo en UnitCfg
local COLS = {
	{ field = "hpNum", head = "HP #" },
	{ field = "hpPct", head = "HP %" },
	{ field = "mpNum", head = "MP #" },
	{ field = "mpPct", head = "MP %" },
};
local COL_X = { 165, 230, 300, 365 };

-- Panel de POSICION (derecha): 8 sliders, en 2 columnas de 4.
local OFF_LAYOUT = {
	{ col = 1, row = 1, field = "hpNumX", label = "HP #  X" },
	{ col = 1, row = 2, field = "hpNumY", label = "HP #  Y" },
	{ col = 1, row = 3, field = "hpPctX", label = "HP %  X" },
	{ col = 1, row = 4, field = "hpPctY", label = "HP %  Y" },
	{ col = 2, row = 1, field = "mpNumX", label = "MP #  X" },
	{ col = 2, row = 2, field = "mpNumY", label = "MP #  Y" },
	{ col = 2, row = 3, field = "mpPctX", label = "MP %  X" },
	{ col = 2, row = 4, field = "mpPctY", label = "MP %  Y" },
};
local OFF_COLX = { [1] = 425, [2] = 555 };
local OFF_ROWY = { [1] = -128, [2] = -176, [3] = -224, [4] = -272 };

local function RefreshWindow()
	if not win then return; end
	win._syncing = true;
	local db = DB();
	win.remSlider:SetValue(db.remainder or 1);
	win.preSlider:SetValue(db.prefix or 3);
	if _G["NUF_AbbrevPreSliderText"] then
		_G["NUF_AbbrevPreSliderText"]:SetText(
			(L["ABBREV_FROM"] or "Abbreviate from") .. ": " .. AbbrevThreshold(
				DATA[#DATA - ((db.prefix >= 3) and (db.prefix - 3) or 0)].breakpoint));
	end
	for _, cb in ipairs(win.cells) do
		local cfg = UnitCfg(cb._unit);
		cb:SetChecked(cfg[cb._field] and true or false);
		-- Los maestros ademas habilitan/deshabilitan su fila
		if cb._refreshRow then cb._refreshRow(); end
	end

	-- Sliders de posicion de la unidad seleccionada
	if win.offSliders then
		local cfg = UnitPos(win.selUnit or "player");
		for i, s in ipairs(win.offSliders) do
			local v = cfg[s._field] or 0;
			s:SetValue(v);
			if _G["NUF_AbbrevOff" .. i .. "Text"] then
				_G["NUF_AbbrevOff" .. i .. "Text"]:SetText(s._label .. "  " .. v);
			end
		end
		if win.unitDD then UIDropDownMenu_SetSelectedValue(win.unitDD, win.selUnit or "player"); end
	end

	if win.themeFS then
		local u = win.selUnit or "player";
		win._themeKey = ThemeKey(u);
		win.themeFS:SetText("|cff8EAEC9" .. (L["ABBREV_POS_THEME"] or "Theme")
			.. ":|r |cffFFD100" .. ThemeLabel(u) .. "|r");
	end

	win._syncing = false;
end

local function BuildWindow()
	win = CreateFrame("Frame", "NUF_AbbrevStatusWindow", UIParent);
	-- Cajita con el valor debajo de cada slider (UIKit).
	if K.UI and K.UI.AutoRestyle then K.UI.AutoRestyle(win); end

	win:SetSize(690, 430);
	win:SetPoint("CENTER");
	win:SetFrameStrata("FULLSCREEN_DIALOG");
	win:EnableMouse(true);
	win:SetMovable(true);
	win:RegisterForDrag("LeftButton");
	win:SetScript("OnDragStart", win.StartMoving);
	win:SetScript("OnDragStop",  win.StopMovingOrSizing);
	win:SetClampedToScreen(true);
	win:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	});

	local titleBox = CreateFrame("Frame", nil, win);
	titleBox:SetSize(260, 30);
	titleBox:SetPoint("TOP", win, "TOP", 0, 6);
	titleBox:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
		tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	});
	titleBox:SetBackdropColor(0.10, 0.10, 0.10, 1.0);
	local title = titleBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	title:SetPoint("CENTER", titleBox, "CENTER", 0, 1);
	title:SetText(L["MOD_ABBREV_STATUS"] or "Abbreviated Status");

	local close = CreateFrame("Button", nil, win, "UIPanelCloseButton");
	close:SetPoint("TOPRIGHT", -4, -4);
	close:SetScript("OnClick", function() win:Hide(); end);

	-- ── FORMATO ──
	local fmtH = win:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	fmtH:SetPoint("TOPLEFT", 20, -40);
	fmtH:SetText((K.UI and K.UI.Header("Format")) or "|cffFFD100Format|r");

	local rem = CreateFrame("Slider", "NUF_AbbrevRemSlider", win, "OptionsSliderTemplate");
	rem:SetPoint("TOPLEFT", 30, -78);
	rem:SetWidth(150);
	rem:SetMinMaxValues(0, 2);
	rem:SetValueStep(1);
	_G["NUF_AbbrevRemSliderLow"]:SetText("0");
	_G["NUF_AbbrevRemSliderHigh"]:SetText("2");
	_G["NUF_AbbrevRemSliderText"]:SetText(L["ABBREV_DECIMALS"] or "Decimals");
	rem:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v + 0.5);
		if win._syncing then return; end
		DB().remainder = v;
		RefreshAllBars();
	end);
	win.remSlider = rem;

	local pre = CreateFrame("Slider", "NUF_AbbrevPreSlider", win, "OptionsSliderTemplate");
	pre:SetPoint("TOPLEFT", 240, -78);
	pre:SetWidth(150);
	pre:SetMinMaxValues(3, 8);
	pre:SetValueStep(1);
	_G["NUF_AbbrevPreSliderLow"]:SetText("");
	_G["NUF_AbbrevPreSliderHigh"]:SetText("");
	pre:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v + 0.5);
		local idx = (v >= 3) and (v - 3) or 0;
		_G["NUF_AbbrevPreSliderText"]:SetText(
			(L["ABBREV_FROM"] or "Abbreviate from") .. ": " .. AbbrevThreshold(DATA[#DATA - idx].breakpoint));
		if win._syncing then return; end
		DB().prefix = v;
		RefreshAllBars();
	end);
	win.preSlider = pre;

	if K.UI and K.UI.Separator then K.UI.Separator(win, 16, -118, 408); end

	-- ── GRILLA ──
	local onHead = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	onHead:SetPoint("CENTER", win, "TOPLEFT", 30, -134);
	onHead:SetText("|cffFFD100" .. (L["ABBREV_ON"] or "On") .. "|r");

	for i, c in ipairs(COLS) do
		local h = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
		h:SetPoint("CENTER", win, "TOPLEFT", COL_X[i] + 12, -134);
		h:SetText("|cffFFD100" .. c.head .. "|r");
	end

	win.cells = {};
	local rowY = -152;
	for _, u in ipairs(UNITS) do
		-- Checkbox MAESTRO de la unidad: apagado, esa unidad queda con el
		-- texto normal de Blizzard y sus 4 casillas se deshabilitan.
		local master = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate");
		master:SetSize(24, 24);
		master:SetPoint("TOPLEFT", 18, rowY);
		master._unit, master._field = u.key, "on";
		table.insert(win.cells, master);

		local ulabel = win:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		ulabel:SetPoint("TOPLEFT", 46, rowY - 4);
		ulabel:SetText(u.label);

		local rowCells = {};
		for i, c in ipairs(COLS) do
			local cb = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate");
			cb:SetSize(24, 24);
			cb:SetPoint("TOPLEFT", COL_X[i], rowY);
			cb._unit, cb._field = u.key, c.field;
			cb:SetScript("OnClick", function(self)
				if win._syncing then return; end
				local v = self:GetChecked() == 1 or self:GetChecked() == true;
				UnitCfg(u.key)[c.field] = v;
				RefreshAllBars();
			end);
			table.insert(win.cells, cb);
			table.insert(rowCells, cb);
		end

		-- Habilita / deshabilita visualmente la fila segun el maestro
		local function RefreshRow()
			local on = UnitCfg(u.key).on;
			for _, cb in ipairs(rowCells) do
				if on then cb:Enable(); cb:SetAlpha(1);
				else cb:Disable(); cb:SetAlpha(0.35); end
			end
			ulabel:SetAlpha(on and 1 or 0.45);
		end
		master._refreshRow = RefreshRow;

		master:SetScript("OnClick", function(self)
			if win._syncing then return; end
			local v = self:GetChecked() == 1 or self:GetChecked() == true;
			UnitCfg(u.key).on = v;
			RefreshRow();
			RefreshAllBars();
		end);

		rowY = rowY - 32;
	end

	-- ── PANEL DE POSICION (derecha) ──
	win.selUnit = win.selUnit or "player";

	local posH = win:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	posH:SetPoint("TOPLEFT", 410, -40);
	posH:SetText((K.UI and K.UI.Header("Position")) or "|cffFFD100Position|r");

	local posNote = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	posNote:SetPoint("TOPLEFT", 412, -60);
	posNote:SetWidth(250);
	posNote:SetJustifyH("LEFT");
	posNote:SetText("|cff8EAEC9" .. (L["ABBREV_POS_NOTE"]
		or "Move the health/mana texts of the selected unit.") .. "|r");

	-- QUE RANURA SE ESTA EDITANDO.
	--
	-- Cada tema visual guarda su propia posicion, asi que sin este cartel
	-- no habria forma de saber si lo que estas moviendo le corresponde al
	-- tema que tenes puesto o a otro.
	local themeFS = win:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
	themeFS:SetPoint("TOPLEFT", 412, -92);
	win.themeFS = themeFS;

	-- Selector de unidad
	local unitDD = CreateFrame("Frame", "NUF_AbbrevUnitDD", win, "UIDropDownMenuTemplate");
	unitDD:SetPoint("TOPLEFT", 400, -74);
	UIDropDownMenu_SetWidth(unitDD, 130);
	UIDropDownMenu_Initialize(unitDD, function(self, level)
		for _, u in ipairs(UNITS) do
			local info = UIDropDownMenu_CreateInfo();
			info.text  = u.label;
			info.value = u.key;
			info.func  = function(btn)
				win.selUnit = btn.value;
				UIDropDownMenu_SetSelectedValue(unitDD, btn.value);
				RefreshWindow();
			end;
			info.checked = (u.key == win.selUnit);
			UIDropDownMenu_AddButton(info, level);
		end
	end);
	UIDropDownMenu_SetSelectedValue(unitDD, win.selUnit);
	win.unitDD = unitDD;

	-- 8 sliders de offset
	win.offSliders = {};
	for i, o in ipairs(OFF_LAYOUT) do
		local sName = "NUF_AbbrevOff" .. i;
		local s = CreateFrame("Slider", sName, win, "OptionsSliderTemplate");
		s:SetPoint("TOPLEFT", OFF_COLX[o.col], OFF_ROWY[o.row]);
		s:SetWidth(110);
		s:SetMinMaxValues(-30, 30);
		s:SetValueStep(1);
		_G[sName .. "Low"]:SetText("");
		_G[sName .. "High"]:SetText("");
		_G[sName .. "Text"]:SetText(o.label);
		s._field = o.field;
		s._label = o.label;
		s:SetScript("OnValueChanged", function(self, v)
			v = math.floor(v + 0.5);
			_G[sName .. "Text"]:SetText(o.label .. "  " .. v);
			if win._syncing then return; end
			UnitPos(win.selUnit)[o.field] = v;
			RefreshAllBars();
		end);
		win.offSliders[i] = s;
	end

	local reset = CreateFrame("Button", nil, win, "UIPanelButtonTemplate");
	reset:SetSize(150, 22);
	reset:SetPoint("BOTTOM", win, "BOTTOM", 0, 18);
	reset:SetText(L["ABBREV_RESET"] or "Restore defaults");
	reset:SetScript("OnClick", function()
		NidhausUnitFramesDB.AbbrevStatus = { prefix = 3, remainder = 1, units = {} };
		RefreshAllBars();
		RefreshWindow();
	end);

	-- Si cambias de tema con la ventana abierta (esta justo al lado, en el
	-- panel de NUF), los sliders tienen que pasar a mostrar la ranura del
	-- tema nuevo. Se compara la clave cada cuarto de segundo: es mas
	-- barato que enganchar cada lugar del addon donde se cambia el estilo,
	-- y no se puede olvidar ninguno.
	win:SetScript("OnUpdate", function(self, elapsed)
		self._t = (self._t or 0) + elapsed;
		if self._t < 0.25 then return; end
		self._t = 0;
		if self._themeKey ~= ThemeKey(self.selUnit or "player") then
			RefreshWindow();
		end
	end);

	tinsert(UISpecialFrames, "NUF_AbbrevStatusWindow");  -- cerrar con ESC
end

function K.OpenAbbreviatedStatusMenu()
	if not win then BuildWindow(); end
	if win:IsShown() then
		win:Hide();
	else
		RefreshWindow();
		win:Show();
	end
end

-- ---------------------------------------------------------
-- Registro del modulo (checkbox en Interface > General)
-- ---------------------------------------------------------
K.RegisterModule("AbbreviatedStatus", {
	name    = L["MOD_ABBREV_STATUS"] or "Abbreviated Status Text",
	desc    = L["MOD_ABBREV_STATUS_DESC"]
		or "Shortens the health/mana numbers on unit frames (12.3k instead of 12345).",
	default = false,
	hideFromModulesTab = true,  -- vive en Interface > General
	configLabel = L["BTN_MODULE_OPEN"] or "Open",
	configFunc  = function() K.OpenAbbreviatedStatusMenu(); end,
	onEnable = function()
		-- Excluyente con "Vida completa (sin /max)": las dos reescriben el
		-- MISMO TextString de las barras. Con las dos activas se pisaban y
		-- los numeros quedaban corridos o a medio formatear.
		if C.ShowCurrentValueOnly then
			if K.SaveConfig then K.SaveConfig("ShowCurrentValueOnly", false); end
			C.ShowCurrentValueOnly = false;
			if K.ApplyHealthTextFormat then K.ApplyHealthTextFormat(); end
		end
		if K._SyncStatusTextExclusive then K._SyncStatusTextExclusive(); end
		RefreshAllBars();
	end,
	onDisable = function()
		RefreshAllBars();
		-- El otro modo reescribe el texto: hay que pedirle que lo repinte,
		-- si no quedan los numeros abreviados hasta el proximo cambio de vida.
		if K.ApplyHealthTextFormat then K.ApplyHealthTextFormat(); end
		if K._SyncStatusTextExclusive then K._SyncStatusTextExclusive(); end
	end,
});
