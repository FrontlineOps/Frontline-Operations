/*
 * Function: FLO_fnc_factionBuildMergedAutoMilitaryCatalog
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds one FLO military faction catalog from multiple auto-detected
 *   CfgFactionClasses entries.
 *
 * Arguments:
 *   0: Faction classnames <ARRAY>
 *
 * Return Value:
 *   HASHMAP matching a side entry in FLO_FactionCatalog
 */

params [["_factionClasses", [], [[]]]];

private _classes = _factionClasses select { _x isEqualType "" && {_x != ""} };
_classes = _classes arrayIntersect _classes;

private _empty = createHashMap;
if (_classes isEqualTo []) exitWith { _empty };

private _arrayFields = [
    "groups",
    "units",
    "officers",
    "groundInfantryGroups",
    "groundInfantryUnits",
    "groundSpecOpsGroups",
    "groundSpecOpsUnits",
    "groundMotorized",
    "groundMechanized",
    "groundArmor",
    "groundTransport",
    "groundArtillery",
    "airHeli",
    "airJet",
    "airTransport",
    "airDrone",
    "groundDrone",
    "mobileAA",
    "staticAA",
    "boat",
    "radar"
];

private _mergedPairs = [
    ["source", "auto_multi"],
    ["factionClass", _classes select 0],
    ["factionClasses", _classes]
];

{
    _mergedPairs pushBack [_x, []];
} forEach _arrayFields;

private _merged = createHashMapFromArray _mergedPairs;
private _catalogs = [];

{
    private _catalog = [_x] call FLO_fnc_factionBuildAutoMilitaryCatalog;
    if ((count keys _catalog) == 0) then {
        ["FACTIONS", 2, format ["Skipping empty auto faction catalog while merging: %1", _x]] call FLO_fnc_log;
        continue;
    };

    _catalogs pushBack _catalog;

    {
        private _field = _x;
        private _values = _merged get _field;
        {
            _values pushBackUnique _x;
        } forEach (_catalog get _field);
        _merged set [_field, _values];
    } forEach _arrayFields;
} forEach _classes;

if (_catalogs isEqualTo []) exitWith { _empty };

private _baseCatalog = _catalogs select 0;
{
    _merged set [_x, _baseCatalog get _x];
} forEach [
    "transportReserveGroundCount",
    "transportReserveAirCount",
    "objectiveGroups",
    "objectiveGroupTypeCaps",
    "groupCounts"
];

if ((_merged get "officers") isEqualTo [] && {(_merged get "groundInfantryUnits") isNotEqualTo []}) then {
    private _officer = [_merged get "groundInfantryUnits", "officer"] call FLO_fnc_factionPickUnitByRole;
    if (_officer != "") then {
        _merged set ["officers", [_officer]];
    };
};

["FACTIONS", 2, format [
    "Merged auto military factions %1: units=%2 groups=%3 motorized=%4 mechanized=%5 armor=%6 mobileAA=%7 staticAA=%8 air=%9",
    _classes,
    count (_merged get "groundInfantryUnits"),
    count (_merged get "groundInfantryGroups"),
    count (_merged get "groundMotorized"),
    count (_merged get "groundMechanized"),
    count (_merged get "groundArmor"),
    count (_merged get "mobileAA"),
    count (_merged get "staticAA"),
    count ((_merged get "airHeli") + (_merged get "airJet"))
]] call FLO_fnc_log;

_merged
