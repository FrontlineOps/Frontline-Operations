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
 * Requires UI/defines.hpp to be included before this file.
 */

// ============================================================================
// DIALOG LAYOUT CONSTANTS
// ============================================================================

// Dialog dimensions
#define FACTION_DIALOG_W            (58 * GUI_GRID_W)
#define FACTION_DIALOG_H            (26.4 * GUI_GRID_H)
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
#define FACTION_CARD_FACTIONS_H     (4.4 * GUI_GRID_H)
#define FACTION_CARD_COMMANDER_H    (8.9 * GUI_GRID_H)
#define FACTION_CARD_MISC_H         (6.8 * GUI_GRID_H)

// Card positions
#define FACTION_CARD_FACTIONS_Y     (FACTION_CONTENT_Y)
#define FACTION_CARD_COMMANDER_Y    (FACTION_CARD_FACTIONS_Y + FACTION_CARD_FACTIONS_H + FACTION_CARD_GAP_Y)
#define FACTION_CARD_MISC_Y         (FACTION_CARD_COMMANDER_Y + FACTION_CARD_COMMANDER_H + FACTION_CARD_GAP_Y)

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

// ============================================================================
// DIALOG-SPECIFIC CONTROL CLASSES
// ============================================================================

class FLO_FactionCombo: FLO_RscCombo
{
	h = FACTION_ROW_H;
	colorSelectBackground[] = FLO_COLOR_PRIMARY;
	wholeHeight = 12 * GUI_GRID_H;
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
	idd = FLO_IDD_FACTION;
	movingEnable = true;
	enableSimulation = true;

	onLoad = "_this call FLO_fnc_factionDialogOnLoad";
	onUnload = "_this call FLO_fnc_factionDialogOnUnload";

	class Controls
	{
		class Background: FLO_RscBackground
		{
			idc = FLO_IDC_NONE;
			x = FACTION_DIALOG_X;
			y = FACTION_DIALOG_Y + FACTION_HEADER_H;
			w = FACTION_DIALOG_W;
			h = FACTION_DIALOG_H - FACTION_HEADER_H;
		};

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

		class HeaderSubtitle: FLO_RscText_Muted
		{
			idc = FLO_IDC_NONE;
			text = "Pick the theater, commander posture, and campaign pacing before deployment.";
			x = FACTION_FULL_X;
			y = FACTION_DIALOG_Y + FACTION_HEADER_H + (0.15 * GUI_GRID_H);
			w = FACTION_FULL_W;
			h = FACTION_LABEL_H;
		};

		// ====================================================================
		// CARD: FACTIONS
		// ====================================================================

		class CardFactionsBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FACTION_FULL_X;
			y = FACTION_CARD_FACTIONS_Y;
			w = FACTION_FULL_W;
			h = FACTION_CARD_FACTIONS_H;
		};

		class CardFactionsFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FACTION_FULL_X;
			y = FACTION_CARD_FACTIONS_Y;
			w = FACTION_FULL_W;
			h = FACTION_CARD_FACTIONS_H;
		};

		class CardFactionsTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "FACTIONS";
			x = FACTION_FULL_X + (0.8 * GUI_GRID_W);
			y = FACTION_CARD_FACTIONS_Y + (0.35 * GUI_GRID_H);
			w = FACTION_FULL_W - (1.6 * GUI_GRID_W);
			h = FACTION_LABEL_H;
		};

		class CardFactionsHint: FLO_RscText_Muted
		{
			idc = FLO_IDC_NONE;
			text = "These define the three sides present in the campaign.";
			x = FACTION_FULL_X + (0.8 * GUI_GRID_W);
			y = FACTION_CARD_FACTIONS_Y + (1.0 * GUI_GRID_H);
			w = FACTION_FULL_W - (1.6 * GUI_GRID_W);
			h = FACTION_LABEL_H;
		};

		class LabelPlayerFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Player Faction";
			x = FACTION_THIRD_X1;
			y = FACTION_CARD_FACTIONS_Y + (1.85 * GUI_GRID_H);
			w = FACTION_THIRD_W;
			h = FACTION_LABEL_H;
		};

		class ComboPlayerFaction: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_PLAYER;
			x = FACTION_THIRD_X1;
			y = FACTION_CARD_FACTIONS_Y + (2.55 * GUI_GRID_H);
			w = FACTION_THIRD_W;
			tooltip = "Select the player faction";
		};

		class LabelEnemyFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Enemy Faction";
			x = FACTION_THIRD_X2;
			y = FACTION_CARD_FACTIONS_Y + (1.85 * GUI_GRID_H);
			w = FACTION_THIRD_W;
			h = FACTION_LABEL_H;
		};

		class ComboEnemyFaction: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_ENEMY;
			x = FACTION_THIRD_X2;
			y = FACTION_CARD_FACTIONS_Y + (2.55 * GUI_GRID_H);
			w = FACTION_THIRD_W;
			tooltip = "Select the enemy faction";
		};

		class LabelCivilianFaction: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Civilian Faction";
			x = FACTION_THIRD_X3;
			y = FACTION_CARD_FACTIONS_Y + (1.85 * GUI_GRID_H);
			w = FACTION_THIRD_W;
			h = FACTION_LABEL_H;
		};

		class ComboCivilianFaction: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_CIVILIAN;
			x = FACTION_THIRD_X3;
			y = FACTION_CARD_FACTIONS_Y + (2.55 * GUI_GRID_H);
			w = FACTION_THIRD_W;
			tooltip = "Select the civilian faction";
		};

		// ====================================================================
		// CARD: COMMANDER
		// ====================================================================

		class CardCommanderBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FACTION_FULL_X;
			y = FACTION_CARD_COMMANDER_Y;
			w = FACTION_FULL_W;
			h = FACTION_CARD_COMMANDER_H;
		};

		class CardCommanderFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FACTION_FULL_X;
			y = FACTION_CARD_COMMANDER_Y;
			w = FACTION_FULL_W;
			h = FACTION_CARD_COMMANDER_H;
		};

		class CardCommanderTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "COMMANDER POSTURE";
			x = FACTION_FULL_X + (0.8 * GUI_GRID_W);
			y = FACTION_CARD_COMMANDER_Y + (0.35 * GUI_GRID_H);
			w = FACTION_FULL_W - (1.6 * GUI_GRID_W);
			h = FACTION_LABEL_H;
		};

		class CardCommanderHint: FLO_RscText_Muted
		{
			idc = FLO_IDC_NONE;
			text = "Configure each side's commander separately so BLUFOR and OPFOR do not share the same posture.";
			x = FACTION_FULL_X + (0.8 * GUI_GRID_W);
			y = FACTION_CARD_COMMANDER_Y + (1.0 * GUI_GRID_H);
			w = FACTION_FULL_W - (1.6 * GUI_GRID_W);
			h = FACTION_LABEL_H;
		};

		class CommanderWestTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "BLUFOR / WEST";
			x = FACTION_SIDE_X1;
			y = FACTION_CARD_COMMANDER_Y + (1.75 * GUI_GRID_H);
			w = FACTION_SIDE_W;
			h = FACTION_LABEL_H;
		};

		class CommanderEastTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "OPFOR / EAST";
			x = FACTION_SIDE_X2;
			y = FACTION_CARD_COMMANDER_Y + (1.75 * GUI_GRID_H);
			w = FACTION_SIDE_W;
			h = FACTION_LABEL_H;
		};

		class LabelWestAttackCoverage: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Attack Coverage";
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (2.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboWestAttackCoverage: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_ATTACK_COVERAGE;
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (3.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How heavily the WEST commander fills per-objective attack caps";
		};

		class LabelWestDefenseCoverage: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Defense Coverage";
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (2.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboWestDefenseCoverage: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_DEFENSE_COVERAGE;
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (3.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How heavily the WEST commander fills defensive slots";
		};

		class LabelWestAggression: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Aggression";
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (4.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboWestAggression: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_AGGRESSION;
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (5.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How willing the WEST commander is to launch attacks with partial force";
		};

		class LabelWestTempo: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Tempo";
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (4.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboWestTempo: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_TEMPO;
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (5.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How often the WEST commander runs full decision cycles";
		};

		class LabelWestForceGrowth: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Force Growth";
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (6.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboWestForceGrowth: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_FORCE_GROWTH;
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (7.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How many extra force slots WEST earns after secure captures";
		};

		class LabelWestGarrison: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Baseline Garrison";
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (6.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboWestGarrison: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_WEST_GARRISON;
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X1);
			y = FACTION_CARD_COMMANDER_Y + (7.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "Standing defenders WEST keeps before sending groups elsewhere";
		};

		class LabelEastAttackCoverage: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Attack Coverage";
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (2.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboEastAttackCoverage: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_ATTACK_COVERAGE;
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (3.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How heavily the EAST commander fills per-objective attack caps";
		};

		class LabelEastDefenseCoverage: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Defense Coverage";
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (2.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboEastDefenseCoverage: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_DEFENSE_COVERAGE;
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (3.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How heavily the EAST commander fills defensive slots";
		};

		class LabelEastAggression: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Aggression";
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (4.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboEastAggression: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_AGGRESSION;
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (5.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How willing the EAST commander is to launch attacks with partial force";
		};

		class LabelEastTempo: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Tempo";
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (4.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboEastTempo: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_TEMPO;
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (5.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How often the EAST commander runs full decision cycles";
		};

		class LabelEastForceGrowth: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Force Growth";
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (6.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboEastForceGrowth: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_FORCE_GROWTH;
			x = FACTION_SIDE_FIELD_X1(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (7.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "How many extra force slots EAST earns after secure captures";
		};

		class LabelEastGarrison: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Baseline Garrison";
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (6.55 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboEastGarrison: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_EAST_GARRISON;
			x = FACTION_SIDE_FIELD_X2(FACTION_SIDE_X2);
			y = FACTION_CARD_COMMANDER_Y + (7.25 * GUI_GRID_H);
			w = FACTION_SIDE_FIELD_W;
			tooltip = "Standing defenders EAST keeps before sending groups elsewhere";
		};

		// ====================================================================
		// CARD: CAMPAIGN
		// ====================================================================

		class CardCampaignBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FACTION_FULL_X;
			y = FACTION_CARD_MISC_Y;
			w = FACTION_HALF_W;
			h = FACTION_CARD_MISC_H;
		};

		class CardCampaignFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FACTION_FULL_X;
			y = FACTION_CARD_MISC_Y;
			w = FACTION_HALF_W;
			h = FACTION_CARD_MISC_H;
		};

		class CardCampaignTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "CAMPAIGN";
			x = FACTION_FULL_X + (0.8 * GUI_GRID_W);
			y = FACTION_CARD_MISC_Y + (0.35 * GUI_GRID_H);
			w = FACTION_HALF_W - (1.6 * GUI_GRID_W);
			h = FACTION_LABEL_H;
		};

		class LabelStartingResources: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Starting Resources";
			x = FACTION_HALF_FIELD_X1(FACTION_FULL_X);
			y = FACTION_CARD_MISC_Y + (1.7 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboStartingResources: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_RESOURCES;
			x = FACTION_HALF_FIELD_X1(FACTION_FULL_X);
			y = FACTION_CARD_MISC_Y + (2.4 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			tooltip = "Select starting resource level";
		};

		class LabelReputation: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Civilian Standing";
			x = FACTION_HALF_FIELD_X2(FACTION_FULL_X);
			y = FACTION_CARD_MISC_Y + (1.7 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboReputation: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_REPUTATION;
			x = FACTION_HALF_FIELD_X2(FACTION_FULL_X);
			y = FACTION_CARD_MISC_Y + (2.4 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			tooltip = "Set how friendly civilians are to players at mission start";
		};

		// ====================================================================
		// CARD: WORLD
		// ====================================================================

		class CardWorldBg: FLO_FactionCard
		{
			idc = FLO_IDC_NONE;
			x = FACTION_HALF_X2;
			y = FACTION_CARD_MISC_Y;
			w = FACTION_HALF_W;
			h = FACTION_CARD_MISC_H;
		};

		class CardWorldFrame: FLO_FactionCardFrame
		{
			idc = FLO_IDC_NONE;
			x = FACTION_HALF_X2;
			y = FACTION_CARD_MISC_Y;
			w = FACTION_HALF_W;
			h = FACTION_CARD_MISC_H;
		};

		class CardWorldTitle: FLO_RscText_Title
		{
			idc = FLO_IDC_NONE;
			text = "WORLD";
			x = FACTION_HALF_X2 + (0.8 * GUI_GRID_W);
			y = FACTION_CARD_MISC_Y + (0.35 * GUI_GRID_H);
			w = FACTION_HALF_W - (1.6 * GUI_GRID_W);
			h = FACTION_LABEL_H;
		};

		class LabelObjectiveSizeThreshold: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Objective Size";
			x = FACTION_HALF_FIELD_X1(FACTION_HALF_X2);
			y = FACTION_CARD_MISC_Y + (1.7 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboObjectiveSizeThreshold: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_OBJ_SIZE;
			x = FACTION_HALF_FIELD_X1(FACTION_HALF_X2);
			y = FACTION_CARD_MISC_Y + (2.4 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			tooltip = "Minimum structures required for generated cluster objectives";
		};

		class LabelVirtualizationDistance: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Virtualization Distance";
			x = FACTION_HALF_FIELD_X2(FACTION_HALF_X2);
			y = FACTION_CARD_MISC_Y + (1.7 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboVirtualizationDistance: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_VIRT_DIST;
			x = FACTION_HALF_FIELD_X2(FACTION_HALF_X2);
			y = FACTION_CARD_MISC_Y + (2.4 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			tooltip = "Distance at which virtual groups physically spawn";
		};

		class LabelVirtualizationUnitCap: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Active AI Cap";
			x = FACTION_HALF_FIELD_X1(FACTION_HALF_X2);
			y = FACTION_CARD_MISC_Y + (4.1 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboVirtualizationUnitCap: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_VIRT_UNIT_CAP;
			x = FACTION_HALF_FIELD_X1(FACTION_HALF_X2);
			y = FACTION_CARD_MISC_Y + (4.8 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			tooltip = "Maximum non-player AI that may stay physically spawned before additional groups are held at the virtualization edge";
		};

		class LabelTerritoryRatio: FLO_RscText_Label
		{
			idc = FLO_IDC_NONE;
			text = "Starting Territory";
			x = FACTION_HALF_FIELD_X2(FACTION_HALF_X2);
			y = FACTION_CARD_MISC_Y + (4.1 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			h = FACTION_LABEL_H;
		};

		class ComboTerritoryRatio: FLO_FactionCombo
		{
			idc = FLO_IDC_FACTION_COMBO_TERRITORY_RATIO;
			x = FACTION_HALF_FIELD_X2(FACTION_HALF_X2);
			y = FACTION_CARD_MISC_Y + (4.8 * GUI_GRID_H);
			w = FACTION_HALF_FIELD_W;
			tooltip = "Initial objective ownership split before combat starts";
		};

		class StartButton: FLO_RscButton_Primary
		{
			idc = FLO_IDC_FACTION_BTN_START;
			text = "START MISSION";
			x = FACTION_DIALOG_X + FACTION_DIALOG_W/2 - (8 * GUI_GRID_W);
			y = FACTION_DIALOG_Y + FACTION_DIALOG_H - (1.9 * GUI_GRID_H);
			w = 16 * GUI_GRID_W;
			h = 1.4 * GUI_GRID_H;
			action = "[] call FLO_fnc_factionDialogStart";
			tooltip = "Start the mission with selected settings";
		};
	};
};

// ============================================================================
// LEGACY ALIAS (for backward compatibility)
// ============================================================================

class factionselect_dialog2: FLO_FactionSelectDialog {};
