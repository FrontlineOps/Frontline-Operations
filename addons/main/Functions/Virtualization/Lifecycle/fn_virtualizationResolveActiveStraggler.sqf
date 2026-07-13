/*
 * Function: FLO_fnc_virtualizationResolveActiveStraggler
 * Author: Frontline Operations Development Group
 * Description:
 *   Removes tiny active infantry remnants that are no longer visible to
 *   players and are not part of a hot objective or active mission flow.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 * 2: Real Group <GROUP>
 * 3: Tracks Assets <BOOL>
 * 4: Nearest Player Distance <NUMBER>
 * 5: Virtualization Stats <HASHMAP>
 * 6: Converted Asset-Crew Remnant <BOOL>
 *
 * Return Value:
 * BOOL - True when the group was resolved and removed
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_realGroup", grpNull, [grpNull]],
    ["_tracksAssets", false, [false]],
    ["_nearestDist", 0, [0]],
    ["_virtStats", createHashMap, [createHashMap]],
    ["_convertedCrewRemnant", false, [false]]
];

if (_groupId == "") exitWith { false };
if (_tracksAssets) exitWith { false };
if (isNull _realGroup) exitWith { false };
if ((_groupData get "transportRole")) exitWith { false };
if ((_groupData get "inCombat")) exitWith { false };
if ((_groupData get "missionLock") != "") exitWith { false };
if ((_groupData get "replacementState") != "") exitWith { false };
if ((_groupData get "attachedTo") != "" || {(_groupData get "mountedIn") != ""}) exitWith { false };

private _playerEvidenceRadius = FLO_AftermathCleanup get "playerEvidenceRadius";
if (_nearestDist <= _playerEvidenceRadius) exitWith { false };

private _aliveUnits = units _realGroup select { alive _x };
private _aliveUnitCount = count _aliveUnits;
if (_aliveUnitCount <= 0 || {_aliveUnitCount > 3}) exitWith { false };
private _activeInitialUnitCount = _groupData get "activeInitialUnitCount";
if (!_convertedCrewRemnant && {_aliveUnitCount >= _activeInitialUnitCount}) exitWith { false };

private _objectiveId = _groupData get "defendObjective";
if (_objectiveId == "") then {
    _objectiveId = _groupData get "attackObjective";
};
if (_objectiveId == "") then {
    _objectiveId = _groupData get "garrisonObjective";
};
if (_objectiveId == "") then {
    _objectiveId = _groupData get "homeObjective";
};

if (_objectiveId != "") then {
    private _objectiveData = FLO_Objectives get _objectiveId;
    if ((_objectiveData get "contested") || {_objectiveData get "underAttack"} || {(_objectiveData get "enemyCount") > 0}) exitWith {
        false
    };
};

["VIRTUALIZATION", 4, format [
    "Resolving remote straggler group %1 (%2) with %3 survivors at %4m",
    _groupId,
    _groupData get "groupType",
    _aliveUnitCount,
    round _nearestDist
]] call FLO_fnc_log;

if !([_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup) exitWith { false };

[_groupId] call FLO_fnc_virtualizationRemoveGroup;
_virtStats set ["stragglerResolvesTotal", (_virtStats get "stragglerResolvesTotal") + 1];
_virtStats set ["stragglerResolvesThisBatch", (_virtStats get "stragglerResolvesThisBatch") + 1];

true
