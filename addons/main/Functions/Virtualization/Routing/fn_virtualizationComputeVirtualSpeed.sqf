/*
 * Function: FLO_fnc_virtualizationComputeVirtualSpeed
 */

params ["_groupData", "_wpSpeed"];

private _groupType = _groupData get "groupType";
private _archetype = [_groupType] call FLO_fnc_virtualizationGetArchetype;
private _speedMPS = [_groupData] call FLO_fnc_virtualizationResolveMoveSpeedMps;

if (_speedMPS <= 0) then {
    _speedMPS = _archetype get "baseSpeedMps";
};

private _terrainFactor = _archetype get "terrainFactor";

private _speedScale = switch (_wpSpeed) do {
    case "LIMITED": { 0.33 };
    case "NORMAL": { 0.66 };
    case "FULL": { 1 };
    default { 0.66 };
};

(_speedMPS * _terrainFactor * _speedScale) max 1
