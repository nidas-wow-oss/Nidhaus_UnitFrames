local AddOnName, ns = ...;
ns[1] = {};
ns[2] = {};
ns[3] = {};








_G.NidhausUnitFramesNS = ns;












_G.NUF_SAFE = false;









local emgFrame = CreateFrame("Frame");
emgFrame:RegisterEvent("ADDON_LOADED");
emgFrame:SetScript("OnEvent", function(self, event, addon)
	if addon ~= AddOnName then return; end
	self:UnregisterEvent("ADDON_LOADED");
	if type(NidhausUnitFramesDB) ~= "table" or not NidhausUnitFramesDB._emgReset_v36d then
		NidhausUnitFramesDB = { _emgReset_v36d = true };
	end
end);

local function SaveBlizzardDefaults()
	local C = ns[2];
	
	if PlayerFrame and not C.PlayerFrame_BlizzardDefault then
		local point, relativeTo, relativePoint, x, y = PlayerFrame:GetPoint(1);

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
	







	if PlayerFrame and PlayerFrame.healthbar and not C.PlayerHealthBar_BlizzardDefault then
		local hb = PlayerFrame.healthbar;
		local point, relativeTo, relativePoint, x, y = hb:GetPoint(1);
		if point then
			C.PlayerHealthBar_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "PlayerFrame",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0,
				height = hb:GetHeight(),
			};
		end
	end
	
	if TargetFrame and TargetFrame.healthbar and not C.TargetHealthBar_BlizzardDefault then
		local hb = TargetFrame.healthbar;
		local point, relativeTo, relativePoint, x, y = hb:GetPoint(1);
		if point then
			C.TargetHealthBar_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "TargetFrame",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0,
				height = hb:GetHeight(),
			};
		end
	end
	
	if FocusFrame and FocusFrame.healthbar and not C.FocusHealthBar_BlizzardDefault then
		local hb = FocusFrame.healthbar;
		local point, relativeTo, relativePoint, x, y = hb:GetPoint(1);
		if point then
			C.FocusHealthBar_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "FocusFrame",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0,
				height = hb:GetHeight(),
			};
		end
	end
	
	if PlayerStatusTexture and not C.PlayerStatusTexture_BlizzardDefault then
		local tex = PlayerStatusTexture:GetTexture();
		local point, relativeTo, relativePoint, x, y = PlayerStatusTexture:GetPoint(1);
		if tex and point then
			C.PlayerStatusTexture_BlizzardDefault = {
				texture = tex,
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "PlayerFrame",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0,
			};
		end
	end
end




SaveBlizzardDefaults();



local initDefaults = CreateFrame("Frame");
initDefaults:RegisterEvent("PLAYER_LOGIN");
initDefaults:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	SaveBlizzardDefaults();
end);