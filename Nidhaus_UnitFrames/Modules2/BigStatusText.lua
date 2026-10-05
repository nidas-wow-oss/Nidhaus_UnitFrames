local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- BigStatusText.lua  ·  Interface > General > Status Text
--
--   [x] Big text (name above the frame)      C.BigStatusText
--       [x] Custom text size                 C.BigTextCustomSize
--           Health text  8 ──●── 16          C.BigTextHealthSize
--           Mana text    8 ──●── 16          C.BigTextManaSize
--
-- La idea viene del modo de marcos gruesos de RougeUI (el BigFrames de
-- ZyrokofArenaFrames): nombre arriba del marco y la barra libre para el
-- numero. Los marcos grandes en si NO hacen falta: Light, Dark y Compact
-- ya son marcos gruesos, y por eso la opcion solo existe con esos tres.
--
-- Quien hace que:
--   * Core/API.lua             K.BigStatusTextOn / K.BigStatusSizeOn (la regla)
--   * UnitFrames/PlayerFrame   nombre arriba + numero centrado (jugador)
--   * UnitFrames/TargetFrame   lo mismo en objetivo y foco
--   * AbbreviatedStatus        una ranura de posiciones aparte ("+Big")
--   * este archivo             el tamaño de los numeros, y el boton que
--                              reaplica todo al tocar la opcion
--
-- TAMAÑO: solo cambia el tamaño. La cara y el contorno se dejan como los
-- tenga la fuente (los de Blizzard, o los de otro modulo). Toca el numero
-- de cada barra; el porcentaje del texto abreviado (otro FontString, de
-- ese modulo) copia la fuente del numero, asi que lo sigue solo.
-- =========================================================

local BARS = {};   -- [barra] = { unit = "player", hp = true/false }
do
	local list = {
		{ "PlayerFrameHealthBar", "player", true  }, { "PlayerFrameManaBar", "player", false },
		{ "TargetFrameHealthBar", "target", true  }, { "TargetFrameManaBar", "target", false },
		{ "FocusFrameHealthBar",  "focus",  true  }, { "FocusFrameManaBar",  "focus",  false },
	};
	for _, e in ipairs(list) do
		local bar = _G[e[1]];
		if bar then BARS[bar] = { unit = e[2], hp = e[3] }; end
	end
end

local function Clamp(v, def)
	v = tonumber(v) or def;
	v = math.floor(v + 0.5);
	if v < 8 then v = 8; elseif v > 16 then v = 16; end
	return v;
end

-- Tamaño de fabrica de cada FontString, tomado la PRIMERA vez que se lo
-- agranda. Sin tocar nunca, no hay nada que devolver.
local origSize = {};

local function SetSize(fs, size)
	if not fs or not fs.GetFont then return; end
	local face, cur, flags = fs:GetFont();
	if not face then return; end
	if size then
		if not origSize[fs] then origSize[fs] = cur; end
		if not cur or math.abs(cur - size) > 0.05 then
			pcall(fs.SetFont, fs, face, size, flags);
		end
	else
		local o = origSize[fs];
		if o and cur and math.abs(cur - o) > 0.05 then
			pcall(fs.SetFont, fs, face, o, flags);
		end
	end
end

local function ApplyBar(bar, info)
	local size;
	if K.BigStatusSizeOn and K.BigStatusSizeOn(info.unit) then
		size = info.hp and Clamp(C.BigTextHealthSize, 12) or Clamp(C.BigTextManaSize, 10);
	end
	SetSize(bar.TextString, size);
	-- El porcentaje copia la fuente ENTERA del numero (no un tamano aparte:
	-- con dos tamanos guardados por separado, al apagar quedaban distintos).
	if K.MirrorAbbrevPct then K.MirrorAbbrevPct(bar); else SetSize(bar._nufPct, size); end
end

-- Cada vez que Blizzard repinta el texto de una barra. Corre para TODAS
-- las barras del juego (placas de nombre incluidas), asi que lo primero es
-- descartar las que no son nuestras: una busqueda en una tabla y afuera.
-- Va despues del hook del texto abreviado (carga antes en el XML), asi que
-- el porcentaje que ese modulo crea en su primera pasada ya existe aca.
hooksecurefunc("TextStatusBar_UpdateTextString", function(bar)
	local info = BARS[bar];
	if info then pcall(ApplyBar, bar, info); end
end);

function K.RefreshBigStatusFonts()
	for bar, info in pairs(BARS) do pcall(ApplyBar, bar, info); end
end

-- Lo llama el panel al tocar cualquiera de las dos casillas: reacomoda los
-- marcos (nombre, numero centrado), el texto abreviado y el tamaño.
function K.ApplyBigStatusText()
	if K.ApplyPlayerFrameSkin    then pcall(K.ApplyPlayerFrameSkin);    end
	if K.ApplyTargetFrameSkin    then pcall(K.ApplyTargetFrameSkin);    end
	if K.InvalidateAbbrevAnchors then pcall(K.InvalidateAbbrevAnchors); end
	K.RefreshBigStatusFonts();
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	K.RefreshBigStatusFonts();
end);
