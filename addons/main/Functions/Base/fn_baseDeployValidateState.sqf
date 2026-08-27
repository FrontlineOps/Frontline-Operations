params ["_state"];

if !(_state isEqualType createHashMap) then {
    throw format ["Base deployment claim state must be a HashMap, got %1", typeName _state];
};

private _expectedKeys = ["WEST", "EAST"];
{
    if !(_x in _state) then {
        throw format ["Base deployment claim state is missing %1", _x];
    };

    private _claimed = _state get _x;
    if !(_claimed isEqualType true) then {
        throw format ["Base deployment claim state for %1 must be Boolean, got %2", _x, typeName _claimed];
    };
} forEach _expectedKeys;

true
