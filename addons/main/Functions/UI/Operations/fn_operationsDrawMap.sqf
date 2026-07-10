/*
 * Function: FLO_fnc_operationsDrawMap
 * Description:
 *   Draws cached operation markers over the native Arma terrain map.
 */

params ["_map"];

if (FLO_OperationsMapDrawData isEqualTo []) exitWith {};

private _mapScale = ctrlMapScale _map;
private _selectedId = FLO_OperationsSelectedObjectiveId;

{
    _x params ["_from", "_to", "_state"];
    private _routeColor = [[0.37, 0.44, 0.52, 0.58], [0.65, 1, 0.35, 0.72]] select (_state == "CONNECTED");
    _map drawLine [_from, _to, _routeColor];
} forEach FLO_OperationsMapRouteDrawData;

{
    _x params ["_nodeId", "_position", "_type", "_state", "_throughput", "_throughputMax"];
    private _nodeColor = switch (_state) do {
        case "CONNECTED": { [0.65, 1, 0.35, 1] };
        case "STRAINED": { [1, 0.72, 0.29, 1] };
        case "ESTABLISHING": { [0.15, 0.84, 1, 1] };
        default { [0.55, 0.58, 0.62, 0.9] };
    };
    _map drawIcon [
        FLO_OperationsMapLogisticsIcon,
        _nodeColor,
        _position,
        22,
        22,
        0,
        format ["%1 / SUPPLY %2/%3", _type, _throughput, _throughputMax],
        2,
        0.031,
        "RobotoCondensedBold",
        "right"
    ];
} forEach FLO_OperationsMapNodeDrawData;

{
    _x params ["_position", "_type", "_grid", "_radius", "_remainingSeconds", "_color"];
    private _areaColor = +_color;
    _areaColor set [3, 0.55];
    _map drawEllipse [_position, _radius, _radius, 0, _areaColor, ""];
    _map drawIcon [
        FLO_OperationsMapLogisticsIcon,
        _color,
        _position,
        22,
        22,
        0,
        format ["REPORTED ENY %1 / GRID %2 / %3m", _type, _grid, ceil (_remainingSeconds / 60)],
        2,
        0.031,
        "RobotoCondensedBold",
        "right"
    ];
} forEach FLO_OperationsMapEnemyLogisticsIntelDrawData;

{
    private _threatSector = _x;
    private _sectorPosition = _threatSector get "position";
    _map drawEllipse [
        _sectorPosition,
        _threatSector get "longAxis",
        _threatSector get "shortAxis",
        _threatSector get "direction",
        [1, 1, 1, 0.18],
        "#(rgb,8,8,3)color(1,0.72,0.29,0.18)"
    ];
    _map drawEllipse [
        _sectorPosition,
        _threatSector get "longAxis",
        _threatSector get "shortAxis",
        _threatSector get "direction",
        [1, 0.72, 0.29, 0.9],
        ""
    ];
    _map drawIcon [
        FLO_OperationsMapIntelIcon,
        [1, 0.72, 0.29, 1],
        _sectorPosition,
        24,
        24,
        0,
        format ["%1 / GRID %2", _threatSector get "label", _threatSector get "grid"],
        2,
        0.034,
        "RobotoCondensedBold",
        "right"
    ];
} forEach FLO_OperationsMapThreatSectors;

{
    _x params [
        "_objectiveId",
        "_position",
        "_name",
        "_ownerColor",
        "_intent",
        "_integrationState",
        "_contested",
        "_underAttack"
    ];

    private _isSelected = _objectiveId == _selectedId;
    private _isMainEffort = _intent in ["MAIN_EFFORT", "DEFEND_MAIN"];
    private _isSpecial = _intent != "NONE" || {_integrationState != "INTEGRATED"} || {_contested} || {_underAttack};
    private _intentColor = switch (_intent) do {
        case "MAIN_EFFORT";
        case "DEFEND_MAIN": { [1, 0.72, 0.29, 1] };
        case "SUPPORTING_EFFORT";
        case "DEFEND_SUPPORT": { [0.145, 0.843, 1, 1] };
        case "SUPPORT": { [0.65, 1, 0.35, 0.95] };
        case "FOOTHOLD";
        case "OPPORTUNITY": { [1, 0.72, 0.29, 0.95] };
        case "SCREEN": { [0.65, 0.72, 0.78, 0.85] };
        default { [0.65, 0.72, 0.78, 0] };
    };

    if (_isSpecial) then {
        _map drawIcon [
            FLO_OperationsMapFocusIcon,
            _intentColor,
            _position,
            [20, 26] select _isMainEffort,
            [20, 26] select _isMainEffort,
            0,
            "",
            2
        ];
    };

    if (_isSelected) then {
        _map drawIcon [FLO_OperationsMapFocusIcon, [1, 1, 1, 1], _position, 32, 32, 0, "", 2];
    };

    private _label = ["", _name] select (_isSpecial || {_isSelected} || {_mapScale <= 0.035});
    _map drawIcon [
        FLO_OperationsMapDotIcon,
        _ownerColor,
        _position,
        [10, 14] select _isSpecial,
        [10, 14] select _isSpecial,
        0,
        _label,
        2,
        0.032,
        "RobotoCondensedBold",
        "right"
    ];
} forEach FLO_OperationsMapDrawData;

private _playerState = FLO_OperationsLastSnapshot get "player";
private _playerPosition = _playerState get "position";
_map drawIcon [
    FLO_OperationsMapFocusIcon,
    [1, 1, 1, 1],
    _playerPosition,
    24,
    24,
    0,
    format ["YOU / %1", _playerState get "grid"],
    2,
    0.034,
    "RobotoCondensedBold",
    "right"
];
