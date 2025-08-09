/*
 * Function: FLO_fnc_getObjectiveNearPlayer
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects an objective close to any player, with a configurable max distance,
 *   and falls back to the nearest objective to a reference position if none are within range.
 *
 * Arguments:
 *   0: max distance from any player to consider "near" <NUMBER> (default: 4000)
 *   1: reference position for fallback nearest search <ARRAY> (default: center of map)
 *
 * Returns:
 *   Objective ID <STRING> or empty string if none available
 *
 * Example:
 *   private _objId = [4000, getPos player] call FLO_fnc_getObjectiveNearPlayer;
 */

params [
    ["_maxDist", 4000],
    ["_refPos", [worldSize/2, worldSize/2, 0]]
];

if (isNil "FLO_Objectives") exitWith {""};
private _keys = keys FLO_Objectives;
if ((count _keys) == 0) exitWith {""};

private _players = allPlayers;

// Filter objectives near any player within _maxDist
private _nearbyIds = _keys select {
    private _data = FLO_Objectives get _x;
    if (isNil "_data") exitWith {false};
    private _pos = _data get "position";
    ({ _pos distance2D (getPos _x) <= _maxDist } count _players) > 0
};

if ((count _nearbyIds) > 0) exitWith { selectRandom _nearbyIds };

// Fallback: nearest objective to _refPos
[_refPos] call FLO_fnc_getNearestObjective
