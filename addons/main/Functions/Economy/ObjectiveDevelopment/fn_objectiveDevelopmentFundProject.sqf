params [
    ["_side", sideUnknown, [west]],
    ["_objectiveId", "", [""]]
];

if !(_side in [west, east]) then { throw format ["Invalid Development funding side %1", _side]; };
if !(_objectiveId in FLO_Objectives) then { throw format ["Cannot fund missing Development objective %1", _objectiveId]; };
private _objective = FLO_Objectives get _objectiveId;
[_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
private _project = _objective get "developmentProject";
if ((_project get "state") != "FUNDING") then {
    throw format ["Development project %1 is not awaiting funding", _objectiveId];
};
if ((_objective get "owner") isNotEqualTo _side) then {
    throw format ["Development funding owner changed outside capture handler at %1", _objectiveId];
};
if ((_objective get "campaignIntegrationState") != "INTEGRATED") exitWith { false };
private _enemyCountKey = ["opforCount", "bluforCount"] select (_side isEqualTo east);
if ((_objective get "contested") || {_objective get "underAttack"} || {(_objective get _enemyCountKey) > 0}) exitWith { false };

private _sideKey = [_side] call FLO_fnc_sideKey;
private _network = FLO_Logistics_Networks get _sideKey;
[_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
private _supplyPerTick = FLO_ObjectiveDevelopmentConfig get "commanderSupplyPerTick";
if (([_network, _objectiveId, [], _supplyPerTick] call FLO_fnc_logisticsNetworkFindSupplySourceObjective) == "") exitWith { false };

private _treasury = FLO_SideResources get _sideKey;
private _reservationId = _project get "reservationId";
private _reservations = _treasury get "_reservations";
if !(_reservationId in _reservations) then {
    throw format ["Development project %1 is missing reservation %2", _objectiveId, _reservationId];
};
private _reserved = (_reservations get _reservationId) get "remaining";
private _fundingRemaining = (_project get "treasuryCost") - _reserved;
if (_fundingRemaining < 0) then {
    throw format ["Development project %1 reservation exceeds its treasury cost", _objectiveId];
};
if (_fundingRemaining == 0) exitWith {
    [_objectiveId] call FLO_fnc_objectiveDevelopmentActivateFundedProject
};

private _fundingAmount = [_treasury, _fundingRemaining] call FLO_fnc_commanderSpendingGetDevelopmentFundingAmount;
if (_fundingAmount <= 0) exitWith { false };
if !([_treasury, _reservationId, _fundingAmount, format ["Continued funding at %1", _objectiveId]] call FLO_fnc_sideResourcesIncreaseReservation) then {
    throw format ["Development project %1 could not reserve approved funding amount %2", _objectiveId, _fundingAmount];
};

private _nextReserved = _reserved + _fundingAmount;
if (_nextReserved == (_project get "treasuryCost")) exitWith {
    [_objectiveId] call FLO_fnc_objectiveDevelopmentActivateFundedProject
};
["ECONOMY", 3, format [
    "%1 funded %2 at %3 reserved=%4/%5",
    _sideKey,
    _project get "branch",
    _objectiveId,
    _nextReserved,
    _project get "treasuryCost"
]] call FLO_fnc_log;
true
