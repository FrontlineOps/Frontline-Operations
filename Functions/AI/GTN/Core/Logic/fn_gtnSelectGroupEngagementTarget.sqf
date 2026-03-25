/*
 * Function: FLO_fnc_gtnSelectGroupEngagementTarget
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects the best commander-confirmed opportunistic engagement target for
 *   one GTN group without changing its strategic order.
 *
 * Arguments:
 * 0: Friendly group data <HASHMAP>
 * 1: Enemy engagement picture <HASHMAP>
 * 2: Commander config <HASHMAP>
 * 3: Current engagement target assignment state <HASHMAP>
 *
 * Return Value:
 * HASHMAP - Empty when no target is valid, otherwise contains:
 *   "targetGroupId", "targetPos", "targetObjective", "reason",
 *   "leashMeters", "score"
 */

params ["_groupData", "_engagementPicture", "_config", ["_assignmentState", createHashMap, [createHashMap]]];

private _bestTarget = createHashMap;
private _bestScore = -1e12;
private _engagementGroups = _engagementPicture get "groups";
private _objectiveGroups = _engagementPicture get "objectiveGroups";
private _order = _groupData get "commanderOrder";

private _candidateIds = switch (_order) do {
    case "ATTACK": {
        keys _engagementGroups
    };
    case "DEFEND": {
        _objectiveGroups getOrDefault [_groupData get "defendObjective", []]
    };
    case "GARRISON": {
        _objectiveGroups getOrDefault [_groupData get "garrisonObjective", []]
    };
    default {
        []
    };
};

{
    private _targetGroupId = _x;
    private _targetData = _engagementGroups getOrDefault [_targetGroupId, createHashMap];
    if (count (keys _targetData) == 0) then { continue };

    private _evaluation = [_groupData, _targetData, _config] call FLO_fnc_gtnEvaluateGroupEngagementTarget;
    if (count (keys _evaluation) == 0) then { continue };

    private _score = _evaluation get "score";
    private _assignment = if (_targetGroupId in (keys _assignmentState)) then {
        _assignmentState get _targetGroupId
    } else {
        createHashMapFromArray [
            ["count", 0],
            ["load", 0]
        ]
    };
    private _assignmentCap = [_targetData, _config] call FLO_fnc_gtnGetEngagementTargetAssignmentCap;
    private _assignedCount = _assignment get "count";
    private _assignedLoad = _assignment get "load";
    private _loadPenalty = _assignedLoad / 6;

    _score = _score - (_assignedCount * (_config get "engagementReservationPenaltyPerGroup")) - _loadPenalty;
    if (_assignedCount >= (_assignmentCap get "maxGroups") || {_assignedLoad >= (_assignmentCap get "maxLoad")}) then {
        _score = _score - (_config get "engagementSaturationPenalty");
    };

    if (_score > _bestScore) then {
        _bestScore = _score;

        private _objectiveIds = _targetData get "objectiveIds";
        private _targetObjective = switch (_order) do {
            case "DEFEND": { _groupData get "defendObjective" };
            case "GARRISON": { _groupData get "garrisonObjective" };
            default {
                if (count _objectiveIds > 0) then { _objectiveIds select 0 } else { "" };
            };
        };

        _bestTarget = createHashMapFromArray [
            ["targetGroupId", _targetGroupId],
            ["targetPos", _targetData get "position"],
            ["targetObjective", _targetObjective],
            ["reason", _evaluation get "reason"],
            ["leashMeters", _evaluation get "leashMeters"],
            ["score", _score]
        ];
    };
} forEach _candidateIds;

_bestTarget
