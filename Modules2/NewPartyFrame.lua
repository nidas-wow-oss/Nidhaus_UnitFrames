-- NewPartyFrame — Módulo integrado en Nidhaus_UnitFrames
-- Reemplaza las texturas del PartyMemberFrame con un estilo custom
-- Texturas: Media/Light/UI-PartyFrame2.blp, UI-PartyFrame2-Flash.blp, UI-Vehicles-PartyFrame2.blp
--           Media/Dark/UI-PartyFrame2.blp, UI-PartyFrame2-Flash.blp, UI-Vehicles-PartyFrame2.blp

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local _G = _G;
local hooksecurefunc = hooksecurefunc;

local isEnabled = false;
local hooksRegistered = false;
local timerFrame;
local pollRemaining = 0;
local elapsed = 0;

-- Estado original de cada frame (capturado UNA vez antes de modificar)
local originals = {};

-- Font original (se captura UNA vez)
local origFont, origFontSize, origFontFlags;

local function CaptureOriginalFont(nameStr)
	if origFont then return; end
	local f, s, fl = nameStr:GetFont();
	if f and s then
		origFont, origFontSize, origFontFlags = f, s, fl;
	end
end

-- Helpers para capturar puntos y tamaño
local function SavePoints(element)
	if not element then return nil; end
	local pts = {};
	for p = 1, element:GetNumPoints() do
		pts[p] = {element:GetPoint(p)};
	end
	return pts;
end

local function RestorePoints(element, pts)
	if not element or not pts then return; end
	element:ClearAllPoints();
	for _, pt in ipairs(pts) do
		element:SetPoint(unpack(pt));
	end
end

------------------------------------------------------------------------
-- Capturar estado original de un PartyMemberFrame (una sola vez)
------------------------------------------------------------------------
local function CaptureOriginals(id)
	if originals[id] then return; end

	local fn = "PartyMemberFrame"..id;
	local frame = _G[fn];
	if not frame then return; end

	local o = {};

	local texture = _G[fn.."Texture"];
	if texture then
		o.texPath = texture:GetTexture();
		o.texPoints = SavePoints(texture);
		o.texW, o.texH = texture:GetWidth(), texture:GetHeight();
		o.texLayer = texture:GetDrawLayer();
	end

	local flash = _G[fn.."Flash"];
	if flash then
		o.flashPath = flash:GetTexture();
		o.flashPoints = SavePoints(flash);
		o.flashW, o.flashH = flash:GetWidth(), flash:GetHeight();
	end

	local portrait = _G[fn.."Portrait"];
	if portrait then
		o.portPoints = SavePoints(portrait);
		o.portW, o.portH = portrait:GetWidth(), portrait:GetHeight();
	end

	local name = _G[fn.."Name"];
	if name then
		o.namePoints = SavePoints(name);
		local f, s, fl = name:GetFont();
		o.nameFont = {f, s, fl};
	end

	local health = _G[fn.."HealthBar"];
	if health then
		o.hbPoints = SavePoints(health);
		o.hbW, o.hbH = health:GetWidth(), health:GetHeight();
		if health.GetStatusBarTexture then
			local sbTex = health:GetStatusBarTexture();
			if sbTex then o.hbStatusBar = sbTex:GetTexture(); end
		end
	end

	local healthText = _G[fn.."HealthBarText"];
	if healthText then
		o.hbTextPoints = SavePoints(healthText);
		o.hbTextLayer = healthText:GetDrawLayer();
	end

	local mana = _G[fn.."ManaBar"];
	if mana then
		o.mbPoints = SavePoints(mana);
		o.mbW, o.mbH = mana:GetWidth(), mana:GetHeight();
		if mana.GetStatusBarTexture then
			local sbTex = mana:GetStatusBarTexture();
			if sbTex then o.mbStatusBar = sbTex:GetTexture(); end
		end
	end

	local manaText = _G[fn.."ManaBarText"];
	if manaText then
		o.mbTextAlpha = manaText:GetAlpha();
		o.mbTextPoints = SavePoints(manaText);
		o.mbTextLayer = manaText:GetDrawLayer();
	end

	local bg = _G[fn.."Background"];
	if bg then
		o.bgPoints = SavePoints(bg);
		o.bgW, o.bgH = bg:GetWidth(), bg:GetHeight();
	end

	-- FIX VEHICLE: Capturar VehicleTexture (Blizzard la MUESTRA en vez de Texture al entrar a vehículo)
	local vehTex = _G[fn.."VehicleTexture"];
	if vehTex then
		o.vehTexPath = vehTex:GetTexture();
		o.vehTexPoints = SavePoints(vehTex);
		o.vehTexW, o.vehTexH = vehTex:GetWidth(), vehTex:GetHeight();
	end

	local pet = _G[fn.."PetFrame"];
	if pet then
		o.petPoints = SavePoints(pet);
	end

	o.debuffPoints = {};
	for j = 1, 4 do
		local debuff = _G[fn.."Debuff"..j];
		if debuff then
			o.debuffPoints[j] = SavePoints(debuff);
		end
	end

	originals[id] = o;
end

------------------------------------------------------------------------
-- Restaurar un PartyMemberFrame a su estado original
------------------------------------------------------------------------
local function RestorePartyMemberFrame(id)
	local o = originals[id];
	if not o then return; end

	local fn = "PartyMemberFrame"..id;

	local texture = _G[fn.."Texture"];
	if texture and o.texPath then
		texture:SetTexture(o.texPath);
		RestorePoints(texture, o.texPoints);
		texture:SetSize(o.texW, o.texH);
		if o.texLayer then texture:SetDrawLayer(o.texLayer); end
	end

	local flash = _G[fn.."Flash"];
	if flash and o.flashPath then
		flash:SetTexture(o.flashPath);
		RestorePoints(flash, o.flashPoints);
		flash:SetSize(o.flashW, o.flashH);
	end

	local portrait = _G[fn.."Portrait"];
	if portrait and o.portPoints then
		RestorePoints(portrait, o.portPoints);
		portrait:SetSize(o.portW, o.portH);
	end

	local name = _G[fn.."Name"];
	if name and o.namePoints then
		RestorePoints(name, o.namePoints);
		if o.nameFont and o.nameFont[1] then
			name:SetFont(unpack(o.nameFont));
		end
	end

	local health = _G[fn.."HealthBar"];
	if health and o.hbPoints then
		RestorePoints(health, o.hbPoints);
		health:SetSize(o.hbW, o.hbH);
		if o.hbStatusBar then health:SetStatusBarTexture(o.hbStatusBar); end
	end

	local healthText = _G[fn.."HealthBarText"];
	if healthText and o.hbTextPoints then
		RestorePoints(healthText, o.hbTextPoints);
		if o.hbTextLayer then healthText:SetDrawLayer(o.hbTextLayer); end
	end

	local mana = _G[fn.."ManaBar"];
	if mana and o.mbPoints then
		RestorePoints(mana, o.mbPoints);
		mana:SetSize(o.mbW, o.mbH);
		if o.mbStatusBar then mana:SetStatusBarTexture(o.mbStatusBar); end
	end

	local manaText = _G[fn.."ManaBarText"];
	if manaText then
		if o.mbTextPoints then
			RestorePoints(manaText, o.mbTextPoints);
		end
		if o.mbTextAlpha then
			manaText:SetAlpha(o.mbTextAlpha);
		end
		if o.mbTextLayer then manaText:SetDrawLayer(o.mbTextLayer); end
	end

	local bg = _G[fn.."Background"];
	if bg and o.bgPoints then
		RestorePoints(bg, o.bgPoints);
		bg:SetSize(o.bgW, o.bgH);
	end

	-- FIX VEHICLE: Restaurar VehicleTexture a estado original
	local vehTex = _G[fn.."VehicleTexture"];
	if vehTex and o.vehTexPath then
		vehTex:SetTexture(o.vehTexPath);
		RestorePoints(vehTex, o.vehTexPoints);
		vehTex:SetSize(o.vehTexW, o.vehTexH);
	end

	local pet = _G[fn.."PetFrame"];
	if pet and o.petPoints then
		RestorePoints(pet, o.petPoints);
	end

	for j = 1, 4 do
		local debuff = _G[fn.."Debuff"..j];
		if debuff and o.debuffPoints[j] then
			RestorePoints(debuff, o.debuffPoints[j]);
		end
	end
end

local function RestoreAllFrames()
	for i = 1, 4 do
		RestorePartyMemberFrame(i);
	end
end

-- Obtener path de texturas según tema (Dark / Light)
local function GetTexturePath()
	if C.darkFrames then
		return "Interface\\Addons\\"..AddOnName.."\\Media\\Dark\\";
	else
		return "Interface\\Addons\\"..AddOnName.."\\Media\\Light\\";
	end
end

------------------------------------------------------------------------
-- Estilo completo — detecta vehiculo y ajusta layout
------------------------------------------------------------------------
local function StylePartyMemberFrame(id)
	if not isEnabled then return; end

	local fn = "PartyMemberFrame"..id;
	local frame = _G[fn];
	if not frame then return; end
	if not frame:IsShown() then return; end

	-- Capturar estado original ANTES de modificar (una sola vez)
	CaptureOriginals(id);

	local name       = _G[fn.."Name"];
	local health     = _G[fn.."HealthBar"];
	local mana       = _G[fn.."ManaBar"];
	local portrait   = _G[fn.."Portrait"];
	local texture    = _G[fn.."Texture"];
	local flash      = _G[fn.."Flash"];
	local bg         = _G[fn.."Background"];
	local healthText = _G[fn.."HealthBarText"];
	local manaText   = _G[fn.."ManaBarText"];

	-- Detectar si está en vehiculo/torreta (múltiples checks para robustez en WotLK)
	local unit = "party"..id;
	local inVehicle = false;
	if UnitHasVehicleUI and UnitHasVehicleUI(unit) then
		inVehicle = true;
	elseif UnitInVehicle and UnitInVehicle(unit) then
		inVehicle = true;
	elseif UnitUsingVehicle and UnitUsingVehicle(unit) then
		inVehicle = true;
	end
	-- FIX: Fallback — si Blizzard ya cambió la textura a vehicle art, asumir vehículo
	if not inVehicle and frame.state and frame.state == "vehicle" then
		inVehicle = true;
	end
	if not inVehicle and texture then
		local curTex = texture:GetTexture() or "";
		if type(curTex) == "string" and curTex:lower():find("vehicle") then
			inVehicle = true;
		end
	end

	local Path = GetTexturePath();

	-- FIX VEHICLE BUG: Blizzard usa DOS texturas diferentes:
	--   PartyMemberFrame{i}Texture       → modo normal (player art)
	--   PartyMemberFrame{i}VehicleTexture → modo vehículo (vehicle art)
	-- Cuando entra en vehículo, Blizzard ESCONDE Texture y MUESTRA VehicleTexture.
	-- Si solo estilizamos Texture (que está oculta), el frame se ve roto.
	-- Solución (patrón KPack): estilizar AMBAS texturas según el modo.
	local vehTex = _G[fn.."VehicleTexture"];

	-- TEXTURA BASE (122 x 61)
	if texture then
		if inVehicle then
			-- En vehículo: Blizzard oculta esta textura, pero la seteamos por si acaso
			texture:SetTexture(Path.."UI-Vehicles-PartyFrame2");
		else
			texture:SetTexture(Path.."UI-PartyFrame2");
		end
		texture:ClearAllPoints();
		texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 10);
		texture:SetSize(122, 61);
		texture:SetDrawLayer("BORDER");
	end

	-- FIX VEHICLE: Estilizar VehicleTexture (la que Blizzard realmente MUESTRA en vehículo)
	if vehTex then
		if inVehicle then
			vehTex:SetTexture(Path.."UI-Vehicles-PartyFrame2");
			vehTex:ClearAllPoints();
			vehTex:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 10);
			vehTex:SetSize(122, 61);
		end
		-- Cuando no está en vehículo, Blizzard ya la oculta → no tocar
	end

	-- FLASH
	if flash then
		flash:SetTexture(Path.."UI-PartyFrame2-Flash");
		flash:ClearAllPoints();
		flash:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 10);
		flash:SetSize(122, 61);
	end

	-- RETRATO — la textura de vehiculo tiene un circulo mas grande
	if portrait then
		portrait:ClearAllPoints();
		if inVehicle then
			portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, 4);
			portrait:SetWidth(45);
			portrait:SetHeight(45);
		else
			portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, 0);
			portrait:SetWidth(37);
			portrait:SetHeight(37);
		end
	end

	-- Offset de barras según modo normal/vehiculo
	local barLeft = inVehicle and 48 or 44;
	local barWidth = inVehicle and 63 or 67;

	-- NOMBRE
	if name then
		CaptureOriginalFont(name);
		if origFont then
			name:ClearAllPoints();
			name:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", barLeft + 2, -14);
			name:SetFont(origFont, origFontSize - 1, origFontFlags);
		end
	end

	-- VIDA (67 x 22)
	if health then
		health:ClearAllPoints();
		health:SetPoint("TOPLEFT", frame, "TOPLEFT", barLeft, -4);
		health:SetWidth(barWidth);
		health:SetHeight(22);
	end

	-- Texto de vida centrado en la barra — forzar OVERLAY para que quede encima de la textura
	if healthText then
		healthText:ClearAllPoints();
		healthText:SetPoint("CENTER", health, "CENTER", 0, -6);
		healthText:SetDrawLayer("OVERLAY");
	end

	-- MANA (67 x 9) — anclada al bottom de health
	if mana then
		mana:ClearAllPoints();
		mana:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1);
		mana:SetWidth(barWidth);
		mana:SetHeight(9);
	end

	-- Texto de mana centrado — visible y encima de la textura
	if manaText then
		manaText:SetAlpha(1);
		manaText:ClearAllPoints();
		manaText:SetPoint("CENTER", mana, "CENTER", 0, 0);
		manaText:SetDrawLayer("OVERLAY");
	end

	-- STATUSBAR TEXTURE (usar la misma del player/target si está configurada)
	if C.statusbarOn and C.statusbarTexture then
		if health then health:SetStatusBarTexture(C.statusbarTexture); end
		if mana then mana:SetStatusBarTexture(C.statusbarTexture); end
	end

	-- BG BARRAS
	if bg then
		bg:ClearAllPoints();
		bg:SetPoint("TOPLEFT", frame, "TOPLEFT", barLeft - 1, -3);
		bg:SetSize(barWidth + 2, 34);
	end

	-- PET FRAME — Solo mover si PartyBuffs está activo (necesita más espacio)
	-- Si PartyBuffs está OFF, restaurar posición original (controla espaciado entre frames)
	local pet = _G[fn.."PetFrame"];
	if pet then
		if K.IsPartyBuffsActive and K.IsPartyBuffsActive() then
			pet:ClearAllPoints();
			pet:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 23, 5);
		else
			-- Restaurar posición original si fue movido
			local o = originals[id];
			if o and o.petPoints then
				RestorePoints(pet, o.petPoints);
			end
		end
	end

	-- DEBUFFS por defecto (solo si PartyBuffs NO controla la posición)
	if not K.IsPartyBuffsActive or not K.IsPartyBuffsActive() then
		if mana then
			for j = 1, 4 do
				local debuff = _G[fn.."Debuff"..j];
				if debuff then
					debuff:ClearAllPoints();
					if j == 1 then
						debuff:SetPoint("TOPLEFT", mana, "BOTTOMLEFT", 0, -1);
					else
						local prev = _G[fn.."Debuff"..(j - 1)];
						if prev then
							debuff:SetPoint("LEFT", prev, "RIGHT", 2, 0);
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Actualizar todos
------------------------------------------------------------------------
local function UpdateAllFrames()
	if not isEnabled then return; end
	for i = 1, 4 do
		StylePartyMemberFrame(i);
	end
end

-- Exportar funciones para uso externo (PartyBuffs las necesita)
K.StyleNewPartyFrame = StylePartyMemberFrame;
K.UpdateNewPartyFrames = UpdateAllFrames;

------------------------------------------------------------------------
-- Polling con OnUpdate (WotLK no tiene C_Timer)
------------------------------------------------------------------------
local function StartPolling(duration)
	if not timerFrame then
		timerFrame = CreateFrame("Frame");
		timerFrame:SetScript("OnUpdate", function(self, dt)
			elapsed = elapsed + dt;
			if elapsed >= 0.25 then
				elapsed = 0;
				pollRemaining = pollRemaining - 0.25;
				UpdateAllFrames();
				if pollRemaining <= 0 then
					self:Hide();
				end
			end
		end);
	end
	pollRemaining = duration or 3;
	elapsed = 0;
	timerFrame:Show();
end

------------------------------------------------------------------------
-- Hooks en funciones de Blizzard (una sola vez)
------------------------------------------------------------------------
local function RegisterHooks()
	if hooksRegistered then return; end

	if PartyMemberFrame_UpdateArt then
		hooksecurefunc("PartyMemberFrame_UpdateArt", function()
			if isEnabled then UpdateAllFrames(); end
		end);
	end

	if PartyMemberFrame_UpdateMember then
		hooksecurefunc("PartyMemberFrame_UpdateMember", function()
			if isEnabled then UpdateAllFrames(); end
		end);
	end

	if PartyMemberFrame_UpdateLeader then
		hooksecurefunc("PartyMemberFrame_UpdateLeader", function()
			if isEnabled then UpdateAllFrames(); end
		end);
	end

	-- Hooks de vehículo — Blizzard llama estas funciones para cambiar arte
	-- Hookear DESPUÉS para sobreescribir con nuestro estilo
	if PartyMemberFrame_ToVehicleArt then
		hooksecurefunc("PartyMemberFrame_ToVehicleArt", function(self)
			if not isEnabled or not self then return; end
			local n = self.GetName and self:GetName();
			if n then
				local id = tonumber(n:match("PartyMemberFrame(%d+)$"));
				if id then
					StylePartyMemberFrame(id);
					-- Polling corto: Blizzard a veces re-aplica después
					StartPolling(1);
				end
			end
		end);
	end

	if PartyMemberFrame_ToPlayerArt then
		hooksecurefunc("PartyMemberFrame_ToPlayerArt", function(self)
			if not isEnabled or not self then return; end
			local n = self.GetName and self:GetName();
			if n then
				local id = tonumber(n:match("PartyMemberFrame(%d+)$"));
				if id then
					StylePartyMemberFrame(id);
					StartPolling(1);
				end
			end
		end);
	end

	if UnitFramePortrait_Update then
		hooksecurefunc("UnitFramePortrait_Update", function(self)
			if not self or not isEnabled then return; end
			local n = self.GetName and self:GetName();
			if n and n:find("^PartyMemberFrame%d+$") then
				local id = tonumber(n:match("(%d+)$"));
				if id then StylePartyMemberFrame(id); end
			end
		end);
	end

	-- Hook UnitFrameHealthBar_Update: Blizzard llama esto al actualizar
	-- la barra de vida (incluyendo vehículos) y resetea la statusbar texture
	if UnitFrameHealthBar_Update then
		hooksecurefunc("UnitFrameHealthBar_Update", function(self)
			if not isEnabled or not self then return; end
			local parent = self:GetParent();
			if not parent then return; end
			local n = parent.GetName and parent:GetName();
			if n and n:find("^PartyMemberFrame%d+$") then
				if C.statusbarOn and C.statusbarTexture then
					self:SetStatusBarTexture(C.statusbarTexture);
				end
			end
		end);
	end

	-- Hook UnitFrameManaBar_Update: lo mismo para la barra de mana
	if UnitFrameManaBar_Update then
		hooksecurefunc("UnitFrameManaBar_Update", function(self)
			if not isEnabled or not self then return; end
			local parent = self:GetParent();
			if not parent then return; end
			local n = parent.GetName and parent:GetName();
			if n and n:find("^PartyMemberFrame%d+$") then
				if C.statusbarOn and C.statusbarTexture then
					self:SetStatusBarTexture(C.statusbarTexture);
				end
			end
		end);
	end

	for i = 1, 4 do
		local frame = _G["PartyMemberFrame"..i];
		if frame then
			frame:HookScript("OnShow", function()
				if isEnabled then StylePartyMemberFrame(i); end
			end);
		end
	end

	hooksRegistered = true;
end

------------------------------------------------------------------------
-- Público: consultar si NewPartyFrame está activo
------------------------------------------------------------------------
function K.IsNewPartyFrameActive()
	return isEnabled;
end

------------------------------------------------------------------------
-- Enable / Disable
------------------------------------------------------------------------
local eventFrame;

local function NPF_Enable()
	if isEnabled then return; end
	isEnabled = true;

	RegisterHooks();

	if not eventFrame then
		eventFrame = CreateFrame("Frame");
		eventFrame:SetScript("OnEvent", function(self, event, ...)
			if not isEnabled then return; end
			if event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
				local unit = ...;
				for i = 1, 4 do
					if unit == "party"..i then
						-- Estilizar inmediatamente
						StylePartyMemberFrame(i);
						-- Polling agresivo: Blizzard puede resetear el arte
						-- varias veces durante la transición de vehículo
						StartPolling(3);
						break;
					end
				end
			else
				UpdateAllFrames();
				StartPolling(1.5);
			end
		end);
	end

	-- FIX: Registrar eventos seguros primero. GROUP_ROSTER_UPDATE puede no existir
	-- en WotLK 3.3.0 stock y si falla, corta la ejecución de las líneas siguientes.
	eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
	eventFrame:RegisterEvent("PARTY_MEMBER_ENABLE");
	eventFrame:RegisterEvent("PARTY_MEMBER_DISABLE");
	eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE");
	eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE");
	pcall(eventFrame.RegisterEvent, eventFrame, "GROUP_ROSTER_UPDATE");
	pcall(eventFrame.RegisterEvent, eventFrame, "VEHICLE_PASSENGERS_CHANGED");

	UpdateAllFrames();
	StartPolling(3);

	-- Notificar a PartyBuffs para re-anclar debajo del nuevo frame
	if K.PartyBuffs_ReanchorAll then K.PartyBuffs_ReanchorAll(); end
end

local function NPF_Disable()
	if not isEnabled then return; end
	isEnabled = false;

	if eventFrame then
		eventFrame:UnregisterAllEvents();
	end

	if timerFrame then
		timerFrame:Hide();
	end

	-- Restaurar todos los frames a su estado original
	RestoreAllFrames();

	-- Forzar que Blizzard re-aplique su layout (vehiculo, arte, etc)
	for i = 1, 4 do
		local frame = _G["PartyMemberFrame"..i];
		if frame and frame:IsShown() then
			if PartyMemberFrame_UpdateArt then
				pcall(PartyMemberFrame_UpdateArt, frame);
			end
			if PartyMemberFrame_UpdateMember then
				pcall(PartyMemberFrame_UpdateMember, frame);
			end
		end
	end

	-- Notificar a PartyBuffs para volver a posición normal
	if K.PartyBuffs_ReanchorAll then K.PartyBuffs_ReanchorAll(); end
end

------------------------------------------------------------------------
-- Exports para el checkbox en OptionsPanel (Frames tab)
------------------------------------------------------------------------
K.EnableNewPartyFrame = NPF_Enable;
K.DisableNewPartyFrame = NPF_Disable;

-- Auto-enable al cargar config si estaba activo
K.RegisterConfigEvent("CONFIG_LOADED", function()
	if C.NewPartyFrame then
		NPF_Enable();
	end
end);