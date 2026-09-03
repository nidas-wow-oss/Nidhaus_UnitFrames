local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PartyFramePW.lua  -  cuarto estilo de marco de grupo
--
-- Aspecto tomado de pw_unitframes (modules/party.lua). Dos cosas lo
-- distinguen de los otros tres estilos:
--
--   1. La textura del marco, copiada a Media\pw\UI-PartyFrame.blp
--   2. LA POSICION DE LOS TEXTOS. Blizzard pone los numeros de vida y
--      mana centrados en su propia barra; pw los corre al centro del
--      MARCO, a la derecha del retrato, y sube la barra de vida.
--
-- Lo segundo es lo que hace que se lea distinto, mas que la textura.
--
-- Numeros, tal cual salen de pw/modules/party.lua:
--
--     healthbar  TOPLEFT 46, -13    alto 12
--     manabar    TOPLEFT 46, -25
--     texto vida  CENTER del frame  18,  9
--     texto mana  CENTER del frame  18, -1
--
-- =========================================================
-- LA FOTO ORIGINAL SE SACA UNA SOLA VEZ
--
-- Igual que en SquareStyle, BarBaseline y los botones del minimapa: si
-- se recapturara al cambiar de estilo, la segunda vez guardariamos como
-- "original" lo que pusimos nosotros, y volver atras dejaria el marco
-- roto. Es el error que mas veces aparecio en este addon.
-- =========================================================

local MAX_PARTY = MAX_PARTY_MEMBERS or 4;

local PW_DIR   = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\pw\\";

-- DOS VARIANTES DEL MISMO TEMA
--
-- El tema pw trae dos juegos de marco de grupo:
--
--   UI-PartyFrame   -> "Compact"    (el que ya estaba)
--   UI-PartyFrame2  -> "Compact 2"  (el mismo dibujo que usa el tema
--                                    Compact del PlayerFrame)
--
-- La segunda estaba en la carpeta sin usarse. Como todo lo demas del
-- estilo es identico — anclajes, barras, nombre arriba — la unica
-- diferencia es que textura se carga, asi que en vez de duplicar el
-- modulo se elige aca segun el estilo activo.
local function PWTex()
	if K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2" then
		-- LA MISMA TEXTURA QUE EL PLAYERFRAME EN MODO COMPACT.
		--
		-- PlayerFrame.lua, con C.pwFrames puesto, hace exactamente esto:
		--     PlayerFrameTexture:SetTexture(ThemeDir() .. "UI-TargetingFrame")
		-- donde ThemeDir() resuelve a Media\pw\. Asi el grupo queda con el
		-- mismo marco que el jugador y no con una variante parecida.
		return PW_DIR .. "UI-TargetingFrame";
	end
	return PW_DIR .. "UI-PartyFrame";
end

local function PWFlash()
	if K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2" then
		return PW_DIR .. "UI-PartyFrame2-Flash";
	end
	return PW_DIR .. "UI-PARTYFRAME-FLASH";
end

-- SIN TEÑIR.
--
-- pw le pone SetVertexColor(.22,.22,.22) desde config.global.framecolors,
-- su tema general. Lo habia copiado tal cual, pero dejaba el estilo
-- incoherente: los marcos del GRUPO salian oscuros y los de jugador y
-- objetivo — que usan la misma carpeta de texturas — con el brillo normal,
-- porque ahi solo se cambia la ruta y no se tiñe nada.
--
-- 1,1,1,1 es el neutro: la textura tal cual la dibujaron, igual que en el
-- resto del tema.
local PW_COLOR = { 1, 1, 1, 1 };

-- ...SALVO QUE LORTI UI ESTE PUESTO.
--
-- Lorti oscurece los marcos del grupo, y este estilo le pisaba el color
-- con el blanco de arriba: prendias Lorti y en Compact no pasaba nada.
-- Ahora se le pregunta antes de teñir.
local function TintFrame(tex)
	if not tex then return; end
	if not (K.ApplyLortiTint and K.ApplyLortiTint(tex, "LortiUI_Party")) then
		tex:SetVertexColor(unpack(PW_COLOR));
	end
end

local LAYOUT = {
	health    = { x = 46, y = -13, h = 12 },
	mana      = { x = 46, y = -25 },
	healthTxt = { x = 18, y =  9 },
	manaTxt   = { x = 18, y = -1 },
};

-- ---------------------------------------------------------
-- AJUSTE DE COMPACT 2
--
-- UI-TargetingFrame esta dibujada para el marco del jugador, que es mas
-- grande y con otras proporciones que el de un compañero. Puesta tal cual
-- en el marco de grupo, el arte quedaba corto y las barras se salian por
-- la derecha.
--
-- Estos numeros la reacomodan. Son los UNICOS que hay que tocar si algo
-- queda corrido: el resto del estilo no cambia.
--
--   tex   = tamaño y posicion del arte del marco
--   bars  = ancho de las barras de vida y mana, y donde arrancan
--   ring  = tamaño y posicion del retrato, para que caiga dentro del aro
-- ---------------------------------------------------------
-- LA RECETA SALE DE ARENA.
--
-- UI-TargetingFrame es el arte del marco grande. Los marcos de arena
-- la usan en un espacio chico y se ve bien porque la RECORTAN antes de
-- dibujarla (ArenaFrame.lua):
--
--     tex:SetTexCoord(0.09375, 1.0, 0, 0.78125)
--     tex:SetSize(124, 48)
--
-- Sin ese recorte la imagen entra entera en un marco chico y queda
-- apretada; forzandole un tamaño mayor, se estira. Recortada y con el
-- tamaño correcto, se dibuja en su proporcion.
--
-- Aca ademas va espejada, porque el retrato del marco de grupo va a la
-- izquierda: invertir el primer par de coordenadas (1.0 y 0.09375 al
-- reves) da vuelta la imagen sin tocar el recorte.
local PW2 = {
	crop = { 1.0, 0.09375, 0, 0.78125 },
	-- CORRIMIENTO DE TODO EL BLOQUE.
	--
	-- Se suma al X del marco, del retrato y de las barras a la vez, asi
	-- que mueve el conjunto sin desarmar el encuadre entre ellos.
	--
	-- Existe porque el icono de PvP no lo toca este estilo: queda donde
	-- lo ancla Blizzard, pegado al borde izquierdo del marco, y el resto
	-- del contenido quedaba corrido a la derecha con un hueco en medio.
	-- Negativo = a la izquierda.
	blockX = -17,
	tex  = { w = 121, h = 52, x = 0, y = 0 },
	-- hh / mh = ALTO de la barra de vida y de la de mana.
	bars = { w = 61,  x = 57, hy = -13, my = -27, hh = 14, mh = 6 },
	-- Retrato: lado del cuadrado y donde arranca respecto de la esquina
	-- superior izquierda del marco. De fabrica el del grupo mide 37x37.
	portrait = { size = 30, x = 25, y = -8 },
	-- FONDO: el que YA TRAE el marco, no uno nuevo.
	--
	-- El marco de grupo viene con su propia textura de fondo detras de
	-- las barras. Al principio yo le agregaba una segunda encima, y
	-- terminabas con dos fondos. Ahora se busca la de fabrica y se le
	-- cambian estos numeros:
	--
	--   x / y  = corrimiento respecto de donde la deja el juego
	--   w / h  = tamaño (0 = dejarlo como viene)
	--   alpha  = opacidad de 0 a 100
	-- Medido a mano sobre los marcos, con la ventana de /nufpw2. Con x=12 y
	-- w=45 el fondo arrancaba a la derecha del retrato y le dejaba el
	-- hueco a la vista. Corrido 17 a la izquierda y ensanchado 16, el
	-- borde derecho queda donde estaba y el retrato deja de sobresalir.
	bg = { x = -5, y = -2, w = 61, h = 21, alpha = 94 },
};

-- Cuanto bajan los buffs y debuffs de Blizzard, en pixeles.
--
-- Compact sube la barra de vida y la de mana (mira LAYOUT: -13 y -25,
-- contra el -19 y -32 de Blizzard), pero los iconos de aura se quedan
-- donde estaban y terminan pisando el borde de abajo del marco.
--
-- El corrimiento se calcula SIEMPRE contra el anclaje de fabrica
-- guardado en la foto, nunca contra donde esta el icono ahora. Si se
-- hiciera "posicion actual - 2", cada vez que Blizzard actualiza al
-- compañero el icono bajaria dos pixeles mas, y en un rato estaria
-- abajo de todo.
local AURA_DROP = -2;

-- Compact 2 usa un arte mas alto (62 contra los ~49 del marco normal),
-- asi que sus iconos de aura tienen que bajar bastante mas o quedan
-- pisando el borde de abajo del marco.
local AURA_DROP_PW2 = -63;

-- TEXTOS DE VIDA Y MANA COMO LOS DE ARENA.
--
-- Los marcos de arena escriben los numeros CENTRADOS EN SU BARRA y con
-- una fuente chica (ArenaFrame.lua):
--
--     healthbar.TextString:SetPoint("CENTER", healthbar)
--     manabar.TextString:SetPoint("CENTER", manabar)
--     SetFont(unpack(C.ArenaFrameFont or {"Fonts\\FRIZQT__.TTF", 7, "OUTLINE"}))
--
-- pw en cambio los apila los dos en el centro del MARCO (LAYOUT.healthTxt
-- y manaTxt), que con el marco angosto de Compact 2 los dejaba encimados
-- y con la fuente grande de Blizzard.
--
-- Compact 2 usa la receta de arena, y la MISMA config: si cambias la
-- fuente de los marcos de arena, el grupo la sigue.
local function ArenaTextFont()
	return C.ArenaFrameFont or { "Fonts\\FRIZQT__.TTF", 7, "OUTLINE" };
end

local function AuraDrop()
	if K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2" then
		return AURA_DROP_PW2;
	end
	return AURA_DROP;
end

local orig = {};      -- [frameName] = foto de fabrica
local applied = false;

-- ---------------------------------------------------------
-- Foto / restauracion
-- ---------------------------------------------------------
local function SnapPoint(region)
	if not region then return nil; end
	local point, relTo, relPoint, x, y = region:GetPoint(1);
	if not point then return nil; end
	return {
		point = point, relTo = relTo, relPoint = relPoint,
		x = x or 0, y = y or 0,
		h = region:GetHeight(),
	};
end

local function RestorePoint(region, s)
	if not region or not s then return; end
	region:ClearAllPoints();
	region:SetPoint(s.point, s.relTo, s.relPoint, s.x, s.y);
	if s.h and s.h > 0 and region.SetHeight then region:SetHeight(s.h); end
end

-- Busca la textura de fondo del marco: primero por el nombre que usa
-- Blizzard, y si no aparece, la primera textura cuyo archivo diga
-- "background". Se cachea en el propio frame.
local function FindFrameBG(f, fn)
	if f.nufBGRegion then return f.nufBGRegion; end

	local byName = _G[fn .. "Background"];
	if byName then f.nufBGRegion = byName; return byName; end

	for _, r in ipairs({ f:GetRegions() }) do
		if r.GetTexture and r.GetObjectType and r:GetObjectType() == "Texture" then
			local tx = r:GetTexture();
			if type(tx) == "string" and string.find(string.lower(tx), "background") then
				f.nufBGRegion = r;
				return r;
			end
		end
	end
	return nil;
end

local function Capture(i)
	local fn = "PartyMemberFrame" .. i;
	if orig[fn] then return; end

	local hp  = _G[fn .. "HealthBar"];
	local mp  = _G[fn .. "ManaBar"];
	local tex = _G[fn .. "Texture"];
	local fl  = _G[fn .. "Flash"];

	orig[fn] = {
		health    = SnapPoint(hp),
		mana      = SnapPoint(mp),
		healthTxt = hp and SnapPoint(hp.TextString) or nil,
		manaTxt   = mp and SnapPoint(mp.TextString) or nil,
		-- Compact 2 les cambia la fuente, asi que hay con que volver.
		healthFont = (hp and hp.TextString) and { hp.TextString:GetFont() } or nil,
		manaFont   = (mp and mp.TextString) and { mp.TextString:GetFont() } or nil,
		-- El nombre se mueve ARRIBA del marco en este estilo, asi que hay
		-- que guardar de donde venia para poder devolverlo.
		name      = SnapPoint(_G[fn .. "Name"]),
		texPath   = tex and tex:GetTexture() or nil,
		-- Compact 2 cambia tamaño y anclaje del arte, y el ancho de las
		-- barras: sin esto no habia con que volver atras.
		texSize   = tex and { tex:GetWidth(), tex:GetHeight() } or nil,
		texPoint  = SnapPoint(tex),
		hpW       = hp and hp:GetWidth() or nil,
		hpTex     = (hp and hp.GetStatusBarTexture and hp:GetStatusBarTexture()
		             and hp:GetStatusBarTexture():GetTexture()) or nil,
		mpTex     = (mp and mp.GetStatusBarTexture and mp:GetStatusBarTexture()
		             and mp:GetStatusBarTexture():GetTexture()) or nil,
		portPoint = SnapPoint(_G[fn .. "Portrait"]),
		portSize  = _G[fn .. "Portrait"] and { _G[fn .. "Portrait"]:GetWidth(), _G[fn .. "Portrait"]:GetHeight() } or nil,
		mpW       = mp and mp:GetWidth() or nil,
		flashPath = fl and fl:GetTexture() or nil,
		buff1     = SnapPoint(_G[fn .. "Buff1"]),
		debuff1   = SnapPoint(_G[fn .. "Debuff1"]),
	};
end

-- ---------------------------------------------------------
-- Bajar un icono de aura respecto de su anclaje de fabrica
--
-- Se salta los que Blizzard encadeno a OTRO icono: ese otro ya se
-- movio y volver a bajar este lo bajaria dos veces. Asi la funcion
-- no depende de como esten encadenados los cuatro buffs entre si.
-- ---------------------------------------------------------
local function DropAura(fn, suffix, s)
	if not s then return; end
	local r = _G[fn .. suffix];
	if not r then return; end
	if s.relTo ~= _G[fn] then return; end

	r:ClearAllPoints();
	r:SetPoint(s.point, s.relTo, s.relPoint, s.x, s.y + AuraDrop());
end

-- ---------------------------------------------------------
-- Aplicar
-- ---------------------------------------------------------
local function StyleOne(i)
	local fn = "PartyMemberFrame" .. i;
	local f  = _G[fn];
	if not f then return; end

	Capture(i);

	local tex = _G[fn .. "Texture"];
	if tex then
		tex:SetTexture(PWTex());
		TintFrame(tex);

		-- COMPACT 2 VA ESPEJADA.
		--
		-- UI-TargetingFrame esta dibujada para el marco del OBJETIVO, con
		-- el retrato a la derecha. El PlayerFrame la usa dada vuelta: eso
		-- lo hace Blizzard en el XML de ese marco, no la textura.
		--
		-- El marco de grupo no la voltea, asi que salia al reves —
		-- el aro dorado del retrato caia del lado de las barras.
		-- Invertir la coordenada horizontal (1,0 en vez de 0,1) la deja
		-- igual que la del jugador.
		local isPW2 = (K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2");
		if isPW2 then
			-- Recortada y espejada, igual que en arena (ver PW2 arriba).
			tex:SetTexCoord(unpack(PW2.crop));
			tex:ClearAllPoints();
			tex:SetPoint("TOPLEFT", f, "TOPLEFT", PW2.tex.x + PW2.blockX, PW2.tex.y);
			tex:SetSize(PW2.tex.w, PW2.tex.h);
		else
			tex:SetTexCoord(0, 1, 0, 1);
		end
	end

	local fl = _G[fn .. "Flash"];
	if fl then fl:SetTexture(PWFlash()); end

	-- A la mascota no le cambiamos la textura: es otra distinta y ponerle
	-- la del grupo desalinearia el marco chico. Solo la dejamos en neutro
	-- por si venia teñida de otro estilo.
	local petTex = _G[fn .. "PetFrameTexture"];
	TintFrame(petTex);

	local isPW2b = (K.GetPartyFrameStyle and K.GetPartyFrameStyle() == "PW2");

	local hp = _G[fn .. "HealthBar"];
	if hp then
		hp:ClearAllPoints();
		if isPW2b then
			hp:SetPoint("TOPLEFT", f, "TOPLEFT", PW2.bars.x + PW2.blockX, PW2.bars.hy);
			hp:SetWidth(PW2.bars.w);
			hp:SetHeight(PW2.bars.hh);
		else
			hp:SetPoint("TOPLEFT", f, "TOPLEFT", LAYOUT.health.x, LAYOUT.health.y);
		end
		if not isPW2b then hp:SetHeight(LAYOUT.health.h); end
		if hp.TextString then
			hp.TextString:ClearAllPoints();
			if isPW2b then
				hp.TextString:SetPoint("CENTER", hp);
				hp.TextString:SetFont(unpack(ArenaTextFont()));
			else
				hp.TextString:SetPoint("CENTER", f, "CENTER",
					LAYOUT.healthTxt.x, LAYOUT.healthTxt.y);
			end
		end
	end

	-- TEXTURA DE LAS BARRAS: LA MISMA QUE ARENA.
	--
	-- Los marcos de arena usan C.statusbarTexture cuando C.statusbarOn
	-- esta puesto (ArenaFrame.lua). Compact 2 hace lo mismo para que el
	-- grupo y los enemigos se vean del mismo material, en vez de mezclar
	-- la barra de Blizzard con la del addon.
	if isPW2b and C.statusbarOn and C.statusbarTexture then
		if hp then hp:SetStatusBarTexture(C.statusbarTexture); end
		local mpBar = _G[fn .. "ManaBar"];
		if mpBar then mpBar:SetStatusBarTexture(C.statusbarTexture); end
	end

	-- NOMBRE ARRIBA DEL MARCO
	--
	-- Mismo anclaje que usa el estilo Custom de arena en ArenaFrame.lua:
	--     frame.name:SetPoint("BOTTOM", frame.healthbar, "TOP", 0, 1)
	--
	-- En el estilo compacto el marco es angosto y el nombre encima de la
	-- barra de vida se comia los numeros. Sacandolo arriba se leen las dos
	-- cosas, y ademas queda igual que los marcos de arena, que es como se
	-- ve el conjunto cuando tenes party y arena en pantalla a la vez.
	local nameFS = _G[fn .. "Name"];
	if nameFS and hp then
		nameFS:ClearAllPoints();
		-- +2 y no el +1 de pw: con el nombre ARRIBA del marco un pixel de
		-- aire mas lo despega del borde superior de la barra de vida.
		nameFS:SetPoint("BOTTOM", hp, "TOP", 0, 2);
	end

	-- FONDO DEL MARCO
	--
	-- El que ya trae el marco de grupo, no uno agregado. Se lo busca por
	-- nombre y, si ese no existe, recorriendo las texturas del frame:
	-- asi funciona sin depender de como se llame en cada version.
	--
	-- Se guarda su posicion de fabrica la primera vez, asi los
	-- corrimientos son SIEMPRE contra ese punto y no se van acumulando
	-- cada vez que se re-estila el marco.
	local bg = FindFrameBG(f, fn);
	if bg and isPW2b then
		if not bg.nufBase then
			bg.nufBase = {
				point = { bg:GetPoint(1) },
				w = bg:GetWidth(), h = bg:GetHeight(),
				alpha = bg:GetAlpha(),
			};
		end
		local b = bg.nufBase;
		if b.point[1] then
			bg:ClearAllPoints();
			bg:SetPoint(b.point[1], b.point[2], b.point[3],
				(b.point[4] or 0) + PW2.bg.x, (b.point[5] or 0) + PW2.bg.y);
		end
		if PW2.bg.w > 0 then bg:SetWidth(PW2.bg.w); elseif b.w then bg:SetWidth(b.w); end
		if PW2.bg.h > 0 then bg:SetHeight(PW2.bg.h); elseif b.h then bg:SetHeight(b.h); end
		bg:SetAlpha(PW2.bg.alpha / 100);
	elseif bg and bg.nufBase then
		local b = bg.nufBase;
		if b.point[1] then
			bg:ClearAllPoints();
			bg:SetPoint(unpack(b.point));
		end
		if b.w then bg:SetWidth(b.w); end
		if b.h then bg:SetHeight(b.h); end
		bg:SetAlpha(b.alpha or 1);
	end

	-- Retrato: solo en Compact 2, que es el que cambia el marco de lugar.
	local port = _G[fn .. "Portrait"];
	if port and isPW2b then
		port:ClearAllPoints();
		port:SetPoint("TOPLEFT", f, "TOPLEFT", PW2.portrait.x + PW2.blockX, PW2.portrait.y);
		port:SetSize(PW2.portrait.size, PW2.portrait.size);
	end

	local mp = _G[fn .. "ManaBar"];
	if mp then
		mp:ClearAllPoints();
		if isPW2b then
			mp:SetPoint("TOPLEFT", f, "TOPLEFT", PW2.bars.x + PW2.blockX, PW2.bars.my);
			mp:SetWidth(PW2.bars.w);
			mp:SetHeight(PW2.bars.mh);
		else
			mp:SetPoint("TOPLEFT", f, "TOPLEFT", LAYOUT.mana.x, LAYOUT.mana.y);
		end
		if mp.TextString then
			mp.TextString:ClearAllPoints();
			if isPW2b then
				mp.TextString:SetPoint("CENTER", mp);
				mp.TextString:SetFont(unpack(ArenaTextFont()));
			else
				mp.TextString:SetPoint("CENTER", f, "CENTER",
					LAYOUT.manaTxt.x, LAYOUT.manaTxt.y);
			end
		end
	end

	-- Los buffs y debuffs de Blizzard, un par de pixeles mas abajo.
	--
	-- Solo cuando el modulo PartyBuffs esta APAGADO. Con el prendido
	-- esos anclajes son suyos (los reparte el, guarda los de fabrica y
	-- los devuelve al apagarse); moverlos desde aca seria el problema
	-- de siempre, dos duenos del mismo numero peleandose.
	if not (K.IsPartyBuffsActive and K.IsPartyBuffsActive()) then
		DropAura(fn, "Buff1", orig[fn].buff1);
		DropAura(fn, "Debuff1", orig[fn].debuff1);
	end
end

local function RestoreOne(i)
	local fn = "PartyMemberFrame" .. i;
	local s  = orig[fn];
	if not s then return; end

	local tex = _G[fn .. "Texture"];
	if tex then
		if s.texPath then tex:SetTexture(s.texPath); end
		-- Compact 2 la deja espejada: al salir del estilo hay que devolver
		-- las coordenadas o el marco de Blizzard queda al reves.
		tex:SetTexCoord(0, 1, 0, 1);
		if s.texSize then tex:SetSize(s.texSize[1], s.texSize[2]); end
		RestorePoint(tex, s.texPoint);
		-- Neutro por las dudas. Hoy Compact ya no tiñe, pero el color no
		-- forma parte de la foto de fabrica, asi que si algun dia otro
		-- estilo lo tocara esto lo deja limpio igual.
		tex:SetVertexColor(1, 1, 1);
	end

	local fl = _G[fn .. "Flash"];
	if fl and s.flashPath then fl:SetTexture(s.flashPath); end

	local petTex = _G[fn .. "PetFrameTexture"];
	if petTex then petTex:SetVertexColor(1, 1, 1); end

	local hp = _G[fn .. "HealthBar"];
	RestorePoint(hp, s.health);
	if hp and s.hpW then hp:SetWidth(s.hpW); end
	if hp and s.hpTex then hp:SetStatusBarTexture(s.hpTex); end


	-- EL FONDO VUELVE A COMO VENIA.
	--
	-- Importa para el estilo Blizzard: ahi no se toca absolutamente nada
	-- del marco, asi que si Compact 2 le habia movido el fondo, hay que
	-- devolverlo antes de soltarlo.
	local pf = _G[fn];
	local bgR = pf and FindFrameBG(pf, fn);
	if bgR and bgR.nufBase then
		local b = bgR.nufBase;
		if b.point[1] then
			bgR:ClearAllPoints();
			bgR:SetPoint(unpack(b.point));
		end
		if b.w then bgR:SetWidth(b.w); end
		if b.h then bgR:SetHeight(b.h); end
		bgR:SetAlpha(b.alpha or 1);
	end

	local port = _G[fn .. "Portrait"];
	RestorePoint(port, s.portPoint);
	if port and s.portSize then port:SetSize(s.portSize[1], s.portSize[2]); end
	if hp then RestorePoint(hp.TextString, s.healthTxt); end
	if hp and hp.TextString and s.healthFont and s.healthFont[1] then
		hp.TextString:SetFont(unpack(s.healthFont));
	end

	-- El nombre vuelve adentro del marco.
	RestorePoint(_G[fn .. "Name"], s.name);

	local mp = _G[fn .. "ManaBar"];
	RestorePoint(mp, s.mana);
	if mp and s.mpW then mp:SetWidth(s.mpW); end
	if mp and s.mpTex then mp:SetStatusBarTexture(s.mpTex); end
	if mp then RestorePoint(mp.TextString, s.manaTxt); end
	if mp and mp.TextString and s.manaFont and s.manaFont[1] then
		mp.TextString:SetFont(unpack(s.manaFont));
	end

	-- Las auras vuelven a su anclaje de fabrica, sin el corrimiento.
	RestorePoint(_G[fn .. "Buff1"], s.buff1);
	RestorePoint(_G[fn .. "Debuff1"], s.debuff1);
end

-- ---------------------------------------------------------
-- API para el coordinador de estilos
-- ---------------------------------------------------------
function K.EnablePartyFramePW()
	applied = true;
	for i = 1, MAX_PARTY do StyleOne(i); end
end

function K.DisablePartyFramePW()
	if not applied then return; end
	applied = false;
	for i = 1, MAX_PARTY do RestoreOne(i); end
end

function K.IsPartyFramePWActive()
	return applied;
end

-- ---------------------------------------------------------
-- Reaplicar
--
-- Blizzard repinta el marco y reposiciona las barras en cada
-- actualizacion del miembro del grupo y al entrar o salir de vehiculo.
-- Sin estos hooks, el estilo se pierde en cuanto alguien recibe un
-- golpe. Es lo mismo que ya hacen NewPartyFrame y Improved.
-- ---------------------------------------------------------
local function Reapply()
	if not applied then return; end
	if InCombatLockdown() then return; end
	for i = 1, MAX_PARTY do StyleOne(i); end
end

if type(PartyMemberFrame_UpdateMember) == "function" then
	hooksecurefunc("PartyMemberFrame_UpdateMember", Reapply);
end
if type(PartyMemberFrame_ToPlayerArt) == "function" then
	hooksecurefunc("PartyMemberFrame_ToPlayerArt", Reapply);
end

-- =========================================================
-- /nufpw2  -  ajuste en vivo de las medidas de Compact 2
--
-- Cambiar numeros a ojo, recargar, mirar, repetir, es lento y encima
-- hay que verlo en pantalla para saber si quedo bien. Con esto se
-- mueven en el momento y quedan guardados en la DB del addon, asi que
-- sobreviven al /reload sin tocar el archivo.
--
--   /nufpw2                      -> muestra los valores actuales
--   /nufpw2 tex 134 52 -4 3      -> ancho, alto, x, y del marco
--   /nufpw2 bars 76 46 -13 -25   -> ancho, x, y de vida, y de mana
--   /nufpw2 aura -16             -> cuanto bajan los iconos de aura
--   /nufpw2 reset                -> vuelve a los valores de fabrica
-- =========================================================
local PW2_DEFAULTS = {
	tex  = { PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y },
	bars = { PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my, PW2.bars.hh, PW2.bars.mh },
	aura = AURA_DROP_PW2,
	portrait = { PW2.portrait.size, PW2.portrait.x, PW2.portrait.y },
	bg = { PW2.bg.x, PW2.bg.y, PW2.bg.w, PW2.bg.h, PW2.bg.alpha },
	blockX = PW2.blockX,
};

local function PW2DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	NidhausUnitFramesDB.PW2 = NidhausUnitFramesDB.PW2 or {};
	return NidhausUnitFramesDB.PW2;
end

local function PW2Load()
	local db = PW2DB();
	if db.tex then
		PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y = unpack(db.tex);
	end
	if db.bars then
		local w, x, hy, my, hh, mh = unpack(db.bars);
		PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my = w, x, hy, my;
		-- hh y mh son mas nuevos: si vienen de una config vieja, no estan.
		PW2.bars.hh = hh or PW2.bars.hh;
		PW2.bars.mh = mh or PW2.bars.mh;
	end
	if db.aura then AURA_DROP_PW2 = db.aura; end
	-- El fondo cambio de formato: antes eran 4 numeros (pad, alpha, x, y)
	-- de la version que agregaba una textura propia. Los de 4 se descartan
	-- para no leer un ancho o un alto que no significan nada.
	if db.blockX then PW2.blockX = db.blockX; end
	if db.bg and #db.bg >= 5 then
		local bx, by, bw, bh, ba = unpack(db.bg);
		PW2.bg.x, PW2.bg.y = bx or 0, by or 0;
		PW2.bg.w, PW2.bg.h = bw or 0, bh or 0;
		PW2.bg.alpha = ba or 100;
	end
	if db.portrait then
		PW2.portrait.size, PW2.portrait.x, PW2.portrait.y = unpack(db.portrait);
	end
end

local function PW2Apply()
	if not applied then return; end
	for i = 1, MAX_PARTY do StyleOne(i); end
end

local function PW2Print()
	print("|cff4FC3F7NUF Compact 2|r");
	print(string.format("  tex  %d %d %d %d", PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y));
	print(string.format("  bars %d %d %d %d", PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my));
	print(string.format("  aura %d", AURA_DROP_PW2));
	print(string.format("  portrait %d %d %d",
		PW2.portrait.size, PW2.portrait.x, PW2.portrait.y));
end

SLASH_NUFPW21 = "/nufpw2";
SlashCmdList["NUFPW2"] = function(msg)
	local args = {};
	for w in tostring(msg or ""):gmatch("%S+") do args[#args + 1] = w; end
	local cmd = string.lower(args[1] or "");

	if cmd == "" then
		-- Sin argumentos abre la ventana con botones, que es como se usa
		-- esto en la practica. Los comandos de texto quedan para quien
		-- prefiera tipear.
		if K.TogglePW2Panel then K.TogglePW2Panel(); end
		return;
	end

	if cmd == "reset" then
		local db = PW2DB();
		db.tex, db.bars, db.aura, db.portrait, db.bg, db.blockX = nil, nil, nil, nil, nil, nil;
		PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y = unpack(PW2_DEFAULTS.tex);
		PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my, PW2.bars.hh, PW2.bars.mh = unpack(PW2_DEFAULTS.bars);
		AURA_DROP_PW2 = PW2_DEFAULTS.aura;
		PW2.portrait.size, PW2.portrait.x, PW2.portrait.y = unpack(PW2_DEFAULTS.portrait);
		PW2.bg.x, PW2.bg.y, PW2.bg.w, PW2.bg.h, PW2.bg.alpha = unpack(PW2_DEFAULTS.bg);
		PW2.blockX = PW2_DEFAULTS.blockX;
		PW2Apply(); PW2Print();
		return;
	end

	if cmd == "tex" and args[5] then
		local w, h, x, y = tonumber(args[2]), tonumber(args[3]), tonumber(args[4]), tonumber(args[5]);
		if w and h and x and y then
			PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y = w, h, x, y;
			PW2DB().tex = { w, h, x, y };
			PW2Apply(); PW2Print();
		end
		return;
	end

	if cmd == "bars" and args[5] then
		local w, x, hy, my = tonumber(args[2]), tonumber(args[3]), tonumber(args[4]), tonumber(args[5]);
		if w and x and hy and my then
			PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my = w, x, hy, my;
			PW2DB().bars = { w, x, hy, my };
			PW2Apply(); PW2Print();
		end
		return;
	end

	if cmd == "portrait" and args[4] then
		local s, x, y = tonumber(args[2]), tonumber(args[3]), tonumber(args[4]);
		if s and x and y then
			PW2.portrait.size, PW2.portrait.x, PW2.portrait.y = s, x, y;
			PW2DB().portrait = { s, x, y };
			PW2Apply(); PW2Print();
		end
		return;
	end

	if cmd == "aura" and args[2] then
		local v = tonumber(args[2]);
		if v then
			AURA_DROP_PW2 = v;
			PW2DB().aura = v;
			PW2Apply(); PW2Print();
		end
		return;
	end

	print("|cff4FC3F7NUF:|r /nufpw2 tex <w h x y> | bars <w x hy my> | portrait <lado x y> | aura <n> | reset");
end

-- Los valores guardados se cargan al entrar, antes de aplicar el estilo.
local pw2Init = CreateFrame("Frame");
pw2Init:RegisterEvent("PLAYER_LOGIN");
pw2Init:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	PW2Load();
	PW2Apply();
end);

-- =========================================================
-- VENTANA DE AJUSTE  (/nufpw2)
--
-- Escribir numeros a mano para acomodar un marco es lento y a ciegas.
-- Esta ventana tiene una fila por valor, con botones de -5 -1 +1 +5:
-- se aprieta, se ve el resultado al instante sobre los cuatro marcos,
-- y queda guardado.
-- =========================================================
local panel;

local ROWS = {
	{ label = "TODO  X",       get = function() return PW2.blockX end,
	  set = function(v) PW2.blockX = v end, key = "block" },

	{ label = "Marco  ancho",  get = function() return PW2.tex.w end,
	  set = function(v) PW2.tex.w = v end, key = "tex" },
	{ label = "Marco  alto",   get = function() return PW2.tex.h end,
	  set = function(v) PW2.tex.h = v end, key = "tex" },
	{ label = "Marco  X",      get = function() return PW2.tex.x end,
	  set = function(v) PW2.tex.x = v end, key = "tex" },
	{ label = "Marco  Y",      get = function() return PW2.tex.y end,
	  set = function(v) PW2.tex.y = v end, key = "tex" },

	{ label = "Barras  ancho", get = function() return PW2.bars.w end,
	  set = function(v) PW2.bars.w = v end, key = "bars" },
	{ label = "Barras  X",     get = function() return PW2.bars.x end,
	  set = function(v) PW2.bars.x = v end, key = "bars" },
	{ label = "Vida  Y",       get = function() return PW2.bars.hy end,
	  set = function(v) PW2.bars.hy = v end, key = "bars" },
	{ label = "Mana  Y",       get = function() return PW2.bars.my end,
	  set = function(v) PW2.bars.my = v end, key = "bars" },

	{ label = "Vida  alto",    get = function() return PW2.bars.hh end,
	  set = function(v) PW2.bars.hh = v end, key = "bars" },
	{ label = "Mana  alto",    get = function() return PW2.bars.mh end,
	  set = function(v) PW2.bars.mh = v end, key = "bars" },

	{ label = "Retrato  lado", get = function() return PW2.portrait.size end,
	  set = function(v) PW2.portrait.size = v end, key = "portrait" },
	{ label = "Retrato  X",    get = function() return PW2.portrait.x end,
	  set = function(v) PW2.portrait.x = v end, key = "portrait" },
	{ label = "Retrato  Y",    get = function() return PW2.portrait.y end,
	  set = function(v) PW2.portrait.y = v end, key = "portrait" },

	{ label = "Fondo  ancho",  get = function() return PW2.bg.w end,
	  set = function(v) PW2.bg.w = math.max(0, v) end, key = "bg" },
	{ label = "Fondo  alto",   get = function() return PW2.bg.h end,
	  set = function(v) PW2.bg.h = math.max(0, v) end, key = "bg" },
	{ label = "Fondo  opacidad", get = function() return PW2.bg.alpha end,
	  set = function(v) PW2.bg.alpha = math.max(0, math.min(100, v)) end, key = "bg" },

	{ label = "Fondo  X",      get = function() return PW2.bg.x end,
	  set = function(v) PW2.bg.x = v end, key = "bg" },
	{ label = "Fondo  Y",      get = function() return PW2.bg.y end,
	  set = function(v) PW2.bg.y = v end, key = "bg" },

	{ label = "Auras  Y",      get = function() return AURA_DROP_PW2 end,
	  set = function(v) AURA_DROP_PW2 = v end, key = "aura" },
};

-- Guarda en la DB el grupo que se acaba de tocar.
local function PW2Save(key)
	local db = PW2DB();
	if key == "tex" then
		db.tex = { PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y };
	elseif key == "bars" then
		db.bars = { PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my, PW2.bars.hh, PW2.bars.mh };
	elseif key == "portrait" then
		db.portrait = { PW2.portrait.size, PW2.portrait.x, PW2.portrait.y };
	elseif key == "block" then
		db.blockX = PW2.blockX;
	elseif key == "bg" then
		db.bg = { PW2.bg.x, PW2.bg.y, PW2.bg.w, PW2.bg.h, PW2.bg.alpha };
	elseif key == "aura" then
		db.aura = AURA_DROP_PW2;
	end
end

local function BuildPanel()
	if panel then return panel; end

	panel = CreateFrame("Frame", "NUF_PW2Panel", UIParent);
	panel:SetSize(320, 40 + (#ROWS * 24) + 44);
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	panel:SetFrameStrata("DIALOG");
	panel:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	});
	panel:EnableMouse(true);
	panel:SetMovable(true);
	panel:RegisterForDrag("LeftButton");
	panel:SetScript("OnDragStart", panel.StartMoving);
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing);

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	title:SetPoint("TOP", panel, "TOP", 0, -14);
	title:SetText("Compact 2  -  ajuste de marcos");

	local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton");
	close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4);

	local y = -38;
	for _, row in ipairs(ROWS) do
		local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
		fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, y - 4);
		fs:SetText(row.label);

		local val = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		val:SetPoint("TOPLEFT", panel, "TOPLEFT", 132, y - 4);
		val:SetWidth(34);
		val:SetJustifyH("CENTER");
		row.valFS = val;

		local function Step(delta)
			row.set(row.get() + delta);
			PW2Save(row.key);
			PW2Apply();
			val:SetText(tostring(row.get()));
		end

		local xs = { { -5, "-5", 172 }, { -1, "-", 208 }, { 1, "+", 240 }, { 5, "+5", 272 } };
		for _, b in ipairs(xs) do
			local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
			btn:SetSize((b[2] == "-" or b[2] == "+") and 28 or 32, 20);
			btn:SetPoint("TOPLEFT", panel, "TOPLEFT", b[3], y);
			btn:SetText(b[2]);
			btn:SetScript("OnClick", function() Step(b[1]); end);
		end

		val:SetText(tostring(row.get()));
		y = y - 24;
	end

	local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate");
	reset:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 14);
	reset:SetSize(120, 22);
	reset:SetText("Valores de fabrica");
	reset:SetScript("OnClick", function()
		local db = PW2DB();
		db.tex, db.bars, db.aura, db.portrait, db.bg, db.blockX = nil, nil, nil, nil, nil, nil;
		PW2.tex.w, PW2.tex.h, PW2.tex.x, PW2.tex.y = unpack(PW2_DEFAULTS.tex);
		PW2.bars.w, PW2.bars.x, PW2.bars.hy, PW2.bars.my, PW2.bars.hh, PW2.bars.mh = unpack(PW2_DEFAULTS.bars);
		PW2.portrait.size, PW2.portrait.x, PW2.portrait.y = unpack(PW2_DEFAULTS.portrait);
		PW2.bg.x, PW2.bg.y, PW2.bg.w, PW2.bg.h, PW2.bg.alpha = unpack(PW2_DEFAULTS.bg);
		PW2.blockX = PW2_DEFAULTS.blockX;
		AURA_DROP_PW2 = PW2_DEFAULTS.aura;
		PW2Apply();
		for _, r in ipairs(ROWS) do r.valFS:SetText(tostring(r.get())); end
	end);

	local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
	hint:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -18, 20);
	hint:SetText("se aplica al instante");

	return panel;
end

function K.TogglePW2Panel()
	BuildPanel();
	if panel:IsShown() then
		panel:Hide();
	else
		for _, r in ipairs(ROWS) do r.valFS:SetText(tostring(r.get())); end
		panel:Show();
	end
end
