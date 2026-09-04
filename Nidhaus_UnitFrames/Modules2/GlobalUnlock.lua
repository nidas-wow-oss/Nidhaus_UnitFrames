local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- GlobalUnlock.lua
-- Modo "desbloquear todo": muestra un overlay arrastrable sobre
-- cada frame movible y guarda la posicion.
--
-- Cubre: Player, Target, Focus, Party, barras de accion, buffs,
-- debuffs, barra de casteo, Auto Shot y Melee Swing.
--
-- /nufmove  -> activa / desactiva
-- =========================================================

local unlocked = false;
local overlays = {};

-- name        = clave para guardar la posicion
-- frame       = nombre global del frame a mover
-- label       = texto del overlay
-- protected   = true si es un frame protegido (no se puede mover en combate)
-- managed   = clave en UIPARENT_MANAGED_FRAME_POSITIONS. Blizzard reposiciona
--             estos frames constantemente ("se quedan imantados"), asi que hay
--             que sacarlos de esa tabla apenas el usuario los mueve.
-- scalable  = se puede agrandar con Ctrl + rueda
-- frames = lista de candidatos. Se usa el PRIMERO que exista.
-- NUF reparenta Player y Party a sus propios contenedores, asi que hay que
-- mover ESOS y no los de Blizzard, si no el recuadro azul queda desfasado.
-- group      = "frames" (unit frames) | "extra" (barras, buffs, timers)
-- managed    = lo administra UIParent_ManageFramePositions
-- protected  = frame protegido: no se puede mover en combate
-- scalable   = se agranda con Ctrl + rueda
-- overlayPad  = expande el recuadro por FUERA del frame, en pixeles. Para
--               frames cuyo arte se dibuja mas grande que ellos mismos.
-- overlaySize = tamaño MINIMO del recuadro. Necesario para frames que no
--              tienen tamaño propio (BuffFrame mide 1x1: sin esto el recuadro
--              sale de 1 pixel y es imposible agarrarlo).
-- overlayOn   = nombre de OTRO frame sobre el que dibujar el recuadro. Se
--               sigue arrastrando el de "frames"; esto solo cambia donde se
--               ve la caja. Para contenedores mas grandes que su contenido,
--               como MinimapCluster respecto del mapa.
-- overlayOffset = corrimiento { x, y } del recuadro, en pixeles. Para
--               anclas cuyo contenido no arranca justo en su borde.
local MOVABLES = {
	-- SIN tamaño fijo: el recuadro toma el del frame.
	--
	-- Les habia puesto 200x50 y quedo peor que antes — una caja que no
	-- seguia ni la escala ni el tamaño real. El recuadro grande no era el
	-- problema: es el tamaño que de verdad ocupa el marco.
	{ key = "Player",  group = "frames", frames = {"NidhausPlayerFrame", "PlayerFrame"}, label = "Player", scalable = true },
	{ key = "Target",  group = "frames", frames = {"TargetFrame"},  label = "Target", scalable = true },
	-- EL FOCUS NO ESTA ACA A PROPOSITO.
	--
	-- Su posicion la maneja "Use Custom Positions" (Core/FramePositions.lua)
	-- junto con la del jugador y la del objetivo. Tenerlo tambien aca eran
	-- dos sistemas empujando el mismo marco: lo movias con el recuadro y al
	-- rato volvia solo, o al reves.
	--
	-- Si algun dia se lo quiere devolver, primero hay que decidir cual de
	-- los dos manda; mientras tanto, uno solo.
	{ key = "Pet",     group = "frames", frames = {"PetFrame"},     label = "Pet",    scalable = true, managed = "PetFrame",
	  overlaySize = {120, 40} },   -- PetFrame mide poco: caja fija para poder agarrarlo sin mascota

	-- Party 1-4 individuales (antes era UNA sola caja "Party").
	-- partyIndex marca que su posicion se guarda en el MISMO store que lee
	-- el modo 3v3 (K.GetSavedPosition), no en globalPos: asi las dos cosas
	-- no se pelean y arrastrar un miembro es compatible con el 3v3.
	{ key = "Party1", group = "frames", frames = {"PartyMemberFrame1"}, label = "Party 1", partyIndex = 1 },
	{ key = "Party2", group = "frames", frames = {"PartyMemberFrame2"}, label = "Party 2", partyIndex = 2 },
	{ key = "Party3", group = "frames", frames = {"PartyMemberFrame3"}, label = "Party 3", partyIndex = 3 },
	{ key = "Party4", group = "frames", frames = {"PartyMemberFrame4"}, label = "Party 4", partyIndex = 4 },
	-- Arena NO va aca: los marcos de arena ya tienen su propio mover
	-- ("Show Arena Frame" / Shift+Alt+Click). Poner un overlay encima
	-- tapaba ese mover y agregaba un recuadro que antes no estaba.
	-- Boss NO va: tiene su propio modo de prueba con /nuf boss

	-- Buffs: se mueve el ancla propia de AuraAnchor.lua, no BuffFrame.
	-- Mover BuffFrame no sirve porque Blizzard re-ancla las auras en cada update.
	-- El ancla mide 330x90 y las auras crecen hacia la IZQUIERDA desde su
	-- esquina superior derecha, asi que el recuadro quedaba corrido a la
	-- izquierda respecto de los iconos que realmente se ven. El corrimiento
	-- lo acomoda; es un solo numero si hay que afinarlo.
	{ key = "Buffs",      group = "extra", frames = {"NUF_BuffAnchor"},   label = "Buffs",   scalable = true, auraAnchor = true,
	  overlayOffset = { 20, 0 } },
	-- Mismo corrimiento que Buffs: si no, los dos recuadros quedaban
	-- desalineados entre si aunque las auras si esten alineadas.
	{ key = "Debuffs",    group = "extra", frames = {"NUF_DebuffAnchor"}, label = "Debuffs", scalable = true, debuffAnchor = true,
	  overlayOffset = { 20, 0 } },
	-- La barra mide 195x13 pero su marco decorado sobresale bastante: con
	-- SetAllPoints el recuadro quedaba visiblemente adentro de la barra.
	-- El padding lo expande por fuera, y como se calcula sobre el tamaño
	-- REAL, sigue a la escala cuando la subis con Ctrl + rueda.
	{ key = "CastBar",    group = "extra", frames = {"CastingBarFrame"},       label = "Cast Bar", scalable = true, managed = "CastingBarFrame",
	  overlayPad = { 4, 5 } },
	-- Se sigue arrastrando MainMenuBar (ver el comentario largo mas abajo
	-- sobre por que NO se mueven las barras como bloque), pero el recuadro
	-- se dibuja sobre NUF_ActionBarsBox, que abarca todas las barras a la
	-- vista. Antes cubria solo los 510 de MainMenuBar y dejaba afuera media
	-- barra unificada.
	{ key = "MainBar",    group = "extra", frames = {"MainMenuBar"},           label = "Action Bars", scalable = true, protected = true, managed = "MainMenuBar",
	  overlayOn = "NUF_ActionBarsBox" },

	-- BARRAS QUE CUELGAN DE LA PRINCIPAL
	--
	-- Con anchorTo se anclan a MainMenuBar: si moves la barra principal,
	-- estas la siguen solas porque su posicion esta expresada respecto de
	-- ella. Y si arrastras una por separado, se guarda su desplazamiento
	-- relativo, asi que sigue acompañando a la principal desde el lugar
	-- nuevo. Es el mismo patron de "Holder" que usa Modules/ActionBars.lua.
	{ key = "PetBar",     group = "extra", frames = {"PetActionBarFrame"},     label = "Pet Bar",
	  scalable = true, protected = true, anchorTo = "MainMenuBar", managed = "PetActionBarFrame", onlyIfVisible = true, overlaySize = { 300, 34 } },
	-- Se mueve NUESTRO contenedor, no el frame de Blizzard: los botones
	-- cuelgan de el (ver K.AttachStanceButtons en Modules/ActionBars.lua).
	-- Asi no hay frame protegido, ni gestor de posiciones, ni candados.
	{ key = "StanceBar",  group = "extra", frames = {"NUF_StanceBarHolder"},  label = "Stance Bar",
	  scalable = true, anchorTo = "MainMenuBar", onlyIfVisible = true,
	  resetFunc = "ResetStanceHolder" },
	{ key = "TotemBar",   group = "extra", frames = {"MultiCastActionBarFrame"}, label = "Totem Bar",
	  scalable = true, protected = true, anchorTo = "MainMenuBar", managed = "MultiCastActionBarFrame", onlyIfVisible = true, overlaySize = { 250, 40 },
	  class = "SHAMAN" },
	{ key = "PossessBar", group = "extra", frames = {"PossessBarFrame"},       label = "Possess Bar",
	  scalable = true, protected = true, anchorTo = "MainMenuBar", managed = "PossessBarFrame", onlyIfVisible = true, overlaySize = { 120, 40 } },
	{ key = "AutoShot",   group = "extra", frames = {"NUF_AutoShotMover"},     label = "Auto Shot", scalable = true,
	  module = "AutoShotTimer", class = "HUNTER" },
	{ key = "SwingTimer", group = "extra", frames = {"NUF_SwingMover"},        label = "Auto attack", scalable = true,
	  module = "MeleeSwingTimer" },
	-- Modulos con marco propio: tambien se acomodan desde "Mover todo".
	{ key = "PaladinICD", group = "extra", frames = {"PaladinICDFrame"},       label = "Paladin ICD", scalable = true,
	  preview = "SetPaladinICDPreview", module = "PaladinICD", class = "PALADIN" },
	{ key = "PalAuras",   group = "extra", frames = {"NUF_PaladinAuras"},      label = "Paladin tracker", scalable = true,
	  preview = "SetPaladinAurasPreview", module = "PaladinAuras", class = "PALADIN" },
	{ key = "TurnEvil",   group = "extra", frames = {"NUF_TurnEvilStack"},     label = "Turn Evil", scalable = true,
	  preview = "SetTurnEvilPreview", module = "TurnEvil", class = "PALADIN" },
	-- Portados de WeakAuras (ver Modules2/NidhausTools).
	{ key = "SacredShield", group = "extra", frames = {"NUF_SacredShieldFrame"},   label = "Sacred Shield", scalable = true,
	  preview = "SetSacredShieldMove", module = "SacredShield", class = "PALADIN" },
	{ key = "SSTracker",    group = "extra", frames = {"NUF_SacredShieldTracker"}, label = "Sacred Shield tracker", scalable = true,
	  preview = "SetSacredShieldTrackerMove", module = "SacredShieldTracker", class = "PALADIN" },
	{ key = "Seduction",    group = "extra", frames = {"NUF_SeductionAlert"},      label = "Seduction alert", scalable = true,
	  preview = "SetSeductionAlertMove", module = "SeductionAlert" },
	-- GARGOLA: SIN RECUADRO AZUL, a proposito.
	--
	-- Dos cosas estaban mal aca. El frame se llama GT_Blizzard, no
	-- "GT_Blizz": ese nombre no existe, asi que el recuadro terminaba
	-- cayendo sobre otro frame y salia gigante y corrido.
	--
	-- Y sobre todo, no hace falta: los dos frames de la gargola YA son
	-- arrastrables por su cuenta (SetMovable + EnableMouse + RegisterForDrag
	-- en GargoyleTracker.lua). Ponerles un overlay encima daba dos cosas
	-- para lo mismo — el recuadro y el marco real — y encima el recuadro
	-- tapaba el arrastre propio.
	--
	-- Con noOverlay, "Mover todo" solo dispara su modo prueba para que el
	-- marco aparezca, y lo arrastras directo.
	{ key = "Gargoyle",   group = "extra", frames = {"GT_Blizzard", "GT_Custom"}, label = "Gargoyle",
	  -- SIN filtro de clase: rastrea la gargola ENEMIGA, no la propia. Le
	  -- sirve a cualquiera que juegue contra un DK, que es todo el mundo.
	  -- Le habia puesto class = "DEATHKNIGHT" por asumir que era la tuya.
	  preview = "SetGargoylePreview", module = "GargoyleTracker", noOverlay = true },
	-- SPELL ALERT: mismo caso que la gargola, SIN RECUADRO.
	--
	-- El ancla ya se arrastra sola (SetMovable + RegisterForDrag +
	-- OnDragStart/Stop en EnemySpellAlert.lua), asi que un overlay encima
	-- seria un segundo sistema de arrastre tapando al que ya funciona.
	--
	-- Lo que faltaba era el preview: sin el, al abrir "Mover todo" el icono
	-- no aparecia (el modulo lo tiene oculto hasta que un enemigo castea) y
	-- no habia nada que agarrar. Y al cerrar, su modo arrastre quedaba
	-- prendido por su cuenta. Con esto se abre y se cierra junto con el
	-- resto.
	{ key = "EnemyAlert", group = "extra", frames = {"NUF_EnemyAlertAnchor"},  label = "Spell Alert",
	  preview = "SetEnemyAlertPreview", module = "EnemySpellAlert", noOverlay = true },
	{ key = "ArrowCount", group = "extra", frames = {"NUF_ArrowCountFrame"},   label = "Ammo",      scalable = true,
	  module = "ArrowCount", class = "HUNTER" },
	{ key = "DungeonRoles", group = "extra", frames = {"NUF_DungeonRoles"},   label = "Dungeon roles", scalable = true,
	  module = "DungeonRoles", preview = "SetDungeonRolesPreview" },

	-- Barras de casteo del grupo (addon PartyCastingBars).
	--
	-- Se mueve SOLO la del compa 1 y las otras tres copian el mismo offset:
	-- cada una cuelga de su propio PartyMemberFrame, asi que con un unico
	-- recuadro quedan las cuatro alineadas. Cuatro recuadros encimados
	-- sobre los marcos del grupo no se podian ni agarrar.
	--
	-- Va con "setting" y no con "module" porque no es un modulo de NUF:
	-- es el checkbox Party Castbars del panel.
	{ key = "PartyCast", group = "frames", frames = {"PartyMemberFrame1CastingBarFrame"},
	  label = "Party Cast Bar", setting = "PCB_Enabled",
	  preview = "SetPartyCastBarPreview", partyCast = true,
	  -- Mismo caso que el Cast Bar del jugador: la StatusBar es mas angosta
	  -- que su borde decorado (PartyCastingBars le pone uno de 202x28 y
	  -- ademas escala la barra a 1.10), asi que SetAllPoints daba un
	  -- recuadro que terminaba antes que la barra.
	  overlayPad = { 6, 6 } },
	  -- SIN overlaySize: yo le habia puesto 150x16 a ojo y quedaba mas chico
	  -- que la barra. Sin ese campo, el recuadro hace SetAllPoints sobre el
	  -- frame real, asi que mide exactamente lo que estas moviendo. El
	  -- tamaño fijo solo hace falta para frames que miden 1x1 (los anchors
	  -- de auras), no para este.

	-- Marcos de objetivo del grupo.
	--
	-- Igual que las barras de casteo: se mueve el del compa 1 y los otros
	-- tres lo siguen, porque el modulo ya guarda UN offset compartido
	-- respecto de cada PartyMemberFrame.
	{ key = "PartyTarget", group = "frames", frames = {"PartyTargetFrame1"},
	  label = "Party Target", setting = "PartyTargetsEnabled",
	  preview = "SetPartyTargetPreview", partyTarget = true },

	-- ── Cosas de Blizzard que tambien ocupan pantalla ──
	--
	-- Si el modo se llama "Mover todo", que falten estas llama la atencion.
	-- Ninguna es un frame protegido, asi que se arrastran como cualquier
	-- otra.
	--
	-- Se mueve MinimapCluster y no Minimap: el cluster es el contenedor que
	-- lleva ademas el nombre de la zona, el reloj y los botones. Agarrando
	-- solo el mapa, el resto se quedaba atras.
	-- El recuadro va sobre Minimap y no sobre el cluster: el cluster incluye
	-- la barra del nombre de zona, el reloj y los botones, asi que su caja
	-- sobresalia bastante por arriba y por los costados del mapa. Se sigue
	-- arrastrando el cluster, que es lo que hay que mover.
	{ key = "Minimap",  group = "extra", frames = {"MinimapCluster"},
	  label = "Minimap", managed = "MinimapCluster", overlayOn = "Minimap" },

	-- Marcador de battleground / objetivos de la zona. Aparece solo en BG y
	-- en zonas con objetivos, asi que la mayor parte del tiempo no se ve —
	-- por eso lleva caja fija: sin ella el recuadro mide 0 y no se agarra.
	{ key = "BGScore",  group = "extra", frames = {"WorldStateAlwaysUpFrame"},
	  label = "BG score", overlaySize = { 200, 60 }, overlayAnchor = "TOP" },

	-- Barra de captura (Ojo de la Tormenta, Arathi...).
	{ key = "CaptureBar", group = "extra", frames = {"WorldStateCaptureBar1"},
	  label = "Capture bar", overlaySize = { 180, 40 } },

	-- ── Timers de arena ──
	--
	-- Estos solo existen dentro de una arena, y ahi no vas a estar
	-- acomodando la interfaz. Sin un modo prueba que los muestre, eran
	-- imposibles de posicionar: tenias que entrar a una arena, aguantar el
	-- timer y adivinar.
	{ key = "DalaranPipe", group = "extra", frames = {"NUF_DalaranPipeTimer"},
	  label = "Dalaran waterfall", scalable = true,
	  setting = "ArenaDalaranPipeTimer", preview = "SetArenaTimersPreview" },
	{ key = "RoVPillars",  group = "extra", frames = {"NUF_RoVPillarTimer"},
	  label = "RoV pillars", scalable = true,
	  setting = "ArenaRoVPillarTimer", preview = "SetArenaTimersPreview" },
	{ key = "ArenaEnd",    group = "extra", frames = {"NUF_ArenaEndTimer"},
	  label = "Arena time", scalable = true,
	  setting = "ArenaEndTimer", preview = "SetArenaTimersPreview" },

	-- ── Timers de clase (mago) ──
	--
	-- Ya tienen su propio "Show to position" en la pestaña de clase, pero
	-- eso obliga a abrir el panel, ir a Mago y prender el modo. Estando en
	-- "Mover todo" es donde uno acomoda la interfaz: tienen que estar aca.
	--
	-- Solo existen si el personaje es mago; ResolveFrame devuelve nil para
	-- las otras clases y el recuadro no se crea.
	{ key = "WaterEle",  group = "extra", frames = {"NUF_ClassTimer_WaterElemental"},
	  label = "Water Elemental", setting = "MageWaterEleTimer",
	  preview = "SetClassTimersPreview", class = "MAGE" },
	{ key = "MirrorImg", group = "extra", frames = {"NUF_ClassTimer_MirrorImage"},
	  label = "Mirror Image", setting = "MageMirrorTimer",
	  preview = "SetClassTimersPreview", class = "MAGE" },
};

-- ---------------------------------------------------------
-- La "barra de posturas" no se llama igual para todos
--
-- ShapeshiftBarFrame es un solo frame que cada clase usa para lo suyo:
-- el paladin para las AURAS, el caballero de la muerte para las
-- presencias, el druida para las formas, y solo el guerrero para
-- posturas de verdad. Decirle "Stance Bar" a un paladin no significa
-- nada — que es justo lo que pasaba.
--
-- Se resuelve una vez al cargar, porque la clase no cambia.
-- ---------------------------------------------------------
do
	local _, class = UnitClass("player");
	local byClass = {
		PALADIN     = L["MOVE_AURA_BAR"]     or "Aura Bar",
		DEATHKNIGHT = L["MOVE_PRESENCE_BAR"] or "Presence Bar",
		DRUID       = L["MOVE_FORM_BAR"]     or "Form Bar",
		WARRIOR     = L["MOVE_STANCE_BAR"]   or "Stance Bar",
	};
	local name = byClass[class or ""];
	if name then
		for _, entry in ipairs(MOVABLES) do
			if entry.key == "StanceBar" then entry.label = name; break; end
		end
	end
end

-- Alcance actual del modo mover: "frames" o "all"
local currentScope = "all";

-- Modulos apagados = no se muestra su caja.
--
-- Antes aparecian igual y quedaban recuadros vacios: el frame no existe o
-- esta oculto, asi que no habia nada que arrastrar. Peor con los que tienen
-- modo prueba, porque el preview no se podia disparar.
-- Clase del jugador, resuelta LA PRIMERA VEZ QUE SE PIDE, no al cargar.
--
-- Yo la habia puesto como "local playerClass = select(2, UnitClass('player'))"
-- en el cuerpo del archivo, y eso rompia todo el filtro por clase: cuando
-- este archivo se ejecuta, el juego todavia no tiene los datos del personaje
-- y UnitClass devuelve nil.
--
-- Con playerClass = nil, la comparacion "entry.class ~= playerClass" daba
-- verdadera SIEMPRE, asi que se ocultaban TODAS las entradas con clase: la
-- gargola del DK, el Paladin ICD, el tracker, Turn Evil, Auto Shot, Ammo y
-- los dos timers de mago. Para todo el mundo, incluida la clase correcta.
--
-- Es el mismo error que tenia ArenaPointsCalc con su SavedVariable: leer al
-- cargar algo que recien existe despues. Resuelto en el primer uso, que
-- ocurre cuando abris el modo mover — ahi el personaje ya esta cargado.
local playerClass;

local function PlayerClass()
	if not playerClass then
		playerClass = select(2, UnitClass("player"));
	end
	return playerClass;
end

-- REGLA para poner "class" en una entrada:
--
--   SI el modulo mira TU personaje  ->  lleva class
--   SI mira al ENEMIGO o al grupo   ->  NO lleva
--
-- Me equivoque con la gargola justamente por no distinguir esto: el nombre
-- "Gargoyle Tracker" suena a algo del DK, pero rastrea la gargola ENEMIGA
-- — le sirve a cualquiera que juegue contra un DK. Ponerle
-- class = "DEATHKNIGHT" se la escondia a todos menos al unico que no la
-- necesita.
--
-- Con class hoy: Paladin ICD y tracker (tus defensivos y tus procs), Turn
-- Evil (lo que TU pusiste sobre el grupo), Auto Shot y Ammo (tu tiro), los
-- dos timers de mago (tus invocaciones).
--
-- Sin class: Spell Alert y la gargola, que son del rival.
local function EntryModuleActive(entry)
	-- Cosas de una clase que no es la tuya no tienen por que aparecer.
	--
	-- El modulo puede estar "activo" en la base de datos aunque seas de otra
	-- clase — el registro no filtra por clase, solo el panel lo hace — asi
	-- que preguntarle a IsModuleEnabled no alcanzaba. Un cazador veia el
	-- recuadro del Paladin tracker.
	--
	-- Si por lo que sea la clase todavia no se puede leer, NO se filtra:
	-- mostrar de mas es preferible a esconder algo que si corresponde.
	local cls = PlayerClass();
	if entry.class and cls and entry.class ~= cls then return false; end

	-- Algunas cosas movibles no son modulos registrados sino un checkbox
	-- suelto del panel (las barras de casteo del grupo, por ejemplo, que
	-- son de un addon externo). Para esas se mira el setting directo.
	if entry.setting then
		return (C and C[entry.setting]) and true or false;
	end
	if not entry.module then return true; end   -- no depende de nada
	if not K.IsModuleEnabled then return true; end
	return K.IsModuleEnabled(entry.module) and true or false;
end

-- Se define despues de ResolveFrame, que es de donde saca el frame real.
local EntryHasContent;

local function EntryInScope(entry)
	if not EntryModuleActive(entry) then return false; end
	if not EntryHasContent(entry) then return false; end
	if currentScope == "all" then return true; end
	return entry.group == currentScope;
end

-- Devuelve el frame real a mover para una entrada
local function ResolveFrame(entry)
	for _, name in ipairs(entry.frames) do
		local f = _G[name];
		if f and f.SetPoint then return f; end
	end
	-- Algunos contenedores de NUF viven en K y no en _G
	if entry.key == "Party"  and K.NidhausPartyFrame then return K.NidhausPartyFrame; end
	return nil;
end

-- Barras que solo existen para algunas clases o situaciones: la de formas
-- sin formas, la de mascota sin mascota, la de posesion fuera de un
-- vehiculo. Con un paladin aparecian igual tres recuadros vacios encima de
-- la barra principal, tapandola y sin nada que mover adentro.
--
-- Se mira el frame REAL: si el juego no lo muestra, no hay recuadro. Para
-- la de formas se pregunta ademas cuantas hay, porque el frame existe
-- aunque la clase no tenga ninguna.
function EntryHasContent(entry)
	if not entry.onlyIfVisible then return true; end

	local f = ResolveFrame(entry);
	if not f then return false; end

	if entry.key == "StanceBar" then
		local n = (GetNumShapeshiftForms and GetNumShapeshiftForms()) or 0;
		if n < 1 then return false; end
		-- El Holder solo se usa en modo unificado. En MiniBar la barra la
		-- apila ese modo, asi que no hay nada que arrastrar aca.
		if C.UnifyActionBars ~= true then return false; end
		return true;
	elseif entry.key == "PetBar" then
		if not (UnitExists("pet") or (PetHasActionBar and PetHasActionBar())) then
			return false;
		end
	end

	return f:IsVisible() and true or false;
end

-- ---------------------------------------------------------
-- Estado original de cada frame (para el boton Reset)
-- Se captura UNA vez, antes de aplicar cualquier posicion guardada.
-- Sin esto el reset solo borraba la DB y los frames se quedaban donde
-- estaban: habia que hacer /reload para verlos volver a su lugar.
-- ---------------------------------------------------------
local originals = {};
local capturedOnce = false;

local function CaptureOriginals()
	if capturedOnce then return; end
	capturedOnce = true;

	for _, entry in ipairs(MOVABLES) do
		local f = ResolveFrame(entry);
		if f and not originals[entry.key] then
			local pts = {};
			for i = 1, (f:GetNumPoints() or 0) do
				-- Guardado por NOMBRE de campo, no como lista.
				--
				-- GetPoint devuelve cinco valores y el segundo (relativeTo) es
				-- nil cuando el frame cuelga directamente de su padre. Metido
				-- en una tabla eso deja un agujero en el indice 2, y unpack()
				-- sobre una tabla con agujeros corta donde quiere: podia
				-- devolver solo el primer valor, con lo que el SetPoint de
				-- vuelta quedaba en "esquina contra esquina del padre y sin
				-- desplazamiento". De ahi que algun frame terminara pegado a
				-- una esquina de la pantalla despues de un Reset.
				local p, rel, rp, x, y = f:GetPoint(i);
				pts[i] = { point = p, rel = rel, relPoint = rp, x = x, y = y };
			end
			originals[entry.key] = {
				points = pts,
				scale  = f:GetScale() or 1,
			};
		end
	end
end
K.CaptureMovableOriginals = CaptureOriginals;

local function RestoreOriginal(entry)
	local orig = originals[entry.key];
	local f = ResolveFrame(entry);
	if not f or not orig then return; end
	if entry.protected and InCombatLockdown() then return; end

	f._nufApplying = true;
	pcall(f.SetScale, f, orig.scale or 1);
	if orig.points and #orig.points > 0 then
		f:ClearAllPoints();
		for _, pt in ipairs(orig.points) do
			pcall(f.SetPoint, f, pt.point, pt.rel or f:GetParent(),
				pt.relPoint or pt.point, pt.x or 0, pt.y or 0);
		end
	end
	f._nufApplying = nil;
end

-- ---------------------------------------------------------
-- DB
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.globalPos then NidhausUnitFramesDB.globalPos = {}; end
	return NidhausUnitFramesDB.globalPos;
end

-- Blizzard reposiciona los frames "managed" en cada UIParent_ManageFramePositions.
-- Si el usuario movio uno, lo sacamos de esa tabla para que deje de imantarse.
-- Blizzard reposiciona los frames "managed" en cada UIParent_ManageFramePositions.
-- La forma correcta de sacarlos de ahi (la que usa MoveAnything) es el flag
-- oficial ignoreFramePositionManager en el propio frame, NO vaciar la tabla
-- global UIPARENT_MANAGED_FRAME_POSITIONS.
local function ReleaseManaged(entry, frame)
	if not entry.managed then return; end
	frame = frame or ResolveFrame(entry);
	if not frame then return; end
	frame.ignoreFramePositionManager = true;
end

-- Devuelve el frame al control de Blizzard (para el reset)
local function ReclaimManaged(entry)
	if not entry.managed then return; end
	local frame = ResolveFrame(entry);
	if not frame then return; end
	frame.ignoreFramePositionManager = nil;
	frame.MAPoint = nil;
	if frame.SetUserPlaced and not frame:IsProtected() then
		pcall(frame.SetUserPlaced, frame, false);
	end
end

-- Los miembros de party guardan su posicion en el store de FrameDragger
-- (NidhausUnitFramesDB.positions["PartyMemberFrameN"]), que es el que lee
-- el modo 3v3 y el modo individual normal. Ademas prende PartyIndividualMove
-- para que esos sistemas respeten la posicion en vez de reordenar en fila.
-- ROMPER LA CADENA DEL GRUPO
--
-- Blizzard ancla cada marco de grupo AL ANTERIOR: el 2 cuelga del 1, el 3
-- del 2 y el 4 del 3. Por eso arrastrar el primero se llevaba los otros
-- tres puestos, en fila, aunque cada uno tenga su propio recuadro.
--
-- La solucion es sacarlos de esa fila ANTES de mover ninguno: a cada uno
-- se le calcula donde esta en la pantalla y se lo vuelve a anclar ahi
-- mismo, pero contra UIParent. Visualmente no se mueve nada; lo que
-- cambia es de quien depende cada marco, y a partir de ahi cada uno se
-- arrastra solo.
--
-- La conversion de coordenadas es la misma que ya usa FrameDragger en
-- ApplyIndividualPartyPositions, para que los dos sistemas guarden el
-- mismo tipo de punto.
--
-- El Reset del Move Everything repone la foto de fabrica, asi que la
-- cadena original vuelve sola cuando hace falta.
local function DetachPartyChain()
	if InCombatLockdown() then return; end
	local uiScale = UIParent:GetEffectiveScale();
	local uiH = UIParent:GetHeight();
	for i = 1, (MAX_PARTY_MEMBERS or 4) do
		local pf = _G["PartyMemberFrame" .. i];
		if pf and not pf:IsProtected() then
			local scale = pf:GetEffectiveScale();
			local left, top = pf:GetLeft(), pf:GetTop();
			if left and top then
				local x = left * scale / uiScale;
				local y = top * scale / uiScale - uiH;
				pf:SetParent(UIParent);
				pf:ClearAllPoints();
				pf:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y);
			end
		end
	end
end

local function SavePartyMemberPosition(entry, frame)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end

	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1);
	if not point then return; end
	local relName = "UIParent";
	if relativeTo and relativeTo.GetName then relName = relativeTo:GetName() or "UIParent"; end

	NidhausUnitFramesDB.positions["PartyMemberFrame" .. entry.partyIndex] = {
		point = point, relativeTo = relName, relativePoint = relativePoint, x = x, y = y,
	};

	if not C.PartyIndividualMove then
		C.PartyIndividualMove = true;
		if K.SaveConfig then K.SaveConfig("PartyIndividualMove", true); end
	end
end

local function SavePosition(entry, frame)
	if entry.partyIndex then
		SavePartyMemberPosition(entry, frame);
		return;
	end
	local db = DB();
	db[entry.key] = db[entry.key] or {};

	-- Barras hijas: se guarda el DESPLAZAMIENTO respecto de su padre, no la
	-- posicion en pantalla. Asi mover la barra principal las arrastra a
	-- todas, y mover una por separado solo cambia su distancia a la madre.
	if entry.anchorTo then
		local parent = _G[entry.anchorTo];
		if parent and parent:GetLeft() and frame:GetLeft() then
			db[entry.key].point         = "BOTTOMLEFT";
			db[entry.key].relativePoint = "BOTTOMLEFT";
			db[entry.key].x             = frame:GetLeft()   - parent:GetLeft();
			db[entry.key].y             = frame:GetBottom() - parent:GetBottom();
			db[entry.key].rel           = entry.anchorTo;
			-- Se re-ancla en el acto: si se deja colgando de UIParent, deja
			-- de seguir a la principal hasta el proximo login.
			frame:ClearAllPoints();
			frame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT",
				db[entry.key].x, db[entry.key].y);
			ReleaseManaged(entry, frame);
			return;
		end
	end

	local point, _, relativePoint, x, y = frame:GetPoint();
	if not point then return; end
	db[entry.key].point         = point;
	db[entry.key].relativePoint = relativePoint;
	db[entry.key].x             = x;
	db[entry.key].y             = y;
	db[entry.key].rel           = nil;
	ReleaseManaged(entry, frame);

	if entry.auraAnchor then
		if K.SaveAuraAnchorPosition then K.SaveAuraAnchorPosition(); end
		if K.ReanchorAuras then K.ReanchorAuras(); end
	elseif entry.debuffAnchor then
		if K.SaveDebuffAnchorPosition then K.SaveDebuffAnchorPosition(); end
		if K.ReanchorDebuffs then K.ReanchorDebuffs(); end
	end
end

local function SaveScale(entry, scale)
	local db = DB();
	db[entry.key] = db[entry.key] or {};
	db[entry.key].scale = scale;
	if entry.auraAnchor and K.SaveAuraAnchorScale then
		K.SaveAuraAnchorScale(scale);
	elseif entry.debuffAnchor and K.SaveDebuffAnchorScale then
		K.SaveDebuffAnchorScale(scale);
	end
end

-- Escalar un movable desde AFUERA (un slider de otro panel, por ejemplo).
--
-- Existe para que no haya dos duenos del mismo numero. La escala de un
-- frame movible se guarda en UN solo lugar, globalPos[key].scale, y se
-- aplica en UN solo lugar. Cualquier control que quiera cambiarla entra
-- por aca en vez de llamar a SetScale por su cuenta: si no, el proximo
-- login restauraria el valor viejo y pareceria que el slider no guarda.
-- Indice por clave. El slider llama a esto en cada tick del arrastre;
-- recorrer los treinta movibles cada vez seria trabajo al pedo.
local BY_KEY = {};
for _, entry in ipairs(MOVABLES) do BY_KEY[entry.key] = entry; end

function K.SetGlobalFrameScale(key, scale)
	if type(scale) ~= "number" then return false; end
	local entry = BY_KEY[key];
	if not entry then return false; end
	if entry.protected and InCombatLockdown() then return false; end

	local f = ResolveFrame(entry);
	if f then pcall(f.SetScale, f, scale); end
	SaveScale(entry, scale);
	return true;
end

-- Aplica nuestra posicion guardada, marcando la operacion para que el hook
-- de SetPoint no entre en recursion.
local function ApplyPoint(frame, entry, pos)
	-- pos.rel = nombre del frame al que esta anclada (barras hijas). Sin
	-- eso, UIParent como toda la vida.
	local anchorFrame = (pos.rel and _G[pos.rel]) or UIParent;
	frame._nufApplying = true;
	frame:SetClampedToScreen(true);
	frame:ClearAllPoints();
	frame:SetPoint(pos.point, anchorFrame, pos.relativePoint, pos.x, pos.y);
	frame._nufApplying = nil;
end

-- Los frames "managed" (buffs, debuffs, castbar, barras) se reanclan solos
-- una y otra vez: sacarlos de UIPARENT_MANAGED_FRAME_POSITIONS no alcanza,
-- Blizzard igual les llama SetPoint. Enganchamos su SetPoint y reponemos.
-- Patron tomado de MoveAnything: guardamos el punto "bueno" en el frame y,
-- si alguien le llama SetPoint, lo reponemos. Mucho mas fiable que solo
-- confiar en ignoreFramePositionManager.
local function OnLockedSetPoint(frame)
	if not frame.NUFPoint then return; end
	if frame._nufApplying then return; end
	if unlocked then return; end            -- mientras se arrastra, no pelear
	if frame:IsProtected() and InCombatLockdown() then return; end

	local p = frame.NUFPoint;
	frame._nufApplying = true;
	frame:ClearAllPoints();
	frame:SetPoint(unpack(p));
	frame._nufApplying = nil;
end

local function LockFramePoint(frame, entry, pos)
	if not frame.NUFPointHook then
		hooksecurefunc(frame, "SetPoint", OnLockedSetPoint);
		frame.NUFPointHook = true;
	end
	-- pos.rel: barras hijas ancladas a la principal en vez de a UIParent
	-- (ver anchorTo). El resto sigue colgando de UIParent como siempre.
	local anchorFrame = (pos.rel and _G[pos.rel]) or UIParent;
	frame.NUFPoint = { pos.point, anchorFrame, pos.relativePoint, pos.x, pos.y };
end

local function UnlockFramePoint(frame)
	if frame then frame.NUFPoint = nil; end
end

local function RestoreOne(entry)
	-- Los party target no guardan posicion aca: la maneja su modulo,
	-- anclandolos a cada PartyMemberFrame. Si quedo una entrada vieja de
	-- antes de separar los dos sistemas, se borra en vez de aplicarla —
	-- si no, cada login volvia a pegarle la posicion equivocada al del
	-- compa 1 y quedaba desalineado de los otros tres.
	if entry.partyTarget then
		DB()[entry.key] = nil;
		return;
	end

	local pos = DB()[entry.key];
	if not pos then return; end

	local frame = ResolveFrame(entry);
	if not frame then return; end

	if entry.protected and InCombatLockdown() then return; end

	if pos.scale then
		pcall(frame.SetScale, frame, pos.scale);
	end

	if pos.point then
		ReleaseManaged(entry, frame);
		ApplyPoint(frame, entry, pos);
		if frame.SetUserPlaced and not frame:IsProtected() then
			pcall(frame.SetUserPlaced, frame, true);
		end
		-- Bloquear reanclajes ajenos (esto es lo que faltaba para los buffs)
		LockFramePoint(frame, entry, pos);
	end
end

-- ¿Move Everything ya tiene una posicion propia para esta clave?
--
-- La usan los modulos que reposicionan frames por su cuenta (el de las
-- barras de accion, sin ir mas lejos) para no pelearse con el usuario:
-- si el frame ya se movio a mano, ellos no lo tocan.
function K.HasGlobalPos(key)
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;
	local p = db and db[key];
	return (p and p.point) and true or false;
end

function K.RestoreGlobalPositions()
	for _, entry in ipairs(MOVABLES) do
		pcall(RestoreOne, entry);
	end

	-- La barra 1 se restaura sola (tiene posicion guardada); las otras tres
	-- no guardan nada, la copian de ella. Sin esto volvian al lugar de
	-- fabrica en cada login y quedaban desalineadas con la primera.
	if K.MirrorPartyCastBars then pcall(K.MirrorPartyCastBars); end
end

-- ¿Hay algo guardado? Si no, no hace falta reponer nada nunca.
local function HasSavedPositions()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;
	if not db then return false; end
	return next(db) ~= nil;
end

-- Blizzard reanclea en UIParent_ManageFramePositions.
if type(UIParent_ManageFramePositions) == "function" then
	hooksecurefunc("UIParent_ManageFramePositions", function()
		if InCombatLockdown() then return; end
		if not HasSavedPositions() then return; end
		K.RestoreGlobalPositions();
	end);
end

-- ---------------------------------------------------------
-- La barra de accion se mueve SOLA. A proposito.
--
-- Intente moverla como bloque: tomar el desplazamiento de MainMenuBar y
-- aplicarselo a MultiBarBottomLeft/Right, las laterales, mascota y forma.
-- El resultado fue el que ya conocemos con estas barras: las laterales se
-- dispararon fuera de pantalla y la principal se partio en dos.
--
-- No es la primera vez. Este addon ya tiene Core/BarBaseline.lua escrito
-- justo por esto, y el comando /nufbars restore se saco por lo mismo. Las
-- barras de accion tienen tres sistemas encima — el gestor de posiciones de
-- Blizzard, MiniBar y Unify — y cualquier calculo de delta hecho desde
-- afuera pelea con los tres.
--
-- Mover solo MainMenuBar funciona: las barras que estan ancladas A ELLA lo
-- siguen solas, que es la mayoria. Las que cuelgan de UIParent se acomodan
-- desde sus propias opciones.
-- ---------------------------------------------------------

-- ---------------------------------------------------------
-- Barras de casteo del grupo
--
-- Son de PartyCastingBars, un addon aparte. Cada barra cuelga de su propio
-- PartyMemberFrame, asi que basta con mover la del compa 1 y copiarle el
-- desplazamiento a las otras tres.
--
-- Y estan ocultas salvo que alguien este casteando, o sea que en modo mover
-- hay que mostrarlas a la fuerza: si no, el recuadro apunta a algo invisible
-- y no sabes donde lo estas dejando.
-- ---------------------------------------------------------
local function PartyCastBar(i)
	return _G["PartyMemberFrame" .. i .. "CastingBarFrame"];
end

function K.SetPartyCastBarPreview(on)
	for i = 1, 4 do
		local bar = PartyCastBar(i);
		if bar then
			if on then
				bar.nufPreview = true;
				bar:SetMinMaxValues(0, 1);
				bar:Show();

				-- Casteo simulado: nombre, icono y la barra llenandose.
				--
				-- Antes se dejaba la barra quieta al 60% y sin texto, o sea
				-- una tira de color que no se parecia a lo que vas a ver en
				-- combate. Con nombre e icono se entiende que estas moviendo
				-- y donde va a quedar cada cosa.
				local txt = _G[bar:GetName() .. "Text"];
				if txt then txt:SetText(GetSpellInfo(2050) or "Lesser Heal"); end

				local icon = _G[bar:GetName() .. "Icon"];
				if icon then
					local _, _, tex = GetSpellInfo(2050);
					if tex then icon:SetTexture(tex); icon:Show(); end
				end

				-- El destello, apagado.
				--
				-- Es la textura que la barra enciende cuando el casteo
				-- TERMINA. Como el bucle de prueba reinicia el llenado cada
				-- vuelta, quedaba prendido y se veia ese halo blanco
				-- rodeando la barra, que no es como se ve en combate.
				local flash = _G[bar:GetName() .. "Flash"];
				if flash then
					bar.nufFlashWasShown = flash:IsShown();
					flash:Hide();
				end

				-- El OnUpdate lo pone el modo prueba y lo saca al salir, asi
				-- que no queda corriendo cuando el modo se apaga.
				bar.nufFill = 0;
				bar:SetScript("OnUpdate", function(self, elapsed)
					self.nufFill = (self.nufFill or 0) + (elapsed or 0) * 0.4;
					if self.nufFill > 1 then self.nufFill = 0; end
					self:SetValue(self.nufFill);
				end);

			elseif bar.nufPreview then
				bar.nufPreview = nil;
				bar.nufFill = nil;

				-- BUG QUE ESTABA AQUI: se dejaba el OnUpdate en nil.
				--
				-- El modo prueba PISA el OnUpdate de la barra con su propia
				-- animacion de relleno. Al salir hay que devolver el motor de
				-- PartyCastingBars, no borrarlo: ese OnUpdate es el que hace
				-- avanzar el casteo, el que lo desvanece al terminar y el que
				-- lleva la red de seguridad contra barras colgadas.
				--
				-- Sin el, despues del primer /nufmove la barra se quedaba
				-- clavada con el ultimo casteo para siempre. Es lo que hacia
				-- que "se quedara guardada" una barra al salir de la arena.
				if C.PCB_Enabled and PartyCastingBars and PartyCastingBars.OnUpdate then
					bar:SetScript("OnUpdate", function(self)
						PartyCastingBars.OnUpdate(self);
					end);
				else
					bar:SetScript("OnUpdate", nil);
				end

				-- Solo se repone si lo apagamos nosotros.
				local flash = _G[bar:GetName() .. "Flash"];
				if flash and bar.nufFlashWasShown then flash:Show(); end
				bar.nufFlashWasShown = nil;
				-- Solo se oculta la que mostramos nosotros: si el compa esta
				-- casteando de verdad, la barra tiene que quedarse.
				if not (bar.casting or bar.channeling) then bar:Hide(); end
			end
		end
	end
end

-- Copia a las barras 2, 3 y 4 la posicion relativa que quedo en la 1.
--
-- La cuenta va en PIXELES DE PANTALLA y despues se traduce a la escala de
-- cada barra. Restar los offsets crudos no servia: los marcos del grupo
-- pueden tener escalas distintas (el modo 3v3 usa 1.5 para los dos primeros
-- y 1.3 para los otros), y las barras habrian quedado desparejas.
function K.MirrorPartyCastBars()
	local b1, p1 = PartyCastBar(1), _G["PartyMemberFrame1"];
	if not (b1 and p1 and b1:GetLeft() and p1:GetRight()) then return; end

	local es1, ep1 = b1:GetEffectiveScale(), p1:GetEffectiveScale();
	local dx = (b1:GetLeft() * es1) - (p1:GetRight() * ep1);
	local dy = (b1:GetTop()  * es1) - (p1:GetTop()   * ep1);

	for i = 2, 4 do
		local b, p = PartyCastBar(i), _G["PartyMemberFrame" .. i];
		if b and p then
			local es = b:GetEffectiveScale();
			if not es or es == 0 then es = 1; end
			b:ClearAllPoints();
			b:SetPoint("TOPLEFT", p, "TOPRIGHT", dx / es, dy / es);
		end
	end
end

-- ---------------------------------------------------------
-- Modo prueba de los timers de arena
--
-- Los tres frames existen siempre (se crean al cargar), pero arrancan
-- ocultos y solo se muestran cuando el evento correspondiente ocurre
-- dentro de una arena. Para el modo mover alcanza con mostrarlos: no hace
-- falta simular la cuenta atras, con ver la caja donde va ya sabes donde
-- la estas dejando.
--
-- Se recuerda cuales mostramos NOSOTROS, para no ocultar al salir uno que
-- estuviera visible de verdad.
-- ---------------------------------------------------------
local ARENA_TIMER_FRAMES = {
	"NUF_DalaranPipeTimer", "NUF_RoVPillarTimer", "NUF_ArenaEndTimer",
};

function K.SetArenaTimersPreview(on)
	for _, name in ipairs(ARENA_TIMER_FRAMES) do
		local f = _G[name];
		if f then
			if on then
				if not f:IsShown() then
					f.nufPreviewShown = true;
					f:Show();
				end
			elseif f.nufPreviewShown then
				f.nufPreviewShown = nil;
				f:Hide();
			end
		end
	end
end

-- ---------------------------------------------------------
-- Marcos de objetivo del grupo
--
-- Estan bajo RegisterUnitWatch: el juego los muestra u oculta segun exista
-- o no "partyNtarget", y un Show() a secas no les hace nada. Para el modo
-- mover hay que sacarlos del watch, mostrarlos, y devolverlos al salir.
--
-- Fuera de combate esto es seguro; adentro, RegisterUnitWatch esta bloqueado
-- y por eso se chequea.
-- ---------------------------------------------------------
function K.SetPartyTargetPreview(on)
	if InCombatLockdown() then return; end
	for i = 1, 4 do
		local f = _G["PartyTargetFrame" .. i];
		if f then
			if on then
				if not f.nufWatchOff then
					f.nufWatchOff = true;
					pcall(UnregisterUnitWatch, f);
				end
				f:Show();
			elseif f.nufWatchOff then
				f.nufWatchOff = nil;
				pcall(RegisterUnitWatch, f);
			end
		end
	end
end

-- ---------------------------------------------------------
-- Overlays
-- ---------------------------------------------------------
local MOVER_BACKDROP = {
	bgFile   = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 14,
	insets   = { left = 2.6, right = 2.6, top = 2.6, bottom = 2.6 },
};

-- Alfa BAJO a proposito.
--
-- Con 0.55 y 0.65 el recuadro tapaba por completo el frame que estabas
-- moviendo: arrastrabas a ciegas y recien veias el resultado al soltar. El
-- relleno solo tiene que insinuar el area; quien la define es el borde, y
-- por eso el borde va al 100% de opacidad en vez de al 50%.
local COLOR_FRAME = { 1, 0.565, 0.251, 0.28 };          -- marcos de unidad
local COLOR_EXTRA = { 0.671, 0.804, 0.937, 0.30 };      -- barras, auras, avisos
local COLOR_EDGE  = { 0, 1, 0.62, 1 };                  -- borde, bien visible

local overlayLevel = 10;

local function CreateOverlay(entry)
	local frame = ResolveFrame(entry);
	if not frame then return nil; end

	local overlay = CreateFrame("Frame", "NUF_Move_" .. entry.key, UIParent);
	overlay:SetFrameStrata("FULLSCREEN_DIALOG");

	-- Niveles crecientes segun el orden de MOVABLES. Sin esto todos quedaban
	-- en el mismo nivel y ganaba el ultimo dibujado: el recuadro del Player
	-- (que es grande) tapaba al de la mascota, que vive justo debajo, y no
	-- habia forma de agarrarla. Los frames chicos van declarados despues, o
	-- sea que quedan por encima.
	overlayLevel = overlayLevel + 2;
	overlay:SetFrameLevel(overlayLevel);

	-- ESTE era el bug de los buffs: BuffFrame no tiene tamaño propio
	-- (mide 1x1), asi que SetAllPoints daba un recuadro de 1 pixel
	-- imposible de agarrar. Cuando el frame no mide nada usable, le
	-- damos al overlay un tamaño fijo anclado a una esquina.
	-- overlaySize es un MINIMO, no un reemplazo.
	--
	-- Lo tenia como override y estaba mal en las dos direcciones: a
	-- Player/Target/Focus les daba una caja fija que no seguia su escala ni
	-- su tamaño real, y al Cast Bar le daba una caja que no crecia aunque
	-- subieras la escala a 1.80. Ahora el tamaño sale del frame y el minimo
	-- solo entra si el frame es mas chico que eso.
	--
	-- overlayPad expande el recuadro POR FUERA del frame. Hace falta cuando
	-- el arte se dibuja mas grande que el frame — la barra de casteo es el
	-- caso tipico: mide 195x13 pero su marco decorado sobresale por los
	-- cuatro lados, asi que SetAllPoints daba un recuadro visiblemente mas
	-- chico que la barra.
	local function AnchorOverlay(self)
		self:ClearAllPoints();
		local e = self.entry;

		-- El recuadro puede dibujarse sobre un frame DISTINTO del que se
		-- arrastra. El minimapa es el caso: hay que mover MinimapCluster,
		-- que ademas del mapa lleva el nombre de la zona, el reloj y los
		-- botones, asi que es bastante mas grande que el mapa en si. Con
		-- overlayOn el cuadro calza con el mapa y se sigue moviendo el
		-- cluster entero.
		-- La caja de las barras de accion se mide sobre los botones, asi
		-- que hay que recalcularla ACA y no solo al construir: durante el
		-- arrastre la barra se mueve y, con la caja vieja, el recuadro
		-- quedaba clavado donde estaba antes.
		if e.overlayOn == "NUF_ActionBarsBox" and K.UpdateActionBarsBox then
			pcall(K.UpdateActionBarsBox);
		elseif e.overlayOn == "NUF_StanceBarBox" and K.UpdateStanceBarBox then
			pcall(K.UpdateStanceBarBox);
		end

		local box  = (e.overlayOn and _G[e.overlayOn]) or self.target;
		local offX = (e.overlayOffset and e.overlayOffset[1]) or 0;
		local offY = (e.overlayOffset and e.overlayOffset[2]) or 0;

		local w = box:GetWidth()  or 0;
		local h = box:GetHeight() or 0;

		local minW = (e.overlaySize and e.overlaySize[1]) or 0;
		local minH = (e.overlaySize and e.overlaySize[2]) or 0;
		local padX = (e.overlayPad  and e.overlayPad[1])  or 0;
		local padY = (e.overlayPad  and e.overlayPad[2])  or 0;

		-- Frame sin tamaño util (los anchors de auras miden 1x1): caja fija
		-- en la esquina que diga la entrada.
		if w < 8 or h < 8 then
			self:SetSize(math.max(minW, 200), math.max(minH, 60));
			local anchor = e.overlayAnchor or "TOPLEFT";
			self:SetPoint(anchor, box, anchor, offX, offY);
			return;
		end

		-- Sin minimo, padding ni corrimiento: el recuadro ES el frame.
		if minW == 0 and minH == 0 and padX == 0 and padY == 0
			and offX == 0 and offY == 0 then
			self:SetAllPoints(box);
			return;
		end

		-- Centrado sobre el frame, con el tamaño que haga falta.
		--
		-- EL FACTOR DE ESCALA NO ES OPCIONAL. GetWidth devuelve el ancho en
		-- el espacio del FRAME; SetSize lo interpreta en el espacio del
		-- RECUADRO. Si el frame esta escalado (Ctrl + rueda) los dos
		-- espacios dejan de coincidir: con la barra de casteo al 2.00, el
		-- frame mide 195 en su espacio pero 390 en pantalla, y sin convertir
		-- el recuadro salia de 223 — la mitad de la barra.
		--
		-- SetAllPoints no tiene este problema porque ancla esquina con
		-- esquina y la conversion la hace el motor. Al pasar a SetSize hay
		-- que hacerla a mano.
		local ts = box:GetEffectiveScale() or 1;
		local os = self:GetEffectiveScale() or 1;
		if ts == 0 then ts = 1; end
		if os == 0 then os = 1; end
		local k = ts / os;

		self:SetSize(math.max(w * k + padX * 2, minW),
		             math.max(h * k + padY * 2, minH));
		self:SetPoint("CENTER", box, "CENTER", offX, offY);
	end
	overlay.AnchorOverlay = AnchorOverlay;
	overlay:EnableMouse(true);
	overlay:SetMovable(true);
	overlay:RegisterForDrag("LeftButton");
	overlay:Hide();

	-- Aspecto del recuadro.
	--
	-- Antes era una textura plana celeste, sin borde: con quince recuadros
	-- encimados no se distinguia donde terminaba uno y empezaba el otro.
	-- Ahora lleva backdrop con borde, y el color dice de que se trata:
	--
	--   naranja = marcos de unidad (Player, Target, Focus, Party, Arena)
	--   celeste = todo lo demas (barras, auras, avisos, timers)
	--
	-- Es la misma idea del mover de pw_unitframes, que separa por color el
	-- marco principal de los elementos que cuelgan de el.
	overlay:SetBackdrop(MOVER_BACKDROP);
	local col = (entry.group == "frames") and COLOR_FRAME or COLOR_EXTRA;
	overlay:SetBackdropColor(col[1], col[2], col[3], col[4]);
	overlay:SetBackdropBorderColor(unpack(COLOR_EDGE));

	-- Etiqueta en la ESQUINA, no al centro.
	--
	-- Centrada caia justo donde casi todos los frames tienen su propio
	-- texto — el nombre del compañero, el de la barra de casteo — y los dos
	-- se encimaban hasta volverse ilegibles. Arriba a la izquierda no hay
	-- nada con que chocar, y ademas queda claro a que recuadro pertenece
	-- cuando dos se solapan.
	--
	-- Lleva una chapita oscura detras: sobre el mundo, un texto amarillo
	-- suelto se pierde apenas pasas sobre algo claro.
	overlay.textBG = overlay:CreateTexture(nil, "ARTWORK");
	overlay.textBG:SetTexture(0, 0, 0, 0.65);

	overlay.text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
	overlay.text:SetPoint("TOPLEFT", overlay, "TOPLEFT", 5, -4);
	overlay.text:SetTextColor(1, 0.82, 0);
	overlay.text:SetText(entry.label);

	overlay.textBG:SetPoint("TOPLEFT",     overlay.text, "TOPLEFT",     -3,  2);
	overlay.textBG:SetPoint("BOTTOMRIGHT", overlay.text, "BOTTOMRIGHT",  3, -2);

	overlay.target = frame;
	overlay.entry  = entry;

-- ---------------------------------------------------------
-- Cuadricula
--
-- La pantalla se trata como dividida en casilleros de GRID pixeles, y el
-- frame se engancha al casillero mas cercano mientras lo arrastras. Sirve
-- para alinear dos frames entre si sin pelearla a ojo: si los dos caen en
-- la misma columna, quedan derechos y listo.
--
-- POR QUE NO ALCANZA CON StartMoving
-- StartMoving es de Blizzard y pega el frame al cursor pixel a pixel, sin
-- lugar para meter el redondeo. Asi que el arrastre se hace a mano: se
-- guarda donde estaban el frame y el cursor al empezar, y en cada cuadro
-- se reposiciona segun cuanto se corrio el cursor, ya redondeado.
--
-- LA CUADRICULA VA EN PIXELES DE PANTALLA, NO DEL FRAME
-- Esto es lo que hace que la cosa realmente sirva. Los offsets de SetPoint
-- estan en el espacio del frame, que depende de su escala: redondear ahi
-- haria que un frame al 1.5 caiga cada 15 pixeles reales y otro al 1.0
-- cada 10, y nunca coincidirian. Por eso se redondea la posicion en
-- pantalla y recien despues se traduce de vuelta a offsets.
-- ---------------------------------------------------------
-- El lado del casillero lo elige el usuario desde el panel (2, 5 o 10).
-- Se lee en cada arrastre, no se cachea: asi cambiar la opcion tiene
-- efecto en el acto, sin recargar ni volver a abrir el modo mover.
local function GridStep()
	local v = C and C.MoveGridStep;
	if type(v) ~= "number" or v < 1 then return 10; end
	return v;
end

local function BeginDrag(overlay)
	local f = overlay.target;
	if not f then return; end

	-- SOLTARLO DEL GESTOR DE BLIZZARD ANTES DE MOVERLO.
	--
	-- Las barras de auras, mascota, formas y totems las reposiciona
	-- UIParent_ManageFramePositions todo el tiempo. Se marcaban como
	-- "managed" recien al guardar, asi que durante el arrastre Blizzard
	-- las devolvia a su lugar en el mismo frame en que las moviamos: se
	-- veian como si no se movieran para nada.
	if overlay.entry and overlay.entry.managed then
		f.ignoreFramePositionManager = true;
	end

	local point, relTo, relPoint, ox, oy = f:GetPoint(1);
	if not point then
		-- Sin punto propio no hay de donde partir; se le da uno.
		f:ClearAllPoints();
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		point, relTo, relPoint, ox, oy = f:GetPoint(1);
		if not point then return; end
	end

	local cx, cy = GetCursorPosition();
	overlay.drag = {
		point = point, relTo = relTo, relPoint = relPoint,
		ox = ox or 0, oy = oy or 0, cx = cx, cy = cy,
	};

	overlay:SetScript("OnUpdate", function(self)
		local d = self.drag;
		if not d or not self.target then return; end
		local f = self.target;

		local es = f:GetEffectiveScale();
		if not es or es == 0 then es = 1; end

		-- 1) seguir al cursor, uno a uno
		local nx, ny = GetCursorPosition();
		local ox = d.ox + (nx - d.cx) / es;
		local oy = d.oy + (ny - d.cy) / es;
		f:ClearAllPoints();
		f:SetPoint(d.point, d.relTo, d.relPoint, ox, oy);

		-- 2) ver donde cayo EN PANTALLA y correrlo al casillero mas cercano
		local left, bottom = f:GetLeft(), f:GetBottom();
		if left and bottom then
			local grid = GridStep();
			local sl, sb = left * es, bottom * es;
			local tl = math.floor(sl / grid + 0.5) * grid;
			local tb = math.floor(sb / grid + 0.5) * grid;
			-- la correccion vuelve al espacio del frame para sumarla al offset
			f:ClearAllPoints();
			f:SetPoint(d.point, d.relTo, d.relPoint,
				ox + (tl - sl) / es,
				oy + (tb - sb) / es);
		end

		self:AnchorOverlay();
	end);
end

local function EndDrag(overlay)
	overlay:SetScript("OnUpdate", nil);
	overlay.drag = nil;
end

	overlay:SetScript("OnDragStart", function(self)
		if self.entry.protected and InCombatLockdown() then
			print("|cffFF5555NUF:|r " .. (L["MOVE_COMBAT_BLOCK"]
				or "Action bars cannot be moved during combat."));
			return;
		end
		-- Soltarlo del sistema de posiciones de Blizzard ANTES de moverlo,
		-- si no se vuelve solo a su lugar al soltar el mouse.
		ReleaseManaged(self.entry, self.target);
		UnlockFramePoint(self.target);
		-- Los de party: reparentar a UIParent para que el punto guardado
		-- quede relativo a la pantalla y no a NidhausPartyFrame (que en
		-- modo normal es el padre). Asi ApplyIndividualPartyPositions lo
		-- reaplica igual sin importar el modo.
		if self.entry.partyIndex and not InCombatLockdown() then
			-- Y ademas soltar a los CUATRO de la fila: si no, mover el
			-- primero arrastraba a los otros tres, que cuelgan de el.
			DetachPartyChain();
			self.target:SetParent(UIParent);
		end
		self.target:SetMovable(true);
		if self.entry.auraAnchor or self.entry.debuffAnchor then self.target:EnableMouse(false); end
		self.target:SetClampedToScreen(true);   -- que no se salga de la pantalla
		BeginDrag(self);
		self.isMoving = true;
	end);

	overlay:SetScript("OnDragStop", function(self)
		if not self.isMoving then return; end
		self.isMoving = false;
		EndDrag(self);
		if self.target.SetUserPlaced and not self.target:IsProtected() then
			pcall(self.target.SetUserPlaced, self.target, true);
		end

		-- ¿QUIEN ES EL DUEÑO DE ESTA POSICION?
		--
		-- Para casi todo, este modulo: se guarda en globalPos y se pone un
		-- lock sobre SetPoint para que nadie la corra despues.
		--
		-- Pero hay frames cuya posicion la maneja OTRO modulo, con su propio
		-- formato. Los del grupo (3v3 / movimiento individual) ya estaban
		-- contemplados. Los PARTY TARGET no, y por eso el del compa 1 se
		-- portaba distinto a los otros tres:
		--
		--   - solo el 1 pasa por aca, porque es el unico con recuadro
		--   - al soltarlo se le guardaba una posicion en globalPos Y se le
		--     ponia un lock
		--   - el lock reaplicaba esa posicion cada vez que PartyTargets
		--     intentaba anclarlo a su PartyMemberFrame
		--
		-- Dos sistemas empujando el mismo frame: el 1 quedaba donde decia el
		-- lock y los otros tres donde decia el modulo.
		local moduleOwned = self.entry.partyIndex or self.entry.partyTarget;

		if not moduleOwned then
			SavePosition(self.entry, self.target);
			local pos = DB()[self.entry.key];
			if pos and pos.point then LockFramePoint(self.target, self.entry, pos); end
		elseif self.entry.partyIndex then
			if C.PartyMode3v3 and K.Apply3v3PartyMode then
				pcall(K.Apply3v3PartyMode);
			elseif K.ApplyIndividualPartyPositions then
				pcall(K.ApplyIndividualPartyPositions);
			end
		end

		if self.entry.auraAnchor and K.ReanchorAuras then K.ReanchorAuras(); end
		if self.entry.debuffAnchor and K.ReanchorDebuffs then K.ReanchorDebuffs(); end
		if self.entry.partyCast and K.MirrorPartyCastBars then
			pcall(K.MirrorPartyCastBars);
		end
		if self.entry.partyTarget and PartyTargets_AnchorFromFrame then
			-- El modulo recalcula el offset compartido a partir de donde
			-- quedo este, y reancla los cuatro.
			pcall(PartyTargets_AnchorFromFrame, self.target);
		end
		self:AnchorOverlay();
	end);

	-- Ctrl + rueda = escalar este frame
	if entry.scalable then
		overlay:EnableMouseWheel(true);
		overlay:SetScript("OnMouseWheel", function(self, delta)
			if not IsControlKeyDown() then return; end
			if self.entry.protected and InCombatLockdown() then return; end

			local current = self.target:GetScale() or 1;
			local newScale = current + (delta > 0 and 0.05 or -0.05);
			if newScale < 0.5 then newScale = 0.5; end
			if newScale > 2.0 then newScale = 2.0; end

			self.target:SetScale(newScale);
			SaveScale(self.entry, newScale);

			-- Mantener los sliders del panel en sincronia
			if K.SyncFrameScaleSetting then
				K.SyncFrameScaleSetting(self.entry.key, newScale);
			end

			self.text:SetText(self.entry.label .. "  " .. string.format("%.2f", newScale));
			self:AnchorOverlay();
		end);
	end

	overlay.target = frame;
	overlay.entry  = entry;
	AnchorOverlay(overlay);

	return overlay;
end

-- Puente con los sliders de la pestaña Frames: si escalas con la rueda,
-- el setting correspondiente se actualiza para que el slider no quede desfasado.
-- Que slider del panel le corresponde a cada frame movible.
--
-- "Party" estaba muerto: no existe ningun movible con esa clave, son
-- cuatro (Party1..Party4). O sea que escalar un marco del grupo con
-- Ctrl + rueda nunca movia el slider de Party Frame Scale.
local SCALE_SETTING = {
	Player = "PlayerFrameScale",
	Target = "TargetFrameScale",
	Focus  = "FocusScale",
	Pet    = "PetFrameScale",
	Party1 = "PartyFrameScale",
	Party2 = "PartyFrameScale",
	Party3 = "PartyFrameScale",
	Party4 = "PartyFrameScale",
	MainBar = "ActionBarScale",
	CastBar = "CastBarPWScale",
};

-- El camino inverso: que frames movibles maneja un slider dado.
--
-- Lo usa el panel para que mover el slider escriba en el MISMO lugar
-- donde escribe Ctrl + rueda. Antes cada uno guardaba en el suyo — el
-- slider en C, la rueda en globalPos — y al reloguear ganaba globalPos:
-- el marco volvia al tamaño viejo y el slider seguia mostrando el
-- nuevo, sin que se entendiera por que.
local SETTING_MOVABLES = {};
for key, setting in pairs(SCALE_SETTING) do
	SETTING_MOVABLES[setting] = SETTING_MOVABLES[setting] or {};
	table.insert(SETTING_MOVABLES[setting], key);
end
for _, list in pairs(SETTING_MOVABLES) do table.sort(list); end

function K.GetMovablesForSetting(setting)
	return SETTING_MOVABLES[setting];
end

function K.SyncFrameScaleSetting(key, scale)
	local setting = SCALE_SETTING[key];
	if not setting then return; end
	if K.SaveConfigSilent then
		K.SaveConfigSilent(setting, scale);
	elseif K.SaveConfig then
		K.SaveConfig(setting, scale);
	end
	if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
	if K.RefreshCastBarScaleSlider then K.RefreshCastBarScaleSlider(); end
end

-- Se puede volver a llamar: algunos frames (NidhausPlayerFrame, las barras
-- de los timers) se crean tarde, asi que reintentamos crear los que falten
-- y reanclamos los que ya existen.
local builtFor = {};

local function BuildOverlays()
	-- La caja que abarca todas las barras se recalcula antes de anclar: su
	-- tamaño depende de que barras esten a la vista y del modo puesto.
	if K.UpdateActionBarsBox then pcall(K.UpdateActionBarsBox); end
	if K.UpdateStanceBarBox then pcall(K.UpdateStanceBarBox); end

	for _, entry in ipairs(MOVABLES) do
		-- Los que traen su propio arrastre no llevan recuadro: sumaria un
		-- segundo sistema encima del que ya funciona.
		if entry.noOverlay then
			-- nada que construir
		elseif not builtFor[entry.key] then
			local ov = CreateOverlay(entry);
			if ov then
				builtFor[entry.key] = ov;
				table.insert(overlays, ov);
			end
		else
			-- Re-resolver por si el frame real cambio
			local f = ResolveFrame(entry);
			local ov = builtFor[entry.key];
			if f and ov.target ~= f then
				ov.target = f;
			end
			if ov.target and ov.AnchorOverlay then ov:AnchorOverlay(); end
		end
	end
end

-- ---------------------------------------------------------
-- Toggle
-- ---------------------------------------------------------
-- ---------------------------------------------------------
-- Consola del modo mover
--
-- Mientras el modo mover esta activo aparece una ventanita con lo que uno
-- necesita EN ESE MOMENTO. La cuadricula estaba solo en el panel de
-- opciones, o sea que para cambiarla habia que abrir el panel, buscarla y
-- volver — justo lo que no queres hacer mientras estas acomodando cosas.
--
-- Es movible y recuerda donde la dejaste.
-- ---------------------------------------------------------
local console;

local function BuildConsole()
	if console then return console; end

	console = CreateFrame("Frame", "NUF_MoverConsole", UIParent);
	console:SetSize(320, 124);

	-- TOOLTIP, no FULLSCREEN_DIALOG.
	--
	-- Los recuadros movibles viven en FULLSCREEN_DIALOG y su nivel va
	-- subiendo con cada uno que se crea. Con la consola en esa misma capa,
	-- alcanzaba con que un recuadro quedara encima para que los botones no
	-- respondieran al click. TOOLTIP esta por arriba de todo eso, asi que
	-- la consola siempre recibe el mouse.
	console:SetFrameStrata("TOOLTIP");
	console:SetToplevel(true);
	console:SetBackdrop(MOVER_BACKDROP);
	console:SetBackdropColor(0, 0, 0, 0.75);
	console:SetBackdropBorderColor(1, 0.71, 0, 0.45);
	console:Hide();

	-- Posicion propia, guardada aparte de la de los frames movibles.
	local saved = NidhausUnitFramesDB and NidhausUnitFramesDB.moverConsolePos;
	if saved and saved.point then
		console:SetPoint(saved.point, UIParent, saved.relPoint or saved.point,
			saved.x or 0, saved.y or 0);
	else
		-- Arriba y a la derecha, no en el centro.
		--
		-- A -150 en el eje central caia justo encima del personaje, que es
		-- lo unico que NO queres tapar mientras acomodas la interfaz.
		console:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -40, -60);
	end

	console:EnableMouse(true);
	console:SetMovable(true);
	console:SetClampedToScreen(true);
	console:RegisterForDrag("LeftButton");
	console:SetScript("OnDragStart", function(self) self:StartMoving(); end);
	console:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
		local point, _, relPoint, x, y = self:GetPoint(1);
		if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
		NidhausUnitFramesDB.moverConsolePos = {
			point = point, relPoint = relPoint, x = x, y = y,
		};
	end);

	console.title = console:CreateFontString(nil, "OVERLAY", "GameFontNormal");
	console.title:SetPoint("TOP", console, "TOP", 0, -8);
	console.title:SetTextColor(1, 0.8, 0);
	console.title:SetText(L["MOVER_CONSOLE"] or "Move Everything");

	-- Dos filas: arriba la cuadricula, abajo las acciones.
	--
	-- Antes iba todo en una sola linea y las cuentas no cerraban: Reset
	-- arrancaba en x=148, justo donde terminaba el boton x10. Se pisaban, y
	-- el click caia en el que estuviera dibujado ultimo. De ahi que Reset y
	-- Lock it parecieran no responder.
	-- El escalado con Ctrl + rueda no estaba escrito en ningun lado: era
	-- una funcion que solo conocia quien leyera el codigo.
	console.hint = console:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	console.hint:SetPoint("TOP", console, "TOP", 0, -22);
	console.hint:SetText("|cff8EAEC9" .. (L["MOVER_HINT_SCALE"]
		or "Ctrl + mouse wheel over a box to scale it") .. "|r");

	console.gridLbl = console:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	console.gridLbl:SetPoint("TOPLEFT", console, "TOPLEFT", 14, -52);
	console.gridLbl:SetText(L["LBL_MOVE_GRID"] or "Grid");

	-- Los tres pasos de cuadricula, a mano y sin abrir nada.
	console.gridBtns = {};
	local function RefreshGrid()
		local cur = (C and C.MoveGridStep) or 10;
		for step, b in pairs(console.gridBtns) do
			if step == cur then b:LockHighlight(); else b:UnlockHighlight(); end
		end
	end
	console.RefreshGrid = RefreshGrid;

	local gx = 56;
	for _, step in ipairs({ 2, 5, 10 }) do
		local b = CreateFrame("Button", nil, console, "UIPanelButtonTemplate");
		b:SetPoint("TOPLEFT", console, "TOPLEFT", gx, -48);
		b:SetSize(50, 22);
		b:SetText("x" .. step);
		b:SetScript("OnClick", function()
			if K.SaveConfig then K.SaveConfig("MoveGridStep", step); end
			RefreshGrid();
			-- El panel de opciones, si esta abierto, tiene los mismos tres
			-- botones: hay que dejarlos en el mismo estado.
			if K._RefreshMoveGridButtons then pcall(K._RefreshMoveGridButtons); end
		end);
		console.gridBtns[step] = b;
		gx = gx + 54;
	end

	-- Segunda fila, bien separada de la de arriba.
	local lockBtn = CreateFrame("Button", nil, console, "UIPanelButtonTemplate");
	lockBtn:SetPoint("BOTTOMRIGHT", console, "BOTTOMRIGHT", -14, 12);
	lockBtn:SetSize(120, 24);
	lockBtn:SetText(L["BTN_LOCK_IT"] or "Lock it");
	lockBtn:SetScript("OnClick", function()
		if K.SetGlobalUnlock then K.SetGlobalUnlock(false, currentScope); end
	end);

	local resetBtn = CreateFrame("Button", nil, console, "UIPanelButtonTemplate");
	resetBtn:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", 14, 12);
	resetBtn:SetSize(120, 24);
	resetBtn:SetText(L["BTN_MOVE_RESET"] or "Reset");
	resetBtn:SetScript("OnClick", function()
		if K.ResetGlobalPositions then K.ResetGlobalPositions(); end
	end);

	RefreshGrid();
	return console;
end

-- Recalcula que recuadros se ven, sin apagar ni prender el modo mover.
--
-- Hace falta porque los checkbox de los modulos se pueden tocar CON el modo
-- mover ya activo. Antes la lista de recuadros se armaba una sola vez al
-- entrar al modo: tildabas un modulo y su marco no aparecia hasta salir y
-- volver a entrar, lo cual no tenia ninguna logica visible desde afuera.
--
-- Tambien dispara el modo prueba del modulo recien prendido, para que su
-- frame se vea aunque normalmente este oculto hasta que pase algo.
function K.RefreshGlobalUnlockOverlays()
	if not unlocked then return; end

	BuildOverlays();

	for _, entry in ipairs(MOVABLES) do
		if entry.preview and K[entry.preview] then
			pcall(K[entry.preview], EntryModuleActive(entry) and true or false);
		end
	end

	for _, ov in ipairs(overlays) do
		if EntryInScope(ov.entry) then
			if ov.AnchorOverlay then ov:AnchorOverlay(); end
			ov:Show();
		else
			ov:Hide();
		end
	end
end

function K.SetGlobalUnlock(state, scope)
	unlocked = state and true or false;

	-- Los modulos con modo mover PROPIO se fijan primero: si no, quedan dos
	-- sistemas de arrastre sobre el mismo frame y se traba.
	if unlocked then
		if K.IsMeleeSwingUnlocked and K.IsMeleeSwingUnlocked() then
			pcall(K.ToggleMeleeSwingUnlock);
		end
	end

	-- Varios modulos tienen el frame oculto hasta que pasa algo (un CD, un
	-- golpe). En modo mover hay que mostrarlos igual, si no el recuadro azul
	-- apunta a algo invisible y no sabes donde lo estas dejando.
	for _, entry in ipairs(MOVABLES) do
		-- Solo de modulos PRENDIDOS: si no, se disparaba el modo prueba de
		-- algo que el usuario tiene apagado y aparecia un marco que no
		-- deberia existir.
		if entry.preview and K[entry.preview] and EntryModuleActive(entry) then
			pcall(K[entry.preview], unlocked);
		end
	end
	currentScope = scope or "all";
	BuildOverlays();

	for _, ov in ipairs(overlays) do
		if unlocked and EntryInScope(ov.entry) then
			if ov.AnchorOverlay then ov:AnchorOverlay(); end
			ov:Show();
		else
			ov:Hide();
		end
	end

	-- Modo prueba de party: sin grupo no hay marcos que mover
	if K.SetPartyTestMode then
		pcall(K.SetPartyTestMode, unlocked);
	end

	-- Marcos de arena: se usa exactamente el mismo camino que /nuf arena
	-- (K.ToggleArenaFramesMover). El estado real NO es mover:IsShown(), es
	-- NidhausUnitFramesDB.ArenaMover.IsShown — mirar el frame era el motivo
	-- de que se mostrara pero nunca se ocultara.
	if K.ToggleArenaFramesMover and not InCombatLockdown() then
		local db = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover;
		local shown = (db and db.IsShown) and true or false;

		if unlocked then
			if not shown then pcall(K.ToggleArenaFramesMover); end
		else
			if shown then pcall(K.ToggleArenaFramesMover); end
		end
	end

	-- Consola en pantalla: solo mientras el modo esta activo.
	if unlocked then
		local c = BuildConsole();
		if c then
			if c.RefreshGrid then c:RefreshGrid(); end
			c:Show();
		end
	elseif console then
		console:Hide();
	end

	-- Sin aviso por chat: los recuadros azules ya se ven, el print solo
	-- ensuciaba el chat cada vez que se prendia o apagaba el modo mover.
end

function K.IsGlobalUnlocked()
	return unlocked;
end

function K.ToggleGlobalUnlock(scope)
	K.SetGlobalUnlock(not unlocked, scope);
end

-- Devuelve las barras de NUF a su posicion de fabrica
function K.ResetTimerBarPositions()
	if K.ResetAutoShotTimerPosition then pcall(K.ResetAutoShotTimerPosition); end
	if K.ResetMeleeSwingTimerPosition then pcall(K.ResetMeleeSwingTimerPosition); end
	if K.ResetArrowCountPosition then pcall(K.ResetArrowCountPosition); end
end

-- only = tabla opcional { Clave = true } para resetear SOLO esos movibles.
-- Sin ella resetea todo, como siempre. Se agrego porque el boton Reset de
-- Action Bars te borraba tambien la posicion de buffs, debuffs y demas.

-- ---------------------------------------------------------
-- STORES PROPIOS DE CADA MODULO
--
-- ACA ESTABA EL AGUJERO DEL RESET.
--
-- Los modulos con marco propio (el tracker de paladin, Turn Evil, la
-- alerta de hechizos, el contador de flechas...) guardan SU posicion en
-- SU propia tabla, no en globalPos. El Reset borraba globalPos y reponia
-- el frame, pero el modulo volvia a aplicar su posicion guardada en el
-- siguiente refresco o al reloguear: parecia que el Reset no habia hecho
-- nada.
--
-- Aca se limpian SOLO los campos de posicion. El resto de cada tabla —
-- la lista de hechizos de la alerta, el modo de la gargola, las zonas
-- donde se muestra — queda intacto: eso es configuracion del usuario,
-- no posicion.
-- ---------------------------------------------------------
local POS_FIELDS = { "point", "rel", "relPoint", "relativePoint",
                     "relativeTo", "x", "y" };

-- entrada -> tabla dentro de NidhausUnitFramesDB
local OWN_STORES = {
	PalAuras     = "PaladinAuras",
	TurnEvil     = "TurnEvil",
	EnemyAlert   = "EnemySpellAlert",
	ArrowCount   = "ArrowCount",
	DungeonRoles = "DungeonRoles",
	AutoShot     = "AutoShotTimer",
	SwingTimer   = "MeleeSwingTimer",
	Gargoyle     = "GargoyleTracker",
	-- Los timers de clase del mago guardan en ClassTimers; los de arena
	-- (tubo de Dalaran, pilares, fin de ronda) en timerPos.
	WaterEle     = "ClassTimers",
	MirrorImg    = "ClassTimers",
	DalaranPipe  = "timerPos",
	RoVPillars   = "timerPos",
	ArenaEnd     = "timerPos",
};

-- entrada -> variable guardada APARTE (tienen su propio SavedVariable)
local OWN_GLOBALS = {
	PaladinICD   = "PaladinICD_DB",
	SacredShield = "SacredShieldDB",
	SSTracker    = "SacredShieldTrackerDB",
	Seduction    = "SeductionAlertDB",
};

-- Borra los campos de posicion de una tabla. Si al hacerlo la tabla
-- queda VACIA, devuelve true para que el llamador la elimine entera.
--
-- Esto ultimo no es un detalle: los modulos preguntan "hay algo
-- guardado?" mirando si la tabla existe, no si tiene campos. Una tabla
-- vacia les hacia creer que si, y despues llamaban a SetPoint con un
-- punto nil. Justo lo que reventaba el timer del tubo de Dalaran.
local function WipePos(tbl)
	if type(tbl) ~= "table" then return false; end

	for _, f in ipairs(POS_FIELDS) do tbl[f] = nil; end

	-- Algunos guardan la posicion en una sub-tabla por marco o por perfil.
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			local vacia = true;
			for _, f in ipairs(POS_FIELDS) do v[f] = nil; end
			for _ in pairs(v) do vacia = false; break; end
			if vacia then tbl[k] = nil; end
		end
	end

	for _ in pairs(tbl) do return false; end
	return true;   -- quedo vacia
end

local function ClearOwnStore(key)
	local name = OWN_STORES[key];
	if name and NidhausUnitFramesDB then
		if WipePos(NidhausUnitFramesDB[name]) then
			NidhausUnitFramesDB[name] = nil;
		end
	end
	local gname = OWN_GLOBALS[key];
	if gname and _G[gname] then
		if WipePos(_G[gname]) then _G[gname] = nil; end
	end
end

-- LIMPIEZA DE UNA SOLA VEZ.
--
-- El Focus estuvo un tiempo en la lista de arriba, asi que puede haber una
-- posicion suya guardada. Como ya no figura, nadie la aplicaria ni la
-- borraria nunca: se queda de basura en la config. Se saca al cargar.
local function DropLegacyFocusPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;
	if db and db.Focus then db.Focus = nil; end
end

function K.ResetGlobalPositions(only)
	CaptureOriginals();

	local function Wanted(key) return (not only) or only[key]; end

	-- Borrar lo guardado ANTES de reponer, para que el hook de SetPoint
	-- no vuelva a aplicar la posicion vieja mientras restauramos.
	if NidhausUnitFramesDB then
		if only then
			local db = NidhausUnitFramesDB.globalPos;
			if db then
				for key in pairs(only) do db[key] = nil; end
			end
		else
			NidhausUnitFramesDB.globalPos = nil;
		end
	end

	-- Los miembros de party guardan en otro store (FrameDragger); limpiarlo
	-- tambien, si no el 3v3 seguiria leyendo posiciones viejas.
	if not only and NidhausUnitFramesDB and NidhausUnitFramesDB.positions then
		for i = 1, (MAX_PARTY_MEMBERS or 4) do
			NidhausUnitFramesDB.positions["PartyMemberFrame" .. i] = nil;
		end
	end
	if not only and C.PartyIndividualMove then
		C.PartyIndividualMove = false;
		if K.SaveConfig then K.SaveConfig("PartyIndividualMove", false); end
	end

	-- Soltar el lock, devolver al sistema de Blizzard y reponer el original
	for _, entry in ipairs(MOVABLES) do
		if Wanted(entry.key) then
			local f = ResolveFrame(entry);
			if f then
				UnlockFramePoint(f);
				f.NUFPoint = nil;
			end
			ReclaimManaged(entry);
			pcall(RestoreOriginal, entry);
			-- Algunos movibles son frames PROPIOS creados al vuelo (el
			-- Holder de posturas, por ejemplo). Su "original" puede no
			-- existir, asi que cada uno puede traer su propio reset.
			if entry.resetFunc and K[entry.resetFunc] then
				pcall(K[entry.resetFunc]);
			end
			-- ...y limpiar su store propio, si tiene.
			pcall(ClearOwnStore, entry.key);
		end
	end

	-- Barras de casteo del grupo.
	--
	-- El bucle de arriba solo repone la del compa 1, que es la unica que
	-- figura en MOVABLES. Las otras tres no guardan posicion propia: la
	-- copian de la 1 con MirrorPartyCastBars, y eso NO se estaba volviendo a
	-- llamar despues del Reset. Resultado: la 1 volvia a su sitio y las otras
	-- tres se quedaban colgadas del ultimo arrastre, sueltas por la pantalla.
	--
	-- PartyCastingBars trae su propio reset, que devuelve LAS CUATRO al
	-- costado de su marco de grupo. Es la referencia buena, asi que se usa esa
	-- en vez de recalcular offsets a mano.
	if Wanted("PartyCast") then
		if PartyCastingBars and PartyCastingBars.ResetBarLocations then
			pcall(PartyCastingBars.ResetBarLocations);
		elseif K.MirrorPartyCastBars then
			pcall(K.MirrorPartyCastBars);
		end
	end

	-- Devolver los party a su fila normal / o a la config 3v3
	if not only then
		if C.PartyMode3v3 and K.Apply3v3PartyMode then
			pcall(K.Apply3v3PartyMode);
		elseif K.RestorePartyToGroup then
			pcall(K.RestorePartyToGroup);
		end

		K.ResetTimerBarPositions();
	end
	if Wanted("Buffs") or Wanted("Debuffs") then
		if K.ResetAuraAnchor then K.ResetAuraAnchor(); end
	end

	-- Que Blizzard recoloque todo lo que administra (castbar, buffs, barras)
	if not InCombatLockdown() and type(UIParent_ManageFramePositions) == "function" then
		pcall(UIParent_ManageFramePositions);
	end

	-- Reposicionar los recuadros azules si el modo mover sigue activo
	for _, ov in ipairs(overlays) do
		if ov.AnchorOverlay then pcall(ov.AnchorOverlay, ov); end
	end

	-- ...y otra vez un frame despues. UIParent_ManageFramePositions (arriba)
	-- recoloca buffs y barras DESPUES de que reseteamos, asi que el ancla de
	-- auras y su recuadro azul quedaban en el lugar viejo: las auras volvian
	-- a su sitio pero la caja de arrastre no. Con este segundo pase, ya con
	-- todo asentado, los dos terminan donde corresponde.
	local settle = CreateFrame("Frame");
	settle:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil);
		if Wanted("Buffs") or Wanted("Debuffs") then
			if K.ResetAuraAnchor then pcall(K.ResetAuraAnchor); end
		end
		for _, ov in ipairs(overlays) do
			if ov.AnchorOverlay then pcall(ov.AnchorOverlay, ov); end
		end
	end);

	-- ── ESCALAS ──
	--
	-- Borrar globalPos limpia el numero guardado, pero eso NO devuelve el
	-- frame a 1.0: la escala ya esta puesta sobre el frame y ahi se queda.
	-- Por eso al resetear volvia la posicion pero la barra de casteo seguia
	-- agrandada. Hay que ponersela de vuelta a mano.
	for _, entry in ipairs(MOVABLES) do
		if entry.scalable and Wanted(entry.key) then
			local f = ResolveFrame(entry);
			if f and f.SetScale then
				pcall(f.SetScale, f, 1.0);
			end
			-- Los anclas de auras guardan su escala en su propio store.
			if entry.auraAnchor and K.SaveAuraAnchorScale then
				pcall(K.SaveAuraAnchorScale, 1.0);
			elseif entry.debuffAnchor and K.SaveDebuffAnchorScale then
				pcall(K.SaveDebuffAnchorScale, 1.0);
			end
			if K.SyncFrameScaleSetting then
				pcall(K.SyncFrameScaleSetting, entry.key, 1.0);
			end
		end
	end

	-- Y refrescar los sliders del panel, que ahora valen otra cosa
	if K.RefreshScaleSliders then K.RefreshScaleSliders(); end
	print("|cff4FC3F7NUF:|r " .. (L["MOVE_RESET"]
		or "Saved positions cleared. /reload to restore the defaults."));
end

-- ---------------------------------------------------------
-- Restaurar al entrar al mundo
-- ---------------------------------------------------------
local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:SetScript("OnEvent", function(self)
	DropLegacyFocusPos();

	-- Capturar el estado de fabrica antes de aplicar nada nuestro
	CaptureOriginals();

	-- Esperar unos frames: varias barras se crean tarde
	local acc, tries = 0, 0;
	self:SetScript("OnUpdate", function(s, elapsed)
		acc = acc + elapsed;
		if acc < 0.5 then return; end
		acc = 0;
		tries = tries + 1;
		CaptureOriginals();
		K.RestoreGlobalPositions();
		if tries >= 3 then s:SetScript("OnUpdate", nil); end
	end);
end);

-- Cuando otro módulo reanclea frames (New Party Frame, modo 3v3, etc.)
-- hay que reponer lo que el usuario movió. Se hace UNA sola pasada con un
-- pequeño retardo. Antes esto corría en cada CONFIG_CHANGED y hacía
-- parpadear los buffs con cada checkbox del panel.
local reapply = CreateFrame("Frame");
local reapplyAcc = 0;
reapply:Hide();
reapply:SetScript("OnUpdate", function(self, elapsed)
	reapplyAcc = reapplyAcc + elapsed;
	if reapplyAcc < 0.3 then return; end
	self:Hide();
	if not InCombatLockdown() and HasSavedPositions() then
		K.RestoreGlobalPositions();
	end
end);

function K.ScheduleGlobalPositionReapply()
	if not HasSavedPositions() then return; end
	reapplyAcc = 0;
	reapply:Show();
end

-- Salir del modo mover al entrar en combate (los frames protegidos rompen)
local combatGuard = CreateFrame("Frame");
combatGuard:RegisterEvent("PLAYER_REGEN_DISABLED");
combatGuard:SetScript("OnEvent", function()
	if unlocked then K.SetGlobalUnlock(false); end
end);

-- Varios alias a proposito.
--
-- "/nufmove" hay que acordarselo; "/move" sale solo. Se dejan los tres
-- porque un alias corto siempre corre el riesgo de que otro addon lo pise
-- (el ultimo que registra gana), y asi si /move te lo roba alguien todavia
-- tenes los largos, que son unicos.
SLASH_NUFMOVE1 = "/nufmove";
SLASH_NUFMOVE2 = "/move";
SLASH_NUFMOVE3 = "/nufunlock";

SlashCmdList["NUFMOVE"] = function(msg)
	msg = string.lower(msg or "");
	msg = string.gsub(msg, "^%s+", "");
	msg = string.gsub(msg, "%s+$", "");

	if msg == "reset" then
		K.ResetGlobalPositions();
		print("|cff4FC3F7NUF:|r " .. (L["MOVE_RESET_DONE"]
			or "Every frame is back to its default position."));
		return;
	end

	if msg == "lock" then
		K.SetGlobalUnlock(false, currentScope);
		return;
	end

	if msg == "help" or msg == "?" then
		print("|cff4FC3F7NUF - " .. (L["MOVER_CONSOLE"] or "Move Everything") .. "|r");
		print("   /move          " .. (L["MOVE_HELP_ALL"]    or "unlock everything"));
		print("   /move frames   " .. (L["MOVE_HELP_FRAMES"] or "only the unit frames"));
		print("   /move lock     " .. (L["MOVE_HELP_LOCK"]   or "lock it back"));
		print("   /move reset    " .. (L["MOVE_HELP_RESET"]  or "back to default positions"));
		return;
	end

	-- /move frames -> solo los marcos de unidad
	K.ToggleGlobalUnlock(msg == "frames" and "frames" or "all");
end
