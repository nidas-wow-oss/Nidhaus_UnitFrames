local AddOnName, ns = ...;
local K, C, L = unpack(ns);

K.DeferModule("ButtonRange", {
    name = L["MOD_BUTTON_RANGE"] or "Button Range",
    desc = L["MOD_BUTTON_RANGE_DESC"] or "Colors out-of-range action buttons red.",
    default = false,

    hideFromModulesTab = true,
}, function()
    local hooked = false;

    local brEnabled = false;

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

                    local icon = _G[self:GetName().."Icon"];
                    local normalTex = _G[self:GetName().."NormalTexture"];
                    if icon then icon:SetVertexColor(1, 0, 0); end

                    local onRing = LortiRed() and K.LortiRangeBorder(self, true);
                    if normalTex and not onRing then normalTex:SetVertexColor(1, 0, 0); end
                    range = true;
                end

                if not range and K.LortiRangeBorder then K.LortiRangeBorder(self, false); end
                if self.range ~= range and range == false then
                    ActionButton_UpdateUsable(self);
                end
                self.range = range;
            end
        end);
        hooked = true;
    end

    function K.ButtonRangeResetLorti()
        if K.LortiRangeBorderReset then K.LortiRangeBorderReset(); end
    end

    K.RegisterModule("ButtonRange", {
        onEnable = EnableButtonRange,
        onDisable = function()
            brEnabled = false;
            K.ButtonRangeResetLorti();
        end,
    });
end);
