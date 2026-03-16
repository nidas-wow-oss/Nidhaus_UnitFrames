local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- ModuleManager.lua - Sistema de registro y gestión de módulos

K.Modules = {};
K.ModuleOrder = {};

function K.RegisterModule(id, info)
	if not id or not info then
		print(L["MM_REGISTER_ERROR"]);
		return;
	end

	if K.Modules[id] then
		return;
	end

	K.Modules[id] = {
		name      = info.name or id,
		desc      = info.desc or "",
		onEnable  = info.onEnable,
		onDisable = info.onDisable,
		createUI  = info.createUI or nil,
		default   = (info.default ~= false),
		hideFromModulesTab = info.hideFromModulesTab or false,
	};

	table.insert(K.ModuleOrder, id);
end

function K.IsModuleEnabled(id)
	if not NidhausUnitFramesDB or not NidhausUnitFramesDB.Modules then return false; end
	local val = NidhausUnitFramesDB.Modules[id];
	if val == nil then
		return K.Modules[id] and K.Modules[id].default or false;
	end
	return val == true;
end

function K.SetModuleEnabled(id, enabled)
	if not K.Modules[id] then return false; end

	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.Modules then NidhausUnitFramesDB.Modules = {}; end

	NidhausUnitFramesDB.Modules[id] = enabled;

	local mod = K.Modules[id];
	if enabled and mod.onEnable then
		local ok, err = pcall(mod.onEnable);
		if not ok then print(L["MM_ERROR_ENABLING"]..id..": "..tostring(err)); end
	elseif not enabled and mod.onDisable then
		local ok, err = pcall(mod.onDisable);
		if not ok then print(L["MM_ERROR_DISABLING"]..id..": "..tostring(err)); end
	end

	return true;
end

function K.InitializeModules()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.Modules then NidhausUnitFramesDB.Modules = {}; end

	for _, id in ipairs(K.ModuleOrder) do
		local mod = K.Modules[id];

		if NidhausUnitFramesDB.Modules[id] == nil then
			NidhausUnitFramesDB.Modules[id] = mod.default;
		end

		local enabled = NidhausUnitFramesDB.Modules[id];

		if enabled and mod.onEnable then
			local ok, err = pcall(mod.onEnable);
			if not ok then
				print(L["MM_ERROR_INIT"]..id..": "..tostring(err));
			end
		end
	end
end

function K.ListModules()
	print(L["MM_LIST_HEADER"]);
	if #K.ModuleOrder == 0 then
		print(L["MM_LIST_EMPTY"]);
		print(L["MM_LIST_HINT"]);
	else
		for _, id in ipairs(K.ModuleOrder) do
			local mod = K.Modules[id];
			local enabled = K.IsModuleEnabled(id);
			local status = enabled and "|cff00FF00ON|r" or "|cffFF0000OFF|r";
			print("  ["..status.."] |cffFFFFFF"..mod.name.."|r - "..mod.desc);
		end
	end
	print("");
end

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN");
		K.InitializeModules();
	end
end);