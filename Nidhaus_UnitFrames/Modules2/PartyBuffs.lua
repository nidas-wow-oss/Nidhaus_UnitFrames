









local AddOnName, ns = ...;
local K, C, L = unpack(ns);

PartyBuffsDB = PartyBuffsDB or {}


if GroupBuffsDB and not PartyBuffsDB._migrated then
	for k, v in pairs(GroupBuffsDB) do
		if PartyBuffsDB[k] == nil then PartyBuffsDB[k] = v; end
	end
	PartyBuffsDB._migrated = true;
end




local DEFAULTS_BLIZ = {
	buffs   = { x = 48,  y = -32 },
	debuffs = { x = -7,  y = 5   },
}
local DEFAULTS_NPF = {
	buffs   = { x = 44,  y = -37 },
	debuffs = { x = -7,  y = 5   },
}









local DEFAULTS_IMP = {
	buffs   = { x = 48,  y = -30 },
	debuffs = { x = -7,  y = 5   },
}







local DEFAULTS_PW = {
	buffs   = { x = 48,  y = -32 },
	debuffs = { x = -7,  y = 5   },
}
local DEFAULTS_PW2 = {
	buffs   = { x = 33,  y = -37 },
	debuffs = { x = -28, y = 10  },
}
local DEFAULTS_SHARED = {
	scale      = { buffs = 1.00, debuffs = 1.00 },
	panel      = { x = 220, y = 0 },
	maxBuffs   = 8,
	maxDebuffs = 10,
}




local pbEnabled   = false
local initialized = false
local boot
local auraEvts  = {}
local movers    = {}








local origAnchors = {}




local UpdateMoverPositions
local dragState = { debuffs = false, buffs = false }




local function CopyScale(src)
	return { buffs = tonumber(src.buffs) or 1, debuffs = tonumber(src.debuffs) or 1 }
end
local function CopyPanel(src)


	src = src or {}
	return {
		point         = src.point,
		relativePoint = src.relativePoint,
		x             = tonumber(src.x) or 0,
		y             = tonumber(src.y) or 0,
	}
end
local function IsNPFActive()
	return K.IsNewPartyFrameActive and K.IsNewPartyFrameActive();
end




local function StyleKey()
	local style = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or nil;
	if style == "Improved" then return "imp"; end
	if style == "New" then return "npf"; end
	if style == "PW" then return "pw"; end
	if style == "PW2" then return "pw2"; end
	if style == "Default" then return "bliz"; end

	return IsNPFActive() and "npf" or "bliz";
end
local function GetPartyAnchor()
	return _G["PartyMemberFrame1"]
end













local function ApplyDefaults()
	if not PartyBuffsDB.blizBuffs   then PartyBuffsDB.blizBuffs   = { x=DEFAULTS_BLIZ.buffs.x,   y=DEFAULTS_BLIZ.buffs.y   } end
	if not PartyBuffsDB.blizDebuffs then PartyBuffsDB.blizDebuffs = { x=DEFAULTS_BLIZ.debuffs.x, y=DEFAULTS_BLIZ.debuffs.y } end
	if not PartyBuffsDB.npfBuffs    then PartyBuffsDB.npfBuffs    = { x=DEFAULTS_NPF.buffs.x,    y=DEFAULTS_NPF.buffs.y    } end
	if not PartyBuffsDB.npfDebuffs  then PartyBuffsDB.npfDebuffs  = { x=DEFAULTS_NPF.debuffs.x,  y=DEFAULTS_NPF.debuffs.y  } end
	if not PartyBuffsDB.impBuffs    then PartyBuffsDB.impBuffs    = { x=DEFAULTS_IMP.buffs.x,    y=DEFAULTS_IMP.buffs.y    } end
	if not PartyBuffsDB.impDebuffs  then PartyBuffsDB.impDebuffs  = { x=DEFAULTS_IMP.debuffs.x,  y=DEFAULTS_IMP.debuffs.y  } end
	if not PartyBuffsDB.pwBuffs     then PartyBuffsDB.pwBuffs     = { x=DEFAULTS_PW.buffs.x,     y=DEFAULTS_PW.buffs.y     } end
	if not PartyBuffsDB.pwDebuffs   then PartyBuffsDB.pwDebuffs   = { x=DEFAULTS_PW.debuffs.x,   y=DEFAULTS_PW.debuffs.y   } end
	if not PartyBuffsDB.pw2Buffs    then PartyBuffsDB.pw2Buffs    = { x=DEFAULTS_PW2.buffs.x,    y=DEFAULTS_PW2.buffs.y    } end
	if not PartyBuffsDB.pw2Debuffs  then PartyBuffsDB.pw2Debuffs  = { x=DEFAULTS_PW2.debuffs.x,  y=DEFAULTS_PW2.debuffs.y  } end
	if not PartyBuffsDB.scale       then PartyBuffsDB.scale       = { buffs=DEFAULTS_SHARED.scale.buffs, debuffs=DEFAULTS_SHARED.scale.debuffs } end
	if not PartyBuffsDB.panel       then PartyBuffsDB.panel       = { x=DEFAULTS_SHARED.panel.x, y=DEFAULTS_SHARED.panel.y } end
	if not PartyBuffsDB.maxBuffs    then PartyBuffsDB.maxBuffs    = DEFAULTS_SHARED.maxBuffs   end
	if not PartyBuffsDB.maxDebuffs  then PartyBuffsDB.maxDebuffs  = DEFAULTS_SHARED.maxDebuffs end


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




local BUFFS_BY_STYLE   = { bliz = "blizBuffs",   npf = "npfBuffs",   imp = "impBuffs",   pw = "pwBuffs",   pw2 = "pw2Buffs"   };
local DEBUFFS_BY_STYLE = { bliz = "blizDebuffs", npf = "npfDebuffs", imp = "impDebuffs", pw = "pwDebuffs", pw2 = "pw2Debuffs" };
local DEFAULTS_BY_STYLE = { bliz = DEFAULTS_BLIZ, npf = DEFAULTS_NPF, imp = DEFAULTS_IMP, pw = DEFAULTS_PW, pw2 = DEFAULTS_PW2 };

local function GetCurrentBuffs()
	ApplyDefaults();
	return PartyBuffsDB[BUFFS_BY_STYLE[StyleKey()] or "blizBuffs"];
end
local function GetCurrentDebuffs()
	ApplyDefaults();
	return PartyBuffsDB[DEBUFFS_BY_STYLE[StyleKey()] or "blizDebuffs"];
end
local function GetCurrentDefaults()
	return DEFAULTS_BY_STYLE[StyleKey()] or DEFAULTS_BLIZ;
end









local function GetMaxBuffs()
	ApplyDefaults();
	return tonumber(PartyBuffsDB.maxBuffs) or DEFAULTS_SHARED.maxBuffs;
end
local function GetMaxDebuffs()
	ApplyDefaults();
	return tonumber(PartyBuffsDB.maxDebuffs) or DEFAULTS_SHARED.maxDebuffs;
end


local function ShowBuffs()   return PartyBuffsDB.showBuffs   ~= false; end
local function ShowDebuffs() return PartyBuffsDB.showDebuffs ~= false; end





local function RestoreOrigAnchor(i, f, which)
	local o = origAnchors[i];
	if which == "debuff" then
		local d1 = _G[f:GetName() .. "Debuff1"];
		if d1 then
			d1:ClearAllPoints();
			if o and o.debuff and o.debuff[1] then
				local pt, rel, rp, x, y = unpack(o.debuff);
				d1:SetPoint(pt, rel or f, rp or pt, x or 0, y or 0);
			else
				d1:SetPoint("LEFT", f, "RIGHT", 5, 0);
			end
		end
	else
		local b1 = _G[f:GetName() .. "Buff1"];
		if b1 then
			b1:ClearAllPoints();
			if o and o.buff and o.buff[1] then
				local pt, rel, rp, x, y = unpack(o.buff);
				b1:SetPoint(pt, rel or f, rp or pt, x or 0, y or 0);
			else
				b1:SetPoint("TOPLEFT", f, "TOPLEFT", 48, -32);
			end
		end
	end
end




local function EnsureAuraFrames(f)
	local maxB, maxD = GetMaxBuffs(), GetMaxDebuffs();
	local dPrefix = f:GetName() .. "Debuff";
	for j = 5, maxD do
		local frame = _G[dPrefix .. j] or CreateFrame("Frame", dPrefix .. j, f, "PartyDebuffFrameTemplate");
		frame:ClearAllPoints();
		frame:SetPoint("LEFT", _G[dPrefix .. (j-1)], "RIGHT");
	end
	local bPrefix = f:GetName() .. "Buff";
	for j = 1, maxB do
		local frame = _G[bPrefix .. j];
		if not frame then
			frame = CreateFrame("Frame", bPrefix .. j, f, "TargetBuffFrameTemplate");
			frame:EnableMouse(false);
		end
		if j > 1 then
			frame:ClearAllPoints();
			frame:SetPoint("LEFT", _G[bPrefix .. (j-1)], "RIGHT", 1, 0);
		end
	end
end




local function RefreshFrameAuras(f)
	local unit = f.unit;
	if not unit or not UnitExists(unit) then return; end
	if ShowDebuffs() then
		if RefreshDebuffs then
			RefreshDebuffs(f, unit, GetMaxDebuffs(), nil, 1);
		else
			PartyMemberFrame_RefreshDebuffs(f);
		end
	else
		PartyMemberFrame_RefreshDebuffs(f);
	end
	if ShowBuffs() then
		if RefreshBuffs then
			RefreshBuffs(f, unit, GetMaxBuffs(), nil, 1);
		elseif PartyMemberFrame_RefreshBuffs then
			PartyMemberFrame_RefreshBuffs(f);
		end
	else
		for j = 1, 20 do
			local bf = _G[f:GetName() .. "Buff" .. j];
			if bf then bf:Hide(); end
		end
	end
end

local function RefreshAllAuras()
	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i];
		if f then RefreshFrameAuras(f); end
	end
end




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
				if b and b.SetScale then b:SetScale(ShowBuffs() and sb or 1) end
				if d and d.SetScale then d:SetScale(ShowDebuffs() and sd or 1) end
			end
		end
	end
end









local function ReanchorAll()
	if not pbEnabled then return; end
	ApplyDefaults()

	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	local maxB    = GetMaxBuffs();
	local maxD    = GetMaxDebuffs();

	local doB, doD = ShowBuffs(), ShowDebuffs()

	for i = 1, 4 do
		local f = _G["PartyMemberFrame" .. i]
		if f then
			EnsureAuraFrames(f)


			if doD then
				local d1 = _G[f:GetName() .. "Debuff1"]
				if d1 then
					d1:ClearAllPoints()
					d1:SetPoint("LEFT", f, "RIGHT", debuffs.x, debuffs.y)
				end
			end
			if doB then
				local b1 = _G[f:GetName() .. "Buff1"]
				if b1 then
					b1:ClearAllPoints()
					b1:SetPoint("TOPLEFT", f, "TOPLEFT", buffs.x, buffs.y)
				end
			end


			for j = (doB and maxB or 0) + 1, 20 do
				local b = _G[f:GetName() .. "Buff"   .. j]
				if b then b:Hide() end
			end
			for j = (doD and maxD or 4) + 1, 20 do
				local d = _G[f:GetName() .. "Debuff" .. j]
				if d then d:Hide() end
			end
		end
	end
end




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

			f:UnregisterEvent("UNIT_AURA")

			local evt = CreateFrame("Frame")
			evt:RegisterEvent("UNIT_AURA")
			auraEvts[i] = evt
			evt:SetScript("OnEvent", function(self, event, unit)
				if not unit then return end
				if unit == f.unit then
					RefreshFrameAuras(f)
				elseif unit == f.unit .. "pet" then
					PartyMemberFrame_RefreshPetDebuffs(f)
				end
			end)




			if not origAnchors[i] then
				local o = {}
				local d0 = _G[f:GetName() .. "Debuff1"]
				local b0 = _G[f:GetName() .. "Buff1"]
				if d0 and d0:GetNumPoints() > 0 then
					o.debuff = { d0:GetPoint(1) }
				end
				if b0 and b0:GetNumPoints() > 0 then
					o.buff = { b0:GetPoint(1) }
				end
				origAnchors[i] = o
			end




			EnsureAuraFrames(f)
		end
	end
end




function K.IsPartyBuffsActive()
	return pbEnabled;
end

K.PartyBuffs_ReanchorAll = function()
	if pbEnabled then
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
	end
end



K.PartyBuffs_OnFramesMoved = function()
	if not pbEnabled then return end
	ReanchorAll()
	ApplyScaleAll(PartyBuffsDB.scale)




	if (movers.debuffs and movers.debuffs:IsShown())
		or (movers.buffs and movers.buffs:IsShown()) then
		UpdateMoverPositions()
	end
end




local function FullReset()
	ApplyDefaults()



	PartyBuffsDB.blizBuffs.x   = DEFAULTS_BLIZ.buffs.x;   PartyBuffsDB.blizBuffs.y   = DEFAULTS_BLIZ.buffs.y
	PartyBuffsDB.blizDebuffs.x = DEFAULTS_BLIZ.debuffs.x; PartyBuffsDB.blizDebuffs.y = DEFAULTS_BLIZ.debuffs.y
	PartyBuffsDB.npfBuffs.x    = DEFAULTS_NPF.buffs.x;    PartyBuffsDB.npfBuffs.y    = DEFAULTS_NPF.buffs.y
	PartyBuffsDB.npfDebuffs.x  = DEFAULTS_NPF.debuffs.x;  PartyBuffsDB.npfDebuffs.y  = DEFAULTS_NPF.debuffs.y
	PartyBuffsDB.impBuffs.x    = DEFAULTS_IMP.buffs.x;    PartyBuffsDB.impBuffs.y    = DEFAULTS_IMP.buffs.y
	PartyBuffsDB.impDebuffs.x  = DEFAULTS_IMP.debuffs.x;  PartyBuffsDB.impDebuffs.y  = DEFAULTS_IMP.debuffs.y
	PartyBuffsDB.pwBuffs.x     = DEFAULTS_PW.buffs.x;     PartyBuffsDB.pwBuffs.y     = DEFAULTS_PW.buffs.y
	PartyBuffsDB.pwDebuffs.x   = DEFAULTS_PW.debuffs.x;   PartyBuffsDB.pwDebuffs.y   = DEFAULTS_PW.debuffs.y
	PartyBuffsDB.pw2Buffs.x    = DEFAULTS_PW2.buffs.x;    PartyBuffsDB.pw2Buffs.y    = DEFAULTS_PW2.buffs.y
	PartyBuffsDB.pw2Debuffs.x  = DEFAULTS_PW2.debuffs.x;  PartyBuffsDB.pw2Debuffs.y  = DEFAULTS_PW2.debuffs.y

	PartyBuffsDB.scale      = { buffs=DEFAULTS_SHARED.scale.buffs, debuffs=DEFAULTS_SHARED.scale.debuffs }
	PartyBuffsDB.panel      = { x=DEFAULTS_SHARED.panel.x, y=DEFAULTS_SHARED.panel.y }
	PartyBuffsDB.maxBuffs   = DEFAULTS_SHARED.maxBuffs
	PartyBuffsDB.maxDebuffs = DEFAULTS_SHARED.maxDebuffs
end




local function CreateMoverFrame(name, label)
	local m = _G[name]
	if m then
		if m.text then m.text:SetText(label) end
		return m
	end













	local parentFrame = GetPartyAnchor() or UIParent
	m = CreateFrame("Frame", name, parentFrame)
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





function UpdateMoverPositions()
	local f1 = GetPartyAnchor()
	if not f1 then return end
	ApplyDefaults()
	local buffs   = GetCurrentBuffs();
	local debuffs = GetCurrentDebuffs();
	if movers.debuffs then
		movers.debuffs:ClearAllPoints()
		movers.debuffs:SetPoint("LEFT",  f1, "RIGHT",   debuffs.x, debuffs.y)
	end
	if movers.buffs then
		movers.buffs:ClearAllPoints()
		movers.buffs:SetPoint("TOPLEFT", f1, "TOPLEFT", buffs.x, buffs.y)
	end
end





local function ComputeDebuffOffsetsFromMover(mover)
	local f1 = GetPartyAnchor()
	if not f1 then local d = GetCurrentDefaults(); return d.debuffs.x, d.debuffs.y end
	local ml = mover:GetLeft() or 0
	local _, mcy = mover:GetCenter(); mcy = mcy or 0
	local fr = f1:GetRight() or 0
	local _, fcy = f1:GetCenter(); fcy = fcy or 0
	return math.floor(ml  - fr  + 0.5),
	       math.floor(mcy - fcy + 0.5)
end

local function ComputeBuffOffsetsFromMover(mover)
	local f1 = GetPartyAnchor()
	if not f1 then local d = GetCurrentDefaults(); return d.buffs.x, d.buffs.y end
	local ml = mover:GetLeft() or 0
	local mt = mover:GetTop()  or 0
	local fl = f1:GetLeft()    or 0
	local ft = f1:GetTop()     or 0













	return math.floor(ml - fl + 0.5),
	       math.floor(mt - ft + 0.5)
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
		print("|cff66CCFFPartyBuffs:|r " .. (L["PB_NO_FRAME"] or "PartyMemberFrame1 not available. Use /reload."))
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


	local sd, sb = show and ShowDebuffs(), show and ShowBuffs()
	if movers.debuffs then if sd then movers.debuffs:Show() else movers.debuffs:Hide() end end
	if movers.buffs   then if sb then movers.buffs:Show()   else movers.buffs:Hide()   end end
end


















local scalePanel
local runtimeScale
local runtimePanel









local function SavePanelPoint()
	if not (scalePanel and runtimePanel) then return end
	local point, _, relativePoint, x, y = scalePanel:GetPoint()
	if not point then return end



	runtimePanel.point         = point
	runtimePanel.relativePoint = relativePoint
	runtimePanel.x             = x or 0
	runtimePanel.y             = y or 0
end

local function PlacePanelFrom(src)
	if not scalePanel then return end
	scalePanel:ClearAllPoints()
	if src and src.point then
		scalePanel:SetPoint(src.point, UIParent, src.relativePoint or src.point,
			src.x or 0, src.y or 0)
		return
	end

	local f1 = GetPartyAnchor()
	if f1 then
		scalePanel:SetPoint("TOPLEFT", f1, "TOPRIGHT", 12, 0)
	else
		scalePanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

local function LockUI()
	ShowMovers(false)
	if scalePanel and scalePanel:IsShown() then scalePanel:Hide() end
end

local function EnsureScalePanel()
	if scalePanel then return end

	scalePanel = CreateFrame("Frame", "PB_ScalePanel", UIParent)

	if K.UI and K.UI.AutoRestyle then K.UI.AutoRestyle(scalePanel); end




	scalePanel:SetSize(300, 268)








	scalePanel:SetFrameStrata("FULLSCREEN_DIALOG")
	scalePanel:SetToplevel(true)
	scalePanel:SetClampedToScreen(true)
	scalePanel:EnableMouse(true)
	scalePanel:SetMovable(true)
	scalePanel:Hide()

	if scalePanel.SetBackdrop then
		scalePanel:SetBackdrop({
			bgFile   = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = false, edgeSize = 12,
			insets = { left=3, right=3, top=3, bottom=3 },
		})
		scalePanel:SetBackdropColor(0.05, 0.06, 0.09, 1)
	end


	local header = CreateFrame("Frame", nil, scalePanel)
	header:SetPoint("TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", 0, 0)
	header:SetHeight(18)
	header:EnableMouse(true)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function()



		scalePanel:ClearAllPoints()
		scalePanel:StartMoving()
	end)
	header:SetScript("OnDragStop", function()
		scalePanel:StopMovingOrSizing()


		SavePanelPoint()
	end)

	local titleFS = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	titleFS:SetPoint("TOPLEFT", 8, -4)
	titleFS:SetText("|cff66CCFF" .. (L["PB_TITLE"] or "Party Buffs") .. "|r  " .. (L["PB_SCALEMAX"] or "Scale / Max"))


	local sep0 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep0:SetTexture(1, 1, 1, 0.12)
	sep0:SetPoint("TOPLEFT", 4, -18); sep0:SetPoint("TOPRIGHT", -4, -18); sep0:SetHeight(1)


	local function MakeRow(yOff, labelTxt, sliderName, minV, maxV, step, isInt, onChangeFn)
		local lbl = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		lbl:SetPoint("TOPLEFT", 10, yOff)
		lbl:SetText(labelTxt)
		lbl:SetWidth(55)


		local s = CreateFrame("Slider", sliderName, scalePanel, "OptionsSliderTemplate")
		s:SetWidth(200); s:SetHeight(14)
		s:SetPoint("TOPLEFT", 68, yOff + 1)
		s:SetMinMaxValues(minV, maxV)
		s:SetValueStep(step)

		local sL = _G[sliderName.."Low"]; local sH = _G[sliderName.."High"]; local sT = _G[sliderName.."Text"]
		if sL then sL:SetText("") sL:Hide() end
		if sH then sH:SetText("") sH:Hide() end
		if sT then sT:SetText("") sT:Hide() end









		s:SetScript("OnValueChanged", function(self, val)
			val = math.floor(val / step + 0.5) * step
			if isInt then
				val = math.floor(val + 0.5)
			else
				val = tonumber(string.format("%.2f", val)) or 1
			end
			if onChangeFn then onChangeFn(val) end
		end)
		return s
	end


	local lblScale = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lblScale:SetPoint("TOPLEFT", 10, -24); lblScale:SetText("|cffaaaaaa" .. (L["PB_SCALE_ICONS"] or "Scale icons:") .. "|r")

	scalePanel.buffSlider = MakeRow(-42, "Buffs", "PB_BuffScaleSlider", 0.5, 2.0, 0.1, false,
		function(v) if runtimeScale then runtimeScale.buffs   = v; ApplyScaleAll(runtimeScale) end end)
	scalePanel.debuffSlider = MakeRow(-80, "Debuffs", "PB_DebuffScaleSlider", 0.5, 2.0, 0.1, false,
		function(v) if runtimeScale then runtimeScale.debuffs = v; ApplyScaleAll(runtimeScale) end end)


	local sep1 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep1:SetTexture(1, 1, 1, 0.08)
	sep1:SetPoint("TOPLEFT", 4, -120); sep1:SetPoint("TOPRIGHT", -4, -120); sep1:SetHeight(1)


	local lblMax = scalePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	lblMax:SetPoint("TOPLEFT", 10, -128); lblMax:SetText("|cffaaaaaa" .. (L["PB_MAX_ICONS"] or "Max icons:") .. "|r")

	scalePanel.maxBuffSlider = MakeRow(-148, "Buffs", "PB_MaxBuffSlider", 1, 20, 1, true,
		function(v) ApplyDefaults(); PartyBuffsDB.maxBuffs   = v; ReanchorAll() end)
	scalePanel.maxDebuffSlider = MakeRow(-186, "Debuffs", "PB_MaxDebuffSlider", 1, 20, 1, true,
		function(v) ApplyDefaults(); PartyBuffsDB.maxDebuffs = v; ReanchorAll() end)


	local sep2 = scalePanel:CreateTexture(nil, "ARTWORK")
	sep2:SetTexture(1, 1, 1, 0.12)
	sep2:SetPoint("BOTTOMLEFT", 4, 38); sep2:SetPoint("BOTTOMRIGHT", -4, 38); sep2:SetHeight(1)


	local resetBtn = CreateFrame("Button", nil, scalePanel, "UIPanelButtonTemplate")
	resetBtn:SetSize(95, 22)
	resetBtn:SetPoint("BOTTOMLEFT", 8, 8)
	resetBtn:SetText(L["BTN_RESET_SHORT"] or "Reset")
	resetBtn:SetScript("OnClick", function()
		FullReset()
		if runtimeScale then runtimeScale.buffs = DEFAULTS_SHARED.scale.buffs; runtimeScale.debuffs = DEFAULTS_SHARED.scale.debuffs end


		if runtimePanel then
			runtimePanel.point = nil; runtimePanel.relativePoint = nil
			runtimePanel.x = 0; runtimePanel.y = 0
		end
		PartyBuffsDB.panel = { x = 0, y = 0 }
		PlacePanelFrom(nil)
		scalePanel.buffSlider:SetValue(DEFAULTS_SHARED.scale.buffs)
		scalePanel.debuffSlider:SetValue(DEFAULTS_SHARED.scale.debuffs)
		scalePanel.maxBuffSlider:SetValue(DEFAULTS_SHARED.maxBuffs)
		scalePanel.maxDebuffSlider:SetValue(DEFAULTS_SHARED.maxDebuffs)
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)
		if movers.buffs or movers.debuffs then UpdateMoverPositions() end
	end)

	local saveBtn = CreateFrame("Button", nil, scalePanel, "UIPanelButtonTemplate")
	saveBtn:SetSize(95, 22)
	saveBtn:SetPoint("BOTTOMRIGHT", -8, 8)
	saveBtn:SetText(L["BTN_SAVE"] or "Save")
	saveBtn:SetScript("OnClick", function()
		ApplyDefaults()
		if runtimeScale then PartyBuffsDB.scale.buffs = runtimeScale.buffs; PartyBuffsDB.scale.debuffs = runtimeScale.debuffs end
		if runtimePanel then


			SavePanelPoint()
			PartyBuffsDB.panel = CopyPanel(runtimePanel)
		end
		ApplyScaleAll(PartyBuffsDB.scale)
		LockUI()
	end)
end

local function PlaceScalePanelFromDB()
	ApplyDefaults()


	PlacePanelFrom(runtimePanel or PartyBuffsDB.panel)
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




SLASH_PARTYBUFFS1 = "/pbuffs"
SLASH_PARTYBUFFS2 = "/partybuffs"















SlashCmdList["PARTYBUFFS"] = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")

	if msg == "" then
		if scalePanel and scalePanel:IsShown() then
			LockUI()
		else
			CreateMovers()
			ShowMovers(true)
			ShowScalePanel(true)
		end

	elseif msg == "reset" then

		FullReset()
		ReanchorAll()
		ApplyScaleAll(PartyBuffsDB.scale)

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
		print("|cff66CCFFPartyBuffs:|r " .. (L["PB_RESET_DONE"] or "Reset done. Positions and scale restored."))

	else
		print("|cff66CCFFPartyBuffs:|r " .. (L["CMD_AVAILABLE"] or "Available commands:"))
		print("  /pbuffs        — " .. (L["PB_HELP_OPEN"] or "Open the settings panel and the movers"))
		print("  /pbuffs reset  — " .. (L["PB_HELP_RESET"] or "Reset positions and scale to defaults"))
	end
end




local function PB_Enable()
	if pbEnabled then return end
	pbEnabled = true

	ApplyDefaults()
	SetupFrames()
	ReanchorAll()
	ApplyScaleAll(PartyBuffsDB.scale)
	RefreshAllAuras()

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




			RestoreOrigAnchor(i, f, "debuff")
			RestoreOrigAnchor(i, f, "buff")

			if f.unit and UnitExists(f.unit) then
				if PartyMemberFrame_RefreshDebuffs then pcall(PartyMemberFrame_RefreshDebuffs, f) end
				if PartyMemberFrame_RefreshBuffs   then pcall(PartyMemberFrame_RefreshBuffs, f)   end
			end
		end
	end

	initialized = false
	if K.UpdateNewPartyFrames then K.UpdateNewPartyFrames(); end
end





function K.PartyBuffsOwnsDebuffs() return pbEnabled and ShowDebuffs(); end
function K.PartyBuffsOwnsBuffs()   return pbEnabled and ShowBuffs();   end


function K.PartyBuffs_GetShown()
	local on = K.IsModuleEnabled and K.IsModuleEnabled("PartyBuffs");
	return (on and ShowBuffs()) and true or false, (on and ShowDebuffs()) and true or false;
end



function K.PartyBuffs_SetShown(which, on)
	on = on and true or false;
	local key = (which == "buffs") and "showBuffs" or "showDebuffs";
	local moduleOn = K.IsModuleEnabled and K.IsModuleEnabled("PartyBuffs");

	if on and not moduleOn then

		PartyBuffsDB.showBuffs   = (which == "buffs");
		PartyBuffsDB.showDebuffs = (which ~= "buffs");
		K.SetModuleEnabled("PartyBuffs", true);
	elseif not on and moduleOn and not (key == "showBuffs" and ShowDebuffs() or key == "showDebuffs" and ShowBuffs()) then

		PartyBuffsDB[key] = false;
		K.SetModuleEnabled("PartyBuffs", false);
	else
		local was = PartyBuffsDB[key] ~= false;
		PartyBuffsDB[key] = on;
		if pbEnabled and was ~= on then

			if not on then
				for i = 1, 4 do
					local f = _G["PartyMemberFrame" .. i];
					if f then RestoreOrigAnchor(i, f, (which == "buffs") and "buff" or "debuff"); end
				end
			end
			ReanchorAll();
			ApplyScaleAll(PartyBuffsDB.scale);
			RefreshAllAuras();
			if scalePanel and scalePanel:IsShown() then ShowMovers(true); end

			if K.UpdateNewPartyFrames then K.UpdateNewPartyFrames(); end
		end
	end
	if K.RefreshModuleCheckbox then K.RefreshModuleCheckbox("PartyBuffs"); end
end






local BLIZZ_FILTERS = {
	buffs   = { cvar = "showCastableBuffs", uvar = "SHOW_CASTABLE_BUFFS",      event = "SHOW_CASTABLE_BUFFS_TEXT" },
	debuffs = { cvar = "showDispelDebuffs", uvar = "SHOW_DISPELLABLE_DEBUFFS", event = "SHOW_DISPELLABLE_DEBUFFS_TEXT" },
};


function K.PartyBuffs_HasBlizzFilter(which)
	local info = BLIZZ_FILTERS[which];
	return info and GetCVar(info.cvar) ~= nil or false;
end

function K.PartyBuffs_GetBlizzFilter(which)
	local info = BLIZZ_FILTERS[which];
	return info and GetCVar(info.cvar) == "1" or false;
end

function K.PartyBuffs_SetBlizzFilter(which, on)
	local info = BLIZZ_FILTERS[which];
	if not info or GetCVar(info.cvar) == nil then return false; end
	local v = on and "1" or "0";

	SetCVar(info.cvar, v, info.event);



	if _G[info.uvar] ~= nil and _G[info.uvar] ~= v then _G[info.uvar] = v; end

	if pbEnabled then
		RefreshAllAuras();
	else
		for i = 1, 4 do
			local f = _G["PartyMemberFrame" .. i];
			if f and f.unit and UnitExists(f.unit) and PartyMemberFrame_RefreshDebuffs then
				pcall(PartyMemberFrame_RefreshDebuffs, f);
			end
		end
	end
	return true;
end




K.RegisterModule("PartyBuffs", {
	name    = "Party Buffs",
	desc    = L["MOD_PARTYBUFFS_DESC"] or "Extended buffs and/or debuffs (1-20 icons) on party frames. /pbuffs | /pbuffs reset",
	default = false,
	onEnable  = PB_Enable,
	onDisable = PB_Disable,
	hideFromModulesTab = true,
})