local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- SideBarHover.lua
-- Muestra las barras LATERALES (MultiBarLeft / MultiBarRight) solo
-- cuando el mouse esta encima. El resto del tiempo quedan invisibles.
--
-- Idea tomada del modulo ActionBars de KPack ("Hover Mode").
--
-- MISMA LOGICA QUE "Hide bags and micro menu" (BarFade.lua): al sacar el
-- mouse la barra se queda 5 segundos a la vista y despues se desvanece en
-- 3 segundos. Antes desaparecia en el acto, y era facil perderla por
-- pasarse un pixel del borde. Cada barra lleva su propio tiempo.
--
-- NOTA: se usa MouseIsOver en un ticker y no OnEnter/OnLeave porque los
-- botones hijos se comen esos eventos del contenedor: con OnEnter la barra
-- parpadearia al pasar de un boton a otro.
--
-- El alpha 0 NO bloquea los clicks: los botones siguen funcionando aunque
-- no se vean (igual que en el addon original).
--
-- En "Mover todo" se ven enteras, para poder acomodarlas.
--
-- Rendimiento: el ticker SOLO corre con la opcion activada, a 20 Hz (lo
-- justo para que el desvanecimiento se vea suave).
-- =========================================================

local BARS = { "MultiBarLeft", "MultiBarRight" };

local LINGER = 5;     -- segundos a la vista despues de sacar el mouse
local FADE   = 3;     -- segundos que tarda en desaparecer
local TICK   = 0.05;

local ticker = CreateFrame("Frame");
ticker:Hide();
local acc = 0;
local lastOver = {};   -- [nombre] = GetTime() de la ultima vez con el mouse encima

local function SetBarsAlpha(a)
	for _, name in ipairs(BARS) do
		local f = _G[name];
		if f and f.SetAlpha then f:SetAlpha(a); end
	end
end

local function AlphaFor(name, t)
	local idle = t - (lastOver[name] or t);
	if idle <= LINGER then return 1; end
	if idle >= LINGER + FADE then return 0; end
	local a = 1 - (idle - LINGER) / FADE;
	-- Lo que queda del final se redondea a 0: si no, por los decimales del
	-- reloj podia quedar en 0.0000001 y nunca escribirse el 0 exacto.
	if a < 0.01 then a = 0; end
	return a;
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < TICK then return; end
	acc = 0;

	local t = GetTime();
	local forced = K.IsGlobalUnlocked and K.IsGlobalUnlocked();
	for _, name in ipairs(BARS) do
		local f = _G[name];
		if f and f:IsShown() then
			if forced or MouseIsOver(f) then lastOver[name] = t; end
			local a = AlphaFor(name, t);
			local cur = f:GetAlpha() or 1;
			-- Solo se escribe si cambio (no en cada vuelta).
			if cur - a > 0.001 or a - cur > 0.001 then f:SetAlpha(a); end
		end
	end
end);

-- Prende / apaga el modo hover.
function K.ApplySideBarHover()
	if C.SideBarsHover then
		if not ticker:IsShown() then
			-- Recien prendido: a la vista y a contar los 5 s.
			local t = GetTime();
			for _, name in ipairs(BARS) do lastOver[name] = t; end
		end
		acc = 0;
		ticker:Show();
	else
		ticker:Hide();
		SetBarsAlpha(1);   -- al apagar, siempre visibles otra vez
	end
end

-- Al entrar al mundo aplicamos el estado guardado.
local ev = CreateFrame("Frame");
ev:RegisterEvent("PLAYER_ENTERING_WORLD");
ev:SetScript("OnEvent", function()
	if K.ApplySideBarHover then K.ApplySideBarHover(); end
end);
