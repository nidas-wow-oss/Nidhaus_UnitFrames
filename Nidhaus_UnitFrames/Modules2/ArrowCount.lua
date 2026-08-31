local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ArrowCount.lua  (portado a NUF)
-- Muestra la cantidad de flechas / balas que tenes en las bolsas.
-- Mover: Alt + click izquierdo y arrastrar.
-- Comandos: /arrowcount show | hide | reset | scale <n>
-- =========================================================

local arrowIDs = {
	[2512] = true, [2515] = true, [3030] = true, [3031] = true,
	[52021] = true, [41165] = true,
};
local bulletIDs = {
	[2516] = true, [2519] = true, [52020] = true, [32782] = true,
	[3464] = true, [41164] = true,
};

local enabled = false;

-- ---------------------------------------------------------
-- Frame
-- ---------------------------------------------------------
-- Mismo aspecto que el addon original: recuadro con backdrop y borde,
-- icono cubriendo el frame y el numero en blanco abajo a la derecha.
local frame = CreateFrame("Frame", "NUF_ArrowCountFrame", UIParent);
frame:SetSize(64, 64);
frame:Hide();
frame:SetMovable(true);
-- Transparente al mouse salvo mientras se lo acomoda (boton "Move").
-- Con EnableMouse fijo en true el recuadro se comia los clicks de lo
-- que tuviera detras aunque ya estuviera en su lugar.
frame:EnableMouse(false);
frame:SetClampedToScreen(true);

frame:SetBackdrop({
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
});
frame:SetBackdropColor(0, 0, 0, 0.5);

frame.icon = frame:CreateTexture(nil, "ARTWORK");
frame.icon:SetAllPoints();

frame.count = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
frame.count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5);
frame.count:SetText("0");

-- ---------------------------------------------------------
-- Posicion / escala guardadas en la DB de NUF
-- ---------------------------------------------------------
local function DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ArrowCount then
		NidhausUnitFramesDB.ArrowCount = {};
	end
	return NidhausUnitFramesDB.ArrowCount;
end

local function SavePosition()
	local db = DB();
	local point, _, relativePoint, x, y = frame:GetPoint();
	db.point = point; db.relativePoint = relativePoint; db.x = x; db.y = y;
end

local function RestorePosition()
	-- Este frame tiene DOS lugares donde puede quedar guardada su posicion:
	-- el store propio (arrastre con Alt) y el de "Mover todo" (globalPos).
	-- Si lo moviste con el modo mover, la posicion vive alla; restaurar la
	-- de aca lo mandaba de vuelta al default en cada toggle del modulo.
	local gp = NidhausUnitFramesDB and NidhausUnitFramesDB.globalPos;
	if gp and gp.ArrowCount and gp.ArrowCount.point then
		if K.RestoreGlobalPositions then pcall(K.RestoreGlobalPositions); end
		return;
	end

	local db = DB();
	frame:ClearAllPoints();
	if db.point then
		frame:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y);
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 300, -180);
	end
	frame:SetScale(db.scale or 1);
end

frame:RegisterForDrag("LeftButton");
frame:SetScript("OnDragStart", function(self)
	if IsAltKeyDown() then self:StartMoving(); end
end);
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing();
	SavePosition();
end);

-- ---------------------------------------------------------
-- Deteccion de munición
-- ---------------------------------------------------------
local function GetEquippedAmmoType()
	local slotID = GetInventorySlotInfo("RangedSlot");
	if not slotID then return nil; end
	local itemID = GetInventoryItemID("player", slotID);
	if not itemID then return nil; end

	local _, _, _, _, _, _, itemSubType, _, _, _, _, classID, subClassID = GetItemInfo(itemID);

	-- classID 2 = arma. subClassID: 2 = arcos, 3 = armas de fuego, 18 = ballestas
	if classID == 2 and subClassID then
		if subClassID == 3 then
			return "bullet";
		elseif subClassID == 2 or subClassID == 18 then
			return "arrow";
		end
	end

	-- Fallback por texto (otros idiomas / servers que no devuelven classID)
	if itemSubType then
		local st = string.lower(itemSubType);
		if string.find(st, "gun") or string.find(st, "arma de fuego") or string.find(st, "fusil") then
			return "bullet";
		elseif string.find(st, "bow") or string.find(st, "arco") or string.find(st, "ballesta") then
			return "arrow";
		end
	end

	return nil;
end

local function UpdateDisplay()
	if not enabled then frame:Hide(); return; end

	local ammoType = GetEquippedAmmoType();
	if not ammoType then frame:Hide(); return; end

	local ids = (ammoType == "bullet") and bulletIDs or arrowIDs;
	local total, texture = 0, nil;

	for bag = 0, 4 do
		local slots = GetContainerNumSlots(bag) or 0;
		for slot = 1, slots do
			local id = GetContainerItemID(bag, slot);
			if id and ids[id] then
				local _, count = GetContainerItemInfo(bag, slot);
				total = total + (count or 0);
				if not texture then texture = GetItemIcon(id); end
			end
		end
	end

	if total > 0 then
		frame.count:SetText(total);
		frame.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark");
		frame:Show();
	else
		frame:Hide();
	end
end

-- ---------------------------------------------------------
-- Eventos
-- ---------------------------------------------------------
local events = CreateFrame("Frame");

-- Se registran solo con el modulo activo (BAG_UPDATE dispara mucho)
local function RegisterArrowEvents()
	events:RegisterEvent("PLAYER_ENTERING_WORLD");
	events:RegisterEvent("BAG_UPDATE");
	events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	events:RegisterEvent("UNIT_INVENTORY_CHANGED");
end

-- Al entrar al mundo los items todavia no estan cacheados: reintentar
local retry = CreateFrame("Frame");
local retryAcc, retryCount = 0, 0;
retry:Hide();
retry:SetScript("OnUpdate", function(self, elapsed)
	retryAcc = retryAcc + elapsed;
	if retryAcc < 0.5 then return; end
	retryAcc = 0;
	retryCount = retryCount + 1;
	UpdateDisplay();
	if retryCount >= 4 then self:Hide(); end
end);

events:SetScript("OnEvent", function(self, event)
	if not enabled then return; end
	if event == "PLAYER_ENTERING_WORLD" then
		RestorePosition();
		retryAcc, retryCount = 0, 0;
		retry:Show();
	else
		UpdateDisplay();
	end
end);

-- ---------------------------------------------------------
-- Comandos
-- ---------------------------------------------------------
SLASH_NUFARROWCOUNT1 = "/arrowcount";
SlashCmdList["NUFARROWCOUNT"] = function(msg)
	msg = string.lower(msg or "");
	if msg == "hide" then
		frame:Hide();
	elseif msg == "show" then
		UpdateDisplay();
	elseif msg == "reset" then
		local db = DB();
		db.point, db.relativePoint, db.x, db.y, db.scale = nil, nil, nil, nil, nil;
		RestorePosition();
		print("|cff4FC3F7NUF:|r ArrowCount - posición y escala reiniciadas.");
	elseif string.match(msg, "^scale%s+[%d%.]+") then
		local scale = tonumber(string.match(msg, "^scale%s+([%d%.]+)"));
		if scale and scale > 0 then
			DB().scale = scale;
			frame:SetScale(scale);
			print("|cff4FC3F7NUF:|r ArrowCount - escala: " .. scale);
		end
	else
		print("|cff4FC3F7NUF:|r /arrowcount show | hide | reset | scale <n>   (Alt + arrastrar para mover)");
	end
end


function K.ResetArrowCountPosition()
	local db = DB();
	db.point, db.relativePoint, db.x, db.y, db.scale = nil, nil, nil, nil, nil;
	RestorePosition();
end

-- ---------------------------------------------------------
-- Registro del modulo
-- ---------------------------------------------------------
K.RegisterModule("ArrowCount", {
	name    = L["MOD_ARROWCOUNT"] or "Arrow / Bullet Count",
	desc    = L["MOD_ARROWCOUNT_DESC"] or "Shows how much ammo you have left. Alt + drag to move.",
	default = false,
	configLabel = L["BTN_MODULE_MOVE"] or "Move",
	configFunc = function()
		-- Mostrarlo aunque no haya municion equipada, para poder ubicarlo.
		-- Mientras dura este modo se enciende el mouse para poder arrastrarlo.
		RestorePosition();
		frame:EnableMouse(true);
		if frame:IsShown() then
			UpdateDisplay();
			print("|cff4FC3F7NUF:|r ArrowCount - Alt + arrastrar para moverlo.");
		else
			frame.icon:SetTexture("Interface\\Icons\\INV_Ammo_Arrow_02");
			frame.count:SetText("---");
			frame:Show();
			print("|cff4FC3F7NUF:|r ArrowCount - modo prueba. Alt + arrastrar para moverlo.");
		end
	end,
	onEnable = function()
		enabled = true;
		RegisterArrowEvents();
		RestorePosition();
		UpdateDisplay();
	end,
	onDisable = function()
		enabled = false;
		events:UnregisterAllEvents();
		frame:EnableMouse(false);
		frame:Hide();
	end,
});
