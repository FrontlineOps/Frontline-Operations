/**
 * Function: FLO_fnc_addReward
 * 
 * Description:
 * Adds specified amount to the player's reward/money counter.
 * The money value is stored in a marker with color "Color2_FD_F".
 *
 * Parameters:
 * _this select 0: NUMBER - The amount to add to the reward counter
 *
 * Returns:
 * NUMBER - The new money value after adding the reward
 *
 * Example:
 * [100] call FLO_fnc_addReward;
 */

if (!isServer) exitWith {}; // Only execute on server

// Check parameters
params [["_RWRD", 0, [0]]];

// Find money marker
private _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
if (count _mrkrs == 0) exitWith {
    diag_log "[FLO] ERROR: No money marker (Color2_FD_F) found on map";
    0
};

// Get marker and current money value
private _mrkr = _mrkrs select 0;
private _Money = 0;
private _markerText = markerText _mrkr;

// Try to parse current money value
if (_markerText != "") then {
    _Money = parseNumber _markerText;
};

// Calculate new money value
private _NewMoney = _Money + _RWRD;

// Update marker text
_mrkr setMarkerText str _NewMoney;

// Return new balance
_NewMoney 