/* Validates every operation allocation against treasury commitments. */
params ["_director"];

private _state = _director get "_state";
[_state] call FLO_fnc_campaignSyncPrimaryProjection;
private _operations = _state get "operations";
private _expectedReservations = createHashMap;

{
    private _operationId = _x;
    private _operation = _y;
    private _reservationId = _operation get "resourceReservationId";
    private _expectedRemaining = (_operation get "resourceBudget")
        - (_operation get "resourceSpent")
        - (_operation get "resourceReleased");
    if (_expectedRemaining < -0.001) then {
        throw format ["Operation %1 overspent its resource budget", _operationId];
    };

    private _activePhase = (_operation get "phase") in ["ASSAULT", "SECURE", "CONSOLIDATE"];
    if (!_activePhase && {_reservationId != ""}) then {
        throw format ["Inactive operation %1 retained reservation %2", _operationId, _reservationId];
    };
    if (!_activePhase && {_expectedRemaining > 0.001}) then {
        throw format ["Inactive operation %1 retained %2 expected resources", _operationId, _expectedRemaining];
    };
    if (_activePhase && {_expectedRemaining > 0.001} && {_reservationId == ""}) then {
        throw format ["Active operation %1 is missing its treasury reservation", _operationId];
    };
    if (_reservationId != "") then {
        if (_reservationId in _expectedReservations) then {
            throw format ["Campaign operations share reservation %1", _reservationId];
        };
        _expectedReservations set [_reservationId, createHashMapFromArray [
            ["operationId", _operationId],
            ["sideKey", _operation get "attackerSideKey"],
            ["remaining", _expectedRemaining max 0]
        ]];
    };
} forEach _operations;

private _actualReservations = createHashMap;
{
    private _treasury = _y;
    {
        private _reservationId = _x;
        private _reservation = _y;
        if ((_reservation get "category") != "OPERATION") then { continue };
        if !(_reservationId in _expectedReservations) then {
            throw format ["Stale campaign treasury reservation %1 on side %2", _reservationId, _treasury get "_sideKey"];
        };
        private _expected = _expectedReservations get _reservationId;
        if ((_expected get "sideKey") != (_treasury get "_sideKey")) then {
            throw format ["Operation reservation %1 exists on the wrong side treasury", _reservationId];
        };
        _actualReservations set [_reservationId, _reservation get "remaining"];
    } forEach (_treasury get "_reservations");
} forEach FLO_SideResources;

{
    private _reservationId = _x;
    private _expected = _y;
    if !(_reservationId in _actualReservations) then {
        throw format ["Operation %1 reservation %2 is absent from the treasury", _expected get "operationId", _reservationId];
    };
    private _actualRemaining = _actualReservations get _reservationId;
    if (abs (_actualRemaining - (_expected get "remaining")) > 0.001) then {
        throw format [
            "Operation %1 reservation mismatch: state=%2 treasury=%3",
            _expected get "operationId",
            _expected get "remaining",
            _actualRemaining
        ];
    };
} forEach _expectedReservations;
true
