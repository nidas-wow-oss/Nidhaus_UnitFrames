local AddOnName, ns = ...;
ns[1] = {};	-- K, Functions;
ns[2] = {};	-- C, Config;
ns[3] = {};	-- L, Localization;

local function SaveBlizzardDefaults()
	local C = ns[2];
	
	if PlayerFrame and not C.PlayerFrame_BlizzardDefault then
		local point, relativeTo, relativePoint, x, y = PlayerFrame:GetPoint(1);
		-- FIX: Solo guardar si GetPoint devolvió datos válidos
		if point then
			C.PlayerFrame_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0
			};
		end
	end
	
	if TargetFrame and not C.TargetFrame_BlizzardDefault then
		local point, relativeTo, relativePoint, x, y = TargetFrame:GetPoint(1);
		-- FIX: Solo guardar si GetPoint devolvió datos válidos
		if point then
			C.TargetFrame_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0
			};
		end
	end
end

-- FIX: Intentar en parse-time (que es lo más temprano posible, antes de que
-- CONFIG_LOADED mueva los frames), pero con nil guards robustos.
-- Si falla (GetPoint devuelve nil), reintentar en PLAYER_LOGIN como backup.
SaveBlizzardDefaults();

-- Backup: si parse-time no capturó los defaults, reintentar antes de que
-- FramePositions.lua los necesite en PLAYER_LOGIN.
local initDefaults = CreateFrame("Frame");
initDefaults:RegisterEvent("PLAYER_LOGIN");
initDefaults:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	SaveBlizzardDefaults();
end);