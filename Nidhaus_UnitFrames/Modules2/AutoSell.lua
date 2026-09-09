-- AutoSell - Vende grises automaticamente al abrir vendor
-- Credit: FatalEntity | Integrated into NUF by Nidhaus
local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local frame = CreateFrame("Frame");

local function OnMerchantShow()
	if not C.AutoSellGray then return; end

	local totalSold = 0;
	local itemCount = 0;

	for bagIndex = 0, 4 do
		if GetContainerNumSlots(bagIndex) > 0 then
			for slotIndex = 1, GetContainerNumSlots(bagIndex) do
				if select(2, GetContainerItemInfo(bagIndex, slotIndex)) then
					local itemLink = GetContainerItemLink(bagIndex, slotIndex);
					local quality = select(3, string.find(itemLink, "(|c%x+)"));
					if quality == ITEM_QUALITY_COLORS[0].hex then
						-- FIX: Track sell value before selling
						local _, stackCount = GetContainerItemInfo(bagIndex, slotIndex);
						local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemLink);
						if sellPrice and sellPrice > 0 and stackCount then
							totalSold = totalSold + (sellPrice * stackCount);
						end
						itemCount = itemCount + 1;
						UseContainerItem(bagIndex, slotIndex);
					end
				end
			end
		end
	end

	-- FIX: Show feedback so user knows what happened (matches AutoRepair style)
	if itemCount > 0 and totalSold > 0 then
		local gold   = math.floor(totalSold / 10000);
		local silver = math.floor(totalSold / 100) % 100;
		local copper = totalSold % 100;
		local costStr;
		if gold > 0 then
			costStr = string.format("%d|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", gold, silver, copper);
		elseif silver > 0 then
			costStr = string.format("%d|cffc7c7cfs|r %d|cffeda55fc|r", silver, copper);
		else
			costStr = string.format("%d|cffeda55fc|r", copper);
		end
		print(string.format("|cff00FF00NUF:|r Sold %d gray item%s for %s.", itemCount, itemCount > 1 and "s" or "", costStr));
	end
end

frame:RegisterEvent("MERCHANT_SHOW");
frame:SetScript("OnEvent", function(self, event)
	if event == "MERCHANT_SHOW" then
		OnMerchantShow();
	end
end);