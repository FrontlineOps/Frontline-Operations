/* Serializes validated current-version probe records without runtime aliases. */
params [["_fronts", createHashMap, [createHashMap]]];

private _serialized = createHashMap;
{
    [_x, _y] call FLO_fnc_campaignValidateProbeFrontState;
    private _front = _y;
    _serialized set [_x, createHashMapFromArray [
        ["probeId", _front get "probeId"],
        ["sideKey", _front get "sideKey"],
        ["objectiveId", _front get "objectiveId"],
        ["sourceObjectiveIds", +(_front get "sourceObjectiveIds")],
        ["primarySourceObjectiveId", _front get "primarySourceObjectiveId"],
        ["stage", _front get "stage"],
        ["stageReason", _front get "stageReason"],
        ["committedGroupIds", +(_front get "committedGroupIds")],
        ["committedUnitBaseline", _front get "committedUnitBaseline"],
        ["contactSamples", _front get "contactSamples"],
        ["progressSamples", _front get "progressSamples"],
        ["stalledSamples", _front get "stalledSamples"],
        ["bestDistance", _front get "bestDistance"],
        ["lastEnemyCount", _front get "lastEnemyCount"],
        ["lastActiveGroupCount", _front get "lastActiveGroupCount"],
        ["lastUnitCount", _front get "lastUnitCount"],
        ["lastArrivedCount", _front get "lastArrivedCount"],
        ["lastContested", _front get "lastContested"],
        ["lastContactCount", _front get "lastContactCount"],
        ["lastContactAt", _front get "lastContactAt"],
        ["reinforcementProgressCheckpoint", _front get "reinforcementProgressCheckpoint"],
        ["supportProgressCheckpoint", _front get "supportProgressCheckpoint"],
        ["supportMissionCount", _front get "supportMissionCount"],
        ["artilleryMissionCount", _front get "artilleryMissionCount"],
        ["airMissionCount", _front get "airMissionCount"],
        ["evaluatedSupportMissionCount", _front get "evaluatedSupportMissionCount"],
        ["supportAttemptCount", _front get "supportAttemptCount"],
        ["nextActionAtDateNum", _front get "nextActionAtDateNum"],
        ["axisRevision", _front get "axisRevision"],
        ["formalOperationId", _front get "formalOperationId"],
        ["createdAtDateNum", _front get "createdAtDateNum"],
        ["stageChangedAtDateNum", _front get "stageChangedAtDateNum"],
        ["lastEvaluatedAtDateNum", _front get "lastEvaluatedAtDateNum"]
    ]];
} forEach _fronts;

_serialized
