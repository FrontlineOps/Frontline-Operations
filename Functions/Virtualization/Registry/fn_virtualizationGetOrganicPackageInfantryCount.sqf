/*
 * Function: FLO_fnc_virtualizationGetOrganicPackageInfantryCount
 */

params ["_carrierData"];

private _groupType = _carrierData get "groupType";
if !(_groupType in ["motorized", "mechanized"]) exitWith { 0 };

private _composition = _carrierData get "comp";
if (_composition isEqualTo []) then {
    throw format [
        "FLO_fnc_virtualizationGetOrganicPackageInfantryCount: %1 group missing carrier composition",
        _groupType
    ];
};

private _dismountCount = 0;
{
    _dismountCount = _dismountCount + ([_x] call FLO_fnc_transportGetCapacity);
} forEach _composition;

if (_dismountCount <= 0) then {
    ["VIRTUALIZATION", 2, format [
        "Skipping organic %1 package for carrier composition %2 - no cargo capacity",
        _groupType,
        _composition
    ]] call FLO_fnc_log;
    0
};

_dismountCount
