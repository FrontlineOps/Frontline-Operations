/*
 * Function: FLO_fnc_findRoadPathSync
 * Author: Frontline Operations Development Group
 * Description:
 *   Synchronous wrapper for FLO_fnc_findRoadPath. Waits for completion
 *   and returns the resulting waypoint position array.
 *
 * Arguments:
 *   0: Start position <ARRAY>
 *   1: End position <ARRAY>
 *   2: Include Trails <BOOL> (optional, default false)
 *
 * Returns:
 *   Array of positions representing the path
 *
 * Example:
 *   private _path = [_start,_end] call FLO_fnc_findRoadPathSync;
 */

params [ ["_startPos", [0,0,0], [[]] ], ["_endPos", [0,0,0], [[]] ], ["_trails", false, [true]] ];

// Ensure both positions have nearby roads or fail fast
private _hasRoad = {
    params ["_pos"];
    private _road = objNull;
    {
        private _rds = nearestTerrainObjects [_pos, ["MAIN ROAD","ROAD","TRACK","TRAIL"], _x, true];
        if (count _rds > 0) exitWith { _road = _rds#0 };
    } forEach [50,100,500,1000];
    !isNull _road
};

if !([_startPos] call _hasRoad) exitWith { [] };
if !([_endPos] call _hasRoad) exitWith { [] };

private _doneVar = format ["FLO_PF_done_%1", diag_tickTime];
private _pathVar = format ["FLO_PF_path_%1", diag_tickTime];
missionNamespace setVariable [_doneVar, false];
missionNamespace setVariable [_pathVar, []];

private _cb = {
    params ["_status","_posArray","_args"];
    _args params ["_pVar","_dVar"];
    missionNamespace setVariable [_pVar, _posArray];
    missionNamespace setVariable [_dVar, true];
};

[_startPos,_endPos,_cb,[_pathVar,_doneVar],_trails] call FLO_fnc_findRoadPath;

waitUntil { missionNamespace getVariable [_doneVar, false] };
private _result = missionNamespace getVariable [_pathVar, []];
missionNamespace setVariable [_doneVar, nil];
missionNamespace setVariable [_pathVar, nil];
_result
