local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PartyPetTargetFrame.lua  (integrado a NUF)
-- Marco propio para las mascotas de los companeros: retrato, vida/mana,
-- casteo, buffs/debuffs y aviso de CC.
--
-- CAMBIOS respecto del addon suelto:
--   * Es un modulo de NUF: checkbox propio en Frames > Party y los
--     eventos solo se registran con el modulo activo.
--   * UNIT_POWER_UPDATE no existe en 3.3.5a (es de retail): se cambio
--     por los eventos de recurso reales de WotLK.
--   * La textura CC-Glow no venia en el paquete: se usa una nativa.
--   * Se saco el print de carga.
--
-- ---------------------------------------------------------
-- DE UNA MASCOTA A CUATRO
--
-- Todo esto estaba escrito para party1pet y nada mas: un marco suelto,
-- con "party1pet" a mano en once lugares distintos. Agregar el compa 2
-- copiando el archivo habria dejado dos copias del mismo bug esperando.
--
-- Ahora hay UNA fabrica, PPF_Build(i), y cuatro marcos que salen de ella.
-- Cada uno guarda su indice y su unidad; ninguna funcion vuelve a nombrar
-- "party1pet". El que agregue un quinto compa el dia de manana cambia el
-- 4 de NUM_PETS y listo.
--
-- El marco 1 es el unico que se arrastra: los otros tres cuelgan de el en
-- cadena. Es lo que uno espera de una fila -- se agarra la de arriba y se
-- mueve el bloque -- y ademas evita cuatro posiciones guardadas que se
-- pueden desalinear entre si.
--
-- ---------------------------------------------------------
-- SOLO EN ARENAS
--
-- Fuera de arena estos cuatro marcos son ruido: en un raid de 25 la
-- mascota del compa 1 no le importa a nadie, y en el mundo abierto tapan
-- pantalla. En arena son justo lo contrario: saber si el felino esta en
-- miedo o si el elemental esta casteando decide la ronda.
--
-- Asi que por defecto solo se muestran en arena. No es un checkbox nuevo
-- en el panel a proposito -- esa columna ya esta llena y una casilla mas
-- ahi corre todo lo de abajo -- - va por /ppf arena, que ademas queda
-- documentado en el /ppf a secas.
-- =========================================================

local addonName = "PartyPetTargetFrame"
local frame = CreateFrame("Frame", addonName.."Frame", UIParent)

local NUM_PETS   = 4      -- party1pet .. party4pet
local FRAME_W    = 160
local FRAME_H    = 80
local STACK_GAP  = 4      -- separacion entre un marco y el de abajo
local DEF_X, DEF_Y = 300, 100

-- C_Timer.After is not available in WotLK (3.x); use a frame-based fallback
local function TimerAfter(delay, func)
    local t = CreateFrame("Frame")
    local elapsed = 0
    t:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            func()
        end
    end)
end

-- =========================================================
-- OPCIONES (NidhausUnitFramesDB.PartyPetFrame)
--
-- Antes "bloqueado" y "click para seleccionar" vivian en una tabla local y
-- se perdian en cada /reload. Ahora todo se guarda, y el panel (Frames >
-- Party > Mascotas) las muestra.
--
--   showBuffs / showDebuffs / showCast   cada parte del marco
--   auraTimers  el reloj y los segundos en cada buff / debuff
--   borderStyle el borde de esos iconos: "fino", "lorti" o "blizzard"
--   dispelGlow  brillo en los debuffs que TU clase puede sacar
--   ownerColor  la barra de vida, del color de la clase del dueno
--   rangeFade   semitransparente cuando esta lejos de vos
--   clickable   click izquierdo = seleccionar la mascota
--   locked      la fila no se arrastra
--   inArena / inBG / inWorld   donde se muestra (ver ZONA)
--
-- El CC en el retrato y sus segundos van SIEMPRE (eran el pedido; las
-- casillas se sacaron) y el objetivo de la mascota se saco del todo.
-- =========================================================
local OPT_DEFAULTS = {
	showBuffs = true, showDebuffs = true, showCast = true,
	auraTimers = true, borderStyle = "fino",
	dispelGlow = true, ownerColor = true, rangeFade = true,
	clickable = true, locked = false,
}
local BORDER_STYLES = { fino = true, lorti = true, blizzard = true }

local function PPF_Opts()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
	local db = NidhausUnitFramesDB.PartyPetFrame
	if type(db) ~= "table" then
		db = {}
		NidhausUnitFramesDB.PartyPetFrame = db
	end
	for k, v in pairs(OPT_DEFAULTS) do
		if db[k] == nil then db[k] = v end
	end
	if not BORDER_STYLES[db.borderStyle] then db.borderStyle = "fino" end
	-- Las opciones que se sacaron no quedan dando vueltas en el guardado.
	db.showCC, db.ccTimer, db.showTarget = nil, nil, nil
	-- Zonas. Antes habia una sola opcion, "solo en arena" (PartyPetArenaOnly,
	-- con /ppf arena). Se convierte una vez: solo arena -> solo Arena
	-- tildada; si no -> las tres.
	if db.inArena == nil then
		local arenaOnly = (C.PartyPetArenaOnly ~= false)
		db.inArena = true
		db.inBG    = not arenaOnly
		db.inWorld = not arenaOnly
	end
	return db
end

-- ---------------------------------------------------------
-- ZONA
--
-- IsActiveBattlefieldArena existe en 3.3.5a pero no en todos los cores
-- privados, asi que se pregunta con pcall y hay un segundo camino por
-- IsInInstance, que si esta siempre.
-- ---------------------------------------------------------
-- "Solo arena" = Arena tildada y las otras dos no (lo usa /ppf arena).
local function PPF_ArenaOnly()
    local o = PPF_Opts()
    return o.inArena and not o.inBG and not o.inWorld
end

local function PPF_InArena()
    if type(IsActiveBattlefieldArena) == "function" then
        local ok, res = pcall(IsActiveBattlefieldArena)
        if ok and res then return true end
    end
    local _, itype = IsInInstance()
    return itype == "arena"
end

-- Donde se muestra: Arena / Campos de batalla / Mundo abierto (las
-- casillas del panel). Mazmorras, bandas y duelos cuentan como mundo
-- abierto: "Duelos" se saco, en un duelo no hay compas con mascota.
-- Por eso no se usa K.ModuleZoneAllowed, que separa el duelo aparte.
local function PPF_ZoneAllows()
    local o = PPF_Opts()
    if PPF_InArena() then return o.inArena and true or false end
    local _, itype = IsInInstance()
    if itype == "pvp" then return o.inBG and true or false end
    return o.inWorld and true or false
end

-- ---------------------------------------------------------
-- POSICION GUARDADA
--
-- Antes no se guardaba nada: arrastrabas el marco y al recargar volvia al
-- centro. Con uno solo se toleraba; con cuatro en cadena es inaceptable,
-- asi que la posicion del marco 1 -- el unico que se mueve -- se escribe
-- en la DB al soltar.
-- ---------------------------------------------------------
local function PPF_DB()
    if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
    NidhausUnitFramesDB.PartyPetPos = NidhausUnitFramesDB.PartyPetPos or {}
    return NidhausUnitFramesDB.PartyPetPos
end

local petFrames = {}      -- [1..NUM_PETS] = marco

-- =========================================================
-- VISIBILIDAD SEGURA
--
-- Los marcos son Buttons con SecureUnitButtonTemplate, o sea marcos
-- PROTEGIDOS: Show() y Hide() sobre ellos estan vedados en combate. El
-- OnUpdate llamaba a Show() diez veces por segundo, estuviera ya visible
-- o no, y el cliente cortaba cada llamada: 254 lineas seguidas en
-- taint.log de un solo combate, y el cartel amarillo "Interface action
-- failed because of an AddOn" en pantalla.
--
-- RegisterUnitWatch es la herramienta de Blizzard para esto: el codigo
-- seguro muestra y oculta el marco segun exista la unidad, y eso si
-- funciona en combate. Si el cliente no la tuviera, se cae a un Show/Hide
-- a mano que solo se llama cuando el estado cambia de verdad, y nunca
-- dentro de combate: lo pendiente se aplica al salir.
-- =========================================================
local PPF_HasUnitWatch = (type(RegisterUnitWatch) == "function")
	and (type(UnregisterUnitWatch) == "function")
local PPF_WantVisible  = false   -- lo que quiere el modulo: prendido o no
local PPF_Pending      = nil     -- lo que quedo para cuando termine el combate

local PPF_ApplyVisibility        -- se define abajo, la usa el frame de combate
local previewOn = false          -- vista previa (marcos de mentira para ubicarlos)

local ppfCombat = CreateFrame("Frame")
ppfCombat:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	if PPF_Pending ~= nil then
		local want = PPF_Pending
		PPF_Pending = nil
		PPF_ApplyVisibility(want)
	end
end)

function PPF_ApplyVisibility(on)
	-- Con la vista previa puesta los marcos se muestran igual, haya o no
	-- mascota: la visibilidad real se repone al sacarla.
	if previewOn then
		PPF_WantVisible = on
		return
	end
	if InCombatLockdown() then
		PPF_Pending = on
		ppfCombat:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	PPF_WantVisible = on

	-- La zona manda por encima del interruptor: prendido pero fuera de
	-- arena, no se ve nada. Se guarda igual el "want" de arriba, asi al
	-- entrar a la arena aparecen sin tener que tocar nada.
	local show = on and PPF_ZoneAllows()

	for i = 1, NUM_PETS do
		local f = petFrames[i]
		if f then
			if PPF_HasUnitWatch then
				if show and not f.ppfWatching then
					RegisterUnitWatch(f)
					f.ppfWatching = true
				elseif (not show) and f.ppfWatching then
					UnregisterUnitWatch(f)
					f.ppfWatching = false
				end
				if not show then f:Hide() end
			else
				local should = show and UnitExists(f.unit) and true or false
				if should and not f:IsShown() then
					f:Show()
				elseif (not should) and f:IsShown() then
					f:Hide()
				end
			end
		end
	end
end

-- Auras a ocultar
local hiddenAuras = {
    ["Devotion Aura"] = true,
    ["Crusader Aura"] = true,
    ["Concentration Aura"] = true,
    ["Retribution Aura"] = true,
    ["Resistance Aura"] = true,
    ["Trueshot Aura"] = true,
    ["Fire Resistance Aura"] = true,
    ["Frost Resistance Aura"] = true,
    ["Shadow Resistance Aura"] = true,
    ["Aspect of the Pack"] = true,
    ["Aspect of the Wild"] = true,
}

-- =========================================================
-- CC
--
-- La deteccion vieja miraba el "tipo" del debuff buscando "Stun", "Fear",
-- "Polymorph"... pero el tipo en WoW es Magia / Maldicion / Veneno /
-- Enfermedad (o nada): nunca coincidia y el aviso de CC no salia NUNCA.
--
-- Ahora se busca por el spellID del aura en la lista de CC del addon (la
-- misma de los DR de arena: K.GetCCCategory). Si hay varios, gana el mas
-- fuerte; a igual fuerza, el que dura mas.
-- =========================================================
local CC_PRIORITY = {
	cyclone = 100, banish = 100, mc = 95,
	ctrlstun = 90, openstun = 90, rndstun = 90, charge = 90, intimidation = 90,
	disorient = 80, sleep = 80, scatter = 80,
	fear = 70, horror = 70,
	silence = 50, disarm = 40,
	ctrlroot = 30, rndroot = 30, entrapment = 30,
}

-- icono, duracion, vencimiento del CC mas fuerte (o nil)
local function FindCC(unit)
	if not K.GetCCCategory then return nil end
	local bestP, bestIcon, bestDur, bestExp
	for i = 1, 40 do
		local name, _, icon, _, _, duration, expires, _, _, _, spellId = UnitDebuff(unit, i)
		if not name then break end
		local cat = K.GetCCCategory(spellId)
		local p = cat and CC_PRIORITY[cat]
		if p and (not bestP or p > bestP or (p == bestP and (expires or 0) > (bestExp or 0))) then
			bestP, bestIcon, bestDur, bestExp = p, icon, duration, expires
		end
	end
	return bestIcon, bestDur, bestExp
end

-- Icono redondo, como el retrato (si el cliente lo permite).
local function SetRoundIcon(tex, path)
	if type(SetPortraitToTexture) == "function" and pcall(SetPortraitToTexture, tex, path) then
		tex:SetTexCoord(0, 1, 0, 1)
		return
	end
	tex:SetTexture(path)
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

-- Los segundos del CC. Corre solo mientras se ve el CC, diez veces por
-- segundo, y escribe con SetFormattedText (sin basura).
local function CCText_OnUpdate(self, elapsed)
	self.acc = (self.acc or 0) + elapsed
	if self.acc < 0.1 then return end
	self.acc = 0
	local exp = self.expires
	if not exp then return end
	local left = exp - GetTime()
	if left <= 0 then
		if self.loop and self.pf then
			-- Vista previa: el CC de mentira vuelve a empezar.
			self.expires = GetTime() + self.loop
			CooldownFrame_SetTimer(self.pf.ccCD, GetTime(), self.loop, 1)
			return
		end
		self.text:SetText("")
		return
	end
	if left < 10 then
		self.text:SetFormattedText("%.1f", left)
	else
		self.text:SetFormattedText("%d", left)
	end
end

-- Muestra (o saca) el CC en el retrato. Sin CC vuelve el retrato normal.
local function SetCCPortrait(pf, icon, duration, expires, loop)
	if icon then
		-- Aro rojo, el icono del CC tapando el retrato, el reloj y los
		-- segundos: siempre juntos.
		pf.ccGlow:Show()
		if pf.ccIcon.nufPath ~= icon then
			SetRoundIcon(pf.ccIcon, icon)
			pf.ccIcon.nufPath = icon
		end
		pf.ccIcon:Show()
		if duration and duration > 0 and expires then
			if pf.ccCD.nufExp ~= expires then
				CooldownFrame_SetTimer(pf.ccCD, expires - duration, duration, 1)
				pf.ccCD.nufExp = expires
			end
			pf.ccCD:Show()
			pf.ccOverlay.expires = expires
			pf.ccOverlay.loop = loop
			pf.ccOverlay:Show()
		else
			pf.ccCD:Hide()
			pf.ccOverlay:Hide()
		end
		return
	end
	pf.ccGlow:Hide()
	pf.ccIcon:Hide()
	pf.ccIcon.nufPath = nil
	pf.ccCD:Hide()
	pf.ccCD.nufExp = nil
	pf.ccOverlay:Hide()
	pf.ccOverlay.expires = nil
	pf.ccOverlay.loop = nil
end

-- Que buffs se muestran: TODOS menos el ruido de la lista de arriba
-- (auras de paladin, aspectos). En arena lo que importa de la mascota es
-- justamente lo que le pusieron otros o ella misma: Colera de las bestias
-- (inmune al CC), Llamada del maestro, Frenesi profano...
--
-- Antes leia el lanzador en la SEPTIMA posicion de UnitBuff, que en 3.3.5
-- es el vencimiento (el lanzador es la octava): "puesto por vos" no daba
-- nunca y, con la opcion "showCastableBuffs" de Blizzard apagada (la de
-- fabrica), la fila de buffs quedaba siempre vacia.
--
-- (El filtro va adentro del bucle de UpdatePetFrame: una sola llamada a
-- UnitBuff por buff, en vez de dos.)

-- =========================================================
-- ICONOS DE BUFFS / DEBUFFS
--
-- Antes: el aro de debuff de Blizzard ESTIRADO encima del icono (le comia
-- el borde) y pintado de dorado en los buffs. Ahora el icono va limpio y
-- el borde sale de uno de tres estilos, a eleccion (Frames > Party >
-- Mascotas):
--
--   fino      contorno negro de 1 px; los debuffs, ademas, un aro del
--             color de su escuela
--   lorti     el brillo y la sombra de los botones de Lorti UI (la sombra
--             toma el color de la fila "Party pets" de Lorti, si tiene)
--   blizzard  como el marco de objetivo: buffs sin borde, debuffs con su
--             aro de color apenas por fuera del icono
--
-- Cada icono lleva ademas el reloj, los segundos (con noCooldownCount:
-- OmniCC no pone otro numero), las acumulaciones y el brillo de "lo podes
-- dispelear". Las piezas de cada estilo se crean la primera vez que se
-- usan, asi que el estilo que no elegiste no ocupa memoria.
-- =========================================================
local LORTI_MEDIA = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\"
local WHITE8 = "Interface\\Buttons\\WHITE8X8"

local DEBUFF_COLORS = {
    Magic   = {0.2, 0.6, 1},      -- Azul
    Curse   = {0.6, 0, 1},        -- Morado
    Disease = {0.6, 0.4, 0},      -- Marron
    Poison  = {0, 0.6, 0},        -- Verde
}
local DEBUFF_NONE = {0.8, 0, 0}   -- sin escuela (golpes, sangrados...)

-- Lo que puede sacar TU clase (de un aliado). El chaman necesita el
-- talento para las maldiciones, y el brujo, al manafago.
local _, PLAYER_CLASS = UnitClass("player")
local CAN_DISPEL = ({
    PRIEST  = { Magic = true, Disease = true },
    PALADIN = { Magic = true, Poison = true, Disease = true },
    SHAMAN  = { Poison = true, Disease = true, Curse = true },
    DRUID   = { Curse = true, Poison = true },
    MAGE    = { Curse = true },
    WARLOCK = { Magic = true },
})[PLAYER_CLASS or ""] or {}

local function MakeAuraIcon(parent, size)
	local icon = CreateFrame("Frame", nil, parent)
	icon:SetSize(size, size)
	icon.size = size
	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local cd = CreateFrame("Cooldown", nil, icon)
	cd:SetAllPoints(icon.texture)
	-- Al reves, como los de PartyBuffs y los del marco de objetivo
	-- (TargetBuffFrameTemplate trae reverse="true"): lo que queda de
	-- duracion se ve claro y la sombra va ganando.
	cd:SetReverse(true)
	cd.noCooldownCount = true
	cd.noOCC = true
	cd:Hide()
	icon.cd = cd

	-- Textos y brillo por encima del reloj.
	local top = CreateFrame("Frame", nil, icon)
	top:SetAllPoints(icon)
	top:SetFrameLevel(icon:GetFrameLevel() + 3)
	icon.time = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	icon.time:SetPoint("CENTER", icon, "CENTER", 0, 0)
	icon.count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -1)
	icon.glow = top:CreateTexture(nil, "BACKGROUND")
	icon.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	icon.glow:SetBlendMode("ADD")
	icon.glow:SetPoint("CENTER", icon, "CENTER", 0, 0)
	icon.glow:SetSize(size * 1.8, size * 1.8)
	icon.glow:Hide()
	icon:Hide()
	return icon
end

-- Viste el icono con un estilo. r, g, b = color de la escuela (debuffs);
-- nil en los buffs. Si nada cambio, no toca nada: corre seguido.
local function StyleIcon(icon, style, r, g, b)
	if icon.nufStyle == style and icon.nufR == r and icon.nufG == g and icon.nufB == b then return end
	icon.nufStyle, icon.nufR, icon.nufG, icon.nufB = style, r, g, b
	local isDebuff = (r ~= nil)
	if icon.fOuter then icon.fOuter:Hide(); icon.fRing:Hide() end
	if icon.lGloss then icon.lGloss:Hide(); icon.lShadow:Hide(); icon.lRing:Hide() end
	if icon.bBorder then icon.bBorder:Hide() end
	local tex = icon.texture
	tex:ClearAllPoints()

	if style == "lorti" then
		local big = icon.size >= 26
		local inset = big and 2 or 1
		tex:SetPoint("TOPLEFT", icon, "TOPLEFT", inset, -inset)
		tex:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -inset, inset)
		tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		if not icon.lGloss then
			local gl = icon:CreateTexture(nil, "OVERLAY")
			gl:SetTexture(LORTI_MEDIA .. "gloss")
			gl:SetAllPoints(icon)
			icon.lGloss = gl
			-- La sombra va DEBAJO del icono: hijo con un nivel menos.
			local off = big and 4 or 3
			local sh = CreateFrame("Frame", nil, icon)
			sh:SetFrameLevel(math.max(0, icon:GetFrameLevel() - 1))
			sh:SetPoint("TOPLEFT", icon, "TOPLEFT", -off, off)
			sh:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", off, -off)
			sh:SetBackdrop({ edgeFile = LORTI_MEDIA .. "outer_shadow", edgeSize = off + 1,
				insets = { left = off + 1, right = off + 1, top = off + 1, bottom = off + 1 } })
			icon.lShadow = sh
			-- El aro de la escuela, encima del brillo (si no, el borde oscuro
			-- del brillo lo tapa).
			local ring = CreateFrame("Frame", nil, icon)
			ring:SetFrameLevel(icon:GetFrameLevel() + 2)
			ring:SetPoint("TOPLEFT", tex, "TOPLEFT", -1, 1)
			ring:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 1, -1)
			ring:SetBackdrop({ edgeFile = WHITE8, edgeSize = 1 })
			ring:Hide()   -- nace visible: solo lo prenden los debuffs
			icon.lRing = ring
		end
		local sr, sg, sb = nil, nil, nil
		if K.LortiZoneColor then sr, sg, sb = K.LortiZoneColor("PartyPet") end
		if sr then icon.lShadow:SetBackdropBorderColor(sr, sg, sb, 1)
		else icon.lShadow:SetBackdropBorderColor(0, 0, 0, 0.9) end
		icon.lShadow:Show()
		if isDebuff then
			icon.lGloss:SetVertexColor(r, g, b)
			icon.lRing:SetBackdropBorderColor(r, g, b, 1)
			icon.lRing:Show()
		else
			icon.lGloss:SetVertexColor(0, 0, 0)
		end
		icon.lGloss:Show()

	elseif style == "blizzard" then
		tex:SetAllPoints(icon)
		tex:SetTexCoord(0, 1, 0, 1)
		if isDebuff then
			if not icon.bBorder then
				local bo = icon:CreateTexture(nil, "OVERLAY")
				bo:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
				bo:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
				bo:SetPoint("CENTER", icon, "CENTER", 0, 0)
				bo:SetSize(icon.size + 4, icon.size + 4)   -- el aro por fuera
				icon.bBorder = bo
			end
			icon.bBorder:SetVertexColor(r, g, b)
			icon.bBorder:Show()
		end

	else -- fino
		tex:SetAllPoints(icon)
		tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		if not icon.fOuter then
			-- Dos cuadrados DETRAS del icono: de cada uno solo asoma el borde.
			icon.fOuter = icon:CreateTexture(nil, "BACKGROUND")
			icon.fOuter:SetTexture(WHITE8)
			icon.fOuter:SetVertexColor(0, 0, 0, 1)
			icon.fRing = icon:CreateTexture(nil, "BORDER")
			icon.fRing:SetTexture(WHITE8)
			icon.fRing:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
			icon.fRing:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
			icon.fRing:Hide()   -- nace visible: solo lo prenden los debuffs
		end
		local o = isDebuff and 2 or 1
		icon.fOuter:ClearAllPoints()
		icon.fOuter:SetPoint("TOPLEFT", icon, "TOPLEFT", -o, o)
		icon.fOuter:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", o, -o)
		icon.fOuter:Show()
		if isDebuff then
			icon.fRing:SetVertexColor(r, g, b, 1)
			icon.fRing:Show()
		end
	end
end

-- Los segundos que le quedan (redondeado para arriba, como el reloj).
-- SetFormattedText: sin basura. Rojo los ultimos 5 s.
local function UpdateAuraTime(icon, now)
	local exp = icon.expires
	if not exp then return end
	local left = exp - now
	if left <= 0 then
		if icon.loop then
			-- Vista previa: vuelve a empezar.
			icon.expires = now + icon.loop
			icon.cd.nufExp = icon.expires
			CooldownFrame_SetTimer(icon.cd, now, icon.loop, 1)
			left = icon.loop
		else
			icon.time:SetText("")
			return
		end
	end
	if left < 60 then
		icon.time:SetFormattedText("%d", math.ceil(left))
	elseif left < 3600 then
		icon.time:SetFormattedText("%dm", math.ceil(left / 60))
	else
		icon.time:SetFormattedText("%dh", math.ceil(left / 3600))
	end
	local red = left < 5
	if icon.timeRed ~= red then
		icon.timeRed = red
		if red then icon.time:SetTextColor(1, 0.25, 0.25) else icon.time:SetTextColor(1, 1, 1) end
	end
end

local function SetAuraTimer(icon, duration, expires, on, loop)
	if on and duration and duration > 0 and expires and expires > 0 then
		if icon.cd.nufExp ~= expires then
			CooldownFrame_SetTimer(icon.cd, expires - duration, duration, 1)
			icon.cd.nufExp = expires
		end
		icon.cd:Show()
		icon.expires, icon.loop = expires, loop
		UpdateAuraTime(icon, GetTime())
	else
		icon.cd:Hide()
		icon.cd.nufExp = nil
		icon.expires, icon.loop = nil, nil
		icon.time:SetText("")
	end
end

-- Un buff (r = nil) o un debuff, con todo lo suyo.
local function ShowAura(icon, o, texture, count, duration, expires, col, glow, loop)
	icon.texture:SetTexture(texture)
	if col then StyleIcon(icon, o.borderStyle, col[1], col[2], col[3])
	else StyleIcon(icon, o.borderStyle) end
	if count and count > 1 then icon.count:SetFormattedText("%d", count) else icon.count:SetText("") end
	SetAuraTimer(icon, duration, expires, o.auraTimers, loop)
	if glow and col then
		icon.glow:SetVertexColor(col[1], col[2], col[3])
		icon.glow:Show()
	else
		icon.glow:Hide()
	end
	icon:Show()
end

local function HideAura(icon)
	if icon.expires or icon:IsShown() then
		icon:Hide()
		icon.glow:Hide()
		icon.cd:Hide()
		icon.cd.nufExp = nil
		icon.expires, icon.loop = nil, nil
	end
end

-- ---------------------------------------------------------
-- RANGO
--
-- Con un hechizo de curacion se pregunta por la mascota misma (40 m).
-- Sin el (o si el hechizo no esta en el libro), por el dueno -- las
-- mascotas andan pegadas a el -- o, si eso no contesta, por la distancia
-- de "seguir" (28 m), que anda con cualquier unidad.
-- ---------------------------------------------------------
local RANGE_SPELL = ({ PRIEST = 2050, PALADIN = 635, SHAMAN = 331, DRUID = 5185 })[PLAYER_CLASS or ""]
RANGE_SPELL = RANGE_SPELL and GetSpellInfo(RANGE_SPELL) or nil

local function PetInRange(pf)
	local unit = pf.unit
	if RANGE_SPELL then
		local r = IsSpellInRange(RANGE_SPELL, unit)
		if r ~= nil then return r == 1 end
	end
	if UnitInRange(pf.owner) then return true end
	return CheckInteractDistance(unit, 4) and true or false
end

-- El color de la barra de vida: verde, o el de la clase del dueno.
local function OwnerColor(class)
	local col = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if col then return col.r, col.g, col.b end
	return 0, 1, 0
end

-- ---------------------------------------------------------
-- Tinte de Lorti UI
--
-- El marco de la mascota es arte de Blizzard sin tocar, asi que con Lorti
-- puesto quedaba dorado y brillante al lado del resto oscurecido. Piden el
-- tinte por el mismo camino que el grupo, arena y los target de grupo: si
-- Lorti esta apagado, ApplyLortiTint repone el blanco y todo queda como
-- antes.
-- ---------------------------------------------------------
local function ApplyPetLortiTint(pf)
	if not K.ApplyLortiTint then return; end
	K.ApplyLortiTint(pf.bg, "LortiUI_PartyPet");
end

-- =========================================================
-- LA FABRICA
-- =========================================================
local function PPF_Build(i)
	local unit = "party" .. i .. "pet"

	local petFrame = CreateFrame("Button", "CustomParty" .. i .. "PetFrame",
		UIParent, "SecureUnitButtonTemplate")
	-- 160x80, el tamano de siempre. El fondo es UI-PetFrame con SetAllPoints,
	-- asi que agrandar el marco estiraba el arte y el aro del retrato salia
	-- deformado. La barra de casteo y el nombre del objetivo cuelgan de la
	-- barra de mana y no necesitan sitio extra: un hijo puede salirse del
	-- marco, nadie lo recorta.
	petFrame:SetSize(FRAME_W, FRAME_H)
	petFrame.index = i
	petFrame.unit  = unit
	petFrame.owner = "party" .. i   -- el dueno (rango y color de clase)

	-- NACE ESCONDIDO.
	--
	-- CreateFrame devuelve el marco VISIBLE. La visibilidad recien se decide
	-- cuando el modulo arranca o cuando RegisterUnitWatch toma el control, y
	-- hasta ese momento el marco estaba en pantalla sin unidad detras: el
	-- "fantasma" que aparecia al entrar por primera vez, con retrato vacio y
	-- barras a cero, aunque no tuvieras mascota ni compa.
	--
	-- Un Hide() aca no puede fallar: todavia no estamos en combate al cargar.
	petFrame:Hide()

	-- Configurar atributos para clic
	petFrame:SetAttribute("type1", "target")
	petFrame:SetAttribute("unit", unit)
	petFrame:RegisterForClicks("AnyUp")
	petFrame:EnableMouse(true)

	-- Fondo
	petFrame.bg = petFrame:CreateTexture(nil, "BACKGROUND")
	petFrame.bg:SetAllPoints(true)
	petFrame.bg:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\PartyPetFrame\\Media\\UI-PetFrame")
	petFrame.bg:SetDrawLayer("BACKGROUND", 0)

	-- Indicador de bloqueo
	petFrame.lockIndicator = petFrame:CreateTexture(nil, "OVERLAY")
	petFrame.lockIndicator:SetSize(24, 24)
	petFrame.lockIndicator:SetPoint("TOPRIGHT", petFrame, "TOPRIGHT", -5, -5)
	petFrame.lockIndicator:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
	petFrame.lockIndicator:Hide()

	-- Retrato
	petFrame.portraitFrame = CreateFrame("Frame", nil, petFrame)
	petFrame.portraitFrame:SetSize(40, 40)
	petFrame.portraitFrame:SetPoint("LEFT", 12, 12)
	petFrame.portraitFrame:SetFrameLevel(0)

	petFrame.portraitIcon = petFrame.portraitFrame:CreateTexture(nil, "ARTWORK")
	petFrame.portraitIcon:SetAllPoints(true)
	petFrame.portraitIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	petFrame.portraitBG = petFrame.portraitFrame:CreateTexture(nil, "BACKGROUND")
	petFrame.portraitBG:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
	petFrame.portraitBG:SetAllPoints(true)
	petFrame.portraitBG:SetVertexColor(0, 0, 0, 1)

	-- ── CC EN EL RETRATO ──
	-- Icono del CC tapando el retrato, el reloj que gira y los segundos.
	-- El reloj lleva noCooldownCount: los segundos los pone este modulo y
	-- OmniCC no tiene que poner otro numero encima.
	local pfr = petFrame.portraitFrame
	petFrame.ccIcon = pfr:CreateTexture(nil, "OVERLAY")
	petFrame.ccIcon:SetAllPoints(petFrame.portraitIcon)
	petFrame.ccIcon:Hide()

	local ccCD = CreateFrame("Cooldown", nil, pfr)
	ccCD:SetAllPoints(pfr)
	ccCD:SetReverse(true)   -- igual que los buffs y debuffs
	ccCD.noCooldownCount = true
	ccCD.noOCC = true
	ccCD:Hide()
	petFrame.ccCD = ccCD

	local ccOv = CreateFrame("Frame", nil, pfr)
	ccOv:SetAllPoints(pfr)
	ccOv:SetFrameLevel(ccCD:GetFrameLevel() + 2)
	ccOv.text = ccOv:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	ccOv.text:SetPoint("CENTER", ccOv, "CENTER", 0, 0)
	ccOv.pf = petFrame
	ccOv:SetScript("OnUpdate", CCText_OnUpdate)
	ccOv:Hide()
	petFrame.ccOverlay = ccOv

	-- Aro rojo alrededor del retrato mientras dura el CC. Antes era el
	-- brillo de las casillas estirado a todo el marco (160x80), y igual no
	-- se veia nunca: la deteccion no funcionaba.
	petFrame.ccGlow = pfr:CreateTexture(nil, "OVERLAY")
	petFrame.ccGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	petFrame.ccGlow:SetBlendMode("ADD")
	petFrame.ccGlow:SetVertexColor(1, 0.15, 0.15)
	petFrame.ccGlow:SetPoint("CENTER", pfr, "CENTER", 0, 0)
	petFrame.ccGlow:SetSize(76, 76)
	petFrame.ccGlow:Hide()

	-- Nombre
	petFrame.name = petFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	petFrame.name:SetPoint("TOPLEFT", 65, -10)

	-- Vida
	petFrame.healthBar = CreateFrame("StatusBar", nil, petFrame)
	petFrame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	petFrame.healthBar:SetSize(85, 24)
	petFrame.healthBar:SetPoint("TOPLEFT", 60, -10)
	petFrame.healthBar:SetStatusBarColor(0, 1, 0)
	petFrame.healthBar:SetFrameLevel(0)

	-- Mana / Rage / Focus / Energy
	petFrame.manaBar = CreateFrame("StatusBar", nil, petFrame)
	petFrame.manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	petFrame.manaBar:SetSize(85, 10)
	petFrame.manaBar:SetPoint("TOPLEFT", petFrame.healthBar, "BOTTOMLEFT", 0, -4)
	petFrame.manaBar:SetFrameLevel(0)

	-- Debuffs (28 px, en fila a la derecha de la vida) y buffs (24 px,
	-- arriba del retrato; los coloca PlaceBuff). 6 px entre uno y otro:
	-- con 4 los bordes de dos debuffs quedaban pegados.
	petFrame.debuffs = {}
	for n = 1, 8 do
		local icon = MakeAuraIcon(petFrame, 28)
		if n == 1 then
			icon:SetPoint("LEFT", petFrame.healthBar, "RIGHT", 6, 0)
		else
			icon:SetPoint("LEFT", petFrame.debuffs[n-1], "RIGHT", 6, 0)
		end
		petFrame.debuffs[n] = icon
	end
	petFrame.buffs = {}
	for n = 1, 8 do
		petFrame.buffs[n] = MakeAuraIcon(petFrame, 24)
	end

	-- Castbar
	local castBar = CreateFrame("StatusBar", nil, petFrame)
	castBar:SetSize(110, 14)
	castBar:SetPoint("TOPLEFT", petFrame.manaBar, "BOTTOMLEFT", 0, -4)
	castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	castBar:SetStatusBarColor(1, 0.7, 0.2)
	castBar:Hide()
	petFrame.castBar = castBar

	-- El borde de barra de casteo de Blizzard media 138x54 sobre una barra de
	-- 110x14: un marco enorme y desalineado alrededor de una barrita. Fuera.
	-- La barra se lee sola por su fondo, igual que las de arena.
	local castBarBG = castBar:CreateTexture(nil, "BACKGROUND")
	castBarBG:SetTexture("Interface\\Buttons\\WHITE8X8")
	castBarBG:SetPoint("TOPLEFT", castBar, "TOPLEFT", -1, 1)
	castBarBG:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 1, -1)
	castBarBG:SetVertexColor(0, 0, 0, 0.7)

	-- Icono del hechizo, a la izquierda y por fuera de la barra.
	castBar.icon = castBar:CreateTexture(nil, "ARTWORK")
	castBar.icon:SetSize(14, 14)
	castBar.icon:SetPoint("RIGHT", castBar, "LEFT", -3, 0)
	castBar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)   -- sin el borde del icono

	local spark = castBar:CreateTexture(nil, "OVERLAY")
	spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	spark:SetBlendMode("ADD")
	spark:SetSize(24, 24)
	spark:SetPoint("CENTER", castBar:GetStatusBarTexture(), "RIGHT", 0, 0)
	castBar.spark = spark

	castBar.text = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	castBar.text:SetPoint("LEFT", castBar, "LEFT", 4, 0)
	castBar.text:SetJustifyH("LEFT")

	-- Segundos que faltan, contando hacia abajo.
	castBar.timeText = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	castBar.timeText:SetPoint("RIGHT", castBar, "RIGHT", -4, 0)
	castBar.timeText:SetJustifyH("RIGHT")

	-- ---------------------------------------------------------
	-- La barra se anima sola
	--
	-- Antes el valor lo movia el OnUpdate del marco, cada 0.1 s, asi que
	-- avanzaba a los saltos. Ahora la barra tiene su propio OnUpdate y
	-- recalcula en cada cuadro a partir de startTime y endTime, que es como
	-- lo hace la barra de casteo del juego.
	-- ---------------------------------------------------------
	castBar:SetScript("OnUpdate", function(self)
		if not self.endTime then return end
		local now = GetTime()
		if now >= self.endTime then
			self.endTime = nil
			self:Hide()
			return
		end
		if self.isChannel then
			-- Canalizar VACIA la barra: el valor va de endTime hacia startTime.
			self:SetValue(self.startTime + self.endTime - now)
		else
			self:SetValue(now)
		end
		self.timeText:SetFormattedText("%.1f", self.endTime - now)   -- sin basura
	end)

	return petFrame
end

-- ---------------------------------------------------------
-- COLOCAR LA PILA
--
-- El 1 va donde lo dejo el usuario; del 2 al 4 cuelgan del de arriba.
-- Anclarlos en cadena y no cada uno a UIParent es a proposito: mover el
-- primero mueve el bloque entero, y no hay forma de que se desalineen.
-- ---------------------------------------------------------
local function PPF_Layout()
	if InCombatLockdown() then return end     -- marcos protegidos
	local pos = PPF_DB()
	local f1 = petFrames[1]
	if not f1 then return end

	f1:ClearAllPoints()
	f1:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER",
		pos.x or DEF_X, pos.y or DEF_Y)

	for i = 2, NUM_PETS do
		local f = petFrames[i]
		if f then
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", petFrames[i-1], "BOTTOMLEFT", 0, -STACK_GAP)
		end
	end
end

local function PPF_SavePosition()
	local f1 = petFrames[1]
	if not f1 then return end
	local point, rel, relPoint, x, y = f1:GetPoint(1)
	if not point then return end
	-- Se guarda el punto SOLO si esta colgado de UIParent, que es de donde
	-- lo cuelga PPF_Layout. Si algun dia otro sistema lo reanclara a un
	-- tercer marco, guardar esas coordenadas y despues reponerlas contra
	-- UIParent lo mandaria a cualquier lado -- el clasico "lo movi dos
	-- pixeles y aparecio en la otra punta". Mejor no guardar nada.
	if rel and rel ~= UIParent then return end
	local pos = PPF_DB()
	pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
end

-- ---------------------------------------------------------
-- Arrastre: solo el marco 1.
--
-- StartMoving sobre un marco protegido en combate contamina, asi que el
-- arrastre se corta ahi mismo en vez de dejar que el cliente lo rechace.
-- ---------------------------------------------------------
local function PPF_MakeDraggable(f)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		-- Con la vista previa siempre se puede arrastrar (es para eso).
		if PPF_Opts().locked and not previewOn then return end
		if InCombatLockdown() then return end
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		PPF_SavePosition()
		PPF_Layout()          -- reanclar a UIParent con numeros limpios
	end)
end

for i = 1, NUM_PETS do
	petFrames[i] = PPF_Build(i)
end
PPF_MakeDraggable(petFrames[1])
PPF_Layout()

-- =========================================================
-- ACTUALIZACION
-- =========================================================
-- Colores fijos afuera: antes se creaban estas tablas en CADA
-- actualizacion (diez veces por segundo por marco), pura basura.
local POWER_COLORS = {
    [0] = {0, 0, 1},
    [1] = {1, 0, 0},
    [2] = {1, 0.5, 0},
    [3] = {1, 1, 0},
    [6] = {0, 0.8, 1},
}
local DEFAULT_POWER = {0, 0, 1}
local FADE_ALPHA = 0.45           -- "Atenuar fuera de rango"

-- El primer buff va arriba del retrato; el resto en fila.
local function PlaceBuff(pf, n)
    local icon = pf.buffs[n]
    icon:ClearAllPoints()
    if n == 1 then
        icon:SetPoint("TOPLEFT", pf.portraitFrame, "TOPRIGHT", 8, 30)
    else
        icon:SetPoint("LEFT", pf.buffs[n-1], "RIGHT", 5, 0)
    end
end

local function UpdatePetFrame(pf)
    if previewOn then return end      -- la vista previa tiene sus datos
    local unit = pf.unit
    local o = PPF_Opts()
    -- Ni Show() ni Hide() aca: de mostrar y ocultar se encarga el unit
    -- watch, o PPF_ApplyVisibility fuera de combate si no lo hubiera.
    if not UnitExists(unit) then
        if not PPF_HasUnitWatch then PPF_ApplyVisibility(PPF_WantVisible) end
        return
    end
    if not PPF_HasUnitWatch then PPF_ApplyVisibility(PPF_WantVisible) end
    SetPortraitTexture(pf.portraitIcon, unit)
    pf.name:SetText(UnitName(unit) or "Mascota")

    local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
    pf.healthBar:SetMinMaxValues(0, hpMax)
    pf.healthBar:SetValue(hp)
    if o.ownerColor then
        local _, class = UnitClass(pf.owner)
        pf.healthBar:SetStatusBarColor(OwnerColor(class))
    else
        pf.healthBar:SetStatusBarColor(0, 1, 0)
    end

    -- Lejos: semitransparente. SetAlpha si se puede en combate.
    pf:SetAlpha((o.rangeFade and not PetInRange(pf)) and FADE_ALPHA or 1)

    local powerType = UnitPowerType(unit)
    local power, powerMax = UnitPower(unit), UnitPowerMax(unit)
    pf.manaBar:SetMinMaxValues(0, powerMax)
    pf.manaBar:SetValue(power)

    pf.manaBar:SetStatusBarColor(unpack(POWER_COLORS[powerType] or DEFAULT_POWER))

    -- Buffs (todos menos el ruido de hiddenAuras)
    local buffIndex = 1
    for i = 1, (o.showBuffs and 16 or 0) do
        local name, _, texture, count, _, duration, expires = UnitBuff(unit, i)
        if not name then break end
        if not hiddenAuras[name] then
            local icon = pf.buffs[buffIndex]
            -- El pool son 8 iconos y este bucle recorre hasta 16 buffs.
            if not icon then break end
            PlaceBuff(pf, buffIndex)
            ShowAura(icon, o, texture, count, duration, expires)
            buffIndex = buffIndex + 1
        end
    end
    for j = buffIndex, #pf.buffs do HideAura(pf.buffs[j]) end

    -- Debuffs, con el color de su escuela (y el brillo si lo podes sacar)
    for i = 1, 8 do
        local icon = pf.debuffs[i]
        local name, _, texture, count, debuffType, duration, expires
        if o.showDebuffs then
            name, _, texture, count, debuffType, duration, expires = UnitDebuff(unit, i)
        end
        if name then
            local col = (debuffType and DEBUFF_COLORS[debuffType]) or DEBUFF_NONE
            local glow = o.dispelGlow and debuffType and CAN_DISPEL[debuffType]
            ShowAura(icon, o, texture, count, duration, expires, col, glow)
        else
            HideAura(icon)
        end
    end

    -- CC en el retrato (y el aro rojo)
    SetCCPortrait(pf, FindCC(unit))

	ApplyPetLortiTint(pf);
end

-- Castbar
local function UpdateCastBar(pf)
    if previewOn then return end
    local unit    = pf.unit
    local castBar = pf.castBar
    if not PPF_Opts().showCast then
        castBar.endTime = nil
        castBar:Hide()
        return
    end
    -- OJO CON EL ORDEN DE LOS RETORNOS.
    --
    -- Aca habia un bug que dejaba la barra invisible SIEMPRE: se leia
    -- startTime en la cuarta posicion, que es la TEXTURA. Como es un
    -- string, el "type(startTime) == number" de mas abajo daba falso y la
    -- barra se ocultaba siempre, tanto casteando como canalizando.
    --
    -- En 3.3.5a el orden es:
    --   UnitCastingInfo  name, nameSubtext, text, texture, startTime,
    --                    endTime, isTradeSkill, castID, notInterruptible
    --   UnitChannelInfo  lo mismo pero SIN castID
    --
    -- Se nombran todos, como en PartyCastingBars, para que no vuelva a
    -- correrse un lugar sin que nadie lo note.
    local name, nameSubtext, text, texture, startTime, endTime,
          isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    local isChannel = false
    if not name then
        name, nameSubtext, text, texture, startTime, endTime,
            isTradeSkill, notInterruptible = UnitChannelInfo(unit)
        isChannel = true
    end

    if name and type(startTime) == "number" and type(endTime) == "number" then
        -- Los tiempos vienen en milisegundos; adentro se trabaja en segundos.
        castBar.startTime = startTime / 1000
        castBar.endTime   = endTime / 1000
        castBar.isChannel = isChannel
        -- El minimo y el maximo son SIEMPRE start y end, en ese orden, para
        -- las dos formas. Lo que cambia es el valor, y de eso se ocupa el
        -- OnUpdate. Antes se invertian para canalizar y la barra no corria.
        castBar:SetMinMaxValues(castBar.startTime, castBar.endTime)
        castBar.text:SetText(name)
        if castBar.icon then
            castBar.icon:SetTexture(texture)
            if texture then castBar.icon:Show() else castBar.icon:Hide() end
        end
        castBar:SetStatusBarColor(notInterruptible and 1 or 0.7, notInterruptible and 0.3 or 0.7, notInterruptible and 0.3 or 0.2)
        castBar:Show()
    else
        castBar.endTime = nil
        castBar:Hide()
    end
end

local function UpdateAll()
    for i = 1, NUM_PETS do
        local pf = petFrames[i]
        if pf then
            UpdatePetFrame(pf)
            UpdateCastBar(pf)
        end
    end
end

-- ---------------------------------------------------------
-- UN SOLO OnUpdate PARA LOS CUATRO
--
-- El original colgaba el OnUpdate del propio marco. Con cuatro marcos eso
-- serian cuatro temporizadores desfasados entre si haciendo lo mismo. Va
-- uno solo en el frame de eventos, que ademas solo existe con el modulo
-- prendido.
--
-- Y ademas: SOLO los marcos que estan a la vista. Repasar retratos, auras
-- y barras de una mascota que no existe, diez veces por segundo, es
-- trabajo puro al pedo -- y con el modo arena, fuera de arena, seria el
-- 100% del tiempo.
-- ---------------------------------------------------------
local timeSinceLastUpdate = 0
local function PPF_OnUpdate(self, elapsed)
    if previewOn then return end
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate < 0.1 then return end
    timeSinceLastUpdate = 0
    for i = 1, NUM_PETS do
        local pf = petFrames[i]
        if pf and pf:IsShown() then
            UpdatePetFrame(pf)
            UpdateCastBar(pf)
        end
    end
end

-- Eventos
-- OJO: UNIT_POWER_UPDATE es de retail. En 3.3.5a el recurso se avisa con
-- un evento por tipo; se registran todos para cubrir cualquier mascota.
--
-- Los eventos NO se registran al cargar: los engancha el modulo al
-- prenderse (ver el final del archivo). Asi, apagado, no escucha nada.
local PPF_EVENTS = { "UNIT_HEALTH", "UNIT_MANA", "UNIT_MAXMANA", "UNIT_FOCUS", "UNIT_ENERGY", "UNIT_RAGE", "UNIT_HAPPINESS", "UNIT_PET", "PLAYER_ENTERING_WORLD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_DELAYED", "UNIT_AURA", "GROUP_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_BATTLEGROUND", "PLAYER_LEAVING_BATTLEGROUND", "INSTANCE_GROUP_SIZE_CHANGED", "UPDATE_INSTANCE_INFO" };

-- "party3pet" -> el marco 3. Nil si el evento vino de cualquier otra cosa,
-- que es lo normal: UNIT_AURA y UNIT_HEALTH llegan para TODA unidad que se
-- mueva en pantalla, y sin este filtro repintariamos los cuatro marcos por
-- cada tick de veneno de un bicho al otro lado del mapa.
local function PetFrameFor(unitID)
    if type(unitID) ~= "string" then return nil end
    local n = string.match(unitID, "^party(%d)pet$")
    if not n then return nil end
    return petFrames[tonumber(n)]
end

-- Y el mismo filtro para el dueno: UNIT_PET llega como "party2".
local function PetFrameForOwner(unitID)
    if type(unitID) ~= "string" then return nil end
    local n = string.match(unitID, "^party(%d)$")
    if not n then return nil end
    return petFrames[tonumber(n)]
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        -- La zona pudo cambiar: volver a decidir si se ven o no.
        PPF_ApplyVisibility(PPF_WantVisible)
        UpdateAll()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_LEAVING_BATTLEGROUND" or event == "INSTANCE_GROUP_SIZE_CHANGED" or event == "UPDATE_INSTANCE_INFO" then
        -- Forzar actualización después de cambios de zona/instancia.
        -- El medio segundo es porque al cruzar el portal de la arena el
        -- cliente todavia reporta la zona vieja durante unos cuadros.
        TimerAfter(0.5, function()
            PPF_ApplyVisibility(PPF_WantVisible)
            UpdateAll()
        end)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        UpdateAll()
    elseif event == "UNIT_PET" then
        local pf = PetFrameForOwner(arg1)
        if pf then UpdatePetFrame(pf) end
    elseif event == "UNIT_AURA"
        or event == "UNIT_HEALTH" or event == "UNIT_MANA" or event == "UNIT_MAXMANA"
        or event == "UNIT_FOCUS" or event == "UNIT_ENERGY" or event == "UNIT_RAGE"
        or event == "UNIT_HAPPINESS" then
        local pf = PetFrameFor(arg1)
        if pf then UpdatePetFrame(pf) end
    elseif string.find(event, "UNIT_SPELLCAST") then
        local pf = PetFrameFor(arg1)
        if pf then UpdateCastBar(pf) end
    end
end)

-- Funciones de configuración
local function ToggleLock()
    local o = PPF_Opts()
    o.locked = not o.locked
    if InCombatLockdown() then return end   -- marcos protegidos

    for i = 1, NUM_PETS do
        local f = petFrames[i]
        if f then
            if o.locked then
                f:EnableMouse(o.clickable)
                f.lockIndicator:Show()
            else
                f:EnableMouse(true)
                f.lockIndicator:Hide()
            end
        end
    end
    -- Solo el 1 se mueve, asi que solo el 1 cambia de movible.
    petFrames[1]:SetMovable(not o.locked)

    -- Sin aviso por chat: el indicador de bloqueo ya lo muestra.
end

-- Aplica "click para seleccionar" y el bloqueo guardados (fuera de
-- combate: son marcos protegidos).
local function PPF_ApplyClickable()
    if InCombatLockdown() then return end
    local o = PPF_Opts()
    for i = 1, NUM_PETS do
        local f = petFrames[i]
        if f then
            if o.clickable then
                f:SetAttribute("type1", "target")
            else
                f:SetAttribute("type1", nil)
            end
            if o.locked then f:EnableMouse(o.clickable) else f:EnableMouse(true) end
            if o.locked then f.lockIndicator:Show() else f.lockIndicator:Hide() end
        end
    end
    petFrames[1]:SetMovable(not o.locked)
end

local function ToggleClickable()
    local o = PPF_Opts()
    o.clickable = not o.clickable
    PPF_ApplyClickable()

    if o.clickable then
        print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_CLICK_ON"] or "Click enabled - click to target the pet"))
    else
        print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_CLICK_OFF"] or "Click disabled"))
    end
end

local function ResetPosition()
    local pos = PPF_DB()
    pos.point, pos.relPoint, pos.x, pos.y = "CENTER", "CENTER", DEF_X, DEF_Y
    PPF_Layout()
end

-- Comandos slash
SLASH_PARTYPETFRAME1 = "/ppf"
SLASH_PARTYPETFRAME2 = "/partypetframe"
SlashCmdList["PARTYPETFRAME"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "lock" or msg == "bloquear" then
        ToggleLock()
    elseif msg == "click" or msg == "clic" then
        ToggleClickable()
    elseif msg == "arena" then
        -- Alterna entre "solo Arena" y "en todos lados" (la grilla del panel).
        local on = not PPF_ArenaOnly()
        local o = PPF_Opts()
        o.inArena = true
        o.inBG, o.inWorld = not on, not on
        PPF_ApplyVisibility(PPF_WantVisible)
        if on then
            print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_ARENA_ONLY"] or "Arenas only"))
        else
            print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_EVERYWHERE"] or "Everywhere"))
        end
    elseif msg == "reset" then
        ResetPosition()
        print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_POS_RESET"] or "Position reset"))
    else
        print("|cff00ff00[PartyPetFrame] " .. (L["CMD_COMMANDS_TITLE"] or "Commands:") .. "|r")
        print("  /ppf lock - " .. (L["PPF_HELP_LOCK"] or "Lock/unlock the row"))
        print("  /ppf click - " .. (L["PPF_HELP_CLICK"] or "Enable/disable click to target"))
        print("  /ppf arena - " .. (L["PPF_HELP_ARENA"] or "Switch between arenas only and everywhere"))
        print("  /ppf reset - " .. (L["PPF_HELP_RESET"] or "Reset the row position"))
        print("  |cff8A8A8A" .. (L["PPF_HELP_DRAG"] or "Drag the top frame: the other three follow it.") .. "|r")
    end
end

-- =========================================================
-- INTEGRACION NUF
-- =========================================================
-- =========================================================
-- VISTA PREVIA
--
-- Los cuatro marcos con datos de mentira, para ubicarlos y ver las
-- opciones sin estar en una arena. Mientras esta puesta la fila se puede
-- arrastrar aunque este bloqueada. Solo fuera de combate (son marcos
-- protegidos), y se saca sola al entrar en combate.
-- =========================================================
-- owner = la clase del dueno de mentira (para "Color de clase del dueno").
-- debuffs = { spellID, escuela, duracion, acumulaciones }. La mascota 4
-- hace de "lejos" (se ve atenuada si esa opcion esta tildada).
local PREVIEW = {
	{ icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf", owner = "HUNTER", cc = 118, ccLen = 8 },  -- Polimorfia
	{ icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter", owner = "WARLOCK", cast = 19647,      -- Bloqueo de hechizo
	  debuffs = { { 980, "Curse", 24 } } },                                                           -- Agonia
	{ icon = "Interface\\Icons\\Spell_Shadow_AnimateDead", owner = "DEATHKNIGHT",
	  debuffs = { { 172, "Magic", 18 }, { 2818, "Poison", 12, 3 } } },                                 -- Corrupcion, Veneno mortal
	{ icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2", owner = "MAGE", far = true },
}
local PREVIEW_BUFFS = {
	{ "Interface\\Icons\\Spell_Holy_WordFortitude", 1800 },
	{ "Interface\\Icons\\Spell_Nature_Rejuvenation", 15 },
}

local function FillPreview(pf, i)
	local p, o = PREVIEW[i], PPF_Opts()
	local now = GetTime()
	pf.portraitIcon:SetTexture(p.icon)
	pf.name:SetText((L["PPF_PREVIEW_PET"] or "Pet") .. " " .. i)
	pf.healthBar:SetMinMaxValues(0, 100); pf.healthBar:SetValue(90 - i * 12)
	if o.ownerColor then pf.healthBar:SetStatusBarColor(OwnerColor(p.owner))
	else pf.healthBar:SetStatusBarColor(0, 1, 0) end
	pf.manaBar:SetMinMaxValues(0, 100); pf.manaBar:SetValue(70)
	pf.manaBar:SetStatusBarColor(0, 0, 1)
	pf:SetAlpha((o.rangeFade and p.far) and FADE_ALPHA or 1)
	for n = 1, #pf.buffs do
		local icon, b = pf.buffs[n], PREVIEW_BUFFS[n]
		if o.showBuffs and b then
			PlaceBuff(pf, n)
			icon.cd.nufExp = nil
			ShowAura(icon, o, b[1], nil, b[2], now + b[2] - n * 3, nil, nil, b[2])
		else
			HideAura(icon)
		end
	end
	for n = 1, #pf.debuffs do
		local icon, d = pf.debuffs[n], o.showDebuffs and p.debuffs and p.debuffs[n]
		local tex = d and select(3, GetSpellInfo(d[1]))
		if tex then
			icon.cd.nufExp = nil
			local glow = o.dispelGlow and CAN_DISPEL[d[2]]
			ShowAura(icon, o, tex, d[4], d[3], now + d[3] - n * 2, DEBUFF_COLORS[d[2]], glow, d[3])
		else
			HideAura(icon)
		end
	end
	local cb = pf.castBar
	cb.endTime = nil
	if o.showCast and p.cast then
		local name, _, tex = GetSpellInfo(p.cast)
		cb:SetMinMaxValues(0, 1); cb:SetValue(0.6)
		cb.text:SetText(name or ""); cb.timeText:SetText("0.8")
		if tex then cb.icon:SetTexture(tex); cb.icon:Show() end
		cb:SetStatusBarColor(0.7, 0.7, 0.2)
		cb:Show()
	else
		cb:Hide()
	end
	if p.cc then
		local tex = select(3, GetSpellInfo(p.cc))
		local now = GetTime()
		pf.ccCD.nufExp = nil
		SetCCPortrait(pf, tex, p.ccLen, now + p.ccLen, p.ccLen)
	else
		SetCCPortrait(pf, nil)
	end
	ApplyPetLortiTint(pf)
end

local previewWatch = CreateFrame("Frame")
local PPF_SetPreview
local previewAcc = 0
local function PreviewTick(self, elapsed)
	previewAcc = previewAcc + elapsed
	if previewAcc < 0.1 then return end
	previewAcc = 0
	local now = GetTime()
	for i = 1, NUM_PETS do
		local pf = petFrames[i]
		for n = 1, #pf.buffs do UpdateAuraTime(pf.buffs[n], now) end
		for n = 1, #pf.debuffs do UpdateAuraTime(pf.debuffs[n], now) end
	end
end
previewWatch:SetScript("OnEvent", function()
	-- PLAYER_REGEN_DISABLED llega justo ANTES del bloqueo de combate: todavia
	-- se pueden esconder los marcos protegidos.
	if previewOn then PPF_SetPreview(false) end
end)

function PPF_SetPreview(on)
	on = on and true or false
	if InCombatLockdown() then return previewOn end
	if on == previewOn then return previewOn end
	if on then
		previewOn = true
		for i = 1, NUM_PETS do
			local f = petFrames[i]
			if f.ppfWatching then
				UnregisterUnitWatch(f)
				f.ppfWatching = false
			end
			FillPreview(f, i)
			f:Show()
		end
		previewWatch:RegisterEvent("PLAYER_REGEN_DISABLED")
		previewWatch:SetScript("OnUpdate", PreviewTick)
	else
		previewOn = false
		previewWatch:UnregisterEvent("PLAYER_REGEN_DISABLED")
		previewWatch:SetScript("OnUpdate", nil)
		for i = 1, NUM_PETS do
			local f = petFrames[i]
			f:Hide()
			f:SetAlpha(1)
			f.castBar:Hide()
			SetCCPortrait(f, nil)
			for n = 1, #f.buffs do HideAura(f.buffs[n]) end
			for n = 1, #f.debuffs do HideAura(f.debuffs[n]) end
		end
		PPF_ApplyVisibility(PPF_WantVisible)
		UpdateAll()
	end
	return previewOn
end

-- ---------- API para el panel ----------
function K.GetPartyPetOption(key)
	return PPF_Opts()[key]
end

function K.SetPartyPetOption(key, v)
	local o = PPF_Opts()
	if key == "borderStyle" then
		if not BORDER_STYLES[v] then return end
		o.borderStyle = v
	else
		o[key] = v and true or false
	end
	if key == "clickable" or key == "locked" then PPF_ApplyClickable() end
	if key == "rangeFade" and not o.rangeFade then
		for i = 1, NUM_PETS do petFrames[i]:SetAlpha(1) end
	end
	if previewOn then
		for i = 1, NUM_PETS do FillPreview(petFrames[i], i) end
	else
		UpdateAll()
	end
end

-- Si tu clase saca algun tipo de debuff (para la casilla del panel).
function K.PartyPetCanDispel()
	return next(CAN_DISPEL) ~= nil
end

function K.TogglePartyPetPreview()
	return PPF_SetPreview(not previewOn)
end

function K.IsPartyPetPreview()
	return previewOn
end

-- Donde se muestra: la grilla del panel (K.GetModuleZone / SetModuleZone).
if K.RegisterModuleZones then
	K.RegisterModuleZones("PartyPetFrame", PPF_Opts, function()
		PPF_ApplyVisibility(PPF_WantVisible)
	end)
end

-- Tamaño: el slider de escala del panel (los cuatro marcos juntos).
if K.RegisterScalable then
	K.RegisterScalable("PartyPetFrame", petFrames, 1.0)
end

local function PPF_SetEnabled(on)
    if on then
        for _, e in ipairs(PPF_EVENTS) do pcall(frame.RegisterEvent, frame, e) end
        frame:SetScript("OnUpdate", PPF_OnUpdate)
        PPF_Layout()
        PPF_ApplyClickable()
        PPF_ApplyVisibility(true)
        UpdateAll()
    else
        PPF_SetPreview(false)
        frame:UnregisterAllEvents()
        frame:SetScript("OnUpdate", nil)
        PPF_ApplyVisibility(false)
    end
end

function K.TogglePartyPetFrameLock()
    ToggleLock()
end

function K.ResetPartyPetFramePosition()
    ResetPosition()
end

-- Que el rearmado general (cambio de modo de barras, reset) vuelva a
-- colocar la fila donde el usuario la dejo.
if K.LayoutRegisterStore then
    K.LayoutRegisterStore("PartyPetFrames", function()
        PPF_Layout()
    end)
end

K.RegisterModule("PartyPetFrame", {
    name    = L["MOD_PARTYPETFRAME"] or "Party pet enhanced",
    desc    = L["MOD_PARTYPETFRAME_DESC"]
        or "Custom frames for your party members' pets (party 1-4): portrait with the CC they get, health/mana, buffs, debuffs and cast bar. /ppf for commands.",
    default = false,
    hideFromModulesTab = true,   -- vive en Frames > Party
    onEnable  = function() PPF_SetEnabled(true) end,
    onDisable = function() PPF_SetEnabled(false) end,
});
