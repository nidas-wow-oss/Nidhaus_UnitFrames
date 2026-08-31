local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ChatCopy.lua
-- Doble click en la pestana del chat -> abre una caja con el
-- historial para seleccionar y copiar (Ctrl+A / Ctrl+C).
-- Escape cierra. Opcion: C.ChatCopyEnabled
-- =========================================================

local HISTORY_LIMIT = 128;

local tinsert, tremove, floor = table.insert, table.remove, math.floor;

-- ---------------------------------------------------------
-- Frames
-- ---------------------------------------------------------
local scroll  = CreateFrame("ScrollFrame", "NUF_ChatCopyScroll", UIParent);
local slider  = CreateFrame("Slider", "NUF_ChatCopyScrollBar", scroll);
local editbox = CreateFrame("EditBox", "NUF_ChatCopyBox", scroll);

scroll:SetScrollChild(editbox);
scroll:SetFrameStrata("DIALOG");
scroll:Hide();
scroll:EnableMouseWheel(1);

scroll.bg = scroll:CreateTexture(nil, "BACKGROUND");
scroll.bg:SetTexture(0, 0, 0, 1);
scroll.bg:SetPoint("TOPLEFT", -3, 3);
scroll.bg:SetPoint("BOTTOMRIGHT", 3, -3);

scroll:SetScript("OnScrollRangeChanged", function(self, xrange, yrange)
	yrange = yrange or self:GetVerticalScrollRange();
	local value = slider:GetValue();
	slider:SetMinMaxValues(0, yrange);

	-- Al abrir la caja hay que irse ABAJO del todo, no arriba.
	--
	-- El historial se pinta del mas viejo al mas nuevo, asi que el arranque
	-- por defecto del ScrollFrame (posicion 0 = arriba) mostraba los mensajes
	-- mas antiguos. Como la caja se superpone exactamente sobre el chat, el
	-- efecto era el de un salto al principio de la conversacion.
	--
	-- El rango no se conoce hasta que el texto esta medido, y por eso el ajuste
	-- va aca y no en el OnShow: este evento es el primero que sabe cuanto mide.
	if self.nufJumpToBottom then
		self.nufJumpToBottom = nil;
		slider:SetValue(yrange);
		self:SetVerticalScroll(yrange);
	else
		slider:SetValue(value > yrange and yrange or value);
	end

	local total   = self:GetHeight() + yrange;
	local visible = self:GetHeight();
	local ratio   = visible / total;
	if ratio < 1 then
		slider.thumb:SetHeight(floor(visible * ratio));
		slider:Show();
	else
		slider:Hide();
	end
end);

scroll:SetScript("OnMouseWheel", function(self, delta)
	slider:SetValue(slider:GetValue() - delta * slider:GetHeight() / 2);
end);

scroll:SetScript("OnShow", function(self)
	local chatFrame = _G["ChatFrame" .. (self:GetID() or 1)];
	if not chatFrame then self:Hide(); return; end

	self:ClearAllPoints();
	self:SetAllPoints(chatFrame);

	editbox:SetFont(chatFrame:GetFont());
	editbox:SetWidth(chatFrame:GetWidth());
	editbox:SetHeight(chatFrame:GetHeight());
	editbox:SetText("");

	-- Arrancar abajo del todo: la caja tiene que verse igual que el chat que
	-- tapa, con lo ultimo que se dijo a la vista.
	self.nufJumpToBottom = true;
	self:SetVerticalScroll(0);

	local history = chatFrame.NUFHistory;
	if history then
		for i = #history, 1, -1 do
			editbox:Insert(history[i] .. (i ~= 1 and "\n" or ""));
		end
	end

	editbox.cached = editbox:GetText();
	editbox:SetCursorPosition(editbox:GetNumLetters() or 0);

	-- Si el texto entero cabe sin scroll, OnScrollRangeChanged puede no
	-- dispararse; se resuelve la posicion aca tambien para no depender de el.
	self:UpdateScrollChildRect();
	local yrange = self:GetVerticalScrollRange() or 0;
	if yrange > 0 and self.nufJumpToBottom then
		self.nufJumpToBottom = nil;
		slider:SetMinMaxValues(0, yrange);
		slider:SetValue(yrange);
		self:SetVerticalScroll(yrange);
	end
	-- Bloquear edicion (pero permitir seleccionar/copiar)
	editbox:SetScript("OnChar", function(self) self:SetText(self.cached or ""); end);
end);

scroll:SetScript("OnHide", function()
	editbox:SetText("");
	editbox:SetScript("OnChar", nil);
end);

-- Barra lateral
slider:Hide();
slider:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0);
slider:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 1);
slider:SetWidth(10);
slider:SetOrientation("VERTICAL");
slider:SetMinMaxValues(0, 0);
slider:SetValueStep(1);
slider:SetValue(0);
slider:SetAlpha(0.6);
slider:SetBackdrop({
	bgFile   = "Interface\\BUTTONS\\WHITE8X8",
	edgeFile = "Interface\\BUTTONS\\WHITE8X8",
	tile = false, tileSize = 0, edgeSize = 1,
	insets = { left = -1, right = -1, top = -1, bottom = -1 },
});
slider:SetBackdropColor(0, 0, 0, 0.7);
slider:SetBackdropBorderColor(0.2, 0.2, 0.2, 1);
slider:SetThumbTexture("");
slider.thumb = slider:GetThumbTexture();
slider.thumb:SetHeight(50);
slider.thumb:SetTexture(1, 0.82, 0, 1);
slider:SetScript("OnValueChanged", function(self, value)
	scroll:SetVerticalScroll(value);
end);

-- Caja de texto
editbox:SetTextColor(1, 1, 1, 1);
editbox:SetFontObject(ChatFontNormal);
editbox:SetAutoFocus(true);
editbox:SetMultiLine(true);
editbox:SetMaxLetters(0);
editbox:SetScript("OnEscapePressed", function(self)
	self:ClearFocus();
	scroll:Hide();
end);

-- ---------------------------------------------------------
-- Captura del historial + hooks en las pestanas
-- ---------------------------------------------------------
local function HookChatFrame(index)
	local chatFrame = _G["ChatFrame" .. index];
	if not chatFrame or chatFrame.NUFHistory then return; end

	chatFrame.NUFHistory = {};

	hooksecurefunc(chatFrame, "AddMessage", function(self, msg, r, g, b)
		-- Salida temprana: con la opcion apagada no se guarda nada.
		-- Antes se acumulaba historial de CADA mensaje en los 7 chat
		-- frames aunque el usuario nunca fuera a copiarlo.
		if not C.ChatCopyEnabled then return; end
		if type(msg) ~= "string" then return; end
		local history = self.NUFHistory;
		if not history then return; end

		if r and g and b then
			local col = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255);
			tinsert(history, 1, col .. string.gsub(msg, "|r", col));
		else
			tinsert(history, 1, "|cffffffff" .. msg);
		end

		if history[HISTORY_LIMIT + 1] then
			tremove(history, HISTORY_LIMIT + 1);
		end
	end);

	local tab = _G["ChatFrame" .. index .. "Tab"];
	if not tab then return; end

	tab:HookScript("OnDoubleClick", function(self, button)
		if button ~= "LeftButton" then return; end
		if not C.ChatCopyEnabled then return; end
		if scroll:IsShown() then
			scroll:Hide();
		else
			scroll:SetID(self:GetID());
			scroll:Show();
		end
	end);

	tab:HookScript("OnClick", function(self, button)
		if button ~= "LeftButton" then return; end
		if not scroll:IsShown() then return; end
		if scroll:GetID() == self:GetID() then return; end
		scroll:Hide();
	end);
end

for i = 1, NUM_CHAT_WINDOWS do
	HookChatFrame(i);
end

-- Si se desactiva la opcion mientras la caja esta abierta, cerrarla
-- y liberar el historial: si no, quedan 7 tablas de mensajes colgadas
-- en memoria hasta el proximo /reload.
if K.RegisterConfigEvent then
	local lastState = C.ChatCopyEnabled;
	K.RegisterConfigEvent("CONFIG_CHANGED", function()
		local now = C.ChatCopyEnabled and true or false;
		if now == lastState then return; end
		lastState = now;

		if not now then
			if scroll:IsShown() then scroll:Hide(); end
			for i = 1, NUM_CHAT_WINDOWS do
				local cf = _G["ChatFrame" .. i];
				if cf and cf.NUFHistory then wipe(cf.NUFHistory); end
			end
		end
	end);
end

SLASH_NUFCHATCOPY1 = "/nufcopy";
SlashCmdList["NUFCHATCOPY"] = function()
	if not C.ChatCopyEnabled then
		print("|cff4FC3F7NUF:|r " .. (L["CHATCOPY_DISABLED"] or "Chat copy is disabled in the options."));
		return;
	end
	if scroll:IsShown() then
		scroll:Hide();
	else
		scroll:SetID((SELECTED_DOCK_FRAME and SELECTED_DOCK_FRAME:GetID()) or 1);
		scroll:Show();
	end
end
