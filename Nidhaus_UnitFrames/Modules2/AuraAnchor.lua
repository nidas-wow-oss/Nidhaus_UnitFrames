local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- AuraAnchor.lua
-- Mover los buffs / debuffs del jugador.
--
-- POR QUE ASI: mover BuffFrame no funciona. En 3.3.5a BuffFrame
-- mide 1x1 y, sobre todo, Blizzard vuelve a anclar BuffButton1
-- en CADA actualizacion de auras desde BuffFrame_UpdateAllBuffAnchors.
-- Pelearle con SetPoint es una carrera que se pierde.
--
-- La forma que funciona (y la que usan los addons de auras) es
-- crear un ancla propia y re-anclar BuffButton1 a ella dentro de
-- un hook de esa misma funcion: asi, cada vez que Blizzard reordena
-- las auras, lo ultimo que corre es lo nuestro.
-- =========================================================

local ANCHOR_W, ANCHOR_H = 330, 90;

-- ---------------------------------------------------------
-- DB
-- ---------------------------------------------------------
local function BuffRoot()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.AuraAnchor then NidhausUnitFramesDB.AuraAnchor = {}; end
	return NidhausUnitFramesDB.AuraAnchor;
end

local function DebuffRoot()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.DebuffAnchor then NidhausUnitFramesDB.DebuffAnchor = {}; end
	return NidhausUnitFramesDB.DebuffAnchor;
end

-- ---------------------------------------------------------
-- UNA POSICION POR MODO DE BARRAS
--
-- MiniBar, Unify y "sin modo" dejan las barras a alturas distintas, asi
-- que el lugar donde el bloque de auras queda bien tampoco es el mismo.
--
-- Habia UNA sola posicion guardada: la acomodabas con Unify puesto y, al
-- volver a MiniBar, el bloque reaparecia donde lo habia dejado el otro
-- modo. Y era peor que un simple olvido: este modulo SI se anota en el
-- registro de stores de LayoutCore, asi que en cada cambio de modo
-- re-aplicaba con toda fidelidad la misma posicion para los tres.
--
-- Las barras ya guardaban por modo desde hace rato (PER_MODE_KEYS en
-- GlobalUnlock.lua); las auras se habian quedado afuera de esa idea.
--
-- El modo sale de K.LayoutActiveMode(), el mismo que usa el rearmado: una
-- sola definicion, asi no hay dos que se puedan desincronizar.
-- ---------------------------------------------------------
local MODES = { "mini", "unify", "plain" };

local function Mode()
	if K.LayoutActiveMode then return K.LayoutActiveMode(); end
	-- LayoutCore carga mucho antes que este archivo, asi que este respaldo
	-- no deberia usarse nunca. Queda por si alguien reordena el XML.
	if C.MiniBarEnabled  == true then return "mini";  end
	if C.UnifyActionBars == true then return "unify"; end
	return "plain";
end

-- Devuelve el sub-registro del modo activo, migrando lo viejo la primera
-- vez. Lo guardado antes de que esto existiera es UNA posicion sin modo:
-- se copia a los tres para que nadie pierda lo que ya tenia acomodado, y
-- de ahi en adelante cada modo sigue su propio camino.
local function PerMode(root)
	if root.point ~= nil and type(root.byMode) ~= "table" then
		root.byMode = {};
		for _, m in ipairs(MODES) do
			root.byMode[m] = {
				point = root.point, relativePoint = root.relativePoint,
				x     = root.x,     y             = root.y,
			};
		end
		root.point, root.relativePoint, root.x, root.y = nil, nil, nil, nil;
	end
	if type(root.byMode) ~= "table" then root.byMode = {}; end
	local m = Mode();
	if type(root.byMode[m]) ~= "table" then root.byMode[m] = {}; end
	return root.byMode[m];
end

local function DB()       return PerMode(BuffRoot());   end
local function DebuffDB() return PerMode(DebuffRoot()); end

-- El boton Reset borra los TRES modos. Borrar solo el activo dejaba el
-- bloque "reseteado" hasta que cambiabas de modo y reaparecia movido.
local function WipeAllModes(root)
	root.point, root.relativePoint, root.x, root.y = nil, nil, nil, nil;
	root.byMode = {};
end

local function HasCustomPosition()
	return DB().point ~= nil;
end

local function HasCustomDebuffPosition()
	return DebuffDB().point ~= nil;
end

-- ---------------------------------------------------------
-- Ancla
-- ---------------------------------------------------------
local anchor = CreateFrame("Frame", "NUF_BuffAnchor", UIParent);
anchor:SetSize(ANCHOR_W, ANCHOR_H);
anchor:SetMovable(true);
anchor:SetClampedToScreen(true);
anchor:EnableMouse(false);

-- Ancla de debuffs (bloque separado, debajo de los buffs por defecto)
local debuffAnchor = CreateFrame("Frame", "NUF_DebuffAnchor", UIParent);
debuffAnchor:SetSize(ANCHOR_W, 50);
debuffAnchor:SetMovable(true);
debuffAnchor:SetClampedToScreen(true);
debuffAnchor:EnableMouse(false);

-- Escala configurable desde el panel. Son DOS registros separados porque
-- los bloques de buffs y debuffs se mueven por separado, asi que tambien
-- tiene sentido poder agrandarlos por separado.
if K.RegisterScalable then
	K.RegisterScalable("PlayerBuffs",   anchor,       1.0);
	K.RegisterScalable("PlayerDebuffs", debuffAnchor, 1.0);
end

-- LOS BUFFS SE CORREN SI EL MINIMAPA CRECE
--
-- La posicion de fabrica de los buffs en 3.3.5a es TOPRIGHT -205, y ese
-- 205 sale de lo que mide el minimapa a escala 1. Con el slider de tamaño
-- subido, el mapa se hace mas ancho, su borde izquierdo cruza esos 205
-- pixeles y termina dibujado ENCIMA de los buffs.
--
-- En vez de un numero fijo, se mide donde esta parado el borde izquierdo
-- del minimapa y se deja a los buffs justo antes. El maximo contra 205
-- es a proposito: con el mapa en su tamaño normal el resultado tiene que
-- ser exactamente el de fabrica, ni un pixel corrido.
local DEFAULT_INSET = 205;
local CLUSTER_PAD   = 6;    -- aire entre el borde del mapa y el ultimo buff

local function MinimapInset()
	local mc = MinimapCluster;
	if not mc or not mc.GetLeft then return DEFAULT_INSET; end
	local left = mc:GetLeft();
	-- Antes del primer dibujado no hay coordenadas: se usa el de fabrica
	-- y ya se corrige solo en el proximo refresco.
	if not left then return DEFAULT_INSET; end
	local uiScale = UIParent:GetEffectiveScale();
	if not uiScale or uiScale == 0 then return DEFAULT_INSET; end
	-- GetLeft viene en el espacio del propio frame: se pasa a pixeles de
	-- pantalla y de ahi al espacio de UIParent, que es donde vive el ancla.
	left = left * mc:GetEffectiveScale() / uiScale;
	local inset = UIParent:GetWidth() - left + CLUSTER_PAD;
	if inset < DEFAULT_INSET then inset = DEFAULT_INSET; end
	return inset;
end

-- LA ESCALA ES LA DEL SLIDER (ScaleAPI: "PlayerBuffs" / "PlayerDebuffs").
--
-- Antes habia tres: la del slider del panel, la de Ctrl + rueda (globalPos)
-- y una propia de aca (db.scale). Y la posicion de fabrica ademas le
-- clavaba 1: sin posicion propia, el slider de escala de los buffs se
-- deshacia en cada /reload o al cambiar el minimapa.
local function BuffScale()
	return (K.GetModuleScale and K.GetModuleScale("PlayerBuffs")) or 1;
end
local function DebuffScale()
	return (K.GetModuleScale and K.GetModuleScale("PlayerDebuffs")) or 1;
end

-- Posicion de fabrica de los buffs en 3.3.5a
local function ApplyDefaultAnchorPos()
	anchor:ClearAllPoints();
	anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -MinimapInset(), -13);
	anchor:SetScale(BuffScale());
end

-- Se llama al mover el slider de tamaño del minimapa.
--
-- Solo toca la posicion AUTOMATICA: si vos moviste los buffs a mano, esa
-- posicion es tuya y no se pisa.
function K.RefreshAuraAnchorDefault()
	if HasCustomPosition() then return; end
	ApplyDefaultAnchorPos();
	-- Sin BuffFrame_UpdateAllBuffAnchors: llamada desde el addon corre
	-- manchada (taint) y crea/acomoda los iconos de Blizzard manchados.
	if K.ReanchorAuras then K.ReanchorAuras(); end
	if K.ReanchorDebuffs then K.ReanchorDebuffs(); end
end

local function ApplyDefaultDebuffPos()
	debuffAnchor:ClearAllPoints();
	debuffAnchor:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -20);
	debuffAnchor:SetScale(DebuffScale());
end

local function RestoreAnchorPosition()
	-- Una escala vieja guardada aca pasa al slider (una sola vez). Se lee
	-- de la RAIZ y no del sub-registro por modo: la escala nunca dependio
	-- del modo de barras, solo la posicion.
	local broot = BuffRoot();
	if broot.scale then
		if K.SetModuleScale then K.SetModuleScale("PlayerBuffs", broot.scale); end
		broot.scale = nil;
	end

	local db = DB();
	if db.point then
		anchor:ClearAllPoints();
		anchor:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
		anchor:SetScale(BuffScale());
	else
		ApplyDefaultAnchorPos();
	end

	local droot = DebuffRoot();
	if droot.scale then
		if K.SetModuleScale then K.SetModuleScale("PlayerDebuffs", droot.scale); end
		droot.scale = nil;
	end

	local ddb = DebuffDB();
	if ddb.point then
		debuffAnchor:ClearAllPoints();
		debuffAnchor:SetPoint(ddb.point, UIParent, ddb.relativePoint, ddb.x, ddb.y);
		debuffAnchor:SetScale(DebuffScale());
	else
		ApplyDefaultDebuffPos();
	end
end

function K.SaveAuraAnchorPosition()
	local db = DB();
	local point, _, relativePoint, x, y = anchor:GetPoint();
	if not point then return; end
	db.point = point; db.relativePoint = relativePoint; db.x = x; db.y = y;
	if K.UpdateAuraAnchorEvents then K.UpdateAuraAnchorEvents(); end
end

-- Compatibilidad: la escala vive en ScaleAPI (ver BuffScale).
function K.SaveAuraAnchorScale(scale)
	if K.SetModuleScale then K.SetModuleScale("PlayerBuffs", scale); end
end

function K.GetAuraAnchor()
	return anchor;
end

function K.SaveDebuffAnchorPosition()
	local db = DebuffDB();
	local point, _, relativePoint, x, y = debuffAnchor:GetPoint();
	if not point then return; end
	db.point = point; db.relativePoint = relativePoint; db.x = x; db.y = y;
	if K.UpdateAuraAnchorEvents then K.UpdateAuraAnchorEvents(); end
end

function K.SaveDebuffAnchorScale(scale)
	if K.SetModuleScale then K.SetModuleScale("PlayerDebuffs", scale); end
end

function K.ResetAuraAnchor()
	-- FIX: antes el recuadro terminaba corrido hacia abajo porque el default
	-- se anclaba al minimapa. Ahora usa la posicion de fabrica real de los buffs.
	-- Los TRES modos, no solo el que este puesto.
	WipeAllModes(BuffRoot());
	WipeAllModes(DebuffRoot());
	-- Y la escala, que es la del slider.
	if K.ResetModuleScale then
		K.ResetModuleScale("PlayerBuffs");
		K.ResetModuleScale("PlayerDebuffs");
	end

	ApplyDefaultAnchorPos();
	ApplyDefaultDebuffPos();
	-- Sin BuffFrame_UpdateAllBuffAnchors (ver RefreshAuraAnchorDefault):
	-- Blizzard vuelve a anclar los iconos solo en el proximo cambio de auras.
	if not InCombatLockdown() and UIParent_ManageFramePositions then
		pcall(UIParent_ManageFramePositions);
	end
	if K.UpdateAuraAnchorEvents then K.UpdateAuraAnchorEvents(); end
end

-- ---------------------------------------------------------
-- Re-anclar las auras al ancla propia
-- ---------------------------------------------------------
local function ReanchorAuras()
	if not HasCustomPosition() then return; end

	-- Buffs: solo hay que mover el PRIMERO, el resto se encadena a el
	local first = _G["BuffButton1"];
	if first then
		first:ClearAllPoints();
		first:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0);
	end

	-- Encantamientos temporales (arma envenenada, piedra de aceite, etc.)
	local temp = _G["TempEnchant1"];
	if temp then
		temp:ClearAllPoints();
		temp:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0);
		-- Si hay encantamiento temporal, los buffs arrancan a su izquierda
		if first and temp:IsShown() then
			first:ClearAllPoints();
			first:SetPoint("TOPRIGHT", temp, "TOPLEFT", -5, 0);
		end
	end
end

-- Debuffs: mismo truco, con su propia ancla
local function ReanchorDebuffs()
	if not HasCustomDebuffPosition() then return; end
	local first = _G["DebuffButton1"];
	if first then
		first:ClearAllPoints();
		first:SetPoint("TOPRIGHT", debuffAnchor, "TOPRIGHT", 0, 0);
	end
end
K.ReanchorDebuffs = ReanchorDebuffs;
K.ReanchorAuras = ReanchorAuras;

-- ---------------------------------------------------------
-- LA ESCALA VA EN LOS ICONOS, NO EN EL ANCLA
--
-- Los sliders de "Buff scale" y "Debuff scale" no hacian absolutamente
-- nada, ni al moverlos ni despues de un /reload, y el motivo es que el
-- ancla no es el PADRE de los iconos.
--
-- Este modulo no reparenta nada a proposito (ver la cabecera del
-- archivo): solo re-ancla BuffButton1 al ancla dentro del hook de
-- Blizzard. Anclar no es colgar. Los iconos siguen siendo hijos de
-- BuffFrame, asi que la escala que ScaleAPI le ponia al ancla no los
-- alcanzaba: se estaba escalando un marco de 1x1 invisible.
--
-- La escala se le pone a cada icono. Como Blizzard los encadena uno al
-- siguiente, con la misma escala en todos el bloque entero crece parejo
-- y los huecos acompañan.
--
-- Se aplica en dos momentos: cuando el slider cambia el valor (el hook de
-- abajo) y cada vez que se re-anclan las auras, que es cuando pueden
-- haber aparecido iconos nuevos sin escalar.
-- ---------------------------------------------------------
local BUFF_ICONS   = BUFF_MAX_DISPLAY   or 32;
local DEBUFF_ICONS = DEBUFF_MAX_DISPLAY or 16;

local function ScaleIcons(prefix, count, scale)
	for i = 1, count do
		local b = _G[prefix .. i];
		if b and b.SetScale then pcall(b.SetScale, b, scale); end
	end
end

local function ApplyBuffIconScale()
	local s = BuffScale();
	ScaleIcons("BuffButton", BUFF_ICONS, s);
	-- Los encantamientos temporales viven en la misma fila.
	ScaleIcons("TempEnchant", 3, s);
end

local function ApplyDebuffIconScale()
	ScaleIcons("DebuffButton", DEBUFF_ICONS, DebuffScale());
end

K.ApplyAuraIconScales = function()
	ApplyBuffIconScale();
	ApplyDebuffIconScale();
end

-- El slider escribe con K.SetModuleScale; de ahi se engancha para que el
-- cambio se vea en el acto y no en la proxima actualizacion de auras.
if type(K.SetModuleScale) == "function" then
	hooksecurefunc(K, "SetModuleScale", function(id)
		if id == "PlayerBuffs" then
			ApplyBuffIconScale();
		elseif id == "PlayerDebuffs" then
			ApplyDebuffIconScale();
		end
	end);
end

-- ---------------------------------------------------------
-- Iconos por fila (tecnica tomada de KPack/BuffFrame)
--
-- Blizzard arma las filas de buffs leyendo la global BUFFS_PER_ROW justo
-- cuando reordena las auras. Basta con escribirla ANTES de que corra esa
-- funcion: por eso se envuelve la original en vez de usar hooksecurefunc
-- (el hook corre despues, y para entonces las filas ya estan armadas).
-- ---------------------------------------------------------
local function GetIconsPerRow()
	local v = C.AuraIconsPerRow;
	if type(v) ~= "number" or v < 1 then return 8; end
	return math.floor(v);
end
K.GetAuraIconsPerRow = GetIconsPerRow;

-- BUFFS_PER_ROW se fija UNA vez, no en cada actualizacion.
--
-- Antes esto envolvia BuffFrame_UpdateAllBuffAnchors: se guardaba la
-- original en Old_... y se la llamaba desde una funcion nuestra. El taint.log
-- se llenaba de
--
--   Execution tainted by Nidhaus_UnitFrames ... Old_BuffFrame_UpdateAllBuffAnchors()
--
-- una linea por cada icono, en cada refresco de auras.
--
-- Y era al pedo: BUFFS_PER_ROW es una global comun que Blizzard solo LEE;
-- nunca la reescribe. Alcanza con ponerle el valor al cargar y cuando el
-- usuario mueve el slider (ApplyAuraIconsPerRow, aca abajo). El reordenado
-- de iconos ya lo hace el hooksecurefunc que viene despues, que no ensucia.
--
-- Y SOLO SI CAMBIA. BUFFS_PER_ROW es una variable de Blizzard: escrita
-- desde el addon queda manchada (taint), y Blizzard la lee al acomodar
-- los iconos de buffs y debuffs. Con eso los iconos nuevos (DebuffButton15
-- en el taint.log) nacian manchados. Con el valor de fabrica (8) no hay
-- nada que escribir, y no se escribe.
--
-- Tampoco se escribe al cargar el archivo: ahi la configuracion guardada
-- todavia no llego (C tiene los valores por defecto). Se aplica cuando
-- carga la config.
local function ApplyBuffsPerRow()
	local n = GetIconsPerRow();
	if _G.BUFFS_PER_ROW ~= n then
		_G.BUFFS_PER_ROW = n;
	end
end

if K.RegisterConfigEvent then
	K.RegisterConfigEvent("CONFIG_LOADED", ApplyBuffsPerRow);
end

-- Al mover el slider. Sin BuffFrame_UpdateAllBuffAnchors (correria
-- manchada): Blizzard rearma las filas en el proximo cambio de auras, que
-- en la practica es enseguida.
function K.ApplyAuraIconsPerRow()
	ApplyBuffsPerRow();
	if K.ReanchorAuras then K.ReanchorAuras(); end
	if K.ReanchorDebuffs then K.ReanchorDebuffs(); end
end

-- En los dos hooks se re-aplica tambien la escala: Blizzard crea los
-- iconos a medida que hacen falta, y uno recien creado nace en 1. Sin
-- esto, con la escala subida los buffs nuevos aparecian mas chicos que
-- los que ya estaban.
if type(BuffFrame_UpdateAllBuffAnchors) == "function" then
	hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
		if K.ApplyAuraIconScales then K.ApplyAuraIconScales(); end
		ReanchorAuras();
		ReanchorDebuffs();
	end);
end

if type(BuffFrame_Update) == "function" then
	hooksecurefunc("BuffFrame_Update", function()
		if K.ApplyAuraIconScales then K.ApplyAuraIconScales(); end
		ReanchorAuras();
		ReanchorDebuffs();
	end);
end

-- Blizzard tambien reordena en este evento
-- UNIT_AURA solo se registra si hay una posicion custom guardada.
-- Es un evento muy ruidoso (dispara por CADA unidad cuyas auras
-- cambian; en un BG son cientos por segundo) y sin posicion custom
-- ReanchorAuras devuelve enseguida: no hay nada que reanclar.
local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");

function K.UpdateAuraAnchorEvents()
	if HasCustomPosition() or HasCustomDebuffPosition() then
		events:RegisterEvent("UNIT_AURA");
	else
		events:UnregisterEvent("UNIT_AURA");
	end
end

events:SetScript("OnEvent", function(self, event, unit)
	if event == "UNIT_AURA" and unit ~= "player" then return; end
	if event == "PLAYER_ENTERING_WORLD" then
		RestoreAnchorPosition();
		K.UpdateAuraAnchorEvents();
	end
	ReanchorAuras();
	ReanchorDebuffs();
end);

RestoreAnchorPosition();
K.UpdateAuraAnchorEvents();

-- ---------------------------------------------------------
-- ANOTARSE EN EL CORE
--
-- Las posiciones de las auras viven en un store PROPIO, no en globalPos.
-- Por eso al alternar entre MiniBar y el modo normal la barra de auras se
-- quedaba donde la habia dejado el modo anterior: el rearmado reponia
-- globalPos y de esto no se enteraba nadie.
--
-- Anotandose aca, el paso 3 del rearmado la llama siempre, sin que nadie
-- tenga que acordarse.
-- ---------------------------------------------------------
if K.LayoutRegisterStore then
	K.LayoutRegisterStore("AuraAnchor", RestoreAnchorPosition);
end
