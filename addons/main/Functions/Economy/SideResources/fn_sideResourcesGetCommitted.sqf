params ["_treasury"];

private _committed = 0;
{
    private _remaining = _y get "remaining";
    if !(_remaining isEqualType 0 && {_remaining >= 0}) then {
        throw format ["Invalid remaining amount in reservation %1: %2", _x, _remaining];
    };
    _committed = _committed + _remaining;
} forEach (_treasury get "_reservations");

_committed
