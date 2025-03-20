/*
    Function: FLO_fnc_updateFunds
    
    Description: Updates the current funds by adding or subtracting the specified amount
    
    Parameter(s):
        _amount - Amount to add (positive) or subtract (negative) from current funds
        
    Returns:
        Number - New funds balance after update
*/

if (!isServer) exitWith {0};

params ["_amount"];

// Find money marker
private _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
if (count _mrkrs == 0) exitWith {
    diag_log "[FLO] ERROR: No money marker (Color2_FD_F) found on map";
    0
};

private _mrkr = _mrkrs select 0;
private _Money = 0;
private _markerText = markerText _mrkr;

if (_markerText != "") then {
    _Money = parseNumber _markerText;
};

// Calculate new money value
private _NewMoney = _Money + _amount;

// Update marker text
_mrkr setMarkerText str _NewMoney;

// Return new balance
_NewMoney
