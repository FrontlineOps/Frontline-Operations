/*
 * Function: FLO_fnc_virtualizationSetPendingPathRequest
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies canonical pending path-request state to a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Token <NUMBER>
 * 2: Target position <ARRAY>
 * 3: Allow trails <BOOL>
 * 4: Started at <NUMBER>
 * 5: Source tag <STRING>
 * 6: Waypoint settings <ARRAY>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_token", "_targetPos", "_allowTrails", "_startedAt", "_sourceTag", "_waypointSettings"];

_groupData set ["pathToken", _token];
_groupData set ["pathTargetPos", _targetPos];
_groupData set ["pathAllowTrails", _allowTrails];
_groupData set ["pathStartedAt", _startedAt];
_groupData set ["pathSource", _sourceTag];
_groupData set ["pathWaypointSettings", _waypointSettings];

true
