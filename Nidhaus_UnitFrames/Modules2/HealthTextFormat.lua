-- ============================================================
-- Nidhaus_UnitFrames — Modules2/HealthTextFormat.lua
-- "Vida Completa": en vez de "33401 / 33401" (actual/maximo)
-- muestra solo el valor actual: "33401".
--
-- TextStatusBar_UpdateTextString es una funcion GLOBAL de
-- Blizzard compartida por TODAS las StatusBar con texto
-- (Player/Target/Focus/Pet/Party/ArenaEnemyFrame) — un solo
-- hook cubre todo el addon. Mismo mecanismo que usa RougeUI.
-- Portado desde ZyrokofArenaFrames (Fabian / ByZyro).
-- ============================================================

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ¿Es una barra de un miembro del grupo? Se usa para "ocultar texto del
-- party", que NO debe tocar Player / Target / Arena.
local function IsPartyBar(statusBar)
	local n = statusBar and statusBar.GetName and statusBar:GetName();
	if not n then return false; end
	return string.find(n, "^PartyMemberFrame%d") ~= nil;
end

-- ¿Es una barra de un marco de ARENA?
--
-- "Vida completa" borra el "/ maximo", y en arena ese maximo es
-- justamente el dato que se mira para saber cuanta vida le queda al
-- enemigo. Asi que el modo se aplica a todo MENOS a los marcos de arena
-- (y a sus mascotas), que siguen con el formato actual / maximo.
--
-- Los checkbox de cada unidad no se tocan: esto solo decide el formato
-- del numero, no si el texto se ve o no.
local function IsArenaBar(statusBar)
	local n = statusBar and statusBar.GetName and statusBar:GetName();
	if not n then return false; end
	return string.find(n, "^ArenaEnemyFrame") ~= nil
		or string.find(n, "^NUF_Arena") ~= nil;
end

local function OnTextStatusBarUpdateTextString(statusBar)
	local textString = statusBar and statusBar.TextString;
	if not textString then return; end

	-- Ocultar los numeros del party: con alpha, no con Hide(), para no
	-- pelear con el codigo de Blizzard que muestra/oculta ese texto.
	if IsPartyBar(statusBar) then
		textString:SetAlpha(C.PartyHideHealthManaText and 0 or 1);
	end

	if not C.ShowCurrentValueOnly then return; end
	if IsArenaBar(statusBar) then return; end

	local value = statusBar.finalValue or statusBar:GetValue();
	if statusBar.currValue and statusBar.currValue > 0 then
		textString:SetText(value);
	end
end

if TextStatusBar_UpdateTextString then
	hooksecurefunc("TextStatusBar_UpdateTextString", OnTextStatusBarUpdateTextString);
end

-- ────────────────────────────────────────────────────────────
-- Al tocar el checkbox necesitamos refrescar YA, no esperar a
-- que la vida/mana cambie de valor para que se note el cambio.
-- Llamar a la funcion nativa de Blizzard re-dispara nuestro
-- hook de arriba (si esta activado) o deja el formato default
-- de Blizzard tal cual (si esta desactivado) — sirve para
-- aplicar y para restaurar con la misma funcion.
-- ────────────────────────────────────────────────────────────
local TRACKED_BARS = {
	"PlayerFrameHealthBar", "PlayerFrameManaBar",
	"TargetFrameHealthBar", "TargetFrameManaBar",
	"FocusFrameHealthBar", "FocusFrameManaBar",
	"PetFrameHealthBar", "PetFrameManaBar",
	"PartyMemberFrame1HealthBar", "PartyMemberFrame1ManaBar",
	"PartyMemberFrame2HealthBar", "PartyMemberFrame2ManaBar",
	"PartyMemberFrame3HealthBar", "PartyMemberFrame3ManaBar",
	"PartyMemberFrame4HealthBar", "PartyMemberFrame4ManaBar",
};

local MAX_ARENA_HT = MAX_ARENA_ENEMIES or 5;

function K.ApplyHealthTextFormat()
	if not TextStatusBar_UpdateTextString then return; end

	for i = 1, #TRACKED_BARS do
		local bar = _G[TRACKED_BARS[i]];
		if bar then
			pcall(TextStatusBar_UpdateTextString, bar);
		end
	end

	for i = 1, MAX_ARENA_HT do
		local hb = _G["ArenaEnemyFrame"..i.."HealthBar"];
		local mb = _G["ArenaEnemyFrame"..i.."ManaBar"];
		if hb then pcall(TextStatusBar_UpdateTextString, hb); end
		if mb then pcall(TextStatusBar_UpdateTextString, mb); end
	end
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD");
	K.ApplyHealthTextFormat();
end);
