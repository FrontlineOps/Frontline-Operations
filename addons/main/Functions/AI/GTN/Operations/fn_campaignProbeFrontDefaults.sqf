/* Creates one canonical persistent frontline-probe record. */
params [
    ["_sideKey", "", [""]],
    ["_objectiveId", "", [""]],
    ["_sourceObjectiveIds", [], [[]]]
];

_sideKey = toUpper _sideKey;
if !(_sideKey in ["WEST", "EAST"]) then {
    throw format ["Cannot create a probe front for invalid side %1", _sideKey];
};
if (_objectiveId == "") then {
    throw "Cannot create a probe front without an objective";
};
if (_sourceObjectiveIds isEqualTo []) then {
    throw format ["Cannot create probe front %1 without an attack source", _objectiveId];
};

private _sources = +_sourceObjectiveIds;
_sources sort true;
private _now = call FLO_fnc_operationalDateNumber;
createHashMapFromArray [
    ["probeId", [_sideKey, _objectiveId] call FLO_fnc_campaignProbeId],
    ["sideKey", _sideKey],
    ["objectiveId", _objectiveId],
    ["sourceObjectiveIds", _sources],
    ["primarySourceObjectiveId", _sources select 0],
    ["stage", "PROBE"],
    ["stageReason", "FRONTLINE_RECONCILED"],
    ["formationIds", []],
    ["committedGroupIds", []],
    ["committedUnitBaseline", 0],
    ["reinforcementCount", 0],
    ["contactSamples", 0],
    ["progressSamples", 0],
    ["stalledSamples", 0],
    ["bestDistance", 1e12],
    ["lastEnemyCount", -1],
    ["lastActiveGroupCount", 0],
    ["lastUnitCount", 0],
    ["lastArrivedCount", 0],
    ["lastContested", false],
    ["lastContactCount", 0],
    ["lastContactAt", -1],
    ["reinforcementProgressCheckpoint", 0],
    ["supportProgressCheckpoint", 0],
    ["supportMissionCount", 0],
    ["artilleryMissionCount", 0],
    ["airMissionCount", 0],
    ["evaluatedSupportMissionCount", 0],
    ["supportAttemptCount", 0],
    ["nextActionAtDateNum", _now],
    ["axisRevision", 0],
    ["promotionReady", false],
    ["formalOperationId", ""],
    ["createdAtDateNum", _now],
    ["stageChangedAtDateNum", _now],
    ["lastEvaluatedAtDateNum", -1]
]
