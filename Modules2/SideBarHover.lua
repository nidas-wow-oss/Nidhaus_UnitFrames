local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- SideBarHover.lua
-- Muestra las barras LATERALES (MultiBarLeft / MultiBarRight) solo
-- cuando el mouse esta encima. El resto del tiempo quedan invisibles.
--
-- Idea tomada del modulo ActionBars de KPack ("Hover Mode").
--
-- NOTA: se usa MouseIsOver en un ticker y no OnEnter/OnLeave porque los
-- botones hijos se comen esos eventos del contenedor: con OnEnter la barra
-- parpadearia al pasar de un boton a otro.
--
-- El alpha 0 NO bloquea los clicks: los botones siguen funcionando aunque
-- no se vean (igual que en el addon original).
--
-- Rendimiento: el ticker SOLO corre con la opcion activada, y a 10 Hz.
-- =========================================================

local BARS = { "MultiBarLeft", "MultiBarRight" };

local ticker = CreateFrame("Frame");
ticker:Hide();
local acc = 0;

local function SetBarsAlpha(a)
	for _, name in ipairs(BARS) do
		local f = _G[name];
		if f and f.SetAlpha then f:SetAlpha(a); end
	end
end

ticker:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < 0.1 then return; end
	acc = 0;

	for _, name in ipairs(BARS) do
		local f = _G[name];
		if f and f:IsShown() then
			f:SetAlpha(MouseIsOver(f) and 1 or 0);
		end
	end
end);

-- Prende / apaga el modo hover.
function K.ApplySideBarHover()
	if C.SideBarsHover then
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
