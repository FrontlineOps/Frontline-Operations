/*
 * Function: FLO_fnc_virtualizationCanAutoPatrol
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether a virtual group is allowed to use persistent auto-patrol.
 */

params ["_groupData"];

private _groupType = _groupData get "groupType";
if !(_groupType in ["infantry", "motorized", "mechanized", "armor"]) exitWith { false };
if (_groupData get "noWaypoints") exitWith { false };
if ((_groupData get "replacementState") != "") exitWith { false };
if ((_groupData get "missionLock") != "") exitWith { false };
if ((_groupData get "attachedTo") != "") exitWith { false };
if ((_groupData get "mountedIn") != "") exitWith { false };
if ([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) exitWith { false };

true
