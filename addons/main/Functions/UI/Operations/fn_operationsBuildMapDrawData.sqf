/*
 * Function: FLO_fnc_operationsBuildMapDrawData
 * Description:
 *   Caches objective descriptors when a campaign snapshot arrives so the map
 *   draw event performs no HashMap traversal or classification work.
 */

params ["_snapshot"];

private _drawData = [];
{
    private _owner = _x get "owner";
    private _color = switch (_owner) do {
        case "WEST": { [0.145, 0.843, 1, 0.9] };
        case "EAST": { [1, 0.302, 0.369, 0.9] };
        default { [0.65, 0.72, 0.78, 0.72] };
    };
    private _intent = _x get "intent";
    private _integrationState = _x get "integrationState";
    private _contested = _x get "contested";
    private _underAttack = _x get "underAttack";
    private _isMainEffort = _intent == "ATTACK";
    private _isSpecial = _intent != "NONE" || {_integrationState != "INTEGRATED"} || {_contested} || {_underAttack};
    private _intentColor = switch (_intent) do {
        case "ATTACK": { [1, 0.72, 0.29, 1] };
        case "DEFEND": { [0.145, 0.843, 1, 1] };
        case "FOOTHOLD": { [1, 0.72, 0.29, 0.95] };
        case "SCREEN": { [0.65, 0.72, 0.78, 0.85] };
        default { [0.65, 0.72, 0.78, 0] };
    };
    private _wideVisible = _isSpecial || {(_x get "priority") >= 75};

    _drawData pushBack [
        _x get "id",
        _x get "position",
        _x get "name",
        _color,
        _isSpecial,
        _isMainEffort,
        _intentColor,
        _wideVisible
    ];
} forEach (_snapshot get "objectives");

FLO_OperationsMapDrawData = _drawData;
private _logistics = _snapshot get "logistics";
FLO_OperationsMapNodeDrawData = (_logistics get "nodes") apply {
    [
        _x get "id",
        _x get "position",
        _x get "type",
        _x get "state",
        _x get "throughput",
        _x get "throughputMax"
    ]
};
FLO_OperationsMapRouteDrawData = (_logistics get "routes") apply {
    [_x get "from", _x get "to", _x get "state"]
};
private _enemyLogisticsColor = [[0.145, 0.843, 1, 0.95], [1, 0.302, 0.369, 0.95]] select ((_snapshot get "enemySide") == "EAST");
FLO_OperationsMapEnemyLogisticsIntelDrawData = (_snapshot get "enemyLogisticsIntel") apply {
    [
        _x get "position",
        _x get "type",
        _x get "grid",
        _x get "radius",
        _x get "remainingSeconds",
        _enemyLogisticsColor
    ]
};
_drawData
