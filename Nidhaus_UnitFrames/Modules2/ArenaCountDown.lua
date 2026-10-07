-- /script countdown = 60

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hidden = false;
local countdown = -1;
-- La cuenta del ojo se define mas abajo; la de las puertas la avisa al
-- llegar a 0 (respaldo por si el mensaje de inicio no se reconoce).
local EyeFromCountdown;
-- local eyesTime = -1;

local ACDFrame = CreateFrame("Frame", "NUF_ACDFrame", UIParent)
function ACDFrame:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	self[event](self, ...) -- route event parameters to LoseControl:event methods
end
ACDFrame:SetScript("OnEvent", ACDFrame.OnEvent)
ACDFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
-- FIX PERF: Start hidden — OnUpdate only runs when countdown is active
ACDFrame:Hide()

local ACDNumFrame = CreateFrame("Frame", "ACDNumFrame", UIParent)
-- Escala configurable desde el panel (registro central en ScaleAPI).
if K.RegisterScalable then K.RegisterScalable("ArenaCountDown", ACDNumFrame, 1.0); end
-- Los numeros cambian de tamaño solos (dos cifras mas chicas): antes eso
-- se hacia con SetScale(1.0 / 0.7) a secas y pisaba el slider en cada
-- numero. Ahora es relativo a la escala del slider.
local function ACDScale(base)
	local s = (K.GetModuleScale and K.GetModuleScale("ArenaCountDown")) or 1.0;
	return base * s;
end
ACDNumFrame:SetHeight(256)
ACDNumFrame:SetWidth(256)
ACDNumFrame:SetPoint("CENTER", 0, 128)
ACDNumFrame:Show()

local ACDNumTens = ACDNumFrame:CreateTexture("ACDNumTens", "HIGH")
ACDNumTens:SetWidth(256)
ACDNumTens:SetHeight(128)
ACDNumTens:SetPoint("CENTER", ACDNumFrame, "CENTER", -48, 0)

local ACDNumOnes = ACDNumFrame:CreateTexture("ACDNumOnes", "HIGH")
ACDNumOnes:SetWidth(256)
ACDNumOnes:SetHeight(128)
ACDNumOnes:SetPoint("CENTER", ACDNumFrame, "CENTER", 48, 0)

local ACDNumOne = ACDNumFrame:CreateTexture("ACDNumOne", "HIGH")
ACDNumOne:SetWidth(256)
ACDNumOne:SetHeight(128)
ACDNumOne:SetPoint("CENTER", ACDNumFrame, "CENTER", 0, 0)

ACDFrame:SetScript("OnUpdate", function(self, elapse )
	if (countdown > 0) then
		hidden = false;

		if ((math.floor(countdown) ~= math.floor(countdown - elapse)) and (math.floor(countdown - elapse) >= 0)) then
			local str = tostring(math.floor(countdown - elapse));

			if (math.floor(countdown - elapse) == 0) then
				-- FIX: Show "Fight!" texture instead of hiding
				ACDNumTens:Hide();
				ACDNumOnes:Hide();
				ACDNumOne:Show();
				ACDNumOne:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\fight");
				ACDNumFrame:SetScale(ACDScale(1.0));
				if EyeFromCountdown then EyeFromCountdown(); end
			elseif (string.len(str) == 2) then
				-- Display has 2 digits
				ACDNumTens:Show();
				ACDNumOnes:Show();

				ACDNumTens:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\".. string.sub(str,0,1));
				ACDNumOnes:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\".. string.sub(str,2,2));
				ACDNumFrame:SetScale(ACDScale(0.7))
			elseif (string.len(str) == 1) then
				-- Display has 1 digit
				ACDNumOne:Show();
				ACDNumOne:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Artwork\\".. string.sub(str,0,1));
				ACDNumOnes:Hide();
				ACDNumTens:Hide();
				ACDNumFrame:SetScale(ACDScale(1.0))
			end
		end
		countdown = countdown - elapse;
	elseif (not hidden) then
		hidden = true;
		ACDNumTens:Hide();
		ACDNumOnes:Hide();
		ACDNumOne:Hide();
		-- FIX PERF: Stop OnUpdate — no reason to keep running
		ACDFrame:Hide();
	end

end)

-- FIX PERF: Helper to set countdown AND activate OnUpdate
local function StartCountdown(seconds)
	countdown = seconds;
	hidden = false;
	ACDFrame:Show(); -- activates OnUpdate
end

function ACDFrame:CHAT_MSG_BG_SYSTEM_NEUTRAL(arg1)
	if not C.ArenaCountDown then return; end
	-- FIX: Removed redundant "if (event == ...)" check — the OnEvent router
	-- already dispatches by event name. The global "event" variable doesn't
	-- exist in this scope on some servers, which caused the ENTIRE handler to fail.

	-- English patterns
	if (string.find(arg1, "One minute until the Arena battle begins")) then
		StartCountdown(61);
		return;
	end
	if (string.find(arg1, "Thirty seconds until the Arena battle begins")) then
		StartCountdown(31);
		return;
	end
	if (string.find(arg1, "Fifteen seconds until the Arena battle begins")) then
		StartCountdown(16);
		return;
	end

	-- FIX: Numeric patterns (some servers use "60 seconds", "30 seconds", etc.)
	if (string.find(arg1, "60 secon")) or (string.find(arg1, "60 seg")) then
		StartCountdown(61);
		return;
	end
	if (string.find(arg1, "30 secon")) or (string.find(arg1, "30 seg")) then
		StartCountdown(31);
		return;
	end
	if (string.find(arg1, "15 secon")) or (string.find(arg1, "15 seg")) then
		StartCountdown(16);
		return;
	end

	-- FIX: Spanish patterns
	if (string.find(arg1, "Un minuto")) or (string.find(arg1, "un minuto")) then
		StartCountdown(61);
		return;
	end
	if (string.find(arg1, "Treinta segundos")) or (string.find(arg1, "treinta segundos")) then
		StartCountdown(31);
		return;
	end
	if (string.find(arg1, "Quince segundos")) or (string.find(arg1, "quince segundos")) then
		StartCountdown(16);
		return;
	end
end

-- =========================================================
-- OJO (Shadow Sight): cuenta hasta que aparece el ojo en la arena.
--
-- Icono del hechizo + numero, con checkbox propio (C.ShadowSightTimer,
-- Arena > Options). No depende de la cuenta regresiva de las puertas.
--
-- Arranca con el mensaje de inicio de la arena. En 3.3.5 ese mensaje llega
-- por CHAT_MSG_BG_SYSTEM_NEUTRAL (el mismo canal que la cuenta de las
-- puertas); antes solo se escuchaba RAID_BOSS_EMOTE y por eso el ojo podia
-- no aparecer nunca. Se escuchan los dos, y si ninguno se reconoce, la
-- cuenta de las puertas la arranca al llegar a 0.
--
-- Se corta al salir de la arena o cuando la arena termina.
--
-- Se ve en minutos y segundos ("1:20") y se mueve como los otros timers de
-- arena: Alt + arrastrar, /nuftimers para verlo fuera de una arena, y
-- tambien desde "Mover todo".
--
-- Probar sin esperar una arena:  /script K_TestShadowSight()
-- =========================================================
local EYE_SPELL_ID = 34709;   -- Shadow Sight
local EYE_TIME     = 90;      -- segundos desde que abren las puertas
local EYE_ICON_FALLBACK = "Interface\\Icons\\Spell_Shadow_EvilEye";
local _, _, eyeIconTex = GetSpellInfo(EYE_SPELL_ID);

local timer = 0
local total = 0
local eyeTest = false   -- prueba manual: no se corta al cambiar de zona

local frame = CreateFrame("Frame", "NUF_ShadowSightTimer", UIParent)
-- Escala con Ctrl + rueda en "Mover todo" (registro central en ScaleAPI),
-- igual que los otros timers de arena.
if K.RegisterScalable then K.RegisterScalable("ShadowSightTimer", frame, 1.0); end
frame:SetHeight(32)
frame:SetWidth(92)
frame:Hide()

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetWidth(30)
frame.icon:SetHeight(30)
frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
frame.icon:SetTexture(eyeIconTex or EYE_ICON_FALLBACK)
frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

frame.text = frame:CreateFontString(nil, "OVERLAY", "PVPInfoTextFont")
frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 6, 0)
frame.text:SetJustifyH("LEFT")

-- MINUTOS Y SEGUNDOS: "1:20", no "80". El ojo sale al minuto y medio y
-- asi se lee de un vistazo cuanto falta.
local function FormatEye(sec)
	sec = math.max(0, math.floor(sec or 0))
	return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end
-- Texto de entrada: es lo que se ve al acomodarlo en "Mover todo".
frame.text:SetText(FormatEye(EYE_TIME))

-- ---------------------------------------------------------
-- MOVIBLE
--
-- Antes estaba clavado arriba al centro (TOP 0,-30) y no habia forma de
-- correrlo. Ahora es igual que los otros timers de arena: Alt + arrastrar,
-- y la posicion se guarda con la de ellos (timerPos), asi el Reset de
-- "Mover todo" la limpia igual.
-- ---------------------------------------------------------
local EYE_KEY = "ShadowSight"

local function SaveEyePosition()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
	if not NidhausUnitFramesDB.timerPos then NidhausUnitFramesDB.timerPos = {} end
	local point, _, relativePoint, x, y = frame:GetPoint()
	-- Sin punto no se guarda nada (una tabla vacia haria reventar SetPoint
	-- despues: ver el mismo caso en ArenaEndTimer).
	if not point then
		NidhausUnitFramesDB.timerPos[EYE_KEY] = nil
		return
	end
	NidhausUnitFramesDB.timerPos[EYE_KEY] = {
		point = point, relativePoint = relativePoint, x = x, y = y,
	}
end

local function RestoreEyePosition()
	local pos = NidhausUnitFramesDB and NidhausUnitFramesDB.timerPos
		and NidhausUnitFramesDB.timerPos[EYE_KEY]
	frame:ClearAllPoints()
	if pos and pos.point then
		frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
	else
		frame:SetPoint("TOP", UIParent, "TOP", 0, -30)   -- donde estaba siempre
	end
end

frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
	if IsAltKeyDown() then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	SaveEyePosition()
end)
RestoreEyePosition()

local function EyeEnabled()
	return C.ShadowSightTimer ~= false;
end

local function InArena()
	local _, instanceType = IsInInstance();
	return instanceType == "arena";
end

local function StopEye()
	frame:SetScript("OnUpdate", nil)
	frame:Hide()
	eyeTest = false
end

local function OnUpdate(self, elapsed)
	total = total + elapsed
	if total >= 1.0 then
		total = total - 1
		timer = timer - 1
		frame.text:SetText(FormatEye(timer))
		if timer <= 0 then
			StopEye()
		end
	end
end

local function StartEye(seconds)
	timer = seconds
	total = 0
	frame.text:SetText(FormatEye(timer))
	-- La posicion guardada se lee aca (al cargar el archivo la config
	-- todavia no esta).
	RestoreEyePosition()
	frame:Show()
	frame:SetScript("OnUpdate", OnUpdate)
end

-- Respaldo: la cuenta de las puertas llego a 0. Si el mensaje ya la
-- arranco, no se toca (el mensaje es el momento exacto).
EyeFromCountdown = function()
	if not EyeEnabled() or not InArena() then return; end
	if frame:IsShown() and not eyeTest then return; end
	eyeTest = false
	StartEye(EYE_TIME)
end

local function EventHandler(self, event, msg)
	if event == "PLAYER_ENTERING_WORLD" then
		StopEye()
		return
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		if not eyeTest and not InArena() then StopEye() end
		return
	elseif event == "UPDATE_BATTLEFIELD_STATUS" then
		-- La arena termino antes de que apareciera el ojo.
		if frame:IsShown() and not eyeTest and GetBattlefieldWinner and GetBattlefieldWinner() then
			StopEye()
		end
		return
	end

	-- CHAT_MSG_BG_SYSTEM_NEUTRAL / CHAT_MSG_RAID_BOSS_EMOTE
	if not EyeEnabled() or type(msg) ~= "string" or not InArena() then return; end
	if string.find(msg, "has begun") or string.find(msg, "ha comenzado") then
		eyeTest = false
		StartEye(EYE_TIME)
	end
end

frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
frame:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:SetScript("OnEvent", EventHandler)

-- Lo llama el checkbox del panel: si se apaga con la cuenta en marcha,
-- se corta en el momento.
function K.ApplyShadowSightSetting()
	if not EyeEnabled() then StopEye(); end
end

-- Prueba rapida: muestra el ojo 30 s para ver donde queda.
function K_TestShadowSight()
	StartEye(30)
	eyeTest = true
end

-- /nuftimers: lo muestra (o lo saca) junto con los otros timers de arena,
-- con la cuenta entera, para acomodarlo con Alt + arrastrar.
K.ArenaTimerTests = K.ArenaTimerTests or {}
K.ArenaTimerTests[EYE_KEY] = function()
	if frame:IsShown() then
		StopEye()
	else
		StartEye(EYE_TIME)
		eyeTest = true
	end
end
