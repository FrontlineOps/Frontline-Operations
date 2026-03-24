/*
 * Function: FLO_fnc_virtualizationComputeVirtualSpeed
 */

params ["_groupType", "_wpSpeed"];

private _speedMPS = switch (_wpSpeed) do {
    case "LIMITED": { 2 };
    case "NORMAL": { 4 };
    case "FULL": { 8 };
    default { 4 };
};

private _speedMultiplier = switch (_groupType) do {
    case "infantry": { 1.0 };
    case "motorized": { 2.5 };
    case "mechanized": { 2.0 };
    case "armor": { 1.8 };
    case "helicopter";
    case "air": { 6.0 };
    case "jet": { 10.0 };
    default { 1.0 };
};

_speedMPS * _speedMultiplier
