/* Evaluates strategic capacity for one to three concurrent operations. */
params ["_director"];

private _state = _director get "_state";
private _config = _director get "_config";
private _sideKey = _state get "initiativeSideKey";
private _side = [_sideKey] call FLO_fnc_campaignSideFromKey;
private _manager = _director get "_resourceManager";
private _commander = _manager call ["_getCommanderBySide", [_side]];
if (isNil "_commander") then {
    throw format ["FLO_fnc_campaignEvaluateScale: no commander for %1", _sideKey];
};

private _operations = _state get "operations";
private _order = _state get "operationOrder";
private _activeOperationIds = _order select {
    ((_operations get _x) get "phase") != "RECOVERY"
};
private _currentCount = count _activeOperationIds;
private _maximumCount = _config get "operationMaximumCount";

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _availableGroupIds = _commander call ["_getAvailableGroups", [count (keys _groups)]];
private _activeAttackGroups = 0;
{
    private _group = _y;
    if ((_group get "side") isNotEqualTo _side) then { continue };
    if ((_group get "commanderOrder") != "ATTACK") then { continue };
    if ((_group get "campaignOperationId") in _activeOperationIds) then {
        _activeAttackGroups = _activeAttackGroups + 1;
    };
} forEach _groups;

private _offensiveGroups = floor ((count _availableGroupIds) * (_config get "operationOffensivePoolFraction"));
_offensiveGroups = _offensiveGroups + _activeAttackGroups;
private _forceSlots = 0;
if (_offensiveGroups >= (_config get "operationMainMinimumGroups")) then {
    _forceSlots = 1 + floor (
        (_offensiveGroups - (_config get "operationMainMinimumGroups"))
        / (_config get "operationSupportMinimumGroups")
    );
};
_forceSlots = _forceSlots min _maximumCount;

private _network = FLO_Logistics_Networks get _sideKey;
private _activeSupplyNodes = [_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _qualifyingSupplySourceIds = [];
{
    if ((_y get "throughput") >= (_config get "operationLogisticsMinimumSupply")) then {
        _qualifyingSupplySourceIds pushBack _x;
    };
} forEach _activeSupplyNodes;
private _logisticsSlots = (count _qualifyingSupplySourceIds) min _maximumCount;

private _treasury = FLO_SideResources get _sideKey;
private _operationCommitted = 0;
{
    private _reservation = _y;
    if ((_reservation get "category") == "OPERATION") then {
        _operationCommitted = _operationCommitted + (_reservation get "remaining");
    };
} forEach (_treasury get "_reservations");
private _availableResources = [_treasury] call FLO_fnc_sideResourcesGetAvailable;
private _operationEnvelope = (_availableResources + _operationCommitted) min (
    floor ((_treasury get "_balance") * (_config get "operationCommitmentFraction"))
);
private _treasurySlots = floor (_operationEnvelope / (_config get "operationSupportBudgetMinimum"));
_treasurySlots = _treasurySlots min _maximumCount;
if (_currentCount > 0) then { _treasurySlots = _treasurySlots max 1; };
if (_currentCount < _maximumCount) then {
    private _nextRole = ["SUPPORTING_EFFORT", "MAIN_EFFORT"] select (_currentCount == 0);
    private _nextBudget = [_director, _sideKey, _nextRole] call FLO_fnc_campaignCalculateOperationBudget;
    if (_nextBudget <= 0) then {
        _treasurySlots = _currentCount;
    };
};

private _worldObjectives = (_commander get "_worldState") call ["_getObjectives", []];
private _threatenedObjectives = 0;
private _forceDeficit = 0;
{
    private _objectiveId = _x;
    private _objective = _y;
    if ((_objective get "owner") isNotEqualTo _side) then { continue };
    if !([_objectiveId] call FLO_fnc_campaignIsObjectiveIntegrated) then { continue };
    if ((_objective get "underAttack") || {_objective get "contested"}) then {
        _threatenedObjectives = _threatenedObjectives + 1;
    };
    _forceDeficit = _forceDeficit + (((_objective get "enemyCount") - (_objective get "friendlyCount")) max 0);
} forEach _worldObjectives;

private _pressureCap = _maximumCount;
if (_threatenedObjectives >= 3 || {_forceDeficit >= 12}) then {
    _pressureCap = 1;
} else {
    if (_threatenedObjectives >= 1 || {_forceDeficit >= 5}) then {
        _pressureCap = 2;
    };
};

private _baseCapacity = _forceSlots min _logisticsSlots min _treasurySlots min _pressureCap min _maximumCount;
private _excludedObjectiveIds = [];
private _claimedSupplySourceObjectiveIds = [];
private _targetPositions = [];
{
    private _operation = _operations get _x;
    private _objectiveId = _operation get "objectiveId";
    _excludedObjectiveIds pushBack _objectiveId;
    if (_objectiveId in FLO_Objectives) then {
        _targetPositions pushBack ((FLO_Objectives get _objectiveId) get "position");
    };
    private _supplySourceObjectiveId = _operation get "supplySourceObjectiveId";
    if (_supplySourceObjectiveId != "") then {
        _claimedSupplySourceObjectiveIds pushBackUnique _supplySourceObjectiveId;
    };
} forEach _order;

private _plannedSelections = [];
private _registrySlots = (_maximumCount - (count _order)) max 0;
private _additionalSlots = ((_baseCapacity - _currentCount) max 0) min _registrySlots;
for "_i" from 1 to _additionalSlots do {
    private _selection = [
        _director,
        _side,
        _excludedObjectiveIds,
        _claimedSupplySourceObjectiveIds,
        _targetPositions
    ] call FLO_fnc_campaignSelectTarget;
    private _objectiveId = _selection get "objectiveId";
    if (_objectiveId == "") exitWith {};

    _plannedSelections pushBack _selection;
    _excludedObjectiveIds pushBack _objectiveId;
    _claimedSupplySourceObjectiveIds pushBackUnique (_selection get "supplySourceObjectiveId");
    _targetPositions pushBack ((FLO_Objectives get _objectiveId) get "position");
};

private _axisSlots = (_currentCount + (count _plannedSelections)) min _maximumCount;
private _desiredCount = _baseCapacity min _axisSlots;
private _reason = "FULL_CAPACITY";
if (_desiredCount < _maximumCount) then {
    _reason = if (_axisSlots == _desiredCount) then {
        "AXIS_LIMIT"
    } else {
        if (_forceSlots == _desiredCount) then {
            "FORCE_LIMIT"
        } else {
            if (_logisticsSlots == _desiredCount) then {
                "LOGISTICS_LIMIT"
            } else {
                ["DEFENSIVE_PRESSURE", "TREASURY_LIMIT"] select (_treasurySlots == _desiredCount);
            };
        };
    };
};

private _metrics = createHashMapFromArray [
    ["availableGroups", count _availableGroupIds],
    ["activeAttackGroups", _activeAttackGroups],
    ["offensiveGroups", _offensiveGroups],
    ["forceSlots", _forceSlots],
    ["logisticsSlots", _logisticsSlots],
    ["treasurySlots", _treasurySlots],
    ["axisSlots", _axisSlots],
    ["pressureCap", _pressureCap],
    ["threatenedObjectives", _threatenedObjectives],
    ["forceDeficit", _forceDeficit]
];

createHashMapFromArray [
    ["currentCount", _currentCount],
    ["desiredCount", _desiredCount],
    ["reason", _reason],
    ["metrics", _metrics],
    ["plannedSelections", _plannedSelections]
]
