local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- MinimapButton.lua - Icono en el minimapa para abrir el panel de opciones
--
-- Click izquierdo: Abre/cierra el panel de opciones
-- Click derecho: Toggle Arena Mover
-- Shift+Click: /reload
-- Arrastrar: Mover alrededor del minimapa

local math_sqrt, math_atan2, math_sin, math_cos, math_deg, math_rad =
	math.sqrt, math.atan2, math.sin, math.cos, math.deg, math.rad;

local ICON_TEXTURE = "Interface\\Icons\\Spell_Holy_AuraOfLight";
local BUTTON_SIZE = 31;
local DEFAULT_ANGLE = 220;

local button;
local isDragging = false;

local function GetSavedAngle()
	if NidhausUnitFramesDB and NidhausUnitFramesDB.MinimapButtonAngle then
		return NidhausUnitFramesDB.MinimapButtonAngle;
	end
	return DEFAULT_ANGLE;
end

local function SaveAngle(angle)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB.MinimapButtonAngle = angle;
end

local function UpdatePosition(angle)
	local radius = 80;
	local rads = math_rad(angle);
	local x = math_cos(rads) * radius;
	local y = math_sin(rads) * radius;
	button:ClearAllPoints();
	button:SetPoint("CENTER", Minimap, "CENTER", x, y);
end

local function GetAngleFromCursor()
	local mx, my = Minimap:GetCenter();
	local cx, cy = GetCursorPosition();
	local scale = Minimap:GetEffectiveScale();
	cx, cy = cx / scale, cy / scale;
	return math_deg(math_atan2(cy - my, cx - mx));
end

local function CreateMinimapButton()
	if button then return; end

	button = CreateFrame("Button", "NidhausUF_MinimapButton", Minimap);
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE);
	button:SetFrameStrata("MEDIUM");
	button:SetFrameLevel(8);
	button:SetMovable(true);
	button:SetClampedToScreen(true);
	button:RegisterForDrag("LeftButton");
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight");

	local overlay = button:CreateTexture(nil, "OVERLAY");
	overlay:SetSize(53, 53);
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");
	overlay:SetPoint("TOPLEFT", 0, 0);

	local icon = button:CreateTexture(nil, "BACKGROUND");
	icon:SetSize(20, 20);
	icon:SetTexture(ICON_TEXTURE);
	icon:SetPoint("CENTER", 0, 1);
	button.icon = icon;

	UpdatePosition(GetSavedAngle());

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(L["MINIMAP_TITLE"], 1, 1, 1);
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(L["MINIMAP_LEFT_CLICK"], 0.8, 0.8, 0.8);
		GameTooltip:AddLine(L["MINIMAP_RIGHT_CLICK"], 0.8, 0.8, 0.8);
		GameTooltip:AddLine(L["MINIMAP_SHIFT_CLICK"], 0.8, 0.8, 0.8);
		GameTooltip:AddLine(L["MINIMAP_DRAG"], 0.8, 0.8, 0.8);
		GameTooltip:Show();
	end);

	button:SetScript("OnLeave", function()
		GameTooltip:Hide();
	end);

	button:SetScript("OnClick", function(self, btn)
		if btn == "LeftButton" then
			if IsShiftKeyDown() then
				ReloadUI();
			else
				if K.ToggleOptionsPanel then K.ToggleOptionsPanel(); end
			end
		elseif btn == "RightButton" then
			if K.ToggleArenaFramesMover then K.ToggleArenaFramesMover(); end
		end
	end);

	button:SetScript("OnDragStart", function(self)
		isDragging = true;
		self:SetScript("OnUpdate", function()
			local angle = GetAngleFromCursor();
			UpdatePosition(angle);
			SaveAngle(angle);
		end);
		GameTooltip:Hide();
	end);

	button:SetScript("OnDragStop", function(self)
		isDragging = false;
		self:SetScript("OnUpdate", nil);
	end);
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		CreateMinimapButton();
	end
end);
