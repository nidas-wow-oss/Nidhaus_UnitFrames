local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ConfigManager

local defaults = {
	-- GENERAL
	classColor = true,
	statusbarBackdrop = true,
	HealthPercentage = false,   -- apagado por defecto, se prende en Interface > General
	CastingTimers = true,
	
	-- FRAMES
	SetPositions = false,
	LockPositions = true,
	PartyIndividualMove = false,
	PlayerFrameScale = 1.0,
	TargetFrameScale = 1.0,
	FocusScale = 1.0,
	FocusSpellBarScale = 1.2,
	FocusAuraLimit = false,
	Focus_maxDebuffs = 0,
	Focus_maxBuffs = 0,
	BossFrameScale = 0.65,
	PetFrameScale = 1.0,
	
	-- PARTY/ARENA
	NewPartyFrame = false,
	-- Estilo de los marcos de party: "Default" | "New" | "Improved"
	-- Son excluyentes, los coordina Modules2/PartyFrameStyle.lua
	PartyFrameStyle = "Default",
	PartyTargetsEnabled = false,   -- apagado por defecto, se prende en Frames > Party
	PartyFrameOn = true,
	PartyShowPetFrames = false,  -- marcos de mascota de los companeros: apagados por defecto
	PartyFrameScale = 1.0,
	PartyMemberFrameSpacing = 0,
	PartyMode3v3 = true,
	-- Escala individual de cada miembro en modo 3v3
	Party3v3Scale1 = 1.5,
	Party3v3Scale2 = 1.5,
	Party3v3Scale3 = 1.3,
	Party3v3Scale4 = 1.3,
	BossTargetFrameSpacing = 0,
	ArenaFrameOn = true,
	ArenaFrameScale = 1.5,
	ArenaCustomTexture = true,
	ArenaFrame_Trinkets = true,
	-- Trinkets de party: checkbox propio (Frames > Party), independiente
	-- del rastreo de arena. Offset compartido por los 4 miembros.
	PartyTrinketsEnabled = false,
	PartyTrinketSize = 20,
	ArenaFrame_Trinket_Voice = false,
	ArenaMirrorMode = false,
	ArenaFrameSpacing = 0,

	-- ARENA STYLE: "Default", "Custom", "Flat"
	ArenaFrameStyle = "Custom",
	ArenaBlizzardClassColor = false, -- color de clase en el estilo Blizzard de arena

	-- FLAT STYLE OPTIONS
	ArenaFlatMode = false,
	ArenaFlatWidth = 120,
	ArenaFlatHealthBarHeight = 20,
	ArenaFlatPowerBarHeight = 8,
	ArenaFlatHealthFontSize = 9,
	ArenaFlatPowerFontSize = 9,
	ArenaFlatBarTexture = "",
	ArenaFlatMirrored = false,
	ArenaFlatStatusText = true,

	-- ARENA PET FRAME
	ArenaPetFrameShow = false,
	ArenaFlatPetStyle = true,

	-- ARENA TARGET OF TARGET
	-- (el on/off del ToT lo maneja K.RegisterModule("ArenaToT"), no un setting)
	ArenaToTScale = 1.0,
	ArenaToTClassIcon = false,
	ArenaToTMirrored = false,
	ArenaToTSquare = false,   -- retrato cuadrado, como el de Party Targets

	-- CAST BAR OPTIONS
	ArenaCastBarEnable = false,
	ArenaCastBarScale = 1.0,
	ArenaCastBarWidth = 80,

	-- Barra de casteo estilo pw (Modules2/CastBarPW.lua).
	-- Apagada por defecto: cambia el aspecto de las tres barras y eso
	-- se elige, no se hereda.
	CastBarPWEnabled = false,
	CastBarPWIcon = true,       -- icono del hechizo arriba de la barra
	CastBarPWIconSize = 30,     -- tamaño del icono del jugador (pw: 30)
	CastBarPWDark = true,       -- teñir el borde de gris, como pw
	CastBarPWScale = 1.2,       -- escala (pw: 1.2)
	CastBarPWTarget = true,     -- aplicar tambien a la barra del objetivo
	CastBarPWFocus = true,      -- aplicar tambien a la barra del foco

	-- Agregados al tooltip (Modules2/TooltipExtras.lua), portados de
	-- el UI de origen. Los tres apagados por defecto: los dos primeros hacen
	-- consultas al servidor (comparacion de logros e inspeccion) y eso
	-- se elige, no se hereda.
	TooltipArenaExp = false,       -- rating de arena mas alto del jugador
	TooltipTalents = false,        -- arbol y reparto de talentos
	TooltipQualityBorder = false,  -- borde del tooltip segun calidad del objeto
	TooltipIcons = false,          -- icono del objeto/hechizo en la primera linea
	-- Vive en el mismo archivo pero su checkbox esta en Buffs y Debuffs,
	-- que es donde uno lo busca.
	AuraCastBy = false,            -- quien lanzo el buff/debuff, en su tooltip

	-- Bordes de auras del objetivo y el foco (Modules2/AuraBorders.lua).
	-- Apagado por defecto: cambia como se ven todos los iconos.
	AuraBordersEnabled = false,
	AuraBordersPurge = true,    -- resplandor en los buffs magicos del enemigo

	-- VISUAL THEME
	darkFrames = false,
	UnitFrameCustomTexture = true,
	AsuriFrames = false, -- tema Asuri: marco de cadenas, barras finas
	-- Texto de vida/mana (portado de ZyrokofArenaFrames)
	ShowCurrentValueOnly = false,     -- "33401" en vez de "33401 / 33401"
	PartyHideHealthManaText = false,  -- esconde los numeros solo en el party
	PartyFontSize = 0,                -- 0 = tamaño original de cada estilo
	PartyFontOutline = "OUTLINE", -- contorno del texto de los del grupo

	-- NOTA: las opciones monocromas se sacaron. Si quedaron guardadas de
	-- antes, la tabla DEAD de LoadConfig las devuelve a un valor valido.

	-- PARTY CASTING BARS
	PCB_Enabled = false,

	-- EXTRA OPTIONS
	ArenaCountDown = true,
	AutoSellGray = true,
	AutoRepair = true,
	ErrorHideInCombat = true,
	BlockDuels = false,   -- rechazar duelos automaticamente
	-- Tab solo a jugadores enemigos en zonas PvP (Modules2/TabBinder.lua)
	TabBinderEnabled = false,

	-- ARENA TIMERS
	ArenaDalaranPipeTimer = false,
	ArenaRoVPillarTimer = false,
	ArenaEndTimer = false,

	-- ACTION BAR TEXT
	HideKeybindText = false,
	HideMacroText = false,

	-- Lado del casillero de la cuadricula del modo mover, en pixeles de
	-- pantalla. 2 = casi libre, 10 = bien enganchado.
	MoveGridStep = 10,

	-- MINIMAP
	AuraIconsPerRow   = 8,       -- iconos de buff por fila (BUFFS_PER_ROW)
	SideBarsHover     = false,   -- barras laterales solo al pasar el mouse
	MinimapSquare     = false,   -- cuadrado en vez de redondo
	MinimapThinBorder   = false,   -- LEGADO: el checkbox viejo del borde fino.
	                             -- Se sigue leyendo una sola vez para migrar
	                             -- a MinimapBorderStyle = "Light".
	-- Default | Light | Tooltip | Thin | Flat | Blizzard
	MinimapBorderStyle = "Default",
	MinimapHideZone   = false,   -- ocultar el nombre de la zona
	MinimapHideZoneBG = false,   -- ocultar la chapa dorada detras del nombre
	MinimapHideAddonIcons = false, -- ocultar los iconos que cuelgan los addons
	MinimapHideClock  = false,   -- ocultar el reloj
	MinimapHideZoom   = false,   -- ocultar los botones de zoom
	MinimapHideCalendar = false, -- ocultar el calendario (GameTimeFrame)
	MinimapHideWorldMap = false, -- ocultar el boton del mapa del mundo
	MinimapWheelZoom  = true,    -- zoom con la rueda del mouse
	MinimapScale      = 1.0,

	-- CLASS / PVP MODULES
	MageWaterEleTimer  = true,   -- barra del elemental de agua (mago)
	MageMirrorTimer    = true,   -- barra de imagenes espejo (mago)
	MageIcyFrame       = false,  -- skin "Icy Portrait" del PlayerFrame (mago)
	pwFrames           = false,  -- tema "Compact": marcos de pw_unitframes
	PaladinICDKeepVisible = false, -- dejar el icono a la vista (a color) cuando esta listo
	SwingTimerBorderStyle  = "Tooltip",
	AutoShotBorderStyle    = "Tooltip",
	ClassTimersLocked  = false,  -- las barras de clase arrancan movibles
	ComboWatchLocked   = false,  -- el contador de combo arranca movible
	PetBuffsLocked     = false,  -- los buffs de mascota arrancan movibles
	EnemySpellAlertLocked = false, -- la alerta de hechizos enemigos arranca movible
	PetBuffsIconSize   = 32,
	PowerBarCombatOnly = false,  -- barra de recurso solo en combate
	PowerBarShowPercent = false, -- mostrar % en vez de actual / maximo
	PowerBarHideText = false,    -- apagar del todo los numeros de las dos barras
	PowerBarShowHealth = false,  -- mostrar tambien una barra de vida arriba
	PowerBarHealthGradient = true, -- la barra de vida cambia verde/amarillo/rojo
	PowerBarHideWhenFull = false,  -- ocultarla a full vida y recurso fuera de combate
	PowerBarHealthClassColor = false, -- la barra de vida con el color de tu clase
	PowerBarShowAuras = false,     -- dos filas de iconos: buffs arriba, debuffs abajo
	PowerBarAuraPos = "RIGHT",     -- donde van esas filas: RIGHT / BOTTOM / TOP

	-- UNIT NAME COLOR: "Default" | "White" | "Class"
	UnitNameColorMode = "Default",
	UnitNameBorder    = "None",   -- borde/contorno del nombre: None|Outline|Thick

	-- CHAT
	ChatCopyEnabled = false,
	ChatClickableURLs = false,

	-- ACTION BARS
	UnifyActionBars = true,
	-- Separacion entre botones de las barras, en pixeles. Solo se aplica
	-- con Unify o MiniBar puestos (Modules/ActionBars.lua).
	ActionBarButtonSpace = 6,
	MiniBarEnabled = false,
	-- Ocultar el arte de fondo de las barras en modo MiniBar
	MiniBarHideBackground = false,
	HideGryphons = false,
	ActionBarScale = 1.0,
	ShowBagPackTexture = true,

	-- LORTI UI SUB-OPTIONS
	LortiUI_PlayerTargetFocus = true,  -- Player, Target, Focus frame textures
	LortiUI_Party             = true,  -- Party frame textures
	LortiUI_PartyTargets      = true,  -- Target-of-party frame textures
	LortiUI_PartyPet          = true,  -- Party pet frame textures
	LortiUI_Arena             = true,  -- Arena frame textures
	LortiUI_ActionBars        = true,  -- Action bar textures
	LortiUI_Minimap           = true,  -- Minimap textures & scroll
};

local configLoaded = false;

-- FireConfigEvent
local eventCallbacks = {};

local function FireConfigEvent(eventName)
	if eventCallbacks[eventName] then
		for _, callback in ipairs(eventCallbacks[eventName]) do
			local success, err = pcall(callback);
			if not success then
				print("|cffFF0000NUF:|r Error in " .. eventName .. ": " .. tostring(err));
			end
		end
	end
end

-- ── Checkboxes compartidos entre pestañas ────────────────
-- Un mismo setting (ej: PartyMode3v3) puede tener su checkbox en mas de
-- una pestaña. Se registran todos aca y se refrescan juntos al guardar.
K._settingCheckboxes = K._settingCheckboxes or {};

function K.RegisterSettingCheckbox(setting, cb)
	if not setting or not cb then return; end
	if not K._settingCheckboxes[setting] then K._settingCheckboxes[setting] = {}; end
	table.insert(K._settingCheckboxes[setting], cb);
end

function K.RefreshSettingCheckboxes(setting)
	local list = K._settingCheckboxes[setting];
	if not list then return; end
	local value = C[setting];
	if type(value) == "number" then value = (value == 1); end
	for _, cb in ipairs(list) do
		if cb.SetChecked then
			-- cb.nufInverted: el checkbox dice lo CONTRARIO del setting.
			--
			-- Hace falta para opciones redactadas en negativo ("Ocultar X")
			-- cuyo setting guarda el positivo ("mostrar X"). Sin esto, el
			-- refresco central les ponia el tilde al reves y el usuario veia
			-- la opcion cambiar sola al abrir el panel.
			if cb.nufInverted then
				cb:SetChecked(value ~= true);
			else
				cb:SetChecked(value == true);
			end
		end
	end
end

function K.RegisterConfigEvent(eventName, callback)
	if not eventCallbacks[eventName] then
		eventCallbacks[eventName] = {};
	end
	table.insert(eventCallbacks[eventName], callback);
end

-- SafeConvertType
local function SafeConvertType(value, targetType)
	if targetType == "boolean" then
		if type(value) == "string" then
			-- FIX: "false"/"0" deben convertirse a false, no a true
			return value == "true" or value == "1";
		end
		if type(value) == "number" then
			return value ~= 0;
		end
		return not not value;
	elseif targetType == "number" then
		local num = tonumber(value);
		if not num then
			return 0;
		end
		return num;
	elseif targetType == "string" then
		return tostring(value);
	end
	return value;
end

-- LoadConfigFromDB
local function LoadConfigFromDB()
	if configLoaded then 
		return; 
	end
	
	if not NidhausUnitFramesDB then
		NidhausUnitFramesDB = {};
	end
	
	-- Si la DB está vacía, copiar defaults
	if not next(NidhausUnitFramesDB) then
		for key, value in pairs(defaults) do
			NidhausUnitFramesDB[key] = value;
		end
	end
	
	-- Cargar cada valor desde DB o usar default
	for key, defaultValue in pairs(defaults) do
		local savedValue = NidhausUnitFramesDB[key];
		
		if savedValue ~= nil then
			local value = SafeConvertType(savedValue, type(defaultValue));
			C[key] = value;
			
			if type(value) ~= type(savedValue) then
				NidhausUnitFramesDB[key] = value;
			end
		else
			C[key] = defaultValue;
			NidhausUnitFramesDB[key] = defaultValue;
		end
	end
	
	-- Opciones que ya no existen y podrian venir guardadas de una version
	-- anterior. Sin esto, quedaban aplicadas aunque el desplegable ya no
	-- las ofrezca (y el usuario no tenia como sacarlas).
	local DEAD = {
		UnitNameBorder   = { Mono = "None", OutMono = "None" },
		PartyFontOutline = { MONOCHROME = "OUTLINE", ["OUTLINE,MONOCHROME"] = "OUTLINE" },
	};
	for key, map in pairs(DEAD) do
		local fixed = map[C[key]];
		if fixed then
			C[key] = fixed;
			NidhausUnitFramesDB[key] = fixed;
		end
	end

	configLoaded = true;
	
	-- DISPARAR EVENTO: Config lista
	FireConfigEvent("CONFIG_LOADED");
end

-- SaveConfig
local function SaveConfig(key, value)
	if not configLoaded then
		return false;
	end
	
	if defaults[key] == nil then 
		return false; 
	end
	
	if value == nil then
		return false;
	end
	
	local actualValue = SafeConvertType(value, type(defaults[key]));
	
	if type(actualValue) ~= type(defaults[key]) then
		return false;
	end
	
	-- Guardar en ambos lugares
	C[key] = actualValue;
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB[key] = actualValue;
	
	-- Mantener sincronizados los checkboxes del mismo setting en otras pestañas
	if K.RefreshSettingCheckboxes then K.RefreshSettingCheckboxes(key); end

	-- DISPARAR EVENTO: Config cambiada
	FireConfigEvent("CONFIG_CHANGED");
	
	return true;
end

-- ShowConfig
local function ShowConfig()
	print(L["CFG_HEADER"]);
	
	if not configLoaded then
		print(L["CFG_NOT_LOADED"]);
		return;
	end
	
	print(L["CFG_FORMAT"]);
	print("");
	
	local allMatch = true;
	local keys = {};
	
	for key in pairs(defaults) do
		table.insert(keys, key);
	end
	table.sort(keys);
	
	for _, key in ipairs(keys) do
		local dbValue = NidhausUnitFramesDB[key];
		local cValue = C[key];
		local match = (dbValue == cValue) and (type(dbValue) == type(cValue));
		
		if not match then allMatch = false; end
		
		local status = match and "|cffFFD100OK|r" or "|cffFF0000ERR|r";
		
		print(string.format("%s %-30s DB: %-8s (%s) | C: %-8s (%s)", 
			status,
			key,
			tostring(dbValue),
			type(dbValue),
			tostring(cValue),
			type(cValue)
		));
	end
	

	print("");
	if NidhausUnitFramesDB.positions then
		print(L["CFG_SAVED_POS"]);
		for key, pos in pairs(NidhausUnitFramesDB.positions) do
			if type(pos) == "table" then
				-- FIX: Soportar formato con nombres (FrameDragger) y con índices (legacy)
				local anchor = pos.point or pos[1] or "?";
				local xVal = pos.x or pos[4] or 0;
				local yVal = pos.y or pos[5] or 0;
				print(string.format("  %s: %s at (%.1f, %.1f)", 
					key, tostring(anchor), tonumber(xVal) or 0, tonumber(yVal) or 0));
			else
				print(string.format("  %s: %s", key, tostring(pos)));
			end
		end
	else
		print(L["CFG_NO_SAVED_POS"]);
	end
	
	print("");
	if allMatch then
		print(L["CFG_ALL_SYNC"]);
	else
		print(L["CFG_OUT_OF_SYNC"]);
	end
	print("");
end

-- ResetConfig
--
-- BORRA TODO Y RE-SIEMBRA, en vez de ir clave por clave.
--
-- Antes esto reponia los "defaults" y limpiaba solo dos sub-tablas
-- (positions y ArenaMover). Pero el addon guarda MUCHO mas que eso: al
-- medirlo habia 41 claves que no son settings normales — posiciones de cada
-- modulo, escalas, estado de prendido/apagado, anclas de auras, trinkets,
-- timers, iconos del minimapa — y ademas otras cuatro SavedVariables
-- enteras (PartyBuffsDB, NiceDamageDB, DTSU_DB, PaladinICD_DB) que no se
-- tocaban nunca. O sea que "Reset Defaults" dejaba casi todo como estaba.
--
-- Enumerar las 41 seria volver al mismo problema: cada modulo nuevo que
-- guarde algo hay que acordarse de agregarlo, y el primer olvido rompe el
-- reset otra vez. Asi que se hace al reves: se vacia la base y se vuelve a
-- sembrar desde defaults. Lo que se agregue en el futuro queda cubierto
-- solo, sin mantener ninguna lista.
--
-- Lo unico que se conserva son los PERFILES GUARDADOS. No son ajustes:
-- son copias de la config y de las barras/macros de otros personajes, y
-- perderlas no se puede deshacer.
local PRESERVE_ON_RESET = {
	CharProfiles = true,   -- config del addon, por personaje
	SlotProfiles = true,   -- barras / macros / bindeos, por personaje
	SlotBackup   = true,   -- backup del ultimo import o borrado
};

local function ResetConfig()
	if not configLoaded then
		return;
	end

	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end

	-- Apartar lo que sobrevive
	local guardado = {};
	for key in pairs(PRESERVE_ON_RESET) do
		guardado[key] = NidhausUnitFramesDB[key];
	end

	-- Vaciar de verdad
	for key in pairs(NidhausUnitFramesDB) do
		NidhausUnitFramesDB[key] = nil;
	end

	-- Volver a poner lo apartado
	for key, value in pairs(guardado) do
		NidhausUnitFramesDB[key] = value;
	end

	-- Y sembrar los defaults
	for key, value in pairs(defaults) do
		C[key] = value;
		NidhausUnitFramesDB[key] = value;
	end

	-- Las otras SavedVariables del addon. Son globales aparte y por eso se
	-- escapaban del reset. Se vacian y cada modulo las vuelve a llenar con
	-- sus propios defaults en el reload que viene despues.
	if PartyBuffsDB   ~= nil then PartyBuffsDB   = {}; end
	if NiceDamageDB   ~= nil then NiceDamageDB   = {}; end
	if DTSU_DB        ~= nil then DTSU_DB        = {}; end
	if PaladinICD_DB  ~= nil then PaladinICD_DB  = {}; end

	print(L["CFG_RESET_OK"]);
	
	FireConfigEvent("CONFIG_RESET");
	-- FIX: También disparar CONFIG_LOADED para que los módulos se re-inicialicen
	-- (la mayoría solo escucha CONFIG_LOADED y CONFIG_CHANGED, no CONFIG_RESET)
	FireConfigEvent("CONFIG_LOADED");
end

-- IsConfigLoaded
local function IsConfigLoaded()
	return configLoaded;
end

-- Exports
K.SaveConfig = SaveConfig;
K.ShowConfig = ShowConfig;
K.ResetConfig = ResetConfig;
K.IsConfigLoaded = IsConfigLoaded;

-- FIX: SaveConfigSilent — guarda sin disparar CONFIG_CHANGED (para batch saves)
-- Usar con FlushConfigChanges al final del batch
function K.SaveConfigSilent(key, value)
	if not configLoaded then return false; end
	if defaults[key] == nil then return false; end
	if value == nil then return false; end
	local actualValue = SafeConvertType(value, type(defaults[key]));
	if type(actualValue) ~= type(defaults[key]) then return false; end
	C[key] = actualValue;
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB[key] = actualValue;
	return true;
end

-- FIX: FlushConfigChanges — dispara CONFIG_CHANGED una sola vez después de batch save
function K.FlushConfigChanges()
	FireConfigEvent("CONFIG_CHANGED");
end

-- =========================================================
-- PROFILE SERIALIZER (Export / Import)
-- =========================================================

-- Serialize a Lua value to a portable string
local function SerializeValue(val)
	local t = type(val);
	if t == "string" then
		return string.format("%q", val);
	elseif t == "number" then
		return tostring(val);
	elseif t == "boolean" then
		return val and "true" or "false";
	elseif t == "table" then
		local parts = {};
		for k, v in pairs(val) do
			local key;
			if type(k) == "string" then
				key = "[" .. string.format("%q", k) .. "]";
			else
				key = "[" .. tostring(k) .. "]";
			end
			table.insert(parts, key .. "=" .. SerializeValue(v));
		end
		return "{" .. table.concat(parts, ",") .. "}";
	else
		return "nil";
	end
end

-- Serialize the full config DB to a copyable string
function K.ExportProfile()
	if not configLoaded or not NidhausUnitFramesDB then
		return nil, "Config not loaded";
	end

	-- Build export table: all defaults keys + positions + modules + ArenaMover
	local exportData = {};

	for key in pairs(defaults) do
		if NidhausUnitFramesDB[key] ~= nil then
			exportData[key] = NidhausUnitFramesDB[key];
		end
	end

	if NidhausUnitFramesDB.positions then
		exportData.positions = NidhausUnitFramesDB.positions;
	end
	if NidhausUnitFramesDB.Modules then
		exportData.Modules = NidhausUnitFramesDB.Modules;
	end
	if NidhausUnitFramesDB.ArenaMover then
		exportData.ArenaMover = NidhausUnitFramesDB.ArenaMover;
	end

	return "return " .. SerializeValue(exportData);
end

-- Deserialize a string back to a table (sandboxed)
function K.ImportProfile(str)
	if not str or str == "" then
		return false, "Empty string";
	end

	local func, err = loadstring(str);
	if not func then
		return false, "Syntax error: " .. tostring(err);
	end

	-- Sandbox: block access to all globals
	setfenv(func, {});

	local ok, result = pcall(func);
	if not ok then
		return false, "Execution error: " .. tostring(result);
	end
	if type(result) ~= "table" then
		return false, "Invalid data (expected table)";
	end

	-- Validate: at least some known keys exist
	local knownCount = 0;
	for key in pairs(defaults) do
		if result[key] ~= nil then knownCount = knownCount + 1; end
	end
	if knownCount < 3 then
		return false, "Data doesn't look like a NUF profile (too few known keys)";
	end

	-- Apply: overwrite settings
	for key, defaultValue in pairs(defaults) do
		if result[key] ~= nil then
			local value = SafeConvertType(result[key], type(defaultValue));
			NidhausUnitFramesDB[key] = value;
			C[key] = value;
		end
	end

	-- Overwrite positions if present
	if result.positions and type(result.positions) == "table" then
		NidhausUnitFramesDB.positions = result.positions;
	end

	-- Overwrite modules if present
	if result.Modules and type(result.Modules) == "table" then
		NidhausUnitFramesDB.Modules = result.Modules;
	end

	-- Overwrite ArenaMover if present
	if result.ArenaMover and type(result.ArenaMover) == "table" then
		NidhausUnitFramesDB.ArenaMover = result.ArenaMover;
	end

	return true;
end

-- Deep copy helper (for future profile copy features)
function K.DeepCopy(orig)
	if type(orig) ~= "table" then return orig; end
	local copy = {};
	for k, v in pairs(orig) do
		copy[K.DeepCopy(k)] = K.DeepCopy(v);
	end
	return copy;
end

-- SyncConfigToDB
local function SyncConfigToDB()
	if not configLoaded then return; end
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	for key in pairs(defaults) do
		if C[key] ~= nil then
			NidhausUnitFramesDB[key] = C[key];
		end
	end
end

-- ADDON_LOADED
local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("ADDON_LOADED");
initFrame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" and addonName == AddOnName then
		self:UnregisterEvent("ADDON_LOADED");
		
		local success, err = pcall(LoadConfigFromDB);
		if not success then
			-- FIX: Imprimir el error para que el usuario sepa que su config no cargó
			print("|cffFF0000NUF:|r Config load error: " .. tostring(err));
			for key, value in pairs(defaults) do
				C[key] = value;
			end
			configLoaded = true;
			-- FIX: Disparar CONFIG_LOADED incluso si pcall falló.
			-- Sin esto, NINGÚN sistema se inicializa (ArenaFrame, NewPartyFrame, etc.)
			FireConfigEvent("CONFIG_LOADED");
		end
	end
end);

-- FIX PERF: Only sync on PLAYER_LOGOUT (safety net).
-- SaveConfig() already writes to both C[] and NidhausUnitFramesDB in real-time.
-- PLAYER_LEAVING_WORLD fires on EVERY loading screen (instance, BG, zone change),
-- running a full iteration of ~45 keys each time for no benefit.
local saveFrame = CreateFrame("Frame");
saveFrame:RegisterEvent("PLAYER_LOGOUT");
saveFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGOUT" and configLoaded then
		SyncConfigToDB();
	end
end);