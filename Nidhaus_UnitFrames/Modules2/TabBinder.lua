local AddOnName, ns = ...;
local K, C, L = unpack(ns);































local binder = CreateFrame("Frame");
local pendiente = false;

local function EnZonaPvP()
	local _, tipoInstancia = IsInInstance();
	local tipoZona = GetZonePVPInfo();
	return tipoInstancia == "arena" or tipoInstancia == "pvp"
		or tipoZona == "combat";
end




local function TeclaDe(accionNormal, accionJugador, porDefecto)
	return GetBindingKey(accionJugador) or GetBindingKey(accionNormal) or porDefecto;
end

local function Aplicar(forzarPvP)
	if InCombatLockdown() then
		pendiente = true;
		return;
	end

	local set = GetCurrentBindingSet();
	local teclaSig = TeclaDe("TARGETNEARESTENEMY", "TARGETNEARESTENEMYPLAYER", "TAB");
	local teclaAnt = TeclaDe("TARGETPREVIOUSENEMY", "TARGETPREVIOUSENEMYPLAYER", "SHIFT-TAB");

	local quiero = (forzarPvP or EnZonaPvP()) and "TARGETNEARESTENEMYPLAYER"
		or "TARGETNEARESTENEMY";
	local quieroAnt = (forzarPvP or EnZonaPvP()) and "TARGETPREVIOUSENEMYPLAYER"
		or "TARGETPREVIOUSENEMY";



	if teclaSig and GetBindingAction(teclaSig) == quiero then
		pendiente = false;
		return;
	end

	local ok = true;
	if teclaSig then ok = SetBinding(teclaSig, quiero); end
	if teclaAnt then SetBinding(teclaAnt, quieroAnt); end

	if ok then
		SaveBindings(set);
		pendiente = false;
	else
		pendiente = true;
	end
end

binder:SetScript("OnEvent", function(self, event, ...)
	if not C.TabBinderEnabled then return; end

	if event == "CHAT_MSG_SYSTEM" then


		local msg = ...;
		if msg == ERR_DUEL_REQUESTED then Aplicar(true); end
		return;
	end

	if event == "DUEL_REQUESTED" then
		Aplicar(true);
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pendiente then Aplicar(); end
	else
		Aplicar();
	end
end);




local EVENTOS = {
	"ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
	"PLAYER_REGEN_ENABLED", "DUEL_REQUESTED", "DUEL_FINISHED",
	"CHAT_MSG_SYSTEM",
};

function K.ApplyTabBinder()
	if C.TabBinderEnabled then
		for _, e in ipairs(EVENTOS) do binder:RegisterEvent(e); end
		Aplicar();
	else
		binder:UnregisterAllEvents();


		if not InCombatLockdown() then
			local set = GetCurrentBindingSet();
			local teclaSig = GetBindingKey("TARGETNEARESTENEMYPLAYER");
			local teclaAnt = GetBindingKey("TARGETPREVIOUSENEMYPLAYER");
			local cambio = false;
			if teclaSig then SetBinding(teclaSig, "TARGETNEARESTENEMY"); cambio = true; end
			if teclaAnt then SetBinding(teclaAnt, "TARGETPREVIOUSENEMY"); cambio = true; end
			if cambio then SaveBindings(set); end
		end
	end
end

K.RegisterConfigEvent("CONFIG_LOADED", function() K.ApplyTabBinder(); end);
