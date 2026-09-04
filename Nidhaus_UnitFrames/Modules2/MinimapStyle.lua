local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- MinimapStyle.lua
-- Estilo del minimapa: redondo (por defecto) o cuadrado, y
-- limpieza de los adornos que casi nadie usa (nombre de zona,
-- reloj, botones de zoom).
--
-- El cuadrado se logra cambiando la MASCARA del minimapa por una
-- textura solida: Blizzard recorta el mapa con esa mascara, asi
-- que con una textura rectangular el mapa deja de ser un circulo.
-- Despues hay que ocultar el aro dorado (MinimapBorder) y dibujar
-- un borde propio, si no queda el aro flotando sobre las esquinas.
--
-- Todo es reversible en caliente, sin /reload.
-- =========================================================

local ROUND_MASK  = "Interface\\CharacterFrame\\TempPortraitAlphaMask";
local SQUARE_MASK = "Interface\\ChatFrame\\ChatFrameBackground";

local squareBorder;

-- ---------------------------------------------------------
-- Borde propio para el modo cuadrado
-- ---------------------------------------------------------
local function GetSquareBorder()
	if squareBorder then return squareBorder; end
	if not Minimap then return nil; end

	squareBorder = CreateFrame("Frame", "NUF_MinimapSquareBorder", Minimap);
	squareBorder:SetPoint("TOPLEFT",     Minimap, "TOPLEFT",     -3,  3);
	squareBorder:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT",  3, -3);
	squareBorder:SetFrameLevel(Minimap:GetFrameLevel() + 2);

	-- Modo seguro: borde simple de tooltip (el de antes), sin las 4 texturas.
	if _G.NUF_SAFE then
		squareBorder:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 12,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		});
		squareBorder:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.9);
		squareBorder:Hide();
		return squareBorder;
	end

	-- Borde solido y GRUESO hecho con 4 lados (antes era el borde fino de
	-- tooltip). Mas robusto, como el de la referencia.
	local THICK = 3;
	local COLOR = { 0.04, 0.04, 0.04, 1 };   -- casi negro
	local function MakeEdge()
		local t = squareBorder:CreateTexture(nil, "BORDER");
		t:SetTexture("Interface\\Buttons\\WHITE8x8");
		t:SetVertexColor(unpack(COLOR));
		return t;
	end
	local top = MakeEdge();
	top:SetPoint("TOPLEFT", 0, 0);   top:SetPoint("TOPRIGHT", 0, 0);      top:SetHeight(THICK);
	local bottom = MakeEdge();
	bottom:SetPoint("BOTTOMLEFT", 0, 0); bottom:SetPoint("BOTTOMRIGHT", 0, 0); bottom:SetHeight(THICK);
	local left = MakeEdge();
	left:SetPoint("TOPLEFT", 0, 0);  left:SetPoint("BOTTOMLEFT", 0, 0);   left:SetWidth(THICK);
	local right = MakeEdge();
	right:SetPoint("TOPRIGHT", 0, 0); right:SetPoint("BOTTOMRIGHT", 0, 0); right:SetWidth(THICK);

	squareBorder:Hide();
	return squareBorder;
end

-- ---------------------------------------------------------
-- Forma del minimapa para los iconos de addons
-- LibDBIcon (y las librerias compatibles) consultan la global
-- GetMinimapShape para saber como acomodar sus iconos: con "SQUARE" los
-- pegan al borde del cuadrado en vez de repartirlos sobre un circulo.
-- La definimos segun el modo actual.
-- ---------------------------------------------------------
function GetMinimapShape()
	if _G.NUF_SAFE then return "ROUND"; end
	return (C and C.MinimapSquare) and "SQUARE" or "ROUND";
end

-- Empujon para que los iconos ya colgados se reacomoden al cambiar la forma
-- sin tener que recargar. Best-effort: los que usan LibDBIcon se mueven solos;
-- los que no, se acomodan en el proximo /reload.
function K.NudgeMinimapIcons()
	if _G.NUF_SAFE then return; end
	if not LibStub then return; end
	local ok, ldb = pcall(LibStub, "LibDBIcon-1.0", true);
	if ok and ldb and ldb.objects then
		for name in pairs(ldb.objects) do
			pcall(ldb.Refresh, ldb, name);
		end
	end
end

-- ---------------------------------------------------------
-- Botones propios de Blizzard en modo cuadrado
--
-- NudgeMinimapIcons (arriba) solo mueve los iconos de ADDONS: son los que
-- pasan por LibDBIcon y consultan GetMinimapShape. Los botones que trae el
-- juego — zoom + y -, mapa del mundo, calendario, rastreo, correo, cola de
-- battleground — no consultan nada: estan clavados con las coordenadas del
-- circulo que Blizzard escribio en MinimapFrame.xml. Por eso con el
-- minimapa cuadrado quedaban desparramados en arco, flotando fuera de las
-- esquinas.
--
-- Aca se los reancla a los bordes del cuadrado, y se los devuelve a su
-- lugar original al volver a redondo.
--
-- LA FOTO ORIGINAL SE SACA UNA SOLA VEZ, antes de tocar nada. Es la parte
-- que importa: si se recapturara en cada cambio de forma, la segunda vez
-- estariamos guardando como "original" la posicion cuadrada que pusimos
-- nosotros, y al volver a redondo los botones quedarian donde no van. Es
-- exactamente el error que ya nos mordio con las barras de accion y con
-- los movers de PartyBuffs.
-- ---------------------------------------------------------
local blizzOrig = nil;   -- nil = todavia no se saco la foto

-- De cada grupo se usa el PRIMERO que exista: los nombres cambian entre
-- versiones del cliente y no todos estan siempre presentes.
local function Pick(...)
	for i = 1, select("#", ...) do
		local f = _G[(select(i, ...))];
		if f and f.SetPoint and f.GetPoint then return f; end
	end
	return nil;
end

-- Donde va cada uno en el cuadrado. El punto del boton es su CENTRO, asi
-- que cae justo montado sobre la esquina o el borde del mapa.
local function SquareLayout()
	return {
		{ f = Pick("MiniMapWorldMapButton"),
		  point = "CENTER", rel = "TOPRIGHT",    x = -2, y = -2 },


		-- Borde derecho, de arriba hacia abajo: mapa del mundo (en la
		-- esquina), calendario, zoom + y zoom -. Van separados 28px, que
		-- es un poco mas que el ancho del boton, asi no se tocan.
		{ f = Pick("GameTimeFrame"),
		  point = "CENTER", rel = "RIGHT",       x = -2, y =  38 },
		{ f = Pick("MinimapZoomIn"),
		  point = "CENTER", rel = "RIGHT",       x = -2, y =  10 },
		{ f = Pick("MinimapZoomOut"),
		  point = "CENTER", rel = "RIGHT",       x = -2, y = -18 },

		-- Borde izquierdo, espejo del derecho: rastreo, correo y buscador
		-- de grupo con la misma separacion, y la cola de battleground en
		-- la esquina de abajo.
		{ f = Pick("MiniMapTrackingFrame", "MiniMapTracking", "MiniMapTrackingButton"),
		  point = "CENTER", rel = "LEFT",        x =  2, y =  38 },
		{ f = Pick("MiniMapMailFrame"),
		  point = "CENTER", rel = "LEFT",        x =  2, y =  10 },
		{ f = Pick("MiniMapLFGFrame", "MiniMapMeetingStoneButton"),
		  point = "CENTER", rel = "LEFT",        x =  2, y = -18 },
		{ f = Pick("MiniMapBattlefieldFrame"),
		  point = "CENTER", rel = "BOTTOMLEFT",  x =  2, y =  2 },
	};
end

local function CaptureBlizzOrig()
	if blizzOrig then return; end        -- ya esta sacada, no repetir
	blizzOrig = {};
	for _, e in ipairs(SquareLayout()) do
		if e.f then
			local point, relTo, relPoint, x, y = e.f:GetPoint(1);
			if point then
				blizzOrig[e.f] = {
					point = point, relTo = relTo, relPoint = relPoint,
					x = x or 0, y = y or 0,
					-- el nivel tambien: en cuadrado lo subimos, y al
					-- volver a redondo tiene que quedar como estaba.
					level = e.f.GetFrameLevel and e.f:GetFrameLevel() or nil,
				};
			end
		end
	end
end

function K.ApplyMinimapButtonLayout()
	if _G.NUF_SAFE or not Minimap then return; end
	CaptureBlizzOrig();

	if C.MinimapSquare then
		-- El marco cuadrado (NUF_MinimapSquareBorder) se dibuja a nivel
		-- Minimap+2 y cubre todo el area, asi que los botones apoyados en
		-- el borde quedaban DEBAJO de el — se veia cortado el de la cola de
		-- battleground. Se los sube por encima.
		local lvl = (Minimap:GetFrameLevel() or 1) + 4;
		for _, e in ipairs(SquareLayout()) do
			if e.f then
				e.f:ClearAllPoints();
				e.f:SetPoint(e.point, Minimap, e.rel, e.x, e.y);
				if e.f.SetFrameLevel then pcall(e.f.SetFrameLevel, e.f, lvl); end
			end
		end
	else
		for f, o in pairs(blizzOrig) do
			f:ClearAllPoints();
			-- relTo puede haber desaparecido; UIParent como red de seguridad.
			f:SetPoint(o.point, o.relTo or Minimap or UIParent, o.relPoint, o.x, o.y);
			if o.level and f.SetFrameLevel then pcall(f.SetFrameLevel, f, o.level); end
		end
	end
end

-- ---------------------------------------------------------
-- ESTILOS DE BORDE
--
-- Cinco opciones, excluyentes entre si (es un solo borde alrededor de un
-- solo mapa):
--
--   Default   lo de siempre: el aro dorado de Blizzard en redondo, y el
--             borde cuadrado propio de NUF en cuadrado.
--   Light     el marco fino (mira mas abajo). Solo en cuadrado.
--   Tooltip / Thin / Flat / Blizzard
--             portados de MiniMapster. Cada uno viene en dos versiones,
--             round y square, asi que funcionan con las dos formas.
--
-- Los cuatro ultimos usan la tecnica de Chinchilla que copia MiniMapster:
-- una imagen de 256x256 partida en cuatro cuadrantes, cada uno anclado a
-- una esquina del centro del mapa. Asi el borde acompaña el tamaño del
-- minimapa sin deformarse.
local BORDER_DIR = "Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\Minimap\\borders\\";
local CORNER_STYLES = {
	Tooltip = true, Thin = true, Flat = true, Blizzard = true,
};

-- Que estilo esta puesto.
local function BorderStyle()
	local s = C.MinimapBorderStyle;
	if s == nil or s == "" then s = "Default"; end
	return s;
end
K.GetMinimapBorderStyle = BorderStyle;

local corners;

local function GetCorners()
	if corners then return corners; end
	local parent = MinimapBackdrop or Minimap;
	if not parent or not Minimap then return nil; end

	corners = {};
	for i = 1, 4 do
		corners[i] = parent:CreateTexture("NUF_MinimapCorner" .. i, "ARTWORK");
		corners[i]:Hide();
	end
	-- Cada textura toma un cuarto de la imagen y se ancla al centro del
	-- mapa por la esquina que le toca.
	corners[1]:SetPoint("BOTTOMRIGHT", Minimap, "CENTER"); corners[1]:SetTexCoord(0,   0.5, 0,   0.5);
	corners[2]:SetPoint("BOTTOMLEFT",  Minimap, "CENTER"); corners[2]:SetTexCoord(0.5, 1,   0,   0.5);
	corners[3]:SetPoint("TOPRIGHT",    Minimap, "CENTER"); corners[3]:SetTexCoord(0,   0.5, 0.5, 1);
	corners[4]:SetPoint("TOPLEFT",     Minimap, "CENTER"); corners[4]:SetTexCoord(0.5, 1,   0.5, 1);
	return corners;
end

-- Light Border
--
-- Marco fino y limpio alrededor del mapa: un backdrop de edgeSize 14
-- anclado 4 px por fuera del mapa, con el filo en blanco.
--
-- La textura es Media/Border/Border_Light.tga, dibujada por
-- Tools/mkborders.py igual que las de FrameBorders: un hilo de un pixel
-- con caida suave y esquinas redondeadas, generado por geometria.
--
-- REEMPLAZA AL BORDE CUADRADO, no se suma.
--
-- Ese fue el motivo de que no se viera: los dos rodean exactamente el
-- mismo perimetro, y el cuadrado se dibuja en un nivel mas alto (+2), asi
-- que le pasaba por encima y tapaba este por completo. Prendido este, el
-- otro se apaga.
-- ---------------------------------------------------------
local thinBorder;

local function GetThinBorder()
	if thinBorder then return thinBorder; end
	if not Minimap then return nil; end

	thinBorder = CreateFrame("Frame", "NUF_MinimapThinBorder", Minimap);
	thinBorder:SetBackdrop({
		edgeFile = "Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\Border\\Border_Light",
		edgeSize = 14,
		insets = { left = 2.5, right = 2.5, top = 2.5, bottom = 2.5 },
	});
	thinBorder:SetBackdropBorderColor(1, 1, 1, 1);
	thinBorder:Hide();
	return thinBorder;
end

function K.ApplyMinimapBorderStyle()
	local style = BorderStyle();
	local cs = GetCorners();

	-- SE APAGA TODO PRIMERO.
	--
	-- Son excluyentes: sin este barrido, cambiar de estilo dejaba el
	-- anterior dibujado abajo del nuevo.
	if cs then for _, tx in ipairs(cs) do tx:Hide(); end end

	if CORNER_STYLES[style] and cs and Minimap then
		local tb = GetThinBorder(); if tb then tb:Hide(); end
		if squareBorder then squareBorder:Hide(); end
		-- El aro de Blizzard estorba: estos estilos traen el suyo.
		if MinimapBorder then MinimapBorder:Hide(); end
		if MinimapBorderTop then MinimapBorderTop:Hide(); end

		local shape = C.MinimapSquare and "square\\" or "round\\";
		-- La imagen esta dibujada para un mapa de 140: 70 de mapa + 10 de
		-- borde por cuadrante. Se mantiene esa proporcion para que ande
		-- igual si el minimapa cambia de tamaño.
		local size = (Minimap:GetWidth() / 2) * (80 / 70);
		for _, tx in ipairs(cs) do
			tx:SetTexture(BORDER_DIR .. shape .. style);
			tx:SetSize(size, size);
			tx:SetVertexColor(1, 1, 1, 1);
			tx:Show();
		end
		return;
	end

	local b = GetThinBorder();
	if not b then return; end

	if style ~= "Light" then b:Hide(); return; end

	-- SOLO EN MODO CUADRADO.
	--
	-- Es un marco cuadrado: sobre el mapa redondo queda un cuadro alrededor
	-- de un circulo, con el aro dorado de Blizzard en el medio de los dos.
	-- Se probo y no va.
	if not C.MinimapSquare then b:Hide(); return; end

	-- Y NO junto con el minimapa de Lorti UI: ese modo trae su propio
	-- marco, asi que los dos prendidos se encimaban.
	if C.LortiUI_Minimap == true then b:Hide(); return; end

	b:ClearAllPoints();
	b:SetPoint("TOPLEFT",     Minimap, "TOPLEFT",     -4,  4);
	b:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT",  4, -4);

	-- NIVEL: uno arriba del mapa, y nada mas.
	--
	-- Con +10 (como estaba al principio) tapaba los iconos de addons, que
	-- viven en el perimetro del mapa. Con 0 quedaba debajo del borde
	-- cuadrado y no se veia. +1 lo deja visible sobre el mapa y por debajo
	-- de los iconos, que se cuelgan bastante mas arriba.
	b:SetFrameLevel(math.max(0, (Minimap:GetFrameLevel() or 0)) + 1);
	b:Show();
end

-- ---------------------------------------------------------
-- Forma
-- ---------------------------------------------------------
function K.ApplyMinimapShape()
	if not Minimap then return; end

	if C.MinimapSquare then
		Minimap:SetMaskTexture(SQUARE_MASK);
		if MinimapBorder then MinimapBorder:Hide(); end
		if MinimapBorderTop then MinimapBorderTop:Hide(); end
		if MinimapNorthTag then MinimapNorthTag:Hide(); end
		if MinimapCompassTexture then MinimapCompassTexture:Hide(); end
		-- El borde cuadrado simple es el del estilo "Default": con
		-- cualquier otro se apaga, porque todos rodean lo mismo y se
		-- encimarian (mira ApplyMinimapBorderStyle).
		local b = GetSquareBorder();
		if b then
			if BorderStyle() == "Default" then b:Show(); else b:Hide(); end
		end
	else
		Minimap:SetMaskTexture(ROUND_MASK);
		if MinimapBorder then MinimapBorder:Show(); end
		if MinimapBorderTop then MinimapBorderTop:Show(); end
		if MinimapCompassTexture then MinimapCompassTexture:Show(); end
		if squareBorder then squareBorder:Hide(); end
	end

	K.ApplyMinimapBorderStyle();
	K.NudgeMinimapIcons();
	K.ApplyMinimapButtonLayout();
	-- El boton propio de NUF no pasa por LibDBIcon, asi que hay que
	-- reubicarlo a mano: en modo cuadrado sigue el perimetro.
	if K.UpdateMinimapButtonPosition then pcall(K.UpdateMinimapButtonPosition); end
end

-- ---------------------------------------------------------
-- Adornos
-- ---------------------------------------------------------
function K.ApplyMinimapDecorations()
	-- Nombre de la zona
	if MinimapZoneTextButton then
		if C.MinimapHideZone then MinimapZoneTextButton:Hide(); else MinimapZoneTextButton:Show(); end
	end

	-- Texto de la zona mas robusto y con contorno negro, para que se lea
	-- bien sobre el mapa (como la referencia).
	if MinimapZoneText and not _G.NUF_SAFE then
		local f = select(1, MinimapZoneText:GetFont());
		MinimapZoneText:SetFont(f or "Fonts\\FRIZQT__.TTF", 13, "OUTLINE");
		MinimapZoneText:SetShadowColor(0, 0, 0, 1);
		MinimapZoneText:SetShadowOffset(1, -1);
	end
	if MinimapBorderTop and not C.MinimapSquare then
		if C.MinimapHideZone then MinimapBorderTop:Hide(); else MinimapBorderTop:Show(); end
	end

	-- Fondo del nombre de zona.
	-- El "fondo" es MinimapBorderTop: la chapa dorada curva que Blizzard
	-- dibuja detras del texto. Ocultarla deja el nombre flotando limpio
	-- sobre el mundo, que es lo que uno quiere con el minimapa cuadrado.
	if MinimapBorderTop and not C.MinimapHideZone then
		if C.MinimapHideZoneBG then MinimapBorderTop:Hide(); else MinimapBorderTop:Show(); end
	end
	if MinimapZoneTextButton and C.MinimapHideZoneBG then
		-- Sin la chapa, el texto queda muy arriba; se baja sobre el mapa
		MinimapZoneTextButton:SetFrameStrata("MEDIUM");
	end

	-- Reloj
	if TimeManagerClockButton then
		if C.MinimapHideClock then TimeManagerClockButton:Hide(); else TimeManagerClockButton:Show(); end
	end

	-- Botones de zoom
	if MinimapZoomIn and MinimapZoomOut then
		if C.MinimapHideZoom then
			MinimapZoomIn:Hide(); MinimapZoomOut:Hide();
		else
			MinimapZoomIn:Show(); MinimapZoomOut:Show();
		end
	end

	-- Calendario (GameTimeFrame)
	if GameTimeFrame then
		if C.MinimapHideCalendar then GameTimeFrame:Hide(); else GameTimeFrame:Show(); end
	end

	-- Boton del mapa del mundo
	if MiniMapWorldMapButton then
		if C.MinimapHideWorldMap then MiniMapWorldMapButton:Hide(); else MiniMapWorldMapButton:Show(); end
	end
end

-- ---------------------------------------------------------
-- Ocultar los iconos de addons
--
-- Es lo mismo que hace el modulo del botoncito, pero como checkbox
-- directo: mucha gente quiere los iconos ocultos y listo, sin un boton
-- extra colgado del minimapa.
--
-- Solo se ocultan los que ESTABAN visibles, y se recuerdan cuales, para
-- no hacer aparecer despues iconos que Blizzard tenia ocultos a proposito
-- (el sobre del correo sin correo, la cola de battleground, etc).
-- ---------------------------------------------------------
local PROTECTED = {
	["Minimap"] = true, ["MinimapBackdrop"] = true, ["MinimapCluster"] = true,
	["MinimapBorder"] = true, ["MinimapBorderTop"] = true,
	["MinimapNorthTag"] = true, ["MinimapCompassTexture"] = true,
	["MinimapZoneTextButton"] = true, ["MiniMapWorldMapButton"] = true,
	["MinimapZoomIn"] = true, ["MinimapZoomOut"] = true,
	["TimeManagerClockButton"] = true, ["GameTimeFrame"] = true,
	["NUF_MinimapIconToggle"] = true, ["NUF_MinimapSquareBorder"] = true,
	-- ESTE ERA EL BUG DEL BORDE al usar "ocultar iconos de addons": el
	-- barrido recorre TODOS los hijos del minimapa y esconde lo que no
	-- este en esta lista. Como el borde es un frame hijo, se lo llevaba
	-- puesto y despues no volvia solo.
	["NUF_MinimapThinBorder"] = true,
	-- Boton de RASTREO (lupa): es del juego, no de un addon. No se oculta.
	["MiniMapTrackingFrame"] = true, ["MiniMapTracking"] = true,
	["MiniMapTrackingButton"] = true, ["MiniMapTrackingIcon"] = true,
	["MiniMapTrackingBorder"] = true, ["MiniMapTrackingButtonBorder"] = true,
	["MiniMapTrackingBackground"] = true,
};

-- Rescate: si el boton de rastreo quedo oculto de una sesion anterior (antes
-- se ocultaba junto con los iconos de addon), lo devolvemos a la vista.
local function RestoreTrackingButton()
	for _, n in ipairs({ "MiniMapTrackingFrame", "MiniMapTracking", "MiniMapTrackingButton" }) do
		local f = _G[n];
		if f and f.Show and not f:IsShown() then pcall(f.Show, f); end
	end
end
K.RestoreMinimapTracking = RestoreTrackingButton;

-- ESTO YA NO ESCONDE NADA. Lo hace MinimapIconToggle.lua.
--
-- Habia DOS barridos independientes sobre los mismos hijos del minimapa,
-- este y el del modulo del boton, cada uno con su tabla de "que escondi yo".
-- Con los dos activos uno mostraba lo que el otro habia escondido y las
-- tablas quedaban desincronizadas: iconos que no volvian, o que reaparecian
-- solos. Ahora hay un unico dueño y esta funcion solo lo llama.

-- Los addons cuelgan sus iconos tarde, asi que barremos unas veces mas
local iconRetry = CreateFrame("Frame");
local retryAcc, retryCount = 0, 0;
iconRetry:Hide();
iconRetry:SetScript("OnUpdate", function(self, elapsed)
	retryAcc = retryAcc + elapsed;
	if retryAcc < 1 then return; end
	retryAcc = 0;
	retryCount = retryCount + 1;
	if K.ApplyMinimapIconState then K.ApplyMinimapIconState(); end
	if retryCount >= 5 then self:Hide(); end
end);

-- ---------------------------------------------------------
-- Zoom con la rueda
-- ---------------------------------------------------------
local wheelHooked = false;

function K.ApplyMinimapWheelZoom()
	if not Minimap then return; end
	if C.MinimapWheelZoom then
		Minimap:EnableMouseWheel(true);
		if not wheelHooked then
			wheelHooked = true;
			Minimap:SetScript("OnMouseWheel", function(self, delta)
				if not C.MinimapWheelZoom then return; end
				if delta > 0 then
					Minimap_ZoomIn();
				else
					Minimap_ZoomOut();
				end
			end);
		end
	else
		Minimap:EnableMouseWheel(false);
	end
end

-- ---------------------------------------------------------
-- Escala
-- ---------------------------------------------------------
local ScaleRelayout;   -- declarada aca, definida abajo (se usa antes)

function K.ApplyMinimapScale()
	local scale = C.MinimapScale or 1.0;
	if MinimapCluster then MinimapCluster:SetScale(scale); end
	-- Al agrandar el mapa su borde izquierdo se come el lugar de los
	-- buffs. AuraAnchor recalcula donde arrancan (solo si no los moviste
	-- vos a mano).
	if K.RefreshAuraAnchorDefault then K.RefreshAuraAnchorDefault(); end
	-- Y otra vez un frame despues: recien ahi el minimapa ya tiene sus
	-- medidas nuevas. Sin esto, arrastrando el slider los buffs iban
	-- siempre un paso atras del tamaño real.
	ScaleRelayout();
end

-- Frame de un solo uso: se prende, corre una vez y se apaga.
local scaleRelay = CreateFrame("Frame");
scaleRelay:Hide();
scaleRelay:SetScript("OnUpdate", function(self)
	self:Hide();
	if K.RefreshAuraAnchorDefault then K.RefreshAuraAnchorDefault(); end
end);
ScaleRelayout = function()
	scaleRelay:Show();
end

-- ---------------------------------------------------------
-- Todo junto
-- ---------------------------------------------------------
function K.ApplyMinimapSettings()
	K.ApplyMinimapShape();
	K.ApplyMinimapDecorations();
	if K.ApplyMinimapIconState then K.ApplyMinimapIconState(); end
	K.ApplyMinimapWheelZoom();
	K.ApplyMinimapScale();
	RestoreTrackingButton();   -- por si quedo oculto de antes
	retryAcc, retryCount = 0, 0;
	iconRetry:Show();
end

local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:SetScript("OnEvent", function()
	K.ApplyMinimapSettings();
end);

-- Blizzard vuelve a mostrar el aro al cambiar de zona
if type(Minimap_SetPing) == "function" then
	-- nada que hacer, solo evitamos errores si el API no existe
end

SLASH_NUFMINIMAPSTYLE1 = "/nufmap";
SlashCmdList["NUFMINIMAPSTYLE"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "square" or msg == "cuadrado" then
		K.SaveConfig("MinimapSquare", true);
		K.ApplyMinimapSettings();
	elseif msg == "round" or msg == "redondo" then
		K.SaveConfig("MinimapSquare", false);
		K.ApplyMinimapSettings();
	else
		print("|cff4FC3F7NUF:|r /nufmap square | round");
	end
end
