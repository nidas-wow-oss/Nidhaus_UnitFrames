-- PartyBuffs
-- Muestra buffs/debuffs extendidos del grupo (slots 1-20)
-- Posiciones independientes por modo: Blizzard / NewPartyFrame
-- Offsets guardados en espacio LOCAL del party frame (compatibles con 3v3)
--
-- Commands: /pbuffs (abre y cierra el menu) | /pbuffs reset

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

PartyBuffsDB = PartyBuffsDB or {}

-- Migrar datos de GroupBuffsDB si existen
if GroupBuffsDB and not PartyBuffsDB._migrated then
	for k, v in pairs(GroupBuffsDB) do
		if PartyBuffsDB[k] == nil then PartyBuffsDB[k] = v; end
	end
	PartyBuffsDB._migrated = true;
end

------------------------------------------------------------------------
-- Defaults por modo (espacio LOCAL del frame — probados con Blizzard y NPF)
------------------------------------------------------------------------
local DEFAULTS_BLIZ = {
	buffs   = { x = 48,  y = -32 },
	debuffs = { x = -7,  y = 5   },
}
local DEFAULTS_NPF = {
	buffs   = { x = 44,  y = -37 },
	debuffs = { x = -7,  y = 5   },
}
-- Improved tiene su propio juego. Arranca en el de Blizzard pero 2px mas
-- arriba: con esa textura los buffs quedaban pisando el borde del marco.
--
-- Antes ese ajuste era un "+2" que se sumaba al vuelo sobre la posicion de
-- Blizzard, y traia dos problemas: los dos estilos compartian el mismo
-- valor guardado (mover uno pisaba el otro) y ese bonus habia que acordarse
-- de restarlo al leer la posicion del mover — un olvido que ya causo un bug.
-- Con un juego propio, el ajuste es simplemente el default y desaparece la
-- asimetria.
local DEFAULTS_IMP = {
	buffs   = { x = 48,  y = -30 },
	debuffs = { x = -7,  y = 5   },
}
-- Compact (Big Blizzard) y Compact 2 tienen cada uno su juego propio.
--
-- Antes ninguno de los dos figuraba en StyleKey, asi que caian en la
-- ranura de Blizzard y compartian sus valores: acomodabas los buffs en
-- Compact 2 y le pisabas la posicion al estilo de Blizzard, y viceversa.
--
-- Los numeros de Compact 2 salen de dejarlos acomodados en el juego.
local DEFAULTS_PW = {
	buffs   = { x = 48,  y = -32 },
	debuffs = { x = -7,  y = 5   },
}
local DEFAULTS_PW2 = {
	buffs   = { x = 33,  y = -37 },
	debuffs = { x = -28, y = 10  },
}
local DEFAULTS_SHARED = {
	scale      = { buffs = 1.00, debuffs = 1.00 },
	panel      = { x = 220, y = 0 },
	maxBuffs   = 8,
	maxDebuffs = 10,
}

------------------------------------------------------------------------
-- Estado en runtime
------------------------------------------------------------------------
local pbEnabled   = false
local initialized = false
local boot
local auraEvts  = {}
local movers    = {}

-- Anclajes ORIGINALES de Buff1/Debuff1, tal como los deja Blizzard, guardados
-- antes de tocarlos. Al apagar el modulo se vuelve a ESTOS.
--
-- Antes el apagado reponia unos valores escritos a mano como si fueran los de
-- Blizzard. Si no coincidian —y no coincidian— los iconos quedaban donde los
-- habia puesto PartyBuffs, y parecia que el modulo seguia activo hasta que
-- hacias /reload.
local origAnchors = {}

-- Declarada adelantada: K.PartyBuffs_OnFramesMoved la usa mucho antes de
-- donde esta definida, y sin esto la referencia caeria en una global
-- inexistente en vez de en esta local.
local UpdateMoverPositions
local dragState = { debuffs = false, buffs = false }

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
local function CopyScale(src)
	return { buffs = tonumber(src.buffs) or 1, debuffs = tonumber(src.debuffs) or 1 }
end
local function CopyPanel(src)
	-- Copia tambien el tipo de punto, no solo x/y: desde que la ventana se
	-- guarda relativa a UIParent, el punto es parte de la posicion.
	src = src or {}
	return {
		point         = src.point,
		relativePoint = src.relativePoint,
		x             = tonumber(src.x) or 0,
		y             = tonumber(src.y) or 0,
	}
end
local function IsNPFActive()
	return K.IsNewPartyFrameActive and K.IsNewPartyFrameActive();
end

-- Que juego de posiciones corresponde al estilo activo.
-- Son TRES, uno por estilo, para que mover los buffs en uno no pise a los
-- otros y puedas ir y venir sin perder nada.
local function StyleKey()
	local style = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or nil;
	if style == "Improved" then return "imp"; end
	if style == "New" then return "npf"; end
	if style == "PW" then return "pw"; end
	if style == "PW2" then return "pw2"; end
	if style == "Default" then return "bliz"; end
	-- Sin el coordinador de estilos, caer en la deteccion vieja.
	return IsNPFActive() and "npf" or "bliz";
end
local function GetPartyAnchor()
	return _G["PartyMemberFrame1"]
end
-- NOTA: aca vivia la funcion que devolvia la escala del marco de party. Se
-- usaba para convertir los offsets de los movers entre el espacio del marco
-- y el de la pantalla, y esa conversion era el origen del problema: los
-- movers eran hijos de UIParent, asi que el codigo restaba coordenadas de
-- dos espacios distintos y despues lo "corregia" con la escala PROPIA del
-- marco (que ademas ignora la escala global de la UI).
--
-- Ahora los movers son hijos del marco, igual que en Party Trinkets, y no
-- queda ninguna conversion que hacer.

------------------------------------------------------------------------
-- ApplyDefaults — garantiza que todos los campos existen en la DB
------------------------------------------------------------------------
local function ApplyDefaults()
	if not PartyBuffsDB.blizBuffs   then PartyBuffsDB.blizBuffs   = { x=DEFAULTS_BLIZ.buffs.x,   y=DEFAULTS_BLIZ.buffs.y   } end
	if not PartyBuffsDB.blizDebuffs then PartyBuffsDB.blizDebuffs = { x=DEFAULTS_BLIZ.debuffs.x, y=DEFAULTS_BLIZ.debuffs.y } end
	if not PartyBuffsDB.npfBuffs    then PartyBuffsDB.npfBuffs    = { x=DEFAULTS_NPF.buffs.x,    y=DEFAULTS_NPF.buffs.y    } end
	if not PartyBuffsDB.npfDebuffs  then PartyBuffsDB.npfDebuffs  = { x=DEFAULTS_NPF.debuffs.x,  y=DEFAULTS_NPF.debuffs.y  } end
	if not PartyBuffsDB.impBuffs    then PartyBuffsDB.impBuffs    = { x=DEFAULTS_IMP.buffs.x,    y=DEFAULTS_IMP.buffs.y    } end
	if not PartyBuffsDB.impDebuffs  then PartyBuffsDB.impDebuffs  = { x=DEFAULTS_IMP.debuffs.x,  y=DEFAULTS_IMP.debuffs.y  } end
	if not PartyBuffsDB.pwBuffs     then PartyBuffsDB.pwBuffs     = { x=DEFAULTS_PW.buffs.x,     y=DEFAULTS_PW.buffs.y     } end
	if not PartyBuffsDB.pwDebuffs   then PartyBuffsDB.pwDebuffs   = { x=DEFAULTS_PW.debuffs.x,   y=DEFAULTS_PW.debuffs.y   } end
	if not PartyBuffsDB.pw2Buffs    then PartyBuffsDB.pw2Buffs    = { x=DEFAULTS_PW2.buffs.x,    y=DEFAULTS_PW2.buffs.y    } end
	if not PartyBuffsDB.pw2Debuffs  then PartyBuffsDB.pw2Debuffs  = { x=DEFAULTS_PW2.debuffs.x,  y=DEFAULTS_PW2.debuffs.y  } end
	if not PartyBuffsDB.scale       then PartyBuffsDB.scale       = { buffs=DEFAULTS_SHARED.scale.buffs, debuffs=DEFAULTS_SHARED.scale.debuffs } end
	if not PartyBuffsDB.panel       then PartyBuffsDB.panel       = { x=DEFAULTS_SHARED.panel.x, y=DEFAULTS_SHARED.panel.y } end
	if not PartyBuffsDB.maxBuffs    then PartyBuffsDB.maxBuffs    = DEFAULTS_SHARED.maxBuffs   end
	if not PartyBuffsDB.maxDebuffs  then PartyBuffsDB.maxDebuffs  = DEFAULTS_SHARED.maxDebuffs end

	-- Migrar formato plano (legado) → formato separado por modo
	if PartyBuffsDB.buffs and not PartyBuffsDB._storageMigrated then
		PartyBuffsDB.blizBuffs.x  = PartyBuffsDB.buffs.x   or DEFAULTS_BLIZ.buffs.x;
		PartyBuffsDB.blizBuffs.y  = PartyBuffsDB.buffs.y   or DEFAULTS_BLIZ.buffs.y;
		PartyBuffsDB.blizDebuffs.x = (PartyBuffsDB.debuffs and PartyBuffsDB.debuffs.x) or DEFAULTS_BLIZ.debuffs.x;
		PartyBuffsDB.blizDebuffs.y = (PartyBuffsDB.debuffs and PartyBuffsDB.debuffs.y) or DEFAULTS_BLIZ.debuffs.y;
		PartyBuffsDB.buffs   = nil;
		PartyBuffsDB.debuffs = nil;
		PartyBuffsDB._storageMigrated = true;
	end
end

------------------------------------------------------------------------
-- Getters según modo activo
------------------------------------------------------------------------
local BUFFS_BY_STYLE   = { bliz = "blizBuffs",   npf = "npfBuffs",   imp = "impBuffs",   pw = "pwBuffs",   pw2 = "pw2Buffs"   };
local DEBUFFS_BY_STYLE = { bliz = "blizDebuffs", npf = "npfDebuffs", imp = "impDebuffs", pw = "pwDebuffs", pw2 = "pw2Debuffs" };
local DEFAULTS_BY_STYLE = { bliz = DEFAULTS_BLIZ, npf = DEFAULTS_NPF, imp = DEFAULTS_IMP, pw = DEFAULTS_PW, pw2 = DEFAULTS_PW2 };

local function GetCurrentBuffs()
	ApplyDefaults();
	return PartyBuffsDB[BUFFS_BY_STYLE[StyleKey()] or "blizBuffs"];
end
local function GetCurrentDebuffs()
	ApplyDefaults();
	return PartyBuffsDB[DEBUFFS_BY_STYLE[StyleKey()] or "blizDebuffs"];
end
local function GetCurrentDefaults()
	return DEFAULTS_BY_STYLE[StyleKey()] or DEFAULTS_BLIZ;
end

-- NOTA: aca vivia ImprovedBuffYBonus(), que sumaba 2px al vuelo con el
-- estilo Improved. Ya no hace falta: ese estilo tiene su propio juego de
-- posiciones y el ajuste esta en su default (DEFAULTS_IMP).
--
-- Sumar un bonus solo al COLOCAR obligaba a restarlo al LEER la posicion del
-- mover, y olvidarse de eso hacia que el mover saltara en cada arrastre.
-- Sin bonus, colocar y leer son operaciones inversas y no hay nada que
-- desincronizar.
local function GetMaxBuffs()
	ApplyDefaults();
	return tonumber(PartyBuffsDB.maxBuffs) or DEFAULTS_SHARED.maxBuffs;
end
local function GetMaxDebuffs()
	ApplyDefaults();
	return tonumber(PartyBuffsDB.maxDebuffs) or DEFAULTS_SHARED.maxDebuffs;
end

------------------------------------------------------------------------
-- ApplyScaleAll — aplica escala a todos los iconos visibles
------------------------------------------------------------------------
local function ApplyScaleAll(scaleTable)
	ApplyDefaults()
	local sb = tonumber(scaleTable and scaleTable.buffs)   or tonumber(PartyBuffsDB.scale.buffs)   or 1
	local sd = tonumber(scaleTable and scaleTable.debuffs) or tonumber(PartyBuffsDB.scale.debuffs) or 1
	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			for j = 1, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				local d = _G[f:GetName() .. "Debuff" .. j]
				if b and b.SetScale then b:SetScale(sb) end
				if d and d.SetScale then d:SetScale(sd) end
			end
		end
	end
end

------------------------------------------------------------------------
-- ReanchorAll — ancla Buff1/Debuff1 en espacio LOCAL del frame
-- WoW 3.3.5: SetPoint offsets son en el espacio de coordenadas del padre
-- del frame que se ancla. Buff1/Debuff1 son hijos de PartyMemberFrame,
-- por lo que los offsets van en el espacio local de ese frame.
-- Al guardar offsetX=48, un frame en escala 1.5 lo muestra como 72px.
-- Esto es el comportamiento correcto probado en la versión "copia".
------------------------------------------------------------------------
local function ReanchorAll()
	if not pbEnabled then return; end
	ApplyDefaults()

	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	local maxB    = GetMaxBuffs();
	local maxD    = GetMaxDebuffs();

	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			local d1 = _G[f:GetName() .. "Debuff1"]
			if d1 then
				d1:ClearAllPoints()
				d1:SetPoint("LEFT", f, "RIGHT", debuffs.x, debuffs.y)
			end
			local b1 = _G[f:GetName() .. "Buff1"]
			if b1 then
				b1:ClearAllPoints()
				b1:SetPoint("TOPLEFT", f, "TOPLEFT", buffs.x, buffs.y)
			end
			-- Ocultar iconos más allá del límite configurado
			for j = maxB + 1, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				if b then b:Hide() end
			end
			for j = maxD + 1, 20 do
				local d = _G[f:GetName() .. "Debuff" .. j]
				if d then d:Hide() end
			end
		end
	end
end

------------------------------------------------------------------------
-- Setup inicial de frames (ejecuta una sola vez)
------------------------------------------------------------------------
local function SetupFrames()
	if not pbEnabled then return end
	if initialized   then return end
	initialized = true

	ApplyDefaults()
	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	local maxB    = GetMaxBuffs();
	local maxD    = GetMaxDebuffs();

	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			-- Tomar control de UNIT_AURA para este frame
			f:UnregisterEvent("UNIT_AURA")

			local evt = CreateFrame("Frame")
			evt:RegisterEvent("UNIT_AURA")
			auraEvts[i] = evt
			evt:SetScript("OnEvent", function(self, event, unit)
				if not unit then return end
				if unit == f.unit then
					if RefreshDebuffs then
						RefreshDebuffs(f, unit, maxD, nil, 1)
					else
						PartyMemberFrame_RefreshDebuffs(f)
					end
					if RefreshBuffs then
						RefreshBuffs(f, unit, maxB, nil, 1)
					else
						PartyMemberFrame_RefreshBuffs(f)
					end
				elseif unit == f.unit .. "pet" then
					PartyMemberFrame_RefreshPetDebuffs(f)
				end
			end)

			-- Guardar los anclajes de fabrica ANTES de moverlos. Solo la
			-- primera vez: si se recapturara al re-activar, se guardarian
			-- las posiciones propias del modulo y no habria vuelta atras.
			if not origAnchors[i] then
				local o = {}
				local d0 = _G[f:GetName() .. "Debuff1"]
				local b0 = _G[f:GetName() .. "Buff1"]
				if d0 and d0:GetNumPoints() > 0 then
					o.debuff = { d0:GetPoint(1) }
				end
				if b0 and b0:GetNumPoints() > 0 then
					o.buff = { b0:GetPoint(1) }
				end
				origAnchors[i] = o
			end

			-- Debuff1 posición inicial
			local d1 = _G[f:GetName() .. "Debuff1"]
			if d1 then
				d1:ClearAllPoints()
				d1:SetPoint("LEFT", f, "RIGHT", debuffs.x, debuffs.y)
			end

			-- Crear/anclar Debuffs 5 a maxD (2-4 los crea Blizzard)
			for j = 5, maxD do
				local prefix = f:GetName() .. "Debuff"
				local frame  = _G[prefix .. j] or CreateFrame("Frame", prefix .. j, f, "PartyDebuffFrameTemplate")
				frame:ClearAllPoints()
				frame:SetPoint("LEFT", _G[prefix .. (j-1)], "RIGHT")
			end

			-- Ocultar debuffs más allá del límite
			for j = maxD + 1, 20 do
				local frame = _G[f:GetName() .. "Debuff" .. j]
				if frame then frame:Hide() end
			end

			-- Crear/anclar Buffs 1 a maxB
			for j = 1, maxB do
				local prefix = f:GetName() .. "Buff"
				local frame  = _G[prefix .. j] or CreateFrame("Frame", prefix .. j, f, "TargetBuffFrameTemplate")
				frame:EnableMouse(false)
				frame:ClearAllPoints()
				if j == 1 then
					frame:SetPoint("TOPLEFT", f, "TOPLEFT", buffs.x, buffs.y)
				else
					frame:SetPoint("LEFT", _G[prefix .. (j-1)], "RIGHT", 1, 0)
				end
			end

			-- Ocultar buffs más allá del límite
			for j = maxB + 1, 20 do
				local frame = _G[f:GetName() .. "Buff" .. j]
				if frame then frame:Hide() end
			end
		end
	end
end

------------------------------------------------------------------------
-- Exports públicos
------------------------------------------------------------------------
function K.IsPartyBuffsActive()
	return pbEnabled;
end

K.PartyBuffs_ReanchorAll = function()
	if pbEnabled then
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
	end
end

-- Llamado desde Partymode3v3 después de reposicionar frames con nueva escala.
-- Re-ancla iconos y actualiza los movers si están visibles.
K.PartyBuffs_OnFramesMoved = function()
	if not pbEnabled then return end
	ReanchorAll()
	ApplyScaleAll(PartyBuffsDB.scale)

	-- Antes esto repetia la cuenta de anclaje una TERCERA vez (y con el mismo
	-- error de escala). Tener la formula copiada en varios lados es
	-- justamente lo que hacia que se desincronizaran entre si.
	if (movers.debuffs and movers.debuffs:IsShown())
		or (movers.buffs and movers.buffs:IsShown()) then
		UpdateMoverPositions()
	end
end

------------------------------------------------------------------------
-- FullReset — resetea posiciones + escala + max. Sin abrir menús.
------------------------------------------------------------------------
local function FullReset()
	ApplyDefaults()

	-- Resetear TODOS los estilos siempre, no solo el activo: si no, el que
	-- esta apagado se queda con la posicion vieja y reaparece al cambiar.
	PartyBuffsDB.blizBuffs.x   = DEFAULTS_BLIZ.buffs.x;   PartyBuffsDB.blizBuffs.y   = DEFAULTS_BLIZ.buffs.y
	PartyBuffsDB.blizDebuffs.x = DEFAULTS_BLIZ.debuffs.x; PartyBuffsDB.blizDebuffs.y = DEFAULTS_BLIZ.debuffs.y
	PartyBuffsDB.npfBuffs.x    = DEFAULTS_NPF.buffs.x;    PartyBuffsDB.npfBuffs.y    = DEFAULTS_NPF.buffs.y
	PartyBuffsDB.npfDebuffs.x  = DEFAULTS_NPF.debuffs.x;  PartyBuffsDB.npfDebuffs.y  = DEFAULTS_NPF.debuffs.y
	PartyBuffsDB.impBuffs.x    = DEFAULTS_IMP.buffs.x;    PartyBuffsDB.impBuffs.y    = DEFAULTS_IMP.buffs.y
	PartyBuffsDB.impDebuffs.x  = DEFAULTS_IMP.debuffs.x;  PartyBuffsDB.impDebuffs.y  = DEFAULTS_IMP.debuffs.y
	PartyBuffsDB.pwBuffs.x     = DEFAULTS_PW.buffs.x;     PartyBuffsDB.pwBuffs.y     = DEFAULTS_PW.buffs.y
	PartyBuffsDB.pwDebuffs.x   = DEFAULTS_PW.debuffs.x;   PartyBuffsDB.pwDebuffs.y   = DEFAULTS_PW.debuffs.y
	PartyBuffsDB.pw2Buffs.x    = DEFAULTS_PW2.buffs.x;    PartyBuffsDB.pw2Buffs.y    = DEFAULTS_PW2.buffs.y
	PartyBuffsDB.pw2Debuffs.x  = DEFAULTS_PW2.debuffs.x;  PartyBuffsDB.pw2Debuffs.y  = DEFAULTS_PW2.debuffs.y

	PartyBuffsDB.scale      = { buffs=DEFAULTS_SHARED.scale.buffs, debuffs=DEFAULTS_SHARED.scale.debuffs }
	PartyBuffsDB.panel      = { x=DEFAULTS_SHARED.panel.x, y=DEFAULTS_SHARED.panel.y }
	PartyBuffsDB.maxBuffs   = DEFAULTS_SHARED.maxBuffs
	PartyBuffsDB.maxDebuffs = DEFAULTS_SHARED.maxDebuffs
end

------------------------------------------------------------------------
-- Movers
------------------------------------------------------------------------
local function CreateMoverFrame(name, label)
	local m = _G[name]
	if m then
		if m.text then m.text:SetText(label) end
		return m
	end
	-- HIJO DEL MARCO DE PARTY, no de UIParent.
	--
	-- Aca estaba el problema de raiz. Siendo hijo de UIParent, el mover vivia
	-- en un sistema de coordenadas y el marco en otro, y el codigo restaba
	-- mover:GetLeft() - f1:GetLeft() como si fueran comparables. Despues
	-- intentaba arreglarlo dividiendo por f1:GetScale() — que ademas es la
	-- escala PROPIA, no la efectiva, asi que ignoraba la escala de la UI.
	--
	-- Party Trinkets nunca tuvo este problema porque su icono es hijo del
	-- marco: comparte coordenadas con el padre y la resta da directo el
	-- offset, sin conversion ninguna. Los iconos de buff reales tambien se
	-- anclan asi (sin escala). Ahora el mover vive en el mismo espacio que
	-- las dos cosas que representa.
	local parentFrame = GetPartyAnchor() or UIParent
	m = CreateFrame("Frame", name, parentFrame)
	m:SetSize(140, 16)
	m:SetFrameStrata("DIALOG")
	m:EnableMouse(true)
	m:SetMovable(true)
	m:RegisterForDrag("LeftButton")
	m:SetClampedToScreen(true)
	m:Hide()
	if m.SetBackdrop then
		m:SetBackdrop({
			bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile=true, tileSize=16, edgeSize=12,
			insets = { left=2, right=2, top=2, bottom=2 },
		})
		m:SetBackdropColor(0, 0, 0, 0.6)
	end
	local fs = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	fs:SetPoint("CENTER")
	fs:SetText(label)
	m.text = fs
	return m
end

-- Los movers se anclan EXACTAMENTE igual que los iconos que representan:
-- mismos puntos, mismos offsets, sin multiplicar por escala. Al ser hijos
-- del marco comparten su espacio de coordenadas, asi que el offset que se
-- guarda es el mismo numero que usa el icono.
function UpdateMoverPositions()
	local f1 = GetPartyAnchor()
	if not f1 then return end
	ApplyDefaults()
	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	if movers.debuffs then
		movers.debuffs:ClearAllPoints()
		movers.debuffs:SetPoint("LEFT",  f1, "RIGHT",   debuffs.x, debuffs.y)
	end
	if movers.buffs then
		movers.buffs:ClearAllPoints()
		movers.buffs:SetPoint("TOPLEFT", f1, "TOPLEFT", buffs.x, buffs.y)
	end
end

-- Lectura inversa exacta de UpdateMoverPositions.
-- El ancla es LEFT del mover contra RIGHT del marco; los dos puntos estan
-- centrados verticalmente, asi que el Y sale de la diferencia de centros.
-- Es la misma cuenta que hace Party Trinkets al soltar.
local function ComputeDebuffOffsetsFromMover(mover)
	local f1 = GetPartyAnchor()
	if not f1 then local d = GetCurrentDefaults(); return d.debuffs.x, d.debuffs.y end
	local ml = mover:GetLeft() or 0
	local _, mcy = mover:GetCenter(); mcy = mcy or 0
	local fr = f1:GetRight() or 0
	local _, fcy = f1:GetCenter(); fcy = fcy or 0
	return math.floor(ml  - fr  + 0.5),
	       math.floor(mcy - fcy + 0.5)
end

local function ComputeBuffOffsetsFromMover(mover)
	local f1 = GetPartyAnchor()
	if not f1 then local d = GetCurrentDefaults(); return d.buffs.x, d.buffs.y end
	local ml = mover:GetLeft() or 0
	local mt = mover:GetTop()  or 0
	local fl = f1:GetLeft()    or 0
	local ft = f1:GetTop()     or 0

	-- EL SALTO AL SOLTAR ESTABA ACA. UpdateMoverPositions vuelve a anclar
	-- sumando ImprovedBuffYBonus():
	--     SetPoint(..., (buffs.y) * scale)
	-- pero esta funcion NO lo restaba al leer la posicion. Entonces cada
	-- vez que soltabas, el offset guardado se corria ese extra y el mover
	-- pegaba un salto: por eso se sentia "imantado".
	--
	-- Regla, la misma que usa Party Trinkets: hay que LEER con exactamente
	-- los mismos puntos y correcciones con los que se va a VOLVER a anclar,
	-- si no, no cierra el circuito.
	-- El ancla es TOPLEFT contra TOPLEFT, y al colocar se suma
	-- ImprovedBuffYBonus(), asi que al leer hay que restarlo.
	return math.floor(ml - fl + 0.5),
	       math.floor(mt - ft + 0.5)
end

local function StartRealtime(mover, which)
	mover._pb_elapsed = 0
	mover:SetScript("OnUpdate", function(self, elapsed)
		self._pb_elapsed = (self._pb_elapsed or 0) + elapsed
		if self._pb_elapsed < 0.03 then return end
		self._pb_elapsed = 0
		if which == "debuffs" then
			local s = GetCurrentDebuffs();
			s.x, s.y = ComputeDebuffOffsetsFromMover(self)
		else
			local s = GetCurrentBuffs();
			s.x, s.y = ComputeBuffOffsetsFromMover(self)
		end
		ReanchorAll()
	end)
end

local function StopRealtime(mover)
	mover:SetScript("OnUpdate", nil)
	mover._pb_elapsed = nil
end

local function CreateMovers()
	local f1 = GetPartyAnchor()
	if not f1 then
		print("|cff66CCFFPartyBuffs:|r PartyMemberFrame1 not available. Use /reload.")
		return
	end
	ApplyDefaults()

	if not movers.debuffs then movers.debuffs = CreateMoverFrame("PartyBuffsDebuffMover", "Debuffs (drag)") end
	if not movers.buffs   then movers.buffs   = CreateMoverFrame("PartyBuffsBuffMover",   "Buffs (drag)")   end

	UpdateMoverPositions()

	movers.debuffs:SetScript("OnDragStart", function(self)
		dragState.debuffs = true; self:ClearAllPoints(); self:StartMoving(); StartRealtime(self, "debuffs")
	end)
	movers.debuffs:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing(); StopRealtime(self); dragState.debuffs = false
		local s = GetCurrentDebuffs(); s.x, s.y = ComputeDebuffOffsetsFromMover(self)
		ReanchorAll(); UpdateMoverPositions()
	end)
	movers.buffs:SetScript("OnDragStart", function(self)
		dragState.buffs = true; self:ClearAllPoints(); self:StartMoving(); StartRealtime(self, "buffs")
	end)
	movers.buffs:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing(); StopRealtime(self); dragState.buffs = false
		local s = GetCurrentBuffs(); s.x, s.y = ComputeBuffOffsetsFromMover(self)
		ReanchorAll(); UpdateMoverPositions()
	end)
end

local function ShowMovers(show)
	if movers.debuffs then if show then movers.debuffs:Show() else movers.debuffs:Hide() end end
	if movers.buffs   then if show then movers.buffs:Show()   else movers.buffs:Hide()   end end
end

------------------------------------------------------------------------
-- Panel Scale/Max — layout mejorado con botones bien separados
--
--  ┌─────────────────────────────────┐  ← drag header (18px)
--  │ Party Buffs  Scale / Max         │
--  ├─────────────────────────────────┤
--  │ Scale icons:                    │  y = -24
--  │  Buffs   [==========] 1.00      │  y = -40
--  │  Debuffs [==========] 1.00      │  y = -62
--  ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│  sep y = -84
--  │ Max icons:                      │  y = -90
--  │  Buffs   [==========] 8         │  y = -106
--  │  Debuffs [==========] 10        │  y = -128
--  ├─────────────────────────────────┤  sep y = -150
--  │ [ Reset ]         [ Save ]      │  bottom = 8
--  └─────────────────────────────────┘  altura total: 178px
------------------------------------------------------------------------
local scalePanel
local runtimeScale
local runtimePanel

-- La ventana de opciones se guarda a si misma, RELATIVA A UIParent.
--
-- Antes se guardaba como offset contra el marco de party y habia que
-- convertir de un espacio de coordenadas al otro. Esa conversion es la que
-- fallaba y hacia que la ventana no quedara donde la soltabas. Como es una
-- ventana de configuracion y no tiene por que seguir al marco, lo mas
-- simple es que se guarde su propio punto tal como quedo, igual que hacen
-- el resto de las ventanas movibles del addon.
local function SavePanelPoint()
	if not (scalePanel and runtimePanel) then return end
	local point, _, relativePoint, x, y = scalePanel:GetPoint()
	if not point then return end
	-- Se guarda el PUNTO COMPLETO: StartMoving puede cambiar el tipo de
	-- punto (de TOPLEFT a BOTTOMRIGHT, por ejemplo), asi que quedarse solo
	-- con x/y perderia la referencia.
	runtimePanel.point         = point
	runtimePanel.relativePoint = relativePoint
	runtimePanel.x             = x or 0
	runtimePanel.y             = y or 0
end

local function PlacePanelFrom(src)
	if not scalePanel then return end
	scalePanel:ClearAllPoints()
	if src and src.point then
		scalePanel:SetPoint(src.point, UIParent, src.relativePoint or src.point,
			src.x or 0, src.y or 0)
		return
	end
	-- Sin posicion guardada: al costado del marco de party la primera vez.
	local f1 = GetPartyAnchor()
	if f1 then
		scalePanel:SetPoint("TOPLEFT", f1, "TOPRIGHT", 12, 0)
	else
		scalePanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

local function LockUI()
	ShowMovers(false)
	if scalePanel and scalePanel:IsShown() then scalePanel:Hide() end
end

local function EnsureScalePanel()
	if scalePanel then return end

	scalePanel = CreateFrame("Frame", "PB_ScalePanel", UIParent)
	-- Cajita con el valor debajo de cada slider (UIKit).
	if K.UI and K.UI.AutoRestyle then K.UI.AutoRestyle(scalePanel); end

	-- Mas alto que antes (era 178): cada slider ahora muestra su valor en la
	-- cajita editable que le cuelga ABAJO (la del resto del addon), asi que
	-- las filas necesitan el doble de separacion.
	scalePanel:SetSize(300, 268)
	scalePanel:SetFrameStrata("DIALOG")
	scalePanel:SetClampedToScreen(true)
	scalePanel:EnableMouse(true)
	scalePanel:SetMovable(true)
	scalePanel:Hide()

	if scalePanel.SetBackdrop then
		scalePanel:SetBackdrop({
			bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile=true, tileSize=16, edgeSize=12,
			insets = { left=3, right=3, top=3, bottom=3 },
		})
		scalePanel:SetBackdropColor(0, 0, 0, 0.80)
	end

	-- Header arrastrable
	local header = CreateFrame("Frame", nil, scalePanel)
	header:SetPoint("TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", 0, 0)
	header:SetHeight(18)
	header:EnableMouse(true)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function()
		-- ClearAllPoints antes de arrastrar: StartMoving puede cambiarle el
		-- TIPO de punto al frame, y si quedan anclajes viejos mezclados el
		-- panel pelea contra si mismo mientras lo movés.
		scalePanel:ClearAllPoints()
		scalePanel:StartMoving()
	end)
	header:SetScript("OnDragStop", function()
		scalePanel:StopMovingOrSizing()
		-- Se guarda tal cual quedo. Sin conversiones: no hay nada que
		-- recalcular, asi que no hay nada que se pueda desfasar.
		SavePanelPoint()
	end)

	local titleFS = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	titleFS:SetPoint("TOPLEFT", 8, -4)
	titleFS:SetText("|cff66CCFF" .. (L["PB_TITLE"] or "Party Buffs") .. "|r  " .. (L["PB_SCALEMAX"] or "Scale / Max"))

	-- Separador bajo header
	local sep0 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep0:SetTexture(1, 1, 1, 0.12)
	sep0:SetPoint("TOPLEFT", 4, -18); sep0:SetPoint("TOPRIGHT", -4, -18); sep0:SetHeight(1)

	-- Helper genérico de fila
	local function MakeRow(yOff, labelTxt, sliderName, minV, maxV, step, isInt, onChangeFn)
		local lbl = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		lbl:SetPoint("TOPLEFT", 10, yOff)
		lbl:SetText(labelTxt)
		lbl:SetWidth(55)

		-- Sin el numero a la derecha, el slider puede ser mas ancho.
		local s = CreateFrame("Slider", sliderName, scalePanel, "OptionsSliderTemplate")
		s:SetWidth(200); s:SetHeight(14)
		s:SetPoint("TOPLEFT", 68, yOff + 1)
		s:SetMinMaxValues(minV, maxV)
		s:SetValueStep(step)

		local sL = _G[sliderName.."Low"]; local sH = _G[sliderName.."High"]; local sT = _G[sliderName.."Text"]
		if sL then sL:SetText("") sL:Hide() end
		if sH then sH:SetText("") sH:Hide() end
		if sT then sT:SetText("") sT:Hide() end

		-- ANTES habia DOS numeros por slider: este FontString a la derecha,
		-- propio del modulo, y ademas la cajita editable que UIKit le cuelga
		-- debajo a todos los sliders del addon (K.UI.AutoRestyle, mas arriba
		-- en este mismo archivo). Como la cajita cae encima de la fila de
		-- abajo, el resultado era el amontonamiento que se veia.
		--
		-- Queda solo la cajita: es la misma que en el resto del panel y
		-- ademas se puede escribir el valor a mano.
		s:SetScript("OnValueChanged", function(self, val)
			val = math.floor(val / step + 0.5) * step
			if isInt then
				val = math.floor(val + 0.5)
			else
				val = tonumber(string.format("%.2f", val)) or 1
			end
			if onChangeFn then onChangeFn(val) end
		end)
		return s
	end

	-- ── Sección Scale ──────────────────────────────────────────────────────
	local lblScale = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lblScale:SetPoint("TOPLEFT", 10, -24); lblScale:SetText("|cffaaaaaa" .. (L["PB_SCALE_ICONS"] or "Scale icons:") .. "|r")

	scalePanel.buffSlider = MakeRow(-42, "Buffs", "PB_BuffScaleSlider", 0.5, 2.0, 0.1, false,
		function(v) if runtimeScale then runtimeScale.buffs   = v; ApplyScaleAll(runtimeScale) end end)
	scalePanel.debuffSlider = MakeRow(-80, "Debuffs", "PB_DebuffScaleSlider", 0.5, 2.0, 0.1, false,
		function(v) if runtimeScale then runtimeScale.debuffs = v; ApplyScaleAll(runtimeScale) end end)

	-- Separador entre secciones
	local sep1 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep1:SetTexture(1, 1, 1, 0.08)
	sep1:SetPoint("TOPLEFT", 4, -120); sep1:SetPoint("TOPRIGHT", -4, -120); sep1:SetHeight(1)

	-- ── Sección Max Icons ──────────────────────────────────────────────────
	local lblMax = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lblMax:SetPoint("TOPLEFT", 10, -128); lblMax:SetText("|cffaaaaaa" .. (L["PB_MAX_ICONS"] or "Max icons:") .. "|r")

	scalePanel.maxBuffSlider = MakeRow(-148, "Buffs", "PB_MaxBuffSlider", 1, 20, 1, true,
		function(v) ApplyDefaults(); PartyBuffsDB.maxBuffs   = v; ReanchorAll() end)
	scalePanel.maxDebuffSlider = MakeRow(-186, "Debuffs", "PB_MaxDebuffSlider", 1, 20, 1, true,
		function(v) ApplyDefaults(); PartyBuffsDB.maxDebuffs = v; ReanchorAll() end)

	-- Separador antes de botones
	local sep2 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep2:SetTexture(1, 1, 1, 0.12)
	sep2:SetPoint("BOTTOMLEFT", 4, 38); sep2:SetPoint("BOTTOMRIGHT", -4, 38); sep2:SetHeight(1)

	-- ── Botones: bien separados (izquierda y derecha del panel) ───────────
	local resetBtn = CreateFrame("Button", nil, scalePanel, "UIPanelButtonTemplate")
	resetBtn:SetSize(95, 22)
	resetBtn:SetPoint("BOTTOMLEFT", 8, 8)
	resetBtn:SetText(L["BTN_RESET_SHORT"] or "Reset")
	resetBtn:SetScript("OnClick", function()
		FullReset()
		if runtimeScale then runtimeScale.buffs = DEFAULTS_SHARED.scale.buffs; runtimeScale.debuffs = DEFAULTS_SHARED.scale.debuffs end
		-- Reset: se borra el punto guardado para que PlacePanelFrom vuelva
		-- a colocar la ventana al costado del marco.
		if runtimePanel then
			runtimePanel.point = nil; runtimePanel.relativePoint = nil
			runtimePanel.x = 0; runtimePanel.y = 0
		end
		PartyBuffsDB.panel = { x = 0, y = 0 }
		PlacePanelFrom(nil)
		scalePanel.buffSlider:SetValue(DEFAULTS_SHARED.scale.buffs)
		scalePanel.debuffSlider:SetValue(DEFAULTS_SHARED.scale.debuffs)
		scalePanel.maxBuffSlider:SetValue(DEFAULTS_SHARED.maxBuffs)
		scalePanel.maxDebuffSlider:SetValue(DEFAULTS_SHARED.maxDebuffs)
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
		if movers.buffs or movers.debuffs then UpdateMoverPositions() end
		print("|cff66CCFFPartyBuffs:|r Positions and scale reset.")
	end)

	local saveBtn = CreateFrame("Button", nil, scalePanel, "UIPanelButtonTemplate")
	saveBtn:SetSize(95, 22)
	saveBtn:SetPoint("BOTTOMRIGHT", -8, 8)
	saveBtn:SetText(L["BTN_SAVE"] or "Save")
	saveBtn:SetScript("OnClick", function()
		ApplyDefaults()
		if runtimeScale then PartyBuffsDB.scale.buffs = runtimeScale.buffs; PartyBuffsDB.scale.debuffs = runtimeScale.debuffs end
		if runtimePanel then
			-- Guardar por las dudas la posicion actual, aunque no se haya
			-- soltado el arrastre desde la ultima vez.
			SavePanelPoint()
			PartyBuffsDB.panel = CopyPanel(runtimePanel)
		end
		ApplyScaleAll(PartyBuffsDB.scale)
		LockUI()
		print("|cff66CCFFPartyBuffs:|r Settings saved.")
	end)
end

local function PlaceScalePanelFromDB()
	ApplyDefaults()
	-- Con la ventana abierta manda lo que acabas de arrastrar; si no, lo
	-- guardado.
	PlacePanelFrom(runtimePanel or PartyBuffsDB.panel)
end

local function ShowScalePanel(show)
	EnsureScalePanel()
	ApplyDefaults()
	if not show then
		if scalePanel:IsShown() then scalePanel:Hide() end
		runtimeScale = nil; runtimePanel = nil
		return
	end
	runtimeScale = CopyScale(PartyBuffsDB.scale)
	runtimePanel = CopyPanel(PartyBuffsDB.panel)
	PlaceScalePanelFromDB()
	scalePanel.buffSlider:SetValue(runtimeScale.buffs)
	scalePanel.debuffSlider:SetValue(runtimeScale.debuffs)
	scalePanel.maxBuffSlider:SetValue(GetMaxBuffs())
	scalePanel.maxDebuffSlider:SetValue(GetMaxDebuffs())
	scalePanel:Show()
end

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
SLASH_PARTYBUFFS1 = "/pbuffs"
SLASH_PARTYBUFFS2 = "/partybuffs"
-- =====================================================================
-- /pbuffs  ->  abre el menu directamente.
--
-- Antes habia cuatro subcomandos (unlock, lock, reset, status) y escribir
-- /pbuffs solo, que es lo que uno escribe siempre, no hacia mas que
-- imprimir la lista. Ahora el comando pelado hace lo unico que se le
-- pide: abrir el menu, con sus cuadros de arrastre.
--
-- Y lo CIERRA si ya estaba abierto. Sin /pbuffs lock hace falta alguna
-- forma de cerrarlo desde el chat; el boton Save tambien lo cierra.
--
-- "status" se fue: escupia en el chat lo mismo que se ve en la ventana.
-- "reset" se queda, porque es la unica accion que no tiene boton propio
-- fuera del menu.
-- =====================================================================
SlashCmdList["PARTYBUFFS"] = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")

	if msg == "" then
		if scalePanel and scalePanel:IsShown() then
			LockUI()
		else
			CreateMovers()
			ShowMovers(true)
			ShowScalePanel(true)
		end

	elseif msg == "reset" then
		-- Reset silencioso: solo resetea datos y reaplica, SIN abrir ningún menú
		FullReset()
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
		-- Si el panel está abierto, actualizar sus sliders (sin abrirlo si estaba cerrado)
		if scalePanel and scalePanel:IsShown() then
			if runtimeScale then
				runtimeScale.buffs   = DEFAULTS_SHARED.scale.buffs
				runtimeScale.debuffs = DEFAULTS_SHARED.scale.debuffs
			end
			scalePanel.buffSlider:SetValue(DEFAULTS_SHARED.scale.buffs)
			scalePanel.debuffSlider:SetValue(DEFAULTS_SHARED.scale.debuffs)
			scalePanel.maxBuffSlider:SetValue(DEFAULTS_SHARED.maxBuffs)
			scalePanel.maxDebuffSlider:SetValue(DEFAULTS_SHARED.maxDebuffs)
			UpdateMoverPositions()
		end
		print("|cff66CCFFPartyBuffs:|r Reset done. Positions and scale restored.")

	else
		print("|cff66CCFFPartyBuffs:|r Available commands:")
		print("  /pbuffs        — Open the settings panel and the movers")
		print("  /pbuffs reset  — Reset positions and scale to defaults")
	end
end

------------------------------------------------------------------------
-- Enable / Disable
------------------------------------------------------------------------
local function PB_Enable()
	if pbEnabled then return end
	pbEnabled = true

	ApplyDefaults()
	SetupFrames()
	ReanchorAll()
	ApplyScaleAll(PartyBuffsDB.scale)

	if K.UpdateNewPartyFrames then K.UpdateNewPartyFrames(); end

	if not boot then boot = CreateFrame("Frame") end
	boot:UnregisterAllEvents()
	boot:RegisterEvent("PLAYER_ENTERING_WORLD")
	boot:RegisterEvent("PARTY_MEMBERS_CHANGED")
	pcall(boot.RegisterEvent, boot, "GROUP_ROSTER_UPDATE")
	boot:SetScript("OnEvent", function(self, event)
		if not pbEnabled then return end
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
		if (movers.debuffs or movers.buffs) and not dragState.debuffs and not dragState.buffs then
			UpdateMoverPositions()
		end
	end)
end

local function PB_Disable()
	if not pbEnabled then return end
	pbEnabled = false

	if boot then boot:UnregisterAllEvents(); boot:SetScript("OnEvent", nil) end

	LockUI()

	for i, evt in pairs(auraEvts) do
		if evt then evt:UnregisterAllEvents(); evt:SetScript("OnEvent", nil); evt:Hide() end
		auraEvts[i] = nil
	end

	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			f:RegisterEvent("UNIT_AURA")

			for j = 5, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				local d = _G[f:GetName() .. "Debuff" .. j]
				if b then b:Hide() end
				if d then d:Hide() end
			end
			for j = 1, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				local d = _G[f:GetName() .. "Debuff" .. j]
				if b and b.SetScale then b:SetScale(1) end
				if d and d.SetScale then d:SetScale(1) end
			end

			-- Volver a los anclajes REALES que tenia Blizzard, no a numeros
			-- puestos a ojo. El fallback solo entra si por algun motivo no
			-- se llego a capturar (por ejemplo si nunca se activo el modulo).
			local o  = origAnchors[i]
			local d1 = _G[f:GetName() .. "Debuff1"]
			if d1 then
				d1:ClearAllPoints()
				if o and o.debuff and o.debuff[1] then
					local pt, rel, rp, x, y = unpack(o.debuff)
					d1:SetPoint(pt, rel or f, rp or pt, x or 0, y or 0)
				else
					d1:SetPoint("LEFT", f, "RIGHT", 5, 0)
				end
			end

			local b1 = _G[f:GetName() .. "Buff1"]
			if b1 then
				b1:ClearAllPoints()
				if o and o.buff and o.buff[1] then
					local pt, rel, rp, x, y = unpack(o.buff)
					b1:SetPoint(pt, rel or f, rp or pt, x or 0, y or 0)
				else
					b1:SetPoint("TOPLEFT", f, "TOPLEFT", 48, -32)
				end
			end

			if f.unit and UnitExists(f.unit) then
				if PartyMemberFrame_RefreshDebuffs then pcall(PartyMemberFrame_RefreshDebuffs, f) end
				if PartyMemberFrame_RefreshBuffs   then pcall(PartyMemberFrame_RefreshBuffs, f)   end
			end
		end
	end

	initialized = false
	if K.UpdateNewPartyFrames then K.UpdateNewPartyFrames(); end
end

------------------------------------------------------------------------
-- Registro del módulo
------------------------------------------------------------------------
K.RegisterModule("PartyBuffs", {
	name    = "Party Buffs",
	desc    = "Extended buffs/debuffs (1-20 icons) on party frames. /pbuffs | /pbuffs reset",
	default = false,   -- viene apagado: se prende desde Frames > Party
	onEnable  = PB_Enable,
	onDisable = PB_Disable,
	hideFromModulesTab = true,
})