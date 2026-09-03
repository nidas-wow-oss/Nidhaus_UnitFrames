local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PartyTargets - estilo Square
--
-- Segundo aspecto para los marcos de objetivo del grupo, inspirado en el
-- de pw_unitframes: en vez de la barrita horizontal estilo Target-of-Target
-- de Blizzard, un cuadradito vertical con el retrato al medio.
--
--     Classic (96x46)            Square (34x54)
--     +----------------+              Nombre
--     |(o) ====== 85%  |             +------+
--     |    ------      |             |  o   |
--     +----------------+             +------+
--          Nombre                     ======
--                                     ------
--
-- POR QUE ESTA EN UN ARCHIVO APARTE
--
-- Frames.lua son 875 lineas que ya manejan eventos, arrastre, anclado,
-- escala y menu contextual. Nada de eso cambia entre los dos estilos: lo
-- unico distinto es DONDE va cada pieza. Meter el segundo layout ahi
-- adentro habria mezclado dos cosas que no tienen por que tocarse.
--
-- Aca no se crea ningun frame nuevo: se reubican las piezas que el
-- FrameTemplate.xml ya define ($parentPortrait, $parentHealthBar,
-- $parentManaBar, $parentName, $parentTexture).
--
-- LA FOTO ORIGINAL SE SACA UNA SOLA VEZ
--
-- Es la parte delicada. Si se recapturara al cambiar de estilo, la segunda
-- vez estariamos guardando como "Classic" las medidas del Square, y volver
-- atras dejaria el marco roto. Ya nos paso con las barras de accion, con
-- los movers de PartyBuffs y con los botones del minimapa: una sola foto,
-- sacada antes de tocar nada.
-- =========================================================

local FRAMES     = 4;
local FRAME_NAME = "PartyTargetFrame";

-- Medidas del estilo Square: LAS DE pw, COPIADAS TAL CUAL.
--
-- Vengo de tres intentos deduciendo el layout mirando capturas, y los tres
-- salieron mal. Estas salen de leer styleconfig.square en
-- pw_unitframes/modules/partytarget.lua:
--
--   siz = {w=70, h=75}
--   tex = {w=64, h=64, y=-2}   <- marco cuadrado, TEXTURA propia
--   por = {w=32, h=32, y=9}    <- centrado DENTRO del marco
--   hpb = {w=30, h=10, y=-10}  <- tambien DENTRO del marco
--   mpb = {w=30, h=10}         <- pegada abajo de la de vida
--   nam = {y=46}
--
-- Y el punto que no habia entendido: el marco SI es una caja que contiene
-- todo. Lo que me confundia es que su textura tiene el centro transparente
-- y solo dibuja el contorno grueso, asi que a simple vista parece rodear
-- solo el retrato. Sin esa textura, un borde liso del mismo tamaño se veia
-- como un rectangulo vacio, y por eso lo fui achicando cada vez mas.
--
-- La textura esta copiada en Textures\\TargetOfTargetSquare.tga.
local SQ = {
	frame    = { w = 70, h = 75 },
	border   = { w = 64, h = 64, y = -2 },
	portrait = { size = 32, y = 9 },
	health   = { w = 30, h = 10, y = -10 },
	mana     = { w = 30, h = 10 },
	name     = { w = 84 },
};

local TEXPATH      = "Interface\\AddOns\\Nidhaus_UnitFrames\\Textures\\";
local SQUARE_TEX   = TEXPATH .. "TargetOfTargetSquare.tga";
local BAR_TEX      = TEXPATH .. "beige.tga";              -- media.statusbar de pw
-- El atlas de clases: el del JUEGO, no el de pw.
--
-- Fui y volvi con esto, asi que queda escrito. pw tiene DOS caminos:
--
--   elements/portraits.lua  ->  hook de UnitFramePortrait_Update, usa la
--                               textura propia UI-Classes-Circles
--   modules/partytarget.lua ->  PartyTarget_UpdatePortrait, usa squareicn
--
-- Los party target de pw NO pasan por el primero: son frames que pw crea a
-- mano y a los que llama SetPortraitTexture + PartyTarget_UpdatePortrait
-- directamente. Nunca tocan UnitFramePortrait_Update, asi que el hook no
-- corre para ellos. El que se ve es squareicn:
--
--   Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes
--
-- Que ademas es coherente con el estilo: iconos CUADRADOS para un marco
-- cuadrado. UI-Classes-Circles son redondos y por eso desentonaban.
--
-- (Sin extension: en WoW los .blp se nombran sin ella, el cargador se la
-- agrega solo. Poniendosela a mano el archivo no resuelve.)
local CLASS_ATLAS  = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes";

-- Textura SIN teñir.
--
-- pw le pone SetVertexColor(.22,.22,.22) desde config.global.framecolors,
-- que es su tema general de marcos. SetVertexColor MULTIPLICA los colores,
-- asi que 0.22 deja la imagen al 22% de su brillo: el marco original es
-- claro y quedaba hundido en gris oscuro.
--
-- 1,1,1,1 es el neutro: la textura tal cual la dibujaron.
local FRAME_COLOR  = { 1, 1, 1, 1 };

local orig = {};   -- [frameName] = foto de las medidas de fabrica

-- ---------------------------------------------------------
-- Piezas del marco
-- ---------------------------------------------------------
local function Parts(f)
	local n = f:GetName();
	return _G[n .. "Portrait"],
	       _G[n .. "HealthBar"],
	       _G[n .. "ManaBar"],
	       _G[n .. "Name"],
	       _G[n .. "Texture"];
end

-- Guarda punto, tamaño y (para el retrato) las coordenadas de textura.
local function Snap(region)
	if not region then return nil; end
	local point, relTo, relPoint, x, y = region:GetPoint(1);
	return {
		point = point, relTo = relTo, relPoint = relPoint,
		x = x or 0, y = y or 0,
		w = region:GetWidth(), h = region:GetHeight(),
		shown = region:IsShown(),
		-- La fuente entra en la foto porque Square la cambia a 9 OUTLINE.
		-- Sin esto, volver a Classic dejaba el nombre con la letra del
		-- otro estilo: un cambio que no se deshacia.
		font = region.GetFont and { region:GetFont() } or nil,
	};
end

local function Restore(region, s)
	if not region or not s then return; end
	region:ClearAllPoints();
	if s.point then
		region:SetPoint(s.point, s.relTo, s.relPoint, s.x, s.y);
	end
	if s.w and s.w > 0 then region:SetWidth(s.w); end
	if s.h and s.h > 0 then region:SetHeight(s.h); end
	if s.shown then region:Show(); else region:Hide(); end
	if s.font and s.font[1] and region.SetFont then
		pcall(region.SetFont, region, s.font[1], s.font[2], s.font[3]);
	end
end

local function Capture(f)
	local name = f:GetName();
	if orig[name] then return; end          -- ya esta sacada

	local por, hp, mp, nm, tex = Parts(f);
	orig[name] = {
		frame    = { w = f:GetWidth(), h = f:GetHeight() },
		portrait = Snap(por),
		health   = Snap(hp),
		mana     = Snap(mp),
		name     = Snap(nm),
		texture  = Snap(tex),
	};
end

-- ---------------------------------------------------------
-- El marco cuadrado
--
-- Se reusa $parentTexture, que es el mismo TextureRegion que en Classic
-- lleva el marco dorado de Blizzard. Solo se le cambia la imagen y el
-- tamaño: no hace falta crear nada.
-- ---------------------------------------------------------

-- Fondo de las barras.
--
-- Sin esto las barras PARECIAN mas angostas que el retrato, y no lo eran:
-- una StatusBar solo dibuja la parte llena, asi que a media vida veias
-- media barra flotando y el resto transparente. El original tiene un fondo
-- oscuro detras, que es lo que hace leer el ancho completo.
local function GetBarBG(bar)
	if bar.nufSquareBG then return bar.nufSquareBG; end
	local t = bar:CreateTexture(nil, "BACKGROUND");
	t:SetTexture(0, 0, 0, 0.6);
	t:SetAllPoints(bar);
	bar.nufSquareBG = t;
	return t;
end

-- SIN texto de vida.
--
-- Lo habia agregado por leer mal un comentario tuyo. pw no muestra numeros
-- en el marco de objetivo del grupo, y es coherente: el marco es un icono
-- de un vistazo, no un panel de datos. La barra ya dice cuanta vida queda.
--
-- ---------------------------------------------------------
-- Retrato = icono de CLASE
--
-- ME EQUIVOQUE DE ATLAS. Habia usado el del juego
-- (Glues\\CharacterCreate\\UI-CharacterCreate-Classes) porque es el que
-- nombra partytarget.lua. Pero ese nunca llega a verse: el que manda es el
-- hook de elements/portraits.lua, que corre despues y, con prettyportraits
-- activo, pisa la textura con la propia de pw — UI-Classes-Circles.blp.
--
-- Los dos atlas comparten la misma grilla, asi que CLASS_ICON_TCOORDS sirve
-- para ambos; lo unico que cambia es el dibujo.
--
-- Los que no son jugadores no tienen clase: se quedan con su cara.
-- ---------------------------------------------------------
local FACE_COORDS = { 0.08, 0.92, 0.08, 0.92 };   -- recorte normal de retrato

local function ApplyClassPortrait(f)
	local por = _G[f:GetName() .. "Portrait"];
	if not por then return; end

	local unit = "party" .. f:GetID() .. "target";

	if UnitExists(unit) and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit);
		local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class];
		if coords then
			por:SetTexture(CLASS_ATLAS);
			por:SetTexCoord(unpack(coords));
			return;
		end
	end

	-- Sin clase (bichos, mascotas, o el objetivo todavia sin resolver):
	-- la cara.
	--
	-- OJO: hay que reponer la TEXTURA, no solo el recorte. Aca estaba el
	-- bug de la mancha amarilla: si el retrato venia con el atlas de clases
	-- puesto y solo se le cambiaban las coordenadas, quedaba ese atlas
	-- recortado con 0.08-0.92, o sea un pedazo enorme de una grilla de 4x4
	-- estirado sobre 32 px.
	if UnitExists(unit) then
		SetPortraitTexture(por, unit);
	else
		por:SetTexture(nil);
	end
	por:SetTexCoord(unpack(FACE_COORDS));
end

-- ---------------------------------------------------------
-- Aplicar / quitar
-- ---------------------------------------------------------
local function ApplySquare(f)
	local por, hp, mp, nm, tex = Parts(f);
	if not (por and hp and mp and tex) then return; end

	f:SetSize(SQ.frame.w, SQ.frame.h);

	-- El marco: misma region que en Classic lleva el arte dorado, con otra
	-- imagen y otro tamaño. Gris oscuro, como en pw.
	tex:SetTexture(SQUARE_TEX);
	tex:SetTexCoord(0, 1, 0, 1);
	tex:ClearAllPoints();
	tex:SetSize(SQ.border.w, SQ.border.h);
	tex:SetPoint("CENTER", f, "CENTER", 0, SQ.border.y);
	-- El tinte de Lorti manda sobre el color propio; si esta apagado,
	-- ApplyLortiTint repone el blanco y vale el de siempre.
	if not (K.ApplyLortiTint and K.ApplyLortiTint(tex, "LortiUI_PartyTargets")) then
		tex:SetVertexColor(unpack(FRAME_COLOR));
	end
	tex:Show();

	-- Retrato y barras van DENTRO del marco, posicionados respecto de el.
	por:ClearAllPoints();
	por:SetSize(SQ.portrait.size, SQ.portrait.size);
	por:SetPoint("CENTER", tex, "CENTER", 0, SQ.portrait.y);

	hp:ClearAllPoints();
	hp:SetSize(SQ.health.w, SQ.health.h);
	hp:SetPoint("CENTER", tex, "CENTER", 0, SQ.health.y);

	mp:ClearAllPoints();
	mp:SetSize(SQ.mana.w, SQ.mana.h);
	mp:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, 0);

	-- Textura de las barras: la de pw. La del XML es la de Blizzard, con su
	-- degrade y su brillo; al lado del marco gris desentonaba.
	hp:SetStatusBarTexture(BAR_TEX);
	mp:SetStatusBarTexture(BAR_TEX);

	GetBarBG(hp):Show();
	GetBarBG(mp):Show();

	-- Si el nombre esta oculto por opcion, no hay nada que reposicionar.
	-- Se chequea aca ademas de en StyleNameText porque este layout corre en
	-- UNIT_TARGET, y un Show() nuestro le ganaria al Hide() del otro.
	if nm and PartyTargetsDB and PartyTargetsDB.hideName then
		nm:Hide();
	elseif nm then
		nm:Show();
		-- Anclado al MARCO, no a la barra de vida.
		--
		-- Antes colgaba de la barra con +46 de offset, que son los numeros
		-- de pw. Pero la barra esta descentrada dentro del marco, asi que
		-- el nombre heredaba ese corrimiento y ademas quedaba altisimo.
		-- Colgarlo del cuadrado lo deja centrado y pegado, sin cuentas.
		--
		-- El FontString vive dentro de un sub-frame del XML anclado a la
		-- izquierda: sin ClearAllPoints se queda ahi.
		nm:ClearAllPoints();
		nm:SetWidth(SQ.name.w);
		nm:SetHeight(10);
		nm:SetPoint("BOTTOM", tex, "TOP", 0, -2);
		nm:SetJustifyH("CENTER");
		nm:SetFont("Fonts\\FRIZQT__.TTF", 9);
		nm:SetShadowColor(0, 0, 0, 1);
		nm:SetShadowOffset(1, -1);
		nm:SetTextColor(1, 0.82, 0);
	end

	ApplyClassPortrait(f);
end

local function ApplyClassic(f)
	local s = orig[f:GetName()];
	if not s then return; end

	local por, hp, mp, nm, tex = Parts(f);

	f:SetSize(s.frame.w, s.frame.h);
	Restore(por, s.portrait);
	Restore(hp,  s.health);
	Restore(mp,  s.mana);
	Restore(nm,  s.name);
	Restore(tex, s.texture);
	if nm then nm:SetJustifyH("LEFT"); end

	-- La imagen del marco tambien vuelve: Restore repone punto y tamaño,
	-- pero no la textura ni el tinte.
	if tex then
		tex:SetTexture("Interface\\TargetingFrame\\UI-TargetofTargetFrame");
		if not (K.ApplyLortiTint and K.ApplyLortiTint(tex, "LortiUI_PartyTargets")) then
			tex:SetVertexColor(1, 1, 1);
		end
	end
	-- Y la textura de las barras, que Restore no toca.
	if hp then hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); end
	if mp then mp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); end
	-- En Classic el marco dorado de Blizzard ya hace de fondo: dejar el
	-- nuestro puesto le metia un rectangulo negro detras de las barras.
	if hp and hp.nufSquareBG then hp.nufSquareBG:Hide(); end
	if mp and mp.nufSquareBG then mp.nufSquareBG:Hide(); end

	-- El recorte vuelve al de retrato. La TEXTURA no hace falta reponerla:
	-- SetPortraitTexture la reescribe en la proxima actualizacion del
	-- objetivo, que ocurre enseguida.
	if por then por:SetTexCoord(unpack(FACE_COORDS)); end
end

-- ---------------------------------------------------------
-- API
-- ---------------------------------------------------------
function K.GetPartyTargetStyle()
	local v = PartyTargetsDB and PartyTargetsDB.style;
	return (v == "Square") and "Square" or "Classic";
end

function K.ApplyPartyTargetStyle()
	local square = (K.GetPartyTargetStyle() == "Square");

	for i = 1, FRAMES do
		local f = _G[FRAME_NAME .. i];
		if f then
			-- La foto SIEMPRE primero, incluso al pedir Square: si no,
			-- nunca tendriamos con que volver a Classic.
			Capture(f);
			if square then ApplySquare(f) else ApplyClassic(f) end
		end
	end
end

function K.SetPartyTargetStyle(style)
	if not PartyTargetsDB then PartyTargetsDB = {}; end
	PartyTargetsDB.style = (style == "Square") and "Square" or "Classic";
	K.ApplyPartyTargetStyle();
end

-- ---------------------------------------------------------
-- Reaplicar
--
-- Blizzard reposiciona el retrato y las barras en cada actualizacion del
-- miembro del grupo, asi que aplicar una sola vez al entrar no alcanza:
-- se pierde en cuanto alguien cambia de objetivo.
-- ---------------------------------------------------------
local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("PARTY_MEMBERS_CHANGED");
events:RegisterEvent("UNIT_TARGET");
events:SetScript("OnEvent", function(_, event)
	if K.GetPartyTargetStyle() ~= "Square" then return; end

	K.ApplyPartyTargetStyle();
end);

-- El icono de clase hay que reponerlo CADA VEZ que Blizzard repinta el
-- retrato.
--
-- UnitFrame_OnEvent llama a UnitFramePortrait_Update, que hace
-- SetPortraitTexture y pisa el atlas de clases con la cara del personaje.
-- Aplicarlo solo en UNIT_TARGET no alcanzaba: el orden en que corren dos
-- manejadores del mismo evento no esta garantizado, asi que a veces
-- ganabamos y a veces perdiamos, y el icono aparecia o no segun el dia.
--
-- Engancharse a la funcion que lo pisa saca el azar del medio: corremos
-- siempre despues.
if type(UnitFramePortrait_Update) == "function" then
	hooksecurefunc("UnitFramePortrait_Update", function(self)
		if not self or K.GetPartyTargetStyle() ~= "Square" then return; end
		local n = self.GetName and self:GetName();
		if n and string.find(n, "^PartyTargetFrame%d") then
			ApplyClassPortrait(self);
		end
	end);
end

SLASH_NUFPTSTYLE1 = "/ptstyle";
SlashCmdList["NUFPTSTYLE"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "square" then
		K.SetPartyTargetStyle("Square");
		print("|cff4FC3F7NUF:|r party targets = Square");
	elseif msg == "classic" then
		K.SetPartyTargetStyle("Classic");
		print("|cff4FC3F7NUF:|r party targets = Classic");
	else
		print("|cff4FC3F7NUF:|r /ptstyle square | classic   (ahora: "
			.. K.GetPartyTargetStyle() .. ")");
	end
end
