local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooked = false;
-- FIX: Cachear estado en local para evitar DB lookup en cada frame de cada botón
-- (antes: K.IsModuleEnabled("ButtonRange") = acceso a NidhausUnitFramesDB 700+ veces/seg)
local brEnabled = false;

-- =========================================================
-- BORDE ROJO DE LORTI UI (sub-opcion "Lorti UI red border")
--
-- Fuera de rango, ademas del icono rojo, el CONTORNO del boton de Lorti
-- (la sombra de alrededor) se pone rojo. Ese contorno es el mismo que
-- lleva el color de "Action Bars" de Lorti: el rojo lo REEMPLAZA mientras
-- dura, no se dibuja encima, y al volver al rango vuelve su color (lo
-- maneja K.LortiRangeBorder, en Lorti UI/func/functions.lua).
--
-- En este modo el borde de adentro (el gloss) NO se pinta de rojo: si no
-- quedarian dos aros pegados, uno rojo y otro del color elegido.
-- =========================================================
local function LortiRed()
    return C.ButtonRangeLortiRed == true and K.LortiRangeBorder ~= nil;
end

local function EnableButtonRange()
    brEnabled = true;
    if hooked then return; end
    hooksecurefunc("ActionButton_OnUpdate", function(self, elapsed)
        if not brEnabled then return; end
        if self.rangeTimer == TOOLTIP_UPDATE_TIME then
            local range = false;
            if IsActionInRange(self.action) == 0 then
                -- FIX: getglobal() está deprecada, usar _G[]
                local icon = _G[self:GetName().."Icon"];
                local normalTex = _G[self:GetName().."NormalTexture"];
                if icon then icon:SetVertexColor(1, 0, 0); end
                -- Con el borde rojo de Lorti el rojo va en el contorno; si el
                -- boton no tiene estilo Lorti (Lorti apagado) sigue como siempre.
                local onRing = LortiRed() and K.LortiRangeBorder(self, true);
                if normalTex and not onRing then normalTex:SetVertexColor(1, 0, 0); end
                range = true;
            end
            -- De vuelta en rango (o sin hechizo con rango): el contorno a su color.
            if not range and K.LortiRangeBorder then K.LortiRangeBorder(self, false); end
            if self.range ~= range and range == false then
                ActionButton_UpdateUsable(self);
            end
            self.range = range;
        end
    end);
    hooked = true;
end

-- Apagar Button Range o la sub-opcion: ningun contorno se queda rojo.
function K.ButtonRangeResetLorti()
    if K.LortiRangeBorderReset then K.LortiRangeBorderReset(); end
end

K.RegisterModule("ButtonRange", {
    name = L["MOD_BUTTON_RANGE"] or "Button Range",
    desc = L["MOD_BUTTON_RANGE_DESC"] or "Colors out-of-range action buttons red.",
    default = false,
    -- El checkbox vive en General > Barras, no repetirlo en la pestaña Modules
    hideFromModulesTab = true,
    onEnable = EnableButtonRange,
    onDisable = function()
        brEnabled = false;
        K.ButtonRangeResetLorti();
    end,
});
