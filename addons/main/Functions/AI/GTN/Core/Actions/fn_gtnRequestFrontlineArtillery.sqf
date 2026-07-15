/* Requests one paid artillery mission from maintained frontline contact intelligence. */
params [["_cmdr", nil]];

private _metrics = createHashMapFromArray [
    ["assetAvailable", false],
    ["candidateCount", 0],
    ["eligibleCount", 0],
    ["lockedCount", 0],
    ["requestedCount", 0],
    ["selectedObjective", ""],
    ["selectedScore", 0],
    ["authorized", false]
];
if (isNil "_cmdr") exitWith { _metrics };

private _ws = _cmdr get "_worldState";
if !(_ws call ["_isAssetAvailable", ["artillery"]]) exitWith { _metrics };
_metrics set ["assetAvailable", true];
if ((_cmdr get "_frontlineSupportPictureBuiltAt") < 0) exitWith { _metrics };

private _director = _cmdr get "_campaignDirector";
private _state = _director call ["_getState", []];
private _fronts = _state get "frontlineProbes";
private _picture = _cmdr get "_frontlineSupportPicture";
private _sideKey = _cmdr get "_sideKey";
private _ownSide = _cmdr get "_ownSide";
private _enemySide = _cmdr get "_enemySide";
private _objectives = _ws call ["_getObjectives", []];
private _config = _cmdr get "_config";
private _locks = _cmdr get "_frontlineArtilleryLocks";
private _now = diag_tickTime;

private _expiredLocks = [];
{
    if ((_locks get _x) <= _now || {!(_x in _objectives)}) then {
        _expiredLocks pushBack _x;
    };
} forEach (keys _locks);
{ _locks deleteAt _x; } forEach _expiredLocks;

private _bestProbeId = "";
private _bestObjectiveId = "";
private _bestScore = -1e12;
{
    private _probeId = _x;
    private _front = _y;
    if ((_front get "sideKey") != _sideKey) then { continue };
    if ((_front get "stage") in ["SHIFT_AXIS", "REGROUP"]) then { continue };
    private _objectiveId = _front get "objectiveId";
    if !(_objectiveId in _objectives) then {
        throw format ["Frontline artillery probe %1 references missing objective %2", _probeId, _objectiveId];
    };
    if (((_objectives get _objectiveId) get "owner") isNotEqualTo _enemySide) then { continue };
    _metrics set ["candidateCount", (_metrics get "candidateCount") + 1];
    if (_objectiveId in _locks) then {
        _metrics set ["lockedCount", (_metrics get "lockedCount") + 1];
        continue;
    };
    private _contact = _picture get _probeId;
    if ((_contact get "reportCount") <= 0) then { continue };
    if ((_contact get "confidence") < ((_director get "_config") get "probeMinimumContactConfidence")) then { continue };

    private _stageBonus = switch (_front get "stage") do {
        case "DEVELOP_CONTACT": { 20 };
        case "REINFORCE_SUCCESS": { 35 };
        case "COMMIT_SUPPORT": { 60 };
        case "ASSAULT": { 70 };
        case "STALLED": { 50 };
        case "SUPPORT": { 65 };
        default { 0 };
    };
    private _score = (_contact get "score") + _stageBonus + ((_front get "lastActiveGroupCount") * 3);
    _metrics set ["eligibleCount", (_metrics get "eligibleCount") + 1];
    if (_score > _bestScore) then {
        _bestProbeId = _probeId;
        _bestObjectiveId = _objectiveId;
        _bestScore = _score;
    };
} forEach _fronts;

if (_bestProbeId == "" || {_bestScore < (_config get "frontlineArtilleryMinScore")}) exitWith { _metrics };
private _manager = _cmdr get "_artilleryManager";
private _requestStatus = [_manager, _ownSide, _bestObjectiveId] call FLO_fnc_gtnArtilleryCanRequestMission;
if !(_requestStatus select 0) exitWith { _metrics };

private _contact = _picture get _bestProbeId;
private _fresh = (_contact get "freshReportCount") > 0;
private _accuracy = [
    _config get "frontlineArtilleryStaleAccuracy",
    _config get "frontlineArtilleryFreshAccuracy"
] select _fresh;
private _targetContext = createHashMapFromArray [
    ["targetGroupIds", +(_contact get "targetGroupIds")],
    ["contactState", ["FRONTLINE_STALE", "FRONTLINE_FRESH"] select _fresh],
    ["contactConfidence", _contact get "confidence"],
    ["contactAgeSeconds", _contact get "ageSeconds"],
    ["uncertaintyRadius", _contact get "uncertaintyRadius"]
];
private _authorized = _manager call ["_requestFireMission", [
    _contact get "targetPos",
    _config get "frontlineArtilleryRounds",
    _accuracy,
    _ownSide,
    _bestObjectiveId,
    "FRONTLINE",
    false,
    _targetContext
]];
_metrics set ["requestedCount", 1];
_metrics set ["selectedObjective", _bestObjectiveId];
_metrics set ["selectedScore", _bestScore];
_metrics set ["authorized", _authorized];
[
    _director,
    _sideKey,
    _bestObjectiveId,
    "ARTILLERY",
    _authorized
] call FLO_fnc_campaignRecordProbeSupport;
_locks set [
    _bestObjectiveId,
    _now + ([
        _config get "frontlineArtilleryRetrySeconds",
        _config get "frontlineArtilleryObjectiveLockSeconds"
    ] select _authorized)
];

if (_authorized) then {
    ["GTN", 3, format [
        "Frontline artillery authorized for %1 from %2 contact reports (score=%3 age=%4s)",
        _bestObjectiveId,
        _contact get "reportCount",
        round _bestScore,
        round (_contact get "ageSeconds")
    ]] call FLO_fnc_log;
};

_metrics
