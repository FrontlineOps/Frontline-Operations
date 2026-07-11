/*
 * Function: FLO_fnc_virtualizationConvertAssetCrewToInfantryRemnant
 * Author: Frontline Operations Development Group
 * Description:
 *   Converts an asset-tracked group with destroyed vehicles but surviving crew
 *   into an infantry remnant so the survivors can persist and later straggle
 *   out naturally instead of the whole group being treated as hard-dead.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 * 2: Real Group <GROUP>
 *
 * Return Value:
 * BOOL - True when the group was converted
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_realGroup", grpNull, [grpNull]]
];

if (_groupId == "") exitWith { false };
if (isNull _realGroup) exitWith { false };

private _oldGroupType = _groupData get "groupType";
if !([_oldGroupType] call FLO_fnc_virtualizationUsesAssetStrength) exitWith { false };

private _survivingAssets = [_groupData, _realGroup] call FLO_fnc_virtualizationGetRealAssetVehicles;
if (_survivingAssets isNotEqualTo []) exitWith { false };

private _aliveUnits = units _realGroup select { alive _x };
private _aliveUnitCount = count _aliveUnits;
if (_aliveUnitCount <= 0) exitWith { false };

if ([_groupData] call FLO_fnc_virtualizationIsTransportCarrier) then {
    [_groupId] call FLO_fnc_transportDetachAll;
};

if ((_groupData get "mountedIn") != "") then {
    [_groupData] call FLO_fnc_virtualizationClearMountedIn;
};

if ((_groupData get "attachedTo") != "") then {
    [_groupData] call FLO_fnc_virtualizationClearTransportAttachment;
};

private _survivorComp = _aliveUnits apply { typeOf _x };

_groupData set ["groupType", "infantry"];
_groupData set ["groupCfg", []];
_groupData set ["spawnClass", ""];
_groupData set ["transportRole", false];
_groupData set ["isTransport", false];
_groupData set ["attachedGroups", []];
_groupData set ["attachedType", ""];
_groupData set ["unitCount", _aliveUnitCount];
[_groupData, _survivorComp] call FLO_fnc_virtualizationSetAssetComposition;

if (_oldGroupType in ["helicopter", "jet", "air", "artillery", "static_aa", "mobile_aa"] || {_groupData get "missionLock" in ["AIR", "ARTILLERY", "TRANSPORT"]}) then {
    [_groupData] call FLO_fnc_virtualizationClearMissionLock;
    [_groupData] call FLO_fnc_virtualizationClearExecutionState;
};

[_groupData, _groupId] call FLO_fnc_virtualizationValidateGroup;
call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_GroupPatched",
    [_groupId, ["groupType", "unitCount", "comp", "missionLock"]]
] call CBA_fnc_localEvent;

["VIRTUALIZATION", 2, format [
    "Converted destroyed %1 group %2 into infantry remnant with %3 surviving crew",
    _oldGroupType,
    _groupId,
    _aliveUnitCount
]] call FLO_fnc_log;

true
