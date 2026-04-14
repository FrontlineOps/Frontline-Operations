/*
 * Function: FLO_fnc_virtualizationClearPathRequest
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears canonical pending path-request state from a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when the state was cleared
 */

params ["_groupData"];

_groupData set ["pathToken", -1];
_groupData set ["pathTargetPos", []];
_groupData set ["pathAllowTrails", false];
_groupData set ["pathStartedAt", -1];
_groupData set ["pathSource", ""];
_groupData set ["pathWaypointSettings", []];

true
