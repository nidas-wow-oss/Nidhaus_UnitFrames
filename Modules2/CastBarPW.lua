local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- CastBarPW.lua  -  barra de casteo estilo pw_unitframes
--
-- Port de pw_unitframes/modules/elements/castbar.lua para las tres
-- barras que maneja Blizzard: jugador, objetivo y foco.
--
-- Lo que trae pw y no tiene la barra de Blizzard:
--
--   1. Borde, destello y escudo propios (las tres .blp de pw).
--   2. EL ICONO DEL HECHIZO. Blizzard lo crea pero lo deja oculto;
--      pw lo muestra, lo recorta al 8-92% para sacarle el marco
--      feo, y le dibuja un borde encima.
--   3. En la barra del JUGADOR el icono no va al costado: va
--      flotando ARRIBA del centro de la barra, y el borde y el
--      destello suben para acompanarlo.
--   4. Fuente propia (PTSans-Bold) para el nombre del hechizo.
--
-- Numeros, tal cual salen de pw:
--
--     icono jugador          30 x 30
--     icono objetivo/foco    22 x 22
--     recorte                .08 .92 .08 .92
--     borde del icono        3 px hacia afuera, color .2 gris
--     tinte del borde        .22 gris  (config.global.framecolors)
--     escala                 1.2
--     borde y destello       TOP  0, 26   (solo jugador)
--     icono                  CENTER sobre el TOP de la barra, 0, 24
--     nombre del hechizo     CENTER 0, 1
--
-- =========================================================
-- LA FOTO ORIGINAL SE SACA UNA SOLA VEZ
--
-- Igual que en PartyFramePW, SquareStyle y BarBaseline. Si se
-- recapturara al re-aplicar, la segunda vez guardariamos como
-- "original" lo que pusimos nosotros y apagar el checkbox dejaria
-- la barra a medio camino. Es el error que mas veces aparecio en
-- este addon, asi que va explicito.
-- =========================================================
-- CONVIVENCIA CON LO QUE YA HABIA
--
--   * Modules/CastingBarTimer.lua reposiciona el NOMBRE del hechizo
--     para dejarle lugar al contador "(1.5s)". Si lo centraramos
--     encima quedarian los dos textos pisados, asi que despues de
--     estilar volvemos a llamar a K.ToggleCastingTimers y que el
--     contador reacomode lo suyo.
--
--   * Lorti UI tambien tiñe los bordes de estas tres barras (a .05).
--     Los dos escriben el mismo VertexColor: gana el ultimo. Como
--     nosotros re-aplicamos en cada casteo, con los dos prendidos
--     manda este modulo.
--
--   * LA ESCALA TIENE UN DUEÑO POR BARRA, y este modulo respeta los
--     que ya existian:
--         jugador   -> Move Everything (globalPos.CastBar.scale,
--                      Ctrl + rueda). El slider de aca escribe ahi
--                      via K.SetGlobalFrameScale, no con SetScale.
--         foco      -> C.FocusSpellBarScale, que ya tiene su propio
--                      slider en Frames. NO se toca desde aca.
--         objetivo  -> no tenia dueño, asi que lo toma este modulo.
-- =========================================================

local MEDIA = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\pw\\";

-- Las .blp van SIN extension, las .tga CON extension. Poner ".blp"
-- hace que la ruta no resuelva y la textura salga como un manchon.
local TEX_BORDER = MEDIA .. "UI-CastingBar-Border-Small";
local TEX_FLASH  = MEDIA .. "UI-CastingBar-Flash-Small";
local TEX_SHIELD = MEDIA .. "UI-CastingBar-Small-Shield";
local TEX_ICONBD = MEDIA .. "Border.tga";
local FONT_PATH  = MEDIA .. "PTSans-Bold.ttf";

local TEXCOORD    = { 0.08, 0.92, 0.08, 0.92 };
local BORDER_TINT = { 0.22, 0.22, 0.22, 1 };   -- config.global.framecolors
local ICON_TINT   = { 0.20, 0.20, 0.20, 1 };   -- config.global.castbar_icon_color

-- Tamaños de pw. El slider mueve el del jugador; los otros dos van
-- en proporcion para que el conjunto se vea parejo.
local ICON_PLAYER = 30;
local ICON_OTHER  = 22;

local BARS = { "CastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar" };

-- ---------------------------------------------------------
-- Que barras toca el modulo
--
-- Antes eran las tres o ninguna. Ahora objetivo y foco tienen cada una su
-- checkbox en el panel, asi se puede dejar el estilo custom solo en la
-- propia (que es la que se mira todo el tiempo) y que las otras dos sigan
-- con el aspecto de Blizzard.
--
-- La del jugador no lleva checkbox: es la razon de ser del modulo, si no
-- la queres apagas "Custom Cast Bar" y listo.
--
-- El ~= false es a proposito: si la clave todavia no existe en la config
-- de alguien que ya tenia el addon, cuenta como encendida y no le cambia
-- el aspecto de golpe al actualizar.
-- ---------------------------------------------------------
local function BarAllowed(barName)
	if barName == "TargetFrameSpellBar" then return C.CastBarPWTarget ~= false; end
	if barName == "FocusFrameSpellBar"  then return C.CastBarPWFocus  ~= false; end
	return true;
end

local orig    = {};      -- [nombre de la barra] = foto de fabrica
local applied = false;
local castFont;          -- objeto de fuente, creado una sola vez

-- ---------------------------------------------------------
-- Utilidades de foto / restauracion
-- ---------------------------------------------------------
local function SnapPoints(region)
	if not region then return nil; end
	local n = region:GetNumPoints() or 0;
	if n == 0 then return nil; end
	local pts = {};
	for i = 1, n do
		pts[i] = { region:GetPoint(i) };
	end
	return pts;
end

local function RestorePoints(region, pts)
	if not region or not pts or #pts == 0 then return; end
	region:ClearAllPoints();
	for _, pt in ipairs(pts) do
		pcall(region.SetPoint, region, unpack(pt));
	end
end

local function Sub(barName, suffix)
	return _G[barName .. suffix];
end

-- ---------------------------------------------------------
-- Fuente
--
-- CreateFont es global y permanente: se crea una vez y se
-- reutiliza. Si el .ttf no estuviera, SetFont devuelve false y
-- dejamos la fuente sin tocar en vez de romper el texto.
-- ---------------------------------------------------------
local function CastFont()
	if castFont then return castFont; end
	local f = CreateFont("NUF_pwCastFont");
	if not f then return nil; end
	if f:SetFont(FONT_PATH, 14) == false then
		castFont = false;
		return nil;
	end
	f:SetShadowColor(0, 0, 0, 1);
	f:SetShadowOffset(1, -1);
	castFont = f;
	return f;
end

-- ---------------------------------------------------------
-- Foto de fabrica
-- ---------------------------------------------------------
local function Capture(barName)
	if orig[barName] then return; end
	local bar = _G[barName];
	if not bar then return; end

	local border = Sub(barName, "Border");
	local flash  = Sub(barName, "Flash");
	local shield = Sub(barName, "BorderShield");
	local text   = Sub(barName, "Text");
	local icon   = Sub(barName, "Icon");

	local snap = {
		scale = bar:GetScale() or 1,
	};

	if border then
		local r, g, b, a = border:GetVertexColor();
		snap.border = {
			tex    = border:GetTexture(),
			color  = { r or 1, g or 1, b or 1, a or 1 },
			points = SnapPoints(border),
		};
	end

	if flash then
		snap.flash = { tex = flash:GetTexture(), points = SnapPoints(flash) };
	end

	if shield then
		snap.shield = { tex = shield:GetTexture() };
	end

	if text then
		snap.text = { font = text:GetFontObject(), points = SnapPoints(text) };
	end

	if icon then
		snap.icon = {
			shown  = icon:IsShown() and true or false,
			w      = icon:GetWidth(),
			h      = icon:GetHeight(),
			coord  = { icon:GetTexCoord() },
			points = SnapPoints(icon),
		};
	end

	orig[barName] = snap;
end

-- ---------------------------------------------------------
-- Borde del icono
--
-- pw lo crea colgando de la BARRA (no del icono) para que quede en
-- la capa de arriba. Lo creamos una sola vez y despues solo lo
-- mostramos u ocultamos: crear texturas en cada casteo seria basura
-- que nunca se libera.
-- ---------------------------------------------------------
local function IconBorder(bar, icon)
	if bar.nufCastIconBorder then return bar.nufCastIconBorder; end
	local t = bar:CreateTexture(nil, "OVERLAY");
	t:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 3, 3);
	t:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -3, -3);
	t:SetTexture(TEX_ICONBD);
	t:SetVertexColor(unpack(ICON_TINT));
	bar.nufCastIconBorder = t;
	return t;
end

-- ---------------------------------------------------------
-- Aplicar a una barra
-- ---------------------------------------------------------
local function StyleOne(barName)
	local bar = _G[barName];
	if not bar then return; end

	Capture(barName);

	local isPlayer = (barName == "CastingBarFrame");

	-- ── Borde, destello y escudo ──
	local border = Sub(barName, "Border");
	if border then
		border:SetTexture(TEX_BORDER);
		if C.CastBarPWDark == false then
			border:SetVertexColor(1, 1, 1, 1);
		else
			border:SetVertexColor(unpack(BORDER_TINT));
		end
	end

	local flash = Sub(barName, "Flash");
	if flash then flash:SetTexture(TEX_FLASH); end

	local shield = Sub(barName, "BorderShield");
	if shield then shield:SetTexture(TEX_SHIELD); end

	-- ── Nombre del hechizo ──
	local text = Sub(barName, "Text");
	if text then
		local f = CastFont();
		if f then text:SetFontObject(f); end
	end

	-- ── Icono del hechizo ──
	local icon = Sub(barName, "Icon");
	if icon then
		if C.CastBarPWIcon == false then
			icon:Hide();
			if bar.nufCastIconBorder then bar.nufCastIconBorder:Hide(); end
		else
			local base = C.CastBarPWIconSize;
			if type(base) ~= "number" then base = ICON_PLAYER; end
			-- El del objetivo y el del foco van proporcionalmente mas
			-- chicos, igual que en pw (30 contra 22).
			local size = isPlayer and base or (base * ICON_OTHER / ICON_PLAYER);

			icon:Show();
			icon:SetWidth(size);
			icon:SetHeight(size);
			icon:SetTexCoord(unpack(TEXCOORD));

			IconBorder(bar, icon):Show();
		end
	end

	-- ── Lo que solo vale para la barra del jugador ──
	--
	-- Es la unica de las tres que es ancha y esta suelta en el medio
	-- de la pantalla: pw le sube el marco y le pone el icono flotando
	-- arriba del centro. En objetivo y foco el icono se queda donde
	-- lo dejo Blizzard, pegado al costado.
	if isPlayer then
		if border then border:SetPoint("TOP", 0, 26); end
		if flash  then flash:SetPoint("TOP", 0, 26);  end
		if icon and C.CastBarPWIcon ~= false then
			icon:ClearAllPoints();
			icon:SetPoint("CENTER", bar, "TOP", 0, 24);
		end
		if text then
			text:ClearAllPoints();
			text:SetPoint("CENTER", 0, 1);
		end
	end
end

-- ---------------------------------------------------------
-- Restaurar una barra
-- ---------------------------------------------------------
local function RestoreOne(barName)
	local snap = orig[barName];
	if not snap then return; end
	local bar = _G[barName];
	if not bar then return; end

	local border = Sub(barName, "Border");
	if border and snap.border then
		if snap.border.tex then border:SetTexture(snap.border.tex); end
		border:SetVertexColor(unpack(snap.border.color));
		RestorePoints(border, snap.border.points);
	end

	local flash = Sub(barName, "Flash");
	if flash and snap.flash then
		if snap.flash.tex then flash:SetTexture(snap.flash.tex); end
		RestorePoints(flash, snap.flash.points);
	end

	local shield = Sub(barName, "BorderShield");
	if shield and snap.shield and snap.shield.tex then
		shield:SetTexture(snap.shield.tex);
	end

	local text = Sub(barName, "Text");
	if text and snap.text then
		if snap.text.font then text:SetFontObject(snap.text.font); end
		RestorePoints(text, snap.text.points);
	end

	local icon = Sub(barName, "Icon");
	if icon and snap.icon then
		icon:SetWidth(snap.icon.w or 16);
		icon:SetHeight(snap.icon.h or 16);
		if snap.icon.coord and #snap.icon.coord >= 4 then
			pcall(icon.SetTexCoord, icon, unpack(snap.icon.coord));
		end
		RestorePoints(icon, snap.icon.points);
		-- Blizzard lo deja oculto en las tres barras. Volver a Hide es
		-- lo que hace que apagar el checkbox se note de verdad.
		if snap.icon.shown then icon:Show(); else icon:Hide(); end
	end

	if bar.nufCastIconBorder then bar.nufCastIconBorder:Hide(); end

	-- Solo la del objetivo la puso este modulo, asi que solo esa la
	-- devuelve. La del jugador es de Move Everything y la del foco es
	-- de C.FocusSpellBarScale.
	if barName == "TargetFrameSpellBar" then
		pcall(bar.SetScale, bar, snap.scale or 1);
	end
end

-- ---------------------------------------------------------
-- Escala
--
-- Un solo dueño por valor:
--   jugador          -> Move Everything (globalPos.CastBar.scale)
--   objetivo y foco  -> este modulo
-- ---------------------------------------------------------
function K.ApplyCastBarPWScale(value)
	if type(value) ~= "number" then value = C.CastBarPWScale; end
	if type(value) ~= "number" then return; end

	-- Todo por _G, igual que en el resto del archivo. Da lo mismo en el
	-- juego, pero mezclar las dos formas hace que un cambio en un lado
	-- no se note en el otro.
	local player = _G["CastingBarFrame"];
	if K.SetGlobalFrameScale then
		K.SetGlobalFrameScale("CastBar", value);
	elseif player then
		pcall(player.SetScale, player, value);
	end

	-- El foco queda afuera a proposito: su escala es C.FocusSpellBarScale
	-- y tiene slider propio en Frames. Pisarla desde aca haria que ese
	-- slider dejara de funcionar sin que se entienda por que.
	if not applied then return; end
	-- Con el checkbox de objetivo apagado, su escala tampoco se toca: la
	-- barra queda entera como la de Blizzard.
	if not BarAllowed("TargetFrameSpellBar") then return; end
	local target = _G["TargetFrameSpellBar"];
	if target then
		pcall(target.SetScale, target, value);
	end
end

-- ---------------------------------------------------------
-- API publica
-- ---------------------------------------------------------
function K.EnableCastBarPW()
	applied = true;
	-- Se recorren siempre las tres: las permitidas se estilizan y las que
	-- el usuario acaba de destildar se devuelven a como venian. Si solo se
	-- estilizara lo permitido, al destildar objetivo o foco la barra
	-- quedaba con el estilo puesto hasta el proximo /reload.
	for _, name in ipairs(BARS) do
		if BarAllowed(name) then StyleOne(name); else RestoreOne(name); end
	end

	K.ApplyCastBarPWScale(C.CastBarPWScale);

	-- Que el contador de segundos vuelva a acomodar el nombre del
	-- hechizo: recien le centramos el texto encima.
	if C.CastingTimers and K.ToggleCastingTimers then
		K.ToggleCastingTimers(true);
	end
end

function K.DisableCastBarPW()
	if not applied then return; end
	applied = false;
	for _, name in ipairs(BARS) do RestoreOne(name); end

	if C.CastingTimers and K.ToggleCastingTimers then
		K.ToggleCastingTimers(true);
	end
end

function K.IsCastBarPWActive()
	return applied;
end

function K.ApplyCastBarPW()
	if C.CastBarPWEnabled then
		K.EnableCastBarPW();
	else
		K.DisableCastBarPW();
	end
end

-- ---------------------------------------------------------
-- Re-aplicar
--
-- Blizzard oculta y vuelve a mostrar estas barras en cada casteo, y
-- de paso le devuelve al icono su tamaño y su recorte. Enganchamos
-- el OnShow de cada barra en vez de una funcion global: son tres
-- HookScript sobre frames propios de Blizzard, sin riesgo de taint
-- y sin costo cuando el modulo esta apagado (la primera linea sale).
-- ---------------------------------------------------------
local function HookBars()
	for _, name in ipairs(BARS) do
		local bar = _G[name];
		if bar and not bar.nufCastPWHooked then
			bar.nufCastPWHooked = true;
			bar:HookScript("OnShow", function(self)
				if not applied or not BarAllowed(name) then return; end
				StyleOne(name);
			end);
		end
	end
end

-- ---------------------------------------------------------
-- Arranque
--
-- FocusFrameSpellBar existe desde el inicio en 3.3.5a, pero por si
-- algun otro addon lo crea tarde reintentamos enganchar en cada
-- CONFIG_CHANGED: HookBars es idempotente.
-- ---------------------------------------------------------
K.RegisterConfigEvent("CONFIG_LOADED", function()
	HookBars();
	K.ApplyCastBarPW();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	HookBars();
	K.ApplyCastBarPW();
end);
