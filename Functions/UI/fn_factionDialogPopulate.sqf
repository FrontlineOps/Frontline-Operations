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
// STARTING ZONES / Enemy Presence (IDC 1958)
// ============================================================================

private _presenceCombo = _display displayCtrl 1958;
private _presenceOptions = [
	"10% _ Small Operation",
	"30% _ Short Campaign",
	"50% _ Medium Campaign",
	"75% _ Long Campaign",
	"100% _ Dedi Servers with HCs"
];

[_presenceCombo, _presenceOptions, 4] call _fnc_addItems;

// ============================================================================
// STARTING RESOURCES (IDC 1959)
// ============================================================================

private _resourcesCombo = _display displayCtrl 1959;
private _resourceOptions = ["50", "250", "500", "1000"];

[_resourcesCombo, _resourceOptions, 1] call _fnc_addItems;

// ============================================================================
// STARTING REPUTATION (IDC 1960)
// ============================================================================

private _reputationCombo = _display displayCtrl 1960;
private _reputationOptions = [
	"LOW_Enemy to Guerillas",
	"MEDIUM_Neutral to Guerillas",
	"HIGH_Friendly to Guerillas"
];

[_reputationCombo, _reputationOptions, 1] call _fnc_addItems;

// ============================================================================
// STARTING DIFFICULTY (IDC 1961)
// ============================================================================

private _difficultyCombo = _display displayCtrl 1961;
private _difficultyOptions = [
	"EASY _ Low Enemy Presence _ progressive",
	"NORMAL _ Half Enemy Presence _ progressive",
	"HARD _ Full Enemy Presence _ progressive"
];

[_difficultyCombo, _difficultyOptions, 1] call _fnc_addItems;

["UI", 3, "Faction dialog dropdowns populated"] call FLO_fnc_log;

