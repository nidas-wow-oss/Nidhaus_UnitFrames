local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- MinimapButton.lua - Icono en el minimapa para abrir el panel de opciones
--
-- Click izquierdo: Abre/cierra el panel de opciones
-- Click derecho: Toggle Arena Mover
-- Ctrl+Click: Modo "mover todo" (GlobalUnlock, el mismo de /move)
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
	local rads = math_rad(angle);
	local cos, sin = math_cos(rads), math_sin(rads);
	local x, y;

	if C and C.MinimapSquare then
		-- MAPA CUADRADO: seguir el PERIMETRO, no una circunferencia.
		-- Con el radio fijo de 80 el icono describia un circulo y en las
		-- diagonales se metia adentro del mapa, mientras que arriba y a los
		-- costados quedaba flotando afuera.
		--
		-- Se proyecta el angulo sobre el cuadrado escalando por la
		-- componente mas grande: asi el punto siempre cae sobre un borde.
		local half = (Minimap:GetWidth() or 140) / 2 + 8;
		local m = math.max(math.abs(cos), math.abs(sin));
		if m < 0.0001 then m = 1; end
		x = (cos / m) * half;
		y = (sin / m) * half;
	else
		local radius = 80;
		x = cos * radius;
		y = sin * radius;
	end

	button:ClearAllPoints();
	button:SetPoint("CENTER", Minimap, "CENTER", x, y);
end
K.UpdateMinimapButtonPosition = function()
	UpdatePosition(GetSavedAngle());
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
		GameTooltip:AddLine(L["MINIMAP_CTRL_CLICK"]
			or "|cffFFFFFFCtrl + Click:|r Move Everything", 0.8, 0.8, 0.8);
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
			elseif IsControlKeyDown() then
				-- Mismo modo que /move: overlay arrastrable sobre todo lo movible.
				if K.ToggleGlobalUnlock then
					K.ToggleGlobalUnlock("all");
				end
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

	-- El boton se crea en PLAYER_LOGIN, a veces DESPUES de que el barrido de
	-- "ocultar iconos de addon" ya paso, y por eso quedaba visible. Reaplicamos
	-- el ocultado ahora que el boton ya existe: asi tambien se esconde (y se
	-- puede reabrir el panel con /nuf).
	if K.ApplyMinimapAddonIcons then K.ApplyMinimapAddonIcons(); end
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		CreateMinimapButton();
	end
end);
