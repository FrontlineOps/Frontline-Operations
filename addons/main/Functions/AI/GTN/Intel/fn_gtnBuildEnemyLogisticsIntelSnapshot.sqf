/*
 * Function: FLO_fnc_gtnBuildEnemyLogisticsIntelSnapshot
 * Description:
 *   Builds the temporary enemy-logistics reports visible to one side. Records
 *   are captured when intel is recovered, so this never reads the live enemy
 *   logistics network or exposes hidden sustainment state.
 */

params [["_viewerSide", sideUnknown, [sideUnknown]]];

if !(_viewerSide in [east, west]) then {
    throw format ["FLO_fnc_gtnBuildEnemyLogisticsIntelSnapshot: unsupported viewer side %1", _viewerSide];
};

private _sideKey = ([_viewerSide] call FLO_fnc_gtnSideContext) get "sideKey";
private _intelBySide = FLO_GTN_StrategicIntelBySide;
private _sideRecords = _intelBySide get _sideKey;
private _now = diag_tickTime;
private _rows = [];

{
    private _recordKey = _x;
    private _record = _sideRecords get _recordKey;
    private _expiresAt = _record get "expiresAt";
    if (_expiresAt <= _now) then {
        _sideRecords deleteAt _recordKey;
        continue;
    };

    if !((_record get "category") in ["hq", "supply_node"]) then { continue };

    private _reportedAt = _record get "reportedAt";
    _rows pushBack createHashMapFromArray [
        ["type", _record get "nodeType"],
        ["position", +(_record get "position")],
        ["objectiveName", _record get "objectiveName"],
        ["grid", _record get "grid"],
        ["radius", _record get "radius"],
        ["ageSeconds", floor ((_now - _reportedAt) max 0)],
        ["remainingSeconds", ceil ((_expiresAt - _now) max 0)]
    ];
} forEach +(keys _sideRecords);

_intelBySide set [_sideKey, _sideRecords];
FLO_GTN_StrategicIntelBySide = _intelBySide;

[_rows, [], { _x get "remainingSeconds" }, "DESCEND"] call BIS_fnc_sortBy
