local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- MinimapIconToggle.lua
-- Boton chiquito en la esquina superior del minimapa que oculta
-- o muestra TODOS los iconos: zoom, reloj, tracking, calendario,
-- correo, y los iconos que cuelgan los addons.
--
-- El estado se guarda, asi que se mantiene entre sesiones.
-- =========================================================

local enabled  = false;
local hidden   = false;
local toggleBtn;

-- Cosas del cluster que NO hay que tocar nunca.
-- Ojo con la flecha del jugador y el borde del minimapa: si se tocan,
-- al volver a mostrar queda un aro dorado raro alrededor del personaje.
local PROTECTED = {
	["Minimap"]                = true,
	["MinimapBackdrop"]        = true,
	["MinimapCluster"]         = true,
	["MinimapBorder"]          = true,
	["MinimapBorderTop"]       = true,
	["MinimapNorthTag"]        = true,
	["MinimapCompassTexture"]  = true,
	["NUF_MinimapIconToggle"]  = true,
	-- El borde del modo cuadrado. Es parte del MAPA, no un icono: al
	-- ocultarlo con los demas el minimapa quedaba sin contorno, flotando
	-- sobre el mundo, y al volver a mostrarlos ya no coincidia con nada.
	["NUF_MinimapSquareBorder"] = true,
	-- El reloj: siempre visible.
	["TimeManagerClockButton"]  = true,
	["TimeManagerClockTicker"]  = true,
	-- Y el boton del propio NUF. Si se ocultara junto con los demas, el
	-- unico acceso rapido al panel desaparece — y para recuperarlo habria
	-- que acordarse del comando.
	["NidhausUF_MinimapButton"] = true,
	-- Blizzard maneja la visibilidad de estos segun el estado del juego.
	-- Si los mostramos nosotros aparecen sin motivo (correo sin correo, etc.)
	["MiniMapMailFrame"]           = true,
	["MiniMapMailBorder"]          = true,
	["MiniMapVoiceChatFrame"]      = true,
	["MiniMapBattlefieldFrame"]    = true,
	["MiniMapLFGFrame"]            = true,
	["MiniMapInstanceDifficulty"]  = true,
	["MinimapZoneTextButton"]      = true,
	-- El boton de RASTREO (la lupa: buscar entrenadores, minerales, herbolaria...)
	-- es una funcion del juego, no un icono de addon. Antes se ocultaba junto
	-- con los demas y quedaba enterrado, sin forma de volver a sacarlo.
	["MiniMapTrackingFrame"]       = true,
	["MiniMapTracking"]            = true,
	["MiniMapTrackingButton"]      = true,
	["MiniMapTrackingIcon"]        = true,
	["MiniMapTrackingBorder"]      = true,
	["MiniMapTrackingButtonBorder"]= true,
	["MiniMapTrackingBackground"]  = true,
};

-- Iconos "fijos" de Blizzard que colgan del cluster o del minimapa
--
-- El RELOJ no esta aca: se mira todo el tiempo y ocultarlo con los iconos
-- de addons no tiene sentido. Ademas, quien quiera sacarlo tiene el
-- checkbox propio en Interfaz > Minimapa, que es donde corresponde.
local BLIZZ_ICONS = {
	"MinimapZoomIn", "MinimapZoomOut",
	"GameTimeFrame",
	"FeedbackUIButton",
	-- El mapa del mundo si se oculta: tiene tecla propia (M), asi que
	-- perder el boton no te deja sin forma de abrirlo.
	"MiniMapWorldMapButton",
};

local savedShown = {};

-- ---------------------------------------------------------
-- DB
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.MinimapIcons then
		NidhausUnitFramesDB.MinimapIcons = {};
	end
	return NidhausUnitFramesDB.MinimapIcons;
end

-- ---------------------------------------------------------
-- Recolectar todo lo ocultable
-- ---------------------------------------------------------
local function CollectTargets()
	local list = {};

	for _, name in ipairs(BLIZZ_ICONS) do
		local f = _G[name];
		if f and f.Hide and not PROTECTED[name] then
			table.insert(list, f);
		end
	end

	-- Iconos de addons: normalmente son hijos del Minimap
	if Minimap then
		for _, child in ipairs({ Minimap:GetChildren() }) do
			local n = child.GetName and child:GetName();
			if not (n and PROTECTED[n]) and child ~= toggleBtn then
				table.insert(list, child);
			end
		end
	end

	-- Algunos cuelgan del cluster
	if MinimapCluster then
		for _, child in ipairs({ MinimapCluster:GetChildren() }) do
			local n = child.GetName and child:GetName();
			if not (n and PROTECTED[n]) and child ~= Minimap and child ~= toggleBtn then
				table.insert(list, child);
			end
		end
	end

	return list;
end

local function ApplyState()
	if hidden then
		-- Ocultar: guardamos SOLO los que estaban visibles.
		-- Los que ya estaban ocultos (correo sin correo, voice chat apagado,
		-- battlefield sin cola) ni los tocamos, asi no reaparecen despues.
		local targets = CollectTargets();
		for _, f in ipairs(targets) do
			if f:IsShown() and savedShown[f] == nil then
				savedShown[f] = true;
				f:Hide();
			end
		end
	else
		-- Mostrar: SOLO lo que nosotros ocultamos. No volvemos a recolectar,
		-- porque eso hacia aparecer iconos que Blizzard tenia ocultos a proposito.
		for f in pairs(savedShown) do
			if f.Show then f:Show(); end
		end
		wipe(savedShown);
	end

	if toggleBtn then
		if hidden then
			toggleBtn.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up");
		else
			toggleBtn.icon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up");
		end
	end
end

local function SetHidden(state)
	hidden = state and true or false;
	DB().hidden = hidden;
	ApplyState();
end

-- ---------------------------------------------------------
-- Boton
-- ---------------------------------------------------------
local function CreateToggleButton()
	if toggleBtn then return toggleBtn; end
	if not Minimap then return nil; end

	toggleBtn = CreateFrame("Button", "NUF_MinimapIconToggle", Minimap);
	toggleBtn:SetSize(16, 16);

	-- Fuera del minimapa, pegado al borde IZQUIERDO y arriba.
	--
	-- Estaba en la esquina superior derecha, que es justo donde el juego
	-- pone el calendario y (en modo cuadrado) el mapa del mundo: los tres
	-- encimados. Ese lado esta siempre ocupado; el izquierdo de arriba no.
	--
	-- Ademas va POR FUERA del mapa (offset negativo en x) para no taparlo.
	-- y = +4 y no 0: en modo cuadrado el boton de RASTREO va sobre el borde
	-- izquierdo, centrado 38px por debajo del centro, o sea unos 16 por
	-- debajo del techo. Con el toggle a ras del techo se rozaban.
	toggleBtn:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -4, 4);
	toggleBtn:SetFrameStrata("MEDIUM");
	toggleBtn:SetFrameLevel(Minimap:GetFrameLevel() + 10);

	toggleBtn.bg = toggleBtn:CreateTexture(nil, "BACKGROUND");
	toggleBtn.bg:SetAllPoints();
	toggleBtn.bg:SetTexture(0, 0, 0, 0.55);

	toggleBtn.icon = toggleBtn:CreateTexture(nil, "ARTWORK");
	toggleBtn.icon:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0);
	toggleBtn.icon:SetSize(14, 14);
	toggleBtn.icon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up");

	toggleBtn:SetScript("OnClick", function()
		SetHidden(not hidden);
	end);

	toggleBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(L["MINIMAP_TOGGLE_TITLE"] or "Minimap Icons", 1, 1, 1);
		GameTooltip:AddLine(L["MINIMAP_TOGGLE_TIP"]
			or "Click to hide or show every minimap icon (zoom, clock, addons).",
			nil, nil, nil, true);
		GameTooltip:Show();
	end);
	toggleBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	return toggleBtn;
end

-- ---------------------------------------------------------
-- Eventos: los addons cuelgan sus iconos tarde
-- ---------------------------------------------------------
local retry = CreateFrame("Frame");
local retryAcc, retryCount = 0, 0;
retry:Hide();
retry:SetScript("OnUpdate", function(self, elapsed)
	retryAcc = retryAcc + elapsed;
	if retryAcc < 1 then return; end
	retryAcc = 0;
	retryCount = retryCount + 1;
	if enabled and hidden then ApplyState(); end
	if retryCount >= 5 then self:Hide(); end
end);

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function()
	if not enabled then return; end
	CreateToggleButton();
	hidden = DB().hidden and true or false;
	ApplyState();
	retryAcc, retryCount = 0, 0;
	retry:Show();
end);

SLASH_NUFMINIMAP1 = "/nufminimap";
SlashCmdList["NUFMINIMAP"] = function()
	if not enabled then
		print("|cff4FC3F7NUF:|r " .. (L["MINIMAP_TOGGLE_DISABLED"]
			or "Enable the Minimap Icon Toggle module first."));
		return;
	end
	SetHidden(not hidden);
end

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
K.RegisterModule("MinimapIconToggle", {
	name    = L["MOD_MINIMAP_TOGGLE"] or "Minimap Icon Toggle",
	desc    = L["MOD_MINIMAP_TOGGLE_DESC"] or "Button on the minimap corner that hides or shows every minimap icon.",
	default = false,
	configLabel = L["BTN_MODULE_TOGGLE"] or "Toggle",
	configFunc = function() SetHidden(not hidden); end,
	onEnable = function()
		enabled = true;
		CreateToggleButton();
		if toggleBtn then toggleBtn:Show(); end
		hidden = DB().hidden and true or false;
		ApplyState();
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
		retryAcc, retryCount = 0, 0;
		retry:Show();
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		retry:Hide();
		if hidden then
			hidden = false;
			ApplyState();
		end
		if toggleBtn then toggleBtn:Hide(); end
	end,
});
