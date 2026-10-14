local AddOnName, ns = ...
local K = ns[1]
local L = ns[3]   -- tabla de traducciones

local cfg = CreateFrame("Frame")
local kill = function() end
local initialized = false

local function SubOpt(key)
	local C = ns[2]
	if C[key] == nil then return true end
	return C[key]
end

local function ModuleOn()
	return not (K.IsModuleEnabled and not K.IsModuleEnabled("LortiUI"))
end

-- =============================================
-- LAS ZONAS DE LORTI
--
-- Cada parte que Lorti puede tocar es UNA zona, con dos casillas:
--
--   on     "Lorti": la oscurece (o le da el estilo, en botones y auras)
--   color  "Color": en vez de negro, tu color. Solo cuenta con "Lorti"
--          tildada: el color es de la zona oscurecida, no aparte.
--
-- Claves: <on>, y LortiUI_<color>Color + LortiUI_<color>R/G/B.
--
-- Antes habia una lista de casillas a la izquierda y un recuadro de color
-- a la derecha con los mismos nombres repetidos ("Party" y "Party",
-- "Minimap" y "Minimap"...) y un "Custom color" general que pintaba unas
-- zonas si y otras no. Ahora cada zona aparece una sola vez y lleva su
-- propio color. Lo viejo se convierte solo (ver MigrateLayout).
-- =============================================
local ZONES = {
	Player       = { on = "LortiUI_Player",       color = "Player"       },
	Target       = { on = "LortiUI_Target",       color = "Target"       },
	Focus        = { on = "LortiUI_Focus",        color = "Focus"        },
	Party        = { on = "LortiUI_Party",        color = "Party"        },
	PartyTargets = { on = "LortiUI_PartyTargets", color = "PartyTargets" },
	PartyPet     = { on = "LortiUI_PartyPet",     color = "PartyPet"     },
	Arena        = { on = "LortiUI_Arena",        color = "Arena"        },
	CastBar      = { on = "LortiUI_CastBar",      color = "CastBar"      },
	ActionBars   = { on = "LortiUI_ActionBars",   color = "ActionBars"   },
	Minimap      = { on = "LortiUI_Minimap",      color = "Minimap"      },
	Buffs        = { on = "LortiUI_AuraBuffs",    color = "Buff"         },
	Debuffs      = { on = "LortiUI_AuraDebuffs",  color = "Debuff"       },
}
local ZONE_ORDER = { "Player", "Target", "Focus", "Party", "PartyTargets", "PartyPet", "Arena", "CastBar",
	"ActionBars", "Minimap", "Buffs", "Debuffs" }

-- Las llamadas viejas (PlayerFrame, TargetFrame, grupo, arena...) piden el
-- tono con la clave de su casilla de antes. Se traduce a la zona.
local KEY_TO_ZONE = {
	LortiUI_PlayerTargetFocus = "Player",
	LortiUI_Party             = "Party",
	LortiUI_PartyTargets      = "PartyTargets",
	LortiUI_PartyPet          = "PartyPet",
	LortiUI_Arena             = "Arena",
}

local DEFAULT_COLOR = { 0.40, 0.82, 1.0 };   -- el celeste del Lorti UI suelto

local function Clamp01(v, def)
	v = tonumber(v);
	if not v then return def; end
	if v < 0 then return 0; end
	if v > 1 then return 1; end
	return v;
end

-- =============================================
-- CONVERSION DE LA CONFIG VIEJA (una sola vez por perfil)
--
-- La llama ConfigManager justo ANTES de avisar CONFIG_LOADED, asi ningun
-- modulo llega a leer las claves nuevas sin convertir.
--
--   "Player / Target / Focus"  -> Jugador, Objetivo, Foco y Barras de
--                                 casteo (las cuatro iban con esa casilla)
--   "Buffs / Debuffs"          -> Tus buffs y Tus debuffs
--   "Custom color" general     -> el color de cada zona que lo seguia
--                                 (todas menos minimapa y auras), salvo
--                                 las que ya tenian el suyo
--   filas de color de marcos   -> andaban sin su casilla; ahora el color
--                                 va con la zona prendida, asi que se
--                                 prende la zona para que se vea igual
--
-- Nada cambia de color al actualizar.
-- =============================================
function K.LortiMigrateLayout()
	local C = ns[2]
	if not C or C.LortiUI_Layout2 == true then return end
	local DB = NidhausUnitFramesDB
	local function set(k, v)
		C[k] = v
		if DB then DB[k] = v end
	end
	local ptf = (C.LortiUI_PlayerTargetFocus ~= false)
	for _, z in ipairs({ "Player", "Target", "Focus", "CastBar" }) do set("LortiUI_" .. z, ptf) end
	local auras = (C.LortiUI_Auras == true)
	set("LortiUI_AuraBuffs", auras)
	set("LortiUI_AuraDebuffs", auras)
	if C.LortiUI_CustomColor == true then
		local r = Clamp01(C.LortiUI_ColorR, DEFAULT_COLOR[1])
		local g = Clamp01(C.LortiUI_ColorG, DEFAULT_COLOR[2])
		local b = Clamp01(C.LortiUI_ColorB, DEFAULT_COLOR[3])
		for _, p in ipairs({ "Player", "Target", "Focus", "Party", "PartyTargets", "PartyPet", "Arena", "CastBar", "ActionBars" }) do
			if C["LortiUI_" .. p .. "Color"] ~= true then
				set("LortiUI_" .. p .. "Color", true)
				set("LortiUI_" .. p .. "R", r)
				set("LortiUI_" .. p .. "G", g)
				set("LortiUI_" .. p .. "B", b)
			end
		end
		set("LortiUI_CustomColor", false)
	end
	for _, z in ipairs({ "Player", "Target", "Focus", "Party", "CastBar" }) do
		if C["LortiUI_" .. z .. "Color"] == true then set(ZONES[z].on, true) end
	end
	set("LortiUI_Layout2", true)
end

-- =============================================
-- EL TONO DE CADA ZONA (lo piden todos los estilos de NUF)
-- =============================================
function K.LortiZoneOn(zone)
	local Z = ZONES[zone]
	if not Z or not ModuleOn() then return false end
	return SubOpt(Z.on) and true or false
end

-- r, g, b de la zona si tiene "Lorti" y "Color" tildadas; si no, nil.
function K.LortiZoneColor(zone)
	if not K.LortiZoneOn(zone) then return nil end
	local C = ns[2]
	local p = "LortiUI_" .. ZONES[zone].color
	if C[p .. "Color"] ~= true then return nil end
	return Clamp01(C[p .. "R"], DEFAULT_COLOR[1]),
	       Clamp01(C[p .. "G"], DEFAULT_COLOR[2]),
	       Clamp01(C[p .. "B"], DEFAULT_COLOR[3])
end

-- El tono para teñir: nil si la zona esta apagada; si no, su color (por
-- la proporcion de esa parte) o el gris oscuro de siempre.
--
--   marcos / grupo           0.05   color x 1.0
--   arena                    0.10   color x 1.0
--   barras de accion         0.20   color x 0.6
--   puntas de la barra       0.35   color x 0.8
function K.LortiZoneTint(zone, dark, mult)
	if not K.LortiZoneOn(zone) then return nil end
	local r, g, b = K.LortiZoneColor(zone)
	mult = mult or 1
	if r then return r * mult, g * mult, b * mult end
	dark = dark or 0.05
	return dark, dark, dark
end

-- Compatibilidad: (clave de casilla vieja, fila). La fila manda.
function K.LortiTint(key, part)
	local zone = part or KEY_TO_ZONE[key] or "Player"
	return K.LortiZoneTint(zone, (zone == "Arena") and 0.1 or 0.05, 1)
end

-- =============================================
-- TEÑIR UNA TEXTURA
--
-- Un solo camino: el mismo SetVertexColor que Lorti le aplica al arte de
-- Blizzard. Devuelve true si tiño y false si Lorti esta apagado, para que
-- el llamador sepa si tiene que reponer el blanco.
--
-- NOTA PARA EL FUTURO: hubo un intento de desaturar la textura antes de
-- oscurecerla, partiendo de que multiplicar un arte "de color" daba un
-- tono raro. Medi las texturas y NO ES ASI: Light promedia R93 G89 B70,
-- Dark R28 G27 B21 y las de pw R111 G106 B87 — grises calidos, sin nada
-- de verde. Multiplicarlas por 0.05 da negro, no otro color.
-- Ademas SetDesaturated devuelve nil cuando la textura no lo soporta, y
-- dar eso por bueno terminaba ACLARANDO el marco en vez de oscurecerlo.
-- =============================================
function K.ApplyLortiTint(tex, key, part)
	if not tex then return false; end
	local r, g, b = K.LortiTint(key, part);
	if not r then
		tex:SetVertexColor(1, 1, 1);
		return false;
	end
	tex:SetVertexColor(r, g, b);
	return true;
end

-- Borde "Lorti UI" del minimapa (lo dibuja MinimapStyle): su color o el
-- 0.05 de siempre.
function K.LortiMinimapTint()
	local r, g, b = K.LortiZoneColor("Minimap")
	if r then return r, g, b end
	return 0.05, 0.05, 0.05
end

-- Color propio de las barras de casteo, o nil. Tambien lo pide la barra
-- de casteo PW (CastBarPW.lua), que retextura el borde.
function K.LortiCastBarColor()
	return K.LortiZoneColor("CastBar")
end

-- =============================================
-- TEÑIR Y DEVOLVER
--
-- Si Lorti ya no tiñe una textura (destildaste la zona), solo se le
-- devuelve el color de fabrica a las que habia teñido Lorti. Las que
-- nunca toco no se tocan.
-- =============================================
local tinted = {}   -- [textura] = true si la tiño Lorti

local function AsuriOn()
	local C = ns[2]
	return C.UnitFrameCustomTexture and C.AsuriFrames
end

-- restore: color de fabrica (blanco si no se dice otra cosa)
local function TintOne(tex, zone, dark, mult, rr, rg, rb)
	if not tex then return end
	local r, g, b = K.LortiZoneTint(zone, dark, mult)
	if r then
		tex:SetVertexColor(r, g, b)
		tinted[tex] = true
	elseif tinted[tex] then
		tinted[tex] = nil
		tex:SetVertexColor(rr or 1, rg or 1, rb or 1)
	end
end

-- =============================================
-- MARCOS: jugador, objetivo, foco (en todos los estilos)
--
-- El tono sale de K.LortiZoneTint, el MISMO que piden PlayerFrame,
-- TargetFrame y el grupo Compact cuando reaplican su estilo, asi que no
-- se pisan: Default, Light, Dark, Compact y Asuri.
-- =============================================
local FRAME_TEXTURES = {
	-- { textura, zona, marco grande (Asuri lo deja gris) }
	{ "PlayerFrameTexture",                "Player", true },
	{ "PetFrameTexture",                   "Player" },
	{ "TargetFrameTextureFrameTexture",    "Target", true },
	{ "TargetFrameToTTextureFrameTexture", "Target" },
	{ "FocusFrameTextureFrameTexture",     "Focus",  true },
	{ "FocusFrameToTTextureFrameTexture",  "Focus" },
}

local function TintUnitFrames()
	-- El marco de hielo del mago queda afuera: es un skin propio, con su
	-- paleta. PlayerFrame.lua le devuelve el blanco en cada reaplicacion.
	local skipPlayer = K.IcyPlayerFrameOn and K.IcyPlayerFrameOn();
	for _, e in ipairs(FRAME_TEXTURES) do
		if not (skipPlayer and e[1] == "PlayerFrameTexture") then
			local d = (e[3] and AsuriOn()) and 0.25 or 1
			TintOne(_G[e[1]], e[2], 0.05, 1, d, d, d)
		end
	end
end

-- Los 4 del grupo, sus mascotas y el marco de vehiculo, en cualquier
-- estilo de grupo (Default, New, Improved, Compact).
local PARTY_SUFFIX = { "Texture", "PetFrameTexture", "VehicleTexture" }
local function TintPartyFrames()
	for i = 1, 4 do
		for _, suf in ipairs(PARTY_SUFFIX) do
			TintOne(_G["PartyMemberFrame" .. i .. suf], "Party", 0.05)
		end
	end
end

-- =============================================
-- BORDES DE LAS BARRAS DE CASTEO (zona "Barras de casteo")
--
-- Lo de siempre solo se repone si antes los habiamos pintado nosotros: al
-- cargar no se toca nada, para no pisarle el tono a la barra PW.
-- =============================================
local CASTBAR_BORDERS = { "CastingBarFrameBorder", "TargetFrameSpellBarBorder", "FocusFrameSpellBarBorder" }
local castTouched = false

local function ApplyCastBarBorders()
	local r, g, b = K.LortiZoneTint("CastBar", 0.05)
	if not r and not castTouched then return end
	for _, n in ipairs(CASTBAR_BORDERS) do
		local tex = _G[n]
		if tex then
			if r then tex:SetVertexColor(r, g, b) else tex:SetVertexColor(1, 1, 1) end
		end
	end
	local was = castTouched
	castTouched = (r ~= nil)
	-- La barra PW tiene su propio tono para el borde: que lo reponga ella.
	if was and not r then
		local C = ns[2]
		if C.CastBarPWEnabled and K.ApplyCastBarPW then K.ApplyCastBarPW() end
	end
end

-- =============================================
-- EL RELOJ (va con la zona "Minimapa": esta pegado a el)
-- =============================================
local clockTinted = false
local function ApplyClock()
	local r, g, b = K.LortiZoneTint("Minimap", 0.05)
	if not r and not clockTinted then return end
	if not r then r, g, b = 1, 1, 1 end
	for _, f in ipairs({ TimeManagerClockButton or false, GameTimeFrame or false }) do
		if f then
			local region = select(1, f:GetRegions())
			if region then region:SetVertexColor(r, g, b) end
		end
	end
	clockTinted = K.LortiZoneOn("Minimap")
end

-- =============================================
-- ARENA (los enemigos y sus mascotas)
--
-- Lorti solo oscurecia el marco del enemigo y se olvidaba del de su
-- mascota: en arena quedaba el jugador oscuro y al lado su felguard con
-- el marco dorado de Blizzard.
-- =============================================
local function ApplyDarkArenaTextures()
	for i = 1, 5 do
		TintOne(_G["ArenaEnemyFrame" .. i .. "Texture"], "Arena", 0.1)
		TintOne(_G["ArenaEnemyFrame" .. i .. "PetFrameTexture"], "Arena", 0.1)
	end
end

-- =============================================
-- BARRAS DE ACCION (el arte de la barra; el contorno de los botones lo
-- pinta func/functions.lua con K.LortiZoneColor("ActionBars"))
-- =============================================
local BAR_TEXTURES = {
	"BonusActionBarTexture0", "BonusActionBarTexture1",
	"MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
	"MainMenuMaxLevelBar0", "MainMenuMaxLevelBar1", "MainMenuMaxLevelBar2", "MainMenuMaxLevelBar3",
	"MainMenuXPBarTextureLeftCap", "MainMenuXPBarTextureRightCap", "MainMenuXPBarTextureMid",
	"MainMenuXPBarTexture0", "MainMenuXPBarTexture1", "MainMenuXPBarTexture2", "MainMenuXPBarTexture3",
	"ReputationWatchBarTexture0", "ReputationWatchBarTexture1", "ReputationWatchBarTexture2", "ReputationWatchBarTexture3",
	"ReputationXPBarTexture0", "ReputationXPBarTexture1", "ReputationXPBarTexture2", "ReputationXPBarTexture3",
}
local function ApplyActionBarTextures()
	for _, n in ipairs(BAR_TEXTURES) do TintOne(_G[n], "ActionBars", 0.2, 0.6) end
	TintOne(MainMenuBarLeftEndCap, "ActionBars", 0.35, 0.8)
	TintOne(MainMenuBarRightEndCap, "ActionBars", 0.35, 0.8)
end

-- =============================================
-- MINIMAP
-- =============================================
local function InitMinimap()
	if not SubOpt("LortiUI_Minimap") then return end
	local ok, err = pcall(function()
		-- EL BORDE NO SE PINTA ACA: lo dibuja MinimapStyle como el estilo
		-- "Lorti UI" del desplegable de borde (en caliente y reversible). La
		-- casilla es el espejo de ese estilo: ver K.SyncLortiMinimap.
		--
		-- Tampoco se fuerzan a mostrar los botones de zoom y el del mapa
		-- del mundo: los decide Interface > Minimap > Decorations.
		if MiniMapTracking then
			MiniMapTracking:Show()
			MiniMapTracking.Show = kill
			MiniMapTracking:UnregisterAllEvents()
		end
		if Minimap then
			Minimap:EnableMouseWheel(true)
			Minimap:SetScript("OnMouseWheel", function(self, z)
				local c = Minimap:GetZoom()
				if z > 0 and c < 5 then Minimap:SetZoom(c + 1)
				elseif z < 0 and c > 0 then Minimap:SetZoom(c - 1) end
			end)
			Minimap:SetScript("OnMouseUp", function(self, btn)
				if btn == "RightButton" then
					if _G.GameTimeFrame then _G.GameTimeFrame:Click() end
				elseif btn == "MiddleButton" then
					_G.ToggleDropDownMenu(1, nil, _G.MiniMapTrackingDropDown, self)
				else
					_G.Minimap_OnClick(self)
				end
			end)
		end
	end)
	if not ok then
		print("|cffFF0000NUF Lorti:|r " .. (L["LORTI_MINIMAP_ERR"] or "Minimap init error:") .. " " .. tostring(err))
	end
end

-- =============================================
-- TUS BUFFS / TUS DEBUFFS (dos zonas)
--
-- El aspecto de Lorti en los iconos de aura, igual que en los botones:
-- icono recortado, el borde "gloss" encima y el contorno (sombra) de
-- alrededor. SOLO LOS TUYOS, arriba a la derecha (BuffButton,
-- DebuffButton y los encantamientos de arma, TempEnchant, que van con
-- los buffs). Los del objetivo y el foco quedan como los de Blizzard.
--
-- Colores:
--   borde de adentro: negro en los buffs; en los debuffs, el de su
--     escuela (el mismo que pone Blizzard en su aro); en los
--     encantamientos, violeta.
--   contorno: negro, o el color de la zona.
--
-- Se aplica y se quita en el acto. La foto del icono se saca una sola
-- vez, antes de tocarlo, para poder devolverlo tal cual.
-- =============================================
local buffsOn, debuffsOn = false, false
local auraStyled = {}  -- [boton] = "Buff" | "Debuff" | "Temp"
local auraOrig = {}    -- [boton] = { pts = {...}, coord = {...} }
local TEMP_COLOR = { 0.6, 0.2, 0.9 }

local function SnapPoints(region)
	if not region then return nil end
	local n = region:GetNumPoints() or 0
	if n == 0 then return nil end
	local pts = {}
	for i = 1, n do pts[i] = { region:GetPoint(i) } end
	return pts
end

local function AuraShadowColor(kind)
	local r, g, b = K.LortiZoneColor((kind == "Debuff") and "Debuffs" or "Buffs")
	if r then return r, g, b, 1 end
	local sc = cfg.background.shadowcolor
	return sc.r, sc.g, sc.b, sc.a
end

local function AuraGlossColor(bu, kind)
	if kind == "Debuff" then
		-- El color de la escuela ya lo puso Blizzard en su aro (que aca va
		-- escondido): se copia de ahi.
		local bo = _G[bu:GetName() .. "Border"]
		if bo and bo.GetVertexColor then
			local r, g, b = bo:GetVertexColor()
			if r then return r, g, b end
		end
		return 0.8, 0, 0
	elseif kind == "Temp" then
		return TEMP_COLOR[1], TEMP_COLOR[2], TEMP_COLOR[3]
	end
	local n = cfg.color.normal
	return n.r, n.g, n.b
end

local function StyleAura(bu, kind)
	local name = bu and bu.GetName and bu:GetName()
	if not name then return end
	local icon = _G[name .. "Icon"]
	if not auraOrig[bu] then
		auraOrig[bu] = { pts = SnapPoints(icon), coord = icon and { icon:GetTexCoord() } or nil }
	end
	if not bu.nufLortiGloss then
		-- Encima del icono y debajo del numero de acumulaciones.
		local gl = bu:CreateTexture(nil, "OVERLAY")
		if gl.SetDrawLayer then pcall(gl.SetDrawLayer, gl, "OVERLAY", -1) end
		gl:SetTexture(cfg.textures.normal)
		gl:SetAllPoints(bu)
		bu.nufLortiGloss = gl
		local sh = CreateFrame("Frame", nil, bu)
		sh:SetFrameLevel(math.max(0, (bu:GetFrameLevel() or 1) - 1))
		bu.nufLortiShadow = sh
	end
	auraStyled[bu] = kind

	local big = (bu:GetWidth() or 30) >= 26
	local inset = big and 2 or 1
	if icon then
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", bu, "TOPLEFT", inset, -inset)
		icon:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", -inset, inset)
		icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	end
	local sh = bu.nufLortiShadow
	local off = big and 4 or 3
	if sh.nufOff ~= off then
		sh.nufOff = off
		sh:ClearAllPoints()
		sh:SetPoint("TOPLEFT", bu, "TOPLEFT", -off, off)
		sh:SetPoint("BOTTOMRIGHT", bu, "BOTTOMRIGHT", off, -off)
		sh:SetBackdrop({
			edgeFile = cfg.textures.outer_shadow, edgeSize = off + 1,
			insets = { left = off + 1, right = off + 1, top = off + 1, bottom = off + 1 },
		})
	end
	sh:SetBackdropBorderColor(AuraShadowColor(kind))
	sh:Show()
	bu.nufLortiGloss:SetVertexColor(AuraGlossColor(bu, kind))
	bu.nufLortiGloss:Show()
	-- El aro gordo de Blizzard (debuffs y encantamientos): con los dos el
	-- icono queda con doble marco.
	local bo = _G[name .. "Border"]
	if bo then bo:Hide() end
end

local function RestoreAura(bu)
	if not auraStyled[bu] then return end
	auraStyled[bu] = nil
	if bu.nufLortiGloss then bu.nufLortiGloss:Hide() end
	if bu.nufLortiShadow then bu.nufLortiShadow:Hide() end
	local name = bu:GetName()
	local icon = name and _G[name .. "Icon"]
	local o = auraOrig[bu]
	if icon and o then
		icon:ClearAllPoints()
		if o.pts then
			for _, pt in ipairs(o.pts) do pcall(icon.SetPoint, icon, unpack(pt)) end
		else
			-- Sin anclas en el XML el icono llena el boton.
			icon:SetAllPoints(bu)
		end
		if o.coord and #o.coord >= 4 then pcall(icon.SetTexCoord, icon, unpack(o.coord)) end
	end
	local bo = name and _G[name .. "Border"]
	if bo then bo:Show() end
end

-- Gancho (hooksecurefunc: corre despues de Blizzard, sin contaminar).
-- AuraButton_Update es solo la barra de auras del jugador.
if type(AuraButton_Update) == "function" then
	hooksecurefunc("AuraButton_Update", function(buttonName, index)
		local isDebuff = (buttonName == "DebuffButton")
		if isDebuff then
			if not debuffsOn then return end
		elseif not buffsOn then
			return
		end
		local bu = _G[buttonName .. index]
		if not bu or not bu:IsShown() then return end
		StyleAura(bu, isDebuff and "Debuff" or "Buff")
	end)
end

-- Prender, apagar o cambiar de color, en el acto.
function K.ApplyLortiAuras()
	buffsOn = K.LortiZoneOn("Buffs")
	debuffsOn = K.LortiZoneOn("Debuffs")
	for bu, kind in pairs(auraStyled) do
		local want = buffsOn            -- buffs y encantamientos
		if kind == "Debuff" then want = debuffsOn end
		if not want then RestoreAura(bu) end
	end
	if buffsOn then
		for i = 1, (BUFF_MAX_DISPLAY or 32) do
			local bu = _G["BuffButton" .. i]
			if bu and bu:IsShown() then StyleAura(bu, "Buff") end
		end
		-- Los encantamientos son fijos (existen aunque esten ocultos).
		for i = 1, 3 do
			local bu = _G["TempEnchant" .. i]
			if bu then StyleAura(bu, "Temp") end
		end
	end
	if debuffsOn then
		for i = 1, (DEBUFF_MAX_DISPLAY or 16) do
			local bu = _G["DebuffButton" .. i]
			if bu and bu:IsShown() then StyleAura(bu, "Debuff") end
		end
	end
end

-- =============================================
-- APLICAR TODO (al cargar y cada vez que cambia algo del panel)
-- =============================================
local function ApplyAll()
	TintUnitFrames()
	TintPartyFrames()
	ApplyCastBarBorders()
	ApplyClock()
	if IsAddOnLoaded("Blizzard_ArenaUI") then ApplyDarkArenaTextures() end
	ApplyActionBarTextures()
	-- El contorno de los botones (func/functions.lua). Va siempre: con la
	-- zona apagada o sin color los devuelve a su negro.
	if K.ApplyLortiButtonColor then K.ApplyLortiButtonColor() end
	K.ApplyLortiAuras()
end

-- Lo llama el panel al tocar cualquier casilla o color: todo en el acto.
-- (Las zonas con * terminan de verse con /reload: sus marcos piden el
-- tono cuando se actualizan.)
function K.ApplyLortiColor()
	if not initialized then return end
	if not ModuleOn() then return end
	ApplyAll()
	-- El borde "Lorti UI" del minimapa lo dibuja MinimapStyle.
	if SubOpt("LortiUI_Minimap") and K.ApplyMinimapSettings then K.ApplyMinimapSettings() end
end

local function WhenLoaded(addon, fn)
	if IsAddOnLoaded(addon) then fn(); return end
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_LOADED")
	f:SetScript("OnEvent", function(self, event, name)
		if name == addon then
			self:UnregisterEvent("ADDON_LOADED")
			self:SetScript("OnEvent", nil)
			fn()
		end
	end)
end

local function Init()
	if initialized then return end
	initialized = true
	if K.LortiMigrateLayout then K.LortiMigrateLayout() end

	InitMinimap()
	ApplyAll()
	-- Lo que Blizzard carga despues: el reloj y la arena.
	WhenLoaded("Blizzard_TimeManager", ApplyClock)
	WhenLoaded("Blizzard_ArenaUI", ApplyDarkArenaTextures)

	if K.RegisterConfigEvent then
		K.RegisterConfigEvent("CONFIG_LOADED", function()
			if ModuleOn() then ApplyAll() end
		end)
	end
end

-- =============================================
-- Config
-- =============================================
cfg.textures = {
	normal         = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\gloss",
	flash          = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\flash",
	hover          = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\hover",
	pushed         = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\pushed",
	checked        = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\checked",
	equipped       = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\gloss_grey",
	buttonback     = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\button_background",
	buttonbackflat = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\button_background_flat",
	outer_shadow   = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\outer_shadow",
}
cfg.background = {
	showbg = true, showshadow = true, useflatbackground = false,
	backgroundcolor = { r=0.3, g=0.3, b=0.3, a=0.7 },
	shadowcolor     = { r=0,   g=0,   b=0,   a=0.9 },
	classcolored = false, inset = 5,
}
cfg.color = {
	normal   = { r=0,   g=0,    b=0,   a=0.9 },
	equipped = { r=0.3, g=0.55, b=0.1 },
	classcolored = false,
}
cfg.hotkeys   = { show=true, fontsize=12, pos1={a1="TOPRIGHT",x=0,y=0}, pos2={a1="TOPLEFT",x=0,y=0} }
cfg.macroname = { show=true, fontsize=11, pos1={a1="BOTTOMLEFT",x=-4,y=0}, pos2={a1="BOTTOMRIGHT",x=4,y=0} }
cfg.itemcount = { show=true, fontsize=12, pos1={a1="BOTTOMRIGHT",x=0,y=0} }
cfg.cooldown  = { spacing=0 }
cfg.font      = "Fonts\\FRIZQT__.TTF"
ns.cfg = cfg

-- =============================================
-- EL PANEL (pestaña Addons, debajo de la casilla "Lorti UI")
-- API: createUI(container, yOffset, parentCheckbox) -> subUIHeight
--
--   MARCOS             Lorti Color    INTERFAZ            Lorti Color
--   Jugador             [x]  [ ]■     Barras de accion     [x]  [x]■
--   Objetivo            [x]  [x]■     Minimapa             [ ]  [ ]■
--   ...                               Tus buffs / debuffs
--                                     ───────────────────────────────
--                                     Mismo color a todo          ■
--                                     [Colores por defecto]
--                                     * necesita /reload
--
-- Cada zona aparece UNA sola vez. "Color" solo se puede tildar con "Lorti"
-- tildada en esa fila. El cuadrito: click elige el color, click derecho
-- vuelve al celeste por defecto. Todo se aplica en el acto.
-- =============================================
local ZONE_INFO = {
	-- zona = { etiqueta EN, tooltip EN, necesita /reload }
	Player       = { "Player", "Your frame and your pet's frame, in any style (Default, Light, Dark, Compact or Asuri). The mage's Icy frame keeps its own colors." },
	Target       = { "Target", "The target frame and its target of target, in any style." },
	Focus        = { "Focus", "The focus frame and its target, in any style." },
	Party        = { "Party", "The 4 party frames, their pets and their vehicle frame, in any party style (Default, New, Improved or Compact)." },
	PartyTargets = { "Party targets", "The target-of-party frames.", true },
	PartyPet     = { "Party pets", "The enhanced party pet frames and their cast bar border.", true },
	Arena        = { "Arena", "The enemy arena frames and their pets.", true },
	CastBar      = { "Cast bars", "The border of the cast bars: yours, target and focus." },
	ActionBars   = { "Action bars", "The action bar art (also the XP and reputation bars) and the glow around the action buttons." },
	Minimap      = { "Minimap", "The Lorti UI border of the minimap, and the clock. Same option as Interface > Minimap > Border style: Lorti UI.\nAlso: right-click the minimap to open the calendar." },
	Buffs        = { "Your buffs", "Your buffs (top right) and your weapon enchants: cut icon, Lorti border and glow. The target and focus auras stay normal." },
	Debuffs      = { "Your debuffs", "Your debuffs: cut icon and glow. The border keeps the school color (Magic, Curse, Poison, Disease)." },
}
local LEFT_ZONES  = { "Player", "Target", "Focus", "Party", "PartyTargets", "PartyPet", "Arena", "CastBar" }
local RIGHT_ZONES = { "ActionBars", "Minimap", "Buffs", "Debuffs" }

local function CreateLortiSubUI(container, yOffset, parentCheckbox)
	local C = ns[2]
	if K.LortiMigrateLayout then K.LortiMigrateLayout() end

	-- Wrapper frame para todo el bloque (se muestra/oculta como grupo)
	local wrapper = CreateFrame("Frame", nil, container)
	wrapper:SetPoint("TOPLEFT", 0, yOffset)
	local W = container:GetWidth() or 540
	if not W or W < 400 then W = 540 end
	wrapper:SetWidth(W)

	-- Separador visual
	local sep = wrapper:CreateTexture(nil, "ARTWORK")
	sep:SetHeight(1)
	sep:SetPoint("TOPLEFT", 36, 4)
	sep:SetPoint("TOPRIGHT", -10, 4)
	sep:SetTexture(1, 1, 1, 0.07)

	-- Medidas. Las casillas van a escala 0.85 y SetPoint mide en la escala
	-- de la casilla: por eso MakeCB divide por CB_S (si no, cada fila queda
	-- mas arriba de lo calculado y se encima con lo de al lado).
	local CB_S  = 0.85
	local X1    = 46
	local GAP   = 30
	local COL_W = math.max(220, math.min(270, math.floor((W - X1 - GAP - 20) / 2)))
	local X2    = X1 + COL_W + GAP
	local ROW_H = 22
	local TOP   = -8           -- titulos de grupo y de columna
	local FIRST = TOP - 16     -- primera fila

	local function SaveKey(key, v)
		local save = K.SaveConfigSilent or K.SaveConfig
		save(key, v)
	end
	local function ColorOf(p)
		return Clamp01(C[p .. "R"], DEFAULT_COLOR[1]),
		       Clamp01(C[p .. "G"], DEFAULT_COLOR[2]),
		       Clamp01(C[p .. "B"], DEFAULT_COLOR[3])
	end
	local function MakeCB(name, x, y)
		local cb = CreateFrame("CheckButton", name, wrapper, "InterfaceOptionsCheckButtonTemplate")
		cb:SetScale(CB_S)
		cb:SetPoint("TOPLEFT", wrapper, "TOPLEFT", x / CB_S, y / CB_S)
		local t = _G[name .. "Text"]
		if t then t:SetText("") end
		return cb
	end
	local function Text(text, point, x, y, font)
		local fs = wrapper:CreateFontString(nil, "ARTWORK", font or "GameFontDisableSmall")
		fs:SetPoint(point, wrapper, "TOPLEFT", x, y)
		fs:SetText(text)
		return fs
	end
	-- Dentro de cada columna: Lorti, Color y el cuadrito, pegados a la derecha.
	local function Cols(x)
		local lx = x + COL_W - 74
		return lx, lx + 28, lx + 54
	end
	local function Tip(owner, title, line, warn)
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetText(title, 1, 1, 1)
		if line then GameTooltip:AddLine(line, nil, nil, nil, true) end
		if warn then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(warn, 1, 0.67, 0, true)
		end
		GameTooltip:Show()
	end
	local function HideTip() GameTooltip:Hide() end

	-- El selector de color de WoW (el mismo del Lorti UI suelto). Las
	-- funciones van ANTES de SetColorRGB: SetColorRGB llama a .func, y si
	-- quedara la de otro addon (o la de otra fila) le mandariamos el color.
	local function OpenPicker(r, g, b, onPick, onCancel)
		ColorPickerFrame.func = function() onPick(ColorPickerFrame:GetColorRGB()) end
		ColorPickerFrame.cancelFunc = function() onCancel() end
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.opacityFunc = nil
		ColorPickerFrame.previousValues = { r = r, g = g, b = b }
		ColorPickerFrame:SetColorRGB(r, g, b)
		ShowUIPanel(ColorPickerFrame)
	end
	local function MakeSwatch(x, y)
		local sw = CreateFrame("Button", nil, wrapper)
		sw:SetSize(18, 18)
		sw:SetPoint("TOPLEFT", wrapper, "TOPLEFT", x, y - 2)
		local bd = sw:CreateTexture(nil, "BACKGROUND")
		bd:SetPoint("TOPLEFT", -1, 1)
		bd:SetPoint("BOTTOMRIGHT", 1, -1)
		bd:SetTexture(0.6, 0.6, 0.6, 1)
		local tx = sw:CreateTexture(nil, "ARTWORK")
		tx:SetAllPoints()
		tx:SetTexture(1, 1, 1, 1)
		sw.tex = tx
		sw:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		return sw
	end

	-- Titulos: grupo a la izquierda, "Lorti" y "Color" arriba de sus casillas.
	local function Header(x, text)
		local lx, cx = Cols(x)
		Text(text, "TOPLEFT", x, TOP, "GameFontNormalSmall")
		Text(L["LORTI_COL_LORTI"] or "Lorti", "TOP", lx + 11, TOP)
		Text(L["LORTI_COL_COLOR"] or "Color", "TOP", cx + 20, TOP)
	end
	Header(X1, L["LORTI_GROUP_FRAMES"] or "Frames")
	Header(X2, L["LORTI_GROUP_UI"] or "Interface")

	local rows = {}
	local RefreshAll
	local function Apply()
		if K.ApplyLortiColor then K.ApplyLortiColor() end
	end

	local function MakeRow(zone, x, y)
		local Z, info = ZONES[zone], ZONE_INFO[zone]
		local p = "LortiUI_" .. Z.color
		local label = L["LORTI_Z_" .. zone] or info[1]
		local tip = L["LORTI_ZTIP_" .. zone] or info[2]
		local reload = info[3]
		local lx, cx, sx = Cols(x)

		local name = wrapper:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		name:SetPoint("LEFT", wrapper, "TOPLEFT", x, y - 11)
		name:SetText(label .. (reload and " |cff888888*|r" or ""))

		local lorti = MakeCB("NidhausLortiZone_" .. zone, lx, y)
		-- El nombre es parte de la casilla: pasar el mouse o hacer click en
		-- el nombre es lo mismo que en la casilla.
		lorti:SetHitRectInsets(-(lx - x) / CB_S, 0, 0, 0)
		local color = MakeCB("NidhausLortiColor_" .. zone, cx, y)
		-- La plantilla de la casilla estira su zona de click 100 px a la
		-- DERECHA (para el texto, que aca no hay): tapaba el cuadrito, y el
		-- click iba a la casilla en vez de abrir el selector de color.
		color:SetHitRectInsets(0, 0, 0, 0)
		local sw = MakeSwatch(sx, y)
		-- Y por las dudas, el cuadrito por encima de las casillas.
		sw:SetFrameLevel((color:GetFrameLevel() or 1) + 2)

		local row = { zone = zone }
		function row.Avail()
			if C[Z.on] == false then return false end
			if zone == "Minimap" then
				-- Solo con el borde "Lorti UI" puesto: es lo unico que pinta.
				local style = (K.GetMinimapBorderStyle and K.GetMinimapBorderStyle()) or C.MinimapBorderStyle
				return style == "Lorti"
			end
			return true
		end
		function row.Refresh()
			local on = (C[Z.on] ~= false)
			lorti:SetChecked(on)
			local v = on and 1 or 0.55
			name:SetTextColor(v, v, v)
			local avail = row.Avail()
			local colOn = (C[p .. "Color"] == true)
			color:SetChecked(colOn)
			if avail then color:Enable() else color:Disable() end
			sw.tex:SetVertexColor(ColorOf(p))
			if avail and colOn then
				sw:Enable(); sw:SetAlpha(1)
			else
				sw:Disable(); sw:SetAlpha(0.3)
			end
		end

		lorti:SetScript("OnEnter", function(self)
			Tip(self, label, tip, reload and ("\226\154\160 " .. (L["LORTI_REQ_RELOAD"] or "Requires /reload")) or nil)
		end)
		lorti:SetScript("OnLeave", HideTip)
		lorti:SetScript("OnClick", function(self)
			local checked = self:GetChecked() == 1 or self:GetChecked() == true
			K.SaveConfig(Z.on, checked)
			-- ESPEJO DEL BORDE DEL MINIMAPA: tildar pone el borde "Lorti UI"
			-- y destildar vuelve a "Default", en el acto.
			if zone == "Minimap" then
				local cur = (K.GetMinimapBorderStyle and K.GetMinimapBorderStyle()) or C.MinimapBorderStyle
				if checked then
					K.SaveConfig("MinimapBorderStyle", "Lorti")
				elseif cur == "Lorti" then
					K.SaveConfig("MinimapBorderStyle", "Default")
				end
				if K.ApplyMinimapSettings then K.ApplyMinimapSettings() end
			end
			Apply()
			RefreshAll()
		end)

		color:SetScript("OnEnter", function(self)
			Tip(self, (L["LORTI_COL_COLOR"] or "Color") .. ": " .. label,
				L["LORTI_COLOR_TIP"] or "Your own color instead of black. Click the square to choose it; right-click it for the default color.",
				(not row.Avail()) and (L["LORTI_COLOR_OFF"] or "Tick 'Lorti' on this row first.") or nil)
		end)
		color:SetScript("OnLeave", HideTip)
		color:SetScript("OnClick", function(self)
			local checked = self:GetChecked() == 1 or self:GetChecked() == true
			K.SaveConfig(p .. "Color", checked)
			row.Refresh()
			Apply()
		end)

		sw:SetScript("OnEnter", function(self)
			Tip(self, (L["LORTI_COL_COLOR"] or "Color") .. ": " .. label,
				L["LORTI_SWATCH_TIP"] or "Click: choose the color (applies instantly).\nRight-click: back to the default color.")
		end)
		sw:SetScript("OnLeave", HideTip)
		sw:SetScript("OnClick", function(self, button)
			local function Save(r, g, b)
				SaveKey(p .. "R", r); SaveKey(p .. "G", g); SaveKey(p .. "B", b)
				sw.tex:SetVertexColor(r, g, b)
				Apply()
			end
			if button == "RightButton" then
				Save(DEFAULT_COLOR[1], DEFAULT_COLOR[2], DEFAULT_COLOR[3])
				return
			end
			local r, g, b = ColorOf(p)
			OpenPicker(r, g, b, Save, function() Save(r, g, b) end)
		end)

		row.Refresh()
		rows[#rows + 1] = row
	end

	for i, zone in ipairs(LEFT_ZONES) do MakeRow(zone, X1, FIRST - (i - 1) * ROW_H) end
	for i, zone in ipairs(RIGHT_ZONES) do MakeRow(zone, X2, FIRST - (i - 1) * ROW_H) end

	-- ── Debajo de Interfaz: las herramientas de color ──
	local yR = FIRST - #RIGHT_ZONES * ROW_H - 6
	local line = wrapper:CreateTexture(nil, "ARTWORK")
	line:SetHeight(1)
	line:SetWidth(COL_W - 2)
	line:SetPoint("TOPLEFT", wrapper, "TOPLEFT", X2, yR)
	line:SetTexture(1, 1, 1, 0.08)
	yR = yR - 6

	-- Mismo color a todo: pinta (y tilda "Color" en) todas las filas con
	-- "Lorti" tildada. Cancelar en el selector deja todo como estaba.
	local allLbl = wrapper:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	allLbl:SetPoint("LEFT", wrapper, "TOPLEFT", X2, yR - 11)
	allLbl:SetText(L["LORTI_ALL_COLOR"] or "Same color for all")
	local _, _, sxAll = Cols(X2)
	local allSw = MakeSwatch(sxAll, yR)
	allSw:SetScript("OnEnter", function(self)
		Tip(self, L["LORTI_ALL_COLOR"] or "Same color for all",
			L["LORTI_ALL_COLOR_TIP"] or "Paints every row that has 'Lorti' ticked with this color, and ticks its 'Color'. Cancel in the picker leaves everything as it was.")
	end)
	allSw:SetScript("OnLeave", HideTip)
	allSw:SetScript("OnClick", function()
		local snap = {}
		for _, z in ipairs(ZONE_ORDER) do
			local p = "LortiUI_" .. ZONES[z].color
			snap[z] = { C[p .. "Color"] == true, ColorOf(p) }
		end
		local r0, g0, b0 = ColorOf("LortiUI_All")
		local function PaintAll(nr, ng, nb)
			SaveKey("LortiUI_AllR", nr); SaveKey("LortiUI_AllG", ng); SaveKey("LortiUI_AllB", nb)
			allSw.tex:SetVertexColor(nr, ng, nb)
			for _, z in ipairs(ZONE_ORDER) do
				if C[ZONES[z].on] ~= false then
					local p = "LortiUI_" .. ZONES[z].color
					SaveKey(p .. "Color", true)
					SaveKey(p .. "R", nr); SaveKey(p .. "G", ng); SaveKey(p .. "B", nb)
				end
			end
			Apply()
			RefreshAll()
		end
		OpenPicker(r0, g0, b0, PaintAll, function()
			for z, s in pairs(snap) do
				local p = "LortiUI_" .. ZONES[z].color
				SaveKey(p .. "Color", s[1])
				SaveKey(p .. "R", s[2]); SaveKey(p .. "G", s[3]); SaveKey(p .. "B", s[4])
			end
			SaveKey("LortiUI_AllR", r0); SaveKey("LortiUI_AllG", g0); SaveKey("LortiUI_AllB", b0)
			Apply()
			RefreshAll()
		end)
	end)
	yR = yR - 26

	-- Colores por defecto: todas las filas vuelven al negro de Lorti.
	local defBtn = CreateFrame("Button", nil, wrapper, "UIPanelButtonTemplate")
	defBtn:SetSize(150, 20)
	defBtn:SetPoint("TOPLEFT", wrapper, "TOPLEFT", X2, yR)
	defBtn:SetText(L["LORTI_DEFAULT_COLORS"] or "Default colors")
	defBtn:SetScript("OnEnter", function(self)
		Tip(self, L["LORTI_DEFAULT_COLORS"] or "Default colors",
			L["LORTI_DEFAULT_COLORS_TIP"] or "Every row back to the black of Lorti UI: unticks 'Color' and resets the colors to the default light blue.")
	end)
	defBtn:SetScript("OnLeave", HideTip)
	defBtn:SetScript("OnClick", function()
		for _, z in ipairs(ZONE_ORDER) do
			local p = "LortiUI_" .. ZONES[z].color
			SaveKey(p .. "Color", false)
			SaveKey(p .. "R", DEFAULT_COLOR[1]); SaveKey(p .. "G", DEFAULT_COLOR[2]); SaveKey(p .. "B", DEFAULT_COLOR[3])
		end
		Apply()
		RefreshAll()
	end)
	yR = yR - 28

	Text("* " .. (L["LORTI_RELOAD_NOTE"] or "needs /reload"), "TOPLEFT", X2, yR)
	yR = yR - 14

	RefreshAll = function()
		for _, r in ipairs(rows) do r.Refresh() end
		allSw.tex:SetVertexColor(ColorOf("LortiUI_All"))
	end
	RefreshAll()
	-- Al reabrir el panel algo pudo cambiar desde otro lado (el borde del
	-- minimapa se elige tambien en Interface > Minimap).
	wrapper:SetScript("OnShow", RefreshAll)

	local leftBottom = FIRST - #LEFT_ZONES * ROW_H
	local subUIHeight = math.abs(math.min(leftBottom, yR)) + 8
	wrapper:SetHeight(subUIHeight)

	-- RE-SINCRONIZAR CON C. LortiUI_Minimap tiene dos duenos: esta casilla y
	-- el desplegable de borde del minimapa. MinimapStyle y el panel llaman a
	-- esto cuando cambia desde el otro lado.
	K.RefreshLortiSubOptions = RefreshAll

	-- Mostrar/ocultar según estado del módulo
	local function SetSubsVisible(show)
		if show then wrapper:Show() else wrapper:Hide() end
		-- Ajustar altura del contenedor y re-calcular scroll
		local ct = K._moduleContainers and K._moduleContainers["LortiUI"]
		if ct then
			if show then
				ct:SetHeight(ct._baseHeight + subUIHeight)
			else
				ct:SetHeight(ct._baseHeight)
			end
			if K.UpdateModulesScrollHeight then K.UpdateModulesScrollHeight() end
		end
	end

	-- Hook del checkbox padre
	if parentCheckbox then
		local origClick = parentCheckbox:GetScript("OnClick")
		parentCheckbox:SetScript("OnClick", function(self)
			if origClick then origClick(self) end
			local enabled = self:GetChecked() == 1 or self:GetChecked() == true
			SetSubsVisible(enabled)
		end)
	end

	-- Estado inicial
	if K.IsModuleEnabled("LortiUI") then
		wrapper:Show()
	else
		wrapper:Hide()
	end

	return subUIHeight
end

-- =============================================
-- REGISTRO
-- =============================================
K.RegisterModule("LortiUI", {
	name     = "Lorti UI",
	desc     = L["MOD_LORTI_DESC"] or "Lorti UI look: dark (or your color) frames, action buttons, minimap and your buffs. Turning the module on or off needs /reload.",
	default  = false,
	onEnable = Init,
	createUI = CreateLortiSubUI,
})
