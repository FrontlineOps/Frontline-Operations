/*
 * Function: FLO_fnc_templateHVTConvoy
 * Author: Frontline Operations Development Group
 * Description:
 *   Template for the High Value Target Convoy mission.
 *   Intercept a high-priority enemy convoy.
 *
 * Returns:
 *   HASHMAP - Mission template configuration
 */

private _template = createHashMapFromArray [
    ["name", "Intercept HVT Convoy"],
    ["description", "A high value enemy convoy is on the move. Ambush and destroy it before it reaches its destination."],
    ["icon", "mil_destroy"],
    ["color", "colorOPFOR"],
    ["cooldown", 1500],
    ["timeout", 2400],
    ["maxActive", 1],
    ["reward", 150],
    ["isConvoy", true],
    
    // Setup - same as regular convoy
    ["fnc_setup", {
        params ["_typeName"];
        
        if (!isNil "ConVLocc" && {ConVLocc > 0}) exitWith { [false, [0,0,0]] };
        
        private _canSpawn = false;
        private _startPos = [0,0,0];
        
        // Find OPFOR-controlled objectives only
        if (!isNil "FLO_Objectives" && {count (keys FLO_Objectives) > 0}) then {
            private _destObjId = [4000, getPos player, east] call FLO_fnc_getObjectiveNearPlayer;
            if (_destObjId != "") then {
                private _destPos = [_destObjId] call FLO_fnc_getRandomObjectivePos;

                // Find far OPFOR objective for start
                private _startCandidates = (keys FLO_Objectives) select {
                    _x != _destObjId && {
                        private _data = FLO_Objectives get _x;
                        private _owner = _data getOrDefault ["owner", east];
                        _owner isEqualTo east && {
                            private _p = _data get "position";
                            (_p distance2D _destPos) >= 6000
                        }
                    }
                };

                if (count _startCandidates > 0) then {
                    private _startObjId = selectRandom _startCandidates;
                    _startPos = [_startObjId] call FLO_fnc_getRandomObjectivePos;

                    private _startRoads = _startPos nearRoads 800;
                    private _destRoads = _destPos nearRoads 800;
                    if (count _startRoads > 0 && count _destRoads > 0) then {
                        _startPos = getPosATL (selectRandom _startRoads);
                        _canSpawn = true;
                    };
                };
            };
        };
        
        [_canSpawn, _startPos]
    }],
    
    // Spawn - heavier escort than regular convoy
    ["fnc_spawn", {
        params ["_missionId"];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _startPos = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        ConVLocc = 1;
        
        // Find OPFOR-controlled destination
        private _destObjId = [4000, getPos player, east] call FLO_fnc_getObjectiveNearPlayer;
        private _endPos = if (_destObjId != "") then {
            [_destObjId] call FLO_fnc_getRandomObjectivePos
        } else {
            _startPos getPos [3000, _startPos getDir player]
        };
        
        // Find roads near start and end positions
        private _startRoads = (_startPos nearRoads 100) + (_startPos nearRoads 500);
        private _startRoad = if (count _startRoads > 0) then { _startRoads select 0 } else { objNull };

        private _endRoads = (_endPos nearRoads 100) + (_endPos nearRoads 500);
        private _endRoad = if (count _endRoads > 0) then { _endRoads select 0 } else { objNull };

        // Expand search if no roads found
        if (isNull _startRoad) then {
            private _farRoads = _startPos nearRoads 1000;
            if (count _farRoads > 0) then { _startRoad = _farRoads select 0; };
        };
        if (isNull _endRoad) then {
            private _farRoads = _endPos nearRoads 1000;
            if (count _farRoads > 0) then { _endRoad = _farRoads select 0; };
        };

        // Abort if no roads found
        if (isNull _startRoad || isNull _endRoad) exitWith {
            ["SIDEMISSION", 1, format["HVT Convoy %1: No roads found near start/end positions", _missionId]] call FLO_fnc_log;
        };

        _startPos = getPosATL _startRoad;
        _endPos = getPosATL _endRoad;
        
        private _data = _instance get "data";
        _data set ["startPos", _startPos];
        _data set ["endPos", _endPos];
        _data set ["vehicles", []];

        private _nextRoad = (roadsConnectedTo _startRoad) select 0;
        private _spawnDir = if (!isNull _nextRoad) then { _startRoad getDir _nextRoad } else { _startPos getDir _endPos };
        
        // HVT convoy has heavier escort - each vehicle with own crew group
        private _vehicles = [];
        private _spacing = 20;
        
        private _vehTypes = [
            selectRandom East_Ground_Vehicles_Light,
            selectRandom East_Ground_Vehicles_Light,
            selectRandom East_Ground_Transport,  // HVT vehicle
            selectRandom East_Ground_Vehicles_Light,
            selectRandom East_Ground_Vehicles_Light
        ];
        
        if (_aggrScore > 5) then {
            _vehTypes append [selectRandom East_Ground_Vehicles_Medium];
        };
        if (_aggrScore > 10) then {
            _vehTypes append [selectRandom East_Ground_Vehicles_Medium];
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
            private _route = if (_status && count _posArray > 0) then { _posArray } else { [] };
            
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
        (_vehicles findIf { alive _x && { _x distance2D _endPos < 200 } }) >= 0
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
        ConVLocc = 0;
    }]
];

_template

