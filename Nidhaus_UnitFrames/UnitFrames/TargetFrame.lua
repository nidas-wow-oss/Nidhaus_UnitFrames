local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- Mismo caso que en PlayerFrame: el blanco que habia aca corria cada vez
-- que se reaplica el skin y le borraba el tinte de Lorti UI.
--
local function TintBorder(tex)
	if not tex then return; end
	if not (K.ApplyLortiTint and K.ApplyLortiTint(tex,
		"LortiUI_PlayerTargetFocus")) then
		tex:SetVertexColor(1, 1, 1);
	end
end

local hooksecurefunc = hooksecurefunc;
local unpack, _G = unpack, _G;
local UnitClassification, UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP = UnitClassification, UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP;

local Path;
local isInitialized = false;

-- ── ASURI ─────────────────────────────────────────────────────
-- Tercer tema (RougeUI "Asuri UI Frames"): marco de cadenas, barras
-- finas y el nombre apoyado justo arriba de la barra de vida. El nivel,
-- el fondo del nombre y el indicador de amenaza se ocultan: el marco
-- Asuri no tiene lugar para ellos.
local ASURI = "Interface\\AddOns\\"..AddOnName.."\\Media\\Asuri\\";

local function AsuriOn()
	return C.UnitFrameCustomTexture and C.AsuriFrames;
end

-- FIX: Path según checkbox "Custom Skin" + tema Dark/Light. Con el skin
-- apagado usa el path real de Blizzard, dejando el marco/ToT-ToF default.
local function UpdatePath()
	if not C.UnitFrameCustomTexture then
		Path = "Interface\\TargetingFrame\\";
	elseif C.pwFrames then
		-- Tema "Compact", tomado de pw_unitframes. La carpeta tiene las
		-- dos texturas propias de pw (marco normal y de elite) y el resto
		-- completadas con las de Dark, que es el tema mas parecido: si
		-- faltara alguna, ese marco saldria en verde.
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\pw\\";
	elseif C.darkFrames then
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\";
	else
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\";
	end
	return Path;
end

-- FIX: captura (una sola vez, por frame) la geometría default del healthbar
-- y el anclaje default del texto, antes de que el addon los pise. keyBase
-- distingue Target de Focus.
-- FIX: captura (una sola vez, por frame) la geometría default del healthbar,
-- el anclaje default del texto de vida, el anclaje default del NOMBRE, y si
-- el nameBackground estaba visible. keyBase distingue Target de Focus.
-- Capturar el nombre y el nameBackground es lo que faltaba: el addon reancla
-- el nombre y esconde el fondo del nombre incondicionalmente, y eso no se
-- revertía → nombre corrido y fondo faltante con el skin apagado.
local function CaptureFrameDefaults(self, keyBase)
	if self.healthbar then
		-- Geometría (point único + height) para restaurar el DEFAULT de Blizzard
		K.CaptureBarGeometry(self.healthbar, keyBase.."HealthBar");
		-- Anclajes COMPLETOS (todos los points) para reproducir el doble
		-- anclaje que usa el look custom (TOPRIGHT default + TOPLEFT).
		K.CaptureAnchors(self.healthbar, keyBase.."HealthBarAnchors");
		if self.healthbar.TextString then
			K.CaptureAnchors(self.healthbar.TextString, keyBase.."HealthText");
		end
	end
	if self.name then
		K.CaptureAnchors(self.name, keyBase.."Name");
		-- Big Frames cambia la fuente del nombre: hay que poder volver atras.
		if not self._nufNameFont then
			self._nufNameFont = self.name:GetFontObject();
		end
	end
	if self.manabar then
		K.CaptureAnchors(self.manabar, keyBase.."ManaBarAnchors");
	end
	local bg = _G[self:GetName() .. "Background"];
	if bg and not bg._nufOrig then
		bg._nufOrig = { w = bg:GetWidth(), h = bg:GetHeight(),
			pts = { bg:GetPoint(1) } };
	end
end

--	Target frame
local function Nidhaus_UnitFrames_Style_TargetFrame(self)
	local keyBase = (self == FocusFrame) and "Focus" or "Target";
	CaptureFrameDefaults(self, keyBase);

	if C.UnitFrameCustomTexture then
		self.highLevelTexture:ClearAllPoints();
		self.highLevelTexture:SetPoint("CENTER", self.levelText, "CENTER", 1, 0);
		self.deadText:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
		self.nameBackground:Hide();
		-- FIX: usar anclaje ABSOLUTO desde el default capturado + offset, en vez
		-- de K.SetOffset (que lee el punto actual y suma → drift al togglear).
		K.RestoreAnchors(self.name, keyBase.."Name");
		if C.TargetNameOffset and type(C.TargetNameOffset) == "table" then
			self.name:SetPoint(K.SetOffset(self.name, unpack(C.TargetNameOffset)));
		else
			self.name:SetPoint(K.SetOffset(self.name, 0, 0));
		end

		-- ASURI: nombre pegado arriba de la barra, sin nivel ni fondo.
		if AsuriOn() then
			self.highLevelTexture:SetAlpha(0);
			self.nameBackground:SetAlpha(0);
			self.levelText:SetAlpha(0);
			if self.threatIndicator then self.threatIndicator:SetAlpha(0); end
			self.name:ClearAllPoints();
			self.name:SetPoint("CENTER", self, "CENTER", -50, 25);
			self.name:SetShadowOffset(1, -1);
			if self._nufNameFont then self.name:SetFontObject(self._nufNameFont); end

			self.healthbar:ClearAllPoints();
			self.healthbar:SetPoint("CENTER", self, "CENTER", -50, 7);
			self.healthbar:SetHeight(16);
			self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, 0);
			if self.deadText then
				self.deadText:ClearAllPoints();
				self.deadText:SetPoint("CENTER", self.healthbar, "CENTER", 0, 0);
			end

			self.manabar:ClearAllPoints();
			self.manabar:SetPoint("CENTER", self, "CENTER", -50, -7);
			if self.manabar.TextString then
				self.manabar.TextString:SetPoint("CENTER", self.manabar, "CENTER", 0, -1);
			end

			-- Fondo recortado al alto de vida+mana. Ademas hay que RE-ANCLARLO:
			-- solo achicarlo lo dejaba colgando del anclaje de arriba, asi que
			-- el rectangulo negro seguia tapando la fila del nombre. Anclado
			-- por abajo cubre exactamente las dos barras.
			local bg = _G[self:GetName() .. "Background"];
			if bg then
				bg:SetWidth(119);
				bg:SetHeight(30);
				bg:ClearAllPoints();
				bg:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 7, 35);
			end

			self.healthbar.lockColor = true;
			if C.statusbarOn then
				self.healthbar:SetStatusBarTexture(C.statusbarTexture);
				self.manabar:SetStatusBarTexture(C.statusbarTexture);
			end
			return;   -- el resto del look custom no aplica a Asuri
		end

		-- Saliendo de Asuri: devolver lo que Asuri habia apagado.
		local bgN = _G[self:GetName() .. "Background"];
		if bgN and bgN._nufOrig then
			local o = bgN._nufOrig;
			bgN:SetWidth(o.w);
			bgN:SetHeight(o.h);
			if o.pts and o.pts[1] then
				bgN:ClearAllPoints();
				bgN:SetPoint(o.pts[1], o.pts[2] or self, o.pts[3] or o.pts[1],
					o.pts[4] or 0, o.pts[5] or 0);
			end
		end
		if self.threatIndicator then self.threatIndicator:SetAlpha(1); end
		K.RestoreAnchors(self.manabar, keyBase.."ManaBarAnchors");

		-- Compact tampoco muestra el nivel. Va ACA, en la rama comun, y no
		-- dentro del bloque de Asuri: ese bloque ademas mueve el nombre,
		-- las barras y el fondo, y Compact solo quiere lo del nivel.
		local hideLevel = (C.UnitFrameCustomTexture and C.pwFrames);
		self.levelText:SetAlpha(hideLevel and 0 or 1);
		self.highLevelTexture:SetAlpha(hideLevel and 0 or 1);

		if self._nufNameFont then
			self.name:SetFontObject(self._nufNameFont);
			self.name:SetShadowOffset(1, -1);
		end

		self.healthbar:SetHeight(28);
		-- FIX: el look custom depende de un DOBLE anclaje: el TOPRIGHT default
		-- del XML (que el addon original nunca borra) + este TOPLEFT. Los dos
		-- juntos estiran la barra para llenar el marco .blp. Restaurar primero
		-- el/los anclaje(s) default asegura que el TOPRIGHT esté presente antes
		-- de sumar el TOPLEFT — sin esto, tras un toggle la barra queda con un
		-- solo anclaje y "flota" al costado (bug con Custom Positions).
		K.RestoreAnchors(self.healthbar, keyBase.."HealthBarAnchors");
		self.healthbar:SetPoint("TOPLEFT", 5, -24);
		self.healthbar.TextString:SetPoint("CENTER", self.healthbar, "CENTER", 0, -5);
	else
		-- FIX: restaurar TODO a default (capturado): geometría de barra,
		-- anclaje del texto de vida, anclaje del nombre y el fondo del nombre.
		K.RestoreBarGeometry(self.healthbar, keyBase.."HealthBar");
		K.RestoreAnchors(self.healthbar.TextString, keyBase.."HealthText");
		K.RestoreAnchors(self.name, keyBase.."Name");
		self.nameBackground:Show();
		-- Con el skin apagado tambien hay que devolver la fuente: si venias
		-- de Big Frames quedaba con la fuente chica de contorno.
		if self._nufNameFont then
			self.name:SetFontObject(self._nufNameFont);
			self.name:SetShadowOffset(1, -1);
		end
		TintBorder(self.borderTexture);
		-- Deshacer tambien lo que apaga Asuri
		local bgD = _G[self:GetName() .. "Background"];
		if bgD and bgD._nufOrig then
			local o = bgD._nufOrig;
			bgD:SetWidth(o.w);
			bgD:SetHeight(o.h);
			if o.pts and o.pts[1] then
				bgD:ClearAllPoints();
				bgD:SetPoint(o.pts[1], o.pts[2] or self, o.pts[3] or o.pts[1],
					o.pts[4] or 0, o.pts[5] or 0);
			end
		end
		self.highLevelTexture:SetAlpha(1);
		self.nameBackground:SetAlpha(1);
		self.levelText:SetAlpha(1);
		if self.threatIndicator then self.threatIndicator:SetAlpha(1); end
		K.RestoreAnchors(self.manabar, keyBase.."ManaBarAnchors");
	end
	
	self.healthbar.lockColor = true;
	if C.statusbarOn then
		self.healthbar:SetStatusBarTexture(C.statusbarTexture);
		self.manabar:SetStatusBarTexture(C.statusbarTexture);
	end;
end;

local function Nidhaus_UnitFrames_TargetFrame_CheckClassification(self, forceNormalTexture)
	local texture;
	local classification = UnitClassification(self.unit);

	-- ASURI: un unico marco; elite/rare se marcan con la cadena dorada.
	if AsuriOn() then
		self.borderTexture:SetTexture(ASURI.."AsuriFrame");
		self.borderTexture:SetVertexColor(0.25, 0.25, 0.25);
		return;
	end

	TintBorder(self.borderTexture);

	if classification == "worldboss" or classification == "elite" then
		texture = Path.."UI-TargetingFrame-Elite";
	elseif classification == "rareelite" then
		texture = Path.."UI-TargetingFrame-Rare-Elite";
	elseif classification == "rare" then
		texture = Path.."UI-TargetingFrame-Rare";
	end;
	if texture and not forceNormalTexture then
		self.borderTexture:SetTexture(texture);
	else
		self.borderTexture:SetTexture(Path.."UI-TargetingFrame");
	end;
end;

local function Nidhaus_UnitFrames_TargetFrame_CheckFaction(self)
	if self.showPVP then
		local factionGroup = UnitFactionGroup(self.unit);
		if UnitIsPVPFreeForAll(self.unit) then
			self.pvpIcon:SetTexture(Path.."UI-PVP-FFA");
			self.pvpIcon:Show();
		elseif factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(self.unit) then
			self.pvpIcon:SetTexture(Path.."UI-PVP-"..factionGroup);
			self.pvpIcon:Show();
		else
			self.pvpIcon:Hide();
		end;
	end;
end;

--	ToT & ToF
local function Nidhaus_UnitFrames_Style_ToTF(self)
	local name = self:GetName();
	local hb = _G[name.."HealthBar"];
	local mb = _G[name.."ManaBar"];
	local bg = self.background;
	-- Captura una vez la geometría default de ToT/ToF antes de pisarla
	K.CaptureBarGeometry(hb, name.."HB");
	K.CaptureBarGeometry(mb, name.."MB");
	K.CaptureAnchors(bg, name.."BG");

	_G[name.."TextureFrameTexture"]:SetTexture(Path.."UI-TargetofTargetFrame");
	self.deadText:ClearAllPoints();
	self.deadText:SetPoint("CENTER", name.."HealthBar", "CENTER", 1, 0);

	if C.UnitFrameCustomTexture then
		self.name:SetSize(65, 10);
		hb:ClearAllPoints();
		hb:SetPoint("TOPLEFT", 45, -15);
		hb:SetHeight(10);
		mb:ClearAllPoints();
		mb:SetPoint("TOPLEFT", 45, -25);
		mb:SetHeight(5);
		bg:SetSize(50, 14);
		bg:ClearAllPoints();
		bg:SetPoint("CENTER", self, "CENTER", 20, 0);
	else
		-- FIX: restaurar geometría default de Blizzard (capturada)
		K.RestoreBarGeometry(hb, name.."HB");
		K.RestoreBarGeometry(mb, name.."MB");
		K.RestoreAnchors(bg, name.."BG");
	end
end;

-- Focus frame
local function Nidhaus_UnitFrames_Style_FocusFrame()
	if C.FocusScale and type(C.FocusScale) == "number" and C.FocusScale > 0 and C.FocusScale <= 3 then
		FocusFrame:SetScale(C.FocusScale);
	end
	
	if C.FocusSpellBarScale and type(C.FocusSpellBarScale) == "number" and C.FocusSpellBarScale > 0 and C.FocusSpellBarScale <= 3 then
		FocusFrameSpellBar:SetScale(C.FocusSpellBarScale);
	end
	
	if C.FocusAuraLimit then
		FocusFrame.maxDebuffs = C.Focus_maxDebuffs or 0;
		FocusFrame.maxBuffs = C.Focus_maxBuffs or 0;
	end;
end;

--	Create Backdrop
local function ApplyBackdrop()
	if C.statusbarBackdrop then
		K.CreateBackdrop(TargetFrame);
		K.CreateBackdrop(FocusFrame);
	end
end

local function InitializeTargetFrame()
	if isInitialized then return; end
	
	-- Determinar path de texturas (custom on/off + tema Dark/Light)
	UpdatePath();
	
	-- Aplicar escala del Target Frame
	if C.TargetFrameScale and type(C.TargetFrameScale) == "number" and C.TargetFrameScale > 0 and C.TargetFrameScale <= 3 then
		TargetFrame:SetScale(C.TargetFrameScale);
	end
	
	-- Aplicar estilos
	Nidhaus_UnitFrames_Style_TargetFrame(TargetFrame);
	Nidhaus_UnitFrames_Style_TargetFrame(FocusFrame);
	
	-- Registrar hooks
	hooksecurefunc("TargetFrame_CheckClassification", Nidhaus_UnitFrames_TargetFrame_CheckClassification);
	hooksecurefunc("TargetFrame_CheckFaction", Nidhaus_UnitFrames_TargetFrame_CheckFaction);
	
	-- Aplicar estilos a ToT y ToF
	Nidhaus_UnitFrames_Style_ToTF(TargetFrameToT);
	Nidhaus_UnitFrames_Style_ToTF(FocusFrameToT);
	
	-- Aplicar estilos a Focus
	Nidhaus_UnitFrames_Style_FocusFrame();
	
	-- Aplicar backdrop
	ApplyBackdrop();
	
	isInitialized = true;
end

function K.ApplyTargetFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	TargetFrame:SetScale(scale);
end

function K.ApplyFocusFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	FocusFrame:SetScale(scale);
end

function K.ApplyFocusSpellBarScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	if FocusFrameSpellBar then
		FocusFrameSpellBar:SetScale(scale);
	end
end

-- FIX: Aplica el toggle "Custom Skin" a Target/Focus (+ ToT/ToF) en tiempo
-- real, sin /reload. Idempotente: cada rama deja un estado final fijo, así
-- togglear rápido siempre termina bien. Recalcula Path, re-corre el estilo
-- (barras/texto) y dispara las rutinas nativas de Blizzard para el marco/
-- ícono (nuestros hooks re-aplican o restauran según el checkbox).
local function RefreshTargetLikeFrame(frame)
	if not frame then return; end
	-- FIX: NO llamamos las funciones nativas de Blizzard directamente (ni el
	-- addon original lo hace — solo las hookea). En su lugar
	-- corremos NUESTRA propia lógica de marco/facción + estilo, que es lo
	-- mismo que aplican los hooks, pero sin riesgo de taint/side-effects por
	-- invocar código protegido de Blizzard fuera de su flujo normal.
	Nidhaus_UnitFrames_TargetFrame_CheckClassification(frame);
	Nidhaus_UnitFrames_TargetFrame_CheckFaction(frame);
	Nidhaus_UnitFrames_Style_TargetFrame(frame);
end

function K.ApplyTargetFrameSkin()
	if not isInitialized then return; end
	UpdatePath();
	RefreshTargetLikeFrame(TargetFrame);
	RefreshTargetLikeFrame(FocusFrame);
	Nidhaus_UnitFrames_Style_ToTF(TargetFrameToT);
	Nidhaus_UnitFrames_Style_ToTF(FocusFrameToT);
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	InitializeTargetFrame();
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if not isInitialized then return; end
	
	if C.TargetFrameScale then
		K.ApplyTargetFrameScale(C.TargetFrameScale);
	end
	
	if C.FocusScale then
		K.ApplyFocusFrameScale(C.FocusScale);
	end
	
	if C.FocusSpellBarScale then
		K.ApplyFocusSpellBarScale(C.FocusSpellBarScale);
	end
end);