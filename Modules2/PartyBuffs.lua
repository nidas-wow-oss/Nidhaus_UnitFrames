-- PartyBuffs
-- Muestra buffs/debuffs extendidos del grupo (slots 1-20)
-- Posiciones independientes por modo: Blizzard / NewPartyFrame
-- Offsets guardados en espacio LOCAL del party frame (compatibles con 3v3)
--
-- Comandos: /pbuffs unlock | /pbuffs lock | /pbuffs reset | /pbuffs status

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

PartyBuffsDB = PartyBuffsDB or {}

-- Migrar datos de GroupBuffsDB si existen
if GroupBuffsDB and not PartyBuffsDB._migrated then
	for k, v in pairs(GroupBuffsDB) do
		if PartyBuffsDB[k] == nil then PartyBuffsDB[k] = v; end
	end
	PartyBuffsDB._migrated = true;
end

------------------------------------------------------------------------
-- Defaults por modo (espacio LOCAL del frame — probados con Blizzard y NPF)
------------------------------------------------------------------------
local DEFAULTS_BLIZ = {
	buffs   = { x = 48,  y = -32 },
	debuffs = { x = -7,  y = 5   },
}
local DEFAULTS_NPF = {
	buffs   = { x = 44,  y = -37 },
	debuffs = { x = -7,  y = 5   },
}
local DEFAULTS_SHARED = {
	scale      = { buffs = 1.00, debuffs = 1.00 },
	panel      = { x = 220, y = 0 },
	maxBuffs   = 8,
	maxDebuffs = 10,
}

------------------------------------------------------------------------
-- Estado en runtime
------------------------------------------------------------------------
local pbEnabled   = false
local initialized = false
local boot
local auraEvts  = {}
local movers    = {}
local dragState = { debuffs = false, buffs = false }

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
local function CopyScale(src)
	return { buffs = tonumber(src.buffs) or 1, debuffs = tonumber(src.debuffs) or 1 }
end
local function CopyPanel(src)
	return { x = tonumber(src.x) or 0, y = tonumber(src.y) or 0 }
end
local function IsNPFActive()
	return K.IsNewPartyFrameActive and K.IsNewPartyFrameActive();
end
local function GetPartyAnchor()
	return _G["PartyMemberFrame1"]
end
-- Escala del frame1 — usada para convertir offsets locales a coordenadas de pantalla
local function GetPartyScale()
	local f1 = GetPartyAnchor();
	return (f1 and f1:GetScale()) or 1;
end

------------------------------------------------------------------------
-- ApplyDefaults — garantiza que todos los campos existen en la DB
------------------------------------------------------------------------
local function ApplyDefaults()
	if not PartyBuffsDB.blizBuffs   then PartyBuffsDB.blizBuffs   = { x=DEFAULTS_BLIZ.buffs.x,   y=DEFAULTS_BLIZ.buffs.y   } end
	if not PartyBuffsDB.blizDebuffs then PartyBuffsDB.blizDebuffs = { x=DEFAULTS_BLIZ.debuffs.x, y=DEFAULTS_BLIZ.debuffs.y } end
	if not PartyBuffsDB.npfBuffs    then PartyBuffsDB.npfBuffs    = { x=DEFAULTS_NPF.buffs.x,    y=DEFAULTS_NPF.buffs.y    } end
	if not PartyBuffsDB.npfDebuffs  then PartyBuffsDB.npfDebuffs  = { x=DEFAULTS_NPF.debuffs.x,  y=DEFAULTS_NPF.debuffs.y  } end
	if not PartyBuffsDB.scale       then PartyBuffsDB.scale       = { buffs=DEFAULTS_SHARED.scale.buffs, debuffs=DEFAULTS_SHARED.scale.debuffs } end
	if not PartyBuffsDB.panel       then PartyBuffsDB.panel       = { x=DEFAULTS_SHARED.panel.x, y=DEFAULTS_SHARED.panel.y } end
	if not PartyBuffsDB.maxBuffs    then PartyBuffsDB.maxBuffs    = DEFAULTS_SHARED.maxBuffs   end
	if not PartyBuffsDB.maxDebuffs  then PartyBuffsDB.maxDebuffs  = DEFAULTS_SHARED.maxDebuffs end

	-- Migrar formato plano (legado) → formato separado por modo
	if PartyBuffsDB.buffs and not PartyBuffsDB._storageMigrated then
		PartyBuffsDB.blizBuffs.x  = PartyBuffsDB.buffs.x   or DEFAULTS_BLIZ.buffs.x;
		PartyBuffsDB.blizBuffs.y  = PartyBuffsDB.buffs.y   or DEFAULTS_BLIZ.buffs.y;
		PartyBuffsDB.blizDebuffs.x = (PartyBuffsDB.debuffs and PartyBuffsDB.debuffs.x) or DEFAULTS_BLIZ.debuffs.x;
		PartyBuffsDB.blizDebuffs.y = (PartyBuffsDB.debuffs and PartyBuffsDB.debuffs.y) or DEFAULTS_BLIZ.debuffs.y;
		PartyBuffsDB.buffs   = nil;
		PartyBuffsDB.debuffs = nil;
		PartyBuffsDB._storageMigrated = true;
	end
end

------------------------------------------------------------------------
-- Getters según modo activo
------------------------------------------------------------------------
local function GetCurrentBuffs()
	ApplyDefaults();
	return IsNPFActive() and PartyBuffsDB.npfBuffs or PartyBuffsDB.blizBuffs;
end
local function GetCurrentDebuffs()
	ApplyDefaults();
	return IsNPFActive() and PartyBuffsDB.npfDebuffs or PartyBuffsDB.blizDebuffs;
end
local function GetCurrentDefaults()
	return IsNPFActive() and DEFAULTS_NPF or DEFAULTS_BLIZ;
end
local function GetMaxBuffs()
	ApplyDefaults();
	return tonumber(PartyBuffsDB.maxBuffs) or DEFAULTS_SHARED.maxBuffs;
end
local function GetMaxDebuffs()
	ApplyDefaults();
	return tonumber(PartyBuffsDB.maxDebuffs) or DEFAULTS_SHARED.maxDebuffs;
end

------------------------------------------------------------------------
-- ApplyScaleAll — aplica escala a todos los iconos visibles
------------------------------------------------------------------------
local function ApplyScaleAll(scaleTable)
	ApplyDefaults()
	local sb = tonumber(scaleTable and scaleTable.buffs)   or tonumber(PartyBuffsDB.scale.buffs)   or 1
	local sd = tonumber(scaleTable and scaleTable.debuffs) or tonumber(PartyBuffsDB.scale.debuffs) or 1
	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			for j = 1, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				local d = _G[f:GetName() .. "Debuff" .. j]
				if b and b.SetScale then b:SetScale(sb) end
				if d and d.SetScale then d:SetScale(sd) end
			end
		end
	end
end

------------------------------------------------------------------------
-- ReanchorAll — ancla Buff1/Debuff1 en espacio LOCAL del frame
-- WoW 3.3.5: SetPoint offsets son en el espacio de coordenadas del padre
-- del frame que se ancla. Buff1/Debuff1 son hijos de PartyMemberFrame,
-- por lo que los offsets van en el espacio local de ese frame.
-- Al guardar offsetX=48, un frame en escala 1.5 lo muestra como 72px.
-- Esto es el comportamiento correcto probado en la versión "copia".
------------------------------------------------------------------------
local function ReanchorAll()
	if not pbEnabled then return; end
	ApplyDefaults()

	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	local maxB    = GetMaxBuffs();
	local maxD    = GetMaxDebuffs();

	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			local d1 = _G[f:GetName() .. "Debuff1"]
			if d1 then
				d1:ClearAllPoints()
				d1:SetPoint("LEFT", f, "RIGHT", debuffs.x, debuffs.y)
			end
			local b1 = _G[f:GetName() .. "Buff1"]
			if b1 then
				b1:ClearAllPoints()
				b1:SetPoint("TOPLEFT", f, "TOPLEFT", buffs.x, buffs.y)
			end
			-- Ocultar iconos más allá del límite configurado
			for j = maxB + 1, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				if b then b:Hide() end
			end
			for j = maxD + 1, 20 do
				local d = _G[f:GetName() .. "Debuff" .. j]
				if d then d:Hide() end
			end
		end
	end
end

------------------------------------------------------------------------
-- Setup inicial de frames (ejecuta una sola vez)
------------------------------------------------------------------------
local function SetupFrames()
	if not pbEnabled then return end
	if initialized   then return end
	initialized = true

	ApplyDefaults()
	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	local maxB    = GetMaxBuffs();
	local maxD    = GetMaxDebuffs();

	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			-- Tomar control de UNIT_AURA para este frame
			f:UnregisterEvent("UNIT_AURA")

			local evt = CreateFrame("Frame")
			evt:RegisterEvent("UNIT_AURA")
			auraEvts[i] = evt
			evt:SetScript("OnEvent", function(self, event, unit)
				if not unit then return end
				if unit == f.unit then
					if RefreshDebuffs then
						RefreshDebuffs(f, unit, maxD, nil, 1)
					else
						PartyMemberFrame_RefreshDebuffs(f)
					end
					if RefreshBuffs then
						RefreshBuffs(f, unit, maxB, nil, 1)
					else
						PartyMemberFrame_RefreshBuffs(f)
					end
				elseif unit == f.unit .. "pet" then
					PartyMemberFrame_RefreshPetDebuffs(f)
				end
			end)

			-- Debuff1 posición inicial
			local d1 = _G[f:GetName() .. "Debuff1"]
			if d1 then
				d1:ClearAllPoints()
				d1:SetPoint("LEFT", f, "RIGHT", debuffs.x, debuffs.y)
			end

			-- Crear/anclar Debuffs 5 a maxD (2-4 los crea Blizzard)
			for j = 5, maxD do
				local prefix = f:GetName() .. "Debuff"
				local frame  = _G[prefix .. j] or CreateFrame("Frame", prefix .. j, f, "PartyDebuffFrameTemplate")
				frame:ClearAllPoints()
				frame:SetPoint("LEFT", _G[prefix .. (j-1)], "RIGHT")
			end

			-- Ocultar debuffs más allá del límite
			for j = maxD + 1, 20 do
				local frame = _G[f:GetName() .. "Debuff" .. j]
				if frame then frame:Hide() end
			end

			-- Crear/anclar Buffs 1 a maxB
			for j = 1, maxB do
				local prefix = f:GetName() .. "Buff"
				local frame  = _G[prefix .. j] or CreateFrame("Frame", prefix .. j, f, "TargetBuffFrameTemplate")
				frame:EnableMouse(false)
				frame:ClearAllPoints()
				if j == 1 then
					frame:SetPoint("TOPLEFT", f, "TOPLEFT", buffs.x, buffs.y)
				else
					frame:SetPoint("LEFT", _G[prefix .. (j-1)], "RIGHT", 1, 0)
				end
			end

			-- Ocultar buffs más allá del límite
			for j = maxB + 1, 20 do
				local frame = _G[f:GetName() .. "Buff" .. j]
				if frame then frame:Hide() end
			end
		end
	end
end

------------------------------------------------------------------------
-- Exports públicos
------------------------------------------------------------------------
function K.IsPartyBuffsActive()
	return pbEnabled;
end

K.PartyBuffs_ReanchorAll = function()
	if pbEnabled then
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
	end
end

-- Llamado desde Partymode3v3 después de reposicionar frames con nueva escala.
-- Re-ancla iconos y actualiza los movers si están visibles.
K.PartyBuffs_OnFramesMoved = function()
	if not pbEnabled then return end
	ReanchorAll()
	ApplyScaleAll(PartyBuffsDB.scale)

	-- Re-posicionar movers para reflejar la nueva escala del frame
	local f1 = GetPartyAnchor()
	if not f1 then return end
	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	local scale   = GetPartyScale();
	if movers.debuffs and movers.debuffs:IsShown() then
		movers.debuffs:ClearAllPoints()
		movers.debuffs:SetPoint("LEFT", f1, "RIGHT", debuffs.x * scale, debuffs.y * scale)
	end
	if movers.buffs and movers.buffs:IsShown() then
		movers.buffs:ClearAllPoints()
		movers.buffs:SetPoint("TOPLEFT", f1, "TOPLEFT", buffs.x * scale, buffs.y * scale)
	end
end

------------------------------------------------------------------------
-- FullReset — resetea posiciones + escala + max. Sin abrir menús.
------------------------------------------------------------------------
local function FullReset()
	ApplyDefaults()

	-- Resetear ambos modos siempre (para no dejar datos sucios en el modo inactivo)
	PartyBuffsDB.blizBuffs.x   = DEFAULTS_BLIZ.buffs.x;   PartyBuffsDB.blizBuffs.y   = DEFAULTS_BLIZ.buffs.y
	PartyBuffsDB.blizDebuffs.x = DEFAULTS_BLIZ.debuffs.x; PartyBuffsDB.blizDebuffs.y = DEFAULTS_BLIZ.debuffs.y
	PartyBuffsDB.npfBuffs.x    = DEFAULTS_NPF.buffs.x;    PartyBuffsDB.npfBuffs.y    = DEFAULTS_NPF.buffs.y
	PartyBuffsDB.npfDebuffs.x  = DEFAULTS_NPF.debuffs.x;  PartyBuffsDB.npfDebuffs.y  = DEFAULTS_NPF.debuffs.y

	PartyBuffsDB.scale      = { buffs=DEFAULTS_SHARED.scale.buffs, debuffs=DEFAULTS_SHARED.scale.debuffs }
	PartyBuffsDB.panel      = { x=DEFAULTS_SHARED.panel.x, y=DEFAULTS_SHARED.panel.y }
	PartyBuffsDB.maxBuffs   = DEFAULTS_SHARED.maxBuffs
	PartyBuffsDB.maxDebuffs = DEFAULTS_SHARED.maxDebuffs
end

------------------------------------------------------------------------
-- Movers
------------------------------------------------------------------------
local function CreateMoverFrame(name, label)
	local m = _G[name]
	if m then
		if m.text then m.text:SetText(label) end
		return m
	end
	m = CreateFrame("Frame", name, UIParent)
	m:SetSize(140, 16)
	m:SetFrameStrata("DIALOG")
	m:EnableMouse(true)
	m:SetMovable(true)
	m:RegisterForDrag("LeftButton")
	m:SetClampedToScreen(true)
	m:Hide()
	if m.SetBackdrop then
		m:SetBackdrop({
			bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile=true, tileSize=16, edgeSize=12,
			insets = { left=2, right=2, top=2, bottom=2 },
		})
		m:SetBackdropColor(0, 0, 0, 0.6)
	end
	local fs = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	fs:SetPoint("CENTER")
	fs:SetText(label)
	m.text = fs
	return m
end

-- Offsets locales → posición en pantalla (movers son hijos de UIParent)
-- Multiplicar por escala para convertir espacio local → pantalla
local function UpdateMoverPositions()
	local f1 = GetPartyAnchor()
	if not f1 then return end
	ApplyDefaults()
	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	local scale   = GetPartyScale();
	if movers.debuffs then
		movers.debuffs:ClearAllPoints()
		movers.debuffs:SetPoint("LEFT",    f1, "RIGHT",   debuffs.x * scale, debuffs.y * scale)
	end
	if movers.buffs then
		movers.buffs:ClearAllPoints()
		movers.buffs:SetPoint("TOPLEFT",   f1, "TOPLEFT", buffs.x   * scale, buffs.y   * scale)
	end
end

-- Posición pantalla del mover → offset LOCAL (dividir por escala)
local function ComputeDebuffOffsetsFromMover(mover)
	local f1 = GetPartyAnchor()
	if not f1 then local d = GetCurrentDefaults(); return d.debuffs.x, d.debuffs.y end
	local scale  = GetPartyScale();
	local ml = mover:GetLeft() or 0
	local _, mcy = mover:GetCenter(); mcy = mcy or 0
	local fr = f1:GetRight() or 0
	local _, fcy = f1:GetCenter(); fcy = fcy or 0
	return math.floor((ml  - fr)  / scale + 0.5),
	       math.floor((mcy - fcy) / scale + 0.5)
end

local function ComputeBuffOffsetsFromMover(mover)
	local f1 = GetPartyAnchor()
	if not f1 then local d = GetCurrentDefaults(); return d.buffs.x, d.buffs.y end
	local scale = GetPartyScale();
	local ml = mover:GetLeft() or 0
	local mt = mover:GetTop()  or 0
	local fl = f1:GetLeft()    or 0
	local ft = f1:GetTop()     or 0
	return math.floor((ml - fl) / scale + 0.5),
	       math.floor((mt - ft) / scale + 0.5)
end

local function StartRealtime(mover, which)
	mover._pb_elapsed = 0
	mover:SetScript("OnUpdate", function(self, elapsed)
		self._pb_elapsed = (self._pb_elapsed or 0) + elapsed
		if self._pb_elapsed < 0.03 then return end
		self._pb_elapsed = 0
		if which == "debuffs" then
			local s = GetCurrentDebuffs();
			s.x, s.y = ComputeDebuffOffsetsFromMover(self)
		else
			local s = GetCurrentBuffs();
			s.x, s.y = ComputeBuffOffsetsFromMover(self)
		end
		ReanchorAll()
	end)
end

local function StopRealtime(mover)
	mover:SetScript("OnUpdate", nil)
	mover._pb_elapsed = nil
end

local function CreateMovers()
	local f1 = GetPartyAnchor()
	if not f1 then
		print("|cff66CCFFPartyBuffs:|r PartyMemberFrame1 no disponible. Usa /reload.")
		return
	end
	ApplyDefaults()

	if not movers.debuffs then movers.debuffs = CreateMoverFrame("PartyBuffsDebuffMover", "Debuffs (drag)") end
	if not movers.buffs   then movers.buffs   = CreateMoverFrame("PartyBuffsBuffMover",   "Buffs (drag)")   end

	UpdateMoverPositions()

	movers.debuffs:SetScript("OnDragStart", function(self)
		dragState.debuffs = true; self:ClearAllPoints(); self:StartMoving(); StartRealtime(self, "debuffs")
	end)
	movers.debuffs:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing(); StopRealtime(self); dragState.debuffs = false
		local s = GetCurrentDebuffs(); s.x, s.y = ComputeDebuffOffsetsFromMover(self)
		ReanchorAll(); UpdateMoverPositions()
	end)
	movers.buffs:SetScript("OnDragStart", function(self)
		dragState.buffs = true; self:ClearAllPoints(); self:StartMoving(); StartRealtime(self, "buffs")
	end)
	movers.buffs:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing(); StopRealtime(self); dragState.buffs = false
		local s = GetCurrentBuffs(); s.x, s.y = ComputeBuffOffsetsFromMover(self)
		ReanchorAll(); UpdateMoverPositions()
	end)
end

local function ShowMovers(show)
	if movers.debuffs then if show then movers.debuffs:Show() else movers.debuffs:Hide() end end
	if movers.buffs   then if show then movers.buffs:Show()   else movers.buffs:Hide()   end end
end

------------------------------------------------------------------------
-- Panel Scale/Max — layout mejorado con botones bien separados
--
--  ┌─────────────────────────────────┐  ← drag header (18px)
--  │ Party Buffs  Scale / Max         │
--  ├─────────────────────────────────┤
--  │ Scale icons:                    │  y = -24
--  │  Buffs   [==========] 1.00      │  y = -40
--  │  Debuffs [==========] 1.00      │  y = -62
--  ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│  sep y = -84
--  │ Max icons:                      │  y = -90
--  │  Buffs   [==========] 8         │  y = -106
--  │  Debuffs [==========] 10        │  y = -128
--  ├─────────────────────────────────┤  sep y = -150
--  │ [ Reset ]         [ Save ]      │  bottom = 8
--  └─────────────────────────────────┘  altura total: 178px
------------------------------------------------------------------------
local scalePanel
local runtimeScale
local runtimePanel

local function LockUI()
	ShowMovers(false)
	if scalePanel and scalePanel:IsShown() then scalePanel:Hide() end
end

local function EnsureScalePanel()
	if scalePanel then return end

	scalePanel = CreateFrame("Frame", "PB_ScalePanel", UIParent)
	scalePanel:SetSize(300, 178)
	scalePanel:SetFrameStrata("DIALOG")
	scalePanel:SetClampedToScreen(true)
	scalePanel:EnableMouse(true)
	scalePanel:SetMovable(true)
	scalePanel:Hide()

	if scalePanel.SetBackdrop then
		scalePanel:SetBackdrop({
			bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile=true, tileSize=16, edgeSize=12,
			insets = { left=3, right=3, top=3, bottom=3 },
		})
		scalePanel:SetBackdropColor(0, 0, 0, 0.80)
	end

	-- Header arrastrable
	local header = CreateFrame("Frame", nil, scalePanel)
	header:SetPoint("TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", 0, 0)
	header:SetHeight(18)
	header:EnableMouse(true)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function() scalePanel:StartMoving() end)
	header:SetScript("OnDragStop", function()
		scalePanel:StopMovingOrSizing()
		local f1 = GetPartyAnchor()
		if not f1 or not runtimePanel then return end
		-- Guardar en espacio local (dividir por escala, igual que offsets de buffs/debuffs)
		local scale = GetPartyScale();
		runtimePanel.x = math.floor(((scalePanel:GetLeft() or 0) - (f1:GetRight() or 0)) / scale + 0.5)
		runtimePanel.y = math.floor(((scalePanel:GetTop()  or 0) - (f1:GetTop()   or 0)) / scale + 0.5)
	end)

	local titleFS = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	titleFS:SetPoint("TOPLEFT", 8, -4)
	titleFS:SetText("|cff66CCFFParty Buffs|r  Scale / Max")

	-- Separador bajo header
	local sep0 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep0:SetTexture(1, 1, 1, 0.12)
	sep0:SetPoint("TOPLEFT", 4, -18); sep0:SetPoint("TOPRIGHT", -4, -18); sep0:SetHeight(1)

	-- Helper genérico de fila
	local function MakeRow(yOff, labelTxt, sliderName, minV, maxV, step, isInt, onChangeFn)
		local lbl = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		lbl:SetPoint("TOPLEFT", 10, yOff)
		lbl:SetText(labelTxt)
		lbl:SetWidth(55)

		local s = CreateFrame("Slider", sliderName, scalePanel, "OptionsSliderTemplate")
		s:SetWidth(150); s:SetHeight(14)
		s:SetPoint("TOPLEFT", 68, yOff + 1)
		s:SetMinMaxValues(minV, maxV)
		s:SetValueStep(step)

		local sL = _G[sliderName.."Low"]; local sH = _G[sliderName.."High"]; local sT = _G[sliderName.."Text"]
		if sL then sL:SetText("") sL:Hide() end
		if sH then sH:SetText("") sH:Hide() end
		if sT then sT:SetText("") sT:Hide() end

		local valFS = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		valFS:SetPoint("LEFT", s, "RIGHT", 6, 0)
		valFS:SetText(isInt and tostring(math.floor(minV)) or "1.00")
		valFS:SetWidth(30)
		s._valFS = valFS

		s:SetScript("OnValueChanged", function(self, val)
			val = math.floor(val / step + 0.5) * step
			if isInt then
				val = math.floor(val + 0.5)
				valFS:SetText(tostring(val))
			else
				val = tonumber(string.format("%.2f", val)) or 1
				valFS:SetText(string.format("%.2f", val))
			end
			if onChangeFn then onChangeFn(val) end
		end)
		return s
	end

	-- ── Sección Scale ──────────────────────────────────────────────────────
	local lblScale = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lblScale:SetPoint("TOPLEFT", 10, -24); lblScale:SetText("|cffaaaaaaScale icons:|r")

	scalePanel.buffSlider = MakeRow(-40, "Buffs", "PB_BuffScaleSlider", 0.5, 2.0, 0.1, false,
		function(v) if runtimeScale then runtimeScale.buffs   = v; ApplyScaleAll(runtimeScale) end end)
	scalePanel.debuffSlider = MakeRow(-62, "Debuffs", "PB_DebuffScaleSlider", 0.5, 2.0, 0.1, false,
		function(v) if runtimeScale then runtimeScale.debuffs = v; ApplyScaleAll(runtimeScale) end end)

	-- Separador entre secciones
	local sep1 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep1:SetTexture(1, 1, 1, 0.08)
	sep1:SetPoint("TOPLEFT", 4, -84); sep1:SetPoint("TOPRIGHT", -4, -84); sep1:SetHeight(1)

	-- ── Sección Max Icons ──────────────────────────────────────────────────
	local lblMax = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lblMax:SetPoint("TOPLEFT", 10, -90); lblMax:SetText("|cffaaaaaaMax icons:|r")

	scalePanel.maxBuffSlider = MakeRow(-106, "Buffs", "PB_MaxBuffSlider", 1, 20, 1, true,
		function(v) ApplyDefaults(); PartyBuffsDB.maxBuffs   = v; ReanchorAll() end)
	scalePanel.maxDebuffSlider = MakeRow(-128, "Debuffs", "PB_MaxDebuffSlider", 1, 20, 1, true,
		function(v) ApplyDefaults(); PartyBuffsDB.maxDebuffs = v; ReanchorAll() end)

	-- Separador antes de botones
	local sep2 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep2:SetTexture(1, 1, 1, 0.12)
	sep2:SetPoint("BOTTOMLEFT", 4, 38); sep2:SetPoint("BOTTOMRIGHT", -4, 38); sep2:SetHeight(1)

	-- ── Botones: bien separados (izquierda y derecha del panel) ───────────
	local resetBtn = CreateFrame("Button", nil, scalePanel, "UIPanelButtonTemplate")
	resetBtn:SetSize(95, 22)
	resetBtn:SetPoint("BOTTOMLEFT", 8, 8)
	resetBtn:SetText("Reset")
	resetBtn:SetScript("OnClick", function()
		FullReset()
		if runtimeScale then runtimeScale.buffs = DEFAULTS_SHARED.scale.buffs; runtimeScale.debuffs = DEFAULTS_SHARED.scale.debuffs end
		if runtimePanel then runtimePanel.x = DEFAULTS_SHARED.panel.x; runtimePanel.y = DEFAULTS_SHARED.panel.y end
		scalePanel.buffSlider:SetValue(DEFAULTS_SHARED.scale.buffs)
		scalePanel.debuffSlider:SetValue(DEFAULTS_SHARED.scale.debuffs)
		scalePanel.maxBuffSlider:SetValue(DEFAULTS_SHARED.maxBuffs)
		scalePanel.maxDebuffSlider:SetValue(DEFAULTS_SHARED.maxDebuffs)
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
		if movers.buffs or movers.debuffs then UpdateMoverPositions() end
		print("|cff66CCFFPartyBuffs:|r Posiciones y escala reseteadas.")
	end)

	local saveBtn = CreateFrame("Button", nil, scalePanel, "UIPanelButtonTemplate")
	saveBtn:SetSize(95, 22)
	saveBtn:SetPoint("BOTTOMRIGHT", -8, 8)
	saveBtn:SetText("Save")
	saveBtn:SetScript("OnClick", function()
		ApplyDefaults()
		if runtimeScale then PartyBuffsDB.scale.buffs = runtimeScale.buffs; PartyBuffsDB.scale.debuffs = runtimeScale.debuffs end
		if runtimePanel then PartyBuffsDB.panel.x = runtimePanel.x; PartyBuffsDB.panel.y = runtimePanel.y end
		ApplyScaleAll(PartyBuffsDB.scale)
		LockUI()
		print("|cff66CCFFPartyBuffs:|r Configuración guardada.")
	end)
end

local function PlaceScalePanelFromDB()
	local f1 = GetPartyAnchor()
	if not f1 then
		scalePanel:ClearAllPoints(); scalePanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		return
	end
	ApplyDefaults()
	local scale = GetPartyScale();
	local ox = tonumber(PartyBuffsDB.panel.x) or DEFAULTS_SHARED.panel.x
	local oy = tonumber(PartyBuffsDB.panel.y) or DEFAULTS_SHARED.panel.y
	-- panel.x/y en espacio local → multiplicar por escala para pantalla
	scalePanel:ClearAllPoints()
	scalePanel:SetPoint("TOPLEFT", f1, "TOPRIGHT", ox * scale, oy * scale)
end

local function ShowScalePanel(show)
	EnsureScalePanel()
	ApplyDefaults()
	if not show then
		if scalePanel:IsShown() then scalePanel:Hide() end
		runtimeScale = nil; runtimePanel = nil
		return
	end
	runtimeScale = CopyScale(PartyBuffsDB.scale)
	runtimePanel = CopyPanel(PartyBuffsDB.panel)
	PlaceScalePanelFromDB()
	scalePanel.buffSlider:SetValue(runtimeScale.buffs)
	scalePanel.debuffSlider:SetValue(runtimeScale.debuffs)
	scalePanel.maxBuffSlider:SetValue(GetMaxBuffs())
	scalePanel.maxDebuffSlider:SetValue(GetMaxDebuffs())
	scalePanel:Show()
end

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
-- FIX: Changed from /pb to /pbuffs to avoid conflict with PlateBuffs addon
SLASH_PARTYBUFFS1 = "/pbuffs"
SLASH_PARTYBUFFS2 = "/partybuffs"
SlashCmdList["PARTYBUFFS"] = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")

	if msg == "unlock" then
		CreateMovers()
		ShowMovers(true)
		ShowScalePanel(true)
		local mode = IsNPFActive() and "NPF" or "Blizzard"
		print("|cff66CCFFPartyBuffs:|r Desbloqueado (modo " .. mode .. "). /pbuffs lock para cerrar.")

	elseif msg == "lock" then
		LockUI()
		print("|cff66CCFFPartyBuffs:|r Bloqueado.")

	elseif msg == "reset" then
		-- Reset silencioso: solo resetea datos y reaplica, SIN abrir ningún menú
		FullReset()
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
		-- Si el panel está abierto, actualizar sus sliders (sin abrirlo si estaba cerrado)
		if scalePanel and scalePanel:IsShown() then
			if runtimeScale then
				runtimeScale.buffs   = DEFAULTS_SHARED.scale.buffs
				runtimeScale.debuffs = DEFAULTS_SHARED.scale.debuffs
			end
			scalePanel.buffSlider:SetValue(DEFAULTS_SHARED.scale.buffs)
			scalePanel.debuffSlider:SetValue(DEFAULTS_SHARED.scale.debuffs)
			scalePanel.maxBuffSlider:SetValue(DEFAULTS_SHARED.maxBuffs)
			scalePanel.maxDebuffSlider:SetValue(DEFAULTS_SHARED.maxDebuffs)
			UpdateMoverPositions()
		end
		print("|cff66CCFFPartyBuffs:|r Reset completado. Posiciones y escala restauradas.")

	elseif msg == "status" then
		ApplyDefaults()
		local mode    = IsNPFActive() and "NPF" or "Blizzard"
		local buffs   = GetCurrentBuffs();
		local debuffs = GetCurrentDebuffs();
		local f1 = GetPartyAnchor(); local f3 = _G["PartyMemberFrame3"]
		print(string.format("|cff66CCFFPartyBuffs|r — Modo: %s | Activo: %s", mode, tostring(pbEnabled)))
		print(string.format("  Buffs   → x=%.0f y=%.0f | scale=%.2f | max=%d",
			buffs.x, buffs.y, PartyBuffsDB.scale.buffs, GetMaxBuffs()))
		print(string.format("  Debuffs → x=%.0f y=%.0f | scale=%.2f | max=%d",
			debuffs.x, debuffs.y, PartyBuffsDB.scale.debuffs, GetMaxDebuffs()))
		print(string.format("  Frame1 scale=%.2f | Frame3 scale=%.2f",
			f1 and (f1:GetScale() or 1) or 0,
			f3 and (f3:GetScale() or 1) or 0))
	else
		print("|cff66CCFFPartyBuffs:|r Comandos disponibles:")
		print("  /pbuffs unlock  — Abre movers (drag) y panel de ajuste")
		print("  /pbuffs lock    — Cierra movers y panel")
		print("  /pbuffs reset   — Restaura posiciones y escala por defecto")
		print("  /pbuffs status  — Muestra estado actual en el chat")
	end
end

------------------------------------------------------------------------
-- Enable / Disable
------------------------------------------------------------------------
local function PB_Enable()
	if pbEnabled then return end
	pbEnabled = true

	ApplyDefaults()
	SetupFrames()
	ReanchorAll()
	ApplyScaleAll(PartyBuffsDB.scale)

	if K.UpdateNewPartyFrames then K.UpdateNewPartyFrames(); end

	if not boot then boot = CreateFrame("Frame") end
	boot:UnregisterAllEvents()
	boot:RegisterEvent("PLAYER_ENTERING_WORLD")
	boot:RegisterEvent("PARTY_MEMBERS_CHANGED")
	pcall(boot.RegisterEvent, boot, "GROUP_ROSTER_UPDATE")
	boot:SetScript("OnEvent", function(self, event)
		if not pbEnabled then return end
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
		if (movers.debuffs or movers.buffs) and not dragState.debuffs and not dragState.buffs then
			UpdateMoverPositions()
		end
	end)
end

local function PB_Disable()
	if not pbEnabled then return end
	pbEnabled = false

	if boot then boot:UnregisterAllEvents(); boot:SetScript("OnEvent", nil) end

	LockUI()

	for i, evt in pairs(auraEvts) do
		if evt then evt:UnregisterAllEvents(); evt:SetScript("OnEvent", nil); evt:Hide() end
		auraEvts[i] = nil
	end

	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			f:RegisterEvent("UNIT_AURA")

			for j = 5, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				local d = _G[f:GetName() .. "Debuff" .. j]
				if b then b:Hide() end
				if d then d:Hide() end
			end
			for j = 1, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				local d = _G[f:GetName() .. "Debuff" .. j]
				if b and b.SetScale then b:SetScale(1) end
				if d and d.SetScale then d:SetScale(1) end
			end

			local d1 = _G[f:GetName() .. "Debuff1"]
			if d1 then d1:ClearAllPoints(); d1:SetPoint("LEFT", f, "RIGHT", 5, 0) end

			local b1 = _G[f:GetName() .. "Buff1"]
			if b1 then b1:ClearAllPoints(); b1:SetPoint("TOPLEFT", f, "TOPLEFT", 48, -32) end

			if f.unit and UnitExists(f.unit) then
				if PartyMemberFrame_RefreshDebuffs then pcall(PartyMemberFrame_RefreshDebuffs, f) end
				if PartyMemberFrame_RefreshBuffs   then pcall(PartyMemberFrame_RefreshBuffs, f)   end
			end
		end
	end

	initialized = false
	if K.UpdateNewPartyFrames then K.UpdateNewPartyFrames(); end
end

------------------------------------------------------------------------
-- Registro del módulo
------------------------------------------------------------------------
K.RegisterModule("PartyBuffs", {
	name    = "Party Buffs",
	desc    = "Buffs/debuffs extendidos (1-20 iconos) en frames de grupo. /pbuffs unlock | /pbuffs reset",
	default = true,
	onEnable  = PB_Enable,
	onDisable = PB_Disable,
	hideFromModulesTab = true,
})