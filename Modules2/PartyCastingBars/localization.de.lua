--[[
	PartyCastingBars - German Localization
	
	By: StarDust
	
	$Id: localization.de.lua 4136 2006-10-10 00:23:30Z karlkfi $
	$Rev: 4136 $
	$LastChangedBy: karlkfi $
	$Date: 2006-10-09 17:23:30 -0700 (Mon, 09 Oct 2006) $
]]--

if ( GetLocale() == "deDE" ) then

	-- Khaos Configuration
	PCB_SECTION_TEXT			= "Gruppen-Zauberleisten";
	PCB_SECTION_TIP				= "Erlaubt es Zauber-Fortschrittsbalken der Gruppenmitgliedern neben deren Charakterfenster anzuzeigen und zu verschieben.";
	PCB_HEADER_TEXT				= "Gruppen-Zauberleisten";
	PCB_HEADER_TIP				= "Von AnduinLothar";
	PCB_ENABLE_TEXT				= "Gruppen-Zauberleisten aktivieren";
	PCB_ENABLE_TIP				= "Wenn aktiviert, werden die Zauber-Fortschrittsbalken der Gruppenmitgliedern neben deren Charakterfenster angezeigt.";
	PCB_SHOW_ICON_TEXT			= "Zaubericon anzeigen";
	PCB_SHOW_ICON_TIP			= "Wenn aktiviert, wird neben den Gruppen-Zauberleisten das Icon des jeweiligen Zaubers angezeigt.";
	PCB_PARTYMEMBERFRAME_PARENT_TEXT	= "Gruppen-Zauberleisten an Gruppenfenster befestigen";
	PCB_PARTYMEMBERFRAME_PARENT_TIP		= "Wenn aktiviert, wird als 'parent' der Gruppen-Zauberleisten das jeweilge Gruppenfenster festgelegt.";
	PCB_SCALE_TEXT				= "Skalierung";
	PCB_SCALE_TIP				= "Legt die Skalierung der Gruppen-Zauberleisten fest.";
	PCB_SCALE					= "Skalierung";
	PCB_DRAGGABLE_TEXT			= "Gruppen-Zauberleisten positionieren";
	PCB_DRAGGABLE_TIP			= "Wenn aktiviert, werden die Gruppen-Zauberleisten in den 'Verschieben-Modus' versetzt, wodurch jene sichtbar werden und verschoben werden k\195\182nnen. In diesem Modus werden keine Zauber angezeigt.";
	PCB_RESET_TEXT				= "Poition zur\195\188cksetzen";
	PCB_RESET_TIP				= "Setzt die Position der Gruppen-Zauberleisten rechts neben den Standard Gruppenfenstern zur\195\188ck.";
	PCB_SETTEXT					= "Festlegen";
	PCB_RESETTEXT					= "R\195\188cksetzen";
	PCB_HEADER_FRIENDLY_TEXT		= "Farbe bei Zauber gegen freundliche Ziele";
	PCB_HEADER_FRIENDLY_TIP			= "Legt die verwendete Farbe der Gruppen-Zauberleisten fest, wenn ein Zauber gegen ein freundliches Ziel gewirkt wird.";
	PCB_HEADER_HOSTILE_TEXT			= "Farbe bei Zauber gegen feindliche Ziele";
	PCB_HEADER_HOSTILE_TIP			= "Legt die verwendete Farbe der Gruppen-Zauberleisten fest, wenn ein Zauber gegen ein feindliches Ziel gewirkt wird.";
	PCB_CASTCOLOR_HOSTILE_SET		= "Farbe der Zauberleisten (Standard ist Orange):";
	PCB_CASTCOLOR_FRIENDLY_SET		= "Farbe der Zauberleisten (Standard ist Hellblau):";
	PCB_CASTCOLOR_SET_TIP			= "\195\132ndert die Farbe der Zauberleiste wenn ein allgemeiner Zauber gewirkt wird.";
	PCB_CASTCOLOR_RESET				= "Farbe zur\195\188cksetzen";
	PCB_CASTCOLOR_RESET_TIP			= "Setzt die Farbe der Zauberleisten bei allgemeinen Zaubern auf Orange zur\195\188ck.";
	PCB_CHANNELCOLOR_HOSTILE_SET	= "Farbe beim Kanalisieren (Standard ist Gr\195\188n):";
	PCB_CHANNELCOLOR_FRIENDLY_SET	= "Farbe beim Kanalisieren (Standard ist Gr\195\188n):";
	PCB_CHANNELCOLOR_SET_TIP		= "\195\132ndert die Farbe der Zauberleiste wenn ein kanalisierender Zauber gewirkt wird.";
	PCB_CHANNELCOLOR_RESET			= "Farbe zur\195\188cksetzen";
	PCB_CHANNELCOLOR_RESET_TIP		= "Setzt die Farbe der Zauberleisten bei kanalisierenden Zaubern auf Gr\195\188n zur\195\188ck.";
	PCB_SUCCESSCOLOR_HOSTILE_SET	= "Farbe bei Erfolg (Standard ist Gr\195\188n):";
	PCB_SUCCESSCOLOR_FRIENDLY_SET	= "Farbe bei Erfolg (Standard ist Gr\195\188n):";
	PCB_SUCCESSCOLOR_SET_TIP		= "\195\132ndert die Farbe der Zauberleiste wenn ein Zauber erfolgreich gewirkt wurde.";
	PCB_SUCCESSCOLOR_RESET			= "Farbe zur\195\188cksetzen";
	PCB_SUCCESSCOLOR_RESET_TIP		= "Setzt die Farbe der Zauberleisten bei erfolgreich gewirktem Zaubern auf Gr\195\188n zur\195\188ck.";
	PCB_FAILURECOLOR_HOSTILE_SET	= "Farbe bei Fehlschlag (Standard ist Rot):";
	PCB_FAILURECOLOR_FRIENDLY_SET	= "Farbe bei Fehlschlag (Standard ist Rot):";
	PCB_FAILURECOLOR_SET_TIP		= "\195\132ndert die Farbe der Zauberleiste wenn ein Zauber unterbrochen wird/nicht erfolgreich gewirkt wurde.";
	PCB_FAILURECOLOR_RESET			= "Farbe zur\195\188cksetzen";
	PCB_FAILURECOLOR_RESET_TIP		= "Setzt die Farbe der Zauberleisten wenn ein Zauber unterbrochen wird/nicht erfolgreich gewirkt wurde auf Rot zur\195\188ck.";

	PCB_COLOR_CHANGED			= "|c%s%s Farbe ge\195\164ndert.|r";
	PCB_COLOR_RESET				= "|c%s%s Farbe zur\195\188ckgesetzt.|r";

	PCB_SHOWNICONFEEDBACK_NEGATIVE		= "Zaubericon wird nicht angezeigt.";
	PCB_SHOWNICONFEEDBACK_POSITIVE		= "Zaubericon wird angezeigt.";

	PCB_PARTYMEMBERFRAME_PARENT_NEGATIVE	= "Zauberleisten am UIParent befestigt.";
	PCB_PARTYMEMBERFRAME_PARENT_POSITIVE	= "Zauberleisten an den Gruppenfenstern befestigt.";

	PCB_SCALE_NEGATIVE			= "Skalierung der Zauberleisten auf 1.0 zur\195\188ckgesetzt.";
	PCB_SCALE_POSITIVE			= "Skalierung der Zauberleisten auf %.1f festgelegt.";

	PCB_DRAGGABLE				= "Verschieben-Modus";

	PCB_DRAGGABLE_NEGATIVE			= "Zauberleisten sind jetzt im Zauber-Modus.";
	PCB_DRAGGABLE_POSITIVE			= "Zauberleisten sind jetzt im Verschieben-Modus.";

	PCB_LOCATIONS_RESET			= "Positionen der Zauberleisten wurden zur\195\188ckgesetzt.";


	-------
	-- Note: Color strings are format |c########Translatable text here|r
	-------
	PCB_HELP1				= "|c0055AA55Gruppen-Zauberleisten /chat Befehle.|r";
	PCB_HELP2				= "|c00995555Beachte, dss diese befehle nur funktionieren wenn das AddOn Khaos nicht aktiv ist. Ansonsten kannst du all diese Optionen in den Einstellungen von Khaos finden.|r";
	PCB_HELP3				= "|c00555555Enable|r - |c00AA5555Aktiviert die Gruppen-Zauberleisten.|r";
	PCB_HELP4				= "|c00555555Disable|r - |c00AA5555Ist ein Geheimnis.|r";
	PCB_HELP6				= "|c00555555Set Failure|r - |c00AA5555\195\150ffnet einen Dialog um die Farbe der Zauberleisten festzulegen, wenn ein Zauber fehlschl\195\164gt.|r";
	PCB_HELP7				= "|c00555555Set Success|r - |c00AA5555\195\150ffnet einen Dialog um die Farbe der Zauberleisten festzulegen, wenn ein Zauber erfolgreich war.|r";
	PCB_HELP8				= "|c00555555Set Channel|r - |c00AA5555\195\150ffnet einen Dialog um die Farbe der Zauberleisten festzulegen, w\195\164hrend ein Zauber kanalisiert wird.|r";
	PCB_HELP9				= "|c00555555Set Cast|r - |c00AA5555\195\150ffnet einen Dialog um die Farbe der Zauberleisten festzulegen, w\195\164hrend ein normaler Zauber gewirkt wird.|r";
	PCB_HELP10				= "|c00555555Reset Failure|r - |c00AA5555Setzt die Farbe (wenn ein Zauber fehlgeschlagen ist) der Zauberleiste zur\195\188ck.|r";
	PCB_HELP11				= "|c00555555Reset Success|r - |c00AA5555Setzt die Farbe (wenn ein Zauber erfolgreich war) der Zauberleiste zur\195\188ck.|r";
	PCB_HELP12				= "|c00555555Reset Channel|r - |c00AA5555Setzt die Farbe (w\195\164hrend ein Zauber kanalisiert wird) der Zauberleiste zur\195\188ck.|r";
	PCB_HELP13				= "|c00555555Reset Cast|r - |c00AA5555Setzt die Farbe (w\195\164hrend ein normaler Zauber gewirkt wird) der Zauberleiste zur\195\188ck.|r";
	PCB_HELP14				= "|c00555555Help|r - |c00AA5555Zeigt diese Hilfe an.|r";

	PCB_INVALID_COMMAND			= "Unbekannter Befehl der Gruppen-Zauberleisten. Benutzung \"/arcanebar help\" ein um Hilfe zu erhalten.";

	PCB_ENABLED				= "Gruppen-Zauberleisten aktiviert.";
	PCB_DISABLED				= "Gruppen-Zauberleisten deaktiviert.";

end