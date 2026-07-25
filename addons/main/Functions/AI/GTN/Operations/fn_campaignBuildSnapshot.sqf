/* Builds the side-filtered Command Net from direct ATTACK group ownership. */
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

private _viewerAttackCounts = createHashMap;
private _enemyAttackCounts = createHashMap;
{
    private _groupData = _y;
    if ((_groupData get "unitCount") <= 0) then { continue };
    if ((_groupData get "commanderOrder") != "ATTACK") then { continue };
    private _objectiveId = _groupData get "attackObjective";
    if (_objectiveId == "") then {
        ["CAMPAIGN", 1, format ["Snapshot found ATTACK group %1 without an objective", _x]] call FLO_fnc_log;
        throw format ["ATTACK group %1 has no objective", _x];
    };

    private _counts = [_enemyAttackCounts, _viewerAttackCounts] select ((_groupData get "side") isEqualTo _viewerSide);
    if ((_groupData get "side") in [_viewerSide, _enemySide]) then {
        private _count = if (_objectiveId in _counts) then { _counts get _objectiveId } else { 0 };
        _counts set [_objectiveId, _count + 1];
    };
} forEach (call FLO_fnc_virtualizationGetGroupMap);

private _rankedAttacks = [];
{
    private _objectiveId = _x;
    if !(_objectiveId in FLO_Objectives) then {
        throw format ["Direct attack references missing objective %1", _objectiveId];
    };
    private _objective = FLO_Objectives get _objectiveId;
    _rankedAttacks pushBack [
        -(_viewerAttackCounts get _objectiveId),
        -(_objective get "priority"),
        _objectiveId,
        createHashMapFromArray [
            ["id", format ["ATTACK_%1_%2", _viewerSideKey, _objectiveId]],
            ["isPrimary", false],
            ["role", "ATTACKING"],
            ["targetVisible", true],
            ["targetId", _objectiveId],
            ["targetName", [_objectiveId] call FLO_fnc_campaignObjectiveName],
            ["attackerCount", _viewerAttackCounts get _objectiveId],
            ["attackerCap", _attackCap]
        ]
    ];
} forEach (keys _viewerAttackCounts);
_rankedAttacks sort true;
private _attackRows = _rankedAttacks apply { _x select 3 };
if (_attackRows isNotEqualTo []) then { (_attackRows select 0) set ["isPrimary", true] };

private _primaryAttack = createHashMapFromArray [
    ["id", ""],
    ["isPrimary", true],
    ["role", "IDLE"],
    ["targetVisible", false],
    ["targetId", ""],
    ["targetName", "Active Front"],
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
        if (_objectiveId in _enemyAttackCounts && {_owner isEqualTo _viewerSide}) then {
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
    private _enemyLocal = [_objective get "bluforCount", _objective get "opforCount"] select (_viewerSide isEqualTo west);
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
        ["contested", _objective get "contested"],
        ["underAttack", _objective get "underAttack"],
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
        if (_playerObjectiveId in _enemyAttackCounts && {(_playerObjective get "owner") isEqualTo _viewerSide}) then {
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
    ["logistics", _logistics],
    ["enemyLogisticsIntel", _enemyLogisticsIntel],
    ["objectives", _nodes]
]
