/*
 * Function: FLO_fnc_virtualizationGetOrganicPackageInfantryCount
 */

params ["_carrierData"];

private _dismountCounts = [_carrierData] call FLO_fnc_virtualizationGetOrganicPackageInfantryCounts;
private _dismountCount = 0;
{
    _dismountCount = _dismountCount + _x;
} forEach _dismountCounts;

_dismountCount
