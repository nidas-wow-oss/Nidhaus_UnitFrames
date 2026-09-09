local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ClassOutline.lua
-- Anillo del color de la clase alrededor del retrato.
--
-- Adaptado de RougeUI (outlines.lua). Cambios para 3.3.5a:
--   * RougeUI usa CreateColor(), que NO existe en 3.3.5a (llega en 8.0).
--     Alla funciona porque el addon depende de !!!ClassicAPI, que lo
--     agrega a mano. Aca se usa una tabla RGB comun.
--   * RougeUI lo pone solo en target y focus; aca tambien en el player.
--   * El anillo se ancla al retrato de cada marco, asi que sigue al frame
--     aunque NUF le cambie el skin o la escala.
--
-- La textura es un anillo blanco: se tiñe con SetVertexColor, no hace
-- falta una imagen por clase.
-- =========================================================

local TEX_DIR  = "Interface\\AddOns\\" .. AddOnName .. "\\Modules2\\ClassOutline\\Textures\\";
-- Dos anillos: el normal tiene un HUECO en el cuadrante inferior derecho,
-- justo donde el marco dibuja el circulito del nivel; el "Full" es cerrado.
--
-- El hueco solo tiene sentido si HAY un numero de nivel que esquivar. Los
-- temas Asuri y Compact no lo dibujan, asi que con el anillo normal se veia
-- un mordisco en el borde sin razon: ahi va el cerrado.
--
-- Light y Dark si muestran el nivel y se quedan con el del hueco.
local function RingTexture()
	if C.AsuriFrames or C.pwFrames then return TEX_DIR .. "PortraitRingFull"; end
	return TEX_DIR .. "PortraitRing";
end

-- El hueco viene dibujado abajo a la DERECHA, porque en RougeUI el anillo
-- solo se usaba en target y focus (retrato a la derecha, nivel abajo a la
-- derecha). En el PLAYER el retrato esta a la izquierda y el nivel queda
-- abajo a la izquierda: con la textura sin espejar, el anillo le pasaba
-- por encima al numero. Espejandola horizontalmente el hueco cae donde va.
local function RingTexCoord(frame)
	if frame.unit == "player" then
		return 1, 0, 0, 1;   -- espejado
	end
	return 0, 1, 0, 1;
end

-- Colores de clase. Se prefieren los de Blizzard (RAID_CLASS_COLORS) y
-- se cae a esta tabla si falta alguno (ej. clases que no existen en WotLK).
local FALLBACK = {
	HUNTER      = { r = 0.67, g = 0.83, b = 0.45 },
	WARLOCK     = { r = 0.53, g = 0.53, b = 0.93 },
	PRIEST      = { r = 1.00, g = 1.00, b = 1.00 },
	PALADIN     = { r = 0.96, g = 0.55, b = 0.73 },
	MAGE        = { r = 0.25, g = 0.78, b = 0.92 },
	ROGUE       = { r = 1.00, g = 0.96, b = 0.41 },
	DRUID       = { r = 1.00, g = 0.49, b = 0.04 },
	SHAMAN      = { r = 0.00, g = 0.44, b = 0.87 },
	WARRIOR     = { r = 0.78, g = 0.61, b = 0.43 },
	DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
};

local function ClassColor(class)
	if not class then return nil; end
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class];
	if c and c.r then return c; end
	return FALLBACK[class];
end

-- Marcos donde se dibuja el anillo
local WATCHED = {
	player = true,
	target = true,
	focus  = true,
};

local enabled  = false;
local hooked   = false;
local rings    = {};   -- frame -> ring frame

-- ---------------------------------------------------------
-- DB (tamaño del anillo)
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ClassOutline then
		NidhausUnitFramesDB.ClassOutline = { size = 62 };
	end
	return NidhausUnitFramesDB.ClassOutline;
end

-- ---------------------------------------------------------
-- Anillo
-- ---------------------------------------------------------
local function GetRing(frame)
	if rings[frame] then return rings[frame]; end
	if not frame.portrait then return nil; end

	local size = DB().size or 62;

	-- OJO CON EL PADRE: en el player, K.MoveFrame reparenta los hijos del
	-- PlayerFrame a NidhausPlayerFrame. Si el anillo cuelga de PlayerFrame
	-- queda por DEBAJO del marco (que vive en el otro frame) y no se ve
	-- — se notaba sobre todo con el marco grueso de Asuri.
	-- Colgandolo del mismo padre que el retrato, siempre queda encima.
	local host = frame.portrait:GetParent() or frame;

	local ring = CreateFrame("Frame", nil, host);
	ring:SetWidth(size);
	ring:SetHeight(size);
	-- Centrado sobre el retrato: asi vale para player, target y focus por
	-- igual, sin coordenadas fijas por marco.
	ring:SetPoint("CENTER", frame.portrait, "CENTER", 0, 0);
	ring:SetFrameLevel(math.max(0, (host:GetFrameLevel() or 1) + 2));

	ring.texture = ring:CreateTexture(nil, "OVERLAY");
	ring.texture:SetAllPoints(ring);
	ring.texture:SetTexture(RingTexture());

	-- El anillo es un frame hijo, asi que se dibuja por ENCIMA de las
	-- texturas del marco... incluido el icono de Alianza/Horda, que quedaba
	-- tapado. Se resuelve poniendo el icono en un frame propio por encima
	-- del anillo, en vez de bajar el anillo (ahi lo tapaba el marco).
	local icon = _G[(frame:GetName() or "") .. "PVPIcon"] or frame.pvpIcon
		or (frame == PlayerFrame and _G["PlayerPVPIcon"]);
	if icon and not icon._nufRaised then
		local host = CreateFrame("Frame", nil, frame);
		host:SetAllPoints(frame);
		host:SetFrameLevel(ring:GetFrameLevel() + 1);
		pcall(icon.SetParent, icon, host);
		icon._nufRaised = true;
	end

	ring:Hide();
	rings[frame] = ring;
	return ring;
end

-- Cadena del tema Asuri: en RougeUI vive en el mismo hook que el anillo
-- de clase, y reemplaza al anillo cuando el objetivo es elite o raro.
-- OJO: nada de ".." en las rutas, el cliente no las resuelve.
local ASURI = "Interface\\AddOns\\" .. AddOnName .. "\\Media\\Asuri\\";

local function AsuriChain(frame, ring)
	if not (C.UnitFrameCustomTexture and C.AsuriFrames) then return false; end
	if frame.unit == "player" then return false; end

	local class = UnitClassification(frame.unit);
	if class == "normal" or not UnitExists(frame.unit) then return false; end

	local gold = (class == "elite" or class == "worldboss");
	ring.texture:SetTexture(ASURI .. (gold and "ChainAsuriGold" or "ChainAsuri"));
	ring.texture:SetVertexColor(1, 1, 1);
	ring:SetWidth(256);
	ring:SetHeight(128);
	ring:ClearAllPoints();
	if frame == FocusFrame then
		ring.texture:SetTexCoord(1, 0, 0, 1);
		ring:SetPoint("CENTER", frame.portrait, "BOTTOMLEFT", 85, 12);
	else
		ring.texture:SetTexCoord(0, 1, 0, 1);
		ring:SetPoint("CENTER", frame.portrait, "BOTTOMLEFT", -22, 12);
	end
	ring:Show();
	return true;
end

-- Deja el anillo como anillo otra vez (la cadena le cambia tamaño y anclaje)
local function ResetRing(ring, frame)
	local size = DB().size or 62;
	ring.texture:SetTexture(RingTexture());
	ring.texture:SetTexCoord(RingTexCoord(frame));
	ring:SetWidth(size);
	ring:SetHeight(size);
	ring:ClearAllPoints();
	ring:SetPoint("CENTER", frame.portrait, "CENTER", 0, 0);
end

local function UpdateFrame(frame)
	if not frame or not frame.unit then return; end
	if not WATCHED[frame.unit] then return; end

	local ring = GetRing(frame);
	if not ring then return; end

	-- La cadena Asuri corre aunque el modulo de anillos este apagado:
	-- es parte del tema, no del indicador de clase.
	if AsuriChain(frame, ring) then return; end
	ResetRing(ring, frame);

	if not enabled then
		ring:Hide();
		return;
	end

	-- Solo jugadores: en un mob el color de clase no significa nada.
	if not UnitExists(frame.unit) or not UnitIsPlayer(frame.unit) then
		ring:Hide();
		return;
	end

	local _, class = UnitClass(frame.unit);
	local c = ClassColor(class);
	if not c then
		ring:Hide();
		return;
	end

	ring.texture:SetVertexColor(c.r, c.g, c.b);
	ring:Show();
end

local function UpdateAll()
	local frames = {
		_G["NidhausPlayerFrame"] or _G["PlayerFrame"],
		_G["PlayerFrame"],
		_G["TargetFrame"],
		_G["FocusFrame"],
	};
	for _, f in ipairs(frames) do
		if f then UpdateFrame(f); end
	end
end
K.RefreshClassOutlines = UpdateAll;

-- ---------------------------------------------------------
-- Hook
-- ---------------------------------------------------------
local function EnsureHook()
	if hooked then return; end
	hooked = true;
	-- Se engancha UNA sola vez y para siempre: hooksecurefunc no se puede
	-- deshacer, por eso adentro se chequea 'enabled'.
	hooksecurefunc("UnitFramePortrait_Update", function(self)
		if self and self.portrait then UpdateFrame(self); end
	end);
end

local events = CreateFrame("Frame");
events:SetScript("OnEvent", function()
	UpdateAll();
end);

-- El tema Asuri necesita el hook aunque el modulo de anillos este apagado.
local boot = CreateFrame("Frame");
boot:RegisterEvent("PLAYER_ENTERING_WORLD");
boot:SetScript("OnEvent", function(self)
	if C.UnitFrameCustomTexture and C.AsuriFrames then
		EnsureHook();
		events:RegisterEvent("PLAYER_TARGET_CHANGED");
		events:RegisterEvent("PLAYER_FOCUS_CHANGED");
		UpdateAll();
	end
end);

-- ---------------------------------------------------------
-- API para el panel
-- ---------------------------------------------------------
function K.GetClassOutlineSize()
	return DB().size or 62;
end

function K.SetClassOutlineSize(v)
	v = tonumber(v) or 62;
	DB().size = v;
	UpdateAll();
end

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
K.RegisterModule("ClassOutline", {
	name    = L["MOD_CLASSOUTLINE"] or "Class Colored Outlines",
	desc    = L["MOD_CLASSOUTLINE_DESC"]
		or "Adds a class colored ring around the player, target and focus portraits.",
	default = false,
	hideFromModulesTab = true,   -- pedido: fuera de la lista de Addons

	onEnable = function()
		enabled = true;
		EnsureHook();
		events:RegisterEvent("PLAYER_ENTERING_WORLD");
		events:RegisterEvent("PLAYER_TARGET_CHANGED");
		events:RegisterEvent("PLAYER_FOCUS_CHANGED");
		events:RegisterEvent("UNIT_PORTRAIT_UPDATE");
		UpdateAll();
	end,

	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		for _, ring in pairs(rings) do ring:Hide(); end
	end,
});
