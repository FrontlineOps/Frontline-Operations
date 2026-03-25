/*
 * Function: FLO_fnc_virtualizationRestoreSavedGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores the canonical saved virtualization schema onto a newly created
 *   virtual-group record.
 *
 * Arguments:
 * 0: Live group data <HASHMAP>
 * 1: Saved group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when restore completed
 */

params ["_groupData", "_savedData"];

[_groupData, _savedData get "state"] call FLO_fnc_virtualizationSetRuntimeState;
_groupData set ["spawnClass", _savedData get "spawnClass"];
[_groupData, _savedData get "comp"] call FLO_fnc_virtualizationSetAssetComposition;
_groupData set ["waypoints", _savedData get "waypoints"];
_groupData set ["currentWaypointIndex", _savedData get "currentWaypointIndex"];
_groupData set ["autoPatrol", _savedData get "autoPatrol"];
_groupData set ["patrolConfig", _savedData get "patrolConfig"];
_groupData set ["alwaysActive", _savedData get "alwaysActive"];
_groupData set ["noWaypoints", _savedData get "noWaypoints"];
_groupData set ["forceVirtual", _savedData get "forceVirtual"];
_groupData set ["organicPackageRole", _savedData get "organicPackageRole"];
_groupData set ["organicPackageParentGroupId", _savedData get "organicPackageParentGroupId"];

[_groupData, _savedData] call FLO_fnc_virtualizationRestoreMissionState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreCommanderState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestorePathState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreAAState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreTransportState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreReplacementState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreEngagementState;

true

