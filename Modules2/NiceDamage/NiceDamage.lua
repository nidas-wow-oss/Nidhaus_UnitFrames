-- ============================================================
--  NiceDamage - Module for Nidhaus UnitFrames
--  v3.1 - Integrated as NUF Module (Modules2)
--         Dual Font Selector: Damage + Heals/Auras
-- ============================================================
local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local ADDON_PATH   = "Interface\\AddOns\\" .. AddOnName .. "\\Modules2\\NiceDamage\\";
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF";

local fontList = {
	{ name = "Default WoW",    file = nil          },
	{ name = "Pepsi",          file = "font.ttf"   },
	{ name = "Zombie",         file = "font2.ttf"  },
	{ name = "Basket Hammers", file = "font3.ttf"  },
	{ name = "College",        file = "font4.ttf"  },
	{ name = "Galaxy",         file = "font5.ttf"  },
	{ name = "Elite",          file = "font6.ttf"  },
	{ name = "Stentiga",       file = "font7.ttf"  },
	{ name = "Skratch Punk",   file = "font8.ttf"  },
};

-- Estado
local dmgFontIndex  = 2;
local healFontIndex = 1;
local moduleActive  = false;

-- ── Helpers ──────────────────────────────────────────────────
local function GetFontPath(index)
	local data = fontList[index];
	if data and data.file then
		return ADDON_PATH .. data.file;
	end
	return DEFAULT_FONT;
end

local function SafeSetFont(fontObj, path, size, flags)
	if not fontObj then return false; end
	local ok = fontObj:SetFont(path, size or 18, flags or "");
	if not ok then
		fontObj:SetFont(DEFAULT_FONT, size or 18, flags or "");
		return false;
	end
	return true;
end

-- ── Font validation ──────────────────────────────────────────
-- WoW caches DAMAGE_TEXT_FONT at startup. If the path points to a
-- missing/invalid file, floating damage text becomes INVISIBLE.
-- We validate by attempting SetFont on a hidden test FontString.
local _testFontString;
local function IsFontValid(path)
	if not path or path == DEFAULT_FONT then return true; end
	if not _testFontString then
		local f = CreateFrame("Frame", nil, UIParent);
		f:Hide();
		_testFontString = f:CreateFontString(nil, "ARTWORK");
	end
	local ok = _testFontString:SetFont(path, 12, "");
	return ok;
end

-- ── SavedVariables ───────────────────────────────────────────
-- (Must be defined BEFORE ApplyDamageFont which references SaveChoice)
local function SaveChoice()
	NiceDamageDB = NiceDamageDB or {};
	NiceDamageDB.dmgFont  = dmgFontIndex;
	NiceDamageDB.healFont = healFontIndex;
end

local function LoadChoice()
	if NiceDamageDB then
		dmgFontIndex  = NiceDamageDB.dmgFont  or 2;
		healFontIndex = NiceDamageDB.healFont or 1;
		if NiceDamageDB.selectedFont and not NiceDamageDB.dmgFont then
			dmgFontIndex = NiceDamageDB.selectedFont;
		end
	end
	if type(dmgFontIndex)  ~= "number" then dmgFontIndex  = 2; end
	if type(healFontIndex) ~= "number" then healFontIndex = 1; end
	if dmgFontIndex  < 1 or dmgFontIndex  > #fontList then dmgFontIndex  = 2; end
	if healFontIndex < 1 or healFontIndex > #fontList then healFontIndex = 1; end
end

-- ── Aplicar fuentes ──────────────────────────────────────────
local function ApplyDamageFont()
	local path = GetFontPath(dmgFontIndex);
	-- FIX: Validate font before setting global. If invalid, fall back to default
	-- and reset index to prevent permanent invisible damage text.
	if IsFontValid(path) then
		DAMAGE_TEXT_FONT = path;
	else
		DAMAGE_TEXT_FONT = DEFAULT_FONT;
		dmgFontIndex = 1; -- reset to Default WoW
		SaveChoice();
	end
end

local function ApplyHealFont()
	if CombatTextFont then
		local _, size, flags = CombatTextFont:GetFont();
		SafeSetFont(CombatTextFont, GetFontPath(healFontIndex), size, flags);
	end
end

local function ApplyAll()
	if not moduleActive then return; end
	ApplyDamageFont();
	ApplyHealFont();
end

-- ── Menu ─────────────────────────────────────────────────────
local menuFrame;
local ROW_HEIGHT = 28;
local BTN_SIZE   = 22;
local PANEL_W    = 310;
local PANEL_H    = 58 + (#fontList * ROW_HEIGHT) + 60;

local function BuildMenu()
	if menuFrame then return; end

	menuFrame = CreateFrame("Frame", "NiceDamageMenu", UIParent);
	menuFrame:SetWidth(PANEL_W);
	menuFrame:SetHeight(PANEL_H);
	menuFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	menuFrame:SetFrameStrata("DIALOG");
	menuFrame:SetMovable(true);
	menuFrame:EnableMouse(true);
	menuFrame:RegisterForDrag("LeftButton");
	menuFrame:SetScript("OnDragStart", function() menuFrame:StartMoving(); end);
	menuFrame:SetScript("OnDragStop",  function() menuFrame:StopMovingOrSizing(); end);
	menuFrame:Hide();

	menuFrame:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	});
	menuFrame:SetBackdropColor(0.08, 0.08, 0.15, 0.97);
	menuFrame:SetBackdropBorderColor(0.4, 0.4, 0.8, 1);

	local title = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	title:SetPoint("TOP", menuFrame, "TOP", 0, -12);
	title:SetText("|cff88aaffNiceDamage|r |cffaaaaaaFont Selector|r");

	local closeBtn = CreateFrame("Button", nil, menuFrame, "UIPanelCloseButton");
	closeBtn:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -2, -2);
	closeBtn:SetScript("OnClick", function() menuFrame:Hide(); end);

	local headerY = -34;
	local lblFont = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	lblFont:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 12, headerY);
	lblFont:SetText("|cffffff88Font|r");

	local lblD = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	lblD:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -38, headerY);
	lblD:SetText("|cffff8844D|r");

	local lblH = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	lblH:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -14, headerY);
	lblH:SetText("|cff44ff88H|r");

	local rows = {};
	local listStartY = -48;

	for i, fontData in ipairs(fontList) do
		local idx = i;
		local rowY = listStartY - (i - 1) * ROW_HEIGHT;
		local row = {};

		local rowBg = menuFrame:CreateTexture(nil, "BACKGROUND");
		rowBg:SetPoint("TOPLEFT",  menuFrame, "TOPLEFT",  8,  rowY + 1);
		rowBg:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -8, rowY + 1);
		rowBg:SetHeight(ROW_HEIGHT - 2);
		rowBg:SetTexture(0.12, 0.12, 0.22, 0.5);
		row.bg = rowBg;

		local label = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		label:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 14, rowY - 5);
		label:SetWidth(PANEL_W - 80);
		label:SetJustifyH("LEFT");
		if fontData.file then
			local ok = label:SetFont(ADDON_PATH .. fontData.file, 13, "");
			if not ok then label:SetFontObject(GameFontNormal); end
		end
		label:SetText(fontData.name);
		row.label = label;

		-- Boton [D]
		local btnD = CreateFrame("Button", nil, menuFrame);
		btnD:SetWidth(BTN_SIZE); btnD:SetHeight(BTN_SIZE);
		btnD:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -34, rowY - 2);
		local btnDbg = btnD:CreateTexture(nil, "BACKGROUND");
		btnDbg:SetAllPoints(); btnDbg:SetTexture(0.2, 0.15, 0.1, 0.8);
		row.btnDbg = btnDbg;
		local btnDhl = btnD:CreateTexture(nil, "HIGHLIGHT");
		btnDhl:SetAllPoints(); btnDhl:SetTexture(0.5, 0.3, 0.1, 0.5);
		local btnDtxt = btnD:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		btnDtxt:SetPoint("CENTER"); btnDtxt:SetText("|cffff8844D|r");
		row.btnDtxt = btnDtxt;

		btnD:SetScript("OnClick", function()
			dmgFontIndex = idx; SaveChoice(); ApplyDamageFont(); menuFrame:RefreshSelection();
		end);
		btnD:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("|cffff8844Enemy Damage|r\n|cffaaaaaaRequires reopening WoW|r", nil, nil, nil, nil, true);
			GameTooltip:Show();
		end);
		btnD:SetScript("OnLeave", function() GameTooltip:Hide(); end);

		-- Boton [H]
		local btnH = CreateFrame("Button", nil, menuFrame);
		btnH:SetWidth(BTN_SIZE); btnH:SetHeight(BTN_SIZE);
		btnH:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -10, rowY - 2);
		local btnHbg = btnH:CreateTexture(nil, "BACKGROUND");
		btnHbg:SetAllPoints(); btnHbg:SetTexture(0.1, 0.2, 0.1, 0.8);
		row.btnHbg = btnHbg;
		local btnHhl = btnH:CreateTexture(nil, "HIGHLIGHT");
		btnHhl:SetAllPoints(); btnHhl:SetTexture(0.1, 0.5, 0.2, 0.5);
		local btnHtxt = btnH:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		btnHtxt:SetPoint("CENTER"); btnHtxt:SetText("|cff44ff88H|r");
		row.btnHtxt = btnHtxt;

		btnH:SetScript("OnClick", function()
			healFontIndex = idx; SaveChoice(); ApplyHealFont(); menuFrame:RefreshSelection();
		end);
		btnH:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("|cff44ff88Heals, Auras & Self Text|r\n|cffaaaaaaApplies instantly|r", nil, nil, nil, nil, true);
			GameTooltip:Show();
		end);
		btnH:SetScript("OnLeave", function() GameTooltip:Hide(); end);

		rows[i] = row;
	end
	menuFrame.rows = rows;

	local sepY = listStartY - (#fontList * ROW_HEIGHT) - 2;
	local sep = menuFrame:CreateTexture(nil, "ARTWORK");
	sep:SetHeight(1);
	sep:SetPoint("TOPLEFT",  menuFrame, "TOPLEFT",  10, sepY);
	sep:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -10, sepY);
	sep:SetTexture(0.4, 0.4, 0.6, 0.8);

	local legD = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	legD:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 12, sepY - 8);
	legD:SetText("|cffff8844D|r |cffaaaaaa= Enemy Damage (requires reopening WoW)|r");

	local legH = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	legH:SetPoint("TOPLEFT", legD, "BOTTOMLEFT", 0, -4);
	legH:SetText("|cff44ff88H|r |cffaaaaaa= Heals / Auras / Self Text (instant)|r");

	function menuFrame:RefreshSelection()
		for i, row in ipairs(self.rows) do
			local isDmg  = (i == dmgFontIndex);
			local isHeal = (i == healFontIndex);
			if isDmg and isHeal then
				row.bg:SetTexture(0.25, 0.35, 0.2, 0.7);
			elseif isDmg then
				row.bg:SetTexture(0.3, 0.2, 0.1, 0.6);
			elseif isHeal then
				row.bg:SetTexture(0.1, 0.25, 0.15, 0.6);
			else
				row.bg:SetTexture(0.12, 0.12, 0.22, 0.5);
			end
			if isDmg then
				row.btnDbg:SetTexture(0.8, 0.4, 0.1, 0.9);
				row.btnDtxt:SetText("|cffffffffD|r");
			else
				row.btnDbg:SetTexture(0.2, 0.15, 0.1, 0.6);
				row.btnDtxt:SetText("|cff886644D|r");
			end
			if isHeal then
				row.btnHbg:SetTexture(0.1, 0.7, 0.3, 0.9);
				row.btnHtxt:SetText("|cffffffffH|r");
			else
				row.btnHbg:SetTexture(0.1, 0.2, 0.1, 0.6);
				row.btnHtxt:SetText("|cff448844H|r");
			end
			if isDmg and isHeal then
				row.label:SetTextColor(1, 1, 0.5);
			elseif isDmg then
				row.label:SetTextColor(1, 0.6, 0.3);
			elseif isHeal then
				row.label:SetTextColor(0.4, 1, 0.5);
			else
				row.label:SetTextColor(0.8, 0.8, 0.8);
			end
		end
	end
end

local function ToggleMenu()
	if not moduleActive then return; end
	BuildMenu();
	if menuFrame:IsShown() then
		menuFrame:Hide();
	else
		menuFrame:RefreshSelection();
		menuFrame:Show();
	end
end

-- Export para acceso desde slash command
K.ToggleNiceDamageMenu = ToggleMenu;

-- ── createUI: botón "Open Font Selector" en tab Modules ─────
local function NiceDamage_CreateUI(parent, yOffset, mainCheck)
	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
	btn:SetPoint("TOPLEFT", 36, yOffset - 4);
	btn:SetSize(140, 20);
	btn:SetText("Open Font Selector");
	btn:SetScript("OnClick", function()
		ToggleMenu();
	end);
	return 30; -- height used
end

-- ── Enable / Disable ─────────────────────────────────────────
local function NiceDamage_Enable()
	moduleActive = true;
	LoadChoice();
	ApplyAll();
end

local function NiceDamage_Disable()
	moduleActive = false;
	if menuFrame and menuFrame:IsShown() then menuFrame:Hide(); end
	DAMAGE_TEXT_FONT = DEFAULT_FONT;
	if CombatTextFont then
		local _, size, flags = CombatTextFont:GetFont();
		CombatTextFont:SetFont(DEFAULT_FONT, size or 18, flags or "");
	end
end

-- ── Register Module ──────────────────────────────────────────
K.RegisterModule("NiceDamage", {
	name      = "NiceDamage",
	desc      = "Dual font selector: one font for damage, another for heals/auras. /nd to open.",
	default   = true,
	onEnable  = NiceDamage_Enable,
	onDisable = NiceDamage_Disable,
	createUI  = NiceDamage_CreateUI,
});

-- ── Eventos ──────────────────────────────────────────────────
-- FIX: Set DAMAGE_TEXT_FONT as early as possible (ADDON_LOADED).
-- WoW reads this global to create font objects — if we wait until
-- PLAYER_LOGIN (when modules init), it may be too late and damage
-- text won't render until client restart.
-- PLAYER_ENTERING_WORLD: re-apply heal font on zone changes.
local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == AddOnName then
		-- Load saved choice and set DAMAGE_TEXT_FONT immediately
		LoadChoice();
		local path = GetFontPath(dmgFontIndex);
		if IsFontValid(path) then
			DAMAGE_TEXT_FONT = path;
		else
			DAMAGE_TEXT_FONT = DEFAULT_FONT;
			dmgFontIndex = 1;
		end
	elseif event == "PLAYER_ENTERING_WORLD" and moduleActive then
		ApplyAll();
	end
end);

-- ── Slash commands ───────────────────────────────────────────
SLASH_NICEDAMAGE1 = "/nicedamage";
SLASH_NICEDAMAGE2 = "/nd";
SlashCmdList["NICEDAMAGE"] = function(msg)
	msg = string.lower(msg or "");
	if not moduleActive then
		print("|cff88aaffNiceDamage:|r Module disabled. Enable it in NUF options > Modules.");
		return;
	end
	if msg == "reset" then
		dmgFontIndex  = 2;
		healFontIndex = 1;
		SaveChoice();
		ApplyAll();
	elseif msg == "debug" then
		local d = fontList[dmgFontIndex]  and fontList[dmgFontIndex].name  or "?";
		local h = fontList[healFontIndex] and fontList[healFontIndex].name or "?";
		DEFAULT_CHAT_FRAME:AddMessage("|cff88aaffNiceDamage DEBUG:|r");
		DEFAULT_CHAT_FRAME:AddMessage("  Dano: [" .. dmgFontIndex .. "] " .. d);
		DEFAULT_CHAT_FRAME:AddMessage("  Heals: [" .. healFontIndex .. "] " .. h);
		DEFAULT_CHAT_FRAME:AddMessage("  DAMAGE_TEXT_FONT = " .. tostring(DAMAGE_TEXT_FONT));
		if CombatTextFont then
			local f, s = CombatTextFont:GetFont();
			DEFAULT_CHAT_FRAME:AddMessage("  CombatTextFont = " .. tostring(f) .. " @ " .. tostring(s));
		end
	else
		ToggleMenu();
	end
end