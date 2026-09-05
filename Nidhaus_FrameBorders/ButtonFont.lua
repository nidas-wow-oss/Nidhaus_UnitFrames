local ADDON, ns = ...;

-- =========================================================
-- ButtonFont.lua  --  la letra de los botones
--
-- Cambia la fuente de la tecla, el nombre de la macro y el contador de
-- cargas en las barras de accion, y la duracion y el apilamiento en las
-- auras. Va con el borde porque es parte del mismo aspecto.
--
-- SE CAMBIA LA FAMILIA, NO EL TAMANO. Cada texto viene con el suyo -- la
-- tecla es chica, el contador grande -- y pisarlos con un numero fijo
-- desarma la lectura del boton. Se lee el tamano que ya tenia y se reusa.
--
-- SE GUARDA EL ORIGINAL. La opcion "Sin cambiar" tiene que devolver
-- exactamente la letra de Blizzard, y esa no es FRIZQT a secas: cada texto
-- usa su propio objeto de fuente (la tecla, por ejemplo,
-- NumberFontNormalSmallGray). Se anota lo que tenia la primera vez que se
-- lo toca y se repone tal cual.
--
-- CLAVES DEBILES en la tabla de originales: si el texto desaparece, la
-- anotacion se va con el y no queda una tabla creciendo para siempre.
-- =========================================================

local PROTOTYPE = ns.MEDIA .. "Fonts\\Prototype.ttf";

-- El indice se guarda, asi que el orden no se toca.
ns.FONTS = {
	{ name = "Sin cambiar",       file = nil                          },
	{ name = "Prototype",         file = PROTOTYPE                    },
	{ name = "Prototype Outline", file = PROTOTYPE, flags = "OUTLINE" },
};

local function Choice()
	local i = tonumber(ns.Get("font")) or 1;
	if i < 1 or i > #ns.FONTS then return 1; end
	return i;
end

-- La familia elegida, o nil si esta en "Sin cambiar". Se devuelve nil y no
-- una ruta a proposito: quien consulta sabe cual es SU original.
function NidhausFrameBorders_ButtonFont()
	local d = ns.FONTS[Choice()];
	if not d or not d.file then return nil; end
	return d.file, d.flags;
end

local originals = setmetatable({}, { __mode = "k" });

local function ApplyTo(fs)
	if not fs or not fs.GetFont then return; end

	local o = originals[fs];
	if not o then
		local path, size, flags = fs:GetFont();
		o = { path, size, flags };
		originals[fs] = o;
	end

	local path, flags = NidhausFrameBorders_ButtonFont();
	if not path then
		fs:SetFont(o[1], o[2], o[3]);
		return;
	end
	if flags == nil then flags = o[3]; end

	-- Si el .ttf no carga, SetFont devuelve false y el texto quedaria
	-- INVISIBLE: se vuelve al original en vez de dejar el boton mudo.
	if not fs:SetFont(path, o[2], flags) then
		fs:SetFont(o[1], o[2], o[3]);
	end
end

-- Cada familia declara que textos le cuelgan: la barra de mascota y la de
-- posturas no tienen nombre de macro, y las auras no tienen tecla.
local GROUPS = {
	{ prefix = "ActionButton",              count = 12, texts = { "HotKey", "Name", "Count" } },
	{ prefix = "MultiBarBottomLeftButton",  count = 12, texts = { "HotKey", "Name", "Count" } },
	{ prefix = "MultiBarBottomRightButton", count = 12, texts = { "HotKey", "Name", "Count" } },
	{ prefix = "MultiBarRightButton",       count = 12, texts = { "HotKey", "Name", "Count" } },
	{ prefix = "MultiBarLeftButton",        count = 12, texts = { "HotKey", "Name", "Count" } },
	{ prefix = "BonusActionButton",         count = 12, texts = { "HotKey", "Name", "Count" } },
	{ prefix = "PetActionButton",           count = 10, texts = { "HotKey", "Count" } },
	{ prefix = "ShapeshiftButton",          count = 10, texts = { "HotKey", "Count" } },
	{ prefix = "BuffButton",                count = 32, texts = { "Duration", "Count" } },
	{ prefix = "DebuffButton",              count = 16, texts = { "Duration", "Count" } },
	{ prefix = "TempEnchant",               count = 3,  texts = { "Duration", "Count" } },
};

local DEFAULT_TEXTS = { "HotKey", "Name", "Count" };

local function ApplyToButton(button, texts)
	if not button or not button.GetName then return; end
	local name = button:GetName();
	if not name then return; end
	for _, suffix in ipairs(texts or DEFAULT_TEXTS) do
		ApplyTo(_G[name .. suffix]);
	end
end

function ns.ApplyFont()
	for _, g in ipairs(GROUPS) do
		for i = 1, g.count do
			ApplyToButton(_G[g.prefix .. i], g.texts);
		end
	end
end

-- ---------------------------------------------------------
-- Hooks
--
-- Blizzard reescribe estos textos en cada actualizacion, pero SetText no
-- toca la fuente: la familia elegida se mantiene. Los hooks estan por los
-- botones que aparecen despues (mascota, posturas, vehiculo) y que por eso
-- nunca pasaron por el barrido inicial.
-- ---------------------------------------------------------
local function HookIfActive(fn)
	if type(_G[fn]) ~= "function" then return; end
	hooksecurefunc(fn, function(self)
		if type(self) == "table" and self.GetName then
			ApplyToButton(self, nil);
		else
			ns.ApplyFont();
		end
	end);
end

HookIfActive("ActionButton_UpdateHotkeys");
HookIfActive("ActionButton_Update");
HookIfActive("PetActionBar_Update");

-- Las barras de mascota y postura no existen al cargar, asi que se pasa
-- unas cuantas veces mas despues de entrar al mundo.
local sweepAcc, sweepCount = 0, 0;
local sweep = CreateFrame("Frame");
sweep:Hide();
sweep:SetScript("OnUpdate", function(self, elapsed)
	sweepAcc = sweepAcc + elapsed;
	if sweepAcc < 0.5 then return; end
	sweepAcc = 0;
	sweepCount = sweepCount + 1;
	ns.ApplyFont();
	if sweepCount >= 6 then self:Hide(); end
end);

local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
events:RegisterEvent("UNIT_PET");
-- Blizzard recicla el boton de aura al vencer una, y el nuevo viene con la
-- letra de fabrica. UNIT_AURA salta seguido, asi que hace un repaso y nada
-- mas: arrancar el barrido completo por cada buff que vence seria trabajo
-- al dope.
events:RegisterEvent("UNIT_AURA");
events:SetScript("OnEvent", function(self, event)
	if event == "UNIT_AURA" then
		ns.ApplyFont();
		return;
	end
	ns.ApplyFont();
	sweepAcc, sweepCount = 0, 0;
	sweep:Show();
end);
