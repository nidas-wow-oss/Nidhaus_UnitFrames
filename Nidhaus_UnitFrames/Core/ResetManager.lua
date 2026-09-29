local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ResetManager.lua  --  UN SOLO DUENO DEL "VOLVER A EMPEZAR"
--
-- EL PROBLEMA QUE RESUELVE.
--
-- Habia DOS botones de Reset: el de la consola de "Move Everything" y el
-- de la pestaña Action Bars. Cada uno armaba su propia secuencia. Se
-- parecian, pero no eran la misma, y ahi estaba la incompatibilidad:
--
--   - el de Action Bars borraba lo guardado y reponia escalas, pero NO
--     deshacia el aplanado de la pila de MiniBar, asi que en pantalla no
--     volvia nada a su lugar;
--   - el de Move Everything si lo deshacia, pero no tocaba el ajuste
--     ActionBarScale del panel, que Ctrl + rueda tambien escribe.
--
-- Cada vez que se arreglaba uno, el otro quedaba a medio camino.
--
-- Aca vive la secuencia UNA sola vez. Los botones ya no deciden nada:
-- piden. Si algun dia aparece un tercer boton, llama a lo mismo.
--
-- EL ORDEN IMPORTA, y es lo que costo encontrar:
--
--   1. devolver el AJUSTE de escala a fabrica  (antes que nada, porque el
--      rearmado lo lee)
--   2. borrar las posiciones y escalas guardadas
--   3. deshacer el aplanado y rearmar el layout
--
-- Saltarse el 3 es exactamente lo que hacia que el boton "no hiciera
-- nada": los datos se borraban y las barras se quedaban donde estaban.
-- =========================================================

-- Todo lo que vive en el area de las barras de accion. No es solo las
-- tres filas: postura, totem, mascota y posesion se mueven desde ahi
-- mismo, asi que un reset que las deje afuera hace medio trabajo.
local BAR_KEYS = {
	"MainBar", "ActionBar2", "ActionBar3",
	"StanceBar", "TotemBar", "PetBar", "PossessBar",
};

-- Las claves SIMPLES, sin el sufijo del modo.
--
-- En la DB se guardan con el modo pegado (MainBar#mini, MainBar#unify)
-- para que cada modo recuerde lo suyo, pero ResetGlobalPositions espera la
-- clave pelada: la usa para saber a que movible reponerle su original, y
-- ahi el nombre es "MainBar" a secas. La traduccion al modo la hace el
-- borrado, adentro.
--
-- Pasarle las claves ya traducidas era el motivo por el que este boton
-- borraba los datos pero no movia nada en pantalla.
local function BarKeySet()
	local keys = {};
	for _, k in ipairs(BAR_KEYS) do keys[k] = true; end
	return keys;
end

-- La escala de fabrica del panel.
--
-- Va aparte del borrado de la DB porque Ctrl + rueda escribe en DOS
-- lados: la escala del movible en globalPos Y el ajuste ActionBarScale,
-- para que el slider no quede desincronizado. Limpiar solo el primero
-- dejaba el segundo con la escala agrandada, y el rearmado la volvia a
-- aplicar: el reset te devolvia justo a donde estabas.
local function ResetBarScaleSetting()
	local def = (K.GetConfigDefault and K.GetConfigDefault("ActionBarScale")) or 1.0;
	if C then C.ActionBarScale = def; end
	if K.SaveConfig then pcall(K.SaveConfig, "ActionBarScale", def); end
	if K.RefreshScaleSliders then pcall(K.RefreshScaleSliders); end
	return def;
end

-- EL PASO QUE FALTABA.
--
-- Al abrir el modo mover, la pila de MiniBar se APLANA: cada cosa pasa a
-- estar anclada a UIParent en coordenadas absolutas, para que arrastrar
-- una no se lleve a las de arriba. Borrar la DB no deshace eso.
--
-- ResetMiniBarLayout es quien lo deshace: suelta los anclajes, repone
-- escalas y fuerza el rearmado aunque el modo mover este abierto -- que
-- es justo cuando se aprieta el boton.
-- Un cuadro de espera. Ver el final de RelayoutBars.
local resync = CreateFrame("Frame");
resync:Hide();
resync:SetScript("OnUpdate", function(self)
	self:Hide();
	if C.MiniBarEnabled ~= true then return; end
	if InCombatLockdown() then return; end
	if K.ApplyBarHolderScales then
		pcall(K.ApplyBarHolderScales, C.ActionBarScale or 1.0);
	end
end);

local function RelayoutBars()
	if InCombatLockdown() then return; end

	if C.MiniBarEnabled == true then
		if K.ResetMiniBarLayout then pcall(K.ResetMiniBarLayout); end
	elseif K.ApplyActionBarButtonSpace then
		pcall(K.ApplyActionBarButtonSpace);
	end

	if K.UpdateActionBarsBox then pcall(K.UpdateActionBarsBox); end

	-- Y UNA PASADA MAS, UN CUADRO DESPUES.
	--
	-- El reset dispara varias cosas -- reponer originales, soltar anclajes,
	-- rearmar -- y cualquiera de ellas puede dejar el fondo (MainMenuBar)
	-- despegado del contenedor de la fila 1, porque su anclaje depende de
	-- la escala que quede puesta AL FINAL.
	--
	-- En vez de adivinar cual de todas fue, se reescribe el anclaje cuando
	-- ya no queda nada corriendo. Es idempotente: escribe siempre el mismo
	-- valor, asi que repetirlo no acumula nada.
	if C.MiniBarEnabled == true then resync:Show(); end
end

-- ---------------------------------------------------------
-- SOLO LAS BARRAS DE ACCION
--
-- Lo que usa el boton Reset de la pestaña Action Bars. Misma secuencia
-- que el reset general, pero acotada: no toca buffs, minimapa, marcos de
-- unidad ni nada que no sea el area de barras.
-- ---------------------------------------------------------
function K.ResetActionBars()
	ResetBarScaleSetting();

	if K.ResetGlobalPositions then
		K.ResetGlobalPositions(BarKeySet());
	end

	RelayoutBars();
end

-- ---------------------------------------------------------
-- LAS OTRAS ZONAS DEL ADDON PRINCIPAL
--
-- Mismo patron: un grupo de claves y, si la zona tiene un store propio
-- ademas de globalPos, la llamada que lo limpia. Las pestañas de Addons y
-- Arena tienen sus resets aparte y no se tocan desde aca.
--
-- Cada grupo pasa por ResetGlobalPositions, que es quien sabe reponer
-- posicion Y escala y devolver el frame a su sitio de fabrica. Antes cada
-- boton hacia su propia cuenta.
-- ---------------------------------------------------------
local function ResetKeys(list, after)
	local keys = {};
	for _, k in ipairs(list) do keys[k] = true; end
	if K.ResetGlobalPositions then K.ResetGlobalPositions(keys); end
	if after then after(); end
end

-- Buffs y debuffs. El ancla de auras guarda ademas en su propio store,
-- asi que hay que limpiarlo aparte o el proximo login repone lo viejo.
function K.ResetAuras()
	ResetKeys({ "Buffs", "Debuffs" }, function()
		if K.ResetAuraAnchor then pcall(K.ResetAuraAnchor); end
		if K.ReanchorAuras   then pcall(K.ReanchorAuras);   end
		if K.ReanchorDebuffs then pcall(K.ReanchorDebuffs); end
	end);
end

function K.ResetCastBar()
	ResetKeys({ "CastBar" }, function()
		if K.ResetCastBarPositions then pcall(K.ResetCastBarPositions); end
	end);
end

function K.ResetMinimap()
	ResetKeys({ "Minimap" });
end

-- Los marcos de unidad: jugador, objetivo, mascota y los cuatro del grupo.
-- Incluye las escalas, que es lo que hacia el boton "Reset All Scales" por
-- su cuenta escribiendo en C a mano.
-- Los ajustes de escala y separacion que muestra la pestaña Frames.
--
-- SOLO LA LISTA DE NOMBRES: el valor de fabrica de cada uno sale de
-- ConfigManager, que es el unico lugar donde esos numeros viven de
-- verdad. Antes habia TRES copias de la tabla de defaults -- aca, en
-- FrameDragger y adentro del boton del panel -- y no coincidian: el
-- boton reseteaba PetFrameScale y las separaciones pero no ArenaFrameScale,
-- y FrameDragger al reves. Segun cual apretaras, quedabas distinto.
local UNITFRAME_SCALES = {
	"PlayerFrameScale", "TargetFrameScale",
	"FocusScale", "FocusSpellBarScale",
	"PetFrameScale",
	"PartyFrameScale", "PartyMemberFrameSpacing",
	"BossFrameScale", "BossTargetFrameSpacing",
	-- Las cuatro escalas por miembro del 3v3. Van ANTES de que el paso 4
	-- re-aplique el modo, asi el grupo vuelve a 1.5 / 1.5 / 1.3 / 1.3 y
	-- no a lo que tuvieras en los sliders.
	"Party3v3Scale1", "Party3v3Scale2", "Party3v3Scale3", "Party3v3Scale4",
};

function K.ResetUnitFrames()
	ResetKeys({
		"Player", "Target", "Pet",
		"Party1", "Party2", "Party3", "Party4",
		"PartyCast", "PartyTarget",
	}, function()
		-- 1) posiciones guardadas y escalas de los movibles
		if K.ResetPositionsAndScale then pcall(K.ResetPositionsAndScale); end

		-- 2) los ajustes del panel, al valor de fabrica, de UNA sola fuente
		for _, key in ipairs(UNITFRAME_SCALES) do
			local def = K.GetConfigDefault and K.GetConfigDefault(key);
			if def ~= nil then
				C[key] = def;
				if K.SaveConfigSilent then pcall(K.SaveConfigSilent, key, def); end

				-- Y donde escribe Ctrl + rueda, si el frame es movible: sin
				-- esto el reset duraba hasta el proximo login.
				local movables = K.GetMovablesForSetting and K.GetMovablesForSetting(key);
				if movables and K.SetGlobalFrameScale then
					for _, mk in ipairs(movables) do pcall(K.SetGlobalFrameScale, mk, def); end
				end
			end
		end
		if K.FlushConfigChanges then pcall(K.FlushConfigChanges); end

		-- 3) EN EL ACTO, lo que no pasa por el modo mover.
		--
		-- Esto es lo que faltaba y por lo que el boton viejo terminaba
		-- diciendo "/reload para restaurar del todo": escribia los numeros
		-- pero no llamaba a nadie que los aplicara.
		if K.ApplyFocusFrameScale  then pcall(K.ApplyFocusFrameScale,  C.FocusScale); end
		if K.ApplyPetFrameScale    then pcall(K.ApplyPetFrameScale,    C.PetFrameScale); end
		if K.ApplyBossFrameScale   then pcall(K.ApplyBossFrameScale,   C.BossFrameScale); end
		if K.ApplyBossFrameSpacing then pcall(K.ApplyBossFrameSpacing); end
		if FocusFrameSpellBar then
			pcall(FocusFrameSpellBar.SetScale, FocusFrameSpellBar, C.FocusSpellBarScale or 1.2);
		end

		-- 4) EL 3v3 MANDA SOBRE LA ESCALA DEL GRUPO.
		--
		-- Sin esto, resetear con el 3v3 puesto dejaba los cuatro marcos en
		-- 1.0 y las posiciones del modo: medio reseteado y medio no.
		if K.Is3v3Active and K.Is3v3Active() then
			if K.Apply3v3PartyMode then pcall(K.Apply3v3PartyMode); end
		else
			if K.ApplyPartyFrameScale then pcall(K.ApplyPartyFrameScale, C.PartyFrameScale); end
			if K.ApplyPartyFrameSpacing then pcall(K.ApplyPartyFrameSpacing); end
		end

		-- 5) y que el panel muestre los numeros nuevos
		if K.RefreshScaleSliders then pcall(K.RefreshScaleSliders); end
		if K.RefreshCastBarScaleSlider then pcall(K.RefreshCastBarScaleSlider); end
		-- Los del 3v3 no estan en la lista de RefreshScaleSliders (son
		-- otro tipo de slider, mas chico), asi que tienen su propio aviso.
		-- Refresca los de las DOS pestañas, General y Party.
		if K.Refresh3v3Sliders then pcall(K.Refresh3v3Sliders); end
	end);
end

-- ---------------------------------------------------------
-- TODO
--
-- Lo que usa el boton Reset de la consola de "Move Everything".
-- ResetGlobalPositions sin filtro ya limpia todos los movibles; lo que se
-- suma aca es el ajuste de escala del panel y la red de seguridad del
-- rearmado, para que los dos botones terminen en el mismo estado.
-- ---------------------------------------------------------
function K.ResetEverything()
	ResetBarScaleSetting();

	if K.ResetGlobalPositions then
		K.ResetGlobalPositions();
	end

	RelayoutBars();
end
