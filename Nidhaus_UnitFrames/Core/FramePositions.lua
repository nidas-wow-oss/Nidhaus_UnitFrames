local AddOnName, ns = ...;
local K, C, L = unpack(ns);

function K.ApplyFramePositions()
	local unpack = unpack;

	-- Player Frame
	if NidhausPlayerFrame then
		NidhausPlayerFrame:ClearAllPoints();
		if (not C.SetPositions) and C.PlayerFrame_BlizzardDefault then
			local pos = C.PlayerFrame_BlizzardDefault;
			local relFrame = _G[pos.relativeTo] or UIParent;
			NidhausPlayerFrame:SetPoint(pos.point, relFrame, pos.relativePoint, pos.x, pos.y);
		elseif C.SetPositions then
			-- FIX: Prioridad a posiciones guardadas por drag
			local saved = K.GetSavedPosition and K.GetSavedPosition("PlayerFrame");
			if saved then
				local relFrame = _G[saved.relativeTo] or UIParent;
				NidhausPlayerFrame:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				-- Actualizar C[] para consistencia
				C.PlayerFramePoint = {saved.point, relFrame, saved.relativePoint, saved.x, saved.y};
			elseif C.PlayerFramePoint then
				NidhausPlayerFrame:SetPoint(unpack(C.PlayerFramePoint));
			end
		elseif C.PlayerFramePoint then
			NidhausPlayerFrame:SetPoint(unpack(C.PlayerFramePoint));
		end
	end

	-- Target Frame
	if TargetFrame then
		TargetFrame:ClearAllPoints();
		if (not C.SetPositions) and C.TargetFrame_BlizzardDefault then
			local pos = C.TargetFrame_BlizzardDefault;
			local relFrame = _G[pos.relativeTo] or UIParent;
			TargetFrame:SetPoint(pos.point, relFrame, pos.relativePoint, pos.x, pos.y);
		elseif C.SetPositions then
			-- FIX: Prioridad a posiciones guardadas por drag
			local saved = K.GetSavedPosition and K.GetSavedPosition("TargetFrame");
			if saved then
				local relFrame = _G[saved.relativeTo] or UIParent;
				TargetFrame:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				C.TargetFramePoint = {saved.point, relFrame, saved.relativePoint, saved.x, saved.y};
			elseif C.TargetFramePoint then
				TargetFrame:SetPoint(unpack(C.TargetFramePoint));
			end
		elseif C.TargetFramePoint then
			TargetFrame:SetPoint(unpack(C.TargetFramePoint));
		end
	end

	-- Boss / Party containers
	if C.SetPositions then
		-- FIX: Boss ahora usa K.GetSavedPosition (igual que Player, Target, Party)
		if K.NidhausBossFrame then
			K.NidhausBossFrame:ClearAllPoints();
			local saved = K.GetSavedPosition and K.GetSavedPosition("BossMover");
			if saved then
				local relFrame = _G[saved.relativeTo] or UIParent;
				K.NidhausBossFrame:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				C.BossTargetFramePoint = {saved.point, relFrame, saved.relativePoint, saved.x, saved.y};
			elseif C.BossTargetFramePoint then
				K.NidhausBossFrame:SetPoint(unpack(C.BossTargetFramePoint));
			end
		end
		if K.NidhausPartyFrame then
			K.NidhausPartyFrame:ClearAllPoints();
			-- FIX: Prioridad a posiciones guardadas por drag
			local saved = K.GetSavedPosition and K.GetSavedPosition("PartyMemberFrame");
			if saved then
				local relFrame = _G[saved.relativeTo] or UIParent;
				K.NidhausPartyFrame:SetPoint(saved.point, relFrame, saved.relativePoint, saved.x, saved.y);
				C.PartyMemberFramePoint = {saved.point, relFrame, saved.relativePoint, saved.x, saved.y};
			elseif C.PartyMemberFramePoint then
				K.NidhausPartyFrame:SetPoint(unpack(C.PartyMemberFramePoint));
			end
		end
	end
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		K.ApplyFramePositions();
	end
end);