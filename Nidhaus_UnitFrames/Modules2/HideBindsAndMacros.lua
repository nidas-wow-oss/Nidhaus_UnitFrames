local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- HideBindsAndMacros.lua
-- Oculta el texto de los bindeos (hotkey) y/o el nombre de
-- las macros en los botones de las barras de accion.
-- Dos opciones independientes:
--   C.HideKeybindText -> oculta el texto de la tecla
--   C.HideMacroText   -> oculta el nombre de la macro
-- =========================================================

-- Prefijos de botones a procesar
local buttonGroups = {
	{ prefix = "ActionButton",              count = 12 },
	{ prefix = "MultiBarBottomLeftButton",  count = 12 },
	{ prefix = "MultiBarBottomRightButton", count = 12 },
	{ prefix = "MultiBarRightButton",       count = 12 },
	{ prefix = "MultiBarLeftButton",        count = 12 },
	{ prefix = "BonusActionButton",         count = 12 },
	{ prefix = "PetActionButton",           count = 10 },
	{ prefix = "ShapeshiftButton",          count = 10 },
};

local function ApplyToButton(button)
	if not button then return; end
	local name = button:GetName();
	if not name then return; end

	local hotkey = _G[name .. "HotKey"];
	local macro  = _G[name .. "Name"];

	if hotkey then
		if C.HideKeybindText then hotkey:Hide(); else hotkey:Show(); end
	end
	if macro then
		if C.HideMacroText then macro:Hide(); else macro:Show(); end
	end
end

local function ApplyAll()
	for _, group in ipairs(buttonGroups) do
		for i = 1, group.count do
			ApplyToButton(_G[group.prefix .. i]);
		end
	end
end
K.ApplyHideBindsAndMacros = ApplyAll;

-- ---------------------------------------------------------
-- Hooks: Blizzard vuelve a mostrar los textos en cada update
-- ---------------------------------------------------------
hooksecurefunc("ActionButton_UpdateHotkeys", function(self)
	if not self or not self.GetName then return; end
	if not (C.HideKeybindText or C.HideMacroText) then return; end
	ApplyToButton(self);
end);

if type(ActionButton_Update) == "function" then
	hooksecurefunc("ActionButton_Update", function(self)
		if not self or not self.GetName then return; end
		if not (C.HideKeybindText or C.HideMacroText) then return; end
		ApplyToButton(self);
	end);
end

if type(PetActionBar_Update) == "function" then
	hooksecurefunc("PetActionBar_Update", function()
		if not C.HideKeybindText then return; end
		for i = 1, 10 do ApplyToButton(_G["PetActionButton" .. i]); end
	end);
end

-- ---------------------------------------------------------
-- Aplicar al cambiar la config y al entrar al mundo
-- ---------------------------------------------------------
if K.RegisterConfigEvent then
	K.RegisterConfigEvent("CONFIG_CHANGED", ApplyAll);
end

-- Reintentos: algunas barras se crean tarde (relog, entrar a arena)
local retry = CreateFrame("Frame");
local attempts, acc = 0, 0;
retry:Hide();
retry:SetScript("OnUpdate", function(self, elapsed)
	acc = acc + elapsed;
	if acc < 0.4 then return; end
	acc = 0;
	ApplyAll();
	attempts = attempts + 1;
	if attempts >= 6 then self:Hide(); end
end);

local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("PLAYER_LOGIN");
events:RegisterEvent("UPDATE_BINDINGS");
events:SetScript("OnEvent", function()
	ApplyAll();
	attempts, acc = 0, 0;
	retry:Show();
end);
