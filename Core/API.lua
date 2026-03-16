local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local SecureUnitButton_OnLoad, ToggleDropDownMenu = SecureUnitButton_OnLoad, ToggleDropDownMenu;
local unpack, tonumber, _G, ipairs, pairs, setmetatable = unpack, tonumber, _G, ipairs, pairs, setmetatable;

--	Create Backdrop (Player & Target Frames);
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

--	Move Frames;
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
	
	-- FIX: Solo llamar EnableMouse una vez
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

--	Move Point;
function K.SetOffset(Obj, x, y)
	local point, relativeTo, relativePoint, xOffset, yOffset = Obj:GetPoint(1);
	return point, relativeTo, relativePoint, xOffset + x, yOffset + y;
end;

-- ═══════════════════════════════════════════════════════════
-- GetArenaPositionKey — composite key per style + mirror mode
-- Used by CastBarPositions and TrinketPositions to save/load
-- positions independently per arena style (Blizzard/Custom/Flat)
-- and per mirror mode (normal/mirror).
-- ═══════════════════════════════════════════════════════════
function K.GetArenaPositionKey()
	local style = C.ArenaFrameStyle or "Custom";
	local mirror = C.ArenaMirrorMode and "mirror" or "normal";
	return style .. "_" .. mirror;
end