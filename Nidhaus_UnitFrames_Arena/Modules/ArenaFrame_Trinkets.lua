local AddOnName = ...;
-- Este addon se carga a pedido (ver Core/ArenaLoader.lua del addon
-- principal), asi que el "..." de arriba NO trae el namespace de NUF: es el
-- suyo propio. El de NUF se publica como global en Core/Init.lua.
local ns = NidhausUnitFramesNS;
local K, C, L = unpack(ns);
-- Las texturas y los sonidos NO se mudaron: siguen en la carpeta del addon
-- principal. AddOnName, aca, es "Nidhaus_UnitFrames_Arena".
local MEDIA_ADDON = "Nidhaus_UnitFrames";


local select, pairs, _G, UnitFactionGroup, IsInInstance, GetSpellInfo, GetTime =
	select, pairs, _G, UnitFactionGroup, IsInInstance, GetSpellInfo, GetTime;
local CooldownFrame_SetTimer = CooldownFrame_SetTimer;
local PlaySoundFile = PlaySoundFile;

local MAX_ARENA_ENEMIES = MAX_ARENA_ENEMIES or 5;
local MAX_PARTY = MAX_PARTY_MEMBERS or 4;

-- =========================================================
-- Trinkets y raciales que rompen control, por spellID.
--
-- POR QUE POR ID Y NO POR NOMBRE: antes se hacia
--   spell == GetSpellInfo(59752)
-- o sea, se resolvia el nombre localizado del hechizo y se comparaba
-- string contra string en CADA evento. Eso es mas lento y ademas se
-- rompe si el cliente esta en otro idioma que el esperado. El spellID
-- es el mismo en todos lados.
--
-- WILL OF THE FORSAKEN (7744) NO ES EL TRINKET.
--
-- Es la racial del no-muerto (su propio cooldown es de 2 minutos). Desde
-- el parche 3.3 comparte 45 segundos de cooldown con los efectos
-- parecidos -- el medallon PvP incluido --: si el no-muerto la usa, su
-- trinket queda bloqueado 45 s, NO 2 minutos, y despues lo tiene de
-- nuevo.
--
-- Antes se la anotaba como si hubiera usado el trinket (2 minutos): el
-- icono decia "sin trinket" hasta un minuto y cuarto despues de que en
-- realidad ya lo tenia de vuelta. Ahora marca los 45 s que dura el
-- bloqueo, y si el trinket ya estaba en un cooldown mas largo (lo habia
-- usado antes) no se lo acorta.
--
-- Every Man for Himself (humano) si comparte el cooldown entero con el
-- trinket: usarla es como usar el trinket, 2 minutos.
-- =========================================================
local WOTF_SHARED_CD = 45;   -- bloqueo del trinket por Will of the Forsaken

local TRINKET_SPELLS = {
	[42292] = { cd = 120, voice = "Trinket" },              -- Medallon PvP (ambas facciones)
	[59752] = { cd = 120, voice = "Trinket" },              -- Every Man for Himself (humano)
	[7744]  = { cd = WOTF_SHARED_CD, shared = true,          -- Voluntad de los Renegados
	            voice = "WillOfTheForsaken" },
};

-- Hasta cuando esta en cooldown cada icono. El marco Cooldown de 3.3.5 no
-- dice cuanto le queda, y hace falta saberlo para no acortar un trinket
-- de 2 minutos con el bloqueo de 45 s de la racial.
local trinketExpire = {};   -- [marco cooldown] = GetTime() de fin

ns.ArenaFrame_Trinkets = CreateFrame("Frame");
local Core = ns.ArenaFrame_Trinkets;

Core:RegisterEvent("ADDON_LOADED");
Core:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end);

Core.addonLoaded = false;
Core.created = false;
Core.frames = {};
-- Mapa unitID -> frame de cooldown. Incluye arena Y party, para poder
-- resolver por GUID sin importar de que tipo de unidad se trate.
Core.cooldowns = {};
Core.partyFrames = {};
-- GUID -> unitID. Se llena cuando la unidad es visible (ver RefreshGUIDCache)
Core.guidCache = {};

local function IsEnabled()
	return C.ArenaFrameOn and C.ArenaFrame_Trinkets;
end

-- Los trinkets de party son independientes de los de arena: pueden estar
-- prendidos con el rastreo de arena apagado y al reves. El combat log se
-- necesita si CUALQUIERA de los dos esta activo.
local function AnyTrinketEnabled()
	return IsEnabled() or (C.PartyTrinketsEnabled == true);
end

-- Posiciones DE FABRICA del modo Flat.
--
-- El modo Flat rearma los marcos por completo, asi que los lugares
-- utiles del trinket y de la barra de casteo no son los mismos que en
-- Custom. Estos valores salieron de dejarlos acomodados en el juego y
-- son los que se usan mientras Flat este activo y el usuario no haya
-- movido nada todavia.
local FLAT_DEFAULT = { "CENTER", "CENTER", 78.2, 9 };
-- Con el modo espejo la de fabrica va del otro lado del marco.
local FLAT_DEFAULT_MIRROR = { "CENTER", "CENTER", -78.2, 9 };

-- Lo guardado para el modo puesto (estilo + espejo), o nil.
function K.GetSavedTrinketPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.TrinketPositions;
	if not db then return nil; end
	local key = K.GetArenaPositionKey and K.GetArenaPositionKey()
		or ((C.ArenaFrameStyle or "Custom") .. (C.ArenaMirrorMode and "_mirror" or "_normal"));
	return db[key];
end

-- DONDE VA EL TRINKET: lo guardado para el modo puesto, o el lugar de
-- fabrica de ese modo. Es la UNICA cuenta: antes habia cinco copias y no
-- coincidian (fuera de Flat lo guardado se ignoraba y el trinket volvia
-- solo a su lugar en cada recarga del marco; y sin nada guardado se
-- quedaba donde lo habias dejado en el estilo anterior).
function K.GetArenaTrinketPoint()
	local saved = K.GetSavedTrinketPos();
	if type(saved) == "table" and saved[1] then return saved; end
	if K.IsFlatModeActive and K.IsFlatModeActive() then
		return C.ArenaMirrorMode and FLAT_DEFAULT_MIRROR or FLAT_DEFAULT;
	end
	if C.ArenaMirrorMode then
		return { "BOTTOMRIGHT", "BOTTOMLEFT", -8, 0 };
	end
	return { "BOTTOMLEFT", "BOTTOMRIGHT", 8, 0 };
end

local function TrinketBorder(index)
	local b = _G["NidhausArenaTrinketBorder" .. index];
	if b then return b; end
	local t = Core.frames and Core.frames[index];
	return t and t.border;
end

function K.PositionArenaTrinket(index)
	local border = TrinketBorder(index);
	local af = _G["ArenaEnemyFrame" .. index];
	if not (border and af) or border._isMoving then return; end
	local p = K.GetArenaTrinketPoint();
	border:ClearAllPoints();
	border:SetPoint(p[1], af, p[2], p[3] or 0, p[4] or 0);
end

function K.PositionArenaTrinkets()
	for i = 1, (MAX_ARENA_ENEMIES or 5) do K.PositionArenaTrinket(i); end
end

function Core:CreateTrinket(Frame, Index)
	if not Frame then 
		return;
	end
	
	local Border = CreateFrame("Frame", "NidhausArenaTrinketBorder"..Index, Frame);
	Border:SetFrameStrata("MEDIUM");

	-- Ya en su lugar del modo puesto (guardado o de fabrica).
	do
		local p = K.GetArenaTrinketPoint();
		Border:SetPoint(p[1], Frame, p[2], p[3] or 0, p[4] or 0);
	end

	Border:SetSize(32, 32);
	Border:SetMovable(true);
	-- Mouse deshabilitado por defecto; se activa solo en test mode + Flat style
	Border:EnableMouse(false);

	Border:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 4,
		insets = {left = 2, right = 2, top = 2, bottom = 2}
	});

	if C.darkFrames then
		Border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1);
	else
		Border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1);
	end

	local Trinket = CreateFrame("Frame", nil, Frame);
	Trinket:SetFrameStrata("MEDIUM");
	Trinket:SetFrameLevel(Border:GetFrameLevel() - 2);
	Trinket:SetPoint("CENTER", Border, 0, 0);
	Trinket:SetSize(32, 32);

	Trinket.icon = Trinket:CreateTexture(nil, "BACKGROUND");
	Trinket.icon:SetAllPoints();

	local faction = select(1, UnitFactionGroup("player"));
	if faction == "Alliance" then
		Trinket.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_01");
	elseif faction == "Horde" then
		Trinket.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_02");
	end

	local CoolDownFrame = CreateFrame("Cooldown", nil, Trinket, "CooldownFrameTemplate");
	CoolDownFrame:SetAllPoints(Trinket);

	-- sArena-style drag: OnMouseDown/OnMouseUp (NO OnUpdate)
	-- Funciona en Flat mode y en Test mode (Shift+Alt+Click)
	Border:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return; end
		if InCombatLockdown() then return; end
		-- Permitir drag en Flat mode O en test mode
		local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
		local isTestMode = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
			and NidhausUnitFramesDB.ArenaMover.IsShown;
		if not (isFlat or isTestMode) then return; end
		if IsShiftKeyDown() and IsAltKeyDown() and not self._isMoving then
			self:StartMoving();
			self:SetUserPlaced(false);
			self._isMoving = true;
		end
	end);

	Border:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then return; end
		if not self._isMoving then return; end
		self:StopMovingOrSizing();
		self._isMoving = false;

		local arenaFrame = self:GetParent();
		if not arenaFrame then return; end

		local parentX, parentY = arenaFrame:GetCenter();
		local frameX, frameY = self:GetCenter();
		if not parentX or not frameX then return; end

		local scale = self:GetScale();
		local offsetX = ((frameX * scale) - parentX) / scale;
		local offsetY = ((frameY * scale) - parentY) / scale;

		offsetX = math.floor(offsetX * 10 + 0.5) / 10;
		offsetY = math.floor(offsetY * 10 + 0.5) / 10;

		self:ClearAllPoints();
		self:SetPoint("CENTER", arenaFrame, "CENTER", offsetX, offsetY);

		if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
		if not NidhausUnitFramesDB.TrinketPositions then NidhausUnitFramesDB.TrinketPositions = {}; end
		local posKey = K.GetArenaPositionKey and K.GetArenaPositionKey() or (C.ArenaMirrorMode and "mirror" or "normal");
		NidhausUnitFramesDB.TrinketPositions[posKey] = {"CENTER", "CENTER", offsetX, offsetY};

		for i = 1, MAX_ARENA_ENEMIES do
			local trinketFrame = Core.frames[i];
			if trinketFrame and trinketFrame.border then
				local af = _G["ArenaEnemyFrame"..i];
				if af then
					trinketFrame.border:ClearAllPoints();
					trinketFrame.border:SetPoint("CENTER", af, "CENTER", offsetX, offsetY);
				end
			end
		end
	end);

	-- Failsafe: stop drag si el frame se oculta
	Border:SetScript("OnHide", function(self)
		if self._isMoving then
			self:StopMovingOrSizing();
			self._isMoving = false;
		end
	end);

	Core["arena"..Index] = CoolDownFrame;
	Core.frames[Index] = { border = Border, trinket = Trinket };
	Core.cooldowns["arena"..Index] = CoolDownFrame;

	if not IsEnabled() then
		Border:Hide();
		Trinket:Hide();
	end
end

function Core:TryCreate()
	if self.created then return end
	if not self.addonLoaded then return end
	
	local allFramesExist = true;
	for i = 1, MAX_ARENA_ENEMIES do
		if not _G["ArenaEnemyFrame"..i] then
			allFramesExist = false;
			break;
		end
	end
	
	if not allFramesExist then return end

	local success, err = pcall(function()
		for i = 1, MAX_ARENA_ENEMIES do
			self:CreateTrinket(_G["ArenaEnemyFrame"..i], i);
		end
	end);
	
	if not success then
		return;
	end

	self.created = true;
	self:PLAYER_ENTERING_WORLD();
end

-- =========================================================
-- ARRANQUE QUE NO DEPENDE DE UN EVENTO QUE YA PASO
--
-- Los iconos se armaban al oir el ADDON_LOADED de Blizzard_ArenaUI. Eso
-- andaba mientras este archivo vivia en el addon principal, que se carga
-- al entrar al juego: ya estaba escuchando mucho antes de que a nadie se
-- le ocurriera abrir una arena.
--
-- Con el paquete de arena a pedido se dio vuelta. La forma NORMAL de que
-- este archivo exista es justamente ese ADDON_LOADED: es el que dispara
-- la carga (ver Core/ArenaLoader.lua del addon principal). O sea que el
-- archivo empieza a correr MIENTRAS el evento se esta repartiendo, y
-- registrarse para el llega tarde: no se oye nunca. addonLoaded se queda
-- en false, TryCreate no corre y no aparece NINGUN trinket -- y como el
-- combat log se registra recien ahi, tampoco se marca el cooldown.
--
-- Por eso ya no se depende del evento:
--   * si Blizzard_ArenaUI YA esta cargado, se arma en el acto;
--   * PLAYER_ENTERING_WORLD queda registrado SIEMPRE (antes se registraba
--     adentro de TryCreate, o sea solo si ya habia salido bien: si fallaba
--     una vez no habia segundo intento);
--   * ARENA_OPPONENT_UPDATE reintenta, que es el momento en que los
--     marcos enemigos existen con seguridad.
--
-- No se fuerza LoadAddOn("Blizzard_ArenaUI") aca: si todavia no esta, se
-- arma en alguno de los reintentos. Cargarlo de prepo en cada login seria
-- devolver la memoria que se gano al separar el paquete de arena.
-- =========================================================
function Core:Bootstrap()
	if self.created then return true; end
	if not self.addonLoaded and IsAddOnLoaded and IsAddOnLoaded("Blizzard_ArenaUI") then
		self.addonLoaded = true;
	end
	if not self.addonLoaded then return false; end
	self:ApplyState();
	return self.created and true or false;
end

function Core:ShowAll()
	for i = 1, MAX_ARENA_ENEMIES do
		local f = self.frames[i];
		if f then
			f.border:Show();
			f.trinket:Show();
		end
	end
end

function Core:HideAll()
	for i = 1, MAX_ARENA_ENEMIES do
		local f = self.frames[i];
		if f then
			f.border:Hide();
			f.trinket:Hide();
		end
	end

	-- Los de party usan el mismo combat log: si siguen prendidos, no se corta.
	if not AnyTrinketEnabled() and self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	end

	for i = 1, MAX_ARENA_ENEMIES do
		if self["arena"..i] then
			CooldownFrame_SetTimer(self["arena"..i], GetTime(), 0, 1);
			trinketExpire[self["arena"..i]] = nil;
		end
	end
end

function Core:ApplyState()
	if not IsEnabled() then
		if self.created then
			self:HideAll();
		end
		-- Los trinkets de party no dependen de este interruptor: se arman y
		-- escuchan igual (sin esto, cargando en la arena no andaban nunca).
		self:RefreshTracking();
		return
	end

	-- FIX: Si Blizzard_ArenaUI ya está cargado pero ADDON_LOADED no se disparó
	-- (porque el addon se habilitó después del load), setear el flag manualmente.
	-- Sin esto, addonLoaded quedaba en false y TryCreate() nunca se ejecutaba.
	if not self.addonLoaded then
		if IsAddOnLoaded("Blizzard_ArenaUI") then
			self.addonLoaded = true;
		else
			LoadAddOn("Blizzard_ArenaUI");
			-- Si LoadAddOn tuvo éxito, setear flag (ADDON_LOADED puede no dispararse sincrónicamente)
			if IsAddOnLoaded("Blizzard_ArenaUI") then
				self.addonLoaded = true;
			end
		end
	end

	self:TryCreate();
	if self.created then
		self:ShowAll();
		self:PLAYER_ENTERING_WORLD();
	end
end

function Core:ADDON_LOADED(addonName)
	if addonName ~= "Blizzard_ArenaUI" then return; end
	self.addonLoaded = true;
	self:UnregisterEvent("ADDON_LOADED");
	self:ApplyState();
end

function Core:PLAYER_ENTERING_WORLD()
	-- Reintento. Entrar a una arena puede ser la primera vez que
	-- Blizzard_ArenaUI existe; Bootstrap corta solo si ya esta armado, y el
	-- guard de aca es el que corta la recursion (TryCreate vuelve a llamar
	-- a esta funcion al terminar).
	if not self.created then self:Bootstrap(); end
	self:RefreshTracking();
end

-- Party + combat log segun donde estes. Va aparte para que ApplyState la
-- pueda llamar con el rastreo de arena apagado sin volver a Bootstrap.
function Core:RefreshTracking()
	-- Los de party se arman SIEMPRE que su propio checkbox este activo,
	-- sin importar el estado del rastreo de arena.
	self:SetupPartyTrinkets();
	self:ShowPartyTrinkets(C.PartyTrinketsEnabled);

	if not AnyTrinketEnabled() then
		if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
		return
	end

	local _, instanceType = IsInInstance();
	if instanceType == "arena" then
		if not self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
		-- Arena nueva: los GUIDs viejos ya no sirven
		self:WipeGUIDCache();
		if not self:IsEventRegistered("ARENA_OPPONENT_UPDATE") then
			self:RegisterEvent("ARENA_OPPONENT_UPDATE");
		end
		if not self:IsEventRegistered("PARTY_MEMBERS_CHANGED") then
			self:RegisterEvent("PARTY_MEMBERS_CHANGED");
		end
		self:RefreshGUIDCache();
	else
		-- Fuera de arena no hace falta escuchar el combat log
		if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		end
		if self:IsEventRegistered("ARENA_OPPONENT_UPDATE") then
			self:UnregisterEvent("ARENA_OPPONENT_UPDATE");
		end
		if self:IsEventRegistered("PARTY_MEMBERS_CHANGED") then
			self:UnregisterEvent("PARTY_MEMBERS_CHANGED");
		end
		self:WipeGUIDCache();
		for i = 1, MAX_ARENA_ENEMIES do
			if self["arena"..i] then
				CooldownFrame_SetTimer(self["arena"..i], GetTime(), 0, 1);
				trinketExpire[self["arena"..i]] = nil;
			end
		end
	end
end


-- =========================================================
-- TRINKETS DE PARTY
--
-- NUF solo cubria arena. Saber si tu healer todavia tiene trinket vale
-- tanto como saberlo del enemigo, asi que se agrega el mismo icono al
-- lado de cada marco de party.
--
-- Se crean una sola vez y quedan siempre visibles (con el cooldown
-- vacio cuando no se uso nada). Se cuelgan del marco de party, asi que
-- siguen su escala y posicion sin codigo extra.
-- =========================================================
-- Offset COMPARTIDO por los 4: se arrastra uno y los otros tres siguen.
-- Se guarda como desplazamiento respecto del marco de party, no como
-- posicion absoluta, para que aguante cambios de escala y de posicion
-- de los marcos sin quedar desalineado.
local function PartyTrinketDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.PartyTrinket then
		NidhausUnitFramesDB.PartyTrinket = {};
	end
	return NidhausUnitFramesDB.PartyTrinket;
end

local PT_DEFAULT_X, PT_DEFAULT_Y = 4, 0;

function Core:ApplyPartyTrinketLayout()
	local db   = PartyTrinketDB();
	local x    = db.x or PT_DEFAULT_X;
	local y    = db.y or PT_DEFAULT_Y;
	local size = C.PartyTrinketSize or 20;

	for i = 1, MAX_PARTY do
		local f = self.partyFrames[i];
		if f then
			f.holder:SetSize(size, size);
			f.holder:ClearAllPoints();
			f.holder:SetPoint("LEFT", f.holder:GetParent(), "RIGHT", x, y);
		end
	end
end

function Core:SetupPartyTrinkets()
	if not C.PartyTrinketsEnabled then return; end

	for i = 1, MAX_PARTY do
		local parent = _G["PartyMemberFrame"..i];
		if parent and not self.partyFrames[i] then
			local holder = CreateFrame("Frame", "NidhausPartyTrinket"..i, parent);
			holder:SetSize(C.PartyTrinketSize or 20, C.PartyTrinketSize or 20);
			holder:SetPoint("LEFT", parent, "RIGHT", PT_DEFAULT_X, PT_DEFAULT_Y);
			holder:SetFrameStrata("MEDIUM");
			holder:SetMovable(true);
			holder:EnableMouse(false);

			holder.icon = holder:CreateTexture(nil, "BACKGROUND");
			holder.icon:SetAllPoints();

			-- Icono segun la faccion del jugador: en party sos aliado,
			-- asi que comparten faccion.
			local faction = select(1, UnitFactionGroup("player"));
			if faction == "Horde" then
				holder.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_02");
			else
				holder.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_01");
			end

			local cd = CreateFrame("Cooldown", nil, holder, "CooldownFrameTemplate");
			cd:SetAllPoints(holder);

			-- Overlay de arrastre (solo visible en modo mover)
			holder.dragHint = holder:CreateTexture(nil, "OVERLAY");
			holder.dragHint:SetAllPoints();
			holder.dragHint:SetTexture(0, 0.7, 1, 0.35);
			holder.dragHint:Hide();

			-- Al soltar se calcula el offset y se aplica a LOS CUATRO
			holder:SetScript("OnMouseDown", function(self, button)
				if button ~= "LeftButton" or not Core.partyMoveMode then return; end
				if InCombatLockdown() then return; end
				self:StartMoving();
				self._moving = true;
			end);
			holder:SetScript("OnMouseUp", function(self, button)
				if not self._moving then return; end
				self:StopMovingOrSizing();
				self._moving = false;

				local parentFrame = self:GetParent();
				if not parentFrame then return; end

				-- El ancla es LEFT del icono contra RIGHT del marco, y ambos
				-- puntos estan centrados verticalmente. Entonces:
				--   x = borde izquierdo del icono - borde derecho del marco
				--   y = centro del icono - centro del marco
				--
				-- BUG que tenia: calculaba el Y mezclando GetTop() con medias
				-- alturas, asi que al soltar el icono saltaba a otro lado. Se
				-- sentia "imantado" porque ApplyPartyTrinketLayout lo re-anclaba
				-- enseguida con un offset mal calculado.
				local pRight            = parentFrame:GetRight();
				local sLeft             = self:GetLeft();
				local _,      pCenterY  = parentFrame:GetCenter();
				local _,      sCenterY  = self:GetCenter();
				if not (pRight and sLeft and pCenterY and sCenterY) then return; end

				local db = PartyTrinketDB();
				db.x = sLeft    - pRight;
				db.y = sCenterY - pCenterY;
				Core:ApplyPartyTrinketLayout();
			end);
			holder:SetScript("OnHide", function(self)
				if self._moving then
					self:StopMovingOrSizing();
					self._moving = false;
				end
			end);

			self.partyFrames[i]         = { holder = holder, cd = cd };
			self.cooldowns["party"..i]  = cd;
		end
	end

	self:ApplyPartyTrinketLayout();
end

function Core:ShowPartyTrinkets(show)
	show = show and C.PartyTrinketsEnabled;
	for i = 1, MAX_PARTY do
		local f = self.partyFrames[i];
		if f then
			if show then f.holder:Show(); else f.holder:Hide(); end
		end
	end
end

-- ── API para el panel de opciones ────────────────────────
Core.partyMoveMode = false;

function K.SetPartyTrinketMoveMode(state)
	Core.partyMoveMode = state and true or false;
	Core:SetupPartyTrinkets();

	-- Los trinkets cuelgan de PartyMemberFrameN: si no hay grupo, el padre
	-- esta oculto y el hijo no se dibuja por mas que lo mostremos. Se
	-- enciende el modo prueba para poder acomodarlos estando solo.
	if K.SetPartyTestMode and not InCombatLockdown() then
		if Core.partyMoveMode then
			if not (K.IsPartyTestMode and K.IsPartyTestMode()) then
				Core._startedTestMode = true;
				K.SetPartyTestMode(true);
			end
		elseif Core._startedTestMode then
			Core._startedTestMode = nil;
			K.SetPartyTestMode(false);
		end
	end

	for i = 1, MAX_PARTY do
		local f = Core.partyFrames[i];
		if f then
			f.holder:EnableMouse(Core.partyMoveMode);
			if Core.partyMoveMode then
				f.holder.dragHint:Show();
				f.holder:Show();
				-- Cooldown de muestra para que se vea algo mientras se acomoda
				CooldownFrame_SetTimer(f.cd, GetTime(), 120, 1);
			else
				f.holder.dragHint:Hide();
				CooldownFrame_SetTimer(f.cd, GetTime(), 0, 1);
				if not C.PartyTrinketsEnabled then f.holder:Hide(); end
			end
		end
	end
end

function K.IsPartyTrinketMoveMode()
	return Core.partyMoveMode;
end

function K.ResetPartyTrinketPosition()
	local db = PartyTrinketDB();
	db.x, db.y = nil, nil;
	Core:ApplyPartyTrinketLayout();
end

function K.ApplyPartyTrinketSettings()
	Core:SetupPartyTrinkets();
	Core:ApplyPartyTrinketLayout();
	Core:ShowPartyTrinkets(C.PartyTrinketsEnabled);
end

-- =========================================================
-- DETECCION POR COMBAT LOG
--
-- POR QUE SE CAMBIO: antes esto usaba UNIT_SPELLCAST_SUCCEEDED
-- filtrando por el token "arenaX". Ese evento SOLO dispara si el token
-- es valido en ese instante, y en 3.3.5a los tokens de arena se
-- invalidan cuando el cliente no "ve" al enemigo: en sigilo, fuera de
-- rango, o antes de que la UI de arena lo registre. Resultado: si el
-- picaro trinketeaba desde sigilo, el trinket no se marcaba nunca.
--
-- El combat log reporta por GUID y no le importa la visibilidad, asi
-- que se entera igual. Es la razon por la que otros addons de trinket
-- se sienten mas confiables.
-- =========================================================

-- ── Cache de GUIDs ──────────────────────────────────────
-- Preguntar UnitGUID("arena1") en el momento del trinket NO alcanza:
-- si el picaro esta en sigilo el token no es valido y UnitExists da
-- false, que es exactamente el caso que queremos cubrir. (El addon
-- ArenaPartyTrinkets tiene este mismo agujero.)
--
-- Solucion: cachear el GUID de cada unidad CADA VEZ que si es visible,
-- y despues resolver contra el cache. Al principio de la ronda todos
-- son visibles al menos un instante, asi que para cuando alguien se
-- mete en sigilo ya sabemos que GUID le corresponde.
function Core:RefreshGUIDCache()
	for unit in pairs(self.cooldowns) do
		if UnitExists(unit) then
			local guid = UnitGUID(unit);
			if guid then self.guidCache[guid] = unit; end
		end
	end
end

function Core:WipeGUIDCache()
	for k in pairs(self.guidCache) do self.guidCache[k] = nil; end
end

-- Resuelve un GUID a su frame de cooldown (arena o party)
function Core:FindCooldownByGUID(guid)
	if not guid then return nil; end

	-- 1) Por cache: funciona aunque la unidad este en sigilo o fuera de rango
	local unit = self.guidCache[guid];
	if unit and self.cooldowns[unit] then
		return self.cooldowns[unit];
	end

	-- 2) Fallback en vivo, por si el cache todavia no vio a esta unidad
	for u, cdFrame in pairs(self.cooldowns) do
		if UnitExists(u) and UnitGUID(u) == guid then
			self.guidCache[guid] = u;
			return cdFrame;
		end
	end

	return nil;
end

-- Cada vez que un enemigo aparece o el grupo cambia, actualizar el cache
function Core:ARENA_OPPONENT_UPDATE()
	-- Tambien es reintento: aca los marcos enemigos existen con seguridad.
	-- Con el rastreo de arena apagado no hay nada que armar.
	if not self.created and IsEnabled() then self:Bootstrap(); end
	if AnyTrinketEnabled() then self:RefreshGUIDCache(); end
end

function Core:PARTY_MEMBERS_CHANGED()
	if AnyTrinketEnabled() then
		self:RefreshGUIDCache();
		self:SetupPartyTrinkets();
	end
end

function Core:COMBAT_LOG_EVENT_UNFILTERED(timestamp, eventType,
	srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID)

	if not AnyTrinketEnabled() then return; end
	if eventType ~= "SPELL_CAST_SUCCESS" then return; end

	local info = TRINKET_SPELLS[spellID];
	if not info then return; end

	local cdFrame = self:FindCooldownByGUID(srcGUID);
	if not cdFrame then return; end

	-- La racial solo bloquea el trinket 45 s: si ya estaba en un cooldown
	-- mas largo, se deja como esta (la voz si suena: avisa que la uso).
	local now = GetTime();
	local left = (trinketExpire[cdFrame] or 0) - now;
	if not (info.shared and left >= info.cd) then
		trinketExpire[cdFrame] = now + info.cd;
		CooldownFrame_SetTimer(cdFrame, now, info.cd, 1);
	end

	if C.ArenaFrame_Trinket_Voice and info.voice then
		pcall(function()
			PlaySoundFile("Interface\\Addons\\"..MEDIA_ADDON.."\\Media\\Voice\\"..info.voice..".mp3");
		end);
	end
end

function K.ToggleArenaTrinketsTracking(enabled)
	C.ArenaFrame_Trinkets = enabled and true or false;
	if ns and ns.ArenaFrame_Trinkets and ns.ArenaFrame_Trinkets.ApplyState then
		ns.ArenaFrame_Trinkets:ApplyState();
	end
end

-- Habilita/deshabilita mouse en trinkets. Funciona en Flat mode y Test mode.
function K.SetTrinketMouseState(state)
	if not Core.frames then return; end
	-- FIX: Also check K._testModeActive — the DB flag IsShown may not be set yet
	-- when this is called during test mode setup (timing issue)
	local isFlat = K.IsFlatModeActive and K.IsFlatModeActive();
	local isTestMode = K._testModeActive or (NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
		and NidhausUnitFramesDB.ArenaMover.IsShown);
	local enableMouse = state and (isFlat or isTestMode);
	for i = 1, MAX_ARENA_ENEMIES do
		local f = Core.frames[i];
		if f and f.border then
			f.border:EnableMouse(enableMouse or false);
			if not enableMouse and f.border._isMoving then
				f.border:StopMovingOrSizing();
				f.border._isMoving = false;
			end
		end
	end
end

-- FIX: Actualizar color del borde de trinkets cuando cambia darkFrames
-- Sin esto, cambiar el tema dark/light no actualiza los bordes hasta /reload
function K.UpdateTrinketBorderColors()
	if not Core.frames then return; end
	for i = 1, MAX_ARENA_ENEMIES do
		local f = Core.frames[i];
		if f and f.border then
			if C.darkFrames then
				f.border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1);
			else
				f.border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1);
			end
		end
	end
end

-- ---------------------------------------------------------
-- ENGANCHES DE ARRANQUE
--
-- Ver "ARRANQUE QUE NO DEPENDE DE UN EVENTO QUE YA PASO", mas arriba.
-- Los dos eventos quedan registrados desde que el archivo carga, no desde
-- que TryCreate sale bien, y se intenta armar una vez en el acto por si
-- Blizzard_ArenaUI ya estaba (que es el caso normal ahora).
-- ---------------------------------------------------------
Core:RegisterEvent("PLAYER_ENTERING_WORLD");
Core:RegisterEvent("ARENA_OPPONENT_UPDATE");
Core:Bootstrap();
