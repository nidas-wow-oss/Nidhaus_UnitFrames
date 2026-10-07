local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local _G, unpack = _G, unpack;
local hooksecurefunc = hooksecurefunc;









local BLIZZ_FONT, BLIZZ_FLAGS;
local function BlizzStatusFont()
	if BLIZZ_FONT then return BLIZZ_FONT, BLIZZ_FLAGS; end
	local probe = UIParent:CreateFontString(nil, "BACKGROUND", "TextStatusBarText");
	if probe then
		local f, _, fl = probe:GetFont();
		BLIZZ_FONT, BLIZZ_FLAGS = f, fl;
		probe:Hide();
	end
	return BLIZZ_FONT, BLIZZ_FLAGS;
end
local UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP, UnitPowerMax = UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP, UnitPowerMax;

local NidhausPartyFrame;
local Path;
local isInitialized = false;


local function Nidhaus_UnitFrames_Style_PartyMemberFrame(id)
	local partyFrame = _G["PartyMemberFrame"..id];
	if not partyFrame then return; end
	










	local scale = C.PartyFrameScale;
	if C.PartyMode3v3 and K.Get3v3Scale then
		scale = K.Get3v3Scale(id);
	end





	if type(scale) == "number" and scale > 0 and scale <= 3 and not InCombatLockdown() then
		partyFrame:SetScale(scale);
	end




	local pstyle = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
	if pstyle == "Default" then
		_G["PartyMemberFrame"..id.."Texture"]:SetTexture(Path.."UI-PartyFrame");
	end

	local hpTxt = _G["PartyMemberFrame"..id.."HealthBarText"];
	local mpTxt = _G["PartyMemberFrame"..id.."ManaBarText"];
	local nameTxt = _G["PartyMemberFrame"..id.."Name"];



	if hpTxt and not hpTxt._nufOrig then
		local f, sz, fl = hpTxt:GetFont();
		hpTxt._nufOrig = { font = { f, sz, fl }, pts = { hpTxt:GetPoint(1) } };
	end
	if mpTxt and not mpTxt._nufOrigFont then
		local f, sz, fl = mpTxt:GetFont();
		mpTxt._nufOrigFont = { f, sz, fl };
	end







	local style = pstyle;
	if style ~= "Default" and style ~= "Improved" then
		if hpTxt then
			hpTxt:ClearAllPoints();
			hpTxt:SetPoint("CENTER", partyFrame, "CENTER", 19, 10);
			hpTxt:SetFont(unpack(C.PartyFrameFont));
		end
		if mpTxt then mpTxt:SetFont(unpack(C.PartyFrameFont)); end
	else

		if hpTxt and hpTxt._nufOrig then
			local o = hpTxt._nufOrig;
			if o.font[1] then hpTxt:SetFont(o.font[1], o.font[2], o.font[3]); end
			if o.pts and o.pts[1] then
				hpTxt:ClearAllPoints();
				hpTxt:SetPoint(o.pts[1], o.pts[2] or partyFrame, o.pts[3] or o.pts[1],
					o.pts[4] or 0, o.pts[5] or 0);
			end
		end
		if mpTxt and mpTxt._nufOrigFont and mpTxt._nufOrigFont[1] then
			local o = mpTxt._nufOrigFont;
			mpTxt:SetFont(o[1], o[2], o[3]);
		end
	end
	









	local isCustomStyle = (pstyle == "New" or pstyle == "Improved");
	if isCustomStyle then
		local outline = C.PartyFontOutline;
		if outline == "" or outline == "Blizz" then outline = nil; end




		local fsize = tonumber(C.PartyFontSize) or 0;
		if fsize > 0 and fsize < 6 then fsize = 6; end


		local blizzMode = (C.PartyFontOutline == "Blizz");
		local bFont, bFlags;
		if blizzMode then bFont, bFlags = BlizzStatusFont(); end


		local function Base(fs)
			if not fs._nufBaseSize then
				local f0, sz0 = fs:GetFont();
				fs._nufBaseSize = sz0 or 10;
				fs._nufBaseFont = f0;
			end
			return fs._nufBaseFont, fs._nufBaseSize;
		end


		if nameTxt then
			local bf, bs = Base(nameTxt);
			local f, sz = nameTxt:GetFont();
			if blizzMode and bFont then



				pcall(nameTxt.SetFont, nameTxt, bFont, sz or bs, bFlags);
				pcall(nameTxt.SetShadowOffset, nameTxt, 1, -1);
				pcall(nameTxt.SetShadowColor, nameTxt, 0, 0, 0, 1);
			elseif f then
				pcall(nameTxt.SetFont, nameTxt, bf or f, sz or bs, outline);
			end
		end



		for _, fs in ipairs({ hpTxt, mpTxt }) do
			if fs then
				local bf, bs = Base(fs);
				local f, sz, fl = fs:GetFont();
				local target = (fsize > 0) and fsize or bs;
				if f then pcall(fs.SetFont, fs, f, target, fl); end
			end
		end
	end















	if not C.SetPositions then return; end;

	if InCombatLockdown() then return; end;
	if not NidhausPartyFrame then return; end;
	if C.PartyMode3v3 then return; end;
	if C.PartyIndividualMove then return; end;

	partyFrame:ClearAllPoints();
	partyFrame:SetParent(NidhausPartyFrame);
	if id == 1 then
		partyFrame:SetPoint("TOPLEFT", NidhausPartyFrame, "TOPLEFT");
	else

		partyFrame:SetPoint("TOPLEFT", _G["PartyMemberFrame"..(id - 1).."PetFrame"], "BOTTOMLEFT", -23, -10 - C.PartyMemberFrameSpacing);
	end;
end;

local function partyPvpIcon(self)
	local id = self:GetID();
	local unit = "party"..id;
	local icon = _G["PartyMemberFrame"..id.."PVPIcon"];
	local factionGroup = UnitFactionGroup(unit);
	if UnitIsPVPFreeForAll(unit) then
		icon:SetTexture(Path.."UI-PVP-FFA");
	elseif factionGroup and UnitIsPVP(unit) then
		icon:SetTexture(Path.."UI-PVP-"..factionGroup);
	end
end;


local function Nidhaus_UnitFrames_PartyMemberFrame_UpdatePet(self, id)
	if id then return; end;
	_G[self:GetName().."PetFrameTexture"]:SetTexture(Path.."UI-PartyFrame");


	if C.PartyShowPetFrames == false then



		if K.ApplyPartyPetFrames then K.ApplyPartyPetFrames(); end
	end
end;
















local petPending = false;

function K.ApplyPartyPetFrames()
	if InCombatLockdown() then petPending = true; return; end
	petPending = false;

	local show = (C.PartyShowPetFrames ~= false);
	for i = 1, 4 do
		local pf = _G["PartyMemberFrame" .. i .. "PetFrame"];
		if pf then


			local want = show and UnitExists("partypet" .. i) and true or false;
			if want and not pf:IsShown() then
				pf:Show();
			elseif (not want) and pf:IsShown() then
				pf:Hide();
			end
		end
	end
end

local function InitializePartyFrames()
	if isInitialized then return; end
	

	if C.darkFrames then 
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\";
	else
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\";
	end
	

	if C.SetPositions and not NidhausPartyFrame then
		NidhausPartyFrame = CreateFrame("Frame", nil, UIParent);
		NidhausPartyFrame:SetSize(10, 10);

		if PartyMemberFrame1 then
			NidhausPartyFrame:SetFrameStrata(PartyMemberFrame1:GetFrameStrata());
		end
		K.NidhausPartyFrame = NidhausPartyFrame;
	end
	

	for i = 1, MAX_PARTY_MEMBERS do
		Nidhaus_UnitFrames_Style_PartyMemberFrame(i);
	end
	

	hooksecurefunc("PartyMemberFrame_UpdatePvPStatus", partyPvpIcon);
	hooksecurefunc("PartyMemberFrame_UpdatePet", Nidhaus_UnitFrames_PartyMemberFrame_UpdatePet);
	
	isInitialized = true;
end

K.InitializePartyFrames = InitializePartyFrames;



function K.RestylePartyFrames()
	if not isInitialized then return; end



	if InCombatLockdown() and K.AfterCombat then
		K.AfterCombat("RestylePartyFrames", K.RestylePartyFrames);
	end





	if K.ReleaseAbbrevAnchors then pcall(K.ReleaseAbbrevAnchors, "PartyMemberFrame"); end
	for i = 1, MAX_PARTY_MEMBERS do
		Nidhaus_UnitFrames_Style_PartyMemberFrame(i);
	end
	if K.RefreshAbbreviatedStatusBars then pcall(K.RefreshAbbreviatedStatusBars); end
end

function K.ApplyPartyFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	for i = 1, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame then
			partyFrame:SetScale(scale);
		end
	end
end


function K.ApplyPartyFrameSpacing()
	if not isInitialized then return; end
	
	local spacing = C.PartyMemberFrameSpacing;
	if type(spacing) ~= "number" then spacing = 0; end
	



	if K.Is3v3Active and K.Is3v3Active() and not C.PartyIndividualMove and K.Apply3v3PartyMode then
		K.Apply3v3PartyMode();
		return;
	end
	

	if C.PartyIndividualMove then return; end
	
	for i = 2, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame then
			local prevPet = _G["PartyMemberFrame"..(i-1).."PetFrame"];
			partyFrame:ClearAllPoints();
			if prevPet then
				partyFrame:SetPoint("TOPLEFT", prevPet, "BOTTOMLEFT", -23, -10 - spacing);
			else
				partyFrame:SetPoint("TOPLEFT", _G["PartyMemberFrame"..(i-1)], "BOTTOMLEFT", 0, -10 - spacing);
			end
		end
	end
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	if C.PartyFrameOn then
		InitializePartyFrames();
	end
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if not isInitialized then return; end
	










	if not (K.Is3v3Active and K.Is3v3Active()) then
		if C.PartyFrameScale then
			K.ApplyPartyFrameScale(C.PartyFrameScale);
		end
	end
	

	if not C.PartyIndividualMove then
		K.ApplyPartyFrameSpacing();
	end
end);



local petEvents = CreateFrame("Frame");
petEvents:RegisterEvent("PLAYER_ENTERING_WORLD");
petEvents:RegisterEvent("PARTY_MEMBERS_CHANGED");
petEvents:RegisterEvent("UNIT_PET");
petEvents:RegisterEvent("PLAYER_REGEN_ENABLED");
petEvents:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_ENABLED" and not petPending then return; end
	if K.ApplyPartyPetFrames then K.ApplyPartyPetFrames(); end
end);
