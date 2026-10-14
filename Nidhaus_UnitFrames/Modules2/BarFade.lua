local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- BarFade.lua
-- Oculta la mochila y el micromenu (C.BarsFadeBags) mientras esta puesto
-- "Unify Action Bars" o "MiniBar". Aparecen con el mouse encima; al
-- sacarlo se quedan 5 segundos y despues se desvanecen en 3 segundos
-- hasta desaparecer.
--
-- (Hubo tambien una opcion para las barras de accion de abajo: se saco a
-- pedido. El codigo quedo armado por grupos por si algun dia vuelve.)
--
-- En combate NO aparecen solas: solo con el mouse (lo que se eligio).
--
-- Como "Show side bars on mouseover":
--   * Se usa MouseIsOver en un ticker y no OnEnter/OnLeave: los botones
--     hijos se comen esos eventos y el bloque parpadearia al pasar de un
--     boton a otro.
--   * Solo alpha, nunca Hide(): con alpha 0 los botones siguen andando,
--     y SetAlpha se puede usar en combate sin que el cliente lo bloquee.
--
-- En un vehiculo y en "Mover todo" se ve entero (en el vehiculo el
-- micromenu cuelga de la barra del vehiculo). Al salir, otra vez 5 s y se
-- desvanece.
--
-- Rendimiento: el ticker solo corre con la opcion puesta, a 20 Hz (lo
-- justo para que el desvanecimiento se vea suave).
-- =========================================================

local LINGER = 5;     -- segundos a la vista despues de sacar el mouse
local FADE   = 3;     -- segundos que tarda en desaparecer
local TICK   = 0.05;

local MICRO_BUTTONS = {
	"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
	"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
};


-- ---------------------------------------------------------
-- Grupos
-- ---------------------------------------------------------
local function BagsAlphaFrames(out)
	if BagPackFrame then out[#out + 1] = BagPackFrame; end
	for _, name in ipairs(MICRO_BUTTONS) do
		local b = _G[name];
		if b then out[#out + 1] = b; end
	end
	return out;
end


local function BagsOver()
	if BagPackFrame and BagPackFrame:IsVisible() and MouseIsOver(BagPackFrame) then return true; end
	for _, name in ipairs(MICRO_BUTTONS) do
		local b = _G[name];
		if b and b:IsVisible() and MouseIsOver(b) then return true; end
	end
	return false;
end


local groups = {
	bags = { setting = "BarsFadeBags", frames = BagsAlphaFrames, over = BagsOver },
};
for _, g in pairs(groups) do
	g.applied = {};      -- [frame] = alpha que le pusimos
	g.lastOver = 0;
	g.active = false;
end

-- Tablas de trabajo reusadas: el ticker corre 20 veces por segundo y no
-- tiene sentido fabricar basura en cada vuelta.
local scratchList, scratchSet, scratchTop, scratchNow = {}, {}, {}, {};

-- Solo los de arriba: un marco que cuelga (a cualquier altura) de otro de
-- la misma lista se saca.
local function TopLevelOnly(list)
	wipe(scratchSet); wipe(scratchTop);
	for _, f in ipairs(list) do scratchSet[f] = true; end
	for _, f in ipairs(list) do
		local p, nested = f:GetParent(), false;
		while p do
			if scratchSet[p] then nested = true; break; end
			p = p:GetParent();
		end
		if not nested then scratchTop[#scratchTop + 1] = f; end
	end
	return scratchTop;
end

-- Devuelve a alpha 1 todo lo que el grupo habia tocado.
local function Release(g)
	for f in pairs(g.applied) do
		pcall(f.SetAlpha, f, 1);
		g.applied[f] = nil;
	end
	g.active = false;
end

local function SetGroupAlpha(g, a)
	local frames = TopLevelOnly(g.frames(wipe(scratchList)));
	local now = wipe(scratchNow);
	for _, f in ipairs(frames) do
		now[f] = true;
		-- Tambien se reescribe si otro codigo le cambio el alpha por su
		-- cuenta (si no, quedaria a la vista hasta el proximo mouseover).
		local cur = f:GetAlpha() or 1;
		if g.applied[f] ~= a or cur - a > 0.01 or a - cur > 0.01 then
			f:SetAlpha(a);
			g.applied[f] = a;
		end
	end
	-- Lo que dejo de estar en la lista (cambio de modo, o paso a colgar
	-- de otro marco de la lista) vuelve a alpha 1.
	for f in pairs(g.applied) do
		if not now[f] then
			pcall(f.SetAlpha, f, 1);
			g.applied[f] = nil;
		end
	end
end

local function AlphaFor(g, t)
	local idle = t - g.lastOver;
	if idle <= LINGER then return 1; end
	if idle >= LINGER + FADE then return 0; end
	return 1 - (idle - LINGER) / FADE;
end

-- Todo a la vista, sin desvanecer: vehiculo o "Mover todo".
local function ForceShown()
	if UnitHasVehicleUI and UnitHasVehicleUI("player") then return true; end
	if K.IsGlobalUnlocked and K.IsGlobalUnlocked() then return true; end
	return false;
end

local function ModeActive()
	if K.IsAnyBarModeActive then return K.IsAnyBarModeActive(); end
	return (C.UnifyActionBars == true) or (C.MiniBarEnabled == true);
end

local ticker = CreateFrame("Frame");
ticker:Hide();
local acc = 0;

local function Step(t)
	local mode = ModeActive();
	local forced = ForceShown();
	for _, g in pairs(groups) do
		if C[g.setting] == true and mode then
			if not g.active then
				-- Recien prendido (o volvio el modo): a la vista y a contar.
				g.active = true;
				g.lastOver = t;
			end
			if forced or g.over() then g.lastOver = t; end
			SetGroupAlpha(g, AlphaFor(g, t));
		elseif g.active or next(g.applied) then
			Release(g);
		end
	end
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < TICK then return; end
	acc = 0;
	Step(GetTime());
end);

-- Prende / apaga segun las opciones. Lo llaman las casillas del panel.
function K.ApplyBarFade()
	local any = (C.BarsFadeBags == true);
	if any then
		acc = TICK;   -- que el primer paso sea ya
		ticker:Show();
	else
		ticker:Hide();
	end
	-- Lo que se apago vuelve a verse en el acto (sin esperar al ticker).
	Step(GetTime());
end

-- Al entrar al mundo se aplica lo guardado (C ya esta cargado).
local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_ENTERING_WORLD");
ev:SetScript("OnEvent", function()
	K.ApplyBarFade();
end);
