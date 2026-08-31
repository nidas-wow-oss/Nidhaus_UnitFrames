local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ============================================================
-- CastingBarTimer.lua
-- Muestra el tiempo de casteo (en segundos, ej: "1.5s") sobre la
-- barra de casteo del PERSONAJE (CastingBarFrame) y del OBJETIVO
-- (TargetFrameSpellBar).
--
-- Lógica basada en la opción "Display casting bar timers" de
-- CT_Core (CTMod), reescrita y aislada para NUF:
--   * Sin dependencias de CTMod ni de su librería.
--   * Usa el sistema de config de NUF (C.CastingTimers) y sus
--     eventos CONFIG_LOADED / CONFIG_CHANGED.
--   * Togglea en tiempo real, sin /reload.
--
-- Config: C.CastingTimers (boolean). Default definido en
-- ConfigManager.lua. Checkbox en el panel de opciones.
-- ============================================================

local format = format or string.format;
local max = math.max;
local hooksecurefunc = hooksecurefunc;

local isInitialized = false;
local displayTimers = false;

-- Referencias a los FontStrings del contador que creamos
local countDownText;        -- sobre CastingBarFrame (jugador)
local countDownTargetText;  -- sobre TargetFrameSpellBar (objetivo)

-- ────────────────────────────────────────────────────────────
-- Crear los FontStrings del contador (una sola vez)
-- ────────────────────────────────────────────────────────────
local function CreateTimerTexts()
	if countDownText then return; end

	-- Jugador
	if CastingBarFrame then
		countDownText = CastingBarFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		countDownText:SetPoint("TOPRIGHT", 2, 5);
		countDownText:SetPoint("BOTTOMLEFT", CastingBarFrame, "BOTTOMRIGHT", -56, 2);
		CastingBarFrame.nufCountDownText = countDownText;
		CastingBarFrame.nufCtElapsed = 0;
	end

	-- Objetivo
	if TargetFrameSpellBar then
		countDownTargetText = TargetFrameSpellBar:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		countDownTargetText:SetPoint("TOPRIGHT", 0, 5);
		countDownTargetText:SetPoint("BOTTOMLEFT", TargetFrameSpellBar, "BOTTOMRIGHT", -60, 0);
		TargetFrameSpellBar.nufCountDownText = countDownTargetText;
		TargetFrameSpellBar.nufCtElapsed = 0;
	end
end

-- ────────────────────────────────────────────────────────────
-- Hook del OnUpdate de la barra de casteo.
-- Se dispara para CastingBarFrame Y TargetFrameSpellBar (ambos
-- usan la MISMA función CastingBarFrame_OnUpdate en 3.3.5a).
-- Actualiza el texto ~10 veces por segundo (no en cada frame) para
-- no gastar CPU de más — igual que el original de CTMod.
-- ────────────────────────────────────────────────────────────
local function CastTimer_OnUpdate(self, secondsElapsed)
	-- Sólo procesar frames que tengan nuestro contador enganchado
	local cd = self.nufCountDownText;
	if not cd then return; end
	if not displayTimers then return; end

	local elapsed = (self.nufCtElapsed or 0) - (secondsElapsed or 0);
	if elapsed < 0 then
		if self.casting then
			-- Casteo normal: tiempo RESTANTE = max - value
			cd:SetText(format("(%.1fs)", max((self.maxValue or 0) - (self.value or 0), 0)));
		elseif self.channeling then
			-- Canalizado: tiempo restante = value (cuenta hacia abajo)
			cd:SetText(format("(%.1fs)", max(self.value or 0, 0)));
		else
			cd:SetText("");
		end
		self.nufCtElapsed = 0.1;  -- próximo update en 0.1s
	else
		self.nufCtElapsed = elapsed;
	end
end

-- ────────────────────────────────────────────────────────────
-- Activar / desactivar el contador y reposicionar el texto normal
-- de la barra (nombre del hechizo) para que no se pise con el número.
-- ────────────────────────────────────────────────────────────
local function ApplyCastingTimers(enable)
	displayTimers = enable and true or false;

	local castingBarText = CastingBarFrameText;
	local castingBarTargetText = TargetFrameSpellBarText;

	if castingBarText then castingBarText:ClearAllPoints(); end
	if castingBarTargetText then castingBarTargetText:ClearAllPoints(); end

	if displayTimers then
		if countDownText then countDownText:Show(); end
		if countDownTargetText then countDownTargetText:Show(); end

		-- Colocacion del contador y del nombre.
		--
		-- El reparto de antes (nombre a la izquierda, 56px reservados a la
		-- derecha para el numero) funciona con la barra de Blizzard, que es
		-- ancha. Con la barra custom, que es bastante mas corta, esos 56px se
		-- comen casi la mitad: el nombre no cabe en lo que queda, desborda su
		-- hueco y se ve pisado por el numero.
		--
		-- Con la barra custom el numero se saca FUERA, pegado al borde
		-- derecho, y el nombre se queda centrado con toda la barra para el.
		-- Asi no se solapan nunca, mida lo que mida el nombre.
		local custom = C and C.CastBarPWEnabled;

		if custom then
			if countDownText then
				countDownText:ClearAllPoints();
				countDownText:SetPoint("LEFT", CastingBarFrame, "RIGHT", 4, 0);
				countDownText:SetJustifyH("LEFT");
			end
			if castingBarText then
				castingBarText:SetWidth(0);
				castingBarText:SetPoint("TOP", 0, 5);
			end
		else
			if countDownText then
				countDownText:ClearAllPoints();
				countDownText:SetPoint("TOPRIGHT", 2, 5);
				countDownText:SetPoint("BOTTOMLEFT", CastingBarFrame, "BOTTOMRIGHT", -56, 2);
				countDownText:SetJustifyH("CENTER");
			end
			-- Nombre a la izquierda, dejando lugar al numero a la derecha.
			-- El desplazamiento va en negativo para que el hueco del nombre
			-- TERMINE antes de donde empieza el numero; con +10 se metia diez
			-- pixeles dentro y ya se rozaban.
			if castingBarText and countDownText then
				castingBarText:SetPoint("TOPLEFT", 0, 5);
				castingBarText:SetPoint("BOTTOMRIGHT", countDownText, "BOTTOMLEFT", -4, 0);
			end
		end

		if castingBarTargetText and countDownTargetText then
			castingBarTargetText:SetPoint("TOPLEFT", 2, 5);
			castingBarTargetText:SetPoint("BOTTOMRIGHT", countDownTargetText, "BOTTOMLEFT", -4, 0);
		end
	else
		if countDownText then
			countDownText:Hide();
			countDownText:SetText("");
		end
		if countDownTargetText then
			countDownTargetText:Hide();
			countDownTargetText:SetText("");
		end

		-- Restaurar el nombre del hechizo centrado (default de Blizzard)
		if castingBarText then
			castingBarText:SetWidth(0);
			castingBarText:SetPoint("TOP", 0, 5);
		end
		if castingBarTargetText then
			castingBarTargetText:SetWidth(0);
			castingBarTargetText:SetPoint("TOP", 0, 5);
		end
	end
end

-- Público: para el checkbox del panel de opciones (toggle en vivo)
function K.ToggleCastingTimers(enable)
	if not isInitialized then return; end
	ApplyCastingTimers(enable);
end

-- Recoloca el contador sin cambiar si esta encendido o no. Lo llama el panel
-- al activar o desactivar la barra custom, porque el reparto de nombre y
-- numero es distinto en cada una.
function K.RefreshCastingTimerLayout()
	if not isInitialized then return; end
	ApplyCastingTimers(displayTimers);
end

-- ────────────────────────────────────────────────────────────
-- Init
-- ────────────────────────────────────────────────────────────
local function InitializeCastingTimers()
	if isInitialized then return; end

	-- Necesitamos que existan los frames de Blizzard
	if not CastingBarFrame then return; end

	CreateTimerTexts();

	-- Un solo hook cubre jugador y objetivo (misma función OnUpdate)
	hooksecurefunc("CastingBarFrame_OnUpdate", CastTimer_OnUpdate);

	isInitialized = true;

	-- Estado inicial según config
	ApplyCastingTimers(C.CastingTimers);
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	InitializeCastingTimers();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if isInitialized then
		ApplyCastingTimers(C.CastingTimers);
	end
end);
