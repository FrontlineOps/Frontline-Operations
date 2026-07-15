/* Authorizes one air sortie against treasury and connected Local Supplies. */
params [
    ["_groupId", "", [""]],
    ["_groupData", nil],
    ["_missionRecord", nil],
    ["_playerRequested", false, [true]]
];

if (!isServer) then { throw "Air sortie authorization is server-owned"; };
if (isNil "_groupData" || {isNil "_missionRecord"}) then { throw "Air sortie authorization requires group and mission state"; };

private _side = _groupData get "side";
private _sideKey = [_side] call FLO_fnc_sideKey;
private _groupType = _groupData get "groupType";
private _missionType = _missionRecord get "missionType";
private _costs = if (_missionType == "CAP") then {
    [800, 1200]
} else {
    [[600, 900], [1000, 1500]] select (_groupType == "jet")
};
_costs params ["_treasuryCost", "_localSupplyCost"];

private _homeObjective = _groupData get "homeObjective";
if (_homeObjective == "") then { throw format ["Air group %1 has no homeObjective", _groupId]; };
private _network = FLO_Logistics_Networks get _sideKey;
private _treasury = FLO_SideResources get _sideKey;
private _sourceObjective = [_network, _homeObjective, [], _localSupplyCost] call FLO_fnc_logisticsNetworkFindSupplySourceObjective;
if (_sourceObjective == "") exitWith {
    ["GTN Air", 3, format ["%1 sortie denied - no connected source can sustain aircraft %2", _sideKey, _groupId]] call FLO_fnc_log;
    false
};

private _source = (_network get "_activeSupplyNodes") get _sourceObjective;
private _sourceNodeId = _source get "nodeId";
private _missionId = _missionRecord get "missionId";
private _reservationId = format ["AIR:%1:%2", _sideKey, _missionId];
private _reason = format ["%1 air sortie", _missionType];
private _actor = ["COMMANDER", "PLAYER"] select _playerRequested;

private _spendingAllowed = true;
if (!_playerRequested) then {
    private _spendingDecision = [
        _treasury,
        _treasuryCost,
        "AIR_SUPPORT",
        "OPERATIONAL",
        createHashMapFromArray [["strategic", true], ["commitment", false], ["reserved", false], ["referenceId", _missionId]]
    ] call FLO_fnc_commanderSpendingEvaluate;
    _spendingAllowed = _spendingDecision get "allowed";
};
if (!_spendingAllowed) exitWith { false };

if !(_treasury call ["reserve", [_reservationId, _treasuryCost, "AIR_SUPPORT", _reason, _actor, _missionId]]) exitWith { false };
if !([_network, _sourceNodeId, _localSupplyCost, _reason] call FLO_fnc_logisticsNetworkConsumeThroughput) exitWith {
    _treasury call ["releaseReservation", [_reservationId, "Air sortie source Local Supplies changed"]];
    false
};
if !(_treasury call ["commitReservation", [_reservationId, _treasuryCost, _reason]]) then {
    [_network, _sourceNodeId, _localSupplyCost, "Air sortie authorization rollback"] call FLO_fnc_logisticsNetworkRestoreThroughput;
    _treasury call ["releaseReservation", [_reservationId, "Air sortie authorization rollback"]];
    throw format ["Air sortie reservation %1 failed during commit", _reservationId];
};

_missionRecord set ["treasuryCost", _treasuryCost];
_missionRecord set ["localSupplyCost", _localSupplyCost];
_missionRecord set ["supplyNodeId", _sourceNodeId];
_missionRecord set ["supplyObjectiveId", _sourceObjective];
true
