local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- LayoutCore.lua  --  UN SOLO CAMINO PARA REARMAR LA INTERFAZ
--
-- POR QUE EXISTE ESTE ARCHIVO. Lo siguiente esta MEDIDO, no supuesto.
--
-- Se contaron los sistemas que guardan y reponen el estado de LOS MISMOS
-- marcos:
--
--     BarBaseline   baseline         la foto limpia. Completa y bien hecha.
--     MiniBar       mb_savedFrames   su propia foto, con UN SOLO anclaje
--     Unify         saved            otra foto
--     Unify         origSetPoints    otra mas
--     ActionBars    btnOrig          otra
--     GlobalUnlock  globalPos        las posiciones del usuario
--     FrameDragger  positions        OTRAS posiciones del usuario
--     ...y cada modulo con su store propio (auras, arena, timers)
--
-- Y los marcos con MAS DE UN DUENO escribiendoles posicion, escala o
-- padre: MainMenuBar, MultiBarBottomLeft, MultiBarBottomRight,
-- MainMenuExpBar.
--
-- De ahi salen TODOS los bugs de esta familia, y siempre con el mismo
-- guion: alguien repone media cosa, otro repone la otra media, y el orden
-- en que corran decide como queda. Se apaga un modo y algo no vuelve. Se
-- recarga y vuelve. Se arregla un camino y se rompe otro.
--
-- ---------------------------------------------------------
-- LA REGLA, UNA SOLA
--
--   Rearmar NO es deshacer paso por paso. Es volver al estado limpio y
--   aplicar de nuevo, SIEMPRE en el mismo orden:
--
--       0. apagar lo que este puesto
--       1. aplicar el modo activo   MiniBar / Unify / ninguno
--       2. lo que guardo el usuario  (globalPos + cada store propio)
--
-- Deshacer paso por paso es lo que veniamos haciendo, y no se puede
-- sostener: cada cosa nueva que un modo toca hay que acordarse de
-- deshacerla, y el dia que alguien se olvida -- o la repone a medias --
-- aparece un bug que solo se ve al alternar. Asi se perdio el ancho del
-- marco del arte, asi se perdio su padre, asi se quedo la barra de auras
-- donde no iba.
--
-- Volver a cero y reconstruir no se puede olvidar de nada, porque no hay
-- lista de deshacer que mantener. Es la misma idea que usan Dominos y
-- Bartender: el estado en pantalla es una FUNCION de (foto + modo +
-- guardado), y se recalcula entero cada vez.
--
-- ---------------------------------------------------------
-- EL REGISTRO DE STORES es la otra mitad.
--
-- Cada modulo que guarda posiciones propias -- auras, arena, timers -- se
-- anota aca UNA vez, y el paso 3 los llama a todos. Asi no hay forma de
-- que un toggle re-aplique unas posiciones y se olvide de otras, que es
-- exactamente por que la barra de auras no volvia a su lugar: sus
-- posiciones viven en un store aparte de globalPos, y el toggle solo
-- reponia globalPos.
--
-- Anotarse es UNA linea. Olvidarse ya no es posible sin que se note.
-- =========================================================

-- ---------------------------------------------------------
-- Registro de stores
-- ---------------------------------------------------------
local stores    = {};
local rebuilding = false;
local pendingCombat = false;

-- name  = para poder verlo en el diagnostico y para no duplicar
-- apply = funcion que vuelve a aplicar lo que ese modulo tenga guardado
function K.LayoutRegisterStore(name, applyFn)
	if type(name) ~= "string" or type(applyFn) ~= "function" then return false; end
	for _, s in ipairs(stores) do
		-- Re-registrar pisa: gana el ultimo. Asi recargar un modulo no
		-- deja dos entradas llamando a dos versiones de lo mismo.
		if s.name == name then s.apply = applyFn; return true; end
	end
	stores[#stores + 1] = { name = name, apply = applyFn };
	return true;
end

function K.LayoutStoreNames()
	local out = {};
	for i, s in ipairs(stores) do out[i] = s.name; end
	return out;
end

-- ---------------------------------------------------------
-- El modo activo sale de la CONFIGURACION, no de banderas internas.
--
-- Las banderas (minibarEnabled, _unifyActive) dicen "que hay puesto
-- ahora", que durante un rearmado es justo lo que esta cambiando. La
-- configuracion dice "que TIENE que haber", que es lo unico estable.
-- ---------------------------------------------------------
local function ActiveMode()
	if C.MiniBarEnabled  == true then return "mini";  end
	if C.UnifyActionBars == true then return "unify"; end
	return "plain";
end
K.LayoutActiveMode = ActiveMode;

-- ---------------------------------------------------------
-- EL REARMADO
-- ---------------------------------------------------------
function K.LayoutRebuild(reason)
	-- En combate no se pueden mover marcos protegidos. No se fuerza ni se
	-- hace a medias: se anota y se rehace entero al salir.
	if InCombatLockdown() then
		pendingCombat = true;
		return false;
	end

	-- Sin reentrada. El paso 2 llama a los modos, y los modos disparan
	-- repintados que podrian volver a pedir un rearmado: eso seria una
	-- vuelta infinita.
	if rebuilding then return false; end
	rebuilding = true;

	-- 0) APAGAR LO QUE ESTE PUESTO.
	--
	--    NO por la geometria: de eso se encarga el paso 1, y por eso este
	--    paso ya no es el que sostiene nada. Se llama por lo que una foto
	--    NO puede deshacer, porque no es posicion ni tamaño:
	--
	--      - eventos que el modo dejo enganchados
	--      - marcos propios del modo que quedan visibles (BagPackFrame)
	--      - entradas que el modo saco de UIPARENT_MANAGED_FRAME_POSITIONS
	--
	--    La diferencia con antes es cual de los dos manda. Antes este paso
	--    era el unico que devolvia las cosas a su lugar, asi que cualquier
	--    olvido suyo -- un ancho, un padre, un anclaje de dos esquinas --
	--    quedaba en pantalla. Ahora el paso 1 pasa por encima y arregla lo
	--    que este haya hecho mal.
	if K._minibarActive and K.DisableMiniBar then
		pcall(K.DisableMiniBar);
	end
	if K._unifyActive and K.DisableUnifyActionBars then
		pcall(K.DisableUnifyActionBars);
	end

	-- 1) EL MODO QUE CORRESPONDE.
	--
	-- ACA ME PASE DE LISTO Y LO ROMPI. Lo dejo escrito para no repetirlo.
	--
	-- Habia puesto un RestoreBarBaseline() aca en el medio, y como los
	-- Enable... se cortan si creen que ya estan puestos, tuve que agregar
	-- ademas un "marcalos como apagados". Dos pasos nuevos, ninguno
	-- probado, en el camino mas delicado del addon: alternar modos quedo
	-- peor que antes -- botones de postura metidos entre los de accion y
	-- una fila de casillas vacias colgada.
	--
	-- No hacian falta NINGUNO de los dos. EnableMiniBar y
	-- EnableUnifyActionBars ya reponen la foto de fabrica ellos mismos,
	-- antes de aplicar lo suyo (mira EnsureBarBaseline / RestoreBarBaseline
	-- adentro de cada uno). Reponerla otra vez aca afuera solo servia para
	-- dejar el estado a mitad de camino entre el paso 0 y el 1.
	--
	-- Queda el camino de siempre, que es el que andaba: apagar, prender.
	-- Lo NUEVO de este core es el paso 2, que es lo que de verdad faltaba.
	local mode = ActiveMode();
	if mode == "mini" then
		if K.EnableMiniBar then pcall(K.EnableMiniBar); end
	elseif mode == "unify" then
		if K.EnableUnifyActionBars then pcall(K.EnableUnifyActionBars); end
	else
		-- Sin modo: las barras quedan como las trae el juego. Aca si va la
		-- foto, porque no hay ningun Enable que la reponga.
		if K.RestoreBarBaseline then pcall(K.RestoreBarBaseline); end
	end

	-- 2) LO QUE GUARDO EL USUARIO.
	--    Primero el store general, despues los propios de cada modulo.
	if K.RestoreGlobalPositions then pcall(K.RestoreGlobalPositions); end
	for _, s in ipairs(stores) do pcall(s.apply); end

	rebuilding = false;
	return true;
end

-- Lo que quedo pendiente por combate se hace apenas termina.
local combat = CreateFrame("Frame");
combat:RegisterEvent("PLAYER_REGEN_ENABLED");
combat:SetScript("OnEvent", function()
	if not pendingCombat then return; end
	pendingCombat = false;
	K.LayoutRebuild("fin de combate");
end);
