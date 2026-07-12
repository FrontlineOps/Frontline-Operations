params ["_map"];

private _playerPosition = getPosATL player;
_map drawIcon [
    FLO_SupportPlayerIcon,
    [1, 1, 1, 1],
    _playerPosition,
    24,
    24,
    0,
    format ["YOU / %1", mapGridPosition _playerPosition],
    2,
    0.034,
    "RobotoCondensedBold",
    "right"
];

if (FLO_SupportTargetPosition isEqualTo []) exitWith {};

private _color = switch (FLO_SupportSelectedType) do {
    case "ARTY": { [1, 0.72, 0.29, 1] };
    case "CAS": { [1, 0.33, 0.41, 1] };
    case "CAP": { [0.15, 0.84, 1, 1] };
    default { throw format ["FLO_fnc_supportDrawMap: unsupported support type %1", FLO_SupportSelectedType] };
};
private _dangerCloseRadius = switch (FLO_SupportSelectedType) do {
    case "ARTY": { 250 };
    case "CAS": { 175 };
    case "CAP": { 0 };
};

if (_dangerCloseRadius > 0) then {
    private _fill = +_color;
    _fill set [3, 0.12];
    _map drawEllipse [FLO_SupportTargetPosition, _dangerCloseRadius, _dangerCloseRadius, 0, _color, ""];
    _map drawEllipse [FLO_SupportTargetPosition, _dangerCloseRadius, _dangerCloseRadius, 0, _fill, "#(rgb,8,8,3)color(1,1,1,0.12)"];
};

_map drawIcon [
    FLO_SupportTargetIcon,
    _color,
    FLO_SupportTargetPosition,
    30,
    30,
    0,
    format ["%1 / %2", FLO_SupportSelectedType, mapGridPosition FLO_SupportTargetPosition],
    2,
    0.038,
    "RobotoCondensedBold",
    "right"
];
