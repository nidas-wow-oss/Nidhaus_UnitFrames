local AddOnName, ns = ...;
ns[1] = {};	-- K, Functions;
ns[2] = {};	-- C, Config;
ns[3] = {};	-- L, Localization;

-- EL NAMESPACE, VISIBLE DESDE AFUERA.
--
-- El "..." de cada archivo es privado del addon que lo carga, asi que el
-- panel de opciones — que ahora es un addon aparte (LoadOnDemand) — no
-- puede recibirlo por ahi. Se publica una sola global con la misma tabla:
-- no se copia nada, es la misma referencia, asi que K, C y L son los
-- mismos objetos de los dos lados.
_G.NidhausUnitFramesNS = ns;

-- ══════════════════════════════════════════════════════════════════
-- MODO SEGURO (diagnostico de freeze)
-- Con esto en true se NEUTRALIZAN los cambios de esta sesion que corren
-- solos al cargar: el borde del nombre, los agregados del minimapa
-- (GetMinimapShape / reacomodo de iconos / fuente de zona) y el skin icy
-- del mago. Sirve para descartar de un saque si el freeze viene de ahi.
-- Cuando el WoW cargue bien, lo ponemos en false y encontramos el exacto.
-- ══════════════════════════════════════════════════════════════════
-- Ya no hace falta: el culpable del freeze era ShieldWatch, que quedo fuera
-- del load. Con esto en false vuelven a funcionar el borde del nombre, los
-- agregados del minimapa y el skin icy.
_G.NUF_SAFE = false;

-- ══════════════════════════════════════════════════════════════════
-- RESET DE EMERGENCIA (una sola vez)
-- Como no se puede tocar el archivo de SavedVariables desde afuera, lo
-- limpiamos desde aca: la PRIMERA vez que carga con esta version, la
-- config guardada se descarta y se arranca de cero. Si el freeze venia de
-- una config corrupta (mucho toqueteo), esto lo soluciona. Se hace una
-- unica vez (queda una marca) y despues guarda normal.
-- ══════════════════════════════════════════════════════════════════
local emgFrame = CreateFrame("Frame");
emgFrame:RegisterEvent("ADDON_LOADED");
emgFrame:SetScript("OnEvent", function(self, event, addon)
	if addon ~= AddOnName then return; end
	self:UnregisterEvent("ADDON_LOADED");
	if type(NidhausUnitFramesDB) ~= "table" or not NidhausUnitFramesDB._emgReset_v36d then
		NidhausUnitFramesDB = { _emgReset_v36d = true };
	end
end);

local function SaveBlizzardDefaults()
	local C = ns[2];
	
	if PlayerFrame and not C.PlayerFrame_BlizzardDefault then
		local point, relativeTo, relativePoint, x, y = PlayerFrame:GetPoint(1);
		-- FIX: Solo guardar si GetPoint devolvió datos válidos
		if point then
			C.PlayerFrame_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0
			};
		end
	end
	
	if TargetFrame and not C.TargetFrame_BlizzardDefault then
		local point, relativeTo, relativePoint, x, y = TargetFrame:GetPoint(1);
		-- FIX: Solo guardar si GetPoint devolvió datos válidos
		if point then
			C.TargetFrame_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0
			};
		end
	end
	
	-- FIX: Capturar también la geometría default (Blizzard, sin el addon) de
	-- las healthbars de Player/Target/Focus, y la textura+posición default
	-- del ícono de status del Player (descanso/combate). Esto es lo que usa
	-- el checkbox "Custom Skin (Player/Target/Focus)" para poder volver EXACTO
	-- al default de Blizzard cuando se apaga, en vez de dejar la barra de vida
	-- con el tamaño/posición pensado para el marco .blp custom (lo que la
	-- dejaba desalineada/ensimada contra el marco default).
	if PlayerFrame and PlayerFrame.healthbar and not C.PlayerHealthBar_BlizzardDefault then
		local hb = PlayerFrame.healthbar;
		local point, relativeTo, relativePoint, x, y = hb:GetPoint(1);
		if point then
			C.PlayerHealthBar_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "PlayerFrame",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0,
				height = hb:GetHeight(),
			};
		end
	end
	
	if TargetFrame and TargetFrame.healthbar and not C.TargetHealthBar_BlizzardDefault then
		local hb = TargetFrame.healthbar;
		local point, relativeTo, relativePoint, x, y = hb:GetPoint(1);
		if point then
			C.TargetHealthBar_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "TargetFrame",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0,
				height = hb:GetHeight(),
			};
		end
	end
	
	if FocusFrame and FocusFrame.healthbar and not C.FocusHealthBar_BlizzardDefault then
		local hb = FocusFrame.healthbar;
		local point, relativeTo, relativePoint, x, y = hb:GetPoint(1);
		if point then
			C.FocusHealthBar_BlizzardDefault = {
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "FocusFrame",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0,
				height = hb:GetHeight(),
			};
		end
	end
	
	if PlayerStatusTexture and not C.PlayerStatusTexture_BlizzardDefault then
		local tex = PlayerStatusTexture:GetTexture();
		local point, relativeTo, relativePoint, x, y = PlayerStatusTexture:GetPoint(1);
		if tex and point then
			C.PlayerStatusTexture_BlizzardDefault = {
				texture = tex,
				point = point,
				relativeTo = relativeTo and relativeTo:GetName() or "PlayerFrame",
				relativePoint = relativePoint,
				x = x or 0,
				y = y or 0,
			};
		end
	end
end

-- FIX: Intentar en parse-time (que es lo más temprano posible, antes de que
-- CONFIG_LOADED mueva los frames), pero con nil guards robustos.
-- Si falla (GetPoint devuelve nil), reintentar en PLAYER_LOGIN como backup.
SaveBlizzardDefaults();

-- Backup: si parse-time no capturó los defaults, reintentar antes de que
-- FramePositions.lua los necesite en PLAYER_LOGIN.
local initDefaults = CreateFrame("Frame");
initDefaults:RegisterEvent("PLAYER_LOGIN");
initDefaults:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN");
	SaveBlizzardDefaults();
end);