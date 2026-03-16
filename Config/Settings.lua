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
C["ArenaFrameFont"] = {"Fonts\\FRIZQT__.TTF", 7, "OUTLINE"};

-- = OFFSETS DE NOMBRES =
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

if not C["PlayerFramePoint"] then
	C["PlayerFramePoint"] = {"TOPLEFT", UIParent, "TOPLEFT", 239, -4};
end

if not C["TargetFramePoint"] then
	C["TargetFramePoint"] = {"TOPLEFT", UIParent, "TOPLEFT", 509, -4};
end

if not C["PartyMemberFramePoint"] then
	C["PartyMemberFramePoint"] = {"TOPLEFT", UIParent, "TOPLEFT", 10, -160};
end

if not C["BossTargetFramePoint"] then
	C["BossTargetFramePoint"] = {"TOPLEFT", UIParent, "TOPLEFT", 1300, -220};
end

-- ARENA FRAME POINT: Esta es la posición DEFAULT cuando SetPositions = true
if not C["ArenaFramePoint"] then
	C["ArenaFramePoint"] = {"TOPRIGHT", UIParent, "TOPRIGHT", -390, -330};
end

-- FLAT STYLE: Textura de barras
-- FIX: Usar la textura propia del addon como default en vez de depender de sArena
-- Si sArena no está instalado, la textura no existe y las barras quedan blancas/vacías
if not C["ArenaFlatBarTexture"] or C["ArenaFlatBarTexture"] == "" then
	C["ArenaFlatBarTexture"] = C["statusbarTexture"] or "Interface\\AddOns\\"..AddOnName.."\\Media\\Statusbar\\whoa";
end