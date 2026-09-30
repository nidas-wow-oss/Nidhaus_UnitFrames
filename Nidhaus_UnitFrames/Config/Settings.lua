local AddOnName, ns = ...;
local K, C, L = unpack(ns);

-- Settings.lua - Configuración de constantes y valores NO configurables
-- 
-- IMPORTANTE: Este archivo se carga DESPUÉS de ConfigManager.lua
-- NO debe sobreescribir valores que están en ConfigManager.defaults
-- Solo debe setear valores CONSTANTES que no están en la DB

-- = OPCIONES SIEMPRE ACTIVAS (no configurables) =
C["statusbarOn"] = true;
C["PlayerFrameOn"] = true;
C["TargetFrameOn"] = true;
C["PartyMode"] = "3v3";

-- = TEMA VISUAL =
-- darkFrames is now managed by ConfigManager.lua (saved in DB)
-- Do NOT set C["darkFrames"] here - it would override the user's saved preference

-- = TEXTURAS Y COLORES =
C["statusbarTexture"] = "Interface\\AddOns\\"..AddOnName.."\\Media\\Statusbar\\whoa";
C["statusbarBackdropColor"] = {0, 0, 0, 0.2};

-- = FUENTES =
C["PartyFrameFont"] = {"Fonts\\FRIZQT__.TTF", 9, "OUTLINE"};
-- Contorno del texto de los miembros del grupo (ver PartyFrame.lua).
-- Vacio = sin contorno. Valores usados: OUTLINE, THICKOUTLINE, o "Blizz"
-- (modo especial: misma fuente y sombra que el texto de vida/mana).
C["PartyFontOutline"] = "OUTLINE";
C["ArenaFrameFont"] = {"Fonts\\FRIZQT__.TTF", 7, "OUTLINE"};

-- = OFFSETS DE NOMBRES =
-- 0,0 = donde lo pone Blizzard. Sin Asuri el nombre NO se toca; el ajuste
-- de altura vive en la rama Asuri de PlayerFrame.lua, que es el unico modo
-- donde el nombre queda mal ubicado.
C["PlayerNameOffset"] = {0, 0};
C["TargetNameOffset"] = {0, 0};

-- POSICIONES CUSTOM (DEFAULTS para cuando SetPositions = true)
-- 
-- IMPORTANTE: Estas son posiciones DEFAULT que se usan SOLO cuando:
-- 1. SetPositions = true
-- 2. No hay posición guardada por el usuario
-- 
-- Si el usuario mueve los frames, sus posiciones se guardan en
-- NidhausUnitFramesDB.positions y TIENEN PRIORIDAD sobre estas.

-- NOTA: NO sobreescribir si ConfigManager ya lo cargó desde la DB
-- Estos valores solo se usan como FALLBACK cuando no hay nada en la DB

-- UNA SOLA COPIA DE LAS POSICIONES DE FABRICA.
--
-- Estaban escritas aca y OTRA VEZ en el reset de FrameDragger. Mientras
-- coincidan no pasa nada; el dia que se cambie una y no la otra, el reset
-- deja los marcos en un lugar distinto del de una instalacion nueva.
K.DEFAULT_FRAME_POINTS = {
	PlayerFramePoint      = {"TOPLEFT",  UIParent, "TOPLEFT",  239,  -4},
	TargetFramePoint      = {"TOPLEFT",  UIParent, "TOPLEFT",  509,  -4},
	PartyMemberFramePoint = {"TOPLEFT",  UIParent, "TOPLEFT",   10, -160},
	BossTargetFramePoint  = {"TOPLEFT",  UIParent, "TOPLEFT", 1300, -220},
	ArenaFramePoint       = {"TOPRIGHT", UIParent, "TOPRIGHT", -390, -330},
};

if not C["PlayerFramePoint"] then
	C["PlayerFramePoint"] = { unpack(K.DEFAULT_FRAME_POINTS.PlayerFramePoint) };
end

if not C["TargetFramePoint"] then
	C["TargetFramePoint"] = { unpack(K.DEFAULT_FRAME_POINTS.TargetFramePoint) };
end

if not C["PartyMemberFramePoint"] then
	C["PartyMemberFramePoint"] = { unpack(K.DEFAULT_FRAME_POINTS.PartyMemberFramePoint) };
end

if not C["BossTargetFramePoint"] then
	C["BossTargetFramePoint"] = { unpack(K.DEFAULT_FRAME_POINTS.BossTargetFramePoint) };
end

-- ARENA FRAME POINT: Esta es la posición DEFAULT cuando SetPositions = true
if not C["ArenaFramePoint"] then
	C["ArenaFramePoint"] = { unpack(K.DEFAULT_FRAME_POINTS.ArenaFramePoint) };
end

-- FLAT STYLE: Textura de barras
-- FIX: Usar la textura propia del addon como default en vez de depender de sArena
-- Si sArena no está instalado, la textura no existe y las barras quedan blancas/vacías
if not C["ArenaFlatBarTexture"] or C["ArenaFlatBarTexture"] == "" then
	C["ArenaFlatBarTexture"] = C["statusbarTexture"] or "Interface\\AddOns\\"..AddOnName.."\\Media\\Statusbar\\whoa";
end