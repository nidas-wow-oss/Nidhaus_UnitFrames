local AddOnName, ns = ...;
local K, C, L = unpack(ns);

































local _, playerClass = UnitClass("player");
local IS_HUNTER = (playerClass == "HUNTER");

local DEFAULT_ICON_SIZE = 32;
local ICON_GAP          = 5;



local BUFFS = {
	{ key = "MendPet",   id = 48990, unit = "pet"  },
	{ key = "Cower",     id = 1742,  unit = "pet"  },
	{ key = "LastStand", id = 53479, altId = 53478, unit = "both" },
};

local enabled = false;
local frame, icons = nil, {};




local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.HunterPetBuffs then
		NidhausUnitFramesDB.HunterPetBuffs = {};
	end
	return NidhausUnitFramesDB.HunterPetBuffs;
end

local function IsLocked()
	return C.PetBuffsLocked == true;
end




local function ResolveSpells()
	for _, b in ipairs(BUFFS) do
		local name, _, icon = GetSpellInfo(b.id);
		if not name and b.altId then
			name, _, icon = GetSpellInfo(b.altId);
		end
		b.name = name;
		b.icon = icon;

		if b.altId then
			b.altName = GetSpellInfo(b.altId);
			if b.altName == b.name then b.altName = nil; end
		end
	end
end




local function CreateIcon(parent, size)
	local btn = CreateFrame("Frame", nil, parent);
	btn:SetSize(size, size);

	btn.icon = btn:CreateTexture(nil, "ARTWORK");
	btn.icon:SetAllPoints();

	btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate");
	btn.cooldown:SetAllPoints();

	btn.count = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1);

	btn:Hide();
	return btn;
end

local function Layout()
	if not frame then return; end
	local size = C.PetBuffsIconSize or DEFAULT_ICON_SIZE;
	local x = 0;

	for _, b in ipairs(BUFFS) do
		local ic = icons[b.key];
		if ic then
			ic:SetSize(size, size);
			ic:ClearAllPoints();
			ic:SetPoint("LEFT", frame, "LEFT", x, 0);
			x = x + size + ICON_GAP;
		end
	end

	frame:SetSize(math.max(x - ICON_GAP, size), size);
end

local function Build()
	if frame then return; end
	ResolveSpells();

	frame = CreateFrame("Frame", "NUF_PetBuffs", UIParent);
	frame:SetSize(DEFAULT_ICON_SIZE * 3 + ICON_GAP * 2, DEFAULT_ICON_SIZE);
	frame:SetMovable(true);
	frame:EnableMouse(false);
	frame:SetClampedToScreen(true);


	frame.moveBG = frame:CreateTexture(nil, "BACKGROUND");
	frame.moveBG:SetAllPoints();
	frame.moveBG:SetTexture(0, 0.7, 1, 0.25);
	frame.moveBG:Hide();

	for _, b in ipairs(BUFFS) do
		if b.name and b.icon then
			local ic = CreateIcon(frame, C.PetBuffsIconSize or DEFAULT_ICON_SIZE);
			ic.icon:SetTexture(b.icon);
			icons[b.key] = ic;
		end
	end

	frame:RegisterForDrag("LeftButton");
	frame:SetScript("OnDragStart", function(self)
		if IsLocked() then return; end
		self:StartMoving();
	end);
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
		local db = DB();
		local point, _, relativePoint, x, y = self:GetPoint();
		db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y;
	end);

	Layout();
end

local function RestorePosition()
	if not frame then return; end
	local db = DB();
	frame:ClearAllPoints();
	if db.point then
		frame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
	elseif PetFrame then

		frame:SetPoint("TOPLEFT", PetFrame, "BOTTOMLEFT", 0, -5);
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, -120);
	end
end

function K.ResetPetBuffsPosition()
	local db = DB();
	db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil;
	RestorePosition();
end




local function FindBuff(unit, b)
	if not UnitExists(unit) then return nil; end
	for i = 1, 40 do
		local name, _, _, count, _, duration, expirationTime = UnitBuff(unit, i);
		if not name then break; end
		if name == b.name or (b.altName and name == b.altName) then
			return count, duration, expirationTime;
		end
	end
	return nil;
end

local preview = false;

local function Update()
	if not frame or not enabled then return; end
	if preview then return; end

	for _, b in ipairs(BUFFS) do
		local ic = icons[b.key];
		if ic then
			local count, duration, expirationTime;

			if b.unit == "both" then


				count, duration, expirationTime = FindBuff("pet", b);
				if not count then
					count, duration, expirationTime = FindBuff("player", b);
				end
			else
				count, duration, expirationTime = FindBuff(b.unit, b);
			end

			if count then
				ic:Show();
				if duration and duration > 0 and expirationTime then
					ic.cooldown:SetCooldown(expirationTime - duration, duration);
					ic.cooldown:Show();
				else
					ic.cooldown:Hide();
					ic.cooldown:SetCooldown(0, 0);
				end
				ic.count:SetText((count and count > 1) and count or "");
			else
				ic:Hide();
			end
		end
	end
end

K.UpdatePetBuffs = Update;




function K.SetPetBuffsPreview(state)
	if not IS_HUNTER then return; end
	Build();
	preview = state and true or false;

	if preview then
		RestorePosition();
		Layout();
		frame:EnableMouse(true);
		frame.moveBG:Show();
		frame:Show();
		for _, b in ipairs(BUFFS) do
			local ic = icons[b.key];
			if ic then
				ic:Show();
				ic.cooldown:SetCooldown(GetTime(), 15);
				ic.cooldown:Show();
			end
		end
	else
		frame:EnableMouse(false);
		frame.moveBG:Hide();
		for _, b in ipairs(BUFFS) do
			local ic = icons[b.key];
			if ic then ic.cooldown:SetCooldown(0, 0); end
		end
		Update();
	end
end

function K.IsPetBuffsPreview()
	return preview;
end

function K.ApplyPetBuffsLayout()
	if not frame then return; end
	Layout();
	if preview then K.SetPetBuffsPreview(true); end
end




local events = CreateFrame("Frame");
events:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_ENTERING_WORLD" then
		RestorePosition();
		Update();
		return;
	end

	if event == "UNIT_AURA" and unit ~= "pet" and unit ~= "player" then return; end
	Update();
end);




if IS_HUNTER then
	K.RegisterModule("HunterPetBuffs", {
		name    = L["MOD_PETBUFFS"] or "Pet Buffs",
		desc    = L["MOD_PETBUFFS_DESC"]
			or "Icons under the pet frame for Mend Pet, Cower and Last Stand, with their remaining duration.",
		default = false,
		onEnable = function()
			enabled = true;
			Build();
			RestorePosition();
			events:RegisterEvent("PLAYER_ENTERING_WORLD");
			events:RegisterEvent("UNIT_AURA");
			events:RegisterEvent("UNIT_PET");
			frame:Show();
			Update();
		end,
		onDisable = function()
			enabled = false;
			preview = false;
			events:UnregisterAllEvents();
			if frame then
				frame:EnableMouse(false);
				frame.moveBG:Hide();
				frame:Hide();
			end
		end,
	});
end

SLASH_NUFPETBUFFS1 = "/nufpetbuffs";
SlashCmdList["NUFPETBUFFS"] = function(msg)
	if not IS_HUNTER then
		print("|cff4FC3F7NUF:|r " .. (L["PETBUFFS_WRONG_CLASS"]
			or "This module is only for hunters."));
		return;
	end
	msg = string.lower(msg or "");
	if msg == "show" or msg == "move" then
		K.SetPetBuffsPreview(true);
	elseif msg == "hide" then
		K.SetPetBuffsPreview(false);
	elseif msg == "reset" then
		K.ResetPetBuffsPosition();
	else
		print("|cff4FC3F7NUF:|r /nufpetbuffs show | hide | reset");
	end
end
