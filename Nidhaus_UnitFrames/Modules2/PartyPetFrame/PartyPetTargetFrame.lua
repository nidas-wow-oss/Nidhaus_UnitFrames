local AddOnName, ns = ...;
local K, C, L = unpack(ns);

K.DeferModule("PartyPetFrame", {
    name    = L["MOD_PARTYPETFRAME"] or "Party pet enhanced",
    desc    = L["MOD_PARTYPETFRAME_DESC"]
        or "Custom frames for your party members' pets (party 1-4): portrait with the CC they get, health/mana, buffs, debuffs and cast bar. /ppf for commands.",
    default = false,
    hideFromModulesTab = true,
}, function()
    local addonName = "PartyPetTargetFrame"
    local frame = CreateFrame("Frame", addonName.."Frame", UIParent)

    local NUM_PETS   = 4
    local FRAME_W    = 160
    local FRAME_H    = 80
    local STACK_GAP  = 4
    local DEF_X, DEF_Y = 300, 100

    local function TimerAfter(delay, func)
        local t = CreateFrame("Frame")
        local elapsed = 0
        t:SetScript("OnUpdate", function(self, e)
            elapsed = elapsed + e
            if elapsed >= delay then
                self:SetScript("OnUpdate", nil)
                func()
            end
        end)
    end

    local OPT_DEFAULTS = {
    	showBuffs = true, showDebuffs = true, showCast = true,
    	auraTimers = true, borderStyle = "fino",
    	dispelGlow = true, ownerColor = true, rangeFade = true,
    	clickable = true, locked = false,
    	frameStyle = "compact", hpText = true,
    }
    local BORDER_STYLES = { fino = true, lorti = true, blizzard = true }

    local FRAME_STYLES  = { compact = true, compact2 = true, blizzard = true, bigblizzard = true }

    local function PPF_Opts()
    	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
    	local db = NidhausUnitFramesDB.PartyPetFrame
    	if type(db) ~= "table" then
    		db = {}
    		NidhausUnitFramesDB.PartyPetFrame = db
    	end
    	for k, v in pairs(OPT_DEFAULTS) do
    		if db[k] == nil then db[k] = v end
    	end
    	if not BORDER_STYLES[db.borderStyle] then db.borderStyle = "fino" end
    	if not FRAME_STYLES[db.frameStyle] then db.frameStyle = "compact" end

    	db.showCC, db.ccTimer, db.showTarget = nil, nil, nil

    	if db.inArena == nil then
    		local arenaOnly = (C.PartyPetArenaOnly ~= false)
    		db.inArena = true
    		db.inBG    = not arenaOnly
    		db.inWorld = not arenaOnly
    	end
    	return db
    end

    local function PPF_ArenaOnly()
        local o = PPF_Opts()
        return o.inArena and not o.inBG and not o.inWorld
    end

    local function PPF_InArena()
        if type(IsActiveBattlefieldArena) == "function" then
            local ok, res = pcall(IsActiveBattlefieldArena)
            if ok and res then return true end
        end
        local _, itype = IsInInstance()
        return itype == "arena"
    end

    local function PPF_ZoneAllows()
        local o = PPF_Opts()
        if PPF_InArena() then return o.inArena and true or false end
        local _, itype = IsInInstance()
        if itype == "pvp" then return o.inBG and true or false end
        return o.inWorld and true or false
    end

    local function PPF_DB()
        if not NidhausUnitFramesDB then NidhausUnitFramesDB = {} end
        NidhausUnitFramesDB.PartyPetPos = NidhausUnitFramesDB.PartyPetPos or {}
        return NidhausUnitFramesDB.PartyPetPos
    end

    local petFrames = {}

    local PPF_HasUnitWatch = (type(RegisterUnitWatch) == "function")
    	and (type(UnregisterUnitWatch) == "function")
    local PPF_WantVisible  = false
    local PPF_Pending      = nil

    local PPF_ApplyVisibility
    local previewOn = false

    local ppfCombat = CreateFrame("Frame")
    ppfCombat:SetScript("OnEvent", function(self)
    	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    	if PPF_Pending ~= nil then
    		local want = PPF_Pending
    		PPF_Pending = nil
    		PPF_ApplyVisibility(want)
    	end
    end)

    function PPF_ApplyVisibility(on)

    	if previewOn then
    		PPF_WantVisible = on
    		return
    	end
    	if InCombatLockdown() then
    		PPF_Pending = on
    		ppfCombat:RegisterEvent("PLAYER_REGEN_ENABLED")
    		return
    	end
    	PPF_WantVisible = on

    	local show = on and PPF_ZoneAllows()

    	for i = 1, NUM_PETS do
    		local f = petFrames[i]
    		if f then
    			if PPF_HasUnitWatch then
    				if show and not f.ppfWatching then
    					RegisterUnitWatch(f)
    					f.ppfWatching = true
    				elseif (not show) and f.ppfWatching then
    					UnregisterUnitWatch(f)
    					f.ppfWatching = false
    				end
    				if not show then f:Hide() end
    			else
    				local should = show and UnitExists(f.unit) and true or false
    				if should and not f:IsShown() then
    					f:Show()
    				elseif (not should) and f:IsShown() then
    					f:Hide()
    				end
    			end
    		end
    	end
    end

    local hiddenAuras = {
        ["Devotion Aura"] = true,
        ["Crusader Aura"] = true,
        ["Concentration Aura"] = true,
        ["Retribution Aura"] = true,
        ["Resistance Aura"] = true,
        ["Trueshot Aura"] = true,
        ["Fire Resistance Aura"] = true,
        ["Frost Resistance Aura"] = true,
        ["Shadow Resistance Aura"] = true,
        ["Aspect of the Pack"] = true,
        ["Aspect of the Wild"] = true,
    }

    local CC_PRIORITY = {
    	cyclone = 100, banish = 100, mc = 95,
    	ctrlstun = 90, openstun = 90, rndstun = 90, charge = 90, intimidation = 90,
    	disorient = 80, sleep = 80, scatter = 80,
    	fear = 70, horror = 70,
    	silence = 50, disarm = 40,
    	ctrlroot = 30, rndroot = 30, entrapment = 30,
    }

    local function FindCC(unit)
    	if not K.GetCCCategory then return nil end
    	local bestP, bestIcon, bestDur, bestExp
    	for i = 1, 40 do
    		local name, _, icon, _, _, duration, expires, _, _, _, spellId = UnitDebuff(unit, i)
    		if not name then break end
    		local cat = K.GetCCCategory(spellId)
    		local p = cat and CC_PRIORITY[cat]
    		if p and (not bestP or p > bestP or (p == bestP and (expires or 0) > (bestExp or 0))) then
    			bestP, bestIcon, bestDur, bestExp = p, icon, duration, expires
    		end
    	end
    	return bestIcon, bestDur, bestExp
    end

    local function SetRoundIcon(tex, path)
    	if type(SetPortraitToTexture) == "function" and pcall(SetPortraitToTexture, tex, path) then
    		tex:SetTexCoord(0, 1, 0, 1)
    		return
    	end
    	tex:SetTexture(path)
    	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local function CCText_OnUpdate(self, elapsed)
    	self.acc = (self.acc or 0) + elapsed
    	if self.acc < 0.1 then return end
    	self.acc = 0
    	local exp = self.expires
    	if not exp then return end
    	local left = exp - GetTime()
    	if left <= 0 then
    		if self.loop and self.pf then

    			self.expires = GetTime() + self.loop
    			CooldownFrame_SetTimer(self.pf.ccCD, GetTime(), self.loop, 1)
    			return
    		end
    		self.text:SetText("")
    		return
    	end
    	if left < 10 then
    		self.text:SetFormattedText("%.1f", left)
    	else
    		self.text:SetFormattedText("%d", left)
    	end
    end

    local function SetCCPortrait(pf, icon, duration, expires, loop)
    	if icon then

    		pf.ccGlow:Show()
    		if pf.ccIcon.nufPath ~= icon then
    			SetRoundIcon(pf.ccIcon, icon)
    			pf.ccIcon.nufPath = icon
    		end
    		pf.ccIcon:Show()
    		if duration and duration > 0 and expires then
    			if pf.ccCD.nufExp ~= expires then
    				CooldownFrame_SetTimer(pf.ccCD, expires - duration, duration, 1)
    				pf.ccCD.nufExp = expires
    			end
    			pf.ccCD:Show()
    			pf.ccOverlay.expires = expires
    			pf.ccOverlay.loop = loop
    			pf.ccOverlay:Show()
    		else
    			pf.ccCD:Hide()
    			pf.ccOverlay:Hide()
    		end
    		return
    	end
    	pf.ccGlow:Hide()
    	pf.ccIcon:Hide()
    	pf.ccIcon.nufPath = nil
    	pf.ccCD:Hide()
    	pf.ccCD.nufExp = nil
    	pf.ccOverlay:Hide()
    	pf.ccOverlay.expires = nil
    	pf.ccOverlay.loop = nil
    end

    local LORTI_MEDIA = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\Lorti UI\\media\\"
    local WHITE8 = "Interface\\Buttons\\WHITE8X8"

    local DEBUFF_COLORS = {
        Magic   = {0.2, 0.6, 1},
        Curse   = {0.6, 0, 1},
        Disease = {0.6, 0.4, 0},
        Poison  = {0, 0.6, 0},
    }
    local DEBUFF_NONE = {0.8, 0, 0}

    local _, PLAYER_CLASS = UnitClass("player")
    local CAN_DISPEL = ({
        PRIEST  = { Magic = true, Disease = true },
        PALADIN = { Magic = true, Poison = true, Disease = true },
        SHAMAN  = { Poison = true, Disease = true, Curse = true },
        DRUID   = { Curse = true, Poison = true },
        MAGE    = { Curse = true },
        WARLOCK = { Magic = true },
    })[PLAYER_CLASS or ""] or {}

    local function MakeAuraIcon(parent, size)
    	local icon = CreateFrame("Frame", nil, parent)
    	icon:SetSize(size, size)
    	icon.size = size
    	icon.texture = icon:CreateTexture(nil, "ARTWORK")
    	icon.texture:SetAllPoints(icon)
    	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    	local cd = CreateFrame("Cooldown", nil, icon)
    	cd:SetAllPoints(icon.texture)

    	cd:SetReverse(true)
    	cd.noCooldownCount = true
    	cd.noOCC = true
    	cd:Hide()
    	icon.cd = cd

    	local top = CreateFrame("Frame", nil, icon)
    	top:SetAllPoints(icon)
    	top:SetFrameLevel(icon:GetFrameLevel() + 3)
    	icon.time = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    	icon.time:SetPoint("CENTER", icon, "CENTER", 0, 0)
    	icon.count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    	icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -1)
    	icon.glow = top:CreateTexture(nil, "BACKGROUND")
    	icon.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    	icon.glow:SetBlendMode("ADD")
    	icon.glow:SetPoint("CENTER", icon, "CENTER", 0, 0)
    	icon.glow:SetSize(size * 1.8, size * 1.8)
    	icon.glow:Hide()
    	icon:Hide()
    	return icon
    end

    local function StyleIcon(icon, style, r, g, b)
    	if icon.nufStyle == style and icon.nufR == r and icon.nufG == g and icon.nufB == b then return end
    	icon.nufStyle, icon.nufR, icon.nufG, icon.nufB = style, r, g, b
    	local isDebuff = (r ~= nil)
    	if icon.fOuter then icon.fOuter:Hide(); icon.fRing:Hide() end
    	if icon.lGloss then icon.lGloss:Hide(); icon.lShadow:Hide(); icon.lRing:Hide() end
    	if icon.bBorder then icon.bBorder:Hide() end
    	local tex = icon.texture
    	tex:ClearAllPoints()

    	if style == "lorti" then
    		local big = icon.size >= 26
    		local inset = big and 2 or 1
    		tex:SetPoint("TOPLEFT", icon, "TOPLEFT", inset, -inset)
    		tex:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -inset, inset)
    		tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    		if not icon.lGloss then
    			local gl = icon:CreateTexture(nil, "OVERLAY")
    			gl:SetTexture(LORTI_MEDIA .. "gloss")
    			gl:SetAllPoints(icon)
    			icon.lGloss = gl

    			local off = big and 4 or 3
    			local sh = CreateFrame("Frame", nil, icon)
    			sh:SetFrameLevel(math.max(0, icon:GetFrameLevel() - 1))
    			sh:SetPoint("TOPLEFT", icon, "TOPLEFT", -off, off)
    			sh:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", off, -off)
    			sh:SetBackdrop({ edgeFile = LORTI_MEDIA .. "outer_shadow", edgeSize = off + 1,
    				insets = { left = off + 1, right = off + 1, top = off + 1, bottom = off + 1 } })
    			icon.lShadow = sh

    			local ring = CreateFrame("Frame", nil, icon)
    			ring:SetFrameLevel(icon:GetFrameLevel() + 2)
    			ring:SetPoint("TOPLEFT", tex, "TOPLEFT", -1, 1)
    			ring:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 1, -1)
    			ring:SetBackdrop({ edgeFile = WHITE8, edgeSize = 1 })
    			ring:Hide()
    			icon.lRing = ring
    		end
    		local sr, sg, sb, sa = nil, nil, nil, nil
    		if K.LortiZoneColor then sr, sg, sb, sa = K.LortiZoneColor("PartyPet") end
    		if sr then icon.lShadow:SetBackdropBorderColor(sr, sg, sb, sa or 1)
    		else icon.lShadow:SetBackdropBorderColor(0, 0, 0, 0.9) end
    		icon.lShadow:Show()
    		if isDebuff then
    			icon.lGloss:SetVertexColor(r, g, b)
    			icon.lRing:SetBackdropBorderColor(r, g, b, 1)
    			icon.lRing:Show()
    		else
    			icon.lGloss:SetVertexColor(0, 0, 0)
    		end
    		icon.lGloss:Show()

    	elseif style == "blizzard" then
    		tex:SetAllPoints(icon)
    		tex:SetTexCoord(0, 1, 0, 1)
    		if isDebuff then
    			if not icon.bBorder then
    				local bo = icon:CreateTexture(nil, "OVERLAY")
    				bo:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    				bo:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    				bo:SetPoint("CENTER", icon, "CENTER", 0, 0)
    				bo:SetSize(icon.size + 4, icon.size + 4)
    				icon.bBorder = bo
    			end
    			icon.bBorder:SetVertexColor(r, g, b)
    			icon.bBorder:Show()
    		end

    	else
    		tex:SetAllPoints(icon)
    		tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    		if not icon.fOuter then

    			icon.fOuter = icon:CreateTexture(nil, "BACKGROUND")
    			icon.fOuter:SetTexture(WHITE8)
    			icon.fOuter:SetVertexColor(0, 0, 0, 1)
    			icon.fRing = icon:CreateTexture(nil, "BORDER")
    			icon.fRing:SetTexture(WHITE8)
    			icon.fRing:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    			icon.fRing:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    			icon.fRing:Hide()
    		end
    		local o = isDebuff and 2 or 1
    		icon.fOuter:ClearAllPoints()
    		icon.fOuter:SetPoint("TOPLEFT", icon, "TOPLEFT", -o, o)
    		icon.fOuter:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", o, -o)
    		icon.fOuter:Show()
    		if isDebuff then
    			icon.fRing:SetVertexColor(r, g, b, 1)
    			icon.fRing:Show()
    		end
    	end
    end

    local function OmniOn()
    	return (rawget(_G, "OmniCC") ~= nil) or (IsAddOnLoaded and IsAddOnLoaded("OmniCC")) and true or false
    end

    local function UpdateAuraTime(icon, now)
    	local exp = icon.expires
    	if not exp then return end
    	local left = exp - now
    	if left <= 0 then
    		if icon.loop then

    			icon.expires = now + icon.loop
    			icon.cd.nufExp = icon.expires
    			CooldownFrame_SetTimer(icon.cd, now, icon.loop, 1)
    			left = icon.loop
    		else
    			icon.time:SetText("")
    			return
    		end
    	end
    	if icon.omni or icon.noNum then return end
    	if left < 60 then
    		icon.time:SetFormattedText("%d", math.ceil(left))
    	elseif left < 3600 then
    		icon.time:SetFormattedText("%dm", math.ceil(left / 60))
    	else
    		icon.time:SetFormattedText("%dh", math.ceil(left / 3600))
    	end
    	local red = left < 5
    	if icon.timeRed ~= red then
    		icon.timeRed = red
    		if red then icon.time:SetTextColor(1, 0.25, 0.25) else icon.time:SetTextColor(1, 1, 1) end
    	end
    end

    local function SetAuraTimer(icon, duration, expires, on, loop)
    	if duration and duration > 0 and expires and expires > 0 then

    		local omni = on and OmniOn() or false
    		if icon.omni ~= omni then
    			icon.omni = omni
    			icon.cd.noCooldownCount = not omni
    			icon.cd.noOCC = not omni
    			icon.cd.nufExp = nil
    			if omni then icon.time:SetText("") end
    		end
    		if icon.cd.nufExp ~= expires then
    			CooldownFrame_SetTimer(icon.cd, expires - duration, duration, 1)
    			icon.cd.nufExp = expires
    		end
    		icon.cd:Show()
    		icon.expires, icon.loop = expires, loop
    		icon.noNum = not on
    		if on then UpdateAuraTime(icon, GetTime()) else icon.time:SetText("") end
    	else
    		icon.cd:Hide()
    		icon.cd.nufExp = nil
    		icon.expires, icon.loop = nil, nil
    		icon.time:SetText("")
    	end
    end

    local function ShowAura(icon, o, texture, count, duration, expires, col, glow, loop)
    	icon.texture:SetTexture(texture)

    	if col then StyleIcon(icon, o.borderStyle, col[1], col[2], col[3])
    	else StyleIcon(icon, "blizzard") end
    	if count and count > 1 then icon.count:SetFormattedText("%d", count) else icon.count:SetText("") end
    	SetAuraTimer(icon, duration, expires, o.auraTimers, loop)
    	if glow and col then
    		icon.glow:SetVertexColor(col[1], col[2], col[3])
    		icon.glow:Show()
    	else
    		icon.glow:Hide()
    	end
    	icon:Show()
    end

    local function HideAura(icon)
    	if icon.expires or icon:IsShown() then
    		icon:Hide()
    		icon.glow:Hide()
    		icon.cd:Hide()
    		icon.cd.nufExp = nil
    		icon.expires, icon.loop = nil, nil
    	end
    end

    local RANGE_SPELL = ({ PRIEST = 2050, PALADIN = 635, SHAMAN = 331, DRUID = 5185 })[PLAYER_CLASS or ""]
    RANGE_SPELL = RANGE_SPELL and GetSpellInfo(RANGE_SPELL) or nil

    local function PetInRange(pf)
    	local unit = pf.unit
    	if RANGE_SPELL then
    		local r = IsSpellInRange(RANGE_SPELL, unit)
    		if r ~= nil then return r == 1 end
    	end
    	if UnitInRange(pf.owner) then return true end
    	return CheckInteractDistance(unit, 4) and true or false
    end

    local function OwnerColor(class)
    	local col = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    	if col then return col.r, col.g, col.b end
    	return 0, 1, 0
    end

    local function ApplyPetLortiTint(pf)
    	if not K.ApplyLortiTint then return; end
    	K.ApplyLortiTint(pf.bg, "LortiUI_PartyPet");
    end

    local PET_STYLES = {
    	compact = {
    		bg = "Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\PartyPetFrame\\Media\\UI-PetFrame",
    		port = { size = 40, point = "LEFT", x = 12, y = 12 },
    		name = { "TOPLEFT", 65, -10 },
    		hp = { w = 85, h = 24, x = 60, y = -10 }, mp = { w = 85, h = 10, gap = -4 },
    		customBar = true,
    	},
    	blizzard = {
    		bg = "Interface\\TargetingFrame\\UI-PartyFrame", w = 128, h = 64, x = 0, y = -2,
    		port = { size = 37, point = "TOPLEFT", x = 7, y = -6 },
    		hp = { w = 70, h = 8, x = 47, y = -12 }, mp = { w = 70, h = 8, gap = -1 },
    		barBG = true,
    	},
    	bigblizzard = {
    		bg = "Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\pw\\UI-PartyFrame", w = 128, h = 64, x = 0, y = -2,
    		port = { size = 37, point = "TOPLEFT", x = 7, y = -6 },
    		hp = { w = 70, h = 12, x = 46, y = -13 }, mp = { w = 70, h = 8, gap = 0 },
    		barBG = true,
    	},
    	compact2 = {
    		bg = "Interface\\AddOns\\Nidhaus_UnitFrames\\Media\\pw\\UI-TargetingFrame", w = 121, h = 52, x = 0, y = 0,
    		coords = { 1.0, 0.09375, 0, 0.78125 },
    		port = { size = 30, point = "TOPLEFT", x = 25, y = -8 },
    		hp = { w = 61, h = 14, x = 57, y = -13 }, mp = { w = 61, h = 6, gap = 0 },
    		barBG = true,
    		customBar = true,
    	},
    }

    local function ApplyPetFrameStyle(pf)
    	if not pf then return end

    	if InCombatLockdown() then
    		if K.AfterCombat then K.AfterCombat("PPFStyle" .. (pf.index or 0), function() ApplyPetFrameStyle(pf) end) end
    		return
    	end
    	local st = PET_STYLES[PPF_Opts().frameStyle] or PET_STYLES.compact

    	pf.bg:SetTexture(st.bg)
    	pf.bg:SetTexCoord(unpack(st.coords or { 0, 1, 0, 1 }))
    	pf.bg:ClearAllPoints()
    	if st.w then
    		pf.bg:SetPoint("TOPLEFT", pf, "TOPLEFT", st.x or 0, st.y or 0)
    		pf.bg:SetSize(st.w, st.h)
    	else
    		pf.bg:SetAllPoints(pf)
    	end
    	ApplyPetLortiTint(pf)

    	local pr = pf.portraitFrame
    	pr:ClearAllPoints()
    	pr:SetPoint(st.port.point, pf, st.port.point, st.port.x, st.port.y)
    	pr:SetSize(st.port.size, st.port.size)
    	if pf.ccGlow then pf.ccGlow:SetSize(st.port.size * 1.9, st.port.size * 1.9) end

    	pf.healthBar:ClearAllPoints()
    	pf.healthBar:SetPoint("TOPLEFT", pf, "TOPLEFT", st.hp.x, st.hp.y)
    	pf.healthBar:SetSize(st.hp.w, st.hp.h)
    	pf.manaBar:ClearAllPoints()
    	pf.manaBar:SetPoint("TOPLEFT", pf.healthBar, "BOTTOMLEFT", 0, st.mp.gap)
    	pf.manaBar:SetSize(st.mp.w, st.mp.h)

    	pf.name:ClearAllPoints()
    	if st.name then
    		pf.name:SetPoint(st.name[1], pf, st.name[1], st.name[2], st.name[3])
    	else
    		pf.name:SetPoint("BOTTOMLEFT", pf.healthBar, "TOPLEFT", 1, 1)
    	end

    	for _, bar in ipairs({ pf.healthBar, pf.manaBar }) do
    		if not bar.nufBG then
    			bar.nufBG = bar:CreateTexture(nil, "BACKGROUND")
    			bar.nufBG:SetAllPoints(bar)
    			bar.nufBG:SetTexture(0, 0, 0, 0.5)
    		end
    		if st.barBG then bar.nufBG:Show() else bar.nufBG:Hide() end
    	end
    	if pf.barBG then pf.barBG:Hide() end

    	local barTex = "Interface\\TargetingFrame\\UI-StatusBar"
    	if st.customBar and C.statusbarOn and C.statusbarTexture then barTex = C.statusbarTexture end
    	pf.healthBar:SetStatusBarTexture(barTex)
    	pf.manaBar:SetStatusBarTexture(barTex)

    	if K.SyncPartyPetAuraSize then pcall(K.SyncPartyPetAuraSize, pf) end
    end

    local function RefSize(name, fallback, pf)
    	local ref = _G[name]
    	if not (ref and ref.GetWidth and ref:GetWidth() and ref:GetWidth() > 0) then return fallback end

    	local base = pf:GetEffectiveScale()
    	if not base or base <= 0 then return fallback end
    	local px = ref:GetWidth() * ref:GetEffectiveScale() / base
    	if px < 8 or px > 64 then return fallback end
    	return math.floor(px + 0.5)
    end

    local function ResizeIcon(icon, size)
    	if icon.size == size then return end
    	icon.size = size
    	icon:SetSize(size, size)
    	icon.glow:SetSize(size * 1.8, size * 1.8)
    	if icon.bBorder then icon.bBorder:SetSize(size + 4, size + 4) end
    	icon.nufStyle = nil
    end

    local function MatchFont(fs, refName, pf)
    	local ref = _G[refName]
    	if not (fs and ref and ref.GetFont) then return end
    	local font, size, flags = ref:GetFont()
    	local es = pf:GetEffectiveScale()
    	if not (font and size and es and es > 0) then return end

    	local holder = ref:GetParent()
    	local rs = holder and holder.GetEffectiveScale and holder:GetEffectiveScale()
    	if not (rs and rs > 0) then return end
    	local px = size * rs / es
    	if px < 6 or px > 30 then return end
    	fs:SetFont(font, px, flags)
    end

    function K.SyncPartyPetAuraSize(pf)
    	if not (pf and pf.buffs and pf.debuffs) then return end
    	MatchFont(pf.name, "PartyMemberFrame1Name", pf)
    	MatchFont(pf.hpText, "PartyMemberFrame1HealthBarText", pf)

    	local pbOn = K.IsModuleEnabled and K.IsModuleEnabled("PartyBuffs")

    	local b = pbOn and RefSize("PartyMemberFrame1Buff1", 21, pf) or 21
    	local d = pbOn and RefSize("PartyMemberFrame1Debuff1", 28, pf) or 28
    	for n = 1, #pf.buffs do ResizeIcon(pf.buffs[n], b) end
    	for n = 1, #pf.debuffs do ResizeIcon(pf.debuffs[n], d) end
    end

    local function PPF_Build(i)
    	local unit = "party" .. i .. "pet"

    	local petFrame = CreateFrame("Button", "CustomParty" .. i .. "PetFrame",
    		UIParent, "SecureUnitButtonTemplate")

    	petFrame:SetSize(FRAME_W, FRAME_H)
    	petFrame.index = i
    	petFrame.unit  = unit
    	petFrame.owner = "party" .. i

    	petFrame:Hide()

    	petFrame:SetAttribute("type1", "target")
    	petFrame:SetAttribute("unit", unit)
    	petFrame:RegisterForClicks("AnyUp")
    	petFrame:EnableMouse(true)

    	petFrame.bg = petFrame:CreateTexture(nil, "BACKGROUND")
    	petFrame.bg:SetAllPoints(true)
    	petFrame.bg:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\PartyPetFrame\\Media\\UI-PetFrame")
    	petFrame.bg:SetDrawLayer("BACKGROUND", 0)

    	petFrame.lockIndicator = petFrame:CreateTexture(nil, "OVERLAY")
    	petFrame.lockIndicator:SetSize(24, 24)
    	petFrame.lockIndicator:SetPoint("TOPRIGHT", petFrame, "TOPRIGHT", -5, -5)
    	petFrame.lockIndicator:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
    	petFrame.lockIndicator:Hide()

    	petFrame.portraitFrame = CreateFrame("Frame", nil, petFrame)
    	petFrame.portraitFrame:SetSize(40, 40)
    	petFrame.portraitFrame:SetPoint("LEFT", 12, 12)
    	petFrame.portraitFrame:SetFrameLevel(0)

    	petFrame.portraitIcon = petFrame.portraitFrame:CreateTexture(nil, "ARTWORK")
    	petFrame.portraitIcon:SetAllPoints(true)
    	petFrame.portraitIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    	petFrame.portraitBG = petFrame.portraitFrame:CreateTexture(nil, "BACKGROUND")
    	petFrame.portraitBG:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    	petFrame.portraitBG:SetAllPoints(true)
    	petFrame.portraitBG:SetVertexColor(0, 0, 0, 1)

    	local pfr = petFrame.portraitFrame
    	petFrame.ccIcon = pfr:CreateTexture(nil, "OVERLAY")
    	petFrame.ccIcon:SetAllPoints(petFrame.portraitIcon)
    	petFrame.ccIcon:Hide()

    	local ccCD = CreateFrame("Cooldown", nil, pfr)
    	ccCD:SetAllPoints(pfr)
    	ccCD:SetReverse(true)
    	ccCD.noCooldownCount = true
    	ccCD.noOCC = true
    	ccCD:Hide()
    	petFrame.ccCD = ccCD

    	local ccOv = CreateFrame("Frame", nil, pfr)
    	ccOv:SetAllPoints(pfr)
    	ccOv:SetFrameLevel(ccCD:GetFrameLevel() + 2)
    	ccOv.text = ccOv:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    	ccOv.text:SetPoint("CENTER", ccOv, "CENTER", 0, 0)
    	ccOv.pf = petFrame
    	ccOv:SetScript("OnUpdate", CCText_OnUpdate)
    	ccOv:Hide()
    	petFrame.ccOverlay = ccOv

    	petFrame.ccGlow = pfr:CreateTexture(nil, "OVERLAY")
    	petFrame.ccGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    	petFrame.ccGlow:SetBlendMode("ADD")
    	petFrame.ccGlow:SetVertexColor(1, 0.15, 0.15)
    	petFrame.ccGlow:SetPoint("CENTER", pfr, "CENTER", 0, 0)
    	petFrame.ccGlow:SetSize(76, 76)
    	petFrame.ccGlow:Hide()

    	petFrame.name = petFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    	petFrame.name:SetPoint("TOPLEFT", 65, -10)

    	petFrame.healthBar = CreateFrame("StatusBar", nil, petFrame)
    	petFrame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    	petFrame.healthBar:SetSize(85, 24)
    	petFrame.healthBar:SetPoint("TOPLEFT", 60, -10)
    	petFrame.healthBar:SetStatusBarColor(0, 1, 0)
    	petFrame.healthBar:SetFrameLevel(0)

    	petFrame.hpText = petFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    	petFrame.hpText:SetPoint("CENTER", petFrame.healthBar, "CENTER", 0, 0)

    	petFrame.manaBar = CreateFrame("StatusBar", nil, petFrame)
    	petFrame.manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    	petFrame.manaBar:SetSize(85, 10)
    	petFrame.manaBar:SetPoint("TOPLEFT", petFrame.healthBar, "BOTTOMLEFT", 0, -4)
    	petFrame.manaBar:SetFrameLevel(0)

    	petFrame.debuffs = {}
    	for n = 1, 8 do
    		local icon = MakeAuraIcon(petFrame, 28)
    		if n == 1 then
    			icon:SetPoint("LEFT", petFrame.healthBar, "RIGHT", 6, 0)
    		else
    			icon:SetPoint("LEFT", petFrame.debuffs[n-1], "RIGHT", 6, 0)
    		end
    		petFrame.debuffs[n] = icon
    	end
    	petFrame.buffs = {}
    	for n = 1, 8 do
    		petFrame.buffs[n] = MakeAuraIcon(petFrame, 21)
    	end

    	local castBar = CreateFrame("StatusBar", nil, petFrame)
    	castBar:SetSize(110, 14)
    	castBar:SetPoint("TOPLEFT", petFrame.manaBar, "BOTTOMLEFT", 0, -4)
    	castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    	castBar:SetStatusBarColor(1, 0.7, 0.2)
    	castBar:Hide()
    	petFrame.castBar = castBar

    	local castBarBG = castBar:CreateTexture(nil, "BACKGROUND")
    	castBarBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    	castBarBG:SetPoint("TOPLEFT", castBar, "TOPLEFT", -1, 1)
    	castBarBG:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 1, -1)
    	castBarBG:SetVertexColor(0, 0, 0, 0.7)

    	castBar.icon = castBar:CreateTexture(nil, "ARTWORK")
    	castBar.icon:SetSize(14, 14)
    	castBar.icon:SetPoint("RIGHT", castBar, "LEFT", -3, 0)
    	castBar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    	local spark = castBar:CreateTexture(nil, "OVERLAY")
    	spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    	spark:SetBlendMode("ADD")
    	spark:SetSize(24, 24)
    	spark:SetPoint("CENTER", castBar:GetStatusBarTexture(), "RIGHT", 0, 0)
    	castBar.spark = spark

    	castBar.text = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    	castBar.text:SetPoint("LEFT", castBar, "LEFT", 4, 0)
    	castBar.text:SetJustifyH("LEFT")

    	castBar.timeText = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    	castBar.timeText:SetPoint("RIGHT", castBar, "RIGHT", -4, 0)
    	castBar.timeText:SetJustifyH("RIGHT")

    	castBar:SetScript("OnUpdate", function(self)
    		if not self.endTime then return end
    		local now = GetTime()
    		if now >= self.endTime then
    			self.endTime = nil
    			self:Hide()
    			return
    		end
    		if self.isChannel then

    			self:SetValue(self.startTime + self.endTime - now)
    		else
    			self:SetValue(now)
    		end
    		self.timeText:SetFormattedText("%.1f", self.endTime - now)
    	end)

    	ApplyPetFrameStyle(petFrame)
    	return petFrame
    end

    local function PPF_Layout()
    	if InCombatLockdown() then return end
    	local pos = PPF_DB()
    	local f1 = petFrames[1]
    	if not f1 then return end

    	f1:ClearAllPoints()
    	f1:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER",
    		pos.x or DEF_X, pos.y or DEF_Y)

    	for i = 2, NUM_PETS do
    		local f = petFrames[i]
    		if f then
    			f:ClearAllPoints()
    			f:SetPoint("TOPLEFT", petFrames[i-1], "BOTTOMLEFT", 0, -STACK_GAP)
    		end
    	end
    end

    local function PPF_SavePosition()
    	local f1 = petFrames[1]
    	if not f1 then return end
    	local point, rel, relPoint, x, y = f1:GetPoint(1)
    	if not point then return end

    	if rel and rel ~= UIParent then return end
    	local pos = PPF_DB()
    	pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
    end

    local function PPF_MakeDraggable(f)
    	f:SetMovable(true)
    	f:RegisterForDrag("LeftButton")
    	f:SetScript("OnDragStart", function(self)

    		if PPF_Opts().locked and not previewOn then return end
    		if InCombatLockdown() then return end
    		self:StartMoving()
    	end)
    	f:SetScript("OnDragStop", function(self)
    		self:StopMovingOrSizing()
    		PPF_SavePosition()
    		PPF_Layout()
    	end)
    end

    for i = 1, NUM_PETS do
    	petFrames[i] = PPF_Build(i)
    end
    PPF_MakeDraggable(petFrames[1])
    PPF_Layout()

    local POWER_COLORS = {
        [0] = {0, 0, 1},
        [1] = {1, 0, 0},
        [2] = {1, 0.5, 0},
        [3] = {1, 1, 0},
        [6] = {0, 0.8, 1},
    }
    local DEFAULT_POWER = {0, 0, 1}
    local FADE_ALPHA = 0.45

    local function PlaceBuff(pf, n)
        local icon = pf.buffs[n]
        icon:ClearAllPoints()
        if n == 1 then
            icon:SetPoint("TOPLEFT", pf.portraitFrame, "TOPRIGHT", 8, 30)
        else
            icon:SetPoint("LEFT", pf.buffs[n-1], "RIGHT", 1, 0)
        end
    end

    local function UpdatePetFrame(pf)
        if previewOn then return end
        local unit = pf.unit
        local o = PPF_Opts()

        if not UnitExists(unit) then
            if not PPF_HasUnitWatch then PPF_ApplyVisibility(PPF_WantVisible) end
            return
        end
        if not PPF_HasUnitWatch then PPF_ApplyVisibility(PPF_WantVisible) end
        SetPortraitTexture(pf.portraitIcon, unit)
        pf.name:SetText(UnitName(unit) or "Mascota")

        local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
        pf.healthBar:SetMinMaxValues(0, hpMax)
        pf.healthBar:SetValue(hp)
        if o.hpText and hpMax and hpMax > 0 then
            pf.hpText:SetFormattedText("%d / %d", hp, hpMax)
        else
            pf.hpText:SetText("")
        end
        if o.ownerColor then
            local _, class = UnitClass(pf.owner)
            pf.healthBar:SetStatusBarColor(OwnerColor(class))
        else
            pf.healthBar:SetStatusBarColor(0, 1, 0)
        end

        pf:SetAlpha((o.rangeFade and not PetInRange(pf)) and FADE_ALPHA or 1)

        local powerType = UnitPowerType(unit)
        local power, powerMax = UnitPower(unit), UnitPowerMax(unit)
        pf.manaBar:SetMinMaxValues(0, powerMax)
        pf.manaBar:SetValue(power)

        pf.manaBar:SetStatusBarColor(unpack(POWER_COLORS[powerType] or DEFAULT_POWER))

        local buffIndex = 1
        for i = 1, (o.showBuffs and 16 or 0) do
            local name, _, texture, count, _, duration, expires = UnitBuff(unit, i)
            if not name then break end
            if not hiddenAuras[name] then
                local icon = pf.buffs[buffIndex]

                if not icon then break end
                PlaceBuff(pf, buffIndex)
                ShowAura(icon, o, texture, count, duration, expires)
                buffIndex = buffIndex + 1
            end
        end
        for j = buffIndex, #pf.buffs do HideAura(pf.buffs[j]) end

        for i = 1, 8 do
            local icon = pf.debuffs[i]
            local name, _, texture, count, debuffType, duration, expires
            if o.showDebuffs then
                name, _, texture, count, debuffType, duration, expires = UnitDebuff(unit, i)
            end
            if name then
                local col = (debuffType and DEBUFF_COLORS[debuffType]) or DEBUFF_NONE
                local glow = o.dispelGlow and debuffType and CAN_DISPEL[debuffType]
                ShowAura(icon, o, texture, count, duration, expires, col, glow)
            else
                HideAura(icon)
            end
        end

        SetCCPortrait(pf, FindCC(unit))

    	ApplyPetLortiTint(pf);
    end

    local function UpdateCastBar(pf)
        if previewOn then return end
        local unit    = pf.unit
        local castBar = pf.castBar
        if not PPF_Opts().showCast then
            castBar.endTime = nil
            castBar:Hide()
            return
        end

        local name, nameSubtext, text, texture, startTime, endTime,
              isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
        local isChannel = false
        if not name then
            name, nameSubtext, text, texture, startTime, endTime,
                isTradeSkill, notInterruptible = UnitChannelInfo(unit)
            isChannel = true
        end

        if name and type(startTime) == "number" and type(endTime) == "number" then

            castBar.startTime = startTime / 1000
            castBar.endTime   = endTime / 1000
            castBar.isChannel = isChannel

            castBar:SetMinMaxValues(castBar.startTime, castBar.endTime)
            castBar.text:SetText(name)
            if castBar.icon then
                castBar.icon:SetTexture(texture)
                if texture then castBar.icon:Show() else castBar.icon:Hide() end
            end
            castBar:SetStatusBarColor(notInterruptible and 1 or 0.7, notInterruptible and 0.3 or 0.7, notInterruptible and 0.3 or 0.2)
            castBar:Show()
        else
            castBar.endTime = nil
            castBar:Hide()
        end
    end

    local function UpdateAll()
        for i = 1, NUM_PETS do
            local pf = petFrames[i]
            if pf then
                UpdatePetFrame(pf)
                UpdateCastBar(pf)
            end
        end
    end

    local timeSinceLastUpdate = 0
    local function PPF_OnUpdate(self, elapsed)
        if previewOn then return end
        timeSinceLastUpdate = timeSinceLastUpdate + elapsed
        if timeSinceLastUpdate < 0.1 then return end
        timeSinceLastUpdate = 0
        for i = 1, NUM_PETS do
            local pf = petFrames[i]
            if pf and pf:IsShown() then
                UpdatePetFrame(pf)
                UpdateCastBar(pf)
            end
        end
    end

    local PPF_EVENTS = { "UNIT_HEALTH", "UNIT_MANA", "UNIT_MAXMANA", "UNIT_FOCUS", "UNIT_ENERGY", "UNIT_RAGE", "UNIT_HAPPINESS", "UNIT_PET", "PLAYER_ENTERING_WORLD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_DELAYED", "UNIT_AURA", "GROUP_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_BATTLEGROUND", "PLAYER_LEAVING_BATTLEGROUND", "INSTANCE_GROUP_SIZE_CHANGED", "UPDATE_INSTANCE_INFO" };

    local function PetFrameFor(unitID)
        if type(unitID) ~= "string" then return nil end
        local n = string.match(unitID, "^party(%d)pet$")
        if not n then return nil end
        return petFrames[tonumber(n)]
    end

    local function PetFrameForOwner(unitID)
        if type(unitID) ~= "string" then return nil end
        local n = string.match(unitID, "^party(%d)$")
        if not n then return nil end
        return petFrames[tonumber(n)]
    end

    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then

            PPF_ApplyVisibility(PPF_WantVisible)
            UpdateAll()
        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_LEAVING_BATTLEGROUND" or event == "INSTANCE_GROUP_SIZE_CHANGED" or event == "UPDATE_INSTANCE_INFO" then

            TimerAfter(0.5, function()
                PPF_ApplyVisibility(PPF_WantVisible)
                UpdateAll()
            end)
        elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            UpdateAll()
        elseif event == "UNIT_PET" then
            local pf = PetFrameForOwner(arg1)
            if pf then UpdatePetFrame(pf) end
        elseif event == "UNIT_AURA"
            or event == "UNIT_HEALTH" or event == "UNIT_MANA" or event == "UNIT_MAXMANA"
            or event == "UNIT_FOCUS" or event == "UNIT_ENERGY" or event == "UNIT_RAGE"
            or event == "UNIT_HAPPINESS" then
            local pf = PetFrameFor(arg1)
            if pf then UpdatePetFrame(pf) end
        elseif string.find(event, "UNIT_SPELLCAST") then
            local pf = PetFrameFor(arg1)
            if pf then UpdateCastBar(pf) end
        end
    end)

    local function ToggleLock()
        local o = PPF_Opts()
        o.locked = not o.locked
        if InCombatLockdown() then return end

        for i = 1, NUM_PETS do
            local f = petFrames[i]
            if f then
                if o.locked then
                    f:EnableMouse(o.clickable)
                    f.lockIndicator:Show()
                else
                    f:EnableMouse(true)
                    f.lockIndicator:Hide()
                end
            end
        end

        petFrames[1]:SetMovable(not o.locked)

    end

    local function PPF_ApplyClickable()
        if InCombatLockdown() then return end
        local o = PPF_Opts()
        for i = 1, NUM_PETS do
            local f = petFrames[i]
            if f then
                if o.clickable then
                    f:SetAttribute("type1", "target")
                else
                    f:SetAttribute("type1", nil)
                end
                if o.locked then f:EnableMouse(o.clickable) else f:EnableMouse(true) end
                if o.locked then f.lockIndicator:Show() else f.lockIndicator:Hide() end
            end
        end
        petFrames[1]:SetMovable(not o.locked)
    end

    local function ToggleClickable()
        local o = PPF_Opts()
        o.clickable = not o.clickable
        PPF_ApplyClickable()

        if o.clickable then
            print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_CLICK_ON"] or "Click enabled - click to target the pet"))
        else
            print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_CLICK_OFF"] or "Click disabled"))
        end
    end

    local function ResetPosition()
        local pos = PPF_DB()
        pos.point, pos.relPoint, pos.x, pos.y = "CENTER", "CENTER", DEF_X, DEF_Y
        PPF_Layout()
    end

    SLASH_PARTYPETFRAME1 = "/ppf"
    SLASH_PARTYPETFRAME2 = "/partypetframe"
    SlashCmdList["PARTYPETFRAME"] = function(msg)
        msg = string.lower(msg or "")

        if msg == "lock" or msg == "bloquear" then
            ToggleLock()
        elseif msg == "click" or msg == "clic" then
            ToggleClickable()
        elseif msg == "arena" then

            local on = not PPF_ArenaOnly()
            local o = PPF_Opts()
            o.inArena = true
            o.inBG, o.inWorld = not on, not on
            PPF_ApplyVisibility(PPF_WantVisible)
            if on then
                print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_ARENA_ONLY"] or "Arenas only"))
            else
                print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_EVERYWHERE"] or "Everywhere"))
            end
        elseif msg == "reset" then
            ResetPosition()
            print("|cff00ff00[PartyPetFrame]|r " .. (L["PPF_POS_RESET"] or "Position reset"))
        else
            print("|cff00ff00[PartyPetFrame] " .. (L["CMD_COMMANDS_TITLE"] or "Commands:") .. "|r")
            print("  /ppf lock - " .. (L["PPF_HELP_LOCK"] or "Lock/unlock the row"))
            print("  /ppf click - " .. (L["PPF_HELP_CLICK"] or "Enable/disable click to target"))
            print("  /ppf arena - " .. (L["PPF_HELP_ARENA"] or "Switch between arenas only and everywhere"))
            print("  /ppf reset - " .. (L["PPF_HELP_RESET"] or "Reset the row position"))
            print("  |cff8A8A8A" .. (L["PPF_HELP_DRAG"] or "Drag the top frame: the other three follow it.") .. "|r")
        end
    end

    local PREVIEW = {
    	{ icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf", owner = "HUNTER", cc = 118, ccLen = 8 },
    	{ icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter", owner = "WARLOCK", cast = 19647,
    	  debuffs = { { 980, "Curse", 24 } } },
    	{ icon = "Interface\\Icons\\Spell_Shadow_AnimateDead", owner = "DEATHKNIGHT",
    	  debuffs = { { 172, "Magic", 18 }, { 2818, "Poison", 12, 3 } } },
    	{ icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2", owner = "MAGE", far = true },
    }
    local PREVIEW_BUFFS = {
    	{ "Interface\\Icons\\Spell_Holy_WordFortitude", 1800 },
    	{ "Interface\\Icons\\Spell_Nature_Rejuvenation", 15 },
    }

    local function FillPreview(pf, i)
    	local p, o = PREVIEW[i], PPF_Opts()
    	local now = GetTime()
    	pf.portraitIcon:SetTexture(p.icon)
    	pf.name:SetText((L["PPF_PREVIEW_PET"] or "Pet") .. " " .. i)
    	pf.healthBar:SetMinMaxValues(0, 100); pf.healthBar:SetValue(90 - i * 12)
    	if o.hpText then
    		pf.hpText:SetFormattedText("%d / %d", (90 - i * 12) * 150, 15000)
    	else
    		pf.hpText:SetText("")
    	end
    	if o.ownerColor then pf.healthBar:SetStatusBarColor(OwnerColor(p.owner))
    	else pf.healthBar:SetStatusBarColor(0, 1, 0) end
    	pf.manaBar:SetMinMaxValues(0, 100); pf.manaBar:SetValue(70)
    	pf.manaBar:SetStatusBarColor(0, 0, 1)
    	pf:SetAlpha((o.rangeFade and p.far) and FADE_ALPHA or 1)
    	for n = 1, #pf.buffs do
    		local icon, b = pf.buffs[n], PREVIEW_BUFFS[n]
    		if o.showBuffs and b then
    			PlaceBuff(pf, n)
    			icon.cd.nufExp = nil
    			ShowAura(icon, o, b[1], nil, b[2], now + b[2] - n * 3, nil, nil, b[2])
    		else
    			HideAura(icon)
    		end
    	end
    	for n = 1, #pf.debuffs do
    		local icon, d = pf.debuffs[n], o.showDebuffs and p.debuffs and p.debuffs[n]
    		local tex = d and select(3, GetSpellInfo(d[1]))
    		if tex then
    			icon.cd.nufExp = nil
    			local glow = o.dispelGlow and CAN_DISPEL[d[2]]
    			ShowAura(icon, o, tex, d[4], d[3], now + d[3] - n * 2, DEBUFF_COLORS[d[2]], glow, d[3])
    		else
    			HideAura(icon)
    		end
    	end
    	local cb = pf.castBar
    	cb.endTime = nil
    	if o.showCast and p.cast then
    		local name, _, tex = GetSpellInfo(p.cast)
    		cb:SetMinMaxValues(0, 1); cb:SetValue(0.6)
    		cb.text:SetText(name or ""); cb.timeText:SetText("0.8")
    		if tex then cb.icon:SetTexture(tex); cb.icon:Show() end
    		cb:SetStatusBarColor(0.7, 0.7, 0.2)
    		cb:Show()
    	else
    		cb:Hide()
    	end
    	if p.cc then
    		local tex = select(3, GetSpellInfo(p.cc))
    		local now = GetTime()
    		pf.ccCD.nufExp = nil
    		SetCCPortrait(pf, tex, p.ccLen, now + p.ccLen, p.ccLen)
    	else
    		SetCCPortrait(pf, nil)
    	end
    	ApplyPetLortiTint(pf)
    end

    local previewWatch = CreateFrame("Frame")
    local PPF_SetPreview
    local previewAcc = 0
    local function PreviewTick(self, elapsed)
    	previewAcc = previewAcc + elapsed
    	if previewAcc < 0.1 then return end
    	previewAcc = 0
    	local now = GetTime()
    	for i = 1, NUM_PETS do
    		local pf = petFrames[i]
    		for n = 1, #pf.buffs do UpdateAuraTime(pf.buffs[n], now) end
    		for n = 1, #pf.debuffs do UpdateAuraTime(pf.debuffs[n], now) end
    	end
    end
    previewWatch:SetScript("OnEvent", function()

    	if previewOn then PPF_SetPreview(false) end
    end)

    function PPF_SetPreview(on)
    	on = on and true or false
    	if InCombatLockdown() then return previewOn end
    	if on == previewOn then return previewOn end
    	if on then
    		previewOn = true
    		for i = 1, NUM_PETS do
    			local f = petFrames[i]
    			if f.ppfWatching then
    				UnregisterUnitWatch(f)
    				f.ppfWatching = false
    			end
    			FillPreview(f, i)
    			f:Show()
    		end
    		previewWatch:RegisterEvent("PLAYER_REGEN_DISABLED")
    		previewWatch:SetScript("OnUpdate", PreviewTick)
    	else
    		previewOn = false
    		previewWatch:UnregisterEvent("PLAYER_REGEN_DISABLED")
    		previewWatch:SetScript("OnUpdate", nil)
    		for i = 1, NUM_PETS do
    			local f = petFrames[i]
    			f:Hide()
    			f:SetAlpha(1)
    			f.castBar:Hide()
    			SetCCPortrait(f, nil)
    			for n = 1, #f.buffs do HideAura(f.buffs[n]) end
    			for n = 1, #f.debuffs do HideAura(f.debuffs[n]) end
    		end
    		PPF_ApplyVisibility(PPF_WantVisible)
    		UpdateAll()
    	end
    	return previewOn
    end

    function K.GetPartyPetOption(key)
    	return PPF_Opts()[key]
    end

    function K.SetPartyPetOption(key, v)
    	local o = PPF_Opts()
    	if key == "borderStyle" then
    		if not BORDER_STYLES[v] then return end
    		o.borderStyle = v
    		K.SyncAllPartyPetAuraSizes()
    	elseif key == "frameStyle" then
    		if not FRAME_STYLES[v] then return end
    		o.frameStyle = v
    		for n = 1, NUM_PETS do ApplyPetFrameStyle(petFrames[n]) end
    	else
    		o[key] = v and true or false
    	end
    	if key == "clickable" or key == "locked" then PPF_ApplyClickable() end
    	if key == "rangeFade" and not o.rangeFade then
    		for i = 1, NUM_PETS do petFrames[i]:SetAlpha(1) end
    	end
    	if previewOn then
    		for i = 1, NUM_PETS do FillPreview(petFrames[i], i) end
    	else
    		UpdateAll()
    	end
    end

    function K.PartyPetCanDispel()
    	return next(CAN_DISPEL) ~= nil
    end

    function K.TogglePartyPetPreview()
    	return PPF_SetPreview(not previewOn)
    end

    function K.IsPartyPetPreview()
    	return previewOn
    end

    if K.RegisterModuleZones then
    	K.RegisterModuleZones("PartyPetFrame", PPF_Opts, function()
    		PPF_ApplyVisibility(PPF_WantVisible)
    	end)
    end

    if type(K.FramePositionOwners) ~= "table" then K.FramePositionOwners = {} end
    K.FramePositionOwners["PartyPets"] = function()
    	local f1 = petFrames[1]
    	if not f1 or InCombatLockdown() then return end
    	local l, t = f1:GetLeft(), f1:GetTop()
    	if not (l and t) then return end
    	local pos = PPF_DB()
    	pos.point, pos.relPoint, pos.x, pos.y = "TOPLEFT", "BOTTOMLEFT", l, t
    	PPF_Layout()
    end

    function K.SetPartyPetPreview(on)
    	return PPF_SetPreview(on)
    end

    if K.RegisterScalable then
    	K.RegisterScalable("PartyPetFrame", petFrames, 1.0)
    end

    function K.SyncAllPartyPetAuraSizes()
    	if InCombatLockdown() then
    		if K.AfterCombat then K.AfterCombat("PPFAuraSize", K.SyncAllPartyPetAuraSizes) end
    		return
    	end
    	for n = 1, NUM_PETS do K.SyncPartyPetAuraSize(petFrames[n]) end
    end
    if type(K.ApplyPartyFrameScale) == "function" then
    	hooksecurefunc(K, "ApplyPartyFrameScale", function() K.SyncAllPartyPetAuraSizes() end)
    end

    for _, fn in ipairs({ "SetModuleScale", "ResetModuleScale" }) do
    	if type(K[fn]) == "function" then
    		hooksecurefunc(K, fn, function(id)
    			if id == "PartyPetFrame" then K.SyncAllPartyPetAuraSizes() end
    		end)
    	end
    end

    local function PPF_SetEnabled(on)
        if on then
            K.SyncAllPartyPetAuraSizes()
            for _, e in ipairs(PPF_EVENTS) do pcall(frame.RegisterEvent, frame, e) end
            frame:SetScript("OnUpdate", PPF_OnUpdate)
            PPF_Layout()
            PPF_ApplyClickable()
            PPF_ApplyVisibility(true)
            UpdateAll()
        else
            PPF_SetPreview(false)
            frame:UnregisterAllEvents()
            frame:SetScript("OnUpdate", nil)
            PPF_ApplyVisibility(false)
        end
    end

    function K.TogglePartyPetFrameLock()
        ToggleLock()
    end

    function K.ResetPartyPetFramePosition()
        ResetPosition()
    end

    if K.LayoutRegisterStore then
        K.LayoutRegisterStore("PartyPetFrames", function()
            PPF_Layout()
        end)
    end

    K.RegisterModule("PartyPetFrame", {
        onEnable  = function() PPF_SetEnabled(true) end,
        onDisable = function() PPF_SetEnabled(false) end,
    });
end);
