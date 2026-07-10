/*
 * Function: FLO_fnc_objectiveConfig
 * Author: Frontline Operations Development Group
 * Description:
 *   Centralized configuration for the objective system.
 *   Returns configuration values or initializes globals.
 *
 * Arguments:
 *   0: Operation (STRING) - "init", "get", "getAll"
 *   1: Key (STRING) - Config key to retrieve (for "get" operation)
 *
 * Returns:
 *   Varies by operation
 *
 * Examples:
 *   ["init"] call FLO_fnc_objectiveConfig;
 *   ["get", "baseClasses"] call FLO_fnc_objectiveConfig;
 *   ["getAll"] call FLO_fnc_objectiveConfig;
 */

params [["_operation", "init"], ["_key", ""]];

// Auto-initialize on first call
if (isNil "FLO_ObjectiveConfig") then {
    FLO_ObjectiveConfig = createHashMapFromArray [
        // Structure scanning classes
        ["baseClasses", [
            "HeliH", "AirportBase", "Strategic", "House_F",
            "House_Small", "House", "HouseBase", "Church"
        ]],
        
        // Classes to exclude from scanning
        ["excludeClasses", [
            "PowerLines_base_F"
        ]],
        
        // Radius configuration
        ["minRadius", 90],
        ["maxRadius", 300],
        ["radiusStep", 30],
        ["minGrowth", 2],  // Minimum structures to keep growing radius
        
        // Virtual objective clustering
        ["gridSize", 100],
        ["minClusterSize", createHashMapFromArray [
            ["Small", 4],
            ["Medium", 8],
            ["Large", 12],
            ["Huge", 24]
        ]],
        
        // Objective linking
        ["linkDistance", 5000],  // Base radius for adjacency before sparse-map continuity links bridge disconnected components
        
        // Capture/dominance settings
        ["captureTime", 20],      // Seconds to push capture progress to the secure phase
        ["captureSecureTime", 90], // Seconds attackers must hold after progress completes
        
        // Marker settings
        ["markerAlpha", 0.3],
        ["markerColors", createHashMapFromArray [
            [west, "colorBLUFOR"],
            [east, "colorOPFOR"],
            [resistance, "ColorGUER"],
            [civilian, "ColorCIV"],
            ["default", "ColorBlack"]
        ]],

        // Location type mappings
        ["locationTypes", [
            ["NameCityCapital", "civilian", "capital"],
            ["NameCity", "civilian", "city"],
            ["NameVillage", "civilian", "village"],
            ["NameLocal", "military", "local"],
            ["NameMarine", "military", "marine"]
        ]],
        
        // Debug settings
        ["debug", false]
    ];
};

private _result = nil;

switch (toLower _operation) do {
    case "init": {
        _result = true;
    };
    
    case "get": {
        _result = FLO_ObjectiveConfig get _key;
    };
    
    case "getall": {
        _result = +FLO_ObjectiveConfig;
    };
    
    case "set": {
        params ["", "_key", "_value"];
        FLO_ObjectiveConfig set [_key, _value];
        _result = true;
    };
    
    default {
        _result = nil;
    };
};

_result

