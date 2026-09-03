local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PowerBar.lua   (portado de MobileEnergy 0.22 - B-Buck)
--
-- Barra movible de recurso (mana / energia / rabia / poder runico /
-- concentracion) para tenerla cerca del personaje y no tener que
-- mirar al marco del jugador.
--
-- POR QUE UNA REESCRITURA Y NO UNA COPIA:
-- el addon original compara UnitClass("Player") contra los nombres
-- de clase EN ESPAÑOL ("Guerrero", "Picaro", ...), asi que en un
-- cliente en ingles no muestra nada. Ademas pintaba de azul oscuro
-- a cazador, paladin, sacerdote, brujo, etc. sin distinguir el tipo
-- de recurso. Aca el color sale de UnitPowerType, que es lo correcto
-- y funciona en cualquier idioma y con cualquier clase.
--
-- Mover: Alt + click izquierdo y arrastrar.
-- =========================================================

local DEFAULT_W, DEFAULT_H = 160, 16;

local enabled = false;

-- Declaracion ADELANTADA. ApplyBarLayout y los setters de ancho/alto estan
-- definidos mas arriba en el archivo que el cuerpo de DB(), y en Lua un
-- "local function" declarado despues NO esta en scope: se compilaba como
-- global nil y reventaba con "attempt to call global 'DB'".
local DB;

-- Color por TIPO de recurso, no por clase (0=mana 1=rabia 2=foco
-- 3=energia 6=poder runico). Fallback: azul mana.
-- Color de la clase del personaje, para la barra de vida. Se resuelve una
-- sola vez: nadie cambia de clase a mitad de sesion. CUSTOM_CLASS_COLORS es
-- el estandar que exponen los addons que retocan la paleta (ClassColors,
-- phanx...); si no esta, manda la tabla de Blizzard.
local CLASS_R, CLASS_G, CLASS_B;
do
	local _, class = UnitClass("player");
	local t = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class])
		or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]);
	if t then CLASS_R, CLASS_G, CLASS_B = t.r, t.g, t.b; end
end

local POWER_COLORS = {
	[0] = { 0.20, 0.35, 0.90 },   -- Mana
	[1] = { 0.85, 0.15, 0.15 },   -- Rabia
	[2] = { 0.90, 0.55, 0.20 },   -- Concentracion (pet)
	[3] = { 0.95, 0.90, 0.25 },   -- Energia
	[6] = { 0.00, 0.75, 0.95 },   -- Poder runico
};

-- ---------------------------------------------------------
-- Frame
-- ---------------------------------------------------------
local frame = CreateFrame("Frame", "NUF_PowerBarFrame", UIParent);
frame:SetSize(DEFAULT_W, DEFAULT_H);
frame:Hide();
frame:SetMovable(true);
-- Arranca transparente al mouse: la barra vive encima del personaje y
-- si captura clicks no podes seleccionar lo que tenga detras. El mouse
-- se enciende solo mientras se la esta acomodando (boton "Move").
frame:EnableMouse(false);
frame:SetClampedToScreen(true);

frame:SetBackdrop({
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
});
frame:SetBackdropColor(0, 0, 0, 0.6);
frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9);

local PAD, BAR_H, GAP = 4, 14, 2;   -- para el modo con barra de vida

-- Barra de VIDA (opcional, arriba). El anclaje real lo pone ApplyBarLayout.
local healthBar = CreateFrame("StatusBar", "NUF_PowerBarHealth", frame);
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
healthBar:SetMinMaxValues(0, 100);
healthBar:SetValue(100);
healthBar:Hide();

local healthBG = healthBar:CreateTexture(nil, "BACKGROUND");
healthBG:SetAllPoints(healthBar);
healthBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
healthBG:SetVertexColor(0.1, 0.1, 0.1, 0.6);

local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0);

-- Barra de RECURSO (la de siempre).
local bar = CreateFrame("StatusBar", "NUF_PowerBarStatus", frame);
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
bar:SetMinMaxValues(0, 100);
bar:SetValue(100);

local barBG = bar:CreateTexture(nil, "BACKGROUND");
barBG:SetAllPoints(bar);
barBG:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
barBG:SetVertexColor(0.1, 0.1, 0.1, 0.6);

local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
text:SetPoint("CENTER", bar, "CENTER", 0, 0);
text:SetText("0 / 0");


-- =========================================================
-- AURAS
--
-- Dos filas de iconos chicos colgadas del marco: arriba los buffs,
-- abajo los debuffs. El marco de Blizzard solo muestra los que el
-- elige; aca van TODOS los que tengas, hasta el tope por fila que
-- marque el slider.
--
-- La posicion es elegible entre tres (derecha, abajo, arriba) con el
-- mismo selector de botones que usan los estilos de los timers.
--
-- Los iconos son hijos del marco, asi que se ocultan y se escalan con
-- el: no hay que acordarse de esconderlos por separado.
-- =========================================================
local DEF_AURA_SIZE, DEF_AURA_PERROW = 16, 8;
local AURA_GAP, AURA_MARGIN = 2, 4;

-- Los mismos colores que usa Blizzard para el borde de los debuffs.
local DEBUFF_COLORS = {
	Magic   = { 0.20, 0.60, 1.00 },
	Curse   = { 0.60, 0.00, 1.00 },
	Disease = { 0.60, 0.40, 0.00 },
	Poison  = { 0.00, 0.60, 0.00 },
};
local DEBUFF_DEFAULT = { 0.80, 0.10, 0.10 };
local BUFF_EDGE      = { 0.25, 0.25, 0.25 };

local buffRow   = CreateFrame("Frame", nil, frame);
local debuffRow = CreateFrame("Frame", nil, frame);
local buffIcons, debuffIcons = {}, {};

local function MakeIcon(parent)
	local f = CreateFrame("Frame", nil, parent);

	-- Un cuadrado un pixel mas grande por detras: al quedar tapado por el
	-- icono, lo unico que se ve es el filo. Sale mas barato que un backdrop
	-- y en 3.3.5a los Button no aceptan SetBackdrop.
	f.edge = f:CreateTexture(nil, "BACKGROUND");
	f.edge:SetTexture("Interface\\Buttons\\WHITE8X8");
	f.edge:SetPoint("TOPLEFT",     f, "TOPLEFT",     -1,  1);
	f.edge:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  1, -1);

	f.icon = f:CreateTexture(nil, "ARTWORK");
	f.icon:SetAllPoints(f);
	f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);   -- sin el borde del arte

	f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate");
	f.cd:SetAllPoints(f);

	f.count = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
	f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, 0);

	f:Hide();
	return f;
end

local function EnsureIcons(list, parent, n)
	for i = #list + 1, n do
		list[i] = MakeIcon(parent);
	end
end

-- Acomoda las dos filas segun la posicion elegida. Siempre en el mismo
-- orden de lectura: los buffs por encima de los debuffs, vayan donde vayan.
local function LayoutAuras()
	local db   = DB();
	local size = db.auraSize   or DEF_AURA_SIZE;
	local per  = db.auraPerRow or DEF_AURA_PERROW;
	local pos  = C.PowerBarAuraPos or "RIGHT";
	local rowW = (per * size) + ((per - 1) * AURA_GAP);

	EnsureIcons(buffIcons,   buffRow,   per);
	EnsureIcons(debuffIcons, debuffRow, per);

	for _, row in ipairs({ buffRow, debuffRow }) do
		row:SetWidth(rowW);
		row:SetHeight(size);
	end

	for _, list in ipairs({ buffIcons, debuffIcons }) do
		for i, ic in ipairs(list) do
			ic:SetWidth(size);
			ic:SetHeight(size);
			ic:ClearAllPoints();
			ic:SetPoint("LEFT", ic:GetParent(), "LEFT", (i - 1) * (size + AURA_GAP), 0);
			if i > per then ic:Hide(); end
		end
	end

	buffRow:ClearAllPoints();
	debuffRow:ClearAllPoints();

	if pos == "BOTTOM" then
		buffRow:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -AURA_MARGIN);
		debuffRow:SetPoint("TOPLEFT", buffRow, "BOTTOMLEFT", 0, -AURA_GAP);
	elseif pos == "TOP" then
		-- Subiendo: la fila pegada al marco es la de debuffs, y los buffs
		-- quedan por encima. Asi el orden buffs-arriba se mantiene.
		debuffRow:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, AURA_MARGIN);
		buffRow:SetPoint("BOTTOMLEFT", debuffRow, "TOPLEFT", 0, AURA_GAP);
	else
		buffRow:SetPoint("TOPLEFT", frame, "TOPRIGHT", AURA_MARGIN, 0);
		debuffRow:SetPoint("TOPLEFT", buffRow, "BOTTOMLEFT", 0, -AURA_GAP);
	end
end

local function FillRow(list, getter, per, isDebuff)
	local shown = 0;
	for i = 1, per do
		local ic = list[i];
		if not ic then break; end
		local name, _, icon, count, dtype, duration, expires = getter("player", i);
		if name and icon then
			ic.icon:SetTexture(icon);

			local col = isDebuff
				and (DEBUFF_COLORS[dtype or ""] or DEBUFF_DEFAULT)
				or BUFF_EDGE;
			ic.edge:SetVertexColor(col[1], col[2], col[3]);

			if count and count > 1 then
				ic.count:SetText(count);
				ic.count:Show();
			else
				ic.count:Hide();
			end

			-- Las auras sin duracion (las de siempre) no llevan barrido.
			if duration and duration > 0 and expires then
				ic.cd:Show();
				CooldownFrame_SetTimer(ic.cd, expires - duration, duration, 1);
			else
				ic.cd:Hide();
			end

			ic:Show();
			shown = shown + 1;
		else
			ic:Hide();
		end
	end
	return shown;
end

local function UpdateAuras()
	if not C.PowerBarShowAuras then
		buffRow:Hide();
		debuffRow:Hide();
		return;
	end
	local per = DB().auraPerRow or DEF_AURA_PERROW;
	FillRow(buffIcons,   UnitBuff,   per, false);
	FillRow(debuffIcons, UnitDebuff, per, true);
	buffRow:Show();
	debuffRow:Show();
end

-- Lo que necesita el panel.
function K.GetPowerBarAuraSize()   return DB().auraSize   or DEF_AURA_SIZE;   end
function K.GetPowerBarAuraPerRow() return DB().auraPerRow or DEF_AURA_PERROW; end
function K.GetPowerBarAuraPos()    return C.PowerBarAuraPos or "RIGHT";       end

function K.SavePowerBarAuraSize(v)   DB().auraSize   = v; LayoutAuras(); UpdateAuras(); end
function K.SavePowerBarAuraPerRow(v) DB().auraPerRow = v; LayoutAuras(); UpdateAuras(); end

function K.SetPowerBarAuraPos(v)
	local val = (v == "TOP" and "TOP") or (v == "BOTTOM" and "BOTTOM") or "RIGHT";
	K.SaveConfig("PowerBarAuraPos", val);
	LayoutAuras();
	UpdateAuras();
end

function K.ApplyPowerBarAuras()
	LayoutAuras();
	UpdateAuras();
end

-- Acomoda las barras segun si se muestra la vida o no, y ajusta la altura
-- del marco (una barra = fino; con vida = dos barras apiladas).
local function ApplyBarLayout()
	local db = DB();
	local barH = db.barHeight or BAR_H;   -- alto de cada barra (slider)
	bar:ClearAllPoints();
	healthBar:ClearAllPoints();
	if C.PowerBarShowHealth then
		healthBar:Show();
		healthBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",   PAD, -PAD);
		healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD);
		healthBar:SetHeight(barH);
		bar:SetPoint("TOPLEFT",  healthBar, "BOTTOMLEFT",  0, -GAP);
		bar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, -GAP);
		bar:SetHeight(barH);
		frame:SetHeight(PAD + barH + GAP + barH + PAD);
	else
		healthBar:Hide();
		bar:SetPoint("TOPLEFT",  frame, "TOPLEFT",   PAD, -PAD);
		bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD);
		bar:SetHeight(barH);
		frame:SetHeight(PAD + barH + PAD);
	end
	-- Las filas de auras cuelgan de los bordes del marco: si cambia de alto
	-- hay que reanclarlas.
	LayoutAuras();
end
K.ApplyPowerBarLayout = ApplyBarLayout;

-- Setters de ancho y alto (los usan los sliders del panel).
function K.SavePowerBarWidth(w)
	DB().width = w;
	frame:SetWidth(w);
end
function K.GetPowerBarWidth() return DB().width or DEFAULT_W; end

function K.SavePowerBarBarHeight(h)
	DB().barHeight = h;
	ApplyBarLayout();
end
function K.GetPowerBarBarHeight() return DB().barHeight or BAR_H; end

-- ---------------------------------------------------------
-- DB
-- ---------------------------------------------------------
-- Sin "local": asigna a la variable declarada arriba (no crea una nueva).
function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.PowerBar then
		NidhausUnitFramesDB.PowerBar = {};
	end
	return NidhausUnitFramesDB.PowerBar;
end

local function SavePosition()
	local db = DB();
	local point, _, relativePoint, x, y = frame:GetPoint();
	if not point then return; end
	db.point = point; db.relativePoint = relativePoint; db.x = x; db.y = y;
end

local function RestorePosition()
	local db = DB();
	frame:ClearAllPoints();
	if db.point then
		frame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
	else
		-- Debajo del personaje, que es para lo que sirve la barra
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, -140);
	end
	frame:SetScale(db.scale or 1);
	frame:SetWidth(db.width or DEFAULT_W);
	ApplyBarLayout();   -- fija la altura segun si hay barra de vida
end

function K.SavePowerBarScale(scale)
	DB().scale = scale;
	frame:SetScale(scale or 1);
end

function K.GetPowerBarScale()
	return DB().scale or 1;
end

function K.ResetPowerBarPosition()
	local db = DB();
	db.point, db.relativePoint, db.x, db.y, db.scale = nil, nil, nil, nil, nil;
	db.width, db.height, db.barHeight = nil, nil, nil;
	RestorePosition();
end

frame:RegisterForDrag("LeftButton");
frame:SetScript("OnDragStart", function(self)
	if IsAltKeyDown() then self:StartMoving(); end
end);
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing();
	SavePosition();
end);

-- ---------------------------------------------------------
-- Actualizacion
-- ---------------------------------------------------------
local testMode = false;

local function ShouldBeVisible()
	if not enabled then return false; end
	if testMode then return true; end
	-- Opcional: solo en combate
	if C.PowerBarCombatOnly and not InCombatLockdown() then return false; end

	-- Opcional: esconderla cuando estas "a full" y fuera de combate. Asi no
	-- ocupa pantalla cuando no aporta nada, y reaparece sola al gastar
	-- recurso, perder vida o entrar en combate.
	if C.PowerBarHideWhenFull and not InCombatLockdown() then
		local cur, max = UnitPower("player") or 0, UnitPowerMax("player") or 0;
		local hp, hpmax = UnitHealth("player") or 0, UnitHealthMax("player") or 0;
		local powerFull  = (max <= 0) or (cur >= max);
		local healthFull = (hpmax <= 0) or (hp >= hpmax);
		if powerFull and healthFull then return false; end
	end

	return true;
end

-- Color de la barra de vida segun cuanta queda: verde -> amarillo -> rojo.
local function HealthColor(pct)
	if pct > 0.5 then
		-- 100%..50%: verde -> amarillo
		local t = (1 - pct) * 2;
		return 0.15 + (0.85 * t), 0.75, 0.15;
	else
		-- 50%..0%: amarillo -> rojo
		local t = pct * 2;
		return 1, 0.75 * t, 0.15 * t;
	end
end

local function UpdateBar()
	if not ShouldBeVisible() then frame:Hide(); return; end

	local cur = UnitPower("player") or 0;
	local max = UnitPowerMax("player") or 0;
	if max <= 0 then frame:Hide(); return; end

	local ptype = UnitPowerType("player") or 0;
	local col = POWER_COLORS[ptype] or POWER_COLORS[0];
	bar:SetStatusBarColor(col[1], col[2], col[3]);
	bar:SetMinMaxValues(0, max);
	bar:SetValue(cur);

	if C.PowerBarShowPercent then
		text:SetText(string.format("%d%%", math.floor(cur / max * 100 + 0.5)));
	else
		text:SetText(cur .. " / " .. max);
	end

	-- Barra de vida (si esta activada)
	if C.PowerBarShowHealth then
		local hp    = UnitHealth("player") or 0;
		local hpmax = UnitHealthMax("player") or 0;
		if hpmax > 0 then
			healthBar:SetMinMaxValues(0, hpmax);
			healthBar:SetValue(hp);
			-- Color segun el porcentaje: se pone amarilla y despues roja a
			-- medida que baja, para que se note de reojo.
			-- Orden de prioridad: color de clase > degradado > verde fijo.
			-- El de clase es fijo (sos siempre la misma clase), asi que se
			-- calcula una sola vez al cargar y no en cada tick.
			if C.PowerBarHealthClassColor and CLASS_R then
				healthBar:SetStatusBarColor(CLASS_R, CLASS_G, CLASS_B);
			elseif C.PowerBarHealthGradient then
				healthBar:SetStatusBarColor(HealthColor(hp / hpmax));
			else
				healthBar:SetStatusBarColor(0.15, 0.75, 0.15);   -- verde fijo
			end
			if C.PowerBarShowPercent then
				healthText:SetText(string.format("%d%%", math.floor(hp / hpmax * 100 + 0.5)));
			else
				healthText:SetText(hp .. " / " .. hpmax);
			end
		end
	end

	frame:Show();
end

K.UpdatePowerBar = UpdateBar;

-- Los eventos se registran SOLO con el modulo activo.
-- UNIT_POWER es de los mas ruidosos del juego: en 3.3.5a no existe
-- RegisterUnitEvent, asi que dispara para CADA unidad en rango. En un
-- BG de 40 son cientos de despachos por segundo, y antes se pagaban
-- aunque la barra estuviera apagada.
local events = CreateFrame("Frame");

local function RegisterPowerEvents()
	events:RegisterEvent("PLAYER_ENTERING_WORLD");
	-- OJO 3.3.5a: NO existe UNIT_POWER (llego en Cataclysm). Los recursos se
	-- avisan con eventos por tipo. Registrarlos todos cubre cualquier clase
	-- y hace que la barra se actualice en tiempo real (antes solo se veia
	-- bien tras un /reload).
	-- pcall por si algun nombre no existe en este cliente: RegisterEvent con
	-- un evento desconocido tira error y romperia el modulo entero.
	for _, ev in ipairs({
		"UNIT_MANA", "UNIT_MAXMANA", "UNIT_RAGE", "UNIT_MAXRAGE",
		"UNIT_ENERGY", "UNIT_MAXENERGY", "UNIT_FOCUS", "UNIT_MAXFOCUS",
		"UNIT_RUNIC_POWER", "UNIT_MAXRUNIC_POWER", "UNIT_DISPLAYPOWER",
	}) do
		pcall(events.RegisterEvent, events, ev);
	end
	events:RegisterEvent("PLAYER_REGEN_DISABLED");
	events:RegisterEvent("PLAYER_REGEN_ENABLED");
	-- Las auras solo se escuchan si se estan mostrando: UNIT_AURA tampoco
	-- es barato, y en 3.3.5a dispara para cualquier unidad.
	if C.PowerBarShowAuras then events:RegisterEvent("UNIT_AURA"); end
	-- Los eventos de vida (tambien ruidosos) solo se enganchan si hacen
	-- falta: con la barra de vida activada, o con el auto-ocultar (que
	-- necesita enterarse cuando perdes vida para volver a mostrarse).
	if C.PowerBarShowHealth or C.PowerBarHideWhenFull then
		events:RegisterEvent("UNIT_HEALTH");
		events:RegisterEvent("UNIT_MAXHEALTH");
	end
end

events:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_ENTERING_WORLD" then
		RestorePosition();
		UpdateBar();
		UpdateAuras();
		return;
	end
	-- Los eventos UNIT_* traen la unidad como primer arg: filtramos a player.
	-- Los de combate (PLAYER_REGEN_*) no traen unidad y pasan directo.
	if unit and unit ~= "player" then return; end
	if event == "UNIT_AURA" then UpdateAuras(); return; end
	UpdateBar();
end);

-- La llama el checkbox del panel: reacomoda las barras y re-registra los
-- eventos de vida segun corresponda.
function K.ApplyPowerBarHealth()
	ApplyBarLayout();
	if enabled then
		events:UnregisterAllEvents();
		RegisterPowerEvents();
		UpdateBar();
		UpdateAuras();
	end
end

-- La llama el checkbox de auras del panel: re-registra UNIT_AURA (o lo
-- suelta) y redibuja.
function K.ApplyPowerBarAuraToggle()
	if enabled then
		events:UnregisterAllEvents();
		RegisterPowerEvents();
	end
	LayoutAuras();
	UpdateAuras();
end

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
K.RegisterModule("PowerBar", {
	name    = L["MOD_POWERBAR"] or "Power Bar",
	desc    = L["MOD_POWERBAR_DESC"]
		or "Movable mana / energy / rage / runic power bar. Alt + drag to move.",
	default = false,
	configLabel = L["BTN_MODULE_MOVE"] or "Move",
	configFunc = function()
		RestorePosition();
		testMode = not testMode;
		frame:EnableMouse(testMode);
		if testMode then
			UpdateBar();
			if not frame:IsShown() then
				bar:SetMinMaxValues(0, 100);
				bar:SetValue(70);
				bar:SetStatusBarColor(0.20, 0.35, 0.90);
				text:SetText("70 / 100");
				frame:Show();
			end
			print("|cff4FC3F7NUF:|r Power Bar - Alt + arrastrar para moverla. Click de nuevo en Move para salir.");
		else
			UpdateBar();
		end
	end,
	onEnable = function()
		enabled = true;
		RegisterPowerEvents();
		RestorePosition();
		UpdateBar();
		UpdateAuras();
	end,
	onDisable = function()
		enabled = false;
		testMode = false;
		events:UnregisterAllEvents();
		frame:Hide();
	end,
});

SLASH_NUFPOWERBAR1 = "/nufpower";
SlashCmdList["NUFPOWERBAR"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "reset" then
		K.ResetPowerBarPosition();
		print("|cff4FC3F7NUF:|r Power Bar - posicion reiniciada.");
	else
		print("|cff4FC3F7NUF:|r Power Bar - Alt + arrastrar para moverla. /nufpower reset");
	end
end
