local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local registry = {};

local function ScaleDB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ModuleScales then
		NidhausUnitFramesDB.ModuleScales = {};
	end
	return NidhausUnitFramesDB.ModuleScales;
end

local function AsList(frame)
	if type(frame) ~= "table" then return nil; end
	if frame.SetScale then return { frame }; end
	local out = {};
	for _, f in ipairs(frame) do
		if type(f) == "table" and f.SetScale then out[#out + 1] = f; end
	end
	return (#out > 0) and out or nil;
end

function K.RegisterScalable(id, frame, default)
	if not id or not frame then return; end
	local list = AsList(frame);
	if not list then return; end
	registry[id] = { frames = list, frame = list[1], default = default or 1.0 };

	local saved = ScaleDB()[id];
	if type(saved) == "number" and saved > 0 then
		for _, f in ipairs(list) do pcall(f.SetScale, f, saved); end
	end
end

function K.IsScalable(id)
	return registry[id] ~= nil;
end

function K.SetScalableCentered(id, onMoved)
	local entry = registry[id];
	if not entry then return; end
	entry.centered = true;
	entry.onMoved = onMoved;
end

local function ApplyScale(entry, value)
	for _, f in ipairs(entry.frames or { entry.frame }) do
		local cx, cy;
		if entry.centered and (f:GetNumPoints() or 0) > 0 then cx, cy = f:GetCenter(); end
		if cx then
			local s0 = f:GetEffectiveScale();
			pcall(f.SetScale, f, value);
			local s1 = f:GetEffectiveScale();
			if s1 and s1 > 0 then
				f:ClearAllPoints();
				f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx * s0 / s1, cy * s0 / s1);
			end
			if entry.onMoved then pcall(entry.onMoved, f); end
		else
			pcall(f.SetScale, f, value);
			if entry.centered and entry.onMoved then pcall(entry.onMoved, f); end
		end
	end
end

function K.GetModuleScale(id)
	local entry = registry[id];
	local saved = ScaleDB()[id];
	if type(saved) == "number" and saved > 0 then return saved; end
	return (entry and entry.default) or 1.0;
end

function K.SetModuleScale(id, value)
	local entry = registry[id];
	if not entry then return; end
	value = tonumber(value) or 1.0;
	if value < 0.3 then value = 0.3; end
	if value > 3.0 then value = 3.0; end
	ScaleDB()[id] = value;
	ApplyScale(entry, value);

	if K.RefreshModuleScaleSliders then K.RefreshModuleScaleSliders(id); end

	if K.RequestMoverRefresh then K.RequestMoverRefresh(id); end
end

function K.HasModuleScale(id)
	local saved = ScaleDB()[id];
	return type(saved) == "number" and saved > 0;
end

function K.ResetModuleScale(id)
	local entry = registry[id];
	if not entry then return; end
	ScaleDB()[id] = nil;
	ApplyScale(entry, entry.default or 1.0);
	if K.RefreshModuleScaleSliders then K.RefreshModuleScaleSliders(id); end

	if K.RequestMoverRefresh then K.RequestMoverRefresh(id); end
end

function K.ReapplyModuleScales()
	for id, entry in pairs(registry) do
		local v = K.GetModuleScale(id);
		for _, f in ipairs(entry.frames or { entry.frame }) do
			pcall(f.SetScale, f, v);
		end
	end
end

local scaleLoader = CreateFrame("Frame");
scaleLoader:RegisterEvent("ADDON_LOADED");
scaleLoader:RegisterEvent("PLAYER_LOGIN");
scaleLoader:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" and name ~= AddOnName then return; end
	K.ReapplyModuleScales();
	if K.RefreshModuleScaleSliders then K.RefreshModuleScaleSliders(); end
	if event == "PLAYER_LOGIN" then self:UnregisterAllEvents(); end
end);
