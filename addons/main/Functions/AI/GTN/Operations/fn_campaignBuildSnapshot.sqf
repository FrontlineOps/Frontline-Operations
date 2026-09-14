/* Own GTN intent progress and the maintained intelligence picture. */
params [["_player", objNull, [objNull]]];

if (isNull _player) then { throw "FLO_fnc_campaignBuildSnapshot: null player" };
private _viewerSide = side group _player;
if !(_viewerSide in [west, east]) then {
    throw format ["FLO_fnc_campaignBuildSnapshot: unsupported viewer side %1", _viewerSide];
};

private _viewerSideKey = ([_viewerSide] call FLO_fnc_gtnSideContext) get "sideKey";
private _enemySide = [_viewerSide] call FLO_fnc_gtnTaskEnemySide;
private _enemySideKey = ([_enemySide] call FLO_fnc_gtnSideContext) get "sideKey";
private _viewerSideName = ["BLUFOR", "OPFOR"] select (_viewerSide isEqualTo east);
private _attackCoverage = (([_viewerSide, "attackCoverage"] call FLO_fnc_gtnGetSideCommanderHandle) get "value");
private _attackCap = [_attackCoverage, 6] call FLO_fnc_gtnResolveAttackCoverageCap;
private _treasury = FLO_SideResources get _viewerSideKey;
private _economy = [_treasury] call FLO_fnc_sideResourcesGetUiSnapshot;
private _logistics = [FLO_Logistics_Networks get _viewerSideKey] call FLO_fnc_logisticsNetworkGetSideSnapshot;
private _enemyLogisticsIntel = [_viewerSide] call FLO_fnc_gtnBuildEnemyLogisticsIntelSnapshot;

private _commander = [_viewerSide] call FLO_fnc_gtnGetCommanderBySide;
private _observedObjectives = (_commander get "_worldState") get "_objectives";
private _operationRows = [_commander] call FLO_fnc_campaignBuildOperationRows;
private _attackRows = _operationRows select { (_x get "kind") == "CAPTURE" };
private _viewerAttackCounts = createHashMap;
{
    _x set ["attackerCap", _attackCap];
    _viewerAttackCounts set [_x get "targetId", _x get "attackerCount"];
} forEach _attackRows;
if (_attackRows isNotEqualTo []) then { (_attackRows select 0) set ["isPrimary", true] };

private _primaryAttack = createHashMapFromArray [
    ["id", ""],
    ["isPrimary", true],
    ["role", "IDLE"],
    ["targetVisible", false],
    ["targetId", ""],
    ["targetName", "No offensive underway"],
    ["status", "Commander evaluating objectives and available forces"],
    ["attackerCount", 0],
    ["attackerCap", _attackCap]
];
if (_attackRows isNotEqualTo []) then { _primaryAttack = _attackRows select 0 };

private _nodes = [];
private _friendlyCount = 0;
private _enemyCount = 0;
private _footholdCount = 0;
{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    if !(_objectiveId in _observedObjectives) then {
        throw format ["Campaign snapshot: %1 objective %2 is absent from initialized World State", _viewerSideKey, _objectiveId];
    };
    private _observed = _observedObjectives get _objectiveId;
    private _owner = _objective get "owner";
    private _ownerKey = "NEUTRAL";
    if (_owner isEqualTo west) then { _ownerKey = "WEST" };
    if (_owner isEqualTo east) then { _ownerKey = "EAST" };
    if (_owner isEqualTo _viewerSide) then { _friendlyCount = _friendlyCount + 1 };
    if (_owner isEqualTo _enemySide) then { _enemyCount = _enemyCount + 1 };

    private _integrationState = _objective get "campaignIntegrationState";
    if (_owner isEqualTo _viewerSide && {_integrationState == "FOOTHOLD"}) then { _footholdCount = _footholdCount + 1 };

    private _intent = "NONE";
    if (_objectiveId in _viewerAttackCounts) then {
        _intent = "ATTACK";
    } else {
        if ((_observed get "underAttack") && {_owner isEqualTo _viewerSide}) then {
            _intent = "DEFEND";
        } else {
            if (_owner isEqualTo _viewerSide && {_integrationState == "FOOTHOLD"}) then {
                _intent = "FOOTHOLD";
            } else {
                if (_owner isEqualTo _viewerSide) then {
                    {
                        if (((FLO_Objectives get _x) get "owner") isEqualTo _enemySide) exitWith { _intent = "SCREEN" };
                    } forEach (_objective get "linkedObjectives");
                };
            };
        };
    };

    private _friendlyLocal = [_objective get "opforCount", _objective get "bluforCount"] select (_viewerSide isEqualTo west);
    private _enemyLocal = _observed get "enemyCount";
    _nodes pushBack createHashMapFromArray [
        ["id", _objectiveId],
        ["name", [_objectiveId] call FLO_fnc_campaignObjectiveName],
        ["position", _objective get "position"],
        ["priority", _objective get "priority"],
        ["owner", _ownerKey],
        ["captureState", _objective get "captureState"],
        ["integrationState", _integrationState],
        ["friendlyCount", _friendlyLocal],
        ["enemyCount", _enemyLocal],
        ["enemyStrengthKnown", _observed get "enemyStrengthKnown"],
        ["intelConfidence", _observed get "enemyIntelConfidence"],
        ["contested", _observed get "contested"],
        ["underAttack", _observed get "underAttack"],
        ["intent", _intent]
    ];
} forEach (keys FLO_Objectives);

private _playerObjectiveId = [getPosATL _player] call FLO_fnc_campaignFindObjectiveAtPosition;
private _playerStatus = "OUTSIDE_OBJECTIVE";
if (_playerObjectiveId != "") then {
    private _playerObjective = FLO_Objectives get _playerObjectiveId;
    if (_playerObjectiveId in _viewerAttackCounts) then {
        _playerStatus = "IN_ATTACK";
    } else {
        if (((_observedObjectives get _playerObjectiveId) get "underAttack") && {(_playerObjective get "owner") isEqualTo _viewerSide}) then {
            _playerStatus = "IN_DEFENSE";
        } else {
            _playerStatus = ["OFF_FRONT", "IN_FOOTHOLD"] select (
                (_playerObjective get "campaignIntegrationState") == "FOOTHOLD"
                && {(_playerObjective get "owner") isEqualTo _viewerSide}
            );
        };
    };
};

createHashMapFromArray [
    ["revision", round (diag_tickTime * 10)],
    ["generatedAt", diag_tickTime],
    ["viewerSide", _viewerSideKey],
    ["viewerSideName", _viewerSideName],
    ["enemySide", _enemySideKey],
    ["worldSize", worldSize],
    ["keybind", "Ctrl+Shift+O"],
    ["attack", _primaryAttack],
    ["attacks", _attackRows],
    ["operations", _operationRows],
    ["player", createHashMapFromArray [
        ["grid", mapGridPosition _player],
        ["position", getPosATL _player],
        ["objectiveId", _playerObjectiveId],
        ["status", _playerStatus]
    ]],
    ["summary", createHashMapFromArray [
        ["friendlyObjectives", _friendlyCount],
        ["enemyObjectives", _enemyCount],
        ["footholds", _footholdCount]
    ]],
    ["economy", _economy],
    ["save", call FLO_fnc_saveGetStatus],
    ["canSave", [_player] call FLO_fnc_saveCanRequest],
    ["logistics", _logistics],
    ["enemyLogisticsIntel", _enemyLogisticsIntel],
    ["objectives", _nodes]
]
