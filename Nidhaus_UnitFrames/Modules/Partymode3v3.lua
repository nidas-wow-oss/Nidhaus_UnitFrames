local AddOnName, ns = ...;
local K, C, L = unpack(ns);



local _G = _G;

local PARTY_3V3_CONFIG = {
	[1] = { defScale = 1.5, point = "TOPLEFT", x = 40,  y = -140 },
	[2] = { defScale = 1.5, point = "TOPLEFT", x = 40,  y = -260 },
	[3] = { defScale = 1.3, point = "TOPLEFT", x = 10,  y = -390 },
	[4] = { defScale = 1.3, point = "TOPLEFT", x = 10,  y = -460 },
};




















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































function K.Is3v3Active()
	return C.PartyMode3v3 == true;
end


local function Get3v3Scale(i)
	local cfg = PARTY_3V3_CONFIG[i];
	if not cfg then return 1.0; end
	local v = C["Party3v3Scale"..i];
	if type(v) == "number" and v > 0 then return v; end
	return cfg.defScale;
end
K.Get3v3Scale = Get3v3Scale;


function K.Apply3v3MemberScale(i)
	if not C.PartyMode3v3 then return; end

	if InCombatLockdown() then pendingApply = true; return; end
	local pf = _G["PartyMemberFrame"..i];
	if pf then pf:SetScale(Get3v3Scale(i)); end
	if K.PartyBuffs_OnFramesMoved then K.PartyBuffs_OnFramesMoved(); end
end


function K.Apply3v3PartyMode()

	if not C.PartyMode3v3 then return; end;
	if InCombatLockdown() then pendingApply = true; return; end

	for i = 1, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		local cfg = PARTY_3V3_CONFIG[i];
		if partyFrame and cfg then







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






	if K.PartyBuffs_OnFramesMoved then
		K.PartyBuffs_OnFramesMoved();
	end
end;


function K.Disable3v3PartyMode()
	if InCombatLockdown() then pendingDisable = true; return; end








	local base = C.PartyFrameScale;
	if type(base) ~= "number" or base <= 0 or base > 3 then base = 1.0; end
	for i = 1, MAX_PARTY_MEMBERS do
		local pf = _G["PartyMemberFrame"..i];
		if pf then pf:SetScale(base); end
	end

	if not K.NidhausPartyFrame then


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


	if K.ApplyPartyFrameSpacing then
		K.ApplyPartyFrameSpacing();
	end


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

			return;
		end
		K.Apply3v3PartyMode();
	end
end);