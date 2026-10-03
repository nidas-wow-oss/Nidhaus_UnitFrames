local AddOnName, ns = ...;
local K, C, L = unpack(ns);



































local BAR_KEYS = {
	"MainBar", "ActionBar2", "ActionBar3",
	"StanceBar", "TotemBar", "PetBar", "PossessBar",
};











local function BarKeySet()
	local keys = {};
	for _, k in ipairs(BAR_KEYS) do keys[k] = true; end
	return keys;
end








local function ResetBarScaleSetting()
	local def = (K.GetConfigDefault and K.GetConfigDefault("ActionBarScale")) or 1.0;
	if C then C.ActionBarScale = def; end
	if K.SaveConfig then pcall(K.SaveConfig, "ActionBarScale", def); end
	if K.RefreshScaleSliders then pcall(K.RefreshScaleSliders); end
	return def;
end











local resync = CreateFrame("Frame");
resync:Hide();
resync:SetScript("OnUpdate", function(self)
	self:Hide();
	if C.MiniBarEnabled ~= true then return; end
	if InCombatLockdown() then return; end
	if K.ApplyBarHolderScales then
		pcall(K.ApplyBarHolderScales, C.ActionBarScale or 1.0);
	end
end);

local function RelayoutBars()
	if InCombatLockdown() then return; end

	if C.MiniBarEnabled == true then
		if K.ResetMiniBarLayout then pcall(K.ResetMiniBarLayout); end
	elseif K.ApplyActionBarButtonSpace then
		pcall(K.ApplyActionBarButtonSpace);
	end

	if K.UpdateActionBarsBox then pcall(K.UpdateActionBarsBox); end











	if C.MiniBarEnabled == true then resync:Show(); end
end








function K.ResetActionBars()
	ResetBarScaleSetting();

	if K.ResetGlobalPositions then
		K.ResetGlobalPositions(BarKeySet());
	end

	RelayoutBars();
end












local function ResetKeys(list, after)
	local keys = {};
	for _, k in ipairs(list) do keys[k] = true; end
	if K.ResetGlobalPositions then K.ResetGlobalPositions(keys); end
	if after then after(); end
end



function K.ResetAuras()
	ResetKeys({ "Buffs", "Debuffs" }, function()
		if K.ResetAuraAnchor then pcall(K.ResetAuraAnchor); end
		if K.ReanchorAuras   then pcall(K.ReanchorAuras);   end
		if K.ReanchorDebuffs then pcall(K.ReanchorDebuffs); end
	end);
end

function K.ResetCastBar()
	ResetKeys({ "CastBar" }, function()
		if K.ResetCastBarPositions then pcall(K.ResetCastBarPositions); end
	end);
end

function K.ResetMinimap()
	ResetKeys({ "Minimap" });
end












local UNITFRAME_SCALES = {
	"PlayerFrameScale", "TargetFrameScale",
	"FocusScale", "FocusSpellBarScale",
	"PetFrameScale",
	"PartyFrameScale", "PartyMemberFrameSpacing",
	"BossFrameScale", "BossTargetFrameSpacing",



	"Party3v3Scale1", "Party3v3Scale2", "Party3v3Scale3", "Party3v3Scale4",
};

function K.ResetUnitFrames()
	ResetKeys({
		"Player", "Target", "Pet",
		"Party1", "Party2", "Party3", "Party4",
		"PartyCast", "PartyTarget",
	}, function()

		if K.ResetPositionsAndScale then pcall(K.ResetPositionsAndScale); end


		for _, key in ipairs(UNITFRAME_SCALES) do
			local def = K.GetConfigDefault and K.GetConfigDefault(key);
			if def ~= nil then
				C[key] = def;
				if K.SaveConfigSilent then pcall(K.SaveConfigSilent, key, def); end



				local movables = K.GetMovablesForSetting and K.GetMovablesForSetting(key);
				if movables and K.SetGlobalFrameScale then
					for _, mk in ipairs(movables) do pcall(K.SetGlobalFrameScale, mk, def); end
				end
			end
		end
		if K.FlushConfigChanges then pcall(K.FlushConfigChanges); end






		if K.ApplyFocusFrameScale  then pcall(K.ApplyFocusFrameScale,  C.FocusScale); end
		if K.ApplyPetFrameScale    then pcall(K.ApplyPetFrameScale,    C.PetFrameScale); end
		if K.ApplyBossFrameScale   then pcall(K.ApplyBossFrameScale,   C.BossFrameScale); end
		if K.ApplyBossFrameSpacing then pcall(K.ApplyBossFrameSpacing); end
		if FocusFrameSpellBar then
			pcall(FocusFrameSpellBar.SetScale, FocusFrameSpellBar, C.FocusSpellBarScale or 1.2);
		end





		if K.Is3v3Active and K.Is3v3Active() then
			if K.Apply3v3PartyMode then pcall(K.Apply3v3PartyMode); end
		else
			if K.ApplyPartyFrameScale then pcall(K.ApplyPartyFrameScale, C.PartyFrameScale); end
			if K.ApplyPartyFrameSpacing then pcall(K.ApplyPartyFrameSpacing); end
		end


		if K.RefreshScaleSliders then pcall(K.RefreshScaleSliders); end
		if K.RefreshCastBarScaleSlider then pcall(K.RefreshCastBarScaleSlider); end



		if K.Refresh3v3Sliders then pcall(K.Refresh3v3Sliders); end
	end);
end









function K.ResetEverything()
	ResetBarScaleSetting();

	if K.ResetGlobalPositions then
		K.ResetGlobalPositions();
	end

	RelayoutBars();
end
