local AddOnName, ns = ...;
local K, C, L = unpack(ns);





















local STYLE_DEFAULT  = "Default";
local STYLE_NEW      = "New";
local STYLE_IMPROVED = "Improved";
local STYLE_PW       = "PW";



local STYLE_PW2      = "PW2";

K.PARTY_STYLES = { STYLE_DEFAULT, STYLE_NEW, STYLE_IMPROVED, STYLE_PW, STYLE_PW2 };

local applying = false;

function K.GetPartyFrameStyle()
	return C.PartyFrameStyle or STYLE_DEFAULT;
end




function K.SetPartyFrameStyle(style, skipSave)
	if applying then return; end
	if style ~= STYLE_NEW and style ~= STYLE_IMPROVED and style ~= STYLE_PW
		and style ~= STYLE_PW2 then
		style = STYLE_DEFAULT;
	end

	applying = true;











	if not skipSave then
		if K.SaveConfig then K.SaveConfig("PartyFrameStyle", style); end
	end
	C.PartyFrameStyle = style;


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


	local wantImproved = (style == STYLE_IMPROVED);
	if K.Modules and K.Modules["PartyFramesImproved"] then
		if K.IsModuleEnabled("PartyFramesImproved") ~= wantImproved then
			K.SetModuleEnabled("PartyFramesImproved", wantImproved);
		end
		if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("PartyFramesImproved"); end
	end




	local wantPW = (style == STYLE_PW) or (style == STYLE_PW2);
	if wantPW then
		if K.EnablePartyFramePW then pcall(K.EnablePartyFramePW); end
	else
		if K.DisablePartyFramePW then pcall(K.DisablePartyFramePW); end
	end



	applying = false;


	if K.ApplyPartyFrameSpacing then pcall(K.ApplyPartyFrameSpacing); end
	if K.RestylePartyFrames then pcall(K.RestylePartyFrames); end


	if wantImproved and K.PFI_Restyle then pcall(K.PFI_Restyle); end


	if wantPW and K.EnablePartyFramePW then pcall(K.EnablePartyFramePW); end
	if K.PartyBuffs_OnFramesMoved then pcall(K.PartyBuffs_OnFramesMoved); end
	if C.PartyMode3v3 and K.Apply3v3PartyMode then pcall(K.Apply3v3PartyMode); end

	if K.RefreshPartyStyleSelector then K.RefreshPartyStyleSelector(); end
end



function K.NotifyPartyStyleFromModule(style)
	if applying then return; end
	K.SetPartyFrameStyle(style);
end




local init = CreateFrame("Frame");
init:RegisterEvent("PLAYER_LOGIN");
init:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");



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
