/*
 * Function: FLO_fnc_templateConvoyInterdiction
 * Author: Frontline Operations Development Group
 * Description:
 *   Template for the Convoy Interdiction side mission.
 *   Intercept and destroy an enemy supply convoy.
 *
 * Returns:
 *   HASHMAP - Mission template configuration
 */

private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
if !(_activeSide in [east, west]) then { _activeSide = west };
private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };
private _enemyKey = if (_enemySide isEqualTo east) then { "EAST" } else { "WEST" };
private _enemyCatalog = missionNamespace getVariable ["FLO_FactionCatalog", createHashMap] getOrDefault [_enemyKey, createHashMap];
private _enemyLight = _enemyCatalog getOrDefault ["groundLight", if (!isNil "East_Ground_Vehicles_Light") then { East_Ground_Vehicles_Light } else { ["O_MRAP_02_F"] }];
private _enemyTransport = _enemyCatalog getOrDefault ["groundTransport", if (!isNil "East_Ground_Transport") then { East_Ground_Transport } else { _enemyLight }];
private _enemyColor = if (_enemySide isEqualTo east) then { "colorOPFOR" } else { "colorBLUFOR" };

private _template = createHashMapFromArray [
    ["name", "Intercept Enemy Convoy"],
    ["description", "Intel suggests an enemy support convoy heading toward the frontlines. Intercept and destroy it."],
    ["icon", "mil_destroy"],
    ["color", _enemyColor],
    ["cooldown", 1200],
    ["timeout", 2400],
    ["maxActive", 1],
    ["reward", 100],
    ["isConvoy", true],
    
    // Setup - find road positions
    ["fnc_setup", {
        params ["_typeName"];

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_activeSide in [east, west]) then { _activeSide = west };
        private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };
        
        if (!isNil "ConVLocc" && {ConVLocc > 0}) exitWith { [false, [0,0,0]] };
        
        private _canSpawn = false;
        private _startPos = [0,0,0];
        
        // Find start and end objectives - enemy controlled only
        if (!isNil "FLO_Objectives" && {(count (keys FLO_Objectives)) > 0}) then {
            private _destObjId = [4000, getPos player, _enemySide] call FLO_fnc_getObjectiveNearPlayer;
            if (_destObjId != "") then {
                private _destPos = [_destObjId] call FLO_fnc_getRandomObjectivePos;

                // Find far enemy objective for start
                private _startCandidates = (keys FLO_Objectives) select {
                    _x != _destObjId && {
                        private _data = FLO_Objectives get _x;
                        private _owner = _data get "owner";
                        if (_owner isEqualType "") then {
                            private _ownerKey = toUpper _owner;
                            if (_ownerKey isEqualTo "EAST") then { _owner = east; };
                            if (_ownerKey isEqualTo "WEST") then { _owner = west; };
                        };
                        _owner isEqualTo _enemySide && {
                            private _p = _data get "position";
                            (_p distance2D _destPos) >= 6000
                        }
                    }
                };

                if ((count _startCandidates) > 0) then {
                    private _startObjId = selectRandom _startCandidates;
                    _startPos = [_startObjId] call FLO_fnc_getRandomObjectivePos;

                    // Verify road access
                    private _startRoads = _startPos nearRoads 800;
                    private _destRoads = _destPos nearRoads 800;
                    if ((count _startRoads) > 0 && {(count _destRoads) > 0}) then {
                        _startPos = getPosATL (selectRandom _startRoads);
                        _canSpawn = true;
                    };
                };
            };
        };
        
        [_canSpawn, _startPos]
    }],
    
    // Spawn function
    ["fnc_spawn", {
        params ["_missionId"];

        private _activeSide = missionNamespace getVariable ["FLO_ActivePlayerSide", west];
        if !(_activeSide in [east, west]) then { _activeSide = west };
        private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };
        private _enemyKey = if (_enemySide isEqualTo east) then { "EAST" } else { "WEST" };
        private _enemyCatalog = missionNamespace getVariable ["FLO_FactionCatalog", createHashMap] getOrDefault [_enemyKey, createHashMap];
        private _enemyLight = _enemyCatalog getOrDefault ["groundLight", if (!isNil "East_Ground_Vehicles_Light") then { East_Ground_Vehicles_Light } else { ["O_MRAP_02_F"] }];
        private _enemyTransport = _enemyCatalog getOrDefault ["groundTransport", if (!isNil "East_Ground_Transport") then { East_Ground_Transport } else { _enemyLight }];
        private _enemyColor = if (_enemySide isEqualTo east) then { "colorOPFOR" } else { "colorBLUFOR" };
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _startPos = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        ConVLocc = 1;
        
        // Find destination (enemy controlled)
        private _destObjId = [4000, getPos player, _enemySide] call FLO_fnc_getObjectiveNearPlayer;
        if (_destObjId == "") then {
            _destObjId = [_startPos, _enemySide] call FLO_fnc_getNearestObjective;
        };
        if (_destObjId == "") exitWith {
            ConVLocc = 0;
            ["SIDEMISSION", 1, format["Convoy Interdiction %1: No enemy objective available for destination", _missionId]] call FLO_fnc_log;
        };
        private _endPos = [_destObjId] call FLO_fnc_getRandomObjectivePos;
        
        // Find roads
        private _startRoads = (_startPos nearRoads 100) + (_startPos nearRoads 500);
        private _endRoads = (_endPos nearRoads 100) + (_endPos nearRoads 500);
        private _startRoad = if ((count _startRoads) > 0) then { _startRoads select 0 } else { objNull };
        private _endRoad = if ((count _endRoads) > 0) then { _endRoads select 0 } else { objNull };

        if (isNull _startRoad) then {
            private _farRoads = _startPos nearRoads 1000;
            if ((count _farRoads) > 0) then { _startRoad = _farRoads select 0; };
        };
        if (isNull _endRoad) then {
            private _farRoads = _endPos nearRoads 1000;
            if ((count _farRoads) > 0) then { _endRoad = _farRoads select 0; };
        };
        if (isNull _startRoad || isNull _endRoad) exitWith {
            ConVLocc = 0;
            ["SIDEMISSION", 1, format["Convoy Interdiction %1: No roads found near start/end positions", _missionId]] call FLO_fnc_log;
        };
        
        _startPos = getPosATL _startRoad;
        _endPos = getPosATL _endRoad;
        
        // Store mission data
        private _data = _instance get "data";
        _data set ["startPos", _startPos];
        _data set ["endPos", _endPos];
        _data set ["vehicles", []];

        // Calculate spawn direction
        private _connectedRoads = roadsConnectedTo _startRoad;
        private _spawnDir = if ((count _connectedRoads) > 0) then {
            _startRoad getDir (_connectedRoads select 0)
        } else {
            _startPos getDir _endPos
        };
        
        // Spawn vehicles (each with own crew group via createVehicleCrew)
        private _vehicles = [];
        private _spacing = 20;
        
        private _vehTypes = [
            selectRandom _enemyLight,
            selectRandom _enemyTransport,
            selectRandom _enemyLight
        ];
        
        if (_aggrScore > 5) then {
            _vehTypes append [selectRandom _enemyTransport, selectRandom _enemyLight];
        };
        if (_aggrScore > 10) then {
            _vehTypes append [selectRandom _enemyTransport, selectRandom _enemyLight];
        };
        
        {
            private _spawnPos = _startPos getPos [_forEachIndex * _spacing, _spawnDir + 180];
            private _veh = createVehicle [_x, _spawnPos, [], 5, "NONE"];
            _veh setDir _spawnDir;
            
            // Create crew - stays in its own group (NOT joined to convoy group)
            createVehicleCrew _veh;
            
            _vehicles pushBack _veh;
            ["addEntity", [_missionId, _veh]] call FLO_fnc_sideMissionEntityTracker;
            ["addGroup", [_missionId, group driver _veh]] call FLO_fnc_sideMissionEntityTracker;
        } forEach _vehTypes;
        
        _data set ["vehicles", _vehicles];

        // Use convoy controller for proper per-vehicle management
        private _convoyPathCallback = {
            params ["_status", "_posArray", "_args"];
            _args params ["_vehs", "_finalPos", "_missionData"];

            // Start convoy controller with route
            private _route = if (_status && {(count _posArray) > 0}) then { _posArray } else { [] };
            
            private _controller = [
                _vehs,
                _route,
                _finalPos,
                createHashMapFromArray [
                    ["speed", "LIMITED"],
                    ["behavior", "SAFE"],
                    ["stuckTimeout", 45]
                ]
            ] call FLO_fnc_convoyController;
            
            _missionData set ["convoyController", _controller];
        };

        [_startPos, _endPos, _convoyPathCallback, [_vehicles, _endPos, _data], false] call FLO_fnc_findRoadPath;

        [_missionId] call FLO_fnc_sideMissionTaskCreate;
        
        // Create tracking marker attached to convoy lead
        private _leadVeh = _vehicles select 0;
        private _trackMarkerName = format ["SM_ConvoyTrack_%1", _missionId];
        private _trackMarker = createMarkerLocal [_trackMarkerName, getPos _leadVeh];
        _trackMarkerName setMarkerTypeLocal "o_mech_inf";
        _trackMarkerName setMarkerColorLocal _enemyColor;
        _trackMarkerName setMarkerTextLocal "Convoy";
        _trackMarkerName setMarkerSizeLocal [0.8, 0.8];
        
        _data set ["trackMarker", _trackMarkerName];
        
        // Start tracking PFH
        private _pfhHandle = [{
            params ["_args", "_handle"];
            _args params ["_vehicles", "_markerName", "_missionId"];
            
            // Find lead alive vehicle
            private _leadVeh = objNull;
            { if (alive _x) exitWith { _leadVeh = _x; }; } forEach _vehicles;
            
            if (isNull _leadVeh) exitWith {
                // All vehicles destroyed - cleanup
                deleteMarker _markerName;
                [_handle] call CBA_fnc_removePerFrameHandler;
            };
            
            // Update marker position
            _markerName setMarkerPosLocal (getPos _leadVeh);
            
        }, 2, [_vehicles, _trackMarkerName, _missionId]] call CBA_fnc_addPerFrameHandler;
        
        _data set ["trackPFH", _pfhHandle];
    }],
    
    ["fnc_checkSuccess", {
        params ["_missionId", "_instance"];
        private _vehicles = (_instance get "data") getOrDefault ["vehicles", []];
        ({ alive _x } count _vehicles) == 0
    }],
    
    ["fnc_checkFail", {
        params ["_missionId", "_instance"];
        private _data = _instance get "data";
        private _vehicles = _data getOrDefault ["vehicles", []];
        private _endPos = _data getOrDefault ["endPos", [0,0,0]];
        
        // Fail if any vehicle reaches destination
        (_vehicles findIf { alive _x && { _x distance2D _endPos < 200 } }) >= 0
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
        ConVLocc = 0;
        
        // Cleanup tracking marker and PFH
        private _data = _instance get "data";
        private _trackMarker = _data getOrDefault ["trackMarker", ""];
        private _trackPFH = _data getOrDefault ["trackPFH", -1];
        
        if (_trackMarker != "") then { deleteMarker _trackMarker; };
        if (_trackPFH >= 0) then { [_trackPFH] call CBA_fnc_removePerFrameHandler; };
    }]
];

_template
