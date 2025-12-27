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
private _playerFactions = ["CUSTOM_PLAYER_FACTION"];

// Add mod-dependent factions (commented out for now, can be enabled)
// if (isClass (configFile >> "CfgFactionClasses" >> "BLU_NATO_lxWS")) then {
//     _playerFactions pushBack "NATO Forces _ Desert _ Western Sahara";
// };

[_playerCombo, _playerFactions, 0] call _fnc_addItems;

// ============================================================================
// ENEMY FACTION (IDC 1956)
// ============================================================================

private _enemyCombo = _display displayCtrl 1956;
private _enemyFactions = ["CUSTOM_ENEMY_FACTION"];

[_enemyCombo, _enemyFactions, 0] call _fnc_addItems;

// ============================================================================
// CIVILIAN FACTION (IDC 1957)
// ============================================================================

private _civilianCombo = _display displayCtrl 1957;
private _civilianFactions = ["CUSTOM_CIVILIAN_FACTION"];

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

