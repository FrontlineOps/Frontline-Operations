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

private _template = createHashMapFromArray [
    ["name", "Intercept Enemy Convoy"],
    ["description", "Intel suggests an enemy support convoy heading toward the frontlines. Intercept and destroy it."],
    ["icon", "mil_destroy"],
    ["color", "colorOPFOR"],
    ["cooldown", 1200],
    ["timeout", 2400],
    ["maxActive", 1],
    ["reward", 100],
    ["isConvoy", true],
    
    // Setup - find road positions
    ["fnc_setup", {
        params ["_typeName"];
        
        if (!isNil "ConVLocc" && {ConVLocc > 0}) exitWith { [false, [0,0,0]] };
        
        private _canSpawn = false;
        private _startPos = [0,0,0];
        
        // Find start and end objectives
        if (!isNil "FLO_Objectives" && {count (keys FLO_Objectives) > 0}) then {
            private _destObjId = [4000, getPos player] call FLO_fnc_getObjectiveNearPlayer;
            if (_destObjId != "") then {
                private _destPos = [_destObjId] call FLO_fnc_getRandomObjectivePos;
                
                // Find far objective for start
                private _startCandidates = (keys FLO_Objectives) select {
                    _x != _destObjId && {
                        private _p = (FLO_Objectives get _x) get "position";
                        (_p distance2D _destPos) >= 6000
                    }
                };
                
                if (count _startCandidates > 0) then {
                    private _startObjId = selectRandom _startCandidates;
                    _startPos = [_startObjId] call FLO_fnc_getRandomObjectivePos;
                    
                    // Verify road access
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
    
    // Spawn function
    ["fnc_spawn", {
        params ["_missionId"];
        
        private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
        private _startPos = _instance get "position";
        private _aggrScore = FLO_DifficultyHandle getOrDefault ["value", 5];
        
        ConVLocc = 1;
        
        // Find destination
        private _destObjId = [4000, getPos player] call FLO_fnc_getObjectiveNearPlayer;
        private _endPos = if (_destObjId != "") then { 
            [_destObjId] call FLO_fnc_getRandomObjectivePos 
        } else { 
            _startPos getPos [3000, _startPos getDir player] 
        };
        
        // Find roads
        private _startRoad = ((_startPos nearRoads 100) + (_startPos nearRoads 500)) select 0;
        private _endRoad = ((_endPos nearRoads 100) + (_endPos nearRoads 500)) select 0;
        
        if (isNull _startRoad) then { _startRoad = (_startPos nearRoads 1000) select 0; };
        if (isNull _endRoad) then { _endRoad = (_endPos nearRoads 1000) select 0; };
        
        _startPos = getPosATL _startRoad;
        _endPos = getPosATL _endRoad;
        
        // Store mission data
        private _data = _instance get "data";
        _data set ["startPos", _startPos];
        _data set ["endPos", _endPos];
        _data set ["vehicles", []];
        
        // Create markers
        private _startMrkr = createMarker [format ["SM_ConvStart_%1", _missionId], _startPos];
        _startMrkr setMarkerType "mil_marker_noShadow";
        _startMrkr setMarkerColor "colorOPFOR";
        _startMrkr setMarkerText "Convoy Start";
        ["addMarker", [_missionId, _startMrkr]] call FLO_fnc_sideMissionEntityTracker;
        
        private _endMrkr = createMarker [format ["SM_ConvEnd_%1", _missionId], _endPos];
        _endMrkr setMarkerType "mil_marker_noShadow";
        _endMrkr setMarkerColor "colorOPFOR";
        _endMrkr setMarkerText "Convoy Destination";
        ["addMarker", [_missionId, _endMrkr]] call FLO_fnc_sideMissionEntityTracker;
        
        // Create convoy group
        private _convoyGrp = createGroup East;
        _convoyGrp deleteGroupWhenEmpty true;
        
        // Calculate spawn direction
        private _nextRoad = (roadsConnectedTo _startRoad) select 0;
        private _spawnDir = if (!isNull _nextRoad) then { _startRoad getDir _nextRoad } else { _startPos getDir _endPos };
        
        // Spawn vehicles
        private _vehicles = [];
        private _spacing = 15;
        
        private _vehTypes = [
            selectRandom East_Ground_Vehicles_Light,
            selectRandom East_Ground_Transport,
            selectRandom East_Ground_Vehicles_Light
        ];
        
        if (_aggrScore > 5) then {
            _vehTypes append [selectRandom East_Ground_Transport, selectRandom East_Ground_Vehicles_Light];
        };
        if (_aggrScore > 10) then {
            _vehTypes append [selectRandom East_Ground_Transport, selectRandom East_Ground_Vehicles_Light];
        };
        
        {
            private _spawnPos = _startPos getPos [_forEachIndex * _spacing, _spawnDir + 180];
            private _veh = createVehicle [_x, _spawnPos, [], 5, "NONE"];
            _veh setDir _spawnDir;
            
            private _crewGrp = createVehicleCrew _veh;
            { [_x] join _convoyGrp; } forEach units _crewGrp;
            
            _vehicles pushBack _veh;
            ["addEntity", [_missionId, _veh]] call FLO_fnc_sideMissionEntityTracker;
        } forEach _vehTypes;
        
        _data set ["vehicles", _vehicles];
        _data set ["convoyGroup", _convoyGrp];
        ["addGroup", [_missionId, _convoyGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        // Set convoy destination
        private _wp = _convoyGrp addWaypoint [_endPos, 50];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointSpeed "LIMITED";
        
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
        
        // Fail if any vehicle reaches destination
        (_vehicles findIf { alive _x && { _x distance2D _endPos < 200 } }) >= 0
    }],
    
    ["fnc_cleanup", {
        params ["_missionId", "_instance"];
        ConVLocc = 0;
    }]
];

_template

