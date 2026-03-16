local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- PartyMode3v3

local _G = _G;

local PARTY_3V3_CONFIG = {
	[1] = { scale = 1.5, point = "TOPLEFT", x = 40,  y = -140 },
	[2] = { scale = 1.5, point = "TOPLEFT", x = 40,  y = -260 },
	[3] = { scale = 1.3, point = "TOPLEFT", x = 10,  y = -390 },
	[4] = { scale = 1.3, point = "TOPLEFT", x = 10,  y = -460 },
};

-- Apply3v3PartyMode
function K.Apply3v3PartyMode()
	if not C.SetPositions then return; end;
	if not C.PartyMode3v3 then return; end;

	for i = 1, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		local cfg = PARTY_3V3_CONFIG[i];
		if partyFrame and cfg then
			-- FIX: If PartyIndividualMove is active, check for saved positions first.
			if C.PartyIndividualMove and K.GetSavedPosition then
				local saved = K.GetSavedPosition("PartyMemberFrame"..i);
				if saved then
					partyFrame:SetScale(cfg.scale);
					partyFrame:ClearAllPoints();
					partyFrame:SetParent(UIParent);
					local relFrame = _G[saved.relativeTo] or UIParent;
					partyFrame:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				else
					partyFrame:SetScale(cfg.scale);
					partyFrame:ClearAllPoints();
					partyFrame:SetParent(UIParent);
					partyFrame:SetPoint(cfg.point, cfg.x, cfg.y);
				end
			else
				partyFrame:SetScale(cfg.scale);
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
	if not C.SetPositions then return; end;
	if not K.NidhausPartyFrame then return; end;

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
	if C.SetPositions and C.PartyMode3v3 then
		-- Apply3v3PartyMode ya incluye la llamada a PartyBuffs_OnFramesMoved
		K.Apply3v3PartyMode();
	end
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if C.SetPositions and C.PartyMode3v3 then
		if C.PartyIndividualMove then
			-- No re-posicionar si el usuario está arrastrando frames individualmente
			return;
		end
		K.Apply3v3PartyMode();
	end
end);