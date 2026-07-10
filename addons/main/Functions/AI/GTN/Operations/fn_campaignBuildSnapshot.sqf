/*
 * Function: FLO_fnc_campaignBuildSnapshot
 * Description:
 *   Builds a side-filtered read model for the operations browser.
 */

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
private _economy = [_treasury] call FLO_fnc_sideResourcesGetSnapshot;
private _logistics = [FLO_Logistics_Networks get _viewerSideKey] call FLO_fnc_logisticsNetworkGetSideSnapshot;
private _enemyLogisticsIntel = [_viewerSide] call FLO_fnc_gtnBuildEnemyLogisticsIntelSnapshot;
private _enemySide = [_viewerSide] call FLO_fnc_gtnTaskEnemySide;
private _enemySideKey = ([_enemySide] call FLO_fnc_gtnSideContext) get "sideKey";
private _viewerSideName = ["BLUFOR", "OPFOR"] select (_viewerSide isEqualTo east);
private _state = _director get "_state";
private _phase = _state get "phase";
private _operationId = _state get "operationId";
private _objectiveId = _state get "objectiveId";
private _viewerIsAttacker = (_state get "attackerSideKey") == _viewerSideKey;
private _defenderIntelLevel = _state get "defenderIntelLevel";
private _viewerIntelLevel = if (_operationId == "") then {
    "NONE"
} else {
    [_defenderIntelLevel, "TARGET"] select _viewerIsAttacker
};
private _targetVisible = _viewerIntelLevel == "TARGET";
private _threatSector = createHashMapFromArray [
    ["visible", false],
    ["position", []],
    ["longAxis", 0],
    ["shortAxis", 0],
    ["direction", 0],
    ["grid", ""],
    ["label", ""]
];
if (!_viewerIsAttacker && {_phase == "PREPARE"} && {_viewerIntelLevel == "SECTOR"}) then {
    _threatSector = [_director] call FLO_fnc_campaignBuildThreatSector;
};

private _visibleObjectiveId = ["", _objectiveId] select _targetVisible;
private _visibleTargetName = "Undisclosed";
private _visibleTargetPosition = [];
if (_visibleObjectiveId != "") then {
    _visibleTargetName = [_visibleObjectiveId] call FLO_fnc_campaignObjectiveName;
    _visibleTargetPosition = (FLO_Objectives get _visibleObjectiveId) get "position";
};

private _role = "REORGANIZE";
if (_operationId != "" && {_phase != "LULL"}) then {
    _role = if (_viewerIsAttacker) then {
        "MAIN_EFFORT"
    } else {
        ["SCREEN", "DEFEND"] select _targetVisible
    };
};

private _supportPosture = switch (_phase) do {
    case "PREPARE": { ["SCREENING", "STAGING"] select _viewerIsAttacker };
    case "ASSAULT": { "COMMITTED" };
    case "SECURE": { "HOLDING" };
    case "CONSOLIDATE": { "CONSOLIDATING" };
    case "RECOVERY": { "RECOVERING" };
    default { "ON_CALL" };
};

private _now = dateToNumber date;
private _remainingSeconds = round ([_now, _state get "phaseEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds);
_remainingSeconds = _remainingSeconds max 0;
private _resourceReservationRemaining = 0;
private _resourceReservationId = _state get "resourceReservationId";
if (_resourceReservationId != "" && {_viewerIsAttacker}) then {
    _resourceReservationRemaining = _treasury call ["getReservationRemaining", [_resourceReservationId]];
};

private _viewerOpportunityObjectives = createHashMap;
private _opportunityRows = [];
{
    private _record = _y;
    if ((_record get "sideKey") != _viewerSideKey) then { continue };

    private _opportunityObjectiveId = _record get "objectiveId";
    if !(_opportunityObjectiveId in FLO_Objectives) then { continue };

    _viewerOpportunityObjectives set [_opportunityObjectiveId, _record get "status"];
    _opportunityRows pushBack createHashMapFromArray [
        ["objectiveId", _opportunityObjectiveId],
        ["name", [_opportunityObjectiveId] call FLO_fnc_campaignObjectiveName],
        ["status", _record get "status"],
        ["sampleCount", _record get "sampleCount"],
        ["ageSeconds", round ([_record get "lastSeenAtDateNum", _now] call FLO_fnc_dateNumberDeltaSeconds)]
    ];
} forEach (_state get "opportunities");

private _sourceObjectiveIds = if (_viewerIsAttacker) then { _state get "sourceObjectiveIds" } else { [] };
private _supportObjectiveIds = if (_viewerIsAttacker) then { _state get "supportObjectiveIds" } else { [] };
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
    if (_nodeId == _visibleObjectiveId) then {
        _intent = ["DEFEND", "MAIN_EFFORT"] select _viewerIsAttacker;
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
                            private _linkedObjective = FLO_Objectives get _x;
                            if ((_linkedObjective get "owner") isEqualTo _enemySide) exitWith { _frontline = true; };
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
        ["radius", _objective get "radius"],
        ["priority", _objective get "priority"],
        ["owner", _ownerKey],
        ["captureState", _objective get "captureState"],
        ["integrationState", _integrationState],
        ["friendlyCount", _friendlyLocal],
        ["enemyCount", _enemyLocal],
        ["contested", _objective get "contested"],
        ["underAttack", _objective get "underAttack"],
        ["intent", _intent],
        ["links", _objective get "linkedObjectives"]
    ];
} forEach (keys FLO_Objectives);

private _playerObjectiveId = [getPosATL _player] call FLO_fnc_campaignFindObjectiveAtPosition;
private _playerStatus = "OUTSIDE_OBJECTIVE";
if (_playerObjectiveId != "") then {
    private _playerObjective = FLO_Objectives get _playerObjectiveId;
    if (_playerObjectiveId == _visibleObjectiveId) then {
        _playerStatus = ["DEFENDING_MAIN_EFFORT", "IN_MAIN_EFFORT"] select _viewerIsAttacker;
    } else {
        if ((_playerObjective get "campaignIntegrationState") == "FOOTHOLD" && {(_playerObjective get "owner") isEqualTo _viewerSide}) then {
            _playerStatus = "IN_FOOTHOLD";
        } else {
            if (_playerObjectiveId in _supportObjectiveIds) then {
                _playerStatus = "IN_SUPPORT_AREA";
            } else {
                _playerStatus = "OFF_OPERATION";
            };
        };
    };
};

createHashMapFromArray [
    ["revision", _state get "revision"],
    ["generatedAt", diag_tickTime],
    ["viewerSide", _viewerSideKey],
    ["viewerSideName", _viewerSideName],
    ["enemySide", _enemySideKey],
    ["worldSize", worldSize],
    ["keybind", "Ctrl+Shift+O"],
    ["operation", createHashMapFromArray [
        ["id", _operationId],
        ["role", _role],
        ["phase", [_phase, "SCREEN"] select (!_viewerIsAttacker && {!_targetVisible && {_phase == "PREPARE"}})],
        ["targetVisible", _targetVisible],
        ["targetId", _visibleObjectiveId],
        ["targetName", _visibleTargetName],
        ["targetPosition", _visibleTargetPosition],
        ["intelLevel", _viewerIntelLevel],
        ["intelReason", [(_state get "defenderIntelReason"), "COMMANDER_INTENT"] select _viewerIsAttacker],
        ["threatSector", _threatSector],
        ["sourceObjectiveIds", _sourceObjectiveIds],
        ["supportObjectiveIds", _supportObjectiveIds],
        ["supportPosture", _supportPosture],
        ["remainingSeconds", _remainingSeconds],
        ["result", _state get "result"],
        ["transitionReason", _state get "transitionReason"],
        ["lastCompletedOperationId", _state get "lastCompletedOperationId"],
        ["lastCompletedResult", _state get "lastCompletedResult"],
        ["resourceBudget", [0, _state get "resourceBudget"] select _viewerIsAttacker],
        ["resourceSpent", [0, _state get "resourceSpent"] select _viewerIsAttacker],
        ["resourceRemaining", _resourceReservationRemaining],
        ["resourceReleased", [0, _state get "resourceReleased"] select _viewerIsAttacker]
    ]],
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
    ["opportunities", _opportunityRows],
    ["objectives", _nodes]
]
