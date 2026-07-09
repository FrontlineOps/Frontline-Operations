/*
 * Function: FLO_fnc_virtualizationGetGroundCombatVehiclePool
 */

params ["_groupType", "_pools"];

private _vehiclePool = switch (_groupType) do {
    case "motorized": { _pools get "groundMotorized" };
    case "mechanized": { _pools get "groundMechanized" };
    case "armor": { _pools get "groundArmor" };
    case "mobile_aa": { _pools get "mobileAA" };
    default { [] };
};

private _vehiclePoolName = switch (_groupType) do {
    case "motorized": { "groundMotorized" };
    case "mechanized": { "groundMechanized" };
    case "armor": { "groundArmor" };
    case "mobile_aa": { "mobileAA" };
    default { _groupType };
};

[_vehiclePool, _vehiclePoolName]
