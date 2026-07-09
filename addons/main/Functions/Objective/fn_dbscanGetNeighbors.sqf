/*
 * Function: FLO_fnc_dbscanGetNeighbors
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns neighboring point indexes for DBSCAN using the prebuilt spatial
 *   grid.
 *
 * Arguments:
 * 0: Point index <NUMBER>
 * 1: Positions <ARRAY>
 * 2: Grid <HASHMAP>
 * 3: Grid size <NUMBER>
 * 4: Epsilon <NUMBER>
 *
 * Returns:
 * Neighbor indexes <ARRAY>
 */
params ["_pointIdx", "_positions", "_grid", "_gridSize", "_epsilon"];

private _pos = _positions select _pointIdx;
private _neighbors = [];
private _gx = floor ((_pos select 0) / _gridSize);
private _gy = floor ((_pos select 1) / _gridSize);

for "_dx" from -1 to 1 do {
    for "_dy" from -1 to 1 do {
        private _cell = format ["%1_%2", _gx + _dx, _gy + _dy];
        private _cellData = _grid getOrDefault [_cell, []];

        {
            private _otherIdx = _x;
            if (_otherIdx != _pointIdx) then {
                private _otherPos = _positions select _otherIdx;
                if (_pos distance2D _otherPos <= _epsilon) then {
                    _neighbors pushBack _otherIdx;
                };
            };
        } forEach _cellData;
    };
};

_neighbors
