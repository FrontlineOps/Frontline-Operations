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

private _groups = FLO_virtualGroups get "_groups";
private _chosenId = "";
private _chosenData = createHashMap;
private _matchCount = 0;

if (!isNil "FLO_GTNArtilleryManager") then {
    private _cache = (FLO_GTNArtilleryManager get "artilleryGroupsBySide") get "EAST";
    {
        if !(_x in _groups) then { continue };

        private _gData = _groups get _x;
        private _pos = _gData get "position";
        if ((_pos distance2D _centerPos) > _radius) then { continue };

        _matchCount = _matchCount + 1;
        if ((floor random _matchCount) == 0) then {
            _chosenId = _x;
            _chosenData = _gData;
        };
    } forEach (keys _cache);
} else {
    {
        private _gData = _y;
        if ((_gData get "side") != east) then { continue };
        if !((_gData get "groupType") in ["artillery", "mortar", "mlrs"]) then { continue };

        private _pos = _gData get "position";
        if ((_pos distance2D _centerPos) > _radius) then { continue };

        _matchCount = _matchCount + 1;
        if ((floor random _matchCount) == 0) then {
            _chosenId = _x;
            _chosenData = _gData;
        };
    } forEach _groups;
};

if (_matchCount isEqualTo 0) exitWith {
    ["No artillery batteries detected in range", "info"] call FLO_fnc_sendNotification;
    false
};

private _pos = _chosenData get "position";

// Add slight position randomization (intel isn't perfect)
private _revealPos = _pos getPos [50 + random 100, random 360];

// Create position marker
private _mrkId = format ["artyIntel_%1_%2", _chosenId, floor diag_tickTime];
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
