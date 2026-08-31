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
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.AuraAnchor then NidhausUnitFramesDB.AuraAnchor = {}; end
	return NidhausUnitFramesDB.AuraAnchor;
end

local function DebuffDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.DebuffAnchor then NidhausUnitFramesDB.DebuffAnchor = {}; end
	return NidhausUnitFramesDB.DebuffAnchor;
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

-- Posicion de fabrica de los buffs en 3.3.5a
local function ApplyDefaultAnchorPos()
	anchor:ClearAllPoints();
	anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -MinimapInset(), -13);
	anchor:SetScale(1);
end

-- Se llama al mover el slider de tamaño del minimapa.
--
-- Solo toca la posicion AUTOMATICA: si vos moviste los buffs a mano, esa
-- posicion es tuya y no se pisa.
function K.RefreshAuraAnchorDefault()
	if HasCustomPosition() then return; end
	ApplyDefaultAnchorPos();
	if BuffFrame_UpdateAllBuffAnchors then pcall(BuffFrame_UpdateAllBuffAnchors); end
end

local function ApplyDefaultDebuffPos()
	debuffAnchor:ClearAllPoints();
	debuffAnchor:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -20);
	debuffAnchor:SetScale(1);
end

local function RestoreAnchorPosition()
	local db = DB();
	if db.point then
		anchor:ClearAllPoints();
		anchor:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
		if db.scale then anchor:SetScale(db.scale); end
	else
		ApplyDefaultAnchorPos();
	end

	local ddb = DebuffDB();
	if ddb.point then
		debuffAnchor:ClearAllPoints();
		debuffAnchor:SetPoint(ddb.point, UIParent, ddb.relativePoint, ddb.x, ddb.y);
		if ddb.scale then debuffAnchor:SetScale(ddb.scale); end
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

function K.SaveAuraAnchorScale(scale)
	DB().scale = scale;
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
	DebuffDB().scale = scale;
end

function K.ResetAuraAnchor()
	-- FIX: antes el recuadro terminaba corrido hacia abajo porque el default
	-- se anclaba al minimapa. Ahora usa la posicion de fabrica real de los buffs.
	local db = DB();
	db.point, db.relativePoint, db.x, db.y, db.scale = nil, nil, nil, nil, nil;
	local ddb = DebuffDB();
	ddb.point, ddb.relativePoint, ddb.x, ddb.y, ddb.scale = nil, nil, nil, nil, nil;

	ApplyDefaultAnchorPos();
	ApplyDefaultDebuffPos();
	if BuffFrame_UpdateAllBuffAnchors then pcall(BuffFrame_UpdateAllBuffAnchors); end
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
_G.BUFFS_PER_ROW = GetIconsPerRow();

-- Re-arma las filas al mover el slider
function K.ApplyAuraIconsPerRow()
	_G.BUFFS_PER_ROW = GetIconsPerRow();
	if BuffFrame_UpdateAllBuffAnchors then pcall(BuffFrame_UpdateAllBuffAnchors); end
end

if type(BuffFrame_UpdateAllBuffAnchors) == "function" then
	hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
		ReanchorAuras();
		ReanchorDebuffs();
	end);
end

if type(BuffFrame_Update) == "function" then
	hooksecurefunc("BuffFrame_Update", function() ReanchorAuras(); ReanchorDebuffs(); end);
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
		K.UpdateAuraAnchorEvents();
	end
	ReanchorAuras();
	ReanchorDebuffs();
end);

RestoreAnchorPosition();
K.UpdateAuraAnchorEvents();
