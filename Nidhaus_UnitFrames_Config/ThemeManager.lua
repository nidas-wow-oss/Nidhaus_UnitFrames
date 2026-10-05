



local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);




















local THEMES = {};
local THEME_ORDER = {"Classic", "DarkGold", "ArcaneBlue"};















THEMES["Classic"] = {
	id    = "Classic",
	label = "Classic",
	accent = {1, 0.82, 0},


	frameBG        = "Interface\\DialogFrame\\UI-DialogBox-Background",
	frameBorder    = "Interface\\DialogFrame\\UI-DialogBox-Border",
	frameTileSize  = 32,
	frameEdgeSize  = 32,
	frameInsets    = {left=11, right=12, top=12, bottom=11},


	frameBGColor   = {1, 1, 1, 1},
	frameBorderColor = {1, 1, 1, 1},


	useNativeHeader  = true,
	titleBGColor     = {0.08, 0.08, 0.08, 1.0},
	titleBorderBG    = "Interface\\DialogFrame\\UI-DialogBox-Background",
	titleBorderEdge  = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
	titleBorderColor = {1, 1, 1, 1},







	tabBarBGColor     = {0, 0, 0, 0},
	tabBarBorderColor = {0, 0, 0, 0},
	tabSelBGColor     = {0, 0, 0, 0},
	tabSelBorderColor = {0, 0, 0, 0},
	tabBGColor        = {0, 0, 0, 0},
	tabBorderColor    = {0, 0, 0, 0},
	tabHoverBGColor   = {0, 0, 0, 0},







	panelBGColor      = {0.06, 0.06, 0.06, 0.85},
	panelBorderColor  = {1, 1, 1, 1},

	nativeTabs   = true,
	sideGoldText = true,
	sideSelColor = {0.10, 0.22, 0.42},
	footerAlpha  = 1.0,
};




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





local activeTheme  = THEMES["ArcaneBlue"];
local frameRegistry = {};





local function ApplyThemeToFrames(theme)
	local reg = frameRegistry;


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





	if reg.mainFrame then
		local headerTex = reg.mainFrame._titleHeaderTex;
		local titleBox  = reg.titleBox;
		if theme.useNativeHeader then

			if headerTex then headerTex:Show(); end
			if titleBox then
				titleBox:SetBackdropColor(0, 0, 0, 0);
				titleBox:SetBackdropBorderColor(0, 0, 0, 0);
			end
		else

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


	if reg.tabBar then
		reg.tabBar:SetBackdropColor(unpack(theme.tabBarBGColor));
		reg.tabBar:SetBackdropBorderColor(unpack(theme.tabBarBorderColor));
	end










	if reg.tabs then
		local useNative = theme.nativeTabs and true or false;
		for _, tab in ipairs(reg.tabs) do
			tab._nufTheme = theme;

			if not tab._nufHidden then
				if useNative and tab.native then
					tab:Hide();
					tab.native:Show();
				else
					if tab.native then tab.native:Hide(); end
					tab:Show();
				end
			end

			if tab.selected then
				tab:SetBackdropColor(unpack(theme.tabSelBGColor));
				tab:SetBackdropBorderColor(unpack(theme.tabSelBorderColor));
			else
				tab:SetBackdropColor(unpack(theme.tabBGColor));
				tab:SetBackdropBorderColor(unpack(theme.tabBorderColor));
			end
		end
	end


	if reg.tabPanels then
		for _, panel in ipairs(reg.tabPanels) do
			panel:SetBackdropColor(unpack(theme.panelBGColor));
			panel:SetBackdropBorderColor(unpack(theme.panelBorderColor));
		end
	end




	if K.RestyleSideLists then K.RestyleSideLists(); end






	if reg.secondaryButtons then
		local a = theme.footerAlpha or 0.75;
		for _, btn in ipairs(reg.secondaryButtons) do
			btn:SetAlpha(a);
		end
	end



	if K.RefreshPanelTabs then K.RefreshPanelTabs(); end


	if reg.themeButtons then
		for id, btn in pairs(reg.themeButtons) do
			local t = THEMES[id];
			if t then
				if id == theme.id then

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







function K.RegisterThemeFrames(data)
	frameRegistry = data;
end


function K.ApplyPanelTheme(themeName)
	local theme = THEMES[themeName] or THEMES["Classic"];
	activeTheme = theme;

	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB.PanelTheme = theme.id;

	ApplyThemeToFrames(theme);
end


function K.GetActiveTheme()
	return activeTheme;
end


function K.GetPanelThemes()
	return THEMES, THEME_ORDER;
end


function K.LoadSavedTheme()
	local saved = (NidhausUnitFramesDB and NidhausUnitFramesDB.PanelTheme) or "ArcaneBlue";
	local theme = THEMES[saved] or THEMES["ArcaneBlue"];
	activeTheme = theme;
	ApplyThemeToFrames(theme);
end