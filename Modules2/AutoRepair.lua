-- AutoRepair - Repara automaticamente al abrir vendor
-- Credit: Nidhaus | Integrated into NUF
local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local frame = CreateFrame("Frame");

local function OnMerchantShow()
	if not C.AutoRepair then return; end
	if not CanMerchantRepair() then return; end

	local cost = GetRepairAllCost();
	if cost <= 0 or IsShiftKeyDown() then return; end

	if cost > GetMoney() then
		print("|cffFF0000NUF:|r Insufficient funds to repair!");
		return;
	end

	local gold   = floor(math.abs(cost) / 10000);
	local silver = mod(floor(math.abs(cost) / 100), 100);
	local copper = mod(floor(math.abs(cost)), 100);

	local costStr;
	if gold ~= 0 then
		costStr = format("%s|cffffd700g|r %s|cffc7c7cfs|r %s|cffeda55fc|r", gold, silver, copper);
	elseif silver ~= 0 then
		costStr = format("%s|cffc7c7cfs|r %s|cffeda55fc|r", silver, copper);
	else
		costStr = format("%s|cffeda55fc|r", copper);
	end

	-- Intentar con banco de guild primero
	if CanGuildBankRepair() then
		RepairAllItems(1);
		if GetRepairAllCost() == 0 then
			print(format("|cff00FF00NUF:|r Repaired (guild bank) for %s.", costStr));
			return;
		end
	end

	-- Reparar con fondos propios
	if GetRepairAllCost() > 0 then
		RepairAllItems();
		print(format("|cff00FF00NUF:|r Repaired for %s.", costStr));
	end
end

frame:RegisterEvent("MERCHANT_SHOW");
frame:SetScript("OnEvent", function(self, event)
	if event == "MERCHANT_SHOW" then
		OnMerchantShow();
	end
end);
