/*
 * Function: FLO_fnc_virtualizationEstimateVehicleCrewCount
 */

params ["_vehicleClass"];

private _cfg = configFile >> "CfgVehicles" >> _vehicleClass;
if !(isClass _cfg) then {
    throw format ["FLO_fnc_virtualizationEstimateVehicleCrewCount: invalid vehicle class '%1'", _vehicleClass];
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
