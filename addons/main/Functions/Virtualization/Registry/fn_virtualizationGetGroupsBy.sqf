/*
 * Function: FLO_fnc_virtualizationGetGroupsBy
 */

params ["_virt", "_criteria"];

private _groups = _virt get "_groups";
private _result = [];

{
    private _match = true;
    {
        private _key = _x;
        private _val = _criteria get _key;
        if ((_y get _key) isNotEqualTo _val) then {
            _match = false;
        };
    } forEach _criteria;

    if (_match) then {
        _result pushBack [_x, _y];
    };
} forEach _groups;

_result
