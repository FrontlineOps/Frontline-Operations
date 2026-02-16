/*
 * Faction Selection Dialog
 * Author: Frontline Operations
 *
 * Description:
 * Mission setup dialog for selecting player, enemy, and civilian factions,
 * along with starting parameters like resources, difficulty, and reputation.
 *
 * Dependencies:
 * Requires UI/defines.hpp to be included before this file.
 */

// ============================================================================
// DIALOG LAYOUT CONSTANTS
// ============================================================================

// Dialog dimensions
#define FACTION_DIALOG_W        (50 * GUI_GRID_W)
#define FACTION_DIALOG_H        (16 * GUI_GRID_H)
#define FACTION_DIALOG_X        (safeZoneX + safeZoneW/2 - FACTION_DIALOG_W/2)
#define FACTION_DIALOG_Y        (safeZoneY + safeZoneH/2 - FACTION_DIALOG_H/2)

// Column layout (3 columns)
#define FACTION_COL_W           (14 * GUI_GRID_W)
#define FACTION_COL_GAP         (2 * GUI_GRID_W)
#define FACTION_COL1_X          (FACTION_DIALOG_X + 2 * GUI_GRID_W)
#define FACTION_COL2_X          (FACTION_COL1_X + FACTION_COL_W + FACTION_COL_GAP)
#define FACTION_COL3_X          (FACTION_COL2_X + FACTION_COL_W + FACTION_COL_GAP)

// Row layout
#define FACTION_HEADER_H        (1.2 * GUI_GRID_H)
#define FACTION_ROW_H           (1.2 * GUI_GRID_H)
#define FACTION_LABEL_H         (0.8 * GUI_GRID_H)
#define FACTION_ROW_GAP         (0.5 * GUI_GRID_H)

// Content area
#define FACTION_CONTENT_Y       (FACTION_DIALOG_Y + FACTION_HEADER_H + 1 * GUI_GRID_H)

// ============================================================================
// DIALOG-SPECIFIC COMBO CLASS
// ============================================================================

class FLO_FactionCombo: FLO_RscCombo
{
	w = FACTION_COL_W;
	h = FACTION_ROW_H;
	colorSelectBackground[] = FLO_COLOR_PRIMARY;
	wholeHeight = 12 * GUI_GRID_H;
};

// ============================================================================
// FACTION SELECTION DIALOG
// ============================================================================

class FLO_FactionSelectDialog
{
	idd = FLO_IDD_FACTION;
	movingEnable = true;
	enableSimulation = true;

	onLoad = "_this call FLO_fnc_factionDialogOnLoad";
	onUnload = "_this call FLO_fnc_factionDialogOnUnload";

	class Controls
	{
		// ====================================================================
		// BACKGROUND LAYER
		// ====================================================================

		class Background: FLO_RscBackground
		{
			idc = FLO_IDC_NONE;
			x = FACTION_DIALOG_X;
			y = FACTION_DIALOG_Y + FACTION_HEADER_H;
			w = FACTION_DIALOG_W;
			h = FACTION_DIALOG_H - FACTION_HEADER_H;
		};

		// ====================================================================
		// HEADER BAR
		// ====================================================================

		class HeaderBar: FLO_RscTitleBar
		{
			idc = FLO_IDC_NONE;
			text = "MISSION SETUP";
			x = FACTION_DIALOG_X;
			y = FACTION_DIALOG_Y;
			w = FACTION_DIALOG_W - FLO_UI_CLOSE_BTN_W;
			h = FACTION_HEADER_H;
		};

		class CloseButton: FLO_RscButton_Close
		{
			idc = FLO_IDC_FACTION_BTN_CLOSE;
			x = FACTION_DIALOG_X + FACTION_DIALOG_W - FLO_UI_CLOSE_BTN_W;
			y = FACTION_DIALOG_Y;
			h = FACTION_HEADER_H;
			action = "closeDialog 0";
		};

		// ====================================================================
		// SECTION TITLE
		// ====================================================================

		class SectionTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "FACTION SELECTION";
			x = FACTION_COL1_X;
			y = FACTION_CONTENT_Y;
			w = FACTION_DIALOG_W - 4 * GUI_GRID_W;
			h = FACTION_LABEL_H;
			colorText[] = FLO_COLOR_PRIMARY;
		};

		class SectionTitleCommander: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "COMMANDER & CAMPAIGN SETTINGS";
			x = FACTION_COL1_X;
			y = FACTION_CONTENT_Y + 3.6 * GUI_GRID_H;
			w = FACTION_DIALOG_W - 4 * GUI_GRID_W;
			h = FACTION_LABEL_H;
			colorText[] = FLO_COLOR_PRIMARY;
		};

		// ====================================================================
		// ROW 1: FACTION SELECTION (Player, Enemy, Civilian)
		// ====================================================================

		// Player Faction
		class LabelPlayerFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Player Faction";
			x = FACTION_COL1_X;
			y = FACTION_CONTENT_Y + 1.0 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboPlayerFaction: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_PLAYER;
			x = FACTION_COL1_X;
			y = FACTION_CONTENT_Y + 1.8 * GUI_GRID_H;
			tooltip = "Select the player faction";
		};

		// Enemy Faction
		class LabelEnemyFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Enemy Faction";
			x = FACTION_COL2_X;
			y = FACTION_CONTENT_Y + 1.0 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboEnemyFaction: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_ENEMY;
			x = FACTION_COL2_X;
			y = FACTION_CONTENT_Y + 1.8 * GUI_GRID_H;
			tooltip = "Select the enemy faction";
		};

		// Civilian Faction
		class LabelCivilianFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Civilian Faction";
			x = FACTION_COL3_X;
			y = FACTION_CONTENT_Y + 1.0 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboCivilianFaction: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_CIVILIAN;
			x = FACTION_COL3_X;
			y = FACTION_CONTENT_Y + 1.8 * GUI_GRID_H;
			tooltip = "Select the civilian faction";
		};

		// ====================================================================
		// ROW 2: COMMANDER SETTINGS (Attack Ops, Defense Ops, Aggression)
		// ====================================================================

		// AI Commander Attack Operations
		class LabelStartingZones: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "AI Commander Attack Ops";
			x = FACTION_COL1_X;
			y = FACTION_CONTENT_Y + 4.5 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboStartingZones: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_PRESENCE;
			x = FACTION_COL1_X;
			y = FACTION_CONTENT_Y + 5.3 * GUI_GRID_H;
			tooltip = "Set how many concurrent offensive plans each AI commander can run";
		};

		class LabelGTNDefenseOps: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "AI Commander Defense Ops";
			x = FACTION_COL2_X;
			y = FACTION_CONTENT_Y + 4.5 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboGTNDefenseOps: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_GTN_DEFENSE;
			x = FACTION_COL2_X;
			y = FACTION_CONTENT_Y + 5.3 * GUI_GRID_H;
			tooltip = "Set how many concurrent defensive plans each AI commander can run";
		};

		// AI Commander Aggression
		class LabelStartingDifficulty: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "AI Commander Aggression";
			x = FACTION_COL3_X;
			y = FACTION_CONTENT_Y + 4.5 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboStartingDifficulty: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_DIFFICULTY;
			x = FACTION_COL3_X;
			y = FACTION_CONTENT_Y + 5.3 * GUI_GRID_H;
			tooltip = "Set commander willingness to launch attacks with partial force";
		};

		// ====================================================================
		// ROW 3: CAMPAIGN SETTINGS (Tempo, Resources, Civilian Standing)
		// ====================================================================

		class LabelGTNTempo: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "AI Commander Tempo";
			x = FACTION_COL1_X;
			y = FACTION_CONTENT_Y + 6.9 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboGTNTempo: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_GTN_TEMPO;
			x = FACTION_COL1_X;
			y = FACTION_CONTENT_Y + 7.7 * GUI_GRID_H;
			tooltip = "Set how often commanders run decision cycles (mission speed)";
		};

		// Starting Resources
		class LabelStartingResources: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Starting Resources";
			x = FACTION_COL2_X;
			y = FACTION_CONTENT_Y + 6.9 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboStartingResources: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_RESOURCES;
			x = FACTION_COL2_X;
			y = FACTION_CONTENT_Y + 7.7 * GUI_GRID_H;
			tooltip = "Select starting resource level";
		};

		class LabelReputation: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Civilian Standing";
			x = FACTION_COL3_X;
			y = FACTION_CONTENT_Y + 6.9 * GUI_GRID_H;
			w = FACTION_COL_W;
			h = FACTION_LABEL_H;
		};

		class ComboReputation: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_REPUTATION;
			x = FACTION_COL3_X;
			y = FACTION_CONTENT_Y + 7.7 * GUI_GRID_H;
			tooltip = "Set how friendly civilians are to players at mission start";
		};

		// ====================================================================
		// ACTION BUTTONS
		// ====================================================================

		class StartButton: FLO_RscButton_Primary
		{
			idc = FLO_IDC_FACTION_BTN_START;
			text = "START MISSION";
			x = FACTION_DIALOG_X + FACTION_DIALOG_W/2 - 8 * GUI_GRID_W;
			y = FACTION_DIALOG_Y + FACTION_DIALOG_H - 2 * GUI_GRID_H;
			w = 16 * GUI_GRID_W;
			h = 1.5 * GUI_GRID_H;
			action = "[] call FLO_fnc_factionDialogStart";
			tooltip = "Start the mission with selected settings";
		};
	};
};

// ============================================================================
// LEGACY ALIAS (for backward compatibility)
// ============================================================================

class factionselect_dialog2: FLO_FactionSelectDialog {};
