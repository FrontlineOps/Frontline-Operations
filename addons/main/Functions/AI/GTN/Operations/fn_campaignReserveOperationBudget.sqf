/* Reserves a bounded share of the attacker's available treasury for one operation. */
params ["_director"];

private _state = _director get "_state";
private _operationId = _state get "operationId";
if (_operationId == "") then { throw "Cannot reserve a campaign budget without an operation ID"; };
if ((_state get "resourceReservationId") != "") then {
    throw format ["Operation %1 already owns a treasury reservation", _operationId];
};

private _sideKey = _state get "attackerSideKey";
private _treasury = FLO_SideResources get _sideKey;
private _config = _director get "_config";
private _available = [_treasury] call FLO_fnc_sideResourcesGetAvailable;
private _budget = round (_available * (_config get "operationBudgetFraction"));
_budget = ((_budget max (_config get "operationBudgetMinimum")) min (_config get "operationBudgetMaximum")) min _available;

_state set ["resourceBudget", _budget];
_state set ["resourceSpent", 0];
_state set ["resourceReleased", 0];
if (_budget <= 0) exitWith { "" };

private _reservationId = format ["OPERATION:%1", _operationId];
if !(_treasury call ["reserve", [
    _reservationId,
    _budget,
    "OPERATION",
    format ["Campaign operation %1", _operationId],
    "COMMANDER",
    _state get "objectiveId"
]]) then {
    throw format ["Failed to reserve %1 for campaign operation %2", _budget, _operationId];
};

_state set ["resourceReservationId", _reservationId];
_reservationId
