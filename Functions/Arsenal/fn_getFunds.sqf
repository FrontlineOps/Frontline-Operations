/*
    Function: FLO_fnc_getFunds
    
    Description: Gets the current funds from the money marker
    
    Parameter(s):
        None
        
    Returns:
        Number - Current funds available
*/

if (!isServer) exitWith {0};

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

_Money
