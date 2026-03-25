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
 * FLO_IDC_FACTION_COMBO_PRESENCE   = 1958
 * FLO_IDC_FACTION_COMBO_RESOURCES  = 1959
 * FLO_IDC_FACTION_COMBO_REPUTATION = 1960
 * FLO_IDC_FACTION_COMBO_DIFFICULTY = 1961
 * FLO_IDC_FACTION_COMBO_GTN_DEFENSE = 1962
 * FLO_IDC_FACTION_COMBO_GTN_TEMPO = 1963
 * FLO_IDC_FACTION_COMBO_OBJ_SIZE = 1964
 * FLO_IDC_FACTION_COMBO_VIRT_DIST = 1965
 * FLO_IDC_FACTION_COMBO_GTN_FORCE_GROWTH = 1966
 * FLO_IDC_FACTION_COMBO_GTN_GARRISON = 1967
 * FLO_IDC_FACTION_COMBO_VIRT_UNIT_CAP = 1968
 */

disableSerialization;

private _display = uiNamespace getVariable ["FLO_FactionDialog", displayNull];
if (isNull _display) exitWith {
	["UI", 1, "Cannot populate faction dialog - display is null"] call FLO_fnc_log;
};

// Helper function to add items to a combo box
private _fnc_addItems = {
	params ["_ctrl", "_items", "_defaultIndex"];
	{
		_ctrl lbAdd _x;
	} forEach _items;
	_ctrl lbSetCurSel _defaultIndex;
};

// ============================================================================
// PLAYER FACTION (IDC 1955)
// ============================================================================

private _playerCombo = _display displayCtrl 1955;
private _playerFactions = [
	"CUSTOM_PLAYER_FACTION",
	"BAF _ Desert _ AEW",
	"BAF _ Woodland _ AEW",
	"GAF _ Desert _ BW",
	"GAF _ Woodland _ AEW",
	"GAF _ Woodland _ BW",
	"IAF _ Woodland _ AEW",
	"LDF _ Woodland _ AEW",
	"NATO _ Desert",
	"NATO _ Woodland",
	"SAF _ Woodland _ FFAA",
	"US _ Desert _ AEW",
	"US _ Desert _ CUP RHS",
	"US _ PFSOG",
	"US _ Woodland _ AEW",
	"US _ Woodland _ CUP RHS",
	"Western Sahara"
];

[_playerCombo, _playerFactions, 0] call _fnc_addItems;

// ============================================================================
// ENEMY FACTION (IDC 1956)
// ============================================================================

private _enemyCombo = _display displayCtrl 1956;
private _enemyFactions = [
	"CUSTOM_ENEMY_FACTION",
	"AAF _ Woodland",
	"Afghan AF _ CUP",
	"Afghan Insurgents _ CUP",
	"African Insurgents _ POF",
	"CSAT _ Desert",
	"CSAT _ Woodland",
	"East Europe Insurgents _ Desert _ AEW",
	"East Europe Insurgents _ Woodland _ AEW",
	"ISIS _ POF",
	"Iran AF _ POF",
	"LDF _ Woodland",
	"NVA _ PFSOG",
	"Russia AF _ Desert _ RHS",
	"Russia AF _ Woodland _ RHS",
	"SFF _ Desert _ Western Sahara",
	"Syndikat _ Woodland",
	"Syrian AF _ POF",
	"TTI _ Desert _ Western Sahara"
];

[_enemyCombo, _enemyFactions, 0] call _fnc_addItems;

// ============================================================================
// CIVILIAN FACTION (IDC 1957)
// ============================================================================

private _civilianCombo = _display displayCtrl 1957;
private _civilianFactions = [
	"CUSTOM_CIVILIAN_FACTION",
	"Asian Civilians",
	"East Europe Civilians",
	"East Europe Civilians _ CUP",
	"Greek Civilians",
	"Middle East Civilians _ CUP",
	"Tanoan Civilians",
	"Vietnamese Civilians",
	"Western Sahara Civilians"
];

[_civilianCombo, _civilianFactions, 0] call _fnc_addItems;

// ============================================================================
// AI COMMANDER ATTACK LANES (IDC 1958)
// ============================================================================

private _presenceCombo = _display displayCtrl 1958;
private _presenceOptions = [
	"Conservative",
	"Balanced",
	"Aggressive",
	"Relentless"
];

[_presenceCombo, _presenceOptions, 1] call _fnc_addItems;

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
// AI COMMANDER AGGRESSION (IDC 1961)
// ============================================================================

private _difficultyCombo = _display displayCtrl 1961;
private _difficultyOptions = [
	"LOW _ Cautious Commander",
	"MEDIUM _ Balanced Commander",
	"HIGH _ Aggressive Commander"
];

[_difficultyCombo, _difficultyOptions, 1] call _fnc_addItems;

// ============================================================================
// AI COMMANDER DEFENSE COVERAGE (IDC 1962)
// ============================================================================

private _defenseOpsCombo = _display displayCtrl 1962;
private _defenseOpsOptions = [
	"Minimal Coverage",
	"Balanced Coverage",
	"Layered Coverage",
	"Maximum Coverage"
];

[_defenseOpsCombo, _defenseOpsOptions, 1] call _fnc_addItems;

// ============================================================================
// AI COMMANDER TEMPO (IDC 1963)
// ============================================================================

private _tempoCombo = _display displayCtrl 1963;
private _tempoOptions = [
	"10s",
	"14s",
	"20s",
	"28s"
];

[_tempoCombo, _tempoOptions, 2] call _fnc_addItems;

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
// COMMANDER FORCE GROWTH (IDC 1966)
// ============================================================================

private _forceGrowthCombo = _display displayCtrl 1966;
private _forceGrowthOptions = [
    "None _ 0 Groups Per Capture",
    "Low _ 1 Group Per Capture",
    "Standard _ 2 Groups Per Capture",
    "High _ 3 Groups Per Capture"
];

[_forceGrowthCombo, _forceGrowthOptions, 2] call _fnc_addItems;

// ============================================================================
// BASELINE GARRISON (IDC 1967)
// ============================================================================

private _garrisonCombo = _display displayCtrl 1967;
private _garrisonOptions = [
    "Light _ 1 Rear / 2 Front",
    "Standard _ 2 Rear / 4 Front",
    "Heavy _ 3 Rear / 5 Front",
    "Fortified _ 4 Rear / 6 Front"
];

[_garrisonCombo, _garrisonOptions, 1] call _fnc_addItems;

["UI", 3, "Faction dialog dropdowns populated"] call FLO_fnc_log;

