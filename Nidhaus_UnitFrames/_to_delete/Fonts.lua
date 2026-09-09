local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- Fonts.lua  --  UN SOLO DUEÑO PARA LAS LETRAS
--
-- Cada modulo elegia su fuente por su cuenta, y dos terminaban escribiendo
-- sobre el MISMO texto: Lorti UI y el modulo de barras de accion se
-- pisaban la tecla, el nombre de macro y las cargas. Ganaba el que corriera
-- ultimo, y como Lorti reaplica en cada actualizacion de boton, casi
-- siempre ganaba Lorti.
--
-- Aca viven el catalogo y la decision. Los modulos CONSULTAN, no eligen.
--
-- POR QUE EN Core Y NO EN UN MODULO. Un modulo se puede apagar. El
-- catalogo no puede desaparecer porque alguien apago NiceDamage, que es
-- donde vivia hasta ahora.
--
-- LOS .ttf SE QUEDAN EN Modules2/NiceDamage/. Moverlos era tocar doce
-- archivos para nada: desde aca se los nombra igual.
--
-- OJO: NiceDamage MANTIENE SU PROPIA COPIA de esta lista. Es a proposito
-- -- ese selector ya andaba bien y no se toca -- pero significa que una
-- fuente nueva hay que agregarla en LOS DOS LADOS: aca y en
-- Modules2/NiceDamage/NiceDamage.lua. Las dos listas tienen que quedar en
-- el MISMO ORDEN: lo que se guarda es el indice, asi que si se desalinean
-- cada panel aplica una letra distinta.
-- =========================================================

local FONT_DIR     = "Interface\\AddOns\\" .. AddOnName .. "\\Modules2\\NiceDamage\\";
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF";

-- EL CATALOGO.
--
-- El orden IMPORTA: lo que se guarda es el indice, asi que una fuente
-- nueva va al FINAL. Meterla en el medio le cambia la letra a quien ya
-- eligio.
--
-- flags: bandera de SetFont. Sin campo se respeta la que ya tenia el
-- texto, que no es lo mismo que ponerle "" (sin contorno).
K.Fonts = {
	{ name = "Default WoW",       file = nil              },
	{ name = "Pepsi",             file = "font.ttf"       },
	{ name = "Zombie",            file = "font2.ttf"      },
	{ name = "Basket Hammers",    file = "font3.ttf"      },
	{ name = "College",           file = "font4.ttf"      },
	{ name = "Galaxy",            file = "font5.ttf"      },
	{ name = "Elite",             file = "font6.ttf"      },
	{ name = "Stentiga",          file = "font7.ttf"      },
	{ name = "Skratch Punk",      file = "font8.ttf"      },
	{ name = "Prototype",         file = "Prototype.ttf"  },
	{ name = "Prototype Outline", file = "Prototype.ttf", flags = "OUTLINE" },
};

-- LAS SUPERFICIES: cada zona que puede tener su propia letra, con la
-- clave donde se guarda la eleccion.
local SURFACES = {
	ActionBars = "Font_ActionBars",   -- tecla, nombre de macro, cargas
	Auras      = "Font_Auras",        -- duracion y apilamiento de buffs
	CastBar    = "Font_CastBar",      -- nombre del hechizo
};

-- En orden, para que el panel los dibuje siempre igual.
K.FontSurfaces = { "ActionBars", "Auras", "CastBar" };

-- ---------------------------------------------------------
-- Consulta
-- ---------------------------------------------------------
function K.FontIndex(surface)
	local key = SURFACES[surface];
	local i = key and tonumber(C[key]);
	if not i or i < 1 or i > #K.Fonts then return 1; end
	return i;
end

function K.FontPath(index)
	local d = K.Fonts[index];
	if d and d.file then return FONT_DIR .. d.file; end
	return DEFAULT_FONT;
end

function K.FontFlags(index, fallback)
	local d = K.Fonts[index];
	if d and d.flags ~= nil then return d.flags; end
	return fallback;
end

-- La familia de una superficie, o NIL si esta en "Default WoW".
--
-- Devuelve nil y no la ruta de FRIZQT a proposito: quien consulta sabe
-- cual es SU original, y casi nunca es FRIZQT pelado. La tecla de un boton
-- usa NumberFontNormalSmallGray, no FRIZQT.
function K.FontFamily(surface)
	local i = K.FontIndex(surface);
	if i <= 1 then return nil; end
	return K.FontPath(i), K.FontFlags(i, nil);
end

-- ---------------------------------------------------------
-- Aplicar, con vuelta atras
--
-- Se guarda lo que el texto tenia la PRIMERA vez que se lo toca, para que
-- "Default WoW" devuelva exactamente la letra de Blizzard.
--
-- Claves debiles: si el texto desaparece, la anotacion se va con el y no
-- queda una tabla creciendo para siempre.
-- ---------------------------------------------------------
local originals = setmetatable({}, { __mode = "k" });

function K.SetFont(fs, surface)
	if not fs or not fs.GetFont then return; end

	local o = originals[fs];
	if not o then
		local path, size, flags = fs:GetFont();
		o = { path, size, flags };
		originals[fs] = o;
	end

	local path, flags = K.FontFamily(surface);
	if not path then
		fs:SetFont(o[1], o[2], o[3]);
		return;
	end
	if flags == nil then flags = o[3]; end

	-- SE RESPETA EL TAMAÑO. Cada texto viene con el suyo -- la tecla es
	-- chica, el contador grande -- y pisarlos con un numero fijo desarma
	-- la lectura del boton.
	--
	-- Si el .ttf no carga, SetFont devuelve false y el texto quedaria
	-- INVISIBLE: se vuelve al original en vez de dejarlo mudo.
	if not fs:SetFont(path, o[2], flags) then
		fs:SetFont(o[1], o[2], o[3]);
	end
end

-- ---------------------------------------------------------
-- Quien aplica cada superficie
--
-- El nucleo no sabe donde estan los textos: cada modulo se anota y dice
-- como repasar los suyos. Asi el panel cambia una eleccion y llama aca
-- sin conocer a nadie.
-- ---------------------------------------------------------
local appliers = {};

function K.RegisterFontSurface(surface, fn)
	if type(fn) == "function" then appliers[surface] = fn; end
end

function K.ApplyFonts(surface)
	if surface then
		local fn = appliers[surface];
		if fn then fn(); end
		return;
	end
	for _, fn in pairs(appliers) do fn(); end
end

-- ---------------------------------------------------------
-- Migracion
--
-- ActionBarFont era UNA sola eleccion para los botones y las auras
-- juntos. Ahora son dos superficies distintas, asi que el valor viejo se
-- reparte en las dos y no se lee nunca mas.
-- ---------------------------------------------------------
local function Migrate()
	if C.FontsMigrated then return; end

	local old = tonumber(C.ActionBarFont);
	if old and old > 1 and old <= #K.Fonts then
		C.Font_ActionBars = old;
		C.Font_Auras      = old;
		if K.SaveConfig then
			K.SaveConfig("Font_ActionBars", old);
			K.SaveConfig("Font_Auras", old);
		end
	end

	C.FontsMigrated = true;
	if K.SaveConfig then K.SaveConfig("FontsMigrated", true); end
end

local boot = CreateFrame("Frame");
boot:RegisterEvent("PLAYER_LOGIN");
boot:SetScript("OnEvent", function(self)
	Migrate();
	K.ApplyFonts();
	self:UnregisterAllEvents();
end);
