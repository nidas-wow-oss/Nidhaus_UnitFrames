local AddOnName, ns = ...;
local K, C, L = unpack(ns);

local hooked = false;
-- FIX: Cachear estado en local para evitar DB lookup en cada frame de cada botón
-- (antes: K.IsModuleEnabled("ButtonRange") = acceso a NidhausUnitFramesDB 700+ veces/seg)
local brEnabled = false;

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
                if normalTex then normalTex:SetVertexColor(1, 0, 0); end
                range = true;
            end
            if self.range ~= range and range == false then
                ActionButton_UpdateUsable(self);
            end
            self.range = range;
        end
    end);
    hooked = true;
end

K.RegisterModule("ButtonRange", {
    name = "Button Range",
    desc = "Pone rojos los botones fuera de rango.",
    default = false,
    onEnable = EnableButtonRange,
    onDisable = function() brEnabled = false; end,
});