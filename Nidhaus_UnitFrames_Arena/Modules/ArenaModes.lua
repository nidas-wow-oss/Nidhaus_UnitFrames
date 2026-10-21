local AddOnName = ...;
-- Addon a pedido: el namespace de NUF llega por el global (ver ArenaLoader).
local ns = NidhausUnitFramesNS;
local K, C, L = unpack(ns);

-- =========================================================
-- CADA ESTILO DE ARENA RECUERDA LO SUYO
--
-- Blizzard, Custom, Borderless, Compact 2 y Flat no tienen el mismo
-- tamaño ni la misma forma: lo que acomodas en uno no sirve en otro.
-- Antes la escala, la separacion, el tamaño de los iconos de DR y DoT, la
-- barra de casteo y el lugar de los marcos eran UNO solo para todos, y al
-- cambiar de estilo te quedaba lo del anterior.
--
-- Dos niveles:
--   * Por ESTILO (el aspecto): escalas, separaciones y tamaños.
--   * Por MODO (estilo + espejo, K.GetArenaPositionKey): las posiciones.
--     El espejo es para tener los marcos del otro lado de la pantalla,
--     asi que cada lado tiene su lugar.
--
-- Las posiciones de la barra de casteo, el trinket, la mascota, el ToT y
-- las filas de DR y DoT ya se guardaban por modo, cada una en su tabla.
-- Lo que se guardaba una sola vez (los valores de C y el ancla de los
-- marcos) se intercambia aca al cambiar: C y positions tienen SIEMPRE lo
-- del estilo y el modo que estan puestos, asi que el resto del addon los
-- sigue leyendo como siempre.
--
-- La primera vez que entras a un estilo arranca de fabrica: es nuevo.
-- =========================================================

local STYLE_KEYS = {
	"ArenaFrameScale", "ArenaFrameSpacing",
	"ArenaCastBarScale", "ArenaCastBarWidth",
	"ArenaDRSize", "ArenaDRSpacing",
	"ArenaDoTSize", "ArenaDoTSpacing",
	"ArenaToTScale",
};
K.ArenaStyleKeys = STYLE_KEYS;

-- El ancla de los marcos, en NidhausUnitFramesDB.positions.
local ANCHOR_KEYS = { "ArenaMover", "NidhausArenaAnchor" };

local function StyleOf() return C.ArenaFrameStyle or "Custom"; end
local function ModeOf()
	if K.GetArenaPositionKey then return K.GetArenaPositionKey(); end
	return StyleOf() .. "_" .. (C.ArenaMirrorMode and "mirror" or "normal");
end

local function Store(name)
	if type(NidhausUnitFramesDB) ~= "table" then NidhausUnitFramesDB = {}; end
	if type(NidhausUnitFramesDB[name]) ~= "table" then NidhausUnitFramesDB[name] = {}; end
	return NidhausUnitFramesDB[name];
end

local function Copy(t)
	if type(t) ~= "table" then return nil; end
	local o = {};
	for k, v in pairs(t) do o[k] = v; end
	return o;
end

-- De que estilo y modo son los valores que hay HOY en C y en positions.
local activeStyle, activeMode;

local function StashStyle(style)
	local t = {};
	for _, k in ipairs(STYLE_KEYS) do t[k] = C[k]; end
	Store("ArenaStyleValues")[style] = t;
end

local function LoadStyle(style)
	local t = Store("ArenaStyleValues")[style];
	for _, k in ipairs(STYLE_KEYS) do
		local v = t and t[k];
		if v == nil and K.GetConfigDefault then v = K.GetConfigDefault(k); end
		if v ~= nil then
			if not (K.SaveConfigSilent and K.SaveConfigSilent(k, v)) then C[k] = v; end
		end
	end
end

local function StashAnchor(mode)
	local pos = Store("positions");
	local t = {};
	for _, k in ipairs(ANCHOR_KEYS) do t[k] = Copy(pos[k]); end
	Store("ArenaModeAnchors")[mode] = t;
end

local function LoadAnchor(mode)
	local pos = Store("positions");
	local t = Store("ArenaModeAnchors")[mode];
	for _, k in ipairs(ANCHOR_KEYS) do pos[k] = t and Copy(t[k]) or nil; end
end

local function SavedPoint(p)
	local point = p.point or p[1];
	local relName = p.relativeTo or p[2];
	local rel = (type(relName) == "string" and _G[relName]) or UIParent;
	return point, rel, p.relativePoint or p[3], p.x or p[4] or 0, p.y or p[5] or 0;
end

-- El ancla (y el cuadro del Test) al lugar del modo puesto.
local function ApplyAnchor()
	if K.AfterCombat("ArenaModeAnchor", ApplyAnchor) then return; end
	local pos = NidhausUnitFramesDB and NidhausUnitFramesDB.positions;
	local p = pos and (pos.ArenaMover or pos.NidhausArenaAnchor);
	for _, name in ipairs({ "NidhausArenaEnemyFrames", "NUF_ArenaMover" }) do
		local f = _G[name];
		if f then
			f:ClearAllPoints();
			if type(p) == "table" and (p.point or p[1]) then
				f:SetPoint(SavedPoint(p));
			elseif C.ArenaFramePoint then
				f:SetPoint(unpack(C.ArenaFramePoint));
			end
		end
	end
end

-- Escalas, separacion y tamaños del estilo puesto.
local function ApplyStyleValues()
	if K.ApplyArenaScale then K.ApplyArenaScale(C.ArenaFrameScale); end
	if C.ArenaFrameOn and K.ApplyArenaSpacing then K.ApplyArenaSpacing(); end
	if C.ArenaCastBarEnable and K.ToggleArenaCastBar then K.ToggleArenaCastBar(true); end
	if K.ApplyArenaToTScale then K.ApplyArenaToTScale(C.ArenaToTScale); end
	-- DR y DoT leen su tamaño al redibujarse (K.RefreshArenaModeLayout).
end

-- Todo lo que se coloca por modo: cada pieza vuelve a SU lugar del modo
-- puesto, o al de fabrica si en ese modo nunca la moviste.
function K.RefreshArenaModeLayout()
	if K.RestoreCastBarPositions then pcall(K.RestoreCastBarPositions); end
	if K.PositionArenaTrinkets then pcall(K.PositionArenaTrinkets); end
	if K.RestorePetFramePositions then pcall(K.RestorePetFramePositions); end
	if K.RefreshArenaDRLayout then pcall(K.RefreshArenaDRLayout); end
	if K.RefreshArenaDoTLayout then pcall(K.RefreshArenaDoTLayout); end
	if K.RepositionAllArenaToT then pcall(K.RepositionAllArenaToT); end
	if K.RefreshArenaPanelSliders then pcall(K.RefreshArenaPanelSliders); end
end

-- LOS DATOS AL INSTANTE, LO VISUAL DESPUES DEL ESTILO.
--
-- El cambio de estilo dispara CONFIG_CHANGED ANTES de que el panel arme el
-- estilo nuevo. Ahi se intercambian solo los datos (C y positions); lo que
-- se ve se aplica cuando el estilo ya esta armado: lo llama el panel al
-- final, y si nadie lo llama, sale solo en el cuadro siguiente. Aplicar la
-- escala antes (con Flat la escala rearma el estilo Flat) le sacaba la
-- "foto de fabrica" al estilo viejo.
local applyPending = false;
local applier = CreateFrame("Frame");
applier:Hide();

-- Si cambio el estilo o el espejo: guarda lo del que se fue y trae lo del
-- que llega (solo datos). Devuelve true si hubo cambio.
local function SwapIfChanged()
	if not activeStyle then activeStyle, activeMode = StyleOf(), ModeOf(); end
	local style, mode = StyleOf(), ModeOf();
	local changed = false;
	if style ~= activeStyle then
		StashStyle(activeStyle);
		LoadStyle(style);
		activeStyle = style;
		changed = true;
	end
	if mode ~= activeMode then
		StashAnchor(activeMode);
		LoadAnchor(mode);
		activeMode = mode;
		changed = true;
	end
	if changed then
		applyPending = true;
		applier:Show();
	end
	return changed;
end
K.SwapArenaModeData = SwapIfChanged;

-- Aplica lo que quedo pendiente del cambio. true si habia algo.
local function ApplyPending()
	applier:Hide();
	if not applyPending then return false; end
	applyPending = false;
	pcall(ApplyAnchor);
	pcall(ApplyStyleValues);
	K.RefreshArenaModeLayout();
	return true;
end
applier:SetScript("OnUpdate", function() ApplyPending(); end);

-- Intercambia (si hace falta) y aplica ya. Llamarla de mas no hace nada;
-- devuelve true si hubo cambio.
function K.SyncArenaMode()
	SwapIfChanged();
	return ApplyPending();
end

function K.GetActiveArenaStyle() return activeStyle or StyleOf(); end

-- ---------------------------------------------------------
-- Lo guardado por versiones viejas
--
-- La barra de casteo, el trinket y la mascota caian a una posicion "sin
-- estilo" (normal / mirror / global) cuando el modo no tenia la suya: por
-- eso lo movido en un estilo aparecia igual en todos. Ahora eso pasa a ser
-- del estilo que tenes puesto y los demas arrancan de fabrica. Corre en
-- cada carga: si no queda nada viejo no hace nada, y asi tambien cubre un
-- perfil importado de una version anterior.
-- ---------------------------------------------------------
local LEGACY_TABLES = { "CastBarPositions", "TrinketPositions", "PetFramePositions" };

local function MigrateLegacy()
	if type(NidhausUnitFramesDB) ~= "table" then return; end
	local style = StyleOf();
	for _, name in ipairs(LEGACY_TABLES) do
		local db = NidhausUnitFramesDB[name];
		if type(db) == "table" then
			local n = db.normal or db.global;
			local m = db.mirror or db.global;
			if n and db[style .. "_normal"] == nil then db[style .. "_normal"] = n; end
			if m and db[style .. "_mirror"] == nil then db[style .. "_mirror"] = m; end
			db.normal, db.mirror, db.global = nil, nil, nil;
		end
	end
end

-- Al cargar (y tras "Reset Defaults"): lo que hay en C es del estilo puesto.
K.RegisterConfigEvent("CONFIG_LOADED", function()
	MigrateLegacy();
	activeStyle, activeMode = StyleOf(), ModeOf();
end);

-- Red de seguridad: cualquier cambio de estilo o espejo, venga de donde
-- venga, pasa por aca (el panel ademas la llama directo).
K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if activeStyle then SwapIfChanged(); end
end);
