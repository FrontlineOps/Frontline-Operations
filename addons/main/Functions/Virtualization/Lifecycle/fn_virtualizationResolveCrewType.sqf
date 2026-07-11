/*
 * Function: FLO_fnc_virtualizationResolveCrewType
 */

params ["_vehicleType", "_fallbackUnits", "_sideKey", "_groupType"];

private _crewType = getText (configFile >> "CfgVehicles" >> _vehicleType >> "crew");
if (_crewType == "") then {
    [_fallbackUnits, "units", _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries;
    _crewType = selectRandom _fallbackUnits;
};

_crewType
