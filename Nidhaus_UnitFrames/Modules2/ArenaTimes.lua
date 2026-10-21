local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local function fmtMS(sec)
  sec = math.max(0, math.floor((sec or 0) + 0.5));
  local m = math.floor(sec / 60);
  local s = sec % 60;
  -- Segundos siempre con dos cifras: "0:05", no "0:5".
  return string.format("%d:%02d", m, s);
end

local function AT_IsInArenaInstance()
  local inInstance, instanceType = IsInInstance();
  return inInstance and instanceType == "arena";
end

local function GetConfirmIndex()
  for i = 1, MAX_BATTLEFIELD_QUEUES do
    if GetBattlefieldStatus(i) == "confirm" then
      return i;
    end
  end
  return nil;
end

local function GetBestArenaQueueIndex()
  -- FIX: Ahora también matchea BGs (antes solo arenas)
  for i = 1, MAX_BATTLEFIELD_QUEUES do
    local status = GetBattlefieldStatus(i);
    if status == "queued" or status == "confirm" then
      return i;
    end
  end
  return nil;
end

if _G["ArenaTimes_InviteBarHolder"] then return; end

local initialized = false;

-- FIX: Upvalues para onDisable
local AT_qFrame;
local AT_eventFrame;
local AT_StopInviteBar;
local AT_HideQueueText;
local AT_inviteWarned = false;

local function Init()
  if initialized then
    -- Volver a prender despues de un Disable: Disable le saco los eventos.
    -- Antes esto volvia sin hacer nada y el modulo quedaba muerto hasta
    -- /reload.
    if AT_eventFrame then
      AT_eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
      AT_eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
      AT_eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
      local fn = AT_eventFrame:GetScript("OnEvent");
      if fn then pcall(fn, AT_eventFrame); end
    end
    return;
  end
  initialized = true;

  -- =======================================================
  -- ACA NO SE TOCA StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].
  --
  -- Antes se le ponia hideOnEscape = false, para que Escape no te cerrara
  -- el cartel de "entrar a la arena". Andaba, y de paso manchaba (taint)
  -- una tabla de Blizzard para siempre. El precio aparecia lejos de aca:
  --
  --   StaticPopup_EscapePressed() recorre los carteles abiertos y lee
  --   info.hideOnEscape de cada uno. Leer ESE campo manchado ensucia la
  --   ejecucion de ahi en adelante, y en el mismo recorrido se llega al
  --   cartel "CAMP", cuyo OnCancel llama a CancelLogout().
  --
  -- O sea: con la invitacion de arena en pantalla, apretar Escape durante
  -- la cuenta de salida dejaba el logout sin poder cancelarse, con el
  -- cartel de "Interface action failed because of an AddOn". Ese es el
  -- CancelLogout() que reportaba el TaintFixer.
  --
  -- No hay manera de dejar ese flag en false sin manchar: el campo vive
  -- adentro de la tabla de Blizzard. Asi que se deja como viene, y lo que
  -- se queria evitar -- perder la entrada por un Escape de mas -- se
  -- cubre avisando por chat cuando el cartel se cierra con tiempo
  -- todavia (ver el OnUpdate de la barra, mas abajo).
  -- =======================================================

  local holder = CreateFrame("Frame", "ArenaTimes_InviteBarHolder", UIParent);
  holder:SetHeight(12);
  holder:Hide();
  holder:SetFrameStrata("DIALOG");
  holder:SetFrameLevel(10);

  local emptyBG = holder:CreateTexture(nil, "BACKGROUND");
  emptyBG:SetAllPoints(true);
  emptyBG:SetTexture(0, 0, 0, 0.30);

  local bar = CreateFrame("StatusBar", "ArenaTimes_InviteBar", holder);
  bar:SetAllPoints(true);
  bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar");
  bar:SetStatusBarColor(0.85, 0.05, 0.05, 1);
  bar:SetFrameLevel(holder:GetFrameLevel() + 1);

  local border = CreateFrame("Frame", nil, holder);
  border:SetPoint("TOPLEFT", -2, 2);
  border:SetPoint("BOTTOMRIGHT", 2, -2);
  border:SetFrameStrata("DIALOG");
  border:SetFrameLevel(holder:GetFrameLevel() + 3);
  if border.SetBackdrop then
    border:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 9, edgeSize = 9,
      insets = { left = 2, right = 2, top = 3, bottom = 2 },
    });
    border:SetBackdropColor(0, 0, 0, 0.0);
    border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1);
  end

  local textFrame = CreateFrame("Frame", "ArenaTimes_TextFrame", UIParent);
  textFrame:Hide();
  textFrame:SetFrameStrata("TOOLTIP");
  textFrame:SetFrameLevel(9999);

  local txt = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
  txt:SetPoint("CENTER", textFrame, "CENTER", 0, 0);
  txt:SetTextColor(1, 1, 1, 1);
  txt:SetText("");

  local enabled = false;
  local confirmIndex = nil;
  local maxTime = 0;
  local timeLeft = 0;

  local function StopInviteBar()
    enabled = false;
    holder:Hide();
    textFrame:Hide();
    holder:SetScript("OnUpdate", nil);
    confirmIndex = nil;
    maxTime = 0;
    timeLeft = 0;
    txt:SetText("");
  end
  AT_StopInviteBar = StopInviteBar;

  local function LayoutToPopup(popup)
    local w = popup:GetWidth() or 360;
    holder:SetWidth(w - 24);
    holder:ClearAllPoints();
    holder:SetPoint("TOP", popup, "BOTTOM", 0, -2);
    textFrame:ClearAllPoints();
    textFrame:SetAllPoints(holder);
  end

  -- El cartel de entrada no siempre es StaticPopup1: si ya habia otro
  -- abierto (liberar espiritu, invitacion...) cae en el siguiente libre.
  -- Se busca por tipo y por indice de cola (Blizzard lo pasa como data).
  local function FindConfirmPopup(idx)
    local any;
    for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
      local f = _G["StaticPopup" .. i];
      if f and f:IsShown() and f.which == "CONFIRM_BATTLEFIELD_ENTRY" then
        if f.data == idx then return f; end
        any = any or f;
      end
    end
    return any;
  end

  local function StartInviteBar()
    local idxNow = GetConfirmIndex();
    if not idxNow then StopInviteBar(); return; end
    local popup = FindConfirmPopup(idxNow);
    if not popup then StopInviteBar(); return; end
    -- Si ya está corriendo para el mismo índice, no reiniciar
    if enabled and confirmIndex == idxNow then return; end
    confirmIndex = idxNow;
    LayoutToPopup(popup);
    local serverRemain = GetBattlefieldPortExpiration(confirmIndex) or 0;
    if serverRemain <= 0 then StopInviteBar(); return; end
    enabled = true;
    maxTime = serverRemain;
    timeLeft = serverRemain;
    bar:SetMinMaxValues(0, maxTime);
    bar:SetValue(timeLeft);
    txt:SetText(fmtMS(timeLeft));
    holder:Show();
    textFrame:Show();
    -- Usa elapsed para animación suave (server devuelve enteros = saltos feos)
    AT_inviteWarned = false;
    holder:SetScript("OnUpdate", function(self, elapsed)
      -- Cerrado, o el mismo marco ya muestra otro cartel.
      if not popup:IsShown() or popup.which ~= "CONFIRM_BATTLEFIELD_ENTRY" then
        -- EL REEMPLAZO DEL hideOnEscape.
        --
        -- El cartel se fue pero la invitacion sigue viva. En vez de
        -- manchar la tabla de Blizzard para que Escape no lo cierre
        -- (ver el comentario grande en Init), se avisa que todavia
        -- estas a tiempo. Una sola vez por invitacion.
        local left = GetBattlefieldPortExpiration(confirmIndex) or 0;
        if left > 0 and not AT_inviteWarned then
          AT_inviteWarned = true;
          print("|cff4FC3F7NUF:|r " .. string.format(
            L["ARENA_INVITE_STILL_OPEN"]
              or "You closed the entry popup, but you can still join: %d s. Reopen it from the battleground icon on the minimap.",
            math.floor(left)));
        end
        StopInviteBar();
        return;
      end
      local sr = GetBattlefieldPortExpiration(confirmIndex) or 0;
      if sr <= 0 then StopInviteBar(); return; end
      timeLeft = timeLeft - elapsed;
      if timeLeft <= 0 then StopInviteBar(); return; end
      bar:SetValue(timeLeft);
      txt:SetText(fmtMS(timeLeft));
    end);
  end

  local qText = MiniMapBattlefieldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  qText:SetPoint("CENTER", MiniMapBattlefieldFrame, "LEFT", -12, 1);
  qText:SetTextHeight(13);
  qText:SetText("");
  qText:Hide();

  local function HideQueueText()
    qText:SetText("");
    qText:Hide();
  end
  AT_HideQueueText = HideQueueText;

  local qAcc = 0;
  local function UpdateArenaQueueTime()
    if AT_IsInArenaInstance() then HideQueueText(); return; end
    local idx = GetBestArenaQueueIndex();
    if not idx then HideQueueText(); return; end
    local status = GetBattlefieldStatus(idx);
    if status ~= "queued" and status ~= "confirm" then HideQueueText(); return; end
    if MiniMapBattlefieldFrame and not MiniMapBattlefieldFrame:IsShown() then
      MiniMapBattlefieldFrame:Show();
    end
    local waitedMS = GetBattlefieldTimeWaited(idx) or 0;
    qText:SetText(fmtMS(waitedMS / 1000));
    qText:Show();
  end

  -- FIX: qFrame empieza oculto, solo corre OnUpdate cuando hay cola activa
  local qFrame = CreateFrame("Frame", "ArenaTimes_QueueUpdater", UIParent);
  qFrame:Hide();
  qFrame:SetScript("OnUpdate", function(self, elapsed)
    qAcc = qAcc + elapsed;
    if qAcc < 0.25 then return; end
    qAcc = 0;
    UpdateArenaQueueTime();
  end);
  AT_qFrame = qFrame;

  local e = CreateFrame("Frame");
  e:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
  e:RegisterEvent("PLAYER_ENTERING_WORLD");
  e:RegisterEvent("ZONE_CHANGED_NEW_AREA");
  e:SetScript("OnEvent", function()
    if AT_IsInArenaInstance() then
      StopInviteBar();
      HideQueueText();
      qFrame:Hide();
      return;
    end
    if GetConfirmIndex() then StartInviteBar(); else StopInviteBar(); end

    -- FIX: Activar/desactivar qFrame según si hay cola
    if GetBestArenaQueueIndex() then
      qFrame:Show();
    else
      qFrame:Hide();
      HideQueueText();
    end
  end);
  AT_eventFrame = e;

  -- Check inicial
  if GetBestArenaQueueIndex() then
    qFrame:Show();
  end
  UpdateArenaQueueTime();
end

-- FIX: onDisable para limpieza
local function Disable()
  if not initialized then return; end
  if AT_qFrame then AT_qFrame:Hide(); end
  if AT_eventFrame then AT_eventFrame:UnregisterAllEvents(); end
  if AT_StopInviteBar then AT_StopInviteBar(); end
  if AT_HideQueueText then AT_HideQueueText(); end
end

K.RegisterModule("ArenaTimes", {
    name = L["MOD_ARENA_TIMES"] or "Arena Times",
    desc = L["MOD_ARENA_TIMES_DESC"] or "Timer on arena invite popup + queue time next to minimap.",
    default = true,
    -- El checkbox vive en Arena > Options, no repetirlo aca
    hideFromModulesTab = true,
    onEnable = Init,
    onDisable = Disable,
});