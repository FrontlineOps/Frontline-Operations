/*
 * Function: FLO_fnc_virtualizationComputeVirtualSpeed
 */

params ["_groupData", "_wpSpeed"];

private _groupType = _groupData get "groupType";
private _platformClass = [_groupData] call FLO_fnc_virtualizationResolveMovePlatformClass;
private _speedMPS = 0;

if (_platformClass != "") then {
    private _cfg = configFile >> "CfgVehicles" >> _platformClass;
    if (isClass _cfg) then {
        private _maxSpeed = getNumber (_cfg >> "maxSpeed");
        if (_maxSpeed > 0) then {
            _speedMPS = (_maxSpeed * 1000) / 3600;
        };
    };
};

if (_speedMPS <= 0) then {
    _speedMPS = switch (_groupType) do {
        case "infantry";
        case "civilian";
        case "civ_pedestrian";
        case "civ_building": { 6.5 };
        case "motorized": { 18 };
        case "mechanized": { 15 };
        case "armor";
        case "mobile_aa";
        case "artillery";
        case "static_aa": { 12 };
        case "helicopter";
        case "air": { 65 };
        case "jet": { 180 };
        case "civilianVehicle";
        case "civ_car": { 14 };
        default { 6.5 };
    };
};

private _terrainFactor = switch (_groupType) do {
    case "motorized": { 0.75 };
    case "mechanized": { 0.7 };
    case "armor";
    case "mobile_aa";
    case "artillery";
    case "static_aa": { 0.65 };
    case "helicopter";
    case "air": { 0.9 };
    default { 1 };
};

private _speedScale = switch (_wpSpeed) do {
    case "LIMITED": { 0.33 };
    case "NORMAL": { 0.66 };
    case "FULL": { 1 };
    default { 0.66 };
};

(_speedMPS * _terrainFactor * _speedScale) max 1
