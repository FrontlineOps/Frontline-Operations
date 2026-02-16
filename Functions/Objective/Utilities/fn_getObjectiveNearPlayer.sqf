/*
 * Function: FLO_fnc_getObjectiveNearPlayer
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects an objective close to any player, with a configurable max distance.
 *   Falls back to the nearest objective to a reference position if none are within range.
 *   Optionally filters by owner side.
 *
 * Arguments:
 *   0: Max distance from any player (NUMBER) - Default: 4000
 *   1: Reference position for fallback (ARRAY) - Default: center of map
 *   2: Filter by owner side (SIDE) - Optional, nil for any side
 *
 * Returns:
 *   STRING - Objective ID, or "" if none available
 *
 * Examples:
 *   [] call FLO_fnc_getObjectiveNearPlayer;
 *   [4000, getPos player] call FLO_fnc_getObjectiveNearPlayer;
 *   [4000, getPos player, east] call FLO_fnc_getObjectiveNearPlayer;
 */

params [
    ["_maxDist", 4000],
    ["_refPos", [worldSize/2, worldSize/2, 0]],
    ["_filterSide", nil]
];

if (isNil "FLO_Objectives") exitWith { "" };

private _keys = keys FLO_Objectives;
if ((count _keys) == 0) exitWith { "" };

private _players = allPlayers;
if ((count _players) == 0) exitWith { [_refPos, _filterSide] call FLO_fnc_getNearestObjective };

// Filter objectives near any player within _maxDist
private _nearbyIds = [];
{
    private _objId = _x;
    private _data = FLO_Objectives get _objId;
    private _pos = _data get "position";

    if (!isNil "_filterSide") then {
        private _owner = _data get "owner";
        if (_owner isEqualType "") then {
            private _ownerKey = toUpper _owner;
            if (_ownerKey isEqualTo "EAST") then { _owner = east; };
            if (_ownerKey isEqualTo "WEST") then { _owner = west; };
        };
        if !(_owner isEqualTo _filterSide) then { continue };
    };

    if (({ _pos distance2D (getPos _x) <= _maxDist } count _players) > 0) then {
        _nearbyIds pushBack _objId;
    };
} forEach _keys;

if ((count _nearbyIds) > 0) exitWith {
    selectRandom _nearbyIds
};

// Fallback: nearest objective to _refPos
[_refPos, _filterSide] call FLO_fnc_getNearestObjective
