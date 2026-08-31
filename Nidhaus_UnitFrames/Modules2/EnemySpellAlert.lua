local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- EnemySpellAlert.lua
-- Portado de la idea del WeakAura "Announce Spells": cuando un ENEMIGO
-- castea uno de los hechizos vigilados aparece su icono en pantalla unos
-- segundos, para reaccionar.
--
-- Deteccion: COMBAT_LOG_EVENT_UNFILTERED, solo fuentes HOSTILES.
--
-- El menu propio (boton "Spell list") tiene la lista completa agrupada por
-- CLASE, cada hechizo con su checkbox, y arriba una vista previa del icono
-- tal como se vera en pantalla.
--
-- Movible con boton izquierdo (desbloqueado); se fija con el checkbox del
-- panel. Bloqueado = transparente al mouse. El combat log (evento caro)
-- solo se registra con el modulo activo.
-- =========================================================

local ICON_SIZE = 40;   -- valor por defecto; el real sale de la DB
local SPACING   = 6;
local MAX_ICONS = 10;
local DURATION  = 3;      -- segundos que se muestra cada icono

local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x00000040;

-- ---------------------------------------------------------
-- Hechizos vigilados, agrupados por clase.
-- { id, porDefecto }  -- porDefecto = si viene tildado de fabrica
-- ---------------------------------------------------------
local SPELLS = {
	{ class = "MAGE", color = "|cff69CCF0", ids = {
		{ 2139,  true  },  -- Contrahechizo
		{ 118,   true  },  -- Polimorfia
		{ 44572, true  },  -- Congelacion profunda
		{ 122,   false },  -- Nova de escarcha
		{ 45438, false },  -- Bloque de hielo
	}},
	{ class = "PRIEST", color = "|cffFFFFFF", ids = {
		{ 8122,  true  },  -- Grito psiquico
		{ 15487, true  },  -- Silencio
		{ 605,   true  },  -- Control mental
		{ 47585, false },  -- Dispersion
	}},
	{ class = "WARLOCK", color = "|cff9482C9", ids = {
		{ 5484,  true  },  -- Aullido de terror
		{ 5782,  true  },  -- Miedo
		{ 19647, true  },  -- Bloqueo de hechizo (felhunter)
		{ 6358,  true  },  -- Seduccion (succubus)
		{ 30283, false },  -- Furia de las sombras
		{ 6789,  false },  -- Toque de la muerte
	}},
	{ class = "HUNTER", color = "|cffABD473", ids = {
		{ 1499,  true  },  -- Trampa congelante
		{ 60192, true  },  -- Flecha congelante
		{ 34490, true  },  -- Disparo silenciador
		{ 19503, true  },  -- Disparo dispersor
		{ 13809, false },  -- Trampa de escarcha
		{ 34600, false },  -- Trampa de serpientes
		{ 19263, false },  -- Disuasion
	}},
	{ class = "ROGUE", color = "|cffFFF569", ids = {
		{ 1766,  true  },  -- Patada
		{ 2094,  true  },  -- Cegar
		{ 408,   true  },  -- Punetazo renal
		{ 1833,  true  },  -- Golpe bajo
		{ 6770,  false },  -- Apalear
		{ 1776,  false },  -- Gubia
		{ 51713, true  },  -- Danza de las sombras
		{ 31224, false },  -- Capa de sombras
		{ 5277,  false },  -- Evasion
	}},
	{ class = "WARRIOR", color = "|cffC79C6E", ids = {
		{ 6552,  true  },  -- Aporrear
		{ 72,    true  },  -- Golpe de escudo
		{ 5246,  true  },  -- Grito intimidatorio
		{ 46924, true  },  -- Torbellino de espadas
		{ 23920, false },  -- Reflexion de hechizos
		{ 871,   false },  -- Muro de escudos
	}},
	{ class = "DRUID", color = "|cffFF7D0A", ids = {
		{ 33786, true  },  -- Ciclon
		{ 339,   true  },  -- Raices enredadoras
		{ 2637,  true  },  -- Hibernar
		{ 16979, false },  -- Carga salvaje
		{ 22812, false },  -- Corteza
	}},
	{ class = "SHAMAN", color = "|cff0070DE", ids = {
		{ 51514, true  },  -- Embrujo
		{ 57994, true  },  -- Viento cortante
		{ 30823, false },  -- Furia chamanica
	}},
	{ class = "PALADIN", color = "|cffF58CBA", ids = {
		{ 853,   true  },  -- Martillo de justicia
		{ 20066, true  },  -- Arrepentimiento
		{ 642,   false },  -- Escudo divino
		{ 1022,  false },  -- Mano de proteccion
		{ 31884, false },  -- Ira vengadora
	}},
	{ class = "DEATHKNIGHT", color = "|cffC41F3B", ids = {
		{ 47528, true  },  -- Congelar mente
		{ 47476, true  },  -- Estrangular
		{ 49203, true  },  -- Frio hambriento
		{ 48792, false },  -- Fortaleza gelida
		{ 48707, false },  -- Caparazon antimagia
	}},
};

-- ---------------------------------------------------------
-- DB / estado
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.EnemySpellAlert then
		NidhausUnitFramesDB.EnemySpellAlert = {};
	end
	local db = NidhausUnitFramesDB.EnemySpellAlert;
	if not db.iconSize then db.iconSize = ICON_SIZE; end
	-- Donde mostrarse (por defecto en todos lados)
	if db.inArena == nil then db.inArena = true; end
	if db.inBG    == nil then db.inBG    = true; end
	if db.inDuel  == nil then db.inDuel  = true; end
	if db.inWorld == nil then db.inWorld = true; end
	if not db.custom then db.custom = {}; end   -- hechizos agregados a mano
	if not db.spells then db.spells = {}; end

	-- LOS HECHIZOS NUEVOS TAMBIEN LLEGAN A QUIEN YA TENIA LA LISTA.
	--
	-- Antes esto corria SOLO la primera vez ("if not db.spells"). Al sumar
	-- un hechizo a la tabla de arriba, el que ya tenia su lista guardada no
	-- lo veia nunca: quedaba en nil, que es lo mismo que apagado, y encima
	-- sin aparecer tildado en el menu.
	--
	-- Recorriendo siempre y escribiendo solo lo que FALTA, los nuevos
	-- entran con su valor de fabrica y lo que vos hayas tildado o destildado
	-- queda intacto.
	for _, grp in ipairs(SPELLS) do
		for _, e in ipairs(grp.ids) do
			if db.spells[e[1]] == nil then
				db.spells[e[1]] = e[2] and true or false;
			end
		end
	end
	return db;
end

local function GetIconSize()
	local v = DB().iconSize;
	if type(v) ~= "number" or v < 16 then return ICON_SIZE; end
	return v;
end
K.GetEnemyAlertIconSize = GetIconSize;

-- Filtro de zona: igual que el Gargoyle Tracker.
local function ZoneAllowed()
	local db = DB();
	local _, itype = GetInstanceInfo();
	if itype == "arena" then return db.inArena; end
	if itype == "pvp"   then return db.inBG; end
	if db.inDuel and _G.DuelOutOfBoundsTimer then return true; end
	return db.inWorld;
end

function K.GetEnemyAlertZone(key) return DB()[key] and true or false; end
function K.SetEnemyAlertZone(key, v) DB()[key] = v and true or false; end

local function IsSpellOn(id)
	local v = DB().spells[id];
	return v == true;
end

local function IsLocked() return C.EnemySpellAlertLocked == true; end

local enabled = false;
local preview = false;

-- name -> icon, armado solo con los hechizos ACTIVADOS
local watch = {};

local function BuildWatch()
	watch = {};
	for _, grp in ipairs(SPELLS) do
		for _, e in ipairs(grp.ids) do
			local id = e[1];
			if IsSpellOn(id) then
				local name, _, icon = GetSpellInfo(id);
				if name and not watch[name] then
					watch[name] = { icon = icon, id = id };
				end
			end
		end
	end

	-- Hechizos agregados a mano por el usuario (por ID o por nombre).
	-- Con el nombre suelto no hay icono, asi que se usa uno generico.
	for key, entry in pairs(DB().custom or {}) do
		if entry then
			local nm, ic = entry.name, entry.icon;
			if entry.id then
				local n2, _, i2 = GetSpellInfo(entry.id);
				nm = n2 or nm; ic = i2 or ic;
			end
			if nm and not watch[nm] then
				watch[nm] = { icon = ic or "Interface\\Icons\\INV_Misc_QuestionMark", id = entry.id, custom = key };
			end
		end
	end
end

-- Agrega un hechizo a mano. Acepta un ID numerico o un nombre suelto.
-- Devuelve true + el nombre mostrado, o false + motivo.
function K.AddEnemyAlertSpell(text)
	if not text or text == "" then return false, "empty"; end
	local db = DB();
	local id = tonumber(text);
	if id then
		local name, _, icon = GetSpellInfo(id);
		if not name then return false, "notfound"; end
		db.custom["id" .. id] = { id = id, name = name, icon = icon };
		BuildWatch();
		return true, name;
	end
	-- Nombre suelto: se guarda tal cual (matchea contra el combat log)
	db.custom["nm" .. string.lower(text)] = { name = text };
	BuildWatch();
	return true, text;
end

function K.RemoveEnemyAlertSpell(key)
	local db = DB();
	if db.custom[key] then db.custom[key] = nil; BuildWatch(); return true; end
	return false;
end

function K.GetEnemyAlertCustomSpells()
	return DB().custom or {};
end
K.RebuildEnemyAlertWatch = BuildWatch;

-- ---------------------------------------------------------
-- Anchor (lo que se arrastra)
-- ---------------------------------------------------------
local anchor = CreateFrame("Frame", "NUF_EnemyAlertAnchor", UIParent);
anchor:SetSize(ICON_SIZE, ICON_SIZE);
anchor:SetFrameStrata("HIGH");
anchor:SetMovable(true);
anchor:SetClampedToScreen(true);
anchor:EnableMouse(false);

-- Escala configurable desde el panel (registro central en ScaleAPI).
-- Se escala el ANCLA, no el icono: todo lo demas cuelga de ella, asi que
-- crece o se achica el conjunto entero y no hay que tocar cada pieza.
if K.RegisterScalable then K.RegisterScalable("EnemySpellAlert", anchor, 1.0); end

anchor.bg = anchor:CreateTexture(nil, "BACKGROUND");
anchor.bg:SetAllPoints();
anchor.bg:SetTexture(0, 1, 0, 0.3);
anchor.bg:Hide();

anchor:RegisterForDrag("LeftButton");
anchor:SetScript("OnDragStart", function(self)
	if IsLocked() and not preview then return; end
	self:StartMoving();
end);
anchor:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing();
	local point, _, rel, x, y = self:GetPoint();
	local db = DB();
	db.point, db.rel, db.x, db.y = point, rel, x, y;
end);

local function RestorePosition()
	local db = DB();
	anchor:ClearAllPoints();
	if db.point then
		anchor:SetPoint(db.point, UIParent, db.rel, db.x, db.y);
	else
		anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 60);
	end
end

-- ---------------------------------------------------------
-- Pool de iconos
-- ---------------------------------------------------------
local pool, active, states = {}, {}, {};

local function CreateIcon()
	local sz = GetIconSize();
	local f = CreateFrame("Frame", nil, anchor);
	f:SetSize(sz, sz);

	f.tex = f:CreateTexture(nil, "ARTWORK");
	f.tex:SetAllPoints();
	f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92);

	f.border = f:CreateTexture(nil, "BACKGROUND");
	f.border:SetPoint("TOPLEFT", -1, 1);
	f.border:SetPoint("BOTTOMRIGHT", 1, -1);
	f.border:SetTexture("Interface\\Buttons\\WHITE8x8");
	f.border:SetVertexColor(0, 0, 0, 1);

	f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate");
	f.cd:SetAllPoints();
	f.cd:SetReverse(true);

	f:Hide();
	return f;
end

local function GetIcon()
	for _, f in ipairs(pool) do
		if not f.inUse then f.inUse = true; return f; end
	end
	local f = CreateIcon();
	f.inUse = true;
	table.insert(pool, f);
	return f;
end

local function ReleaseIcon(f)
	f.inUse = false;
	f:Hide();
end

local function Layout()
	local sz = GetIconSize();
	local n = 0;
	for _, key in ipairs(active) do if states[key] then n = n + 1; end end
	local totalW = n * sz + math.max(0, n - 1) * SPACING;
	local startX = -totalW / 2 + sz / 2;
	local i = 0;
	for _, key in ipairs(active) do
		local st = states[key];
		if st then
			st.widget:SetSize(sz, sz);
			st.widget:ClearAllPoints();
			st.widget:SetPoint("CENTER", anchor, "CENTER", startX + i * (sz + SPACING), 0);
			i = i + 1;
		end
	end
	anchor:SetSize(sz, sz);
end

-- La llama el slider del panel
function K.SaveEnemyAlertIconSize(v)
	DB().iconSize = v;
	for _, f in ipairs(pool) do f:SetSize(v, v); end
	Layout();
end

local function Remove(key)
	local st = states[key];
	if not st then return; end
	ReleaseIcon(st.widget);
	states[key] = nil;
	for i, k in ipairs(active) do
		if k == key then table.remove(active, i); break; end
	end
end

local function ClearAll()
	local keys = {};
	for k in pairs(states) do table.insert(keys, k); end
	for _, k in ipairs(keys) do Remove(k); end
end

-- ---------------------------------------------------------
-- Ticker de expiracion (solo corre mientras hay iconos)
-- ---------------------------------------------------------
local ticker = CreateFrame("Frame");
ticker:Hide();
ticker.acc = 0;
ticker:SetScript("OnUpdate", function(self, e)
	self.acc = self.acc + e;
	if self.acc < 0.1 then return; end
	self.acc = 0;

	local now = GetTime();
	local rm;
	for key, st in pairs(states) do
		if now >= st.expire then
			rm = rm or {};
			table.insert(rm, key);
		end
	end
	if rm then
		for _, k in ipairs(rm) do Remove(k); end
		Layout();
	end
	if not next(states) then self:Hide(); end
end);

-- ---------------------------------------------------------
-- Disparar un icono
-- ---------------------------------------------------------
local function Trigger(name)
	local w = watch[name];
	if not w then return; end
	if not preview and not ZoneAllowed() then return; end

	local st = states[name];
	if not st then
		if #active >= MAX_ICONS then return; end
		st = { widget = GetIcon(), expire = 0 };
		states[name] = st;
		table.insert(active, name);
		st.widget.tex:SetTexture(w.icon);
	end
	st.expire = GetTime() + DURATION;
	st.widget.cd:SetCooldown(GetTime(), DURATION);
	st.widget:Show();
	ticker:Show();
	Layout();
end

-- ---------------------------------------------------------
-- Deteccion (combat log)
-- ---------------------------------------------------------
local clog = CreateFrame("Frame");
clog:SetScript("OnEvent", function(self, event, ...)
	-- 3.3.5a: timestamp, sub, srcGUID, srcName, srcFlags, dstGUID, dstName,
	-- dstFlags, spellId, spellName, ...
	local _, sub, _, _, srcFlags, _, _, _, _, spellName = ...;
	if sub == "SPELL_CAST_SUCCESS" or sub == "SPELL_CAST_START" then
		if bit.band(srcFlags or 0, HOSTILE) == 0 then return; end   -- solo enemigos
		if spellName and watch[spellName] then
			Trigger(spellName);
		end
	end
end);

-- ---------------------------------------------------------
-- Preview / lock / reset
-- ---------------------------------------------------------
function K.SetEnemyAlertPreview(state)
	preview = state and true or false;
	BuildWatch();
	RestorePosition();
	anchor:EnableMouse(preview or not IsLocked());

	ClearAll();
	if preview then
		-- UN SOLO icono de referencia para arrastrar.
		anchor.bg:Show();
		local name, w = next(watch);
		local key = name or "preview";
		local st = { widget = GetIcon(), expire = GetTime() + 999999 };
		states[key] = st;
		table.insert(active, key);
		st.widget.tex:SetTexture(w and w.icon or "Interface\\Icons\\INV_Misc_QuestionMark");
		st.widget.cd:SetCooldown(0, 0);
		st.widget:Show();
		Layout();
	else
		anchor.bg:Hide();
		ticker:Hide();
	end
end

function K.IsEnemyAlertPreview() return preview; end

function K.ApplyEnemyAlertLock()
	anchor:EnableMouse(preview or not IsLocked());
end

function K.ResetEnemyAlertPosition()
	local db = DB();
	db.point, db.rel, db.x, db.y = nil, nil, nil, nil;
	RestorePosition();
end

-- =========================================================
-- MENU PROPIO: lista de hechizos por clase
-- =========================================================
local win;

local function BuildMenu()
	win = CreateFrame("Frame", "NUF_EnemyAlertWindow", UIParent);
	-- Cajita con el valor debajo de cada slider (UIKit).
	if K.UI and K.UI.AutoRestyle then K.UI.AutoRestyle(win); end

	win:SetSize(420, 600);
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
	titleBox:SetSize(270, 30);
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
	title:SetText(L["MOD_ENEMYALERT"] or "Enemy Spell Alert");

	local close = CreateFrame("Button", nil, win, "UIPanelCloseButton");
	close:SetPoint("TOPRIGHT", -4, -4);
	close:SetScript("OnClick", function() win:Hide(); end);

	-- ── Vista previa: como se ve el icono en pantalla ──
	local prevLabel = win:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	prevLabel:SetPoint("TOPLEFT", 20, -40);
	prevLabel:SetText((K.UI and K.UI.Header(L["ALERT_PREVIEW"] or "Preview"))
		or "|cffFFD100Preview|r");

	local prevBox = CreateFrame("Frame", nil, win);
	prevBox:SetSize(ICON_SIZE + 8, ICON_SIZE + 8);
	prevBox:SetPoint("TOPLEFT", 24, -62);
	prevBox:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	prevBox:SetBackdropColor(0, 0, 0, 0.5);

	local prevIcon = prevBox:CreateTexture(nil, "ARTWORK");
	prevIcon:SetSize(ICON_SIZE, ICON_SIZE);
	prevIcon:SetPoint("CENTER");
	prevIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
	win.prevIcon = prevIcon;

	local prevNote = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	prevNote:SetPoint("TOPLEFT", prevBox, "TOPRIGHT", 10, -4);
	prevNote:SetWidth(280);
	prevNote:SetJustifyH("LEFT");
	prevNote:SetText("|cff8EAEC9" .. (L["ALERT_PREVIEW_NOTE"]
		or "This is how the icon appears on screen when an enemy casts a watched spell.") .. "|r");

	-- ── Tamaño del icono ──
	local szSlider = CreateFrame("Slider", "NUF_EnemyAlertSize", win, "OptionsSliderTemplate");
	szSlider:SetPoint("TOPLEFT", 24, -118);
	szSlider:SetWidth(170);
	szSlider:SetMinMaxValues(20, 80);
	szSlider:SetValueStep(1);
	_G["NUF_EnemyAlertSizeLow"]:SetText("");
	_G["NUF_EnemyAlertSizeHigh"]:SetText("");
	do
		local cur = GetIconSize();
		_G["NUF_EnemyAlertSizeText"]:SetText((L["ALERT_ICON_SIZE"] or "Icon size") .. ": " .. cur);
		szSlider:SetValue(cur);
		szSlider._last = cur;
	end
	szSlider:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v + 0.5);
		if self._last == v then return; end
		self._last = v;
		_G["NUF_EnemyAlertSizeText"]:SetText((L["ALERT_ICON_SIZE"] or "Icon size") .. ": " .. v);
		if K.SaveEnemyAlertIconSize then K.SaveEnemyAlertIconSize(v); end
		-- La vista previa NO cambia de tamaño: es solo una muestra del icono
		-- dentro de la ventana. El slider afecta al icono real en pantalla.
	end);

	-- ── Agregar hechizo por ID o nombre ──
	local addLbl = win:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	addLbl:SetPoint("TOPLEFT", 220, -114);
	addLbl:SetText("|cff8EAEC9" .. (L["ALERT_ADD_HINT"] or "Add by ID or name:") .. "|r");

	local addBox = CreateFrame("EditBox", "NUF_EnemyAlertAddBox", win, "InputBoxTemplate");
	addBox:SetPoint("TOPLEFT", 224, -130);
	addBox:SetSize(110, 20);
	addBox:SetAutoFocus(false);

	local addBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate");
	addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0);
	addBtn:SetSize(56, 20);
	addBtn:SetText(L["ALERT_ADD"] or "Add");

	local function DoAdd()
		local txt = addBox:GetText();
		if not txt or txt == "" then return; end
		local ok, res = K.AddEnemyAlertSpell(txt);
		if ok then
			print("|cff4FC3F7NUF:|r " .. (L["ALERT_ADDED"] or "Added") .. ": " .. tostring(res));
			addBox:SetText("");
			if K.RefreshEnemyAlertMenu then K.RefreshEnemyAlertMenu(); end
		else
			print("|cffFF5555NUF:|r " .. (L["ALERT_NOTFOUND"] or "Spell ID not found."));
		end
		addBox:ClearFocus();
	end
	addBtn:SetScript("OnClick", DoAdd);
	addBox:SetScript("OnEnterPressed", DoAdd);
	addBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);

	if K.UI and K.UI.Separator then K.UI.Separator(win, 16, -156, 388); end

	-- ── Lista scrolleable por clase ──
	local scroll = CreateFrame("ScrollFrame", "NUF_EnemyAlertScroll", win, "UIPanelScrollFrameTemplate");
	scroll:SetPoint("TOPLEFT", 16, -166);
	scroll:SetPoint("BOTTOMRIGHT", -34, 48);

	local pane = CreateFrame("Frame", nil, scroll);
	pane:SetWidth(350);
	pane:SetHeight(1);
	scroll:SetScrollChild(pane);

	win.cells = {};
	local y = -6;

	for _, grp in ipairs(SPELLS) do
		-- Encabezado de clase, con su color
		local ch = pane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		ch:SetPoint("TOPLEFT", 6, y);
		local cname = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[grp.class] or grp.class;
		ch:SetText((grp.color or "|cffFFFFFF") .. cname .. "|r");
		y = y - 22;

		for _, e in ipairs(grp.ids) do
			local id = e[1];
			local sname, _, sicon = GetSpellInfo(id);
			if sname then
				local cb = CreateFrame("CheckButton", nil, pane, "UICheckButtonTemplate");
				cb:SetSize(22, 22);
				cb:SetPoint("TOPLEFT", 14, y);
				cb._id = id;

				local ico = pane:CreateTexture(nil, "ARTWORK");
				ico:SetSize(18, 18);
				ico:SetPoint("LEFT", cb, "RIGHT", 2, 0);
				ico:SetTexture(sicon);
				ico:SetTexCoord(0.08, 0.92, 0.08, 0.92);

				local lbl = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
				lbl:SetPoint("LEFT", ico, "RIGHT", 6, 0);
				lbl:SetText(sname);

				cb:SetScript("OnClick", function(self)
					if win._syncing then return; end
					local v = self:GetChecked() == 1 or self:GetChecked() == true;
					DB().spells[id] = v;
					BuildWatch();
					if win.prevIcon and v and sicon then win.prevIcon:SetTexture(sicon); end
				end);

				table.insert(win.cells, cb);
				y = y - 26;
			end
		end
		y = y - 8;
	end

	-- ── Hechizos agregados a mano (con boton para quitarlos) ──
	win.customRows = {};
	win.customPane = pane;
	win.customStartY = y;

	function win:BuildCustomRows()
		for _, r in ipairs(self.customRows) do r:Hide(); end
		self.customRows = {};

		local cy = self.customStartY;
		local list = K.GetEnemyAlertCustomSpells and K.GetEnemyAlertCustomSpells() or {};
		local any = false;
		for _ in pairs(list) do any = true; break; end
		if not any then
			pane:SetHeight(math.abs(cy) + 20);
			return;
		end

		local hdr = pane:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		hdr:SetPoint("TOPLEFT", 6, cy);
		hdr:SetText("|cffFFD100" .. (L["ALERT_CUSTOM"] or "Added by you") .. "|r");
		table.insert(self.customRows, hdr);
		cy = cy - 22;

		for key, entry in pairs(list) do
			local nm = entry.name or "?";
			local ic = entry.icon;
			if entry.id then
				local n2, _, i2 = GetSpellInfo(entry.id);
				nm = n2 or nm; ic = i2 or ic;
			end

			local row = CreateFrame("Frame", nil, pane);
			row:SetPoint("TOPLEFT", 14, cy);
			row:SetSize(320, 24);

			local ico = row:CreateTexture(nil, "ARTWORK");
			ico:SetSize(18, 18);
			ico:SetPoint("LEFT", 0, 0);
			ico:SetTexture(ic or "Interface\\Icons\\INV_Misc_QuestionMark");
			ico:SetTexCoord(0.08, 0.92, 0.08, 0.92);

			local lbl = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
			lbl:SetPoint("LEFT", ico, "RIGHT", 6, 0);
			lbl:SetText(nm .. (entry.id and (" |cff888888(" .. entry.id .. ")|r") or ""));

			local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate");
			del:SetSize(60, 18);
			del:SetPoint("LEFT", 240, 0);
			del:SetText(L["ALERT_REMOVE"] or "Remove");
			del:SetScript("OnClick", function()
				if K.RemoveEnemyAlertSpell then K.RemoveEnemyAlertSpell(key); end
				win:BuildCustomRows();
			end);

			table.insert(self.customRows, row);
			cy = cy - 26;
		end

		pane:SetHeight(math.abs(cy) + 20);
	end

	win:BuildCustomRows();

	-- ── Botones de abajo ──
	local allBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate");
	allBtn:SetSize(90, 22);
	allBtn:SetPoint("BOTTOMLEFT", 20, 16);
	allBtn:SetText(L["ALERT_ALL"] or "All");
	allBtn:SetScript("OnClick", function()
		for _, grp in ipairs(SPELLS) do
			for _, e in ipairs(grp.ids) do DB().spells[e[1]] = true; end
		end
		BuildWatch();
		if K.RefreshEnemyAlertMenu then K.RefreshEnemyAlertMenu(); end
	end);

	local noneBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate");
	noneBtn:SetSize(90, 22);
	noneBtn:SetPoint("LEFT", allBtn, "RIGHT", 6, 0);
	noneBtn:SetText(L["ALERT_NONE"] or "None");
	noneBtn:SetScript("OnClick", function()
		for _, grp in ipairs(SPELLS) do
			for _, e in ipairs(grp.ids) do DB().spells[e[1]] = false; end
		end
		BuildWatch();
		if K.RefreshEnemyAlertMenu then K.RefreshEnemyAlertMenu(); end
	end);

	local defBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate");
	defBtn:SetSize(110, 22);
	defBtn:SetPoint("LEFT", noneBtn, "RIGHT", 6, 0);
	defBtn:SetText(L["ALERT_DEFAULTS"] or "Defaults");
	defBtn:SetScript("OnClick", function()
		for _, grp in ipairs(SPELLS) do
			for _, e in ipairs(grp.ids) do DB().spells[e[1]] = e[2] and true or false; end
		end
		BuildWatch();
		if K.RefreshEnemyAlertMenu then K.RefreshEnemyAlertMenu(); end
	end);

	tinsert(UISpecialFrames, "NUF_EnemyAlertWindow");
end

function K.RefreshEnemyAlertMenu()
	if not win then return; end
	win._syncing = true;
	for _, cb in ipairs(win.cells) do
		cb:SetChecked(IsSpellOn(cb._id));
	end
	-- Icono de muestra: el primero que este activado
	if win.BuildCustomRows then win:BuildCustomRows(); end
	local _, w = next(watch);
	if win.prevIcon then
		win.prevIcon:SetTexture((w and w.icon) or "Interface\\Icons\\INV_Misc_QuestionMark");
	end
	win._syncing = false;
end

function K.OpenEnemyAlertMenu()
	if not win then BuildMenu(); end
	if win:IsShown() then
		win:Hide();
	else
		BuildWatch();
		K.RefreshEnemyAlertMenu();
		win:Show();
	end
end

-- ---------------------------------------------------------
-- On / Off del modulo
-- ---------------------------------------------------------
local function SetEnabled(on)
	enabled = on;
	if on then
		BuildWatch();
		RestorePosition();
		clog:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		anchor:EnableMouse(preview or not IsLocked());
	else
		clog:UnregisterAllEvents();
		ClearAll();
		ticker:Hide();
		preview = false;
		anchor.bg:Hide();
		anchor:EnableMouse(false);
	end
end

RestorePosition();

K.RegisterModule("EnemySpellAlert", {
	name    = L["MOD_ENEMYALERT"] or "Enemy Spell Alert",
	desc    = L["MOD_ENEMYALERT_DESC"]
		or "Shows the spell icon on screen when an enemy casts a trap, fear or interrupt.",
	default = false,
	hideFromModulesTab = true,   -- vive en Interface > PvP
	onEnable  = function() SetEnabled(true) end,
	onDisable = function() SetEnabled(false) end,
});
