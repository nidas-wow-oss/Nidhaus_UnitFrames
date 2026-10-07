local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local SecureUnitButton_OnLoad, ToggleDropDownMenu = SecureUnitButton_OnLoad, ToggleDropDownMenu;
local unpack, tonumber, _G, ipairs, pairs, setmetatable = unpack, tonumber, _G, ipairs, pairs, setmetatable;


function K.CreateBackdrop(Obj)
	if Obj.Backdrop then return; end;
	
	local Backdrop = CreateFrame("Frame", nil, Obj);
	Backdrop:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]});
	Backdrop:SetBackdropColor(unpack(C.statusbarBackdropColor));
	Backdrop:SetPoint("TOPLEFT",Obj.healthbar, "TOPLEFT");
	Backdrop:SetPoint("BOTTOMRIGHT",Obj.manabar, "BOTTOMRIGHT");
	if Obj:GetFrameLevel() - 1 >= 0 then
		Backdrop:SetFrameLevel(Obj:GetFrameLevel() - 1);
	else
		Backdrop:SetFrameLevel(0);
	end;
	
	Obj.Backdrop = Backdrop;
end;


function K.MoveFrame(Obj, NewFrameName, UnitId, xOffset, yOffset, ParentBossFrame)
	CreateFrame("Button", NewFrameName, UIParent, "SecureUnitButtonTemplate");
	local Frame = _G[NewFrameName];
	Frame:SetFrameStrata(Obj:GetFrameStrata());
	Frame:SetFrameLevel(Obj:GetFrameLevel());
	Frame:SetHeight(Obj:GetHeight());
	Frame:SetWidth(Obj:GetWidth());
	
	ClickCastFrames = ClickCastFrames or {};
	ClickCastFrames[Frame] = true;
	
	Frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	
	local ShowMenu = function()
		ToggleDropDownMenu(1, nil, _G[Obj:GetName().."DropDown"], NewFrameName, xOffset, yOffset);
	end
	SecureUnitButton_OnLoad(Frame, UnitId, ShowMenu);
	
	for _, script in ipairs({"OnEnter", "OnLeave", "OnReceiveDrag"}) do
		Frame:SetScript(script, Obj:GetScript(script));
	end;
	

	Obj:EnableMouse(false);
	
	setmetatable(Frame, {__index = Obj});
	
	local point, relativeTo, relativePoint, xOffset, yOffset;
	for _, child in pairs({Obj:GetChildren()}) do
		child:SetParent(Frame);
		for pointNum = 1, child:GetNumPoints() do
			point, relativeTo, relativePoint, xOffset, yOffset = child:GetPoint(pointNum);
			if (relativeTo == Obj) then
				child:SetPoint(point, Frame, relativePoint, xOffset, yOffset);
				if NewFrameName:find("Boss") and child:GetName():find("Bar") then 
					child:SetFrameLevel(Frame:GetFrameLevel()-1);
				end;
			end;
		end;
	end;
	for _, child in pairs({Obj:GetRegions()}) do
		child:SetParent(Frame);
		for pointNum = 1, child:GetNumPoints() do
			point, relativeTo, relativePoint, xOffset, yOffset = child:GetPoint(pointNum);
			if (relativeTo == Obj) then
				child:SetPoint(point, Frame, relativePoint, xOffset, yOffset);
			end;
		end;
	end;
	Frame:SetParent(Obj);
	
	if UnitId:find("Boss") then
		local id = tonumber(UnitId:sub(5, 5));
		if id == 1 then
			Frame:SetPoint("TOPLEFT", ParentBossFrame, 0, 0);
		else
			Frame:SetPoint("TOPLEFT", ParentBossFrame["Boss"..id-1], "BOTTOMLEFT", 0, -(C.BossTargetFrameSpacing or 0));
		end;
		ParentBossFrame["Boss"..id] = Frame;
	end;
end;


function K.SetOffset(Obj, x, y)
	local point, relativeTo, relativePoint, xOffset, yOffset = Obj:GetPoint(1);
	return point, relativeTo, relativePoint, xOffset + x, yOffset + y;
end;







function K.GetArenaPositionKey()
	local style = C.ArenaFrameStyle or "Custom";
	local mirror = C.ArenaMirrorMode and "mirror" or "normal";
	return style .. "_" .. mirror;
end












local skinCapture = {};


function K.CaptureTexture(region, id)
	if not region then return; end
	if skinCapture[id] == nil then
		skinCapture[id] = region:GetTexture() or false;
	end
end

function K.RestoreTexture(region, id)
	if not region then return; end
	local tex = skinCapture[id];
	if tex ~= nil and tex ~= false then
		region:SetTexture(tex);
	end
end


function K.CaptureBarGeometry(bar, id)
	if not bar then return; end
	if skinCapture[id] == nil then
		local point, relativeTo, relativePoint, x, y = bar:GetPoint(1);
		skinCapture[id] = {
			point = point,
			relativeTo = relativeTo,
			relativePoint = relativePoint,
			x = x or 0,
			y = y or 0,
			w = bar:GetWidth(),
			h = bar:GetHeight(),
		};
	end
end

function K.RestoreBarGeometry(bar, id)
	if not bar then return; end
	local d = skinCapture[id];
	if type(d) ~= "table" then return; end
	bar:ClearAllPoints();
	if d.point then
		bar:SetPoint(d.point, d.relativeTo or bar:GetParent(), d.relativePoint, d.x, d.y);
	end
	if d.h and d.h > 0 then bar:SetHeight(d.h); end
end




function K.CaptureAnchors(region, id)
	if not region then return; end
	if skinCapture[id] == nil then
		local pts = {};
		for i = 1, region:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = region:GetPoint(i);
			pts[i] = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, x = x or 0, y = y or 0 };
		end
		skinCapture[id] = pts;
	end
end

function K.RestoreAnchors(region, id)
	if not region then return; end
	local pts = skinCapture[id];
	if type(pts) ~= "table" then return; end
	region:ClearAllPoints();
	for _, p in ipairs(pts) do
		if p.point then
			region:SetPoint(p.point, p.relativeTo, p.relativePoint, p.x, p.y);
		end
	end
end

























function K.ApplyUnitFrameTheme()
	if K.ApplyPlayerFrameSkin      then pcall(K.ApplyPlayerFrameSkin);      end
	if K.ApplyTargetFrameSkin      then pcall(K.ApplyTargetFrameSkin);      end
	if K.RestylePartyFrames        then pcall(K.RestylePartyFrames);        end
	if K.RestyleBossFrames         then pcall(K.RestyleBossFrames);         end
	if K.RefreshClassOutlines      then pcall(K.RefreshClassOutlines);      end
	if K.UpdateTrinketBorderColors then pcall(K.UpdateTrinketBorderColors); end

	if K.RefreshBigStatusFonts     then pcall(K.RefreshBigStatusFonts);     end


	if K.InvalidateAbbrevAnchors   then pcall(K.InvalidateAbbrevAnchors);   end
end

















function K.BigStatusTextOn(unit)
	if not C.BigStatusText then return false; end
	if C.UnitFrameCustomTexture ~= true then return false; end
	if C.AsuriFrames then return false; end
	if unit == "player" and K.IcyPlayerFrameOn and K.IcyPlayerFrameOn() then return false; end
	return true;
end


function K.BigStatusSizeOn(unit)
	return (C.BigTextCustomSize and K.BigStatusTextOn(unit)) and true or false;
end

















local afterCombat, afterCombatOrder = {}, {};
local afterCombatFrame = CreateFrame("Frame");
afterCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
afterCombatFrame:SetScript("OnEvent", function()
	local list, order = afterCombat, afterCombatOrder;
	afterCombat, afterCombatOrder = {}, {};
	for _, key in ipairs(order) do
		local fn = list[key];
		if fn then pcall(fn); end
	end
end);

function K.AfterCombat(key, fn)
	if not InCombatLockdown() then return false; end
	if not afterCombat[key] then table.insert(afterCombatOrder, key); end
	afterCombat[key] = fn;
	return true;
end
