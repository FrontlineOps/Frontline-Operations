/*
 * Function: FLO_fnc_filterNonCivGroups
 * Author: Azraeelian Angel
 * Description:
 * Filters out civilian and civilianVehicle groups from a hashmap
 *
 * Arguments:
 * 0: Groups hashmap to filter <HASHMAP>
 *
 * Return Value:
 * Filtered hashmap <HASHMAP>
 *
 * Example:
 * [_groupsMap] call FLO_fnc_filterNonCivGroups;
 */

params ["_groupsMap"];
private _result = createHashMap;
{
    private _groupType = _y get "groupType";
    if (!(_groupType in ["civilian", "civilianVehicle"])) then {
        _result set [_x, _y];
    };
} forEach _groupsMap;
_result
