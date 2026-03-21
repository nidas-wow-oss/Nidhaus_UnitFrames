local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ThemeManager.lua
-- Visual theme system for the NUF options panel.
--
-- 3 themes:
--   Classic    — WoW Blizzard gold/brown, traditional look
--   DarkGold   — Deep black with amber/gold accents (Image 1 style)
--   ArcaneBlue — Dark with cyan/blue arcane accents (Image 2 style)
--
-- Usage:
--   K.ApplyPanelTheme("DarkGold")   — switch and persist
--   K.GetActiveTheme()               — returns current theme table
--   K.RegisterThemeFrames(data)      — called by OptionsPanel after build
-- =========================================================

-- ──────────────────────────────────────────────────────────
-- THEME DEFINITIONS
-- ──────────────────────────────────────────────────────────

local THEMES = {};
local THEME_ORDER = {"Classic", "DarkGold", "ArcaneBlue"};

-- ── Theme 1: Classic ──────────────────────────────────────
-- Standard WoW DialogBox look with gold active-tab accents.
-- Darker background + separator line under title (like Blizzard Interface panel).
THEMES["Classic"] = {
	id    = "Classic",
	label = "Classic",
	accent = {0.95, 0.78, 0.10},

	-- Main frame backdrop
	frameBG        = "Interface\\DialogFrame\\UI-DialogBox-Background",
	frameBorder    = "Interface\\DialogFrame\\UI-DialogBox-Border",
	frameTileSize  = 32,
	frameEdgeSize  = 32,
	frameInsets    = {left=11, right=12, top=12, bottom=11},
	frameBGColor   = {0.0, 0.0, 0.0, 0.88},   -- dark opaque background
	frameBorderColor = {1, 1, 1, 1},

	-- Title box — Classic uses native Blizzard header texture (see ThemeManager)
	useNativeHeader  = true,
	titleBGColor     = {0.08, 0.08, 0.08, 1.0},   -- unused in Classic but kept for safety
	titleBorderBG    = "Interface\\DialogFrame\\UI-DialogBox-Background",
	titleBorderEdge  = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
	titleBorderColor = {1, 1, 1, 1},

	-- Tab bar container
	tabBarBGColor     = {0, 0, 0, 0.40},
	tabBarBorderColor = {0, 0, 0, 0.85},

	-- Active tab
	tabSelBGColor     = {0.20, 0.20, 0.20, 0.90},
	tabSelBorderColor = {0.80, 0.70, 0.00, 0.90},

	-- Inactive tab
	tabBGColor        = {0.08, 0.08, 0.08, 0.80},
	tabBorderColor    = {0.40, 0.40, 0.40, 0.80},

	-- Hover tab
	tabHoverBGColor   = {0.30, 0.30, 0.30, 0.80},

	-- Content panels
	panelBGColor      = {0, 0, 0, 0.35},
	panelBorderColor  = {0.20, 0.20, 0.20, 0.80},
};

-- ── Theme 2: Dark Gold ────────────────────────────────────
-- Inspired by AddonPerformance / WoW arena addon UIs:
-- very dark background, warm amber/gold borders and accents.
THEMES["DarkGold"] = {
	id    = "DarkGold",
	label = "Dark Gold",
	accent = {0.96, 0.68, 0.08},

	frameBG        = "Interface\\Tooltips\\UI-Tooltip-Background",
	frameBorder    = "Interface\\Tooltips\\UI-Tooltip-Border",
	frameTileSize  = 16,
	frameEdgeSize  = 16,
	frameInsets    = {left=5, right=5, top=5, bottom=5},
	frameBGColor   = {0.040, 0.034, 0.018, 0.97},
	frameBorderColor = {0.72, 0.50, 0.07, 0.95},

	titleBGColor     = {0.060, 0.050, 0.010, 1.0},
	titleBorderBG    = "Interface\\Tooltips\\UI-Tooltip-Background",
	titleBorderEdge  = "Interface\\Tooltips\\UI-Tooltip-Border",
	titleBorderColor = {0.90, 0.62, 0.06, 1.0},

	tabBarBGColor     = {0.055, 0.045, 0.015, 0.97},
	tabBarBorderColor = {0.52, 0.36, 0.05, 0.88},

	tabSelBGColor     = {0.18, 0.13, 0.02, 0.97},
	tabSelBorderColor = {0.95, 0.70, 0.10, 1.00},

	tabBGColor        = {0.07, 0.06, 0.02, 0.85},
	tabBorderColor    = {0.40, 0.28, 0.05, 0.70},

	tabHoverBGColor   = {0.14, 0.10, 0.02, 0.90},

	panelBGColor      = {0.045, 0.036, 0.012, 0.92},
	panelBorderColor  = {0.58, 0.40, 0.06, 0.68},
};

-- ── Theme 3: Arcane Blue ──────────────────────────────────
-- Inspired by CASTCOP / dark PvP addon style:
-- near-black with cool blue/cyan accents, sharp borders.
THEMES["ArcaneBlue"] = {
	id    = "ArcaneBlue",
	label = "Arcane",
	accent = {0.25, 0.66, 1.0},

	frameBG        = "Interface\\Tooltips\\UI-Tooltip-Background",
	frameBorder    = "Interface\\Tooltips\\UI-Tooltip-Border",
	frameTileSize  = 16,
	frameEdgeSize  = 16,
	frameInsets    = {left=5, right=5, top=5, bottom=5},
	frameBGColor   = {0.028, 0.048, 0.095, 0.97},
	frameBorderColor = {0.22, 0.52, 0.92, 0.95},

	titleBGColor     = {0.035, 0.065, 0.140, 1.0},
	titleBorderBG    = "Interface\\Tooltips\\UI-Tooltip-Background",
	titleBorderEdge  = "Interface\\Tooltips\\UI-Tooltip-Border",
	titleBorderColor = {0.28, 0.68, 1.0, 1.0},

	tabBarBGColor     = {0.035, 0.060, 0.118, 0.97},
	tabBarBorderColor = {0.18, 0.44, 0.82, 0.88},

	tabSelBGColor     = {0.075, 0.145, 0.270, 0.97},
	tabSelBorderColor = {0.32, 0.72, 1.00, 1.00},

	tabBGColor        = {0.038, 0.075, 0.145, 0.85},
	tabBorderColor    = {0.16, 0.38, 0.68, 0.70},

	tabHoverBGColor   = {0.095, 0.180, 0.320, 0.90},

	panelBGColor      = {0.032, 0.058, 0.112, 0.92},
	panelBorderColor  = {0.20, 0.48, 0.85, 0.68},
};

-- ──────────────────────────────────────────────────────────
-- STATE
-- ──────────────────────────────────────────────────────────

local activeTheme  = THEMES["ArcaneBlue"];
local frameRegistry = {};

-- ──────────────────────────────────────────────────────────
-- INTERNAL APPLY
-- ──────────────────────────────────────────────────────────

local function ApplyThemeToFrames(theme)
	local reg = frameRegistry;

	-- Main panel window
	if reg.mainFrame then
		reg.mainFrame:SetBackdrop({
			bgFile   = theme.frameBG,
			edgeFile = theme.frameBorder,
			tile     = true,
			tileSize = theme.frameTileSize,
			edgeSize = theme.frameEdgeSize,
			insets   = theme.frameInsets,
		});
		reg.mainFrame:SetBackdropColor(unpack(theme.frameBGColor));
		reg.mainFrame:SetBackdropBorderColor(unpack(theme.frameBorderColor));
	end

	-- Title: Classic uses native Blizzard header texture; others use themed backdrop frame.
	-- IMPORTANT: titleBox is NEVER hidden — doing so would hide the title FontString too.
	-- For Classic: make titleBox backdrop fully transparent, show the texture on top.
	-- For DarkGold/Arcane: hide the texture, apply themed backdrop colors to titleBox.
	if reg.mainFrame then
		local headerTex = reg.mainFrame._titleHeaderTex;
		local titleBox  = reg.titleBox;
		if theme.useNativeHeader then
			-- Classic: show metallic texture, make titleBox backdrop invisible
			if headerTex then headerTex:Show(); end
			if titleBox then
				titleBox:SetBackdropColor(0, 0, 0, 0);
				titleBox:SetBackdropBorderColor(0, 0, 0, 0);
			end
		else
			-- DarkGold / ArcaneBlue: hide texture, apply themed backdrop
			if headerTex then headerTex:Hide(); end
			if titleBox then
				titleBox:SetBackdrop({
					bgFile   = theme.titleBorderBG,
					edgeFile = theme.titleBorderEdge,
					tile     = true,
					tileSize = 16,
					edgeSize = 16,
					insets   = {left=4, right=4, top=4, bottom=4},
				});
				titleBox:SetBackdropColor(unpack(theme.titleBGColor));
				titleBox:SetBackdropBorderColor(unpack(theme.titleBorderColor));
			end
		end
	end

	-- Tab bar strip
	if reg.tabBar then
		reg.tabBar:SetBackdropColor(unpack(theme.tabBarBGColor));
		reg.tabBar:SetBackdropBorderColor(unpack(theme.tabBarBorderColor));
	end

	-- Individual tabs (re-apply current selected/unselected state)
	if reg.tabs then
		for _, tab in ipairs(reg.tabs) do
			tab._nufTheme = theme;
			if tab.selected then
				tab:SetBackdropColor(unpack(theme.tabSelBGColor));
				tab:SetBackdropBorderColor(unpack(theme.tabSelBorderColor));
			else
				tab:SetBackdropColor(unpack(theme.tabBGColor));
				tab:SetBackdropBorderColor(unpack(theme.tabBorderColor));
			end
		end
	end

	-- Content panels
	if reg.tabPanels then
		for _, panel in ipairs(reg.tabPanels) do
			panel:SetBackdropColor(unpack(theme.panelBGColor));
			panel:SetBackdropBorderColor(unpack(theme.panelBorderColor));
		end
	end

	-- Theme selector pill buttons
	if reg.themeButtons then
		for id, btn in pairs(reg.themeButtons) do
			local t = THEMES[id];
			if t then
				if id == theme.id then
					-- Selected: glow in accent color
					btn:SetBackdropColor(
						t.accent[1] * 0.18,
						t.accent[2] * 0.18,
						t.accent[3] * 0.18,
						0.95);
					btn:SetBackdropBorderColor(
						t.accent[1], t.accent[2], t.accent[3], 1.0);
					if btn.dot then
						btn.dot:SetVertexColor(
							t.accent[1], t.accent[2], t.accent[3], 1.0);
					end
					if btn.labelFS then
						btn.labelFS:SetTextColor(
							t.accent[1], t.accent[2], t.accent[3]);
					end
				else
					-- Unselected: dim
					btn:SetBackdropColor(0.07, 0.07, 0.07, 0.65);
					btn:SetBackdropBorderColor(
						t.accent[1] * 0.38,
						t.accent[2] * 0.38,
						t.accent[3] * 0.38,
						0.55);
					if btn.dot then
						btn.dot:SetVertexColor(
							t.accent[1] * 0.48,
							t.accent[2] * 0.48,
							t.accent[3] * 0.48,
							0.65);
					end
					if btn.labelFS then
						btn.labelFS:SetTextColor(0.48, 0.48, 0.48);
					end
				end
			end
		end
	end
end

-- ──────────────────────────────────────────────────────────
-- PUBLIC API
-- ──────────────────────────────────────────────────────────

--- Register frame references from OptionsPanel after it's built.
-- @param data table: {mainFrame, titleBox, tabBar, tabs, tabPanels, themeButtons}
function K.RegisterThemeFrames(data)
	frameRegistry = data;
end

--- Apply a named theme and persist the choice.
function K.ApplyPanelTheme(themeName)
	local theme = THEMES[themeName] or THEMES["Classic"];
	activeTheme = theme;

	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB.PanelTheme = theme.id;

	ApplyThemeToFrames(theme);
end

--- Returns the currently active theme table (used by OptionsPanel's SelectTab).
function K.GetActiveTheme()
	return activeTheme;
end

--- Returns THEMES table and order array (used by OptionsPanel to build buttons).
function K.GetPanelThemes()
	return THEMES, THEME_ORDER;
end

--- Load the saved theme. Called by OptionsPanel after the panel is built.
function K.LoadSavedTheme()
	local saved = (NidhausUnitFramesDB and NidhausUnitFramesDB.PanelTheme) or "ArcaneBlue";
	local theme = THEMES[saved] or THEMES["ArcaneBlue"];
	activeTheme = theme;
	ApplyThemeToFrames(theme);
end