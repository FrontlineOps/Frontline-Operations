/*
 * Function: FLO_fnc_revealRandomEnemyGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Reveals a random nearby OPFOR virtual group on the map. The logic
 *   mirrors the civilian intel reveal, but uses the military intel
 *   notification string.
 * Parameters:
 *   0: Center object or position (default: player)
 *   1: Search radius in meters (default: 2000)
 *   2: Notification stringtable key (default: "STR_FLO_INTEL_MIL")
 * Returns: Grid string of revealed group
 */

params [ ["_center", player], ["_radius", 2000], ["_msg", "STR_FLO_INTEL_MIL"] ];

if (isNil "FLO_virtualGroups") exitWith {};

private _centerPos = if (typeName _center == "OBJECT") then { position _center } else { _center };

private _groupsMap = FLO_virtualGroups get "_groups";
private _chosenId = "";
private _chosenData = createHashMap;
private _matchCount = 0;

{
    private _data = _y;
    private _pos = _data get "position";
    if ((_data get "side") != east) then { continue };
    if ((_pos distance2D _centerPos) > _radius) then { continue };

    _matchCount = _matchCount + 1;
    if ((floor random _matchCount) == 0) then {
        _chosenId = _x;
        _chosenData = _data;
    };
} forEach _groupsMap;

if (_matchCount isEqualTo 0) exitWith {
    ["STR_FLO_INTEL_NONE", "info"] call FLO_fnc_sendNotification;
};

private _gpos = _chosenData get "position";

private _markerBase = format ["milIntel_%1_%2", _chosenId, floor diag_tickTime];
private _mrkGrp = createMarkerLocal [_markerBase, _gpos];
_mrkGrp setMarkerTypeLocal "o_unknown";
_mrkGrp setMarkerColorLocal "colorOPFOR";
_mrkGrp setMarkerSizeLocal [0.8,0.8];
_mrkGrp setMarkerAlpha 1;

private _markers = [_mrkGrp];
private _wpts = _chosenData get "waypoints";
{
    private _wName = format ["%1_wp_%2", _markerBase, _forEachIndex];
    private _wpPos = _x select 0;
    private _wMark = createMarkerLocal [_wName, _wpPos];
    _wMark setMarkerTypeLocal "hd_dot";
    _wMark setMarkerColorLocal "colorOPFOR";
    _wMark setMarkerSizeLocal [0.5,0.5];
    _wMark setMarkerAlpha 1;
    _markers pushBack _wMark;
} forEach _wpts;

[_markers] spawn {
    params ["_marks"]; 
    private _steps = 10;
    for "_i" from 1 to _steps do {
        private _a = 1 - (_i / _steps);
        { _x setMarkerAlpha _a; } forEach _marks;
        sleep 6;
    };
    { deleteMarker _x; } forEach _marks;
};

private _grid = mapGridPosition _gpos;
[[_msg, _grid], "info"] call FLO_fnc_sendNotification;
_grid
