/*
 * Faction Selection Dialog
 * Author: Frontline Operations
 *
 * Description:
 * Mission setup dialog for selecting factions and campaign parameters.
 * The layout is organized into larger section cards so settings remain
 * readable as the setup surface grows.
 *
 * Dependencies:
 * Requires UI/addon_defines.hpp to be included before this file.
 */

// ============================================================================
// DIALOG LAYOUT CONSTANTS
// ============================================================================

#define FLO_DIALOG_STRINGIFY_IMPL(value) #value
#define FLO_DIALOG_STRINGIFY(value) FLO_DIALOG_STRINGIFY_IMPL(value)
#define FLO_Q(value) FLO_DIALOG_STRINGIFY(value)

// Dialog dimensions
#define FACTION_DIALOG_W            (58 * GUI_GRID_W)
#define FACTION_DIALOG_H            (42.0 * GUI_GRID_H)
#define FACTION_DIALOG_X            (safeZoneX + safeZoneW/2 - FACTION_DIALOG_W/2)
#define FACTION_DIALOG_Y            (safeZoneY + safeZoneH/2 - FACTION_DIALOG_H/2)

// Overall spacing
#define FACTION_HEADER_H            (1.3 * GUI_GRID_H)
#define FACTION_PAD_X               (1.5 * GUI_GRID_W)
#define FACTION_PAD_Y               (0.8 * GUI_GRID_H)
#define FACTION_CARD_GAP_X          (1.0 * GUI_GRID_W)
#define FACTION_CARD_GAP_Y          (0.8 * GUI_GRID_H)

// Shared content geometry
#define FACTION_CONTENT_Y           (FACTION_DIALOG_Y + FACTION_HEADER_H + FACTION_PAD_Y)
#define FACTION_FULL_X              (FACTION_DIALOG_X + FACTION_PAD_X)
#define FACTION_FULL_W              (FACTION_DIALOG_W - (2 * FACTION_PAD_X))
#define FACTION_HALF_W              ((FACTION_FULL_W - FACTION_CARD_GAP_X) / 2)
#define FACTION_HALF_X2             (FACTION_FULL_X + FACTION_HALF_W + FACTION_CARD_GAP_X)

// Card heights
#define FACTION_CARD_FACTIONS_H     (9.0 * GUI_GRID_H)
#define FACTION_CARD_COMMANDER_H    (8.9 * GUI_GRID_H)
#define FACTION_CARD_COMPOSITION_H  (10.8 * GUI_GRID_H)
#define FACTION_CARD_MISC_H         (6.8 * GUI_GRID_H)

// Card positions
#define FACTION_CARD_FACTIONS_Y     (FACTION_CONTENT_Y)
#define FACTION_CARD_COMMANDER_Y    (FACTION_CARD_FACTIONS_Y + FACTION_CARD_FACTIONS_H + FACTION_CARD_GAP_Y)
#define FACTION_CARD_COMPOSITION_Y  (FACTION_CARD_COMMANDER_Y + FACTION_CARD_COMMANDER_H + FACTION_CARD_GAP_Y)
#define FACTION_CARD_MISC_Y         (FACTION_CARD_COMPOSITION_Y + FACTION_CARD_COMPOSITION_H + FACTION_CARD_GAP_Y)

// Field sizing
#define FACTION_ROW_H               (1.2 * GUI_GRID_H)
#define FACTION_LABEL_H             (0.75 * GUI_GRID_H)
#define FACTION_FIELD_GAP_X         (1.0 * GUI_GRID_W)
#define FACTION_THIRD_W             ((FACTION_FULL_W - (2 * FACTION_FIELD_GAP_X)) / 3)
#define FACTION_THIRD_X1            (FACTION_FULL_X)
#define FACTION_THIRD_X2            (FACTION_THIRD_X1 + FACTION_THIRD_W + FACTION_FIELD_GAP_X)
#define FACTION_THIRD_X3            (FACTION_THIRD_X2 + FACTION_THIRD_W + FACTION_FIELD_GAP_X)
#define FACTION_HALF_FIELD_W        ((FACTION_HALF_W - FACTION_FIELD_GAP_X) / 2)
#define FACTION_HALF_FIELD_X1(_cardX) (_cardX)
#define FACTION_HALF_FIELD_X2(_cardX) (_cardX + FACTION_HALF_FIELD_W + FACTION_FIELD_GAP_X)
#define FACTION_SIDE_W              ((FACTION_FULL_W - FACTION_CARD_GAP_X) / 2)
#define FACTION_SIDE_X1             (FACTION_FULL_X)
#define FACTION_SIDE_X2             (FACTION_SIDE_X1 + FACTION_SIDE_W + FACTION_CARD_GAP_X)
#define FACTION_SIDE_FIELD_W        ((FACTION_SIDE_W - FACTION_FIELD_GAP_X) / 2)
#define FACTION_SIDE_FIELD_X1(_cardX) (_cardX)
#define FACTION_SIDE_FIELD_X2(_cardX) (_cardX + FACTION_SIDE_FIELD_W + FACTION_FIELD_GAP_X)
#define FACTION_TUNE_SECTION_W      ((FACTION_FULL_W - (2 * FACTION_CARD_GAP_X) - (1.6 * GUI_GRID_W)) / 3)
#define FACTION_TUNE_RESERVE_X      (FACTION_FULL_X + (0.8 * GUI_GRID_W))
#define FACTION_TUNE_CAPS_X         (FACTION_TUNE_RESERVE_X + FACTION_TUNE_SECTION_W + FACTION_CARD_GAP_X)
#define FACTION_TUNE_COUNTS_X       (FACTION_TUNE_CAPS_X + FACTION_TUNE_SECTION_W + FACTION_CARD_GAP_X)
#define FACTION_TUNE_LABEL_W        (FACTION_TUNE_SECTION_W - (8.2 * GUI_GRID_W))
#define FACTION_TUNE_WEST_W         (3.4 * GUI_GRID_W)
#define FACTION_TUNE_EAST_W         (3.4 * GUI_GRID_W)
#define FACTION_TUNE_WEST_X(_tableX) (_tableX + FACTION_TUNE_LABEL_W + (0.3 * GUI_GRID_W))
#define FACTION_TUNE_EAST_X(_tableX) (_tableX + FACTION_TUNE_LABEL_W + FACTION_TUNE_WEST_W + (0.6 * GUI_GRID_W))
#define FACTION_TUNE_ROW_Y(_row)    (FACTION_CARD_COMPOSITION_Y + ((2.45 + (_row * 0.72)) * GUI_GRID_H))
#define FACTION_TUNE_CELL_H         (0.62 * GUI_GRID_H)
#define FACTION_TAB_W               (7.4 * GUI_GRID_W)
#define FACTION_TAB_H               (0.66 * GUI_GRID_H)
#define FACTION_TAB_GAP             (0.35 * GUI_GRID_W)
#define FACTION_TAB_Y               (FACTION_CARD_COMPOSITION_Y + (0.42 * GUI_GRID_H))
#define FACTION_TAB_X_OBJECTIVES    (FACTION_FULL_X + FACTION_FULL_W - (0.8 * GUI_GRID_W) - FACTION_TAB_W)
#define FACTION_TAB_X_COMPOSITION   (FACTION_TAB_X_OBJECTIVES - FACTION_TAB_GAP - FACTION_TAB_W)

// ============================================================================
// DIALOG-SPECIFIC CONTROL CLASSES
// ============================================================================

class FLO_FactionCombo: FLO_RscCombo
{
	h = FLO_Q(FACTION_ROW_H);
	colorSelectBackground[] = FLO_COLOR_PRIMARY;
	wholeHeight = FLO_Q(12 * GUI_GRID_H);
};

class FLO_FactionMultiList: FLO_RscListBox
{
	style = LB_MULTI;
	h = FLO_Q(5.75 * GUI_GRID_H);
	rowHeight = FLO_Q(0.58 * GUI_GRID_H);
	sizeEx = FLO_FONT_SIZE_XS;
	colorSelectBackground[] = FLO_COLOR_PRIMARY;
	colorSelectBackground2[] = FLO_COLOR_PRIMARY;
	tooltip = "Select one faction, or select multiple auto factions from the same config side to merge their pools.";
};

class FLO_FactionTuneEdit: FLO_RscEdit
{
	h = FLO_Q(FACTION_TUNE_CELL_H);
	style = ST_CENTER;
	colorBackground[] = FLO_COLOR_INPUT_BG;
	sizeEx = FLO_FONT_SIZE_XS;
};

class FLO_FactionTuneLabel: FLO_RscText_Label
{
	h = FLO_Q(FACTION_TUNE_CELL_H);
	sizeEx = FLO_FONT_SIZE_XS;
};

class FLO_FactionTuneSection: FLO_FactionTuneLabel
{
	colorText[] = FLO_COLOR_TEXT_TITLE;
};

class FLO_FactionTabButton: FLO_RscButton_Secondary
{
	h = FLO_Q(FACTION_TAB_H);
	sizeEx = FLO_FONT_SIZE_XS;
};

class FLO_FactionCard: FLO_RscSurface
{
	colorBackground[] = {0.11, 0.11, 0.11, 0.96};
};

class FLO_FactionCardFrame: FLO_RscFrame
{
	colorText[] = {0.28, 0.14, 0.14, 1.00};
};

// ============================================================================
// FACTION SELECTION DIALOG
// ============================================================================

class FLO_FactionSelectDialog
{
	idd = FLO_IDD_FACTION_SELECT;
	movingEnable = 1;
	enableSimulation = 1;

	onLoad = "_this call FLO_fnc_factionDialogOnLoad";
	onUnload = "_this call FLO_fnc_factionDialogOnUnload";

	class Controls
	{
		class Background: FLO_RscBackground
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_DIALOG_X);
			y = FLO_Q(FACTION_DIALOG_Y + FACTION_HEADER_H);
			w = FLO_Q(FACTION_DIALOG_W);
			h = FLO_Q(FACTION_DIALOG_H - FACTION_HEADER_H);
		};

		class HeaderBar: FLO_RscTitleBar
		{
			idc = FLO_IDC_NONE;
			text = "MISSION SETUP";
			x = FLO_Q(FACTION_DIALOG_X);
			y = FLO_Q(FACTION_DIALOG_Y);
			w = FLO_Q(FACTION_DIALOG_W - FLO_UI_CLOSE_BTN_W);
			h = FLO_Q(FACTION_HEADER_H);
		};

		class CloseButton: FLO_RscButton_Close
		{
			idc = FLO_IDC_FACTION_BTN_CLOSE;
			x = FLO_Q(FACTION_DIALOG_X + FACTION_DIALOG_W - FLO_UI_CLOSE_BTN_W);
			y = FLO_Q(FACTION_DIALOG_Y);
			h = FLO_Q(FACTION_HEADER_H);
			action = "closeDialog 0";
		};

		class HeaderSubtitle: FLO_RscText_Muted
		{
			idc = FLO_IDC_NONE;
			text = "Pick the theater, commander posture, and campaign pacing before deployment.";
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_DIALOG_Y + FACTION_HEADER_H + (0.15 * GUI_GRID_H));
			w = FLO_Q(FACTION_FULL_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		// ====================================================================
		// CARD: FACTIONS
		// ====================================================================

		class CardFactionsBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_FACTIONS_Y);
			w = FLO_Q(FACTION_FULL_W);
			h = FLO_Q(FACTION_CARD_FACTIONS_H);
		};

		class CardFactionsFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_FACTIONS_Y);
			w = FLO_Q(FACTION_FULL_W);
			h = FLO_Q(FACTION_CARD_FACTIONS_H);
		};

		class CardFactionsTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "FACTIONS";
			x = FLO_Q(FACTION_FULL_X + (0.8 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (0.35 * GUI_GRID_H));
			w = FLO_Q(22 * GUI_GRID_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class LabelPlayerSide: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "PLAYER SIDE";
			x = FLO_Q(FACTION_FULL_X + FACTION_FULL_W - (15.2 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (0.35 * GUI_GRID_H));
			w = FLO_Q(5.2 * GUI_GRID_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboPlayerSide: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_PLAYER_SIDE;
			x = FLO_Q(FACTION_FULL_X + FACTION_FULL_W - (9.2 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (0.16 * GUI_GRID_H));
			w = FLO_Q(8.4 * GUI_GRID_W);
			tooltip = "Choose the human campaign side. Players must use matching BLUFOR or OPFOR lobby slots.";
		};

		class CardFactionsHint: FLO_RscText_Muted
		{
			idc = FLO_IDC_NONE;
			text = "Each catalog is locked to its native Arma side. Select multiple factions to merge pools for that side.";
			x = FLO_Q(FACTION_FULL_X + (0.8 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (1.0 * GUI_GRID_H));
			w = FLO_Q(FACTION_FULL_W - (1.6 * GUI_GRID_W));
			h = FLO_Q(FACTION_LABEL_H);
		};

		class LabelBluforFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "BLUFOR Faction(s)";
			x = FLO_Q(FACTION_THIRD_X1);
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (1.85 * GUI_GRID_H));
			w = FLO_Q(FACTION_THIRD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboBluforFaction: FLO_FactionMultiList
		{
			idc = FLO_IDC_FACTION_COMBO_BLUFOR;
			x = FLO_Q(FACTION_THIRD_X1);
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (2.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_THIRD_W);
			tooltip = "Select one or more native BLUFOR factions (config side 1).";
		};

		class LabelOpforFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "OPFOR Faction(s)";
			x = FLO_Q(FACTION_THIRD_X2);
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (1.85 * GUI_GRID_H));
			w = FLO_Q(FACTION_THIRD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboOpforFaction: FLO_FactionMultiList
		{
			idc = FLO_IDC_FACTION_COMBO_OPFOR;
			x = FLO_Q(FACTION_THIRD_X2);
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (2.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_THIRD_W);
			tooltip = "Select one or more native OPFOR factions (config side 0).";
		};

		class LabelCivilianFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Civilian Faction(s)";
			x = FLO_Q(FACTION_THIRD_X3);
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (1.85 * GUI_GRID_H));
			w = FLO_Q(FACTION_THIRD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboCivilianFaction: FLO_FactionMultiList
		{
			idc = FLO_IDC_FACTION_COMBO_CIVILIAN;
			x = FLO_Q(FACTION_THIRD_X3);
			y = FLO_Q(FACTION_CARD_FACTIONS_Y + (2.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_THIRD_W);
			tooltip = "Select one or more native civilian factions (config side 3).";
		};

		// ====================================================================
		// CARD: COMMANDER
		// ====================================================================

		class CardCommanderBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_COMMANDER_Y);
			w = FLO_Q(FACTION_FULL_W);
			h = FLO_Q(FACTION_CARD_COMMANDER_H);
		};

		class CardCommanderFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_COMMANDER_Y);
			w = FLO_Q(FACTION_FULL_W);
			h = FLO_Q(FACTION_CARD_COMMANDER_H);
		};

		class CardCommanderTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "COMMANDER POSTURE";
			x = FLO_Q(FACTION_FULL_X + (0.8 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (0.35 * GUI_GRID_H));
			w = FLO_Q(FACTION_FULL_W - (1.6 * GUI_GRID_W));
			h = FLO_Q(FACTION_LABEL_H);
		};

		class CardCommanderHint: FLO_RscText_Muted
		{
			idc = FLO_IDC_NONE;
			text = "Configure each side's commander separately so BLUFOR and OPFOR do not share the same posture.";
			x = FLO_Q(FACTION_FULL_X + (0.8 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (1.0 * GUI_GRID_H));
			w = FLO_Q(FACTION_FULL_W - (1.6 * GUI_GRID_W));
			h = FLO_Q(FACTION_LABEL_H);
		};

		class CommanderWestTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "BLUFOR / WEST";
			x = FLO_Q(FACTION_SIDE_X1);
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (1.75 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class CommanderEastTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "OPFOR / EAST";
			x = FLO_Q(FACTION_SIDE_X2);
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (1.75 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class LabelWestAttackCoverage: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Attack Coverage";
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (2.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboWestAttackCoverage: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_ATTACK_COVERAGE;
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (3.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How heavily the WEST commander fills per-objective attack caps";
		};

		class LabelWestDefenseCoverage: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Defense Coverage";
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (2.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboWestDefenseCoverage: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_DEFENSE_COVERAGE;
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (3.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How heavily the WEST commander fills defensive slots";
		};

		class LabelWestAggression: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Aggression";
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (4.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboWestAggression: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_AGGRESSION;
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (5.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How willing the WEST commander is to launch attacks with partial force";
		};

		class LabelWestTempo: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Tempo";
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (4.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboWestTempo: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_TEMPO;
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (5.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How often the WEST commander runs full decision cycles";
		};

		class LabelWestForceGrowth: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Force Growth";
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (6.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboWestForceGrowth: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_FORCE_GROWTH;
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (7.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How many extra force slots WEST earns after secure captures";
		};

		class LabelWestGarrison: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Baseline Garrison";
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (6.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboWestGarrison: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_GARRISON;
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (7.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "Standing defenders WEST keeps before sending groups elsewhere";
		};

		class LabelEastAttackCoverage: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Attack Coverage";
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (2.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboEastAttackCoverage: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_ATTACK_COVERAGE;
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (3.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How heavily the EAST commander fills per-objective attack caps";
		};

		class LabelEastDefenseCoverage: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Defense Coverage";
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (2.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboEastDefenseCoverage: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_DEFENSE_COVERAGE;
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (3.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How heavily the EAST commander fills defensive slots";
		};

		class LabelEastAggression: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Aggression";
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (4.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboEastAggression: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_AGGRESSION;
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (5.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How willing the EAST commander is to launch attacks with partial force";
		};

		class LabelEastTempo: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Tempo";
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (4.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboEastTempo: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_TEMPO;
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (5.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How often the EAST commander runs full decision cycles";
		};

		class LabelEastForceGrowth: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Force Growth";
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (6.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboEastForceGrowth: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_FORCE_GROWTH;
			x = FLO_Q(FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (7.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "How many extra force slots EAST earns after secure captures";
		};

		class LabelEastGarrison: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Baseline Garrison";
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (6.55 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboEastGarrison: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_GARRISON;
			x = FLO_Q(FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2));
			y = FLO_Q(FACTION_CARD_COMMANDER_Y + (7.25 * GUI_GRID_H));
			w = FLO_Q(FACTION_SIDE_FIELD_W);
			tooltip = "Standing defenders EAST keeps before sending groups elsewhere";
		};

		// ====================================================================
		// CARD: PER NUMERIC FORCE COMPOSITION
		// ====================================================================

		class CardCompositionBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y);
			w = FLO_Q(FACTION_FULL_W);
			h = FLO_Q(FACTION_CARD_COMPOSITION_H);
		};

		class CardCompositionFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y);
			w = FLO_Q(FACTION_FULL_W);
			h = FLO_Q(FACTION_CARD_COMPOSITION_H);
		};

		class CardCompositionTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "PER NUMERIC FORCE COMPOSITION";
			x = FLO_Q(FACTION_FULL_X + (0.8 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y + (0.35 * GUI_GRID_H));
			w = FLO_Q(FACTION_FULL_W - (1.6 * GUI_GRID_W));
			h = FLO_Q(FACTION_LABEL_H);
		};

		class CardCompositionHint: FLO_RscText_Muted
		{
			idc = FLO_IDC_NONE;
			text = "Default faction values load here; use tabs to edit composition and objective groups.";
			x = FLO_Q(FACTION_FULL_X + (0.8 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y + (1.0 * GUI_GRID_H));
			w = FLO_Q(FACTION_FULL_W - (1.6 * GUI_GRID_W));
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ButtonCompositionTab: FLO_FactionTabButton
		{
			idc = FLO_IDC_FACTION_BTN_COMPOSITION_TAB;
			text = "COMPOSITION";
			x = FLO_Q(FACTION_TAB_X_COMPOSITION);
			y = FLO_Q(FACTION_TAB_Y);
			w = FLO_Q(FACTION_TAB_W);
			action = "['composition'] call FLO_fnc_factionDialogShowCompositionTab";
			tooltip = "Show reserve, cap, and group count fields";
		};

		class ButtonObjectiveGroupsTab: FLO_FactionTabButton
		{
			idc = FLO_IDC_FACTION_BTN_OBJECTIVE_GROUPS_TAB;
			text = "OBJECTIVE GROUPS";
			x = FLO_Q(FACTION_TAB_X_OBJECTIVES);
			y = FLO_Q(FACTION_TAB_Y);
			w = FLO_Q(FACTION_TAB_W);
			action = "['objectives'] call FLO_fnc_factionDialogShowCompositionTab";
			tooltip = "Show objective subtype group templates";
		};

		class CompositionContentAnchor: FLO_FactionTuneLabel
		{
			idc = FLO_IDC_FACTION_COMPOSITION_ANCHOR;
			text = "";
			x = FLO_Q(FACTION_TUNE_RESERVE_X);
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			w = FLO_Q(FACTION_FULL_W - (1.6 * GUI_GRID_W));
			h = FLO_Q(FACTION_TUNE_CELL_H);
			colorText[] = {0, 0, 0, 0};
		};

		class TuneSectionReserves: FLO_FactionTuneSection
		{
			idc = FLO_IDC_NONE;
			text = "RESERVES";
			x = FLO_Q(FACTION_TUNE_RESERVE_X);
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y + (1.65 * GUI_GRID_H));
			w = FLO_Q(FACTION_TUNE_LABEL_W);
		};

		class TuneSectionCaps: FLO_FactionTuneSection
		{
			idc = FLO_IDC_NONE;
			text = "OBJECTIVE CAPS";
			x = FLO_Q(FACTION_TUNE_CAPS_X);
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y + (1.65 * GUI_GRID_H));
			w = FLO_Q(FACTION_TUNE_LABEL_W);
		};

		class TuneSectionCounts: FLO_FactionTuneSection
		{
			idc = FLO_IDC_NONE;
			text = "GROUP COUNTS";
			x = FLO_Q(FACTION_TUNE_COUNTS_X);
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y + (1.65 * GUI_GRID_H));
			w = FLO_Q(FACTION_TUNE_LABEL_W);
		};

		class TuneHeaderWestLeft: FLO_FactionTuneLabel
		{
			idc = FLO_IDC_NONE;
			text = "BLUFOR";
			x = FLO_Q(FACTION_TUNE_WEST_X(FACTION_TUNE_RESERVE_X));
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y + (1.65 * GUI_GRID_H));
			w = FLO_Q(FACTION_TUNE_WEST_W);
		};

		class TuneHeaderEastLeft: FLO_FactionTuneLabel
		{
			idc = FLO_IDC_NONE;
			text = "OPFOR";
			x = FLO_Q(FACTION_TUNE_EAST_X(FACTION_TUNE_RESERVE_X));
			y = FLO_Q(FACTION_CARD_COMPOSITION_Y + (1.65 * GUI_GRID_H));
			w = FLO_Q(FACTION_TUNE_EAST_W);
		};

		class TuneHeaderWestCaps: TuneHeaderWestLeft
		{
			x = FLO_Q(FACTION_TUNE_WEST_X(FACTION_TUNE_CAPS_X));
		};

		class TuneHeaderEastCaps: TuneHeaderEastLeft
		{
			x = FLO_Q(FACTION_TUNE_EAST_X(FACTION_TUNE_CAPS_X));
		};

		class TuneHeaderWestCounts: TuneHeaderWestLeft
		{
			x = FLO_Q(FACTION_TUNE_WEST_X(FACTION_TUNE_COUNTS_X));
		};

		class TuneHeaderEastCounts: TuneHeaderEastLeft
		{
			x = FLO_Q(FACTION_TUNE_EAST_X(FACTION_TUNE_COUNTS_X));
		};

		class TuneLabelGroundReserve: FLO_FactionTuneLabel
		{
			idc = FLO_IDC_NONE;
			text = "Ground Reserve";
			x = FLO_Q(FACTION_TUNE_RESERVE_X);
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			w = FLO_Q(FACTION_TUNE_LABEL_W);
		};
		class TuneWestGroundReserve: FLO_FactionTuneEdit
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_RESERVE_GROUND;
			x = FLO_Q(FACTION_TUNE_WEST_X(FACTION_TUNE_RESERVE_X));
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			w = FLO_Q(FACTION_TUNE_WEST_W);
			tooltip = "Set BLUFOR ground transport reserve count";
		};
		class TuneEastGroundReserve: FLO_FactionTuneEdit
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_RESERVE_GROUND;
			x = FLO_Q(FACTION_TUNE_EAST_X(FACTION_TUNE_RESERVE_X));
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			w = FLO_Q(FACTION_TUNE_EAST_W);
			tooltip = "Set OPFOR ground transport reserve count";
		};

		class TuneLabelAirReserve: TuneLabelGroundReserve
		{
			text = "Air Reserve";
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
		};
		class TuneWestAirReserve: TuneWestGroundReserve
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_RESERVE_AIR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
			tooltip = "Set BLUFOR air transport reserve count";
		};
		class TuneEastAirReserve: TuneEastGroundReserve
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_RESERVE_AIR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
			tooltip = "Set OPFOR air transport reserve count";
		};

		class TuneLabelInfantryCap: TuneLabelGroundReserve
		{
			text = "Infantry Cap";
			x = FLO_Q(FACTION_TUNE_CAPS_X);
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
		};
		class TuneWestInfantryCap: TuneWestGroundReserve
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_INFANTRY;
			x = FLO_Q(FACTION_TUNE_WEST_X(FACTION_TUNE_CAPS_X));
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			tooltip = "Set BLUFOR infantry objective cap";
		};
		class TuneEastInfantryCap: TuneEastGroundReserve
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_INFANTRY;
			x = FLO_Q(FACTION_TUNE_EAST_X(FACTION_TUNE_CAPS_X));
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			tooltip = "Set OPFOR infantry objective cap";
		};

		class TuneLabelMotorizedCap: TuneLabelInfantryCap
		{
			text = "Motorized Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
		};
		class TuneWestMotorizedCap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_MOTORIZED;
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
			tooltip = "Set BLUFOR motorized objective cap";
		};
		class TuneEastMotorizedCap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_MOTORIZED;
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
			tooltip = "Set OPFOR motorized objective cap";
		};

		class TuneLabelMechanizedCap: TuneLabelInfantryCap
		{
			text = "Mechanized Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(2));
		};
		class TuneWestMechanizedCap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_MECHANIZED;
			y = FLO_Q(FACTION_TUNE_ROW_Y(2));
			tooltip = "Set BLUFOR mechanized objective cap";
		};
		class TuneEastMechanizedCap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_MECHANIZED;
			y = FLO_Q(FACTION_TUNE_ROW_Y(2));
			tooltip = "Set OPFOR mechanized objective cap";
		};

		class TuneLabelArmorCap: TuneLabelInfantryCap
		{
			text = "Armor Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(3));
		};
		class TuneWestArmorCap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_ARMOR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(3));
			tooltip = "Set BLUFOR armor objective cap";
		};
		class TuneEastArmorCap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_ARMOR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(3));
			tooltip = "Set OPFOR armor objective cap";
		};

		class TuneLabelHelicopterCap: TuneLabelInfantryCap
		{
			text = "Helicopter Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(4));
		};
		class TuneWestHelicopterCap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_HELICOPTER;
			y = FLO_Q(FACTION_TUNE_ROW_Y(4));
			tooltip = "Set BLUFOR helicopter objective cap";
		};
		class TuneEastHelicopterCap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_HELICOPTER;
			y = FLO_Q(FACTION_TUNE_ROW_Y(4));
			tooltip = "Set OPFOR helicopter objective cap";
		};

		class TuneLabelJetCap: TuneLabelInfantryCap
		{
			text = "Jet Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(5));
		};
		class TuneWestJetCap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_JET;
			y = FLO_Q(FACTION_TUNE_ROW_Y(5));
			tooltip = "Set BLUFOR jet objective cap";
		};
		class TuneEastJetCap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_JET;
			y = FLO_Q(FACTION_TUNE_ROW_Y(5));
			tooltip = "Set OPFOR jet objective cap";
		};

		class TuneLabelAirCap: TuneLabelInfantryCap
		{
			text = "Air Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(6));
		};
		class TuneWestAirCap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_AIR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(6));
			tooltip = "Set BLUFOR combined air objective cap";
		};
		class TuneEastAirCap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_AIR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(6));
			tooltip = "Set OPFOR combined air objective cap";
		};

		class TuneLabelArtilleryObjectiveCap: TuneLabelInfantryCap
		{
			text = "Artillery Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(7));
		};
		class TuneWestArtilleryCap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_ARTILLERY;
			y = FLO_Q(FACTION_TUNE_ROW_Y(7));
			tooltip = "Set BLUFOR artillery objective cap";
		};
		class TuneEastArtilleryCap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_ARTILLERY;
			y = FLO_Q(FACTION_TUNE_ROW_Y(7));
			tooltip = "Set OPFOR artillery objective cap";
		};

		class TuneLabelMobileAACap: TuneLabelInfantryCap
		{
			text = "Mobile AA Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(8));
		};
		class TuneWestMobileAACap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_MOBILE_AA;
			y = FLO_Q(FACTION_TUNE_ROW_Y(8));
			tooltip = "Set BLUFOR mobile AA objective cap";
		};
		class TuneEastMobileAACap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_MOBILE_AA;
			y = FLO_Q(FACTION_TUNE_ROW_Y(8));
			tooltip = "Set OPFOR mobile AA objective cap";
		};

		class TuneLabelStaticAACap: TuneLabelInfantryCap
		{
			text = "Static AA Cap";
			y = FLO_Q(FACTION_TUNE_ROW_Y(9));
		};
		class TuneWestStaticAACap: TuneWestInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_CAP_STATIC_AA;
			y = FLO_Q(FACTION_TUNE_ROW_Y(9));
			tooltip = "Set BLUFOR static AA objective cap";
		};
		class TuneEastStaticAACap: TuneEastInfantryCap
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_CAP_STATIC_AA;
			y = FLO_Q(FACTION_TUNE_ROW_Y(9));
			tooltip = "Set OPFOR static AA objective cap";
		};

		class TuneLabelInfantryCount: FLO_FactionTuneLabel
		{
			idc = FLO_IDC_NONE;
			text = "Infantry Count";
			x = FLO_Q(FACTION_TUNE_COUNTS_X);
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			w = FLO_Q(FACTION_TUNE_LABEL_W);
		};
		class TuneWestInfantryCount: FLO_FactionTuneEdit
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_INFANTRY;
			x = FLO_Q(FACTION_TUNE_WEST_X(FACTION_TUNE_COUNTS_X));
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			w = FLO_Q(FACTION_TUNE_WEST_W);
			tooltip = "Set BLUFOR infantry group count";
		};
		class TuneEastInfantryCount: FLO_FactionTuneEdit
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_INFANTRY;
			x = FLO_Q(FACTION_TUNE_EAST_X(FACTION_TUNE_COUNTS_X));
			y = FLO_Q(FACTION_TUNE_ROW_Y(0));
			w = FLO_Q(FACTION_TUNE_EAST_W);
			tooltip = "Set OPFOR infantry group count";
		};

		class TuneLabelMotorizedCount: TuneLabelInfantryCount
		{
			text = "Motorized Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
		};
		class TuneWestMotorizedCount: TuneWestInfantryCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_MOTORIZED;
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
			tooltip = "Set BLUFOR motorized group count";
		};
		class TuneEastMotorizedCount: TuneEastInfantryCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_MOTORIZED;
			y = FLO_Q(FACTION_TUNE_ROW_Y(1));
			tooltip = "Set OPFOR motorized group count";
		};

		class TuneLabelMechanizedCount: TuneLabelInfantryCount
		{
			text = "Mechanized Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(2));
		};
		class TuneWestMechanizedCount: TuneWestInfantryCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_MECHANIZED;
			y = FLO_Q(FACTION_TUNE_ROW_Y(2));
			tooltip = "Set BLUFOR mechanized group count";
		};
		class TuneEastMechanizedCount: TuneEastInfantryCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_MECHANIZED;
			y = FLO_Q(FACTION_TUNE_ROW_Y(2));
			tooltip = "Set OPFOR mechanized group count";
		};

		class TuneLabelArmorCount: TuneLabelInfantryCount
		{
			text = "Armor Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(3));
		};
		class TuneWestArmorCount: TuneWestInfantryCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_ARMOR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(3));
			tooltip = "Set BLUFOR armor group count";
		};
		class TuneEastArmorCount: TuneEastInfantryCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_ARMOR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(3));
			tooltip = "Set OPFOR armor group count";
		};

		class TuneLabelHelicopterCount: TuneLabelArmorCount
		{
			text = "Helicopter Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(4));
		};
		class TuneWestHelicopterCount: TuneWestArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_HELICOPTER;
			y = FLO_Q(FACTION_TUNE_ROW_Y(4));
			tooltip = "Set BLUFOR helicopter group count";
		};
		class TuneEastHelicopterCount: TuneEastArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_HELICOPTER;
			y = FLO_Q(FACTION_TUNE_ROW_Y(4));
			tooltip = "Set OPFOR helicopter group count";
		};

		class TuneLabelJetCount: TuneLabelArmorCount
		{
			text = "Jet Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(5));
		};
		class TuneWestJetCount: TuneWestArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_JET;
			y = FLO_Q(FACTION_TUNE_ROW_Y(5));
			tooltip = "Set BLUFOR jet group count";
		};
		class TuneEastJetCount: TuneEastArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_JET;
			y = FLO_Q(FACTION_TUNE_ROW_Y(5));
			tooltip = "Set OPFOR jet group count";
		};

		class TuneLabelAirCount: TuneLabelArmorCount
		{
			text = "Air Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(6));
		};
		class TuneWestAirCount: TuneWestArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_AIR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(6));
			tooltip = "Set BLUFOR combined air group count";
		};
		class TuneEastAirCount: TuneEastArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_AIR;
			y = FLO_Q(FACTION_TUNE_ROW_Y(6));
			tooltip = "Set OPFOR combined air group count";
		};

		class TuneLabelArtilleryCount: TuneLabelArmorCount
		{
			text = "Artillery Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(7));
		};
		class TuneWestArtilleryCount: TuneWestArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_ARTILLERY;
			y = FLO_Q(FACTION_TUNE_ROW_Y(7));
			tooltip = "Set BLUFOR artillery group count";
		};
		class TuneEastArtilleryCount: TuneEastArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_ARTILLERY;
			y = FLO_Q(FACTION_TUNE_ROW_Y(7));
			tooltip = "Set OPFOR artillery group count";
		};

		class TuneLabelMobileAACount: TuneLabelArmorCount
		{
			text = "Mobile AA Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(8));
		};
		class TuneWestMobileAACount: TuneWestArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_MOBILE_AA;
			y = FLO_Q(FACTION_TUNE_ROW_Y(8));
			tooltip = "Set BLUFOR mobile AA group count";
		};
		class TuneEastMobileAACount: TuneEastArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_MOBILE_AA;
			y = FLO_Q(FACTION_TUNE_ROW_Y(8));
			tooltip = "Set OPFOR mobile AA group count";
		};

		class TuneLabelStaticAACount: TuneLabelArmorCount
		{
			text = "Static AA Count";
			y = FLO_Q(FACTION_TUNE_ROW_Y(9));
		};
		class TuneWestStaticAACount: TuneWestArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_WEST_COUNT_STATIC_AA;
			y = FLO_Q(FACTION_TUNE_ROW_Y(9));
			tooltip = "Set BLUFOR static AA group count";
		};
		class TuneEastStaticAACount: TuneEastArmorCount
		{
			idc = FLO_IDC_FACTION_EDIT_EAST_COUNT_STATIC_AA;
			y = FLO_Q(FACTION_TUNE_ROW_Y(9));
			tooltip = "Set OPFOR static AA group count";
		};

		// ====================================================================
		// CARD: CAMPAIGN
		// ====================================================================

		class CardCampaignBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_MISC_Y);
			w = FLO_Q(FACTION_HALF_W);
			h = FLO_Q(FACTION_CARD_MISC_H);
		};

		class CardCampaignFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_MISC_Y);
			w = FLO_Q(FACTION_HALF_W);
			h = FLO_Q(FACTION_CARD_MISC_H);
		};

		class CardCampaignTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "CAMPAIGN";
			x = FLO_Q(FACTION_FULL_X + (0.8 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_MISC_Y + (0.35 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_W - (1.6 * GUI_GRID_W));
			h = FLO_Q(FACTION_LABEL_H);
		};

		class LabelReputation: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Civilian Standing";
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_MISC_Y + (1.7 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboReputation: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_REPUTATION;
			x = FLO_Q(FACTION_FULL_X);
			y = FLO_Q(FACTION_CARD_MISC_Y + (2.4 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_W);
			tooltip = "Set how friendly civilians are to players at mission start";
		};

		// ====================================================================
		// CARD: WORLD
		// ====================================================================

		class CardWorldBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_HALF_X2);
			y = FLO_Q(FACTION_CARD_MISC_Y);
			w = FLO_Q(FACTION_HALF_W);
			h = FLO_Q(FACTION_CARD_MISC_H);
		};

		class CardWorldFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FLO_Q(FACTION_HALF_X2);
			y = FLO_Q(FACTION_CARD_MISC_Y);
			w = FLO_Q(FACTION_HALF_W);
			h = FLO_Q(FACTION_CARD_MISC_H);
		};

		class CardWorldTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "WORLD";
			x = FLO_Q(FACTION_HALF_X2 + (0.8 * GUI_GRID_W));
			y = FLO_Q(FACTION_CARD_MISC_Y + (0.35 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_W - (1.6 * GUI_GRID_W));
			h = FLO_Q(FACTION_LABEL_H);
		};

		class LabelObjectiveSizeThreshold: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Objective Size";
			x = FLO_Q(FACTION_HALF_FIELD_X1(FACTION_HALF_X2));
			y = FLO_Q(FACTION_CARD_MISC_Y + (1.7 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboObjectiveSizeThreshold: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_OBJ_SIZE;
			x = FLO_Q(FACTION_HALF_FIELD_X1(FACTION_HALF_X2));
			y = FLO_Q(FACTION_CARD_MISC_Y + (2.4 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_FIELD_W);
			tooltip = "Minimum structures required for generated cluster objectives";
		};

		class LabelVirtualizationDistance: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Virtualization Distance";
			x = FLO_Q(FACTION_HALF_FIELD_X2(FACTION_HALF_X2));
			y = FLO_Q(FACTION_CARD_MISC_Y + (1.7 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboVirtualizationDistance: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_VIRT_DIST;
			x = FLO_Q(FACTION_HALF_FIELD_X2(FACTION_HALF_X2));
			y = FLO_Q(FACTION_CARD_MISC_Y + (2.4 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_FIELD_W);
			tooltip = "Distance at which virtual groups physically spawn";
		};

		class LabelVirtualizationUnitCap: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Active AI Cap";
			x = FLO_Q(FACTION_HALF_FIELD_X1(FACTION_HALF_X2));
			y = FLO_Q(FACTION_CARD_MISC_Y + (4.1 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboVirtualizationUnitCap: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_VIRT_UNIT_CAP;
			x = FLO_Q(FACTION_HALF_FIELD_X1(FACTION_HALF_X2));
			y = FLO_Q(FACTION_CARD_MISC_Y + (4.8 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_FIELD_W);
			tooltip = "Maximum non-player AI that may stay physically spawned before additional groups are held at the virtualization edge";
		};

		class LabelTerritoryRatio: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Starting Territory";
			x = FLO_Q(FACTION_HALF_FIELD_X2(FACTION_HALF_X2));
			y = FLO_Q(FACTION_CARD_MISC_Y + (4.1 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_FIELD_W);
			h = FLO_Q(FACTION_LABEL_H);
		};

		class ComboTerritoryRatio: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_TERRITORY_RATIO;
			x = FLO_Q(FACTION_HALF_FIELD_X2(FACTION_HALF_X2));
			y = FLO_Q(FACTION_CARD_MISC_Y + (4.8 * GUI_GRID_H));
			w = FLO_Q(FACTION_HALF_FIELD_W);
			tooltip = "Initial objective ownership split before combat starts";
		};

		class StartButton: FLO_RscButton_Primary
		{
			idc = FLO_IDC_FACTION_BTN_START;
			text = "START MISSION";
			x = FLO_Q(FACTION_DIALOG_X + FACTION_DIALOG_W/2 - (8 * GUI_GRID_W));
			y = FLO_Q(FACTION_DIALOG_Y + FACTION_DIALOG_H - (1.9 * GUI_GRID_H));
			w = FLO_Q(16 * GUI_GRID_W);
			h = FLO_Q(1.4 * GUI_GRID_H);
			action = "[] call FLO_fnc_factionDialogStart";
			tooltip = "Start the mission with selected settings";
		};
	};
};

// ============================================================================
// LEGACY ALIAS (for backward compatibility)
// ============================================================================

class factionselect_dialog2: FLO_FactionSelectDialog {};
