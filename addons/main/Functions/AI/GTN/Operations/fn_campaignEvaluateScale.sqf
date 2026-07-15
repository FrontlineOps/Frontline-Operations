/* Plans every affordable formal promotion from mature canonical probes. */
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
private _offensiveGroups = (count _availableGroupIds) + _activeAttackGroups;

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

private _network = FLO_Logistics_Networks get _sideKey;
private _activeSupplyNodes = [_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _qualifyingSupplySourceCount = 0;
{
    if ((_y get "throughput") >= (_config get "operationLogisticsMinimumSupply")) then {
        _qualifyingSupplySourceCount = _qualifyingSupplySourceCount + 1;
    };
} forEach _activeSupplyNodes;

private _treasury = FLO_SideResources get _sideKey;
private _operationCommitted = 0;
{
    if ((_y get "category") == "OPERATION") then {
        _operationCommitted = _operationCommitted + (_y get "remaining");
    };
} forEach (_treasury get "_reservations");
private _availableResources = [_treasury] call FLO_fnc_sideResourcesGetAvailable;
private _capRemaining = ((floor ((_treasury get "_balance") * (_config get "operationCommitmentFraction"))) - _operationCommitted) max 0;
private _planningAvailable = _availableResources;
private _planningCapRemaining = _capRemaining;

private _excludedObjectiveIds = [];
{
    _excludedObjectiveIds pushBack ((_operations get _x) get "objectiveId");
} forEach _order;

private _promotableProbeCount = 0;
{
    private _front = _y;
    if ((_front get "sideKey") != _sideKey) then { continue };
    private _objectiveId = _front get "objectiveId";
    if (_objectiveId in _excludedObjectiveIds) then { continue };
    if (([_director, _sideKey, _objectiveId] call FLO_fnc_campaignGetPromotableProbeGroups) isNotEqualTo []) then {
        _promotableProbeCount = _promotableProbeCount + 1;
    };
} forEach (_state get "frontlineProbes");

private _plannedSelections = [];
private _canPlan = _order isEqualTo [] || {_activeOperationIds isNotEqualTo []};
private _rankedSelections = [];
if (_canPlan) then {
    _rankedSelections = [
        _director,
        _side,
        _excludedObjectiveIds,
        [],
        []
    ] call FLO_fnc_campaignSelectTarget;
};
private _rankableProbeCount = count _rankedSelections;

{
    private _selection = _x;
    private _priorityRole = ["SUPPORTING_EFFORT", "MAIN_EFFORT"] select (
        _order isEqualTo [] && {_plannedSelections isEqualTo []}
    );
    private _budget = [
        _director,
        _sideKey,
        _priorityRole,
        _planningAvailable,
        _planningCapRemaining
    ] call FLO_fnc_campaignCalculateOperationBudget;
    if (_budget <= 0) exitWith {};

    _selection set ["plannedBudget", _budget];
    _plannedSelections pushBack _selection;
    _planningAvailable = _planningAvailable - _budget;
    _planningCapRemaining = _planningCapRemaining - _budget;
} forEach _rankedSelections;

private _desiredCount = _currentCount + (count _plannedSelections);
private _reason = if (_plannedSelections isNotEqualTo []) then {
    "MATURE_PROBES_READY"
} else {
    if (_rankableProbeCount > 0) then {
        "TREASURY_LIMIT"
    } else {
        ["NO_MATURE_PROBE", "LOGISTICS_OR_TERRAIN_LIMIT"] select (_promotableProbeCount > 0)
    }
};
private _treasurySlots = _currentCount + floor (
    ((_availableResources min _capRemaining) max 0) / (_config get "operationSupportBudgetMinimum")
);
private _axisSlots = _currentCount + _rankableProbeCount;
private _forceSlots = _axisSlots;
private _logisticsSlots = [0, _axisSlots] select (_qualifyingSupplySourceCount > 0);

private _metrics = createHashMapFromArray [
    ["availableGroups", count _availableGroupIds],
    ["activeAttackGroups", _activeAttackGroups],
    ["offensiveGroups", _offensiveGroups],
    ["forceSlots", _forceSlots],
    ["logisticsSlots", _logisticsSlots],
    ["treasurySlots", _treasurySlots],
    ["axisSlots", _axisSlots],
    ["pressureCap", _axisSlots],
    ["threatenedObjectives", _threatenedObjectives],
    ["forceDeficit", _forceDeficit],
    ["qualifyingSupplySourceCount", _qualifyingSupplySourceCount],
    ["promotableProbeCount", _promotableProbeCount],
    ["rankableProbeCount", _rankableProbeCount],
    ["plannedCommitment", _availableResources - _planningAvailable]
];

createHashMapFromArray [
    ["currentCount", _currentCount],
    ["desiredCount", _desiredCount],
    ["reason", _reason],
    ["metrics", _metrics],
    ["plannedSelections", _plannedSelections]
]
