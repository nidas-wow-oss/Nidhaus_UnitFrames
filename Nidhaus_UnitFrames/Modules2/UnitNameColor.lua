local AddOnName, ns = ...;
local K, C, L = unpack(ns);
















local NEUTRAL_R, NEUTRAL_G, NEUTRAL_B = 1, 0.86, 0;
local WHITE_R,   WHITE_G,   WHITE_B   = 1, 1, 1;


local unitFrames = {
	{ unit = "player",       frame = "PlayerFrame"       },
	{ unit = "target",       frame = "TargetFrame"       },
	{ unit = "targettarget", frame = "TargetFrameToT"    },
	{ unit = "focus",        frame = "FocusFrame"        },
	{ unit = "focustarget",  frame = "FocusFrameToT"     },
	{ unit = "pet",          frame = "PetFrame"          },
	{ unit = "party1",       frame = "PartyMemberFrame1" },
	{ unit = "party2",       frame = "PartyMemberFrame2" },
	{ unit = "party3",       frame = "PartyMemberFrame3" },
	{ unit = "party4",       frame = "PartyMemberFrame4" },
	{ unit = "arena1",       frame = "ArenaEnemyFrame1"  },
	{ unit = "arena2",       frame = "ArenaEnemyFrame2"  },
	{ unit = "arena3",       frame = "ArenaEnemyFrame3"  },
	{ unit = "arena4",       frame = "ArenaEnemyFrame4"  },
	{ unit = "arena5",       frame = "ArenaEnemyFrame5"  },
};

local function GetNameString(frameName)
	local frame = _G[frameName];
	if not frame then return nil; end
	if frame.name and frame.name.SetTextColor then return frame.name; end

	local fs = _G[frameName .. "Name"];
	if fs and fs.SetTextColor then return fs; end
	fs = _G[frameName .. "TextureFrameName"];
	if fs and fs.SetTextColor then return fs; end
	return nil;
end




local originalColor = {};

local function EnsureCaptured(frameName, nameString)
	if originalColor[frameName] then return; end
	local ok, r, g, b = pcall(nameString.GetTextColor, nameString);
	if ok and r then
		originalColor[frameName] = { r, g, b };
	else

		if frameName == "PetFrame" then
			originalColor[frameName] = { 1, 0.82, 0 };
		else
			originalColor[frameName] = { 1, 1, 1 };
		end
	end
end


local originalFont = {};
local function EnsureFontCaptured(frameName, nameString)
	if originalFont[frameName] then return; end
	if not nameString.GetFont then return; end
	local ok, f, s, fl = pcall(nameString.GetFont, nameString);




	if not ok or type(f) ~= "string" or f == "" then return; end


	local sx, sy = 0, 0;
	if nameString.GetShadowOffset then
		local okS, x, y = pcall(nameString.GetShadowOffset, nameString);
		if okS then sx, sy = x or 0, y or 0; end
	end
	local sr, sg, sb, sa = 0, 0, 0, 1;
	if nameString.GetShadowColor then
		local okC, r, g, b, a = pcall(nameString.GetShadowColor, nameString);
		if okC and r then sr, sg, sb, sa = r, g, b, a or 1; end
	end

	originalFont[frameName] = { f, s or 12, fl or "",
		shadow = { sx, sy, sr, sg, sb, sa } };
end










local sbFont, sbFlags, sbShadow;
local function StatusBarFont()
	if sbFont ~= nil then return sbFont, sbFlags, sbShadow; end
	sbFont = false;
	local probe = UIParent:CreateFontString(nil, "BACKGROUND", "TextStatusBarText");
	if not probe then return nil; end

	local ok, f, _, fl = pcall(probe.GetFont, probe);
	if ok and type(f) == "string" and f ~= "" then
		sbFont, sbFlags = f, fl;
		local sx, sy = 0, -1;
		local okO, x, y = pcall(probe.GetShadowOffset, probe);
		if okO and x then sx, sy = x, y; end
		local r, g, b, a = 0, 0, 0, 1;
		local okC, cr, cg, cb, ca = pcall(probe.GetShadowColor, probe);
		if okC and cr then r, g, b, a = cr, cg, cb, ca or 1; end
		sbShadow = { sx, sy, r, g, b, a };
	end
	probe:Hide();
	if sbFont == false then return nil; end
	return sbFont, sbFlags, sbShadow;
end


local function ApplyBorder(frameName, nameString)
	if _G.NUF_SAFE then return; end
	local of = originalFont[frameName];
	if not of or not of[1] or not nameString.SetFont then return; end
	local border = C.UnitNameBorder or "None";



	if border == "Shadow" then
		local f, fl, sh = StatusBarFont();
		if f then
			pcall(nameString.SetFont, nameString, f, of[2], fl);
			if sh then
				pcall(nameString.SetShadowOffset, nameString, sh[1], sh[2]);
				pcall(nameString.SetShadowColor, nameString, sh[3], sh[4], sh[5], sh[6]);
			end
			return;
		end

	end

	local FLAGS = {
		Outline = "OUTLINE",
		Thick   = "THICKOUTLINE",
	};
	local flag = FLAGS[border];
	if not flag then

		flag = (of[3] ~= "" and of[3]) or nil;
	end
	pcall(nameString.SetFont, nameString, of[1], of[2], flag);


	local sh = of.shadow;
	if sh then
		pcall(nameString.SetShadowOffset, nameString, sh[1], sh[2]);
		pcall(nameString.SetShadowColor, nameString, sh[3], sh[4], sh[5], sh[6]);
	end
end


local function IsActive()
	return (C.UnitNameColorMode or "Default") ~= "Default"
		or (C.UnitNameBorder or "None") ~= "None";
end

local function ApplyToUnit(unit, frameName)
	local nameString = GetNameString(frameName);
	if not nameString or not nameString.SetTextColor then return; end

	EnsureCaptured(frameName, nameString);
	EnsureFontCaptured(frameName, nameString);


	ApplyBorder(frameName, nameString);

	local mode = C.UnitNameColorMode or "Default";

	if mode == "White" then
		nameString:SetTextColor(WHITE_R, WHITE_G, WHITE_B);

	elseif mode == "Class" then
		if UnitExists(unit) and UnitIsPlayer(unit) then
			local _, class = UnitClass(unit);
			local color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class])
				or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]);
			if color then
				nameString:SetTextColor(color.r, color.g, color.b);
				return;
			end
		end

		local orig = originalColor[frameName];
		if orig then nameString:SetTextColor(orig[1], orig[2], orig[3]); end

	else
		local orig = originalColor[frameName];
		if orig then nameString:SetTextColor(orig[1], orig[2], orig[3]); end
	end
end

local function ApplyAll()
	if not IsActive() then return; end
	for _, entry in ipairs(unitFrames) do
		ApplyToUnit(entry.unit, entry.frame);
	end
end
K.ApplyUnitNameColor = ApplyAll;



function K.ResetUnitNameColor()
	for _, entry in ipairs(unitFrames) do
		local nameString = GetNameString(entry.frame);
		if nameString and nameString.SetTextColor then
			EnsureCaptured(entry.frame, nameString);
			EnsureFontCaptured(entry.frame, nameString);
			local orig = originalColor[entry.frame];
			if orig then nameString:SetTextColor(orig[1], orig[2], orig[3]); end
			local of = originalFont[entry.frame];
			if of and of[1] and nameString.SetFont then
				pcall(nameString.SetFont, nameString, of[1], of[2], (of[3] ~= "" and of[3]) or nil);
			end
		end
	end


	if type(TargetFrame_CheckFaction) == "function" then
		if TargetFrame and UnitExists("target") then pcall(TargetFrame_CheckFaction, TargetFrame); end
		if FocusFrame and UnitExists("focus") then pcall(TargetFrame_CheckFaction, FocusFrame); end
	end
end




local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("PLAYER_TARGET_CHANGED");
events:RegisterEvent("PLAYER_FOCUS_CHANGED");
events:RegisterEvent("UNIT_TARGET");
events:RegisterEvent("UNIT_PET");
events:RegisterEvent("PARTY_MEMBERS_CHANGED");
events:RegisterEvent("ARENA_OPPONENT_UPDATE");




pcall(events.RegisterEvent, events, "GROUP_ROSTER_UPDATE");
events:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" and not IsAddOnLoaded("Blizzard_ArenaUI") then

		pcall(LoadAddOn, "Blizzard_ArenaUI");
	end
	ApplyAll();
end);





local function HookIfExists(funcName, handler)
	if type(_G[funcName]) == "function" then
		hooksecurefunc(funcName, handler);
	end
end

HookIfExists("UnitFrame_Update", function(self)
	if not IsActive() then return; end
	if not self or not self.unit then return; end
	local frameName = self.GetName and self:GetName();
	if frameName then ApplyToUnit(self.unit, frameName); end
end);

HookIfExists("TargetFrame_Update", function()
	if not IsActive() then return; end
	ApplyToUnit("target", "TargetFrame");
	ApplyToUnit("targettarget", "TargetFrameToT");
end);

HookIfExists("TargetFrame_CheckFaction", function()
	if not IsActive() then return; end
	ApplyToUnit("target", "TargetFrame");
	ApplyToUnit("focus",  "FocusFrame");
end);

HookIfExists("PartyMemberFrame_UpdateMember", function(self)
	if not IsActive() then return; end
	if not self or not self.id then return; end
	ApplyToUnit("party" .. self.id, "PartyMemberFrame" .. self.id);
end);











local ticker = CreateFrame("Frame");
local tickAcc = 0;
ticker:Hide();
ticker:SetScript("OnUpdate", function(self, elapsed)
	tickAcc = tickAcc + elapsed;
	if tickAcc < 0.25 then return; end
	tickAcc = 0;
	ApplyAll();
end);

local function UpdateTickerState()
	if not IsActive() then
		ticker:Hide();
	else
		tickAcc = 0;
		ticker:Show();
	end
end

local function ApplyNow()
	if not IsActive() then
		K.ResetUnitNameColor();
	else
		ApplyAll();
	end
	UpdateTickerState();
end
K.ApplyUnitNameColorNow = ApplyNow;

if K.RegisterConfigEvent then
	K.RegisterConfigEvent("CONFIG_CHANGED", ApplyNow);
end


local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents();
	UpdateTickerState();
end);






SLASH_NUFNAMES1 = "/nufnames";
SlashCmdList["NUFNAMES"] = function(msg)
	msg = string.lower(msg or "");


	if msg == "white" or msg == "class" or msg == "default" then
		local mode = (msg == "white" and "White") or (msg == "class" and "Class") or "Default";
		if K.SaveConfig then K.SaveConfig("UnitNameColorMode", mode); end
		C.UnitNameColorMode = mode;
		ApplyNow();
		print("|cff4FC3F7NUF:|r modo forzado a " .. mode);
		return;
	end

	print("|cff4FC3F7NUF names|r ------------------------------");
	print("  modulo cargado: |cff00FF00si|r");
	print("  C.UnitNameColorMode = " .. tostring(C.UnitNameColorMode));
	print("  ticker corriendo   = " .. tostring(ticker:IsShown()));

	local found, missing = 0, {};
	for _, entry in ipairs(unitFrames) do
		local fs = GetNameString(entry.frame);
		if fs then
			found = found + 1;
			local ok, r, g, b = pcall(fs.GetTextColor, fs);
			if not ok then r, g, b = -1, -1, -1; end
			print(string.format("  |cff00FF00OK|r  %-18s color %.2f %.2f %.2f  texto: %s",
				entry.frame, r or -1, g or -1, b or -1, tostring(fs:GetText() or "")));
		else
			table.insert(missing, entry.frame);
		end
	end

	if #missing > 0 then
		print("  |cffFF5555NO ENCONTRADOS:|r " .. table.concat(missing, ", "));
	end
	print("  encontrados: " .. found .. " de " .. #unitFrames);
	print("  Uso: /nufnames white | class | default");
end
