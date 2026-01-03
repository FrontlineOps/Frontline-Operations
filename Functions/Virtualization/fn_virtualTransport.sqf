/*
 * Function: FLO_fnc_virtualTransport
 * Author: Frontline Operations Development Group
 * Description:
 * Virtual Transport System for the virtualization framework.
 * Allows infantry groups to attach to transport vehicles (APCs, IFVs, trucks, helicopters)
 * and move at vehicle speed in the virtual world.
 * 
 * When activated, infantry spawns inside the transport vehicle ready to dismount.
 * 
 * Features:
 * - Attach/detach infantry groups to transports
 * - Calculate transport capacity from config
 * - Map edge spawn points for reinforcements
 * - Combined arms movement (mechanized assault)
 * 
 * Return Value:
 * Virtual Transport HashMap Object <HASHMAP>
 */

if (!isServer) exitWith {};

if (!isNil "FLO_VirtualTransport") exitWith { FLO_VirtualTransport };

["VIRTUALIZATION", 3, "Initializing Virtual Transport System"] call FLO_fnc_log;

FLO_VirtualTransport = createHashMapObject [[
    // Transport speed multipliers (m/s base speed ~5 for infantry)
    ["_transportSpeeds", createHashMapFromArray [
        ["motorized", 15],      // ~54 km/h
        ["mechanized", 12],     // ~43 km/h  
        ["helicopter", 50],     // ~180 km/h
        ["armor", 10],          // ~36 km/h
        ["truck", 14]           // ~50 km/h
    ]],
    
    // Cached map edge positions
    ["_mapEdgePositions", []],
    ["_mapEdgeCacheTime", 0],
    
    // ========================================================================
    // TRANSPORT CAPACITY
    // ========================================================================
    
    // Get transport capacity for a group type or specific vehicle class
    ["_getTransportCapacity", {
        params ["_groupTypeOrClass"];
        
        // If it's a vehicle class, use config
        if (_groupTypeOrClass isKindOf "AllVehicles") then {
            private _cfg = configFile >> "CfgVehicles" >> _groupTypeOrClass;
            if (isClass _cfg) then {
                getNumber (_cfg >> "transportSoldier")
            } else { 0 }
        } else {
            // Estimate by group type
            switch (_groupTypeOrClass) do {
                case "motorized": { 6 };      // Typical truck/MRAP
                case "mechanized": { 8 };     // BMP/BTR style
                case "helicopter": { 12 };    // Transport heli
                case "armor": { 0 };          // Tanks don't carry
                default { 0 }
            }
        }
    }],
    
    // ========================================================================
    // ATTACH/DETACH GROUPS
    // ========================================================================
    
    // Attach an infantry group to a transport group
    ["_attachGroup", {
        params ["_infantryGroupId", "_transportGroupId"];
        
        if (isNil "FLO_virtualGroups") exitWith {
            ["VIRTUALIZATION", 1, "ERROR: Virtualization system not initialized"] call FLO_fnc_log;
            false
        };
        
        private _groups = FLO_virtualGroups get "_groups";
        private _infData = _groups getOrDefault [_infantryGroupId, nil];
        private _transData = _groups getOrDefault [_transportGroupId, nil];
        
        if (isNil "_infData" || isNil "_transData") exitWith {
            ["VIRTUALIZATION", 2, format["Cannot attach: group not found (inf: %1, trans: %2)", 
                _infantryGroupId, _transportGroupId]] call FLO_fnc_log;
            false
        };
        
        // Check if infantry is already attached
        private _currentAttach = _infData getOrDefault ["attachedTo", ""];
        if (_currentAttach != "") exitWith {
            ["VIRTUALIZATION", 2, format["Group %1 already attached to %2", 
                _infantryGroupId, _currentAttach]] call FLO_fnc_log;
            false
        };
        
        // Check transport capacity
        private _transType = _transData get "groupType";
        private _capacity = _self call ["_getTransportCapacity", [_transType]];
        private _currentlyAttached = _transData getOrDefault ["attachedGroups", []];
        
        // Count currently attached units
        private _attachedUnitCount = 0;
        {
            private _gData = _groups getOrDefault [_x, nil];
            if (!isNil "_gData") then {
                _attachedUnitCount = _attachedUnitCount + (_gData getOrDefault ["unitCount", 0]);
            };
        } forEach _currentlyAttached;
        
        private _infUnitCount = _infData getOrDefault ["unitCount", 4];
        if (_attachedUnitCount + _infUnitCount > _capacity) exitWith {
            ["VIRTUALIZATION", 2, format["Transport %1 capacity exceeded (%2/%3)", 
                _transportGroupId, _attachedUnitCount + _infUnitCount, _capacity]] call FLO_fnc_log;
            false
        };
        
        // Attach the infantry to transport
        _infData set ["attachedTo", _transportGroupId];
        _infData set ["attachedType", if (_transData get "groupType" in ["helicopter"]) then {"AIR"} else {"GROUND"}];
        
        // Update transport's attached groups list
        _currentlyAttached pushBack _infantryGroupId;
        _transData set ["attachedGroups", _currentlyAttached];
        _transData set ["isTransport", true];
        
        // Set infantry position to transport position
        _infData set ["position", _transData get "position"];
        
        ["VIRTUALIZATION", 3, format["Attached %1 (%2 units) to transport %3", 
            _infantryGroupId, _infUnitCount, _transportGroupId]] call FLO_fnc_log;
        
        true
    }],
    
    // Detach an infantry group from its transport
    ["_detachGroup", {
        params ["_infantryGroupId", ["_offsetDir", random 360]];
        
        if (isNil "FLO_virtualGroups") exitWith { false };
        
        private _groups = FLO_virtualGroups get "_groups";
        private _infData = _groups getOrDefault [_infantryGroupId, nil];
        if (isNil "_infData") exitWith { false };
        
        private _transportId = _infData getOrDefault ["attachedTo", ""];
        if (_transportId == "") exitWith { false };
        
        private _transData = _groups getOrDefault [_transportId, nil];
        
        // Remove from transport's attached list
        if (!isNil "_transData") then {
            private _attached = _transData getOrDefault ["attachedGroups", []];
            _attached = _attached - [_infantryGroupId];
            _transData set ["attachedGroups", _attached];
            if (count _attached == 0) then {
                _transData set ["isTransport", false];
            };
        };
        
        // Clear infantry attachment
        _infData set ["attachedTo", ""];
        _infData set ["attachedType", ""];
        
        // Offset position slightly from transport
        private _pos = _infData get "position";
        private _newPos = _pos getPos [30, _offsetDir];
        _infData set ["position", _newPos];
        
        ["VIRTUALIZATION", 3, format["Detached %1 from transport %2", _infantryGroupId, _transportId]] call FLO_fnc_log;

        true
    }],

    // Detach all groups from a transport
    ["_detachAllFromTransport", {
        params ["_transportGroupId"];

        if (isNil "FLO_virtualGroups") exitWith { false };

        private _groups = FLO_virtualGroups get "_groups";
        private _transData = _groups getOrDefault [_transportGroupId, nil];
        if (isNil "_transData") exitWith { false };

        private _attached = _transData getOrDefault ["attachedGroups", []];
        private _detachedCount = 0;

        {
            private _dir = 360 / (count _attached) * _forEachIndex;
            if (_self call ["_detachGroup", [_x, _dir]]) then {
                _detachedCount = _detachedCount + 1;
            };
        } forEach +_attached;

        ["VIRTUALIZATION", 3, format["Detached %1 groups from transport %2", _detachedCount, _transportGroupId]] call FLO_fnc_log;

        _detachedCount
    }],

    // ========================================================================
    // MAP EDGE SPAWNING
    // ========================================================================

    // Get valid map edge spawn positions
    ["_getMapEdgePositions", {
        params [["_forceRefresh", false]];

        private _cached = _self get "_mapEdgePositions";
        private _cacheTime = _self get "_mapEdgeCacheTime";

        // Use cache if valid and not forcing refresh
        if (!_forceRefresh && {count _cached > 0} && {time - _cacheTime < 3600}) exitWith { _cached };

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
                // Check for road access
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
        _self set ["_mapEdgePositions", _positions];
        _self set ["_mapEdgeCacheTime", time];

        ["VIRTUALIZATION", 3, format["Cached %1 map edge spawn positions", count _positions]] call FLO_fnc_log;

        _positions
    }],

    // Get a spawn position farthest from players
    ["_getBestEdgeSpawnPos", {
        params [["_preferredEdge", ""]];

        private _edgePositions = _self call ["_getMapEdgePositions", []];
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
    }],

    // ========================================================================
    // TRANSPORT MOVEMENT SPEED
    // ========================================================================

    // Get virtual movement speed for a transport
    ["_getTransportSpeed", {
        params ["_groupType"];

        private _speeds = _self get "_transportSpeeds";
        _speeds getOrDefault [_groupType, 5]
    }],

    // ========================================================================
    // COMBINED ARMS CREATION
    // ========================================================================

    // Create a mechanized assault group (transport + infantry)
    ["_createMechanizedGroup", {
        params ["_spawnPos", "_targetPos", "_side", ["_infantryCount", 1]];

        if (isNil "FLO_virtualGroups") exitWith { ["", []] };

        // Create the mechanized transport
        private _mechGroupId = [_spawnPos, "mechanized", nil, "", 1, _side] call FLO_fnc_createVirtualGroup;
        if (_mechGroupId == "") exitWith { ["", []] };

        private _groups = FLO_virtualGroups get "_groups";
        private _mechData = _groups get _mechGroupId;
        _mechData set ["isTransport", true];
        _mechData set ["attachedGroups", []];

        // Create and attach infantry groups
        private _infantryIds = [];
        for "_i" from 1 to _infantryCount do {
            private _infGroupId = [_spawnPos, "infantry", nil, "", 6, _side] call FLO_fnc_createVirtualGroup;
            if (_infGroupId != "") then {
                if (_self call ["_attachGroup", [_infGroupId, _mechGroupId]]) then {
                    _infantryIds pushBack _infGroupId;
                };
            };
        };

        // Set waypoints for the transport (infantry follows automatically)
        private _waypoints = [[_targetPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 50]];
        [_mechGroupId, _waypoints, false] call FLO_fnc_updateVirtualGroupWaypoints;

        // Set dismount waypoint index
        _mechData set ["dismountAtWaypoint", 0];

        ["VIRTUALIZATION", 3, format["Created mechanized group %1 with %2 infantry squads at %3",
            _mechGroupId, count _infantryIds, _spawnPos]] call FLO_fnc_log;

        [_mechGroupId, _infantryIds]
    }],

    // Create air assault group (helicopter + infantry)
    ["_createAirAssaultGroup", {
        params ["_spawnPos", "_targetPos", "_side", ["_infantryCount", 2]];

        if (isNil "FLO_virtualGroups") exitWith { ["", []] };

        // Create the helicopter transport
        private _heliGroupId = [_spawnPos, "helicopter", nil, "", 1, _side] call FLO_fnc_createVirtualGroup;
        if (_heliGroupId == "") exitWith { ["", []] };

        private _groups = FLO_virtualGroups get "_groups";
        private _heliData = _groups get _heliGroupId;
        _heliData set ["isTransport", true];
        _heliData set ["attachedGroups", []];

        // Create and attach infantry groups
        private _infantryIds = [];
        for "_i" from 1 to _infantryCount do {
            private _infGroupId = [_spawnPos, "infantry", nil, "", 8, _side] call FLO_fnc_createVirtualGroup;
            if (_infGroupId != "") then {
                if (_self call ["_attachGroup", [_infGroupId, _heliGroupId]]) then {
                    _infantryIds pushBack _infGroupId;
                };
            };
        };

        // Set waypoints for helicopter
        private _waypoints = [[_targetPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 50]];
        [_heliGroupId, _waypoints, false] call FLO_fnc_updateVirtualGroupWaypoints;

        // Set dismount waypoint
        _heliData set ["dismountAtWaypoint", 0];

        ["VIRTUALIZATION", 3, format["Created air assault group %1 with %2 infantry squads",
            _heliGroupId, count _infantryIds]] call FLO_fnc_log;

        [_heliGroupId, _infantryIds]
    }],

    // ========================================================================
    // REINFORCEMENT FROM MAP EDGE
    // ========================================================================

    // Spawn reinforcement from map edge to objective
    ["_spawnEdgeReinforcement", {
        params ["_targetObjective", "_groupType", "_side", ["_withInfantry", true], ["_infantryCount", 1]];

        // Get spawn position at map edge
        private _spawnPos = _self call ["_getBestEdgeSpawnPos", []];
        if (_spawnPos isEqualTo [0,0,0]) exitWith {
            ["VIRTUALIZATION", 2, "No valid map edge position found"] call FLO_fnc_log;
            ["", []]
        };

        // Get target position - objective must exist with position
        private _targetPos = if (_targetObjective isEqualType "") then {
            if (!isNil "FLO_Objectives") then {
                (FLO_Objectives get _targetObjective) get "position"
            } else { nil }
        } else {
            _targetObjective
        };

        if (isNil "_targetPos") exitWith {
            ["VIRTUALIZATION", 2, format["Invalid target for edge reinforcement: %1", _targetObjective]] call FLO_fnc_log;
            ["", []]
        };

        // Create appropriate group type
        private _result = switch (_groupType) do {
            case "mechanized": {
                if (_withInfantry) then {
                    _self call ["_createMechanizedGroup", [_spawnPos, _targetPos, _side, _infantryCount]]
                } else {
                    private _gId = [_spawnPos, "mechanized", nil, _targetObjective, 1, _side] call FLO_fnc_createVirtualGroup;
                    [_gId, []]
                }
            };
            case "helicopter": {
                if (_withInfantry) then {
                    _self call ["_createAirAssaultGroup", [_spawnPos, _targetPos, _side, _infantryCount]]
                } else {
                    private _gId = [_spawnPos, "helicopter", nil, _targetObjective, 1, _side] call FLO_fnc_createVirtualGroup;
                    [_gId, []]
                }
            };
            case "armor": {
                private _gId = [_spawnPos, "armor", nil, _targetObjective, 1, _side] call FLO_fnc_createVirtualGroup;
                [_gId, []]
            };
            default {
                private _gId = [_spawnPos, _groupType, nil, _targetObjective, nil, _side] call FLO_fnc_createVirtualGroup;
                [_gId, []]
            };
        };

        _result params ["_mainGroupId", "_attachedIds"];

        // Set waypoints to target if not already set
        if (_mainGroupId != "" && count _attachedIds == 0) then {
            private _waypoints = [[_targetPos, "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW", 50]];
            [_mainGroupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints; // Use road pathfinding
        };

        ["VIRTUALIZATION", 3, format["Edge reinforcement: %1 from %2 to %3",
            _groupType, _spawnPos, _targetPos]] call FLO_fnc_log;

        _result
    }],

    // ========================================================================
    // UPDATE ATTACHED GROUP POSITIONS
    // ========================================================================

    // Called from update loop - sync attached group positions
    ["_updateAttachedPositions", {
        if (isNil "FLO_virtualGroups") exitWith {};

        private _groups = FLO_virtualGroups get "_groups";

        // Find all transport groups and update their attached groups
        {
            private _groupId = _x;
            private _groupData = _y;

            private _isTransport = _groupData getOrDefault ["isTransport", false];
            if (!_isTransport) then { continue };

            private _attachedIds = _groupData getOrDefault ["attachedGroups", []];
            if (count _attachedIds == 0) then { continue };

            private _transportPos = _groupData get "position";

            // Update all attached group positions
            {
                private _attachedData = _groups getOrDefault [_x, nil];
                if (!isNil "_attachedData") then {
                    _attachedData set ["position", _transportPos];
                };
            } forEach _attachedIds;

        } forEach _groups;
    }],

    // ========================================================================
    // HANDLE DISMOUNT ON ACTIVATION
    // ========================================================================

    // Check if transport should dismount at current waypoint
    ["_shouldDismount", {
        params ["_groupId"];

        if (isNil "FLO_virtualGroups") exitWith { false };

        private _groups = FLO_virtualGroups get "_groups";
        private _groupData = _groups getOrDefault [_groupId, nil];
        if (isNil "_groupData") exitWith { false };

        private _dismountIdx = _groupData getOrDefault ["dismountAtWaypoint", -1];
        if (_dismountIdx < 0) exitWith { false };

        private _currentWpIdx = _groupData getOrDefault ["currentWaypointIndex", 0];
        private _waypoints = _groupData getOrDefault ["waypoints", []];

        if (count _waypoints == 0) exitWith { false };

        // Check if we've reached the dismount waypoint
        if (_currentWpIdx >= _dismountIdx) then {
            private _wpData = _waypoints select (_dismountIdx min (count _waypoints - 1));
            private _wpPos = _wpData select 0;
            private _pos = _groupData get "position";

            // Close enough to dismount?
            _pos distance2D _wpPos < 100
        } else {
            false
        }
    }]
]];

["VIRTUALIZATION", 3, "Virtual Transport System initialized"] call FLO_fnc_log;

FLO_VirtualTransport

