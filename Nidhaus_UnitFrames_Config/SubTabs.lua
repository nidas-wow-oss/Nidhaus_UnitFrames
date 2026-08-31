-- Este archivo vive en Nidhaus_UnitFrames_Config, un addon aparte que se
-- carga SOLO cuando abris el panel (LoadOnDemand). Por eso no recibe el
-- namespace por "...", que es privado de cada addon: lo toma de la global
-- que publica el addon principal en Core/Init.lua.
local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

-- =========================================================
-- SubTabs.lua
-- Sistema reutilizable de subpestanas para los paneles de opciones.
--
-- Uso:
--   local sub = K.CreateSubTabs(panel, { "Frames", "Timers", "Modulos" });
--   -- sub[1], sub[2], sub[3] son los scrollChild donde colgar el contenido
--   -- sub.SetContentHeight(1, 700)  -> define el alto scrolleable de cada uno
--   -- sub.Select(2)                 -> cambiar de subpestana por codigo
--
-- Cada subpestana tiene su propio ScrollFrame, asi que el contenido puede
-- ser mas alto que el panel sin problema.
-- =========================================================

local BAR_HEIGHT   = 22;
local BAR_TOP      = -6;
local TAB_GAP      = 3;

local subTabCounter = 0;

local function StyleTabButton(btn, selected)
	if selected then
		btn:SetBackdropColor(0.10, 0.35, 0.60, 0.90);
		btn:SetBackdropBorderColor(0.35, 0.70, 1.00, 0.95);
		btn.labelFS:SetTextColor(1, 1, 1);
	else
		btn:SetBackdropColor(0.06, 0.06, 0.06, 0.60);
		btn:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.55);
		btn.labelFS:SetTextColor(0.58, 0.58, 0.58);
	end
end

function K.CreateSubTabs(panel, names)
	if not panel or not names or #names == 0 then return nil; end

	subTabCounter = subTabCounter + 1;
	local prefix = "NidhausSubTab" .. subTabCounter .. "_";

	local result   = {};
	local buttons  = {};
	local panes    = {};
	local selected = 1;

	-- ── Barra de botones ──────────────────────────────────
	local bar = CreateFrame("Frame", prefix .. "Bar", panel);
	bar:SetPoint("TOPLEFT",  6, BAR_TOP);
	bar:SetPoint("TOPRIGHT", -6, BAR_TOP);
	bar:SetHeight(BAR_HEIGHT);

	local count    = #names;
	local barWidth = (panel:GetWidth() or 640) - 12;
	local btnWidth = (barWidth - (TAB_GAP * (count - 1))) / count;

	local function Select(index)
		if not panes[index] then return; end
		selected = index;
		for i = 1, count do
			if i == index then
				panes[i].scrollFrame:Show();
			else
				panes[i].scrollFrame:Hide();
			end
			StyleTabButton(buttons[i], i == index);
		end
	end

	for i, name in ipairs(names) do
		-- Boton
		local btn = CreateFrame("Button", prefix .. "Btn" .. i, bar);
		btn:SetSize(btnWidth, BAR_HEIGHT);
		if i == 1 then
			btn:SetPoint("LEFT", bar, "LEFT", 0, 0);
		else
			btn:SetPoint("LEFT", buttons[i - 1], "RIGHT", TAB_GAP, 0);
		end
		btn:SetBackdrop({
			bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile     = true, tileSize = 16, edgeSize = 10,
			insets   = { left = 3, right = 3, top = 3, bottom = 3 },
		});

		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		fs:SetPoint("CENTER", btn, "CENTER", 0, 0);
		fs:SetText(name);
		btn.labelFS = fs;

		btn:SetScript("OnClick", function() Select(i); end);
		buttons[i] = btn;

		-- Panel scrolleable
		local scrollFrame = CreateFrame("ScrollFrame", prefix .. "Scroll" .. i,
			panel, "UIPanelScrollFrameTemplate");
		scrollFrame:SetPoint("TOPLEFT",     4, BAR_TOP - BAR_HEIGHT - 4);
		scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4);
		scrollFrame:Hide();

		local scrollChild = CreateFrame("Frame", prefix .. "Child" .. i, scrollFrame);
		scrollChild:SetWidth(600);
		scrollChild:SetHeight(1);
		scrollFrame:SetScrollChild(scrollChild);

		scrollChild.scrollFrame = scrollFrame;
		panes[i] = scrollChild;
		result[i] = scrollChild;
	end

	result.Select = Select;
	result.buttons = buttons;
	result.count = count;

	-- Define el alto scrolleable de una subpestana.
	-- Aceptamos un Y negativo (el ultimo yPos usado) o un alto positivo.
	result.SetContentHeight = function(index, value)
		local pane = panes[index];
		if not pane then return; end
		local h = math.abs(value or 0) + 40;
		if h < 60 then h = 60; end
		pane:SetHeight(h);
	end

	Select(1);
	return result;
end
