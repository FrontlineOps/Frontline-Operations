/*
 * Function: FLO_fnc_virtualizationEstimateVehicleCrewCount
 */

params ["_vehicleClass"];

private _cfg = configFile >> "CfgVehicles" >> _vehicleClass;
if !(isClass _cfg) exitWith {
    diag_log format ["[VIRTUALIZATION][WARN] Invalid vehicle class for crew estimation: %1", _vehicleClass];
    3 // Fallback to standard crew count estimate
};

private _crewCount = if (getNumber (_cfg >> "hasDriver") == 0) then { 0 } else { 1 };
private _turretStacks = [_cfg >> "Turrets"];

while {count _turretStacks > 0} do {
    private _turretsCfg = _turretStacks deleteAt ((count _turretStacks) - 1);
    {
        _crewCount = _crewCount + 1;
        _turretStacks pushBack (_x >> "Turrets");
    } forEach (configProperties [_turretsCfg, "isClass _x", false]);
};

(_crewCount max 1)
