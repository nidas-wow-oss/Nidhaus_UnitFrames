--[[
	PartyCastingBars - Adapted for Nidhaus_UnitFrames
	Original by: AnduinLothar / Mercedesa
	Adapted by: Nidhaus integration
	
	Changes from original:
	  - Uses NUF namespace (K, C, L) instead of standalone SavedVariables
	  - Removed ChatThrottleLib dependency (uses SendAddonMessage directly)
	  - Removed Khaos config block (NUF has its own options panel)
	  - Fixed texture path to point inside Nidhaus_UnitFrames folder
	  - Initialization hooked into CONFIG_LOADED instead of VARIABLES_LOADED
	  - EnableToggle uses local tracking var instead of broken global SavedVar
	  - Slash commands registered at parse-time (always available)
]]--

local AddOnName, ns = ...;
local K, C, L = unpack(ns);

--------------------------------------------------
-- Globals / Namespace
--------------------------------------------------

PartyCastingBars = {};

PartyCastingBars.ColorResetting = {};
PartyCastingBars.ColorResetting["FRIENDLY"] = {};
PartyCastingBars.ColorResetting["HOSTILE"] = {};

PartyCastingBars.Bars = {};

PartyCastingBars.DefaultColors = {
	["FRIENDLY"] = {
		["CAST"]    = { r=0.0, g=0.7, b=1.0 },  -- Light Blue
		["CHANNEL"] = { r=0.0, g=1.0, b=0.0 },  -- Green
		["SUCCESS"] = { r=0.0, g=1.0, b=0.0 },  -- Green
		["FAILURE"] = { r=1.0, g=0.0, b=0.0 },  -- Red
	},
	["HOSTILE"] = {
		["CAST"]    = { r=1.0, g=0.5, b=0.1 },  -- Orange
		["CHANNEL"] = { r=1.0, g=0.6, b=0.2 },  -- Orange
		["SUCCESS"] = { r=0.0, g=1.0, b=0.0 },  -- Green
		["FAILURE"] = { r=1.0, g=0.0, b=0.0 },  -- Red
	},
};

PartyCastingBars.TIME_LEFT       = "(%.1fs)";
PartyCastingBars.SPELL_AND_TARGET = "%s - %s";
PartyCastingBars.COMM_FORMAT     = "%s,%s,%s"; -- spellname, targetname, hostile/friendly

-- Color table (runtime only; saved as C.PCB_* via NUF DB)
PartyCastingBars_Colors = {
	["FRIENDLY"] = {
		["CAST"]    = { r=0.0, g=0.7, b=1.0 },
		["CHANNEL"] = { r=0.0, g=1.0, b=0.0 },
		["SUCCESS"] = { r=0.0, g=1.0, b=0.0 },
		["FAILURE"] = { r=1.0, g=0.0, b=0.0 },
	},
	["HOSTILE"] = {
		["CAST"]    = { r=1.0, g=0.5, b=0.1 },
		["CHANNEL"] = { r=1.0, g=0.6, b=0.2 },
		["SUCCESS"] = { r=0.0, g=1.0, b=0.0 },
		["FAILURE"] = { r=1.0, g=0.0, b=0.0 },
	},
};

-- Tag each color entry with its own extraInfo for the color picker
for reaction, info in pairs(PartyCastingBars_Colors) do
	for typeString, typeInfo in pairs(info) do
		typeInfo.extraInfo = { typeString = typeString, reaction = reaction };
	end
end

-- Local flag: tracks whether OnEvent/OnUpdate scripts are currently active on bars.
local PCB_IsActive = false;

-- Internal state (managed by the addon itself, NOT by ConfigManager)
local PCB_IconsEnabled = true;
local PCB_Parented     = true;
local PCB_Scale        = 0.7;

--------------------------------------------------
-- Guardado
--
-- Estas cuatro cosas — escala, iconos, anclaje y los ocho colores —
-- vivian solo en memoria y volvian al default en cada relogueo. El
-- comentario de arriba de la tabla de colores decia "saved as C.PCB_*
-- via NUF DB", pero eso no pasaba en ningun lado.
--
-- No van en ConfigManager porque los colores son una tabla anidada y
-- ese sistema copia los defaults por referencia y les aplica una
-- conversion de tipo. Van en su propia SavedVariable, como PartyBuffs.
--
-- SIEMPRE por la funcion, nunca cacheada en una local de archivo: la
-- SavedVariable recien existe en ADDON_LOADED, o sea DESPUES de que
-- corren todos los .lua. Guardarse la tabla ahora seria quedarse con
-- una huerfana que no se guarda nunca. Ya paso con ArenaPointsCalcDB.
--------------------------------------------------

local function PCB_DB()
	if type(PartyCastingBarsDB) ~= "table" then PartyCastingBarsDB = {}; end
	return PartyCastingBarsDB;
end

local function PCB_SaveColors()
	local db = PCB_DB();
	db.colors = {};
	for reaction, types in pairs(PartyCastingBars_Colors) do
		db.colors[reaction] = {};
		for typeString, info in pairs(types) do
			db.colors[reaction][typeString] = { r = info.r, g = info.g, b = info.b };
		end
	end
end

local function PCB_LoadSaved()
	local db = PCB_DB();
	if type(db.scale)    == "number"  then PCB_Scale        = db.scale;    end
	if type(db.icons)    == "boolean" then PCB_IconsEnabled = db.icons;    end
	if type(db.parented) == "boolean" then PCB_Parented     = db.parented; end

	if type(db.colors) ~= "table" then return; end
	for reaction, types in pairs(PartyCastingBars_Colors) do
		local saved = db.colors[reaction];
		if type(saved) == "table" then
			for typeString, info in pairs(types) do
				local c = saved[typeString];
				if type(c) == "table" and type(c.r) == "number" then
					info.r, info.g, info.b = c.r, c.g, c.b;
				end
			end
		end
	end
end

-- Lo que necesita el menu (PCB_Menu.lua) para dibujarse al dia.
function PartyCastingBars.GetIcons()    return PCB_IconsEnabled; end
function PartyCastingBars.GetParented() return PCB_Parented; end
function PartyCastingBars.GetScale()    return PCB_Scale; end
function PartyCastingBars.IsDragging()  return PartyCastingBars.draggable == true; end
function PartyCastingBars.SaveColors()  PCB_SaveColors(); end
function PartyCastingBars.GetDB()       return PCB_DB(); end

function PartyCastingBars.ResetAllColors()
	for reaction, types in pairs(PartyCastingBars_Colors) do
		for typeString in pairs(types) do
			PartyCastingBars.ResetBarColor(reaction, typeString);
		end
	end
	PCB_SaveColors();
end

--------------------------------------------------
-- Color Utilities
--------------------------------------------------

local function colorToString(color)
	if not color then return "FFFFFFFF"; end
	return string.format("%.2X%.2X%.2X%.2X",
		(color.a or color.opacity or 1) * 255,
		(color.r or 0) * 255,
		(color.g or 0) * 255,
		(color.b or 0) * 255
	);
end

local function setBarColor()
	local r, g, b = ColorPickerFrame:GetColorRGB();
	local reaction   = ColorPickerFrame.extraInfo.reaction;
	local typeString = ColorPickerFrame.extraInfo.typeString;
	local info = PartyCastingBars_Colors[reaction][typeString];
	info.r = r; info.g = g; info.b = b;
	PCB_SaveColors();
	if PartyCastingBars.RefreshMenu then PartyCastingBars.RefreshMenu(); end
end

local function cancelBarColorChange()
	local color = ColorPickerFrame.previousValues;
	local reaction   = ColorPickerFrame.extraInfo.reaction;
	local typeString = ColorPickerFrame.extraInfo.typeString;
	local info = PartyCastingBars_Colors[reaction][typeString];
	info.r = color.r; info.g = color.g; info.b = color.b;
	PCB_SaveColors();
	if PartyCastingBars.RefreshMenu then PartyCastingBars.RefreshMenu(); end
end

function PartyCastingBars.ResetBarColor(reaction, typeString)
	local default = PartyCastingBars.DefaultColors[reaction][typeString];
	local info = PartyCastingBars_Colors[reaction][typeString];
	info.r = default.r; info.g = default.g; info.b = default.b;
	PCB_SaveColors();
	if PartyCastingBars.RefreshMenu then PartyCastingBars.RefreshMenu(); end
end

function PartyCastingBars.OpenColorPicker(info)
	ColorPickerFrame.hasOpacity  = nil;
	ColorPickerFrame.opacityFunc = nil;
	ColorPickerFrame.opacity     = 1;
	ColorPickerFrame.previousValues = { r = info.r + 0, g = info.g + 0, b = info.b + 0, opacity = 1 };
	ColorPickerFrame.func        = setBarColor;
	ColorPickerFrame.cancelFunc  = cancelBarColorChange;
	ColorPickerFrame.extraInfo   = info.extraInfo;
	ShowUIPanel(ColorPickerFrame);
	ColorPickerFrame:SetColorRGB(info.r, info.g, info.b);
end

function PartyCastingBars.GetColorArgs(database)
	return database.r, database.g, database.b;
end

--------------------------------------------------
-- Party Member Caching
--------------------------------------------------

PartyCastingBars.PartyMembers   = {};
PartyCastingBars.HostilityCache = {};

function PartyCastingBars.CachePartyMembers()
	PartyCastingBars.PartyMembers = {};
	for i = 1, 4 do
		local unit = "party"..i;
		if UnitExists(unit) then
			local name = UnitName(unit);
			PartyCastingBars.PartyMembers[name] = i;
			PartyCastingBars.HostilityCache[name] = UnitCanAttack("player", unit);
		end
	end
	if UnitInRaid("player") then
		for i = 1, 40 do
			local unit = "raid"..i;
			if UnitExists(unit) then
				local name = UnitName(unit);
				PartyCastingBars.HostilityCache[name] = UnitCanAttack("player", unit);
			end
		end
	end
end

--------------------------------------------------
-- EventFrame Scripts
--------------------------------------------------

function PartyCastingBars.EventFrameOnLoad(frame)
	-- BUG FIX: Removed VARIABLES_LOADED (initialization now via CONFIG_LOADED hook).
	-- Only register the runtime events here.
	frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	frame:RegisterEvent("PARTY_MEMBERS_CHANGED");
	frame:RegisterEvent("PLAYER_TARGET_CHANGED");
	frame:RegisterEvent("UNIT_SPELLCAST_SENT");
	frame:RegisterEvent("CHAT_MSG_ADDON");
end

--------------------------------------------------
-- Reset de barras colgadas
--
-- BUG: al entrar a una arena la barra se quedaba pegada (p.ej. "Crimson
-- Deathcharger" a 0.0s y sin desvanecerse). Motivo: durante la pantalla de
-- carga la barra deja de recibir OnUpdate y el UNIT_SPELLCAST_STOP del
-- lanzamiento se pierde, asi que se queda con estado a medias y visible.
-- Nada en el modulo la devolvia a cero.
--------------------------------------------------

function PartyCastingBars.ResetBar(bar)
	if not bar then return; end
	bar.casting     = nil;
	bar.channeling  = nil;
	bar.flash       = nil;
	bar.fadeOut     = nil;
	bar.holdTime    = 0;
	bar.targetName  = nil;
	bar.hostileCast = nil;
	bar.nextTargetName  = nil;
	bar.nextHostileCast = nil;
	if bar.barSpark then bar.barSpark:Hide(); end
	if bar.barFlash then bar.barFlash:SetAlpha(0.0); bar.barFlash:Hide(); end
	bar:SetAlpha(1.0);
	bar:Hide();
end

-- onlyMissing = true  -> solo las barras cuya unidad ya no existe.
function PartyCastingBars.ResetAllBars(onlyMissing)
	if PartyCastingBars.draggable then return; end   -- en modo mover deben quedarse
	for i, bar in ipairs(PartyCastingBars.Bars) do
		if (not onlyMissing) or (bar.unit and not UnitExists(bar.unit)) then
			PartyCastingBars.ResetBar(bar);
		end
	end
end

function PartyCastingBars.EventFrameOnEvent(event, newarg1, newarg2, newarg3, newarg4)
	if event == "PLAYER_ENTERING_WORLD" then
		-- Cambio de zona (arena, mazmorra, portal...): lo que hubiera en curso
		-- ya no vale y su evento de fin se perdio en la carga.
		PartyCastingBars.ResetAllBars(false);
		PartyCastingBars.CachePartyMembers();

	elseif event == "PARTY_MEMBERS_CHANGED" then
		-- Aca solo se limpian las barras de gente que ya no esta, para no
		-- cortar el lanzamiento de los que siguen en el grupo.
		PartyCastingBars.ResetAllBars(true);
		PartyCastingBars.CachePartyMembers();

	elseif event == "PLAYER_TARGET_CHANGED" then
		if UnitExists("target") then
			PartyCastingBars.HostilityCache[UnitName("target")] = UnitCanAttack("player", "target");
		end

	elseif event == "UNIT_SPELLCAST_SENT" then
		-- arg1=unit, arg2=spellName, arg3=rank, arg4=targetName
		if newarg2 and newarg4 then
			-- BUG FIX: Removed ChatThrottleLib (not a dep of NUF). Use SendAddonMessage directly.
			if PartyCastingBars.HostilityCache[newarg4] then
				SendAddonMessage("PartyCastingBars", format(PartyCastingBars.COMM_FORMAT, newarg2, newarg4, "hostile"),  "PARTY");
			else
				SendAddonMessage("PartyCastingBars", format(PartyCastingBars.COMM_FORMAT, newarg2, newarg4, "friendly"), "PARTY");
			end
		end

	elseif event == "CHAT_MSG_ADDON" then
		-- prefix, msg, distribution, sender
		if newarg1 == "PartyCastingBars" then
			local partyNum = PartyCastingBars.PartyMembers[newarg4];
			if partyNum then
				local _, _, spellName, targetName, relationship = strfind(newarg2, "^(.+),(.+),(.+)$");
				if spellName and targetName and relationship then
					-- BUG FIX: replaced deprecated getglobal() with _G[]
					local frame = _G["PartyMemberFrame"..partyNum.."CastingBarFrame"];
					if frame then
						frame.targetName = targetName;
						frame.hostileCast = (relationship == "hostile");
						PartyCastingBars.OnEvent(frame, "UNIT_SPELLCAST_TARGET_CHANGED", "party"..partyNum, spellName);
					end
				end
			end
		end
	end
end

--------------------------------------------------
-- Bar Scripts
--------------------------------------------------

function PartyCastingBars.OnLoad(bar)
	bar:RegisterEvent("UNIT_SPELLCAST_START");
	bar:RegisterEvent("UNIT_SPELLCAST_STOP");
	bar:RegisterEvent("UNIT_SPELLCAST_FAILED");
	bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
	bar:RegisterEvent("UNIT_SPELLCAST_DELAYED");
	bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
	bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
	bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");

	bar:RegisterForDrag("LeftButton");

	bar.partyFrame  = bar:GetParent();
	-- GetAttribute("unit") is the safe way; .unit is the old Blizzard convention
	bar.unit        = bar:GetParent().unit or bar:GetParent():GetAttribute("unit");
	bar.showTradeSkills = true;
	bar.casting     = nil;
	bar.channeling  = nil;
	bar.holdTime    = 0;
	bar.showCastbar = true;

	local barName = bar:GetName();

	-- Text
	local text = _G[barName.."Text"];
	if text then
		text:ClearAllPoints();
		text:SetPoint("CENTER", bar, "CENTER", 0, 0);
		bar.barText = text;
	end

	-- Border
	local border = _G[barName.."Border"];
	if border then
		border:SetTexture("Interface\\Tooltips\\UI-StatusBar-Border");
		border:SetWidth(202);
		border:SetHeight(28);
		border:ClearAllPoints();
		border:SetPoint("CENTER", bar, "CENTER", 0, 0);
		bar.border = border;
	end

	-- Flash  (BUG FIX: texture path now points inside Nidhaus_UnitFrames)
	local flash = _G[barName.."Flash"];
	if flash then
		flash:SetTexture("Interface\\AddOns\\Nidhaus_UnitFrames\\Modules2\\PartyCastingBars\\Skin\\ArcaneBarFlash");
		flash:SetWidth(292);
		flash:SetHeight(34);
		flash:ClearAllPoints();
		flash:SetPoint("CENTER", bar, "CENTER", 0, 0);
		bar.barFlash = flash;
	end

	-- Icon
	local icon = _G[barName.."Icon"];
	if icon then
		icon:Show();
		bar.barIcon = icon;
	end

	-- Spark
	bar.barSpark = _G[barName.."Spark"];

	-- Time font string (defined as $parentTime in XML)
	bar.barTime = _G[barName.."Time"];

	tinsert(PartyCastingBars.Bars, bar);
end

function PartyCastingBars.GetTimeLeft(bar)
	local min, max = bar:GetMinMaxValues();
	local current_time;
	if bar.channeling then
		current_time = bar:GetValue() - min;
	else
		current_time = max - bar:GetValue();
	end
	return format(PartyCastingBars.TIME_LEFT, math.max(current_time, 0));
end

function PartyCastingBars.OnEvent(bar, event, unit, spellName)
	if unit ~= bar.unit then return; end

	local barSpark = bar.barSpark;
	local barText  = bar.barText;
	local barFlash = bar.barFlash;
	local barIcon  = bar.barIcon;

	if event == "UNIT_SPELLCAST_START" then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(bar.unit);
		if not name or (not bar.showTradeSkills and isTradeSkill) then
			bar:Hide();
			return;
		end

		bar.hostileCast = bar.nextHostileCast;
		bar.targetName  = bar.nextTargetName;

		if bar.hostileCast then
			bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["CAST"]));
		else
			bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["CAST"]));
		end
		barSpark:Show();
		bar.startTime = startTime / 1000;
		bar.maxValue  = endTime  / 1000;
		bar:SetMinMaxValues(bar.startTime, bar.maxValue);
		bar:SetValue(bar.startTime);
		if bar.targetName then
			barText:SetText(format(PartyCastingBars.SPELL_AND_TARGET, text, bar.targetName));
		else
			barText:SetText(text);
		end
		barIcon:SetTexture(texture);
		bar:SetAlpha(1.0);
		bar.holdTime  = 0;
		bar.casting   = 1;
		bar.channeling = nil;
		bar.fadeOut   = nil;
		if bar.showCastbar then
			bar:Show();
		end
		return;

	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if not bar:IsVisible() then
			bar:Hide();
		end
		if bar:IsShown() then
			local min, max = bar:GetMinMaxValues();
			local currTimeLeft = max - bar:GetValue();
			if currTimeLeft > 0.1 and not bar.channeling then
				-- Treat as interrupted
				event = "UNIT_SPELLCAST_INTERRUPTED";
			else
				barSpark:Hide();
				barFlash:SetAlpha(0.0);
				barFlash:Show();
				bar:SetValue(bar.maxValue);
				if event == "UNIT_SPELLCAST_STOP" then
					if bar.casting then
						if bar.hostileCast then
							bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["SUCCESS"]));
						else
							bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["SUCCESS"]));
						end
					end
					bar.casting = nil;
				else
					bar.channeling = nil;
				end
				bar.flash    = 1;
				bar.fadeOut  = 1;
				bar.holdTime = 0;
			end
			bar.targetName  = nil;
			bar.hostileCast = nil;
		end
	end

	if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		if bar:IsShown() and not bar.channeling then
			if not bar.maxValue then return; end
			bar:SetValue(bar.maxValue);
			if bar.hostileCast then
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["FAILURE"]));
			else
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["FAILURE"]));
			end
			barSpark:Hide();
			bar.casting    = nil;
			bar.channeling = nil;
			bar.fadeOut    = 1;
			bar.holdTime   = GetTime() + CASTING_BAR_HOLD_TIME;
			bar.targetName  = nil;
			bar.hostileCast = nil;
		end

	elseif event == "UNIT_SPELLCAST_TARGET_CHANGED" then
		-- Fake event generated by the addon-message system
		if not spellName then return; end
		if bar:IsShown() then
			local min, max = bar:GetMinMaxValues();
			local currTimeLeft = max - bar:GetValue();
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill;
			if bar.casting then
				name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(bar.unit);
			elseif bar.channeling then
				name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(bar.unit);
			end
			if spellName == name and currTimeLeft > 0.1 then
				if bar.casting then
					if bar.hostileCast then
						bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["CAST"]));
					else
						bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["CAST"]));
					end
				elseif bar.channeling then
					if bar.hostileCast then
						bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["CHANNEL"]));
					else
						bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["CHANNEL"]));
					end
				end
				if bar.targetName then
					barText:SetText(format(PartyCastingBars.SPELL_AND_TARGET, text, bar.targetName));
				else
					barText:SetText(text);
				end
				return;
			end
		end
		bar.nextHostileCast = bar.hostileCast;
		bar.nextTargetName  = bar.targetName;

	elseif event == "UNIT_SPELLCAST_DELAYED" then
		if bar:IsShown() then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(bar.unit);
			if not name or (not bar.showTradeSkills and isTradeSkill) then
				bar:Hide();
				return;
			end
			bar.startTime = startTime / 1000;
			bar.maxValue  = endTime  / 1000;
			bar:SetMinMaxValues(bar.startTime, bar.maxValue);
		end

	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(bar.unit);
		if not name or (not bar.showTradeSkills and isTradeSkill) then
			bar:Hide();
			return;
		end
		bar.hostileCast = bar.nextHostileCast;
		bar.targetName  = bar.nextTargetName;
		if bar.hostileCast then
			bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["CHANNEL"]));
		else
			bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["CHANNEL"]));
		end
		barSpark:Show();
		bar.startTime = startTime / 1000;
		bar.endTime   = endTime   / 1000;
		bar.duration  = bar.endTime - bar.startTime;
		bar.maxValue  = bar.startTime;
		bar:SetMinMaxValues(bar.startTime, bar.endTime);
		bar:SetValue(bar.endTime);
		if bar.targetName then
			barText:SetText(format(PartyCastingBars.SPELL_AND_TARGET, text, bar.targetName));
		else
			barText:SetText(text);
		end
		barIcon:SetTexture(texture);
		bar:SetAlpha(1.0);
		bar.holdTime   = 0;
		bar.casting    = nil;
		bar.channeling = 1;
		bar.fadeOut    = nil;
		if bar.showCastbar then
			bar:Show();
		end

	elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
		if bar:IsShown() then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(bar.unit);
			if not name or (not bar.showTradeSkills and isTradeSkill) then
				bar:Hide();
				return;
			end
			bar.startTime = startTime / 1000;
			bar.endTime   = endTime   / 1000;
			bar.maxValue  = bar.startTime;
			bar:SetMinMaxValues(bar.startTime, bar.endTime);
		end
	end
end

function PartyCastingBars.OnUpdate(bar)
	if PartyCastingBars.draggable then return; end

	if bar.casting then
		local status = GetTime();
		if status > bar.maxValue then status = bar.maxValue; end
		if status == bar.maxValue then
			bar:SetValue(bar.maxValue);
			if bar.hostileCast then
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["SUCCESS"]));
			else
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["SUCCESS"]));
			end
			bar.barSpark:Hide();
			bar.barFlash:SetAlpha(0.0);
			bar.barFlash:Show();
			bar.casting = nil;
			bar.flash   = 1;
			bar.fadeOut = 1;
			return;
		end
		bar:SetValue(status);
		bar.barFlash:Hide();
		local sparkPosition = ((status - bar.startTime) / (bar.maxValue - bar.startTime)) * bar:GetWidth();
		if sparkPosition < 0 then sparkPosition = 0; end
		bar.barSpark:SetPoint("CENTER", bar, "LEFT", sparkPosition, 0);
		bar.barTime:SetText(PartyCastingBars.GetTimeLeft(bar));

	elseif bar.channeling then
		local time = GetTime();
		if time > bar.endTime then time = bar.endTime; end
		if time == bar.endTime then
			if bar.hostileCast then
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["SUCCESS"]));
			else
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["SUCCESS"]));
			end
			bar.barSpark:Hide();
			bar.barFlash:SetAlpha(0.0);
			bar.barFlash:Show();
			bar.channeling = nil;
			bar.flash  = 1;
			bar.fadeOut = 1;
			return;
		end
		local barValue = bar.startTime + (bar.endTime - time);
		bar:SetValue(barValue);
		bar.barFlash:Hide();
		local sparkPosition = ((barValue - bar.startTime) / (bar.endTime - bar.startTime)) * bar:GetWidth();
		bar.barSpark:SetPoint("CENTER", bar, "LEFT", sparkPosition, 0);
		bar.barTime:SetText(PartyCastingBars.GetTimeLeft(bar));

	elseif GetTime() < bar.holdTime then
		return;
	elseif bar.flash then
		local alpha = bar.barFlash:GetAlpha() + CASTING_BAR_FLASH_STEP;
		if alpha < 1 then
			bar.barFlash:SetAlpha(alpha);
		else
			bar.barFlash:SetAlpha(1.0);
			bar.flash = nil;
		end
	elseif bar.fadeOut then
		local alpha = bar:GetAlpha() - CASTING_BAR_ALPHA_STEP;
		if alpha > 0 then
			bar:SetAlpha(alpha);
		else
			bar.fadeOut = nil;
			bar:Hide();
		end

	elseif bar:IsShown() then
		-- Red de seguridad: visible pero sin lanzamiento, canalizacion, flash
		-- ni fade pendientes = barra colgada. Antes se quedaba asi para
		-- siempre porque ninguna rama la tocaba. Se comprueba ademas contra
		-- la API por si el evento de fin llego a perderse.
		if not (UnitCastingInfo(bar.unit) or UnitChannelInfo(bar.unit)) then
			PartyCastingBars.ResetBar(bar);
		end
	end
end

function PartyCastingBars.OnDragStart(bar, button)
	if not PartyCastingBars.draggable then return; end
	bar:StartMoving();
end

function PartyCastingBars.OnDragStop(bar)
	bar:StopMovingOrSizing();
end

function PartyCastingBars.OnHide(bar)
	bar:StopMovingOrSizing();
end

--------------------------------------------------
-- Master Enable / Disable
-- BUG FIX: Uses PCB_IsActive (local) instead of PartyCastingBars_Enabled (broken global).
-- OptionsPanelFrames calls K.SaveConfig("PCB_Enabled", val) THEN EnableToggle(val).
-- PCB_IsActive tracks the actual script state so double-calls are safe.
--------------------------------------------------

function PartyCastingBars.EnableToggle(value)
	if value then
		if not PCB_IsActive then
			for i, barFrame in ipairs(PartyCastingBars.Bars) do
				barFrame:SetScript("OnEvent", function(self, event, ...)
					PartyCastingBars.OnEvent(self, event, ...);
				end);
				barFrame:SetScript("OnUpdate", function(self)
					PartyCastingBars.OnUpdate(self);
				end);
			end
			PCB_IsActive = true;
		end
	else
		-- Desactivar scripts, drag mode y ocultar barras
		PartyCastingBars.draggable = false;
		for i, barFrame in ipairs(PartyCastingBars.Bars) do
			barFrame:SetScript("OnEvent", nil);
			barFrame:SetScript("OnUpdate", nil);
			barFrame:EnableMouse(false);
			barFrame:Hide();
		end
		PCB_IsActive = false;
	end
end

--------------------------------------------------
-- Icon Toggle
--------------------------------------------------

function PartyCastingBars.EnableIcons(value)
	PCB_IconsEnabled = value;
	PCB_DB().icons = value and true or false;
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		if barFrame.barIcon then
			if value then barFrame.barIcon:Show();
			else           barFrame.barIcon:Hide(); end
		end
	end
	-- Al final, no al principio: si no, el menu se repinta con el
	-- estado viejo y la casilla queda al reves de lo que pasa.
	if PartyCastingBars.RefreshMenu then PartyCastingBars.RefreshMenu(); end
end

--------------------------------------------------
-- Parent Toggle
--------------------------------------------------

function PartyCastingBars.SetParents(value)
	PCB_Parented = value;
	PCB_DB().parented = value and true or false;
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		barFrame:SetParent(value and barFrame.partyFrame or UIParent);
	end
	if PartyCastingBars.RefreshMenu then PartyCastingBars.RefreshMenu(); end
end

--------------------------------------------------
-- Scale
--------------------------------------------------

function PartyCastingBars.SetScales(value)
	PCB_Scale = value;
	PCB_DB().scale = value;
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		barFrame:SetScale(value);
	end
end

--------------------------------------------------
-- Draggable Mode
-- BUG FIX: Added nil guards on bar sub-elements.
--------------------------------------------------

function PartyCastingBars.EnableDragging(value)
	if value and not C.PCB_Enabled then
		DEFAULT_CHAT_FRAME:AddMessage("PCB - Enable PartyCastingBars first (/pcb enable).", 1, 0.5, 0);
		return;
	end
	PartyCastingBars.draggable = (value == true);
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		if PartyCastingBars.draggable then
			barFrame:Show();
			if barFrame.barText  then barFrame.barText:SetText((PCB_DRAGGABLE or "Draggable").." #"..i); end
			if barFrame.barSpark then barFrame.barSpark:Hide(); end
			if barFrame.barTime  then
				barFrame.barTime:SetText(format(PartyCastingBars.TIME_LEFT, 15));
				barFrame.barTime:Show();
			end
			if barFrame.barIcon then
				barFrame.barIcon:SetTexture("Interface\\Icons\\Spell_Holy_PowerWordShield");
			end
			barFrame:SetAlpha(1);
			barFrame:EnableMouse(true);
		else
			barFrame:Hide();
			barFrame:EnableMouse(false);
		end
	end
end

--------------------------------------------------
-- Reset Bar Locations
--------------------------------------------------

function PartyCastingBars.ResetBarLocations()
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		barFrame:ClearAllPoints();
		barFrame:SetPoint("TOPLEFT", barFrame.partyFrame, "TOPRIGHT", 7, 2);
	end
end

--------------------------------------------------
-- Initialization (via NUF CONFIG_LOADED)
-- BUG FIX: Removed VARIABLES_LOADED path. We hook NUF's own config event so
-- C.PCB_Enabled is guaranteed to be populated when we apply initial state.
--------------------------------------------------

local function PCB_ApplyInitialState()
	-- Enable / disable scripts
	if C.PCB_Enabled then
		for i, barFrame in ipairs(PartyCastingBars.Bars) do
			barFrame:SetScript("OnEvent", function(self, event, ...)
				PartyCastingBars.OnEvent(self, event, ...);
			end);
			barFrame:SetScript("OnUpdate", function(self)
				PartyCastingBars.OnUpdate(self);
			end);
		end
		PCB_IsActive = true;
	else
		for i, barFrame in ipairs(PartyCastingBars.Bars) do
			barFrame:SetScript("OnEvent", nil);
			barFrame:SetScript("OnUpdate", nil);
			barFrame:Hide();
		end
		PCB_IsActive = false;
	end

	-- Lo guardado manda sobre los defaults del archivo. Va ANTES de los
	-- tres Enable/Set de abajo, que son los que lo aplican a las barras.
	PCB_LoadSaved();

	-- Apply internal defaults
	PartyCastingBars.EnableIcons(PCB_IconsEnabled);
	PartyCastingBars.SetParents(PCB_Parented);
	PartyCastingBars.SetScales(PCB_Scale);

	PartyCastingBars.CachePartyMembers();
end

-- Hook into NUF's CONFIG_LOADED. At that point C[] is fully populated.
-- We defer one more frame to PLAYER_LOGIN so all bar frames are definitely created.
K.RegisterConfigEvent("CONFIG_LOADED", function()
	local waitFrame = CreateFrame("Frame");
	waitFrame:RegisterEvent("PLAYER_LOGIN");
	waitFrame:SetScript("OnEvent", function(self)
		self:UnregisterEvent("PLAYER_LOGIN");
		PCB_ApplyInitialState();
	end);
end);

-- Also react to CONFIG_CHANGED so the options panel checkbox takes effect live
K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if not PCB_IsActive and C.PCB_Enabled then
		PartyCastingBars.EnableToggle(true);
	elseif PCB_IsActive and not C.PCB_Enabled then
		PartyCastingBars.EnableToggle(false);
	end
end);

--------------------------------------------------
-- Slash Commands
-- BUG FIX: Registered at parse-time (not inside RegisterConfig/VARIABLES_LOADED).
-- This guarantees /pcb drag (and all other commands) work immediately after login.
--------------------------------------------------

SLASH_PARTYCASTINGBARS1 = "/partycastingbars";
SLASH_PARTYCASTINGBARS2 = "/pcb";

-- =====================================================================
-- /pcb  ->  abre el menu.
--
-- Los subcomandos siguen andando (drag, icon, scale, parent, reset):
-- no cuestan nada y sirven para macros. Lo que cambia es que /pcb
-- pelado ya no imprime una lista de ayuda que nadie lee, sino que
-- abre la ventana donde estan todos.
-- =====================================================================
SlashCmdList["PARTYCASTINGBARS"] = function(msg)
	-- Con PCB apagado no hay barras que configurar. Antes esto era un
	-- return mudo: escribias /pcb y no pasaba nada, sin explicacion.
	if not C.PCB_Enabled then
		DEFAULT_CHAT_FRAME:AddMessage(
			"PCB - Party Cast Bars is turned off. Turn it on in Frames > Party.", 1, 0.5, 0);
		return;
	end

	msg = msg or "";
	local parts = { strsplit(" ", string.upper(msg)) };
	local cmd        = parts[1] or "";
	local reaction   = parts[2];
	local typeString = parts[3];

	if cmd == "ICON" then
		local newState = not PCB_IconsEnabled;
		PartyCastingBars.EnableIcons(newState);
		if newState then
			DEFAULT_CHAT_FRAME:AddMessage(PCB_SHOWNICONFEEDBACK_POSITIVE or "Icons shown.", 0, 1, 1);
		else
			DEFAULT_CHAT_FRAME:AddMessage(PCB_SHOWNICONFEEDBACK_NEGATIVE or "Icons hidden.", 1, 1, 0);
		end

	elseif cmd == "SCALE" then
		local val = tonumber(parts[2]);
		if val and val >= 0.5 and val <= 2.0 then
			PartyCastingBars.SetScales(val);
			DEFAULT_CHAT_FRAME:AddMessage(format("PCB - Bar scale set to %.1f", val), 0, 1, 1);
		else
			DEFAULT_CHAT_FRAME:AddMessage("PCB - Usage: /pcb scale <0.5 - 2.0>", 1, 1, 0);
		end

	elseif cmd == "DRAG" then
		PartyCastingBars.EnableDragging(not PartyCastingBars.draggable);
		if PartyCastingBars.draggable then
			DEFAULT_CHAT_FRAME:AddMessage(PCB_DRAGGABLE_POSITIVE or "Bars in drag mode.", 0, 1, 1);
		else
			DEFAULT_CHAT_FRAME:AddMessage(PCB_DRAGGABLE_NEGATIVE or "Bars in cast mode.", 1, 1, 0);
		end

	elseif cmd == "PARENT" then
		local newState = not PCB_Parented;
		PartyCastingBars.SetParents(newState);
		if newState then
			DEFAULT_CHAT_FRAME:AddMessage(PCB_PARTYMEMBERFRAME_PARENT_POSITIVE or "Bars parented to party frames.", 0, 1, 1);
		else
			DEFAULT_CHAT_FRAME:AddMessage(PCB_PARTYMEMBERFRAME_PARENT_NEGATIVE or "Bars parented to UIParent.", 1, 1, 0);
		end

	elseif cmd == "RESET" then
		if reaction and typeString
		and PartyCastingBars.DefaultColors[reaction]
		and PartyCastingBars.DefaultColors[reaction][typeString] then
			PartyCastingBars.ResetBarColor(reaction, typeString);
		else
			PartyCastingBars.ResetBarLocations();
			DEFAULT_CHAT_FRAME:AddMessage(PCB_LOCATIONS_RESET or "Bar locations reset.", 0, 1, 0);
		end

	elseif cmd == "SET" and reaction and typeString
	and PartyCastingBars_Colors[reaction]
	and PartyCastingBars_Colors[reaction][typeString] then
		PartyCastingBars.OpenColorPicker(PartyCastingBars_Colors[reaction][typeString]);

	elseif cmd == "" then
		if PartyCastingBars.ToggleMenu then PartyCastingBars.ToggleMenu(); end

	elseif cmd == "HELP" then
		DEFAULT_CHAT_FRAME:AddMessage("PartyCastingBars (/pcb) commands:", 0, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("  (no argument) — Open the options window");
		DEFAULT_CHAT_FRAME:AddMessage("  drag    — Toggle drag/position mode");
		DEFAULT_CHAT_FRAME:AddMessage("  icon    — Toggle spell icons");
		DEFAULT_CHAT_FRAME:AddMessage("  scale <0.5-2.0> — Set bar scale");
		DEFAULT_CHAT_FRAME:AddMessage("  parent  — Toggle frame parenting");
		DEFAULT_CHAT_FRAME:AddMessage("  reset   — Reset bar positions");
	else
		DEFAULT_CHAT_FRAME:AddMessage(PCB_INVALID_COMMAND or "Unknown PCB command. Type /pcb help.", 0.5, 0.5, 0.5);
	end
end