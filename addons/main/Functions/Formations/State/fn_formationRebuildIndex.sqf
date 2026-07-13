/* Rebuilds the non-persisted group-to-formation index. */
params ["_state"];

private _index = createHashMap;
{
    private _formationId = _x;
    {
        if (_x in _index) then {
            throw format ["Group %1 is indexed by multiple formations", _x];
        };
        _index set [_x, _formationId];
    } forEach (_y get "memberIds");
} forEach (_state get "formations");
_state set ["groupToFormation", _index];
_index
