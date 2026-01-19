/*
 * Function: FLO_fnc_transportMapEdge
 * Author: Frontline Operations Development Group
 * Description:
 *   Map edge spawning utilities for transportation/reinforcement system.
 *   Provides cached map edge positions and finds best spawn position.
 *
 *   Migrated from fn_virtualTransport.sqf
 *
 * Return Value:
 *   None (initializes globals)
 */

if (!isServer) exitWith {};

// Cache for map edge positions
FLO_Transport_MapEdgePositions = [];
FLO_Transport_MapEdgeCacheTime = 0;

["TRANSPORT", 3, "Map edge spawning utilities initialized"] call FLO_fnc_log;

// ============================================================================
// Get valid map edge spawn positions (cached for 1 hour)
// ============================================================================
FLO_fnc_transportGetMapEdgePositions = {
    params [["_forceRefresh", false, [false]]];

    // Use cache if valid and not forcing refresh
    if (!_forceRefresh && {count FLO_Transport_MapEdgePositions > 0} && {time - FLO_Transport_MapEdgeCacheTime < 3600}) exitWith { 
        FLO_Transport_MapEdgePositions 
    };

    private _worldSize = worldSize;
    private _edgeOffset = 200; // Distance from actual edge
    private _positions = [];

    // Generate candidate positions along each edge
    private _spacing = 500;
    private _numPoints = floor (_worldSize / _spacing);

    // North edge (top of map)
    for "_i" from 1 to (_numPoints - 1) do {
        private _pos = [_i * _spacing, _worldSize - _edgeOffset, 0];
        if (!surfaceIsWater _pos) then {
            private _roads = _pos nearRoads 300;
            if (count _roads > 0) then {
                _positions pushBack [getPos (selectRandom _roads), "NORTH"];
            };
        };
    };

    // South edge (bottom of map)
    for "_i" from 1 to (_numPoints - 1) do {
        private _pos = [_i * _spacing, _edgeOffset, 0];
        if (!surfaceIsWater _pos) then {
            private _roads = _pos nearRoads 300;
            if (count _roads > 0) then {
                _positions pushBack [getPos (selectRandom _roads), "SOUTH"];
            };
        };
    };

    // East edge (right of map)
    for "_i" from 1 to (_numPoints - 1) do {
        private _pos = [_worldSize - _edgeOffset, _i * _spacing, 0];
        if (!surfaceIsWater _pos) then {
            private _roads = _pos nearRoads 300;
            if (count _roads > 0) then {
                _positions pushBack [getPos (selectRandom _roads), "EAST"];
            };
        };
    };

    // West edge (left of map)
    for "_i" from 1 to (_numPoints - 1) do {
        private _pos = [_edgeOffset, _i * _spacing, 0];
        if (!surfaceIsWater _pos) then {
            private _roads = _pos nearRoads 300;
            if (count _roads > 0) then {
                _positions pushBack [getPos (selectRandom _roads), "WEST"];
            };
        };
    };

    // Cache results
    FLO_Transport_MapEdgePositions = _positions;
    FLO_Transport_MapEdgeCacheTime = time;

    ["TRANSPORT", 3, format["Cached %1 map edge spawn positions", count _positions]] call FLO_fnc_log;

    _positions
};

// ============================================================================
// Get best spawn position (farthest from players)
// ============================================================================
FLO_fnc_transportGetBestEdgeSpawnPos = {
    params [["_preferredEdge", "", [""]]];

    private _edgePositions = [] call FLO_fnc_transportGetMapEdgePositions;
    if (count _edgePositions == 0) exitWith { [0,0,0] };

    // Filter by preferred edge if specified
    if (_preferredEdge != "") then {
        private _filtered = _edgePositions select {(_x select 1) == _preferredEdge};
        if (count _filtered > 0) then {
            _edgePositions = _filtered;
        };
    };

    // Find position farthest from all players
    private _bestPos = [];
    private _bestDist = 0;

    {
        _x params ["_pos", "_edge"];
        private _minPlayerDist = 999999;

        {
            private _dist = _pos distance2D _x;
            if (_dist < _minPlayerDist) then { _minPlayerDist = _dist };
        } forEach allPlayers;

        if (_minPlayerDist > _bestDist) then {
            _bestDist = _minPlayerDist;
            _bestPos = _pos;
        };
    } forEach _edgePositions;

    if (count _bestPos == 0 && count _edgePositions > 0) then {
        _bestPos = (_edgePositions select 0) select 0;
    };

    _bestPos
};
