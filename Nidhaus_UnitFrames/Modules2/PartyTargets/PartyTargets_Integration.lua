local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- PartyTargets_Integration.lua
-- Integra el addon PartyTargets con el sistema de config de Nidhaus UnitFrames.
-- Permite habilitar/deshabilitar PartyTargets desde la pestaña Frames del panel.
--
-- El problema: PartyTargets registra UnitWatch + 15 eventos por frame en su OnLoad (XML).
-- Un simple Hide() no basta porque UnitWatch y PLAYER_ENTERING_WORLD vuelven a mostrarlos.
-- Solución: desregistrar TODO (UnitWatch + eventos) cuando está desactivado.

-- Lista de eventos que PartyTargets registra en su OnLoad
local PT_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"PARTY_MEMBERS_CHANGED",
	"PARTY_MEMBER_ENABLE",
	"PARTY_MEMBER_DISABLE",
	"PARTY_LOOT_METHOD_CHANGED",
	"VARIABLES_LOADED",
	"UNIT_FACTION",
	"UNIT_TARGET",
	"UNIT_PVP_UPDATE",
	"UNIT_HEALTH",
	"UNIT_MAXHEALTH",
	"UNIT_MANA",
	"UNIT_ENERGY",
	"UNIT_FOCUS",
	"UNIT_RAGE",
	"UNIT_RUNIC_POWER",
};

-- Desactivar completamente un PartyTargetFrame
local function DisableTargetFrame(frame)
	if not frame then return; end
	-- Desregistrar UnitWatch (secure state driver que auto-muestra el frame)
	UnregisterUnitWatch(frame);
	-- Desregistrar todos los eventos para que no se re-actualice
	for _, evt in ipairs(PT_EVENTS) do
		frame:UnregisterEvent(evt);
	end
	-- Ocultar y desactivar OnUpdate
	frame:Hide();
	frame:SetScript("OnUpdate", nil);
end

-- Reactivar un PartyTargetFrame (restaurar estado original)
local function EnableTargetFrame(frame)
	if not frame then return; end
	-- Re-registrar UnitWatch
	RegisterUnitWatch(frame);
	-- Re-registrar eventos
	for _, evt in ipairs(PT_EVENTS) do
		frame:RegisterEvent(evt);
	end
	-- Restaurar OnUpdate (usa la función del addon original)
	local PT = LibStub and LibStub("PartyTargets-3.3", true);
	if PT and PT.OnUpdate then
		frame:SetScript("OnUpdate", function(self, elapsed)
			PT.OnUpdate(self, elapsed);
		end);
	end
end

-- API pública para el panel de opciones
function K.ApplyPartyTargetsState(enabled)
	for i = 1, MAX_PARTY_MEMBERS do
		local frame = _G["PartyTargetFrame"..i];
		if frame then
			if enabled then
				EnableTargetFrame(frame);
			else
				DisableTargetFrame(frame);
			end
		end
	end
end

-- Inicialización: aplicar estado al cargar config
K.RegisterConfigEvent("CONFIG_LOADED", function()
	-- Esperar un frame para que PartyTargets haya inicializado sus frames via XML OnLoad
	local delayFrame = CreateFrame("Frame");
	delayFrame:SetScript("OnUpdate", function(self)
		self:SetScript("OnUpdate", nil);
		if C.PartyTargetsEnabled == false then
			K.ApplyPartyTargetsState(false);
		end
	end);
end);

-- Seguro adicional: PLAYER_ENTERING_WORLD puede dispararse DESPUÉS del CONFIG_LOADED.
-- Re-aplicar el estado desactivado si corresponde.
-- FIX: Reuse a single delay frame instead of creating a new one per zone change
local pewGuard = CreateFrame("Frame");
local pewDelay = CreateFrame("Frame");
pewDelay:Hide();
pewDelay:SetScript("OnUpdate", function(s)
	s:SetScript("OnUpdate", nil);
	s:Hide();
	if C.PartyTargetsEnabled == false then
		K.ApplyPartyTargetsState(false);
	end
end);

pewGuard:RegisterEvent("PLAYER_ENTERING_WORLD");
pewGuard:SetScript("OnEvent", function(self, event)
	if C.PartyTargetsEnabled == false then
		-- Delay one frame to execute AFTER PartyTargets' own handler
		pewDelay:Show();
		pewDelay:SetScript("OnUpdate", function(s)
			s:SetScript("OnUpdate", nil);
			s:Hide();
			if C.PartyTargetsEnabled == false then
				K.ApplyPartyTargetsState(false);
			end
		end);
	end
end);