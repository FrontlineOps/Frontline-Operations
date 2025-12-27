/*
 * Request Menu Dialog
 * Author: Frontline Operations
 *
 * Description:
 * Dialog for requesting vehicles, supplies, and base containers.
 * Shows available resources, resistance, and aggression levels.
 *
 * Dependencies:
 * Requires UI/defines.hpp to be included before this file.
 */

// ============================================================================
// DIALOG LAYOUT CONSTANTS
// ============================================================================

// Dialog dimensions (full width, partial height)
#define REQUEST_DIALOG_X        (safeZoneX)
#define REQUEST_DIALOG_Y        (safeZoneY + 0.11 * safeZoneH)
#define REQUEST_DIALOG_W        (safeZoneW)
#define REQUEST_DIALOG_H        (0.74 * safeZoneH)

// Header bar
#define REQUEST_HEADER_H        (1.2 * GUI_GRID_H)
#define REQUEST_HEADER_Y        (REQUEST_DIALOG_Y)

// Content area
#define REQUEST_CONTENT_Y       (REQUEST_HEADER_Y + REQUEST_HEADER_H + 0.5 * GUI_GRID_H)

// Column layout (3 columns)
#define REQUEST_COL_GAP         (2.5 * GUI_GRID_W)
#define REQUEST_COL1_X          (safeZoneX + 0.175 * safeZoneW)
#define REQUEST_COL2_X          (safeZoneX + 0.425 * safeZoneW)
#define REQUEST_COL3_X          (safeZoneX + 0.675 * safeZoneW)
#define REQUEST_COL_W           (0.2 * safeZoneW)
#define REQUEST_COL3_W          (0.15 * safeZoneW)

// List and button dimensions
#define REQUEST_LIST_H          (0.4 * safeZoneH)
#define REQUEST_BTN_H           (1.2 * GUI_GRID_H)
#define REQUEST_LABEL_H         (0.9 * GUI_GRID_H)

// ============================================================================
// DIALOG-SPECIFIC LISTBOX CLASS
// ============================================================================

class FLO_RequestListbox: FLO_RscListBox
{
	colorScrollbar[] = FLO_COLOR_PRIMARY;
	colorSelectBackground[] = FLO_COLOR_SELECT_BG;
	colorSelectBackground2[] = FLO_COLOR_SELECT_BG;
	rowHeight = 1.2 * GUI_GRID_H;
};

// ============================================================================
// REQUEST MENU DIALOG
// ============================================================================

class FLO_RequestMenuDialog
{
	idd = FLO_IDD_REQUEST;
	movingEnable = true;
	enableSimulation = true;

	onLoad = "uiNamespace setVariable ['FLO_RequestDialog', _this select 0]";
	onUnload = "uiNamespace setVariable ['FLO_RequestDialog', displayNull]";

	class Controls
	{
		// ====================================================================
		// BACKGROUND LAYER
		// ====================================================================

		class Background: FLO_RscBackground
		{
			idc = FLO_IDC_NONE;
			x = REQUEST_DIALOG_X;
			y = REQUEST_CONTENT_Y;
			w = REQUEST_DIALOG_W;
			h = REQUEST_DIALOG_H - REQUEST_HEADER_H;
		};

		// ====================================================================
		// HEADER BAR WITH RESOURCE INFO
		// ====================================================================

		class HeaderBar: FLO_RscTitleBar
		{
			idc = FLO_IDC_NONE;
			text = "";
			x = REQUEST_DIALOG_X;
			y = REQUEST_HEADER_Y;
			w = REQUEST_DIALOG_W - FLO_UI_CLOSE_BTN_W;
			h = REQUEST_HEADER_H;
		};

		class TitleText: FLO_RscText_Title
		{
			idc = FLO_IDC_REQUEST_TITLE;
			text = "REQUEST MENU";
			x = REQUEST_DIALOG_X + 0.5 * GUI_GRID_W;
			y = REQUEST_HEADER_Y;
			w = 8 * GUI_GRID_W;
			h = REQUEST_HEADER_H;
		};

		class ResourcesText: FLO_RscText
		{
			idc = FLO_IDC_REQUEST_RESOURCES;
			text = "Resources: ";
			x = REQUEST_DIALOG_X + 10 * GUI_GRID_W;
			y = REQUEST_HEADER_Y;
			w = 10 * GUI_GRID_W;
			h = REQUEST_HEADER_H;
			colorBackground[] = FLO_COLOR_SURFACE;
		};

		class ResistanceText: FLO_RscText
		{
			idc = FLO_IDC_REQUEST_RESISTANCE;
			text = "Resistance: ";
			x = REQUEST_DIALOG_X + 20 * GUI_GRID_W;
			y = REQUEST_HEADER_Y;
			w = 10 * GUI_GRID_W;
			h = REQUEST_HEADER_H;
			colorBackground[] = FLO_COLOR_SURFACE;
		};

		class AggressionText: FLO_RscText
		{
			idc = FLO_IDC_REQUEST_AGGRESSION;
			text = "Aggression: ";
			x = REQUEST_DIALOG_X + 30 * GUI_GRID_W;
			y = REQUEST_HEADER_Y;
			w = 10 * GUI_GRID_W;
			h = REQUEST_HEADER_H;
			colorBackground[] = FLO_COLOR_SURFACE;
		};

		class CloseButton: FLO_RscButton_Close
		{
			idc = FLO_IDC_REQUEST_BTN_CLOSE;
			x = REQUEST_DIALOG_X + REQUEST_DIALOG_W - FLO_UI_CLOSE_BTN_W;
			y = REQUEST_HEADER_Y;
			h = REQUEST_HEADER_H;
			action = "closeDialog 0";
		};

		// ====================================================================
		// COLUMN 1: GROUND VEHICLES
		// ====================================================================

		class LabelGroundVehicles: FLO_RscText_Label
		{
			idc = FLO_IDC_REQUEST_LABEL_GROUND;
			text = "GROUND VEHICLES";
			x = REQUEST_COL1_X;
			y = REQUEST_CONTENT_Y;
			w = REQUEST_COL_W;
			h = REQUEST_LABEL_H;
			colorBackground[] = FLO_COLOR_HEADER;
			style = ST_CENTER;
		};

		class ListGroundVehicles: FLO_RequestListbox
		{
			idc = FLO_IDC_REQUEST_LIST_GROUND;
			x = REQUEST_COL1_X;
			y = REQUEST_CONTENT_Y + REQUEST_LABEL_H;
			w = REQUEST_COL_W;
			h = REQUEST_LIST_H;
		};

		class BtnRequestGround: FLO_RscButton
		{
			idc = FLO_IDC_REQUEST_BTN_GROUND;
			text = "Request";
			x = REQUEST_COL1_X;
			y = REQUEST_CONTENT_Y + REQUEST_LABEL_H + REQUEST_LIST_H + 0.3 * GUI_GRID_H;
			w = REQUEST_COL_W;
			h = REQUEST_BTN_H;
			action = "[2101] call VEH_REQUEST";
		};

		// ====================================================================
		// COLUMN 2: AIR / SEA VEHICLES
		// ====================================================================

		class LabelAirSeaVehicles: FLO_RscText_Label
		{
			idc = FLO_IDC_REQUEST_LABEL_AIR;
			text = "AIR | SEA VEHICLES";
			x = REQUEST_COL2_X;
			y = REQUEST_CONTENT_Y;
			w = REQUEST_COL_W;
			h = REQUEST_LABEL_H;
			colorBackground[] = FLO_COLOR_HEADER;
			style = ST_CENTER;
		};

		class ListAirSeaVehicles: FLO_RequestListbox
		{
			idc = FLO_IDC_REQUEST_LIST_AIR;
			x = REQUEST_COL2_X;
			y = REQUEST_CONTENT_Y + REQUEST_LABEL_H;
			w = REQUEST_COL_W;
			h = REQUEST_LIST_H;
		};

		class BtnRequestAirSea: FLO_RscButton
		{
			idc = FLO_IDC_REQUEST_BTN_AIR;
			text = "Request";
			x = REQUEST_COL2_X;
			y = REQUEST_CONTENT_Y + REQUEST_LABEL_H + REQUEST_LIST_H + 0.3 * GUI_GRID_H;
			w = REQUEST_COL_W;
			h = REQUEST_BTN_H;
			action = "[2102] call VEH_REQUEST";
		};

		// ====================================================================
		// COLUMN 3: SUPPLIES
		// ====================================================================

		class LabelSupplies: FLO_RscText_Label
		{
			idc = FLO_IDC_REQUEST_LABEL_SUPPLIES;
			text = "SUPPLIES";
			x = REQUEST_COL3_X;
			y = REQUEST_CONTENT_Y;
			w = REQUEST_COL3_W;
			h = REQUEST_LABEL_H;
			colorBackground[] = FLO_COLOR_HEADER;
			style = ST_CENTER;
		};

		class ListSupplies: FLO_RequestListbox
		{
			idc = FLO_IDC_REQUEST_LIST_SUPPLIES;
			x = REQUEST_COL3_X;
			y = REQUEST_CONTENT_Y + REQUEST_LABEL_H;
			w = REQUEST_COL3_W;
			h = REQUEST_LIST_H;
		};

		class BtnRequestSupplies: FLO_RscButton
		{
			idc = FLO_IDC_REQUEST_BTN_SUPPLIES;
			text = "Request";
			x = REQUEST_COL3_X;
			y = REQUEST_CONTENT_Y + REQUEST_LABEL_H + REQUEST_LIST_H + 0.3 * GUI_GRID_H;
			w = REQUEST_COL3_W;
			h = REQUEST_BTN_H;
			action = "[2103] call VEH_REQUEST";
		};

		// ====================================================================
		// CONTAINER BUTTONS (Bottom Row)
		// ====================================================================

		class BtnNewFOB: FLO_RscButton_Primary
		{
			idc = FLO_IDC_REQUEST_BTN_FOB;
			text = "New FOB Container [$2000]";
			x = safeZoneX + 0.3 * safeZoneW;
			y = REQUEST_CONTENT_Y + REQUEST_LABEL_H + REQUEST_LIST_H + REQUEST_BTN_H + 1.5 * GUI_GRID_H;
			w = 0.2 * safeZoneW;
			h = REQUEST_BTN_H;
			action = "execVM 'Scripts\PObjectives\FOBHQ.sqf'";
			tooltip = "Deploy a new Forward Operating Base container";
		};

		class BtnNewOP: FLO_RscButton
		{
			idc = FLO_IDC_REQUEST_BTN_OP;
			text = "New OP Container [$100]";
			x = safeZoneX + 0.5 * safeZoneW;
			y = REQUEST_CONTENT_Y + REQUEST_LABEL_H + REQUEST_LIST_H + REQUEST_BTN_H + 1.5 * GUI_GRID_H;
			w = 0.2 * safeZoneW;
			h = REQUEST_BTN_H;
			action = "execVM 'Scripts\PObjectives\OPHQ.sqf'";
			tooltip = "Deploy a new Observation Post container";
		};
	};
};

// ============================================================================
// LEGACY ALIAS (for backward compatibility)
// ============================================================================

class supr_RequestsMenu: FLO_RequestMenuDialog {};