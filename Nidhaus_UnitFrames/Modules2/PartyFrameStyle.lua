local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PartyFrameStyle.lua
-- Coordinador del ASPECTO de los marcos de party.
--
-- Hay tres estilos y son EXCLUYENTES: los tres retexturizan los
-- mismos marcos, asi que dos prendidos a la vez se pisan y queda
-- cualquier cosa.
--
--   "Default"  -> el de Blizzard, sin tocar nada
--   "New"      -> NewPartyFrame  (setting C.NewPartyFrame)
--   "Improved" -> PartyFramesImproved (modulo)
--
-- POR QUE UN COORDINADOR Y NO DOS CHECKBOX SUELTOS: uno se puede
-- prender desde Frames > Party y el otro desde Addons > Interfaz.
-- Sin un lugar unico que decida, era cuestion de tiempo terminar con
-- los dos activos. Todo pasa por K.SetPartyFrameStyle, venga de donde
-- venga, y el guard de re-entrada evita el ida y vuelta infinito
-- entre el coordinador y el onEnable del modulo.
-- =========================================================

local STYLE_DEFAULT  = "Default";
local STYLE_NEW      = "New";
local STYLE_IMPROVED = "Improved";
local STYLE_PW       = "PW";        -- aspecto de pw_unitframes
-- Misma maquinaria que PW, otra textura de marco (UI-PartyFrame2), que es
-- la que usa el tema Compact del PlayerFrame. La elige PartyFramePW.lua
-- leyendo el estilo activo.
local STYLE_PW2      = "PW2";

K.PARTY_STYLES = { STYLE_DEFAULT, STYLE_NEW, STYLE_IMPROVED, STYLE_PW, STYLE_PW2 };

local applying = false;   -- guard de re-entrada

function K.GetPartyFrameStyle()
	return C.PartyFrameStyle or STYLE_DEFAULT;
end

-- ---------------------------------------------------------
-- Aplicar
-- ---------------------------------------------------------
function K.SetPartyFrameStyle(style, skipSave)
	if applying then return; end
	if style ~= STYLE_NEW and style ~= STYLE_IMPROVED and style ~= STYLE_PW
		and style ~= STYLE_PW2 then
		style = STYLE_DEFAULT;
	end

	applying = true;

	-- EL ESTILO SE GUARDA ANTES DE APLICAR NADA.
	--
	-- Estaba al final, y eso rompia a cualquier modulo que durante el
	-- aplicado preguntara "que estilo esta puesto". El caso concreto:
	-- PartyFramePW elige entre la textura de Compact y la de Compact 2
	-- leyendo K.GetPartyFrameStyle(); como todavia no se habia escrito,
	-- leia el estilo VIEJO y pintaba la textura equivocada.
	--
	-- Escribirlo primero es ademas lo natural: de aca para abajo todo el
	-- mundo ve el estilo que se esta aplicando, no el que habia.
	if not skipSave then
		if K.SaveConfig then K.SaveConfig("PartyFrameStyle", style); end
	end
	C.PartyFrameStyle = style;

	-- ── NewPartyFrame ──
	local wantNew = (style == STYLE_NEW);
	if C.NewPartyFrame ~= wantNew then
		C.NewPartyFrame = wantNew;
		if K.SaveConfig then K.SaveConfig("NewPartyFrame", wantNew); end
	end
	if wantNew then
		if K.EnableNewPartyFrame then pcall(K.EnableNewPartyFrame); end
	else
		if K.DisableNewPartyFrame then pcall(K.DisableNewPartyFrame); end
	end

	-- ── PartyFramesImproved ──
	local wantImproved = (style == STYLE_IMPROVED);
	if K.Modules and K.Modules["PartyFramesImproved"] then
		if K.IsModuleEnabled("PartyFramesImproved") ~= wantImproved then
			K.SetModuleEnabled("PartyFramesImproved", wantImproved);
		end
		if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("PartyFramesImproved"); end
	end

	-- ── PW ──
	-- Va DESPUES de los otros dos: si se apagan despues de aplicarlo,
	-- su restauracion le pisa la textura.
	local wantPW = (style == STYLE_PW) or (style == STYLE_PW2);
	if wantPW then
		if K.EnablePartyFramePW then pcall(K.EnablePartyFramePW); end
	else
		if K.DisablePartyFramePW then pcall(K.DisablePartyFramePW); end
	end

	-- (el estilo ya quedo guardado al principio de la funcion)

	applying = false;

	-- Los marcos cambiaron de tamaño: reacomodar lo que cuelga de ellos
	if K.ApplyPartyFrameSpacing then pcall(K.ApplyPartyFrameSpacing); end
	if K.RestylePartyFrames then pcall(K.RestylePartyFrames); end
	-- Despues del restyle, el modulo de estilo vuelve a pintar SU textura
	-- (el orden importa: si no, queda la de NUF encima).
	if wantImproved and K.PFI_Restyle then pcall(K.PFI_Restyle); end
	-- Idem para PW: RestylePartyFrames repone la textura de NUF, asi que
	-- la de pw hay que volver a pintarla despues.
	if wantPW and K.EnablePartyFramePW then pcall(K.EnablePartyFramePW); end
	if K.PartyBuffs_OnFramesMoved then pcall(K.PartyBuffs_OnFramesMoved); end
	if C.PartyMode3v3 and K.Apply3v3PartyMode then pcall(K.Apply3v3PartyMode); end

	if K.RefreshPartyStyleSelector then K.RefreshPartyStyleSelector(); end
end

-- Lo llaman los modulos cuando se los prende desde otro lado (por
-- ejemplo el checkbox de PartyFramesImproved en Addons > Interfaz).
function K.NotifyPartyStyleFromModule(style)
	if applying then return; end
	K.SetPartyFrameStyle(style);
end

-- ---------------------------------------------------------
-- Aplicar el estilo guardado al entrar
-- ---------------------------------------------------------
local init = CreateFrame("Frame");
init:RegisterEvent("PLAYER_LOGIN");
init:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");

	-- Migracion: quien ya tenia NewPartyFrame prendido de antes no tiene
	-- PartyFrameStyle guardado. Se deduce del estado actual una sola vez.
	if not C.PartyFrameStyle or C.PartyFrameStyle == "" then
		local style = STYLE_DEFAULT;
		if C.NewPartyFrame then
			style = STYLE_NEW;
		elseif K.IsModuleEnabled and K.IsModuleEnabled("PartyFramesImproved") then
			style = STYLE_IMPROVED;
		end
		if K.SaveConfig then K.SaveConfig("PartyFrameStyle", style); end
		C.PartyFrameStyle = style;
	end

	-- Un frame de retraso: los modulos se inicializan en este mismo evento
	self:SetScript("OnUpdate", function(s)
		s:SetScript("OnUpdate", nil);
		K.SetPartyFrameStyle(C.PartyFrameStyle, true);
	end);
end);

SLASH_NUFPARTYSTYLE1 = "/nufpartystyle";
SlashCmdList["NUFPARTYSTYLE"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "default" then
		K.SetPartyFrameStyle(STYLE_DEFAULT);
	elseif msg == "new" then
		K.SetPartyFrameStyle(STYLE_NEW);
	elseif msg == "improved" then
		K.SetPartyFrameStyle(STYLE_IMPROVED);
	else
		print("|cff4FC3F7NUF:|r /nufpartystyle default | new | improved  ("
			.. (L["PARTY_STYLE_CURRENT"] or "current") .. ": " .. K.GetPartyFrameStyle() .. ")");
	end
end
