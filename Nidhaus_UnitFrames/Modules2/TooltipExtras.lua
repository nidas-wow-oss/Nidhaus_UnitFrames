local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- TooltipExtras.lua
--
-- Tres agregados al tooltip:
--
--   1) Experiencia de arena  (idea original de Fernir)
--      El mejor rating personal de 2v2, 3v3 y 5v5 del jugador que estas
--      mirando. Sale de comparar ESTADISTICAS DE LOGROS, que es la unica
--      via en 3.3.5: el servidor no manda el rating de nadie mas.
--
--   2) Talentos               (base: TipTacTalents, de Aezay) — arbol principal y reparto 0/0/0 del objetivo.
--
--   3) Borde por calidad
--      El borde del tooltip toma el color de la calidad del objeto.
--
-- DIFERENCIA IMPORTANTE CON EL ORIGINAL: alla cada archivo hacia
-- "if C.Tooltip.X ~= true then return end" en la primera linea, o sea que
-- prender o apagar exigia recargar la interfaz. Aca los enganches se
-- instalan una sola vez y cada uno consulta su opcion EN EL MOMENTO, asi
-- los checkbox del panel hacen efecto al toque.
-- =========================================================

local _G = _G;
local format, tonumber, select, ipairs, pairs = string.format, tonumber, select, ipairs, pairs;
local gtt = GameTooltip;

local function On(key) return C[key] == true; end

-- ---------------------------------------------------------
-- 1) EXPERIENCIA DE ARENA
-- ---------------------------------------------------------
-- Ids de estadistica de logro con el rating personal mas alto por modalidad.
local ARENA_STATS = {
	370,   -- 2 contra 2
	595,   -- 3 contra 3
	596,   -- 5 contra 5
};

-- El nombre de cada linea sale de GetAchievementInfo, o sea del cliente.
-- En Warmane el bracket de 5 se usa para el Solo Queue, asi que esa linea
-- se renombra; las otras dos quedan con el texto del juego.
local ARENA_STAT_LABELS = {
	[596] = L["TT_SOLO_QUEUE"] or "Solo Queue",
};

-- Verde a rojo segun el valor: 0 rojo, 100+ verde. Es del original.
local function Gradient(val, low, high)
	local percent, r, g;
	if high > low then
		percent = val / (high - low);
	else
		percent = 1 - val / (low - high);
	end
	if percent > 1 then percent = 1; end
	if percent < 0 then percent = 0; end
	if percent < 0.5 then
		r, g = 1, 2 * percent;
	else
		r, g = (1 - percent) * 2, 1;
	end
	return format("|cff%02x%02x%02x%s|r", r * 255, g * 255, 0, val);
end

local arenaFrame = CreateFrame("Frame");
local arenaUnit;

arenaFrame:SetScript("OnEvent", function(self, event)
	if event ~= "INSPECT_ACHIEVEMENT_READY" then return; end
	if not GetComparisonAchievementPoints() then return; end

	local shown = false;
	for _, id in ipairs(ARENA_STATS) do
		local v = tonumber(GetComparisonStatistic(id));
		if v and v > 0 then
			gtt:AddDoubleLine(ARENA_STAT_LABELS[id] or select(2, GetAchievementInfo(id)), Gradient(v, 0, 100));
			shown = true;
		end
	end
	if shown then gtt:Show(); end

	-- GearScore usa el mismo evento: se lo devolvemos.
	if _G.GearScore then _G.GearScore:RegisterEvent("INSPECT_ACHIEVEMENT_READY"); end

	self:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
	ClearAchievementComparisonUnit();
end);

local function ArenaOnSetUnit()
	if not On("TooltipArenaExp") then return; end
	-- En combate no: la comparacion de logros es una consulta al servidor.
	if InCombatLockdown() then return; end
	-- Con el panel de logros abierto se pisan la comparacion.
	if AchievementFrame and AchievementFrame:IsShown() then return; end

	arenaUnit = select(2, gtt:GetUnit());
	if not arenaUnit or not UnitIsPlayer(arenaUnit) then return; end

	if _G.GearScore then _G.GearScore:UnregisterEvent("INSPECT_ACHIEVEMENT_READY"); end
	ClearAchievementComparisonUnit();
	arenaFrame:RegisterEvent("INSPECT_ACHIEVEMENT_READY");
	SetAchievementComparisonUnit(arenaUnit);
end

local function ArenaOnCleared()
	if arenaFrame:IsEventRegistered("INSPECT_ACHIEVEMENT_READY") then
		arenaFrame:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
		ClearAchievementComparisonUnit();
	end
end

-- ---------------------------------------------------------
-- 2) TALENTOS
-- ---------------------------------------------------------
local CACHE_SIZE = 25;
local talFrame   = CreateFrame("Frame");
local cache, current = {}, {};

local function TalentsPrefix()
	return (TALENTS or "Talents") .. ":|cffffffff ";
end

local function GatherTalents(isInspect)
	local group = GetActiveTalentGroup(isInspect);
	local maxTree = 1;
	for i = 1, 3 do
		local _, _, pts = GetTalentTabInfo(i, isInspect, nil, group);
		current[i] = pts or 0;
		if current[i] > current[maxTree] then maxTree = i; end
	end
	current.tree = GetTalentTabInfo(maxTree, isInspect, nil, group);

	if current[maxTree] == 0 then
		current.format = L["TOOLTIP_NO_TALENT"] or "No talents";
	else
		current.format = (current.tree or "?")
			.. " (" .. current[1] .. "/" .. current[2] .. "/" .. current[3] .. ")";
	end

	local prefix = TalentsPrefix();
	if not isInspect then
		gtt:AddLine(prefix .. current.format);
	elseif gtt:GetUnit() then
		-- Inspeccion: la linea ya estaba puesta como "Cargando...", se
		-- reemplaza en su lugar en vez de agregar otra.
		for i = 2, gtt:NumLines() do
			local fs = _G["GameTooltipTextLeft" .. i];
			if fs and (fs:GetText() or ""):match("^" .. TALENTS) then
				fs:SetFormattedText("%s%s", prefix, current.format);
				if not gtt.fadeOut then gtt:Show(); end
				break;
			end
		end
	end

	-- Cache por nombre, para no re-inspeccionar a cada rato.
	for i = #cache, 1, -1 do
		if current.name == cache[i].name then table.remove(cache, i); break; end
	end
	if #cache > CACHE_SIZE then table.remove(cache, 1); end
	cache[#cache + 1] = {
		name = current.name, tree = current.tree, format = current.format,
		current[1], current[2], current[3],
	};
end

talFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("INSPECT_TALENT_READY");
	if gtt:GetUnit() == current.name then
		GatherTalents(1);
	end
end);

local function TalentsOnSetUnit()
	if not On("TooltipTalents") then return; end

	local _, unit = gtt:GetUnit();
	if not unit then
		local mFocus = GetMouseFocus();
		if mFocus and mFocus.unit then unit = mFocus.unit; end
	end
	if not unit or not UnitIsPlayer(unit) then return; end
	-- Por debajo de 10 no hay talentos que mostrar.
	if not (UnitLevel(unit) > 9 or UnitLevel(unit) == -1) then return; end
	if not CanInspect(unit) then return; end

	for k in pairs(current) do current[k] = nil; end
	current.name = UnitName(unit);

	if UnitIsUnit(unit, "player") then
		GatherTalents();
		return;
	end

	-- Si la ventana de inspeccion esta abierta, NotifyInspect se la rompe.
	local allowInspect = (not InspectFrame or not InspectFrame:IsShown())
		and (not Examiner or not Examiner:IsShown());
	if allowInspect then
		talFrame:RegisterEvent("INSPECT_TALENT_READY");
		NotifyInspect(unit);
	end

	for _, entry in ipairs(cache) do
		if current.name == entry.name then
			gtt:AddLine(TalentsPrefix() .. entry.format);
			current.tree, current.format = entry.tree, entry.format;
			current[1], current[2], current[3] = entry[1], entry[2], entry[3];
			return;
		end
	end

	if allowInspect then
		gtt:AddLine(TalentsPrefix() .. (L["TOOLTIP_LOADING"] or "Loading..."));
	end
end

-- ---------------------------------------------------------
-- 3) BORDE POR CALIDAD DE OBJETO
-- ---------------------------------------------------------
-- Lo habitual es hacerlo dentro de un skin propio de tooltips. NUF no skinea
-- tooltips, asi que se usa el backdrop que el tooltip YA trae de fabrica:
-- SetBackdropBorderColor alcanza y no hace falta tocar la textura.
--
-- El color original se guarda al cargar y se repone al limpiar, para que
-- apagar la opcion (o pasar el mouse por algo que no es objeto) devuelva
-- el borde de siempre.
local QUALITY_TIPS = {
	"GameTooltip", "ItemRefTooltip",
	"ShoppingTooltip1", "ShoppingTooltip2", "ShoppingTooltip3",
};
local defaultBorder = {};

local function SaveDefaultBorder(tip)
	if defaultBorder[tip] then return; end
	if not tip.GetBackdropBorderColor then return; end
	local r, g, b, a = tip:GetBackdropBorderColor();
	defaultBorder[tip] = { r or 1, g or 1, b or 1, a or 1 };
end

local function ResetBorder(tip)
	local d = defaultBorder[tip];
	if d and tip.SetBackdropBorderColor then
		tip:SetBackdropBorderColor(d[1], d[2], d[3], d[4]);
	end
end

local function QualityOnSetItem(tip)
	if not tip.SetBackdropBorderColor then return; end
	SaveDefaultBorder(tip);
	if not On("TooltipQualityBorder") then ResetBorder(tip); return; end

	local _, link = tip:GetItem();
	local quality = link and select(3, GetItemInfo(link));
	-- Solo de poco comun para arriba: gris y blanco quedan como estaban,
	-- si no todo objeto vulgar pintaba el borde de gris oscuro.
	if quality and quality >= 2 then
		local r, g, b = GetItemQualityColor(quality);
		tip:SetBackdropBorderColor(r, g, b);
	else
		ResetBorder(tip);
	end
end

-- ---------------------------------------------------------
-- 4) QUIEN LANZO EL BUFF / DEBUFF
--    (idea original de Renstrom)
--
-- El octavo valor que devuelve UnitAura/UnitBuff/UnitDebuff es la unidad
-- que lanzo el aura. Con eso se agrega una linea al tooltip del icono.
--
-- Cambios respecto al original: alla usaba DONE_BY y
-- BETTER_FACTION_BAR_COLORS, que son de su propio addon; aca la etiqueta
-- sale de la localizacion de NUF y los colores de facciones del global de
-- Blizzard, con guarda por si no existe.
-- ---------------------------------------------------------
local function ClassColor(unit)
	local _, class = UnitClass(unit);
	local t = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS or {})[class or ""];
	return t;
end

local function AuraSource(tip, apiFunc, unit, index, filter)
	if not On("AuraCastBy") then return; end
	local src = select(8, apiFunc(unit, index, filter));
	if not src then return; end

	local name = GetUnitName(src, true);
	if not name then return; end

	-- Mascotas: se aclara de quien son, que si no aparece solo el nombre
	-- de la mascota y no se sabe a quien pertenece.
	if src == "pet" or src == "vehicle" then
		name = format("%s (%s)", name, GetUnitName("player", true) or "");
	else
		local pp = src:match("^partypet(%d+)$");
		local rp = src:match("^raidpet(%d+)$");
		if pp then
			name = format("%s (%s)", name, GetUnitName("party" .. pp, true) or "");
		elseif rp then
			name = format("%s (%s)", name, GetUnitName("raid" .. rp, true) or "");
		end
	end

	local color;
	if UnitIsPlayer(src) then
		color = ClassColor(src);
	elseif FACTION_BAR_COLORS then
		color = FACTION_BAR_COLORS[UnitReaction(src, "player") or 4];
	end
	if color then
		name = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name);
	end

	tip:AddLine((L["TOOLTIP_CAST_BY"] or "Cast by:") .. " " .. name);
	tip:Show();
end

local AURA_FUNCS = {
	SetUnitAura   = UnitAura,
	SetUnitBuff   = UnitBuff,
	SetUnitDebuff = UnitDebuff,
};

for method, apiFunc in pairs(AURA_FUNCS) do
	if gtt[method] then
		hooksecurefunc(gtt, method, function(self, unit, index, filter)
			AuraSource(self, apiFunc, unit, index, filter);
		end);
	end
end


-- ---------------------------------------------------------
-- 4) ICONO EN EL TOOLTIP  (Modules/Tooltip/Elements/Icons.lua)
-- ---------------------------------------------------------
-- Pone la imagen del objeto o del hechizo al lado de su nombre, en la
-- primera linea del tooltip.
--
-- COMO: no se agrega una textura al frame — se mete un codigo de textura
-- DENTRO del texto de la linea:
--
--     |T<ruta>:20:20:0:0:64:64:5:59:5:59|t Nombre del objeto
--
-- Los ultimos cuatro numeros recortan un par de pixeles de cada borde,
-- que es lo que le saca el marco gris que traen los iconos del juego.
--
-- Se hace asi porque la primera linea del tooltip es un FontString con
-- ancho automatico: cualquier textura suelta anclada al costado se
-- superpondria con el texto o quedaria fuera del recuadro.
local ICON_CROP = "0:0:64:64:5:59:5:59";

-- Marca por tooltip para no reescribir la linea dos veces. OnTooltipSetItem
-- puede dispararse mas de una vez para el mismo objeto (al refrescar el
-- tooltip), y sin esto se apilaban dos y tres iconos en la misma linea.
local iconDone = setmetatable({}, { __mode = "k" });

local function SetTooltipIcon(tip, icon)
	if not icon then return; end
	local name = tip.GetName and tip:GetName();
	if not name then return; end
	local title = _G[name .. "TextLeft1"];
	local text  = title and title:GetText();
	if not text or text == "" then return; end
	title:SetFormattedText("|T%s:20:20:" .. ICON_CROP .. "|t %s", icon, text);
end

local function IconOnSetItem(self)
	if not On("TooltipIcons") then return; end
	if iconDone[self] then return; end
	if not self.GetItem then return; end

	local _, link = self:GetItem();
	if not link then return; end
	-- GetItemIcon acepta el link entero en 3.3.5a.
	local icon = GetItemIcon and GetItemIcon(link);
	if icon then
		SetTooltipIcon(self, icon);
		iconDone[self] = true;
	end
end

local function IconOnSetSpell(self)
	if not On("TooltipIcons") then return; end
	if iconDone[self] then return; end
	if not self.GetSpell then return; end

	-- En 3.3.5a GetSpell devuelve nombre, rango e id (en 4.x pasa a
	-- devolver solo el id). Se contemplan las dos formas.
	local a, _, c = self:GetSpell();
	local icon;
	if type(a) == "number" then
		icon = select(3, GetSpellInfo(a));
	elseif type(c) == "number" then
		icon = select(3, GetSpellInfo(c));
	elseif type(a) == "string" then
		icon = select(3, GetSpellInfo(a));
	end
	if icon then
		SetTooltipIcon(self, icon);
		iconDone[self] = true;
	end
end

local function IconOnCleared(self)
	iconDone[self] = nil;
end

-- Los mismos tooltips que ya usa el borde por calidad, mas el del chat.
for _, name in ipairs(QUALITY_TIPS) do
	local tip = _G[name];
	if tip and tip.HookScript then
		tip:HookScript("OnTooltipSetItem",  IconOnSetItem);
		tip:HookScript("OnTooltipSetSpell", IconOnSetSpell);
		tip:HookScript("OnTooltipCleared",  IconOnCleared);
	end
end

-- ---------------------------------------------------------
-- Enganches (una sola vez)
-- ---------------------------------------------------------
gtt:HookScript("OnTooltipSetUnit", function()
	ArenaOnSetUnit();
	TalentsOnSetUnit();
end);

gtt:HookScript("OnTooltipCleared", function(self)
	ArenaOnCleared();
	ResetBorder(self);
end);

for _, name in ipairs(QUALITY_TIPS) do
	local tip = _G[name];
	if tip and tip.HookScript then
		SaveDefaultBorder(tip);
		tip:HookScript("OnTooltipSetItem", QualityOnSetItem);
		tip:HookScript("OnHide", ResetBorder);
	end
end

-- Al cambiar una opcion en el panel no hace falta re-enganchar nada: los
-- hooks ya consultan C en cada llamada. Lo unico util es devolver el borde
-- si acaban de apagar la opcion mientras habia un tooltip abierto.
K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if not On("TooltipQualityBorder") then
		for tip in pairs(defaultBorder) do ResetBorder(tip); end
	end
end);
