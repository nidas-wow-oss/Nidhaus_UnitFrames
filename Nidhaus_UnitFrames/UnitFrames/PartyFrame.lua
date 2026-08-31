local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local _G, unpack = _G, unpack;
local hooksecurefunc = hooksecurefunc;

-- ── Fuente "Blizzard" ─────────────────────────────────────────
-- Copia la fuente y los flags REALES del FontObject TextStatusBarText,
-- el que usan los numeros de las barras de vida y mana.
--
-- Nada se hardcodea a proposito: primero se asumio que ese texto solo
-- llevaba sombra y ningun flag de contorno, y el resultado se veia como
-- un sombreado, nada que ver con el borde negro del original. Leyendo el
-- FontObject sale igual, sea cual sea la definicion del cliente.
local BLIZZ_FONT, BLIZZ_FLAGS;
local function BlizzStatusFont()
	if BLIZZ_FONT then return BLIZZ_FONT, BLIZZ_FLAGS; end
	local probe = UIParent:CreateFontString(nil, "BACKGROUND", "TextStatusBarText");
	if probe then
		local f, _, fl = probe:GetFont();
		BLIZZ_FONT, BLIZZ_FLAGS = f, fl;
		probe:Hide();
	end
	return BLIZZ_FONT, BLIZZ_FLAGS;
end
local UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP, UnitPowerMax = UnitFactionGroup, UnitIsPVPFreeForAll, UnitIsPVP, UnitPowerMax;

local NidhausPartyFrame;
local Path;
local isInitialized = false;

--	Party frame
local function Nidhaus_UnitFrames_Style_PartyMemberFrame(id)
	local partyFrame = _G["PartyMemberFrame"..id];
	if not partyFrame then return; end
	
	-- ── Escala ───────────────────────────────────────────────────
	-- El modo 3v3 tiene su PROPIA escala por miembro (1.5 para los dos
	-- primeros, 1.3 para los otros). Aplicar C.PartyFrameScale a ciegas la
	-- pisaba, y como esta funcion la llama K.RestylePartyFrames — o sea el
	-- desplegable de contorno y el slider de tamaño de texto — tocar la
	-- FUENTE te achicaba los marcos del grupo.
	--
	-- Es el mismo problema que ya tenia el bloque de posicion aca abajo: la
	-- funcion de ESTILO no puede decidir cosas que son de otro modo. Se
	-- respeta la misma precedencia.
	local scale = C.PartyFrameScale;
	if C.PartyMode3v3 and K.Get3v3Scale then
		scale = K.Get3v3Scale(id);
	end
	if type(scale) == "number" and scale > 0 and scale <= 3 then
		partyFrame:SetScale(scale);
	end
	-- OJO CON EL ORDEN: los estilos "New" e "Improved" ponen SU PROPIA
	-- textura. Si la de NUF se aplicara siempre, al reestilar los frames
	-- (cambio de estilo) le pisaria la textura al modulo y el marco volvia
	-- al de Blizzard. Por eso solo se aplica en el estilo Default.
	local pstyle = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
	if pstyle == "Default" then
		_G["PartyMemberFrame"..id.."Texture"]:SetTexture(Path.."UI-PartyFrame");
	end

	local hpTxt = _G["PartyMemberFrame"..id.."HealthBarText"];
	local mpTxt = _G["PartyMemberFrame"..id.."ManaBarText"];
	local nameTxt = _G["PartyMemberFrame"..id.."Name"];

	-- Se guarda UNA vez como venian de Blizzard (fuente y anclaje), para
	-- poder volver exacto cuando el estilo es "Blizzard".
	if hpTxt and not hpTxt._nufOrig then
		local f, sz, fl = hpTxt:GetFont();
		hpTxt._nufOrig = { font = { f, sz, fl }, pts = { hpTxt:GetPoint(1) } };
	end
	if mpTxt and not mpTxt._nufOrigFont then
		local f, sz, fl = mpTxt:GetFont();
		mpTxt._nufOrigFont = { f, sz, fl };
	end

	-- La fuente/posicion propias SOLO se aplican con un estilo custom.
	-- Antes se forzaba PartyFrameFont (tamaño 9) siempre, y por eso en modo
	-- Blizzard los textos se veian mas chicos que los originales.
	-- "Improved" tambien queda afuera: su marco es grande y con la fuente
	-- chica de NUF los numeros de vida/mana se veian diminutos. Va con la
	-- fuente y el anclaje originales de Blizzard, igual que el modo Default.
	local style = pstyle;
	if style ~= "Default" and style ~= "Improved" then
		if hpTxt then
			hpTxt:ClearAllPoints();
			hpTxt:SetPoint("CENTER", partyFrame, "CENTER", 19, 10);
			hpTxt:SetFont(unpack(C.PartyFrameFont));
		end
		if mpTxt then mpTxt:SetFont(unpack(C.PartyFrameFont)); end
	else
		-- Volver EXACTO al default de Blizzard
		if hpTxt and hpTxt._nufOrig then
			local o = hpTxt._nufOrig;
			if o.font[1] then hpTxt:SetFont(o.font[1], o.font[2], o.font[3]); end
			if o.pts and o.pts[1] then
				hpTxt:ClearAllPoints();
				hpTxt:SetPoint(o.pts[1], o.pts[2] or partyFrame, o.pts[3] or o.pts[1],
					o.pts[4] or 0, o.pts[5] or 0);
			end
		end
		if mpTxt and mpTxt._nufOrigFont and mpTxt._nufOrigFont[1] then
			local o = mpTxt._nufOrigFont;
			mpTxt:SetFont(o[1], o[2], o[3]);
		end
	end
	
	-- ── Fuente del grupo ──────────────────────────────────────────
	-- VA AL FINAL a proposito: la rama de arriba restaura la fuente
	-- original, asi que si esto corriera antes lo pisaria.
	--
	-- Con el estilo "Blizzard" NO se toca nada: queda el default del juego.
	-- Por eso el panel esconde esta seccion cuando ese estilo esta activo.
	--
	-- Reparto: el CONTORNO es solo para el nombre; el TAMAÑO es solo para
	-- vida y mana. Antes los dos se aplicaban a los tres textos por igual.
	local isCustomStyle = (pstyle == "New" or pstyle == "Improved");
	if isCustomStyle then
		local outline = C.PartyFontOutline;
		if outline == "" or outline == "Blizz" then outline = nil; end

		-- 0 = automatico. Por debajo de 6 el texto es ilegible y ademas
		-- otros modulos le restan puntos, quedando en 0 (SetFont tira
		-- error con altura 0).
		local fsize = tonumber(C.PartyFontSize) or 0;
		if fsize > 0 and fsize < 6 then fsize = 6; end

		-- Modo "Blizz": misma fuente y sombra que el texto de vida/mana.
		local blizzMode = (C.PartyFontOutline == "Blizz");
		local bFont, bFlags;
		if blizzMode then bFont, bFlags = BlizzStatusFont(); end

		-- Guarda el tamaño y la fuente de fabrica de cada texto, una vez.
		local function Base(fs)
			if not fs._nufBaseSize then
				local f0, sz0 = fs:GetFont();
				fs._nufBaseSize = sz0 or 10;
				fs._nufBaseFont = f0;
			end
			return fs._nufBaseFont, fs._nufBaseSize;
		end

		-- NOMBRE: solo el contorno. El tamaño lo sigue poniendo el estilo.
		if nameTxt then
			local bf, bs = Base(nameTxt);
			local f, sz = nameTxt:GetFont();
			if blizzMode and bFont then
				-- bFlags sale del propio FontObject: si el cliente le pone
				-- contorno, se copia el contorno. Poner solo sombra a mano
				-- daba un sombreado que no se parecia al original.
				pcall(nameTxt.SetFont, nameTxt, bFont, sz or bs, bFlags);
				pcall(nameTxt.SetShadowOffset, nameTxt, 1, -1);
				pcall(nameTxt.SetShadowColor, nameTxt, 0, 0, 0, 1);
			elseif f then
				pcall(nameTxt.SetFont, nameTxt, bf or f, sz or bs, outline);
			end
		end

		-- VIDA Y MANA: solo el tamaño. El contorno queda como lo dejo el
		-- estilo, para no pisarle el look a New Party / Improved.
		for _, fs in ipairs({ hpTxt, mpTxt }) do
			if fs then
				local bf, bs = Base(fs);
				local f, sz, fl = fs:GetFont();
				local target = (fsize > 0) and fsize or bs;
				if f then pcall(fs.SetFont, fs, f, target, fl); end
			end
		end
	end

	-- ── Posicion del PartyMemberFrame ────────────────────────────
	-- OJO: esta funcion la llama K.RestylePartyFrames, y a esa la llaman
	-- el desplegable de contorno y el slider de tamaño de texto. O sea que
	-- tocar la FUENTE terminaba REUBICANDO los frames.
	--
	-- Eso rompia el modo 3v3: Apply3v3PartyMode cuelga los frames de
	-- UIParent en posiciones propias, y este bloque los volvia a colgar de
	-- NidhausPartyFrame en fila. Cambiabas el contorno y el grupo se te iba
	-- a otro lado. Lo mismo con los frames movidos a mano.
	--
	-- La precedencia correcta ya esta escrita en K.ApplyPartyFrameSpacing:
	-- 3v3 manda sobre el layout en fila, y el movimiento individual manda
	-- sobre los dos. Aca se replican esos dos cortes en vez de posicionar
	-- a ciegas.
	if not C.SetPositions then return; end;
	if not NidhausPartyFrame then return; end;
	if C.PartyMode3v3 then return; end;
	if C.PartyIndividualMove then return; end;

	partyFrame:ClearAllPoints();
	partyFrame:SetParent(NidhausPartyFrame);
	if id == 1 then
		partyFrame:SetPoint("TOPLEFT", NidhausPartyFrame, "TOPLEFT");
	else
		-- FIX: - en vez de + para que valores positivos expandan
		partyFrame:SetPoint("TOPLEFT", _G["PartyMemberFrame"..(id - 1).."PetFrame"], "BOTTOMLEFT", -23, -10 - C.PartyMemberFrameSpacing);
	end;
end;

local function partyPvpIcon(self)
	local id = self:GetID();
	local unit = "party"..id;
	local icon = _G["PartyMemberFrame"..id.."PVPIcon"];
	local factionGroup = UnitFactionGroup(unit);
	if UnitIsPVPFreeForAll(unit) then
		icon:SetTexture(Path.."UI-PVP-FFA");
	elseif factionGroup and UnitIsPVP(unit) then
		icon:SetTexture(Path.."UI-PVP-"..factionGroup);
	end
end;

-- PetFrame;
local function Nidhaus_UnitFrames_PartyMemberFrame_UpdatePet(self, id)
	if id then return; end;
	_G[self:GetName().."PetFrameTexture"]:SetTexture(Path.."UI-PartyFrame");
	-- Si el usuario apago las mascotas del grupo, se ocultan de nuevo aca:
	-- Blizzard las vuelve a mostrar en cada update del miembro.
	if C.PartyShowPetFrames == false then
		local pf = _G[self:GetName().."PetFrame"];
		if pf then pf:Hide(); end
	end
end;

-- Muestra / oculta los marcos de mascota de los COMPAÑEROS (no el tuyo).
-- Ojo: no se tocan los anclajes; los marcos ocultos conservan su posicion,
-- asi que el espaciado entre miembros no se mueve.
function K.ApplyPartyPetFrames()
	local show = (C.PartyShowPetFrames ~= false);
	for i = 1, 4 do
		local pf = _G["PartyMemberFrame" .. i .. "PetFrame"];
		if pf then
			if show then
				-- Solo se muestra si ese compañero TIENE mascota; si no,
				-- apareceria un marco vacio.
				if UnitExists("partypet" .. i) then pf:Show(); else pf:Hide(); end
			else
				pf:Hide();
			end
		end
	end
end

local function InitializePartyFrames()
	if isInitialized then return; end
	
	-- Determinar path de texturas
	if C.darkFrames then 
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\";
	else
		Path = "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\";
	end
	
	-- Crear frame contenedor solo si SetPositions está activo Y no existe aún
	if C.SetPositions and not NidhausPartyFrame then
		NidhausPartyFrame = CreateFrame("Frame", nil, UIParent);
		NidhausPartyFrame:SetSize(10, 10);
		-- FIX: PartyMemberFrame1 puede no existir aún en este punto
		if PartyMemberFrame1 then
			NidhausPartyFrame:SetFrameStrata(PartyMemberFrame1:GetFrameStrata());
		end
		K.NidhausPartyFrame = NidhausPartyFrame;
	end
	
	-- Aplicar estilos a cada party frame
	for i = 1, MAX_PARTY_MEMBERS do
		Nidhaus_UnitFrames_Style_PartyMemberFrame(i);
	end
	
	-- Registrar hooks solo una vez
	hooksecurefunc("PartyMemberFrame_UpdatePvPStatus", partyPvpIcon);
	hooksecurefunc("PartyMemberFrame_UpdatePet", Nidhaus_UnitFrames_PartyMemberFrame_UpdatePet);
	
	isInitialized = true;
end

K.InitializePartyFrames = InitializePartyFrames;

-- La llama PartyFrameStyle al cambiar de estilo, para que los textos se
-- adapten (fuente propia con estilos custom, default con Blizzard).
function K.RestylePartyFrames()
	if not isInitialized then return; end
	for i = 1, MAX_PARTY_MEMBERS do
		Nidhaus_UnitFrames_Style_PartyMemberFrame(i);
	end
end

function K.ApplyPartyFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	
	for i = 1, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame then
			partyFrame:SetScale(scale);
		end
	end
end

-- FIX: Aplicar spacing en tiempo real
function K.ApplyPartyFrameSpacing()
	if not isInitialized then return; end
	
	local spacing = C.PartyMemberFrameSpacing;
	if type(spacing) ~= "number" then spacing = 0; end
	
	-- FIX: Do NOT re-apply 3v3 positions if PartyIndividualMove is active.
	-- The user dragged frames individually — re-applying 3v3 wipes those positions.
	if C.SetPositions and C.PartyMode3v3 and not C.PartyIndividualMove and K.Apply3v3PartyMode then
		K.Apply3v3PartyMode();
		return;
	end
	
	-- If PartyIndividualMove is active, don't touch positions at all
	if C.PartyIndividualMove then return; end
	
	for i = 2, MAX_PARTY_MEMBERS do
		local partyFrame = _G["PartyMemberFrame"..i];
		if partyFrame then
			local prevPet = _G["PartyMemberFrame"..(i-1).."PetFrame"];
			partyFrame:ClearAllPoints();
			if prevPet then
				partyFrame:SetPoint("TOPLEFT", prevPet, "BOTTOMLEFT", -23, -10 - spacing);
			else
				partyFrame:SetPoint("TOPLEFT", _G["PartyMemberFrame"..(i-1)], "BOTTOMLEFT", 0, -10 - spacing);
			end
		end
	end
end

K.RegisterConfigEvent("CONFIG_LOADED", function()
	if C.PartyFrameOn then
		InitializePartyFrames();
	end
end);

K.RegisterConfigEvent("CONFIG_CHANGED", function()
	if not isInitialized then return; end
	
	-- FIX: Do NOT apply generic PartyFrameScale when 3v3 mode is active.
	-- 3v3 mode sets per-frame scales (1.5 for frames 1-2, 1.3 for 3-4).
	-- Applying the generic scale here would overwrite those to 1.0.
	if not (C.SetPositions and C.PartyMode3v3) then
		if C.PartyFrameScale then
			K.ApplyPartyFrameScale(C.PartyFrameScale);
		end
	end
	
	-- Only apply spacing if user hasn't individually moved party frames.
	if not C.PartyIndividualMove then
		K.ApplyPartyFrameSpacing();
	end
end);

-- Reaplicar cuando cambia el grupo o aparece/desaparece una mascota:
-- Blizzard vuelve a mostrar los marcos por su cuenta en esos momentos.
local petEvents = CreateFrame("Frame");
petEvents:RegisterEvent("PLAYER_ENTERING_WORLD");
petEvents:RegisterEvent("PARTY_MEMBERS_CHANGED");
petEvents:RegisterEvent("UNIT_PET");
petEvents:SetScript("OnEvent", function()
	if K.ApplyPartyPetFrames then K.ApplyPartyPetFrames(); end
end);
