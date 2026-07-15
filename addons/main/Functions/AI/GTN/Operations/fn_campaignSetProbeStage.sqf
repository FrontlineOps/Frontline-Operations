/* Applies one evidence-driven internal probe-stage transition. */
params [
    ["_front", createHashMap, [createHashMap]],
    ["_nextStage", "", [""]],
    ["_reason", "", [""]]
];

private _probeId = _front get "probeId";
private _previousStage = _front get "stage";
_nextStage = toUpper _nextStage;
if (_previousStage == _nextStage) exitWith { false };

private _validStages = [
    "PROBE", "DEVELOP_CONTACT", "REINFORCE_SUCCESS", "COMMIT_SUPPORT", "ASSAULT",
    "STALLED", "SUPPORT", "SHIFT_AXIS"
];
if !(_nextStage in _validStages) then {
    ["CAMPAIGN", 1, format ["Probe front %1 received invalid stage %2", _probeId, _nextStage]] call FLO_fnc_log;
    throw format ["Probe front %1 cannot enter invalid stage %2", _probeId, _nextStage];
};

_front set ["stage", _nextStage];
_front set ["stageReason", _reason];
_front set ["stageChangedAtDateNum", call FLO_fnc_operationalDateNumber];
[_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;

["CAMPAIGN", 3, format [
    "Probe front %1 stage %2 -> %3 (%4)",
    _probeId,
    _previousStage,
    _nextStage,
    _reason
]] call FLO_fnc_log;
true
