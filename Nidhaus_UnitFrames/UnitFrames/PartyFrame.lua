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

-- La carpeta del tema se lee en cada uso: si se calculara una sola vez,
-- cambiar Light/Dark dejaba el grupo con las texturas del tema viejo.
local function ThemePath()
	if C.darkFrames then
		return "Interface\\AddOns\\"..AddOnName.."\\Media\\Dark\\";
	end
	return "Interface\\AddOns\\"..AddOnName.."\\Media\\Light\\";
end

--	Party frame
local function Nidhaus_UnitFrames_Style_PartyMemberFrame(id)
	local partyFrame = _G["PartyMemberFrame"..id];
	if not partyFrame then return; end
	Path = ThemePath();

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
	-- EN COMBATE NO. PartyMemberFrame es un marco protegido: cambiarle la
	-- escala peleando lo corta el juego ("An action was blocked in combat
	-- because of taint from Nidhaus_UnitFrames - PartyMemberFrame1:SetScale()"
	-- en el taint.log, al recargar en un BG). RestylePartyFrames la vuelve a
	-- pedir al terminar la pelea.
	if type(scale) == "number" and scale > 0 and scale <= 3 and not InCombatLockdown() then
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
	-- La mascota la pinta el gancho de UpdatePet, que solo corre cuando
	-- Blizzard la actualiza: al cambiar de tema se repinta aca tambien.
	local petTex = _G["PartyMemberFrame"..id.."PetFrameTexture"];
	if petTex then petTex:SetTexture(Path.."UI-PartyFrame"); end

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
		-- El LUGAR del numero lo pone cada estilo (New y los dos de pw lo
		-- reanclan al pintar); si se anclaba aca, un restyle suelto (cambio
		-- de tema) lo dejaba corrido hasta el proximo repintado del estilo.
		-- Compact 2 pone ademas su propia fuente (la de arena).
		if style ~= "PW2" then
			if hpTxt then hpTxt:SetFont(unpack(C.PartyFrameFont)); end
			if mpTxt then mpTxt:SetFont(unpack(C.PartyFrameFont)); end
		end
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
	-- original, asi que si esto corriera antes lo pisaria. La cuenta vive
	-- en K.ApplyPartyTextFont (abajo), que tambien llaman Improved y los
	-- dos estilos de pw al terminar de pintar.
	if K.ApplyPartyTextFont then K.ApplyPartyTextFont(id); end

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
	-- Mover un marco protegido en combate tambien lo corta el juego.
	if InCombatLockdown() then return; end;
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
	Path = ThemePath();
	if UnitIsPVPFreeForAll(unit) then
		icon:SetTexture(Path.."UI-PVP-FFA");
	elseif factionGroup and UnitIsPVP(unit) then
		icon:SetTexture(Path.."UI-PVP-"..factionGroup);
	end
end;

-- PetFrame;
local function Nidhaus_UnitFrames_PartyMemberFrame_UpdatePet(self, id)
	if id then return; end;
	Path = ThemePath();
	_G[self:GetName().."PetFrameTexture"]:SetTexture(Path.."UI-PartyFrame");
	-- Si el usuario apago las mascotas del grupo, se ocultan de nuevo aca:
	-- Blizzard las vuelve a mostrar en cada update del miembro.
	if C.PartyShowPetFrames == false then
		-- Por ApplyPartyPetFrames, que en combate lo deja para despues y
		-- solo llama a Hide si hace falta. Aca llamaba Hide directo: en
		-- combate el juego lo cortaba (el marco de mascota es protegido).
		if K.ApplyPartyPetFrames then K.ApplyPartyPetFrames(); end
	end
end;

-- Muestra / oculta los marcos de mascota de los COMPAÑEROS (no el tuyo).
-- Ojo: no se tocan los anclajes; los marcos ocultos conservan su posicion,
-- asi que el espaciado entre miembros no se mueve.
-- OJO: los PartyMemberFrameNPetFrame son marcos PROTEGIDOS (cuelgan de los
-- party frames, que heredan SecureUnitButtonTemplate), asi que Show y Hide
-- sobre ellos estan vedados en combate.
--
-- Y esto se dispara con UNIT_PET, que en 3.3.5a no se puede filtrar por
-- unidad: salta por CADA unidad en rango. En un BG eso son decenas de
-- llamadas por pelea, todas cortadas por el cliente. Dos cambios:
--   1) en combate se anota y se aplica al salir;
--   2) solo se llama a Show/Hide cuando el estado CAMBIA de verdad. Antes
--      se llamaba siempre, aunque el marco ya estuviera como corresponde,
--      y una llamada que no hace nada igual se cuenta como accion
--      bloqueada.
local petPending = false;

function K.ApplyPartyPetFrames()
	if InCombatLockdown() then petPending = true; return; end
	petPending = false;

	local show = (C.PartyShowPetFrames ~= false);
	for i = 1, 4 do
		local pf = _G["PartyMemberFrame" .. i .. "PetFrame"];
		if pf then
			-- La misma regla que PartyMemberFrame_UpdatePet: compañero
			-- conectado, con mascota y la opcion de Blizzard de mascotas
			-- del grupo prendida. Si no, se le pisaba esa opcion.
			local want = show and UnitIsConnected("party" .. i) and UnitExists("partypet" .. i)
				and SHOW_PARTY_PETS == "1" and true or false;
			if want and not pf:IsShown() then
				pf:Show();
			elseif (not want) and pf:IsShown() then
				pf:Hide();
			end
		end
	end
end

local function InitializePartyFrames()
	if isInitialized then return; end
	
	-- Determinar path de texturas
	Path = ThemePath();
	
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
-- ---------------------------------------------------------
-- TEXTO DEL GRUPO: NOMBRE Y NUMEROS, CADA UNO CON SU CONTORNO Y SU TAMAÑO
--
-- Una sola funcion, y la llama cada estilo AL TERMINAR de pintar su
-- marco: este archivo (New Party), Improved y los dos de pw (Big Blizzard
-- y Compact 2). Asi ninguno le pisa al otro lo que elegiste.
--
--   * NOMBRE:  contorno (PartyFontOutline) y tamaño (PartyNameSize_<estilo>).
--   * NUMEROS: contorno (PartyNumOutline)  y tamaño (PartyNumSize_<estilo>).
--
-- El tamaño es POR ESTILO: Improved tiene el marco grande y Compact 2 el
-- angosto, asi que no les queda bien el mismo numero. 0 = "Auto", el que
-- pone el estilo. En los numeros y en el contorno "Style", lo del estilo
-- tambien: no se toca, y como cada estilo vuelve a poner su fuente antes
-- de llamar aca, volver a Auto devuelve lo suyo solo.
--
-- El nombre en Big Blizzard y Compact 2 es la excepcion: esos estilos no
-- le ponen fuente, asi que "Auto" lo devuelve a su tamaño de fabrica, que
-- se fotografia al cargar (antes de que nadie lo toque).
--
-- Con el estilo "Blizzard" no se toca nada: manda el default del juego.
-- ---------------------------------------------------------
local MIN_PARTY_FONT = 6;    -- por debajo es ilegible, y SetFont con 0 tira error

-- La foto de fabrica del nombre, AL CARGAR: los marcos del grupo vienen
-- del XML de Blizzard, asi que ya existen. New Party la usa al apagarse.
for i = 1, (MAX_PARTY_MEMBERS or 4) do
	local n = _G["PartyMemberFrame" .. i .. "Name"];
	if n and n.GetFont and not n._nufBaseSize then
		local f0, s0, fl0 = n:GetFont();
		n._nufBaseFont, n._nufBaseSize, n._nufBaseFlags = f0, s0, fl0;
	end
end

local function PartySize(kind, style)
	local v = tonumber(C["Party" .. kind .. "Size_" .. tostring(style)]) or 0;
	if v <= 0 then return 0; end
	if v < MIN_PARTY_FONT then v = MIN_PARTY_FONT; end
	return v;
end
K.GetPartyTextSize = PartySize;

function K.ApplyPartyTextFont(id)
	local style = (K.GetPartyFrameStyle and K.GetPartyFrameStyle()) or "Default";
	local fn = "PartyMemberFrame" .. id;
	if style == "Default" then
		-- Volviendo a Blizzard: si le habiamos cambiado el nombre (contorno o
		-- tamaño en otro estilo), vuelve a como venia. Los numeros ya los
		-- devuelve el estilo (rama "Default" de arriba).
		local n = _G[fn .. "Name"];
		if n and n._nufTouched and n._nufBaseFont and n._nufBaseSize then
			pcall(n.SetFont, n, n._nufBaseFont, n._nufBaseSize, n._nufBaseFlags);
			n._nufTouched = nil;
		end
		return;
	end

	-- NOMBRE
	local nameTxt = _G[fn .. "Name"];
	if nameTxt then
		if not nameTxt._nufBaseSize then
			local f0, s0, fl0 = nameTxt:GetFont();
			nameTxt._nufBaseFont, nameTxt._nufBaseSize, nameTxt._nufBaseFlags = f0, s0, fl0;
		end
		local f, sz = nameTxt:GetFont();
		local want = PartySize("Name", style);
		if want == 0 and (style == "PW" or style == "PW2") then
			want = nameTxt._nufBaseSize or sz;
		end
		if want == 0 then want = sz; end
		local mode = C.PartyFontOutline;
		if mode == nil then mode = "OUTLINE"; end
		if mode == "Blizz" then
			-- Misma cara, contorno y sombra que el numero de vida/mana.
			local bFont, bFlags = BlizzStatusFont();
			if bFont and want then
				nameTxt._nufTouched = true;
				pcall(nameTxt.SetFont, nameTxt, bFont, want, bFlags);
				pcall(nameTxt.SetShadowOffset, nameTxt, 1, -1);
				pcall(nameTxt.SetShadowColor, nameTxt, 0, 0, 0, 1);
			end
		elseif f and want then
			nameTxt._nufTouched = true;
			pcall(nameTxt.SetFont, nameTxt, f, want, (mode ~= "") and mode or nil);
		end
	end

	-- NUMEROS DE VIDA Y MANA
	local size = PartySize("Num", style);
	local nmode = C.PartyNumOutline;
	if nmode == nil then nmode = "Style"; end
	if size == 0 and nmode == "Style" then return; end
	for _, fs in ipairs({ _G[fn .. "HealthBarText"], _G[fn .. "ManaBarText"] }) do
		if fs then
			local f, cur, fl = fs:GetFont();
			if f then
				local target = (size > 0) and size or cur;
				local flags = fl;
				if nmode ~= "Style" then flags = (nmode ~= "") and nmode or nil; end
				if target and (math.abs((cur or 0) - target) > 0.05 or flags ~= fl) then
					pcall(fs.SetFont, fs, f, target, flags);
				end
			end
		end
	end
end

-- Lo que llaman el desplegable y el slider del panel: que cada estilo
-- vuelva a pintar lo suyo (y con eso su fuente de base) y que al final
-- se aplique lo del panel. Cada uno sabe si es el activo.
function K.RefreshPartyText()
	if K.RestylePartyFrames   then K.RestylePartyFrames();   end
	if K.UpdateNewPartyFrames then K.UpdateNewPartyFrames(); end
	if K.PFI_Restyle          then K.PFI_Restyle();          end
	if K.PartyFramePW_Restyle then K.PartyFramePW_Restyle(); end
end

function K.RestylePartyFrames()
	if not isInitialized then return; end
	-- En combate se aplica lo que se puede (fuentes y texturas) y la escala
	-- y el lugar, que el juego no deja tocar peleando, se completan solos
	-- al terminar la pelea con una pasada entera.
	if InCombatLockdown() and K.AfterCombat then
		K.AfterCombat("RestylePartyFrames", K.RestylePartyFrames);
	end
	-- TEXTO ABREVIADO: el estilo reancla y cambia la fuente del numero de
	-- vida. Antes de eso el abreviado suelta sus anclajes (devuelve el
	-- texto a su lugar), y despues vuelve a aplicarse sobre lo nuevo. Si
	-- no, el numero quedaba donde lo ponia el estilo y el porcentaje donde
	-- lo ponia el abreviado, encimados, hasta el proximo cambio de vida.
	if K.ReleaseAbbrevAnchors then pcall(K.ReleaseAbbrevAnchors, "PartyMemberFrame"); end
	for i = 1, MAX_PARTY_MEMBERS do
		Nidhaus_UnitFrames_Style_PartyMemberFrame(i);
	end
	if K.RefreshAbbreviatedStatusBars then pcall(K.RefreshAbbreviatedStatusBars); end
end

function K.ApplyPartyFrameScale(scale)
	if not isInitialized then return; end
	if type(scale) ~= "number" or scale <= 0 or scale > 3 then return; end
	-- Marcos protegidos: en combate SetScale lo bloquea el juego (cualquier
	-- opcion del panel dispara esto). Se repite al salir, con lo que valga
	-- en ese momento y respetando el 3v3.
	if InCombatLockdown() then
		if K.AfterCombat then
			K.AfterCombat("ApplyPartyFrameScale", function()
				if not (K.Is3v3Active and K.Is3v3Active()) then K.ApplyPartyFrameScale(C.PartyFrameScale); end
			end);
		end
		return;
	end

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
	-- Mover marcos protegidos en combate lo corta el juego: al salir.
	if InCombatLockdown() then
		if K.AfterCombat then K.AfterCombat("ApplyPartyFrameSpacing", K.ApplyPartyFrameSpacing); end
		return;
	end

	local spacing = C.PartyMemberFrameSpacing;
	if type(spacing) ~= "number" then spacing = 0; end
	
	-- FIX: Do NOT re-apply 3v3 positions if PartyIndividualMove is active.
	-- The user dragged frames individually — re-applying 3v3 wipes those positions.
	-- Mismo criterio que el modulo del 3v3: no se le suma SetPositions.
	if K.Is3v3Active and K.Is3v3Active() and not C.PartyIndividualMove and K.Apply3v3PartyMode then
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
	-- ACA ESTABA EL BUG DE LA ESCALA DEL 3v3.
	--
	-- La guarda pedia SetPositions ADEMAS de PartyMode3v3, pero el modulo
	-- del 3v3 hace rato que no exige SetPositions. Con las posiciones
	-- custom apagadas, esta condicion daba true con el 3v3 puesto y le
	-- aplicaba C.PartyFrameScale a los cuatro marcos, pisando el
	-- 1.5 / 1.5 / 1.3 / 1.3 del modo. Ahora los dos preguntan lo mismo.
	if not (K.Is3v3Active and K.Is3v3Active()) then
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
petEvents:RegisterEvent("PLAYER_REGEN_ENABLED");
petEvents:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_ENABLED" and not petPending then return; end
	if K.ApplyPartyPetFrames then K.ApplyPartyPetFrames(); end
end);
