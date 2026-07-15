/*
 * Function: FLO_fnc_factionDialogPopulate
 * Author: Frontline Operations
 *
 * Description:
 * Populates all dropdown controls in the Faction Selection Dialog.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call FLO_fnc_factionDialogPopulate;
 *
 * IDC Reference (from UI/constants.hpp):
 * FLO_IDC_FACTION_COMBO_BLUFOR     = 1955
 * FLO_IDC_FACTION_COMBO_OPFOR      = 1956
 * FLO_IDC_FACTION_COMBO_CIVILIAN   = 1957
 * FLO_IDC_FACTION_COMBO_WEST_ATTACK_COVERAGE = 1958
 * FLO_IDC_FACTION_COMBO_PLAYER_SIDE = 1959
 * FLO_IDC_FACTION_COMBO_REPUTATION = 1960
 * FLO_IDC_FACTION_COMBO_WEST_AGGRESSION = 1961
 * FLO_IDC_FACTION_COMBO_WEST_DEFENSE_COVERAGE = 1962
 * FLO_IDC_FACTION_COMBO_WEST_TEMPO = 1963
 * FLO_IDC_FACTION_COMBO_OBJ_SIZE = 1964
 * FLO_IDC_FACTION_COMBO_VIRT_DIST = 1965
 * FLO_IDC_FACTION_COMBO_WEST_FORCE_GROWTH = 1966
 * FLO_IDC_FACTION_COMBO_WEST_GARRISON = 1967
 * FLO_IDC_FACTION_COMBO_VIRT_UNIT_CAP = 1968
 * FLO_IDC_FACTION_COMBO_TERRITORY_RATIO = 1969
 * FLO_IDC_FACTION_COMBO_EAST_ATTACK_COVERAGE = 1970
 * FLO_IDC_FACTION_COMBO_EAST_DEFENSE_COVERAGE = 1971
 * FLO_IDC_FACTION_COMBO_EAST_AGGRESSION = 1972
 * FLO_IDC_FACTION_COMBO_EAST_TEMPO = 1973
 * FLO_IDC_FACTION_COMBO_EAST_FORCE_GROWTH = 1974
 * FLO_IDC_FACTION_COMBO_EAST_GARRISON = 1975
 * FLO_IDC_FACTION_EDIT_*_COMPOSITION = 2050-2093
 */

disableSerialization;

private _display = uiNamespace getVariable ["FLO_FactionDialog", displayNull];
if (isNull _display) exitWith {
	["UI", 1, "Cannot populate faction dialog - display is null"] call FLO_fnc_log;
};

private _autoFactionIndex = [] call FLO_fnc_factionBuildAutoIndex;
private _autoBluforFactions = _autoFactionIndex get "blufor";
private _autoOpforFactions = _autoFactionIndex get "opfor";
private _autoCivilianFactions = _autoFactionIndex get "civilian";
private _bluforDefaultIndex = parseNumber (_autoBluforFactions isNotEqualTo []);
private _opforDefaultIndex = parseNumber (_autoOpforFactions isNotEqualTo []);
private _civilianDefaultIndex = parseNumber (_autoCivilianFactions isNotEqualTo []);

private _bluforCustom = ["blufor"] call FLO_fnc_factionGetCustomDefinition;
private _opforCustom = ["opfor"] call FLO_fnc_factionGetCustomDefinition;
private _civilianCustom = ["civilian"] call FLO_fnc_factionGetCustomDefinition;

// ============================================================================
// BLUFOR FACTION (IDC 1955)
// ============================================================================

private _bluforCombo = _display displayCtrl 1955;
private _bluforFactions = [_bluforCustom select 0];

[_bluforCombo, _bluforFactions, _autoBluforFactions, _bluforDefaultIndex] call FLO_fnc_factionDialogAddFactionItems;

// ============================================================================
// OPFOR FACTION (IDC 1956)
// ============================================================================

private _opforCombo = _display displayCtrl 1956;
private _opforFactions = [_opforCustom select 0];

[_opforCombo, _opforFactions, _autoOpforFactions, _opforDefaultIndex] call FLO_fnc_factionDialogAddFactionItems;

// ============================================================================
// CIVILIAN FACTION (IDC 1957)
// ============================================================================

private _civilianCombo = _display displayCtrl 1957;
private _civilianFactions = [_civilianCustom select 0];

[_civilianCombo, _civilianFactions, _autoCivilianFactions, _civilianDefaultIndex] call FLO_fnc_factionDialogAddFactionItems;

private _playerSideDefault = parseNumber ((side group player) isEqualTo east);
[_display displayCtrl 1959, ["BLUFOR", "OPFOR"], _playerSideDefault] call FLO_fnc_factionDialogAddItems;

// ============================================================================
// AI COMMANDER POSTURE OPTIONS
// ============================================================================

private _attackCoverageOptions = [
	"Minimal Coverage",
	"Balanced Coverage",
	"Layered Coverage",
	"Maximum Coverage"
];

private _difficultyOptions = [
	"LOW _ Cautious Commander",
	"MEDIUM _ Balanced Commander",
	"HIGH _ Aggressive Commander"
];

private _defenseOpsOptions = [
	"Minimal Coverage",
	"Balanced Coverage",
	"Layered Coverage",
	"Maximum Coverage"
];

private _tempoOptions = [
	"10s",
	"14s",
	"20s",
	"28s"
];

private _forceGrowthOptions = [
    "Low _ 1 Group Per Capture",
    "Standard _ 2 Groups Per Capture",
    "High _ 3 Groups Per Capture"
];

private _garrisonOptions = [
    "Light _ 1 Rear / 2 Front",
    "Standard _ 1 Rear / 3 Front",
    "Heavy _ 2 Rear / 3 Front",
    "Fortified _ 2 Rear / 4 Front"
];

{
    [_display displayCtrl _x, _attackCoverageOptions, 1] call FLO_fnc_factionDialogAddItems;
} forEach [1958, 1970];

{
    [_display displayCtrl _x, _defenseOpsOptions, 1] call FLO_fnc_factionDialogAddItems;
} forEach [1962, 1971];

{
    [_display displayCtrl _x, _difficultyOptions, 1] call FLO_fnc_factionDialogAddItems;
} forEach [1961, 1972];

{
    [_display displayCtrl _x, _tempoOptions, 2] call FLO_fnc_factionDialogAddItems;
} forEach [1963, 1973];

{
    [_display displayCtrl _x, _forceGrowthOptions, 1] call FLO_fnc_factionDialogAddItems;
} forEach [1966, 1974];

{
    [_display displayCtrl _x, _garrisonOptions, 1] call FLO_fnc_factionDialogAddItems;
} forEach [1967, 1975];

// ============================================================================
// CIVILIAN STANDING (IDC 1960)
// ============================================================================

private _reputationCombo = _display displayCtrl 1960;
private _reputationOptions = [
	"Hostile _ Civilians Distrust Players",
	"Neutral _ Civilians Tolerate Players",
	"Friendly _ Civilians Support Players"
];

[_reputationCombo, _reputationOptions, 1] call FLO_fnc_factionDialogAddItems;

// ============================================================================
// OBJECTIVE SIZE THRESHOLD (IDC 1964)
// ============================================================================

private _objectiveSizeCombo = _display displayCtrl 1964;
private _objectiveSizeOptions = ["Small", "Medium", "Large", "Huge"];

[_objectiveSizeCombo, _objectiveSizeOptions, 1] call FLO_fnc_factionDialogAddItems;

// ============================================================================
// VIRTUALIZATION DISTANCE (IDC 1965)
// ============================================================================

private _virtualizationDistanceCombo = _display displayCtrl 1965;
private _virtualizationDistanceOptions = ["1000", "1500", "2000", "2500", "3000"];

[_virtualizationDistanceCombo, _virtualizationDistanceOptions, 2] call FLO_fnc_factionDialogAddItems;

// ============================================================================
// ACTIVE AI CAP (IDC 1968)
// ============================================================================

private _virtualizationUnitCapCombo = _display displayCtrl 1968;
private _virtualizationUnitCapOptions = ["100", "150", "200", "250", "300", "350", "400"];

[_virtualizationUnitCapCombo, _virtualizationUnitCapOptions, 2] call FLO_fnc_factionDialogAddItems;

// ============================================================================
// STARTING TERRITORY RATIO (IDC 1969)
// ============================================================================

private _territoryRatioCombo = _display displayCtrl 1969;
private _territoryRatioOptions = [
    "10% BLUFOR / 90% OPFOR",
    "20% BLUFOR / 80% OPFOR",
    "30% BLUFOR / 70% OPFOR",
    "40% BLUFOR / 60% OPFOR",
    "50% BLUFOR / 50% OPFOR",
    "60% BLUFOR / 40% OPFOR",
    "70% BLUFOR / 30% OPFOR",
    "80% BLUFOR / 20% OPFOR",
    "90% BLUFOR / 10% OPFOR"
];

[_territoryRatioCombo, _territoryRatioOptions, 4] call FLO_fnc_factionDialogAddItems;

_bluforCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_selectedIndex"];
    [_ctrl, _selectedIndex] call FLO_fnc_factionDialogNormalizeMultiSelection;
    [ctrlParent _ctrl, "BLUFOR", 1955] call FLO_fnc_factionDialogFillCompositionDefaults;
}];

_opforCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_selectedIndex"];
    [_ctrl, _selectedIndex] call FLO_fnc_factionDialogNormalizeMultiSelection;
    [ctrlParent _ctrl, "OPFOR", 1956] call FLO_fnc_factionDialogFillCompositionDefaults;
}];

_civilianCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_selectedIndex"];
    [_ctrl, _selectedIndex] call FLO_fnc_factionDialogNormalizeMultiSelection;
}];

[_display] call FLO_fnc_factionDialogCreateObjectiveGroupControls;
[_display, "BLUFOR", 1955] call FLO_fnc_factionDialogFillCompositionDefaults;
[_display, "OPFOR", 1956] call FLO_fnc_factionDialogFillCompositionDefaults;
["composition"] call FLO_fnc_factionDialogShowCompositionTab;

["UI", 3, format [
    "Faction dialog dropdowns populated (BLUFOR=%1, OPFOR=%2, civilian=%3)",
    count _autoBluforFactions,
    count _autoOpforFactions,
    count _autoCivilianFactions
]] call FLO_fnc_log;

