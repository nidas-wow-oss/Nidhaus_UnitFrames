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

-- enabled     = el MODULO, que ahora es solo el boton del minimapa.
-- forceHidden = lo que decidio ese boton. Es un interruptor aparte del modo:
--               "escondelos ahora", sin importar que diga la configuracion.
--
-- El motor de mostrar y ocultar YA NO depende del modulo: lo maneja el modo
-- (Siempre / Con el mouse / Nunca) y corre este el boton puesto o no.
local enabled     = false;
local forceHidden = false;
local toggleBtn;

-- Declarados aca arriba a proposito: el arranque los reinicia y esta ANTES
-- del frame de repesca en el archivo. Declarados alla abajo se compilaban
-- como globales.
local retryAcc, retryCount = 0, 0;

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

-- ---------------------------------------------------------
-- SOLO AL PASAR EL MOUSE
--
-- Los iconos son HIJOS del minimapa, asi que colgarse de su OnLeave no
-- sirve: apenas el cursor entra en un icono el minimapa recibe OnLeave,
-- todo se esconde, y el icono que ibas a apretar desaparece justo debajo
-- del cursor. Por eso se consulta la posicion del mouse en un OnUpdate y
-- cuenta como "encima" tanto el minimapa (con margen, que muchos iconos
-- viven en el borde o un poco afuera) como cualquier icono suelto.
--
-- Cinco veces por segundo alcanza de sobra para esto y no se nota.
-- ---------------------------------------------------------
local hoverOver     = false;   -- lo que dice el mouse ahora
local hoverTargets  = nil;     -- cache de iconos, para no recolectar en cada tick
local HOVER_MARGIN  = 24;

-- Un solo estado de tres valores en vez de dos casillas sueltas que se
-- contradecian. Todo lo que decide cuando se ven los iconos vive aca.
local function Mode()
	local m = C.MinimapAddonIcons;
	if m == "Never" or m == "Hover" then return m; end
	return "Always";
end

local function HoverMode()
	return Mode() == "Hover";
end

-- El boton solo puede ESCONDER, nunca revelar: asi quiere decir lo mismo en
-- los tres modos y no hay que adivinar que hace segun cual este puesto. Con
-- "Nunca" no tiene nada que hacer, y esta bien que asi sea.
local function DesiredVisible()
	if Mode() == "Never" then return false; end
	if forceHidden then return false; end
	if HoverMode() then return hoverOver; end
	return true;
end

local function ApplyState()
	if not DesiredVisible() then
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

	-- El icono del boton refleja el interruptor MANUAL, no lo que el mouse
	-- este haciendo en este instante: si no, parpadearia al pasar por encima.
	if toggleBtn then
		if forceHidden then
			toggleBtn.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up");
		else
			toggleBtn.icon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up");
		end
	end
end

local function MouseIsNearMinimap()
	if not Minimap then return false; end
	if MouseIsOver(Minimap, HOVER_MARGIN, -HOVER_MARGIN, -HOVER_MARGIN, HOVER_MARGIN) then
		return true;
	end
	-- Los que quedan mas lejos del borde se preguntan uno por uno. Solo los
	-- visibles: sobre un icono escondido no se puede tener el cursor.
	if hoverTargets then
		for _, f in ipairs(hoverTargets) do
			if f.IsShown and f:IsShown() and MouseIsOver(f) then return true; end
		end
	end
	return false;
end

local hoverDriver = CreateFrame("Frame");
local hoverAcc = 0;
hoverDriver:Hide();
hoverDriver:SetScript("OnUpdate", function(self, elapsed)
	hoverAcc = hoverAcc + elapsed;
	if hoverAcc < 0.2 then return; end
	hoverAcc = 0;

	local over = MouseIsNearMinimap();
	if over ~= hoverOver then
		hoverOver = over;
		if over then hoverTargets = CollectTargets(); end
		ApplyState();
	end
end);

-- La llama el desplegable del panel, y tambien MinimapStyle. Ya no exige
-- que el modulo del boton este prendido: el modo manda solo.
function K.ApplyMinimapIconState()
	if HoverMode() then
		hoverTargets = CollectTargets();
		hoverOver = MouseIsNearMinimap();
		hoverDriver:Show();
	else
		hoverDriver:Hide();
		hoverOver = false;
	end
	ApplyState();
end

-- Nombres viejos, por si algo los llama: MinimapStyle tenia el suyo y el
-- panel llamaba al de hover.
K.ApplyMinimapAddonIcons  = function() K.ApplyMinimapIconState(); end
K.ApplyMinimapIconsOnHover = function() K.ApplyMinimapIconState(); end

-- El motor arranca con el addon, no con el modulo.
local bootstrap = CreateFrame("Frame");
bootstrap:RegisterEvent("PLAYER_ENTERING_WORLD");
bootstrap:SetScript("OnEvent", function()
	forceHidden = DB().hidden and true or false;
	K.ApplyMinimapIconState();
	retryAcc, retryCount = 0, 0;
	retry:Show();
end);

local function SetHidden(state)
	forceHidden = state and true or false;
	DB().hidden = forceHidden;
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
		SetHidden(not forceHidden);
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
retry:Hide();
retry:SetScript("OnUpdate", function(self, elapsed)
	retryAcc = retryAcc + elapsed;
	if retryAcc < 1 then return; end
	retryAcc = 0;
	retryCount = retryCount + 1;
	-- Los addons cuelgan sus iconos tarde, asi que se vuelve a aplicar unas
	-- veces mas. Ya no se pregunta por el modulo: el modo corre igual.
	ApplyState();
	if retryCount >= 5 then self:Hide(); end
end);

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function()
	if not enabled then return; end
	CreateToggleButton();
	if toggleBtn then toggleBtn:Show(); end
end);

SLASH_NUFMINIMAP1 = "/nufminimap";
SlashCmdList["NUFMINIMAP"] = function()
	if not enabled then
		print("|cff4FC3F7NUF:|r " .. (L["MINIMAP_TOGGLE_DISABLED"]
			or "Enable the Minimap Icon Toggle module first."));
		return;
	end
	SetHidden(not forceHidden);
end

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
K.RegisterModule("MinimapIconToggle", {
	name    = L["MOD_MINIMAP_TOGGLE"] or "Minimap Icon Toggle",
	desc    = L["MOD_MINIMAP_TOGGLE_DESC"] or "Button on the minimap corner that hides or shows every minimap icon.",
	default = false,
	configLabel = L["BTN_MODULE_TOGGLE"] or "Toggle",
	configFunc = function() SetHidden(not forceHidden); end,
	-- El modulo es SOLO el boton. Prenderlo o apagarlo no toca los iconos:
	-- de eso se encarga el modo, que vive aparte y corre siempre.
	onEnable = function()
		enabled = true;
		CreateToggleButton();
		if toggleBtn then toggleBtn:Show(); end
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		if toggleBtn then toggleBtn:Hide(); end
		-- Si se va el boton, se va con el lo que el boton habia escondido:
		-- si no, quedarian iconos ocultos sin nada con que recuperarlos.
		if forceHidden then SetHidden(false); end
	end,
});
