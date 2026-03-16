local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local _G, unpack = _G, unpack;
local hooksecurefunc = hooksecurefunc;
local UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP, UnitPowerMax = UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP, UnitPowerMax;

local NidhausPartyFrame;
local Path;
local isInitialized = false;

--	Party frame
local function Nidhaus_UnitFrames_Style_PartyMemberFrame(id)
	local partyFrame = _G["PartyMemberFrame"..id];
	if not partyFrame then return; end
	
	-- FIX: Nil check (antes podía ser nil si se llamaba antes de ConfigManager)
	local scale = C.PartyFrameScale;
	if type(scale) == "number" and scale > 0 and scale <= 3 then
		partyFrame:SetScale(scale);
	end
	_G["PartyMemberFrame"..id.."Texture"]:SetTexture(Path.."UI-PartyFrame");
	_G["PartyMemberFrame"..id.."HealthBarText"]:ClearAllPoints();
	_G["PartyMemberFrame"..id.."HealthBarText"]:SetPoint("CENTER", partyFrame, "CENTER", 19, 10);
	_G["PartyMemberFrame"..id.."HealthBarText"]:SetFont(unpack(C.PartyFrameFont));
	_G["PartyMemberFrame"..id.."ManaBarText"]:SetFont(unpack(C.PartyFrameFont));
	
	-- SetPosition PartyMemberFrame
	if not C.SetPositions then return; end;
	if not NidhausPartyFrame then return; end;
	
	partyFrame:ClearAllPoints();
	partyFrame:SetParent(NidhausPartyFrame);
	if id == 1 then
		partyFrame:SetPoint("TOPLEFT", NidhausPartyFrame, "TOPLEFT");
	else
		-- FIX: - en vez de + para que valores positivos expandan
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

-- PetFrame;
local function Nidhaus_UnitFrames_PartyMemberFrame_UpdatePet(self, id)
	if id then return; end;
	_G[self:GetName().."PetFrameTexture"]:SetTexture(Path.."UI-PartyFrame");
end;

local function InitializePartyFrames()
	if isInitialized then return; end
	
	-- Determinar path de texturas
	if C.darkFrames then 
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\";
	else
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\";
	end
	
	-- Crear frame contenedor solo si SetPositions está activo Y no existe aún
	if C.SetPositions and not NidhausPartyFrame then
		NidhausPartyFrame = CreateFrame("Frame", nil, UIParent);
		NidhausPartyFrame:SetSize(10, 10);
		-- FIX: PartyMemberFrame1 puede no existir aún en este punto
		if PartyMemberFrame1 then
			NidhausPartyFrame:SetFrameStrata(PartyMemberFrame1:GetFrameStrata());
		end
		K.NidhausPartyFrame = NidhausPartyFrame;
	end
	
	-- Aplicar estilos a cada party frame
	for i = 1, MAX_PARTY_MEMBERS do
		Nidhaus_UnitFrames_Style_PartyMemberFrame(i);
	end
	
	-- Registrar hooks solo una vez
	hooksecurefunc("PartyMemberFrame_UpdatePvPStatus", partyPvpIcon);
	hooksecurefunc("PartyMemberFrame_UpdatePet", Nidhaus_UnitFrames_PartyMemberFrame_UpdatePet);
	
	isInitialized = true;
end

K.InitializePartyFrames = InitializePartyFrames;

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

-- FIX: Aplicar spacing en tiempo real
function K.ApplyPartyFrameSpacing()
	if not isInitialized then return; end
	
	local spacing = C.PartyMemberFrameSpacing;
	if type(spacing) ~= "number" then spacing = 0; end
	
	-- FIX: Do NOT re-apply 3v3 positions if PartyIndividualMove is active.
	-- The user dragged frames individually — re-applying 3v3 wipes those positions.
	if C.SetPositions and C.PartyMode3v3 and not C.PartyIndividualMove and K.Apply3v3PartyMode then
		K.Apply3v3PartyMode();
		return;
	end
	
	-- If PartyIndividualMove is active, don't touch positions at all
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
	
	-- FIX: Do NOT apply generic PartyFrameScale when 3v3 mode is active.
	-- 3v3 mode sets per-frame scales (1.5 for frames 1-2, 1.3 for 3-4).
	-- Applying the generic scale here would overwrite those to 1.0.
	if not (C.SetPositions and C.PartyMode3v3) then
		if C.PartyFrameScale then
			K.ApplyPartyFrameScale(C.PartyFrameScale);
		end
	end
	
	-- Only apply spacing if user hasn't individually moved party frames.
	if not C.PartyIndividualMove then
		K.ApplyPartyFrameSpacing();
	end
end);