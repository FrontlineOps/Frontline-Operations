/*
 * Function: FLO_fnc_gtnArtilleryAuthorizeMission
 * Description:
 *   Atomically authorizes one executable artillery mission against shared
 *   cooldown, treasury, and connected Local Supplies state.
 */

params [
    ["_manager", nil],
    ["_groupId", "", [""]],
    ["_groupData", nil],
    ["_requestSide", sideUnknown],
    ["_objectiveId", "", [""]],
    ["_missionRecord", nil]
];

if (!isServer) then {
    throw "Artillery mission authorization is server-owned";
};
if (isNil "_manager" || {isNil "_groupData"} || {isNil "_missionRecord"}) then {
    throw "Artillery mission authorization requires manager, group, and mission state";
};
if (_groupId == "") then {
    throw "Artillery mission authorization requires a battery group ID";
};
if !(_requestSide in [east, west]) exitWith {
    ["GTN Artillery", 1, format ["Rejected artillery mission %1 with invalid request side %2", _missionRecord get "missionId", _requestSide]] call FLO_fnc_log;
    false
};
if ((_groupData get "side") isNotEqualTo _requestSide) then {
    throw format ["Artillery battery %1 belongs to %2, not request side %3", _groupId, _groupData get "side", _requestSide];
};

private _cooldownStatus = [_manager, _requestSide, _objectiveId, _groupId] call FLO_fnc_gtnArtilleryCanRequestMission;
if !(_cooldownStatus select 0) exitWith { false };

private _rounds = _missionRecord get "plannedRounds";
private _costs = [_manager, _rounds] call FLO_fnc_gtnArtilleryCalculateMissionCost;
_costs params ["_treasuryCost", "_localSupplyCost"];

private _sideKey = [_requestSide] call FLO_fnc_sideKey;
private _network = FLO_Logistics_Networks get _sideKey;
private _treasury = FLO_SideResources get _sideKey;
private _batteryObjectiveId = [
    _network,
    _groupData get "position",
    _groupData get "homeObjective"
] call FLO_fnc_logisticsNetworkResolveNodeObjective;

if (_batteryObjectiveId == "") exitWith {
    ["GTN Artillery", 3, format [
        "%1 artillery mission denied - battery %2 is outside secured logistics reach",
        _sideKey,
        _groupId
    ]] call FLO_fnc_log;
    false
};

private _sourceObjectiveId = [
    _network,
    _batteryObjectiveId,
    [],
    _localSupplyCost
] call FLO_fnc_logisticsNetworkFindSupplySourceObjective;

if (_sourceObjectiveId == "") exitWith {
    ["GTN Artillery", 3, format [
        "%1 artillery mission denied - no connected source can provide %2 Local Supplies to battery %3",
        _sideKey,
        _localSupplyCost,
        _groupId
    ]] call FLO_fnc_log;
    false
};

private _source = (_network get "_activeSupplyNodes") get _sourceObjectiveId;
private _sourceNodeId = _source get "nodeId";
private _missionId = _missionRecord get "missionId";
private _requestKind = _missionRecord get "requestKind";
private _reservationId = format ["ARTILLERY:%1:%2", _sideKey, _missionId];
private _reason = format ["%1 artillery mission (%2 rounds)", _requestKind, _rounds];
private _spendingActor = ["COMMANDER", "PLAYER"] select (_requestKind == "PLAYER");
private _spendingAllowed = true;
if (_requestKind != "PLAYER") then {
    private _urgency = ["OPERATIONAL", "PRESSURED"] select (_requestKind in ["COUNTER_BATTERY", "VIRTUAL_COMBAT"]);
    private _spendingDecision = [
        _treasury,
        _treasuryCost,
        "ARTILLERY",
        _urgency,
        createHashMapFromArray [
            ["strategic", true],
            ["commitment", false],
            ["reserved", false],
            ["referenceId", _missionId]
        ]
    ] call FLO_fnc_commanderSpendingEvaluate;
    _spendingAllowed = _spendingDecision get "allowed";
};
if (!_spendingAllowed) exitWith { false };

if !(_treasury call ["reserve", [
    _reservationId,
    _treasuryCost,
    "ARTILLERY",
    _reason,
    _spendingActor,
    _missionId
]]) exitWith {
    ["GTN Artillery", 3, format [
        "%1 artillery mission denied - treasury cannot commit %2 resources",
        _sideKey,
        _treasuryCost
    ]] call FLO_fnc_log;
    false
};

if !([_network, _sourceNodeId, _localSupplyCost, _reason] call FLO_fnc_logisticsNetworkConsumeThroughput) exitWith {
    _treasury call ["releaseReservation", [_reservationId, "Artillery source Local Supplies changed"]];
    false
};

if !(_treasury call ["commitReservation", [_reservationId, _treasuryCost, _reason]]) then {
    [_network, _sourceNodeId, _localSupplyCost, "Artillery authorization rollback"] call FLO_fnc_logisticsNetworkRestoreThroughput;
    _treasury call ["releaseReservation", [_reservationId, "Artillery authorization rollback"]];
    throw format ["Artillery reservation %1 failed during commit", _reservationId];
};

private _now = diag_tickTime;
private _sideReadyAt = _now + FLO_ArtillerySideCooldownSeconds;
private _batteryReadyAt = _now + FLO_ArtilleryBatteryCooldownSeconds;
(_manager get "sideCooldowns") set [_sideKey, _sideReadyAt];
(_manager get "batteryCooldowns") set [_groupId, _batteryReadyAt];

if (_objectiveId != "") then {
    (_manager get "objectiveCooldowns") set [
        format ["%1:%2", _sideKey, _objectiveId],
        _now + (_manager get "objectiveCooldownSeconds")
    ];
};

_missionRecord set ["treasuryCost", _treasuryCost];
_missionRecord set ["localSupplyCost", _localSupplyCost];
_missionRecord set ["supplyNodeId", _sourceNodeId];
_missionRecord set ["supplyObjectiveId", _sourceObjectiveId];
_missionRecord set ["sideReadyAt", _sideReadyAt];
_missionRecord set ["batteryReadyAt", _batteryReadyAt];

["GTN Artillery", 3, format [
    "%1 authorized %2 mission %3 from battery %4: %5 resources, %6 Local Supplies at %7",
    _sideKey,
    _requestKind,
    _missionId,
    _groupId,
    _treasuryCost,
    _localSupplyCost,
    _sourceNodeId
]] call FLO_fnc_log;

true
