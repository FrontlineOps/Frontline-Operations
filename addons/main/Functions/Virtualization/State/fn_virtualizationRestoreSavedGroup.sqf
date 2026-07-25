/*
 * Function: FLO_fnc_virtualizationRestoreSavedGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores the canonical saved virtualization schema onto a newly created
 *   virtual-group record.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Saved group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when restore completed
 */

params ["_groupId", "_savedData"];

[_savedData, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;

private _alwaysActive = _savedData get "alwaysActive";
private _civilianRoutineState = _savedData get "civilianRoutineState";
private _civilianRoutineUntil = _savedData get "civilianRoutineUntil";

if (_civilianRoutineState == "protest") then {
    _alwaysActive = false;
    _civilianRoutineState = "return";
    _civilianRoutineUntil = -1;
};

[_groupData, _savedData get "state"] call FLO_fnc_virtualizationSetRuntimeState;
_groupData set ["spawnPosition", +(_savedData get "spawnPosition")];
_groupData set ["direction", _savedData get "direction"];
_groupData set ["spawnClass", _savedData get "spawnClass"];
_groupData set ["combatExperience", _savedData get "combatExperience"];
[_groupData, _savedData get "comp"] call FLO_fnc_virtualizationSetAssetComposition;
_groupData set ["waypoints", _savedData get "waypoints"];
_groupData set ["currentWaypointIndex", _savedData get "currentWaypointIndex"];
_groupData set ["lastMoveTime", diag_tickTime];
_groupData set ["virtualMoveCarryMeters", 0];
[_groupData] call FLO_fnc_virtualizationRefreshCurrentWaypointSpeed;
_groupData set ["autoPatrol", _savedData get "autoPatrol"];
_groupData set ["patrolConfig", _savedData get "patrolConfig"];
_groupData set ["alwaysActive", _alwaysActive];
_groupData set ["noWaypoints", _savedData get "noWaypoints"];
_groupData set ["forceVirtual", _savedData get "forceVirtual"];
_groupData set ["organicPackageRole", _savedData get "organicPackageRole"];
_groupData set ["organicPackageParentGroupId", _savedData get "organicPackageParentGroupId"];
_groupData set ["civilianRole", _savedData get "civilianRole"];
_groupData set ["civilianObjective", _savedData get "civilianObjective"];
_groupData set ["civilianAnchorPos", _savedData get "civilianAnchorPos"];
_groupData set ["civilianHomeAnchorPos", _savedData get "civilianHomeAnchorPos"];
_groupData set ["civilianRoutineAnchorPos", _savedData get "civilianRoutineAnchorPos"];
_groupData set ["civilianRouteAnchors", _savedData get "civilianRouteAnchors"];
_groupData set ["civilianKnowledgeBias", _savedData get "civilianKnowledgeBias"];
_groupData set ["civilianTrustBias", _savedData get "civilianTrustBias"];
_groupData set ["civilianLastIntelAt", _savedData get "civilianLastIntelAt"];
_groupData set ["civilianLastMood", _savedData get "civilianLastMood"];
_groupData set ["civilianRoutineState", _civilianRoutineState];
_groupData set ["civilianLastRoutineAt", _savedData get "civilianLastRoutineAt"];
_groupData set ["civilianRoutineUntil", _civilianRoutineUntil];

[_groupData, _savedData] call FLO_fnc_virtualizationRestoreMissionState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreCommanderState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestorePathState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreAAState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreTransportState;
[_groupData, _savedData] call FLO_fnc_virtualizationRestoreReplacementState;
[_groupData, _groupId] call FLO_fnc_virtualizationValidateGroup;
call FLO_fnc_virtualizationTouchRegistry;

true

