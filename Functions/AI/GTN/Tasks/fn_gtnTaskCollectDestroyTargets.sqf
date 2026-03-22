/*
 * Function: FLO_fnc_gtnTaskCollectDestroyTargets
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves exact destroy-task targets from nearby active enemy virtual groups
 *   using the maintained spatial index and real asset vehicles. Destroy tasks
 *   only exist when exact vehicles/systems can be marked.
 *
 * Arguments:
 *   0: Objective ID <STRING>
 *   1: Objective Data <HASHMAP>
 *   2: Enemy Side <SIDE>
 *
 * Return Value:
 *   Result <HASHMAP> containing:
 *     - "targets": ARRAY of vehicle objects
 *     - "targetLabel": STRING
 *     - "targetCount": NUMBER
 *     - "taskPos": ARRAY
 *     - "typeBonus": NUMBER
 */

params [
    ["_objectiveId", "", [""]],
    ["_objectiveData", createHashMap, [createHashMap]],
    ["_enemySide", east]
];

if (isNil "FLO_virtualGroups") exitWith { createHashMap };

private _objectivePos = _objectiveData get "position";
private _radius = ((_objectiveData get "radius") max 500) min 1200;
private _candidateGroupIds = ["queryRadius", [_objectivePos, _radius, _enemySide, true]] call FLO_fnc_virtualizationSpatialIndex;
if (count _candidateGroupIds == 0) exitWith { createHashMap };

private _groups = FLO_virtualGroups get "_groups";
private _bestTargets = [];
private _bestLabel = "";
private _bestScore = -1;
private _bestTaskPos = [];
private _bestTypeBonus = 0;

{
    private _groupId = _x;
    private _groupData = _groups get _groupId;

    if !(_groupData get "isActive") then { continue };
    if ((_groupData get "attachedTo") != "") then { continue };

    private _groupType = _groupData get "groupType";
    if !(_groupType in ["armor", "mechanized", "motorized", "mobile_aa", "static_aa", "artillery"]) then { continue };

    private _realGroup = _groupData get "realGroup";
    if (isNull _realGroup) then { continue };

    private _targets = [_groupData, _realGroup] call FLO_fnc_virtualizationGetRealAssetVehicles;
    if (count _targets == 0) then { continue };

    private _groupPos = _groupData get "position";
    private _distancePenalty = (_groupPos distance2D _objectivePos) / 50;
    private _typeBonus = switch (_groupType) do {
        case "armor": { 55 };
        case "mechanized": { 42 };
        case "mobile_aa": { 38 };
        case "static_aa": { 34 };
        case "artillery": { 32 };
        case "motorized": { 24 };
        default { 10 };
    };

    private _score = _typeBonus + (count _targets * 8) - _distancePenalty;
    if (_score > _bestScore) then {
        private _sumX = 0;
        private _sumY = 0;
        {
            private _vehPos = getPosATL _x;
            _sumX = _sumX + (_vehPos select 0);
            _sumY = _sumY + (_vehPos select 1);
        } forEach _targets;

        _bestScore = _score;
        _bestTargets = _targets;
        _bestTaskPos = [_sumX / count _targets, _sumY / count _targets, 0];
        _bestTypeBonus = _typeBonus;
        _bestLabel = switch (_groupType) do {
            case "armor": { "armor" };
            case "mechanized": { "mechanized vehicles" };
            case "mobile_aa": { "mobile air-defense vehicles" };
            case "static_aa": { "air-defense systems" };
            case "artillery": { "artillery pieces" };
            case "motorized": { "motorized vehicles" };
            default { "enemy vehicles" };
        };
    };
} forEach _candidateGroupIds;

if (count _bestTargets == 0) exitWith { createHashMap };

createHashMapFromArray [
    ["targets", _bestTargets],
    ["targetLabel", _bestLabel],
    ["targetCount", count _bestTargets],
    ["taskPos", _bestTaskPos],
    ["typeBonus", _bestTypeBonus]
]
