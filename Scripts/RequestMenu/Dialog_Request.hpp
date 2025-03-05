class supr_RequestsMenu
{
	idd = 1599;
	movingenable = true;
	onLoad = "uiNamespace setVariable ['FLO_RequestDialog', _this select 0]";
	
	// Modern responsive UI base classes
	class RscTextsupr_Request: RscText
	{
		colorText[] = {1,1,1,0.9};
		shadow = 0;
		font = "PuristaMedium";
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
	};
	
	class RscButtonsupr_Request: RscButton
	{
		colorText[] = {1,1,1,1};
		colorBackground[] = {0.1,0.1,0.1,0.8};
		colorBackgroundActive[] = {0.5,0.1,0.1,1};
		colorBackgroundDisabled[] = {0.1,0.1,0.1,0.3};
		colorFocused[] = {0.5,0.1,0.1,0.8};
		colorShadow[] = {0,0,0,0};
		colorBorder[] = {0,0,0,0};
		shadow = 0;
		font = "PuristaMedium";
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
		offsetX = 0;
		offsetY = 0;
		offsetPressedX = 0;
		offsetPressedY = 0;
		borderSize = 0;
	};
	
	class RscListboxsupr_Request: RscListbox
	{
		colorText[] = {0.95,0.95,0.95,1};
		colorBackground[] = {0.1,0.1,0.1,0.8};
		colorScrollbar[] = {0.5,0.1,0.1,1};
		colorSelect[] = {1,1,1,1};
		colorSelect2[] = {1,1,1,1};
		colorSelectBackground[] = {0.5,0.1,0.1,0.8};
		colorSelectBackground2[] = {0.5,0.1,0.1,0.8};
		colorShadow[] = {0,0,0,0.5};
		colorPictureSelected[] = {1,1,1,1};
		colorPictureRightSelected[] = {1,1,1,1};
		font = "PuristaMedium";
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
		rowHeight = 0.04 * safezoneH;
		soundSelect[] = {"\A3\ui_f\data\sound\RscListbox\soundSelect",0.09,1};
	};
	
	class RscTextResourceBar: RscText
	{
		colorText[] = {1,1,1,1};
		colorBackground[] = {0.1,0.1,0.1,0.8};
		shadow = 0;
		font = "PuristaMedium";
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
	};
	
class controls
{
	// Black background panel
	class supr_requestbg: RscText
	{
		idc = -1;
		x = safezoneX;
		y = safezoneY + 0.15 * safezoneH;
		w = safezoneW;
		h = 0.7 * safezoneH;
		colorBackground[] = {0.1,0.1,0.1,0.85};
	};

	// Title bar with modern look
	class supr_requesttitlebar: RscTextsupr_Request
	{
		idc = 1004;
		x = safezoneX;
		y = safezoneY + 0.15 * safezoneH - 0.04 * safezoneH;
		w = safezoneW;
		h = 0.04 * safezoneH;
		colorBackground[] = {0.2,0.2,0.2,1};
		colorText[] = {1,1,1,1};
		font = "PuristaBold";
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
	};

	class supr_requesttitlebarText: RscTextsupr_Request
	{
		idc = 1004;
		text = "Request Menu"; 
		x = safezoneX + 0.01 * safezoneW;
		y = safezoneY + 0.15 * safezoneH - 0.04 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.04 * safezoneH;
		colorBackground[] = {0,0,0,0};
		colorText[] = {1,1,1,1};
		font = "PuristaBold";
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
	};

	class supr_requestclose: RscButtonsupr_Request
	{
		idc = 1600;
		text = "X";  // Changed from Unicode to standard X
		x = safezoneX + safezoneW - 0.04 * safezoneW;
		y = safezoneY + 0.15 * safezoneH - 0.04 * safezoneH;
		w = 0.04 * safezoneW;
		h = 0.04 * safezoneH;
		colorBackground[] = {0.8,0.2,0.2,1};
		colorBackgroundActive[] = {1,0.2,0.2,1};
		action = "closeDialog 0";
		font = "PuristaBold";
		sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.2)"; // Made slightly larger for better visibility
	};

	// Resource info bars
	class supr_requestmanpowertext: RscTextResourceBar
	{
		idc = 1000;
		text = "Resources: "; 
		x = safezoneX + 0.2 * safezoneW;
		y = safezoneY + 0.15 * safezoneH - 0.04 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.04 * safezoneH;
		colorBackground[] = {0.1,0.1,0.1,0.7};
	};

	class supr_requestsupplytext: RscTextResourceBar
	{
		idc = 1001;
		text = "Resistance: "; 
		x = safezoneX + 0.4 * safezoneW;
		y = safezoneY + 0.15 * safezoneH - 0.04 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.04 * safezoneH;
		colorBackground[] = {0.1,0.1,0.1,0.7};
	};

	class supr_requestinteltext: RscTextResourceBar
	{
		idc = 1002;
		text = "Aggression: "; 
		x = safezoneX + 0.6 * safezoneW;
		y = safezoneY + 0.15 * safezoneH - 0.04 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.04 * safezoneH;
		colorBackground[] = {0.1,0.1,0.1,0.7};
	};

	/* GROUND */
	class supr_requestsquadtext: RscTextsupr_Request
	{
		idc = 1005;
		text = "GROUND VEHICLES"; 
		x = safezoneX + 0.175 * safezoneW;
		y = safezoneY + 0.18 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.03 * safezoneH;
		colorBackground[] = {0.2,0.2,0.2,0.5};
		font = "PuristaBold";
	};
	
	class supr_requestsquadsbox: RscListboxsupr_Request
	{
		idc = 2101;
		x = safezoneX + 0.175 * safezoneW;
		y = safezoneY + 0.21 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.4 * safezoneH;
	};
	
	class supr_requestsquadbutton: RscButtonsupr_Request
	{
		idc = 1602;
		text = "Request"; 
		x = safezoneX + 0.175 * safezoneW;
		y = safezoneY + 0.62 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.04 * safezoneH;
		action = "[2101] call VEH_REQUEST";
	};

	/* AIR\SEA */
	class supr_requestvehiclestext: RscTextsupr_Request
	{
		idc = 1006;
		text = "AIR | SEA VEHICLES"; 
		x = safezoneX + 0.425 * safezoneW;
		y = safezoneY + 0.18 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.03 * safezoneH;
		colorBackground[] = {0.2,0.2,0.2,0.5};
		font = "PuristaBold";
	};
	
	class supr_requestvehiclesbox: RscListboxsupr_Request
	{
		idc = 2102;
		x = safezoneX + 0.425 * safezoneW;
		y = safezoneY + 0.21 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.4 * safezoneH;
	};
	
	class supr_requestvehiclebutton: RscButtonsupr_Request
	{
		idc = 1603;
		text = "Request"; 
		x = safezoneX + 0.425 * safezoneW;
		y = safezoneY + 0.62 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.04 * safezoneH;
		action = "[2102] call VEH_REQUEST";
	};
	
	/* SUPPLIES */
	class supr_requestsupportstext: RscTextsupr_Request
	{
		idc = 1007;
		text = "SUPPLIES"; 
		x = safezoneX + 0.675 * safezoneW;
		y = safezoneY + 0.18 * safezoneH;
		w = 0.15 * safezoneW;
		h = 0.03 * safezoneH;
		colorBackground[] = {0.2,0.2,0.2,0.5};
		font = "PuristaBold";
	};

	class supr_requestsupportsbox: RscListboxsupr_Request
	{
		idc = 2103;
		x = safezoneX + 0.675 * safezoneW;
		y = safezoneY + 0.21 * safezoneH;
		w = 0.15 * safezoneW;
		h = 0.4 * safezoneH;
	};

	class supr_unlocksupportsbutton: RscButtonsupr_Request
	{
		idc = 1604;
		text = "Request"; 
		x = safezoneX + 0.675 * safezoneW;
		y = safezoneY + 0.62 * safezoneH;
		w = 0.15 * safezoneW;
		h = 0.04 * safezoneH;
		action = "[2103] call VEH_REQUEST";
	};
	
	/* CONTAINER BUTTONS - CENTERED */
	class supr_requestFOBbutton: RscButtonsupr_Request
	{
		idc = 1888;
		text = "New <FOB> Container <2000$>"; 
		x = safezoneX + 0.3 * safezoneW;
		y = safezoneY + 0.68 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.04 * safezoneH;
		colorBackground[] = {0.3,0.3,0.3,1};
		action = "execVM 'Scripts\FOBHQ.sqf'";
	};
	
	class supr_requestBRIBEbutton: RscButtonsupr_Request
	{
		idc = 1999;
		text = "New <OP> Container <100$>"; 
		x = safezoneX + 0.5 * safezoneW;
		y = safezoneY + 0.68 * safezoneH;
		w = 0.2 * safezoneW;
		h = 0.04 * safezoneH;
		colorBackground[] = {0.3,0.3,0.3,1};
		action = "execVM 'Scripts\OPHQ.sqf'";
	};
};
};