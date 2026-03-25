/*
 * Function: FLO_fnc_virtualizationGetGroundCombatVehiclePool
 */

params ["_groupType", "_pools"];

private _vehiclePool = switch (_groupType) do {
    case "motorized": { _pools get "groundLight" };
    case "mechanized";
    case "armor": { _pools get "groundHeavy" };
    case "mobile_aa": { _pools get "mobileAA" };
    default { [] };
};

private _vehiclePoolName = switch (_groupType) do {
    case "motorized": { "groundLight" };
    case "mechanized";
    case "armor": { "groundHeavy" };
    case "mobile_aa": { "mobileAA" };
    default { _groupType };
};

[_vehiclePool, _vehiclePoolName]
