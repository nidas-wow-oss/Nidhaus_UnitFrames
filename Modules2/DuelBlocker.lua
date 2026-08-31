local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- DuelBlocker.lua
-- Rechaza los duelos automaticamente.
--
-- COMO FUNCIONA: cuando alguien te desafia, el cliente dispara
-- DUEL_REQUESTED y muestra el popup. CancelDuel() lo rechaza, y
-- despues hay que cerrar el StaticPopup a mano: rechazar el duelo
-- no lo esconde solo, quedaba el cartel colgado en pantalla.
--
-- Se avisa por chat quien te desafio, si no uno nunca se entera.
-- =========================================================

local lastChallenger, lastTime = nil, 0;

local events = CreateFrame("Frame");
events:RegisterEvent("DUEL_REQUESTED");
events:SetScript("OnEvent", function(self, event, challenger)
	if not C.BlockDuels then return; end

	CancelDuel();

	-- Cerrar el popup que ya se abrio
	if StaticPopup_Hide then
		StaticPopup_Hide("DUEL_REQUESTED");
	end

	-- Anti-spam: si el mismo tipo insiste, no llenamos el chat
	local now = GetTime();
	if challenger and (challenger ~= lastChallenger or (now - lastTime) > 30) then
		lastChallenger, lastTime = challenger, now;
		print("|cff4FC3F7NUF:|r " .. string.format(
			L["DUEL_BLOCKED"] or "Duel from %s declined.", challenger));
	end
end);

SLASH_NUFDUEL1 = "/nufduel";
SlashCmdList["NUFDUEL"] = function()
	local v = not C.BlockDuels;
	K.SaveConfig("BlockDuels", v);
	if v then
		print("|cff4FC3F7NUF:|r " .. (L["DUEL_BLOCK_ON"] or "Duels are now declined automatically."));
	else
		print("|cff4FC3F7NUF:|r " .. (L["DUEL_BLOCK_OFF"] or "Duels are allowed again."));
	end
end
