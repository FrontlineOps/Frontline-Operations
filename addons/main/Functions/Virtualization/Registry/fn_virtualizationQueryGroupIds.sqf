/*
 * Function: FLO_fnc_virtualizationQueryGroupIds
 * Description:
 *   Returns IDs for records matching every supplied schema field. Registry
 *   records remain private to virtualization.
 */

params [["_criteria", createHashMap, [createHashMap]]];

private _defaults = call FLO_fnc_virtualizationCreateGroupRecordDefaults;
{
    private _field = _x;
    if !(_field in _defaults) then {
        throw format ["Virtual group query contains unknown field %1", _field];
    };
    if !(_y isEqualType (_defaults get _field)) then {
        throw format ["Virtual group query field %1 has invalid type %2", _field, typeName _y];
    };
} forEach _criteria;

private _matches = [];
{
    private _groupId = _x;
    private _groupData = _y;
    private _matchesAll = true;

    {
        if ((_groupData get _x) isNotEqualTo _y) exitWith {
            _matchesAll = false;
        };
    } forEach _criteria;

    if (_matchesAll) then {
        _matches pushBack _groupId;
    };
} forEach (call FLO_fnc_virtualizationGetGroupMap);

_matches
