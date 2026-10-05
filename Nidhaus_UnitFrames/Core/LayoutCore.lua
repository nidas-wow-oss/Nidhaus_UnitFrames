local AddOnName, ns = ...;
local K, C, L = unpack(ns);

































































local stores    = {};
local rebuilding = false;
local pendingCombat = false;



function K.LayoutRegisterStore(name, applyFn)
	if type(name) ~= "string" or type(applyFn) ~= "function" then return false; end
	for _, s in ipairs(stores) do


		if s.name == name then s.apply = applyFn; return true; end
	end
	stores[#stores + 1] = { name = name, apply = applyFn };
	return true;
end

function K.LayoutStoreNames()
	local out = {};
	for i, s in ipairs(stores) do out[i] = s.name; end
	return out;
end








local function ActiveMode()
	if C.MiniBarEnabled  == true then return "mini";  end
	if C.UnifyActionBars == true then return "unify"; end
	return "plain";
end
K.LayoutActiveMode = ActiveMode;




function K.LayoutRebuild(reason)


	if InCombatLockdown() then
		pendingCombat = true;
		return false;
	end




	if rebuilding then return false; end
	rebuilding = true;
















	if K._minibarActive and K.DisableMiniBar then
		pcall(K.DisableMiniBar);
	end
	if K._unifyActive and K.DisableUnifyActionBars then
		pcall(K.DisableUnifyActionBars);
	end




















	local mode = ActiveMode();
	if mode == "mini" then
		if K.EnableMiniBar then pcall(K.EnableMiniBar); end
	elseif mode == "unify" then
		if K.EnableUnifyActionBars then pcall(K.EnableUnifyActionBars); end
	else


		if K.RestoreBarBaseline then pcall(K.RestoreBarBaseline); end
	end



	if K.RestoreGlobalPositions then pcall(K.RestoreGlobalPositions); end
	for _, s in ipairs(stores) do pcall(s.apply); end

	rebuilding = false;
	return true;
end


local combat = CreateFrame("Frame");
combat:RegisterEvent("PLAYER_REGEN_ENABLED");
combat:SetScript("OnEvent", function()
	if not pendingCombat then return; end
	pendingCombat = false;
	K.LayoutRebuild("fin de combate");
end);
