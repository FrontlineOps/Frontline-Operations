/*
 * Function: FLO_fnc_factionExtractVehicleClasses
 * Author: Frontline Operations Development Group
 * Description:
 *   Extracts vehicle class names from faction list entries. Entries may be
 *   plain class strings or array records whose first element is the class.
 *
 * Arguments:
 * 0: List <ARRAY|STRING>
 *
 * Returns:
 * Vehicle classes <ARRAY>
 */
params [["_list", []]];

if (_list isEqualType "") then {
    _list = [_list];
};
if (!(_list isEqualType [])) exitWith { [] };

private _result = [];
{
    if (_x isEqualType []) then {
        if (_x isNotEqualTo []) then {
            private _cls = _x select 0;
            if (_cls isEqualType "" && {_cls != ""}) then {
                _result pushBackUnique _cls;
            };
        };
    } else {
        if (_x isEqualType "" && {_x != ""}) then {
            _result pushBackUnique _x;
        };
    };
} forEach _list;

_result
