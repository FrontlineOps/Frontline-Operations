/*
 * Function: FLO_fnc_campaignSelectTarget
 * Description:
 *   Selects one reachable main-effort objective. Sustained player activity
 *   may override the commander's normal strategic ranking.
 */

params [
    "_director",
    ["_side", sideUnknown, [east]]
];

private _manager = _director get "_resourceManager";
private _commander = _manager call ["_getCommanderBySide", [_side]];
if (isNil "_commander") then {
    throw format ["FLO_fnc_campaignSelectTarget: no commander for %1", _side];
};

private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
private _network = FLO_Logistics_Networks get _sideKey;
private _frontline = _commander call ["_getAttackFrontlineEnemyObjectives", []];
private _state = _director get "_state";
private _config = _director get "_config";
private _opportunities = _state get "opportunities";
private _minimumSamples = _config get "opportunityMinimumSamples";
private _ranked = [];

{
    private _opportunity = _y;
    if ((_opportunity get "sideKey") != _sideKey) then { continue };
    if ((_opportunity get "sampleCount") < _minimumSamples) then { continue };

    private _objectiveId = _opportunity get "objectiveId";
    if !(_objectiveId in _frontline) then { continue };

    private _sources = [_commander, _network, _objectiveId] call FLO_fnc_campaignGetReachableAttackSources;
    if (_sources isEqualTo []) then { continue };

    private _statusWeight = switch (_opportunity get "status") do {
        case "ASSAULT": { 300 };
        case "CONTACT": { 120 };
        default { 0 };
    };
    private _objective = _frontline get _objectiveId;
    private _score = _statusWeight + (_objective get "priority") + ((_opportunity get "sampleCount") min 20);
    _ranked pushBack [_score, _objectiveId, _sources];
} forEach _opportunities;

_ranked sort false;

private _objectiveId = "";
private _sourceObjectiveIds = [];
private _fromOpportunity = false;

if (_ranked isNotEqualTo []) then {
    private _selected = _ranked select 0;
    _objectiveId = _selected select 1;
    _sourceObjectiveIds = _selected select 2;
    _fromOpportunity = true;
} else {
    private _bestDistance = 1e12;
    private _bestPriority = -1e12;
    {
        private _candidateId = _x;
        private _candidateSources = [_commander, _network, _candidateId] call FLO_fnc_campaignGetReachableAttackSources;
        if (_candidateSources isEqualTo []) then { continue };

        private _candidate = _y;
        private _candidatePosition = _candidate get "position";
        private _nearestSourceDistance = 1e12;
        {
            private _sourceDistance = _candidatePosition distance2D ((FLO_Objectives get _x) get "position");
            if (_sourceDistance < _nearestSourceDistance) then { _nearestSourceDistance = _sourceDistance; };
        } forEach _candidateSources;

        private _candidatePriority = _candidate get "priority";
        if (
            _nearestSourceDistance < _bestDistance
            || {_nearestSourceDistance == _bestDistance && {_candidatePriority > _bestPriority}}
        ) then {
            _objectiveId = _candidateId;
            _sourceObjectiveIds = _candidateSources;
            _bestDistance = _nearestSourceDistance;
            _bestPriority = _candidatePriority;
        };
    } forEach _frontline;
};

if (_objectiveId == "" || {_sourceObjectiveIds isEqualTo []}) exitWith {
    createHashMapFromArray [
        ["objectiveId", ""],
        ["sourceObjectiveIds", []],
        ["supportObjectiveIds", []],
        ["fromOpportunity", false]
    ]
};

private _supportObjectiveIds = +_sourceObjectiveIds;
private _objective = FLO_Objectives get _objectiveId;
{
    private _linked = FLO_Objectives get _x;
    if ((_linked get "owner") isEqualTo _side && {[_x] call FLO_fnc_campaignIsObjectiveIntegrated}) then {
        _supportObjectiveIds pushBackUnique _x;
    };
} forEach (_objective get "linkedObjectives");

createHashMapFromArray [
    ["objectiveId", _objectiveId],
    ["sourceObjectiveIds", _sourceObjectiveIds],
    ["supportObjectiveIds", _supportObjectiveIds],
    ["fromOpportunity", _fromOpportunity]
]
