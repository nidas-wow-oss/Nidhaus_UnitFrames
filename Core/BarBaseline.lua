local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- BarBaseline.lua
--
-- UNA SOLA FOTO del layout limpio de las barras de Blizzard, compartida
-- por los dos modos de barras (MiniBar y Unify Action Bars).
--
-- EL PROBLEMA QUE RESUELVE
--
-- Los dos modos reescriben el layout entero: ancho de MainMenuBar, apilado
-- de filas, grifos, micro botones, bolsas, escalas. Cada uno sacaba SU
-- PROPIA foto del "antes" justo al activarse, para poder revertir despues.
--
-- Eso funciona la primera vez y falla siempre despues:
--
--   login          MiniBar saca su foto      -> estado LIMPIO, bien
--   paso a Unify   MiniBar revierte (y le faltan cosas)
--                  Unify saca su foto        -> estado SUCIO
--   vuelvo         Unify revierte a esa foto -> queda peor
--
-- La suciedad se acumula en cada cambio. Por eso terminaban las filas
-- descolocadas y la barra angosta: el modo nuevo armaba su layout sobre
-- restos del anterior. Tapar los huecos de cada lista de restauracion no
-- alcanza — son dos listas largas que hay que mantener sincronizadas a
-- mano, y cualquier olvido futuro reintroduce lo mismo.
--
-- LA SOLUCION
--
-- Sacar la foto UNA vez, cuando el estado todavia es el de Blizzard, y que
-- los dos modos vuelvan SIEMPRE a esa misma foto antes de aplicar lo suyo.
-- Asi el punto de partida es identico en cada cambio y no hay deriva
-- posible, sin importar cuantas veces alternes.
--
-- La foto se toma sola la primera vez que se pide (EnsureBaseline), que es
-- justo antes de que se active el primer modo de la sesion. En ese momento
-- todavia no toco nada nadie.
-- =========================================================

-- Todo lo que cualquiera de los dos modos mueve, redimensiona, reescala o
-- reparenta. La lista salio de leer los dos archivos, no de memoria.
local BAR_FRAMES = {
	"MainMenuBar", "MainMenuBarArtFrame",
	"MainMenuExpBar", "MainMenuBarMaxLevelBar",
	"ReputationWatchBar", "ReputationWatchStatusBar", "ReputationWatchStatusBarText",
	"MainMenuBarExpText", "ExhaustionTick",
	"MainMenuBarLeftEndCap", "MainMenuBarRightEndCap",

	-- Filas de botones
	"MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight",
	"BonusActionButton1", "PossessBarFrame", "PossessButton1",

	-- Paginado
	"ActionBarUpButton", "ActionBarDownButton", "MainMenuBarPageNumber",

	-- Mascota / cambio de forma / totems / vehiculo
	"PetActionBarFrame", "PetActionButton1", "PetActionBarHealthBar", "PetActionBarManaBar",
	"ShapeshiftBarFrame", "ShapeshiftButton1",
	"MultiCastActionBarFrame", "MainMenuBarVehicleLeaveButton",

	-- Bolsas y llavero. Estos son los que MiniBar guardaba pero NUNCA
	-- restauraba (33 guardados contra 28 restaurados): uno de los huecos
	-- que encontre al medir.
	"MainMenuBarBackpackButton", "KeyRingButton",
	"CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot",

	-- Micro botones: los dos modos los reparentan.
	"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"AchievementMicroButton", "QuestLogMicroButton", "SocialsMicroButton",
	"PVPMicroButton", "LFDMicroButton", "MainMenuMicroButton", "HelpMicroButton",
};

local baseline   = nil;   -- nil = todavia no se saco la foto
local capturing  = false;

-- ---------------------------------------------------------
-- Sacar la foto
-- ---------------------------------------------------------
local function SnapshotFrame(frame)
	local snap = {
		width  = frame.GetWidth  and frame:GetWidth()  or nil,
		height = frame.GetHeight and frame:GetHeight() or nil,
		scale  = frame.GetScale  and frame:GetScale()  or nil,
		alpha  = frame.GetAlpha  and frame:GetAlpha()  or nil,
		shown  = frame.IsShown   and frame:IsShown()   or false,
		parent = frame.GetParent and frame:GetParent() or nil,
		points = {},
	};

	-- Se guardan TODOS los puntos de anclaje, no solo el primero: varios de
	-- estos frames usan dos (por ejemplo TOPLEFT + TOPRIGHT para estirarse)
	-- y quedarse con uno solo los deformaria al restaurar.
	if frame.GetNumPoints and frame.GetPoint then
		for i = 1, (frame:GetNumPoints() or 0) do
			local p, rel, rp, x, y = frame:GetPoint(i);
			if p then
				snap.points[#snap.points + 1] = {
					point = p, rel = rel, relPoint = rp, x = x or 0, y = y or 0,
				};
			end
		end
	end

	return snap;
end

-- Devuelve true si la foto quedo tomada (ahora o antes).
function K.EnsureBarBaseline()
	if baseline or capturing then return baseline ~= nil; end
	capturing = true;

	-- Que Blizzard termine de acomodar todo antes de fotografiar.
	if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end

	local snap, n = {}, 0;
	for _, name in ipairs(BAR_FRAMES) do
		local f = _G[name];
		if f then
			local ok, res = pcall(SnapshotFrame, f);
			if ok then snap[name] = res; n = n + 1; end
		end
	end

	baseline = snap;
	capturing = false;
	K._barBaselineCount = n;
	return true;
end

-- ---------------------------------------------------------
-- Volver a la foto
-- ---------------------------------------------------------
local function RestoreFrame(frame, snap)
	if not (frame and snap) then return; end

	-- El parent primero: cambiarlo despues de anclar tirapor la borda los
	-- puntos que acabamos de poner.
	if snap.parent and frame.SetParent and frame:GetParent() ~= snap.parent then
		frame:SetParent(snap.parent);
	end

	if frame.ClearAllPoints then frame:ClearAllPoints(); end
	for _, p in ipairs(snap.points) do
		pcall(frame.SetPoint, frame, p.point, p.rel, p.relPoint, p.x, p.y);
	end

	if snap.width  and snap.width  > 0 and frame.SetWidth  then frame:SetWidth(snap.width);   end
	if snap.height and snap.height > 0 and frame.SetHeight then frame:SetHeight(snap.height); end
	if snap.scale  and snap.scale  > 0 and frame.SetScale  then frame:SetScale(snap.scale);   end
	if snap.alpha  and frame.SetAlpha then frame:SetAlpha(snap.alpha); end

	-- La visibilidad SI se restaura, junto con la geometria.
	--
	-- Probe sacarla de la foto y delegarla en MultiActionBar_Update, con la
	-- idea de que quien decide que barras se ven es Blizzard segun las
	-- CVars. En la practica salio peor: al togglear, las barras se subian.
	-- Se vuelve a como estaba, que es lo que funciona.
	if frame.Show and frame.Hide then
		if snap.shown then frame:Show(); else frame:Hide(); end
	end
end

-- Deja las barras exactamente como estaban antes de que cualquier modo las
-- tocara. Se llama entre apagar un modo y prender el otro.
function K.RestoreBarBaseline()
	-- Los botones vuelven a su anclaje y su padre antes que nada:
	-- el espaciado y el Holder de posturas los reanclan uno por uno.
	if K.RestoreActionBarButtonSpace then K.RestoreActionBarButtonSpace(); end
	if K.DetachStanceButtons then K.DetachStanceButtons(); end

	if not baseline then return false; end
	if InCombatLockdown() then return false; end

	for name, snap in pairs(baseline) do
		local f = _G[name];
		if f then pcall(RestoreFrame, f, snap); end
	end

	-- Y que Blizzard recalcule lo suyo encima de un estado limpio.
	if UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions); end
	if MainMenuBar_UpdateExperienceBars then pcall(MainMenuBar_UpdateExperienceBars); end
	return true;
end

function K.HasBarBaseline() return baseline ~= nil; end

-- ---------------------------------------------------------
-- Diagnostico
--
-- SOLO LECTURA. Aca hubo un "/nufbars restore" que devolvia las barras a la
-- foto original, y se saco: con un modo activo dejaba las barras en el
-- layout de Blizzard pero al modo creyendose aplicado, sus hooks seguian
-- corriendo y terminaba peor que antes. Intente arreglarlo haciendo que
-- re-aplicara el modo, y tampoco: las barras se subian.
--
-- El toggle normal ya funciona, asi que el comando no aportaba nada y solo
-- daba una forma de romper el layout. Este comando ahora no toca nada.
-- ---------------------------------------------------------
SLASH_NUFBARS1 = "/nufbars";
SlashCmdList["NUFBARS"] = function()
	print("|cff4FC3F7NUF barras:|r");
	print("   foto tomada: " .. (baseline and ("si, " .. (K._barBaselineCount or 0) .. " frames") or "todavia no"));
	print("   MiniBar activo: " .. tostring(K._minibarActive == true));
	print("   Unify activo:   " .. tostring(K._unifyActive == true));
end
