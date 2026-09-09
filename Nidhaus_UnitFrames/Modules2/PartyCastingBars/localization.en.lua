--[[
	PartyCastingBars - English Localization
	
	By: AnduinLothar
	
	$Id: localization.en.lua 4136 2006-10-10 00:23:30Z karlkfi $
	$Rev: 4136 $
	$LastChangedBy: karlkfi $
	$Date: 2006-10-09 17:23:30 -0700 (Mon, 09 Oct 2006) $
]]--

-- Khaos Configuration

PCB_SECTION_TEXT			= "PartyCastingBars";
PCB_SECTION_TIP				= "These options configure PartyCastingBars, casting bars for your party member unit frames.";
PCB_HEADER_TEXT				= "PartyCastingBars";
PCB_HEADER_TIP				= "By AnduinLothar";
PCB_ENABLE_TEXT				= "Enable PartyCastingBars";
PCB_ENABLE_TIP				= "Enables/Disables PartyCastingBars.";
PCB_SHOW_ICON_TEXT			= "Show Spell Icons";
PCB_SHOW_ICON_TIP			= "Puts the spell icon next to the casting bars.";
PCB_PARTYMEMBERFRAME_PARENT_TEXT		= "Attach To Default Party Member Frames";
PCB_PARTYMEMBERFRAME_PARENT_TIP			= "Sets the parents of the casting bars to the individual party member frames.";
PCB_SCALE_TEXT				= "Casting Bar Scale";
PCB_SCALE_TIP				= "Sets scale of the casting bars.";
PCB_SCALE					= "Scale";
PCB_DRAGGABLE_TEXT			= "Enable Casting Bar Mobility";
PCB_DRAGGABLE_TIP			= "Put the bars into dragging mode, where they will become visible and not show casts btu can be dragged.";
PCB_RESET_TEXT				= "Reset Casting Bar Locations";
PCB_RESET_TIP				= "Align the bars to the right side of the default party member frames.";
PCB_SETTEXT					= "Change";
PCB_RESETTEXT				= "Reset";
PCB_HEADER_FRIENDLY_TEXT	= "Friendly Cast Colors";
PCB_HEADER_FRIENDLY_TIP		= "Colors used when the cast is directed at a friendly target";
PCB_HEADER_HOSTILE_TEXT		= "Hostile Cast Colors";
PCB_HEADER_HOSTILE_TIP		= "Colors used when the cast is directed at a hostile target";
PCB_CASTCOLOR_HOSTILE_SET			= "Casting color (Default is orange):";
PCB_CASTCOLOR_FRIENDLY_SET			= "Casting color (Default is light blue):";
PCB_CASTCOLOR_SET_TIP				= "Changes the color of the bar when casting a generic spell.";
PCB_CASTCOLOR_RESET					= "Reset cast color";
PCB_CASTCOLOR_RESET_TIP				= "Resets the cast color to orange.";
PCB_CHANNELCOLOR_HOSTILE_SET		= "Channeling color (Default is green):";
PCB_CHANNELCOLOR_FRIENDLY_SET		= "Channeling color (Default is green):";
PCB_CHANNELCOLOR_SET_TIP			= "Changes the color of the bar when casting a channeling spell.";
PCB_CHANNELCOLOR_RESET				= "Reset channeling color";
PCB_CHANNELCOLOR_RESET_TIP			= "Resets the channeling color to green.";
PCB_SUCCESSCOLOR_HOSTILE_SET		= "Success color (Default is green):";
PCB_SUCCESSCOLOR_FRIENDLY_SET		= "Success color (Default is green):";
PCB_SUCCESSCOLOR_SET_TIP			= "Changes the color of the bar when a spell finishes/succeeds.";
PCB_SUCCESSCOLOR_RESET				= "Reset success color";
PCB_SUCCESSCOLOR_RESET_TIP			= "Resets the success color to green.";
PCB_FAILURECOLOR_HOSTILE_SET		= "Failure color (Default is red):";
PCB_FAILURECOLOR_FRIENDLY_SET		= "Failure color (Default is red):";
PCB_FAILURECOLOR_SET_TIP			= "Changes the color of the bar when a spell fails/aborts.";
PCB_FAILURECOLOR_RESET				= "Reset failure color";
PCB_FAILURECOLOR_RESET_TIP			= "Resets the failure color to red.";

PCB_COLOR_CHANGED			= "|c%s%s color changed.|r";
PCB_COLOR_RESET				= "|c%s%s color reset.|r";

PCB_SHOWNICONFEEDBACK_NEGATIVE	= "ArcanePartyBars - Spell icon will be hidden.";
PCB_SHOWNICONFEEDBACK_POSITIVE	= "ArcanePartyBars - Spell icon will be shown.";

PCB_PARTYMEMBERFRAME_PARENT_NEGATIVE	= "ArcanePartyBars - Bars parented to UIParent.";
PCB_PARTYMEMBERFRAME_PARENT_POSITIVE	= "ArcanePartyBars - Bars parented to party member frames.";

PCB_SCALE_NEGATIVE	= "ArcanePartyBars - Bar scale reset to 1.0.";
PCB_SCALE_POSITIVE	= "ArcanePartyBars - Bar scale set to %.1f.";

PCB_COLOR_SET = "ArcanePartybars - %s %s Colors Set: |c%s%.1f, %.1f, %.1f|r"

PCB_DRAGGABLE		= "Draggable";

PCB_DRAGGABLE_NEGATIVE	= "ArcanePartyBars - Bars are now in casting mode.";
PCB_DRAGGABLE_POSITIVE	= "ArcanePartyBars - Bars are now in dragging mode.";

PCB_LOCATIONS_RESET		= "ArcanePartyBars - Bar Locations have been reset.";

SLASH_PARTYCASTINGBARS1 = "/partycastingbars";
SLASH_PARTYCASTINGBARS2 = "/pcb";

-------
-- Note: Color strings are format |c########Translatable text here|r
-------
	 	
PCB_HELP1				= "|c0055AA55PartyCastingBars Slash Command Help ("
							..SLASH_PARTYCASTINGBARS2.." help).|r";
PCB_HELP2				= "|c00995555Note that these commands only work when Portfolio is diabled. These settings can be found in the Interface Option Panel when Portfolio is enabled.|r";
PCB_HELP3				= "|c00555555Enable|r - |c00AA5555Enable PartyCastingBars.|r";
PCB_HELP4				= "|c00555555Disable|r - |c00AA5555Mystery.|r";
PCB_HELP5				= "|c00555555Set <Friendly\124Hostile> <Failure\124Success\124Channel\124Cast>|r\n - |c00AA5555Open a dialog for setting the bar color for a specific target relationship and cast event.|r";
PCB_HELP6				= "|c00555555Reset <Friendly\124Hostile> <Failure\124Success\124Channel\124Cast>|r\n - |c00AA5555Reset the bar color for a specific target relationship and cast event.|r";
PCB_HELP7				= "|c00555555Help|r - |c00AA5555Display Slash Command Help.|r";

PCB_INVALID_COMMAND		= "Unknown PartyCastingBars command. Type \"/pcb help\" for command listing.";

PCB_ENABLED				= "PartyCastingBars enabled.";
PCB_DISABLED			= "PartyCastingBars disabled.";