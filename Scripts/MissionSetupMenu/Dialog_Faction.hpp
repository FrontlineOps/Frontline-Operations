class factionselect_dialog2
{
	idd = 999;
	movingenable = true;
	onLoad = "uiNamespace setVariable ['FLO_FactionDialog', _this select 0]; private _eh = (_this select 0) displayAddEventHandler ['KeyDown', { params ['_d','_k']; if (_k isEqualTo 1) then { closeDialog 0; true } else { false } }]; (_this select 0) setVariable ['FLO_FactionDialog_EH', _eh];";
	onUnload = "params ['_d']; private _eh = _d getVariable ['FLO_FactionDialog_EH', -1]; if (_eh >= 0) then { _d displayRemoveEventHandler ['KeyDown', _eh]; }; uiNamespace setVariable ['FLO_FactionDialog', displayNull];";

	// Modern UI base classes
	class suprChooseFactionCombo: RscCombo
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
		text = "MISSION SETUP";
	};

	// Title text
	class RscText_1000: RscText
	{
		idc = 1000;
		text = "CHOOSE FACTIONS"; 
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

	/* FACTION SELECTION SECTION */
	
	// Player Faction Frame
	class RscFrame_1800: RscText
	{
		idc = 1800;
		text = "Player Faction"; 
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
		tooltip = "";
	};

	// Enemy Faction Frame
	class RscFrame_1801: RscText
	{
		idc = 1801;
		text = "Enemy Faction"; 
		x = safeZoneX + safeZoneW/2 - 6 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
	};

	// Civilian Faction Frame
	class RscFrame_1802: RscText
	{
		idc = 1802;
		text = "Civilian Faction"; 
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
	};
	
	// Starting Zones Frame
	class RscFrame_1803: RscText
	{
		idc = 1803;
		text = "Starting Zones"; 
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 2 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
		tooltip = "";
	};
	
	// Starting Resources Frame
	class RscFrame_1804: RscText
	{
		idc = 1804;
		text = "Starting Resources"; 
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 2 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
		tooltip = "";
	};
	
	// Starting Difficulty Frame
	class RscFrame_1805: RscText
	{
		idc = 1805;
		text = "Starting Difficulty"; 
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 + 2 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
		tooltip = "";
	};

	// Starting Reputation Frame
	class RscFrame_1806: RscText
	{
		idc = 1806;
		text = "Starting Reputation"; 
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 + 2 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 2.5 * GUI_GRID_H;
		colorText[] = {0.5,0.1,0.1,1};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85)";
		font = "PuristaMedium";
		tooltip = "";
	};
	
	// Player Faction Dropdown
	class faction_selection_listbox: suprChooseFactionCombo
	{
		idc = 1955;
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 4 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// Enemy Faction Dropdown
	class faction_selection_enemy_listbox: suprChooseFactionCombo
	{
		idc = 1956;
		x = safeZoneX + safeZoneW/2 - 6 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 4 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// Civilian Faction Dropdown
	class faction_selection_civilian_listbox: suprChooseFactionCombo
	{
		idc = 1957;
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 4 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// Enemy Presence Dropdown
	class faction_selection_presence_listbox: suprChooseFactionCombo
	{
		idc = 1958;
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 0 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// Starting Resources Dropdown
	class faction_selection_Resources_listbox: suprChooseFactionCombo
	{
		idc = 1959;
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 - 0 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// Reputation Dropdown
	class Reputation_selection_listbox: suprChooseFactionCombo
	{
		idc = 1960;
		x = safeZoneX + safeZoneW/2 - 23 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 + 4 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// Difficulty Dropdown
	class Difficulty_selection_listbox: suprChooseFactionCombo
	{
		idc = 1961;
		x = safeZoneX + safeZoneW/2 + 11 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 + 4 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
	};
	
	// START MISSION Button
	class RscButton_1600: RscButton
	{
		idc = 1600;
		text = "START MISSION"; 
		x = safeZoneX + safeZoneW/2 - 7 * GUI_GRID_W;
		y = safeZoneY + safeZoneH/2 + 6 * GUI_GRID_H;
		w = 14 * GUI_GRID_W;
		h = 1.5 * GUI_GRID_H;
		colorText[] = {1,1,1,1};
		colorBackground[] = {0.2,0.2,0.2,1};
		colorBackgroundActive[] = {0.5,0.1,0.1,1};
		colorFocused[] = {0.5,0.1,0.1,0.8};
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
		action = "with uiNamespace do { private _d = FLO_FactionDialog; if (!isNull _d) then { (_d displayCtrl 1600) ctrlEnable false; }; }; _nul = [true] execVM 'Scripts\MissionSetupMenu\Dialog_Faction_Done.sqf';";
		tooltip = "";
		font = "PuristaBold";
	};
};
};