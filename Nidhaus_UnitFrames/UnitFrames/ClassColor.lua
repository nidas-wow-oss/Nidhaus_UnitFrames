local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooksecurefunc, unpack = hooksecurefunc, unpack;
local UnitIsPlayer, UnitClass, UnitIsConnected, UnitExists, UnitReaction = UnitIsPlayer, UnitClass, UnitIsConnected, UnitExists, UnitReaction;
local UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList = UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList;
local UnitPlayerControlled = UnitPlayerControlled;
local CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS, FACTION_BAR_COLORS = CUSTOM_CLASS_COLORS, RAID_CLASS_COLORS, FACTION_BAR_COLORS;

local isInitialized = false;

-- FIX: local para evitar colisiones con otros addons
local function unitClassColors(healthbar, unit)
	if not healthbar or not unit then return; end
	if not UnitIsPlayer(unit) or unit ~= healthbar.unit then return; end
	if not UnitClass(unit) then return; end
	
	-- QUIEN DECIDE EL COLOR DE ESTA BARRA.
	--
	-- Los marcos de arena no tienen coloreo propio en ningun otro lado:
	-- dependen de este mismo hook, asi que la regla entera vive aca.
	--
	--   Arena, estilo retocado -> SIEMPRE por clase. Ahi el color no es
	--     decoracion: es como identificas de un vistazo a quien le estas
	--     pegando, y apagarlo deja los tres marcos iguales.
	--
	--   Arena, estilo Blizzard -> manda su casilla, y manda SOLA. Los
	--     marcos son los de fabrica y hay quien los quiere tal cual,
	--     verdes, aunque tenga el color de clase prendido para el resto de
	--     la interfaz. Por eso no se mira C.classColor aca: si se mirara,
	--     con la opcion general puesta la casilla no podria apagar nada.
	--
	--   Cualquier otro marco -> la opcion general de siempre.
	local isArena = unit and string.find(unit, "^arena%d") ~= nil;
	local useClass;

	if isArena then
		if (C.ArenaFrameStyle or "Custom") == "Blizzard" then
			useClass = (C.ArenaBlizzardClassColor == true);
		else
			useClass = true;
		end
	else
		useClass = C.classColor and true or false;
	end

	if useClass then
		if not UnitIsConnected(unit) then
			healthbar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5);
			return;
		end
		
		local _, class = UnitClass(unit);
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class];
		if color then
			healthbar:SetStatusBarColor(color.r, color.g, color.b);
		end
	else
		if not UnitIsConnected(unit) then
			healthbar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5);
		else
			healthbar:SetStatusBarColor(0, 1.0, 0);
		end
	end
end

local function npcReactionColors(healthbar, unit)
	if not healthbar or not unit then return; end
	if not UnitExists(unit) or UnitIsPlayer(unit) or unit ~= healthbar.unit then return; end

	-- DOS CASOS EN LOS QUE ESTA BARRA NO VA POR REACCION.
	--
	-- 1) LAS MASCOTAS. UnitReaction sobre la mascota de un enemigo devuelve
	--    3, y el color de esa reaccion es naranja: por eso el cangrejo del
	--    cazador salia naranja en vez de verde. Blizzard NUNCA pinta por
	--    reaccion lo que controla un jugador -- mascotas, vehiculos,
	--    totems: van del mismo verde que su dueno.
	--
	-- 2) SIN CUSTOM SKIN. Apagar la piel es pedir la interfaz de fabrica, y
	--    de fabrica todas las barras de vida son verdes. Pintar por
	--    reaccion ahi era el addon metiendose donde dijiste que no.
	--
	-- Se escribe el verde A MANO en vez de salir sin tocar nada: la barra
	-- conserva el color anterior, asi que viniendo de un bicho rojo se
	-- quedaba con el rojo pegado.
	if UnitPlayerControlled(unit) or (not C.UnitFrameCustomTexture) then
		if UnitIsConnected(unit) == false then
			healthbar:SetStatusBarColor(0.6, 0.6, 0.6, 0.5);
		else
			healthbar:SetStatusBarColor(0, 1.0, 0);
		end
		return;
	end

	if not UnitPlayerControlled(unit) and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit) then
		healthbar:SetStatusBarColor(0.5, 0.5, 0.5);
	else
		local reaction = UnitReaction(unit, "player");
		if reaction and FACTION_BAR_COLORS[reaction] then
			local color = FACTION_BAR_COLORS[reaction];
			healthbar:SetStatusBarColor(color.r, color.g, color.b);
		else
			healthbar:SetStatusBarColor(0, 0.6, 0.1);
		end
	end
end

local function ForceUpdateAllFrames()
	if PlayerFrame and PlayerFrame.healthbar then
		UnitFrameHealthBar_Update(PlayerFrame.healthbar, "player");
	end
	
	if TargetFrame and TargetFrame.healthbar then
		UnitFrameHealthBar_Update(TargetFrame.healthbar, "target");
	end
	
	if FocusFrame and FocusFrame.healthbar then
		UnitFrameHealthBar_Update(FocusFrame.healthbar, "focus");
	end
	
	for i = 1, (MAX_PARTY_MEMBERS or 4) do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame and partyFrame.healthbar then
			UnitFrameHealthBar_Update(partyFrame.healthbar, "party"..i);
		end
	end
	
	for i = 1, (MAX_ARENA_ENEMIES or 0) do
		local arenaFrame = _G["ArenaEnemyFrame"..i];
		if arenaFrame and arenaFrame.healthbar then
			UnitFrameHealthBar_Update(arenaFrame.healthbar, "arena"..i);
		end
	end
	
	for i = 1, (MAX_BOSS_FRAMES or 0) do
		local bossFrame = _G["Boss"..i.."TargetFrame"];
		if bossFrame and bossFrame.healthbar then
			UnitFrameHealthBar_Update(bossFrame.healthbar, "boss"..i);
		end
	end
end

local function InitializeClassColors()
	if isInitialized then return; end
	
	-- Un solo hook para UnitFrameHealthBar_Update (class colors + NPC reaction)
	hooksecurefunc("UnitFrameHealthBar_Update", function(healthbar, unit)
		unitClassColors(healthbar, unit);
		npcReactionColors(healthbar, unit);
	end);
	
	-- Un solo hook para HealthBar_OnValueChanged
	hooksecurefunc("HealthBar_OnValueChanged", function(self)
		unitClassColors(self, self.unit);
		npcReactionColors(self, self.unit);
	end);
	
	ForceUpdateAllFrames();
	isInitialized = true;
end

function K.ToggleClassColors(enabled)
	if not isInitialized then return; end
	ForceUpdateAllFrames();
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	InitializeClassColors();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized then
		ForceUpdateAllFrames();
	end
end);