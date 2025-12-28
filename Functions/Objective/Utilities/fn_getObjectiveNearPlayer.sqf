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
if (count _keys == 0) exitWith { "" };

private _players = allPlayers;
if (count _players == 0) exitWith { [_refPos, _filterSide] call FLO_fnc_getNearestObjective };

// Filter objectives near any player within _maxDist
private _nearbyIds = _keys select {
    private _data = FLO_Objectives get _x;
    if (isNil "_data") exitWith { false };

    // Filter by side if specified
    if (!isNil "_filterSide") then {
        private _owner = _data getOrDefault ["owner", east];
        if !(_owner isEqualTo _filterSide) exitWith { false };
        true
    } else {
        true
    } && {
        private _pos = _data get "position";
        // Check if any player is within range
        ({ _pos distance2D (getPos _x) <= _maxDist } count _players) > 0
    }
};

if (count _nearbyIds > 0) exitWith { selectRandom _nearbyIds };

// Fallback: nearest objective to _refPos
[_refPos, _filterSide] call FLO_fnc_getNearestObjective
