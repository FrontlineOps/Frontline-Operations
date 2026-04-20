/*
 * Function: FLO_fnc_virtualizationResolveCrewType
 */

params ["_vehicleType", "_fallbackUnits", "_sideKey", "_groupType"];

// Prefer custom faction crew pool if available, otherwise fallback to engine default
private _crewType = "";
if (!isNil "_fallbackUnits" && {count _fallbackUnits > 0}) then {
    _crewType = selectRandom _fallbackUnits;
} else {
    _crewType = getText (configFile >> "CfgVehicles" >> _vehicleType >> "crew");
};

if (_crewType == "") then {
    [_fallbackUnits, "crewUnits", _sideKey, _groupType] call FLO_fnc_virtualizationRequirePoolEntries;
};

_crewType
