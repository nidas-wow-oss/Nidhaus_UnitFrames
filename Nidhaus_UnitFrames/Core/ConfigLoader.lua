local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ConfigLoader.lua
--
-- EL PANEL DE OPCIONES YA NO SE CARGA AL ENTRAR AL JUEGO.
--
-- Los archivos del panel eran ~300 KB de los ~1.8 MB de Lua que el cliente
-- tenia que leer en CADA login. Es una ventana que abris de vez en cuando,
-- asi que ahora vive en un addon aparte, Nidhaus_UnitFrames_Config, marcado
-- como LoadOnDemand: existe en la lista pero WoW no lo lee hasta que alguien
-- lo pide.
--
-- Este archivo es ese pedido. Es lo unico del panel que queda en el addon
-- principal: unas pocas lineas que cargan el resto la primera vez que abris
-- las opciones.
--
-- Una vez cargado, el propio panel PISA estas funciones con las de verdad
-- (K.ToggleOptionsPanel, el /nufconfig, etc.), asi que a partir de ahi todo
-- funciona exactamente como antes.
-- =========================================================

local LOD = "Nidhaus_UnitFrames_Config";

local function LoadPanel()
	if IsAddOnLoaded and IsAddOnLoaded(LOD) then return true; end
	if not LoadAddOn then return false; end

	local loaded, reason = LoadAddOn(LOD);
	if loaded then return true; end

	-- Los motivos que devuelve WoW son claves ("DISABLED", "MISSING"...).
	-- Se traducen con las globales del juego si existen, para que el mensaje
	-- se lea en el idioma del cliente.
	local why = reason and (_G["ADDON_" .. reason] or reason) or "?";
	print("|cffFF5555NUF:|r " .. (L["PANEL_LOAD_FAIL"]
		or "No se pudo cargar el panel de opciones") .. " (" .. tostring(why) .. ").");
	print("|cffFF5555NUF:|r " .. (L["PANEL_LOAD_HINT"]
		or "Revisa que la carpeta Nidhaus_UnitFrames_Config este junto a la del addon y activada en la lista."));
	return false;
end

K.LoadConfigPanel = LoadPanel;

-- SUPLENTE DE K.ToggleOptionsPanel.
--
-- El boton del minimapa y el /nuf llaman a esta funcion. Mientras el panel
-- no este cargado, la que atiende es esta: carga el addon y le pasa la
-- pelota a la de verdad, que para entonces ya reemplazo a esta misma.
--
-- La comparacion con 'shim' es la que corta la recursion: si despues de
-- cargar la funcion sigue siendo esta, algo fallo y no se vuelve a llamar.
local shim;
shim = function()
	if not LoadPanel() then return; end
	if K.ToggleOptionsPanel and K.ToggleOptionsPanel ~= shim then
		K.ToggleOptionsPanel();
	end
end
K.ToggleOptionsPanel = shim;

-- Los mismos comandos que define el panel. Al cargarse, los sobreescribe
-- y este suplente deja de existir para el juego.
local slashShim;
slashShim = function(msg)
	if not LoadPanel() then return; end
	local real = SlashCmdList["NUFCONFIG"];
	if real and real ~= slashShim then real(msg); end
end

SLASH_NUFCONFIG1 = "/nufconfig";
SLASH_NUFCONFIG2 = "/nufoptions";
SlashCmdList["NUFCONFIG"] = slashShim;
