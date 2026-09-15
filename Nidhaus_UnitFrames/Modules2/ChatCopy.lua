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

-- ---------------------------------------------------------
-- ABRIR DONDE ESTABA EL CHAT
--
-- Antes la caja saltaba SIEMPRE al ultimo mensaje. Si estabas leyendo algo
-- veinte lineas mas arriba y hacias doble click justo para copiar ESO, se
-- te iba al final y habia que volver a buscarlo -- exactamente lo
-- contrario de para lo que abriste la caja.
--
-- GetScrollOffset() dice cuantas lineas por encima del final esta mirando
-- el chat; 0 es abajo del todo. La caja se dibuja encima del chat, con su
-- misma fuente y su mismo ancho, asi que el texto se corta en los mismos
-- lugares: una linea de alla es una linea de aca.
--
-- La conversion a pixeles usa el alto de la fuente. Es una aproximacion --
-- WoW no expone el alto real de linea -- pero cae dentro de una linea o
-- dos, que para "abrime donde estaba" es de sobra. Con offset 0 no hay
-- aproximacion ninguna: se va al fondo, igual que antes.
-- ---------------------------------------------------------
local function TargetScroll(self, yrange)
	local off = self.nufOffset or 0;
	if off <= 0 then return yrange; end
	local v = yrange - off * (self.nufLineH or 15);
	if v < 0 then return 0; end
	if v > yrange then return yrange; end
	return v;
end

scroll:SetScript("OnScrollRangeChanged", function(self, xrange, yrange)
	yrange = yrange or self:GetVerticalScrollRange();
	local value = slider:GetValue();
	slider:SetMinMaxValues(0, yrange);

	-- El rango no se conoce hasta que el texto esta medido, y por eso el
	-- posicionado va aca y no en el OnShow: este evento es el primero que
	-- sabe cuanto mide.
	if self.nufPlaceScroll then
		self.nufPlaceScroll = nil;
		local target = TargetScroll(self, yrange);
		slider:SetValue(target);
		self:SetVerticalScroll(target);
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

	-- La caja tiene que verse igual que el chat que tapa: en el mismo
	-- punto de la conversacion, no siempre al final. Ver TargetScroll.
	local offset = 0;
	if chatFrame.GetScrollOffset then
		offset = chatFrame:GetScrollOffset() or 0;
	end
	local _, fontH = chatFrame:GetFont();
	self.nufOffset = offset;
	self.nufLineH  = (fontH or 14) + 1;

	self.nufPlaceScroll = true;
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
	if yrange > 0 and self.nufPlaceScroll then
		self.nufPlaceScroll = nil;
		local target = TargetScroll(self, yrange);
		slider:SetMinMaxValues(0, yrange);
		slider:SetValue(target);
		self:SetVerticalScroll(target);
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
-- Dos enganches por ventana y CADA UNO CON SU MARCA.
--
-- Antes habia una sola: "si ya tiene NUFHistory, no hagas nada". Con eso
-- alcanzaba porque esto corria una sola vez al cargar. Ahora se vuelve a
-- pasar cada vez que aparece una ventana nueva (ver mas abajo), y una
-- marca compartida deja media ventana sin enganchar: si el historial ya
-- existia pero la pestana todavia no estaba, la funcion salia en la
-- primera linea y el doble click no se enganchaba nunca.
--
-- Cada cosa se marca por separado, y la funcion es idempotente: llamarla
-- diez veces sobre la misma ventana engancha exactamente una.
local function HookChatFrame(index)
	local chatFrame = _G["ChatFrame" .. index];
	if not chatFrame then return; end

	if not chatFrame.NUFHistory then
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
	end

	local tab = _G["ChatFrame" .. index .. "Tab"];
	if not tab or tab.NUFCopyHooked then return; end
	tab.NUFCopyHooked = true;

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

local function HookAllChatFrames()
	for i = 1, (NUM_CHAT_WINDOWS or 7) do
		HookChatFrame(i);
	end
end

HookAllChatFrames();

-- =========================================================
-- LAS VENTANAS QUE NACEN DESPUES
--
-- Este barrido corria UNA sola vez, al cargar el addon. Las pestanas que
-- ya estaban -- General, Combat Log -- quedaban enganchadas y andaban; las
-- que aparecen mas tarde, no.
--
-- Y aparecen mas tarde justamente las que el usuario pidio: una pestana de
-- susurro la crea FCF_OpenTemporaryWindow cuando llega el primer /w, y una
-- pestana propia de party la crea FCF_OpenNewWindow cuando la armas a
-- mano. Las dos reutilizan un ChatFrame libre, y aunque el marco ya
-- existiera al cargar, su pestana puede no haber estado lista todavia.
--
-- Se vuelve a barrer despues de cada una de esas llamadas. HookChatFrame
-- es idempotente, asi que barrer de mas no cuesta nada.
--
-- El cuadro de espera es necesario: cuando FCF_OpenTemporaryWindow
-- devuelve el control, todavia esta terminando de armar la pestana. Sin
-- esperar un cuadro se engancha sobre algo a medio hacer.
-- =========================================================
local rehook = CreateFrame("Frame");
rehook:Hide();
rehook:SetScript("OnUpdate", function(self)
	self:Hide();
	HookAllChatFrames();
end);

local function HookSoon()
	rehook:Show();
end

for _, fname in ipairs({ "FCF_OpenTemporaryWindow", "FCF_OpenNewWindow",
	"FCF_DockFrame", "FCF_SetWindowName", "FCF_RestoreChatsToFrame" }) do
	if type(_G[fname]) == "function" then
		hooksecurefunc(fname, HookSoon);
	end
end

-- Y un barrido al entrar al mundo, por si algun otro addon de chat (Prat,
-- Chatter) rearma las pestanas despues que nosotros.
local rehookLogin = CreateFrame("Frame");
rehookLogin:RegisterEvent("PLAYER_ENTERING_WORLD");
rehookLogin:SetScript("OnEvent", HookSoon);

-- UNA VENTANA TEMPORAL QUE CAMBIA DE DUENO EMPIEZA DE CERO.
--
-- Las de susurro se reciclan: la misma ChatFrame5 que era el susurro con
-- Pepe pasa a ser el susurro con Juan. Sin esto, abrir la caja en la
-- segunda mostraba mezclada la conversacion de la primera -- y eso es
-- filtrar una charla privada dentro de otra.
if type(FCF_SetTemporaryWindowType) == "function" then
	hooksecurefunc("FCF_SetTemporaryWindowType", function(chatFrame, chatType, chatTarget)
		if not chatFrame then return; end
		local key = tostring(chatType) .. "/" .. tostring(chatTarget);
		if chatFrame.NUFCopyTarget == key then return; end
		chatFrame.NUFCopyTarget = key;
		if chatFrame.NUFHistory then wipe(chatFrame.NUFHistory); end
	end);
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
