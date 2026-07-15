/*
 * Function: FLO_fnc_logisticsNetworkReplenishTransportReserves
 * Description:
 *   Replenishes dedicated transport reserve carriers outside the generic
 *   reinforcement composition path so destroyed reserves come back as real
 *   transport-role carriers rather than ordinary combat groups.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *
 * Return Value:
 *   HASHMAP - Replenishment stats
 */

params ["_net"];

private _stats = createHashMapFromArray [
    ["groundMissing", 0],
    ["airMissing", 0],
    ["groundCreated", 0],
    ["airCreated", 0]
];

private _managedSide = _net get "_managedSide";
private _sideKey = [_managedSide] call FLO_fnc_sideKey;
private _catalog = FLO_FactionCatalog get _sideKey;

private _desiredGround = _catalog get "transportReserveGroundCount";
private _desiredAir = _catalog get "transportReserveAirCount";
if (_desiredGround <= 0 && {_desiredAir <= 0}) exitWith { _stats };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _currentGround = 0;
private _currentAir = 0;
private _groundByObjective = createHashMap;
private _airByObjective = createHashMap;

{
    private _groupData = _y;
    if ((_groupData get "side") isNotEqualTo _managedSide) then { continue };
    if !(_groupData get "transportRole") then { continue };

    private _groupType = _groupData get "groupType";
    private _homeObjective = _groupData get "homeObjective";
    if (_groupType isEqualTo "helicopter") then {
        _currentAir = _currentAir + 1;
        if (_homeObjective != "") then {
            _airByObjective set [_homeObjective, (_airByObjective getOrDefault [_homeObjective, 0]) + 1];
        };
        continue;
    };

    if (_groupType in ["motorized", "mechanized"]) then {
        _currentGround = _currentGround + 1;
        if (_homeObjective != "") then {
            _groundByObjective set [_homeObjective, (_groundByObjective getOrDefault [_homeObjective, 0]) + 1];
        };
    };
} forEach _groups;

private _groundMissing = (_desiredGround - _currentGround) max 0;
private _airMissing = (_desiredAir - _currentAir) max 0;
_stats set ["groundMissing", _groundMissing];
_stats set ["airMissing", _airMissing];

if (_groundMissing <= 0 && {_airMissing <= 0}) exitWith { _stats };

private _spawnContext = [_managedSide, _net] call FLO_fnc_transportResolveReserveSpawnContext;
_spawnContext params ["_spawnObjectiveIds", "_reserveObjectiveId", "_reservePos"];
if (_reserveObjectiveId isEqualTo "") exitWith { _stats };

private _activeSupplyNodes = _net get "_activeSupplyNodes";

private _resources = FLO_SideResources get (_net get "_managedSideKey");
private _groupCosts = _net get "GROUP_COSTS";
private _groupThroughputCosts = _net get "GROUP_THROUGHPUT_COSTS";
private _groundCost = _groupCosts get "motorized";
private _airCost = _groupCosts get "helicopter";
private _groundThroughputCost = _groupThroughputCosts get "motorized";
private _airThroughputCost = _groupThroughputCosts get "helicopter";
private _groundCreateCap = (_net get "TRANSPORT_RESERVE_REPLENISH_GROUND_PER_CHECK") min _groundMissing;
private _airCreateCap = (_net get "TRANSPORT_RESERVE_REPLENISH_AIR_PER_CHECK") min _airMissing;

for "_i" from 1 to _groundCreateCap do {
    if !(_resources call ["canAfford", [_groundCost]]) exitWith {};

    private _spawnObjectiveId = [_spawnObjectiveIds, _groundByObjective, _activeSupplyNodes, _reserveObjectiveId] call FLO_fnc_transportPickReserveSpawnObjective;
    if !(_spawnObjectiveId in _activeSupplyNodes) exitWith {};
    private _sourceNodeId = (_activeSupplyNodes get _spawnObjectiveId) get "nodeId";
    private _spendingDecision = [
        _resources,
        _groundCost,
        "TRANSPORT",
        "ROUTINE",
        createHashMapFromArray [
            ["strategic", true],
            ["commitment", false],
            ["reserved", false],
            ["referenceId", _spawnObjectiveId]
        ]
    ] call FLO_fnc_commanderSpendingEvaluate;
    if !(_spendingDecision get "allowed") exitWith {};

    private _reservationId = format ["TRANSPORT:%1:GROUND:%2:%3", _sideKey, round (diag_tickTime * 1000), _i];
    if !(_resources call ["reserve", [_reservationId, _groundCost, "TRANSPORT", "Ground transport reserve", "COMMANDER", _spawnObjectiveId]]) exitWith {};
    if !([_net, _sourceNodeId, _groundThroughputCost, "Ground transport reserve"] call FLO_fnc_logisticsNetworkConsumeThroughput) exitWith {
        _resources call ["releaseReservation", [_reservationId, "Ground reserve source local supplies changed"]];
    };
    private _objectiveReserveCount = if (_spawnObjectiveId in _groundByObjective) then {
        _groundByObjective get _spawnObjectiveId
    } else {
        0
    };
    private _spawnPos = [_net, _spawnObjectiveId, _objectiveReserveCount, "ground", _reservePos] call FLO_fnc_transportResolveReserveSpawnPosition;

    private _groupId = [_managedSide, "ground", _spawnObjectiveId, _spawnPos] call FLO_fnc_transportCreateReserveCarrier;
    if (_groupId isEqualTo "") then {
        [_net, _sourceNodeId, _groundThroughputCost, "Ground reserve creation refund"] call FLO_fnc_logisticsNetworkRestoreThroughput;
        _resources call ["releaseReservation", [_reservationId, "Ground reserve creation failed"]];
        continue;
    };
    if !(_resources call ["commitReservation", [_reservationId, _groundCost, "Created ground transport reserve"]]) then {
        throw format ["Failed to commit guaranteed transport reservation %1", _reservationId];
    };

    _stats set ["groundCreated", (_stats get "groundCreated") + 1];
    _groundByObjective set [_spawnObjectiveId, _objectiveReserveCount + 1];
    [_net, "motorized", _groundCost] call FLO_fnc_logisticsNetworkRecordReplacement;

    ["LOGISTICS", 3, format [
        "Replenished dedicated ground transport reserve %1 for %2 at supply node %3 treasury=%4 localSupplies=%5",
        _groupId,
        _sideKey,
        _spawnObjectiveId,
        _groundCost,
        _groundThroughputCost
    ]] call FLO_fnc_log;
};

for "_i" from 1 to _airCreateCap do {
    if !(_resources call ["canAfford", [_airCost]]) exitWith {};

    private _spawnObjectiveId = [_spawnObjectiveIds, _airByObjective, _activeSupplyNodes, _reserveObjectiveId] call FLO_fnc_transportPickReserveSpawnObjective;
    if !(_spawnObjectiveId in _activeSupplyNodes) exitWith {};
    private _sourceNodeId = (_activeSupplyNodes get _spawnObjectiveId) get "nodeId";
    private _spendingDecision = [
        _resources,
        _airCost,
        "TRANSPORT",
        "ROUTINE",
        createHashMapFromArray [
            ["strategic", true],
            ["commitment", false],
            ["reserved", false],
            ["referenceId", _spawnObjectiveId]
        ]
    ] call FLO_fnc_commanderSpendingEvaluate;
    if !(_spendingDecision get "allowed") exitWith {};

    private _reservationId = format ["TRANSPORT:%1:AIR:%2:%3", _sideKey, round (diag_tickTime * 1000), _i];
    if !(_resources call ["reserve", [_reservationId, _airCost, "TRANSPORT", "Air transport reserve", "COMMANDER", _spawnObjectiveId]]) exitWith {};
    if !([_net, _sourceNodeId, _airThroughputCost, "Air transport reserve"] call FLO_fnc_logisticsNetworkConsumeThroughput) exitWith {
        _resources call ["releaseReservation", [_reservationId, "Air reserve source local supplies changed"]];
    };
    private _objectiveReserveCount = if (_spawnObjectiveId in _airByObjective) then {
        _airByObjective get _spawnObjectiveId
    } else {
        0
    };
    private _spawnPos = [_net, _spawnObjectiveId, _objectiveReserveCount, "air", _reservePos] call FLO_fnc_transportResolveReserveSpawnPosition;

    private _groupId = [_managedSide, "air", _spawnObjectiveId, _spawnPos] call FLO_fnc_transportCreateReserveCarrier;
    if (_groupId isEqualTo "") then {
        [_net, _sourceNodeId, _airThroughputCost, "Air reserve creation refund"] call FLO_fnc_logisticsNetworkRestoreThroughput;
        _resources call ["releaseReservation", [_reservationId, "Air reserve creation failed"]];
        continue;
    };
    if !(_resources call ["commitReservation", [_reservationId, _airCost, "Created air transport reserve"]]) then {
        throw format ["Failed to commit guaranteed transport reservation %1", _reservationId];
    };

    _stats set ["airCreated", (_stats get "airCreated") + 1];
    _airByObjective set [_spawnObjectiveId, _objectiveReserveCount + 1];
    [_net, "helicopter", _airCost] call FLO_fnc_logisticsNetworkRecordReplacement;

    ["LOGISTICS", 3, format [
        "Replenished dedicated air transport reserve %1 for %2 at supply node %3 treasury=%4 localSupplies=%5",
        _groupId,
        _sideKey,
        _spawnObjectiveId,
        _airCost,
        _airThroughputCost
    ]] call FLO_fnc_log;
};

_stats
