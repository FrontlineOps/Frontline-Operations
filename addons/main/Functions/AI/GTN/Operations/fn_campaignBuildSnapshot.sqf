/* Builds the side-filtered Command Net read model. */
params [
    "_director",
    ["_player", objNull, [objNull]]
];

if (isNull _player) then { throw "FLO_fnc_campaignBuildSnapshot: null player"; };
private _viewerSide = side group _player;
if !(_viewerSide in [west, east]) then {
    throw format ["FLO_fnc_campaignBuildSnapshot: unsupported viewer side %1", _viewerSide];
};

private _viewerSideKey = ([_viewerSide] call FLO_fnc_gtnSideContext) get "sideKey";
private _treasury = FLO_SideResources get _viewerSideKey;
private _economy = [_treasury] call FLO_fnc_sideResourcesGetUiSnapshot;
private _logistics = [FLO_Logistics_Networks get _viewerSideKey] call FLO_fnc_logisticsNetworkGetSideSnapshot;
private _enemyLogisticsIntel = [_viewerSide] call FLO_fnc_gtnBuildEnemyLogisticsIntelSnapshot;
private _enemySide = [_viewerSide] call FLO_fnc_gtnTaskEnemySide;
private _enemySideKey = ([_enemySide] call FLO_fnc_gtnSideContext) get "sideKey";
private _viewerSideName = ["BLUFOR", "OPFOR"] select (_viewerSide isEqualTo east);
private _state = _director get "_state";
private _formationState = _state get "formationState";
private _viewerDoctrine = (_formationState get "doctrineBySide") get _viewerSideKey;
private _formationRows = [_viewerSideKey] call FLO_fnc_formationBuildSnapshot;
private _operationsMap = _state get "operations";
private _operationRows = [];

{
    private _operationId = _x;
    _operationRows pushBack ([_operationsMap get _operationId, _viewerSideKey, _treasury, _forEachIndex == 0] call FLO_fnc_campaignBuildOperationSnapshot);
} forEach (_state get "operationOrder");

private _emptyThreatSector = createHashMapFromArray [
    ["operationId", ""],
    ["visible", false],
    ["position", []],
    ["longAxis", 0],
    ["shortAxis", 0],
    ["direction", 0],
    ["grid", ""],
    ["label", ""]
];
private _primaryOperation = createHashMapFromArray [
    ["id", ""],
    ["isPrimary", true],
    ["role", "PROBING"],
    ["phase", "PROBING"],
    ["actualPhase", "PROBING"],
    ["targetVisible", false],
    ["targetId", ""],
    ["targetName", "Active Front"],
    ["targetPosition", []],
    ["intelLevel", "NONE"],
    ["intelReason", "NO_ACTIVE_OPERATION"],
    ["threatSector", _emptyThreatSector],
    ["sourceObjectiveIds", []],
    ["supportObjectiveIds", []],
    ["supplySourceObjectiveId", ""],
    ["supportPosture", "CONTACT"],
    ["remainingSeconds", round (([call FLO_fnc_operationalDateNumber, _state get "phaseEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) max 0)],
    ["result", ""],
    ["transitionReason", _state get "transitionReason"],
    ["resourceBudget", 0],
    ["resourceSpent", 0],
    ["resourceRemaining", 0],
    ["resourceReleased", 0],
    ["assaultOpeningDelaySeconds", 0],
    ["doctrine", _viewerDoctrine],
    ["shapingStatus", "NONE"],
    ["shapingFormationId", ""],
    ["shapingObjectiveId", ""],
    ["shapingObjectiveName", ""],
    ["exploitationStatus", "NONE"],
    ["exploitationFormationId", ""],
    ["exploitationObjectiveId", ""],
    ["exploitationObjectiveName", ""],
    ["drawdownPending", false]
];
if (_operationRows isNotEqualTo []) then {
    _primaryOperation = _operationRows select 0;
};

private _threatSectors = [];
private _visibleTargetIntents = createHashMap;
private _sourceObjectiveIds = [];
private _supportObjectiveIds = [];
{
    private _operation = _x;
    private _threatSector = _operation get "threatSector";
    if (_threatSector get "visible") then {
        _threatSectors pushBack _threatSector;
    };
    private _targetId = _operation get "targetId";
    if (_targetId != "") then {
        private _intent = switch (_operation get "role") do {
            case "MAIN_EFFORT": { "MAIN_EFFORT" };
            case "SUPPORTING_EFFORT": { "SUPPORTING_EFFORT" };
            case "DEFEND_MAIN_EFFORT": { "DEFEND_MAIN" };
            default { "DEFEND_SUPPORT" };
        };
        _visibleTargetIntents set [_targetId, _intent];
    };
    { _sourceObjectiveIds pushBackUnique _x; } forEach (_operation get "sourceObjectiveIds");
    { _supportObjectiveIds pushBackUnique _x; } forEach (_operation get "supportObjectiveIds");
} forEach _operationRows;

private _viewerOpportunityObjectives = createHashMap;
private _opportunityRows = [];
private _now = call FLO_fnc_operationalDateNumber;
{
    private _record = _y;
    if ((_record get "sideKey") != _viewerSideKey) then { continue };
    private _objectiveId = _record get "objectiveId";
    if !(_objectiveId in FLO_Objectives) then { continue };
    _viewerOpportunityObjectives set [_objectiveId, _record get "status"];
    _opportunityRows pushBack createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["name", [_objectiveId] call FLO_fnc_campaignObjectiveName],
        ["status", _record get "status"],
        ["sampleCount", _record get "sampleCount"],
        ["ageSeconds", round ([_record get "lastSeenAtDateNum", _now] call FLO_fnc_dateNumberDeltaSeconds)]
    ];
} forEach (_state get "opportunities");

private _nodes = [];
private _friendlyCount = 0;
private _enemyCount = 0;
private _footholdCount = 0;
{
    private _nodeId = _x;
    private _objective = FLO_Objectives get _nodeId;
    private _owner = _objective get "owner";
    private _ownerKey = "NEUTRAL";
    if (_owner isEqualTo west) then { _ownerKey = "WEST"; };
    if (_owner isEqualTo east) then { _ownerKey = "EAST"; };
    if (_owner isEqualTo _viewerSide) then { _friendlyCount = _friendlyCount + 1; };
    if (_owner isEqualTo _enemySide) then { _enemyCount = _enemyCount + 1; };

    private _integrationState = _objective get "campaignIntegrationState";
    if (_owner isEqualTo _viewerSide && {_integrationState == "FOOTHOLD"}) then {
        _footholdCount = _footholdCount + 1;
    };

    private _intent = "NONE";
    if (_nodeId in _visibleTargetIntents) then {
        _intent = _visibleTargetIntents get _nodeId;
    } else {
        if (_nodeId in _sourceObjectiveIds || {_nodeId in _supportObjectiveIds}) then {
            _intent = "SUPPORT";
        } else {
            if (_owner isEqualTo _viewerSide && {_integrationState == "FOOTHOLD"}) then {
                _intent = "FOOTHOLD";
            } else {
                if (_nodeId in _viewerOpportunityObjectives) then {
                    _intent = "OPPORTUNITY";
                } else {
                    if (_owner isEqualTo _viewerSide) then {
                        private _frontline = false;
                        {
                            if (((FLO_Objectives get _x) get "owner") isEqualTo _enemySide) exitWith {
                                _frontline = true;
                            };
                        } forEach (_objective get "linkedObjectives");
                        if (_frontline) then { _intent = "SCREEN"; };
                    };
                };
            };
        };
    };

    private _friendlyLocal = [_objective get "opforCount", _objective get "bluforCount"] select (_viewerSide isEqualTo west);
    private _enemyLocal = [_objective get "bluforCount", _objective get "opforCount"] select (_viewerSide isEqualTo west);
    _nodes pushBack createHashMapFromArray [
        ["id", _nodeId],
        ["name", [_nodeId] call FLO_fnc_campaignObjectiveName],
        ["position", _objective get "position"],
        ["priority", _objective get "priority"],
        ["owner", _ownerKey],
        ["captureState", _objective get "captureState"],
        ["integrationState", _integrationState],
        ["friendlyCount", _friendlyLocal],
        ["enemyCount", _enemyLocal],
        ["contested", _objective get "contested"],
        ["underAttack", _objective get "underAttack"],
        ["intent", _intent]
    ];
} forEach (keys FLO_Objectives);

private _playerObjectiveId = [getPosATL _player] call FLO_fnc_campaignFindObjectiveAtPosition;
private _playerStatus = "OUTSIDE_OBJECTIVE";
if (_playerObjectiveId != "") then {
    private _playerObjective = FLO_Objectives get _playerObjectiveId;
    if (_playerObjectiveId in _visibleTargetIntents) then {
        private _targetIntent = _visibleTargetIntents get _playerObjectiveId;
        _playerStatus = switch (_targetIntent) do {
            case "MAIN_EFFORT": { "IN_MAIN_EFFORT" };
            case "SUPPORTING_EFFORT": { "IN_SUPPORTING_EFFORT" };
            case "DEFEND_MAIN": { "DEFENDING_MAIN_EFFORT" };
            default { "DEFENDING_SUPPORTING_EFFORT" };
        };
    } else {
        if ((_playerObjective get "campaignIntegrationState") == "FOOTHOLD" && {(_playerObjective get "owner") isEqualTo _viewerSide}) then {
            _playerStatus = "IN_FOOTHOLD";
        } else {
            _playerStatus = ["OFF_OPERATION", "IN_SUPPORT_AREA"] select (_playerObjectiveId in _supportObjectiveIds);
        };
    };
};

private _activeOperationCount = {
    ((_operationsMap get _x) get "phase") != "RECOVERY"
} count (_state get "operationOrder");
private _viewerOwnsInitiative = (_state get "initiativeSideKey") == _viewerSideKey;
private _scaleMetrics = createHashMapFromArray [
    ["availableGroups", 0],
    ["activeAttackGroups", 0],
    ["offensiveGroups", 0],
    ["forceSlots", 0],
    ["logisticsSlots", 0],
    ["treasurySlots", 0],
    ["axisSlots", 0],
    ["pressureCap", 0],
    ["threatenedObjectives", 0],
    ["forceDeficit", 0]
];
if (_viewerOwnsInitiative) then {
    _scaleMetrics = +(_state get "scaleMetrics");
};

createHashMapFromArray [
    ["revision", _state get "revision"],
    ["generatedAt", diag_tickTime],
    ["viewerSide", _viewerSideKey],
    ["viewerSideName", _viewerSideName],
    ["enemySide", _enemySideKey],
    ["worldSize", worldSize],
    ["keybind", "Ctrl+Shift+O"],
    ["operation", _primaryOperation],
    ["operations", _operationRows],
    ["threatSectors", _threatSectors],
    ["scale", createHashMapFromArray [
        ["visible", _viewerOwnsInitiative],
        ["currentCount", _activeOperationCount],
        ["registryCount", count _operationRows],
        ["desiredCount", [0, _state get "desiredOperationCount"] select _viewerOwnsInitiative],
        ["reason", ["CLASSIFIED", _state get "scaleReason"] select _viewerOwnsInitiative],
        ["metrics", _scaleMetrics]
    ]],
    ["lastCompletedOperationId", _state get "lastCompletedOperationId"],
    ["lastCompletedResult", _state get "lastCompletedResult"],
    ["player", createHashMapFromArray [
        ["grid", mapGridPosition _player],
        ["position", getPosATL _player],
        ["objectiveId", _playerObjectiveId],
        ["status", _playerStatus]
    ]],
    ["summary", createHashMapFromArray [
        ["friendlyObjectives", _friendlyCount],
        ["enemyObjectives", _enemyCount],
        ["footholds", _footholdCount],
        ["opportunities", count _opportunityRows]
    ]],
    ["economy", _economy],
    ["logistics", _logistics],
    ["enemyLogisticsIntel", _enemyLogisticsIntel],
    ["doctrine", _viewerDoctrine],
    ["formations", _formationRows],
    ["opportunities", _opportunityRows],
    ["objectives", _nodes]
]
