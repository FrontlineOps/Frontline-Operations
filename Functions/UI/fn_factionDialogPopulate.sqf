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
 * FLO_IDC_FACTION_COMBO_PLAYER     = 1955
 * FLO_IDC_FACTION_COMBO_ENEMY      = 1956
 * FLO_IDC_FACTION_COMBO_CIVILIAN   = 1957
 * FLO_IDC_FACTION_COMBO_WEST_ATTACK_COVERAGE = 1958
 * FLO_IDC_FACTION_COMBO_RESOURCES  = 1959
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
private _autoMilitaryFactions = _autoFactionIndex get "military";
private _autoCivilianFactions = _autoFactionIndex get "civilian";

// Helper function to add text-only items to a combo box
private _fnc_addItems = {
	params ["_ctrl", "_items", "_defaultIndex"];
	{
		_ctrl lbAdd _x;
	} forEach _items;
	_ctrl lbSetCurSel _defaultIndex;
};

private _fnc_addFactionItems = {
    params ["_ctrl", "_presets", "_autoEntries", "_defaultIndex"];

    {
        private _idx = _ctrl lbAdd _x;
        _ctrl lbSetData [_idx, format ["preset|%1", _x]];
    } forEach _presets;

    {
        private _idx = _ctrl lbAdd (_x get "label");
        _ctrl lbSetData [_idx, format ["auto|%1", _x get "class"]];
    } forEach _autoEntries;

    _ctrl lbSetCurSel _defaultIndex;
};

// ============================================================================
// PLAYER FACTION (IDC 1955)
// ============================================================================

private _playerCombo = _display displayCtrl 1955;
private _playerFactions = [
	"CUSTOM_PLAYER_FACTION",
	"NATO _ Desert",
	"AAF _ Woodland",
	"ADF _ Re-Cut",
	"BWMod _ RHSUSAF",
	"UAF _ CUP-UAFVP",
	"USMC _ Current Issue",
	"USMC _ CUP-EF"
];

[_playerCombo, _playerFactions, _autoMilitaryFactions, 1] call _fnc_addFactionItems;

// ============================================================================
// ENEMY FACTION (IDC 1956)
// ============================================================================

private _enemyCombo = _display displayCtrl 1956;
private _enemyFactions = [
	"CUSTOM_ENEMY_FACTION",
	"CSAT _ Desert",
	"Grozovia _ 3CB",
	"IAF _ CUP-EF",
	"Russian AF _ CUP"
];

[_enemyCombo, _enemyFactions, _autoMilitaryFactions, 1] call _fnc_addFactionItems;

// ============================================================================
// CIVILIAN FACTION (IDC 1957)
// ============================================================================

private _civilianCombo = _display displayCtrl 1957;
private _civilianFactions = [
	"CUSTOM_CIVILIAN_FACTION",
	"Greek Civilians"
];

[_civilianCombo, _civilianFactions, _autoCivilianFactions, 1] call _fnc_addFactionItems;

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
    "None _ 0 Groups Per Capture",
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
    [_display displayCtrl _x, _attackCoverageOptions, 1] call _fnc_addItems;
} forEach [1958, 1970];

{
    [_display displayCtrl _x, _defenseOpsOptions, 1] call _fnc_addItems;
} forEach [1962, 1971];

{
    [_display displayCtrl _x, _difficultyOptions, 1] call _fnc_addItems;
} forEach [1961, 1972];

{
    [_display displayCtrl _x, _tempoOptions, 2] call _fnc_addItems;
} forEach [1963, 1973];

{
    [_display displayCtrl _x, _forceGrowthOptions, 2] call _fnc_addItems;
} forEach [1966, 1974];

{
    [_display displayCtrl _x, _garrisonOptions, 1] call _fnc_addItems;
} forEach [1967, 1975];

// ============================================================================
// STARTING RESOURCES (IDC 1959)
// ============================================================================

private _resourcesCombo = _display displayCtrl 1959;
private _resourceOptions = ["50", "250", "500", "1000"];

[_resourcesCombo, _resourceOptions, 1] call _fnc_addItems;

// ============================================================================
// CIVILIAN STANDING (IDC 1960)
// ============================================================================

private _reputationCombo = _display displayCtrl 1960;
private _reputationOptions = [
	"Hostile _ Civilians Distrust Players",
	"Neutral _ Civilians Tolerate Players",
	"Friendly _ Civilians Support Players"
];

[_reputationCombo, _reputationOptions, 1] call _fnc_addItems;

// ============================================================================
// OBJECTIVE SIZE THRESHOLD (IDC 1964)
// ============================================================================

private _objectiveSizeCombo = _display displayCtrl 1964;
private _objectiveSizeOptions = ["Small", "Medium", "Large", "Huge"];

[_objectiveSizeCombo, _objectiveSizeOptions, 1] call _fnc_addItems;

// ============================================================================
// VIRTUALIZATION DISTANCE (IDC 1965)
// ============================================================================

private _virtualizationDistanceCombo = _display displayCtrl 1965;
private _virtualizationDistanceOptions = ["1000", "1500", "2000", "2500", "3000"];

[_virtualizationDistanceCombo, _virtualizationDistanceOptions, 2] call _fnc_addItems;

// ============================================================================
// ACTIVE AI CAP (IDC 1968)
// ============================================================================

private _virtualizationUnitCapCombo = _display displayCtrl 1968;
private _virtualizationUnitCapOptions = ["100", "150", "200", "250", "300", "350", "400"];

[_virtualizationUnitCapCombo, _virtualizationUnitCapOptions, 2] call _fnc_addItems;

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

[_territoryRatioCombo, _territoryRatioOptions, 4] call _fnc_addItems;

_playerCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl"];
    [ctrlParent _ctrl, "BLUFOR", 1955] call FLO_fnc_factionDialogFillCompositionDefaults;
}];

_enemyCombo ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl"];
    [ctrlParent _ctrl, "OPFOR", 1956] call FLO_fnc_factionDialogFillCompositionDefaults;
}];

[_display] call FLO_fnc_factionDialogCreateObjectiveGroupControls;
[_display, "BLUFOR", 1955] call FLO_fnc_factionDialogFillCompositionDefaults;
[_display, "OPFOR", 1956] call FLO_fnc_factionDialogFillCompositionDefaults;
["composition"] call FLO_fnc_factionDialogShowCompositionTab;

["UI", 3, format [
    "Faction dialog dropdowns populated (auto military=%1, auto civilian=%2)",
    count _autoMilitaryFactions,
    count _autoCivilianFactions
]] call FLO_fnc_log;

