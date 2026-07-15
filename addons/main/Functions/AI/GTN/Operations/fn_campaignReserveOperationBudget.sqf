/* Reserves a bounded treasury allocation for one operation. */
params [
    "_director",
    ["_operationId", "", [""]],
    ["_budgetOverride", -1, [0]]
];

private _operation = [_director, _operationId] call FLO_fnc_campaignGetOperation;
if ((_operation get "resourceReservationId") != "") then {
    throw format ["Operation %1 already owns a treasury reservation", _operationId];
};

private _sideKey = _operation get "attackerSideKey";
private _budget = _budgetOverride;
if (_budget < 0) then {
    _budget = [
        _director,
        _sideKey,
        _operation get "priorityRole"
    ] call FLO_fnc_campaignCalculateOperationBudget;
};
if (_budget <= 0) then {
    throw format ["Operation %1 cannot reserve its minimum campaign budget", _operationId];
};

private _treasury = FLO_SideResources get _sideKey;
private _reservationId = format ["OPERATION:%1", _operationId];
if !(_treasury call ["reserve", [
    _reservationId,
    _budget,
    "OPERATION",
    format ["Campaign operation %1", _operationId],
    "COMMANDER",
    _operation get "objectiveId"
]]) then {
    throw format ["Failed to reserve %1 for campaign operation %2", _budget, _operationId];
};

_operation set ["resourceReservationId", _reservationId];
_operation set ["resourceBudget", _budget];
_operation set ["resourceSpent", 0];
_operation set ["resourceReleased", 0];
[(_director get "_state")] call FLO_fnc_campaignSyncPrimaryProjection;
_reservationId
