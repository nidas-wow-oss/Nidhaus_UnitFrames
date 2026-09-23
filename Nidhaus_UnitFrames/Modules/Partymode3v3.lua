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
			-- FIX: If PartyIndividualMove is active, check for saved positions first.
			if C.PartyIndividualMove and K.GetSavedPosition then
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
	if not K.NidhausPartyFrame then return; end;
	if InCombatLockdown() then pendingDisable = true; return; end

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