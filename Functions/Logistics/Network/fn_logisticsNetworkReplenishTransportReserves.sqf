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
private _sideContext = [_managedSide] call FLO_fnc_gtnSideContext;
private _sideKey = _sideContext get "sideKey";
private _catalog = FLO_FactionCatalog get _sideKey;

private _desiredGround = _catalog get "transportReserveGroundCount";
private _desiredAir = _catalog get "transportReserveAirCount";
if (_desiredGround <= 0 && {_desiredAir <= 0}) exitWith { _stats };

private _groups = FLO_virtualGroups get "_groups";
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
private _groundCost = _groupCosts get "motorized";
private _airCost = _groupCosts get "helicopter";
private _groundCreateCap = (_net get "TRANSPORT_RESERVE_REPLENISH_GROUND_PER_CHECK") min _groundMissing;
private _airCreateCap = (_net get "TRANSPORT_RESERVE_REPLENISH_AIR_PER_CHECK") min _airMissing;

for "_i" from 1 to _groundCreateCap do {
    if !(_resources call ["canAfford", [_groundCost, "reinforcement"]]) exitWith {};
    if !(_resources call ["spendResources", [_groundCost, "reinforcement"]]) exitWith {};

    private _spawnObjectiveId = [_spawnObjectiveIds, _groundByObjective, _activeSupplyNodes, _reserveObjectiveId] call FLO_fnc_transportPickReserveSpawnObjective;
    private _objectiveReserveCount = if (_spawnObjectiveId in _groundByObjective) then {
        _groundByObjective get _spawnObjectiveId
    } else {
        0
    };
    private _spawnPos = [_net, _spawnObjectiveId, _objectiveReserveCount, "ground", _reservePos] call FLO_fnc_transportResolveReserveSpawnPosition;

    private _groupId = [_managedSide, "ground", _spawnObjectiveId, _spawnPos] call FLO_fnc_transportCreateReserveCarrier;
    if (_groupId isEqualTo "") then { continue };

    _stats set ["groundCreated", (_stats get "groundCreated") + 1];
    _groundByObjective set [_spawnObjectiveId, _objectiveReserveCount + 1];
    [_net, "motorized", _groundCost] call FLO_fnc_logisticsNetworkRecordReplacement;

    ["LOGISTICS", 2, format [
        "Replenished dedicated ground transport reserve %1 for %2 at supply node %3",
        _groupId,
        _sideKey,
        _spawnObjectiveId
    ]] call FLO_fnc_log;
};

for "_i" from 1 to _airCreateCap do {
    if !(_resources call ["canAfford", [_airCost, "reinforcement"]]) exitWith {};
    if !(_resources call ["spendResources", [_airCost, "reinforcement"]]) exitWith {};

    private _spawnObjectiveId = [_spawnObjectiveIds, _airByObjective, _activeSupplyNodes, _reserveObjectiveId] call FLO_fnc_transportPickReserveSpawnObjective;
    private _objectiveReserveCount = if (_spawnObjectiveId in _airByObjective) then {
        _airByObjective get _spawnObjectiveId
    } else {
        0
    };
    private _spawnPos = [_net, _spawnObjectiveId, _objectiveReserveCount, "air", _reservePos] call FLO_fnc_transportResolveReserveSpawnPosition;

    private _groupId = [_managedSide, "air", _spawnObjectiveId, _spawnPos] call FLO_fnc_transportCreateReserveCarrier;
    if (_groupId isEqualTo "") then { continue };

    _stats set ["airCreated", (_stats get "airCreated") + 1];
    _airByObjective set [_spawnObjectiveId, _objectiveReserveCount + 1];
    [_net, "helicopter", _airCost] call FLO_fnc_logisticsNetworkRecordReplacement;

    ["LOGISTICS", 2, format [
        "Replenished dedicated air transport reserve %1 for %2 at supply node %3",
        _groupId,
        _sideKey,
        _spawnObjectiveId
    ]] call FLO_fnc_log;
};

_stats
