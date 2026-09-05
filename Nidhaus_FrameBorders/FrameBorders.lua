local ADDON, ns = ...;

-- =========================================================
-- FrameBorders.lua  --  el filo y el halo
--
-- COMO SE ARMA EL EDGEFILE. Cada .tga es una tira de OCHO casillas
-- cuadradas, en el orden que espera SetBackdrop: izquierda, derecha,
-- arriba, abajo y las cuatro esquinas. Las de arriba y abajo son copia de
-- las de izquierda y derecha, porque el motor las rota solo al dibujarlas.
-- Con eso el backdrop nativo reparte el borde y no hace falta una sola
-- linea de dibujo a mano.
--
-- La banda va pegada al filo EXTERIOR de la casilla. El marco del borde se
-- crea a 1 px del objetivo, asi que una banda dibujada mas adentro
-- terminaba cruzando por arriba de los botones.
-- =========================================================

local ART = ns.MEDIA .. "Border\\";

-- Grosor: cuantos pixeles de pantalla ocupa cada casilla del edgeFile. El
-- nucleo macizo de la textura son 2.8 de 32 texeles, asi que con 10 da algo
-- menos de un pixel de filo lleno mas la pluma.
local BORDER_FILE, BORDER_EDGE = ART .. "Border_Soft", 10;
local GLOW_FILE,   GLOW_EDGE   = ART .. "Border_Glow", 3;

-- El filo va en blanco. La textura tambien esta dibujada en blanco, asi que
-- esto es solo la opacidad; se deja escrito para no tener que adivinar de
-- donde sale el color si alguna vez hay que cambiarlo.
local BORDER_R, BORDER_G, BORDER_B = 1, 1, 1;

-- EL EDGESIZE NO PUEDE SER MAS GRANDE QUE MEDIO MARCO.
--
-- Cada casilla de esquina se dibuja a edgeSize x edgeSize. En una barra de
-- casteo de 13 px de alto, las dos esquinas de un lado son 20 px y no
-- entran: el backdrop las encima y salen puntas raras en los extremos. Aca
-- se recorta al vuelo segun el lado mas corto.
--
-- El marco del borde va 1 px por fuera del objetivo de cada lado, de ahi
-- el +2.
local function EdgeFor(frame, edge)
	local w = (frame.GetWidth  and frame:GetWidth())  or 0;
	local h = (frame.GetHeight and frame:GetHeight()) or 0;
	local small = math.min(w, h) + 2;
	if small <= 0 then return edge; end

	local maxEdge = math.floor(small / 2);
	if maxEdge < 2 then maxEdge = 2; end
	if edge > maxEdge then return maxEdge; end
	return edge;
end

-- ---------------------------------------------------------
-- Listas de objetivos
--
-- Se guardan por NOMBRE y se resuelven al aplicar: muchos de estos marcos
-- los crea Blizzard tarde, o directamente no existen (la barra de mascota
-- sin mascota), asi que resolverlos al cargar dejaria medias listas.
-- ---------------------------------------------------------
local function Series(prefix, n, suffix)
	local out = {};
	for i = 1, n do out[#out + 1] = prefix .. i .. (suffix or ""); end
	return out;
end

local function Join(...)
	local out = {};
	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do out[#out + 1] = v; end
	end
	return out;
end

local GROUPS = {
	{
		key = "ActionBars", label = "Barras de accion",
		names = Join(
			Series("ActionButton", 12),
			Series("MultiBarBottomLeftButton", 12),
			Series("MultiBarBottomRightButton", 12),
			Series("MultiBarRightButton", 12),
			Series("MultiBarLeftButton", 12),
			Series("BonusActionButton", 12),
			Series("ShapeshiftButton", 10),
			Series("PetActionButton", 10)
		),
	},
	{
		key = "MicroMenu", label = "Micromenu",
		-- POR QUE ESTE GRUPO LLEVA RECORTE.
		--
		-- Un boton del micromenu mide 28x58, pero su dibujo NO ocupa todo
		-- eso: la cara visible es un parche de unos 20x24 pegado abajo y el
		-- resto del alto es la lengueta que en la interfaz original tapa la
		-- barra de accion. Con las texturas de barra ocultas no la tapa
		-- nada, asi que un borde alrededor del marco entero salia como un
		-- rectangulo alto y vacio con el icono en el fondo.
		--
		-- Las fracciones son las coordenadas con las que hay que recortar
		-- ese arte para quedarse solo con la cara: SetTexCoord(0.17, 0.87,
		-- 0.5, 0.908). En fracciones y no en pixeles para que sigan
		-- valiendo si el boton cambia de escala.
		inset = { l = 0.17, r = 0.13, t = 0.50, b = 0.092 },
		names = {
			"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
			"QuestLogMicroButton", "SocialsMicroButton", "AchievementMicroButton",
			"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
		},
	},
	{
		key = "Bags", label = "Bolsas",
		names = { "MainMenuBarBackpackButton", "KeyRingButton",
			"CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot" },
	},
	{
		key = "CastBar", label = "Barra de casteo",
		names = { "CastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar" },
		-- EL MARCO Y EL DESTELLO DE BLIZZARD SE VAN.
		--
		-- Border es el marco grueso con relieve que trae la barra: con el
		-- filo fino por fuera quedaban los dos, uno adentro del otro.
		--
		-- Flash es el fogonazo del final del casteo, y es la misma escuela.
		-- Sin el, al terminar la barra igual se pone verde y se desvanece,
		-- que es la senal que importa; lo que se va es el adorno.
		--
		-- Border se ESCONDE; Flash pierde la TEXTURA, que no es lo mismo:
		-- el OnUpdate de la barra vuelve a mostrar el destello en cada
		-- cuadro del fogonazo, asi que esconderlo no sirve. Sin textura
		-- sigue "mostrado" pero no dibuja nada.
		hideRegions = {
			{ suffix = "Border" },
			{ suffix = "Flash", blank = true },
		},
	},
	{
		key = "Auras", label = "Auras",
		names = Join(
			Series("BuffButton", 32),
			Series("DebuffButton", 16),
			Series("TempEnchant", 3)
		),
	},
};

ns.GROUPS = GROUPS;

-- ---------------------------------------------------------
-- Pintado
-- ---------------------------------------------------------
local decorated = {};   -- [frame] = { border = , shadow = }
local hidden    = {};   -- [textura] = lo que habia antes de taparla

local function BlizzRegions(name, list, hide)
	if not list then return; end
	for _, item in ipairs(list) do
		local tex = _G[name .. item.suffix];
		if tex and tex.Hide then
			if hide then
				if hidden[tex] == nil then
					if item.blank then
						hidden[tex] = tex:GetTexture() or false;
					else
						hidden[tex] = true;
					end
				end
				if item.blank then tex:SetTexture(nil); else tex:Hide(); end

			elseif hidden[tex] ~= nil then
				local prev = hidden[tex];
				hidden[tex] = nil;
				if item.blank then
					if prev then tex:SetTexture(prev); end
				else
					tex:Show();
				end
			end
		end
	end
end

-- Para que otro addon que retexture ese mismo borde sepa que no tiene que
-- volver a mostrarlo. Un solo dueno por textura.
function NidhausFrameBorders_HidesRegion(tex)
	return tex ~= nil and hidden[tex] ~= nil;
end

-- Donde se planta el borde dentro del marco. Sin recorte va 1 px por
-- fuera; con recorte se corre hacia adentro segun las fracciones del
-- grupo, para abrazar el dibujo y no el marco.
local function Anchor(region, frame, inset, pad)
	local lx, ty, rx, by = -pad, pad, pad, -pad;

	if inset then
		local w = (frame.GetWidth  and frame:GetWidth())  or 0;
		local h = (frame.GetHeight and frame:GetHeight()) or 0;
		lx =  w * (inset.l or 0) - pad;
		ty = -h * (inset.t or 0) + pad;
		rx = -w * (inset.r or 0) + pad;
		by =  h * (inset.b or 0) - pad;
	end

	region:ClearAllPoints();
	region:SetPoint("TOPLEFT",     frame, "TOPLEFT",     lx, ty);
	region:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", rx, by);
end

local function Ensure(frame)
	local d = decorated[frame];
	if d then return d; end

	local lvl = frame:GetFrameLevel() or 1;
	d = {};

	-- LOS DOS VAN CON NOMBRE. Sin nombre, cualquier herramienta que liste
	-- marcos los muestra como "(sin nombre)" y hay que deducir de quien son
	-- por el tamano. Con nombre dicen solos de que boton cuelgan.
	local tag = frame:GetName() or tostring(frame);

	-- El borde cuelga del marco, un nivel por encima, para quedar sobre su
	-- arte y no debajo del icono.
	d.border = CreateFrame("Frame", "NFB_Borde_" .. tag, frame);
	d.border:SetFrameLevel(lvl + 1);
	d.border:Hide();

	-- LA SOMBRA CUELGA DEL MARCO, NO DEL PADRE.
	--
	-- Colgada del padre dejaba recuadros flotando: cuando el boton se
	-- escondia, el borde se iba con el (es su hijo) pero la sombra se
	-- quedaba dibujada, porque su padre seguia visible.
	--
	-- Los hooks de OnShow/OnHide no alcanzan: cuando un marco deja de verse
	-- porque lo escondio alguien de su cadena de padres, OnHide NO se
	-- dispara. La unica forma de que la sombra siga SIEMPRE al boton es que
	-- sea su hija y que el motor la esconda solo.
	--
	-- Un nivel por debajo para que quede detras del arte del boton: un hijo
	-- con nivel menor que el padre se dibuja abajo de sus capas.
	d.shadow = CreateFrame("Frame", "NFB_Halo_" .. tag, frame);
	d.shadow:SetFrameLevel(lvl > 0 and lvl - 1 or 0);
	d.shadow:SetBackdrop({ edgeFile = GLOW_FILE, edgeSize = EdgeFor(frame, GLOW_EDGE) });
	d.shadow:SetBackdropBorderColor(0, 0, 0, 0.8);
	d.shadow:Hide();

	decorated[frame] = d;
	return d;
end

-- HAY ALGO DIBUJADO AHI?
--
-- Un boton vacio sigue "mostrado": Blizzard solo le apaga la imagen, y el
-- borde quedaba alrededor de la nada.
--
-- SOLO SE JUZGA A LOS BOTONES. Existe un CastingBarFrameIcon, pero en la
-- barra del JUGADOR vive oculto: el icono del hechizo solo se usa en las
-- del objetivo y el foco. Mirarlo dejaba la barra sin borde. Una barra no
-- tiene imagen propia que mirar, asi que pasa derecho.
--
-- Cada familia nombra su imagen distinto, de ahi los tres casos:
--   <nombre>Icon          botones de accion, postura y mascota
--   <nombre>IconTexture   ranuras de bolsa y la mochila
--   GetNormalTexture()    micromenu y cualquier boton comun
local function HasArt(frame, name)
	local kind = frame.GetObjectType and frame:GetObjectType();
	if kind ~= "Button" and kind ~= "CheckButton" then return true; end

	local icon = _G[name .. "Icon"] or _G[name .. "IconTexture"];
	if icon and icon.GetTexture then
		return (icon:IsShown() and icon:GetTexture()) and true or false;
	end

	if frame.GetNormalTexture then
		local nt = frame:GetNormalTexture();
		if nt and nt.GetTexture then
			return (nt:IsShown() and nt:GetTexture()) and true or false;
		end
	end

	return true;
end

local function ApplyToName(name, want, inset, hideRegions)
	local frame = _G[name];
	if not frame or not frame.GetFrameLevel then return; end

	if want and not HasArt(frame, name) then want = false; end

	BlizzRegions(name, hideRegions, want);

	if not want then
		local d = decorated[frame];
		if d then d.border:Hide(); d.shadow:Hide(); end
		return;
	end

	local d = Ensure(frame);

	-- Se reancla en cada pasada y no solo al crearlo: los botones cambian
	-- de tamano con la escala de las barras y el recorte es proporcional.
	Anchor(d.border, frame, inset, 1);
	Anchor(d.shadow, frame, inset, 3);

	d.border:SetBackdrop({ edgeFile = BORDER_FILE, edgeSize = EdgeFor(frame, BORDER_EDGE) });
	d.border:SetBackdropBorderColor(BORDER_R, BORDER_G, BORDER_B, 1);
	d.border:Show();

	if ns.Get("shadow") ~= false then d.shadow:Show(); else d.shadow:Hide(); end
end

function ns.ApplyBorders()
	local on = ns.Get("enabled") == true;
	for _, g in ipairs(GROUPS) do
		local want = on and (ns.Get(g.key) ~= false);
		for _, name in ipairs(g.names) do
			ApplyToName(name, want, g.inset, g.hideRegions);
		end
	end
end

-- ---------------------------------------------------------
-- Cuando repasar
-- ---------------------------------------------------------

-- Blizzard crea la barra de mascota, la de posturas y los botones de aura
-- tarde y a veces recien al usarlos, asi que se vuelve a pasar unas veces.
local retry = CreateFrame("Frame");
local retryAcc, retryCount = 0, 0;
retry:Hide();
retry:SetScript("OnUpdate", function(self, elapsed)
	retryAcc = retryAcc + elapsed;
	if retryAcc < 1 then return; end
	retryAcc = 0;
	retryCount = retryCount + 1;
	ns.ApplyBorders();
	if retryCount >= 6 then self:Hide(); end
end);

-- Los eventos de casteo van aparte. Blizzard rearma la barra en cada
-- lanzamiento y vuelve a mostrar su borde, asi que hay que taparlo otra
-- vez; pero es un repaso liviano, sin arrancar el barrido de seis pasadas,
-- que en cada hechizo seria trabajo al dope.
local CAST_EVENTS = {
	UNIT_SPELLCAST_START = true, UNIT_SPELLCAST_STOP = true,
	UNIT_SPELLCAST_CHANNEL_START = true, UNIT_SPELLCAST_CHANNEL_STOP = true,
	UNIT_SPELLCAST_INTERRUPTED = true, UNIT_SPELLCAST_FAILED = true,
	UNIT_SPELLCAST_DELAYED = true,
	PLAYER_TARGET_CHANGED = true, PLAYER_FOCUS_CHANGED = true,
};

local events = CreateFrame("Frame");
for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "UPDATE_SHAPESHIFT_FORMS", "UNIT_PET",
	"ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR",
	"PET_BAR_UPDATE" }) do
	events:RegisterEvent(ev);
end
for ev in pairs(CAST_EVENTS) do events:RegisterEvent(ev); end

events:SetScript("OnEvent", function(self, event)
	ns.ApplyBorders();
	if CAST_EVENTS[event] then return; end
	retryAcc, retryCount = 0, 0;
	retry:Show();
end);

-- ---------------------------------------------------------
-- Diagnostico
--
-- /nfb list  dice que esta dibujando ESTE addon.
-- /nfb what  dice quien dibuja lo que esta abajo del mouse.
--
-- El segundo existe porque Blizzard_DebugTools viene vaciado en este
-- cliente (en la carpeta quedo solo el .pub), asi que /framestack no anda.
-- ---------------------------------------------------------
function ns.ListDrawn()
	print("|cff00FF00Frame Borders|r  dibujando ahora:");
	local total = 0;
	for _, g in ipairs(GROUPS) do
		for _, name in ipairs(g.names) do
			local f = _G[name];
			local d = f and decorated[f];
			if d and (d.border:IsShown() or d.shadow:IsShown()) then
				total = total + 1;
				print(string.format("  [%s] %s  %dx%d  visible=%s",
					g.label, name,
					math.floor((f:GetWidth()  or 0) + 0.5),
					math.floor((f:GetHeight() or 0) + 0.5),
					f:IsVisible() and "si" or "no"));
			end
		end
	end
	print("  total: " .. total .. "  --  lo que no figure aca no lo dibuja este addon.");
end

local whatTimer = CreateFrame("Frame");
local whatAcc = 0;
whatTimer:Hide();

whatTimer:SetScript("OnUpdate", function(self, elapsed)
	whatAcc = whatAcc + elapsed;
	if whatAcc < 3 then return; end
	self:Hide();

	local hits = {};
	local function Scan(frame, depth)
		if depth > 7 then return; end
		for _, f in ipairs({ frame:GetChildren() }) do
			if f.IsVisible and f:IsVisible() and MouseIsOver(f) then
				hits[#hits + 1] = f;
			end
			Scan(f, depth + 1);
		end
	end
	Scan(UIParent, 0);

	table.sort(hits, function(a, b)
		return (a:GetFrameLevel() or 0) > (b:GetFrameLevel() or 0);
	end);

	print("|cff00FF00Frame Borders|r  abajo del mouse (de arriba hacia abajo):");
	if #hits == 0 then
		print("  nada. El cursor no esta sobre ningun marco.");
		return;
	end
	for i = 1, math.min(#hits, 12) do
		local f = hits[i];
		local parent = f:GetParent();
		print(string.format("  %s  %dx%d  nivel=%d  padre=%s",
			f:GetName() or "|cffAAAAAA(sin nombre)|r",
			math.floor((f:GetWidth()  or 0) + 0.5),
			math.floor((f:GetHeight() or 0) + 0.5),
			f:GetFrameLevel() or 0,
			(parent and parent:GetName()) or "?"));
	end
	if #hits > 12 then print("  ... y " .. (#hits - 12) .. " mas abajo."); end
end);

function ns.WhatIsUnder()
	print("|cff00FF00Frame Borders|r  llevá el mouse al recuadro. Leo en 3 segundos.");
	whatAcc = 0;
	whatTimer:Show();
end
