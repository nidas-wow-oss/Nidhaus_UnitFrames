local AddOnName, ns = ...;
local K, C, L = unpack(ns);

K.ArenaPositionSaverVersion = "V6-FEB07";

local function SaveAnchorToDB()
	local anchor = _G["NidhausArenaEnemyFrames"];
	if not anchor then return; end
	local point, relativeTo, relativePoint, x, y = anchor:GetPoint();
	if not point then return; end
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
	NidhausUnitFramesDB.positions["NidhausArenaAnchor"] = {
		point = point,
		relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
		relativePoint = relativePoint,
		x = x,
		y = y,
	};
end

local f = CreateFrame("Frame");
f:RegisterEvent("PLAYER_LEAVING_WORLD");
f:RegisterEvent("PLAYER_LOGOUT");
f:SetScript("OnEvent", function() SaveAnchorToDB(); end);

function K.SaveArenaAnchorPosition() SaveAnchorToDB(); end

function K.ResetArenaPosition()
	if NidhausUnitFramesDB and NidhausUnitFramesDB.positions then
		NidhausUnitFramesDB.positions["ArenaMover"] = nil;
		NidhausUnitFramesDB.positions["NidhausArenaAnchor"] = nil;
	end
	local anchor = _G["NidhausArenaEnemyFrames"];
	if anchor and C.ArenaFramePoint then
		anchor:ClearAllPoints();
		anchor:SetPoint(unpack(C.ArenaFramePoint));
	end
end

K.CaptureArenaPosition = function() end
K.SaveArenaPositionToDB = function() SaveAnchorToDB(); end
K.ForceRestoreArenaPosition = function() end
K.UpdateArenaScale = function(scale)
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	-- FIX: No interferir durante test mode — ArenaMover controla la escala
	if K._testModeActive then return; end
	-- Escalar el container de Blizzard.
	-- En arena real: ArenaEnemyFrames es hijo de NidhausArenaEnemyFrames, y los
	-- ArenaEnemyFrame1-5 son hijos de ArenaEnemyFrames. Escalar ArenaEnemyFrames
	-- cascadea automáticamente a todos sus hijos (herencia parent→child).
	-- NOTA: NidhausArenaEnemyFrames es solo un anchor posicional y NO debe ser escalado,
	-- porque escalar ambos causaría efectiveScale = scale × scale (doble escala).
	if ArenaEnemyFrames then
		ArenaEnemyFrames:SetScale(scale);
	end
end
K.UpdateArenaPosition = function(point, relName, relPoint, x, y)
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.positions then NidhausUnitFramesDB.positions = {}; end
	-- FIX: Formato con nombres, consistente con ArenaMover y FrameDragger
	NidhausUnitFramesDB.positions["NidhausArenaAnchor"] = {
		point = point,
		relativeTo = relName,
		relativePoint = relPoint,
		x = x,
		y = y,
	};
end