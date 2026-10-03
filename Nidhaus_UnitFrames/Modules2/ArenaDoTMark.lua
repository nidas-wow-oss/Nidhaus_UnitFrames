-- =========================================================
-- ArenaDoTMark  ·  Aviso de DoTs en los marcos de arena enemigos.
--
-- Al lado de cada marco aparece "DoT" en rojo + los iconos de los DoTs que
-- tiene ese enemigo. Funciona AUNQUE no lo tengas de target ni focus: se
-- apoya en el combat log, no en UnitDebuff. Sirve para no romperte el
-- Arrepentimiento / Polimorfia / Trampa con un tick de dano.
--
-- Como detecta:
--  * Cada SPELL_PERIODIC_DAMAGE sobre un enemigo de arena lo marca durante
--    DOT_GRACE segundos (se renueva con cada tick). No hace falta lista de
--    hechizos: tambien agarra sangrados y DoTs que no esten en KNOWN_DOTS.
--  * Para los DoTs de KNOWN_DOTS, ademas se marca apenas cae el debuff (sin
--    esperar el primer tick) y se saca apenas se va.
--  * Un tick absorbido por un escudo (SPELL_PERIODIC_MISSED / ABSORB) tambien
--    cuenta: el DoT sigue ahi y rompe el CC apenas se cae el escudo.
-- Solo escucha el combat log dentro de una arena.
--
-- Limite: si un DoT es nuevo y todavia no hizo tick, un hechizo fuera de
-- KNOWN_DOTS recien se ve en el primer tick (hasta ~3 s).
--
-- OPCIONES (pestaña Arena > DoT):
--   C.ArenaDoTWarn     prendido / apagado
--   C.ArenaDoTSize     tamaño de los iconos (el texto "DoT" acompaña)
--   C.ArenaDoTSpacing  separacion
--   C.ArenaDoTMax      cuantos iconos como maximo
--   C.ArenaDoTGrow     AUTO / LEFT / RIGHT / UP / DOWN
--   C.ArenaDoTLabel    mostrar el texto "DoT"
--   C.ArenaDoTBorder   borde rojo (si no, borde negro fino)
--
-- POSICION. Sin posicion guardada va debajo del marco. Con el modo Test de
-- arena prendido aparece la vista previa: Shift+Alt+arrastrar la mueve (las
-- cinco filas a la vez). Se guarda por estilo + espejo, como el trinket
-- (NidhausUnitFramesDB.ArenaDoTPositions).
--
-- Prueba:  /nufdot        (vista previa: prende el modo Test de arena)
--          /nufdot clear  (la apaga)
-- =========================================================
local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local GetTime, UnitGUID, UnitExists, GetSpellInfo, IsInInstance =
	GetTime, UnitGUID, UnitExists, GetSpellInfo, IsInInstance;
local ipairs, pairs, tinsert, tremove, select, max, min, floor =
	ipairs, pairs, table.insert, table.remove, select, math.max, math.min, math.floor;

local MAX_ARENA = MAX_ARENA_ENEMIES or 5;

-- ---------- Fijos ----------
local DOT_GRACE = 4.5;   -- segundos sin tick para dar el DoT por terminado
local KNOWN_TTL = 30;    -- un DoT conocido marcado al caer el debuff se queda
                         -- hasta el "aura removed" (Curse of Doom no hace
                         -- ticks); esto es solo el tope por si ese aviso
                         -- no llega (enemigo fuera de rango del log)
local OFFSET_Y  = -4;    -- posicion auto: debajo del marco (en Flat el pet
                         -- asoma 3 px por debajo del marco)
local DEF_SIZE, DEF_GAP, DEF_MAX = 16, 2, 3;
local MAX_CAP   = 6;     -- tope del slider "maximo de iconos"

-- DoTs conocidos (cualquier rank). Para el aviso inmediato.
-- (Por nombre: casi todos los ranks comparten nombre. Los venenos no:
-- "Deadly Poison IX" es otro nombre, por eso van los ranks altos aparte.)
local KNOWN_DOT_IDS = {
	-- Brujo
	172, 980, 30108, 348, 27243, 603, 47960, 17962,  -- Corruption, Agony, UA, Immolate, Seed, Doom, Shadowflame, Conflagrate
	-- Sacerdote
	589, 34914, 2944, 14914,                          -- SW:Pain, VT, Devouring Plague, Holy Fire
	-- Druida
	8921, 5570, 1079, 1822, 33745, 9007,              -- Moonfire, Insect Swarm, Rip, Rake, Lacerate, Pounce Bleed
	-- Picaro
	703, 1943, 2818, 57969, 57970,                    -- Garrote, Rupture, Deadly Poison (I, VIII, IX)
	-- Cazador
	1978, 3674, 53301, 63468,                         -- Serpent Sting, Black Arrow, Explosive Shot, Piercing Shots
	-- (el DoT de Wyvern Sting NO va: el sueño se llama igual y marcaria
	-- "DoT" a alguien dormido. Lo agarra el tick generico.)
	-- Mago
	44457, 11366, 12654, 44614,                       -- Living Bomb, Pyroblast, Ignite, Frostfire Bolt
	-- Chaman
	8050,                                             -- Flame Shock
	-- DK
	55095, 55078, 50536,                              -- Frost Fever, Blood Plague, Unholy Blight
	-- Guerrero
	772, 12721,                                       -- Rend, Deep Wounds
	-- Paladin
	31803, 53742, 61840,                              -- Holy Vengeance, Blood Corruption, Righteous Vengeance
};
local knownDot = {};
for _, id in ipairs(KNOWN_DOT_IDS) do
	local name = GetSpellInfo(id);
	if name then knownDot[name] = true; end
end

-- ---------- Estado ----------
-- dots[idx] = lista de { name, icon, expire, preview }
local dots = {};
local holders = {};
local guidToIdx = {};
local enabled = false;   -- opcion prendida
local listening = false; -- escuchando el combat log (prendida + en arena)
local previewOn = false; -- vista previa (modo Test de arena)

local function InArena()
	local _, instanceType = IsInInstance();
	return instanceType == "arena";
end

local function IsTestMode()
	return K._testModeActive or (NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaMover
		and NidhausUnitFramesDB.ArenaMover.IsShown) and true or false;
end

local function RefreshGUIDs()
	for i = 1, MAX_ARENA do
		local u = "arena" .. i;
		if UnitExists(u) then
			local g = UnitGUID(u);
			if g then guidToIdx[g] = i; end
		end
	end
end

local function IdxFromGUID(guid)
	local i = guidToIdx[guid];
	if i then return i; end
	RefreshGUIDs();
	return guidToIdx[guid];
end

-- ---------- Opciones ----------
local function OptSize()
	local s = tonumber(C.ArenaDoTSize) or DEF_SIZE;
	if s < 10 then s = 10; elseif s > 40 then s = 40; end
	return s;
end
local function OptGap()
	local g = tonumber(C.ArenaDoTSpacing) or DEF_GAP;
	if g < 0 then g = 0; elseif g > 20 then g = 20; end
	return g;
end
local function OptMax()
	local m = floor(tonumber(C.ArenaDoTMax) or DEF_MAX);
	if m < 1 then m = 1; elseif m > MAX_CAP then m = MAX_CAP; end
	return m;
end
local GROW_OK = { AUTO = true, LEFT = true, RIGHT = true, UP = true, DOWN = true };
local function OptGrow()
	local g = C.ArenaDoTGrow;
	return GROW_OK[g] and g or "AUTO";
end

-- ---------- Posicion guardada (por estilo + espejo) ----------
local function PosKey()
	if K.GetArenaPositionKey then return K.GetArenaPositionKey(); end
	return C.ArenaMirrorMode and "mirror" or "normal";
end

-- { x, y, dir }: dir es hacia donde crecia la fila al soltarla. Con la
-- direccion en Auto se respeta esa: antes se recalculaba segun de que lado
-- del centro del marco habia quedado, y al soltar un poco del otro lado
-- la fila se daba vuelta (parecia que "se imantaba" a cualquier lado).
local DIR_OK = { LEFT = true, RIGHT = true, UP = true, DOWN = true };
local function GetSavedPos()
	local db = NidhausUnitFramesDB and NidhausUnitFramesDB.ArenaDoTPositions;
	local p = db and db[PosKey()];
	if type(p) == "table" and tonumber(p[1]) and tonumber(p[2]) then
		return tonumber(p[1]), tonumber(p[2]), DIR_OK[p[3]] and p[3] or nil;
	end
end

local function SavePos(x, y, dir)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if type(NidhausUnitFramesDB.ArenaDoTPositions) ~= "table" then
		NidhausUnitFramesDB.ArenaDoTPositions = {};
	end
	NidhausUnitFramesDB.ArenaDoTPositions[PosKey()] = { x, y, dir };
end

-- ---------- Widgets ----------
local RefreshAll;   -- se define abajo (el arrastre la usa)

local function StartDrag(h)
	if not previewOn or h._moving then return; end
	if InCombatLockdown and InCombatLockdown() then return; end
	if not (IsShiftKeyDown() and IsAltKeyDown()) then return; end
	h:SetMovable(true);
	h:StartMoving();
	h._moving = true;
end

local function StopDrag(h)
	if not h._moving then return; end
	h:StopMovingOrSizing();
	h._moving = false;
	local af = h:GetParent();
	local hx, hy = h:GetCenter();
	-- OJO: "af and af:GetCenter()" se queda solo con el primer valor.
	local ax, ay;
	if af then ax, ay = af:GetCenter(); end
	if hx and hy and ax and ay then
		-- A pixeles de pantalla para restar y de vuelta al espacio de la
		-- fila, que es donde SetPoint interpreta el offset (la misma cuenta
		-- que Party Targets). Hoy fila y marco tienen la misma escala, pero
		-- asi no depende de eso.
		local hs = h:GetEffectiveScale() or 1;
		local as = af:GetEffectiveScale() or 1;
		if hs == 0 then hs = 1; end
		local x = floor(((hx * hs - ax * as) / hs) * 10 + 0.5) / 10;
		local y = floor(((hy * hs - ay * as) / hs) * 10 + 0.5) / 10;
		SavePos(x, y, h._lastDir);
	end
	RefreshAll();
end

local function ShowMoveTip(self)
	if not previewOn then return; end
	GameTooltip:SetOwner(self, "ANCHOR_TOP");
	GameTooltip:SetText(L["HEADER_ARENA_DOT"] or "DoT warning", 1, 1, 1);
	GameTooltip:AddLine(L["DR_MOVE_HINT"] or "Shift+Alt+drag to move", nil, nil, nil, true);
	GameTooltip:Show();
end

local function CreateHolder(idx)
	local af = _G["ArenaEnemyFrame" .. idx];
	if not af then return nil; end

	local h = CreateFrame("Frame", nil, af);
	-- MEDIUM, como el trinket: en el modo Test el contenedor de los marcos
	-- de arena (NidhausArenaEnemyFrames) toma el mouse y tapa los huecos
	-- entre marcos, que es justo donde va esta fila. En el estrato de los
	-- marcos (LOW) el click se lo llevaba el contenedor y no se podia
	-- arrastrar.
	h:SetFrameStrata("MEDIUM");
	h:SetFrameLevel(af:GetFrameLevel() + 6);
	h:SetClampedToScreen(true);
	h:EnableMouse(false);
	h:SetScript("OnMouseDown", function(self, b) if b == "LeftButton" then StartDrag(self); end end);
	h:SetScript("OnMouseUp", function(self, b) if b == "LeftButton" then StopDrag(self); end end);
	h:SetScript("OnHide", function(self)
		if self._moving then self:StopMovingOrSizing(); self._moving = false; end
	end);

	-- Un FontString sin plantilla no tiene fuente: SetText antes de SetFont
	-- tira "Font not set". La fuente va primero (Layout la ajusta al tamaño).
	h.label = h:CreateFontString(nil, "OVERLAY");
	h.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE");
	h.label:SetTextColor(1, 0.15, 0.15);
	h.label:SetText("DoT");

	h.icons = {};
	h:Hide();
	return h;
end

local function GetHolder(idx)
	if not holders[idx] then holders[idx] = CreateHolder(idx); end
	return holders[idx];
end

local function CreateIcon(h)
	local ic = CreateFrame("Frame", nil, h);
	ic:SetFrameLevel(h:GetFrameLevel() + 1);
	ic.tex = ic:CreateTexture(nil, "ARTWORK");
	ic.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93);
	ic:EnableMouse(false);
	ic:SetScript("OnMouseDown", function(_, b) if b == "LeftButton" then StartDrag(h); end end);
	ic:SetScript("OnMouseUp", function(_, b) if b == "LeftButton" then StopDrag(h); end end);
	ic:SetScript("OnEnter", ShowMoveTip);
	ic:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	ic:Hide();
	return ic;
end

-- Borde rojo de 1 px o negro de 1 px (los iconos son chicos).
local function ApplyLook(ic, size)
	ic:SetWidth(size);
	ic:SetHeight(size);
	if not ic._look then
		ic:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 });
		ic.tex:SetPoint("TOPLEFT", 1, -1);
		ic.tex:SetPoint("BOTTOMRIGHT", -1, 1);
		ic._look = true;
	end
	if C.ArenaDoTBorder ~= false then
		ic:SetBackdropBorderColor(1, 0.15, 0.15, 1);
	else
		ic:SetBackdropBorderColor(0, 0, 0, 1);
	end
end

local function Layout(idx, h, shown)
	local af = _G["ArenaEnemyFrame" .. idx];
	if not af then return; end
	local size, gap = OptSize(), OptGap();
	local dir = OptGrow();

	-- La fila se agarra por el primer elemento: si es el texto "DoT", que el
	-- area agarrable lo cubra entero (es mas ancho que un icono).
	local w = size;
	if C.ArenaDoTLabel ~= false then
		h.label:SetFont("Fonts\\FRIZQT__.TTF", max(9, floor(size * 0.7 + 0.5)), "OUTLINE");
		w = max(size, (h.label:GetStringWidth() or 0) + 2);
	end
	h:SetWidth(w);
	h:SetHeight(size);
	if not h._moving then
		h:ClearAllPoints();
		local x, y, savedDir = GetSavedPos();
		if x then
			h:SetPoint("CENTER", af, "CENTER", x, y);
			if dir == "AUTO" then dir = savedDir or ((x < 0) and "LEFT" or "RIGHT"); end
		elseif C.ArenaMirrorMode then
			h:SetPoint("TOPRIGHT", af, "BOTTOMRIGHT", 0, OFFSET_Y);
			if dir == "AUTO" then dir = "LEFT"; end
		else
			h:SetPoint("TOPLEFT", af, "BOTTOMLEFT", 0, OFFSET_Y);
			if dir == "AUTO" then dir = "RIGHT"; end
		end
	elseif dir == "AUTO" then
		dir = h._lastDir or "RIGHT";
	end
	h._lastDir = dir;

	-- Elementos en orden: texto "DoT" (si va) y despues los iconos.
	local elems = {};
	if C.ArenaDoTLabel ~= false then
		h.label:SetFont("Fonts\\FRIZQT__.TTF", max(9, floor(size * 0.7 + 0.5)), "OUTLINE");
		h.label:Show();
		elems[1] = h.label;
	else
		h.label:Hide();
	end
	for k = 1, shown do elems[#elems + 1] = h.icons[k]; end

	local prev;
	for i, e in ipairs(elems) do
		e:ClearAllPoints();
		local g = gap;
		if prev == h.label then g = gap + 2; end
		if not prev then
			if dir == "LEFT" then e:SetPoint("RIGHT", h, "RIGHT", 0, 0);
			elseif dir == "RIGHT" then e:SetPoint("LEFT", h, "LEFT", 0, 0);
			elseif dir == "UP" then e:SetPoint("BOTTOM", h, "BOTTOM", 0, 0);
			else e:SetPoint("TOP", h, "TOP", 0, 0); end
		elseif dir == "LEFT" then
			e:SetPoint("RIGHT", prev, "LEFT", -g, 0);
		elseif dir == "RIGHT" then
			e:SetPoint("LEFT", prev, "RIGHT", g, 0);
		elseif dir == "UP" then
			e:SetPoint("BOTTOM", prev, "TOP", 0, g);
		else
			e:SetPoint("TOP", prev, "BOTTOM", 0, -g);
		end
		prev = e;
	end
end

local function Refresh(idx)
	local list = dots[idx];
	local h = holders[idx];
	if not h and not (enabled and list and #list > 0) then return; end
	h = h or GetHolder(idx);
	if not h then return; end

	local size, maxn = OptSize(), OptMax();
	local shown = 0;
	if enabled and list then
		for _, d in ipairs(list) do
			if shown >= maxn then break; end
			shown = shown + 1;
			local ic = h.icons[shown];
			if not ic then ic = CreateIcon(h); h.icons[shown] = ic; end
			ApplyLook(ic, size);
			ic.tex:SetTexture(d.icon);
			ic:EnableMouse(previewOn);
			ic:Show();
		end
	end
	for k = shown + 1, #h.icons do h.icons[k]:Hide(); end

	if shown > 0 then
		Layout(idx, h, shown);
		h:EnableMouse(previewOn);
		h:Show();
	else
		h:EnableMouse(false);
		h:Hide();
	end
end

RefreshAll = function()
	for i = 1, MAX_ARENA do Refresh(i); end
end

local function WipeAll()
	for i = 1, MAX_ARENA do dots[i] = nil; end
	RefreshAll();
end

-- ---------- Vista previa ----------
local PREVIEW_IDS = { 589, 172, 8921, 1978, 12654, 31803 };  -- SW:P, Corrupcion, Fuego lunar, Picadura, Ignite, Vengeance
local PREVIEW_COUNT = { 3, 2, 6, 1, 4 };                    -- cuantos por marco (el maximo los recorta)

local function FillPreview()
	for idx = 1, MAX_ARENA do
		dots[idx] = {};
		for k = 1, PREVIEW_COUNT[idx] or 2 do
			local id = PREVIEW_IDS[k];
			tinsert(dots[idx], {
				name = "preview" .. k,
				icon = select(3, GetSpellInfo(id)) or "Interface\\Icons\\INV_Misc_QuestionMark",
				expire = math.huge,
				preview = true,
			});
		end
	end
end

local driver;   -- se define abajo

local function SetPreview(on)
	on = (on and enabled) and true or false;
	if on == previewOn then
		if on then RefreshAll(); end
		return;
	end
	previewOn = on;
	if on then FillPreview(); else WipeAll(); end
	RefreshAll();
end

-- ---------- Reloj ----------
driver = CreateFrame("Frame");
driver:Hide();
local acc = 0;
driver:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < 0.25 then return; end
	acc = 0;

	local now = GetTime();
	local any = false;
	for idx = 1, MAX_ARENA do
		local list = dots[idx];
		if list then
			local changed = false;
			for j = #list, 1, -1 do
				if not list[j].preview and now >= list[j].expire then
					tremove(list, j);
					changed = true;
				end
			end
			if #list > 0 then any = true; else dots[idx] = nil; end
			if changed then Refresh(idx); end
		end
	end
	if not any then self:Hide(); end
end);

-- ---------- Combat log ----------
-- ttl: cuanto dura la marca sin novedades. Nunca acorta una marca que ya
-- dura mas (un tick no le quita el tope largo a un DoT conocido).
local function Mark(idx, name, spellID, ttl)
	local now = GetTime();
	dots[idx] = dots[idx] or {};
	local list = dots[idx];
	for _, d in ipairs(list) do
		if d.name == name then
			d.expire = max(d.expire, now + ttl);
			return false;   -- ya estaba: nada que redibujar
		end
	end
	tinsert(list, {
		name = name,
		icon = select(3, GetSpellInfo(spellID)),
		expire = now + ttl,
	});
	return true;
end

-- 3.3.5a: timestamp, evento, srcGUID, srcName, srcFlags, dstGUID, dstName,
-- dstFlags, spellID, spellName, school, auraType / missType
local function OnCLEU(...)
	local _, sub, _, _, _, dstGUID, _, _, spellID, spellName, _, extra = ...;

	if sub == "SPELL_PERIODIC_DAMAGE"
		or (sub == "SPELL_PERIODIC_MISSED" and extra == "ABSORB") then
		local idx = IdxFromGUID(dstGUID);
		if not idx then return; end
		if Mark(idx, spellName, spellID, DOT_GRACE) then Refresh(idx); end
		driver:Show();

	elseif sub == "SPELL_AURA_APPLIED" or sub == "SPELL_AURA_REFRESH" then
		if extra ~= "DEBUFF" or not knownDot[spellName] then return; end
		local idx = IdxFromGUID(dstGUID);
		if not idx then return; end
		if Mark(idx, spellName, spellID, KNOWN_TTL) then Refresh(idx); end
		driver:Show();

	elseif sub == "SPELL_AURA_REMOVED" then
		if not knownDot[spellName] then return; end
		local idx = guidToIdx[dstGUID];
		local list = idx and dots[idx];
		if not list then return; end
		for j = #list, 1, -1 do
			if list[j].name == spellName then tremove(list, j); end
		end
		Refresh(idx);
	end
end

-- ---------- Activar / desactivar ----------
local ev = CreateFrame("Frame");

local function ApplyState()
	local want = C.ArenaDoTWarn and true or false;
	local listen = want and InArena();
	if listen ~= listening then
		listening = listen;
		if listen then
			ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			ev:RegisterEvent("ARENA_OPPONENT_UPDATE");
			RefreshGUIDs();
		else
			ev:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			ev:UnregisterEvent("ARENA_OPPONENT_UPDATE");
		end
	end
	if want ~= enabled then
		enabled = want;
		if not enabled then
			previewOn = false;
			driver:Hide();
			WipeAll();
			return;
		end
	end
	SetPreview(IsTestMode() and not InArena());
	RefreshAll();
end

ev:RegisterEvent("PLAYER_ENTERING_WORLD");
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA");
ev:SetScript("OnEvent", function(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		return OnCLEU(...);
	elseif event == "ARENA_OPPONENT_UPDATE" then
		RefreshGUIDs();
	elseif event == "PLAYER_ENTERING_WORLD" then
		for g in pairs(guidToIdx) do guidToIdx[g] = nil; end
		for i = 1, MAX_ARENA do dots[i] = nil; end
		previewOn = false;
		ApplyState();
	else
		ApplyState();
	end
end);

-- El modo Test de arena prende y apaga el mouse de los trinkets al abrirse
-- y al cerrarse (ArenaMover): mismo momento para la vista previa.
if type(K.SetTrinketMouseState) == "function" then
	hooksecurefunc(K, "SetTrinketMouseState", function(on)
		SetPreview(on and IsTestMode() and not InArena());
	end);
end

-- ---------- API para el panel ----------
function K.ToggleArenaDoTWarn()
	ApplyState();
end

function K.RefreshArenaDoTLayout()
	RefreshAll();
end

function K.IsArenaDoTPreviewOn()
	return previewOn;
end

-- Boton "Vista previa": abre o cierra el modo Test de arena.
function K.ToggleArenaDoTPreview()
	if not C.ArenaDoTWarn or not C.ArenaFrameOn or InArena() then return false; end
	if InCombatLockdown and InCombatLockdown() then return false; end
	if IsTestMode() then
		if previewOn then
			if K.ToggleArenaFramesMover then K.ToggleArenaFramesMover(); end
		else
			SetPreview(true);
		end
	elseif K.ToggleArenaFramesMover then
		K.ToggleArenaFramesMover();
	end
	return true;
end

function K.ResetArenaDoTPosition()
	if NidhausUnitFramesDB then NidhausUnitFramesDB.ArenaDoTPositions = nil; end
	RefreshAll();
end

-- ---------- Prueba por chat ----------
SLASH_NUFDOT1 = "/nufdot";
SlashCmdList["NUFDOT"] = function(msg)
	if msg == "clear" then
		if previewOn and IsTestMode() and K.ToggleArenaFramesMover then
			K.ToggleArenaFramesMover();
		end
		SetPreview(false);
		return;
	end
	if not C.ArenaDoTWarn then
		print("|cffFFD100NUF DoT|r: " .. (L["DOT_NEED_ENABLE"] or "turn it on in Arena > DoT."));
		return;
	end
	if not C.ArenaFrameOn then
		print("|cffFFD100NUF DoT|r: " .. (L["DR_PREVIEW_NEEDS_ARENA"] or "the preview needs the arena frames mod (Arena > Frames)."));
		return;
	end
	if not previewOn then K.ToggleArenaDoTPreview(); end
end
