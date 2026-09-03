local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- UIKit.lua
-- Piezas visuales compartidas del panel de opciones.
--
-- Objetivo: que todas las pestañas hablen el MISMO idioma visual.
-- Antes convivian verde para encabezados, amarillo para titulos de
-- slider, celeste para party features y blanco para checkboxes:
-- cuatro codigos de color distintos sin significado.
--
-- Ahora son dos:
--   DORADO  -> encabezado de seccion
--   BLANCO  -> texto de opcion
--   CELESTE -> valor / dato
-- =========================================================

K.UI = K.UI or {};

-- ── Paleta ────────────────────────────────────────────────
K.UI.COLOR_HEADER = "|cffFFD100";   -- dorado, encabezados
K.UI.COLOR_LABEL  = "|cffFFFFFF";   -- blanco, opciones
K.UI.COLOR_VALUE  = "|cff8EC9FF";   -- celeste, valores
K.UI.COLOR_DIM    = "|cff8A8A8A";   -- gris, descripciones

function K.UI.Header(text) return K.UI.COLOR_HEADER .. (text or "") .. "|r"; end
function K.UI.Label(text)  return K.UI.COLOR_LABEL  .. (text or "") .. "|r"; end
function K.UI.Value(text)  return K.UI.COLOR_VALUE  .. (text or "") .. "|r"; end
function K.UI.Dim(text)    return K.UI.COLOR_DIM    .. (text or "") .. "|r"; end

-- Saca cualquier codigo de color previo de un texto, para poder
-- reaplicar el nuestro sin que quede |cff...|cff... encadenado.
function K.UI.Strip(text)
	if type(text) ~= "string" then return text; end
	text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "");
	text = string.gsub(text, "|r", "");
	return text;
end

-- ── Caja de seccion ───────────────────────────────────────
-- Recuadro con borde tenue y titulo, para agrupar controles.
-- Es DECORATIVA: se dibuja detras del contenido, asi que se puede
-- agregar sin tocar la posicion de nada.
--
--   K.UI.SectionBox(parent, "Action Bars", x, y, width, height)
--
-- SIN recuadros: al usuario no le gustaron las cajas dentro del panel
-- (cuadro dentro de cuadro). Esta funcion ahora solo dibuja el TITULO de
-- la seccion, si lo hay, y devuelve un frame invisible para que todos los
-- llamadores existentes (Show/Hide, etc.) sigan funcionando sin cambios.
function K.UI.SectionBox(parent, title, x, y, width, height)
	local box = CreateFrame("Frame", nil, parent);
	box:SetPoint("TOPLEFT", x, y);
	box:SetSize(width or 10, height or 10);
	-- sin backdrop: invisible

	if title and title ~= "" then
		local fs = box:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		fs:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -2);
		fs:SetText(K.UI.Header(K.UI.Strip(title)));
		box.title = fs;
	end

	return box;
end

-- ── Separador fino ────────────────────────────────────────
function K.UI.Separator(parent, x, y, width)
	local sep = parent:CreateTexture(nil, "ARTWORK");
	sep:SetTexture(1, 1, 1, 0.10);
	sep:SetPoint("TOPLEFT", x, y);
	sep:SetSize(width or 540, 1);
	return sep;
end

-- ── Filas alternadas ──────────────────────────────────────
-- DESACTIVADO a pedido del usuario: las bandas claro/oscuro creaban el
-- efecto de "doble fondo" que no gustaba. Se deja la funcion vacia para
-- no romper a quien la llame.
function K.UI.StripeRow(parent, index)
	return nil;
end

-- ---------------------------------------------------------
-- Slider de escala GENERICO, atado al registro de ScaleAPI.
-- Sirve para cualquier modulo que haya llamado K.RegisterScalable.
--
--   K.UI.ScaleSlider(parent, "DTSU", x, y)
--
-- Si el modulo no esta registrado devuelve nil y no dibuja nada, asi el
-- panel no se rompe si un modulo no soporta escala.
-- ---------------------------------------------------------
-- =========================================================
-- LOS TOPES DEL SLIDER
--
-- OptionsSliderTemplate trae tres FontString: el titulo (anclado arriba al
-- centro) y los dos topes, minimo y maximo, abajo en cada punta.
--
-- En todo el addon se los escondia a los tres de un saque, con un bucle
-- copiado en cuatro archivos, y los sliders quedaban sin referencia: la
-- perilla a media altura y vos adivinando entre que numeros se mueve.
--
-- Estos sliders NO tienen nombre (CreateFrame("Slider", nil, ...)), asi
-- que no se puede ir por _G[nombre.."Low"]. La unica marca estable es
-- donde esta anclado cada uno:
--
--     BOTTOM   -> titulo   (se esconde: cada panel dibuja el suyo)
--     TOPLEFT  -> minimo
--     TOPRIGHT -> maximo
--
-- Devuelve las dos FontStrings por si el llamador quiere reubicarlas.
-- =========================================================
function K.UI.SliderEnds(slider, minText, maxText)
	if not slider or not slider.GetRegions then return; end
	local low, high;
	for _, r in pairs({ slider:GetRegions() }) do
		if r.GetObjectType and r:GetObjectType() == "FontString" then
			local point = r:GetPoint();
			if point == "TOPLEFT" then
				low = r;
				r:SetText(minText or "");
				r:SetTextColor(0.6, 0.6, 0.6);
				r:Show();
			elseif point == "TOPRIGHT" then
				high = r;
				r:SetText(maxText or "");
				r:SetTextColor(0.6, 0.6, 0.6);
				r:Show();
			else
				r:SetText("");
				r:Hide();
			end
		end
	end
	return low, high;
end

function K.UI.ScaleSlider(parent, moduleId, x, y, width, label)
	if not (K.IsScalable and K.IsScalable(moduleId)) then return nil; end

	local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate");
	s:SetPoint("TOPLEFT", x, y);
	s:SetWidth(width or 180);
	s:SetMinMaxValues(0.5, 2.0);
	s:SetValueStep(0.05);

	K.UI.SliderEnds(s, "0.50", "2.00");

	local title = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	title:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 2);
	title:SetText(K.UI.Label(label or (L and L["SLIDER_SCALE"]) or "Scale"));

	local val = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	val:SetPoint("BOTTOMRIGHT", s, "TOPRIGHT", 0, 2);

	-- AttachSliderValue (mas abajo en este mismo archivo) le cuelga una
	-- cajita editable con el valor a TODO slider del addon. Sin esta
	-- marca quedaban los dos numeros: este de aca arriba a la derecha y
	-- el de la cajita debajo. Se veia en el slider de escala de DTSU y
	-- en el de cualquier modulo escalable.
	--
	-- La marca le dice a AttachSliderValue cual es "el nuestro" para que
	-- lo esconda. Se sigue actualizando igual, asi que si algun dia se
	-- saca la cajita este vuelve a aparecer al dia.
	s._nufOwnValue = val;

	local cur = K.GetModuleScale(moduleId);
	s:SetValue(cur);
	val:SetText(string.format("%.2f", cur));
	s._last = cur;

	s:SetScript("OnValueChanged", function(self, v)
		v = math.floor(v * 20 + 0.5) / 20;   -- pasos de 0.05
		if self._last == v then return; end
		self._last = v;
		val:SetText(string.format("%.2f", v));
		K.SetModuleScale(moduleId, v);
	end);

	s.Refresh = function(self)
		local c = K.GetModuleScale(moduleId);
		self._last = c;
		self:SetValue(c);
		val:SetText(string.format("%.2f", c));
	end

	return s;
end

-- ─────────────────────────────────────────────────────────
-- SLIDERS: caja de valor debajo
--
-- OptionsSliderTemplate ya trae el titulo arriba y min/max en las
-- puntas, pero no muestra el valor actual. Cada slider del addon lo
-- resolvia a mano metiendo el numero DENTRO del titulo ("Escala: 1.2"),
-- lo que quedaba largo e inconsistente.
--
-- Aca se le cuelga una cajita editable centrada abajo con el valor, y
-- se le limpia al titulo el sufijo ": <numero>" si lo tenia. Ademas se
-- puede tipear el numero a mano.
--
-- No hay que tocar ningun slider existente: RestyleSliders() recorre el
-- panel y se los aplica a todos.
-- ─────────────────────────────────────────────────────────

-- Cuantos decimales mostrar segun el paso del slider
local function StepDecimals(slider)
	local step = slider:GetValueStep() or 1;
	if step >= 1 then return 0; end
	if step >= 0.1 then return 1; end
	return 2;
end

local function FormatValue(slider, v)
	local d = StepDecimals(slider);
	if d == 0 then return tostring(math.floor(v + 0.5)); end
	return string.format("%." .. d .. "f", v);
end

-- Le saca al titulo el ": 1.25" / ": 62" final que muchos sliders
-- agregaban a mano, para no repetir el numero arriba y abajo.
local function StripTrailingValue(text)
	if type(text) ~= "string" then return text; end
	return (string.gsub(text, "%s*:%s*%-?%d+%.?%d*%s*$", ""));
end

function K.UI.AttachSliderValue(slider)
	if not slider or slider._nufValueBox then return; end
	if not slider.GetValueStep or not slider.GetMinMaxValues then return; end

	-- Las barras de scroll TAMBIEN son objetos "Slider", asi que el recorrido
	-- de RestyleSliders las agarraba y les colgaba una cajita con el valor:
	-- aparecia un numero suelto al pie de cada scroll. Se descartan por
	-- orientacion (las de opciones son horizontales) y por nombre.
	if slider.GetOrientation and slider:GetOrientation() == "VERTICAL" then return; end
	local sname = slider:GetName();
	if sname and string.find(sname, "ScrollBar") then return; end
	local parent = slider:GetParent();
	if parent and parent.GetObjectType and parent:GetObjectType() == "ScrollFrame" then
		return;
	end

	-- El titulo: con nombre sale directo; sin nombre (la mayoria de los
	-- sliders del addon son anonimos) hay que buscarlo entre las regiones.
	-- En OptionsSliderTemplate el titulo es el unico FontString anclado
	-- por su BOTTOM (Low y High van por TOPLEFT / TOPRIGHT).
	local name = slider:GetName();
	local titleFS = name and _G[name .. "Text"];
	if not titleFS then
		for _, r in ipairs({ slider:GetRegions() }) do
			if r.GetObjectType and r:GetObjectType() == "FontString" then
				local pt = r:GetPoint(1);
				if pt == "BOTTOM" then titleFS = r; break; end
			end
		end
	end

	-- Varios sliders ya traian su propio FontString con el valor, justo
	-- debajo. La cajita va en el mismo lugar, asi que hay que esconderlo o
	-- se leen los dos numeros pisados (uno mas grande que el otro).
	-- La pestaña Frames arma un layout compacto propio: titulo a la
	-- izquierda y valor pegado arriba a la derecha (slider.ValueText). Con
	-- la cajita debajo el numero quedaba DOS veces. Se esconde ese, que la
	-- caja ya lo muestra y ademas es editable.
	if slider.ValueText then
		pcall(slider.ValueText.Hide, slider.ValueText);
	end

	if slider._nufOwnValue then
		pcall(slider._nufOwnValue.Hide, slider._nufOwnValue);
	else
		for _, r in ipairs({ slider:GetRegions() }) do
			if r.GetObjectType and r:GetObjectType() == "FontString" and r ~= titleFS then
				local pt, rel, rp = r:GetPoint(1);
				if pt == "TOP" and rp == "BOTTOM" then pcall(r.Hide, r); end
			end
		end
	end

	local box = CreateFrame("EditBox", nil, slider);
	box:SetAutoFocus(false);
	box:SetFontObject("GameFontHighlightSmall");
	box:SetJustifyH("CENTER");
	box:SetWidth(58);
	box:SetHeight(16);
	box:SetPoint("TOP", slider, "BOTTOM", 0, -1);
	box:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	});
	box:SetBackdropColor(0, 0, 0, 0.55);
	box:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8);
	box:SetTextInsets(4, 4, 0, 0);

	slider._nufValueBox = box;

	local function Sync()
		if box:HasFocus() then return; end
		box:SetText(FormatValue(slider, slider:GetValue() or 0));
		box:SetCursorPosition(0);
	end
	slider._nufSyncValue = Sync;

	box:SetScript("OnEnterPressed", function(self)
		local v = tonumber(self:GetText());
		if v then
			local lo, hi = slider:GetMinMaxValues();
			if v < lo then v = lo; elseif v > hi then v = hi; end
			slider:SetValue(v);
		end
		self:ClearFocus();
		Sync();
	end);
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); Sync(); end);
	box:SetScript("OnEditFocusLost", Sync);

	slider:HookScript("OnValueChanged", function(self)
		-- El titulo lo reescribe el OnValueChanged propio de cada slider,
		-- asi que hay que volver a limpiarlo DESPUES de que corra.
		if titleFS then titleFS:SetText(StripTrailingValue(titleFS:GetText())); end
		Sync();
	end);

	if titleFS then titleFS:SetText(StripTrailingValue(titleFS:GetText())); end
	Sync();
	return box;
end

-- Cuelga el restilado del OnShow de una ventana propia (los menus de
-- modulo se arman cuando se abren, no al cargar el panel).
function K.UI.AutoRestyle(frame)
	if not frame or frame._nufAutoRestyle then return; end
	frame._nufAutoRestyle = true;
	frame:HookScript("OnShow", function(self)
		if self._nufSlidersDone then return; end
		self._nufSlidersDone = true;
		pcall(K.UI.RestyleSliders, self);
	end);
	if frame:IsShown() then pcall(K.UI.RestyleSliders, frame); end
end

-- Recorre un frame y le pone la caja de valor a todos los sliders que
-- cuelguen de el, sin importar cuan anidados esten.
function K.UI.RestyleSliders(root, depth)
	if not root or (depth or 0) > 8 then return; end
	local kids = { root:GetChildren() };
	for _, child in ipairs(kids) do
		if child.GetObjectType and child:GetObjectType() == "Slider" then
			pcall(K.UI.AttachSliderValue, child);
		end
		K.UI.RestyleSliders(child, (depth or 0) + 1);
	end
end

-- ─────────────────────────────────────────────────────────
-- BLOQUE DESPLEGABLE
--
-- El problema: casi todo el panel se arma con coordenadas fijas
-- ("gY = gY - 27" y a otra cosa). Con ese esquema, esconder una opcion
-- deja el agujero, porque lo de abajo no sabe que la de arriba ya no
-- esta. Por eso cada desplegable se venia resolviendo a mano.
--
-- Esto lo generaliza. Devuelve un "cuerpo" vacio donde colgar las
-- sub-opciones (con parent = body y coordenadas locales), y el cuerpo
-- sabe medirse: colapsado vale 1px de alto, desplegado vale lo que le
-- pediste. Lo que sigue se ancla AL CUERPO, no a un numero, y entonces
-- sube y baja solo.
--
--   local body = K.UI.Collapsible(pane, x, y, 440, 104, function()
--       return K.IsModuleEnabled("ClassOutline");
--   end);
--   ... controles con parent = body ...
--   siguiente:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -18);
--
-- isOpen se vuelve a consultar en cada Refresh(), asi que alcanza con
-- llamar body:Refresh() desde el OnClick del checkbox.
-- ─────────────────────────────────────────────────────────
function K.UI.Collapsible(parent, x, y, width, height, isOpen)
	local body = CreateFrame("Frame", nil, parent);
	body:SetPoint("TOPLEFT", x, y);
	body:SetWidth(width or 440);
	body:SetHeight(height or 1);

	body._fullHeight = height or 1;

	function body:SetFullHeight(h)
		self._fullHeight = h or 1;
		self:Refresh();
	end

	function body:Refresh()
		local open = true;
		if isOpen then
			local ok, v = pcall(isOpen);
			open = ok and v and true or false;
		end
		if open then
			self:Show();
			self:SetHeight(self._fullHeight);
		else
			self:Hide();
			self:SetHeight(1);
		end
		return open;
	end

	-- Al reabrir el panel el estado pudo cambiar desde otro lado.
	parent:HookScript("OnShow", function() body:Refresh(); end);
	body:Refresh();
	return body;
end
