/*
 * Function: FLO_fnc_civilianIntel
 * Author: Frontline Operations Development Group
 * Description:
 * Provides civilian-provided intel on a nearby OPFOR virtual group. If the
 * group has assigned waypoints, temporary markers are created for both the
 * group and its waypoints which gradually fade out. * Arguments: None
 * Returns: Nothing
 * Usage: [] call FLO_fnc_civilianIntel;
 */

params [];

// Small delay to mimic search time
sleep 2;
// Ensure virtualization system is available
if (isNil "FLO_virtualGroups") exitWith {};

private _searchRadius = 2000;      // Radius to look for groups around player
private _groupsMap = FLO_virtualGroups get "_groups";
private _nearGroups = [];

// Collect nearby OPFOR virtual groups
{
    private _groupId = _x;
    private _data = _y;
    private _pos = _data get "position";
    private _side = _data getOrDefault ["side", east];
    if (_side == east && { _pos distance player <= _searchRadius }) then {
        _nearGroups pushBack [_groupId, _data];
    };
} forEach _groupsMap;

// No virtual groups nearby? Civilian has nothing useful
if (count _nearGroups isEqualTo 0) exitWith {
    ["STR_FLO_INTEL_TITLE", "STR_FLO_INTEL_NONE", "info"] call FLO_fnc_sendNotification;
};

// Random chance the civilian doesn't know anything
private _noIntelChance = 0.25; // 25% chance
if (random 1 < _noIntelChance) exitWith {
    ["STR_FLO_INTEL_TITLE", "STR_FLO_INTEL_NONE", "info"] call FLO_fnc_sendNotification;
};

// Select a random nearby group
private _chosen = selectRandom _nearGroups;
_chosen params ["_gid", "_gdata"];
private _gpos = _gdata get "position";

// Determine marker names
private _markerBase = format ["civIntel_%1_%2", _gid, floor diag_tickTime];
private _mrkGrp = createMarkerLocal [_markerBase, _gpos];
_mrkGrp setMarkerTypeLocal "o_unknown";
_mrkGrp setMarkerColorLocal "colorOPFOR";
_mrkGrp setMarkerSizeLocal [0.8,0.8];
_mrkGrp setMarkerAlpha 1;

private _markers = [_mrkGrp];

// Create waypoint markers if present
private _wpts = _gdata getOrDefault ["waypoints", []];
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

// Fade markers out over 60 seconds
[_markers] spawn {
    params ["_marks"];
    private _steps = 10;
    for "_i" from 1 to _steps do {
        private _alpha = 1 - (_i / _steps);
        { _x setMarkerAlpha _alpha; } forEach _marks;
        sleep 6;
    };
    { deleteMarker _x; } forEach _marks;
};

private _grid = mapGridPosition _gpos;
["STR_FLO_INTEL_TITLE", ["STR_FLO_INTEL_CIV", _grid], "info"] call FLO_fnc_sendNotification;