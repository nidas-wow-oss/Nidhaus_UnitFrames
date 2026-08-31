local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ClassTimers.lua
-- Barras de duracion especificas de clase (logica y aspecto
-- portados de MageNuggets).
--
-- MAGO:
--   Elemental de agua (31687): 45s base + 5s por rango del talento
--     "Elemental de agua duradero" (arbol Escarcha 3,26). Con el glifo
--     Eternal Water (70937) el elemental es permanente: no hay barra.
--   Imagenes espejo (55342): 30s fijos.
--
-- ASPECTO: igual al original -> marco de 120x30 transparente, icono del
-- hechizo de 15x15 abajo a la izquierda, barra AZUL de 105x15 a su
-- derecha, titulo arriba y cuenta regresiva en el centro. Antes yo habia
-- inventado un contenedor con dos barras apiladas, borde propio y otros
-- colores: no se parecia en nada al addon original.
--
-- MOVER: cada barra es independiente y se arrastra con el boton
-- izquierdo. Vienen DESBLOQUEADAS de fabrica; se fijan con el checkbox
-- "Fijar las barras" del panel (Interface > <tu clase>).
-- =========================================================

local FRAME_W, FRAME_H = 120, 30;
local ICON_SIZE        = 15;
local BAR_W,  BAR_H    = 105, 15;
local FONT_SIZE        = 10;

local _, playerClass = UnitClass("player");

function K.GetPlayerClass()
	return playerClass;
end

-- ---------------------------------------------------------
-- DB (una entrada por barra)
-- ---------------------------------------------------------
local function DB(key)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ClassTimers then NidhausUnitFramesDB.ClassTimers = {}; end
	if not NidhausUnitFramesDB.ClassTimers[key] then
		NidhausUnitFramesDB.ClassTimers[key] = {};
	end
	return NidhausUnitFramesDB.ClassTimers[key];
end

local bars    = {};
local preview = false;   -- modo "mostrar para acomodar"

local function IsLocked()
	return C.ClassTimersLocked == true;
end

-- ---------------------------------------------------------
-- Construccion de una barra
-- ---------------------------------------------------------
-- Aplicar la escala guardada a una barra recien creada.
--
-- ESTABA DECLARADA DESPUES DE BuildBar, que es quien la llama. En Lua un
-- "local function" recien existe a partir de su linea: mas arriba el nombre
-- resuelve a la GLOBAL, que es nil. Resultado: BuildBar tiraba
--
--   attempt to call global 'ApplySavedScale' (a nil value)
--
-- en la PRIMERA barra, y el error cortaba el resto del archivo. Por eso
-- Mirror Image "no se mostraba": nunca llegaba a crearse, ni tampoco el
-- frame de eventos que arranca las barras. No era un problema de capas.
--
-- Lee K.GetClassTimersScale, que se define mas abajo, pero eso no importa:
-- se llama en tiempo de ejecucion, no al cargar.
local function ApplySavedScale(f)
	pcall(f.SetScale, f, K.GetClassTimersScale());
end

local function BuildBar(key, label, iconPath, defaultY, maxDuration)
	local f = CreateFrame("Frame", "NUF_ClassTimer_" .. key, UIParent);
	f:SetSize(FRAME_W, FRAME_H);
	f:SetMovable(true);
	-- Bloqueado = transparente al mouse. Si dejamos EnableMouse(true)
	-- siempre, la barra se come los clicks de lo que tenga detras aunque
	-- ya este fijada y no haya nada que arrastrar.
	f:EnableMouse(not IsLocked());
	f:SetClampedToScreen(true);
	f:Hide();

	-- Icono del hechizo, abajo a la izquierda (como el original)
	f.icon = f:CreateTexture(nil, "BACKGROUND");
	f.icon:SetSize(ICON_SIZE, ICON_SIZE);
	f.icon:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0);
	f.icon:SetTexture(iconPath);

	-- Barra azul, pegada a la derecha del icono
	local bar = CreateFrame("StatusBar", "NUF_ClassTimerBar_" .. key, f);
	bar:SetSize(BAR_W, BAR_H);
	bar:SetPoint("LEFT", f.icon, "LEFT", ICON_SIZE, 0);
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
	bar:SetStatusBarColor(0, 0, 1);
	bar:SetMinMaxValues(0, maxDuration);
	bar:SetValue(0);
	f.bar = bar;

	-- Titulo arriba
	f.title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	f.title:SetPoint("TOP", f, "TOP", 0, -3);
	f.title:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE);
	f.title:SetText(label);

	-- Cuenta regresiva, ENCIMA de la barra.
	-- BUG que tenia: la creaba como hija del marco padre. Como la StatusBar
	-- es un frame hijo, se dibuja por encima de las capas del padre y el
	-- numero quedaba tapado por el relleno azul: solo se veia el pedacito
	-- que sobresalia. Colgandola de la barra en capa OVERLAY se ve siempre.
	f.timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	f.timeText:SetPoint("CENTER", bar, "CENTER", 0, 0);
	f.timeText:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE, "OUTLINE");
	f.timeText:SetTextColor(1, 1, 1);

	-- ── Arrastre ──
	f:RegisterForDrag("LeftButton");
	f:SetScript("OnDragStart", function(self)
		if IsLocked() then return; end
		self:StartMoving();
		self.isMoving = true;
	end);
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
		self.isMoving = false;
		local db = DB(key);
		local point, _, relativePoint, x, y = self:GetPoint();
		db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y;
	end);

	f.endTime     = 0;
	f.maxDuration = maxDuration;
	f._key        = key;
	f._defaultY   = defaultY;

	bars[key] = f;
	ApplySavedScale(f);
	return f;
end

local function RestorePosition(f)
	local db = DB(f._key);
	f:ClearAllPoints();
	if db.point then
		f:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 0, f._defaultY);
	end
end

-- Escala de TODAS las barras de clase. No usan un frame contenedor
-- comun, asi que en vez de RegisterScalable se escalan una por una.
function K.GetClassTimersScale()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.ClassTimersScale;
	return (type(db) == "number" and db > 0) and db or 1.0;
end

function K.SetClassTimersScale(v)
	v = tonumber(v) or 1.0;
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB.ClassTimersScale = v;
	for _, f in pairs(bars) do
		pcall(f.SetScale, f, v);
	end
end

function K.ResetClassTimerPositions()
	for key, f in pairs(bars) do
		local db = DB(key);
		db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil;
		RestorePosition(f);
	end
end

-- ---------------------------------------------------------
-- Arranque / actualizacion
-- ---------------------------------------------------------
-- Declaracion adelantada: StartBar la llama, pero el cuerpo se define
-- mas abajo (necesita el frame del ticker). Sin esta linea, dentro de
-- StartBar el nombre se resolvia como GLOBAL nil y reventaba al primer
-- casteo con "attempt to call global 'UpdateTickerState'".
local UpdateTickerState;

local function StartBar(f, duration)
	if not f then return; end
	f.endTime     = GetTime() + duration;
	f.maxDuration = duration;
	f.bar:SetMinMaxValues(0, duration);
	f.bar:SetValue(duration);
	f.timeText:SetText(string.format("%d", duration));
	f:SetAlpha(1);
	f:Show();
	UpdateTickerState();
end

-- El ticker arranca OCULTO y solo se muestra mientras hay alguna barra
-- corriendo. Un frame con OnUpdate visible se llama en CADA frame del
-- juego: antes esto corria siempre, para todas las clases, incluso sin
-- una sola barra creada (si no sos mago, "bars" esta vacio).
local ticker = CreateFrame("Frame");
local acc = 0;
ticker:Hide();

local function AnyBarRunning()
	for _, f in pairs(bars) do
		if f:IsShown() then return true; end
	end
	return false;
end

function UpdateTickerState()
	if preview then ticker:Hide(); return; end
	if AnyBarRunning() then
		acc = 0;
		ticker:Show();
	else
		ticker:Hide();
	end
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < 0.1 then return; end
	acc = 0;

	local anyRunning = false;
	for _, f in pairs(bars) do
		if f:IsShown() then
			local remaining = f.endTime - GetTime();
			if remaining <= 0 then
				f:Hide();
			else
				f.bar:SetValue(remaining);
				f.timeText:SetText(string.format("%d", math.ceil(remaining)));
				anyRunning = true;
			end
		end
	end

	-- Sin barras activas no hay nada que contar: dormir hasta el proximo cast
	if not anyRunning then self:Hide(); end
end);

-- ---------------------------------------------------------
-- Modo "mostrar para acomodar"
-- ---------------------------------------------------------
function K.SetClassTimersPreview(state)
	preview = state and true or false;
	for _, f in pairs(bars) do
		f:EnableMouse(preview or not IsLocked());
		if preview then
			RestorePosition(f);
			f.bar:SetMinMaxValues(0, f.maxDuration);
			f.bar:SetValue(f.maxDuration * 0.65);
			f.timeText:SetText("--");
			f:SetAlpha(0.85);

			-- Por ENCIMA del panel de opciones.
			--
			-- El boton que enciende este modo esta EN el panel, y el panel
			-- ocupa medio monitor: sin esto la barra puede quedar detras.
			-- (Ojo: lo de "Mirror Image no aparece" NO era esto, era el
			-- ApplySavedScale de arriba. Igual conviene tenerlo.)
			if not f._nufStrata then
				f._nufStrata = f:GetFrameStrata();
			end
			f:SetFrameStrata("FULLSCREEN_DIALOG");
			f:Show();
		else
			if f._nufStrata then
				f:SetFrameStrata(f._nufStrata);
				f._nufStrata = nil;
			end
			f:Hide();
		end
	end
	UpdateTickerState();
end

-- La llama el checkbox de "Fijar las barras" del panel
function K.ApplyClassTimersLock()
	local locked = IsLocked();
	for _, f in pairs(bars) do
		f:EnableMouse(not locked);
	end
end

function K.IsClassTimersPreview()
	return preview;
end

function K.HasClassTimers()
	return next(bars) ~= nil;
end

-- ---------------------------------------------------------
-- MAGO
-- ---------------------------------------------------------
if playerClass == "MAGE" then
	local WE = BuildBar("WaterElemental",
		L["BAR_WATER_ELE"] or "Water Elemental",
		"Interface\\Icons\\Spell_Frost_SummonWaterElemental_2", 250, 45);

	local MI = BuildBar("MirrorImage",
		L["BAR_MIRROR"] or "Mirror Image",
		"Interface\\Icons\\spell_magic_lesserinvisibilty", 214, 30);

	-- Con el glifo Eternal Water el elemental es permanente
	local function HasEternalWaterGlyph()
		for k = 1, 6 do
			local enabled, _, glyphSpellID = GetGlyphSocketInfo(k);
			if enabled == 1 and glyphSpellID == 70937 then
				return true;
			end
		end
		return false;
	end

	-- 45s base + 5s por rango de "Elemental de agua duradero" (Escarcha 3,26)
	local function WaterEleDuration()
		local _, _, _, _, currRank = GetTalentInfo(3, 26);
		return 45 + 5 * (currRank or 0);
	end

	local events = CreateFrame("Frame");
	events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	events:RegisterEvent("PLAYER_ENTERING_WORLD");
	events:SetScript("OnEvent", function(self, event, unit, spellName, _, _, spellID)
		if event == "PLAYER_ENTERING_WORLD" then
			RestorePosition(WE);
			RestorePosition(MI);
			return;
		end
		if unit ~= "player" then return; end
		if preview then return; end

		-- Fallback por nombre para servers que no pasan spellID en este evento
		local isWE = (spellID == 31687) or (spellName == GetSpellInfo(31687));
		local isMI = (spellID == 55342) or (spellName == GetSpellInfo(55342));

		if isWE and C.MageWaterEleTimer then
			if not HasEternalWaterGlyph() then
				StartBar(WE, WaterEleDuration());
			end
		elseif isMI and C.MageMirrorTimer then
			StartBar(MI, 30);
		end
	end);
end

-- ---------------------------------------------------------
-- Comandos
-- ---------------------------------------------------------
SLASH_NUFCLASS1 = "/nufclass";
SlashCmdList["NUFCLASS"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "show" or msg == "move" then
		K.SetClassTimersPreview(true);
		print("|cff4FC3F7NUF:|r " .. (L["CLASSTIMERS_PREVIEW_ON"]
			or "Class bars shown. Drag them, then /nufclass hide."));
	elseif msg == "hide" then
		K.SetClassTimersPreview(false);
	elseif msg == "reset" then
		K.ResetClassTimerPositions();
		print("|cff4FC3F7NUF:|r " .. (L["CLASSTIMERS_RESET"] or "Class bar positions reset."));
	else
		print("|cff4FC3F7NUF:|r /nufclass show | hide | reset");
	end
end
