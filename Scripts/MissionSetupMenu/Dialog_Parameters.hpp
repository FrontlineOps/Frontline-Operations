class parameters_dialog
{
	idd = 998;
	movingenable = true;
	onLoad = "escKeyEH = (_this select 0) displayAddEventHandler [""KeyDown"", ""if (((_this select 1) == 1)) then {true} else {false};""];  [] execVM ""Scripts\MissionSetupMenu\Dialog_Parameters_Init.sqf"";";

	// Modern UI base classes
	class suprParameterCombo: RscCombo
	{
		w = 20 * GUI_GRID_W;
		h = 1.2 * GUI_GRID_H;
		colorText[] = {1,1,1,1};
		wholeHeight = 14 * GUI_GRID_H;
		font = "PuristaMedium";
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.9)";
		colorBackground[] = {0.1,0.1,0.1,0.85};
		colorSelectBackground[] = {0.5,0.1,0.1,0.85};
		colorScrollbar[] = {0.5,0.1,0.1,1};
		soundSelect[] = {"\A3\ui_f\data\sound\RscCombo\soundSelect",0.1,1};
		soundExpand[] = {"\A3\ui_f\data\sound\RscCombo\soundExpand",0.1,1};
		soundCollapse[] = {"\A3\ui_f\data\sound\RscCombo\soundCollapse",0.1,1};
	};
	
class controls
{
	// Modern semi-transparent background panel
	class BackgroundPanel: RscText
	{
		idc = -1;
		x = safeZoneX + safeZoneW/2 - 25 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 7.5 * GUI_GRID_H;
		w = 50 * GUI_GRID_W;
		h = 15 * GUI_GRID_H;
		colorBackground[] = {0,0,0,0.85};
	};
	
	// Top header bar
	class HeaderBar: RscText
	{
		idc = -1;
		x = safeZoneX + safeZoneW/2 - 25 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 8.5 * GUI_GRID_H;
		w = 50 * GUI_GRID_W;
		h = 1 * GUI_GRID_H;
		colorText[] = {1,1,1,1};
		colorBackground[] = {0.2,0.2,0.2,1};
		sizeEx = 0.8 * GUI_GRID_H;
		shadow = 1;
		colorShadow[] = {0,0,0,0.5};
		font = "PuristaBold";
		align = "center";
		text = "MISSION PARAMETERS";
	};

	// Title text
	class RscText_1000: RscText
	{
		idc = 1000;
		text = "MISSION SETTINGS"; 
		x = safeZoneX + safeZoneW/2 - 24 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 7 * GUI_GRID_H;
		w = 12 * GUI_GRID_W;
		h = 1 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		colorBackground[] = {0,0,0,0};	
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.1)";
		shadow = 1;
		colorShadow[] = {0,0,0,0.5};
		font = "PuristaBold";
	};

	/* PARAMETERS SECTION */
	
	// AutoSave Switch Frame
	class RscFrame_1800: RscText
	{
		idc = 1800;
		text = "AutoSave Switch"; 
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
		tooltip = "";
	};

	// AutoSave Interval Frame
	class RscFrame_1801: RscText
	{
		idc = 1801;
		text = "AutoSave Interval"; 
		x = safeZoneX + safeZoneW/2 - 6 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
	};

	// Mission Save Management Frame
	class RscFrame_1802: RscText
	{
		idc = 1802;
		text = "Mission Save Management"; 
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
	};
	
	// Restricted Arsenal Frame
	class RscFrame_1803: RscText
	{
		idc = 1803;
		text = "Restricted Arsenal"; 
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 2 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
		tooltip = "";
	};
	
	// AutoSave Switch Dropdown
	class AutoSave_Switch_Combo: suprParameterCombo
	{
		idc = 1970;
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 4 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// AutoSave Interval Dropdown
	class AutoSave_Interval_Combo: suprParameterCombo
	{
		idc = 1971;
		x = safeZoneX + safeZoneW/2 - 6 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 4 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// Mission Save Management Dropdown
	class Mission_Save_Combo: suprParameterCombo
	{
		idc = 1972;
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 4 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// Restricted Arsenal Dropdown
	class Restricted_Arsenal_Combo: suprParameterCombo
	{
		idc = 1973;
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 0 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// APPLY PARAMETERS Button
	class RscButton_1600: RscButton
	{
		idc = 1600;
		text = "APPLY PARAMETERS"; 
		x = safeZoneX + safeZoneW/2 - 7 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 + 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 1.5 * GUI_GRID_H;
		colorText[] = {1,1,1,1};
		colorBackground[] = {0.2,0.2,0.2,1};
		colorBackgroundActive[] = {0.5,0.1,0.1,1};
		colorFocused[] = {0.5,0.1,0.1,0.8};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
		action = "_nul = [] execvm ""Scripts\MissionSetupMenu\Dialog_Parameters_Done.sqf""";
		tooltip = "";
		font = "PuristaBold";
	};
	
	// SWITCH TO FACTIONS Button
	class RscButton_1601: RscButton
	{
		idc = 1601;
		text = "SWITCH TO FACTIONS"; 
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 + 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 1.5 * GUI_GRID_H;
		colorText[] = {1,1,1,1};
		colorBackground[] = {0.2,0.2,0.2,1};
		colorBackgroundActive[] = {0.5,0.1,0.1,1};
		colorFocused[] = {0.5,0.1,0.1,0.8};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
		action = "closeDialog 0; createDialog ""factionselect_dialog2"";";
		tooltip = "";
		font = "PuristaBold";
	};
};
}; 