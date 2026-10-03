local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local SecureUnitButton_OnLoad, ToggleDropDownMenu = SecureUnitButton_OnLoad, ToggleDropDownMenu;
local unpack, tonumber, _G, ipairs, pairs, setmetatable = unpack, tonumber, _G, ipairs, pairs, setmetatable;

--	Create Backdrop (Player & Target Frames);
function K.CreateBackdrop(Obj)
	if Obj.Backdrop then return; end;
	
	local Backdrop = CreateFrame("Frame", nil, Obj);
	Backdrop:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]});
	Backdrop:SetBackdropColor(unpack(C.statusbarBackdropColor));
	Backdrop:SetPoint("TOPLEFT",Obj.healthbar, "TOPLEFT");
	Backdrop:SetPoint("BOTTOMRIGHT",Obj.manabar, "BOTTOMRIGHT");
	if Obj:GetFrameLevel() - 1 >= 0 then
		Backdrop:SetFrameLevel(Obj:GetFrameLevel() - 1);
	else
		Backdrop:SetFrameLevel(0);
	end;
	
	Obj.Backdrop = Backdrop;
end;

--	Move Frames;
function K.MoveFrame(Obj, NewFrameName, UnitId, xOffset, yOffset, ParentBossFrame)
	CreateFrame("Button", NewFrameName, UIParent, "SecureUnitButtonTemplate");
	local Frame = _G[NewFrameName];
	Frame:SetFrameStrata(Obj:GetFrameStrata());
	Frame:SetFrameLevel(Obj:GetFrameLevel());
	Frame:SetHeight(Obj:GetHeight());
	Frame:SetWidth(Obj:GetWidth());
	
	ClickCastFrames = ClickCastFrames or {};
	ClickCastFrames[Frame] = true;
	
	Frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	
	local ShowMenu = function()
		ToggleDropDownMenu(1, nil, _G[Obj:GetName().."DropDown"], NewFrameName, xOffset, yOffset);
	end
	SecureUnitButton_OnLoad(Frame, UnitId, ShowMenu);
	
	for _, script in ipairs({"OnEnter", "OnLeave", "OnReceiveDrag"}) do
		Frame:SetScript(script, Obj:GetScript(script));
	end;
	
	-- FIX: Solo llamar EnableMouse una vez
	Obj:EnableMouse(false);
	
	setmetatable(Frame, {__index = Obj});
	
	local point, relativeTo, relativePoint, xOffset, yOffset;
	for _, child in pairs({Obj:GetChildren()}) do
		child:SetParent(Frame);
		for pointNum = 1, child:GetNumPoints() do
			point, relativeTo, relativePoint, xOffset, yOffset = child:GetPoint(pointNum);
			if (relativeTo == Obj) then
				child:SetPoint(point, Frame, relativePoint, xOffset, yOffset);
				if NewFrameName:find("Boss") and child:GetName():find("Bar") then 
					child:SetFrameLevel(Frame:GetFrameLevel()-1);
				end;
			end;
		end;
	end;
	for _, child in pairs({Obj:GetRegions()}) do
		child:SetParent(Frame);
		for pointNum = 1, child:GetNumPoints() do
			point, relativeTo, relativePoint, xOffset, yOffset = child:GetPoint(pointNum);
			if (relativeTo == Obj) then
				child:SetPoint(point, Frame, relativePoint, xOffset, yOffset);
			end;
		end;
	end;
	Frame:SetParent(Obj);
	
	if UnitId:find("Boss") then
		local id = tonumber(UnitId:sub(5, 5));
		if id == 1 then
			Frame:SetPoint("TOPLEFT", ParentBossFrame, 0, 0);
		else
			Frame:SetPoint("TOPLEFT", ParentBossFrame["Boss"..id-1], "BOTTOMLEFT", 0, -(C.BossTargetFrameSpacing or 0));
		end;
		ParentBossFrame["Boss"..id] = Frame;
	end;
end;

--	Move Point;
function K.SetOffset(Obj, x, y)
	local point, relativeTo, relativePoint, xOffset, yOffset = Obj:GetPoint(1);
	return point, relativeTo, relativePoint, xOffset + x, yOffset + y;
end;

-- ═══════════════════════════════════════════════════════════
-- GetArenaPositionKey — composite key per style + mirror mode
-- Used by CastBarPositions and TrinketPositions to save/load
-- positions independently per arena style (Blizzard/Custom/Flat)
-- and per mirror mode (normal/mirror).
-- ═══════════════════════════════════════════════════════════
function K.GetArenaPositionKey()
	local style = C.ArenaFrameStyle or "Custom";
	local mirror = C.ArenaMirrorMode and "mirror" or "normal";
	return style .. "_" .. mirror;
end
-- ═══════════════════════════════════════════════════════════
-- Skin state capture/restore (para el checkbox "Custom Skin").
-- Guarda UNA sola vez el estado original de un elemento (textura,
-- geometría de una statusbar, o el punto de anclaje de un texto)
-- la primera vez que se llama, y permite restaurarlo tal cual.
--
-- Por qué "una sola vez": la primera captura ocurre justo antes de
-- que el addon pise el valor por primera vez, así siempre agarra el
-- default real de Blizzard (sin importar el core ni el timing). Las
-- llamadas siguientes NO re-capturan, así que nunca se guarda un
-- valor ya modificado por el addon.
-- ═══════════════════════════════════════════════════════════
local skinCapture = {};

-- Captura (una vez) y devuelve la textura original de una region.
function K.CaptureTexture(region, id)
	if not region then return; end
	if skinCapture[id] == nil then
		skinCapture[id] = region:GetTexture() or false;
	end
end

function K.RestoreTexture(region, id)
	if not region then return; end
	local tex = skinCapture[id];
	if tex ~= nil and tex ~= false then
		region:SetTexture(tex);
	end
end

-- Captura (una vez) la geometría original (point + size) de una statusbar.
function K.CaptureBarGeometry(bar, id)
	if not bar then return; end
	if skinCapture[id] == nil then
		local point, relativeTo, relativePoint, x, y = bar:GetPoint(1);
		skinCapture[id] = {
			point = point,
			relativeTo = relativeTo,
			relativePoint = relativePoint,
			x = x or 0,
			y = y or 0,
			w = bar:GetWidth(),
			h = bar:GetHeight(),
		};
	end
end

function K.RestoreBarGeometry(bar, id)
	if not bar then return; end
	local d = skinCapture[id];
	if type(d) ~= "table" then return; end
	bar:ClearAllPoints();
	if d.point then
		bar:SetPoint(d.point, d.relativeTo or bar:GetParent(), d.relativePoint, d.x, d.y);
	end
	if d.h and d.h > 0 then bar:SetHeight(d.h); end
end

-- Captura (una vez) el/los anclaje(s) original(es) de un texto/region
-- y permite restaurarlos. Guarda TODOS los points (un texto puede tener
-- varios), para reproducir exactamente el anclaje default.
function K.CaptureAnchors(region, id)
	if not region then return; end
	if skinCapture[id] == nil then
		local pts = {};
		for i = 1, region:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = region:GetPoint(i);
			pts[i] = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, x = x or 0, y = y or 0 };
		end
		skinCapture[id] = pts;
	end
end

function K.RestoreAnchors(region, id)
	if not region then return; end
	local pts = skinCapture[id];
	if type(pts) ~= "table" then return; end
	region:ClearAllPoints();
	for _, p in ipairs(pts) do
		if p.point then
			region:SetPoint(p.point, p.relativeTo, p.relativePoint, p.x, p.y);
		end
	end
end


-- =========================================================
-- EL TEMA VISUAL, APLICADO ENTERO Y EN EL ACTO
--
-- POR QUE EL PANEL PEDIA /reload.
--
-- El desplegable de "Visual Theme" cambia tres banderas -- darkFrames,
-- AsuriFrames y pwFrames -- y despues llamaba SOLO a dos consumidores: el
-- skin del jugador y el del objetivo. Pero esas banderas las leen tambien
-- los marcos del GRUPO, los de JEFE y el borde de los trinkets de arena.
-- Esos tres se quedaban con el tema anterior.
--
-- O sea que el cartel no mentia del todo: el cambio se veia a medias, y
-- recargar era la unica forma de emparejarlo. Lo que estaba mal no era el
-- cartel sino que faltaba avisarle a la mitad de la casa.
--
-- Aca estan todos, en un solo lugar. Si manana aparece otro consumidor del
-- tema, se agrega en esta funcion y no hay que acordarse de tocar tambien
-- el desplegable -- que es exactamente como se llego a esto.
--
-- Los marcos de ARENA no estan: su estilo se rearma al entrar a la arena y
-- tienen su propio camino (UpdateFlatStyle), que ademas sale temprano si el
-- modo plano no esta puesto. Meterlos aca seria pelear con ese sistema.
-- =========================================================
function K.ApplyUnitFrameTheme()
	if K.ApplyPlayerFrameSkin      then pcall(K.ApplyPlayerFrameSkin);      end
	if K.ApplyTargetFrameSkin      then pcall(K.ApplyTargetFrameSkin);      end  -- objetivo Y foco
	if K.RestylePartyFrames        then pcall(K.RestylePartyFrames);        end
	if K.RestyleBossFrames         then pcall(K.RestyleBossFrames);         end
	if K.RefreshClassOutlines      then pcall(K.RefreshClassOutlines);      end
	if K.UpdateTrinketBorderColors then pcall(K.UpdateTrinketBorderColors); end
	-- El tamaño del texto grande depende del tema (solo Light/Dark/Compact).
	if K.RefreshBigStatusFonts     then pcall(K.RefreshBigStatusFonts);     end
	-- El skin del objetivo/foco reancla el texto de vida: que el abreviado
	-- recapture la posicion buena (el del jugador ya lo pide solo).
	if K.InvalidateAbbrevAnchors   then pcall(K.InvalidateAbbrevAnchors);   end
end

-- =========================================================
-- TEXTO GRANDE  (Interface > General > Status Text > Big text)
--
-- Saca el nombre de adentro del marco y lo pone ARRIBA, como el modo de
-- marcos gruesos de RougeUI. Asi la barra de vida queda libre y el numero
-- puede ir centrado y mas grande (C.BigTextCustomSize + sliders).
--
-- Solo con el Custom Skin en Light, Dark o Compact: esos tres ya son
-- marcos gruesos (barra de vida alta, nombre encima de la barra). Asuri
-- tiene otro reparto y el marco de Blizzard tiene su lugar para el nombre.
-- En el jugador tampoco con el marco de hielo del mago, que tapa al tema.
--
-- unit: "player" | "target" | "focus" (o nil = sin mirar el hielo).
-- Vive aca, en Core, porque la consultan PlayerFrame, TargetFrame, el
-- texto abreviado y el modulo de tamaño, que cargan en ese orden.
-- =========================================================
function K.BigStatusTextOn(unit)
	if not C.BigStatusText then return false; end
	if C.UnitFrameCustomTexture ~= true then return false; end
	if C.AsuriFrames then return false; end
	if unit == "player" and K.IcyPlayerFrameOn and K.IcyPlayerFrameOn() then return false; end
	return true;
end

-- Tamaño propio de los numeros: solo con el texto grande puesto.
function K.BigStatusSizeOn(unit)
	return (C.BigTextCustomSize and K.BigStatusTextOn(unit)) and true or false;
end

-- =========================================================
-- DESPUES DEL COMBATE
--
-- Los marcos de arena, los del grupo y sus mascotas son PROTEGIDOS: en
-- combate el juego no deja moverlos, escalarlos, cambiarles el padre ni
-- mostrarlos u ocultarlos desde un addon. Cada intento se corta y queda
-- anotado en taint.log como "An action was blocked in combat". En una
-- noche de arenas eran unos 3.700.
--
--   if K.AfterCombat("clave", fn) then return; end
--
-- Fuera de combate devuelve false y el llamador sigue normal. En combate
-- anota fn, devuelve true y fn corre al terminar la pelea. Misma clave =
-- una sola vez (gana la ultima): doscientos avisos de ARENA_OPPONENT_UPDATE
-- en una pelea terminan en UNA pasada al final.
-- =========================================================
local afterCombat, afterCombatOrder = {}, {};
local afterCombatFrame = CreateFrame("Frame");
afterCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
afterCombatFrame:SetScript("OnEvent", function()
	local list, order = afterCombat, afterCombatOrder;
	afterCombat, afterCombatOrder = {}, {};
	for _, key in ipairs(order) do
		local fn = list[key];
		if fn then pcall(fn); end
	end
end);

function K.AfterCombat(key, fn)
	if not InCombatLockdown() then return false; end
	if not afterCombat[key] then table.insert(afterCombatOrder, key); end
	afterCombat[key] = fn;
	return true;
end
