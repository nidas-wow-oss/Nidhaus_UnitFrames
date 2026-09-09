local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local _G, string_lower, print = _G, string.lower, print;
local MAX_BOSS_FRAMES = MAX_BOSS_FRAMES;

-- La ayuda ahora es la lista COMPLETA (Core/CommandList.lua), no cinco
-- lineas sueltas. Si por lo que sea ese archivo no cargo, se cae en la
-- ayuda vieja para no dejar al usuario sin nada.
local function PrintHelpInfo()
	if K.PrintCommandList then
		K.PrintCommandList();
		return;
	end
	print(L["CMD_HEADER"]);
	print(L["CMD_HELP"]);
	print(L["CMD_OPTIONS"] or "  |cff00FF00/nuf options|r — Open options panel");
	print(L["CMD_BOSS"]);
	print(L["CMD_ARENA"]);
	print(L["CMD_MODULES"]);
	print(L["CMD_RESET"] or "  |cff00FFFFreset|r - Reset all settings");
end

local IsBossFramesShown = false;

local function ShowBossFrames()
	local mover = K.NidhausBossFrame;
	if not mover then return; end

	if not IsBossFramesShown then
		local scale = C.BossFrameScale or 0.65;
		if type(scale) ~= "number" or scale <= 0 or scale > 3 then scale = 0.65; end
		local spacing = C.BossTargetFrameSpacing or 0;
		-- FIX: Negate so positive slider values = more separation (consistent with BossFrame.lua)
		local offset = -spacing;

		mover:Show();

		for i = 1, MAX_BOSS_FRAMES do
			-- Siempre usar los frames originales de Blizzard, igual que el original
			local bossFrame = _G["Boss"..i.."TargetFrame"];
			if bossFrame then
				bossFrame:SetScale(scale);
				bossFrame:ClearAllPoints();
				if i == 1 then
					bossFrame:SetPoint("TOPLEFT", mover, "BOTTOMLEFT", 0, 0);
				else
					bossFrame:SetPoint("TOPLEFT", _G["Boss"..(i-1).."TargetFrame"], "BOTTOMLEFT", 0, offset);
				end
				bossFrame:Show();
				bossFrame.name:SetText("Boss"..i);
				bossFrame.deadText:Hide();
			end
		end

		IsBossFramesShown = true;
	else
		for i = 1, MAX_BOSS_FRAMES do
			local bossFrame = _G["Boss"..i.."TargetFrame"];
			if bossFrame then
				bossFrame:SetParent(UIParent);
				bossFrame:Hide();
				bossFrame.deadText:Show();
			end
		end
		mover:Hide();
		IsBossFramesShown = false;
	end
end

-- API para el modo mover: mostrar/ocultar los marcos de boss de prueba
function K.SetBossTestFrames(state)
	if state and not IsBossFramesShown then
		ShowBossFrames();
	elseif not state and IsBossFramesShown then
		ShowBossFrames();
	end
end

function K.IsBossTestShown()
	return IsBossFramesShown;
end

SLASH_NUF1 = "/nuf";
SlashCmdList["NUF"] = function(msg)
	-- /nuf SOLO abre el panel. Es lo que uno quiere el 95% de las veces, y
	-- antes escupia una ayuda de cinco lineas que ademas estaba incompleta.
	-- La lista entera quedo en /nuf help.
	if not msg or msg == "" then
		if K.ToggleOptionsPanel then K.ToggleOptionsPanel(); end
	elseif string_lower(msg) == "help" or string_lower(msg) == "ayuda"
		or string_lower(msg) == "cmd" or string_lower(msg) == "comandos" then
		PrintHelpInfo();
	elseif string_lower(msg) == "options" or string_lower(msg) == "config" then
		if K.ToggleOptionsPanel then K.ToggleOptionsPanel(); end
	elseif string_lower(msg) == "boss" then
		ShowBossFrames();
	elseif string_lower(msg) == "arena" then
		if K.ToggleArenaFramesMover then K.ToggleArenaFramesMover(); end
	elseif string_lower(msg) == "modules" then
		if K.ListModules then K.ListModules(); end
	elseif string_lower(msg) == "reset" then
		StaticPopup_Show("NIDHAUS_RESET_CONFIRM");
	end
end