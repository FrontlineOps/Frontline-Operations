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
        
        private _startRoad = ((_startPos nearRoads 100) + (_startPos nearRoads 500)) select 0;
        private _endRoad = ((_endPos nearRoads 100) + (_endPos nearRoads 500)) select 0;
        
        if (isNull _startRoad) then { _startRoad = (_startPos nearRoads 1000) select 0; };
        if (isNull _endRoad) then { _endRoad = (_endPos nearRoads 1000) select 0; };
        
        _startPos = getPosATL _startRoad;
        _endPos = getPosATL _endRoad;
        
        private _data = _instance get "data";
        _data set ["startPos", _startPos];
        _data set ["endPos", _endPos];
        _data set ["vehicles", []];
        
        // Create markers
        private _startMrkr = createMarker [format ["SM_HVTStart_%1", _missionId], _startPos];
        _startMrkr setMarkerType "mil_warning";
        _startMrkr setMarkerColor "colorOPFOR";
        _startMrkr setMarkerText "HVT Convoy";
        ["addMarker", [_missionId, _startMrkr]] call FLO_fnc_sideMissionEntityTracker;
        
        private _endMrkr = createMarker [format ["SM_HVTEnd_%1", _missionId], _endPos];
        _endMrkr setMarkerType "mil_marker_noShadow";
        _endMrkr setMarkerColor "colorOPFOR";
        _endMrkr setMarkerText "HVT Destination";
        ["addMarker", [_missionId, _endMrkr]] call FLO_fnc_sideMissionEntityTracker;
        
        // Create convoy group
        private _convoyGrp = createGroup East;
        _convoyGrp deleteGroupWhenEmpty true;
        _convoyGrp setFormation "COLUMN";

        private _nextRoad = (roadsConnectedTo _startRoad) select 0;
        private _spawnDir = if (!isNull _nextRoad) then { _startRoad getDir _nextRoad } else { _startPos getDir _endPos };
        
        // HVT convoy has heavier escort - always more vehicles
        private _vehicles = [];
        private _spacing = 15;
        
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
            
            private _crewGrp = createVehicleCrew _veh;
            { [_x] join _convoyGrp; } forEach units _crewGrp;
            
            _vehicles pushBack _veh;
            ["addEntity", [_missionId, _veh]] call FLO_fnc_sideMissionEntityTracker;
        } forEach _vehTypes;
        
        _data set ["vehicles", _vehicles];
        _data set ["convoyGroup", _convoyGrp];
        ["addGroup", [_missionId, _convoyGrp]] call FLO_fnc_sideMissionEntityTracker;
        
        private _wp = _convoyGrp addWaypoint [_endPos, 50];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "AWARE";
        _wp setWaypointSpeed "NORMAL";
        
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

