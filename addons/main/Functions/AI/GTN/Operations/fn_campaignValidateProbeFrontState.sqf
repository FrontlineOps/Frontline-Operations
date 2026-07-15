/* Validates one current persistent frontline-probe record. */
params [
    ["_probeId", "", [""]],
    ["_front", createHashMap, [createHashMap]]
];

private _fail = {
    params ["_message"];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};
private _required = createHashMapFromArray [
    ["probeId", ""],
    ["sideKey", ""],
    ["objectiveId", ""],
    ["sourceObjectiveIds", []],
    ["primarySourceObjectiveId", ""],
    ["stage", ""],
    ["stageReason", ""],
    ["committedGroupIds", []],
    ["committedUnitBaseline", 0],
    ["contactSamples", 0],
    ["progressSamples", 0],
    ["stalledSamples", 0],
    ["bestDistance", 0],
    ["lastEnemyCount", 0],
    ["lastActiveGroupCount", 0],
    ["lastUnitCount", 0],
    ["lastArrivedCount", 0],
    ["lastContested", false],
    ["lastContactCount", 0],
    ["lastContactAt", 0],
    ["reinforcementProgressCheckpoint", 0],
    ["supportProgressCheckpoint", 0],
    ["supportMissionCount", 0],
    ["artilleryMissionCount", 0],
    ["airMissionCount", 0],
    ["evaluatedSupportMissionCount", 0],
    ["supportAttemptCount", 0],
    ["nextActionAtDateNum", 0],
    ["axisRevision", 0],
    ["formalOperationId", ""],
    ["createdAtDateNum", 0],
    ["stageChangedAtDateNum", 0],
    ["lastEvaluatedAtDateNum", 0]
];
private _unexpectedFields = (keys _front) select { !(_x in _required) };
if (_unexpectedFields isNotEqualTo []) then {
    [format [
        "Probe front %1 has unexpected fields %2",
        _probeId,
        _unexpectedFields
    ]] call _fail;
};

{
    if !(_x in _front) then {
        [format ["Probe front %1 is missing required field %2", _probeId, _x]] call _fail;
    };
    if !((_front get _x) isEqualType _y) then {
        [format ["Probe front %1 field %2 has type %3, expected %4", _probeId, _x, typeName (_front get _x), typeName _y]] call _fail;
    };
} forEach _required;

if ((_front get "probeId") != _probeId) then {
    [format ["Probe front key/id mismatch %1/%2", _probeId, _front get "probeId"]] call _fail;
};
private _sideKey = _front get "sideKey";
private _objectiveId = _front get "objectiveId";
if !(_sideKey in ["WEST", "EAST"]) then {
    [format ["Probe front %1 has invalid side %2", _probeId, _sideKey]] call _fail;
};
if (_objectiveId == "" || {_probeId != ([_sideKey, _objectiveId] call FLO_fnc_campaignProbeId)}) then {
    [format ["Probe front %1 has invalid objective identity %2/%3", _probeId, _sideKey, _objectiveId]] call _fail;
};

private _validStages = [
    "PROBE", "DEVELOP_CONTACT", "REINFORCE_SUCCESS", "COMMIT_SUPPORT", "ASSAULT",
    "STALLED", "SUPPORT", "SHIFT_AXIS"
];
if !((_front get "stage") in _validStages) then {
    [format ["Probe front %1 has invalid stage %2", _probeId, _front get "stage"]] call _fail;
};
private _sources = _front get "sourceObjectiveIds";
if (_sources isEqualTo [] || {!((_front get "primarySourceObjectiveId") in _sources)}) then {
    [format ["Probe front %1 has no valid primary attack source", _probeId]] call _fail;
};
if ((count _sources) != (count (_sources arrayIntersect _sources))) then {
    [format ["Probe front %1 contains duplicate attack sources", _probeId]] call _fail;
};

{
    if ((_front get _x) < 0) then {
        [format ["Probe front %1 has negative counter %2=%3", _probeId, _x, _front get _x]] call _fail;
    };
} forEach [
    "committedUnitBaseline", "contactSamples", "progressSamples", "stalledSamples",
    "lastActiveGroupCount", "lastUnitCount", "lastArrivedCount", "lastContactCount",
    "reinforcementProgressCheckpoint", "supportProgressCheckpoint", "supportMissionCount",
    "artilleryMissionCount", "airMissionCount", "evaluatedSupportMissionCount", "supportAttemptCount", "axisRevision"
];
if ((_front get "evaluatedSupportMissionCount") > (_front get "supportMissionCount")) then {
    [format ["Probe front %1 evaluated more support missions than were authorized", _probeId]] call _fail;
};
true
