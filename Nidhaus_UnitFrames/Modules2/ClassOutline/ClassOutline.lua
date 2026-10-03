local AddOnName, ns = ...;
local K, C, L = unpack(ns);

















local TEX_DIR  = "Interface\\AddOns\\" .. AddOnName .. "\\Modules2\\ClassOutline\\Textures\\";








local function RingTexture()
	if C.AsuriFrames or C.pwFrames then return TEX_DIR .. "PortraitRingFull"; end
	return TEX_DIR .. "PortraitRing";
end






local function RingTexCoord(frame)
	if frame.unit == "player" then
		return 1, 0, 0, 1;
	end
	return 0, 1, 0, 1;
end



local FALLBACK = {
	HUNTER      = { r = 0.67, g = 0.83, b = 0.45 },
	WARLOCK     = { r = 0.53, g = 0.53, b = 0.93 },
	PRIEST      = { r = 1.00, g = 1.00, b = 1.00 },
	PALADIN     = { r = 0.96, g = 0.55, b = 0.73 },
	MAGE        = { r = 0.25, g = 0.78, b = 0.92 },
	ROGUE       = { r = 1.00, g = 0.96, b = 0.41 },
	DRUID       = { r = 1.00, g = 0.49, b = 0.04 },
	SHAMAN      = { r = 0.00, g = 0.44, b = 0.87 },
	WARRIOR     = { r = 0.78, g = 0.61, b = 0.43 },
	DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
};

local function ClassColor(class)
	if not class then return nil; end
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class];
	if c and c.r then return c; end
	return FALLBACK[class];
end


local WATCHED = {
	player = true,
	target = true,
	focus  = true,
};

local enabled  = false;
local hooked   = false;
local rings    = {};




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ClassOutline then
		NidhausUnitFramesDB.ClassOutline = { size = 62 };
	end
	return NidhausUnitFramesDB.ClassOutline;
end




local function GetRing(frame)
	if rings[frame] then return rings[frame]; end
	if not frame.portrait then return nil; end

	local size = DB().size or 62;






	local host = frame.portrait:GetParent() or frame;

	local ring = CreateFrame("Frame", nil, host);
	ring:SetWidth(size);
	ring:SetHeight(size);


	ring:SetPoint("CENTER", frame.portrait, "CENTER", 0, 0);
	ring:SetFrameLevel(math.max(0, (host:GetFrameLevel() or 1) + 2));

	ring.texture = ring:CreateTexture(nil, "OVERLAY");
	ring.texture:SetAllPoints(ring);
	ring.texture:SetTexture(RingTexture());





	local icon = _G[(frame:GetName() or "") .. "PVPIcon"] or frame.pvpIcon
		or (frame == PlayerFrame and _G["PlayerPVPIcon"]);
	if icon and not icon._nufRaised then
		local host = CreateFrame("Frame", nil, frame);
		host:SetAllPoints(frame);
		host:SetFrameLevel(ring:GetFrameLevel() + 1);
		pcall(icon.SetParent, icon, host);
		icon._nufRaised = true;
	end

	ring:Hide();
	rings[frame] = ring;
	return ring;
end




local ASURI = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\Asuri\\";

local function AsuriChain(frame, ring)
	if not (C.UnitFrameCustomTexture and C.AsuriFrames) then return false; end
	if frame.unit == "player" then return false; end

	local class = UnitClassification(frame.unit);
	if class == "normal" or not UnitExists(frame.unit) then return false; end

	local gold = (class == "elite" or class == "worldboss");
	ring.texture:SetTexture(ASURI .. (gold and "ChainAsuriGold" or "ChainAsuri"));
	ring.texture:SetVertexColor(1, 1, 1);
	ring:SetWidth(256);
	ring:SetHeight(128);
	ring:ClearAllPoints();
	if frame == FocusFrame then
		ring.texture:SetTexCoord(1, 0, 0, 1);
		ring:SetPoint("CENTER", frame.portrait, "BOTTOMLEFT", 85, 12);
	else
		ring.texture:SetTexCoord(0, 1, 0, 1);
		ring:SetPoint("CENTER", frame.portrait, "BOTTOMLEFT", -22, 12);
	end
	ring:Show();
	return true;
end


local function ResetRing(ring, frame)
	local size = DB().size or 62;
	ring.texture:SetTexture(RingTexture());
	ring.texture:SetTexCoord(RingTexCoord(frame));
	ring:SetWidth(size);
	ring:SetHeight(size);
	ring:ClearAllPoints();
	ring:SetPoint("CENTER", frame.portrait, "CENTER", 0, 0);
end

local function UpdateFrame(frame)
	if not frame or not frame.unit then return; end
	if not WATCHED[frame.unit] then return; end

	local ring = GetRing(frame);
	if not ring then return; end



	if AsuriChain(frame, ring) then return; end
	ResetRing(ring, frame);

	if not enabled then
		ring:Hide();
		return;
	end


	if not UnitExists(frame.unit) or not UnitIsPlayer(frame.unit) then
		ring:Hide();
		return;
	end

	local _, class = UnitClass(frame.unit);
	local c = ClassColor(class);
	if not c then
		ring:Hide();
		return;
	end

	ring.texture:SetVertexColor(c.r, c.g, c.b);
	ring:Show();
end

local function UpdateAll()
	local frames = {
		_G["NidhausPlayerFrame"] or _G["PlayerFrame"],
		_G["PlayerFrame"],
		_G["TargetFrame"],
		_G["FocusFrame"],
	};
	for _, f in ipairs(frames) do
		if f then UpdateFrame(f); end
	end
end
K.RefreshClassOutlines = UpdateAll;




local function EnsureHook()
	if hooked then return; end
	hooked = true;


	hooksecurefunc("UnitFramePortrait_Update", function(self)
		if self and self.portrait then UpdateFrame(self); end
	end);
end

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function()
	UpdateAll();
end);


local boot = CreateFrame("Frame");
boot:RegisterEvent("PLAYER_ENTERING_WORLD");
boot:SetScript("OnEvent", function(self)
	if C.UnitFrameCustomTexture and C.AsuriFrames then
		EnsureHook();
		events:RegisterEvent("PLAYER_TARGET_CHANGED");
		events:RegisterEvent("PLAYER_FOCUS_CHANGED");
		UpdateAll();
	end
end);




function K.GetClassOutlineSize()
	return DB().size or 62;
end

function K.SetClassOutlineSize(v)
	v = tonumber(v) or 62;
	DB().size = v;
	UpdateAll();
end




K.RegisterModule("ClassOutline", {
	name    = L["MOD_CLASSOUTLINE"] or "Class Colored Outlines",
	desc    = L["MOD_CLASSOUTLINE_DESC"]
		or "Adds a class colored ring around the player, target and focus portraits.",
	default = false,
	hideFromModulesTab = true,

	onEnable = function()
		enabled = true;
		EnsureHook();
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
		events:RegisterEvent("PLAYER_TARGET_CHANGED");
		events:RegisterEvent("PLAYER_FOCUS_CHANGED");
		events:RegisterEvent("UNIT_PORTRAIT_UPDATE");
		UpdateAll();
	end,

	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		for _, ring in pairs(rings) do ring:Hide(); end
	end,
});
