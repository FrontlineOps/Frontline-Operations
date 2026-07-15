/* Reconciles one commander's canonical probe records with maintained frontline topology. */
params ["_director", "_cmdr"];

private _metrics = createHashMapFromArray [
    ["changed", false],
    ["frontlineCount", 0],
    ["createdCount", 0],
    ["removedCount", 0],
    ["sourceUpdatedCount", 0]
];
private _state = _director get "_state";
private _fronts = _state get "frontlineProbes";
private _sideKey = _cmdr get "_sideKey";
private _network = FLO_Logistics_Networks get _sideKey;
private _frontline = _cmdr call ["_getAttackFrontlineEnemyObjectives", []];
private _desired = createHashMap;

{
    private _objectiveId = _x;
    private _sources = [_cmdr, _network, _objectiveId] call FLO_fnc_campaignGetReachableAttackSources;
    if (_sources isEqualTo []) then { continue };
    _sources sort true;
    private _probeId = [_sideKey, _objectiveId] call FLO_fnc_campaignProbeId;
    _desired set [_probeId, _sources];
    if !(_probeId in _fronts) then {
        _fronts set [_probeId, [_sideKey, _objectiveId, _sources] call FLO_fnc_campaignProbeFrontDefaults];
        _metrics set ["createdCount", (_metrics get "createdCount") + 1];
        _metrics set ["changed", true];
    } else {
        private _front = _fronts get _probeId;
        if ((_front get "sourceObjectiveIds") isNotEqualTo _sources) then {
            _front set ["sourceObjectiveIds", _sources];
            if !((_front get "primarySourceObjectiveId") in _sources) then {
                _front set ["primarySourceObjectiveId", _sources select 0];
                _front set ["axisRevision", (_front get "axisRevision") + 1];
            };
            _metrics set ["sourceUpdatedCount", (_metrics get "sourceUpdatedCount") + 1];
            _metrics set ["changed", true];
        };
        [_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;
    };
} forEach _frontline;
_metrics set ["frontlineCount", count (keys _desired)];

private _removeIds = [];
private _formationOwnershipChanged = false;
{
    private _probeId = _x;
    private _front = _y;
    if ((_front get "sideKey") != _sideKey) then { continue };
    if (_probeId in _desired) then { continue };
    if ((_front get "formalOperationId") != "") then { continue };
    [_director, _cmdr, _front, "FRONTLINE_REMOVED"] call FLO_fnc_campaignReleaseProbeFront;
    _removeIds pushBack _probeId;
} forEach _fronts;
{
    private _front = _fronts get _x;
    private _formations = ((_state get "formationState") get "formations");
    {
        if !(_x in _formations) then { continue };
        private _formation = _formations get _x;
        if ((_formation get "roleOperationId") == (_front get "probeId")) then {
            _formation set ["roleOperationId", ""];
            _formationOwnershipChanged = true;
        };
    } forEach (_front get "formationIds");
    _fronts deleteAt _x;
} forEach _removeIds;
if (_formationOwnershipChanged) then {
    private _formationState = _state get "formationState";
    _formationState set ["revision", (_formationState get "revision") + 1];
};
if (_removeIds isNotEqualTo []) then {
    _metrics set ["removedCount", count _removeIds];
    _metrics set ["changed", true];
};

if (_metrics get "changed") then {
    ["CAMPAIGN", 3, format [
        "%1 probe topology reconciled: fronts=%2 created=%3 removed=%4 sources=%5",
        _sideKey,
        _metrics get "frontlineCount",
        _metrics get "createdCount",
        _metrics get "removedCount",
        _metrics get "sourceUpdatedCount"
    ]] call FLO_fnc_log;
};

_metrics
