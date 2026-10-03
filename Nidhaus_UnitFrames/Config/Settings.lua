local AddOnName, ns = ...;
local K, C, L = unpack(ns);








C["statusbarOn"] = true;
C["PlayerFrameOn"] = true;
C["TargetFrameOn"] = true;
C["PartyMode"] = "3v3";






C["statusbarTexture"] = "Interface\\AddOns\\"..AddOnName.."\\Media\\Statusbar\\whoa";
C["statusbarBackdropColor"] = {0, 0, 0, 0.2};


C["PartyFrameFont"] = {"Fonts\\FRIZQT__.TTF", 9, "OUTLINE"};



C["PartyFontOutline"] = "OUTLINE";
C["ArenaFrameFont"] = {"Fonts\\FRIZQT__.TTF", 7, "OUTLINE"};





C["PlayerNameOffset"] = {0, 0};
C["TargetNameOffset"] = {0, 0};


















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


if not C["ArenaFramePoint"] then
	C["ArenaFramePoint"] = { unpack(K.DEFAULT_FRAME_POINTS.ArenaFramePoint) };
end




if not C["ArenaFlatBarTexture"] or C["ArenaFlatBarTexture"] == "" then
	C["ArenaFlatBarTexture"] = C["statusbarTexture"] or "Interface\\AddOns\\"..AddOnName.."\\Media\\Statusbar\\whoa";
end