/*
 * Function: FLO_fnc_revealArtilleryBattery
 * Author: Frontline Operations Development Group
 * Description:
 *   Reveals an active OPFOR artillery battery on the map with firing range circle.
 *   Integrates with virtual groups to find artillery assets.
 *
 * Parameters:
 *   0: Center position for search (ARRAY) - Default: player position
 *   1: Search radius in meters (NUMBER) - Default: 5000
 *
 * Returns:
 *   BOOLEAN - true if battery revealed, false if none found
 */

params [["_center", getPos player], ["_radius", 5000]];

if (isNil "FLO_virtualGroups") exitWith { 
    ["Intelligence systems offline", "warning"] call FLO_fnc_sendNotification;
    false 
};

private _centerPos = if (typeName _center == "OBJECT") then { getPos _center } else { _center };

// Find artillery virtual groups
private _artilleryGroups = [];
{
    private _gid = _x;
    private _gData = _y;
    private _groupType = _gData getOrDefault ["groupType", ""];
    private _side = _gData getOrDefault ["side", east];
    
    if (_side == east && {_groupType in ["artillery", "mortar", "mlrs"]}) then {
        private _pos = _gData get "position";
        if (_pos distance _centerPos < _radius) then {
            _artilleryGroups pushBack [_gid, _gData];
        };
    };
} forEach (FLO_virtualGroups get "_groups");

if (count _artilleryGroups == 0) exitWith { 
    ["No artillery batteries detected in range", "info"] call FLO_fnc_sendNotification;
    false 
};

private _chosen = selectRandom _artilleryGroups;
_chosen params ["_gid", "_gdata"];
private _pos = _gdata get "position";

// Add slight position randomization (intel isn't perfect)
private _revealPos = _pos getPos [50 + random 100, random 360];

// Create position marker
private _mrkId = format ["artyIntel_%1_%2", _gid, floor diag_tickTime];
private _mrkPos = createMarkerLocal [_mrkId, _revealPos];
_mrkPos setMarkerTypeLocal "mil_warning";
_mrkPos setMarkerColorLocal "colorOPFOR";
_mrkPos setMarkerText "Artillery";
_mrkPos setMarkerAlpha 1;

// Create range circle (800m typical arty range)
private _mrkRangeId = format ["%1_range", _mrkId];
private _mrkRange = createMarkerLocal [_mrkRangeId, _revealPos];
_mrkRange setMarkerShapeLocal "ELLIPSE";
_mrkRange setMarkerSizeLocal [800, 800];
_mrkRange setMarkerColorLocal "colorOPFOR";
_mrkRange setMarkerAlpha 0.2;
_mrkRange setMarkerBrush "DiagGrid";

// Fade markers over 90 seconds
[[_mrkPos, _mrkRange]] spawn {
    params ["_markers"];
    sleep 60;
    private _steps = 10;
    for "_i" from 1 to _steps do {
        private _a = 1 - (_i / _steps);
        { _x setMarkerAlpha (_a * 0.8) } forEach _markers;
        sleep 3;
    };
    { deleteMarker _x } forEach _markers;
};

private _grid = mapGridPosition _revealPos;
[format ["Artillery battery located at grid %1", _grid], "warning"] call FLO_fnc_sendNotification;
["INTEL", 3, format["Revealed artillery at %1", _grid]] call FLO_fnc_log;

true
