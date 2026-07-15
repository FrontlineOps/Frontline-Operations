/* Runs bounded probe reconciliation and evidence evaluation on commander cadence. */
params ["_director", "_cmdr"];

private _metrics = createHashMapFromArray [
    ["run", false],
    ["frontCount", 0],
    ["evaluatedCount", 0],
    ["createdCount", 0],
    ["removedCount", 0],
    ["committedFormationCount", 0],
    ["stageCounts", createHashMap],
    ["supportContactCount", 0],
    ["selectionRejections", createHashMap]
];
private _now = diag_tickTime;
private _lastRun = _cmdr get "_lastProbeEvaluationAt";
private _interval = ((_cmdr get "_config") get "probeEvaluationIntervalSeconds") max 1;
if (_lastRun >= 0 && {_now - _lastRun < _interval}) exitWith { _metrics };
_cmdr set ["_lastProbeEvaluationAt", _now];
_metrics set ["run", true];

private _reconcile = [_director, _cmdr] call FLO_fnc_campaignReconcileFrontlineProbes;
_metrics set ["createdCount", _reconcile get "createdCount"];
_metrics set ["removedCount", _reconcile get "removedCount"];
private _state = _director get "_state";
private _fronts = _state get "frontlineProbes";
private _sideKey = _cmdr get "_sideKey";
private _supportPicture = [_cmdr, _fronts] call FLO_fnc_gtnBuildFrontlineSupportPicture;
_cmdr set ["_frontlineSupportPicture", _supportPicture];
_cmdr set ["_frontlineSupportPictureBuiltAt", _now];

private _probeIds = (keys _fronts) select { ((_fronts get _x) get "sideKey") == _sideKey };
_probeIds sort true;
_metrics set ["frontCount", count _probeIds];
if (_probeIds isEqualTo []) exitWith {
    if (_reconcile get "changed") then {
        _state set ["revision", (_state get "revision") + 1];
    };
    _metrics
};

private _cursor = (_cmdr get "_probeEvaluationCursor") mod (count _probeIds);
private _orderedIds = [];
for "_offset" from 0 to ((count _probeIds) - 1) do {
    _orderedIds pushBack (_probeIds select ((_cursor + _offset) mod (count _probeIds)));
};
_cmdr set ["_probeEvaluationCursor", (_cursor + 1) mod (count _probeIds)];

private _commitAvailable = true;
private _changed = _reconcile get "changed";
private _stageCounts = _metrics get "stageCounts";
private _selectionDiagnostics = _metrics get "selectionRejections";
{
    private _probeId = _x;
    private _front = _fronts get _probeId;
    private _support = _supportPicture get _probeId;
    if ((_support get "reportCount") > 0) then {
        _metrics set ["supportContactCount", (_metrics get "supportContactCount") + 1];
    };
    private _result = [
        _director,
        _cmdr,
        _front,
        _support,
        _commitAvailable,
        _selectionDiagnostics
    ] call FLO_fnc_campaignEvaluateProbeFront;
    _metrics set ["evaluatedCount", (_metrics get "evaluatedCount") + 1];
    if (_result get "changed") then { _changed = true; };
    if (_result get "committed") then {
        _metrics set ["committedFormationCount", 1];
    };
    if (_result get "selectionAttempted") then {
        _commitAvailable = false;
    };
    private _stage = _front get "stage";
    private _stageCount = if (_stage in _stageCounts) then { _stageCounts get _stage } else { 0 };
    _stageCounts set [_stage, _stageCount + 1];
} forEach _orderedIds;

if (("ATTEMPTS" in _selectionDiagnostics) && {(_selectionDiagnostics get "ATTEMPTS") > 0}) then {
    ["CAMPAIGN", 4, format [
        "Probe formation selection %1: committed=%2 rejectionCounts=%3",
        _sideKey,
        _metrics get "committedFormationCount",
        _selectionDiagnostics
    ]] call FLO_fnc_log;
};

if (_changed) then {
    _state set ["revision", (_state get "revision") + 1];
};
_metrics
