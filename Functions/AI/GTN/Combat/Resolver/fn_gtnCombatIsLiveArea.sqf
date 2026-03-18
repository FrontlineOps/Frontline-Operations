/*
 * Function: FLO_fnc_gtnCombatIsLiveArea
 * Author: Frontline Operations Development Group
 * Description:
 *   Determines whether a combat zone is close enough to players to hand combat
 *   off to live AI.
 *
 * Arguments:
 *   0: Zone position <ARRAY>
 *   1: Relevant players <ARRAY>
 *   2: Live area radius <NUMBER>
 *
 * Return Value:
 *   Live handoff required <BOOL>
 */

params ["_zonePos", "_players", "_radius"];

private _playersNear = {
    (getPosATL _x) distance2D _zonePos <= _radius
} count _players;

_playersNear > 0
