/*
 * Function: FLO_fnc_virtualizationCreateSpatialState
 */

params [["_cellSize", 500, [0]]];

createHashMapFromArray [
    ["cellSize", _cellSize],
    ["grid", createHashMap],
    ["gridBySide", createHashMapFromArray [
        ["EAST", createHashMap],
        ["WEST", createHashMap],
        ["GUER", createHashMap],
        ["CIV", createHashMap],
        ["UNKNOWN", createHashMap]
    ]],
    ["groupMeta", createHashMap],
    ["mapSize", worldSize]
]
