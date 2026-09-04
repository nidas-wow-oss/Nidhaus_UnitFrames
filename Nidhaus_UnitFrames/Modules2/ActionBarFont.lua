local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ActionBarFont.lua
--
-- Cambia la letra de los botones de las barras de accion: la tecla, el
-- nombre de la macro y el contador de cargas.
--
-- LA LISTA ES LA MISMA que la del selector de NiceDamage. Ese archivo la
-- publica en K.NUF_Fonts / K.NUF_FontPath / K.NUF_FontFlags, y siempre se
-- carga (que el modulo este apagado solo apaga su comportamiento, no su
-- archivo), asi que aca alcanza con pedirsela. Un solo lugar donde
-- agregar una fuente nueva y aparece en los dos lados.
--
-- SE CAMBIA LA FAMILIA, NO EL TAMAÑO. Cada texto viene con el suyo — la
-- tecla es chica, el contador es mas grande — y pisarlos con un numero
-- fijo desarma la lectura del boton. Se lee el tamaño que ya tenia y se
-- reusa.
--
-- SE GUARDA EL ORIGINAL. "Default WoW" tiene que devolver exactamente la
-- letra de Blizzard, y esa no es FRIZQT a secas: cada texto usa su propio
-- objeto de fuente. Se anota lo que tenia la primera vez que se lo toca y
-- se repone tal cual.
-- =========================================================

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

-- HotKey = la tecla, Name = el nombre de la macro, Count = las cargas.
local SUFFIXES = { "HotKey", "Name", "Count" };

local originals = {};   -- [fontstring] = { ruta, tamaño, banderas }

local function Remember(fs)
	local o = originals[fs];
	if o then return o; end
	local path, size, flags = fs:GetFont();
	o = { path, size, flags };
	originals[fs] = o;
	return o;
end

local function Index()
	local i = tonumber(C.ActionBarFont);
	if not i or i < 1 then return 1; end
	return i;
end

local function ApplyToFontString(fs)
	if not fs or not fs.GetFont then return; end

	local orig = Remember(fs);
	local idx  = Index();

	-- 1 es "Default WoW": se repone lo que tenia y listo.
	if idx <= 1 or not K.NUF_FontPath then
		fs:SetFont(orig[1], orig[2], orig[3]);
		return;
	end

	local path = K.NUF_FontPath(idx);
	if not path then
		fs:SetFont(orig[1], orig[2], orig[3]);
		return;
	end

	local flags = orig[3];
	if K.NUF_FontFlags then flags = K.NUF_FontFlags(idx, orig[3]); end

	-- Si el .ttf no carga, SetFont devuelve false y el texto queda
	-- INVISIBLE. Se vuelve al original en vez de dejar el boton mudo.
	if not fs:SetFont(path, orig[2], flags) then
		fs:SetFont(orig[1], orig[2], orig[3]);
	end
end

local function ApplyToButton(button)
	if not button or not button.GetName then return; end
	local name = button:GetName();
	if not name then return; end
	for _, suffix in ipairs(SUFFIXES) do
		ApplyToFontString(_G[name .. suffix]);
	end
end

function K.ApplyActionBarFont()
	for _, group in ipairs(buttonGroups) do
		for i = 1, group.count do
			ApplyToButton(_G[group.prefix .. i]);
		end
	end
end

-- ---------------------------------------------------------
-- Hooks
--
-- Blizzard reescribe estos textos en cada actualizacion del boton, pero
-- SetText no toca la fuente: la familia elegida se mantiene. Los hooks
-- estan por los botones que aparecen despues (mascota, posturas, vehiculo)
-- y que por eso nunca pasaron por el barrido inicial.
-- ---------------------------------------------------------
local function HookIfActive(fn)
	if type(_G[fn]) ~= "function" then return; end
	hooksecurefunc(fn, function(self)
		if Index() <= 1 then return; end
		if type(self) == "table" and self.GetName then
			ApplyToButton(self);
		else
			K.ApplyActionBarFont();
		end
	end);
end

HookIfActive("ActionButton_UpdateHotkeys");
HookIfActive("ActionButton_Update");
HookIfActive("PetActionBar_Update");

-- ---------------------------------------------------------
-- Arranque
--
-- Las barras de mascota y postura no existen al cargar, asi que se pasa
-- unas cuantas veces mas despues de entrar al mundo.
-- ---------------------------------------------------------
local sweepAcc, sweepCount = 0, 0;

local sweep = CreateFrame("Frame");
sweep:Hide();
sweep:SetScript("OnUpdate", function(self, elapsed)
	sweepAcc = sweepAcc + elapsed;
	if sweepAcc < 0.5 then return; end
	sweepAcc = 0;
	sweepCount = sweepCount + 1;
	K.ApplyActionBarFont();
	if sweepCount >= 6 then self:Hide(); end
end);

local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
events:RegisterEvent("UNIT_PET");
events:SetScript("OnEvent", function()
	K.ApplyActionBarFont();
	sweepAcc, sweepCount = 0, 0;
	sweep:Show();
end);
