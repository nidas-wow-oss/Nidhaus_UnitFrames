local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- =========================================================
-- ArenaPointsCalc.lua  (integrado a NUF)
-- Fuente: Arena Points Calculator v2.1
--
-- CAMBIOS respecto del addon suelto:
--   * ADDON_LOADED ya no dispara: NUF carga el archivo, no el
--     cliente, asi que ese evento nunca llega con este nombre.
--     El aviso de servidor pasa a PLAYER_ENTERING_WORLD.
--   * El boton dentro de la ventana de PvP y los tickers solo
--     corren si el modulo esta encendido en Arena > Timers.
--   * La ventana usa la DB de NUF, no una SavedVariable propia.
-- =========================================================

local apcEnabled = false;

-- FontString del boton que vive en la ventana de PvP. Lo llena
-- AddPvPButton() y lo refresca UpdatePvPButton().
local pvpBtnLabel;

local function APC_DB()
	if not NidhausUnitFramesDB then NidhausUnitFramesDB = {}; end
	if not NidhausUnitFramesDB.ArenaPointsCalc then
		NidhausUnitFramesDB.ArenaPointsCalc = {};
	end
	return NidhausUnitFramesDB.ArenaPointsCalc;
end

local ADDON_NAME = "ArenaPointsCalc"
local APC = CreateFrame("Frame", "ArenaPointsCalcFrame")

-- OJO: aca habia "ArenaPointsCalcDB = APC_DB()".
--
-- Esa linea corre cuando el archivo se CARGA, y en ese momento
-- NidhausUnitFramesDB todavia no existe: las SavedVariables llegan recien en
-- ADDON_LOADED, despues de que todos los .lua terminaron de ejecutarse.
--
-- Asi que APC_DB() creaba una tabla nueva y vacia, y el alias global quedaba
-- apuntando a ELLA. Cuando WoW despues reemplazaba NidhausUnitFramesDB por lo
-- guardado, el alias seguia mirando la tabla vieja — huerfana, que nadie
-- guarda. Resultado: la posicion de la calculadora nunca se conservaba entre
-- sesiones, y era imposible de notar porque dentro de la misma sesion
-- funcionaba perfecto.
--
-- Se llama APC_DB() en cada uso. Es una busqueda de tabla, no cuesta nada.

-- ============================================================
-- SERVER DETECTION
-- ============================================================
local serverMult = 1.0
local realmName = ""

local function DetectServer()
    realmName = GetRealmName() or ""
    serverMult = string.find(realmName, "Blackrock") and 2.0 or 1.0
end

-- ============================================================
-- FORMULA (WotLK 3.3.5)
-- ============================================================
local BRACKET_MULT = { [2] = 0.76, [3] = 0.88, [5] = 1.00 }
local BRACKET_NAMES = { [2] = "2v2", [3] = "3v3", [5] = "5v5" }

local function CalcPoints(rating, bracketSize)
    if rating < 0 then rating = 0 end
    local bMult = BRACKET_MULT[bracketSize] or 1.0
    local baseRating = math.max(rating, 1500)
    local base = 1511.26 / (1 + 1639.28 * math.exp(-0.00412 * baseRating))
    return math.floor(base * bMult * serverMult)
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local mainFrame = CreateFrame("Frame", "APC_MainFrame", UIParent)
-- Sin escala a proposito: es una ventana con su propio tamaño, no un
-- elemento de HUD que convenga agrandar o achicar.
mainFrame:SetWidth(300)
mainFrame:SetHeight(248)
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    local db = APC_DB()
    db.point = point
    db.relPoint = relPoint
    db.x = x
    db.y = y
end)
mainFrame:SetClampedToScreen(true)
mainFrame:Hide()

-- Escape cierra la ventana, como cualquier panel del juego. UISpecialFrames
-- es la lista que mira el cliente al apretar Escape; alcanza con estar en
-- ella y tener nombre global (APC_MainFrame).
tinsert(UISpecialFrames, "APC_MainFrame")
mainFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})

local titleTex = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleTex:SetPoint("TOP", mainFrame, "TOP", 0, -16)
titleTex:SetText("|cff00ccff" .. (L["APC_TITLE"] or "Arena Points Calculator") .. "|r")

local serverInfo = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
serverInfo:SetPoint("TOP", mainFrame, "TOP", 0, -32)

local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

local function MakeSep(y)
    local s = mainFrame:CreateTexture(nil, "ARTWORK")
    s:SetTexture(0.4, 0.4, 0.4, 0.5)
    s:SetHeight(1)
    s:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 18, y)
    s:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -18, y)
end

-- === AUTO SECTION ===
MakeSep(-46)

local autoHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
autoHeader:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -54)
autoHeader:SetText("|cffFFD700" .. (L["APC_MY_POINTS"] or "My Points This Week") .. "|r")

local teamLines = {}
for i = 1, 3 do
    local line = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 24, -70 - (i - 1) * 16)
    line:SetWidth(260)
    line:SetJustifyH("LEFT")
    teamLines[i] = line
end

local noTeamsText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
noTeamsText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 24, -70)
noTeamsText:SetWidth(260)
noTeamsText:SetJustifyH("LEFT")
noTeamsText:SetText("|cffff8080" .. (L["APC_NO_TEAMS"] or "You are not in any arena team.") .. "|r")
noTeamsText:Hide()

local bestPointsText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
bestPointsText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -122)
bestPointsText:SetWidth(260)
bestPointsText:SetJustifyH("LEFT")

-- === CALCULATOR SECTION ===
MakeSep(-146)

local calcHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
calcHeader:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -154)
calcHeader:SetText("|cff00ccff" .. (L["APC_MANUAL"] or "Manual Calculator") .. "|r")

local inputLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
inputLabel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20, -176)
inputLabel:SetText(L["APC_RATING"] or "Rating:")

local ratingInput = CreateFrame("EditBox", "APC_RatingInput", mainFrame, "InputBoxTemplate")
ratingInput:SetWidth(80)
ratingInput:SetHeight(20)
ratingInput:SetPoint("LEFT", inputLabel, "RIGHT", 8, 0)
ratingInput:SetNumeric(true)
ratingInput:SetMaxLetters(4)
ratingInput:SetAutoFocus(false)

local calcBtn = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
calcBtn:SetWidth(85)
calcBtn:SetHeight(22)
calcBtn:SetPoint("LEFT", ratingInput, "RIGHT", 6, 0)
calcBtn:SetText(L["APC_CALCULATE"] or "Calculate")

local resultText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resultText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 18, -200)
resultText:SetWidth(268)
resultText:SetJustifyH("LEFT")
resultText:SetText("")

-- ============================================================
-- AUTO DETECTION LOGIC
-- ============================================================
-- Lee los equipos de arena del personaje y los devuelve ordenados de mas
-- a menos puntos. Se usa desde tres lados: la ventana, el texto del boton
-- y su tooltip, asi que vive aparte en vez de estar metido en la ventana.
local function GetTeams()
    local teams, hasTeam = {}, false
    for i = 1, MAX_ARENA_TEAMS do
        local teamName, teamSize, teamRating, teamPlayed, teamWins, seasonPlayed, seasonWins, playerPlayed, seasonPlayerPlayed, teamRank, playerRating = GetArenaTeam(i)
        if teamName and teamName ~= "" then
            hasTeam = true
            teams[#teams + 1] = {
                size = teamSize, rating = teamRating,
                points = CalcPoints(teamRating, teamSize),
                played = seasonPlayerPlayed or playerPlayed or 0,
                playerRating = playerRating or 0,
                qualified = (seasonPlayerPlayed and seasonPlayerPlayed >= 1) or (playerPlayed and playerPlayed >= 1),
            }
        end
    end
    table.sort(teams, function(a, b) return a.points > b.points end)
    return teams, hasTeam
end

-- Solo cobras los puntos del mejor equipo en el que hayas jugado al menos
-- una partida, asi que los que no califican no cuentan para este numero.
local function GetBest(teams)
    local bestPts, bestBracket = 0, ""
    for _, t in ipairs(teams) do
        if t.qualified and t.points > bestPts then
            bestPts = t.points
            bestBracket = BRACKET_NAMES[t.size] or "?"
        end
    end
    return bestPts, bestBracket
end

-- Texto del boton que aparece dentro de la ventana de PvP.
-- Muestra los puntos de la semana directamente, sin tener que abrir nada.
local function UpdatePvPButton()
    if not pvpBtnLabel then return end
    DetectServer()
    local teams, hasTeam = GetTeams()
    if not hasTeam then
        pvpBtnLabel:SetText("|cffcccccc" .. (L["APC_SHORT"] or "Arena Calculator") .. "|r")
        return
    end
    local bestPts, bestBracket = GetBest(teams)
    if bestPts > 0 then
        pvpBtnLabel:SetText(string.format("|cff00ff00%d|r  |cffaaaaaa%s|r", bestPts, bestBracket))
    else
        pvpBtnLabel:SetText("|cffff4444" .. (L["APC_BTN_NO_GAMES"] or "No games") .. "|r")
    end
end

local function UpdateAutoSection()
    local teams, hasTeam = GetTeams()

    if not hasTeam then
        noTeamsText:Show()
        for i = 1, 3 do teamLines[i]:SetText("") end
        bestPointsText:SetText("")
        UpdatePvPButton()
        return
    end
    noTeamsText:Hide()

    for i = 1, 3 do
        local t = teams[i]
        if t then
            local qualTag = t.qualified and "" or " |cffff4444(no games)|r"
            teamLines[i]:SetText(string.format(
                "%s |cffffff00%d|r rating -> |cff00ff00%d pts|r (PR: %d, %d played)%s",
                BRACKET_NAMES[t.size] or "?", t.rating, t.points, t.playerRating, t.played, qualTag))
        else
            teamLines[i]:SetText("")
        end
    end

    local bestPts, bestBracket = GetBest(teams)
    if bestPts > 0 then
        local multTag = (serverMult ~= 1.0) and string.format(" |cffFFD700(x%.0f)|r", serverMult) or ""
        bestPointsText:SetText(string.format(
            "|cffFFD700>>> You will receive: |cff00ff00%d|r |cffFFD700arena points%s|r (from %s)", bestPts, multTag, bestBracket))
    else
        bestPointsText:SetText("|cffff4444" .. (L["APC_NEED_GAMES"] or ">>> 0 points - you need to play games!") .. "|r")
    end

    UpdatePvPButton()
end

-- ============================================================
-- REPOSITIONING
-- ============================================================
local TEAM_FRAME_NAMES = { "ArenaTeamFrame", "PVPArenaTeamFrame", "ArenaTeamRosterFrame", "ArenaRosterFrame" }
local teamFrame, teamWindowOpen = nil, false

-- Busca la ventana de equipo de arena SOLO por nombre conocido.
--
-- El addon original, si no encontraba ninguno, recorria TODOS los frames
-- de la interfaz con EnumerateFrames() adivinando por ancho y alto. Eso
-- son cientos de frames (los del juego mas los de todos tus addons)
-- barridos cada 0.3 segundos: carisimo y ademas fragil, porque cualquier
-- ventana de otro addon del tamaño parecido daba un falso positivo.
local function FindTeamFrame()
    for _, name in ipairs(TEAM_FRAME_NAMES) do
        local f = _G[name]; if f and f:IsShown() then return f end
    end
    return nil
end

local function RepositionMainFrame()
    if not mainFrame:IsShown() then return end
    if APC_DB().point and not teamWindowOpen then return end
    mainFrame:ClearAllPoints()
    if teamWindowOpen and teamFrame and teamFrame:IsShown() then
        mainFrame:SetPoint("TOPLEFT", teamFrame, "TOPRIGHT", 6, 0)
    elseif PVPFrame and PVPFrame:IsShown() then
        mainFrame:SetPoint("TOPLEFT", PVPFrame, "TOPRIGHT", 6, 0)
    elseif APC_DB().point then
        local db = APC_DB()
        mainFrame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
    else
        mainFrame:SetPoint("CENTER")
    end
end

local scanTimer = 0
local scanFrame = CreateFrame("Frame")
scanFrame:Hide()
scanFrame:SetScript("OnUpdate", function(self, dt)
    -- Solo tiene sentido mirar mientras la ventana de PvP esta abierta
    if not apcEnabled or not (PVPFrame and PVPFrame:IsShown()) then
        self:Hide()
        return
    end
    scanTimer = scanTimer + dt
    if scanTimer < 0.3 then return end
    scanTimer = 0
    local found = FindTeamFrame()
    local nowOpen = found ~= nil
    if nowOpen ~= teamWindowOpen then
        teamWindowOpen = nowOpen
        if nowOpen then teamFrame = found end
        RepositionMainFrame()
    end
end)

-- ============================================================
-- CALCULATOR
-- ============================================================
local function UpdateServerInfo()
    if serverMult == 2.0 then
        serverInfo:SetText("|cffFFD700" .. (L["APC_SERVER_X2"] or "Warmane Blackrock \226\128\148 Points x2") .. "|r")
    else
        serverInfo:SetText(string.format("|cffaaaaaa%s \226\128\148 Points x1|r", realmName))
    end
end

calcBtn:SetScript("OnClick", function()
    local val = tonumber(ratingInput:GetText())
    if not val then resultText:SetText("|cffff4444" .. (L["APC_INVALID_RATING"] or "Enter a valid rating.") .. "|r"); return end
    local p2, p3, p5 = CalcPoints(val, 2), CalcPoints(val, 3), CalcPoints(val, 5)
    local tag = (serverMult ~= 1.0) and string.format(" |cffaaaaaa(x%.0f)|r", serverMult) or ""
    resultText:SetText(string.format(
        "|cffffff00Rating %d%s|r\n  2v2: |cff00ff00%d pts|r   3v3: |cff00ff00%d pts|r   5v5: |cff00ff00%d pts|r",
        val, tag, p2, p3, p5))
end)
ratingInput:SetScript("OnEnterPressed", function() calcBtn:Click(); ratingInput:ClearFocus() end)
mainFrame:SetScript("OnShow", function() DetectServer(); UpdateServerInfo(); UpdateAutoSection(); RepositionMainFrame() end)

-- ============================================================
-- PVP BUTTON
-- ============================================================
local pvpBtnAdded = false
local function AddPvPButton()
    if pvpBtnAdded or not PVPFrame then return end
    pvpBtnAdded = true
    local b = CreateFrame("Button", "APC_PvPButton", PVPFrame)
    b:SetWidth(95); b:SetHeight(18)
    b:SetAlpha(0.9)
    -- Posicion por defecto dentro de la ventana de PvP. Se puede mover con
    -- Alt + arrastrar y queda guardada en la DB (btnX / btnY).
    local db = APC_DB()
    b:SetPoint("TOPLEFT", PVPFrame, "TOPLEFT", db.btnX or 205, db.btnY or -152)
    b:SetMovable(true)
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function(self)
        if IsAltKeyDown() then self:StartMoving() end
    end)
    b:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Guardar el offset relativo al PVPFrame, no la posicion absoluta:
        -- la ventana de PvP no siempre aparece en el mismo lugar.
        if not PVPFrame then return end
        local x = self:GetLeft() - PVPFrame:GetLeft()
        local y = self:GetTop() - PVPFrame:GetTop()
        local d = APC_DB(); d.btnX = x; d.btnY = y
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", PVPFrame, "TOPLEFT", x, y)
    end)
    b:SetFrameLevel(PVPFrame:GetFrameLevel() + 5)
    -- Sin fondo ni borde: el numero tiene que leerse como una linea mas de
    -- la ventana de PvP, al lado de HONOR y ARENA, no como un boton pegado.
    -- GameFontNormal es la fuente estandar de la interfaz (Friz Quadrata),
    -- la misma con la que la ventana escribe HONOR y ARENA. No se le pisa
    -- con SetFont a proposito, para que combine.
    local l = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetPoint("CENTER")
    l:SetText("|cffcccccc" .. (L["APC_SHORT"] or "Arena Calculator") .. "|r")
    pvpBtnLabel = l
    b:EnableMouse(true)
    b:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["APC_TITLE"] or "Arena Points Calculator", 0, 0.8, 1)
        DetectServer()
        local teams, hasTeam = GetTeams()
        if not hasTeam then
            GameTooltip:AddLine(L["APC_NO_TEAMS"] or "You are not in any arena team.", 1, 0.5, 0.5, true)
        else
            for _, t in ipairs(teams) do
                local qualTag = t.qualified and "" or " |cffff4444*|r"
                GameTooltip:AddDoubleLine(
                    string.format("%s  |cffffff00%d|r", BRACKET_NAMES[t.size] or "?", t.rating),
                    string.format("|cff00ff00%d|r |cffcccccc%s|r%s", t.points, L["APC_BTN_PTS"] or "pts", qualTag))
            end
            local bestPts, bestBracket = GetBest(teams)
            GameTooltip:AddLine(" ")
            if bestPts > 0 then
                local multTag = (serverMult ~= 1.0) and string.format(" (x%.0f)", serverMult) or ""
                GameTooltip:AddLine(string.format("%s: |cff00ff00%d|r%s  (%s)",
                    L["APC_BTN_TIP_BEST"] or "Points you will receive this week", bestPts, multTag, bestBracket), 1, 0.84, 0, true)
            else
                GameTooltip:AddLine(L["APC_NEED_GAMES"] or ">>> 0 points - you need to play games!", 1, 0.3, 0.3, true)
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["APC_BTN_TIP_CLICK"] or "Click to open the calculator", 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L["APC_BTN_TIP_DRAG"] or "Alt + drag to move it", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self) self:SetAlpha(0.9); GameTooltip:Hide() end)
    b:SetScript("OnClick", function() if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end end)
    UpdatePvPButton()
end

-- ============================================================
-- SLASH
-- ============================================================
SLASH_ARENACALC1 = "/apc"
SLASH_ARENACALC2 = "/arenapts"
SlashCmdList["ARENACALC"] = function(msg)
    msg = strtrim(msg or "")
    if msg == "auto" then
        DetectServer()
        local found = false
        for i = 1, MAX_ARENA_TEAMS do
            local tn, ts, tr, _, _, _, _, _, sp = GetArenaTeam(i)
            if tn and tn ~= "" then
                found = true
                print(string.format("|cff00ccff[APC]|r %s %s: |cffffff00%d|r -> |cff00ff00%d pts|r (%d played)",
                    BRACKET_NAMES[ts] or "?", tn, tr, CalcPoints(tr, ts), sp or 0))
            end
        end
        if not found then print("|cff00ccff[APC]|r |cffff8080No arena teams.|r") end
        return
    end
    if msg == "btnpos" then
        local d = APC_DB()
        print(string.format("|cff00ccff[APC]|r x = %s, y = %s",
            tostring(d.btnX and math.floor(d.btnX + 0.5) or "default"),
            tostring(d.btnY and math.floor(d.btnY + 0.5) or "default")))
        return
    end
    if msg == "btnreset" then
        local d = APC_DB(); d.btnX = nil; d.btnY = nil
        if APC_PvPButton and PVPFrame then
            APC_PvPButton:ClearAllPoints()
            APC_PvPButton:SetPoint("TOPLEFT", PVPFrame, "TOPLEFT", 205, -152)
        end
        print("|cff00ccff[APC]|r " .. (L["APC_BTN_RESET_DONE"] or "Button position reset."))
        return
    end
    local r = tonumber(msg)
    if r then
        DetectServer()
        local tag = (serverMult ~= 1.0) and string.format(" (x%.0f)", serverMult) or ""
        print(string.format("|cff00ccff[APC]|r Rating |cffffff00%d%s|r -> 2v2:|cff00ff00%d|r  3v3:|cff00ff00%d|r  5v5:|cff00ff00%d|r",
            r, tag, CalcPoints(r, 2), CalcPoints(r, 3), CalcPoints(r, 5)))
        return
    end
    if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
end

-- ============================================================
-- EVENTS
-- ============================================================
-- Los eventos los engancha el modulo al prenderse (ver onEnable)
APC:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        if not apcEnabled then return end
        DetectServer()
        local e = 0
        local t = CreateFrame("Frame")
        t:SetScript("OnUpdate", function(f, dt) e = e + dt; if e >= 2 then f:SetScript("OnUpdate", nil); f:Hide(); AddPvPButton(); UpdatePvPButton(); teamFrame = FindTeamFrame() end end)
    elseif event == "ARENA_TEAM_UPDATE" or event == "ARENA_TEAM_ROSTER_UPDATE" then
        if mainFrame:IsShown() then
            UpdateAutoSection()
        else
            -- El boton muestra los puntos aunque la ventana este cerrada,
            -- asi que hay que refrescarlo igual.
            UpdatePvPButton()
        end
    end
end)

-- El escaneo se despierta al abrir la ventana de PvP y se duerme solo
if PVPFrame then
    PVPFrame:HookScript("OnShow", function()
        if apcEnabled then scanTimer = 0; scanFrame:Show(); UpdatePvPButton(); end
    end)
end

-- =========================================================
-- Registro del modulo en NUF
-- Vive en: Arena > Timers
-- =========================================================
K.RegisterModule("ArenaPointsCalc", {
	name    = L["MOD_APC"] or "Arena Points Calculator",
	desc    = L["MOD_APC_DESC"]
		or "Calculates the arena points you will get each week from your rating. /apc",
	default = false,
	configLabel = L["BTN_MODULE_OPEN"] or "Open",
	configFunc = function()
		if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
	end,
	onEnable = function()
		apcEnabled = true;
		APC:RegisterEvent("PLAYER_ENTERING_WORLD");
		APC:RegisterEvent("ARENA_TEAM_UPDATE");
		APC:RegisterEvent("ARENA_TEAM_ROSTER_UPDATE");
		DetectServer();
		AddPvPButton();
		if APC_PvPButton then APC_PvPButton:Show(); end
		UpdatePvPButton();
		if PVPFrame and PVPFrame:IsShown() then scanTimer = 0; scanFrame:Show(); end
	end,
	onDisable = function()
		apcEnabled = false;
		scanFrame:Hide();
		APC:UnregisterAllEvents();
		mainFrame:Hide();
		if APC_PvPButton then APC_PvPButton:Hide(); end
	end,
});
