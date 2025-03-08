/*
    Function: FLO_fnc_TaskForceDefenseLine
    
    Description:
    Creates defense lines using Task Forces at strategic locations on the frontline.
    Deploys combinations of infantry, mechanized, armor, and fortifications.
    
    Parameters:
    _mode - The function mode to execute ["createDefenseLine", "reinforceDefenseLine"] (String)
    _params - Parameters based on mode (Array)
        createDefenseLine: [_frontlineMarker, _depth, _strength] - Create a defensive line
        reinforceDefenseLine: [_frontlineMarker, _strength] - Reinforce an existing line
    
    Returns:
    Based on mode:
        createDefenseLine: Array - IDs of created Task Forces
        reinforceDefenseLine: Number - Count of Task Forces added
*/

if (!isServer) exitWith {};

params [
    ["_mode", "", [""]],
    ["_params", [], [[]]]
];

private _result = [];

switch (_mode) do {
    case "createDefenseLine": {
        _params params [
            ["_frontlineMarker", "", [""]],
            ["_depth", 2, [0]],
            ["_strength", "medium", [""]]
        ];
        
        // Validate marker
        if (_frontlineMarker == "") exitWith {
            diag_log "[FLO][DefenseLine] Error: Empty frontline marker name";
            []
        };
        
        private _frontlinePos = getMarkerPos _frontlineMarker;
        if (_frontlinePos isEqualTo [0,0,0]) exitWith {
            diag_log "[FLO][DefenseLine] Error: Invalid frontline marker position";
            []
        };
        
        // Find nearest OPFOR installations to use as base markers
        private _opforMarkers = allMapMarkers select {
            markerColor _x in ["colorOPFOR", "ColorEAST"] && 
            markerType _x in ["o_support", "n_support", "o_installation", "n_installation"]
        };
        
        // Sort by distance to frontline
        _opforMarkers = [_opforMarkers, [], {getMarkerPos _x distance _frontlinePos}, "ASCEND"] call BIS_fnc_sortBy;
        
        // Take the closest marker as base
        private _baseMarker = _opforMarkers param [0, ""];
        if (_baseMarker == "") exitWith {
            diag_log "[FLO][DefenseLine] Error: No suitable OPFOR base marker found";
            []
        };
        
        // Check resource availability
        private _currentResources = ["get", []] call FLO_fnc_opforResources;
        private _minimumRequired = 15; // Minimum resources needed
        
        if (_currentResources < _minimumRequired) exitWith {
            diag_log format ["[FLO][DefenseLine] Error: Insufficient resources for defense line (needed %1, have %2)",
                _minimumRequired, _currentResources];
            []
        };
        
        // Determine strength-based parameters
        private _strengthParams = switch (toLower _strength) do {
            case "light": {
                [
                    ["infantry", "squad"],
                    ["infantry", "squad"], 
                    ["fortification", "fireteam"]
                ]
            };
            case "medium": {
                [
                    ["infantry", "platoon"],
                    ["mechanized", "squad"],
                    ["fortification", "squad"]
                ]
            };
            case "heavy": {
                [
                    ["infantry", "platoon"],
                    ["mechanized", "platoon"],
                    ["armored", "squad"],
                    ["fortification", "platoon"]
                ]
            };
            default {
                [
                    ["infantry", "squad"],
                    ["fortification", "squad"]
                ]
            };
        };
        
        // Find direction toward BLUFOR territory
        // First, find all BLUFOR markers that could indicate their territory
        private _bluforMarkers = allMapMarkers select {
            markerColor _x in ["colorBLUFOR", "ColorWEST", "ColorYellow"] &&
            markerType _x in ["b_installation", "b_support", "respawn_west", "b_hq"]
        };
        
        // Get the average BLUFOR position (center of their territory)
        private _bluforPositions = _bluforMarkers apply {getMarkerPos _x};
        private _averageBluforPos = [0,0,0];
        
        if (count _bluforPositions > 0) then {
            {
                _averageBluforPos = _averageBluforPos vectorAdd _x;
            } forEach _bluforPositions;
            _averageBluforPos = _averageBluforPos vectorMultiply (1 / count _bluforPositions);
        } else {
            // If no BLUFOR markers, use the frontline position as reference
            _averageBluforPos = _frontlinePos;
        };
        
        // Direction from frontline to BLUFOR territory
        private _bluforDirection = _frontlinePos getDir _averageBluforPos;
        
        // CRITICAL FIX: We first need to find where OPFOR is relative to the frontline
        private _opforBasePos = getMarkerPos _baseMarker;
        private _directionToOpfor = _frontlinePos getDir _opforBasePos;
        
        // DEBUG
        diag_log format ["[FLO][DefenseLine] Frontline position: %1", _frontlinePos];
        diag_log format ["[FLO][DefenseLine] BLUFOR direction from frontline: %1", _bluforDirection];
        diag_log format ["[FLO][DefenseLine] OPFOR base position: %1", _opforBasePos];
        diag_log format ["[FLO][DefenseLine] Direction to OPFOR from frontline: %1", _directionToOpfor];
        
        // Calculate terrain-aware positions for the defense line
        private _totalWidth = 800; // INCREASED from 600 to 800 - even wider defense line
        private _positionsPerLine = 5; // Increased from 3 to 5 positions per line
        private _spacing = _totalWidth / (_positionsPerLine - 1);
        
        // Initialize the array to store all line positions
        private _linePositions = [];
        
        diag_log format ["[FLO][DefenseLine] Creating defense line facing direction %1 toward BLUFOR", _bluforDirection];
        
        // Create multiple lines based on depth
        for "_lineIndex" from 0 to (_depth - 1) do {
            // CRITICAL FIX: We need to move TOWARD OPFOR from the frontline, not just away from BLUFOR
            // This ensures we're on the OPFOR side of the frontline
            private _lineDistance = 250 + (_lineIndex * 200); // Reduced distance for better positioning
            
            // Calculate base position for this line - moving TOWARD OPFOR base
            private _lineBasePos = _frontlinePos getPos [_lineDistance, _directionToOpfor];
            
            diag_log format ["[FLO][DefenseLine] Line %1 base position: %2 (distance %3 toward OPFOR)", 
                _lineIndex, _lineBasePos, _lineDistance];
            
            // Calculate left edge position (perpendicular to the line between OPFOR and BLUFOR)
            // We need this line to be parallel to the frontline, which should be perpendicular to BLUFOR direction
            private _perpendicularLeft = (_bluforDirection - 90) mod 360;
            private _leftPos = _lineBasePos getPos [_totalWidth / 2, _perpendicularLeft];
            
            // Create positions along the line
            for "_i" from 0 to (_positionsPerLine - 1) do {
                private _posTemp = _leftPos getPos [_i * _spacing, (_perpendicularLeft + 180) mod 360];
                
                // Add some randomness to prevent perfect line formations
                _posTemp = _posTemp getPos [30 + random 70, random 360];
                
                // CRITICAL FIX: Check if position is in water and find land if needed
                if (surfaceIsWater _posTemp) then {
                    diag_log format ["[FLO][DefenseLine] Warning: Initial position is in water: %1", _posTemp];
                    
                    // Try to find a non-water position nearby
                    private _attempts = 0;
                    private _maxAttempts = 10;
                    private _foundLand = false;
                    private _searchRadius = 100;
                    
                    while {_attempts < _maxAttempts && !_foundLand} do {
                        // Increase search radius with each attempt
                        _searchRadius = _searchRadius + (_attempts * 50);
                        
                        // Use BIS_fnc_findSafePos to get a position on land
                        private _landPos = [_posTemp, 0, _searchRadius, 10, 0, 0.1, 0, [], [_posTemp, _posTemp]] call BIS_fnc_findSafePos;
                        
                        // Check if position is valid and on land
                        if (!(_landPos isEqualTo [_posTemp, _posTemp]) && !surfaceIsWater _landPos) then {
                            _posTemp = _landPos;
                            _foundLand = true;
                            diag_log format ["[FLO][DefenseLine] Found land position: %1 (after %2 attempts)", _posTemp, _attempts + 1];
                        };
                        
                        _attempts = _attempts + 1;
                    };
                    
                    // If we couldn't find land, use the frontline position (fallback)
                    if (!_foundLand) then {
                        diag_log format ["[FLO][DefenseLine] Warning: Could not find land position after %1 attempts", _maxAttempts];
                        // Move toward OPFOR base from frontline to ensure we're on land
                        _posTemp = _frontlinePos getPos [100 + random 200, _directionToOpfor];
                    };
                };
                
                // Find suitable position near this point (check for roads, suitable terrain, etc.)
                // If elevated position, it's better
                private _nearestHills = nearestLocations [_posTemp, ["Hill"], 300];
                if (count _nearestHills > 0) then {
                    _posTemp = locationPosition (_nearestHills select 0);
                };
                
                // Find nearby buildings for possible cover
                private _nearBuildings = _posTemp nearObjects ["Building", 100];
                if (count _nearBuildings > 0) then {
                    // Adjust position to be near a building but not inside
                    _posTemp = (_nearBuildings select 0) getPos [15, random 360];
                };
                
                // Add position to list
                _linePositions pushBack _posTemp;
            };
        };
        
        // Create Task Forces at these positions
        private _taskForceIds = [];
        {
            // Select a composition from strength parameters
            private _composition = selectRandom _strengthParams;
            _composition params ["_type", "_size"];
            
            // Create Task Force
            private _taskForceId = ["createTaskForce", [_baseMarker, _type, _size, ""]] call FLO_fnc_TaskForceSystem;
            
            if (_taskForceId != "") then {
                // Deploy immediately at the position (defensive posture)
                // Pass the blufor direction as an additional parameter through the marker name
                // Format: "position|direction"
                diag_log format ["[FLO][DefenseLine] Deploying task force at %1 with blufor direction %2", 
                    _x, _bluforDirection];
                
                ["deployTaskForce", [_taskForceId, _x, true]] call FLO_fnc_TaskForceSystem;
                
                // Add to result
                _taskForceIds pushBack _taskForceId;
                
                diag_log format ["[FLO][DefenseLine] Created %1 Task Force (%2) at position %3 facing direction %4", 
                    _type, _size, _x, _bluforDirection];
            };
        } forEach _linePositions;
        
        diag_log format ["[FLO][DefenseLine] Created defense line at %1 with %2 Task Forces", 
            _frontlineMarker, count _taskForceIds];
            
        // Create marker to show defense line
        // private _defenseMarker = createMarker [format ["defense_line_%1", _frontlineMarker], _frontlinePos];
        // _defenseMarker setMarkerShape "RECTANGLE";
        // _defenseMarker setMarkerBrush "DiagGrid";
        // _defenseMarker setMarkerColor "ColorRed";
        // _defenseMarker setMarkerAlpha 0.5;
        // _defenseMarker setMarkerSize [_totalWidth / 2, 350]; // Even deeper marker
        
        // // CRITICAL FIX: Direction needs to be perpendicular to the BLUFOR direction
        // // This ensures the rectangle is oriented correctly
        // private _markerDir = (_bluforDirection + 90) mod 360;
        // _defenseMarker setMarkerDir _markerDir;
        
        // Create arrow marker pointing toward BLUFOR
        // private _arrowMarker = createMarker [format ["defense_arrow_%1", _frontlineMarker], _frontlinePos];
        // _arrowMarker setMarkerType "hd_arrow";
        // _arrowMarker setMarkerColor "ColorRed";
        // _arrowMarker setMarkerAlpha 0.7;
        // _arrowMarker setMarkerSize [1, 1.5];
        // _arrowMarker setMarkerDir _bluforDirection;
        // _arrowMarker setMarkerText "DEFENSIVE LINE";
        
        _result = _taskForceIds;
    };
    
    case "reinforceDefenseLine": {
        _params params [
            ["_frontlineMarker", "", [""]],
            ["_strength", "light", [""]]
        ];
        
        // Validate marker
        if (_frontlineMarker == "") exitWith {
            diag_log "[FLO][DefenseLine] Error: Empty frontline marker name";
            0
        };
        
        private _frontlinePos = getMarkerPos _frontlineMarker;
        if (_frontlinePos isEqualTo [0,0,0]) exitWith {
            diag_log "[FLO][DefenseLine] Error: Invalid frontline marker position";
            0
        };
        
        // Find nearest OPFOR installations to use as base markers
        private _opforMarkers = allMapMarkers select {
            markerColor _x in ["colorOPFOR", "ColorEAST"] && 
            markerType _x in ["o_support", "n_support", "o_installation", "n_installation"]
        };
        
        // Sort by distance to frontline
        _opforMarkers = [_opforMarkers, [], {getMarkerPos _x distance _frontlinePos}, "ASCEND"] call BIS_fnc_sortBy;
        
        // Take the closest marker as base
        private _baseMarker = _opforMarkers param [0, ""];
        if (_baseMarker == "") exitWith {
            diag_log "[FLO][DefenseLine] Error: No suitable OPFOR base marker found";
            0
        };
        
        // Look for existing Task Force markers near the frontline
        private _taskForceMarkers = allMapMarkers select {
            markerType _x == "mil_triangle" && 
            markerColor _x == "ColorEAST" &&
            markerAlpha _x == 0.6
        };
        
        // Filter to those near frontline
        private _nearFrontlineMarkers = _taskForceMarkers select {
            getMarkerPos _x distance _frontlinePos < 800
        };
        
        if (count _nearFrontlineMarkers == 0) exitWith {
            diag_log "[FLO][DefenseLine] No existing Task Forces found near frontline to reinforce";
            
            // Create a new defense line instead
            _result = ["createDefenseLine", [_frontlineMarker, 1, _strength]] call FLO_fnc_TaskForceDefenseLine;
            count _result
        };
        
        // Determine reinforcement type based on strength
        private _reinforcementParams = switch (toLower _strength) do {
            case "light": {
                [["infantry", "squad"]]
            };
            case "medium": {
                [["mechanized", "squad"], ["fortification", "squad"]]
            };
            case "heavy": {
                [["armored", "squad"], ["fortification", "platoon"]]
            };
            default {
                [["infantry", "squad"]]
            };
        };
        
        // Select reinforcement markers (near positions of existing Task Forces)
        private _reinforceCount = (count _nearFrontlineMarkers) min 3; // Reinforce up to 3 positions
        private _markersToReinforce = [];
        
        for "_i" from 0 to (_reinforceCount - 1) do {
            _markersToReinforce pushBack (selectRandom _nearFrontlineMarkers);
        };
        
        // Create reinforcement Task Forces
        private _reinforcementCount = 0;
        
        {
            // Select composition for this reinforcement
            private _composition = selectRandom _reinforcementParams;
            _composition params ["_type", "_size"];
            
            // Create Task Force
            private _taskForceId = ["createTaskForce", [_baseMarker, _type, _size, ""]] call FLO_fnc_TaskForceSystem;
            
            if (_taskForceId != "") then {
                // Get position from existing marker
                private _pos = getMarkerPos _x;
                
                // Add some randomness to position (dispersion)
                _pos = _pos getPos [10 + random 30, random 360];
                
                // Deploy at the position (defensive posture)
                ["deployTaskForce", [_taskForceId, _pos, true]] call FLO_fnc_TaskForceSystem;
                
                _reinforcementCount = _reinforcementCount + 1;
                
                diag_log format ["[FLO][DefenseLine] Reinforced with %1 Task Force (%2) at position %3", 
                    _type, _size, _pos];
            };
        } forEach _markersToReinforce;
        
        diag_log format ["[FLO][DefenseLine] Reinforced defense line at %1 with %2 Task Forces", 
            _frontlineMarker, _reinforcementCount];
            
        _result = _reinforcementCount;
    };
};

_result 