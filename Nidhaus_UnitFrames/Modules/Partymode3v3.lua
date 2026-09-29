local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- PartyMode3v3

local _G = _G;

local PARTY_3V3_CONFIG = {
	[1] = { defScale = 1.5, point = "TOPLEFT", x = 40,  y = -140 },
	[2] = { defScale = 1.5, point = "TOPLEFT", x = 40,  y = -260 },
	[3] = { defScale = 1.3, point = "TOPLEFT", x = 10,  y = -390 },
	[4] = { defScale = 1.3, point = "TOPLEFT", x = 10,  y = -460 },
};

-- ============================================================
-- LOS MARCOS DE PARTY SON PROTEGIDOS: NADA DE TOCARLOS EN COMBATE.
--
-- TaintFixer lo cazo con el nombre y todo: peleando contra un muneco,
-- PartyMemberFrame3 y 4 tiraban ADDON_ACTION_BLOCKED en SetScale,
-- ClearAllPoints, SetParent y SetPoint -- los cuatro que hace este archivo,
-- en ese mismo orden. No era ruido: el cliente estaba RECHAZANDO cada
-- llamada, y de ahi el cartel "Interface action failed because of an AddOn".
--
-- Blizzard bloquea mover, reparentar o escalar estos marcos mientras estas
-- en combate. Este archivo no tenia ni una sola guarda, asi que cualquier
-- cosa que dispare CONFIG_CHANGED peleando -- mover un slider, entrar a
-- arena, un cambio de grupo -- caia justo ahi.
--
-- No alcanza con salir temprano y listo: si te vas sin aplicar, los marcos
-- se quedan mal hasta que algo mas los vuelva a tocar. Se anota el pedido
-- y se repite apenas termina el combate, que es la misma receta que ya usa
-- PartyFramePW para el vehiculo.
-- ============================================================
local pendingApply, pendingDisable = false, false;

local combatWatch = CreateFrame("Frame");
combatWatch:RegisterEvent("PLAYER_REGEN_ENABLED");
combatWatch:SetScript("OnEvent", function()
	if pendingApply then
		pendingApply = false;
		if K.Apply3v3PartyMode then K.Apply3v3PartyMode(); end
	end
	if pendingDisable then
		pendingDisable = false;
		if K.Disable3v3PartyMode then K.Disable3v3PartyMode(); end
	end
end);

-- =========================================================
-- UNA SOLA FORMA DE PREGUNTAR "ESTA PUESTO EL 3v3"
--
-- ESTE ERA EL BUG DE LA ESCALA.
--
-- Apply3v3PartyMode se arreglo en su momento para NO exigir mas
-- C.SetPositions ("antes exigia C.SetPositions y sin eso el checkbox no
-- hacia NADA", dice el comentario de abajo). Pero los otros seis lugares
-- del addon que preguntan si el 3v3 esta puesto se quedaron con la
-- condicion vieja:
--
--     if C.SetPositions and C.PartyMode3v3 then ...
--
-- Con las posiciones custom APAGADAS y el 3v3 PRENDIDO, las dos mitades
-- dejan de coincidir:
--
--   * Apply3v3PartyMode corre y pone 1.5 / 1.5 / 1.3 / 1.3 y las
--     posiciones del modo;
--   * y el CONFIG_CHANGED de PartyFrame.lua evalua
--     "not (SetPositions and PartyMode3v3)" = not(false and true) = TRUE,
--     asi que aplica C.PartyFrameScale -- tu 1.5 -- A LAS CUATRO.
--
-- Resultado: toma la POSICION del 3v3 pero no la ESCALA, que es
-- exactamente el sintoma. Y no salta al tildarlo (el panel llama a
-- Apply3v3PartyMode despues de guardar), sino en el siguiente cambio de
-- cualquier opcion, que es por lo que "se bugea" un rato despues.
--
-- La respuesta no es agregar un reset mas: es que TODOS pregunten lo
-- mismo. Esta funcion es esa pregunta, y los seis lugares la usan.
-- =========================================================
function K.Is3v3Active()
	return C.PartyMode3v3 == true;
end

-- La escala de cada miembro ahora es configurable desde el panel
local function Get3v3Scale(i)
	local cfg = PARTY_3V3_CONFIG[i];
	if not cfg then return 1.0; end
	local v = C["Party3v3Scale"..i];
	if type(v) == "number" and v > 0 then return v; end
	return cfg.defScale;
end
K.Get3v3Scale = Get3v3Scale;

-- Aplicar la escala de un solo miembro (para los sliders en vivo)
function K.Apply3v3MemberScale(i)
	if not C.PartyMode3v3 then return; end
	-- Mover el slider en combate: se anota y se aplica al salir.
	if InCombatLockdown() then pendingApply = true; return; end
	local pf = _G["PartyMemberFrame"..i];
	if pf then pf:SetScale(Get3v3Scale(i)); end
	if K.PartyBuffs_OnFramesMoved then K.PartyBuffs_OnFramesMoved(); end
end

-- Apply3v3PartyMode
function K.Apply3v3PartyMode()
	-- FIX: antes exigia C.SetPositions y sin eso el checkbox no hacia NADA
	if not C.PartyMode3v3 then return; end;
	if InCombatLockdown() then pendingApply = true; return; end

	for i = 1, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		local cfg = PARTY_3V3_CONFIG[i];
		if partyFrame and cfg then
			-- SI HAY POSICION GUARDADA, MANDA ELLA. SIEMPRE.
			--
			-- Antes esto pedia ademas C.PartyIndividualMove, y hay mas de
			-- un camino que apaga ese flag. Cuando pasaba, el modo pisaba
			-- una posicion que vos habias elegido a mano. El flag ahora
			-- solo decide como se acomodan los marcos que NO tienen
			-- posicion propia.
			if K.GetSavedPosition then
				local saved = K.GetSavedPosition("PartyMemberFrame"..i);
				if saved then
					partyFrame:SetScale(Get3v3Scale(i));
					partyFrame:ClearAllPoints();
					partyFrame:SetParent(UIParent);
					local relFrame = _G[saved.relativeTo] or UIParent;
					partyFrame:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				else
					partyFrame:SetScale(Get3v3Scale(i));
					partyFrame:ClearAllPoints();
					partyFrame:SetParent(UIParent);
					partyFrame:SetPoint(cfg.point, cfg.x, cfg.y);
				end
			else
				partyFrame:SetScale(Get3v3Scale(i));
				partyFrame:ClearAllPoints();
				partyFrame:SetParent(UIParent);
				partyFrame:SetPoint(cfg.point, cfg.x, cfg.y);
			end
		end;
	end;

	-- FIX PARTYBUFFS + 3v3: después de reposicionar los frames con nuevas escalas
	-- (1.5x para frame 1-2, 1.3x para frame 3-4), notificar a PartyBuffs para que
	-- re-ancle los iconos y actualice los movers a la escala correcta.
	-- Sin esta llamada los buffs "se anclan arriba" porque los offsets quedan
	-- referenciados a la posición/escala previa del frame.
	if K.PartyBuffs_OnFramesMoved then
		K.PartyBuffs_OnFramesMoved();
	end
end;

-- Disable3v3PartyMode
function K.Disable3v3PartyMode()
	if InCombatLockdown() then pendingDisable = true; return; end

	-- LA ESCALA SE REPONE SIEMPRE, HAYA CONTENEDOR O NO.
	--
	-- Antes esta funcion arrancaba con "if not K.NidhausPartyFrame then
	-- return end". El contenedor solo existe con las posiciones custom
	-- puestas, asi que sin ellas destildar el 3v3 no hacia NADA: los marcos
	-- se quedaban en 1.5 / 1.5 / 1.3 / 1.3 para siempre. Este es el "reset
	-- de escala" que faltaba al cambiar de modo.
	local base = C.PartyFrameScale;
	if type(base) ~= "number" or base <= 0 or base > 3 then base = 1.0; end
	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then pf:SetScale(base); end
	end

	if not K.NidhausPartyFrame then
		-- Sin contenedor no hay a donde reanclarlos. La escala ya volvio a la
		-- tuya; de la posicion se encarga quien corresponda.
		if K.PartyBuffs_OnFramesMoved then K.PartyBuffs_OnFramesMoved(); end
		return;
	end

	for i = 1, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame then
			partyFrame:SetScale(C.PartyFrameScale);
			partyFrame:ClearAllPoints();
			partyFrame:SetParent(K.NidhausPartyFrame);
			if i == 1 then
				partyFrame:SetPoint("TOPLEFT", K.NidhausPartyFrame, "TOPLEFT");
			end
		end;
	end;

	-- Delegar posicionamiento de frames 2-4 a la función centralizada
	if K.ApplyPartyFrameSpacing then
		K.ApplyPartyFrameSpacing();
	end

	-- FIX PARTYBUFFS: re-anclar también al desactivar 3v3 (frames vuelven a escala C.PartyFrameScale)
	if K.PartyBuffs_OnFramesMoved then
		K.PartyBuffs_OnFramesMoved();
	end
end;

K.RegisterConfigEvent("CONFIG_LOADED", function()
	if C.PartyMode3v3 then
		K.Apply3v3PartyMode();
	end
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if C.PartyMode3v3 then
		if C.PartyIndividualMove then
			-- No re-posicionar si el usuario está arrastrando frames individualmente
			return;
		end
		K.Apply3v3PartyMode();
	end
end);