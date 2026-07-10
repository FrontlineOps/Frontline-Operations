/* Validates the persisted operation allocation against treasury commitments. */
params ["_director"];

private _state = _director get "_state";
private _reservationId = _state get "resourceReservationId";
private _expectedRemaining = (_state get "resourceBudget") - (_state get "resourceSpent") - (_state get "resourceReleased");
if (_expectedRemaining < -0.001) then {
    throw format ["Operation %1 overspent its resource budget", _state get "operationId"];
};

private _activePhase = (_state get "phase") in ["PREPARE", "ASSAULT", "SECURE", "CONSOLIDATE"];
if (!_activePhase && {_reservationId != ""}) then {
    throw format ["Inactive operation %1 retained reservation %2", _state get "operationId", _reservationId];
};
if (_activePhase && {_expectedRemaining > 0.001} && {_reservationId == ""}) then {
    throw format ["Active operation %1 is missing its treasury reservation", _state get "operationId"];
};

private _actualRemaining = 0;
{
    private _treasury = _y;
    {
        private _reservation = _y;
        if ((_reservation get "category") != "OPERATION") then { continue };
        if (_x != _reservationId) then {
            throw format ["Stale campaign treasury reservation %1 on side %2", _x, _treasury get "_sideKey"];
        };
        _actualRemaining = _reservation get "remaining";
    } forEach (_treasury get "_reservations");
} forEach FLO_SideResources;

if (abs (_actualRemaining - (_expectedRemaining max 0)) > 0.001) then {
    throw format [
        "Operation %1 reservation mismatch: state=%2 treasury=%3",
        _state get "operationId",
        _expectedRemaining,
        _actualRemaining
    ];
};
true
