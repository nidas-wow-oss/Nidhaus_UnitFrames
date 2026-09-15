-- Este archivo vive en Nidhaus_UnitFrames_Config, un addon aparte que se
-- carga SOLO cuando abris el panel (LoadOnDemand). Por eso no recibe el
-- namespace por "...", que es privado de cada addon: lo toma de la global
-- que publica el addon principal en Core/Init.lua.
local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);

-- =========================================================
-- SideList.lua
-- Lista vertical de secciones a la IZQUIERDA del panel, al estilo
-- TidyPlates: pestañas arriba, y dentro de cada pestaña una lista
-- de secciones al costado.
--
-- Por que asi y no subpestañas horizontales: una fila de botones
-- arriba se queda sin ancho a partir de 4 o 5 secciones y hay que
-- abreviar los nombres. En vertical entran 8 sin apretar nada, y
-- se ve de un vistazo todo lo que tiene la pestaña.
--
-- Uso:
--   local side = K.CreateSideList(panel, {
--       { name = "General Settings", hint = "Lo que afecta a todo" },
--       { name = "Action Bars" },
--   });
--   side[1], side[2]           -> scrollChild donde colgar el contenido
--   side.SetContentHeight(1, y)-> alto scrolleable (acepta el ultimo yPos negativo)
--   side.Select(2)             -> cambiar de seccion por codigo
-- =========================================================

local LIST_WIDTH  = 140;
local ITEM_HEIGHT = 30;   -- respira mejor que 26, y el texto queda centrado
local SEP_TOP     = 12;   -- aire arriba de la linea separadora
local SEP_BOTTOM  = 12;   -- aire abajo de la linea separadora

local sideCounter = 0;

-- Todas las listas creadas, para que ThemeManager las pueda repintar.
-- Antes la lista se dibujaba con colores fijos dorados y no cambiaba nada
-- al pasar a Arcane o Classic: era lo unico del panel que no seguia el tema.
K._sideLists = K._sideLists or {};

-- Colores por defecto (si todavia no hay tema cargado)
local DEF = {
	bg       = {0, 0, 0, 0.14},
	selBG    = {0.16, 0.12, 0.06, 0.95},
	selAlpha = 0.55,
	accent   = {1, 0.82, 0},
	gold     = false,
};

-- Un punto mas grande que la fuente base del template
local function BumpFont(fs, delta)
	local file, size, flags = fs:GetFont();
	if file and size then fs:SetFont(file, size + (delta or 1), flags); end
end

local function ThemeColors()
	local t = K.GetActiveTheme and K.GetActiveTheme();
	if not t then return DEF; end
	-- Blizzard pinta la seleccion como la ventana Interface: una barra
	-- azul llena, no un velo. Por eso trae su propio color y su propio
	-- alpha, y no toma prestado el de la pestana activa.
	local gold = t.sideGoldText and true or false;

	return {
		-- Solo el TONO del tema; el alpha lo forzamos bajo para que la
		-- columna se lea como un velo y no como un bloque solido.
		bg       = { (t.tabBarBGColor or DEF.bg)[1],
		             (t.tabBarBGColor or DEF.bg)[2],
		             (t.tabBarBGColor or DEF.bg)[3], 0.14 },
		selBG    = (gold and t.sideSelColor) or t.tabSelBGColor or DEF.selBG,
		selAlpha = gold and 0.95 or 0.55,
		accent   = t.accent or DEF.accent,
		gold     = gold,
	};
end

-- El texto va SIEMPRE en blanco, en los tres temas. Que la seleccion
-- se note por el fondo y la barrita de acento, no por el color de la letra:
-- asi la lista se lee igual de bien en Classic, Dark Gold y Arcane.
local function StyleItem(item, selected, col)
	col = col or ThemeColors();
	if selected then
		item.bg:SetTexture(col.selBG[1], col.selBG[2], col.selBG[3],
			col.selAlpha or 0.55);
		if col.gold then
			-- La barra azul y la barrita de acento dicen lo mismo. Juntas
			-- ensucian, asi que con la barra el marcador se apaga.
			item.marker:Hide();
		else
			item.marker:SetTexture(col.accent[1], col.accent[2], col.accent[3], 0.95);
			item.marker:Show();
		end
	else
		item.bg:SetTexture(0, 0, 0, 0);
		item.marker:Hide();
	end

	-- En Classic, Dark Gold y Arcane el texto va blanco en las nueve
	-- entradas y la seleccion se nota por el fondo.
	--
	-- Blizzard va al reves, porque asi es la ventana Interface: las
	-- categorias son DORADAS y la seleccionada pasa a blanco sobre el azul.
	if col.gold and not selected then
		item.labelFS:SetTextColor(1, 0.82, 0);
	else
		item.labelFS:SetTextColor(1, 1, 1);
	end

	-- Y LA FUENTE.
	--
	-- La lista de categorias de la ventana Interface usa GameFontNormal
	-- (FRIZQT 12). Aca la base es GameFontNormalSmall (10) subida un punto:
	-- 11, un punto mas chica, y por eso al lado de la ventana del juego se
	-- veia distinta aunque sea la misma familia.
	--
	-- Siempre desde item.baseFont y nunca desde lo que el texto tiene
	-- puesto: asi repintar mil veces da mil veces lo mismo.
	local base = item.baseFont;
	if base and base[1] then
		local size = base[2];
		if col.gold then size = size + 1; end
		item.labelFS:SetFont(base[1], size, base[3]);
	end
end

-- La llama ThemeManager cuando cambia el tema
function K.RestyleSideLists()
	local col = ThemeColors();
	for _, list in ipairs(K._sideLists) do

		-- LA COLUMNA: velo o recuadro.
		--
		-- Los tres temas propios la dibujan como un velo apenas mas oscuro
		-- con una linea divisoria al costado. La ventana Interface no hace
		-- eso: la lista de categorias vive en su PROPIA CAJA, con borde.
		--
		-- El borde va sin tenir. UI-Tooltip-Border en blanco es el dorado
		-- tostado que se ve en cualquier tooltip del juego, que es
		-- exactamente el de esas cajas. Tenirlo de marron, como estaba,
		-- daba ese gris embarrado.
		if list.listFrame then
			if col.gold then
				list.listFrame:SetBackdrop({
					bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
					edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
					tile     = true, tileSize = 16, edgeSize = 16,
					insets   = {left=4, right=4, top=4, bottom=4},
				});
				list.listFrame:SetBackdropColor(0.06, 0.06, 0.06, 0.85);
				list.listFrame:SetBackdropBorderColor(1, 1, 1, 1);
				if list.listBG  then list.listBG:Hide();  end
				if list.divider then list.divider:Hide(); end
			else
				list.listFrame:SetBackdrop(nil);
				if list.listBG  then list.listBG:Show();  end
				if list.divider then list.divider:Show(); end
			end
		end

		if list.listBG then list.listBG:SetTexture(unpack(col.bg)); end
		if list.divider then
			list.divider:SetTexture(col.accent[1], col.accent[2], col.accent[3], 0.28);
		end
		for i, item in ipairs(list.items) do
			StyleItem(item, i == list.selected, col);
		end
	end
end

function K.CreateSideList(panel, sections)
	if not panel or not sections or #sections == 0 then return nil; end

	sideCounter = sideCounter + 1;
	local prefix = "NidhausSideList" .. sideCounter .. "_";

	local result   = {};
	local items    = {};
	local panes    = {};
	local count    = 0;   -- se calcula en el bucle: los encabezados no cuentan

	-- ── Columna izquierda ─────────────────────────────────
	local list = CreateFrame("Frame", prefix .. "List", panel);
	list:SetPoint("TOPLEFT",    4, -4);
	list:SetPoint("BOTTOMLEFT", 4,  4);
	list:SetWidth(LIST_WIDTH);

	-- Fondo apenas mas oscuro que el panel, para que se lea como columna
	local listBG = list:CreateTexture(nil, "BACKGROUND");
	listBG:SetAllPoints(list);
	listBG:SetTexture(0, 0, 0, 0.14);
	result.listBG    = listBG;
	result.listFrame = list;

	-- Linea divisoria entre la lista y el contenido
	local divider = list:CreateTexture(nil, "ARTWORK");
	divider:SetTexture(1, 1, 1, 0.10);
	divider:SetPoint("TOPRIGHT",    list, "TOPRIGHT",    0, 0);
	divider:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", 0, 0);
	divider:SetWidth(1);
	result.divider = divider;

	local function Select(index)
		if not panes[index] then return; end
		result.selected = index;
		for i = 1, count do
			if i == index then
				panes[i].scrollFrame:Show();
			else
				panes[i].scrollFrame:Hide();
			end
			StyleItem(items[i], i == index);
		end
	end

	local yOffset = -8;
	local index   = 0;   -- indice REAL de seccion (los encabezados no cuentan)

	for _, sec in ipairs(sections) do
		local isTable = (type(sec) == "table");

		-- ── Encabezado de grupo (no clickeable) ──
		-- Sirve para separar "lo de la interfaz" de "lo de combate" sin
		-- meter otra pestaña arriba.
		if isTable and (sec.separator or sec.header) then
			-- Separador visual entre grupos de secciones: solo una linea fina.
			-- Antes llevaba un titulo ("COMBATE") y sobraba: la linea ya dice
			-- lo mismo sin meter otra palabra en la columna.
			yOffset = yOffset - SEP_TOP;

			local gline = list:CreateTexture(nil, "ARTWORK");
			gline:SetTexture(1, 1, 1, 0.12);
			gline:SetPoint("TOPLEFT", list, "TOPLEFT", 12, yOffset);
			gline:SetSize(LIST_WIDTH - 24, 1);

			yOffset = yOffset - SEP_BOTTOM;
		else
			index = index + 1;
			local i    = index;
			local name = isTable and sec.name or sec;

			-- SECCIONES DE FONDO.
			--
			-- Con hidden = true la seccion tiene su panel como cualquier
			-- otra, pero no aparece en la columna: se llega desde un boton
			-- del pie del panel. Es para herramientas que se abren y se
			-- cierran (Move Everything), no para ajustes que uno recorre.
			local hidden = isTable and sec.hidden;

			-- ── Item de la lista ──
			local item = CreateFrame("Button", prefix .. "Item" .. i, list);
			item:SetPoint("TOPLEFT",  list, "TOPLEFT",  0, yOffset);
			item:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, yOffset);
			item:SetHeight(ITEM_HEIGHT);

			item.bg = item:CreateTexture(nil, "BACKGROUND");
			item.bg:SetAllPoints(item);
			item.bg:SetTexture(0, 0, 0, 0);

			-- Barrita de acento a la izquierda del item seleccionado
			item.marker = item:CreateTexture(nil, "ARTWORK");
			item.marker:SetTexture(1, 0.82, 0, 0.9);
			item.marker:SetPoint("TOPLEFT",    item, "TOPLEFT",    0, 0);
			item.marker:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0);
			item.marker:SetWidth(3);
			item.marker:Hide();

			-- Centrado vertical: con TOPLEFT el texto quedaba pegado arriba
			item.labelFS = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
			item.labelFS:SetPoint("LEFT", item, "LEFT", 12, 0);
			item.labelFS:SetJustifyH("LEFT");
			item.labelFS:SetWidth(LIST_WIDTH - 18);
			item.labelFS:SetText(name);
			BumpFont(item.labelFS, 1);

			-- LA MEDIDA BASE, GUARDADA UNA SOLA VEZ.
			--
			-- StyleItem corre en cada repintado, y repintar es cada click
			-- en Classic / Dark Gold / Arcane. Si ahi adentro se volviera a
			-- sumar un punto sobre lo que el texto tiene AHORA, la letra
			-- creceria un punto por click y no pararia nunca -- que es
			-- justo lo que pasaba.
			--
			-- Guardando la medida de arranque, StyleItem escribe siempre un
			-- valor ABSOLUTO y da igual cuantas veces se lo llame.
			item.baseFont = { item.labelFS:GetFont() };

			item:SetScript("OnClick", function() Select(i); end);
			item:SetScript("OnEnter", function(self)
				if result.selected ~= i then
					self.bg:SetTexture(1, 1, 1, 0.07);
				end
			end);
			item:SetScript("OnLeave", function(self)
				if result.selected ~= i then
					self.bg:SetTexture(0, 0, 0, 0);
				end
			end);

			items[i] = item;
			if hidden then
				item:Hide();
			else
				-- Solo los visibles corren el cursor: si no, quedaba un
				-- hueco en la columna donde deberia estar el item.
				yOffset = yOffset - ITEM_HEIGHT - 1;
			end

			-- ── Panel scrolleable de la derecha ──
			local scrollFrame = CreateFrame("ScrollFrame", prefix .. "Scroll" .. i,
				panel, "UIPanelScrollFrameTemplate");
			scrollFrame:SetPoint("TOPLEFT",     LIST_WIDTH + 12, -6);
			scrollFrame:SetPoint("BOTTOMRIGHT", -26, 6);
			scrollFrame:Hide();

			local scrollChild = CreateFrame("Frame", prefix .. "Child" .. i, scrollFrame);
			scrollChild:SetWidth(580);
			scrollChild:SetHeight(1);
			scrollFrame:SetScrollChild(scrollChild);

			scrollChild.scrollFrame = scrollFrame;
			panes[i]  = scrollChild;
			result[i] = scrollChild;
		end
	end

	count = index;

	result.Select = Select;
	result.items  = items;
	result.count  = count;
	result.list   = list;

	-- Acepta un yPos negativo (el ultimo usado) o un alto positivo.
	result.SetContentHeight = function(index, value)
		local pane = panes[index];
		if not pane then return; end
		local h = math.abs(value or 0) + 40;
		if h < 60 then h = 60; end
		pane:SetHeight(h);
	end

	table.insert(K._sideLists, result);

	Select(1);
	return result;
end
