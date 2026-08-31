local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- PartyFramesImproved.lua  (integrado a NUF)
-- Fuente: PartyFramesImproved de SoupsBelly, que a su vez viene de
-- UnitFramesImproved (kiforsbe) y PartyTarget (Valconeye).
--
-- QUE HACE: reemplaza la textura de los marcos de party por una mas
-- ancha y limpia, achica y reubica los textos de nombre / vida / mana,
-- y agranda la barra de vida para que ocupe casi todo el marco.
--
-- CAMBIOS respecto del addon suelto:
--   * Escala y posicion las maneja NUF (Frames > Party). El original
--     movia PartyMemberFrame1 y pisaba lo que hiciera el modo mover.
--   * El coloreado por clase lo hace ClassColor.lua de NUF; aca solo
--     va la parte visual, si no se peleaban por SetStatusBarColor.
--   * Las texturas viven en Modules2/PartyFramesImproved/Textures.
--   * Todo se puede revertir en caliente al apagar el modulo: se
--     guardan textura, fuentes y anclas originales antes de tocarlas.
-- =========================================================

local TEX_PATH = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\PartyFramesImproved\\Textures\\";
local TEX_FRAME   = TEX_PATH .. "PartyFramesImproved-UI-PartyFrame";
local TEX_FLASH   = TEX_PATH .. "PartyFramesImproved-UI-PARTYFRAME-FLASH";
local TEX_VEHICLE = TEX_PATH .. "PartyFramesImproved-UI-VEHICLES-PARTYFRAME";

local MAX_PARTY = MAX_PARTY_MEMBERS or 4;

local enabled  = false;
local hooked   = false;
local original = {};   -- lo que habia antes, para poder volver atras

-- ---------------------------------------------------------
-- Guardar / restaurar el estado original
-- ---------------------------------------------------------
local function CaptureOriginal(i)
	if original[i] then return; end

	local name     = _G["PartyMemberFrame" .. i .. "Name"];
	local hptext   = _G["PartyMemberFrame" .. i .. "HealthBarText"];
	local manatext = _G["PartyMemberFrame" .. i .. "ManaBarText"];
	local texture  = _G["PartyMemberFrame" .. i .. "Texture"];
	local flash    = _G["PartyMemberFrame" .. i .. "Flash"];
	local hpbar    = _G["PartyMemberFrame" .. i .. "HealthBar"];
	local bg       = _G["PartyMemberFrame" .. i .. "Background"];
	if not (name and texture and hpbar) then return; end

	local o = {};

	local f, s, fl = name:GetFont();
	o.nameFont = { f, s, fl };
	o.namePoint = { name:GetPoint() };

	if hptext then
		local hf, hs, hfl = hptext:GetFont();
		o.hpFont = { hf, hs, hfl };
	end
	if manatext then
		local mf, ms, mfl = manatext:GetFont();
		o.manaFont = { mf, ms, mfl };
	end

	o.texture      = texture:GetTexture();
	o.texturePoint = { texture:GetPoint() };

	if flash then
		o.flash      = flash:GetTexture();
		o.flashPoint = { flash:GetPoint() };
	end

	o.hpPoint  = { hpbar:GetPoint() };
	o.hpHeight = hpbar:GetHeight();

	-- Textura de relleno de las barras, para poder devolverla al apagar.
	-- GetStatusBarTexture() devuelve el objeto textura, no la ruta.
	local hpTex = hpbar.GetStatusBarTexture and hpbar:GetStatusBarTexture();
	if hpTex then o.hpBarTexture = hpTex:GetTexture(); end
	local manabar0 = _G["PartyMemberFrame" .. i .. "ManaBar"];
	if manabar0 then
		local mTex = manabar0.GetStatusBarTexture and manabar0:GetStatusBarTexture();
		if mTex then o.manaBarTexture = mTex:GetTexture(); end
	end

	if bg then
		o.bgPoint  = { bg:GetPoint() };
		o.bgHeight = bg:GetHeight();
		o.bgWidth  = bg:GetWidth();
	end

	original[i] = o;
end

-- SetPoint necesita el punto completo; GetPoint devuelve 5 valores y
-- alguno puede venir nil, asi que hay que reconstruirlo con cuidado.
local function SafeSetPoint(region, stored)
	if not (region and stored and stored[1]) then return; end
	region:ClearAllPoints();
	region:SetPoint(stored[1], stored[2] or region:GetParent(),
		stored[3] or stored[1], stored[4] or 0, stored[5] or 0);
end

-- ---------------------------------------------------------
-- Aplicar el estilo
-- ---------------------------------------------------------
local function StyleFrame(i)
	local name     = _G["PartyMemberFrame" .. i .. "Name"];
	local hptext   = _G["PartyMemberFrame" .. i .. "HealthBarText"];
	local manatext = _G["PartyMemberFrame" .. i .. "ManaBarText"];
	local texture  = _G["PartyMemberFrame" .. i .. "Texture"];
	local flash    = _G["PartyMemberFrame" .. i .. "Flash"];
	local hpbar    = _G["PartyMemberFrame" .. i .. "HealthBar"];
	local bg       = _G["PartyMemberFrame" .. i .. "Background"];
	if not (name and texture and hpbar) then return; end

	CaptureOriginal(i);

	-- El contorno sale de la opcion del panel: este modulo corre DESPUES
	-- de PartyFrame.lua, asi que si fijara "OUTLINE" a mano lo pisaria.
	-- "Blizz" no es un flag de fuente sino un modo (fuente + sombra) que
	-- resuelve PartyFrame.lua; aca solo hay que no pasarlo como flag.
	local nameOutline = C.PartyFontOutline;
	if nameOutline == "" or nameOutline == "Blizz" then nameOutline = nil; end
	name:SetFont("Fonts\\FRIZQT__.TTF", 7, nameOutline);
	name:ClearAllPoints();
	name:SetPoint("TOPLEFT", 50, -4);   -- 4px mas arriba (antes -8)

	-- Vida y mana NO se tocan: van con la fuente original de Blizzard.
	-- Antes se forzaban a 7 y los numeros quedaban ilegibles en un marco
	-- que justamente es mas grande. Solo el NOMBRE queda chico y arriba.

	texture:SetTexture(TEX_FRAME);
	texture:ClearAllPoints();
	texture:SetPoint("TOPLEFT", 0, 6);

	if flash then
		flash:SetTexture(TEX_FLASH);
		flash:ClearAllPoints();
		flash:SetPoint("TOPLEFT", 0, 6);
	end

	hpbar:ClearAllPoints();
	hpbar:SetPoint("TOPLEFT", 47, -3);
	hpbar:SetHeight(17);

	if bg then
		bg:ClearAllPoints();
		bg:SetPoint("TOPLEFT", 46, -3);
		bg:SetHeight(24);
		bg:SetWidth(70);
	end

	-- TEXTURA DE LAS BARRAS: la misma que usan player/target y el modo
	-- NewPartyFrame. Antes este modulo no la aplicaba, asi que en Improved
	-- las barras quedaban con el relleno por defecto de Blizzard mientras
	-- que en el otro estilo salian con la textura configurada.
	if C.statusbarOn and C.statusbarTexture then
		hpbar:SetStatusBarTexture(C.statusbarTexture);
		local manabar = _G["PartyMemberFrame" .. i .. "ManaBar"];
		if manabar then manabar:SetStatusBarTexture(C.statusbarTexture); end
	end
end

local function RestoreFrame(i)
	local o = original[i];
	if not o then return; end

	local name     = _G["PartyMemberFrame" .. i .. "Name"];
	local hptext   = _G["PartyMemberFrame" .. i .. "HealthBarText"];
	local manatext = _G["PartyMemberFrame" .. i .. "ManaBarText"];
	local texture  = _G["PartyMemberFrame" .. i .. "Texture"];
	local flash    = _G["PartyMemberFrame" .. i .. "Flash"];
	local hpbar    = _G["PartyMemberFrame" .. i .. "HealthBar"];
	local bg       = _G["PartyMemberFrame" .. i .. "Background"];

	if name and o.nameFont then
		name:SetFont(o.nameFont[1], o.nameFont[2], o.nameFont[3]);
		SafeSetPoint(name, o.namePoint);
	end
	-- hptext / manatext ya no se tocan al aplicar el estilo, asi que
	-- tampoco hay nada que restaurar aca.
	if texture then
		texture:SetTexture(o.texture);
		SafeSetPoint(texture, o.texturePoint);
	end
	if flash and o.flash then
		flash:SetTexture(o.flash);
		SafeSetPoint(flash, o.flashPoint);
	end
	if hpbar then
		SafeSetPoint(hpbar, o.hpPoint);
		if o.hpHeight then hpbar:SetHeight(o.hpHeight); end
	end
	if o.hpBarTexture and hpbar.SetStatusBarTexture then
		hpbar:SetStatusBarTexture(o.hpBarTexture);
	end
	if o.manaBarTexture then
		local manabar = _G["PartyMemberFrame" .. i .. "ManaBar"];
		if manabar then manabar:SetStatusBarTexture(o.manaBarTexture); end
	end

	if bg then
		SafeSetPoint(bg, o.bgPoint);
		if o.bgHeight then bg:SetHeight(o.bgHeight); end
		if o.bgWidth  then bg:SetWidth(o.bgWidth); end
	end
end

local function StyleAll()
	if InCombatLockdown() then return; end
	for i = 1, MAX_PARTY do StyleFrame(i); end
end

local function RestoreAll()
	if InCombatLockdown() then return; end
	for i = 1, MAX_PARTY do RestoreFrame(i); end
end

-- OJO: esto lo llaman el slider de tamaño y el desplegable de contorno para
-- repintar. Antes era StyleAll pelado, asi que tocar cualquiera de los dos
-- con el estilo "Blizzard" activo APLICABA el estilo Improved. Ahora solo
-- repinta si Improved es realmente el estilo elegido.
K.PFI_Restyle = function()
	local style = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
	if style ~= "Improved" then return; end
	StyleAll();
end

-- ---------------------------------------------------------
-- Hooks
-- Blizzard reaplica el arte al entrar y salir de vehiculo y en cada
-- actualizacion del miembro, asi que hay que re-pintar despues.
-- ---------------------------------------------------------
local function InstallHooks()
	if hooked then return; end
	hooked = true;

	if type(PartyMemberFrame_ToPlayerArt) == "function" then
		hooksecurefunc("PartyMemberFrame_ToPlayerArt", function()
			if enabled then StyleAll(); end
		end);
	end

	if type(PartyMemberFrame_ToVehicleArt) == "function" then
		hooksecurefunc("PartyMemberFrame_ToVehicleArt", function()
			if not enabled or InCombatLockdown() then return; end
			for i = 1, MAX_PARTY do
				local tex = _G["PartyMemberFrame" .. i .. "VehicleTexture"];
				if tex then tex:SetTexture(TEX_VEHICLE); end
			end
		end);
	end

	if type(PartyMemberFrame_UpdateMember) == "function" then
		hooksecurefunc("PartyMemberFrame_UpdateMember", function()
			if enabled then StyleAll(); end
		end);
	end

	-- Blizzard REPONE la textura de relleno en cada actualizacion de la
	-- barra, asi que aplicarla una vez no alcanza: se pierde al primer
	-- golpe que reciba el del grupo. NewPartyFrame ya tiene estos hooks,
	-- pero atados a SU flag, asi que con Improved activo no corren.
	local function ReapplyBarTexture(self)
		if not enabled or not self then return; end
		if not (C.statusbarOn and C.statusbarTexture) then return; end
		local parent = self:GetParent();
		local n = parent and parent.GetName and parent:GetName();
		if n and string.find(n, "^PartyMemberFrame%d+$") then
			self:SetStatusBarTexture(C.statusbarTexture);
		end
	end

	if type(UnitFrameHealthBar_Update) == "function" then
		hooksecurefunc("UnitFrameHealthBar_Update", ReapplyBarTexture);
	end
	if type(UnitFrameManaBar_Update) == "function" then
		hooksecurefunc("UnitFrameManaBar_Update", ReapplyBarTexture);
	end
end

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function()
	if enabled then StyleAll(); end
end);

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
K.RegisterModule("PartyFramesImproved", {
	name    = L["MOD_PFI"] or "Party Frames Improved",
	desc    = L["MOD_PFI_DESC"]
		or "Wider, cleaner texture for the party frames, with smaller name / health / mana text and a bigger health bar.",
	default = false,
	onEnable = function()
		enabled = true;
		InstallHooks();
		StyleAll();
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
		events:RegisterEvent("PARTY_MEMBERS_CHANGED");
		-- Si lo prendieron desde Addons > Interfaz, avisar al coordinador
		-- para que apague NewPartyFrame: los dos retexturizan lo mismo.
		if K.NotifyPartyStyleFromModule then K.NotifyPartyStyleFromModule("Improved"); end
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		RestoreAll();
		if K.NotifyPartyStyleFromModule and K.GetPartyFrameStyle
			and K.GetPartyFrameStyle() == "Improved" then
			K.NotifyPartyStyleFromModule("Default");
		end
	end,
});
