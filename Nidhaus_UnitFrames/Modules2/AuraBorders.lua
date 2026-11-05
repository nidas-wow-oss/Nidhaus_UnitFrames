local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- AuraBorders.lua  -  bordes de auras estilo pw_unitframes
--
-- Port de pw_unitframes/modules/elements/auras.lua, quedandose
-- solo con la parte del ASPECTO de los iconos de buffs y debuffs
-- del OBJETIVO y del FOCO.
--
-- Que hace, y por que se nota:
--
--   1. Recorta el icono al 8-92%. Los iconos de hechizo traen un
--      marco gris dibujado en el borde de la imagen; recortandolo
--      queda solo el dibujo.
--   2. Le mete un borde fino propio a CADA icono. Los buffs de
--      Blizzard no tienen ninguno y se ven como estampas pegadas.
--   3. EL BORDE DEL DEBUFF SE PINTA SEGUN LA ESCUELA: Magia azul,
--      Maldicion violeta, Veneno verde, Enfermedad marron. Blizzard
--      ya trae ese color, pero en un aro gordo que tapa medio icono;
--      aca se esconde ese aro y el color va en el borde fino.
--   4. Resplandor en los buffs MAGICOS del enemigo, que son los que
--      se pueden purgar o disipar.
--
-- Lo que NO se porta de pw: posiciones, tamaños y cantidad de auras
-- por fila. De eso ya se ocupan AuraAnchor (las tuyas) y PartyBuffs
-- (las del grupo), y meter un tercer sistema seria pelearse solo.
--
-- =========================================================
-- DOS BUGS DE pw QUE ACA NO ESTAN
--
--   * pw pinta el borde del debuff UNA SOLA VEZ, adentro del
--     "if not frame.styled". El color queda congelado: si el veneno
--     de la ranura 2 se cae y entra una maldicion, el borde sigue
--     verde. Aca el color se recalcula en CADA actualizacion; lo
--     unico que se hace una sola vez es crear la textura.
--
--   * pw levanta una bandera (maxshows) cuando estiliza el ultimo
--     icono y despues no estiliza mas nunca. Los iconos que Blizzard
--     crea despues quedan sin borde.
-- =========================================================
-- LA FOTO ORIGINAL SE SACA UNA SOLA VEZ
--
-- Igual que en CastBarPW, PartyFramePW y BarBaseline: si se
-- recapturara al re-aplicar, la segunda vez guardariamos como
-- "original" lo que pusimos nosotros.
-- =========================================================

local MEDIA = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\pw\\";
local TEX_BORDER = MEDIA .. "Border.tga";   -- .tga: va CON extension

-- pw: config.auras.border_color
local NEUTRAL = { 0.30, 0.30, 0.30, 1 };
local TEXCOORD = { 0.08, 0.92, 0.08, 0.92 };
local INSET = 2;   -- cuanto se mete el icono para que se vea el borde

local UNITS = { "TargetFrame", "FocusFrame" };

local MAX_BUFFS   = MAX_TARGET_BUFFS or 32;
local MAX_DEBUFFS = MAX_TARGET_DEBUFFS or 16;

local orig    = {};    -- [nombre del icono] = foto de fabrica
local applied = false;

-- ---------------------------------------------------------
-- Foto / restauracion
-- ---------------------------------------------------------
local function SnapPoints(region)
	if not region then return nil; end
	local n = region:GetNumPoints() or 0;
	if n == 0 then return nil; end
	local pts = {};
	for i = 1, n do pts[i] = { region:GetPoint(i) }; end
	return pts;
end

local function RestorePoints(region, pts)
	if not region or not pts or #pts == 0 then return; end
	region:ClearAllPoints();
	for _, pt in ipairs(pts) do pcall(region.SetPoint, region, unpack(pt)); end
end

-- ---------------------------------------------------------
-- Preparar un icono (una sola vez por icono)
--
-- Devuelve nuestra textura de borde, o nil si el marco no existe
-- todavia. Blizzard crea los marcos de aura a medida que los
-- necesita, asi que esto se llama siempre, no en un init.
-- ---------------------------------------------------------
local function Prepare(frameName)
	local frame = _G[frameName];
	if not frame then return nil; end

	if frame.nufAuraBorder then return frame.nufAuraBorder; end

	local icon = _G[frameName .. "Icon"];
	orig[frameName] = {
		iconPoints = SnapPoints(icon),
		iconCoord  = icon and { icon:GetTexCoord() } or nil,
	};

	-- Sublevel -1: por ENCIMA del icono (que va en ARTWORK o mas
	-- abajo) y por DEBAJO del numero de acumulaciones, que Blizzard
	-- deja en OVERLAY sublevel 0. Asi no hay que tocar el numero ni
	-- acordarse de devolverlo despues.
	local bo = frame:CreateTexture(nil, "OVERLAY");
	if bo.SetDrawLayer then pcall(bo.SetDrawLayer, bo, "OVERLAY", -1); end
	bo:SetTexture(TEX_BORDER);
	bo:SetAllPoints(frame);
	bo:Hide();
	frame.nufAuraBorder = bo;
	return bo;
end

-- ---------------------------------------------------------
-- Estilar un icono
-- ---------------------------------------------------------
local function StyleIcon(frameName, r, g, b)
	local bo = Prepare(frameName);
	if not bo then return; end

	local frame = _G[frameName];
	local icon  = _G[frameName .. "Icon"];
	if icon then
		icon:ClearAllPoints();
		icon:SetPoint("TOPLEFT", frame, "TOPLEFT", INSET, -INSET);
		icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -INSET, INSET);
		icon:SetTexCoord(unpack(TEXCOORD));
	end

	bo:SetVertexColor(r, g, b, 1);
	bo:Show();
end

local function RestoreIcon(frameName)
	local frame = _G[frameName];
	if not frame then return; end

	if frame.nufAuraBorder then frame.nufAuraBorder:Hide(); end

	local snap = orig[frameName];
	local icon = _G[frameName .. "Icon"];
	if icon and snap then
		RestorePoints(icon, snap.iconPoints);
		if snap.iconCoord and #snap.iconCoord >= 4 then
			pcall(icon.SetTexCoord, icon, unpack(snap.iconCoord));
		end
	end

	-- El aro gordo de Blizzard vuelve a aparecer. Solo los debuffs
	-- tienen uno; en los buffs esto es nil y no pasa nada.
	local blizz = _G[frameName .. "Border"];
	if blizz then blizz:Show(); end

	local steal = _G[frameName .. "Stealable"];
	if steal and snap and snap.stealPoints then
		RestorePoints(steal, snap.stealPoints);
		steal:Hide();
	end
end

-- ---------------------------------------------------------
-- Resplandor de purgable
--
-- Blizzard ya dibuja esta textura, pero solo para el robo de
-- hechizos del mago. pw la reusa con otra regla: cualquier buff
-- MAGICO sobre un enemigo, que es lo que puede sacar una purga o
-- una disipacion. Sirve para chaman, sacerdote, druida y mago.
-- ---------------------------------------------------------
local function UpdateSteal(frameName, show)
	local steal = _G[frameName .. "Stealable"];
	if not steal then return; end
	local icon = _G[frameName .. "Icon"];
	if not icon then return; end

	local snap = orig[frameName];
	if snap and not snap.stealPoints then
		snap.stealPoints = SnapPoints(steal);
	end

	if not show then steal:Hide(); return; end

	steal:ClearAllPoints();
	steal:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 3, 3);
	steal:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", -3, -3);
	if steal.SetBlendMode then steal:SetBlendMode("ADD"); end
	if steal.SetDrawLayer then pcall(steal.SetDrawLayer, steal, "OVERLAY", 7); end
	steal:Show();
end

-- ---------------------------------------------------------
-- Repasar un marco entero (objetivo o foco)
--
-- Se corta en el primer icono que no esta visible: Blizzard los
-- llena en orden, asi que del primer hueco en adelante estan todos
-- vacios. Sin ese corte serian 48 vueltas en cada UNIT_AURA.
-- ---------------------------------------------------------
local function Restyle(self)
	if not applied then return; end
	if not self or not self.GetName then return; end

	local base = self:GetName();
	if base ~= "TargetFrame" and base ~= "FocusFrame" then return; end

	local unit = self.unit;
	local glow = C.AuraBordersPurge ~= false
		and unit and UnitExists(unit) and UnitIsEnemy("player", unit);

	-- NO SE CORTA EN EL PRIMER HUECO. Con "solo mis debuffs" (o en un
	-- enemigo con debuffs ajenos) Blizzard esconde ranuras del medio y
	-- deja visibles las de despues: cortando ahi, esas quedaban sin
	-- borde. Se corta recien donde el marco no existe.

	-- ── Buffs ──
	for i = 1, MAX_BUFFS do
		local name = base .. "Buff" .. i;
		local frame = _G[name];
		if not frame then break; end
		if frame:IsShown() then
			StyleIcon(name, NEUTRAL[1], NEUTRAL[2], NEUTRAL[3]);
			-- isStealable: el robo de hechizos del mago se respeta
			-- aunque el resplandor de purga este apagado.
			local _, _, _, _, debuffType, _, _, _, isStealable = UnitBuff(unit, i);
			UpdateSteal(name, (glow and debuffType == "Magic") or (isStealable and true or false));
		end
	end

	-- ── Debuffs ──
	for i = 1, MAX_DEBUFFS do
		local name = base .. "Debuff" .. i;
		local frame = _G[name];
		if not frame then break; end
		if frame:IsShown() then
			-- El color se lee del aro de Blizzard, que lo acaba de pintar
			-- para ESTE icono. Antes se pedia UnitDebuff(unit, i), y cuando
			-- Blizzard filtra ranuras el numero no coincide: el borde salia
			-- con la escuela de otro debuff. Se recalcula en cada pasada
			-- (el bug de pw era pintarlo una sola vez).
			local blizz = _G[name .. "Border"];
			local r, g, b;
			if blizz and blizz.GetVertexColor then r, g, b = blizz:GetVertexColor(); end
			if not r then r, g, b = NEUTRAL[1], NEUTRAL[2], NEUTRAL[3]; end
			StyleIcon(name, r, g, b);

			-- Esconder el aro gordo de Blizzard: con los dos puestos el
			-- icono queda con doble marco y no se ve nada.
			if blizz then blizz:Hide(); end
		end
	end
end

-- Pedirle a Blizzard que vuelva a dibujar las auras (con lo nuestro o sin).
local function RedrawBlizzard()
	for _, base in ipairs(UNITS) do
		local f = _G[base];
		if f and f.unit and UnitExists(f.unit) and type(TargetFrame_UpdateAuras) == "function" then
			pcall(TargetFrame_UpdateAuras, f);
		end
	end
end

-- ---------------------------------------------------------
-- API publica
-- ---------------------------------------------------------
function K.EnableAuraBorders()
	applied = true;
	for _, base in ipairs(UNITS) do
		local f = _G[base];
		if f then pcall(Restyle, f); end
	end
end

function K.DisableAuraBorders()
	if not applied then return; end
	applied = false;
	for _, base in ipairs(UNITS) do
		for i = 1, MAX_BUFFS   do RestoreIcon(base .. "Buff" .. i);   end
		for i = 1, MAX_DEBUFFS do RestoreIcon(base .. "Debuff" .. i); end
	end
	-- RestoreIcon esconde el resplandor; Blizzard lo vuelve a poner donde
	-- corresponde (robo de hechizos del mago).
	RedrawBlizzard();
end

function K.IsAuraBordersActive()
	return applied;
end

function K.ApplyAuraBorders()
	if C.AuraBordersEnabled then
		K.EnableAuraBorders();
	else
		K.DisableAuraBorders();
	end
end

-- ---------------------------------------------------------
-- Enganche
--
-- TargetFrame_UpdateAuras es la MISMA funcion para el objetivo y
-- para el foco: Blizzard la llama con self = TargetFrame o
-- self = FocusFrame. Un solo hook cubre los dos.
--
-- Va con hooksecurefunc, o sea que corre DESPUES de la de Blizzard
-- sin reemplazarla: asi no se contamina nada y los colores que
-- ponemos son los ultimos que quedan.
-- ---------------------------------------------------------
if type(TargetFrame_UpdateAuras) == "function" then
	hooksecurefunc("TargetFrame_UpdateAuras", Restyle);
end

-- =========================================================
-- AURAS MAS GRANDES EN OBJETIVO Y FOCO (idea de FriskesUI)
--
-- Blizzard las dibuja a 17 (buffs) y 21 (debuffs propios). Con la opcion
-- se re-ubican a 22 y 26. Va en un hook DESPUES del de Blizzard: se
-- vuelve a llamar a su propia funcion de anclaje (updateFunc) con otros
-- tamaños, asi el ancla de la barra de casteo y las filas quedan bien.
--
-- Diferencia con FriskesUI: ahi el ancho de fila se fuerza a 126 siempre
-- y, con el objetivo del objetivo visible, los iconos se meten debajo de
-- el. Aca se respeta el ancho angosto que Blizzard usa en ese caso.
-- =========================================================
local BIG_SMALL, BIG_LARGE, BIG_GAP = 22, 26, 2.5;

local function BigAuraPositions(self, auraName, numAuras, numOppositeAuras,
		largeAuraList, updateFunc, maxRowWidth, offsetX)
	if not C.BigTargetAuras then return; end
	if type(updateFunc) ~= "function" or type(largeAuraList) ~= "table" then return; end
	offsetX = offsetX or 3;
	maxRowWidth = maxRowWidth or 122;
	if maxRowWidth >= 122 then maxRowWidth = 126; end

	local rowWidth, firstOnRow, offsetY = 0, 1, BIG_GAP;
	for i = 1, (numAuras or 0) do
		local size;
		if largeAuraList[i] then
			size = BIG_LARGE;
			offsetY = BIG_GAP + BIG_GAP;
		else
			size = BIG_SMALL;
		end
		if i == 1 then rowWidth = size; else rowWidth = rowWidth + size + offsetX; end

		if rowWidth > maxRowWidth then
			updateFunc(self, auraName, i, numOppositeAuras, firstOnRow, size, offsetX, offsetY);
			rowWidth = size;
			firstOnRow = i;
			offsetY = BIG_GAP;
		else
			updateFunc(self, auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY);
		end
	end
end

if type(TargetFrame_UpdateAuraPositions) == "function" then
	hooksecurefunc("TargetFrame_UpdateAuraPositions", function(...)
		pcall(BigAuraPositions, ...);
	end);
end

local lastBig;
function K.ApplyBigTargetAuras()
	local want = C.BigTargetAuras and true or false;
	if want == lastBig then return; end
	lastBig = want;
	RedrawBlizzard();
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	K.ApplyAuraBorders();
	K.ApplyBigTargetAuras();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	K.ApplyAuraBorders();
	K.ApplyBigTargetAuras();
end);
