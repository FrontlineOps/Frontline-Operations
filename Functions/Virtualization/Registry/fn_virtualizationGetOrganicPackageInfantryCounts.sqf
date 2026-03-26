/*
 * Function: FLO_fnc_virtualizationGetOrganicPackageInfantryCounts
 */

params ["_carrierData"];

private _groupType = _carrierData get "groupType";
if !(_groupType in ["motorized", "mechanized"]) exitWith { [] };

private _composition = _carrierData get "comp";
if (_composition isEqualTo []) then {
    throw format [
        "FLO_fnc_virtualizationGetOrganicPackageInfantryCounts: %1 group missing carrier composition",
        _groupType
    ];
};

private _dismountCounts = [];
{
    private _capacity = [_x] call FLO_fnc_transportGetCapacity;
    if (_capacity > 0) then {
        _dismountCounts pushBack _capacity;
    };
} forEach _composition;

if (count _dismountCounts == 0) then {
    ["VIRTUALIZATION", 2, format [
        "Skipping organic %1 package for carrier composition %2 - no cargo capacity",
        _groupType,
        _composition
    ]] call FLO_fnc_log;
};

_dismountCounts
