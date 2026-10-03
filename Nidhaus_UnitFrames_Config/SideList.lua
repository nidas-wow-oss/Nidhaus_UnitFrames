



local ns = _G.NidhausUnitFramesNS;
local K, C, L = unpack(ns);






















local LIST_WIDTH  = 140;
local ITEM_HEIGHT = 30;
local SEP_TOP     = 12;
local SEP_BOTTOM  = 12;

local sideCounter = 0;




K._sideLists = K._sideLists or {};


local DEF = {
	bg       = {0, 0, 0, 0.14},
	selBG    = {0.16, 0.12, 0.06, 0.95},
	selAlpha = 0.55,
	accent   = {1, 0.82, 0},
	gold     = false,
};


local function BumpFont(fs, delta)
	local file, size, flags = fs:GetFont();
	if file and size then fs:SetFont(file, size + (delta or 1), flags); end
end

local function ThemeColors()
	local t = K.GetActiveTheme and K.GetActiveTheme();
	if not t then return DEF; end



	local gold = t.sideGoldText and true or false;

	return {


		bg       = { (t.tabBarBGColor or DEF.bg)[1],
		             (t.tabBarBGColor or DEF.bg)[2],
		             (t.tabBarBGColor or DEF.bg)[3], 0.14 },
		selBG    = (gold and t.sideSelColor) or t.tabSelBGColor or DEF.selBG,
		selAlpha = gold and 0.95 or 0.55,
		accent   = t.accent or DEF.accent,
		gold     = gold,
	};
end




local function StyleItem(item, selected, col)
	col = col or ThemeColors();
	if selected then
		item.bg:SetTexture(col.selBG[1], col.selBG[2], col.selBG[3],
			col.selAlpha or 0.55);
		if col.gold then


			item.marker:Hide();
		else
			item.marker:SetTexture(col.accent[1], col.accent[2], col.accent[3], 0.95);
			item.marker:Show();
		end
	else
		item.bg:SetTexture(0, 0, 0, 0);
		item.marker:Hide();
	end






	if col.gold and not selected then
		item.labelFS:SetTextColor(1, 0.82, 0);
	else
		item.labelFS:SetTextColor(1, 1, 1);
	end










	local base = item.baseFont;
	if base and base[1] then
		local size = base[2];
		if col.gold then size = size + 1; end
		item.labelFS:SetFont(base[1], size, base[3]);
	end
end


function K.RestyleSideLists()
	local col = ThemeColors();
	for _, list in ipairs(K._sideLists) do











		if list.listFrame then
			if col.gold then
				list.listFrame:SetBackdrop({
					bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
					edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
					tile     = true, tileSize = 16, edgeSize = 16,
					insets   = {left=4, right=4, top=4, bottom=4},
				});
				list.listFrame:SetBackdropColor(0.06, 0.06, 0.06, 0.85);
				list.listFrame:SetBackdropBorderColor(1, 1, 1, 1);
				if list.listBG  then list.listBG:Hide();  end
				if list.divider then list.divider:Hide(); end
			else
				list.listFrame:SetBackdrop(nil);
				if list.listBG  then list.listBG:Show();  end
				if list.divider then list.divider:Show(); end
			end
		end

		if list.listBG then list.listBG:SetTexture(unpack(col.bg)); end
		if list.divider then
			list.divider:SetTexture(col.accent[1], col.accent[2], col.accent[3], 0.28);
		end
		for i, item in ipairs(list.items) do
			StyleItem(item, i == list.selected, col);
		end
	end
end

function K.CreateSideList(panel, sections)
	if not panel or not sections or #sections == 0 then return nil; end

	sideCounter = sideCounter + 1;
	local prefix = "NidhausSideList" .. sideCounter .. "_";

	local result   = {};
	local items    = {};
	local panes    = {};
	local count    = 0;


	local list = CreateFrame("Frame", prefix .. "List", panel);
	list:SetPoint("TOPLEFT",    4, -4);
	list:SetPoint("BOTTOMLEFT", 4,  4);
	list:SetWidth(LIST_WIDTH);


	local listBG = list:CreateTexture(nil, "BACKGROUND");
	listBG:SetAllPoints(list);
	listBG:SetTexture(0, 0, 0, 0.14);
	result.listBG    = listBG;
	result.listFrame = list;


	local divider = list:CreateTexture(nil, "ARTWORK");
	divider:SetTexture(1, 1, 1, 0.10);
	divider:SetPoint("TOPRIGHT",    list, "TOPRIGHT",    0, 0);
	divider:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", 0, 0);
	divider:SetWidth(1);
	result.divider = divider;

	local function Select(index)
		if not panes[index] then return; end
		result.selected = index;
		for i = 1, count do
			if i == index then
				panes[i].scrollFrame:Show();
			else
				panes[i].scrollFrame:Hide();
			end
			StyleItem(items[i], i == index);
		end
	end

	local yOffset = -8;
	local index   = 0;

	for _, sec in ipairs(sections) do
		local isTable = (type(sec) == "table");




		if isTable and (sec.separator or sec.header) then



			yOffset = yOffset - SEP_TOP;

			local gline = list:CreateTexture(nil, "ARTWORK");
			gline:SetTexture(1, 1, 1, 0.12);
			gline:SetPoint("TOPLEFT", list, "TOPLEFT", 12, yOffset);
			gline:SetSize(LIST_WIDTH - 24, 1);

			yOffset = yOffset - SEP_BOTTOM;
		else
			index = index + 1;
			local i    = index;
			local name = isTable and sec.name or sec;







			local hidden = isTable and sec.hidden;


			local item = CreateFrame("Button", prefix .. "Item" .. i, list);
			item:SetPoint("TOPLEFT",  list, "TOPLEFT",  0, yOffset);
			item:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, yOffset);
			item:SetHeight(ITEM_HEIGHT);

			item.bg = item:CreateTexture(nil, "BACKGROUND");
			item.bg:SetAllPoints(item);
			item.bg:SetTexture(0, 0, 0, 0);


			item.marker = item:CreateTexture(nil, "ARTWORK");
			item.marker:SetTexture(1, 0.82, 0, 0.9);
			item.marker:SetPoint("TOPLEFT",    item, "TOPLEFT",    0, 0);
			item.marker:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0);
			item.marker:SetWidth(3);
			item.marker:Hide();


			item.labelFS = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
			item.labelFS:SetPoint("LEFT", item, "LEFT", 12, 0);
			item.labelFS:SetJustifyH("LEFT");
			item.labelFS:SetWidth(LIST_WIDTH - 18);
			item.labelFS:SetText(name);
			BumpFont(item.labelFS, 1);











			item.baseFont = { item.labelFS:GetFont() };

			item:SetScript("OnClick", function() Select(i); end);
			item:SetScript("OnEnter", function(self)
				if result.selected ~= i then
					self.bg:SetTexture(1, 1, 1, 0.07);
				end
			end);
			item:SetScript("OnLeave", function(self)
				if result.selected ~= i then
					self.bg:SetTexture(0, 0, 0, 0);
				end
			end);

			items[i] = item;
			if hidden then
				item:Hide();
			else


				yOffset = yOffset - ITEM_HEIGHT - 1;
			end


			local scrollFrame = CreateFrame("ScrollFrame", prefix .. "Scroll" .. i,
				panel, "UIPanelScrollFrameTemplate");
			scrollFrame:SetPoint("TOPLEFT",     LIST_WIDTH + 12, -6);
			scrollFrame:SetPoint("BOTTOMRIGHT", -26, 6);
			scrollFrame:Hide();

			local scrollChild = CreateFrame("Frame", prefix .. "Child" .. i, scrollFrame);
			scrollChild:SetWidth(580);
			scrollChild:SetHeight(1);
			scrollFrame:SetScrollChild(scrollChild);

			scrollChild.scrollFrame = scrollFrame;
			panes[i]  = scrollChild;
			result[i] = scrollChild;
		end
	end

	count = index;

	result.Select = Select;
	result.items  = items;
	result.count  = count;
	result.list   = list;


	result.SetContentHeight = function(index, value)
		local pane = panes[index];
		if not pane then return; end
		local h = math.abs(value or 0) + 40;
		if h < 60 then h = 60; end
		pane:SetHeight(h);
	end

	table.insert(K._sideLists, result);

	Select(1);
	return result;
end
