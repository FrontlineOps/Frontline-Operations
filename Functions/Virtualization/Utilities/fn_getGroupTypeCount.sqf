/*
 * Function: FLO_fnc_getGroupTypeCount
 * Author: Frontline Operations Development Group
 * Description:
 * Returns the unit/vehicle count for a given group type from side-scoped faction group counts.
 * Falls back to 1 and logs an error if the group type is not found.
 *
 * Arguments:
 * 0: Group Type <STRING>
 * 1: Side <SIDE> - Optional side for side-scoped group count catalog
 *
 * Return Value:
 * Count <NUMBER>
 *
 * Example:
 * ["helicopter"] call FLO_fnc_getGroupTypeCount;
 */

params [
    ["_groupType", "infantry", [""]],
    ["_side", east]
];

private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
private _sideKey = _sideCtx get "sideKey";

private _catalog = FLO_FactionCatalog get _sideKey;
private _groupCounts = _catalog get "groupCounts";

private _entry = _groupCounts select { _x select 0 isEqualTo _groupType };
if (count _entry > 0) then {
    (_entry select 0) select 1
} else {
    diag_log format ["[VIRTUALIZATION] ERROR: No unit count defined for group type %1 (%2), using default 1", _groupType, _sideKey];
    1
}; 
