/*
 * Function: FLO_fnc_virtualizationResolveLandWaypoints
 * Description:
 *   Expands every semantic LAND waypoint segment into a water-safe route.
 *   Original endpoint descriptors retain their settings; inserted pivots are
 *   MOVE waypoints. The function is pure with respect to virtual-group state.
 *
 * Return Value:
 *   [success, resolvedWaypoints, reason, metrics, semanticEndpointIndexes]
 */

params [
    ["_startPos", [0, 0, 0], [[]], [2, 3]],
    ["_waypoints", [], [[]]],
    ["_allowTrails", true, [true]],
    ["_sourceTag", "VG_LAND", [""]],
    ["_closeLoop", false, [true]]
];

if (surfaceIsWater _startPos) exitWith {
    [false, [], "START_IN_WATER", createHashMapFromArray [["segments", 0], ["emitted", 0]], []]
};

if (_waypoints isEqualTo []) exitWith {
    [true, [], "", createHashMapFromArray [["segments", 0], ["emitted", 0]], []]
};

private _resolvedWaypoints = [];
private _endpointIndexes = [];
private _cursor = +_startPos;
private _segmentCount = 0;
private _failedReason = "";
private _routeStartPos = +_startPos;
if (count _routeStartPos > 2) then {
    _routeStartPos set [2, 0];
} else {
    _routeStartPos pushBack 0;
};
private _semanticLoopAnchorPos = +((_waypoints select 0) select 0);
if (count _semanticLoopAnchorPos > 2) then {
    _semanticLoopAnchorPos set [2, 0];
} else {
    _semanticLoopAnchorPos pushBack 0;
};
private _hasCycle = false;

{
    private _semanticIndex = _forEachIndex;
    private _endpoint = +_x;
    private _wpType = toUpper (_endpoint select 1);
    private _targetPos = +(_endpoint select 0);

    if (_wpType == "CYCLE") then {
        if (_semanticIndex != (count _waypoints - 1) || {_semanticIndex == 0}) then {
            throw format ["FLO_fnc_virtualizationResolveLandWaypoints: CYCLE must be the final waypoint of a multi-waypoint route (%1)", _semanticIndex];
        };
        _hasCycle = true;
        _targetPos = +_semanticLoopAnchorPos;
        _endpoint set [0, +_semanticLoopAnchorPos];
    };

    private _pathResult = [_cursor, _targetPos, _allowTrails, _sourceTag] call FLO_fnc_findRoadPath;
    _pathResult params ["_segmentResolved", "_positions"];
    _segmentCount = _segmentCount + 1;

    if (!_segmentResolved || {_positions isEqualTo []}) then {
        _failedReason = format ["NO_LAND_ROUTE:%1", _semanticIndex];
        continue;
    };

    {
        private _isEndpoint = _forEachIndex == (count _positions - 1);
        if (_isEndpoint) then {
            _resolvedWaypoints pushBack (+_endpoint);
        } else {
            _resolvedWaypoints pushBack [
                +_x,
                "MOVE",
                _endpoint select 2,
                _endpoint select 3,
                _endpoint select 4,
                _endpoint select 5,
                5
            ];
        };
    } forEach _positions;

    _endpointIndexes pushBack (count _resolvedWaypoints - 1);
    _cursor = +_targetPos;
} forEach _waypoints;

if (_failedReason != "") exitWith {
    [false, [], _failedReason, createHashMapFromArray [["segments", _segmentCount], ["emitted", 0]], []]
};

if (_closeLoop
    && {!_hasCycle}
    && {count _waypoints > 1}
    && {_cursor distance2D _routeStartPos > 1}) then {
    private _closure = [_cursor, _routeStartPos, _allowTrails, _sourceTag] call FLO_fnc_findRoadPath;
    _closure params ["_closureResolved", "_closurePositions"];
    _segmentCount = _segmentCount + 1;

    if (!_closureResolved || {_closurePositions isEqualTo []}) exitWith {
        _failedReason = "NO_LAND_ROUTE:CLOSURE";
    };

    private _firstSettings = _waypoints select 0;
    {
        _resolvedWaypoints pushBack [
            +_x,
            "MOVE",
            _firstSettings select 2,
            _firstSettings select 3,
            _firstSettings select 4,
            _firstSettings select 5,
            5
        ];
    } forEach _closurePositions;
};

if (_failedReason != "") exitWith {
    [false, [], _failedReason, createHashMapFromArray [["segments", _segmentCount], ["emitted", 0]], []]
};

[
    true,
    _resolvedWaypoints,
    "",
    createHashMapFromArray [["segments", _segmentCount], ["emitted", count _resolvedWaypoints]],
    _endpointIndexes
]
