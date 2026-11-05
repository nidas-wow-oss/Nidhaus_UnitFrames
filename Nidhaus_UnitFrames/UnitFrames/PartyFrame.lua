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

local function ThemePath()
	if C.darkFrames then
		return "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\";
	end
	return "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\";
end

local function Nidhaus_UnitFrames_Style_PartyMemberFrame(id)
	local partyFrame = _G["PartyMemberFrame"..id];
	if not partyFrame then return; end
	Path = ThemePath();

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

	local petTex = _G["PartyMemberFrame"..id.."PetFrameTexture"];
	if petTex then petTex:SetTexture(Path.."UI-PartyFrame"); end

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

		if style ~= "PW2" then
			if hpTxt then hpTxt:SetFont(unpack(C.PartyFrameFont)); end
			if mpTxt then mpTxt:SetFont(unpack(C.PartyFrameFont)); end
		end
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

	if K.ApplyPartyTextFont then K.ApplyPartyTextFont(id); end

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
	Path = ThemePath();
	if UnitIsPVPFreeForAll(unit) then
		icon:SetTexture(Path.."UI-PVP-FFA");
	elseif factionGroup and UnitIsPVP(unit) then
		icon:SetTexture(Path.."UI-PVP-"..factionGroup);
	end
end;

local function Nidhaus_UnitFrames_PartyMemberFrame_UpdatePet(self, id)
	if id then return; end;
	Path = ThemePath();
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

			local want = show and UnitIsConnected("party" .. i) and UnitExists("partypet" .. i)
				and SHOW_PARTY_PETS == "1" and true or false;
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

	Path = ThemePath();

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

local MIN_PARTY_FONT = 6;

for i = 1, (MAX_PARTY_MEMBERS or 4) do
	local n = _G["PartyMemberFrame" .. i .. "Name"];
	if n and n.GetFont and not n._nufBaseSize then
		local f0, s0, fl0 = n:GetFont();
		n._nufBaseFont, n._nufBaseSize, n._nufBaseFlags = f0, s0, fl0;
	end

	if n and n.GetPoint and not n._nufBasePoint then
		local p, rel, rp, x, y = n:GetPoint(1);
		if p then n._nufBasePoint = { p, rel, rp, x or 0, y or 0 }; end
	end
end

function K.RestorePartyNamePoint(i)
	local n = _G["PartyMemberFrame" .. i .. "Name"];
	local p = n and n._nufBasePoint;
	if not p then return false; end
	n:ClearAllPoints();
	n:SetPoint(p[1], p[2] or n:GetParent(), p[3] or p[1], p[4], p[5]);
	return true;
end

local function PartySize(kind, style)
	local v = tonumber(C["Party" .. kind .. "Size_" .. tostring(style)]) or 0;
	if v <= 0 then return 0; end
	if v < MIN_PARTY_FONT then v = MIN_PARTY_FONT; end
	return v;
end
K.GetPartyTextSize = PartySize;

function K.ApplyPartyTextFont(id)
	local style = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
	local fn = "PartyMemberFrame" .. id;
	if style == "Default" then

		local n = _G[fn .. "Name"];
		if n and n._nufTouched and n._nufBaseFont and n._nufBaseSize then
			pcall(n.SetFont, n, n._nufBaseFont, n._nufBaseSize, n._nufBaseFlags);
			n._nufTouched = nil;
		end
		return;
	end

	local nameTxt = _G[fn .. "Name"];
	if nameTxt then
		if not nameTxt._nufBaseSize then
			local f0, s0, fl0 = nameTxt:GetFont();
			nameTxt._nufBaseFont, nameTxt._nufBaseSize, nameTxt._nufBaseFlags = f0, s0, fl0;
		end
		local f, sz = nameTxt:GetFont();
		local want = PartySize("Name", style);
		if want == 0 and (style == "PW" or style == "PW2") then
			want = nameTxt._nufBaseSize or sz;
		end
		if want == 0 then want = sz; end
		local mode = C.PartyFontOutline;
		if mode == nil then mode = "OUTLINE"; end
		if mode == "Blizz" then

			local bFont, bFlags = BlizzStatusFont();
			if bFont and want then
				nameTxt._nufTouched = true;
				pcall(nameTxt.SetFont, nameTxt, bFont, want, bFlags);
				pcall(nameTxt.SetShadowOffset, nameTxt, 1, -1);
				pcall(nameTxt.SetShadowColor, nameTxt, 0, 0, 0, 1);
			end
		elseif f and want then
			nameTxt._nufTouched = true;
			pcall(nameTxt.SetFont, nameTxt, f, want, (mode ~= "") and mode or nil);
		end
	end

	local size = PartySize("Num", style);
	local nmode = C.PartyNumOutline;
	if nmode == nil then nmode = "Style"; end
	for _, fs in ipairs({ _G[fn .. "HealthBarText"], _G[fn .. "ManaBarText"] }) do
		if fs then

			if nmode ~= "Blizz" and fs._nufShadow then
				local sh = fs._nufShadow;
				pcall(fs.SetShadowOffset, fs, sh[1] or 0, sh[2] or 0);
				pcall(fs.SetShadowColor, fs, sh[3] or 0, sh[4] or 0, sh[5] or 0, sh[6] or 0);
				fs._nufShadow = nil;
			end
			local f, cur, fl = fs:GetFont();
			if f and nmode == "Blizz" then

				local bFont, bFlags = BlizzStatusFont();
				local target = (size > 0) and size or cur;
				if bFont and target then
					if not fs._nufShadow then
						local ox, oy = fs:GetShadowOffset();
						local r, g, b, a = fs:GetShadowColor();
						fs._nufShadow = { ox, oy, r, g, b, a };
					end
					pcall(fs.SetFont, fs, bFont, target, bFlags);
					pcall(fs.SetShadowOffset, fs, 1, -1);
					pcall(fs.SetShadowColor, fs, 0, 0, 0, 1);
				end
			elseif f and not (size == 0 and nmode == "Style") then
				local target = (size > 0) and size or cur;
				local flags = fl;
				if nmode ~= "Style" then flags = (nmode ~= "") and nmode or nil; end
				if target and (math.abs((cur or 0) - target) > 0.05 or flags ~= fl) then
					pcall(fs.SetFont, fs, f, target, flags);
				end
			end
		end
	end
end

function K.RefreshPartyText()
	if K.RestylePartyFrames   then K.RestylePartyFrames();   end
	if K.UpdateNewPartyFrames then K.UpdateNewPartyFrames(); end
	if K.PFI_Restyle          then K.PFI_Restyle();          end
	if K.PartyFramePW_Restyle then K.PartyFramePW_Restyle(); end
end

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

	if InCombatLockdown() then
		if K.AfterCombat then
			K.AfterCombat("ApplyPartyFrameScale", function()
				if not (K.Is3v3Active and K.Is3v3Active()) then K.ApplyPartyFrameScale(C.PartyFrameScale); end
			end);
		end
		return;
	end

	for i = 1, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame then
			partyFrame:SetScale(scale);
		end
	end
end

function K.ApplyPartyFrameSpacing()
	if not isInitialized then return; end

	if InCombatLockdown() then
		if K.AfterCombat then K.AfterCombat("ApplyPartyFrameSpacing", K.ApplyPartyFrameSpacing); end
		return;
	end

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
