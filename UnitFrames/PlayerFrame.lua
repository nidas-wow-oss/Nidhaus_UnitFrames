local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooksecurefunc = hooksecurefunc;
local UnitFactionGroup, UnitIsPVP, UnitIsVisible, UnitPowerMax = UnitFactionGroup, UnitIsPVP, UnitIsVisible, UnitPowerMax;
local unpack = unpack;

local isInitialized = false;

-- ── ASURI ─────────────────────────────────────────────────────
-- Tercer tema (RougeUI "Asuri UI Frames"). En el player oculta el nivel
-- (el marco no tiene donde ponerlo) y sube el nombre por encima de las
-- barras, que Asuri corre hacia abajo y afina.
local ASURI = "Interface\\AddOns\\"..AddOnName.."\\Media\\Asuri\\";

-- Carpeta del tema activo.
--
-- Este archivo repetia la ruta completa en cuatro lugares, con un
-- "if darkFrames then Dark else Light" cada vez. Agregar un tercer tema
-- significaba tocar los cuatro y acordarse de todos — justo el tipo de
-- cosa que se olvida en uno. Con un resolvedor, el tema nuevo se agrega
-- en un solo lugar.
local function ThemeDir()
	local base = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\";
	if C.pwFrames   then return base .. "pw\\";   end
	if C.darkFrames then return base .. "Dark\\"; end
	return base .. "Light\\";
end

local function AsuriOn()
	return C.UnitFrameCustomTexture and C.AsuriFrames;
end

local origNameFont;

local function InitializePlayerFrame()
	if isInitialized then return; end
	
	-- FIX: Capturar el estado ORIGINAL de Blizzard ANTES de tocar nada.
	-- Se hace una sola vez, acá, cuando los elementos todavía tienen su
	-- geometría/textura default. El checkbox "Custom Skin" usa esto para
	-- restaurar el default exacto al desactivarse (sin adivinar valores).
	K.CaptureTexture(PlayerFrameTexture, "PlayerFrameTexture");
	K.CaptureTexture(PlayerPVPIcon, "PlayerPVPIcon");
	K.CaptureTexture(PlayerStatusTexture, "PlayerStatusTexture");
	K.CaptureAnchors(PlayerStatusTexture, "PlayerStatusTextureAnchor");
	
	-- Crear frame de movimiento (reparenta y reancla los hijos del PlayerFrame)
	K.MoveFrame(PlayerFrame, "NidhausPlayerFrame", "Player", 105, 27);

	-- FIX: capturar la geometría/anclajes de la healthbar DESPUÉS de MoveFrame,
	-- porque MoveFrame reparenta y reancla los hijos → el anclaje válido es el
	-- post-MoveFrame. Guardamos geometría (para default) y anclajes completos
	-- (para el doble anclaje del look custom, igual que Target).
	if PlayerFrame.healthbar then
		K.CaptureBarGeometry(PlayerFrame.healthbar, "PlayerHealthBar");
		K.CaptureAnchors(PlayerFrame.healthbar, "PlayerHealthBarAnchors");
		if PlayerFrame.healthbar.TextString then
			K.CaptureAnchors(PlayerFrame.healthbar.TextString, "PlayerHealthText");
		end
	end

	-- Aplicar escala (solo al contenedor visual)
	if C.PlayerFrameScale and type(C.PlayerFrameScale) == "number" and C.PlayerFrameScale > 0 and C.PlayerFrameScale <= 3 then
		if NidhausPlayerFrame then 
			NidhausPlayerFrame:SetScale(C.PlayerFrameScale); 
		end
	end
	
	if PlayerFrame.manabar then
		K.CaptureAnchors(PlayerFrame.manabar, "PlayerManaBarAnchors");
	end

	-- Anclaje del NOMBRE. Hace falta porque K.SetOffset suma sobre el punto
	-- ACTUAL: sin restaurar antes, cada pasada de ToPlayerArt (que corre en
	-- un monton de eventos) subiria el nombre otro poco, y terminaba fuera
	-- de la pantalla. Target ya hacia esto; Player no.
	if PlayerFrame.name then
		K.CaptureAnchors(PlayerFrame.name, "PlayerName");
	end

	-- Asuri achica el fondo negro de las barras: guardar el tamaño/anclaje
	-- original para poder devolverlo.
	if PlayerFrameBackground and not PlayerFrameBackground._nufOrig then
		PlayerFrameBackground._nufOrig = {
			w = PlayerFrameBackground:GetWidth(),
			h = PlayerFrameBackground:GetHeight(),
			pts = { PlayerFrameBackground:GetPoint(1) },
		};
	end

	if PlayerFrame.name and not origNameFont then
		origNameFont = PlayerFrame.name:GetFontObject();
	end

	isInitialized = true;
end

--	Player frame.
local function Nidhaus_UnitFrames_Style_PlayerFrame(self)
	if C.statusbarOn then
		self.healthbar:SetStatusBarTexture(C.statusbarTexture);
		self.manabar:SetStatusBarTexture(C.statusbarTexture);
	end;
	if AsuriOn() then
		-- Status3 = SOLO el aro del retrato, sin el contorno de la barra.
		-- Las otras dos versiones traen ese contorno dibujado y con Asuri
		-- las barras son mas finas y estan mas abajo, asi que el trazo
		-- quedaba flotando encima de la vida.
		PlayerStatusTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\UI-Player-Status3");
		PlayerStatusTexture:ClearAllPoints();
		PlayerStatusTexture:SetPoint("CENTER", NidhausPlayerFrame, "CENTER", 16, 8);
	elseif C.UnitFrameCustomTexture then
		PlayerStatusTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\UI-Player-Status2");
		PlayerStatusTexture:ClearAllPoints();
		PlayerStatusTexture:SetPoint("CENTER", NidhausPlayerFrame, "CENTER", 16, 8);
	else
		-- FIX: restaurar textura + anclaje default de Blizzard (capturados en init)
		K.RestoreTexture(PlayerStatusTexture, "PlayerStatusTexture");
		K.RestoreAnchors(PlayerStatusTexture, "PlayerStatusTextureAnchor");
	end
	PlayerFrameGroupIndicatorText:ClearAllPoints();
	PlayerFrameGroupIndicatorText:SetPoint("BOTTOMLEFT", NidhausPlayerFrame, "TOP", 0, -20);
	PlayerFrameGroupIndicatorLeft:Hide();
	PlayerFrameGroupIndicatorMiddle:Hide();
	PlayerFrameGroupIndicatorRight:Hide();
	
	-- FIX: Checkbox "Custom Skin (Player/Target/Focus)". Con el skin apagado
	-- se restauran el marco y el ícono de PVP default (capturados en init),
	-- no las texturas .blp custom.
	-- OJO CON EL ORDEN: Icy va PRIMERO.
	--
	-- Estaba dentro de la cadena que arranca con "si el skin custom esta
	-- apagado, restaurar", asi que con Custom Skin destildado nunca se
	-- llegaba a esta rama y el marco de hielo no se aplicaba nunca. Pero
	-- Icy no es una variante del skin custom: es un skin en si mismo, del
	-- mago. Que dependa del otro no tiene sentido.
	if C.MageIcyFrame and select(2, UnitClass("player")) == "MAGE" then
		-- Icy Portrait (portado de SquidFrame).
		PlayerFrameTexture:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\icy.tga");
		PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
	elseif not C.UnitFrameCustomTexture then
		K.RestoreTexture(PlayerFrameTexture, "PlayerFrameTexture");
		K.RestoreTexture(PlayerPVPIcon, "PlayerPVPIcon");
	elseif C.AsuriFrames then
		PlayerFrameTexture:SetTexture(ASURI.."AsuriFrame");
		PlayerFrameTexture:SetVertexColor(0.25, 0.25, 0.25);
		PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
	else
		PlayerFrameTexture:SetTexture(ThemeDir() .. "UI-TargetingFrame");
		-- El icono de PvP propio solo lo tienen Dark y pw; Light usa el de
		-- Blizzard, que combina mejor con su paleta clara.
		if C.darkFrames or C.pwFrames then
			PlayerPVPIcon:SetTexture(ThemeDir() .. "UI-PVP-FFA");
		else
			PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		end
	end;

	-- Sin esto, al salir de Asuri el marco normal quedaba gris: el
	-- SetVertexColor de arriba no lo revierte ninguna otra rama.
	--
	-- Y aca estaba el motivo de que Lorti UI no se viera en el jugador:
	-- este blanco corre en CADA reaplicacion del skin (PlayerFrame_ToPlayerArt
	-- se dispara todo el tiempo) y le borraba el tinte oscuro que Lorti
	-- pone una sola vez al cargar. Ahora se le pregunta a Lorti primero.
	if not C.AsuriFrames then
		if not (K.ApplyLortiTint and K.ApplyLortiTint(PlayerFrameTexture,
			"LortiUI_PlayerTargetFocus")) then
			PlayerFrameTexture:SetVertexColor(1, 1, 1);
		end
	end
end;

local function Nidhaus_UnitFrames_PlayerFrame_ToPlayerArt(self)
	-- Re-apply custom textures (Blizzard resets them when this function fires)
	Nidhaus_UnitFrames_Style_PlayerFrame(self);

	-- Volver al anclaje base ANTES de sumar el offset (ver la nota de la
	-- captura): asi el resultado es absoluto y no se acumula.
	K.RestoreAnchors(self.name, "PlayerName");
	if C.PlayerNameOffset and type(C.PlayerNameOffset) == "table" then
		self.name:SetPoint(K.SetOffset(self.name, unpack(C.PlayerNameOffset)));
	end

	if AsuriOn() then
		-- Asuri corre las barras hacia abajo y las afina, asi que el nombre
		-- queda pisandolas. Se lo sube por encima, a la misma altura
		-- relativa que usa el objetivo (que ahi va en -50, 25).
		self.name:SetAlpha(1);
		if origNameFont then self.name:SetFontObject(origNameFont); end
		local nameHost = _G["NidhausPlayerFrame"] or self;
		self.name:ClearAllPoints();
		self.name:SetPoint("CENTER", nameHost, "CENTER", 50, 25);
	elseif origNameFont then
		self.name:SetAlpha(1);
		self.name:SetFontObject(origNameFont);
		self.name:SetShadowOffset(1, -1);
	end

	-- Sin nivel en Asuri ni en Compact: ninguno de los dos marcos tiene
	-- donde ponerlo. Se usa alfa y no Hide() porque Blizzard vuelve a
	-- mostrar ese FontString en cada actualizacion, y pelearle con Hide
	-- termina en parpadeo.
	if PlayerLevelText then
		local hideLevel = AsuriOn()
			or (C.UnitFrameCustomTexture and C.pwFrames);
		PlayerLevelText:SetAlpha(hideLevel and 0 or 1);
	end
	
	if AsuriOn() then
		local host = _G["NidhausPlayerFrame"] or self;
		K.RestoreAnchors(self.healthbar, "PlayerHealthBarAnchors");
		self.healthbar:ClearAllPoints();
		self.healthbar:SetPoint("CENTER", host, "CENTER", 50, 7);
		self.healthbar:SetHeight(16);
		self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, 0);
		if self.manabar then
			self.manabar:ClearAllPoints();
			self.manabar:SetPoint("CENTER", host, "CENTER", 50, -7);
			self.manabar:SetHeight(13);
		end
	elseif C.UnitFrameCustomTexture then
		-- FIX: mismo doble anclaje que Target: restaurar el/los anclaje(s)
		-- default (post-MoveFrame) antes de sumar el TOPLEFT, para que la
		-- barra se estire correctamente en vez de quedar con un solo anclaje
		-- y flotar al costado tras un toggle (bug con Custom Positions).
		K.RestoreAnchors(self.healthbar, "PlayerHealthBarAnchors");
		self.healthbar:SetPoint("TOPLEFT", 106, -24);
		self.healthbar:SetHeight(28);
		self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
	else
		-- FIX: restaurar geometría de la barra y anclaje del texto default
		-- (capturados en init). Restaurar el ANCLAJE del texto es clave: el
		-- addon lo re-ancla a la barra, y ese cambio no se revierte solo →
		-- era la causa del texto flotando cuando el skin estaba apagado.
		K.RestoreBarGeometry(self.healthbar, "PlayerHealthBar");
		K.RestoreAnchors(self.healthbar.TextString, "PlayerHealthText");
	end
	if not AsuriOn() and self.manabar then
		K.RestoreAnchors(self.manabar, "PlayerManaBarAnchors");
	end

	-- Fondo negro de las barras: en Asuri se recorta al alto de vida+mana,
	-- si no queda un rectangulo grande sobresaliendo del marco.
	if PlayerFrameBackground then
		if AsuriOn() then
			PlayerFrameBackground:SetWidth(119);
			PlayerFrameBackground:SetHeight(29);
			PlayerFrameBackground:ClearAllPoints();
			PlayerFrameBackground:SetPoint("TOPLEFT", 106, -34);
		elseif PlayerFrameBackground._nufOrig then
			local o = PlayerFrameBackground._nufOrig;
			PlayerFrameBackground:SetWidth(o.w);
			PlayerFrameBackground:SetHeight(o.h);
			if o.pts and o.pts[1] then
				PlayerFrameBackground:ClearAllPoints();
				PlayerFrameBackground:SetPoint(o.pts[1], o.pts[2] or PlayerFrame,
					o.pts[3] or o.pts[1], o.pts[4] or 0, o.pts[5] or 0);
			end
		end
	end
	RuneFrame:ClearAllPoints();
	RuneFrame:SetPoint("TOP", NidhausPlayerFrame, "BOTTOM", 52, 34);

	PlayerFrameFlash:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash");
	PlayerFrameFlash:SetTexCoord(0.9453125, 0, 0, 0.181640625);
end;

-- FIX: local para evitar colisiones con otros addons
local function playerPvpIcon()
	local factionGroup = UnitFactionGroup("player");
	if factionGroup and factionGroup ~= "Neutral" and UnitIsPVP("player") then
		if C.UnitFrameCustomTexture and (C.darkFrames or C.pwFrames) then
			PlayerPVPIcon:SetTexture(ThemeDir() .. "UI-PVP-" .. factionGroup);
		else
			-- Default de Blizzard (también usado por el skin custom en modo Light)
			PlayerPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
		end;
	end;
end;

--	Player vehicle frame.
local function Nidhaus_UnitFrames_PlayerFrame_ToVehicleArt(self, vehicleType)
	if vehicleType == "Natural" then
		PlayerFrameFlash:SetTexture("Interface\\AddOns\\"..AddOnName.."\\Media\\Vehicles\\UI-Vehicle-Frame-Organic-Flash");
		PlayerFrameFlash:SetTexCoord(-0.02, 1, 0.07, 0.86);
		self.healthbar:SetSize(103, 12);
	else
		PlayerFrameFlash:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame-Flash");
		PlayerFrameFlash:SetTexCoord(-0.02, 1, 0.07, 0.86);
		self.healthbar:SetSize(100, 12);
	end;
	self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, 0);
end;

-- Pet frame
local function Nidhaus_UnitFrames_PetFrame_Update(self, override)
	if (not PlayerFrame.animating) or (override) then
		if UnitIsVisible(self.unit) and not PlayerFrame.vehicleHidesPet then
			if UnitPowerMax(self.unit) == 0 then
				PetFrameTexture:SetTexture(ThemeDir() .. "UI-SmallTargetingFrame-NoMana");
				PetFrameManaBarText:Hide();
			else
				PetFrameTexture:SetTexture(ThemeDir() .. "UI-SmallTargetingFrame");
			end;
		end;
	end;
end;

-- Backdrop;
local function ApplyBackdrop()
	if C.statusbarBackdrop then
		K.CreateBackdrop(PlayerFrame);
	end
end

function K.ApplyPlayerFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	if NidhausPlayerFrame then
		NidhausPlayerFrame:SetScale(scale);
	end
end

-- FIX: Aplica el toggle "Custom Skin" en tiempo real (sin /reload).
-- Re-corre nuestra rutina de arte completa, que ahora es idempotente:
-- en modo custom aplica las .blp; en modo default restaura el estado
-- original capturado en init. Como cada llamada deja un estado final
-- determinístico (no depende de "lo que había antes"), togglear rápido
-- muchas veces siempre termina en el estado correcto. Llamada desde
-- OptionsPanel.lua.
function K.ApplyPlayerFrameSkin()
	if not isInitialized then return; end
	-- No forzar arte de player si estás en vehículo (usa arte de vehículo)
	if UnitInVehicle and UnitInVehicle("player") then return; end
	Nidhaus_UnitFrames_PlayerFrame_ToPlayerArt(PlayerFrame);
	playerPvpIcon();
	-- El skin reancla los textos de vida/mana: avisar al modulo de texto
	-- abreviado para que recapture la posicion buena (si no, queda corrido).
	if K.InvalidateAbbrevAnchors then K.InvalidateAbbrevAnchors(); end
end

-- Escala del marco de la mascota (Frames > Pet)
function K.ApplyPetFrameScale(scale)
	scale = scale or C.PetFrameScale or 1.0;
	if PetFrame then PetFrame:SetScale(scale); end
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	-- Inicializar frame
	InitializePlayerFrame();

	-- Escala guardada de la mascota
	if K.ApplyPetFrameScale then K.ApplyPetFrameScale(C.PetFrameScale); end
	
	-- Aplicar estilos
	Nidhaus_UnitFrames_Style_PlayerFrame(PlayerFrame);
	
	-- Registrar hooks
	hooksecurefunc("PlayerFrame_ToPlayerArt", Nidhaus_UnitFrames_PlayerFrame_ToPlayerArt);
	hooksecurefunc("PlayerFrame_UpdatePvPStatus", playerPvpIcon);
	hooksecurefunc("PlayerFrame_ToVehicleArt", Nidhaus_UnitFrames_PlayerFrame_ToVehicleArt);
	hooksecurefunc("PetFrame_Update", Nidhaus_UnitFrames_PetFrame_Update);
	
	-- Aplicar backdrop
	ApplyBackdrop();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized and C.PlayerFrameScale then
		K.ApplyPlayerFrameScale(C.PlayerFrameScale);
	end
end);

-- FIX: Re-apply textures when UI scale or display mode changes
-- Blizzard resets PlayerFrameTexture/PVP icons to defaults on these events
local playerFrameEventWatcher = CreateFrame("Frame");
playerFrameEventWatcher:RegisterEvent("UI_SCALE_CHANGED");
playerFrameEventWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED");
playerFrameEventWatcher:SetScript("OnEvent", function(self)
	if not isInitialized then return; end
	-- Small delay to let Blizzard finish its own updates first
	local elapsed = 0;
	self:SetScript("OnUpdate", function(s, dt)
		elapsed = elapsed + dt;
		if elapsed >= 0.15 then
			s:SetScript("OnUpdate", nil);
			Nidhaus_UnitFrames_Style_PlayerFrame(PlayerFrame);
			Nidhaus_UnitFrames_PetFrame_Update(PetFrame, true);
			playerPvpIcon();
		end
	end);
end);