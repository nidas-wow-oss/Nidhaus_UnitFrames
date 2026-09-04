local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ModuleManager.lua - Sistema de registro y gestión de módulos

K.Modules = {};
K.ModuleOrder = {};

function K.RegisterModule(id, info)
	if not id or not info then
		print(L["MM_REGISTER_ERROR"]);
		return;
	end

	if K.Modules[id] then
		return;
	end

	K.Modules[id] = {
		name      = info.name or id,
		desc      = info.desc or "",
		onEnable  = info.onEnable,
		onDisable = info.onDisable,
		createUI  = info.createUI or nil,
		default   = (info.default ~= false),
		hideFromModulesTab = info.hideFromModulesTab or false,
		-- Boton opcional al lado del checkbox, para abrir el "menu" del modulo
		-- (normalmente: mostrar el frame y desbloquearlo para moverlo)
		configFunc  = info.configFunc,
		configLabel = info.configLabel,
	};

	table.insert(K.ModuleOrder, id);
end

-- Un mismo modulo puede tener su checkbox en mas de un panel.
-- Se guardan todos para poder refrescarlos juntos.
K._moduleCheckboxes = K._moduleCheckboxes or {};

function K.RegisterModuleCheckbox(id, cb)
	if not id or not cb then return; end
	if not K._moduleCheckboxes[id] then K._moduleCheckboxes[id] = {}; end
	table.insert(K._moduleCheckboxes[id], cb);
end

-- Refresca los checkboxes del panel para un modulo (si ya fueron creados).
-- Lo usan los slash commands y los paneles para no desincronizar la UI.
function K.RefreshModuleCheckbox(id)
	local list = K._moduleCheckboxes and K._moduleCheckboxes[id];
	if not list then return; end
	local state = K.IsModuleEnabled(id);
	for _, cb in ipairs(list) do
		if cb.SetChecked then cb:SetChecked(state); end
	end
end

function K.IsModuleEnabled(id)
	if not NidhausUnitFramesDB or not NidhausUnitFramesDB.Modules then return false; end
	local val = NidhausUnitFramesDB.Modules[id];
	if val == nil then
		return K.Modules[id] and K.Modules[id].default or false;
	end
	return val == true;
end

function K.SetModuleEnabled(id, enabled)
	if not K.Modules[id] then return false; end

	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.Modules then NidhausUnitFramesDB.Modules = {}; end

	NidhausUnitFramesDB.Modules[id] = enabled;

	local mod = K.Modules[id];
	if enabled and mod.onEnable then
		local ok, err = pcall(mod.onEnable);
		if not ok then print(L["MM_ERROR_ENABLING"]..id..": "..tostring(err)); end
	elseif not enabled and mod.onDisable then
		local ok, err = pcall(mod.onDisable);
		if not ok then print(L["MM_ERROR_DISABLING"]..id..": "..tostring(err)); end
	end

	-- Si el modo mover esta abierto, que el recuadro de este modulo aparezca
	-- o desaparezca en el acto. Sin esto habia que cerrar y volver a abrir el
	-- modo mover para ver el marco de lo que acababas de tildar.
	if K.RefreshGlobalUnlockOverlays then
		pcall(K.RefreshGlobalUnlockOverlays);
	end

	return true;
end

-- Modulos que arrancan APAGADOS por decision del usuario. El reseteo de
-- una sola vez (abajo) los pone en off aunque hubieran quedado prendidos,
-- para descartar que alguno estuviera causando el freeze. Se activan a mano
-- desde el panel cuando el usuario quiera.
local FORCE_OFF_ONCE = {
	"AbbreviatedStatus", "DTSU", "PaladinICD", "EnemySpellAlert",
	"PowerBar", "ShieldWatch",
	-- Agregados: antes venian prendidos de fabrica y ahora no. Cambiar el
	-- default solo no alcanza, porque la DB ya los tiene guardados en true.
	"PartyBuffs",
};

-- Lo mismo pero para opciones sueltas (no son modulos, viven en la DB
-- directamente). Misma logica: el default nuevo no pisa lo ya guardado.
local FORCE_OFF_SETTINGS_ONCE = {
	"PartyTargetsEnabled",
	"PartyShowPetFrames",
	"HealthPercentage",
};

-- Subir esta version cada vez que se agregue algo a las listas de arriba:
-- es lo que hace que el apagado corra una sola vez y no todos los logins.
local FORCE_OFF_FLAG = "_forcedOff_v39";

function K.InitializeModules()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.Modules then NidhausUnitFramesDB.Modules = {}; end

	-- Reseteo de una sola vez, controlado por FORCE_OFF_FLAG.
	if not NidhausUnitFramesDB[FORCE_OFF_FLAG] then
		NidhausUnitFramesDB[FORCE_OFF_FLAG] = true;
		for _, id in ipairs(FORCE_OFF_ONCE) do
			NidhausUnitFramesDB.Modules[id] = false;
		end
		for _, key in ipairs(FORCE_OFF_SETTINGS_ONCE) do
			NidhausUnitFramesDB[key] = false;
			if C then C[key] = false; end
		end
	end

	for _, id in ipairs(K.ModuleOrder) do
		local mod = K.Modules[id];

		if NidhausUnitFramesDB.Modules[id] == nil then
			NidhausUnitFramesDB.Modules[id] = mod.default;
		end

		local enabled = NidhausUnitFramesDB.Modules[id];

		if enabled and mod.onEnable then
			local ok, err = pcall(mod.onEnable);
			if not ok then
				print(L["MM_ERROR_INIT"]..id..": "..tostring(err));
			end
		end
	end
end

-- Orden en el que se muestran en la pestaña Modules.
-- Los que no esten en esta lista van despues, en orden de carga.
local DISPLAY_PRIORITY = {
	"LortiUI", "NiceDamage", "ClassIcons", "SpecIcons", "PartyBuffs",
};

function K.GetModuleDisplayOrder()
	local out, seen = {}, {};

	for _, id in ipairs(DISPLAY_PRIORITY) do
		if K.Modules[id] then
			table.insert(out, id);
			seen[id] = true;
		end
	end

	for _, id in ipairs(K.ModuleOrder) do
		if not seen[id] then table.insert(out, id); end
	end

	return out;
end

-- =========================================================
-- Grupos de la pestaña "Addons"
--
-- Antes era una lista plana de 12 modulos con descripcion cada uno:
-- habia que scrollear hasta el final para saber que existia. Agrupados
-- por para-que-sirve se encuentra todo de un vistazo.
--
-- Lo especifico de clase (ArrowCount, AutoShotTimer, ...) NO va aca:
-- vive en la pestaña PvP, que muestra solo lo de tu clase.
-- =========================================================
-- Dos grupos y basta. Antes eran cuatro (Interfaz / HUD / Utilidades /
-- Otros) y con 6-7 modulos en total sobraban divisiones: cada seccion
-- quedaba con uno o dos items. "Interfaz" junta lo visual, "Extras" el
-- resto.
-- Orden en que salen los modulos arriba de todo en la pestana Addons.
--
-- ANTES esto eran GRUPOS con nombre traducido: "interface" y "extras",
-- y K.GetAddonGroups los devolvia con su L["ADDONGRP_..."] puesto. Pero
-- el panel los recibia y los aplanaba en una sola lista con un doble
-- for: los nombres se calculaban y se tiraban en la misma pantalla.
--
-- Como la pestana ES una lista sola, esto pasa a ser una lista sola. Si
-- algun dia se le pone lista lateral por categoria se vuelve a partir en
-- grupos; mientras tanto no hay maquinaria manteniendose por las dudas.
local ADDON_ORDER = {
	-- FrameBorders va pegado a LortiUI a proposito: son las dos capas del
	-- mismo aspecto (Lorti tinta, este dibuja el filo) y se prueban juntas.
	"LortiUI", "FrameBorders", "NiceDamage", "ClassIcons", "SpecIcons",
	"ShieldWatch", "HideChatButton", "MinimapIconToggle",
};

-- Modulos que YA tienen su lugar en otra pestaña. No se repiten aca para
-- no terminar con la misma opcion en tres lados distintos.
local ADDON_ELSEWHERE = {
	ArrowCount            = true,  -- Interface > <clase> (cazador)
	AutoShotTimer         = true,  -- Interface > <clase> (cazador)
	ComboWatch            = true,  -- Interface > <clase> (picaro / druida)
	HunterPetBuffs        = true,  -- Interface > <clase> (cazador)
	PowerBar              = true,  -- Interface > PvP
	MeleeSwingTimer       = true,  -- Interface > PvP
	ArenaTimes            = true,  -- Arena
	ArenaToT              = true,  -- Arena
	ButtonRange           = true,  -- Interface > Action Bars
	HideActionBarTextures = true,  -- Interface > Action Bars
	PartyBuffs            = true,  -- Frames > Party
	PartyFramesImproved   = true,  -- Frames > Party (selector de estilo)
	AbbreviatedStatus     = true,  -- Interface > General (checkbox + boton Abrir)
	PaladinICD            = true,  -- Interface > General > Paladin
	EnemySpellAlert       = true,  -- Interface > PvP (Enemy awareness)
	PaladinAuras          = true,  -- Interface > PvP > Paladin (Auras)
	TurnEvil              = true,  -- Interface > PvP > Paladin (Auras)
};

-- Los modulos que van en la pestana Addons, en orden.
--
-- Dos pasadas:
--
--   1. Los de ADDON_ORDER, que van primero porque son los que mas se
--      tocan. Estos entran aunque tengan hideFromModulesTab: esa marca
--      servia para sacarlos de una lista vieja, pero aca se quieren
--      poder prender.
--
--   2. TODO lo demas que este registrado y no tenga su lugar en otra
--      pestana. Esta segunda pasada es la que importa de verdad: sin
--      ella habria que acordarse de anotar a mano cada modulo nuevo, y
--      el que se olvide no aparece en ningun lado del panel.
function K.GetAddonTabIds()
	local ids, placed = {}, {};

	for _, id in ipairs(ADDON_ORDER) do
		if K.Modules[id] then
			table.insert(ids, id);
			placed[id] = true;
		end
	end

	for _, id in ipairs(K.ModuleOrder) do
		local mod = K.Modules[id];
		if not placed[id] and not ADDON_ELSEWHERE[id]
			and mod and not mod.hideFromModulesTab then
			table.insert(ids, id);
		end
	end

	return ids;
end

function K.ListModules()
	print(L["MM_LIST_HEADER"]);
	if #K.ModuleOrder == 0 then
		print(L["MM_LIST_EMPTY"]);
		print(L["MM_LIST_HINT"]);
	else
		for _, id in ipairs(K.ModuleOrder) do
			local mod = K.Modules[id];
			local enabled = K.IsModuleEnabled(id);
			local status = enabled and "|cff00FF00ON|r" or "|cffFF0000OFF|r";
			print("  ["..status.."] |cffFFFFFF"..mod.name.."|r - "..mod.desc);
		end
	end
	print("");
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		K.InitializeModules();
	end
end);