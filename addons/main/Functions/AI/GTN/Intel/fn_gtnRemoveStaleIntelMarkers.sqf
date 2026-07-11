params ["_registry", "_seen"];

private _removed = 0;
{
    if !(_x in _seen) then {
        deleteMarkerLocal _x;
        _registry deleteAt _x;
        _removed = _removed + 1;
    };
} forEach (keys _registry);

_removed
