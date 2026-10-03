local AddOnName, ns = ...;
local K, C, L = unpack(ns);














































local MEDIA = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\pw\\";
local TEX_BORDER = MEDIA .. "Border.tga";


local NEUTRAL = { 0.30, 0.30, 0.30, 1 };
local TEXCOORD = { 0.08, 0.92, 0.08, 0.92 };
local INSET = 2;

local UNITS = { "TargetFrame", "FocusFrame" };

local MAX_BUFFS   = MAX_TARGET_BUFFS or 32;
local MAX_DEBUFFS = MAX_TARGET_DEBUFFS or 16;

local orig    = {};
local applied = false;




local function SnapPoints(region)
	if not region then return nil; end
	local n = region:GetNumPoints() or 0;
	if n == 0 then return nil; end
	local pts = {};
	for i = 1, n do pts[i] = { region:GetPoint(i) }; end
	return pts;
end

local function RestorePoints(region, pts)
	if not region or not pts or #pts == 0 then return; end
	region:ClearAllPoints();
	for _, pt in ipairs(pts) do pcall(region.SetPoint, region, unpack(pt)); end
end








local function Prepare(frameName)
	local frame = _G[frameName];
	if not frame then return nil; end

	if frame.nufAuraBorder then return frame.nufAuraBorder; end

	local icon = _G[frameName .. "Icon"];
	orig[frameName] = {
		iconPoints = SnapPoints(icon),
		iconCoord  = icon and { icon:GetTexCoord() } or nil,
	};





	local bo = frame:CreateTexture(nil, "OVERLAY");
	if bo.SetDrawLayer then pcall(bo.SetDrawLayer, bo, "OVERLAY", -1); end
	bo:SetTexture(TEX_BORDER);
	bo:SetAllPoints(frame);
	bo:Hide();
	frame.nufAuraBorder = bo;
	return bo;
end




local function StyleIcon(frameName, r, g, b)
	local bo = Prepare(frameName);
	if not bo then return; end

	local frame = _G[frameName];
	local icon  = _G[frameName .. "Icon"];
	if icon then
		icon:ClearAllPoints();
		icon:SetPoint("TOPLEFT", frame, "TOPLEFT", INSET, -INSET);
		icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -INSET, INSET);
		icon:SetTexCoord(unpack(TEXCOORD));
	end

	bo:SetVertexColor(r, g, b, 1);
	bo:Show();
end

local function RestoreIcon(frameName)
	local frame = _G[frameName];
	if not frame then return; end

	if frame.nufAuraBorder then frame.nufAuraBorder:Hide(); end

	local snap = orig[frameName];
	local icon = _G[frameName .. "Icon"];
	if icon and snap then
		RestorePoints(icon, snap.iconPoints);
		if snap.iconCoord and #snap.iconCoord >= 4 then
			pcall(icon.SetTexCoord, icon, unpack(snap.iconCoord));
		end
	end



	local blizz = _G[frameName .. "Border"];
	if blizz then blizz:Show(); end

	local steal = _G[frameName .. "Stealable"];
	if steal and snap and snap.stealPoints then
		RestorePoints(steal, snap.stealPoints);
		steal:Hide();
	end
end









local function UpdateSteal(frameName, show)
	local steal = _G[frameName .. "Stealable"];
	if not steal then return; end
	local icon = _G[frameName .. "Icon"];
	if not icon then return; end

	local snap = orig[frameName];
	if snap and not snap.stealPoints then
		snap.stealPoints = SnapPoints(steal);
	end

	if not show then steal:Hide(); return; end

	steal:ClearAllPoints();
	steal:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 3, 3);
	steal:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -3, -3);
	if steal.SetBlendMode then steal:SetBlendMode("ADD"); end
	if steal.SetDrawLayer then pcall(steal.SetDrawLayer, steal, "OVERLAY", 7); end
	steal:Show();
end








local function Restyle(self)
	if not applied then return; end
	if not self or not self.GetName then return; end

	local base = self:GetName();
	if base ~= "TargetFrame" and base ~= "FocusFrame" then return; end

	local unit = self.unit;
	local glow = C.AuraBordersPurge ~= false
		and unit and UnitExists(unit) and UnitIsEnemy("player", unit);


	for i = 1, MAX_BUFFS do
		local name = base .. "Buff" .. i;
		local frame = _G[name];
		if not frame or not frame:IsShown() then break; end

		StyleIcon(name, NEUTRAL[1], NEUTRAL[2], NEUTRAL[3]);

		local _, _, _, _, debuffType = UnitBuff(unit, i);
		UpdateSteal(name, glow and debuffType == "Magic");
	end


	for i = 1, MAX_DEBUFFS do
		local name = base .. "Debuff" .. i;
		local frame = _G[name];
		if not frame or not frame:IsShown() then break; end




		local _, _, _, _, debuffType = UnitDebuff(unit, i);
		local color = (DebuffTypeColor and (DebuffTypeColor[debuffType]
			or DebuffTypeColor["none"])) or nil;

		if color then
			StyleIcon(name, color.r, color.g, color.b);
		else
			StyleIcon(name, NEUTRAL[1], NEUTRAL[2], NEUTRAL[3]);
		end



		local blizz = _G[name .. "Border"];
		if blizz then blizz:Hide(); end
	end
end




function K.EnableAuraBorders()
	applied = true;
	for _, base in ipairs(UNITS) do
		local f = _G[base];
		if f then pcall(Restyle, f); end
	end
end

function K.DisableAuraBorders()
	if not applied then return; end
	applied = false;
	for _, base in ipairs(UNITS) do
		for i = 1, MAX_BUFFS   do RestoreIcon(base .. "Buff" .. i);   end
		for i = 1, MAX_DEBUFFS do RestoreIcon(base .. "Debuff" .. i); end
	end
end

function K.IsAuraBordersActive()
	return applied;
end

function K.ApplyAuraBorders()
	if C.AuraBordersEnabled then
		K.EnableAuraBorders();
	else
		K.DisableAuraBorders();
	end
end












if type(TargetFrame_UpdateAuras) == "function" then
	hooksecurefunc("TargetFrame_UpdateAuras", Restyle);
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	K.ApplyAuraBorders();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	K.ApplyAuraBorders();
end);
