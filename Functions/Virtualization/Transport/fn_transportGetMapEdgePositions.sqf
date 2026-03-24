/*
 * Function: FLO_fnc_transportGetMapEdgePositions
 */

params [["_forceRefresh", false, [false]]];

if (
    !_forceRefresh
    && {count FLO_Transport_MapEdgePositions > 0}
    && {time - FLO_Transport_MapEdgeCacheTime < 3600}
) exitWith {
    FLO_Transport_MapEdgePositions
};

private _worldSize = worldSize;
private _edgeOffset = 200;
private _spacing = 500;
private _numPoints = floor (_worldSize / _spacing);
private _positions = [];

for "_i" from 1 to (_numPoints - 1) do {
    private _pos = [_i * _spacing, _worldSize - _edgeOffset, 0];
    if (!surfaceIsWater _pos) then {
        private _roads = _pos nearRoads 300;
        if (count _roads > 0) then {
            _positions pushBack [getPos (selectRandom _roads), "NORTH"];
        };
    };
};

for "_i" from 1 to (_numPoints - 1) do {
    private _pos = [_i * _spacing, _edgeOffset, 0];
    if (!surfaceIsWater _pos) then {
        private _roads = _pos nearRoads 300;
        if (count _roads > 0) then {
            _positions pushBack [getPos (selectRandom _roads), "SOUTH"];
        };
    };
};

for "_i" from 1 to (_numPoints - 1) do {
    private _pos = [_worldSize - _edgeOffset, _i * _spacing, 0];
    if (!surfaceIsWater _pos) then {
        private _roads = _pos nearRoads 300;
        if (count _roads > 0) then {
            _positions pushBack [getPos (selectRandom _roads), "EAST"];
        };
    };
};

for "_i" from 1 to (_numPoints - 1) do {
    private _pos = [_edgeOffset, _i * _spacing, 0];
    if (!surfaceIsWater _pos) then {
        private _roads = _pos nearRoads 300;
        if (count _roads > 0) then {
            _positions pushBack [getPos (selectRandom _roads), "WEST"];
        };
    };
};

FLO_Transport_MapEdgePositions = _positions;
FLO_Transport_MapEdgeCacheTime = time;

["TRANSPORT", 3, format ["Cached %1 map edge spawn positions", count _positions]] call FLO_fnc_log;

_positions
