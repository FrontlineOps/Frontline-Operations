/*
 * Function: FLO_fnc_factionBuildMergedAutoCivilianCatalog
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds one civilian catalog from multiple auto-detected civilian
 *   CfgFactionClasses entries.
 *
 * Arguments:
 *   0: Faction classnames <ARRAY>
 *
 * Return Value:
 *   HASHMAP with keys men, vehicles
 */

params [["_factionClasses", [], [[]]]];

private _classes = _factionClasses select { _x isEqualType "" && {_x != ""} };
_classes = _classes arrayIntersect _classes;

private _men = [];
private _vehicles = [];

{
    private _catalog = [_x] call FLO_fnc_factionBuildAutoCivilianCatalog;
    {
        _men pushBackUnique _x;
    } forEach (_catalog get "men");
    {
        _vehicles pushBackUnique _x;
    } forEach (_catalog get "vehicles");
} forEach _classes;

["FACTIONS", 2, format [
    "Merged auto civilian factions %1: men=%2 vehicles=%3",
    _classes,
    count _men,
    count _vehicles
]] call FLO_fnc_log;

createHashMapFromArray [
    ["men", _men],
    ["vehicles", _vehicles]
]
